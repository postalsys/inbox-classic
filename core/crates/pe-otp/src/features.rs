//! Turns each candidate into a fixed-length vector of numbers for the scorer, a port of
//! otp-detect's src/features.ts. FEATURE_NAMES is the contract with the trained model: the model
//! records the names it was fit on, and a model with a different list does not build.
//!
//! Every position and length is counted in UTF-16 code units, as otp-detect counts them.

use std::collections::HashMap;
use std::sync::LazyLock;

use pe_jsre::{advance_utf16, is_space, trim, utf16_len};
use regex::Regex;

use crate::candidates::{Candidate, CandidateKind};
use crate::doc::{Doc, Source, block_around, style_at};
use crate::js::{max0, round};
use crate::keywords::{CUE, KeywordText, Keywords, NEGATIVE, PROMO, STRONG, WEAK};

pub const FEATURE_NAMES: [&str; 69] = [
    // shape
    "len",
    "digits",
    "upper",
    "lower",
    "isDigits",
    "isUpperAlpha",
    "isMixedCase",
    "kindGrouped",
    "kindSpaced",
    "kindDashedPart",
    "hasDash",
    "leadingZero",
    "distinctRatio",
    "trivialSequence",
    "looksYear",
    // characters around it
    "colonBefore",
    "hashBefore",
    "currencyNear",
    "plusOrParenBefore",
    "digitNearby",
    "percentAfter",
    // keywords, distances in characters, capped
    "strongBefore",
    "strongAfter",
    "weakBefore",
    "weakAfter",
    "cueBefore",
    "cueAfter",
    "negBefore",
    "negAfter",
    "strongInLine",
    "weakInLine",
    "negInLine",
    "strongRank",
    // layout and style
    "lineLen",
    "aloneOnLine",
    "blockLen",
    "aloneInBlock",
    "fontSize",
    "fontRatio",
    "isLargestFont",
    "bold",
    "letterSpacing",
    "link",
    "heading",
    "mono",
    "hidden",
    "quoted",
    "relPosition",
    "fromHtml",
    // message
    "occurrences",
    "inOtherDoc",
    "inSubject",
    "subjectStrong",
    "subjectWeak",
    "subjectNeg",
    "docStrong",
    "docCue",
    "docLen",
    "candidates",
    "distinctCodes",
    "candidateIndex",
    // codes that prove nothing: promotions, referrals, invitations
    "promoBefore",
    "promoAfter",
    "promoInLine",
    "docPromo",
    "subjectPromo",
    // letters-only codes are random (QWKZT), words in capitals are not (WEBINAR)
    "vowelRatio",
    // identifiers from code and prose (loginFailedError, retry2fa) have word-like letter runs
    "longestLetterRun",
    "caseChanges",
];

const FAR: usize = 1000;

static CURRENCY: LazyLock<Regex> =
    LazyLock::new(|| pe_jsre::regex(r"[€$£¥₽]|\b(?:eur|usd|gbp|sek|nok|dkk|rub)\b", "i"));

/// Keyword matches as UTF-16 offsets. They come from one global expression, so they are sorted
/// and do not overlap: starts and ends both increase, and every lookup is a binary search.
#[derive(Debug, Clone, Copy)]
struct Hit {
    start: usize,
    end: usize,
}

fn hits(keywords: &Keywords, text: &KeywordText) -> Vec<Hit> {
    keywords
        .find_all(text)
        .into_iter()
        .map(|(start, end)| Hit { start, end })
        .collect()
}

/// Distance from the end of the closest hit that ends at or before pos
fn distance_before(hits: &[Hit], pos: usize) -> usize {
    match hits.partition_point(|h| h.end <= pos) {
        0 => FAR,
        i => FAR.min(pos - hits[i - 1].end),
    }
}

/// Distance to the start of the first hit that starts at or after pos
fn distance_after(hits: &[Hit], pos: usize) -> usize {
    let i = hits.partition_point(|h| h.start < pos);
    hits.get(i).map_or(FAR, |h| FAR.min(h.start - pos))
}

/// Whether a whole hit lies within [from, to]; the first hit starting at from has the smallest end
fn in_range(hits: &[Hit], from: usize, to: usize) -> bool {
    let i = hits.partition_point(|h| h.start < from);
    hits.get(i).is_some_and(|h| h.end <= to)
}

/// Per-document data shared by all candidates of the document
pub struct DocContext<'a> {
    doc: &'a Doc,
    strong: Vec<Hit>,
    weak: Vec<Hit>,
    cue: Vec<Hit>,
    neg: Vec<Hit>,
    promo: Vec<Hit>,
    dominant_font: f64,
    max_candidate_font: f64,
    candidates: &'a [Candidate],
    /// The UTF-16 start and end of every candidate
    positions: Vec<(usize, usize)>,
    strong_ranks: Vec<usize>,
    /// How many candidates of the document share each code
    code_counts: HashMap<&'a str, usize>,
}

/// Message data shared by the documents of one email
pub struct MessageContext<'a> {
    subject: &'a str,
    other_text: &'a str,
    distinct_codes: usize,
    subject_strong: bool,
    subject_weak: bool,
    subject_neg: bool,
    subject_promo: bool,
}

pub fn message_context<'a>(subject: &'a str, other_text: &'a str, distinct_codes: usize) -> MessageContext<'a> {
    let keyword_subject = KeywordText::new(subject);
    MessageContext {
        subject,
        other_text,
        distinct_codes,
        subject_strong: STRONG.matches(&keyword_subject),
        subject_weak: WEAK.matches(&keyword_subject),
        subject_neg: NEGATIVE.matches(&keyword_subject),
        subject_promo: PROMO.matches(&keyword_subject),
    }
}

/// A font size as a key of a JavaScript Map: every NaN is one key, and -0 is 0
fn size_key(size: f64) -> u64 {
    if size.is_nan() {
        f64::NAN.to_bits()
    } else if size == 0.0 {
        0
    } else {
        size.to_bits()
    }
}

/// The font size most of the visible text has, by characters; the first size seen wins a tie
fn dominant_font_size(doc: &Doc) -> f64 {
    let mut order: Vec<(f64, usize)> = Vec::new();
    let mut index: HashMap<u64, usize> = HashMap::new();
    for span in &doc.spans {
        if span.style.hidden {
            continue;
        }
        let size = round(span.style.font_size);
        let chars = doc.units.at(span.end) - doc.units.at(span.start);
        match index.get(&size_key(size)) {
            Some(&i) => order[i].1 += chars,
            None => {
                index.insert(size_key(size), order.len());
                order.push((size, chars));
            }
        }
    }
    let mut best = 16.0;
    let mut most = 0;
    for (size, count) in order {
        if count > most {
            best = size;
            most = count;
        }
    }
    best
}

pub fn doc_context<'a>(doc: &'a Doc, candidates: &'a [Candidate]) -> DocContext<'a> {
    let text = KeywordText::new(&doc.text);
    let strong = hits(&STRONG, &text);
    let positions: Vec<(usize, usize)> = candidates
        .iter()
        .map(|c| (doc.units.at(c.start), doc.units.at(c.end)))
        .collect();
    // Keys computed once; the sort is stable, so equal distances keep document order
    let mut keyed: Vec<(usize, usize)> = positions
        .iter()
        .enumerate()
        .map(|(i, &(start, end))| (i, distance_before(&strong, start).min(distance_after(&strong, end))))
        .collect();
    keyed.sort_by_key(|&(_, key)| key);
    let mut strong_ranks = vec![0; candidates.len()];
    for (rank, (i, _)) in keyed.into_iter().enumerate() {
        strong_ranks[i] = rank;
    }
    let mut code_counts = HashMap::new();
    for c in candidates {
        *code_counts.entry(c.code.as_str()).or_default() += 1;
    }
    DocContext {
        doc,
        weak: hits(&WEAK, &text),
        cue: hits(&CUE, &text),
        neg: hits(&NEGATIVE, &text),
        promo: hits(&PROMO, &text),
        strong,
        dominant_font: dominant_font_size(doc),
        max_candidate_font: max0(candidates.iter().map(|c| style_at(doc, c.start).font_size)),
        candidates,
        positions,
        strong_ranks,
        code_counts,
    }
}

/// The line of a candidate: byte offsets of its text, and UTF-16 offsets for the keyword lookups
struct Line<'a> {
    text: &'a str,
    start: usize,
    end: usize,
}

fn line_of<'a>(doc: &'a Doc, c: &Candidate) -> Line<'a> {
    let text = &doc.text;
    let start = text[..c.start].rfind('\n').map_or(0, |i| i + 1);
    let end = text[c.end..].find('\n').map_or(text.len(), |i| c.end + i);
    Line {
        text: &text[start..end],
        start: doc.units.at(start),
        end: doc.units.at(end),
    }
}

fn flag(value: bool) -> f64 {
    if value { 1.0 } else { 0.0 }
}

fn count(code: &str, f: fn(&u8) -> bool) -> usize {
    code.as_bytes().iter().filter(|b| f(b)).count()
}

fn shape_features(c: &Candidate, row: &mut Vec<f64>) {
    let code = c.code.as_str();
    let len = code.len();
    let digits = count(code, u8::is_ascii_digit);
    let upper = count(code, u8::is_ascii_uppercase);
    let lower = count(code, u8::is_ascii_lowercase);
    let bytes = code.as_bytes();
    let trivial = (len >= 2 && bytes[0].is_ascii_digit() && bytes.iter().all(|&b| b == bytes[0]))
        || "0123456789".contains(code)
        || "9876543210".contains(code);
    let mut distinct = [false; 256];
    for &b in bytes {
        distinct[b as usize] = true;
    }
    let distinct = distinct.iter().filter(|&&d| d).count();
    let looks_year = len == 4 && digits == 4 && (code.starts_with("19") || code.starts_with("20"));
    row.extend([
        len as f64,
        digits as f64,
        upper as f64,
        lower as f64,
        flag(digits == len),
        flag(upper == len),
        flag(upper > 0 && lower > 0),
        flag(c.kind == CandidateKind::Grouped),
        flag(c.kind == CandidateKind::Spaced),
        flag(c.kind == CandidateKind::DashedPart),
        flag(c.raw.contains('-')),
        flag(code.starts_with('0')),
        distinct as f64 / len as f64,
        flag(trivial),
        flag(looks_year),
    ]);
}

/// The byte offset `units` UTF-16 code units before `at`, taking a character a JavaScript slice
/// would cut in two whole: its lone half matches none of the expressions run on the slice
fn back_utf16(text: &str, at: usize, units: usize) -> usize {
    let mut taken = 0;
    let mut start = at;
    for c in text[..at].chars().rev() {
        if taken >= units {
            break;
        }
        taken += c.len_utf16();
        start -= c.len_utf8();
    }
    start
}

fn ends_with_after_space(s: &str, chars: &[char]) -> bool {
    s.trim_end_matches(is_space).ends_with(chars)
}

fn surrounding_features(text: &str, c: &Candidate, row: &mut Vec<f64>) {
    let before = &text[back_utf16(text, c.start, 4)..c.start];
    let after = &text[c.end..advance_utf16(text, c.end, 4)];
    let digit = |s: &str| s.bytes().any(|b| b.is_ascii_digit());
    let digit_nearby =
        digit(&text[back_utf16(text, c.start, 3)..c.start]) || digit(&text[c.end..advance_utf16(text, c.end, 3)]);
    row.extend([
        flag(ends_with_after_space(before, &[':'])),
        flag(ends_with_after_space(before, &['#'])),
        flag(CURRENCY.is_match(before) || CURRENCY.is_match(after)),
        flag(ends_with_after_space(before, &['+', '('])),
        flag(digit_nearby),
        flag(after.trim_start_matches(is_space).starts_with('%')),
    ]);
}

fn keyword_features(ctx: &DocContext, index: usize, line: &Line, row: &mut Vec<f64>) {
    let (start, end) = ctx.positions[index];
    row.extend(
        [
            distance_before(&ctx.strong, start),
            distance_after(&ctx.strong, end),
            distance_before(&ctx.weak, start),
            distance_after(&ctx.weak, end),
            distance_before(&ctx.cue, start),
            distance_after(&ctx.cue, end),
            distance_before(&ctx.neg, start),
            distance_after(&ctx.neg, end),
            usize::from(in_range(&ctx.strong, line.start, line.end)),
            usize::from(in_range(&ctx.weak, line.start, line.end)),
            usize::from(in_range(&ctx.neg, line.start, line.end)),
            ctx.strong_ranks[index],
        ]
        .map(|v| v as f64),
    );
}

fn layout_features(ctx: &DocContext, index: usize, line: &Line, row: &mut Vec<f64>) {
    let doc = ctx.doc;
    let c = &ctx.candidates[index];
    let style = style_at(doc, c.start);
    let block = block_around(doc, c.start, c.end);
    let block_text = trim(&doc.text[block.start..block.end]);
    let line_text = trim(line.text);
    let dominant = if ctx.dominant_font == 0.0 || ctx.dominant_font.is_nan() {
        16.0
    } else {
        ctx.dominant_font
    };
    let len = doc.len_units();
    row.extend([
        utf16_len(line_text) as f64,
        flag(line_text == c.raw),
        utf16_len(block_text) as f64,
        flag(block_text == c.raw),
        style.font_size,
        style.font_size / dominant,
        flag(style.font_size >= ctx.max_candidate_font),
        flag(style.bold),
        flag(style.letter_spacing),
        flag(style.link),
        flag(style.heading),
        flag(style.mono),
        flag(style.hidden),
        flag(style.quote || ctx.positions[index].0 >= doc.quote_start),
        if len > 0 {
            ctx.positions[index].0 as f64 / len as f64
        } else {
            0.0
        },
        flag(doc.source == Source::Html),
    ]);
}

fn message_features(ctx: &DocContext, msg: &MessageContext, index: usize, row: &mut Vec<f64>) {
    let c = &ctx.candidates[index];
    row.extend([
        ctx.code_counts[c.code.as_str()] as f64,
        flag(msg.other_text.contains(&c.raw) || msg.other_text.contains(&c.code)),
        flag(msg.subject.contains(&c.raw) || msg.subject.contains(&c.code)),
        flag(msg.subject_strong),
        flag(msg.subject_weak),
        flag(msg.subject_neg),
        ctx.strong.len() as f64,
        flag(!ctx.cue.is_empty()),
        crate::js::log1p(ctx.doc.len_units() as f64),
        ctx.candidates.len() as f64,
        msg.distinct_codes as f64,
        index as f64,
    ]);
}

fn promo_features(ctx: &DocContext, msg: &MessageContext, index: usize, line: &Line, row: &mut Vec<f64>) {
    let (start, end) = ctx.positions[index];
    row.extend([
        distance_before(&ctx.promo, start) as f64,
        distance_after(&ctx.promo, end) as f64,
        flag(in_range(&ctx.promo, line.start, line.end)),
        ctx.promo.len() as f64,
        flag(msg.subject_promo),
    ]);
}

fn code_text_features(code: &str, row: &mut Vec<f64>) {
    let letters = count(code, u8::is_ascii_alphabetic);
    let vowels = code
        .bytes()
        .filter(|b| b"aeiouy".contains(&b.to_ascii_lowercase()))
        .count();
    let vowel_ratio = if letters == 0 {
        -1.0
    } else {
        vowels as f64 / letters as f64
    };
    let longest_run = code
        .split(|c: char| !c.is_ascii_alphabetic())
        .map(str::len)
        .max()
        .unwrap_or(0);
    let bytes = code.as_bytes();
    let case_changes = bytes
        .windows(2)
        .filter(|w| {
            (w[0].is_ascii_lowercase() && w[1].is_ascii_uppercase())
                || (w[0].is_ascii_uppercase() && w[1].is_ascii_lowercase())
        })
        .count();
    row.extend([vowel_ratio, longest_run as f64, case_changes as f64]);
}

/// The feature vector of the candidate at `index` in the context's candidates
pub fn candidate_features(ctx: &DocContext, msg: &MessageContext, index: usize) -> Vec<f64> {
    let c = &ctx.candidates[index];
    let line = line_of(ctx.doc, c);
    let mut row = Vec::with_capacity(FEATURE_NAMES.len());
    shape_features(c, &mut row);
    surrounding_features(&ctx.doc.text, c, &mut row);
    keyword_features(ctx, index, &line, &mut row);
    layout_features(ctx, index, &line, &mut row);
    message_features(ctx, msg, index, &mut row);
    promo_features(ctx, msg, index, &line, &mut row);
    code_text_features(&c.code, &mut row);
    debug_assert_eq!(row.len(), FEATURE_NAMES.len());
    row
}
