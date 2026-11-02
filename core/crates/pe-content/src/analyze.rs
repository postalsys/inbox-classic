//! The pipeline: sections are segmented, a representation is chosen for each, every section is
//! classified as one sequence, and adjacent decisions become segments.

use std::collections::BTreeMap;
use std::sync::LazyLock;

use regex::Regex;

use crate::block::{Block, Evidence, EvidenceKind};
use crate::classify::{
    ClassifyOptions, Decision, PrimaryChoice, RepresentationInfo, classify_blocks, pick_primary, reconcile_section,
    visibility_for,
};
use crate::detect::{REPLY_SUBJECT, is_forward_subject};
use crate::html_text::strip_tags_to_text;
use crate::matching::{
    CONTAINMENT_THRESHOLD, HistoryDocument, build_shingle_index, containment, is_matchable, match_blocks,
    matched_indices, normalise_for_match, strong_matched_indices,
};
use crate::segment_html::segment_html_blocks;
use crate::segment_text::segment_text_blocks;
use crate::util::{is_blank, js_len, js_trim};
use crate::{
    AnalyzeOptions, AnalyzeResult, BodySection, ConfidenceConfig, ConfigurationError, EXTRACTOR_VERSION, Label,
    MessageContent, Reason, Representation, SectionRole, Segment, SourceRef, Visibility, Warning, WarningCode,
};

/// Characters of body content analysed by default, across every section.
const DEFAULT_MAX_CONTENT_CHARS: usize = 8_000_000;

/// Confidence given to anything the pipeline could not classify.
const DEGRADED_CONFIDENCE: f64 = 0.5;

static ANGLE_ADDRESS: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"<[^>]*>").expect("valid"));
static LOCAL_PART: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"([0-9A-Za-z_.+-]{1,64})@").expect("valid"));
static SEPARATORS: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"[._+-]+").expect("valid"));

/// Name tokens from a From header for signature detection: display name words and the address
/// local part, lowercased, three characters or longer.
pub fn sender_tokens_from(from: Option<&str>) -> Vec<String> {
    let Some(from) = from.filter(|from| !from.is_empty()) else {
        return Vec::new();
    };
    let display = ANGLE_ADDRESS.replace_all(from, " ").replace(['"', '\''], " ");
    let local = LOCAL_PART
        .captures(from)
        .and_then(|caps| caps.get(1))
        .map_or("", |m| m.as_str());
    let joined = format!("{display} {}", SEPARATORS.replace_all(local, " ")).to_lowercase();
    let mut tokens: Vec<String> = Vec::new();
    for token in crate::matching::NON_WORD.split(&joined) {
        if js_len(token) >= 3 && !tokens.iter().any(|t| t == token) {
            tokens.push(token.to_string());
        }
    }
    tokens
}

fn validate(config: &ConfidenceConfig) -> Result<(), ConfigurationError> {
    let check = |value: f64, option: &'static str| {
        if value.is_finite() && (0.0..=1.0).contains(&value) {
            Ok(())
        } else {
            Err(ConfigurationError {
                code: "invalid_option",
                option,
            })
        }
    };
    check(config.hide_threshold, "confidence.hideThreshold")?;
    check(config.collapse_threshold, "confidence.collapseThreshold")?;
    check(config.min_anchor_strength, "confidence.minAnchorStrength")?;
    if config.collapse_threshold > config.hide_threshold {
        return Err(ConfigurationError {
            code: "inverted_thresholds",
            option: "confidence.collapseThreshold",
        });
    }
    Ok(())
}

fn non_blank(value: Option<&str>) -> Option<&str> {
    value.filter(|value| !is_blank(value))
}

/// Are two adjacent sections the same content in two representations? Some clients send
/// `multipart/mixed(H, P)` where they meant alternative; content decides, and no match keeps both.
fn is_same_content_alternative(a: &BodySection, b: &BodySection) -> bool {
    let (plain, markup) = match (
        non_blank(a.text),
        non_blank(a.html),
        non_blank(b.text),
        non_blank(b.html),
    ) {
        (Some(text), None, None, Some(html)) => (text, html),
        (None, Some(html), Some(text), None) => (text, html),
        _ => return false,
    };
    let left = build_shingle_index(&normalise_for_match(plain));
    let right = build_shingle_index(&normalise_for_match(&strip_tags_to_text(markup)));
    if !is_matchable(&left) || !is_matchable(&right) {
        return false;
    }
    containment(&left, &right) >= CONTAINMENT_THRESHOLD || containment(&right, &left) >= CONTAINMENT_THRESHOLD
}

fn merge_equivalent_sections<'a>(sections: Vec<BodySection<'a>>) -> Vec<BodySection<'a>> {
    let mut merged: Vec<BodySection<'a>> = Vec::new();
    for section in sections {
        if let Some(previous) = merged.last_mut()
            && is_same_content_alternative(previous, &section)
        {
            *previous = BodySection {
                text: previous.text.or(section.text),
                html: previous.html.or(section.html),
                text_part_id: previous.text_part_id.or(section.text_part_id),
                html_part_id: previous.html_part_id.or(section.html_part_id),
                role: previous.role,
            };
            continue;
        }
        merged.push(section);
    }
    merged
}

fn normalise_sections<'a>(content: &MessageContent<'a>) -> Result<Vec<BodySection<'a>>, ConfigurationError> {
    let has_single = non_blank(content.text).is_some() || non_blank(content.html).is_some();
    if let Some(sections) = &content.sections {
        if has_single {
            return Err(ConfigurationError {
                code: "conflicting_body_input",
                option: "sections",
            });
        }
        if sections.iter().filter(|s| s.role == Some(SectionRole::Primary)).count() > 1 {
            return Err(ConfigurationError {
                code: "invalid_section_role",
                option: "sections",
            });
        }
        let kept = sections
            .iter()
            .filter(|s| non_blank(s.text).is_some() || non_blank(s.html).is_some())
            .cloned()
            .collect();
        return Ok(merge_equivalent_sections(kept));
    }
    if !has_single {
        return Ok(Vec::new());
    }
    Ok(vec![BodySection {
        text: content.text,
        html: content.html,
        text_part_id: content.text_part_id,
        html_part_id: content.html_part_id,
        role: Some(SectionRole::Primary),
    }])
}

/// Whole sections past the budget are dropped, never cut in half.
fn limit_sections<'a>(sections: Vec<BodySection<'a>>, max: usize, warnings: &mut Vec<Warning>) -> Vec<BodySection<'a>> {
    let warning = || Warning {
        code: WarningCode::InputLimitExceeded,
        detail: Some(format!("maxContentChars ({max})")),
        mime_part: None,
    };
    let mut kept = Vec::new();
    let mut used = 0;
    for section in sections {
        let size = section.text.map_or(0, js_len) + section.html.map_or(0, js_len);
        if !kept.is_empty() && used + size > max {
            warnings.push(warning());
            break;
        }
        used += size;
        kept.push(section);
        if used > max {
            warnings.push(warning());
            break;
        }
    }
    kept
}

fn has_anchor(blocks: &[Block], min_anchor_strength: f64) -> bool {
    blocks.iter().any(|block| {
        block.evidence.iter().any(|e| {
            matches!(e.kind, EvidenceKind::ReplyAnchor | EvidenceKind::ForwardAnchor)
                || (e.kind == EvidenceKind::QuoteContainer && e.strength >= min_anchor_strength)
        })
    })
}

fn representation_info(
    blocks: Vec<Block>,
    representation: Representation,
    degraded: bool,
    min: f64,
) -> RepresentationInfo {
    RepresentationInfo {
        representation,
        content_chars: blocks.iter().map(|b| js_len(&b.content)).sum(),
        has_anchor: !degraded && has_anchor(&blocks, min),
        degraded,
        blocks,
    }
}

struct SegmentedSection {
    choice: PrimaryChoice,
    /// Range of this section's blocks in the document sequence.
    start: usize,
    end: usize,
}

/// Merge adjacent decisions with the same label, visibility and part into segments.
fn to_segments(blocks: &[Block], decisions: &[Decision], sources: &[&str], config: &ConfidenceConfig) -> Vec<Segment> {
    let mut segments: Vec<Segment> = Vec::new();
    for (block, decision) in blocks.iter().zip(decisions) {
        let visibility = visibility_for(decision.label, decision.confidence, config);
        let source = sources[block.index];
        let html = block.html(source).filter(|html| !html.is_empty());
        if let Some(previous) = segments.last_mut()
            && previous.label == decision.label
            && previous.visibility == visibility
            && previous.source.mime_part == block.mime_part
        {
            if previous.text.is_empty() {
                previous.text = block.content.clone();
            } else {
                previous.text.push('\n');
                previous.text.push_str(&block.content);
            }
            if let Some(html) = html {
                previous.html.get_or_insert_with(String::new).push_str(html);
            }
            previous.source.end = block.end;
            previous.confidence = previous.confidence.min(decision.confidence);
            for reason in &decision.reasons {
                if !previous.reasons.contains(reason) {
                    previous.reasons.push(*reason);
                }
            }
            continue;
        }
        if block.features.is_all_blank && segments.is_empty() {
            continue;
        }
        segments.push(Segment {
            label: decision.label,
            text: block.content.clone(),
            html: html.map(str::to_string),
            confidence: decision.confidence,
            visibility,
            reasons: decision.reasons.clone(),
            source: SourceRef {
                mime_part: block.mime_part.clone(),
                representation: block.representation,
                block_index: block.source_index,
                start: block.start,
                end: block.end,
                dom_path: block.dom_path.clone(),
            },
        });
    }
    segments.retain(|segment| !js_trim(&segment.text).is_empty());
    segments
}

fn overall_confidence(segments: &[Segment]) -> f64 {
    segments
        .iter()
        .filter(|s| s.visibility != Visibility::Show)
        .map(|s| s.confidence)
        .fold(None, |lowest: Option<f64>, c| Some(lowest.map_or(c, |l| l.min(c))))
        .unwrap_or(1.0)
}

fn resolve_history(options: &AnalyzeOptions) -> Vec<HistoryDocument> {
    if !options.history_documents.is_empty() {
        return options.history_documents.clone();
    }
    options
        .history
        .iter()
        .enumerate()
        .map(|(i, item)| {
            HistoryDocument::from_content(
                item.text.unwrap_or(""),
                item.html.unwrap_or(""),
                format!("history-{i}"),
                i == 0,
            )
        })
        .collect()
}

/// Analyse an already parsed message body.
///
/// Errors only for invalid options. A malformed body never fails: what cannot be segmented comes
/// back as a visible `Unknown` segment with a warning.
pub fn analyze(content: &MessageContent, options: &AnalyzeOptions) -> Result<AnalyzeResult, ConfigurationError> {
    let config = options.confidence;
    validate(&config)?;
    let max_content_chars = match options.max_content_chars {
        None => DEFAULT_MAX_CONTENT_CHARS,
        Some(0) => {
            return Err(ConfigurationError {
                code: "invalid_option",
                option: "maxContentChars",
            });
        }
        Some(max) => max,
    };
    let mut warnings = Vec::new();
    let sections = limit_sections(normalise_sections(content)?, max_content_chars, &mut warnings);
    let subject = content.subject.unwrap_or("");
    let is_reply = content.in_reply_to.is_some_and(|value| !value.is_empty())
        || !content.references.is_empty()
        || REPLY_SUBJECT.is_match(subject);

    let empty = |warnings: Vec<Warning>| AnalyzeResult {
        segments: Vec::new(),
        hidden_segments: Vec::new(),
        overall_confidence: 1.0,
        warnings,
        primary_representation: None,
        extractor_version: EXTRACTOR_VERSION,
        history_used: false,
        is_reply,
        canonical_text: BTreeMap::new(),
    };
    let no_body = |mut warnings: Vec<Warning>| {
        warnings.push(Warning {
            code: WarningCode::NoBodyParts,
            detail: None,
            mime_part: None,
        });
        Ok(empty(warnings))
    };
    if sections.is_empty() {
        return no_body(warnings);
    }

    let sender_tokens = sender_tokens_from(content.from);
    let history = resolve_history(options);
    let message_is_forward = is_forward_subject(subject);

    // Segment every section and choose its representation before anything is classified.
    let mut segmented: Vec<SegmentedSection> = Vec::new();
    let mut document: Vec<Block> = Vec::new();
    // The source each section's blocks index: a canonical text (by position) or the HTML.
    let mut canonical_texts: Vec<(String, String)> = Vec::new();
    let mut section_sources: Vec<Result<usize, &str>> = Vec::new();
    let mut canonical_text = BTreeMap::new();

    for section in &sections {
        let mut text_info = None;
        let mut html_info = None;
        if let Some(text) = non_blank(section.text) {
            let part = section.text_part_id.unwrap_or("TEXT");
            let (canonical_form, blocks) = segment_text_blocks(text, part);
            canonical_texts.push((part.to_string(), canonical_form.text));
            text_info = Some(representation_info(
                blocks,
                Representation::Text,
                false,
                config.min_anchor_strength,
            ));
        }
        if let Some(html) = non_blank(section.html) {
            let part = section.html_part_id.unwrap_or("HTML");
            let result = segment_html_blocks(html, part);
            if result.degraded {
                warnings.push(Warning {
                    code: WarningCode::HtmlParseError,
                    detail: None,
                    mime_part: Some(part.to_string()),
                });
            }
            html_info = Some(representation_info(
                result.blocks,
                Representation::Html,
                result.degraded,
                config.min_anchor_strength,
            ));
        }
        let Some(mut choice) = pick_primary(text_info, html_info) else {
            continue;
        };
        if choice.primary.representation == Representation::Text {
            let (part, text) = &canonical_texts[canonical_texts.len() - 1];
            canonical_text.insert(part.clone(), text.clone());
            section_sources.push(Ok(canonical_texts.len() - 1));
        } else {
            section_sources.push(Err(section.html.unwrap_or("")));
        }
        let start = document.len();
        for (offset, block) in choice.primary.blocks.iter_mut().enumerate() {
            // The section-local index stays for traceability; the classifier indexes by position.
            block.source_index = offset;
            block.index = start + offset;
            if section.role == Some(SectionRole::Appended) {
                block
                    .evidence
                    .push(Evidence::new("mime:appended_section", EvidenceKind::Hint, 0.5));
            }
        }
        document.extend(choice.primary.blocks.iter().cloned());
        segmented.push(SegmentedSection {
            start,
            end: document.len(),
            choice,
        });
    }

    if document.is_empty() {
        return no_body(warnings);
    }

    let mut block_sources: Vec<&str> = Vec::with_capacity(document.len());
    for (section, source) in segmented.iter().zip(&section_sources) {
        let source: &str = match source {
            Ok(at) => canonical_texts[*at].1.as_str(),
            Err(html) => html,
        };
        block_sources.extend(std::iter::repeat_n(source, section.end - section.start));
    }

    let matches = if history.is_empty() {
        Vec::new()
    } else {
        match_blocks(&document, &history)
    };
    let (matched, strong) = (matched_indices(&matches), strong_matched_indices(&matches));
    let mut decisions = classify_blocks(
        &document,
        &ClassifyOptions {
            config,
            history_matched: &matched,
            history_strong: &strong,
            sender_tokens: &sender_tokens,
            message_is_forward,
        },
    );

    for section in &segmented {
        let slice = &mut decisions[section.start..section.end];
        if section.choice.primary.degraded {
            // A degraded parse lost the structure the rules depend on; its decisions are replaced.
            for decision in slice.iter_mut() {
                decision.label = Label::Unknown;
                decision.confidence = DEGRADED_CONFIDENCE;
                decision.reasons = vec![Reason::DegradedToUnknown];
            }
            continue;
        }
        let secondary = section.choice.secondary.as_ref().map(|secondary| {
            let secondary_matches = match_blocks(&secondary.blocks, &history);
            let (matched, strong) = (
                matched_indices(&secondary_matches),
                strong_matched_indices(&secondary_matches),
            );
            let decisions = classify_blocks(
                &secondary.blocks,
                &ClassifyOptions {
                    config,
                    history_matched: &matched,
                    history_strong: &strong,
                    sender_tokens: &sender_tokens,
                    message_is_forward,
                },
            );
            (secondary.blocks.as_slice(), decisions)
        });
        reconcile_section(
            section.choice.primary.representation,
            &document[section.start..section.end],
            slice,
            secondary
                .as_ref()
                .map(|(blocks, decisions)| (*blocks, decisions.as_slice())),
        );
    }

    let mut segments = to_segments(&document, &decisions, &block_sources, &config);
    let primary_representation = segmented[0].choice.primary.representation;

    if segments.is_empty() {
        warnings.push(Warning {
            code: WarningCode::NoVisibleBodyText,
            detail: None,
            mime_part: Some(document[0].mime_part.clone()),
        });
    }

    let any_degraded = segmented.iter().any(|s| s.choice.primary.degraded);
    let body_has_text = document.iter().any(|block| !is_blank(&block.content));
    let visible = segments.iter().any(|s| s.visibility != Visibility::Hide);

    // A message with body text always yields something visible.
    if body_has_text && !visible {
        warnings.push(Warning {
            code: WarningCode::ExtractionDegraded,
            detail: Some("no visible segment survived classification".into()),
            mime_part: None,
        });
        for segment in &mut segments {
            segment.visibility = Visibility::Show;
            segment.label = Label::Unknown;
            segment.reasons.push(Reason::DegradedToUnknown);
        }
        return Ok(AnalyzeResult {
            segments,
            hidden_segments: Vec::new(),
            overall_confidence: DEGRADED_CONFIDENCE,
            warnings,
            primary_representation: Some(primary_representation),
            extractor_version: EXTRACTOR_VERSION,
            history_used: !history.is_empty(),
            is_reply,
            canonical_text,
        });
    }

    let overall = overall_confidence(&segments);
    let (hidden, shown): (Vec<Segment>, Vec<Segment>) =
        segments.into_iter().partition(|s| s.visibility == Visibility::Hide);
    Ok(AnalyzeResult {
        segments: shown,
        hidden_segments: hidden,
        overall_confidence: if any_degraded {
            overall.min(DEGRADED_CONFIDENCE)
        } else {
            overall
        },
        warnings,
        primary_representation: Some(primary_representation),
        extractor_version: EXTRACTOR_VERSION,
        history_used: !history.is_empty(),
        is_reply,
        canonical_text,
    })
}
