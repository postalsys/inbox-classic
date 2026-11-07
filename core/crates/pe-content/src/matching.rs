//! Stage 5: matching blocks against messages that already existed.
//!
//! A block whose text is found in an earlier message of the thread is history by provenance. The
//! matcher is conservative: short blocks are never matched and a high containment is required.

use std::collections::{BTreeSet, HashSet};
use std::sync::LazyLock;

use regex::Regex;
use unicode_normalization::UnicodeNormalization;

use crate::Representation;
use crate::block::Block;
use crate::html_text::strip_tags_to_text;
use crate::text::canonicalise_plain_text;
use crate::util::js_trim;
use pe_jsre::is_space;

/// Minimum tokens before a block is worth matching: short blocks match by coincidence.
const MIN_MATCH_TOKENS: usize = 9;

/// Tokens per shingle.
const SHINGLE_SIZE: usize = 5;

/// Containment at or above this counts as a match.
pub(crate) const CONTAINMENT_THRESHOLD: f64 = 0.8;

/// Containment at or above which a match needs no corroboration from markup.
const STRONG_CONTAINMENT: f64 = 0.95;

/// What separates words: anything but letters and digits, shared with the sender tokens of `analyze`
pub(crate) static NON_WORD: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"[^\p{L}\p{N}]+").expect("valid"));

fn fold_char(c: char, out: &mut String) {
    match c {
        '\u{a0}' | '\u{1680}' | '\u{2000}'..='\u{200a}' | '\u{202f}' | '\u{205f}' | '\u{3000}' => out.push(' '),
        '\u{200b}'..='\u{200d}' | '\u{feff}' | '\u{ad}' => {}
        '\u{2018}' | '\u{2019}' | '\u{201a}' | '\u{201b}' | '\u{2032}' | '\u{2035}' => out.push('\''),
        '\u{201c}' | '\u{201d}' | '\u{201e}' | '\u{201f}' | '\u{2033}' | '\u{2036}' => out.push('"'),
        '\u{2010}'..='\u{2015}' | '\u{2212}' => out.push('-'),
        '\u{2026}' => out.push_str("..."),
        '\u{2022}' | '\u{b7}' | '\u{2043}' => out.push('*'),
        c => out.push(c),
    }
}

/// Normalise text for comparison: quote prefixes stripped, punctuation variants folded,
/// whitespace collapsed, lowercased.
pub(crate) fn normalise_for_match(text: &str) -> String {
    let text: String = if text.is_ascii() {
        text.to_string()
    } else {
        text.nfc().collect()
    };
    let mut folded = String::with_capacity(text.len());
    // `^[ \t]{0,3}(?:>[ \t]?)+` per line, then the character folds.
    for (i, line) in text.split('\n').enumerate() {
        if i > 0 {
            folded.push('\n');
        }
        let (prefix, _) = crate::text::split_quote_prefix(line);
        for c in line[prefix..].chars() {
            fold_char(c, &mut folded);
        }
    }
    let mut out = String::with_capacity(folded.len());
    for word in folded.split(is_space).filter(|w| !w.is_empty()) {
        if !out.is_empty() {
            out.push(' ');
        }
        out.push_str(word);
    }
    js_trim(&out).to_lowercase()
}

fn tokenise(normalised: &str) -> Vec<&str> {
    NON_WORD.split(normalised).filter(|token| !token.is_empty()).collect()
}

fn fnv1a32(value: &str) -> u32 {
    let mut hash: u32 = 0x811c9dc5;
    for unit in value.encode_utf16() {
        hash ^= u32::from(unit & 0xff);
        hash = hash.wrapping_mul(0x01000193);
        hash ^= u32::from(unit >> 8);
        hash = hash.wrapping_mul(0x01000193);
    }
    hash
}

fn fnv1a32b(value: &str) -> u32 {
    let mut hash: u32 = 0x811c9dc5 ^ 0x9e3779b9;
    let units: Vec<u16> = value.encode_utf16().collect();
    for &unit in units.iter().rev() {
        hash ^= u32::from(unit & 0xff);
        hash = hash.wrapping_mul(0x85ebca6b);
        hash ^= u32::from(unit >> 8);
        hash = hash.wrapping_mul(0xc2b2ae35);
    }
    hash
}

fn hash_tokens(tokens: &[&str]) -> u32 {
    let mut hash: u32 = 0x811c9dc5;
    for token in tokens {
        hash = hash.wrapping_mul(31).wrapping_add(fnv1a32(token));
        hash ^= fnv1a32b(token);
    }
    hash
}

#[derive(Debug, Clone, Default)]
pub(crate) struct ShingleIndex {
    hashes: HashSet<u32>,
    token_count: usize,
}

pub(crate) fn build_shingle_index(normalised: &str) -> ShingleIndex {
    let tokens = tokenise(normalised);
    let mut hashes = HashSet::new();
    if tokens.len() < SHINGLE_SIZE {
        // Short text is one shingle, so it can still match exactly.
        if !tokens.is_empty() {
            hashes.insert(hash_tokens(&tokens));
        }
    } else {
        for window in tokens.windows(SHINGLE_SIZE) {
            hashes.insert(hash_tokens(window));
        }
    }
    ShingleIndex {
        hashes,
        token_count: tokens.len(),
    }
}

/// Share of `block`'s shingles that also appear in `reference`.
pub(crate) fn containment(block: &ShingleIndex, reference: &ShingleIndex) -> f64 {
    if block.hashes.is_empty() {
        return 0.0;
    }
    let hits = block
        .hashes
        .iter()
        .filter(|hash| reference.hashes.contains(hash))
        .count();
    hits as f64 / block.hashes.len() as f64
}

/// Long enough for a containment score to mean anything.
pub(crate) fn is_matchable(index: &ShingleIndex) -> bool {
    index.token_count >= MIN_MATCH_TOKENS
}

/// An earlier message of the thread, prepared for matching. Build it once per message and pass it
/// in [`AnalyzeOptions::history_documents`](crate::AnalyzeOptions) to skip the work on every reply.
#[derive(Debug, Clone)]
pub struct HistoryDocument {
    /// Identifier for diagnostics.
    pub id: String,
    normalised: String,
    index: ShingleIndex,
    /// The direct parent rather than an older ancestor.
    pub is_parent: bool,
}

impl HistoryDocument {
    /// From the body parts of a message in MIME order: plain text parts are canonicalised, HTML
    /// parts projected to text, and all of them folded into one document, because which
    /// representation an earlier message used says nothing about which one a reply quoted.
    pub fn from_parts(parts: &[(Representation, &str)], id: impl Into<String>, is_parent: bool) -> HistoryDocument {
        let texts: Vec<String> = parts
            .iter()
            .map(|(representation, body)| match representation {
                Representation::Text => canonicalise_plain_text(body),
                Representation::Html => strip_tags_to_text(body),
            })
            .collect();
        let normalised = normalise_for_match(&texts.join("\n"));
        let index = build_shingle_index(&normalised);
        HistoryDocument {
            id: id.into(),
            normalised,
            index,
            is_parent,
        }
    }

    /// From a message's plain text and HTML bodies, either of which may be empty.
    pub fn from_content(text: &str, html: &str, id: impl Into<String>, is_parent: bool) -> HistoryDocument {
        let mut parts = Vec::new();
        if !text.is_empty() {
            parts.push((Representation::Text, text));
        }
        if !html.is_empty() {
            parts.push((Representation::Html, html));
        }
        HistoryDocument::from_parts(&parts, id, is_parent)
    }
}

pub(crate) struct BlockMatch {
    pub block_index: usize,
    pub is_parent: bool,
    pub containment: f64,
    pub exact: bool,
}

/// One match per block at most, preferring the direct parent, then higher containment.
pub(crate) fn match_blocks(blocks: &[Block], history: &[HistoryDocument]) -> Vec<BlockMatch> {
    if history.is_empty() {
        return Vec::new();
    }
    let mut matches = Vec::new();
    for block in blocks {
        let normalised = normalise_for_match(&block.content);
        if normalised.is_empty() {
            continue;
        }
        let index = build_shingle_index(&normalised);
        if !is_matchable(&index) {
            continue;
        }
        let mut best: Option<BlockMatch> = None;
        for document in history {
            let exact = document.normalised.contains(&normalised);
            let score = if exact {
                1.0
            } else {
                containment(&index, &document.index)
            };
            if score < CONTAINMENT_THRESHOLD {
                continue;
            }
            let better = best.as_ref().is_none_or(|current| {
                if document.is_parent != current.is_parent {
                    document.is_parent
                } else {
                    score > current.containment
                }
            });
            if better {
                best = Some(BlockMatch {
                    block_index: block.index,
                    is_parent: document.is_parent,
                    containment: score,
                    exact,
                });
            }
        }
        matches.extend(best);
    }
    matches
}

pub(crate) fn matched_indices(matches: &[BlockMatch]) -> BTreeSet<usize> {
    matches.iter().map(|m| m.block_index).collect()
}

pub(crate) fn strong_matched_indices(matches: &[BlockMatch]) -> BTreeSet<usize> {
    matches
        .iter()
        .filter(|m| m.exact || m.containment >= STRONG_CONTAINMENT)
        .map(|m| m.block_index)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn folds_quoting_and_punctuation() {
        assert_eq!(
            normalise_for_match("> Hello\u{a0}  World\n> again"),
            "hello world again"
        );
        assert_eq!(
            normalise_for_match("\u{201c}It\u{2019}s\u{201d} \u{2014} ok\u{2026}"),
            "\"it's\" - ok..."
        );
        assert_ne!(
            normalise_for_match("the meeting is on monday"),
            normalise_for_match("the meeting is on tuesday")
        );
    }

    #[test]
    fn scores_containment() {
        let parent = build_shingle_index(&normalise_for_match(
            "We should move the deploy window to Thursday evening because the database migration needs a quiet period.",
        ));
        let quote = build_shingle_index(&normalise_for_match(
            "move the deploy window to Thursday evening because the database",
        ));
        assert_eq!(containment(&quote, &parent), 1.0);
        let other = build_shingle_index(&normalise_for_match(
            "completely unrelated words that share nothing with the parent at all",
        ));
        assert!(containment(&other, &parent) < 0.2);
    }
}
