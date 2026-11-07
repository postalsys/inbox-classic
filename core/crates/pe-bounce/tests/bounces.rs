//! analyze(): bounces and delay notices, every recipient of a report, and ordinary mail that only
//! quotes an SMTP error.

use pe_bounce::{Action, BounceKind, Label, analyze, detect};

fn fixture(name: &str) -> Vec<u8> {
    std::fs::read(format!("{}/tests/fixtures/bounces/{name}", env!("CARGO_MANIFEST_DIR"))).unwrap()
}

/// A plain text message the way EmailEngine's heuristics tests build one
fn message(from: &str, extra_headers: &[&str], body: &str) -> Vec<u8> {
    let mut lines = vec![
        format!("From: {from}"),
        "To: sender@example.com".into(),
        "Subject: Re: the server".into(),
        "Date: Wed, 01 Jan 2025 00:00:00 +0000".into(),
        "MIME-Version: 1.0".into(),
    ];
    lines.extend(extra_headers.iter().map(|h| h.to_string()));
    lines.push("Content-Type: text/plain; charset=utf-8".into());
    lines.push(String::new());
    lines.push(body.into());
    lines.join("\r\n").into_bytes()
}

const DAEMON: &str = "Mail Delivery System <mailer-daemon@mta.example.com>";

#[test]
fn every_fixture_is_a_failure_but_the_delayed_one() {
    for name in [
        "163.eml",
        "fastmail.eml",
        "gmail.eml",
        "hotmail.eml",
        "mailru.eml",
        "outlook.eml",
        "postfix.eml",
        "rambler.eml",
        "workmail.eml",
        "yahoo.eml",
        "zoho.eml",
        "zonemta.eml",
    ] {
        let bounce = analyze(&fixture(name)).unwrap_or_else(|| panic!("{name} is a bounce"));
        assert_eq!(bounce.kind, BounceKind::Failed, "{name}");
        assert_eq!(bounce.recipients.len(), 1, "{name}");
        let recipient = &bounce.recipients[0];
        assert!(recipient.address.is_some(), "{name}");
        assert!(recipient.diagnostic.is_some(), "{name}");
        assert!(
            bounce.original.as_ref().and_then(|o| o.message_id.as_ref()).is_some(),
            "{name}"
        );
    }
    let bounce = analyze(&fixture("delayed.eml")).unwrap();
    assert_eq!(bounce.kind, BounceKind::Delayed);
    let recipient = &bounce.recipients[0];
    assert_eq!(recipient.address.as_deref(), Some("user@example.com"));
    assert_eq!(recipient.status.as_deref(), Some("4.4.1"));
    assert_eq!(recipient.label, Label::ServerError);
}

#[test]
fn gmail_in_full() {
    let bounce = analyze(&fixture("gmail.eml")).unwrap();
    let recipient = &bounce.recipients[0];
    assert_eq!(recipient.address.as_deref(), Some("jhfthgfuyfhvjkugjhvjuyfv@hot.ee"));
    assert_eq!(recipient.status.as_deref(), Some("5.1.1"));
    assert_eq!(
        recipient.diagnostic.as_deref(),
        Some(
            "550 5.1.1 <jhfthgfuyfhvjkugjhvjuyfv@hot.ee>: Recipient address rejected: User unknown in relay recipient table"
        )
    );
    assert_eq!(recipient.label, Label::UserUnknown);
    assert_eq!(recipient.action, Action::Remove);
    assert_eq!(bounce.reporting_mta.as_deref(), Some("googlemail.com"));
    let original = bounce.original.unwrap();
    assert_eq!(original.subject.as_deref(), Some("proovikiri"));
    assert_eq!(original.to.as_deref(), Some("jhfthgfuyfhvjkugjhvjuyfv@hot.ee"));
}

#[test]
fn zoho_is_a_disabled_mailbox() {
    let bounce = analyze(&fixture("zoho.eml")).unwrap();
    assert_eq!(bounce.recipients[0].label, Label::MailboxDisabled);
    assert_eq!(
        bounce.original.unwrap().message_id.as_deref(),
        Some("<63d982c2660381675199170@smtppro.zoho.com>")
    );
}

#[test]
fn reports_every_recipient_of_a_report() {
    let raw = [
        "From: Mail Delivery System <MAILER-DAEMON@mx.example.com>",
        "Subject: Undelivered Mail Returned to Sender",
        "MIME-Version: 1.0",
        "Content-Type: multipart/report; report-type=delivery-status; boundary=\"B\"",
        "",
        "--B",
        "Content-Type: text/plain",
        "",
        "Some recipients failed.",
        "--B",
        "Content-Type: message/delivery-status",
        "",
        "Reporting-MTA: dns; MX.Example.com",
        "",
        "Final-Recipient: rfc822; first@example.com",
        "Action: failed",
        "Status: 5.1.1",
        "Remote-MTA: dns; mx.first.example",
        "Diagnostic-Code: smtp; 550 5.1.1 User unknown",
        "",
        "Final-Recipient: rfc822; second@example.com",
        "Action: delayed",
        "Status: 4.2.0",
        "Diagnostic-Code: smtp; 450 4.2.0 Greylisted, try again in 5 minutes",
        "",
        "Final-Recipient: rfc822; third@example.com",
        "Action: delivered",
        "Status: 2.0.0",
        "",
        "Final-Recipient: rfc822; fourth@example.com",
        "Action: failed",
        "Status: 5.2.2",
        "Diagnostic-Code: smtp; 552 5.2.2 Mailbox full",
        "--B--",
        "",
    ]
    .join("\r\n");
    let bounce = analyze(raw.as_bytes()).unwrap();
    assert_eq!(bounce.kind, BounceKind::Failed);
    assert_eq!(bounce.reporting_mta.as_deref(), Some("mx.example.com"));
    let addresses: Vec<_> = bounce
        .recipients
        .iter()
        .map(|r| r.address.as_deref().unwrap())
        .collect();
    assert_eq!(
        addresses,
        ["first@example.com", "second@example.com", "fourth@example.com"]
    );
    let [first, second, fourth] = &bounce.recipients[..] else {
        panic!()
    };
    assert_eq!(first.remote_mta.as_deref(), Some("mx.first.example"));
    assert_eq!(first.label, Label::UserUnknown);
    assert_eq!(second.kind, BounceKind::Delayed);
    assert_eq!(second.retry_after, Some(300));
    assert_eq!(fourth.label, Label::MailboxFull);
    assert_eq!(fourth.diagnostic.as_deref(), Some("552 5.2.2 Mailbox full"));
}

#[test]
fn a_delivered_report_is_not_a_bounce() {
    let raw = [
        "From: MAILER-DAEMON@mx.example.com",
        "Content-Type: multipart/report; report-type=delivery-status; boundary=\"B\"",
        "",
        "--B",
        "Content-Type: message/delivery-status",
        "",
        "Reporting-MTA: dns; mx.example.com",
        "",
        "Final-Recipient: rfc822; user@example.com",
        "Action: delivered",
        "Status: 2.0.0",
        "--B--",
    ]
    .join("\r\n");
    assert_eq!(analyze(raw.as_bytes()), None);
}

#[test]
fn delay_notices_found_by_the_heuristics_are_delays() {
    let body = [
        "Hi. This is the mail delivery program at mail.example.com.",
        "THIS IS A WARNING MESSAGE ONLY.",
        "YOU DO NOT NEED TO RESEND YOUR MESSAGE.",
        "",
        "<frank@example.com>:",
        "Sorry, I wasn't able to establish an SMTP connection. (#4.4.1)",
        "I'll keep trying for a while longer.",
        "",
    ]
    .join("\r\n");
    let bounce = analyze(&message(DAEMON, &[], &body)).unwrap();
    assert_eq!(bounce.kind, BounceKind::Delayed);
    assert_eq!(bounce.recipients[0].address.as_deref(), Some("frank@example.com"));
    assert_eq!(bounce.recipients[0].status.as_deref(), Some("4.4.1"));

    let body = "<grace@example.com>: host mx.example.com[203.0.113.4] said: 450 4.2.1 Mailbox temporarily unavailable\r\n(in reply to RCPT TO command)\r\n";
    let bounce = analyze(&message(DAEMON, &[], body)).unwrap();
    assert_eq!(bounce.kind, BounceKind::Delayed);
    assert_eq!(bounce.recipients[0].remote_mta.as_deref(), Some("mx.example.com"));
}

#[test]
fn a_final_bounce_quoting_a_temporary_reply_is_a_failure() {
    let body = [
        "Hi. This is the qmail-send program at mail.example.com.",
        "This is a permanent error; I've given up. Sorry it didn't work out.",
        "",
        "<heidi@example.com>:",
        "Sorry, I wasn't able to establish an SMTP connection. (#4.4.1)",
        "I'm not going to try again; this message has been in the queue too long.",
        "",
    ]
    .join("\r\n");
    let bounce = analyze(&message(DAEMON, &[], &body)).unwrap();
    assert_eq!(bounce.kind, BounceKind::Failed);
}

#[test]
fn a_notice_without_the_address_still_reports_the_reason() {
    let body = "Technical details of permanent failure:\r\n\r\n550 5.7.1 Message rejected due to content policy\r\n";
    let bounce = analyze(&message(DAEMON, &[], body)).unwrap();
    assert_eq!(bounce.recipients[0].address, None);
    assert_eq!(bounce.recipients[0].status.as_deref(), Some("5.7.1"));
}

const QUOTING: &str = "Hi,\r\n\r\nthe server keeps answering this when I write to Bob:\r\n\r\n550 5.1.1 <bob@example.com>: Recipient address rejected: user unknown\r\n\r\n<bob@example.com>: host mx.example.com[192.0.2.1] said: 550 5.1.1 user unknown\r\n\r\nAny idea?\r\n";

#[test]
fn ordinary_mail_quoting_an_smtp_error_is_not_a_bounce() {
    let raw = message("Alice <alice@example.com>", &[], QUOTING);
    assert_eq!(analyze(&raw), None);
    let detection = detect(&raw);
    assert!(!detection.heuristics);
    assert_eq!(detection.recipient, None);

    // Auto-Submitted: no is what a person's mail may say
    let raw = message("Alice <alice@example.com>", &["Auto-Submitted: no"], QUOTING);
    assert_eq!(analyze(&raw), None);
}

#[test]
fn the_heuristics_run_for_a_daemon_or_automatic_mail() {
    for (from, headers) in [
        (DAEMON, &[][..]),
        ("postmaster@example.com", &[][..]),
        ("MAILER-DAEMON", &[][..]),
        ("Robot <robot@example.com>", &["Auto-Submitted: auto-replied"][..]),
    ] {
        let bounce = analyze(&message(from, headers, QUOTING)).unwrap_or_else(|| panic!("{from}"));
        assert_eq!(
            bounce.recipients[0].address.as_deref(),
            Some("bob@example.com"),
            "{from}"
        );
        assert_eq!(bounce.recipients[0].label, Label::UserUnknown, "{from}");
    }
}

#[test]
fn a_failed_recipients_header_alone_is_not_a_bounce() {
    let raw = message(
        "Alice <alice@example.com>",
        &["X-Failed-Recipients: bob@example.com"],
        "Just a note.",
    );
    assert_eq!(analyze(&raw), None);
}

#[test]
fn garbage_is_no_bounce() {
    assert_eq!(analyze(b""), None);
    assert_eq!(analyze(b"\xff\xfe\x00garbage"), None);
    assert_eq!(analyze(b"From: MAILER-DAEMON@x\r\n\r\n"), None);
}
