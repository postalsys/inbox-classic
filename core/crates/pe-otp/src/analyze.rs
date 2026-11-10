//! From a message to the feature vector of every candidate, a port of otp-detect's src/analyze.ts.

use std::collections::HashSet;

use crate::candidates::{Candidate, extract_candidates};
use crate::doc::{Doc, Source, render_text};
use crate::features::{candidate_features, doc_context, message_context};
use crate::html::render_html;
use crate::js::slice_utf16;

/// An already parsed message; every part is optional
#[derive(Debug, Clone, Copy, Default)]
pub struct MessageInput<'a> {
    pub subject: Option<&'a str>,
    /// The text/plain body
    pub text: Option<&'a str>,
    /// The text/html body
    pub html: Option<&'a str>,
}

#[derive(Debug, Clone)]
pub struct Occurrence {
    pub candidate: Candidate,
    pub source: Source,
    pub features: Vec<f64>,
}

/// Bodies larger than this many UTF-16 code units are cut; code notifications are a few kilobytes
pub const MAX_BODY_CHARS: usize = 512 * 1024;

/// The longest subject looked at, in UTF-16 code units
const MAX_SUBJECT_CHARS: usize = 1000;

pub fn render_docs(input: &MessageInput) -> Vec<Doc> {
    let mut docs = Vec::new();
    if let Some(html) = input.html.filter(|h| !h.is_empty()) {
        docs.push(render_html(&slice_utf16(html, MAX_BODY_CHARS)));
    }
    if let Some(text) = input.text.filter(|t| !t.is_empty()) {
        docs.push(render_text(&slice_utf16(text, MAX_BODY_CHARS)));
    }
    docs.retain(|d| !d.text.is_empty());
    docs
}

pub fn analyze(input: &MessageInput) -> Vec<Occurrence> {
    let docs = render_docs(input);
    let per_doc: Vec<Vec<Candidate>> = docs.iter().map(extract_candidates).collect();
    let distinct_codes = per_doc
        .iter()
        .flatten()
        .map(|c| c.code.as_str())
        .collect::<HashSet<_>>()
        .len();
    let subject = slice_utf16(input.subject.unwrap_or(""), MAX_SUBJECT_CHARS);
    let mut out = Vec::new();
    for (i, (doc, candidates)) in docs.iter().zip(&per_doc).enumerate() {
        let ctx = doc_context(doc, candidates);
        let other_text = docs
            .iter()
            .enumerate()
            .filter(|&(j, _)| j != i)
            .map(|(_, d)| d.text.as_str())
            .collect::<Vec<_>>()
            .join("\n");
        let msg = message_context(&subject, &other_text, distinct_codes);
        for (index, candidate) in candidates.iter().enumerate() {
            out.push(Occurrence {
                candidate: candidate.clone(),
                source: doc.source,
                features: candidate_features(&ctx, &msg, index),
            });
        }
    }
    out
}
