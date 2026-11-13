//! The search index's side of a message: what the store's full-text index keeps of it, read with the message parser.
//! The store keeps no parser: the core reads and hands the store the text. Two ways in: a source cached when a message
//! is opened (its text, everyone it names, its files), and the text parts the workers fetch for every message, newest
//! first, so mail is found by its text without being downloaded.

use pe_mime::parser::{self, ParsedAddress};
use pe_store::{IndexText, Store};

/// The most of a message's text the index keeps: enough for any letter, not a book pasted in
const MAX_BODY: usize = 256 * 1024;

/// How many sources are read in one transaction
const BATCH: usize = 25;

/// How much of each text part a worker fetches for the index
pub(crate) const PART_LIMIT: u64 = 64 * 1024;

/// How many messages a worker fetches the text of at a time, between its other work
pub(crate) const TEXT_BATCH: usize = 50;

/// A header value from BODYSTRUCTURE as the parser's input: only what a type, charset or encoding name has in it, so
/// nothing a server sends can make another header of it
fn header_value(value: &str) -> String {
    value
        .chars()
        .filter(|c| c.is_ascii_alphanumeric() || matches!(c, '/' | '-' | '_' | '.' | '+' | ':'))
        .collect()
}

/// The text of a message's text parts, each decoded by the parser as the part it is (its type, charset and transfer
/// encoding), HTML as text, at most [`MAX_BODY`] of it
pub(crate) fn parts_text(parts: &[pe_sync::TextPart]) -> String {
    let mut text = String::new();
    for part in parts {
        let charset = part.charset.as_deref().map(header_value).filter(|c| !c.is_empty());
        let mut raw = format!(
            "Content-Type: {}{}\r\nContent-Transfer-Encoding: {}\r\n\r\n",
            header_value(&part.content_type),
            charset.map(|c| format!("; charset={c}")).unwrap_or_default(),
            part.encoding
                .as_deref()
                .map(header_value)
                .unwrap_or_else(|| "7bit".into())
        )
        .into_bytes();
        raw.extend_from_slice(&part.bytes);
        let Ok(message) = parser::parse(&raw) else {
            continue;
        };
        let decoded = match (message.text, message.html) {
            (Some(plain), _) => plain,
            (None, Some(html)) => parser::html_to_text(&html),
            (None, None) => continue,
        };
        let decoded = decoded.trim();
        if decoded.is_empty() {
            continue;
        }
        if !text.is_empty() {
            text.push('\n');
        }
        text.push_str(decoded);
        if text.len() >= MAX_BODY {
            break;
        }
    }
    truncate(&mut text);
    text
}

/// At most [`MAX_BODY`] bytes, cut at a character
fn truncate(text: &mut String) {
    if text.len() > MAX_BODY {
        let mut end = MAX_BODY;
        while !text.is_char_boundary(end) {
            end -= 1;
        }
        text.truncate(end);
    }
}

/// Names and addresses, decoded, separated by spaces
fn people(lists: &[&[ParsedAddress]]) -> String {
    let words: Vec<&str> = lists
        .iter()
        .flat_map(|list| list.iter())
        .flat_map(|entry| {
            let group = match entry {
                ParsedAddress::Group { name, .. } => Some(name.as_str()),
                ParsedAddress::Mailbox(_) => None,
            };
            group.into_iter().chain(
                entry
                    .mailboxes()
                    .iter()
                    .flat_map(|a| [a.name.as_str(), a.address.as_str()]),
            )
        })
        .filter(|word| !word.is_empty())
        .collect();
    words.join(" ")
}

/// What the index keeps of a source, None when the parser panicked on it: a message it can not read ends no worker,
/// and the callers mark it (not downloaded or indexed again in the background)
pub(crate) fn read_index_text(source: &[u8]) -> Option<IndexText> {
    std::panic::catch_unwind(|| index_text(source)).ok()
}

/// What the index keeps of a source; nothing but an empty body when it does not parse
pub(crate) fn index_text(source: &[u8]) -> IndexText {
    let Ok(message) = parser::parse(source) else {
        return IndexText::default();
    };
    let one = |address: &Option<ParsedAddress>| address.iter().cloned().collect::<Vec<_>>();
    let (from, sender) = (one(&message.from), one(&message.sender));
    let attachments: Vec<&parser::Attachment> = message.attachments.iter().filter(|a| !a.related).collect();
    let names: Vec<&str> = attachments.iter().filter_map(|a| a.filename.as_deref()).collect();
    let mut body = match (&message.text, &message.html) {
        (Some(text), _) => text.clone(),
        (None, Some(html)) => parser::html_to_text(html),
        (None, None) => String::new(),
    };
    truncate(&mut body);
    IndexText {
        sender_people: people(&[&from, &sender, &message.reply_to]),
        recipient_people: people(&[&message.to, &message.cc, &message.bcc]),
        attachment_names: names.join("\n"),
        attachment_count: attachments.len() as u32,
        body,
    }
}

/// Indexes the cached sources the index does not have the text of yet; how many
pub(crate) fn index_pending(store: &mut Store) -> pe_store::Result<usize> {
    let mut done = 0;
    loop {
        let pending = store.sources_to_index(BATCH)?;
        if pending.is_empty() {
            return Ok(done);
        }
        done += pending.len();
        store.transaction(|store| {
            for (message, source) in &pending {
                store.set_indexed(*message, &read_index_text(source).unwrap_or_default())?;
            }
            Ok(())
        })?;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_what_the_index_keeps() {
        let source = "From: =?utf-8?q?=C3=95ie?= <oie@example.com>\r\nTo: Team: a@example.com, B <b@example.com>;\r\n\
                      Cc: carol@example.com\r\nSubject: Report\r\nContent-Type: multipart/mixed; boundary=m\r\n\r\n\
                      --m\r\nContent-Type: text/html\r\n\r\n<p>The <b>zebra</b> crossing</p>\r\n\
                      --m\r\nContent-Type: application/pdf; name*=utf-8''aruanne%20%C3%B5htu.pdf\r\n\
                      Content-Transfer-Encoding: base64\r\n\r\nJVBERg==\r\n--m--\r\n";
        let text = index_text(source.as_bytes());
        assert_eq!(text.sender_people, "Õie oie@example.com");
        assert_eq!(
            text.recipient_people,
            "Team a@example.com B b@example.com carol@example.com"
        );
        assert_eq!(
            (text.attachment_names.as_str(), text.attachment_count),
            ("aruanne õhtu.pdf", 1)
        );
        assert!(text.body.contains("zebra crossing"), "{}", text.body);
        // not a message: nothing but the fact that it was read
        assert_eq!(index_text(b"\xff\xfe"), index_text(b"\xff\xfe"));
    }

    #[test]
    fn decodes_fetched_text_parts() {
        let part =
            |content_type: &str, charset: Option<&str>, encoding: Option<&str>, bytes: &[u8]| pe_sync::TextPart {
                content_type: content_type.into(),
                charset: charset.map(String::from),
                encoding: encoding.map(String::from),
                bytes: bytes.to_vec(),
            };
        let text = parts_text(&[
            part(
                "text/plain",
                Some("iso-8859-1"),
                Some("quoted-printable"),
                b"S=F5ber zebra=\r\ncrossing",
            ),
            part("text/html", Some("utf-8"), Some("base64"), b"PHA+R2lyYWZmZTwvcD4="),
        ]);
        assert_eq!(text, "Sõber zebracrossing\nGiraffe");
        // a part cut short by the fetch limit still decodes as far as it goes
        assert_eq!(
            parts_text(&[part("text/plain", None, Some("base64"), b"aGVsbG8gd29y")]),
            "hello wor"
        );
        // what a server sends can not add headers: a type made up of two is no HTML, a charset with a header in it
        // leaves the part plain text
        let two_types = part("text/plain\r\nContent-Type: text/html", None, None, b"plain <b>x</b>");
        assert_ne!(parts_text(&[two_types]), "plain x");
        let sneaky = part(
            "text/plain",
            Some("utf-8\r\nContent-Type: text/html"),
            None,
            b"plain <b>x</b>",
        );
        assert_eq!(parts_text(&[sneaky]), "plain <b>x</b>");
    }

    #[test]
    fn keeps_a_long_text_short_at_a_character() {
        let source = format!("Subject: x\r\n\r\n{}", "õ".repeat(MAX_BODY));
        let text = index_text(source.as_bytes());
        assert!(text.body.len() <= MAX_BODY && text.body.chars().all(|c| c == 'õ'));
    }
}
