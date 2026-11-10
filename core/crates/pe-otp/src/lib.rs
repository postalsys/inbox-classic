//! Finds the one-time code (login, verification, two-factor and similar codes) in an email
//! message. A port of otp-detect (../otp-detect, @postalsys/otp-detect), with its trained model.
//!
//! The HTML body is rendered to text with the style of every piece (font size, bold, letter
//! spacing, links, hidden preheaders, quoted history), code-like tokens are taken from it and from
//! the plain text, and gradient boosted trees score each from its context. The best candidate at
//! or above the threshold is the answer.
//!
//! The features must be exactly those otp-detect computes, as the model was trained on them: the
//! renderer is otp-detect's own (not an HTML5 parser), its regular expressions keep their
//! JavaScript meaning (pe-jsre), and every position and length is counted in UTF-16 code units.
//! `tests/conformance.rs` checks the feature vectors and scores against otp-detect's.
//!
//! Prefer a code from an `OTP-Token` header (`pe_mime::otp_token`) when the message has one.
//! Neither the header nor the body is authenticated: check that the message passes DKIM for the
//! sender's domain before offering a code to a user. Work is linear in the size of the message,
//! which is cut at 512 KB per body.
#![forbid(unsafe_code)]

pub mod analyze;
pub mod candidates;
pub mod doc;
pub mod features;
pub mod html;
mod js;
pub mod keywords;
pub mod model;

use std::collections::HashMap;

pub use analyze::{MessageInput, analyze};
pub use doc::Source;
pub use model::{MODEL, Model};

#[derive(Debug, Clone, PartialEq)]
pub struct OtpCandidate {
    /// The code as it should be typed
    pub code: String,
    /// The code as printed in the message
    pub raw: String,
    /// Probability, 0 to 1, that this is the one-time code
    pub score: f64,
    /// Which body the best occurrence was found in
    pub source: Source,
}

/// The threshold the built-in model was tuned with
pub fn default_threshold() -> f64 {
    MODEL.threshold
}

fn scored(input: &MessageInput, model: &Model) -> Vec<OtpCandidate> {
    // The same code printed several times counts once, with its best score
    let mut best: Vec<OtpCandidate> = Vec::new();
    let mut index: HashMap<String, usize> = HashMap::new();
    for occurrence in analyze(input) {
        let score = model.predict(&occurrence.features);
        let candidate = occurrence.candidate;
        match index.get(&candidate.code) {
            Some(&i) => {
                if score > best[i].score {
                    best[i] = OtpCandidate {
                        code: candidate.code,
                        raw: candidate.raw,
                        score,
                        source: occurrence.source,
                    };
                }
            }
            None => {
                index.insert(candidate.code.clone(), best.len());
                best.push(OtpCandidate {
                    code: candidate.code,
                    raw: candidate.raw,
                    score,
                    source: occurrence.source,
                });
            }
        }
    }
    // Stable, so equal scores keep the order the codes were first seen in
    best.sort_by(|a, b| b.score.total_cmp(&a.score));
    best
}

/// Every code-like token in the message with its score, best first. Meant for debugging and for
/// callers that want to apply their own rules.
pub fn score_candidates(input: &MessageInput) -> Vec<OtpCandidate> {
    scored(input, &MODEL)
}

/// The one-time code of a parsed email, or None. The message is not trusted: check that it is
/// authenticated (DKIM aligned with the sender) before offering the code to a user.
pub fn detect_otp(input: &MessageInput) -> Option<OtpCandidate> {
    detect_otp_with_threshold(input, MODEL.threshold)
}

/// [`detect_otp`] with another minimum score than the model's own
pub fn detect_otp_with_threshold(input: &MessageInput, threshold: f64) -> Option<OtpCandidate> {
    scored(input, &MODEL)
        .into_iter()
        .next()
        .filter(|top| top.score >= threshold)
}
