//! The port against libmime and imapflow: tests/fixtures/mime-cases.json holds what libmime's
//! decodeWords and imapflow's getStructuredParams make of a set of inputs (see
//! generate-mime-cases.mjs there).

use pe_mime::{decode_params, decode_words};
use serde_json::Value;

fn cases() -> Value {
    serde_json::from_str(include_str!("fixtures/mime-cases.json")).unwrap()
}

#[test]
fn words_match_libmime() {
    let mut failures = Vec::new();
    for case in cases()["words"].as_array().unwrap() {
        let input = case["input"].as_str().unwrap();
        let actual = decode_words(input);
        if actual != case["expected"].as_str().unwrap() {
            failures.push(format!("{input:?}: expected {:?}, got {actual:?}", case["expected"]));
        }
    }
    assert!(failures.is_empty(), "{}", failures.join("\n"));
}

#[test]
fn params_match_imapflow() {
    let mut failures = Vec::new();
    for case in cases()["params"].as_array().unwrap() {
        let flat: Vec<&str> = case["input"]
            .as_array()
            .unwrap()
            .iter()
            .map(|v| v.as_str().unwrap())
            .collect();
        let actual = decode_params(flat.chunks(2).map(|pair| (pair[0], pair[1])));
        let actual = serde_json::to_value(&actual).unwrap();
        if actual != case["expected"] {
            failures.push(format!("{flat:?}: expected {}, got {actual}", case["expected"]));
        }
    }
    assert!(failures.is_empty(), "{}", failures.join("\n"));
}
