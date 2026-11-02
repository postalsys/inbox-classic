//! Builds commands for the wire. Every value passes through a check for what its token type can
//! carry, so nothing a caller passes in (a mailbox name, a search term, a flag) can end the
//! command line early or inject a second command. A port of the rules of imapflow's
//! `imap-compiler.ts`, with a typed argument list instead of loosely typed nodes.

use crate::error::CompileError;
use std::io::Write as _;

use crate::syntax::{is_astring_char, is_atom_char, is_command_char};

/// Literals up to this size may be non-synchronizing under LITERAL- (RFC 7888)
const LITERAL_MINUS_MAX: usize = 4096;

/// Longest value a log line shows in full
const LOG_VALUE_LIMIT: usize = 100;

/// One argument of a command
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Arg {
    /// Written as is when every byte is an ATOM-CHAR (a leading `\` is allowed for flags such as
    /// `\Seen`, and `\*`), otherwise as a quoted string
    Atom(String),
    /// A string: quoted when it can be, a literal otherwise
    Str(Vec<u8>),
    /// Always a literal, for message data
    Literal(Vec<u8>),
    /// A literal8 (RFC 3516), for binary message data
    Literal8(Vec<u8>),
    /// A sequence set, validated: `1:5,7,10:*` or `$`
    Sequence(String),
    Number(u64),
    List(Vec<Arg>),
    Nil,
    /// A fetch item with a section and an optional partial range: `BODY.PEEK[HEADER]<0.100>`
    Section {
        name: String,
        section: Vec<Arg>,
        partial: Option<(u64, u64)>,
    },
    /// A value hidden from logs, such as a password
    Sensitive(Box<Arg>),
}

impl Arg {
    pub fn atom(value: impl Into<String>) -> Self {
        Arg::Atom(value.into())
    }

    pub fn string(value: impl Into<Vec<u8>>) -> Self {
        Arg::Str(value.into())
    }

    pub fn sensitive(arg: Arg) -> Self {
        Arg::Sensitive(Box::new(arg))
    }
}

/// A command, `A1 UID FETCH 1:* (FLAGS)`
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Command {
    pub tag: String,
    /// The command name, may be two words (`UID FETCH`)
    pub name: String,
    pub args: Vec<Arg>,
}

#[derive(Debug, Clone, Copy, Default)]
pub struct CompileOptions {
    /// The server announced LITERAL+, literals need no continuation
    pub literal_plus: bool,
    /// The server announced LITERAL-, literals up to 4 KiB need no continuation
    pub literal_minus: bool,
    /// UTF8=ACCEPT is enabled, quoted strings may carry UTF-8
    pub utf8: bool,
}

/// What [`compile`] gives: the parts to send. The first is sent right away; each later part
/// follows a synchronizing literal and is sent only after the server's `+` continuation.
pub type Segments = Vec<Vec<u8>>;

/// Writes `command` for the wire, ending with CRLF.
pub fn compile(command: &Command, options: &CompileOptions) -> Result<Segments, CompileError> {
    let mut writer = Writer {
        options: *options,
        segments: Vec::new(),
        current: Vec::new(),
    };
    writer.head(command)?;
    for arg in &command.args {
        writer.current.push(b' ');
        writer.arg(arg)?;
    }
    writer.current.extend_from_slice(b"\r\n");
    let mut segments = writer.segments;
    segments.push(writer.current);
    Ok(segments)
}

/// The command as a log line: sensitive values hidden, long values and literals replaced by
/// their size. Nothing is validated, so this never fails, whatever the arguments hold.
pub fn to_log_string(command: &Command) -> String {
    let mut out = format!("{} {}", command.tag, command.name);
    for arg in &command.args {
        out.push(' ');
        log_arg(arg, &mut out);
    }
    out.replace(['\r', '\n'], " ")
}

fn log_arg(arg: &Arg, out: &mut String) {
    use std::fmt::Write as _;
    let placeholder = |out: &mut String, length: usize, kind: &str| {
        let _ = write!(out, "\"(* {length}B {kind} *)\"");
    };
    let list = |out: &mut String, items: &[Arg]| {
        for (i, item) in items.iter().enumerate() {
            if i > 0 {
                out.push(' ');
            }
            log_arg(item, out);
        }
    };
    match arg {
        Arg::Atom(value) | Arg::Sequence(value) if value.len() > LOG_VALUE_LIMIT => placeholder(
            out,
            value.len(),
            if matches!(arg, Arg::Atom(_)) {
                "atom"
            } else {
                "sequence"
            },
        ),
        Arg::Atom(value) | Arg::Sequence(value) => out.push_str(value),
        Arg::Str(value) if value.len() > LOG_VALUE_LIMIT => placeholder(out, value.len(), "string"),
        Arg::Str(value) => {
            let _ = write!(out, "{:?}", String::from_utf8_lossy(value));
        }
        Arg::Literal(value) | Arg::Literal8(value) => placeholder(out, value.len(), "literal"),
        Arg::Number(value) => {
            let _ = write!(out, "{value}");
        }
        Arg::Nil => out.push_str("NIL"),
        Arg::List(items) => {
            out.push('(');
            list(out, items);
            out.push(')');
        }
        Arg::Section { name, section, partial } => {
            out.push_str(name);
            out.push('[');
            list(out, section);
            out.push(']');
            if let Some((start, length)) = partial {
                let _ = write!(out, "<{start}.{length}>");
            }
        }
        Arg::Sensitive(_) => out.push_str("\"(* value hidden *)\""),
    }
}

/// Writes validated arguments for the wire
struct Writer {
    options: CompileOptions,
    segments: Segments,
    current: Vec<u8>,
}

impl Writer {
    fn head(&mut self, command: &Command) -> Result<(), CompileError> {
        if command.tag.is_empty() || !command.tag.bytes().all(|c| is_astring_char(c) && c != b'+') {
            return Err(CompileError::new("InvalidTag", "Invalid command tag"));
        }
        if !command
            .name
            .split(' ')
            .all(|w| !w.is_empty() && w.bytes().all(is_command_char))
        {
            return Err(CompileError::new("InvalidCommand", "Invalid command name"));
        }
        let _ = write!(self.current, "{} {}", command.tag, command.name);
        Ok(())
    }

    fn arg(&mut self, arg: &Arg) -> Result<(), CompileError> {
        match arg {
            Arg::Atom(value) => self.atom(value),
            Arg::Str(value) => self.string(value),
            Arg::Literal(value) => self.literal(value, false),
            Arg::Literal8(value) => self.literal(value, true),
            Arg::Sequence(value) => {
                if !is_valid_sequence_set(value) {
                    return Err(CompileError::new("InvalidSequenceSet", "Invalid sequence set value"));
                }
                self.current.extend_from_slice(value.as_bytes());
                Ok(())
            }
            Arg::Number(value) => {
                let _ = write!(self.current, "{value}");
                Ok(())
            }
            Arg::Nil => {
                self.current.extend_from_slice(b"NIL");
                Ok(())
            }
            Arg::List(items) => {
                self.current.push(b'(');
                self.list(items)?;
                self.current.push(b')');
                Ok(())
            }
            Arg::Section { name, section, partial } => {
                if name.is_empty() || !name.bytes().all(is_atom_char) {
                    return Err(CompileError::new("InvalidTokenValue", "Invalid fetch item name"));
                }
                self.current.extend_from_slice(name.as_bytes());
                self.current.push(b'[');
                self.list(section)?;
                self.current.push(b']');
                if let Some((start, length)) = partial {
                    let _ = write!(self.current, "<{start}.{length}>");
                }
                Ok(())
            }
            Arg::Sensitive(inner) => self.arg(inner),
        }
    }

    /// Arguments separated by spaces
    fn list(&mut self, items: &[Arg]) -> Result<(), CompileError> {
        for (i, item) in items.iter().enumerate() {
            if i > 0 {
                self.current.push(b' ');
            }
            self.arg(item)?;
        }
        Ok(())
    }

    fn atom(&mut self, value: &str) -> Result<(), CompileError> {
        let name = value.strip_prefix('\\').unwrap_or(value);
        let valid = !name.is_empty() && (name == "*" && value.starts_with('\\') || name.bytes().all(is_atom_char));
        if !valid {
            return self.string(value.as_bytes());
        }
        self.current.extend_from_slice(value.as_bytes());
        Ok(())
    }

    fn string(&mut self, value: &[u8]) -> Result<(), CompileError> {
        // CR, LF and NUL can not be quoted; 8-bit text only with UTF8=ACCEPT
        let quotable = !value.iter().any(|c| matches!(c, b'\r' | b'\n' | 0))
            && (self.options.utf8 && std::str::from_utf8(value).is_ok() || value.is_ascii());
        if !quotable {
            return self.literal(value, false);
        }
        self.current.push(b'"');
        for c in value {
            if *c == b'"' || *c == b'\\' {
                self.current.push(b'\\');
            }
            self.current.push(*c);
        }
        self.current.push(b'"');
        Ok(())
    }

    fn literal(&mut self, value: &[u8], literal8: bool) -> Result<(), CompileError> {
        let non_sync = self.options.literal_plus || (self.options.literal_minus && value.len() <= LITERAL_MINUS_MAX);
        let _ = write!(
            self.current,
            "{}{{{}{}}}\r\n",
            if literal8 { "~" } else { "" },
            value.len(),
            if non_sync { "+" } else { "" }
        );
        if !non_sync {
            // the data waits for the server's continuation
            self.segments.push(std::mem::take(&mut self.current));
        }
        self.current.extend_from_slice(value);
        Ok(())
    }
}

/// `$` (RFC 5182), or comma separated numbers and ranges where `*` is the largest number in use
pub fn is_valid_sequence_set(value: &str) -> bool {
    let number = |part: &str| part == "*" || (!part.is_empty() && part.bytes().all(|c| c.is_ascii_digit()));
    value == "$"
        || value.split(',').all(|range| match range.split_once(':') {
            Some((first, last)) => number(first) && number(last),
            None => number(range),
        })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn command(name: &str, args: Vec<Arg>) -> Command {
        Command {
            tag: "A1".into(),
            name: name.into(),
            args,
        }
    }

    fn one(command: &Command) -> String {
        let segments = compile(command, &CompileOptions::default()).unwrap();
        assert_eq!(segments.len(), 1);
        String::from_utf8(segments[0].clone()).unwrap()
    }

    #[test]
    fn simple_commands() {
        assert_eq!(one(&command("NOOP", vec![])), "A1 NOOP\r\n");
        let fetch = command(
            "UID FETCH",
            vec![
                Arg::Sequence("1:*".into()),
                Arg::List(vec![
                    Arg::atom("FLAGS"),
                    Arg::Section {
                        name: "BODY.PEEK".into(),
                        section: vec![Arg::atom("HEADER.FIELDS"), Arg::List(vec![Arg::atom("SUBJECT")])],
                        partial: Some((0, 100)),
                    },
                ]),
            ],
        );
        assert_eq!(
            one(&fetch),
            "A1 UID FETCH 1:* (FLAGS BODY.PEEK[HEADER.FIELDS (SUBJECT)]<0.100>)\r\n"
        );
        let store = command(
            "STORE",
            vec![
                Arg::Number(1),
                Arg::atom("+FLAGS"),
                Arg::List(vec![Arg::atom("\\Seen"), Arg::atom("\\*")]),
            ],
        );
        assert_eq!(one(&store), "A1 STORE 1 +FLAGS (\\Seen \\*)\r\n");
    }

    #[test]
    fn strings_are_quoted_or_literal() {
        let login = command("LOGIN", vec![Arg::string("us\"er"), Arg::string("a\\b")]);
        assert_eq!(one(&login), "A1 LOGIN \"us\\\"er\" \"a\\\\b\"\r\n");
        // an atom that is not one is quoted
        assert_eq!(
            one(&command("SELECT", vec![Arg::atom("My Folder")])),
            "A1 SELECT \"My Folder\"\r\n"
        );
        assert_eq!(one(&command("SELECT", vec![Arg::atom("")])), "A1 SELECT \"\"\r\n");

        let segments = compile(
            &command("LOGIN", vec![Arg::string("a\r\nA2 DELETE INBOX")]),
            &CompileOptions::default(),
        )
        .unwrap();
        assert_eq!(
            segments,
            vec![b"A1 LOGIN {18}\r\n".to_vec(), b"a\r\nA2 DELETE INBOX\r\n".to_vec()]
        );

        let utf8 = command("SELECT", vec![Arg::string("Šegregator")]);
        assert_eq!(compile(&utf8, &CompileOptions::default()).unwrap().len(), 2);
        let options = CompileOptions {
            utf8: true,
            ..Default::default()
        };
        assert_eq!(
            compile(&utf8, &options).unwrap(),
            vec!["A1 SELECT \"Šegregator\"\r\n".as_bytes().to_vec()]
        );
    }

    #[test]
    fn literal_plus_and_minus() {
        let append = command("APPEND", vec![Arg::atom("INBOX"), Arg::Literal(b"hello".to_vec())]);
        let plus = CompileOptions {
            literal_plus: true,
            ..Default::default()
        };
        assert_eq!(
            compile(&append, &plus).unwrap(),
            vec![b"A1 APPEND INBOX {5+}\r\nhello\r\n".to_vec()]
        );
        let minus = CompileOptions {
            literal_minus: true,
            ..Default::default()
        };
        assert_eq!(compile(&append, &minus).unwrap().len(), 1);
        let big = command("APPEND", vec![Arg::atom("INBOX"), Arg::Literal8(vec![0; 5000])]);
        let segments = compile(&big, &minus).unwrap();
        assert_eq!(segments[0], b"A1 APPEND INBOX ~{5000}\r\n".to_vec());
    }

    #[test]
    fn refuses_what_can_not_be_written() {
        let options = CompileOptions::default();
        for bad in ["", "1:", "1,,2", "a", "1:2:3", "1 2", "1\r\n"] {
            assert!(
                compile(&command("FETCH", vec![Arg::Sequence(bad.into())]), &options).is_err(),
                "{bad}"
            );
        }
        for good in ["1", "1:*", "*:4,5:7", "$", "1,3,5"] {
            assert!(is_valid_sequence_set(good), "{good}");
        }
        assert!(
            compile(
                &Command {
                    tag: "A\r\n".into(),
                    name: "NOOP".into(),
                    args: vec![]
                },
                &options
            )
            .is_err()
        );
        assert!(
            compile(
                &Command {
                    tag: "+".into(),
                    name: "NOOP".into(),
                    args: vec![]
                },
                &options
            )
            .is_err()
        );
        assert!(
            compile(
                &Command {
                    tag: "A1".into(),
                    name: "NOOP\r\nA2 X".into(),
                    args: vec![]
                },
                &options
            )
            .is_err()
        );
        assert!(
            compile(
                &Command {
                    tag: "A1".into(),
                    name: "UID  FETCH".into(),
                    args: vec![]
                },
                &options
            )
            .is_err()
        );
        let section = Arg::Section {
            name: "BODY PEEK".into(),
            section: vec![],
            partial: None,
        };
        assert!(compile(&command("FETCH", vec![section]), &options).is_err());
    }

    #[test]
    fn log_lines_hide_secrets() {
        let login = command(
            "LOGIN",
            vec![Arg::string("user"), Arg::sensitive(Arg::string("secret"))],
        );
        assert_eq!(to_log_string(&login), "A1 LOGIN \"user\" \"(* value hidden *)\"");
        let append = command(
            "APPEND",
            vec![
                Arg::atom("INBOX"),
                Arg::Literal(vec![b'x'; 500]),
                Arg::string("y".repeat(200)),
            ],
        );
        assert_eq!(
            to_log_string(&append),
            "A1 APPEND INBOX \"(* 500B literal *)\" \"(* 200B string *)\""
        );
        let odd = command("FETCH", vec![Arg::Sequence("not\r\nvalid".into())]);
        assert_eq!(to_log_string(&odd), "A1 FETCH not  valid");
    }
}
