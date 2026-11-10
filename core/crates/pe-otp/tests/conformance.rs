//! The port against otp-detect. tests/fixtures/cases.json holds, for otp-detect's own test inputs,
//! hand-written synthetic emails (inputs.json) and seeded random messages, every candidate
//! occurrence with its feature vector and score, scoreCandidates() and detectOtp().
//! tests/fixtures/generate.mjs writes it from a built otp-detect checkout.
//!
//! Feature vectors must be identical (NaN, written as null, included), scores within 1e-9 (the
//! sigmoid's exp may differ from V8's in the last bit), and the answer the same.

use std::sync::LazyLock;

use pe_otp::features::FEATURE_NAMES;
use pe_otp::{MODEL, MessageInput, OtpCandidate, analyze, detect_otp, score_candidates};
use serde_json::Value;

static CASES: LazyLock<Value> =
    LazyLock::new(|| serde_json::from_str(include_str!("fixtures/cases.json")).expect("cases.json"));

const TOLERANCE: f64 = 1e-9;

fn number(value: &Value) -> f64 {
    value.as_f64().unwrap_or(f64::NAN)
}

fn same_feature(expected: &Value, actual: f64) -> bool {
    let expected = number(expected);
    (expected.is_nan() && actual.is_nan()) || expected == actual
}

fn input(value: &Value) -> MessageInput<'_> {
    MessageInput {
        subject: value["subject"].as_str(),
        text: value["text"].as_str(),
        html: value["html"].as_str(),
    }
}

fn kind_name(kind: pe_otp::candidates::CandidateKind) -> &'static str {
    use pe_otp::candidates::CandidateKind::*;
    match kind {
        Token => "token",
        DashedPart => "dashed-part",
        Grouped => "grouped",
        Spaced => "spaced",
    }
}

fn check_candidate(name: &str, what: &str, expected: &Value, actual: &OtpCandidate, errors: &mut Vec<String>) {
    if expected["code"].as_str() != Some(&actual.code)
        || expected["raw"].as_str() != Some(&actual.raw)
        || expected["source"].as_str() != Some(actual.source.name())
        || (number(&expected["score"]) - actual.score).abs() > TOLERANCE
    {
        errors.push(format!("{name}: {what}: expected {expected}, got {actual:?}"));
    }
}

#[test]
fn the_fixtures_were_made_with_this_feature_list_and_threshold() {
    let names: Vec<&str> = CASES["featureNames"]
        .as_array()
        .unwrap()
        .iter()
        .map(|n| n.as_str().unwrap())
        .collect();
    assert_eq!(names, FEATURE_NAMES);
    assert_eq!(number(&CASES["threshold"]), MODEL.threshold);
}

#[test]
fn matches_otp_detect() {
    let cases = CASES["cases"].as_array().unwrap();
    assert!(cases.len() >= 100, "{} cases", cases.len());
    let mut errors = Vec::new();
    for case in cases {
        let name = case["name"].as_str().unwrap();
        let input = input(&case["input"]);

        let expected = case["occurrences"].as_array().unwrap();
        let actual = analyze(&input);
        if expected.len() != actual.len() {
            let codes: Vec<&str> = actual.iter().map(|o| o.candidate.code.as_str()).collect();
            errors.push(format!(
                "{name}: {} occurrences, expected {}: {codes:?}",
                actual.len(),
                expected.len()
            ));
            continue;
        }
        for (i, (e, a)) in expected.iter().zip(&actual).enumerate() {
            if e["code"].as_str() != Some(&a.candidate.code)
                || e["raw"].as_str() != Some(&a.candidate.raw)
                || e["kind"].as_str() != Some(kind_name(a.candidate.kind))
                || e["source"].as_str() != Some(a.source.name())
            {
                errors.push(format!("{name}: occurrence {i}: expected {e}, got {:?}", a.candidate));
                continue;
            }
            for (f, (ev, av)) in e["features"].as_array().unwrap().iter().zip(&a.features).enumerate() {
                if !same_feature(ev, *av) {
                    errors.push(format!(
                        "{name}: occurrence {i} ({}): {}: expected {ev}, got {av}",
                        a.candidate.code, FEATURE_NAMES[f]
                    ));
                }
            }
            let score = MODEL.predict(&a.features);
            if (number(&e["score"]) - score).abs() > TOLERANCE {
                errors.push(format!("{name}: occurrence {i}: score {} != {score}", e["score"]));
            }
        }

        let expected = case["candidates"].as_array().unwrap();
        let actual = score_candidates(&input);
        if expected.len() != actual.len() {
            errors.push(format!(
                "{name}: {} scored codes, expected {}",
                actual.len(),
                expected.len()
            ));
        } else {
            for (i, (e, a)) in expected.iter().zip(&actual).enumerate() {
                check_candidate(name, &format!("scored code {i}"), e, a, &mut errors);
            }
        }

        match (&case["answer"], detect_otp(&input)) {
            (Value::Null, None) => {}
            (e, Some(a)) if !e.is_null() => check_candidate(name, "answer", e, &a, &mut errors),
            (e, a) => errors.push(format!("{name}: answer: expected {e}, got {a:?}")),
        }
    }
    assert!(
        errors.is_empty(),
        "{} differences:\n{}",
        errors.len(),
        errors.join("\n")
    );
}
