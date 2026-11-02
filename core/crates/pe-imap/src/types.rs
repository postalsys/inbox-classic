//! What a parsed response line is made of.

/// An atom with what can follow it: `BODY[HEADER]<0.100>` is the atom `BODY` with a section and
/// a partial range, and a response code `[UIDNEXT 5]` is an empty atom with a section.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Atom {
    pub value: Vec<u8>,
    pub section: Option<Vec<Token>>,
    pub partial: Option<Vec<u64>>,
}

/// One element of a response
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Token {
    /// `NIL`
    Nil,
    Atom(Atom),
    /// A quoted string, unescaped
    String(Vec<u8>),
    /// The data of a literal (`{5}` and `~{5}`)
    Literal(Vec<u8>),
    /// A sequence set such as `1:5,7` or `*:4`
    Sequence(String),
    /// A parenthesized list
    List(Vec<Token>),
    /// The human readable text of a status response or a continuation request
    Text(Vec<u8>),
}

impl Token {
    /// The bytes of an atom, string, literal, sequence set or text
    pub fn bytes(&self) -> Option<&[u8]> {
        match self {
            Token::Atom(atom) => Some(&atom.value),
            Token::String(value) | Token::Literal(value) | Token::Text(value) => Some(value),
            Token::Sequence(value) => Some(value.as_bytes()),
            Token::Nil | Token::List(_) => None,
        }
    }

    /// The value as text, invalid UTF-8 replaced
    pub fn text(&self) -> Option<String> {
        self.bytes().map(|bytes| String::from_utf8_lossy(bytes).into_owned())
    }

    /// The value as a number, for atoms like `UIDNEXT 5`
    pub fn number(&self) -> Option<u64> {
        let bytes = self.bytes()?;
        if bytes.is_empty() || bytes.len() > 20 || !bytes.iter().all(u8::is_ascii_digit) {
            return None;
        }
        std::str::from_utf8(bytes).ok()?.parse().ok()
    }

    pub fn as_list(&self) -> Option<&[Token]> {
        match self {
            Token::List(items) => Some(items),
            _ => None,
        }
    }

    pub fn as_atom(&self) -> Option<&Atom> {
        match self {
            Token::Atom(atom) => Some(atom),
            _ => None,
        }
    }

    /// Whether this is an atom equal to `name`, ignoring case
    pub fn is_atom(&self, name: &str) -> bool {
        matches!(self, Token::Atom(atom) if atom.value.eq_ignore_ascii_case(name.as_bytes()))
    }
}

/// A parsed response line
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Response {
    /// `*` for untagged responses, `+` for continuation requests, otherwise the tag of a command
    pub tag: String,
    /// The response name (`OK`, `FETCH`, `CAPABILITY`), or a message number (`* 12 FETCH`, `* 3 EXISTS`)
    pub command: String,
    pub attributes: Vec<Token>,
    /// The numbers of an untagged SEARCH response, read without the tokenizer
    pub numbers: Option<Vec<u64>>,
    /// Leading NUL bytes that were removed (some servers pad their lines)
    pub null_bytes_removed: usize,
    /// FETCH data items (e.g. `BODYSTRUCTURE`) replaced by NIL because they nested too deep
    pub truncated_attributes: Vec<String>,
}

impl Response {
    pub fn is_untagged(&self) -> bool {
        self.tag == "*"
    }

    pub fn is_continuation(&self) -> bool {
        self.tag == "+"
    }

    /// The human readable text of a status response
    pub fn text(&self) -> Option<String> {
        self.attributes
            .iter()
            .rev()
            .find(|token| matches!(token, Token::Text(_)))?
            .text()
    }

    /// The response code of a status response (`[UIDNEXT 5]` gives `UIDNEXT` and `[5]`)
    pub fn code(&self) -> Option<(String, &[Token])> {
        let atom = self.attributes.first()?.as_atom()?;
        let section = atom.section.as_ref()?;
        if !atom.value.is_empty() {
            return None;
        }
        let name = section.first()?.text()?.to_ascii_uppercase();
        Some((name, &section[1..]))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn token_helpers() {
        let atom = Token::Atom(Atom {
            value: b"12".to_vec(),
            ..Default::default()
        });
        assert_eq!(atom.number(), Some(12));
        assert!(atom.is_atom("12"));
        assert_eq!(Token::String(b"x".to_vec()).number(), None);
        assert_eq!(Token::Nil.bytes(), None);
        assert_eq!(Token::Atom(Atom::default()).number(), None);
        assert_eq!(Token::Sequence("99999999999999999999999".into()).number(), None);
        assert!(Token::List(vec![]).as_list().is_some());
    }
}
