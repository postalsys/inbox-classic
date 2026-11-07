//! Separates what the sender of a message wrote from the reply history, forwarded content and
//! footers their mail client attached: a port of `analyze()` from email-content.
//!
//! Losing a sentence the sender wrote is treated as far worse than showing redundant history, so
//! content is hidden only behind a structural anchor (an attribution line, a client quote
//! container, a client separator, or a match against an earlier message of the thread), nothing
//! is ever dropped (hidden segments are returned in full), and anything ambiguous stays visible
//! as `Unknown`.
//!
//! Offsets differ from email-content in one way: they are byte offsets into UTF-8 strings, where
//! email-content counts UTF-16 code units. Plain text segments index
//! [`AnalyzeResult::canonical_text`] for their part, HTML segments index the HTML as given.
//!
//! `segment.html` is attacker controlled markup copied out of the message. It is not sanitised.
#![forbid(unsafe_code)]

mod analyze;
mod block;
mod classify;
mod detect;
mod dom;
mod html_text;
mod matching;
mod patterns;
mod segment_html;
mod segment_text;
mod text;
mod util;

pub use analyze::{analyze, sender_tokens_from};
pub use matching::HistoryDocument;
pub use text::canonicalise_plain_text;

/// Version of the email-content extraction logic this port follows.
pub const EXTRACTOR_VERSION: &str = "0.1.18";

/// Which representation a segment came from.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Representation {
    Text,
    Html,
}

impl Representation {
    pub fn as_str(self) -> &'static str {
        match self {
            Representation::Text => "text",
            Representation::Html => "html",
        }
    }
}

/// Final classification of a segment.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Label {
    NewContent,
    InlineQuote,
    ReplyHistory,
    ForwardedContent,
    Signature,
    Disclaimer,
    Unknown,
}

impl Label {
    /// The name email-content uses, such as `REPLY_HISTORY`.
    pub fn as_str(self) -> &'static str {
        match self {
            Label::NewContent => "NEW_CONTENT",
            Label::InlineQuote => "INLINE_QUOTE",
            Label::ReplyHistory => "REPLY_HISTORY",
            Label::ForwardedContent => "FORWARDED_CONTENT",
            Label::Signature => "SIGNATURE",
            Label::Disclaimer => "DISCLAIMER",
            Label::Unknown => "UNKNOWN",
        }
    }
}

/// How a segment should be presented. `Hide` is only ever given to high confidence reply history
/// behind a structural anchor; `Collapse` means one interaction away.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Visibility {
    Show,
    Collapse,
    Hide,
}

impl Visibility {
    pub fn as_str(self) -> &'static str {
        match self {
            Visibility::Show => "show",
            Visibility::Collapse => "collapse",
            Visibility::Hide => "hide",
        }
    }
}

macro_rules! reasons {
    ($($variant:ident => $name:literal,)*) => {
        /// Machine readable justification for a decision.
        #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
        pub enum Reason {
            $($variant,)*
        }

        impl Reason {
            /// The code email-content uses, such as `preceded_by_reply_header`.
            pub fn as_str(self) -> &'static str {
                match self {
                    $(Reason::$variant => $name,)*
                }
            }
        }
    };
}

reasons! {
    PrecededByReplyHeader => "preceded_by_reply_header",
    PrecededByForwardHeader => "preceded_by_forward_header",
    ForwardBySubject => "forward_by_subject",
    InsideQuoteContainer => "inside_quote_container",
    FinalContiguousQuoteRegion => "final_contiguous_quote_region",
    NoNewContentAfterRegion => "no_new_content_after_region",
    NewContentAfterRegion => "new_content_after_region",
    InterleavedWithNewContent => "interleaved_with_new_content",
    InlineAnswersAnnounced => "inline_answers_announced",
    ContainsOldMessageHeaders => "contains_old_message_headers",
    AuthoredTextBeforeAnchor => "authored_text_before_anchor",
    QuoteDepthPositive => "quote_depth_positive",
    NoAnchorForQuote => "no_anchor_for_quote",
    OutlookReplySeparator => "outlook_reply_separator",
    DashDashDelimiter => "dash_dash_delimiter",
    MobileSignaturePhrase => "mobile_signature_phrase",
    SignaturePositionAndLength => "signature_position_and_length",
    DisclaimerPhrase => "disclaimer_phrase",
    MatchedParentMessage => "matched_parent_message",
    ShingleOverlapHigh => "shingle_overlap_high",
    HtmlPrimaryRepresentation => "html_primary_representation",
    TextPrimaryRepresentation => "text_primary_representation",
    RepresentationsDisagree => "representations_disagree",
    NewContentDefault => "new_content_default",
    AmbiguousKeptVisible => "ambiguous_kept_visible",
    DegradedToUnknown => "degraded_to_unknown",
}

/// Where a segment came from.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SourceRef {
    /// The part id the caller gave (`text_part_id`/`html_part_id`), or `TEXT`/`HTML`.
    pub mime_part: String,
    pub representation: Representation,
    /// Index of the first block within its own part.
    pub block_index: usize,
    /// Byte range: into `canonical_text[mime_part]` for text, into the HTML as given for HTML.
    /// A segment's range covers the markup between its blocks too, so consecutive segments of
    /// one part tile it.
    pub start: usize,
    pub end: usize,
    /// HTML only: child index path from the document root, such as `/0/2/1`.
    pub dom_path: Option<String>,
}

/// A classified run of content.
#[derive(Debug, Clone, PartialEq)]
pub struct Segment {
    pub label: Label,
    /// Plain text of the segment.
    pub text: String,
    /// The original markup of the segment's blocks, for HTML segments. UNTRUSTED.
    pub html: Option<String>,
    /// Calibrated in [0, 1].
    pub confidence: f64,
    pub visibility: Visibility,
    pub reasons: Vec<Reason>,
    pub source: SourceRef,
}

/// Warning codes. Details never carry message content.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum WarningCode {
    /// The HTML of a section could not be segmented and came back as one `Unknown` block.
    HtmlParseError,
    /// There was no body to analyse.
    NoBodyParts,
    /// A body existed but held nothing a reader would see.
    NoVisibleBodyText,
    /// Nothing visible survived classification, so everything was shown as `Unknown`.
    ExtractionDegraded,
    /// `max_content_chars` stopped the analysis of later sections.
    InputLimitExceeded,
}

impl WarningCode {
    pub fn as_str(self) -> &'static str {
        match self {
            WarningCode::HtmlParseError => "html_parse_error",
            WarningCode::NoBodyParts => "no_body_parts",
            WarningCode::NoVisibleBodyText => "no_visible_body_text",
            WarningCode::ExtractionDegraded => "extraction_degraded",
            WarningCode::InputLimitExceeded => "input_limit_exceeded",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Warning {
    pub code: WarningCode,
    pub detail: Option<String>,
    pub mime_part: Option<String>,
}

/// What [`analyze`] returns.
#[derive(Debug, Clone, PartialEq)]
pub struct AnalyzeResult {
    /// Segments to render, in document order, including collapsed ones.
    pub segments: Vec<Segment>,
    /// Segments whose visibility is `Hide`, kept in full.
    pub hidden_segments: Vec<Segment>,
    /// The weakest hide or collapse decision.
    pub overall_confidence: f64,
    pub warnings: Vec<Warning>,
    /// The representation that drove the primary section, `None` when there was no body.
    pub primary_representation: Option<Representation>,
    pub extractor_version: &'static str,
    /// Thread history was supplied and used.
    pub history_used: bool,
    /// Threading headers or the subject say this is a reply.
    pub is_reply: bool,
    /// The canonical plain text of each text part that reached the segments, keyed by part id.
    pub canonical_text: std::collections::BTreeMap<String, String>,
}

/// Where a body section sits in the message.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum SectionRole {
    #[default]
    Primary,
    /// A later `multipart/mixed` sibling, such as a gateway footer.
    Appended,
}

/// One structurally independent piece of a body: the text and HTML of a section are alternative
/// renderings of each other, separate sections are not.
#[derive(Debug, Clone, Default)]
pub struct BodySection<'a> {
    pub text: Option<&'a str>,
    pub html: Option<&'a str>,
    pub text_part_id: Option<&'a str>,
    pub html_part_id: Option<&'a str>,
    pub role: Option<SectionRole>,
}

/// A message body, already transfer and charset decoded.
#[derive(Debug, Clone, Default)]
pub struct MessageContent<'a> {
    pub text: Option<&'a str>,
    pub html: Option<&'a str>,
    /// Ordered body sections. Exclusive with `text`/`html`.
    pub sections: Option<Vec<BodySection<'a>>>,
    pub subject: Option<&'a str>,
    /// Sender as a display name and/or address, used only as signature evidence.
    pub from: Option<&'a str>,
    pub in_reply_to: Option<&'a str>,
    pub references: Vec<&'a str>,
    pub text_part_id: Option<&'a str>,
    pub html_part_id: Option<&'a str>,
}

/// Visibility thresholds.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ConfidenceConfig {
    /// At or above this, high confidence history may be hidden.
    pub hide_threshold: f64,
    /// At or above this, content is collapsed.
    pub collapse_threshold: f64,
    /// Minimum anchor strength before hiding is permitted at all.
    pub min_anchor_strength: f64,
}

impl Default for ConfidenceConfig {
    fn default() -> ConfidenceConfig {
        ConfidenceConfig {
            hide_threshold: 0.95,
            collapse_threshold: 0.75,
            min_anchor_strength: 0.85,
        }
    }
}

/// An earlier message of the thread, as content.
#[derive(Debug, Clone, Copy, Default)]
pub struct HistoryContent<'a> {
    pub text: Option<&'a str>,
    pub html: Option<&'a str>,
}

#[derive(Debug, Clone, Default)]
pub struct AnalyzeOptions<'a> {
    pub confidence: ConfidenceConfig,
    /// Most characters (UTF-16 code units, as email-content counts) analysed across every
    /// section. `None` for the default of 8,000,000.
    pub max_content_chars: Option<usize>,
    /// Earlier messages of the thread, nearest first.
    pub history: Vec<HistoryContent<'a>>,
    /// Prebuilt history documents. When not empty, `history` is ignored.
    pub history_documents: Vec<HistoryDocument>,
}

/// An invalid option. Malformed messages never produce one; they degrade.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConfigurationError {
    /// Stable code, such as `invalid_option`.
    pub code: &'static str,
    /// The offending option, such as `confidence.hideThreshold`.
    pub option: &'static str,
}

impl std::fmt::Display for ConfigurationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}: {}", self.option, self.code)
    }
}

impl std::error::Error for ConfigurationError {}

#[cfg(test)]
mod adversarial_tests;
