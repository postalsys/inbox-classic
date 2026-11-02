//! The block model both segmenters produce, and its feature vector.
//!
//! A block is a contiguous run of one representation. Blocks tile their representation: their
//! ranges are adjacent and cover it exactly, so no content can vanish between stages.
//!
//! email-content also computes features that only its `--explain` diagnostics show (character
//! class ratios, tag and class lists, link counts). The port keeps the ones the detectors and the
//! classifier read.

use std::sync::LazyLock;

use crate::Representation;
use crate::jsre::JsRegex;
use crate::patterns::patterns;
use crate::util::{js_len, js_trim, js_words};

/// Structural kind assigned during segmentation, before classification.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum BlockKind {
    Paragraph,
    Quote,
    ReplyHeader,
    ForwardHeader,
    QuotedHeaderBlock,
    List,
    Table,
    Separator,
    Image,
    Blank,
    Unknown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum EvidenceKind {
    ReplyAnchor,
    ForwardAnchor,
    QuoteContainer,
    Attribution,
    Separator,
    Signature,
    Disclaimer,
    NewContent,
    Hint,
}

/// A single piece of evidence from a detector. Detectors never emit verdicts.
#[derive(Debug, Clone, PartialEq)]
pub(crate) struct Evidence {
    pub id: String,
    pub kind: EvidenceKind,
    pub strength: f64,
}

impl Evidence {
    pub fn new(id: impl Into<String>, kind: EvidenceKind, strength: f64) -> Evidence {
        Evidence {
            id: id.into(),
            kind,
            strength,
        }
    }
}

#[derive(Debug, Clone, Default)]
pub(crate) struct BlockFeatures {
    /// Position of the block start within the representation, in [0, 1].
    pub position: f64,
    pub line_count: usize,
    pub word_count: usize,
    pub quote_depth: usize,
    pub blockquote_depth: usize,
    pub has_email_address: bool,
    pub has_url: bool,
    pub has_phone_number: bool,
    /// Lines that look like an embedded message header field.
    pub header_field_lines: usize,
    /// Share of non blank lines shorter than 40 characters.
    pub short_line_ratio: f64,
    pub is_all_blank: bool,
    /// HTML only: lines the sender typed above an embedded header block inside this block.
    pub authored_lines_before_anchor: usize,
}

#[derive(Debug, Clone)]
pub(crate) struct Block {
    /// Position in the sequence the classifier sees.
    pub index: usize,
    /// Position within the block's own representation.
    pub source_index: usize,
    pub kind: BlockKind,
    pub representation: Representation,
    pub mime_part: String,
    /// Byte range in the canonical text or the HTML source.
    pub start: usize,
    pub end: usize,
    /// HTML only: where the block's own nodes start (`start` may reach back over markup between
    /// blocks).
    pub html_start: Option<usize>,
    /// HTML only: where the block's own nodes end (`end` may run on to the end of the document).
    pub html_end: usize,
    /// Display and matching text: quote prefixes removed, surrounding blank lines trimmed.
    pub content: String,
    /// HTML only: stable child index path from the document root.
    pub dom_path: Option<String>,
    pub features: BlockFeatures,
    pub evidence: Vec<Evidence>,
}

impl Block {
    /// The block's original markup, for HTML blocks.
    pub fn html<'s>(&self, source: &'s str) -> Option<&'s str> {
        self.html_start.map(|start| &source[start..self.html_end])
    }
}

/// Bounded so a long run of word characters without an @ cannot backtrack.
static EMAIL: LazyLock<JsRegex> = LazyLock::new(|| JsRegex::fixed(r"[\w.+-]{1,64}@[\w-]{1,63}\.[\w.-]{2,64}", ""));
static URL: LazyLock<JsRegex> = LazyLock::new(|| JsRegex::fixed(r"\b(?:https?:\/\/|www\.)\S+", "i"));
static PHONE: LazyLock<JsRegex> =
    LazyLock::new(|| JsRegex::fixed(r"(?:\+\d[\d\s().-]{7,}|\b\d{3}[\s.-]\d{3}[\s.-]\d{3,4}\b)", ""));

pub(crate) struct FeatureContext {
    /// Start of the block in UTF-16 code units, and the length of the representation.
    pub start16: usize,
    pub total16: usize,
    pub quote_depth: usize,
    pub blockquote_depth: usize,
}

fn count_header_field_lines(lines: &[&str]) -> usize {
    let fields = &patterns().quoted_header_fields;
    lines
        .iter()
        .map(|line| js_trim(line))
        .filter(|line| !line.is_empty() && js_len(line) <= 300)
        .filter(|line| fields.iter().any(|pattern| pattern.regex.is_match(line)))
        .count()
}

/// Compute the feature vector for a block's de-prefixed content.
pub(crate) fn compute_features(content: &str, context: &FeatureContext) -> BlockFeatures {
    let lines: Vec<&str> = content.split('\n').collect();
    let non_blank: Vec<&str> = lines.iter().copied().filter(|line| !js_trim(line).is_empty()).collect();
    let short_lines = non_blank.iter().filter(|line| js_len(js_trim(line)) < 40).count();
    BlockFeatures {
        position: if context.total16 > 0 {
            context.start16 as f64 / context.total16 as f64
        } else {
            0.0
        },
        line_count: lines.len(),
        word_count: js_words(content).count(),
        quote_depth: context.quote_depth,
        blockquote_depth: context.blockquote_depth,
        has_email_address: EMAIL.is_match(content),
        has_url: URL.is_match(content),
        has_phone_number: PHONE.is_match(content),
        header_field_lines: count_header_field_lines(&lines),
        short_line_ratio: if non_blank.is_empty() {
            0.0
        } else {
            short_lines as f64 / non_blank.len() as f64
        },
        is_all_blank: non_blank.is_empty(),
        authored_lines_before_anchor: 0,
    }
}
