//! Finds every token in a document that could be a one-time code, a port of otp-detect's
//! src/candidates.ts. This step is deliberately generous: a code it misses can never be found,
//! while a wrong candidate only costs the scorer one more row to reject.

use std::sync::LazyLock;

use regex::Regex;

use crate::doc::Doc;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CandidateKind {
    Token,
    DashedPart,
    Grouped,
    Spaced,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Candidate {
    /// The code as it would be typed: separators inside digit groups and spaced letters removed
    pub code: String,
    /// The text as it appears in the document
    pub raw: String,
    /// Byte offsets into the document text
    pub start: usize,
    pub end: usize,
    pub kind: CandidateKind,
}

static TOKEN: LazyLock<Regex> = LazyLock::new(|| Regex::new("[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*").expect("valid"));
// Checked once per whitespace separated chunk, never per token, so a long blob stays linear
static URL_OR_ADDRESS: LazyLock<Regex> =
    LazyLock::new(|| pe_jsre::regex(r"://|^www\.|@[A-Za-z0-9-]+\.|\.[a-z]{2,6}/", "i"));
static CHUNK: LazyLock<Regex> = LazyLock::new(|| pe_jsre::regex(r"\S+", "g"));

// Characters that glue a token to its neighbour into something that is not a code: 12.50, 10:30,
// 1,000, a/b, user@host, snake_case
const JOINERS: &[u8] = b".,:/@_\\=&?%+";

pub const MAX_CANDIDATES: usize = 400;

struct Token {
    start: usize,
    end: usize,
}

fn is_digits(s: &str) -> bool {
    !s.is_empty() && s.bytes().all(|b| b.is_ascii_digit())
}

/// Whether a token without separators looks like a code
pub fn code_like(core: &str) -> bool {
    let len = core.len();
    let has = |f: fn(&u8) -> bool| core.as_bytes().iter().any(f);
    if len > 12 && len <= 40 {
        // Long random validation codes mix upper case, lower case and digits (domain validation)
        return has(u8::is_ascii_uppercase)
            && has(u8::is_ascii_lowercase)
            && has(u8::is_ascii_digit)
            && core.bytes().all(|b| b.is_ascii_alphanumeric());
    }
    if !(4..=12).contains(&len) {
        return false;
    }
    if is_digits(core) {
        return len <= 10;
    }
    if !has(u8::is_ascii_digit) {
        // Letter-only codes are printed in capitals (Steam Guard style: QWKZT)
        return core.bytes().all(|b| b.is_ascii_uppercase()) && len <= 10;
    }
    if !has(u8::is_ascii_alphabetic) {
        return false;
    }
    // 21st, 100mg, 1080p, 12px, 5000mAh
    !is_measure(core)
}

/// `/^\d+(?:[a-z]{1,3}|mAh|MB|GB|KB|kB|Hz)$/`
fn is_measure(core: &str) -> bool {
    let digits = core.bytes().take_while(u8::is_ascii_digit).count();
    let unit = &core[digits..];
    digits > 0
        && ((1..=3).contains(&unit.len()) && unit.bytes().all(|b| b.is_ascii_lowercase())
            || matches!(unit, "mAh" | "MB" | "GB" | "KB" | "kB" | "Hz"))
}

fn byte_at(text: &str, at: Option<usize>) -> Option<u8> {
    at.and_then(|at| text.as_bytes().get(at).copied())
}

/// The character before the byte offset is ASCII alphanumeric. A JavaScript string read at
/// offset - 1 gives the last code unit of whatever is there, which for anything else than ASCII is
/// no letter or digit either.
fn alnum_before(text: &str, at: usize) -> bool {
    at > 0 && text.as_bytes()[at - 1].is_ascii_alphanumeric()
}

fn glued_to_neighbour(text: &str, start: usize, end: usize) -> bool {
    let bytes = text.as_bytes();
    if start > 0 && JOINERS.contains(&bytes[start - 1]) && alnum_before(text, start - 1) {
        return true;
    }
    byte_at(text, Some(end)).is_some_and(|b| JOINERS.contains(&b))
        && byte_at(text, Some(end + 1)).is_some_and(|b| b.is_ascii_alphanumeric())
}

fn make(text: &str, start: usize, end: usize, kind: CandidateKind, code: &str) -> Candidate {
    Candidate {
        code: code.to_string(),
        raw: text[start..end].to_string(),
        start,
        end,
        kind,
    }
}

fn token_candidates(text: &str, out: &mut Vec<Candidate>) {
    let mut tokens = Vec::new();
    for chunk in CHUNK.find_iter(text) {
        if URL_OR_ADDRESS.is_match(chunk.as_str()) {
            continue;
        }
        for m in TOKEN.find_iter(chunk.as_str()) {
            let start = chunk.start() + m.start();
            let end = chunk.start() + m.end();
            if !glued_to_neighbour(text, start, end) {
                tokens.push(Token { start, end });
                add_token(text, start, m.as_str(), out);
            }
        }
    }
    add_digit_groups(text, &tokens, out);
}

fn add_token(text: &str, start: usize, value: &str, out: &mut Vec<Candidate>) {
    let end = start + value.len();
    if !value.contains('-') {
        if code_like(value) {
            out.push(make(text, start, end, CandidateKind::Token, value));
        }
        return;
    }
    let parts: Vec<&str> = value.split('-').collect();
    let joined = parts.concat();
    if is_digits(&joined) {
        // 123-456, 12-34-56: typed without the dashes. Other digit runs are phone numbers and dates
        if parts.iter().all(|p| (2..=4).contains(&p.len())) && code_like(&joined) {
            out.push(make(text, start, end, CandidateKind::Grouped, &joined));
        }
        return;
    }
    if joined.len() >= 4
        && value.len() <= 40
        && joined.bytes().any(|b| b.is_ascii_digit())
        && joined.bytes().any(|b| b.is_ascii_alphabetic())
    {
        // ABCD-1234, G-123456, 4a7c01e9-82f3b6d0: keys printed with their dashes. Digit-only runs
        // that are not two to four even groups are phone numbers and dates (372-5-555-0100)
        out.push(make(text, start, end, CandidateKind::Token, value));
    }
    let mut offset = start;
    for part in parts {
        if code_like(part) {
            out.push(make(text, offset, offset + part.len(), CandidateKind::DashedPart, part));
        }
        offset += part.len() + 1;
    }
}

/// "123 456" and "1234 5678": two or three digit groups separated by a single space
fn add_digit_groups(text: &str, tokens: &[Token], out: &mut Vec<Candidate>) {
    let bytes = text.as_bytes();
    for i in 0..tokens.len() {
        let mut digits = String::new();
        for j in i..tokens.len().min(i + 3) {
            let token = &tokens[j];
            let separated_by_space = j == i || (token.start == tokens[j - 1].end + 1 && bytes[token.start - 1] == b' ');
            let value = &text[token.start..token.end];
            if !(is_digits(value) && (2..=4).contains(&value.len())) || !separated_by_space {
                break;
            }
            digits.push_str(value);
            if j > i && (6..=9).contains(&digits.len()) {
                out.push(make(text, tokens[i].start, token.end, CandidateKind::Grouped, &digits));
            }
        }
    }
}

fn spaced_char(b: u8) -> bool {
    b.is_ascii_uppercase() || b.is_ascii_digit()
}

/// `/(?<![A-Za-z0-9])[A-Z0-9](?:[ \n][A-Z0-9]){3,9}(?![A-Za-z0-9])/g`: single characters separated
/// by single spaces or line breaks, "4 8 2 9 1 7", or one digit per table cell
fn spaced_candidates(text: &str, out: &mut Vec<Candidate>) {
    let bytes = text.as_bytes();
    let alnum_at = |at: usize| bytes.get(at).is_some_and(u8::is_ascii_alphanumeric);
    let mut at = 0;
    while at < bytes.len() {
        if !spaced_char(bytes[at]) || alnum_before(text, at) {
            at += 1;
            continue;
        }
        // Greedy repetitions, then back off one when a letter or digit follows: after fewer
        // repetitions a separator follows, which the lookahead accepts
        let mut reps = 0;
        while reps < 9
            && matches!(bytes.get(at + 1 + 2 * reps), Some(b' ' | b'\n'))
            && bytes.get(at + 2 + 2 * reps).copied().is_some_and(spaced_char)
        {
            reps += 1;
        }
        if alnum_at(at + 1 + 2 * reps) {
            reps = reps.saturating_sub(1);
        }
        if reps < 3 {
            at += 1;
            continue;
        }
        let end = at + 1 + 2 * reps;
        let code: String = text[at..end].chars().filter(|&c| c != ' ' && c != '\n').collect();
        if code.bytes().any(|b| b.is_ascii_digit()) {
            out.push(make(text, at, end, CandidateKind::Spaced, &code));
        }
        at = end;
    }
}

pub fn extract_candidates(doc: &Doc) -> Vec<Candidate> {
    let mut out = Vec::new();
    token_candidates(&doc.text, &mut out);
    spaced_candidates(&doc.text, &mut out);
    out.sort_by(|a, b| a.start.cmp(&b.start).then(b.end.cmp(&a.end)));
    out.truncate(MAX_CANDIDATES);
    out
}
