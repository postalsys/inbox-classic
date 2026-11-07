//! Hostile input, ported from EmailEngine's test/bounce-arf-hostile-input-test.js and the
//! unterminated address test of bounce-heuristics-test.js: text that once made the JavaScript
//! patterns take seconds at the 50 KB heuristic window, and a delivery report folded a few hundred
//! thousand times. Rust's regex engine is linear anyway; these check that the work stays linear
//! and that the formats are still read.

use std::time::{Duration, Instant};

use pe_bounce::{detect, headers::MAX_HEADER_BLOCK_SIZE};

const SIZE: usize = 50_000;

/// A notice from a mailer daemon, so the heuristics run on its text
fn notice(text: &str) -> Vec<u8> {
    format!(
        "From: Mail Delivery System <mailer-daemon@mta.example.com>\r\nSubject: Mail delivery failed\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n{text}"
    )
    .into_bytes()
}

fn time(raw: &[u8]) -> Duration {
    let start = Instant::now();
    detect(raw);
    start.elapsed()
}

/// Doubling the input must not much more than double the time. The floor keeps timer noise on
/// short runs from failing the ratio; the bounds are loose for unoptimized test builds
fn assert_linear(label: &str, build: impl Fn(usize) -> Vec<u8>) {
    // the patterns are compiled on first use
    detect(&build(16));
    let small = time(&build(SIZE / 2));
    let large = time(&build(SIZE));
    assert!(large < Duration::from_secs(2), "{label}: {large:?} at full size");
    assert!(
        large <= (small * 3).max(Duration::from_millis(100)),
        "{label}: {small:?} -> {large:?} when doubled"
    );
}

#[test]
fn heuristics_stay_linear_on_hostile_text() {
    assert_linear("newlines", |n| notice(&"\n".repeat(n)));
    assert_linear("angle brackets", |n| notice(&"<".repeat(n)));
    assert_linear("newline angle", |n| notice(&format!("\n<{}", "<".repeat(n))));
    assert_linear("open addresses", |n| notice(&"<a@".repeat(n / 3)));
    assert_linear("Error:", |n| notice(&"Error:".repeat(n / 6)));
    assert_linear("delivery failed newlines", |n| {
        notice(&format!(
            "Delivery to the following recipient failed permanently:{}",
            "\n".repeat(n)
        ))
    });
    assert_linear("affected newlines", |n| {
        notice(&format!("The following recipients were affected:{}", "\n".repeat(n)))
    });
    assert_linear("host spaces", |n| {
        notice(&format!("<a@example.com>: host mx.example.com{}x", " ".repeat(n)))
    });
}

#[test]
fn an_unterminated_address_is_not_read_to_the_end() {
    for anchor in [
        "The following message to <",
        "Your message could not be delivered to the following address: <",
    ] {
        let body = format!("{anchor}a@").repeat(SIZE.div_ceil(anchor.len() + 2));
        let start = Instant::now();
        let detection = detect(&notice(&body));
        assert_eq!(detection.recipient, None);
        assert!(start.elapsed() < Duration::from_secs(2), "{:?}", start.elapsed());
    }
}

#[test]
fn ordinary_formats_are_still_read() {
    let d = detect(&notice(
        "<bob@example.com>: host mx.example.com[203.0.113.4] said: 550 5.1.1 No such user here\n",
    ));
    assert_eq!(d.recipient.as_deref(), Some("bob@example.com"));
    assert_eq!(d.mta.as_deref(), Some("mx.example.com"));

    let d = detect(&notice(
        "<bob@example.com>: host mx.example.com said: 550 5.1.1 No such user here\n",
    ));
    assert_eq!(d.recipient.as_deref(), Some("bob@example.com"));
    assert_eq!(d.mta.as_deref(), Some("mx.example.com"));

    let d = detect(&notice(
        "Delivery to the following recipient failed permanently:\n\n\n     dave@example.com\n\nTechnical details",
    ));
    assert_eq!(d.recipient.as_deref(), Some("dave@example.com"));

    let d = detect(&notice(
        "Technical details:\n\n550-5.7.1 [1.2.3.4 11] Message rejected\n",
    ));
    assert_eq!(d.response.unwrap().status.as_deref(), Some("5.7.1"));

    let d = detect(&notice(
        "Sorry\n<carol@example.com>:\n550: 5.1.1 <carol@example.com>: Recipient address rejected\n",
    ));
    assert_eq!(d.recipient.as_deref(), Some("carol@example.com"));

    let d = detect(&notice("Status: failed\nError: No valid recipients for this MM\n"));
    assert_eq!(
        d.response.unwrap().message.as_deref(),
        Some("Error: No valid recipients for this MM")
    );
}

/// A report with a recipient and a status but no Diagnostic-Code, so the recipient's own block of
/// the text is searched for "host ...:"
fn report_with_text(text: &str, report: &str) -> Vec<u8> {
    [
        "From: Mail Delivery System <mailer-daemon@mta.example.com>",
        "Content-Type: multipart/report; report-type=delivery-status; boundary=\"B\"",
        "",
        "--B",
        "Content-Type: text/plain",
        "",
        text,
        "--B",
        "Content-Type: message/delivery-status",
        "",
        report,
        "--B--",
        "",
    ]
    .join("\r\n")
    .into_bytes()
}

#[test]
fn host_without_a_colon_in_the_recipient_block() {
    let report = "Reporting-MTA: dns; mta.example.com\n\nFinal-Recipient: rfc822; x@example.com\nAction: failed\nStatus: 5.1.1\n";
    assert_linear("host block", |n| {
        report_with_text(
            &format!(
                "A message that you sent could not be delivered\n{} x@example.com",
                " host a".repeat(n / 7)
            ),
            report,
        )
    });
}

#[test]
fn a_huge_delivery_report_is_cut_before_its_headers_are_unfolded() {
    assert_eq!(MAX_HEADER_BLOCK_SIZE, 64 * 1024);
    let report = format!(
        "Final-Recipient: rfc822; x@example.com\nAction: failed\nStatus: 5.1.1\nX-Fold: a\n{}",
        " b\n".repeat(400_000)
    );
    let raw = report_with_text("", &report);
    let start = Instant::now();
    let d = detect(&raw);
    assert!(start.elapsed() < Duration::from_secs(5), "{:?}", start.elapsed());
    assert_eq!(d.recipient.as_deref(), Some("x@example.com"));
    assert_eq!(d.action.as_deref(), Some("failed"));
}

#[test]
fn a_report_with_many_inline_images_reads_every_part() {
    // EmailEngine's check that every parse of a bounce keeps cid: links (mailparser would inline
    // each image once per reference); here, that such a bounce is still read through to its
    // returned message and Zoho's text/rfc822 part
    let image = "AQEB".repeat(683);
    let html = format!("<p>{}</p>", "<img src=\"cid:img1\">".repeat(50));
    let raw = [
        "From: Mail Delivery System <mailer-daemon@zoho.example.com>",
        "X-Mailer: Zoho Mail",
        "MIME-Version: 1.0",
        "Content-Type: multipart/report; report-type=delivery-status; boundary=\"r\"",
        "",
        "--r",
        "Content-Type: multipart/related; boundary=\"h\"",
        "",
        "--h",
        "Content-Type: text/html",
        "",
        &html,
        "--h",
        "Content-Type: image/png",
        "Content-ID: <img1>",
        "Content-Transfer-Encoding: base64",
        "",
        &image,
        "--h--",
        "--r",
        "Content-Type: message/delivery-status",
        "",
        "Final-Recipient: rfc822; x@example.com",
        "Action: failed",
        "Status: 5.1.1",
        "",
        "--r",
        "Content-Type: message/rfc822",
        "",
        "From: a@example.com\r\nMessage-ID: <orig@example.com>\r\nContent-Type: text/plain\r\n\r\nhello",
        "--r",
        "Content-Type: text/rfc822",
        "",
        "Received: from x\r\nMessage-ID: <zoho@example.com>",
        "--r--",
        "",
    ]
    .join("\r\n");
    let d = detect(raw.as_bytes());
    assert_eq!(d.recipient.as_deref(), Some("x@example.com"));
    assert_eq!(d.message_id.as_deref(), Some("<orig@example.com>"));
}

#[test]
fn a_report_of_many_fields_and_recipients_is_read_in_linear_time() {
    // One per-message block of 4000 names and 1700 recipient blocks, within the 64 KB cap. Merging
    // the per-message fields into every recipient anew took seconds
    let build = |fields: usize, recipients: usize| {
        let mut report = String::new();
        for i in 0..fields {
            report.push_str(&format!("k{i}:x\n"));
        }
        report.push_str(&"\nFinal-Recipient:a\n".repeat(recipients));
        report_with_text("x", &report)
    };
    let raw = build(4000, 1700);
    let start = Instant::now();
    let d = detect(&raw);
    let elapsed = start.elapsed();
    assert!(elapsed < Duration::from_millis(500), "{elapsed:?}");
    assert_eq!(d.reports.len(), 1700);
    assert_eq!(d.recipient.as_deref(), Some("a"));
    assert_linear("fields and recipients", |n| build(n / 12, n / 30));
}
