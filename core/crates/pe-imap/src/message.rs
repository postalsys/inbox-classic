//! What FETCH tells about a message: the ENVELOPE and the BODYSTRUCTURE, decoded into structs.
//! A port of imapflow's `parseEnvelope` and `parseBodystructure`.

use std::collections::BTreeMap;

use pe_mime::{decode_params, decode_words};

use crate::types::Token;

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Address {
    pub name: String,
    /// Empty for the name of an RFC 5322 group
    pub address: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Envelope {
    /// The Date header as sent, see [`pe_mime::date::parse_date`]
    pub date: Option<String>,
    pub subject: Option<String>,
    pub from: Vec<Address>,
    pub sender: Vec<Address>,
    pub reply_to: Vec<Address>,
    pub to: Vec<Address>,
    pub cc: Vec<Address>,
    pub bcc: Vec<Address>,
    pub in_reply_to: Option<String>,
    pub message_id: Option<String>,
}

impl Envelope {
    /// The Date header in seconds since the Unix epoch
    pub fn timestamp(&self) -> Option<i64> {
        self.date.as_deref().and_then(pe_mime::date::parse_date)
    }
}

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

fn addresses(token: Option<&Token>) -> Vec<Address> {
    let Some(list) = token.and_then(Token::as_list) else {
        return Vec::new();
    };
    list.iter()
        .filter_map(Token::as_list)
        .filter_map(|fields| {
            let name = decode_text(text(fields.first()));
            let mailbox = text(fields.get(2)).unwrap_or_default();
            let host = text(fields.get(3)).unwrap_or_default();
            // a NIL host is RFC 5322 group syntax: the mailbox holds the group name, a NIL mailbox
            // ends the group. Joining the fields would invent an address that was never there.
            let address = if host.is_empty() {
                let name = if name.is_empty() && !mailbox.is_empty() {
                    decode_text(Some(mailbox))
                } else {
                    name
                };
                Address {
                    name,
                    address: String::new(),
                }
            } else {
                Address {
                    name,
                    address: format!("{mailbox}@{host}"),
                }
            };
            (!address.name.is_empty() || !address.address.is_empty()).then_some(address)
        })
        .collect()
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
    walk(node, &[])
}

fn walk(node: &[Token], path: &[u32]) -> BodyStructure {
    let mut part = BodyStructure {
        part: (!path.is_empty()).then(|| path.iter().map(u32::to_string).collect::<Vec<_>>().join(".")),
        ..Default::default()
    };
    let mut i = 0;
    if matches!(node.first(), Some(Token::List(_))) {
        // multipart: the parts, then the subtype and the extension data
        while let Some(Token::List(child)) = node.get(i) {
            let mut child_path = path.to_vec();
            child_path.push(i as u32 + 1);
            part.children.push(walk(child, &child_path));
            i += 1;
        }
        part.content_type = format!("multipart/{}", lower(node.get(i)));
        i += 1;
        if i < node.len() {
            part.parameters = params(node.get(i));
            i += 1;
        }
    } else {
        i = single_part(&mut part, node, path);
    }
    extension_fields(&mut part, node, i);
    part
}

/// The fields of a non-multipart part, returns the index of its extension data
fn single_part(part: &mut BodyStructure, node: &[Token], path: &[u32]) -> usize {
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
        part.envelope = match node.get(i) {
            Some(Token::List(fields)) => Some(Box::new(parse_envelope(fields))),
            None | Some(Token::Nil) => None,
            Some(other) => Some(Box::new(parse_envelope(std::slice::from_ref(other)))),
        };
        match node.get(i + 1) {
            Some(Token::List(child)) => part.children.push(walk(child, path)),
            None | Some(Token::Nil) => {}
            Some(other) => part.children.push(walk(std::slice::from_ref(other), path)),
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
    i
}

/// Disposition, language and location, shared by multipart and other parts
fn extension_fields(part: &mut BodyStructure, node: &[Token], mut i: usize) {
    if i < node.len() {
        if let Some(disposition) = node[i].as_list().filter(|d| !d.is_empty()) {
            part.disposition = Some(lower(disposition.first()));
            part.disposition_parameters = params(disposition.get(1));
        }
        i += 1;
    }
    if i < node.len() {
        part.language = match &node[i] {
            Token::List(items) => items.iter().map(|t| lower(Some(t))).collect(),
            Token::Nil => Vec::new(),
            other => vec![lower(Some(other))],
        };
        i += 1;
    }
    if i < node.len() {
        part.location = field(node.get(i));
    }
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
