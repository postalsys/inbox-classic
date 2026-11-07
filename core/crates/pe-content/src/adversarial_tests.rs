//! Hostile input bounds and pipeline invariants, ported from email-content's
//! test/adversarial.test.ts and the invariant checks of its other suites.
//!
//! Each bound asserts two things, as the original does: an absolute ceiling, and growth no worse
//! than linear (with a factor of three of slack) across doubling input sizes. Quadratic work grows
//! 256 fold over four doublings where linear grows 16 fold, so the ratio fails loudly.

use std::time::Instant;

use crate::block::Block;
use crate::detect::{detect_attribution_line, detect_quoted_header_block};
use crate::dom::{self, Dom, ROOT};
use crate::html_text::strip_tags_to_text;
use crate::segment_html::{is_pathological_html, scan_markup, segment_html_blocks};
use crate::segment_text::segment_text_blocks;
use crate::{AnalyzeOptions, Label, MessageContent, Visibility, WarningCode, analyze};

const LINEAR_SLACK: f64 = 3.0;

/// Absolute ceiling per case. Debug builds are an order of magnitude slower.
fn budget_ms() -> f64 {
    if cfg!(debug_assertions) { 20_000.0 } else { 2_000.0 }
}

fn measure(mut run: impl FnMut()) -> f64 {
    (0..3)
        .map(|_| {
            let started = Instant::now();
            run();
            started.elapsed().as_secs_f64() * 1000.0
        })
        .fold(f64::INFINITY, f64::min)
}

fn assert_linear(label: &str, sizes: &[usize], build: impl Fn(usize) -> String, run: impl Fn(&str)) {
    run(&build(sizes[0]));
    let inputs: Vec<(usize, String)> = sizes.iter().map(|&size| (size, build(size))).collect();
    // timings on a shared machine are noisy: a quadratic path fails every round, a busy moment only one, so it takes
    // three failed rounds in a row to fail
    let mut failure = String::new();
    for _ in 0..3 {
        match linear_round(label, &inputs, &run) {
            Ok(()) => return,
            Err(why) => failure = why,
        }
    }
    panic!("{failure}");
}

/// One round of [`assert_linear`]: each size timed, and checked against the smallest one's time
fn linear_round(label: &str, inputs: &[(usize, String)], run: &impl Fn(&str)) -> Result<(), String> {
    let timings: Vec<(usize, f64)> = inputs
        .iter()
        .map(|(size, input)| (*size, measure(|| run(input))))
        .collect();
    let (anchor_size, anchor_ms) = timings[0];
    // A floor, so timer noise on a sub millisecond anchor cannot make an enormous ratio.
    let anchor_ms = anchor_ms.max(0.5);
    for (size, ms) in timings {
        if ms >= budget_ms() {
            return Err(format!("{label}: size {size} took {ms:.1}ms"));
        }
        let allowed = anchor_ms * (size as f64 / anchor_size as f64) * LINEAR_SLACK;
        if ms > allowed {
            return Err(format!(
                "{label}: size {size} took {ms:.2}ms, over {allowed:.2}ms for linear growth"
            ));
        }
    }
    Ok(())
}

fn analyze_html(html: &str) -> crate::AnalyzeResult {
    let content = MessageContent {
        html: Some(html),
        ..Default::default()
    };
    analyze(&content, &AnalyzeOptions::default()).unwrap()
}

#[test]
fn strips_mailto_urls_in_linear_time() {
    assert_linear(
        "mailto strip on space runs",
        &[250, 500, 1000, 2000],
        |size| format!("a{}b", " ".repeat(size - 2)),
        |input| {
            for _ in 0..200 {
                detect_attribution_line(input);
                detect_attribution_line(&format!("{}mailto:x", &input[..input.len() - 1]));
            }
        },
    );
}

#[test]
fn keeps_attribution_patterns_cheap_on_a_timed_line() {
    let line = format!("12:30 {}", "x".repeat(290));
    detect_attribution_line(&line);
    let ms = measure(|| {
        for _ in 0..2000 {
            detect_attribution_line(&line);
        }
    });
    assert!(ms < budget_ms() / 5.0, "2000 hostile lines took {ms:.1}ms");
}

#[test]
fn detects_quoted_header_blocks_in_a_single_pass() {
    assert_linear(
        "quoted header scan",
        &[2000, 4000, 8000, 16000],
        |size| vec!["Cc: nobody@example.test"; size].join("\n"),
        |input| {
            let lines: Vec<&str> = input.split('\n').collect();
            detect_quoted_header_block(&lines, 0);
        },
    );
}

#[test]
fn projects_hostile_markup_in_a_single_pass() {
    for (label, unit, sizes) in [
        ("unmatched <", "<", [16000, 32000, 64000, 128000]),
        ("unmatched <script", "<script", [4000, 8000, 16000, 32000]),
        (
            "closed script elements",
            "<script>var a=1;</script>text ",
            [2000, 4000, 8000, 16000],
        ),
        ("unmatched <!--", "<!--", [8000, 16000, 32000, 64000]),
        (
            "unterminated quoted attribute",
            "<a href=\"",
            [4000, 8000, 16000, 32000],
        ),
        ("incomplete entities", "&#x", [8000, 16000, 32000, 64000]),
        (
            "mixed hostile markup",
            "<<!--<script<a href=\"&#x<b class='",
            [2000, 4000, 8000, 16000],
        ),
    ] {
        assert_linear(
            label,
            &sizes,
            |size| unit.repeat(size),
            |input| {
                strip_tags_to_text(input);
            },
        );
    }
}

#[test]
fn builds_trees_of_hostile_markup_in_a_single_pass() {
    // node-html-parser's regular expression rescans the rest of the document for each of these;
    // the tokenizer remembers what it did not find.
    for (label, unit) in [
        ("unterminated comments", "<!--"),
        ("unterminated quotes", "<a \""),
        ("unterminated attribute values", "<a b=\"x"),
        ("unclosed cdata", "<![CDATA[x"),
        ("bare openers", "<a"),
    ] {
        assert_linear(
            label,
            &[8000, 16000, 32000, 64000],
            |size| unit.repeat(size),
            |input| {
                dom::parse(input);
            },
        );
    }
}

#[test]
fn classifies_more_short_lines_than_v8_allows_call_arguments() {
    let text = "x\n".repeat(130000);
    let content = MessageContent {
        text: Some(&text),
        ..Default::default()
    };
    let result = analyze(&content, &AnalyzeOptions::default()).unwrap();
    assert!(!result.segments.is_empty());
    assert!(
        !result
            .warnings
            .iter()
            .any(|w| w.code == WarningCode::ExtractionDegraded)
    );
    assert!(result.segments.iter().any(|s| s.text.contains('x')));
}

#[test]
fn classifies_a_run_of_many_html_nodes() {
    let result = analyze_html(&format!("<div>x{}</div>", "<b></b>".repeat(200000)));
    assert!(!result.segments.is_empty());
    assert!(
        !result
            .warnings
            .iter()
            .any(|w| w.code == WarningCode::ExtractionDegraded)
    );
}

#[test]
fn refuses_to_parse_a_document_of_sibling_text_nodes() {
    assert!(is_pathological_html(&format!("<div>{}</div>", "a<br>".repeat(20000))));
    assert!(!is_pathological_html(&format!("<div>{}</div>", "a<br>".repeat(5000))));
    let result = analyze_html(&format!("<div>SENTINEL<br>{}</div>", "a<br>".repeat(20000)));
    assert!(result.segments.iter().any(|s| s.text.contains("SENTINEL")));
}

#[test]
fn keeps_the_originator_check_cheap_on_brackets() {
    let block = |count: usize, length: usize| {
        let openers = length / 3;
        let from = format!("From: {}{}", "<".repeat(openers), "@".repeat(length - openers));
        let mut lines = vec![from; count];
        lines.push("Sent: Monday, 13 January 2025 09:15".into());
        lines.push("Subject: hi".into());
        lines
    };
    let long = block(1, 20000);
    let ms = measure(|| {
        detect_quoted_header_block(&long, 0);
    });
    assert!(ms < budget_ms() / 40.0, "a 20,000 character value took {ms:.1}ms");
    assert_linear(
        "bracket originator values",
        &[250, 500, 1000, 2000],
        |size| block(size, 300).join("\n"),
        |input| {
            let lines: Vec<&str> = input.split('\n').collect();
            detect_quoted_header_block(&lines, 0);
        },
    );
}

#[test]
fn refuses_documents_that_would_leave_hundreds_of_elements_open() {
    for unit in [
        "<b>x",
        "<i>",
        "<a href=\"#\">x",
        "<section>x",
        "<center>x",
        "<font>x",
        "<Br>",
    ] {
        assert!(
            is_pathological_html(&format!("<p>hi</p>{}", unit.repeat(5000))),
            "{unit}"
        );
    }
    for unit in [
        "<p>para",
        "<li>item",
        "<td>cell",
        "<dt>term",
        "<h1>x",
        "<h2>a<h2>b",
        "<br>",
        "<img src=\"x\">",
    ] {
        assert!(!is_pathological_html(&unit.repeat(5000)), "{unit}");
    }
    assert!(!is_pathological_html(&"<b>x</b>".repeat(5000)));
    assert!(!is_pathological_html(&"<div><b>x</div>".repeat(5000)));
    assert!(!is_pathological_html(&"<span><p>x</span>".repeat(5000)));
    assert!(!is_pathological_html(&format!("<pre>{}</pre>", "<b>".repeat(5000))));
    assert!(!is_pathological_html(&format!("<!--{}-->", "<b>".repeat(5000))));

    let html = format!("<p>SENTINEL</p>{}", "<b>x".repeat(5000));
    let started = Instant::now();
    let result = analyze_html(&html);
    assert!(started.elapsed().as_secs_f64() * 1000.0 < budget_ms());
    assert!(result.warnings.iter().any(|w| w.code == WarningCode::HtmlParseError));
    assert!(result.segments.iter().any(|s| s.text.contains("SENTINEL")));
}

#[test]
fn counts_the_elements_an_ignored_end_tag_leaves_open() {
    for unit in [
        "<a><b><c>y</a></b>",
        "<b>x</i>",
        "<td><font>x</td>",
        "<b>x</B>",
        "<b title=\"x></b>\">",
        "<a>x</a!>",
        "<ul><li><b>x</ul>",
    ] {
        assert!(is_pathological_html(&unit.repeat(1000)), "{unit}");
    }
}

#[test]
fn counts_open_elements_exactly_as_the_parser_does() {
    // Depths of the trees node-html-parser builds with parseNoneClosedTags, recorded from it.
    for (unit, open) in [
        ("<b>x", 20),
        ("<a><b><c>y</a></b>", 60),
        ("<b>x</i>", 20),
        ("<td><font>x</td>", 40),
        ("<b>x</B>", 20),
        ("<b title=\"x></b>\">", 20),
        ("<a>x</a!>", 20),
        ("<tr>", 1),
        ("<Br>", 20),
        ("<ul><li><b>x</ul>", 60),
        ("<table><tr><td>x", 60),
        ("<tbody><tr><td><b>x</tbody>", 80),
        ("<tr><td>a<td>b", 2),
        ("<tbody><tr><td>x", 3),
    ] {
        assert_eq!(scan_markup(&unit.repeat(20)).0, open, "{unit}");
    }
    for unit in [
        "<p>para",
        "<li>item",
        "<td>cell",
        "<h2>a<h2>b",
        "<div><b>x</div>",
        "<span><p>x</span>",
        "<b>x</b>",
        "<pre><b><b><b><b><b></pre>",
        "<!--<b>-->",
        "<table><tfoot><tr><td>x</table>",
        "<br/>",
        "<div/>",
    ] {
        assert!(scan_markup(&unit.repeat(20)).0 <= 1, "{unit}");
    }
}

#[test]
fn scans_markup_in_a_single_pass() {
    for (label, unit) in [
        ("unclosed tags", "<b>x"),
        ("unterminated quotes", "<a \""),
        ("unterminated comments", "<!--"),
        ("unterminated raw text elements", "<pre>x"),
    ] {
        assert_linear(
            label,
            &[8000, 16000, 32000, 64000],
            |size| unit.repeat(size),
            |input| {
                is_pathological_html(input);
            },
        );
    }
}

#[test]
fn projects_leaked_markup_in_a_pre_in_linear_time() {
    for (label, unit) in [
        ("unclosed tags in a pre", "<a "),
        ("unclosed conditional comments in a pre", "<!["),
    ] {
        assert_linear(
            label,
            &[10000, 20000, 40000, 80000],
            |size| format!("<pre>{}</pre>", unit.repeat(size)),
            |input| {
                segment_html_blocks(input, "1");
            },
        );
    }
    let result = segment_html_blocks(
        "<pre><![if !supportLists]><table><tr><td>cell</td></tr></table><![endif]></pre>",
        "1",
    );
    let text: String = result.blocks.iter().map(|b| b.content.as_str()).collect();
    assert_eq!(text.trim(), "cell");
}

#[test]
fn walks_deep_nesting_without_recursion() {
    // Balanced, so not pathological, and far deeper than a recursive walk could go.
    let html = format!(
        "{}deep{}",
        "<div><span>".repeat(100_000),
        "</span></div>".repeat(100_000)
    );
    let result = analyze_html(&html);
    assert!(result.segments.iter().any(|s| s.text.contains("deep")));
    let dom: Dom = dom::parse(&html);
    assert!(!dom.nodes[ROOT].children.is_empty());
}

/// Every HTML and text body of the conformance cases.
fn bodies() -> Vec<(bool, String)> {
    let cases: serde_json::Value = serde_json::from_str(include_str!("../tests/fixtures/cases.json")).unwrap();
    let mut out = Vec::new();
    for case in cases.as_array().unwrap() {
        let content = &case["content"];
        let sections = content["sections"]
            .as_array()
            .cloned()
            .unwrap_or_else(|| vec![content.clone()]);
        for section in sections {
            if let Some(text) = section["text"].as_str() {
                out.push((false, text.to_string()));
            }
            if let Some(html) = section["html"].as_str() {
                out.push((true, html.to_string()));
            }
        }
    }
    out
}

fn assert_tiles(source: &str, blocks: &[Block]) {
    let mut at = 0;
    for block in blocks {
        assert_eq!(block.start, at, "blocks must be adjacent");
        assert!(block.end >= block.start);
        at = block.end;
    }
    assert_eq!(at, source.len(), "blocks must reach the end");
}

#[test]
fn blocks_tile_their_representation() {
    for (is_html, body) in bodies() {
        if is_html {
            let result = segment_html_blocks(&body, "1");
            assert_tiles(&body, &result.blocks);
        } else {
            let (canonical, blocks) = segment_text_blocks(&body, "1");
            assert_tiles(&canonical.text, &blocks);
            let joined: String = blocks.iter().map(|b| &canonical.text[b.start..b.end]).collect();
            assert_eq!(joined, canonical.text);
        }
    }
}

#[test]
fn results_keep_the_safety_invariants() {
    for (is_html, body) in bodies() {
        let content = MessageContent {
            text: (!is_html).then_some(body.as_str()),
            html: is_html.then_some(body.as_str()),
            ..Default::default()
        };
        let result = analyze(&content, &AnalyzeOptions::default()).unwrap();
        // Never empty: a body with text yields something visible, or names why not.
        let explained = result
            .warnings
            .iter()
            .any(|w| matches!(w.code, WarningCode::NoBodyParts | WarningCode::NoVisibleBodyText));
        assert!(
            !result.segments.is_empty() || explained,
            "empty result without a reason"
        );
        // Only reply history is hidden, and only behind a structural reason.
        for segment in &result.hidden_segments {
            assert_eq!(segment.label, Label::ReplyHistory);
            assert_eq!(segment.visibility, Visibility::Hide);
            assert!(segment.reasons.iter().any(|r| matches!(
                r,
                crate::Reason::PrecededByReplyHeader
                    | crate::Reason::InsideQuoteContainer
                    | crate::Reason::OutlookReplySeparator
                    | crate::Reason::MatchedParentMessage
            )));
        }
        assert!(result.segments.iter().all(|s| s.visibility != Visibility::Hide));
        // Offsets stay inside their source.
        for segment in result.segments.iter().chain(&result.hidden_segments) {
            let source_len = match segment.source.representation {
                crate::Representation::Text => result.canonical_text[&segment.source.mime_part].len(),
                crate::Representation::Html => body.len(),
            };
            assert!(segment.source.start <= segment.source.end && segment.source.end <= source_len);
            // A text segment's lines are all in the canonical text range it names.
            if segment.source.representation == crate::Representation::Text {
                let slice = &result.canonical_text[&segment.source.mime_part][segment.source.start..segment.source.end];
                for line in segment.text.split('\n').filter(|l| !l.trim().is_empty()) {
                    assert!(slice.contains(line.trim()), "segment line outside its range");
                }
            }
        }
    }
}
