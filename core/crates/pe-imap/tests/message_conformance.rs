//! ENVELOPE, BODYSTRUCTURE and modified UTF-7 against imapflow: tests/fixtures/message-cases.json
//! holds what imapflow makes of them (see generate-message-cases.mjs there).

use pe_imap::{Address, BodyStructure, Envelope, Framer, parse_body_structure, parse_envelope, utf7};
use serde_json::{Map, Value, json};

fn cases() -> Value {
    serde_json::from_str(include_str!("fixtures/message-cases.json")).unwrap()
}

/// Sets `key` when the value is present, as imapflow leaves absent fields out
fn put(out: &mut Map<String, Value>, key: &str, value: Option<Value>) {
    if let Some(value) = value {
        out.insert(key.into(), value);
    }
}

fn addresses(list: &[Address]) -> Option<Value> {
    (!list.is_empty()).then(|| {
        json!(
            list.iter()
                .map(|a| json!({ "name": a.name, "address": a.address }))
                .collect::<Vec<_>>()
        )
    })
}

fn envelope(envelope: &Envelope) -> Value {
    let mut out = Map::new();
    // imapflow gives a Date for a date JavaScript can read and the text otherwise. JavaScript also
    // reads a bare year ("6643", from a malformed structure), which no Date header is; the year
    // is passed through for the comparison only.
    let date = envelope.date.as_ref().map(|date| match envelope.timestamp() {
        Some(timestamp) => json!(pe_mime::date::to_iso(timestamp)),
        None if date.len() == 4 && date.bytes().all(|c| c.is_ascii_digit()) => {
            json!(format!("{date}-01-01T00:00:00.000Z"))
        }
        None => json!(date),
    });
    put(&mut out, "date", date);
    put(&mut out, "subject", envelope.subject.as_ref().map(|s| json!(s)));
    for (key, list) in [
        ("from", &envelope.from),
        ("sender", &envelope.sender),
        ("replyTo", &envelope.reply_to),
        ("to", &envelope.to),
        ("cc", &envelope.cc),
        ("bcc", &envelope.bcc),
    ] {
        put(&mut out, key, addresses(list));
    }
    put(&mut out, "inReplyTo", envelope.in_reply_to.as_ref().map(|s| json!(s)));
    put(&mut out, "messageId", envelope.message_id.as_ref().map(|s| json!(s)));
    Value::Object(out)
}

fn structure(node: &BodyStructure) -> Value {
    let mut out = Map::new();
    let text = |value: &Option<String>| value.as_ref().map(|s| json!(s));
    put(&mut out, "part", text(&node.part));
    out.insert("type".into(), json!(node.content_type));
    put(
        &mut out,
        "parameters",
        (!node.parameters.is_empty()).then(|| json!(node.parameters)),
    );
    put(&mut out, "id", text(&node.id));
    put(&mut out, "description", text(&node.description));
    put(&mut out, "encoding", text(&node.encoding));
    put(&mut out, "size", node.size.map(|s| json!(s)));
    put(&mut out, "envelope", node.envelope.as_deref().map(envelope));
    put(&mut out, "lineCount", node.line_count.map(|s| json!(s)));
    put(&mut out, "md5", text(&node.md5));
    put(&mut out, "disposition", text(&node.disposition));
    put(
        &mut out,
        "dispositionParameters",
        (!node.disposition_parameters.is_empty()).then(|| json!(node.disposition_parameters)),
    );
    put(
        &mut out,
        "language",
        (!node.language.is_empty()).then(|| json!(node.language)),
    );
    put(&mut out, "location", text(&node.location));
    put(
        &mut out,
        "childNodes",
        (!node.children.is_empty()).then(|| json!(node.children.iter().map(structure).collect::<Vec<_>>())),
    );
    Value::Object(out)
}

/// imapflow keeps an empty parameter object, the Rust side has no such state
fn drop_empty_objects(value: &mut Value) {
    match value {
        Value::Object(map) => {
            map.retain(|_, v| !matches!(v, Value::Object(o) if o.is_empty()));
            map.values_mut().for_each(drop_empty_objects);
        }
        Value::Array(items) => items.iter_mut().for_each(drop_empty_objects),
        _ => {}
    }
}

#[test]
fn envelopes_and_structures_match_imapflow() {
    let mut failures = Vec::new();
    for case in cases()["fetches"].as_array().unwrap() {
        let input = case["input"].as_str().unwrap();
        let mut framed = Vec::new();
        Framer::default()
            .push(format!("{input}\r\n").as_bytes(), &mut framed)
            .unwrap();
        let response = framed.remove(0).parse().unwrap();
        let items = response.attributes[1].as_list().unwrap();
        for pair in items.chunks(2) {
            let key = pair[0].text().unwrap().to_ascii_uppercase();
            let fields = || pair[1].as_list().unwrap();
            let (name, actual) = match key.as_str() {
                "ENVELOPE" => ("envelope", envelope(&parse_envelope(fields()))),
                "BODYSTRUCTURE" => ("bodystructure", structure(&parse_body_structure(fields()))),
                _ => continue,
            };
            let mut expected = case[name].clone();
            drop_empty_objects(&mut expected);
            if actual != expected {
                failures.push(format!("{input}\n  expected {expected}\n  actual   {actual}"));
            }
        }
    }
    assert!(failures.is_empty(), "{}", failures.join("\n"));
}

#[test]
fn mailbox_names_match_imapflow() {
    for case in cases()["names"].as_array().unwrap() {
        let name = case["name"].as_str().unwrap();
        let encoded = case["encoded"].as_str().unwrap();
        assert_eq!(utf7::encode(name), encoded);
        assert_eq!(utf7::decode(encoded), case["decoded"].as_str().unwrap());
    }
}
