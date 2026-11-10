//! The tests of otp-detect's test/index.test.ts. Every fixture here is hand written; never paste
//! real email content into this repository.

use std::time::Instant;

use pe_otp::candidates::extract_candidates;
use pe_otp::doc::render_text;
use pe_otp::features::FEATURE_NAMES;
use pe_otp::html::{decode_entities, render_html};
use pe_otp::{MODEL, MessageInput, Source, detect_otp, score_candidates};

fn codes(text: &str) -> Vec<String> {
    extract_candidates(&render_text(text))
        .into_iter()
        .map(|c| c.code)
        .collect()
}

#[test]
fn finds_digit_codes_grouped_digits_and_capital_letter_codes() {
    assert_eq!(codes("Your code is 482917"), ["482917"]);
    assert!(codes("Code: 482 917").contains(&"482917".into()));
    assert!(codes("Code: 482-917").contains(&"482917".into()));
    assert_eq!(codes("Steam Guard code: QWKZT"), ["QWKZT"]);
    assert!(codes("Use 4 8 2 9 1 7 to continue").contains(&"482917".into()));
}

#[test]
fn skips_prices_times_dates_urls_addresses_and_phone_numbers() {
    let none: [&str; 0] = [];
    for text in [
        "Total 1,250.00 EUR at 10:30 on 12.05.2025",
        "Visit https://example.com/reset/837261 or mail help1234@example.com",
        "Call 372-5-555-0100",
        "The 21st meeting, 100mg, 1080p",
    ] {
        assert_eq!(codes(text), none, "{text}");
    }
}

#[test]
fn keeps_long_random_validation_codes() {
    assert_eq!(codes("validation code: aZ3kQ9mW2xP7rT5v"), ["aZ3kQ9mW2xP7rT5v"]);
}

#[test]
fn spaced_characters_back_off_before_a_letter() {
    // the greedy run ends next to a letter, so the match is one character shorter
    assert_eq!(codes("A 1 B 2 Cx"), ["A1B2"]);
    assert_eq!(codes("x1 2 3 4"), Vec::<String>::new());
}

#[test]
fn decodes_entities() {
    assert_eq!(decode_entities("&uuml;hekordne &amp; &#53;&#x36;"), "ühekordne & 56");
    assert_eq!(
        decode_entities("&#0;&#xD800;&#9999999;&unknown;"),
        "\u{FFFD}\u{FFFD}\u{FFFD}&unknown;"
    );
}

#[test]
fn keeps_the_style_of_the_code_and_drops_hidden_content() {
    let doc = render_html(
        "<html><head><style>p{}</style></head><body><div style=\"display:none\">preheader 111111</div>\
         <p>Your verification code:</p><p style=\"font-size:32px;font-weight:bold;letter-spacing:4px\">530 112</p></body></html>",
    );
    assert!(!doc.text.contains("p{}"));
    let candidates = extract_candidates(&doc);
    let candidate = candidates.iter().find(|c| c.code == "530112").unwrap();
    let span = doc
        .spans
        .iter()
        .find(|s| s.start <= candidate.start && s.end >= candidate.end)
        .unwrap();
    assert_eq!(span.style.font_size, 32.0);
    assert!(span.style.bold);
    assert!(span.style.letter_spacing);
    let hidden = doc
        .spans
        .iter()
        .find(|s| doc.text[s.start..s.end].contains("111111"))
        .unwrap();
    assert!(hidden.style.hidden);
}

#[test]
fn puts_table_cells_on_separate_lines() {
    let doc = render_html("<table><tr><td>1</td><td>2</td></tr></table>");
    assert_eq!(doc.text, "1\n2");
}

#[test]
fn the_model_was_trained_on_the_feature_list_this_version_computes() {
    assert_eq!(MODEL.feature_names, FEATURE_NAMES);
    assert!(MODEL.has_feature_names());
    assert!(!MODEL.trees.is_empty());
}

#[test]
fn finds_the_code_in_a_typical_html_login_email() {
    let result = detect_otp(&MessageInput {
        subject: Some("Your sign-in code"),
        html: Some(
            "<div><p>Hi,</p><p>Use this code to sign in to your Example account:</p>\
             <p style=\"font-size:28px;font-weight:bold;letter-spacing:6px\">739104</p>\
             <p>The code expires in 10 minutes. If you did not request it, ignore this email.</p>\
             <p>Example Inc, 123 Main Street, Springfield 54321</p></div>",
        ),
        ..Default::default()
    })
    .unwrap();
    assert_eq!(result.code, "739104");
    assert_eq!(result.source, Source::Html);
}

#[test]
fn finds_the_code_in_a_plain_text_email() {
    let result = detect_otp(&MessageInput {
        subject: Some("Verify your email"),
        text: Some(
            "Hello,\n\nYour verification code is: 284716\n\nIt is valid for 15 minutes. Do not share it with anyone.\n\nThanks,\nThe Example team\n",
        ),
        ..Default::default()
    });
    assert_eq!(result.map(|r| r.code).as_deref(), Some("284716"));
}

#[test]
fn finds_the_code_in_an_estonian_email() {
    let result = detect_otp(&MessageInput {
        subject: Some("Sinu kinnituskood"),
        text: Some("Tere!\n\nSinu ühekordne kinnituskood on 913560\n\nKood kehtib 10 minutit.\n"),
        ..Default::default()
    });
    assert_eq!(result.map(|r| r.code).as_deref(), Some("913560"));
}

#[test]
fn stays_quiet_on_an_order_confirmation() {
    let result = detect_otp(&MessageInput {
        subject: Some("Order 58213490 confirmed"),
        text: Some(
            "Thank you for your order 58213490.\nTotal: 49.90 EUR\nTracking number: 77341209\nCustomer service: +372 555 0100\n",
        ),
        ..Default::default()
    });
    assert_eq!(result, None);
}

#[test]
fn stays_quiet_on_a_promotional_email() {
    let result = detect_otp(&MessageInput {
        subject: Some("Save 20% this weekend"),
        html: Some(
            "<p>Get 20% off your next purchase with promo code <b>SPRING24</b> at checkout. Offer valid until Sunday.</p>",
        ),
        ..Default::default()
    });
    assert_eq!(result, None);
}

#[test]
fn stays_fast_on_hostile_input() {
    let big = 400 * 1024;
    let inputs: Vec<(Option<String>, Option<String>)> = vec![
        (Some("<a".repeat(big / 2)), None),
        (Some("<!".repeat(big / 2)), None),
        (Some(format!("<a x=\"{}", "y".repeat(big))), None),
        (None, Some("a(".repeat(big / 2))),
        (None, Some("AB12 ".repeat(big / 5))),
        (Some(format!("{}code 123456", "<div>".repeat(big / 5))), None),
        // ours: stray close tags under a deep stack, unclosed quotes in every tag, entities
        (
            Some(format!("{}{}", "<div>".repeat(big / 10), "</span>".repeat(big / 14))),
            None,
        ),
        (Some("<a x=\"<b y='".repeat(big / 12)), None),
        (Some("&#123456;&amp".repeat(big / 13)), None),
        (None, Some("1 2 3 4 5 6 7 8 9 0 ".repeat(big / 20))),
        (None, Some("код ".repeat(big / 4))),
    ];
    for (html, text) in &inputs {
        let started = Instant::now();
        score_candidates(&MessageInput {
            html: html.as_deref(),
            text: text.as_deref(),
            ..Default::default()
        });
        let elapsed = started.elapsed().as_millis();
        let sample: String = html
            .as_deref()
            .or(text.as_deref())
            .unwrap_or("")
            .chars()
            .take(40)
            .collect();
        assert!(elapsed < 3000, "took {elapsed} ms on {sample:?}");
    }
}

#[test]
fn returns_nothing_for_an_empty_message() {
    assert_eq!(detect_otp(&MessageInput::default()), None);
    assert_eq!(
        score_candidates(&MessageInput {
            subject: Some("Hello"),
            ..Default::default()
        }),
        []
    );
}
