//! The port against the JavaScript originals. tests/fixtures/classify-cases.json holds what
//! bounce-classifier makes of every string of its own test suite and a few more; detect-cases.json
//! what EmailEngine's bounceDetect() makes of its bounce fixtures (tests/fixtures/bounces) and of
//! the bounces its tests build inline. generate.mjs writes both from built checkouts.

use std::sync::LazyLock;

use pe_bounce::classify::{self, Blocklist, Classification};
use pe_bounce::{Label, detect};
use serde_json::Value;

static CLASSIFY: LazyLock<Value> =
    LazyLock::new(|| serde_json::from_str(include_str!("fixtures/classify-cases.json")).unwrap());
static DETECT: LazyLock<Value> =
    LazyLock::new(|| serde_json::from_str(include_str!("fixtures/detect-cases.json")).unwrap());

/// Fields where the port knowingly differs, as (case, field, reason). Keep this list short.
const KNOWN_DIFFERENCES: &[(&str, &str, &str)] = &[];

fn known(case: &str, field: &str) -> bool {
    KNOWN_DIFFERENCES.iter().any(|(c, f, _)| *c == case && *f == field)
}

const TOLERANCE: f64 = 1e-5;

fn label(value: &Value) -> Option<Label> {
    value
        .as_str()
        .map(|name| Label::from_name(name).unwrap_or_else(|| panic!("label {name}")))
}

fn blocklist_json(blocklist: &Option<Blocklist>) -> Value {
    let info =
        |b: &classify::BlocklistInfo| serde_json::json!({ "name": b.name, "type": b.kind.name(), "host": b.host });
    match blocklist {
        None => Value::Null,
        Some(Blocklist::One(b)) => info(b),
        Some(Blocklist::Several { lists, host }) => {
            serde_json::json!({ "lists": lists.iter().map(info).collect::<Vec<_>>(), "host": host })
        }
    }
}

fn check_classification(name: &str, expected: &Value, actual: &Classification, errors: &mut Vec<String>) {
    let mut fail = |field: &str, detail: String| {
        if !known(name, field) {
            errors.push(format!("{name}: {field}: {detail}"));
        }
    };
    if label(&expected["label"]) != Some(actual.label) {
        fail("label", format!("{} != {:?}", expected["label"], actual.label));
    }
    if label(&expected["modelLabel"]) != actual.model_label {
        fail(
            "modelLabel",
            format!("{} != {:?}", expected["modelLabel"], actual.model_label),
        );
    }
    if expected["action"].as_str() != Some(actual.action.name()) {
        fail("action", format!("{} != {:?}", expected["action"], actual.action));
    }
    let confidence = expected["confidence"].as_f64().unwrap();
    if (confidence - actual.confidence as f64).abs() > TOLERANCE {
        fail("confidence", format!("{confidence} != {}", actual.confidence));
    }
    for (i, l) in Label::ALL.iter().enumerate() {
        let score = expected["scores"][l.name()].as_f64().unwrap();
        if (score - actual.scores[i] as f64).abs() > TOLERANCE {
            fail("scores", format!("{}: {score} != {}", l.name(), actual.scores[i]));
        }
    }
    if expected["usedFallback"].as_bool().unwrap_or(false) != actual.used_fallback {
        fail(
            "usedFallback",
            format!("{} != {}", expected["usedFallback"], actual.used_fallback),
        );
    }
    if expected["retryAfter"].as_u64() != actual.retry_after.map(u64::from) {
        fail(
            "retryAfter",
            format!("{} != {:?}", expected["retryAfter"], actual.retry_after),
        );
    }
    let blocklist = &expected["blocklist"];
    let blocklist = if blocklist.is_null() { &Value::Null } else { blocklist };
    if *blocklist != blocklist_json(&actual.blocklist) {
        fail(
            "blocklist",
            format!("{blocklist} != {}", blocklist_json(&actual.blocklist)),
        );
    }
}

#[test]
fn classifier_matches_bounce_classifier() {
    let cases = CLASSIFY.as_array().unwrap();
    assert!(cases.len() > 200, "{} cases", cases.len());
    let mut errors = Vec::new();
    let mut classified = 0;
    for case in cases {
        let message = case["message"].as_str().unwrap();
        let name = format!("{message:?}");
        let mut fail = |field: &str, detail: String| {
            if !known(&name, field) {
                errors.push(format!("{name}: {field}: {detail}"));
            }
        };
        if case["retryAfter"].as_u64() != classify::extract_retry_timing(message).map(u64::from) {
            fail("extractRetryTiming", format!("{}", case["retryAfter"]));
        }
        let blocklist = blocklist_json(&classify::identify_blocklist(message));
        if case["blocklist"] != blocklist {
            fail("identifyBlocklist", format!("{} != {blocklist}", case["blocklist"]));
        }
        let codes = classify::extract_smtp_codes(message);
        if case["smtpCodes"]["mainCode"].as_str() != codes.main.as_deref()
            || case["smtpCodes"]["extendedCode"].as_str() != codes.extended.as_deref()
        {
            fail("extractSmtpCodes", format!("{} != {codes:?}", case["smtpCodes"]));
        }
        if label(&case["textFallback"]) != classify::text_fallback(message) {
            fail("getTextBasedFallback", format!("{}", case["textFallback"]));
        }
        if label(&case["codeFallback"]) != classify::code_fallback(message) {
            fail("getCodeBasedFallback", format!("{}", case["codeFallback"]));
        }
        if !case["result"].is_null() {
            classified += 1;
            check_classification(&name, &case["result"], &classify::classify(message), &mut errors);
        }
    }
    assert!(
        errors.is_empty(),
        "{} differences:\n{}",
        errors.len(),
        errors.join("\n")
    );
    assert!(classified > 200);
}

fn raw_of(case: &Value) -> Vec<u8> {
    match case["file"].as_str() {
        Some(file) => std::fs::read(format!("{}/tests/fixtures/bounces/{file}", env!("CARGO_MANIFEST_DIR"))).unwrap(),
        None => case["raw"].as_str().unwrap().as_bytes().to_vec(),
    }
}

/// A header value unfolded as libmime does: EmailEngine keeps the returned message's headers
/// folded as written, the port unfolds them like every other header block
fn unfold(value: &str) -> String {
    let mut out = String::with_capacity(value.len());
    let mut rest = value;
    while let Some(pos) = rest.find(['\r', '\n']) {
        out.push_str(&rest[..pos]);
        out.push(' ');
        let after = rest[pos..].strip_prefix('\r').unwrap_or(&rest[pos..]);
        rest = after
            .strip_prefix('\n')
            .unwrap_or(after)
            .trim_start_matches([' ', '\t']);
    }
    out.push_str(rest);
    out.trim().to_string()
}

fn unfolded(headers: &Value) -> Value {
    match headers.as_object() {
        None => Value::Null,
        Some(map) => Value::Object(
            map.iter()
                .map(|(k, v)| {
                    let values = v.as_array().unwrap().iter().map(|v| unfold(v.as_str().unwrap()));
                    (k.clone(), Value::from(values.collect::<Vec<_>>()))
                })
                .collect(),
        ),
    }
}

fn opt(value: Option<&str>) -> Value {
    value.map_or(Value::Null, Value::from)
}

fn check(errors: &mut Vec<String>, name: &str, field: &str, expected: &Value, actual: Value) {
    if *expected != actual && !known(name, field) {
        errors.push(format!("{name}: {field}: {expected} != {actual}"));
    }
}

#[test]
fn detection_matches_emailengine() {
    let cases = DETECT.as_array().unwrap();
    let mut errors = Vec::new();
    for case in cases {
        let name = case["name"].as_str().unwrap();
        let detection = detect(&raw_of(case));
        let e = &mut errors;
        check(
            e,
            name,
            "recipient",
            &case["recipient"],
            opt(detection.recipient.as_deref()),
        );
        check(e, name, "action", &case["action"], opt(detection.action.as_deref()));
        check(e, name, "mta", &case["mta"], opt(detection.mta.as_deref()));
        check(e, name, "queueId", &case["queueId"], opt(detection.queue_id.as_deref()));
        check(
            e,
            name,
            "messageId",
            &case["messageId"],
            opt(detection.message_id.as_deref()),
        );
        let response = detection.response.as_ref().map_or(Value::Null, |r| {
            let mut map = serde_json::Map::new();
            for (key, value) in [("message", &r.message), ("status", &r.status), ("source", &r.source)] {
                if let Some(value) = value {
                    map.insert(key.into(), Value::from(value.as_str()));
                }
            }
            Value::Object(map)
        });
        check(e, name, "response", &case["response"], response);

        let headers = detection.message_headers.as_ref().map_or(Value::Null, |h| {
            Value::Object(h.iter().map(|(k, v)| (k.to_string(), Value::from(v))).collect())
        });
        check(e, name, "messageHeaders", &unfolded(&case["messageHeaders"]), headers);

        let original = pe_bounce::original(&detection).unwrap_or_default();
        let expected = &case["original"];
        check(
            e,
            name,
            "original.subject",
            &expected["subject"],
            opt(original.subject.as_deref()),
        );
        check(
            e,
            name,
            "original.date",
            &expected["date"],
            opt(original.date.as_deref()),
        );
        check(e, name, "original.to", &expected["to"], opt(original.to.as_deref()));

        if let Some(message) = detection.response.as_ref().and_then(|r| r.message.as_deref()) {
            if case["classification"].is_null() {
                errors.push(format!("{name}: classification missing"));
            } else {
                check_classification(name, &case["classification"], &classify::classify(message), &mut errors);
            }
        }
    }
    assert!(
        errors.is_empty(),
        "{} differences:\n{}",
        errors.len(),
        errors.join("\n")
    );
    assert!(cases.len() >= 37);
}
