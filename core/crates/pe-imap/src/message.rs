//! What FETCH tells about a message: the ENVELOPE and the BODYSTRUCTURE, decoded into structs.
//! A port of imapflow's `parseEnvelope` and `parseBodystructure`.

use std::collections::BTreeMap;

pub use pe_mime::{Address, Envelope};
use pe_mime::{decode_params, decode_words};

use crate::types::Token;

/// One part of a message
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct BodyStructure {
    /// The part number for BODY[...], `1.2`; None for the message itself
    pub part: Option<String>,
    /// Lowercase `type/subtype`
    pub content_type: String,
    pub parameters: BTreeMap<String, String>,
    pub id: Option<String>,
    pub description: Option<String>,
    /// Lowercase transfer encoding
    pub encoding: Option<String>,
    pub size: Option<u64>,
    /// For message/rfc822, the envelope of the attached message
    pub envelope: Option<Box<Envelope>>,
    pub line_count: Option<u64>,
    pub md5: Option<String>,
    pub disposition: Option<String>,
    pub disposition_parameters: BTreeMap<String, String>,
    pub language: Vec<String>,
    pub location: Option<String>,
    /// The parts of a multipart, or the body of an attached message
    pub children: Vec<BodyStructure>,
}

fn text(token: Option<&Token>) -> Option<String> {
    token.and_then(Token::text)
}

fn lower(token: Option<&Token>) -> String {
    text(token).unwrap_or_default().to_ascii_lowercase()
}

/// A count where one is expected: absent for NIL, 0 for something that is not a number (as
/// imapflow reads a malformed structure)
fn count(token: Option<&Token>) -> Option<u64> {
    match token? {
        Token::Nil => None,
        other => Some(other.number().unwrap_or(0)),
    }
}

/// A text field: absent for NIL, empty for a list where text belongs (a malformed structure)
fn field(token: Option<&Token>) -> Option<String> {
    match token? {
        Token::Nil => None,
        Token::List(_) => Some(String::new()),
        other => other.text(),
    }
}

/// The fields of a list: absent for NIL, a field of its own for anything else (a malformed
/// structure, read the way imapflow reads it)
fn fields(token: Option<&Token>) -> Option<&[Token]> {
    match token? {
        Token::List(items) => Some(items),
        Token::Nil => None,
        other => Some(std::slice::from_ref(other)),
    }
}

/// Some servers leave the quotes of a quoted display name in place
fn unquote(value: String) -> String {
    match value.strip_prefix('"').and_then(|v| v.strip_suffix('"')) {
        Some(inner) if value.len() > 2 => inner.to_string(),
        _ => value,
    }
}

fn decode_text(value: Option<String>) -> String {
    unquote(decode_words(&value.unwrap_or_default()))
}

fn address(fields: &[Token]) -> Option<Address> {
    let mut name = decode_text(text(fields.first()));
    let mailbox = text(fields.get(2)).unwrap_or_default();
    let host = text(fields.get(3)).unwrap_or_default();
    // a NIL host is RFC 5322 group syntax: the mailbox holds the group name, a NIL mailbox ends
    // the group. Joining the fields would invent an address that was never there.
    let address = if host.is_empty() {
        if name.is_empty() && !mailbox.is_empty() {
            name = decode_text(Some(mailbox));
        }
        String::new()
    } else {
        format!("{mailbox}@{host}")
    };
    (!name.is_empty() || !address.is_empty()).then_some(Address { name, address })
}

fn addresses(token: Option<&Token>) -> Vec<Address> {
    let list = token.and_then(Token::as_list).unwrap_or_default();
    list.iter().filter_map(Token::as_list).filter_map(address).collect()
}

pub fn parse_envelope(fields: &[Token]) -> Envelope {
    let non_empty = |i: usize| text(fields.get(i)).filter(|value| !value.is_empty());
    Envelope {
        date: non_empty(0),
        subject: non_empty(1).map(|subject| decode_words(&subject)),
        from: addresses(fields.get(2)),
        sender: addresses(fields.get(3)),
        reply_to: addresses(fields.get(4)),
        to: addresses(fields.get(5)),
        cc: addresses(fields.get(6)),
        bcc: addresses(fields.get(7)),
        in_reply_to: non_empty(8).map(|value| value.trim().to_string()),
        message_id: non_empty(9).map(|value| value.trim().to_string()),
    }
}

fn params(token: Option<&Token>) -> BTreeMap<String, String> {
    let Some(list) = token.and_then(Token::as_list) else {
        return BTreeMap::new();
    };
    let values: Vec<String> = list.iter().map(|t| t.text().unwrap_or_default()).collect();
    decode_params(values.chunks_exact(2).map(|pair| (pair[0].as_str(), pair[1].as_str())))
}

pub fn parse_body_structure(node: &[Token]) -> BodyStructure {
    walk(node, None)
}

/// A part numbered `part`; its children are numbered below it
fn walk(node: &[Token], part: Option<String>) -> BodyStructure {
    let mut structure = BodyStructure {
        part,
        ..Default::default()
    };
    let rest = if matches!(node.first(), Some(Token::List(_))) {
        multipart(&mut structure, node)
    } else {
        single_part(&mut structure, node)
    };
    extension_fields(&mut structure, rest);
    structure
}

fn child_part(parent: &Option<String>, index: usize) -> String {
    match parent {
        Some(parent) => format!("{parent}.{index}"),
        None => index.to_string(),
    }
}

/// The parts, the subtype and the parameters of a multipart, returns what follows them
fn multipart<'a>(structure: &mut BodyStructure, node: &'a [Token]) -> &'a [Token] {
    let parts = node.iter().take_while(|t| matches!(t, Token::List(_))).count();
    for (i, child) in node[..parts].iter().filter_map(Token::as_list).enumerate() {
        structure
            .children
            .push(walk(child, Some(child_part(&structure.part, i + 1))));
    }
    structure.content_type = format!("multipart/{}", lower(node.get(parts)));
    if node.len() > parts + 1 {
        structure.parameters = params(node.get(parts + 1));
        return &node[parts + 2..];
    }
    &[]
}

/// The fields of a non-multipart part, returns its extension data
fn single_part<'a>(part: &mut BodyStructure, node: &'a [Token]) -> &'a [Token] {
    part.content_type = format!("{}/{}", lower(node.first()), lower(node.get(1)));
    part.parameters = params(node.get(2));
    part.id = field(node.get(3));
    part.description = field(node.get(4));
    part.encoding = field(node.get(5)).map(|e| e.to_ascii_lowercase());
    part.size = count(node.get(6));
    let mut i = 7;

    if part.content_type == "message/rfc822" {
        // the envelope, the structure and the line count of the attached message, which shares
        // the part number of its wrapper
        part.envelope = fields(node.get(i)).map(|f| Box::new(parse_envelope(f)));
        if let Some(child) = fields(node.get(i + 1)) {
            part.children.push(walk(child, part.part.clone()));
        }
        part.line_count = count(node.get(i + 2));
        i += 3;
    }

    if part.content_type.starts_with("text/") {
        // some servers leave out the line count of a text part, which shifts the disposition
        let shifted = node.len() == 11
            && matches!(node.get(i + 1), Some(Token::List(_)))
            && !matches!(node.get(i + 2), Some(Token::List(_)));
        if !shifted {
            part.line_count = count(node.get(i));
            i += 1;
        }
    }

    if i < node.len() {
        part.md5 = field(node.get(i)).map(|md5| md5.to_ascii_lowercase());
        i += 1;
    }
    node.get(i..).unwrap_or_default()
}

/// Disposition, language and location, shared by multipart and other parts
fn extension_fields(part: &mut BodyStructure, rest: &[Token]) {
    let mut rest = rest.iter();
    if let Some(disposition) = rest.next().and_then(Token::as_list).filter(|d| !d.is_empty()) {
        part.disposition = Some(lower(disposition.first()));
        part.disposition_parameters = params(disposition.get(1));
    }
    part.language = match rest.next() {
        Some(Token::List(items)) => items.iter().map(|t| lower(Some(t))).collect(),
        None | Some(Token::Nil) => Vec::new(),
        Some(other) => vec![lower(Some(other))],
    };
    part.location = field(rest.next());
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::parse;

    fn fetch_items(line: &str) -> Vec<Token> {
        let response = parse(line.as_bytes(), Vec::new()).unwrap();
        response.attributes[1].as_list().unwrap().to_vec()
    }

    #[test]
    fn envelope_with_groups_and_encoded_words() {
        let items = fetch_items(
            "* 1 FETCH (ENVELOPE (\"Mon, 6 Oct 2025 10:00:00 +0000\" \"=?UTF-8?Q?Tere_t=C3=A4na?=\" ((\"\\\"Andris\\\"\" NIL \"andris\" \"example.com\")) NIL NIL ((NIL NIL \"undisclosed-recipients\" NIL)(NIL NIL NIL NIL)) NIL NIL NIL \"<id@example.com>\"))",
        );
        let envelope = parse_envelope(items[1].as_list().unwrap());
        assert_eq!(envelope.subject.as_deref(), Some("Tere täna"));
        assert_eq!(
            envelope.from,
            vec![Address {
                name: "Andris".into(),
                address: "andris@example.com".into()
            }]
        );
        assert_eq!(
            envelope.to,
            vec![Address {
                name: "undisclosed-recipients".into(),
                address: String::new()
            }]
        );
        assert_eq!(envelope.message_id.as_deref(), Some("<id@example.com>"));
        assert_eq!(envelope.timestamp(), Some(1_759_744_800));
        assert!(envelope.cc.is_empty() && envelope.in_reply_to.is_none());
    }

    #[test]
    fn multipart_structure() {
        let items = fetch_items(
            "* 1 FETCH (BODYSTRUCTURE ((\"text\" \"plain\" (\"charset\" \"utf-8\") NIL NIL \"7bit\" 12 1 NIL NIL NIL NIL)(\"application\" \"pdf\" (\"name\" \"=?UTF-8?Q?=C3=B5.pdf?=\") NIL NIL \"base64\" 100 NIL (\"attachment\" (\"filename*\" \"utf-8''%C3%B5.pdf\")) NIL NIL) \"mixed\" (\"boundary\" \"b1\") NIL NIL NIL))",
        );
        let structure = parse_body_structure(items[1].as_list().unwrap());
        assert_eq!(structure.content_type, "multipart/mixed");
        assert_eq!(structure.parameters["boundary"], "b1");
        assert_eq!(structure.children.len(), 2);
        let text = &structure.children[0];
        assert_eq!(
            (text.part.as_deref(), text.content_type.as_str()),
            (Some("1"), "text/plain")
        );
        assert_eq!((text.size, text.line_count), (Some(12), Some(1)));
        let pdf = &structure.children[1];
        assert_eq!(pdf.part.as_deref(), Some("2"));
        assert_eq!(pdf.parameters["name"], "õ.pdf");
        assert_eq!(pdf.disposition.as_deref(), Some("attachment"));
        assert_eq!(pdf.disposition_parameters["filename"], "õ.pdf");
    }
}
