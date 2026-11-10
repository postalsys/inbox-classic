//! The OTP-Token header (draft-goto-otp-token-01) through the message parser, the cases of
//! postal-mime's test/otp-token-test.ts.

use pe_mime::OtpToken;
use pe_mime::parser::parse;

fn message(headers: &[&str]) -> String {
    let mut lines: Vec<&str> = headers.to_vec();
    lines.extend(["Subject: Code", "", "Your code is 123456", ""]);
    lines.join("\r\n")
}

fn otp_of(headers: &[&str]) -> Option<OtpToken> {
    parse(message(headers).as_bytes()).unwrap().otp
}

fn token(code: &str, origin: &str) -> Option<OtpToken> {
    Some(OtpToken {
        code: code.into(),
        origin: origin.into(),
    })
}

fn example() -> Option<OtpToken> {
    token("123456", "https://example.com")
}

#[test]
fn reads_headers() {
    let cases: &[(&str, &[&str], Option<OtpToken>)] = &[
        (
            "the passcode and origin",
            &[r#"OTP-Token: "123456"; origin="https://example.com""#],
            example(),
        ),
        (
            "the header name in any case",
            &[r#"otp-TOKEN: "123456"; origin="https://example.com""#],
            example(),
        ),
        ("no OTP-Token header", &[], None),
        (
            "the header more than once",
            &[
                r#"OTP-Token: "123456"; origin="https://example.com""#,
                r#"OTP-Token: "654321"; origin="https://example.com""#,
            ],
            None,
        ),
        (
            "whitespace before the colon",
            &[r#"OTP-Token : "123456"; origin="https://example.com""#],
            None,
        ),
        (
            "a folded header",
            &["OTP-Token: \"123456\";\r\n origin=\"https://example.com\""],
            example(),
        ),
        (
            // RFC 9651 only allows SP after the semicolon, so a fold with a tab fails the parse
            "a header folded with a tab",
            &["OTP-Token: \"123456\";\r\n\torigin=\"https://example.com\""],
            None,
        ),
        (
            "an escaped passcode",
            &[r#"OTP-Token: "a\"b\\c d"; origin="https://example.com""#],
            token("a\"b\\c d", "https://example.com"),
        ),
        (
            "unknown parameters of any type",
            &[
                r#"OTP-Token: "123456"; token=:NjU0MzIx:; ttl=600; ratio=1.5; flag; on=?1; at=@1700000000; mode=fast/x; label=%"caf%c3%a9"; origin="https://example.com""#,
            ],
            example(),
        ),
        (
            "the last origin parameter",
            &[r#"OTP-Token: "123456"; origin="https://a.example"; origin="https://b.example""#],
            token("123456", "https://b.example"),
        ),
        (
            "a passcode with non-ASCII characters",
            &[r#"OTP-Token: "12345é"; origin="https://example.com""#],
            None,
        ),
        (
            "an empty passcode",
            &[r#"OTP-Token: ""; origin="https://example.com""#],
            None,
        ),
    ];
    for (name, headers, expected) in cases {
        assert_eq!(&otp_of(headers), expected, "{name}");
    }
}

#[test]
fn leaves_otp_unset_without_the_header() {
    assert_eq!(parse(message(&[]).as_bytes()).unwrap().otp, None);
}

#[test]
fn ignores_the_header_of_a_mime_part() {
    let raw = [
        "Content-Type: multipart/mixed; boundary=AAA",
        "",
        "--AAA",
        "Content-Type: text/plain",
        r#"OTP-Token: "123456"; origin="https://example.com""#,
        "",
        "Your code is 123456",
        "--AAA--",
        "",
    ]
    .join("\r\n");
    assert_eq!(parse(raw.as_bytes()).unwrap().otp, None);
}

#[test]
fn ignores_the_header_of_a_forwarded_message() {
    let raw = [
        "Content-Type: message/rfc822",
        "",
        r#"OTP-Token: "123456"; origin="https://example.com""#,
        "Subject: Code",
        "",
        "Your code is 123456",
        "",
    ]
    .join("\r\n");
    assert_eq!(parse(raw.as_bytes()).unwrap().otp, None);
}

#[test]
fn rejects_invalid_header_values() {
    for value in [
        "",
        r#"123456; origin="https://example.com""#,
        r#"abc; origin="https://example.com""#,
        r#""123456""#,
        r#""123456"; origin=https"#,
        r#""123456"; origin"#,
        r#""123456"; origin=:aHR0cHM6Ly9leGFtcGxlLmNvbQ==:"#,
        r#""123456" ; origin="https://example.com""#,
        r#""123456"; Origin="https://example.com""#,
        r#""123456"; origin="https://example.com" x"#,
        r#""123456"; origin="https://example.com","#,
        r#""123456", "654321"; origin="https://example.com""#,
        r#""12345\6"; origin="https://example.com""#,
        r#""123456; origin="https://example.com""#,
        r#""123456"; origin="https://example.com"; ttl=1."#,
        r#""123456"; origin="https://example.com"; ttl=1.2345"#,
        r#""123456"; origin="https://example.com"; ttl=1234567890123456"#,
        r#""123456"; origin="https://example.com"; at=@1.5"#,
        r#""123456"; origin="https://example.com"; on=?2"#,
        r#""123456"; origin="https://example.com"; label=%"caf%C3%A9""#,
        r#""123456"; origin="https://example.com"; label=%"%ff""#,
        r#"=?utf-8?Q?=22123456=22?=; origin="https://example.com""#,
    ] {
        assert_eq!(otp_of(&[&format!("OTP-Token: {value}")]), None, "{value}");
    }
}

#[test]
fn ignores_a_header_longer_than_8_kib() {
    let code = "x".repeat(8192 - r#"""; origin="https://example.com""#.len());
    assert_eq!(
        otp_of(&[&format!(r#"OTP-Token: "{code}"; origin="https://example.com""#)]),
        token(&code, "https://example.com")
    );
    assert_eq!(
        otp_of(&[&format!(r#"OTP-Token: "{code}x"; origin="https://example.com""#)]),
        None
    );
}
