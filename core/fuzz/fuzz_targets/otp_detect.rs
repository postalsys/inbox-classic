//! A message from a sender through one-time code detection: the bytes are split into a subject, a
//! plain text and an HTML body, so the HTML renderer, the candidate finder and the features all see
//! hostile input. Also the OTP-Token header parser, on the same bytes as a header value.
#![no_main]

use libfuzzer_sys::fuzz_target;
use pe_mime::parser::Header;
use pe_otp::{MessageInput, analyze, features::FEATURE_NAMES, score_candidates};

fuzz_target!(|data: &[u8]| {
    let input = String::from_utf8_lossy(data);
    let mut parts = input.splitn(3, '\u{0}');
    let (first, second, third) = (parts.next(), parts.next(), parts.next());
    let message = MessageInput {
        subject: third.and(first),
        text: second.or(first),
        html: third.or(first),
    };
    for occurrence in analyze(&message) {
        assert_eq!(occurrence.features.len(), FEATURE_NAMES.len());
        assert!(!occurrence.candidate.code.is_empty());
    }
    for candidate in score_candidates(&message) {
        assert!((0.0..=1.0).contains(&candidate.score));
    }

    let header = Header {
        key: "otp-token".into(),
        original_key: "OTP-Token".into(),
        value: input.into_owned(),
    };
    if let Some(token) = pe_mime::otp_token(&[header]) {
        assert!(!token.code.is_empty());
    }
});
