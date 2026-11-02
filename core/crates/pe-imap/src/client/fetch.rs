//! FETCH: what to ask for ([`FetchQuery`]) and what comes back ([`FetchedMessage`]). Bodies are
//! fetched with BODY.PEEK so reading does not mark a message as seen. A port of imapflow's
//! fetch.ts and of its formatMessageResponse.

use std::collections::BTreeMap;

use super::{Client, Error};
use crate::compiler::Arg;
use crate::message::{BodyStructure, Envelope, parse_body_structure, parse_envelope};
use crate::types::{Response, Token};

/// The data items to fetch. The UID is always fetched.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct FetchQuery {
    pub flags: bool,
    pub envelope: bool,
    pub body_structure: bool,
    pub internal_date: bool,
    pub size: bool,
    /// MODSEQ, where CONDSTORE is available
    pub modseq: bool,
    /// The header: all of it for `Some(vec![])`, these fields otherwise
    pub headers: Option<Vec<String>>,
    /// Body parts by part number (`1`, `1.2`, `2.MIME`)
    pub parts: Vec<String>,
    /// The whole message
    pub source: bool,
    /// Only messages whose MODSEQ is higher (CONDSTORE)
    pub changed_since: Option<u64>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct FetchedMessage {
    pub seq: u32,
    pub uid: Option<u64>,
    pub flags: Option<Vec<String>>,
    pub envelope: Option<Envelope>,
    pub body_structure: Option<BodyStructure>,
    /// INTERNALDATE in seconds since the Unix epoch
    pub internal_date: Option<i64>,
    pub size: Option<u64>,
    pub modseq: Option<u64>,
    pub headers: Option<Vec<u8>>,
    pub parts: BTreeMap<String, Vec<u8>>,
    pub source: Option<Vec<u8>>,
}

impl FetchQuery {
    fn items(&self, condstore: bool) -> Vec<Arg> {
        let mut items = vec![Arg::atom("UID")];
        let flag = |on: bool, name: &str, items: &mut Vec<Arg>| {
            if on {
                items.push(Arg::atom(name));
            }
        };
        flag(self.flags, "FLAGS", &mut items);
        flag(self.envelope, "ENVELOPE", &mut items);
        flag(self.body_structure, "BODYSTRUCTURE", &mut items);
        flag(self.internal_date, "INTERNALDATE", &mut items);
        flag(self.size, "RFC822.SIZE", &mut items);
        flag(self.modseq && condstore, "MODSEQ", &mut items);
        let peek = |section: Vec<Arg>| Arg::Section {
            name: "BODY.PEEK".into(),
            section,
            partial: None,
        };
        match &self.headers {
            Some(fields) if fields.is_empty() => items.push(peek(vec![Arg::atom("HEADER")])),
            Some(fields) => items.push(peek(vec![
                Arg::atom("HEADER.FIELDS"),
                Arg::List(fields.iter().map(|f| Arg::atom(f.to_ascii_uppercase())).collect()),
            ])),
            None => {}
        }
        for part in &self.parts {
            items.push(peek(vec![Arg::atom(part.as_str())]));
        }
        if self.source {
            items.push(peek(Vec::new()));
        }
        items
    }
}

impl Client {
    /// Fetches `set` (sequence numbers, or UIDs when `uid` is set) and returns the messages in
    /// the order the server sent them
    pub async fn fetch(&mut self, set: &str, uid: bool, query: &FetchQuery) -> Result<Vec<FetchedMessage>, Error> {
        let mut messages: Vec<FetchedMessage> = Vec::new();
        self.fetch_each(set, uid, query, &mut |message| {
            // some servers split one message over several FETCH responses
            match messages.last_mut() {
                Some(last) if last.seq == message.seq => merge(last, message),
                _ => messages.push(message),
            }
        })
        .await?;
        Ok(messages)
    }

    /// Fetches like [`Client::fetch`], handing each message to `each` as it arrives instead of
    /// collecting them, for large mailboxes
    pub async fn fetch_each(
        &mut self,
        set: &str,
        uid: bool,
        query: &FetchQuery,
        each: &mut dyn FnMut(FetchedMessage),
    ) -> Result<(), Error> {
        if self.selected.is_none() {
            return Err(Error::NoMailboxSelected);
        }
        let condstore = self.has_capability("CONDSTORE");
        let mut args = vec![Arg::Sequence(set.to_string()), Arg::List(query.items(condstore))];
        if let (Some(modseq), true) = (query.changed_since, condstore) {
            args.push(Arg::List(vec![Arg::atom("CHANGEDSINCE"), Arg::Number(modseq)]));
        }
        let command = if uid { "UID FETCH" } else { "FETCH" };
        self.collecting_fetch = true;
        let result = self
            .run_with(
                command,
                args,
                &mut |response| {
                    let seq = response.command.parse::<u32>();
                    match (seq, response.attributes.first()) {
                        (Ok(seq), Some(kind)) if kind.is_atom("FETCH") => {
                            each(parse_fetch(seq, &response));
                            Ok(None)
                        }
                        _ => Ok(Some(response)),
                    }
                },
                &mut |_| Err(Error::Unexpected("continuation request".into())),
            )
            .await;
        self.collecting_fetch = false;
        result.map(|_| ())
    }
}

fn merge(into: &mut FetchedMessage, from: FetchedMessage) {
    into.uid = into.uid.or(from.uid);
    into.flags = from.flags.or(into.flags.take());
    into.envelope = from.envelope.or(into.envelope.take());
    into.body_structure = from.body_structure.or(into.body_structure.take());
    into.internal_date = into.internal_date.or(from.internal_date);
    into.size = into.size.or(from.size);
    into.modseq = from.modseq.or(into.modseq);
    into.headers = from.headers.or(into.headers.take());
    into.source = from.source.or(into.source.take());
    into.parts.extend(from.parts);
}

fn bytes(token: &Token) -> Option<Vec<u8>> {
    match token {
        Token::String(value) | Token::Literal(value) => Some(value.clone()),
        Token::Atom(atom) => Some(atom.value.clone()),
        _ => None,
    }
}

/// `* 12 FETCH (UID 98 FLAGS (\Seen) ...)`
pub(crate) fn parse_fetch(seq: u32, response: &Response) -> FetchedMessage {
    let mut message = FetchedMessage {
        seq,
        ..Default::default()
    };
    let Some(items) = response.attributes.get(1).and_then(Token::as_list) else {
        return message;
    };
    for pair in items.chunks_exact(2) {
        let (key, value) = (&pair[0], &pair[1]);
        let Some(atom) = key.as_atom() else { continue };
        let name = String::from_utf8_lossy(&atom.value).to_ascii_uppercase();
        match (name.as_str(), &atom.section) {
            ("UID", _) => message.uid = value.number(),
            ("FLAGS", _) => message.flags = value.as_list().map(|f| f.iter().filter_map(Token::text).collect()),
            ("ENVELOPE", _) => message.envelope = value.as_list().map(parse_envelope),
            ("BODYSTRUCTURE", _) | ("BODY", None) => message.body_structure = value.as_list().map(parse_body_structure),
            ("INTERNALDATE", _) => {
                message.internal_date = value.text().and_then(|d| pe_mime::date::parse_internal_date(&d));
            }
            ("RFC822.SIZE", _) => message.size = value.number(),
            ("MODSEQ", _) => message.modseq = value.as_list().and_then(|l| l.first()).and_then(Token::number),
            ("BODY" | "BINARY", Some(section)) => body_section(&mut message, section, bytes(value)),
            _ => {}
        }
    }
    message
}

fn body_section(message: &mut FetchedMessage, section: &[Token], value: Option<Vec<u8>>) {
    let value = value.unwrap_or_default();
    let Some(first) = section.first().and_then(Token::text) else {
        message.source = Some(value);
        return;
    };
    let upper = first.to_ascii_uppercase();
    if upper == "HEADER" || upper.starts_with("HEADER.FIELDS") {
        message.headers = Some(value);
    } else {
        message.parts.insert(first, value);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::compiler::{Command, CompileOptions, compile};

    #[test]
    fn query_items() {
        let query = FetchQuery {
            flags: true,
            envelope: true,
            modseq: true,
            headers: Some(vec!["Subject".into(), "references".into()]),
            parts: vec!["1.2".into()],
            source: true,
            ..Default::default()
        };
        let command = Command {
            tag: "A1".into(),
            name: "UID FETCH".into(),
            args: vec![Arg::Sequence("1:*".into()), Arg::List(query.items(true))],
        };
        let wire = compile(&command, &CompileOptions::default()).unwrap().concat();
        assert_eq!(
            String::from_utf8(wire).unwrap(),
            "A1 UID FETCH 1:* (UID FLAGS ENVELOPE MODSEQ BODY.PEEK[HEADER.FIELDS (SUBJECT REFERENCES)] BODY.PEEK[1.2] BODY.PEEK[])\r\n"
        );
        assert!(!query.items(false).iter().any(|a| *a == Arg::atom("MODSEQ")));
    }

    #[test]
    fn parses_fetch_items() {
        let response = crate::parse(
            b"* 12 FETCH (UID 98 FLAGS (\\Seen $Forwarded) INTERNALDATE \"17-Jul-1996 02:44:25 -0700\" RFC822.SIZE 4286 MODSEQ (12121231000) BODY[HEADER.FIELDS (SUBJECT)] {4}\r\n BODY[1] \"hi\" BODY[] NIL)",
            vec![b"S: x".to_vec()],
        )
        .unwrap();
        let message = parse_fetch(12, &response);
        assert_eq!(message.uid, Some(98));
        assert_eq!(
            message.flags,
            Some(vec!["\\Seen".to_string(), "$Forwarded".to_string()])
        );
        assert_eq!(message.internal_date, Some(837_596_665));
        assert_eq!((message.size, message.modseq), (Some(4286), Some(12_121_231_000)));
        assert_eq!(message.headers.as_deref(), Some(&b"S: x"[..]));
        assert_eq!(message.parts["1"], b"hi");
        assert_eq!(message.source.as_deref(), Some(&b""[..]));
    }

    #[test]
    fn merges_split_responses() {
        let mut first = FetchedMessage {
            seq: 1,
            uid: Some(5),
            ..Default::default()
        };
        let second = FetchedMessage {
            seq: 1,
            flags: Some(vec![]),
            size: Some(3),
            ..Default::default()
        };
        merge(&mut first, second);
        assert_eq!((first.uid, first.size, first.flags.is_some()), (Some(5), Some(3), true));
    }
}
