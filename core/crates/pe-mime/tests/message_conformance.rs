//! The message parser against postal-mime: tests/fixtures/message-cases.json holds what
//! postal-mime makes of the messages its own tests parse, of its fixture files, of the inputs of
//! its address parser tests and of HTML and text conversions (see generate-message-cases.mjs).

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use pe_mime::parser::{self, Message, ParsedAddress, html_to_text, parse_addresses, text_to_html};
use serde_json::{Map, Value, json};

fn cases() -> Value {
    serde_json::from_str(include_str!("fixtures/message-cases.json")).unwrap()
}

fn address(address: &ParsedAddress) -> Value {
    match address {
        ParsedAddress::Mailbox { name, address } => json!({ "name": name, "address": address }),
        ParsedAddress::Group { name, members } => {
            json!({ "name": name, "group": members.iter().map(|(n, a)| json!({ "name": n, "address": a })).collect::<Vec<_>>() })
        }
    }
}

fn put(out: &mut Map<String, Value>, key: &str, value: Option<Value>) {
    if let Some(value) = value {
        out.insert(key.into(), value);
    }
}

fn list(addresses: &[ParsedAddress]) -> Option<Value> {
    (!addresses.is_empty()).then(|| json!(addresses.iter().map(address).collect::<Vec<_>>()))
}

fn message(message: &Message) -> Value {
    let mut out = Map::new();
    out.insert(
        "headers".into(),
        json!(
            message
                .headers
                .iter()
                .map(|h| json!({ "key": h.key, "originalKey": h.original_key, "value": h.value }))
                .collect::<Vec<_>>()
        ),
    );
    let text = |v: &Option<String>| v.as_ref().map(|s| json!(s));
    put(&mut out, "from", message.from.as_ref().map(address));
    put(&mut out, "sender", message.sender.as_ref().map(address));
    put(&mut out, "deliveredTo", text(&message.delivered_to));
    put(&mut out, "returnPath", text(&message.return_path));
    put(&mut out, "to", list(&message.to));
    put(&mut out, "cc", list(&message.cc));
    put(&mut out, "bcc", list(&message.bcc));
    put(&mut out, "replyTo", list(&message.reply_to));
    put(&mut out, "subject", text(&message.subject));
    put(&mut out, "messageId", text(&message.message_id));
    put(&mut out, "inReplyTo", text(&message.in_reply_to));
    put(&mut out, "references", text(&message.references));
    put(&mut out, "date", text(&message.date));
    put(&mut out, "html", text(&message.html));
    put(&mut out, "text", text(&message.text));
    let attachments: Vec<Value> = message
        .attachments
        .iter()
        .map(|a| {
            let mut entry = Map::new();
            entry.insert("filename".into(), json!(a.filename));
            entry.insert("mimeType".into(), json!(a.mime_type));
            entry.insert("disposition".into(), json!(a.disposition));
            put(&mut entry, "related", a.related.then_some(json!(true)));
            put(
                &mut entry,
                "rfc822DepthExceeded",
                a.rfc822_depth_exceeded.then_some(json!(true)),
            );
            put(&mut entry, "description", text(&a.description));
            put(&mut entry, "contentId", text(&a.content_id));
            put(&mut entry, "method", text(&a.method));
            entry.insert("content".into(), json!(STANDARD.encode(&a.content)));
            entry.insert("encoding".into(), json!("base64"));
            Value::Object(entry)
        })
        .collect();
    out.insert("attachments".into(), json!(attachments));
    Value::Object(out)
}

/// The keys of two objects that differ, for a readable failure
fn differences(expected: &Value, actual: &Value) -> String {
    match (expected, actual) {
        (Value::Object(e), Value::Object(a)) => e
            .keys()
            .chain(a.keys())
            .filter(|k| e.get(*k) != a.get(*k))
            .map(|k| format!("{k}: expected {} got {}", short(e.get(k)), short(a.get(k))))
            .collect::<std::collections::BTreeSet<_>>()
            .into_iter()
            .collect::<Vec<_>>()
            .join("; "),
        _ => format!("expected {} got {}", short(Some(expected)), short(Some(actual))),
    }
}

fn short(value: Option<&Value>) -> String {
    let text = value.map_or("(none)".into(), Value::to_string);
    if text.len() > 300 {
        format!(
            "{}...",
            &text[..text.char_indices().nth(300).map_or(text.len(), |(i, _)| i)]
        )
    } else {
        text
    }
}

#[test]
fn messages_match_postal_mime() {
    let mut failures = Vec::new();
    let cases = cases();
    let all = cases["messages"].as_array().unwrap();
    for (i, case) in all.iter().enumerate() {
        let raw = STANDARD.decode(case["raw"].as_str().unwrap()).unwrap();
        let expected = &case["expected"];
        let actual = match parser::parse(&raw) {
            Ok(parsed) => message(&parsed),
            Err(error) => json!({ "error": error.code }),
        };
        if &actual != expected {
            failures.push(format!("#{i}: {}", differences(expected, &actual)));
        }
    }
    assert!(
        failures.is_empty(),
        "{} of {} messages differ:\n{}",
        failures.len(),
        all.len(),
        failures.join("\n")
    );
}

#[test]
fn addresses_match_postal_mime() {
    let mut failures = Vec::new();
    for case in cases()["addresses"].as_array().unwrap() {
        let input = case["input"].as_str().unwrap();
        let actual = json!(parse_addresses(input).iter().map(address).collect::<Vec<_>>());
        if actual != case["expected"] {
            failures.push(format!(
                "{input:?}\n  expected {}\n  actual   {actual}",
                case["expected"]
            ));
        }
    }
    assert!(
        failures.is_empty(),
        "{} differ:\n{}",
        failures.len(),
        failures.join("\n")
    );
}

#[test]
fn conversions_match_postal_mime() {
    let cases = cases();
    for (name, convert) in [
        ("htmlToText", html_to_text as fn(&str) -> String),
        ("textToHtml", text_to_html),
    ] {
        for case in cases["conversions"][name].as_array().unwrap() {
            let input = case["input"].as_str().unwrap();
            assert_eq!(json!(convert(input)), case["expected"], "{name}({input:?})");
        }
    }
}
