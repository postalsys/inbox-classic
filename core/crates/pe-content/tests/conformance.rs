//! analyze() against email-content: tests/fixtures/cases.json holds what email-content's analyze()
//! makes of every body its own test suite analyses and of every .eml fixture in its test
//! directory (see generate-cases.mjs). Offsets are compared after converting the port's byte
//! offsets to UTF-16 code units.

use std::sync::LazyLock;

use pe_content::{
    AnalyzeOptions, AnalyzeResult, BodySection, ConfidenceConfig, HistoryDocument, MessageContent, Representation,
    SectionRole, Segment, analyze,
};
use serde_json::Value;

static CASES: LazyLock<Value> = LazyLock::new(|| serde_json::from_str(include_str!("fixtures/cases.json")).unwrap());

/// Cases where the port knowingly differs, with the reason. Keep this list short.
const KNOWN_DIFFERENCES: &[(&str, &str)] = &[];

fn str_of(value: &Value) -> Option<&str> {
    value.as_str()
}

fn section(value: &Value) -> BodySection<'_> {
    BodySection {
        text: str_of(&value["text"]),
        html: str_of(&value["html"]),
        text_part_id: str_of(&value["textPartId"]),
        html_part_id: str_of(&value["htmlPartId"]),
        role: match value["role"].as_str() {
            Some("primary") => Some(SectionRole::Primary),
            Some("appended") => Some(SectionRole::Appended),
            _ => None,
        },
    }
}

fn content(value: &Value) -> MessageContent<'_> {
    MessageContent {
        text: str_of(&value["text"]),
        html: str_of(&value["html"]),
        sections: value["sections"]
            .as_array()
            .map(|sections| sections.iter().map(section).collect()),
        subject: str_of(&value["subject"]),
        from: str_of(&value["from"]),
        in_reply_to: str_of(&value["inReplyTo"]),
        references: value["references"]
            .as_array()
            .map(|r| r.iter().filter_map(Value::as_str).collect())
            .unwrap_or_default(),
        text_part_id: str_of(&value["textPartId"]),
        html_part_id: str_of(&value["htmlPartId"]),
    }
}

fn options(value: &Value) -> AnalyzeOptions<'_> {
    let mut confidence = ConfidenceConfig::default();
    // JSON writes NaN and the infinities as null.
    let threshold = |name: &str, default: f64| match value["confidence"].get(name) {
        Some(Value::Null) => f64::NAN,
        Some(v) => v.as_f64().unwrap_or(f64::NAN),
        None => default,
    };
    confidence.hide_threshold = threshold("hideThreshold", confidence.hide_threshold);
    confidence.collapse_threshold = threshold("collapseThreshold", confidence.collapse_threshold);
    confidence.min_anchor_strength = threshold("minAnchorStrength", confidence.min_anchor_strength);
    let history_documents = value["history"]
        .as_array()
        .map(|items| {
            items
                .iter()
                .enumerate()
                .map(|(i, item)| {
                    let id = format!("history-{i}");
                    if let Some(parts) = item["parts"].as_array() {
                        let parts: Vec<(Representation, &str)> = parts
                            .iter()
                            .map(|p| {
                                let representation = if p["representation"] == "html" {
                                    Representation::Html
                                } else {
                                    Representation::Text
                                };
                                (representation, p["body"].as_str().unwrap_or(""))
                            })
                            .collect();
                        HistoryDocument::from_parts(&parts, id, i == 0)
                    } else {
                        HistoryDocument::from_content(
                            item["text"].as_str().unwrap_or(""),
                            item["html"].as_str().unwrap_or(""),
                            id,
                            i == 0,
                        )
                    }
                })
                .collect()
        })
        .unwrap_or_default();
    AnalyzeOptions {
        confidence,
        max_content_chars: value["maxContentChars"].as_u64().map(|v| v as usize),
        history: Vec::new(),
        history_documents,
    }
}

fn units(source: &str, at: usize) -> usize {
    source[..at.min(source.len())].encode_utf16().count() + at.saturating_sub(source.len())
}

/// The string a segment's offsets index.
fn source_of<'a>(input: &'a MessageContent, result: &'a AnalyzeResult, segment: &Segment) -> &'a str {
    let part = segment.source.mime_part.as_str();
    match segment.source.representation {
        Representation::Text => result.canonical_text.get(part).map_or("", String::as_str),
        Representation::Html => {
            let single = std::iter::once(BodySection {
                html: input.html,
                html_part_id: input.html_part_id,
                ..Default::default()
            });
            input
                .sections
                .clone()
                .unwrap_or_default()
                .into_iter()
                .chain(single)
                .find(|s| s.html.is_some() && s.html_part_id.unwrap_or("HTML") == part)
                .and_then(|s| s.html)
                .unwrap_or("")
        }
    }
}

fn compare_segment(input: &MessageContent, result: &AnalyzeResult, got: &Segment, want: &Value) -> Result<(), String> {
    let check = |what: &str, ok: bool, detail: String| if ok { Ok(()) } else { Err(format!("{what}: {detail}")) };
    check(
        "type",
        got.label.as_str() == want["type"],
        format!("{} vs {}", got.label.as_str(), want["type"]),
    )?;
    check(
        "visibility",
        got.visibility.as_str() == want["visibility"],
        format!("{} vs {}", got.visibility.as_str(), want["visibility"]),
    )?;
    check(
        "text",
        got.text == want["text"].as_str().unwrap_or(""),
        format!("{:?} vs {}", got.text, want["text"]),
    )?;
    let confidence = want["confidence"].as_f64().unwrap_or(-1.0);
    check(
        "confidence",
        (got.confidence - confidence).abs() < 1e-9,
        format!("{} vs {confidence}", got.confidence),
    )?;
    let reasons: Vec<&str> = got.reasons.iter().map(|r| r.as_str()).collect();
    let want_reasons: Vec<&str> = want["reasons"]
        .as_array()
        .unwrap()
        .iter()
        .filter_map(Value::as_str)
        .collect();
    check(
        "reasons",
        reasons == want_reasons,
        format!("{reasons:?} vs {want_reasons:?}"),
    )?;
    let source = &want["source"];
    check(
        "mimePart",
        got.source.mime_part == source["mimePart"].as_str().unwrap_or(""),
        format!("{} vs {}", got.source.mime_part, source["mimePart"]),
    )?;
    check(
        "representation",
        got.source.representation.as_str() == source["representation"],
        String::new(),
    )?;
    check(
        "blockIndex",
        Some(got.source.block_index as u64) == source["blockIndex"].as_u64(),
        format!("{} vs {}", got.source.block_index, source["blockIndex"]),
    )?;
    let text = source_of(input, result, got);
    let (start, end) = (units(text, got.source.start), units(text, got.source.end));
    check(
        "start",
        Some(start as u64) == source["start"].as_u64(),
        format!("{start} vs {}", source["start"]),
    )?;
    // node-html-parser can report an end past the source, which the port clamps.
    let want_end = source["end"].as_u64().unwrap_or(0) as usize;
    let text_units = units(text, text.len());
    check(
        "end",
        end == want_end || (end == text_units && want_end > text_units),
        format!("{end} vs {want_end}"),
    )?;
    check(
        "domPath",
        got.source.dom_path.as_deref() == source["domPath"].as_str(),
        format!("{:?} vs {}", got.source.dom_path, source["domPath"]),
    )?;
    check(
        "html",
        got.html.as_deref() == want["html"].as_str(),
        "html differs".into(),
    )?;
    Ok(())
}

fn compare(input: &MessageContent, result: &AnalyzeResult, want: &Value) -> Result<(), String> {
    for (field, got) in [
        ("segments", &result.segments),
        ("hiddenSegments", &result.hidden_segments),
    ] {
        let expected = want[field].as_array().unwrap();
        if got.len() != expected.len() {
            let labels: Vec<String> = got
                .iter()
                .map(|s| format!("{}/{}", s.label.as_str(), s.visibility.as_str()))
                .collect();
            let want_labels: Vec<String> = expected
                .iter()
                .map(|s| format!("{}/{}", s["type"].as_str().unwrap(), s["visibility"].as_str().unwrap()))
                .collect();
            return Err(format!(
                "{field}: {} vs {} segments: {labels:?} vs {want_labels:?}",
                got.len(),
                expected.len()
            ));
        }
        for (i, (segment, expected)) in got.iter().zip(expected).enumerate() {
            compare_segment(input, result, segment, expected).map_err(|err| format!("{field}[{i}] {err}"))?;
        }
    }
    let warnings: Vec<String> = result
        .warnings
        .iter()
        .map(|w| {
            format!(
                "{}|{}|{}",
                w.code.as_str(),
                w.mime_part.as_deref().unwrap_or(""),
                w.detail.as_deref().unwrap_or("")
            )
        })
        .collect();
    let want_warnings: Vec<String> = want["warnings"]
        .as_array()
        .unwrap()
        .iter()
        .map(|w| {
            format!(
                "{}|{}|{}",
                w["code"].as_str().unwrap(),
                w["mimePart"].as_str().unwrap_or(""),
                w["detail"].as_str().unwrap_or("")
            )
        })
        .collect();
    if warnings != want_warnings {
        return Err(format!("warnings {warnings:?} vs {want_warnings:?}"));
    }
    let overall = want["overallConfidence"].as_f64().unwrap();
    if (result.overall_confidence - overall).abs() > 1e-9 {
        return Err(format!("overallConfidence {} vs {overall}", result.overall_confidence));
    }
    let primary = result.primary_representation.map_or("none", Representation::as_str);
    if primary != want["primaryRepresentation"] {
        return Err(format!(
            "primaryRepresentation {primary} vs {}",
            want["primaryRepresentation"]
        ));
    }
    if result.history_used != want["historyUsed"].as_bool().unwrap()
        || result.is_reply != want["isReply"].as_bool().unwrap()
    {
        return Err("historyUsed or isReply differs".into());
    }
    let want_canonical: Vec<(&str, &str)> = want["canonicalText"]
        .as_object()
        .unwrap()
        .iter()
        .map(|(k, v)| (k.as_str(), v.as_str().unwrap()))
        .collect();
    let mut want_canonical = want_canonical;
    want_canonical.sort();
    let canonical: Vec<(&str, &str)> = result
        .canonical_text
        .iter()
        .map(|(k, v)| (k.as_str(), v.as_str()))
        .collect();
    if canonical != want_canonical {
        return Err("canonicalText differs".into());
    }
    Ok(())
}

#[test]
fn agrees_with_email_content() {
    let cases = CASES.as_array().unwrap();
    let mut failures = Vec::new();
    let mut agreeing = 0;
    let mut unrepresentable = 0;
    for case in cases {
        let name = case["name"].as_str().unwrap();
        // A maxContentChars that is not a whole number (NaN, negative, fractional) cannot be
        // expressed as a usize; the type rejects what email-content rejects at run time.
        if case["options"]
            .get("maxContentChars")
            .is_some_and(|v| v.as_u64().is_none())
        {
            unrepresentable += 1;
            continue;
        }
        let input = content(&case["content"]);
        let opts = options(&case["options"]);
        let expected = &case["expected"];
        let outcome = match (analyze(&input, &opts), expected["error"].as_str()) {
            (Err(err), Some(code)) if err.code == code => Ok(()),
            (Err(err), _) => Err(format!("error {err}")),
            (Ok(_), Some(code)) => Err(format!("expected error {code}")),
            (Ok(result), None) => compare(&input, &result, expected),
        };
        match outcome {
            Ok(()) => agreeing += 1,
            Err(err) => {
                if !KNOWN_DIFFERENCES.iter().any(|(known, _)| *known == name) {
                    failures.push(format!("{name}: {err}"));
                }
            }
        }
    }
    eprintln!(
        "{agreeing} of {} cases agree, {unrepresentable} not expressible in the Rust types",
        cases.len()
    );
    assert_eq!(
        agreeing + unrepresentable + failures.len() + KNOWN_DIFFERENCES.len(),
        cases.len()
    );
    assert!(
        failures.is_empty(),
        "{} cases differ:\n{}",
        failures.len(),
        failures.iter().take(40).cloned().collect::<Vec<_>>().join("\n")
    );
}
