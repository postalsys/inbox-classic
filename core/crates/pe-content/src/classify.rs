//! Stages 6 to 8: rule based sequence classification, reconciliation of the plain text and HTML
//! representations, and confidence bands.
//!
//! The load bearing rule is the anchor requirement: a quote region becomes REPLY_HISTORY only when
//! something independent of the quoting says it is history (an attribution line, a client quote
//! container, a client separator, or a match against a message that already existed). Quote depth
//! alone gives INLINE_QUOTE or UNKNOWN, both of which stay visible.

use std::collections::BTreeSet;

use crate::block::{Block, BlockKind, EvidenceKind};
use crate::{ConfidenceConfig, Label, Reason, Representation, Visibility};

#[derive(Debug, Clone)]
pub(crate) struct Decision {
    pub label: Label,
    pub confidence: f64,
    pub reasons: Vec<Reason>,
}

pub(crate) struct ClassifyOptions<'a> {
    pub config: ConfidenceConfig,
    /// Blocks whose text was found in a known earlier message.
    pub history_matched: &'a BTreeSet<usize>,
    /// Blocks whose match was strong enough to stand on its own.
    pub history_strong: &'a BTreeSet<usize>,
    /// Display name and local part tokens of the sender, lowercased.
    pub sender_tokens: &'a [String],
    /// The subject marks the message as a forward and not as a reply.
    pub message_is_forward: bool,
}

/// Confidence for history identified only by matching an earlier message: under the default
/// hide threshold, so it can collapse but never hide.
const UNMARKED_HISTORY_CONFIDENCE: f64 = 0.9;

const TOP_OF_SIGNATURE: &[&str] = &[
    "signature:best_regards",
    "signature:sent_from_device",
    "signature:sent_from_localised",
    "signature:dash_dash_space",
];

fn top_signal(block: &Block) -> bool {
    block
        .evidence
        .iter()
        .any(|e| e.kind == EvidenceKind::Signature && TOP_OF_SIGNATURE.contains(&e.id.as_str()))
}

fn strength_of(block: &Block, kind: EvidenceKind) -> f64 {
    block
        .evidence
        .iter()
        .filter(|e| e.kind == kind && e.strength > 0.0)
        .map(|e| e.strength)
        .fold(0.0, f64::max)
}

fn has_words(block: &Block) -> bool {
    block.features.word_count > 0 && !block.features.is_all_blank
}

fn is_quote(block: &Block) -> bool {
    block.kind == BlockKind::Quote || block.features.quote_depth > 0 || block.features.blockquote_depth > 0
}

/// Client generated boilerplate that introduces a quote.
fn is_anchor_block(block: &Block) -> bool {
    matches!(block.kind, BlockKind::ReplyHeader | BlockKind::QuotedHeaderBlock)
}

/// An embedded header block within the next few non-blank blocks.
fn embedded_header_after(blocks: &[Block], start: usize) -> bool {
    let mut seen = 0;
    for block in blocks.iter().skip(start) {
        if seen >= 4 {
            break;
        }
        if block.features.is_all_blank {
            continue;
        }
        seen += 1;
        if block.kind == BlockKind::QuotedHeaderBlock || block.features.header_field_lines >= 2 {
            return true;
        }
    }
    false
}

#[derive(Clone, Copy)]
struct Run {
    start: usize,
    end: usize,
    quoted: bool,
}

/// Alternating quoted and unquoted runs, ignoring blank blocks.
fn find_runs(blocks: &[Block]) -> Vec<Run> {
    let mut runs: Vec<Run> = Vec::new();
    for block in blocks {
        if block.features.is_all_blank {
            continue;
        }
        let quoted = is_quote(block) || is_anchor_block(block);
        match runs.last_mut() {
            Some(last) if last.quoted == quoted => last.end = block.index,
            _ => runs.push(Run {
                start: block.index,
                end: block.index,
                quoted,
            }),
        }
    }
    runs
}

fn set(decisions: &mut [Decision], index: usize, label: Label, confidence: f64, reasons: Vec<Reason>) {
    if let Some(decision) = decisions.get_mut(index) {
        decision.label = label;
        decision.confidence = confidence;
        decision.reasons = reasons;
    }
}

fn push_reason(reasons: &mut Vec<Reason>, reason: Reason) {
    if !reasons.contains(&reason) {
        reasons.push(reason);
    }
}

/// Classify one sequence of blocks. `blocks[i].index` must equal `i`.
pub(crate) fn classify_blocks(blocks: &[Block], options: &ClassifyOptions) -> Vec<Decision> {
    use Label::*;
    let config = &options.config;
    let n = blocks.len();
    let mut decisions: Vec<Decision> = (0..n)
        .map(|_| Decision {
            label: NewContent,
            confidence: 0.95,
            reasons: vec![Reason::NewContentDefault],
        })
        .collect();

    // Pass 1: anchors.
    let mut reply_anchor: Option<usize> = None;
    let mut reply_anchor_strength = 0.0;
    let mut forward_anchor: Option<usize> = None;
    let mut forward_anchor_strength = 0.0;
    for block in blocks {
        let forward = strength_of(block, EvidenceKind::ForwardAnchor);
        if forward > 0.0 && forward_anchor.is_none() {
            forward_anchor = Some(block.index);
            forward_anchor_strength = forward;
        }
        let reply = strength_of(block, EvidenceKind::ReplyAnchor);
        if reply > 0.0 && reply_anchor.is_none() {
            reply_anchor = Some(block.index);
            reply_anchor_strength = reply;
        }
    }

    // A quote container anchors only when an attribution or a blockquote corroborates it.
    let has_attribution = blocks.iter().any(|block| {
        is_anchor_block(block)
            || block
                .evidence
                .iter()
                .any(|e| matches!(e.kind, EvidenceKind::Attribution | EvidenceKind::ReplyAnchor))
    });
    let has_blockquote = blocks.iter().any(|block| block.features.blockquote_depth > 0);
    let mut container_anchor: Option<usize> = None;
    let mut container_strength = 0.0;
    if has_attribution || has_blockquote {
        for block in blocks {
            let container = strength_of(block, EvidenceKind::QuoteContainer);
            if container >= config.min_anchor_strength {
                container_anchor = Some(block.index);
                container_strength = container;
                break;
            }
        }
    }
    if let Some(container) = container_anchor
        && reply_anchor.is_none_or(|reply| container < reply)
    {
        reply_anchor = Some(container);
        reply_anchor_strength = f64::max(reply_anchor_strength, container_strength);
    }

    // Clients that mark the boundary rather than wrapping the quote.
    let mut separator_anchor: Option<usize> = None;
    let mut separator_strength = 0.0;
    for block in blocks {
        let strength = strength_of(block, EvidenceKind::Separator);
        if strength >= config.min_anchor_strength {
            separator_anchor = Some(block.index);
            separator_strength = strength;
            break;
        }
    }
    // A weak rule counts only when an embedded header block follows closely.
    if separator_anchor.is_none() {
        'outer: for block in blocks {
            if block.kind != BlockKind::Separator || strength_of(block, EvidenceKind::Separator) < 0.6 {
                continue;
            }
            let mut seen = 0;
            for candidate in blocks.iter().skip(block.index + 1) {
                if seen >= 3 {
                    break;
                }
                if candidate.features.is_all_blank {
                    continue;
                }
                seen += 1;
                if candidate.kind == BlockKind::QuotedHeaderBlock {
                    separator_anchor = Some(block.index);
                    separator_strength = 0.9;
                    break 'outer;
                }
            }
        }
    }

    // Pass 2: footers, within the region the sender authored.
    let first_quoted = blocks
        .iter()
        .find(|b| is_quote(b) && !b.features.is_all_blank)
        .map_or(n, |b| b.index);
    let authored_end = first_quoted
        .min(reply_anchor.unwrap_or(n))
        .min(separator_anchor.unwrap_or(n))
        .min(forward_anchor.unwrap_or(n));

    for i in (0..authored_end).rev() {
        let block = &blocks[i];
        if is_quote(block) {
            break;
        }
        if block
            .evidence
            .iter()
            .any(|e| e.id == "signature:dash_dash_space" && e.strength >= 0.9)
        {
            for j in i..authored_end {
                set(&mut decisions, j, Signature, 0.95, vec![Reason::DashDashDelimiter]);
            }
            break;
        }
    }

    // Disclaimers anywhere, on blocks still considered authored.
    for block in blocks {
        let decision = &mut decisions[block.index];
        if decision.label != NewContent {
            continue;
        }
        let strength = strength_of(block, EvidenceKind::Disclaimer);
        if strength >= 0.7 {
            decision.label = Disclaimer;
            decision.confidence = f64::min(0.95, strength);
            decision.reasons = vec![Reason::DisclaimerPhrase];
        }
    }

    // The signature region: short blocks walked back from the end of the authored region.
    const MAX_SIGNATURE_BLOCKS: usize = 6;
    const MAX_SIGNATURE_WORDS: usize = 60;
    const MAX_BLOCK_WORDS: usize = 25;
    let mut signature_start: Option<usize> = None;
    let mut has_contact = false;
    let mut has_phrase = false;
    let mut has_sender_name = false;
    let mut phrase_strength: f64 = 0.0;
    let mut words = 0;
    let mut collected = 0;
    for i in (0..authored_end).rev() {
        if collected >= MAX_SIGNATURE_BLOCKS {
            break;
        }
        let block = &blocks[i];
        let decision = &decisions[i];
        if block.features.is_all_blank {
            continue;
        }
        if decision.label == Signature {
            signature_start = Some(i);
            continue;
        }
        if is_quote(block) || is_anchor_block(block) || decision.label == Disclaimer {
            break;
        }
        if block.features.word_count > MAX_BLOCK_WORDS {
            break;
        }
        words += block.features.word_count;
        if words > MAX_SIGNATURE_WORDS {
            break;
        }
        if block.features.has_email_address || block.features.has_phone_number || block.features.has_url {
            has_contact = true;
        }
        let strength = strength_of(block, EvidenceKind::Signature);
        if strength > 0.0 {
            has_phrase = true;
            phrase_strength = phrase_strength.max(strength);
        }
        if !options.sender_tokens.is_empty() && !has_sender_name {
            let lowered = block.content.to_lowercase();
            if options
                .sender_tokens
                .iter()
                .any(|token| lowered.contains(token.as_str()))
            {
                has_sender_name = true;
            }
        }
        signature_start = Some(i);
        collected += 1;
        // A closing greeting or a device phrase is the top of a signature.
        if top_signal(block) {
            break;
        }
    }

    let strong_phrase = phrase_strength >= 0.9;
    // A signature signs something: there must be authored content above it.
    let has_content_above = signature_start.is_some_and(|start| {
        (0..start)
            .any(|i| !blocks[i].features.is_all_blank && decisions[i].label == NewContent && has_words(&blocks[i]))
    });
    let signals = [has_contact, has_phrase, has_sender_name]
        .iter()
        .filter(|&&s| s)
        .count();
    let accepted = has_content_above && (strong_phrase || signals >= 2);
    if let Some(start) = signature_start
        && accepted
    {
        let confidence = if phrase_strength >= 0.9 {
            0.95
        } else if signals >= 3 {
            0.9
        } else {
            0.85
        };
        let reason = if phrase_strength >= 0.9 {
            Reason::MobileSignaturePhrase
        } else {
            Reason::SignaturePositionAndLength
        };
        for i in start..authored_end {
            if decisions[i].label == Disclaimer {
                continue;
            }
            if is_quote(&blocks[i]) || is_anchor_block(&blocks[i]) {
                break;
            }
            set(&mut decisions, i, Signature, confidence, vec![reason]);
        }
    }

    // Pass 3: regions.
    let runs = find_runs(blocks);
    let quoted_runs: Vec<Run> = runs.iter().copied().filter(|run| run.quoted).collect();
    let content_runs_after_first_quote: Vec<Run> = runs
        .iter()
        .copied()
        .filter(|run| !run.quoted && quoted_runs.first().is_some_and(|first| run.start > first.start))
        .collect();

    // Where unmarked history begins: an anchor followed closely by an embedded header block, with
    // something authored above it.
    let authored_before = |decisions: &[Decision], index: usize| {
        (0..index).any(|i| {
            let block = &blocks[i];
            has_words(block) && !is_quote(block) && !is_anchor_block(block) && decisions[i].label == NewContent
        })
    };
    let unmarked_history_start = [separator_anchor, reply_anchor]
        .into_iter()
        .flatten()
        .filter(|&index| embedded_header_after(blocks, index) && authored_before(&decisions, index))
        .fold(n, usize::min);

    let interleaved = quoted_runs.len() > 1
        && content_runs_after_first_quote.iter().any(|run| {
            if run.start > unmarked_history_start {
                return false;
            }
            if let Some(container) = container_anchor
                && run.start >= container
                && strength_of(&blocks[run.start], EvidenceKind::QuoteContainer) >= config.min_anchor_strength
            {
                return false;
            }
            (run.start..=run.end)
                .any(|i| decisions[i].label == NewContent && has_words(&blocks[i]) && !is_anchor_block(&blocks[i]))
        });

    let inside_forward = |index: usize| forward_anchor.is_some_and(|forward| index >= forward);

    if let Some(forward) = forward_anchor {
        for i in forward..n {
            if decisions[i].label == Disclaimer {
                continue;
            }
            set(
                &mut decisions,
                i,
                ForwardedContent,
                f64::min(0.95, forward_anchor_strength),
                vec![Reason::PrecededByForwardHeader],
            );
        }
    }

    for run in &quoted_runs {
        if forward_anchor.is_some_and(|forward| run.start >= forward) {
            continue;
        }
        let anchored = reply_anchor.is_some_and(|reply| reply <= run.end);
        let anchor_strength = if anchored { reply_anchor_strength } else { 0.0 };

        let new_content_after = (run.end + 1..n).any(|i| {
            let block = &blocks[i];
            !block.features.is_all_blank
                && !matches!(decisions[i].label, Signature | Disclaimer)
                && !is_quote(block)
                && !is_anchor_block(block)
                && has_words(block)
        });

        let run_depth = (run.start..=run.end)
            .map(|i| blocks[i].features.quote_depth.max(blocks[i].features.blockquote_depth))
            .max()
            .unwrap_or(0);
        // Inline answers happen at depth one; deeper quoting is a chain.
        let eligible_for_inline = run_depth <= 1;

        let (label, confidence, reasons) = if interleaved && eligible_for_inline && new_content_after {
            (
                InlineQuote,
                0.9,
                vec![Reason::InterleavedWithNewContent, Reason::NewContentAfterRegion],
            )
        } else if anchored {
            let mut reasons = vec![if reply_anchor == container_anchor {
                Reason::InsideQuoteContainer
            } else {
                Reason::PrecededByReplyHeader
            }];
            if new_content_after {
                reasons.push(Reason::NewContentAfterRegion);
                (ReplyHistory, 0.9, reasons)
            } else {
                reasons.push(Reason::FinalContiguousQuoteRegion);
                reasons.push(Reason::NoNewContentAfterRegion);
                (ReplyHistory, f64::min(0.97, 0.6 + anchor_strength * 0.4), reasons)
            }
        } else if new_content_after && eligible_for_inline {
            (
                InlineQuote,
                0.9,
                vec![Reason::NewContentAfterRegion, Reason::NoAnchorForQuote],
            )
        } else {
            (
                Unknown,
                0.5,
                vec![Reason::NoAnchorForQuote, Reason::AmbiguousKeptVisible],
            )
        };

        for i in run.start..=run.end {
            if matches!(decisions[i].label, Signature | Disclaimer) {
                continue;
            }
            set(&mut decisions, i, label, confidence, reasons.clone());
        }
    }

    // Unmarked history after a strong anchor, swept only as far as the first quoted block.
    if let Some(anchor) = reply_anchor
        && reply_anchor_strength >= config.min_anchor_strength
        && !interleaved
    {
        let limit = (anchor + 1..n).find(|&i| is_quote(&blocks[i])).unwrap_or(n);
        let corroborated = embedded_header_after(blocks, anchor);
        let reasons = if corroborated {
            vec![
                Reason::PrecededByReplyHeader,
                Reason::ContainsOldMessageHeaders,
                Reason::NoNewContentAfterRegion,
            ]
        } else {
            vec![Reason::PrecededByReplyHeader, Reason::AmbiguousKeptVisible]
        };
        let confidence = if corroborated { 0.96 } else { 0.9 };
        for (i, decision) in decisions.iter_mut().enumerate().take(limit).skip(anchor) {
            if inside_forward(i) || matches!(decision.label, ForwardedContent | InlineQuote) {
                continue;
            }
            if decision.label == ReplyHistory && decision.confidence >= confidence {
                continue;
            }
            decision.label = ReplyHistory;
            decision.confidence = confidence;
            decision.reasons = reasons.clone();
        }
    }

    // A client reply separator makes everything after it history.
    if let Some(separator) = separator_anchor
        && !interleaved
    {
        for (i, decision) in decisions.iter_mut().enumerate().skip(separator) {
            if inside_forward(i) || matches!(decision.label, ForwardedContent | ReplyHistory | InlineQuote) {
                continue;
            }
            decision.label = ReplyHistory;
            decision.confidence = f64::min(0.96, 0.6 + separator_strength * 0.4);
            decision.reasons = vec![Reason::OutlookReplySeparator, Reason::FinalContiguousQuoteRegion];
        }
    }

    // An anchor line outside any quoted run belongs to the region it introduces.
    for block in blocks {
        if !is_anchor_block(block) || decisions[block.index].label != NewContent {
            continue;
        }
        let after = block.index + 1;
        let next = if after < n && blocks[after].features.is_all_blank {
            after + 1
        } else {
            after
        };
        if let Some(next) = decisions.get(next).cloned()
            && after < n
            && matches!(next.label, ReplyHistory | InlineQuote | ForwardedContent)
        {
            set(&mut decisions, block.index, next.label, next.confidence, next.reasons);
        }
    }

    // History matches, strictly per block: confirm history, rescue an unanchored quote, never
    // promote an inline quote or new content.
    for &index in options.history_matched {
        let (Some(block), Some(decision)) = (blocks.get(index), decisions.get_mut(index)) else {
            continue;
        };
        if decision.label == ReplyHistory {
            let trailing = decision.reasons.contains(&Reason::NoNewContentAfterRegion);
            let ceiling = if trailing && !inside_forward(index) { 0.98 } else { 0.94 };
            decision.confidence = decision.confidence.max(ceiling);
            push_reason(&mut decision.reasons, Reason::MatchedParentMessage);
            continue;
        }
        if decision.label == Unknown && (is_quote(block) || is_anchor_block(block)) {
            decision.label = ReplyHistory;
            decision.confidence = 0.96;
            decision.reasons = vec![Reason::MatchedParentMessage, Reason::QuoteDepthPositive];
        }
    }

    // Unmarked history only the thread can identify: collapsed, with authored text above it.
    if !options.history_strong.is_empty() {
        let promotable: BTreeSet<usize> = options
            .history_strong
            .iter()
            .copied()
            .filter(|&index| {
                blocks.get(index).is_some_and(|block| {
                    decisions[index].label == NewContent
                        && has_words(block)
                        && !is_quote(block)
                        && !is_anchor_block(block)
                })
            })
            .collect();
        for &index in &promotable {
            let authored_above = (0..index)
                .any(|i| decisions[i].label == NewContent && has_words(&blocks[i]) && !promotable.contains(&i));
            if !authored_above {
                continue;
            }
            set(
                &mut decisions,
                index,
                ReplyHistory,
                UNMARKED_HISTORY_CONFIDENCE,
                vec![Reason::MatchedParentMessage, Reason::ShingleOverlapHigh],
            );
        }
    }

    // Pass 4: blank blocks inherit from their neighbours.
    for i in 0..n {
        if !blocks[i].features.is_all_blank || i == 0 {
            continue;
        }
        let previous = decisions[i - 1].clone();
        match decisions.get(i + 1).cloned() {
            Some(next) if next.label == previous.label => {
                decisions[i] = Decision {
                    label: previous.label,
                    confidence: f64::min(previous.confidence, next.confidence),
                    reasons: previous.reasons,
                };
            }
            _ => decisions[i] = previous,
        }
    }

    // The sender said the answers are inline: the directly quoted message stays visible.
    if let Some(first_history) = decisions.iter().position(|d| d.label == ReplyHistory)
        && first_history > 0
        && (0..first_history).any(|i| {
            matches!(decisions[i].label, NewContent | Unknown)
                && blocks[i].evidence.iter().any(|e| e.id.starts_with("announce:"))
        })
    {
        for i in first_history..n {
            let decision = &mut decisions[i];
            if decision.label == ReplyHistory && blocks[i].features.quote_depth <= 1 {
                decision.label = InlineQuote;
                decision.confidence = 0.6;
                decision.reasons.push(Reason::InterleavedWithNewContent);
                decision.reasons.push(Reason::InlineAnswersAnnounced);
            }
        }
    }

    // In a forward, what the reply rules found is the forwarded message.
    if options.message_is_forward && forward_anchor.is_none() {
        for decision in &mut decisions {
            if decision.label == ReplyHistory {
                decision.label = ForwardedContent;
                decision.reasons.push(Reason::ForwardBySubject);
            }
        }
    }

    // The block where history begins stays visible when the sender typed lines above its headers.
    if let Some(i) = decisions
        .iter()
        .position(|d| matches!(d.label, ReplyHistory | ForwardedContent))
        && blocks[i].features.authored_lines_before_anchor > 0
    {
        let decision = &mut decisions[i];
        decision.label = Unknown;
        decision.confidence = 0.5;
        decision.reasons.push(Reason::AuthoredTextBeforeAnchor);
        decision.reasons.push(Reason::AmbiguousKeptVisible);
    }

    // A message never comes out as only its footer.
    let has_visible_authored =
        (0..n).any(|i| has_words(&blocks[i]) && matches!(decisions[i].label, NewContent | InlineQuote | Unknown));
    if !has_visible_authored {
        for i in 0..n {
            if decisions[i].label == Signature && has_words(&blocks[i]) {
                set(&mut decisions, i, NewContent, 0.7, vec![Reason::AmbiguousKeptVisible]);
            }
        }
    }

    decisions
}

/// One representation of one body section, before classification.
pub(crate) struct RepresentationInfo {
    pub representation: Representation,
    pub blocks: Vec<Block>,
    /// Characters of content, in UTF-16 code units, to spot a stub.
    pub content_chars: usize,
    pub has_anchor: bool,
    pub degraded: bool,
}

pub(crate) struct PrimaryChoice {
    pub primary: RepresentationInfo,
    pub secondary: Option<RepresentationInfo>,
}

/// Choose which representation of a section drives the output. HTML wins by default, plain text
/// when the HTML is a stub or only the text has an anchor, and a degraded one never displaces one
/// that segmented.
pub(crate) fn pick_primary(
    text: Option<RepresentationInfo>,
    html: Option<RepresentationInfo>,
) -> Option<PrimaryChoice> {
    let (text, html) = match (text, html) {
        (Some(text), None) => {
            return Some(PrimaryChoice {
                primary: text,
                secondary: None,
            });
        }
        (None, Some(html)) => {
            return Some(PrimaryChoice {
                primary: html,
                secondary: None,
            });
        }
        (None, None) => return None,
        (Some(text), Some(html)) => (text, html),
    };
    let html_is_stub = html.content_chars * 4 < text.content_chars;
    let text_is_stub = text.content_chars * 4 < html.content_chars;

    let text_primary = (html_is_stub && !text_is_stub) || (!html.has_anchor && text.has_anchor && !text_is_stub);
    let (mut primary, mut secondary, mut primary_stub, mut secondary_stub) = if text_primary {
        (text, html, text_is_stub, html_is_stub)
    } else {
        (html, text, html_is_stub, text_is_stub)
    };
    if primary.degraded && !secondary.degraded && !secondary_stub {
        std::mem::swap(&mut primary, &mut secondary);
        std::mem::swap(&mut primary_stub, &mut secondary_stub);
    }
    let _ = primary_stub;
    if secondary.degraded {
        return Some(PrimaryChoice {
            primary,
            secondary: None,
        });
    }
    Some(PrimaryChoice {
        primary,
        secondary: Some(secondary),
    })
}

fn history_share(blocks: &[Block], decisions: &[Decision]) -> f64 {
    let mut history = 0usize;
    let mut total = 0usize;
    for (block, decision) in blocks.iter().zip(decisions) {
        let chars = crate::util::js_len(&block.content);
        total += chars;
        if decision.label == Label::ReplyHistory {
            history += chars;
        }
    }
    if total > 0 { history as f64 / total as f64 } else { 0.0 }
}

/// Apply cross representation evidence to one section's decisions. Only ever lowers confidence.
pub(crate) fn reconcile_section(
    representation: Representation,
    blocks: &[Block],
    decisions: &mut [Decision],
    secondary: Option<(&[Block], &[Decision])>,
) {
    let reason = match representation {
        Representation::Html => Reason::HtmlPrimaryRepresentation,
        Representation::Text => Reason::TextPrimaryRepresentation,
    };
    for decision in decisions.iter_mut() {
        push_reason(&mut decision.reasons, reason);
    }
    let Some((secondary_blocks, secondary_decisions)) = secondary else {
        return;
    };
    if (history_share(blocks, decisions) - history_share(secondary_blocks, secondary_decisions)).abs() <= 0.25 {
        return;
    }
    for decision in decisions.iter_mut() {
        if decision.label != Label::ReplyHistory || decision.reasons.contains(&Reason::MatchedParentMessage) {
            continue;
        }
        decision.confidence = decision.confidence.min(0.9);
        push_reason(&mut decision.reasons, Reason::RepresentationsDisagree);
    }
}

/// Map a label and confidence to a visibility band. Only REPLY_HISTORY can be hidden.
pub(crate) fn visibility_for(label: Label, confidence: f64, config: &ConfidenceConfig) -> Visibility {
    match label {
        Label::ReplyHistory if confidence >= config.hide_threshold => Visibility::Hide,
        Label::ReplyHistory | Label::ForwardedContent | Label::Signature | Label::Disclaimer => {
            if confidence >= config.collapse_threshold {
                Visibility::Collapse
            } else {
                Visibility::Show
            }
        }
        Label::InlineQuote | Label::NewContent | Label::Unknown => Visibility::Show,
    }
}
