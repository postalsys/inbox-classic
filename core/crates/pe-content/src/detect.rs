//! Stage 4: detectors. They return evidence with a strength, never a verdict; only the classifier
//! assigns labels.

use std::collections::BTreeSet;
use std::sync::LazyLock;

use crate::block::{BlockFeatures, Evidence, EvidenceKind};
use crate::jsre::JsRegex;
use crate::patterns::patterns;
use crate::util::{js_len, js_trim};

/// Longest run of blank lines tolerated inside an embedded header block.
const MAX_GAP: usize = 1;

/// Minimum distinct roles before a run of header-like lines counts as an anchor.
const MIN_FIELDS: usize = 3;

/// An embedded From: line carries an address in some form. Each bracketed form stops at its own
/// opener, so a run of openers is charged only up to the next one.
static ORIGINATOR_VALUE: LazyLock<JsRegex> =
    LazyLock::new(|| JsRegex::fixed(r"(@[\w-]+\.[\w.-]+|<[^<>@]*@[^<>]*>|mailto:|\[[^[\]@]*@[^[\]]*\])", "i"));

/// Longest field value the originator and date checks run on.
const MAX_CHECKED_VALUE_LENGTH: usize = 300;

/// A date field carries something date shaped: a numeric date, a month or day name, or a time.
static DATE_VALUE: LazyLock<JsRegex> = LazyLock::new(|| {
    JsRegex::fixed(
        r"(\d{1,4}[./-]\d{1,2}[./-]\d{1,4}|\b\d{1,2}:\d{2}\b|\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|mon|tue|wed|thu|fri|sat|sun|maj|okt|sty|lut|kwi|cze|lip|sie|wrz|paz|lis|gru|tammi|helmi|maalis|huhti|touko|kesä|heinä|elo|syys|loka|marras|joulu)[a-zäö]*\.?\b|(^|\s)(янв|фев|мар|апр|ма[йя]|июн|июл|авг|сен|окт|ноя|дек)|\b(esmaspäev|teisipäev|kolmapäev|neljapäev|reede|laupäev|pühapäev|montag|dienstag|mittwoch|donnerstag|freitag|samstag|sonntag|lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche)\b)",
        "i",
    )
});

static MAILTO: LazyLock<JsRegex> = LazyLock::new(|| JsRegex::fixed("mailto:", "i"));
static MAILTO_URL: LazyLock<JsRegex> = LazyLock::new(|| JsRegex::fixed(r" ?\bmailto:\S+", "i"));

pub(crate) static REPLY_SUBJECT: LazyLock<JsRegex> =
    LazyLock::new(|| JsRegex::fixed(r"^\s*(re|aw|sv|vs|vast|antw|res|odp|ответ)\s*(\[\d+\])?\s*:", "i"));
static FORWARD_SUBJECT: LazyLock<JsRegex> = LazyLock::new(|| {
    JsRegex::fixed(
        r"^\s*(fwd?|wg|tr|rv|enc|doorst|pd|vl|ed|edasi|пересл[а-я]*|转发|轉寄|転送)\s*(\[\d+\])?\s*:",
        "i",
    )
});

/// A forward, and not a reply to one.
pub(crate) fn is_forward_subject(subject: &str) -> bool {
    !REPLY_SUBJECT.is_match(subject) && FORWARD_SUBJECT.is_match(subject)
}

fn value_of(line: &str) -> &str {
    line.find(':').map_or("", |colon| js_trim(&line[colon + 1..]))
}

#[derive(Debug, Clone)]
pub(crate) struct ReplyHeaderMatch {
    /// First line of the anchor, inclusive.
    pub start_line: usize,
    /// Last line of the anchor, inclusive.
    pub end_line: usize,
    pub evidence: Evidence,
}

/// A single line attribution such as "On Mon, 13 Jan 2025 at 09:15, Bob wrote:". Lines longer
/// than 300 characters are rejected: a genuine attribution is short.
pub(crate) fn detect_attribution_line(line: &str) -> Option<Evidence> {
    if js_len(line) > 2000 {
        return None;
    }
    // Plain text derived from HTML writes links out as mailto: URLs, which say nothing about the
    // line's shape but push it past the length limit.
    let stripped = if MAILTO.is_match(line) {
        MAILTO_URL.re().replace_all(line, "").into_owned()
    } else {
        line.to_string()
    };
    let trimmed = js_trim(&stripped);
    if trimmed.is_empty() || js_len(trimmed) > 300 {
        return None;
    }
    let mut best: Option<Evidence> = None;
    for pattern in &patterns().reply_headers {
        if !pattern.regex.is_match(trimmed) {
            continue;
        }
        if best.as_ref().is_none_or(|best| pattern.strength > best.strength) {
            best = Some(Evidence::new(
                format!("reply:{}", pattern.id),
                EvidenceKind::ReplyAnchor,
                pattern.strength,
            ));
        }
    }
    best
}

/// A sentence announcing that the reply is written into the quoted text.
pub(crate) fn detect_inline_announcement<S: AsRef<str>>(lines: &[S]) -> Option<Evidence> {
    let announcements = &patterns().inline_announcements;
    for line in lines {
        let line = line.as_ref();
        if js_len(line) > 2000 {
            continue;
        }
        if let Some(pattern) = announcements.iter().find(|pattern| pattern.regex.is_match(line)) {
            return Some(Evidence::new(
                format!("announce:{}", pattern.id),
                EvidenceKind::Hint,
                pattern.strength,
            ));
        }
    }
    None
}

#[derive(Default)]
struct Roles(BTreeSet<String>);

impl Roles {
    fn add(&mut self, role: &str) {
        self.0.insert(role.to_string());
    }

    /// The originator plus a date or a subject, and no transport field.
    fn is_strong(&self) -> bool {
        !self.0.contains("transport")
            && self.0.len() >= MIN_FIELDS
            && self.0.contains("originator")
            && (self.0.contains("date") || self.0.contains("subject"))
    }
}

/// A lowercase field name or a value ending in a comma: source code or prose, not a header block.
fn looks_like_code(line: &str, value: &str) -> bool {
    line.as_bytes().first().is_some_and(u8::is_ascii_lowercase) || value.ends_with(',')
}

/// An embedded header block (From/Sent/To/Subject lines) starting at or after `from`.
///
/// Single pass: lines partition into chains of header-shaped lines joined by gaps of at most one
/// blank line, and only the start of each chain can be the earliest strong start.
pub(crate) fn detect_quoted_header_block<S: AsRef<str>>(lines: &[S], from: usize) -> Option<ReplyHeaderMatch> {
    let fields = &patterns().quoted_header_fields;
    // Below a single line attribution on purpose: a person can paste this shape.
    let evidence = || Evidence::new("reply:quoted_header_block", EvidenceKind::ReplyAnchor, 0.88);

    let mut chain_start: Option<usize> = None;
    let mut roles = Roles::default();
    let mut last: Option<usize> = None;
    let mut gap = 0;

    let strong = |roles: &Roles, chain_start: Option<usize>, last: Option<usize>| match (chain_start, last) {
        (Some(start), Some(last)) if roles.is_strong() && last >= start => Some((start, last)),
        _ => None,
    };

    for (j, line) in lines.iter().enumerate().skip(from) {
        let line = js_trim(line.as_ref());

        if line.is_empty() {
            if chain_start.is_none() {
                chain_start = Some(j);
                gap = 1;
                continue;
            }
            gap += 1;
            if gap <= MAX_GAP {
                continue;
            }
            if let Some((start, end)) = strong(&roles, chain_start, last) {
                return Some(ReplyHeaderMatch {
                    start_line: start,
                    end_line: end,
                    evidence: evidence(),
                });
            }
            roles = Roles::default();
            last = None;
            chain_start = Some(j + 1 - MAX_GAP);
            gap = MAX_GAP;
            continue;
        }

        let Some(matched) = fields.iter().find(|pattern| pattern.regex.is_match(line)) else {
            if let Some((start, end)) = strong(&roles, chain_start, last) {
                return Some(ReplyHeaderMatch {
                    start_line: start,
                    end_line: end,
                    evidence: evidence(),
                });
            }
            roles = Roles::default();
            last = None;
            chain_start = None;
            gap = 0;
            continue;
        };

        if chain_start.is_none() {
            chain_start = Some(j);
        }
        gap = 0;
        let role = matched
            .role
            .as_deref()
            .filter(|role| !role.is_empty())
            .unwrap_or(&matched.id);
        let value = value_of(line);
        if role == "transport" {
            roles.add(role);
        } else if looks_like_code(line, value) {
            // Continues the chain, but earns no role.
        } else if role == "originator" || role == "date" {
            let check = if role == "originator" {
                &ORIGINATOR_VALUE
            } else {
                &DATE_VALUE
            };
            if js_len(value) <= MAX_CHECKED_VALUE_LENGTH && check.is_match(value) {
                roles.add(role);
            }
        } else {
            roles.add(role);
        }
        last = Some(j);
    }

    strong(&roles, chain_start, last).map(|(start, end)| ReplyHeaderMatch {
        start_line: start,
        end_line: end,
        evidence: evidence(),
    })
}

/// The Outlook style rule, a run of underscores on its own line, or a run of symbols.
pub(crate) fn detect_rule_separator(line: &str) -> Option<Evidence> {
    let trimmed = js_trim(line);
    let run_of = |set: &[char]| trimmed.chars().count() >= 10 && trimmed.chars().all(|c| set.contains(&c));
    if run_of(&['_']) {
        return Some(Evidence::new(
            "reply:outlook_underscore_rule",
            EvidenceKind::Separator,
            0.6,
        ));
    }
    if run_of(&['*', '=', '~']) {
        return Some(Evidence::new("separator:symbol_rule", EvidenceKind::Separator, 0.35));
    }
    None
}

/// A forward marker such as "---------- Forwarded message ---------".
pub(crate) fn detect_forward_marker(line: &str) -> Option<Evidence> {
    let trimmed = js_trim(line);
    if trimmed.is_empty() || js_len(trimmed) > 300 {
        return None;
    }
    let mut best: Option<Evidence> = None;
    for pattern in &patterns().forward_headers {
        // The bare From: pattern only means something as part of a header block.
        if pattern.id == "fyi_forward_header_block" || !pattern.regex.is_match(trimmed) {
            continue;
        }
        if best.as_ref().is_none_or(|best| pattern.strength > best.strength) {
            best = Some(Evidence::new(
                format!("forward:{}", pattern.id),
                EvidenceKind::ForwardAnchor,
                pattern.strength,
            ));
        }
    }
    best
}

/// Disclaimers sit after the sender's words; only the opening slice is excluded.
const MIN_FOOTER_POSITION: f64 = 0.1;

/// Legal and organisational footer phrases.
pub(crate) fn detect_disclaimer(text: &str, features: &BlockFeatures) -> Vec<Evidence> {
    if features.position < MIN_FOOTER_POSITION || features.is_all_blank {
        return Vec::new();
    }
    patterns()
        .disclaimer_phrases
        .iter()
        .filter(|pattern| pattern.regex.is_match(text))
        .map(|pattern| {
            Evidence::new(
                format!("disclaimer:{}", pattern.id),
                EvidenceKind::Disclaimer,
                pattern.strength,
            )
        })
        .collect()
}

/// Signatures beyond this many lines are almost always something else.
const MAX_SIGNATURE_LINES: usize = 12;

/// The RFC 3676 delimiter, "-- " on its own line.
pub(crate) fn detect_signature_delimiter(line: &str) -> Option<Evidence> {
    patterns()
        .signature_delimiters
        .iter()
        .find(|pattern| pattern.regex.is_match(line))
        .map(|pattern| {
            Evidence::new(
                format!("signature:{}", pattern.id),
                EvidenceKind::Signature,
                pattern.strength,
            )
        })
}

/// Phrase level evidence, such as "Sent from my phone" or a closing greeting.
pub(crate) fn detect_signature_phrases<S: AsRef<str>>(lines: &[S]) -> Vec<Evidence> {
    let phrases = &patterns().signature_phrases;
    let mut found: Vec<Evidence> = Vec::new();
    for line in lines {
        let trimmed = js_trim(line.as_ref());
        if trimmed.is_empty() || js_len(trimmed) > 200 {
            continue;
        }
        for pattern in phrases {
            if !pattern.regex.is_match(trimmed) {
                continue;
            }
            let id = format!("signature:{}", pattern.id);
            match found.iter_mut().find(|existing| existing.id == id) {
                Some(existing) if existing.strength < pattern.strength => existing.strength = pattern.strength,
                Some(_) => {}
                None => found.push(Evidence::new(id, EvidenceKind::Signature, pattern.strength)),
            }
        }
    }
    found
}

/// Weak shape evidence for a short trailing block with contact details.
pub(crate) fn detect_signature_shape(features: &BlockFeatures) -> Option<Evidence> {
    if features.is_all_blank || features.position < MIN_FOOTER_POSITION {
        return None;
    }
    if features.line_count > MAX_SIGNATURE_LINES || features.word_count > 80 {
        return None;
    }
    let contactish = features.has_email_address || features.has_phone_number || features.has_url;
    if !contactish || features.short_line_ratio < 0.6 {
        return None;
    }
    Some(Evidence::new("signature:shape", EvidenceKind::Signature, 0.45))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn matches_attribution_lines_in_several_languages() {
        for line in [
            "On Mon, 13 Jan 2025 at 09:15, Bob Smith <bob@example.com> wrote:",
            "Le lun. 13 janv. 2025 à 09:15, Bob <bob@example.com> a écrit :",
            "Am Mo., 13. Jan. 2025 um 09:15 Uhr schrieb Bob <bob@example.com>:",
            "Bob Smith wrote:",
        ] {
            assert!(detect_attribution_line(line).is_some(), "{line}");
        }
        for line in [
            "As I wrote:",
            "On the other hand I think we should wait.",
            "Like I wrote: no",
        ] {
            assert!(detect_attribution_line(line).is_none(), "{line}");
        }
    }

    #[test]
    fn anchors_on_every_address_form() {
        let rest = ["Sent: Monday, 13 January 2025 09:15", "Subject: hi"];
        for from in [
            "From: Bob <bob@example.com>",
            "From: bob@example.com",
            "From: Bob [bob@example.com]",
            "From: Bob [mailto:bob@example.com]",
        ] {
            let lines: Vec<&str> = std::iter::once(from).chain(rest).collect();
            assert!(detect_quoted_header_block(&lines, 0).is_some(), "{from}");
        }
        let lines = ["From: the address that sent the message", rest[0], rest[1]];
        assert!(detect_quoted_header_block(&lines, 0).is_none());
        let long = format!("From: Bob <bob@example.com>{}", " x".repeat(200));
        let lines = [long.as_str(), rest[0], rest[1]];
        assert!(detect_quoted_header_block(&lines, 0).is_none());
    }

    #[test]
    fn detects_subjects() {
        assert!(REPLY_SUBJECT.is_match("Re: hi"));
        assert!(REPLY_SUBJECT.is_match("AW[2]: hi"));
        assert!(is_forward_subject("Fwd: hi"));
        assert!(!is_forward_subject("Re: Fwd: hi"));
    }
}
