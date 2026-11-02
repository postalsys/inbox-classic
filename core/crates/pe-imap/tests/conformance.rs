//! The port against imapflow: tests/fixtures/parser-cases.json holds what imapflow's ImapStream
//! and parser make of a set of responses (see generate-parser-cases.mjs there). The framer has to
//! split each response the same way, and the parser has to give the same tokens, or fail with the
//! same error code.

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use pe_imap::{Framer, Token, parse};
use serde_json::{Value, json};

fn decode(value: &Value) -> Vec<u8> {
    STANDARD.decode(value.as_str().unwrap()).unwrap()
}

fn text(bytes: &[u8]) -> String {
    String::from_utf8_lossy(bytes).into_owned()
}

fn to_json(token: &Token) -> Value {
    let node = |kind: &str, value: String| json!({ "type": kind, "value": value });
    match token {
        Token::Nil => Value::Null,
        Token::List(items) => Value::Array(items.iter().map(to_json).collect()),
        Token::String(value) => node("STRING", text(value)),
        Token::Literal(value) => node("LITERAL", text(value)),
        Token::Text(value) => node("TEXT", text(value)),
        Token::Sequence(value) => node("SEQUENCE", value.clone()),
        Token::Atom(atom) => {
            let mut out = node("ATOM", text(&atom.value));
            if let Some(section) = &atom.section {
                out["section"] = Value::Array(section.iter().map(to_json).collect());
            }
            if let Some(partial) = &atom.partial {
                out["partial"] = json!(partial);
            }
            out
        }
    }
}

#[test]
fn matches_imapflow() {
    let cases: Vec<Value> = serde_json::from_str(include_str!("fixtures/parser-cases.json")).unwrap();
    assert!(cases.len() > 150);
    let mut failures = Vec::new();
    for case in &cases {
        let input = case["input"].as_str().unwrap();
        let line = decode(&case["line"]);
        let literals: Vec<Vec<u8>> = case["literals"].as_array().unwrap().iter().map(decode).collect();

        let mut framed = Vec::new();
        Framer::default()
            .push(format!("{input}\r\n").as_bytes(), &mut framed)
            .unwrap();
        if framed.len() != 1 || framed[0].line != line || framed[0].literals != literals {
            failures.push(format!("framing {input:?}: {framed:?}"));
            continue;
        }

        let expected = &case["expected"];
        let actual = match parse(&line, literals) {
            Ok(response) => json!({
                "tag": response.tag,
                "command": response.command,
                "attributes": response.attributes.iter().map(to_json).collect::<Vec<_>>(),
                "numbers": response.numbers,
                "nullBytesRemoved": response.null_bytes_removed,
                "truncatedAttributes": response.truncated_attributes,
            }),
            Err(error) => json!({ "error": error.code }),
        };
        if &actual != expected {
            failures.push(format!("{input:?}\n  expected {expected}\n  actual   {actual}"));
        }
    }
    assert!(
        failures.is_empty(),
        "{} of {} cases differ:\n{}",
        failures.len(),
        cases.len(),
        failures.join("\n")
    );
}
