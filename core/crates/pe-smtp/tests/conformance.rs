//! The encoders and the message builder against nodemailer: tests/fixtures/nodemailer-cases.json holds what
//! nodemailer makes of the same inputs (see generate-nodemailer-cases.mjs).

use std::sync::LazyLock;

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use pe_mime::Address;
use pe_mime::parser::{ParsedAddress, parse_addresses};
use pe_smtp::address::format_addresses;
use pe_smtp::encoding::*;
use pe_smtp::{Attachment, Message, build_with};
use serde_json::Value;

static CASES: LazyLock<Value> =
    LazyLock::new(|| serde_json::from_str(include_str!("fixtures/nodemailer-cases.json")).unwrap());

fn cases(kind: &str) -> &'static [Value] {
    CASES[kind].as_array().unwrap()
}

fn text(value: &Value) -> &str {
    value.as_str().unwrap()
}

/// Every case, the failures listed together
fn check(kind: &str, mut compare: impl FnMut(&Value) -> Vec<(String, String, String)>) {
    let mut failures = Vec::new();
    for case in cases(kind) {
        for (what, ours, theirs) in compare(case) {
            if ours != theirs {
                failures.push(format!(
                    "{what} of {}:\n  ours:   {ours:?}\n  theirs: {theirs:?}",
                    case["input"]
                ));
            }
        }
    }
    assert!(
        failures.is_empty(),
        "{} {kind} differences:\n{}",
        failures.len(),
        failures.join("\n")
    );
}

#[test]
fn quoted_printable() {
    check("qp", |case| {
        let input = text(&case["input"]);
        let encoded = qp_encode(input.as_bytes());
        vec![
            ("encode".into(), encoded.clone(), text(&case["encoded"]).into()),
            ("wrap".into(), qp_wrap(&encoded, 76), text(&case["wrapped"]).into()),
        ]
    });
}

#[test]
fn base64_lines() {
    check("base64", |case| {
        let ours = base64_wrap(&base64_encode(text(&case["input"]).as_bytes()), 76);
        vec![("wrap".into(), ours, text(&case["wrapped"]).into())]
    });
}

#[test]
fn encoded_words() {
    check("words", |case| {
        let input = text(&case["input"]);
        let encoding = text_encoding(input);
        vec![
            ("encoding".into(), encoding.to_string(), text(&case["encoding"]).into()),
            ("Q".into(), encode_word(input, 'Q', 0), text(&case["q"]).into()),
            ("B".into(), encode_word(input, 'B', 0), text(&case["b"]).into()),
            ("Q 52".into(), encode_word(input, 'Q', 52), text(&case["q52"]).into()),
            ("B 52".into(), encode_word(input, 'B', 52), text(&case["b52"]).into()),
            (
                "words".into(),
                encode_words(input, encoding, 52, true),
                text(&case["words"]).into(),
            ),
            ("header".into(), encode_header_text(input), text(&case["header"]).into()),
        ]
    });
}

#[test]
fn folding() {
    check("fold", |case| {
        vec![(
            "fold".into(),
            fold_lines(text(&case["input"]), 76, false),
            text(&case["folded"]).into(),
        )]
    });
}

#[test]
fn parameters() {
    check("params", |case| {
        let input = text(&case["input"]);
        let theirs: Vec<String> = case["param"]
            .as_array()
            .unwrap()
            .iter()
            .map(|p| format!("{}={}", text(&p["key"]), text(&p["value"])))
            .collect();
        let ours: Vec<String> = build_header_param("filename", input, 50)
            .into_iter()
            .map(|(k, v)| format!("{k}={v}"))
            .collect();
        vec![
            (
                "value".into(),
                build_header_value("attachment", &[("filename", input)]),
                text(&case["value"]).into(),
            ),
            ("param".into(), ours.join("; "), theirs.join("; ")),
        ]
    });
}

#[test]
fn display_names() {
    check("names", |case| {
        let input = text(&case["input"]);
        vec![("name".into(), encode_address_name(input), text(&case["encoded"]).into())]
    });
}

fn address(value: &Value) -> ParsedAddress {
    match value.get("group") {
        Some(group) => ParsedAddress::Group {
            name: text(&value["name"]).into(),
            members: group
                .as_array()
                .unwrap()
                .iter()
                .map(|m| Address {
                    name: text(&m["name"]).into(),
                    address: text(&m["address"]).into(),
                })
                .collect(),
        },
        None => ParsedAddress::Mailbox(Address {
            name: text(&value["name"]).into(),
            address: text(&value["address"]).into(),
        }),
    }
}

#[test]
fn addresses() {
    check("addresses", |case| {
        let list: Vec<ParsedAddress> = case["input"].as_array().unwrap().iter().map(address).collect();
        vec![(
            "addresses".into(),
            format_addresses(&list),
            text(&case["encoded"]).into(),
        )]
    });
}

/// nodemailer leaves line breaks of 7bit text as they are; SMTP sends CRLF, as the Rust builder writes
fn crlf(raw: &[u8]) -> String {
    String::from_utf8_lossy(raw).replace("\r\n", "\n").replace('\n', "\r\n")
}

fn list(value: &Value) -> Vec<ParsedAddress> {
    match value {
        Value::Null => Vec::new(),
        Value::Array(items) => items.iter().flat_map(|v| parse_addresses(text(v))).collect(),
        other => parse_addresses(text(other)),
    }
}

#[test]
fn messages() {
    let mut failures = Vec::new();
    for case in cases("messages") {
        let mail = &case["mail"];
        let from = match list(&mail["from"]).pop() {
            Some(ParsedAddress::Mailbox(from)) => from,
            _ => panic!("no from"),
        };
        let message = Message {
            from,
            to: list(&mail["to"]),
            cc: list(&mail["cc"]),
            subject: text(&mail["subject"]).into(),
            text: mail["text"].as_str().map(str::to_string),
            html: mail["html"].as_str().map(str::to_string),
            in_reply_to: mail["inReplyTo"].as_str().map(str::to_string),
            references: mail["references"]
                .as_array()
                .map(|r| r.iter().map(|v| text(v).to_string()).collect())
                .unwrap_or_default(),
            attachments: mail["attachments"]
                .as_array()
                .map(|list| {
                    list.iter()
                        .map(|a| Attachment {
                            filename: text(&a["filename"]).into(),
                            content_type: text(&a["contentType"]).into(),
                            content: STANDARD.decode(text(&a["content"])).unwrap(),
                            content_id: a["cid"].as_str().map(str::to_string),
                        })
                        .collect()
                })
                .unwrap_or_default(),
            date: 1_759_744_800,
            message_id: "<fixed@example.com>".into(),
            ..Default::default()
        };
        let ours = build_with(&message, "b0b0b0b0b0b0b0b0");
        let theirs = crlf(&STANDARD.decode(text(&case["raw"])).unwrap());
        let ours = String::from_utf8(ours.raw).unwrap();
        if ours != theirs {
            failures.push(format!("{}:\n--- ours\n{ours}\n--- theirs\n{theirs}", case["name"]));
        }
    }
    assert!(failures.is_empty(), "{}", failures.join("\n"));
}
