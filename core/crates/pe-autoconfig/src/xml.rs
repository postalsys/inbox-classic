//! A walk over an XML document that hands each element's path and text to a visitor, for the autodiscover
//! parsers. Element names are their local names (prefixes dropped) in lowercase, so `s:Envelope` and `Envelope`
//! read the same. Bounded: a document deeper, longer or with more text in one element than any real response is
//! refused.

use quick_xml::Reader;
use quick_xml::events::{BytesStart, Event};

/// Deeper than any response this crate reads
const MAX_DEPTH: usize = 32;
/// The text of one element
const MAX_TEXT: usize = 4096;
/// The events of one document: an autodiscover response with dozens of servers is a few thousand
const MAX_EVENTS: usize = 50_000;

pub(crate) enum Node<'a> {
    /// An element starts; the path ends with its name
    Open(&'a [String]),
    /// An element ends, with its text trimmed
    Close(&'a [String], &'a str),
}

fn name_of(tag: &BytesStart) -> String {
    tag.local_name().into_inner().to_ascii_lowercase()
}

/// Walks `xml`; None when it is not well-formed (an element left open, a mismatched end tag) or too large
pub(crate) fn walk(xml: &str, mut visit: impl FnMut(Node)) -> Option<()> {
    let xml = xml.trim_start_matches('\u{feff}');
    let mut reader = Reader::from_str(xml);
    let mut path: Vec<String> = Vec::new();
    let mut text = String::new();
    for _ in 0..MAX_EVENTS {
        match reader.read_event().ok()? {
            Event::Start(tag) => {
                if path.len() >= MAX_DEPTH {
                    return None;
                }
                path.push(name_of(&tag));
                text.clear();
                visit(Node::Open(&path));
            }
            Event::Empty(tag) => {
                if path.len() >= MAX_DEPTH {
                    return None;
                }
                path.push(name_of(&tag));
                visit(Node::Open(&path));
                visit(Node::Close(&path, ""));
                path.pop();
                text.clear();
            }
            Event::Text(part) => text.push_str(&part),
            Event::CData(part) => text.push_str(&part),
            Event::GeneralRef(reference) => {
                if reference.is_char_ref() {
                    text.extend(reference.resolve_char_ref().ok().flatten());
                } else if let Some(resolved) = quick_xml::escape::resolve_predefined_entity(&reference) {
                    text.push_str(resolved);
                }
            }
            Event::End(_) => {
                // quick-xml has already checked that the end tag matches
                let value = std::mem::take(&mut text);
                visit(Node::Close(&path, value.trim()));
                path.pop()?;
            }
            Event::Eof => return path.is_empty().then_some(()),
            _ => {}
        }
        if text.len() > MAX_TEXT {
            return None;
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    fn closes(xml: &str) -> Option<Vec<String>> {
        let mut out = Vec::new();
        walk(xml, |node| {
            if let Node::Close(path, text) = node {
                out.push(format!("{}={text}", path.join("/")));
            }
        })?;
        Some(out)
    }

    #[test]
    fn paths_and_text() {
        let found = closes(
            "<?xml version=\"1.0\"?><s:Env xmlns:s=\"x\"><s:Body><A>a&amp;<![CDATA[b]]>&#99;</A><B/></s:Body></s:Env>",
        );
        assert_eq!(found.unwrap(), ["env/body/a=a&bc", "env/body/b=", "env/body=", "env="]);
        // a byte order mark is no reason to refuse a document
        assert!(closes("\u{feff}<a>x</a>").is_some());
    }

    #[test]
    fn refuses_what_is_not_a_document() {
        assert_eq!(closes("<a><b>"), None);
        assert_eq!(closes("<a></b>"), None);
        assert_eq!(closes(&"<a>".repeat(40)), None);
        assert_eq!(closes(&format!("<a>{}</a>", "x".repeat(MAX_TEXT + 1))), None);
        // many small elements: bounded
        assert_eq!(closes(&format!("<a>{}</a>", "<b/>".repeat(MAX_EVENTS))), None);
    }
}
