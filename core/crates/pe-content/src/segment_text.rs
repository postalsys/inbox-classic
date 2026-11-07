//! Stage 3: plain text block segmentation.
//!
//! Blocks tile the canonical text: every byte belongs to exactly one block, blank lines and
//! trailing whitespace included. Boundaries are placed at quote depth changes, blank lines,
//! attribution lines, forward markers, signature delimiters, rule separators and the start of an
//! embedded header block.

use std::collections::BTreeMap;
use std::sync::LazyLock;

use crate::Representation;
use crate::block::{Block, BlockKind, Evidence, FeatureContext, compute_features};
use crate::detect::{
    detect_attribution_line, detect_disclaimer, detect_forward_marker, detect_inline_announcement,
    detect_quoted_header_block, detect_rule_separator, detect_signature_delimiter, detect_signature_phrases,
    detect_signature_shape,
};
use crate::text::{CanonicalText, TextLine, canonicalise_text};
use crate::util::js_trim;
use pe_jsre::JsRegex;

#[derive(Clone, Default)]
struct Boundary {
    kind: Option<BlockKind>,
    evidence: Option<Evidence>,
    /// The boundary spans exactly one line.
    single: bool,
}

static LIST_ITEM: LazyLock<JsRegex> = LazyLock::new(|| JsRegex::fixed(r"^([-*+•‣◦]|\d+[.)])\s+", ""));
static COLUMNS: LazyLock<JsRegex> = LazyLock::new(|| JsRegex::fixed(r"\S {3,}\S", ""));

/// Strip quote prefixes and trim surrounding blank lines.
fn content_of(text: &str, lines: &[TextLine]) -> String {
    let mut start = 0;
    let mut end = lines.len();
    while start < end && lines[start].blank {
        start += 1;
    }
    while end > start && lines[end - 1].blank {
        end -= 1;
    }
    let mut out = String::new();
    for (i, line) in lines[start..end].iter().enumerate() {
        if i > 0 {
            out.push('\n');
        }
        out.push_str(line.content(text));
    }
    out
}

/// Deepest quote level, decided by the lines with content. A block of nothing but empty quoted
/// lines keeps its quoting.
fn max_depth(lines: &[TextLine]) -> usize {
    let mut depth = 0;
    let mut blank_depth = 0;
    let mut saw_content = false;
    for line in lines {
        if line.blank {
            blank_depth = blank_depth.max(line.depth);
        } else {
            saw_content = true;
            depth = depth.max(line.depth);
        }
    }
    if saw_content { depth } else { blank_depth }
}

fn classify_kind(text: &str, lines: &[TextLine], forced: Option<BlockKind>) -> BlockKind {
    if let Some(kind) = forced {
        return kind;
    }
    let body: Vec<&TextLine> = lines.iter().filter(|line| !line.blank).collect();
    let Some(first) = body.first() else {
        return BlockKind::Blank;
    };
    if first.depth > 0 {
        return BlockKind::Quote;
    }
    let contents: Vec<&str> = body.iter().map(|line| js_trim(line.content(text))).collect();
    if contents.iter().all(|line| LIST_ITEM.is_match(line)) {
        return BlockKind::List;
    }
    if contents.len() > 1 && contents.iter().all(|line| line.contains('|') || COLUMNS.is_match(line)) {
        return BlockKind::Table;
    }
    BlockKind::Paragraph
}

/// Segment a plain text part into blocks.
pub(crate) fn segment_text_blocks(raw: &str, mime_part: &str) -> (CanonicalText, Vec<Block>) {
    let canonical = canonicalise_text(raw);
    let text = canonical.text.as_str();
    let lines = &canonical.lines;

    let contents: Vec<&str> = lines.iter().map(|line| line.content(text)).collect();
    let mut boundaries: BTreeMap<usize, Boundary> = BTreeMap::new();
    let add = |boundaries: &mut BTreeMap<usize, Boundary>, line: usize, boundary: Boundary| {
        let strength = |b: &Boundary| b.evidence.as_ref().map_or(0.0, |e| e.strength);
        match boundaries.get(&line) {
            Some(existing) if strength(&boundary) <= strength(existing) => {}
            _ => {
                boundaries.insert(line, boundary);
            }
        }
    };

    // Line level anchors.
    for line in lines {
        if line.blank {
            continue;
        }
        let content = line.content(text);
        let found = if let Some(evidence) = detect_attribution_line(content) {
            Some((BlockKind::ReplyHeader, evidence))
        } else if let Some(evidence) = detect_forward_marker(content) {
            Some((BlockKind::ForwardHeader, evidence))
        } else if let Some(evidence) = detect_signature_delimiter(content) {
            Some((BlockKind::Separator, evidence))
        } else {
            detect_rule_separator(content).map(|evidence| (BlockKind::Separator, evidence))
        };
        if let Some((kind, evidence)) = found {
            add(
                &mut boundaries,
                line.index,
                Boundary {
                    kind: Some(kind),
                    evidence: Some(evidence),
                    single: true,
                },
            );
        }
    }

    // Embedded header blocks, scanning on so that several can be found.
    let mut cursor = 0;
    while cursor < lines.len() {
        let Some(found) = detect_quoted_header_block(&contents, cursor) else {
            break;
        };
        add(
            &mut boundaries,
            found.start_line,
            Boundary {
                kind: Some(BlockKind::QuotedHeaderBlock),
                evidence: Some(found.evidence),
                single: false,
            },
        );
        if found.end_line + 1 < lines.len() && !boundaries.contains_key(&(found.end_line + 1)) {
            add(&mut boundaries, found.end_line + 1, Boundary::default());
        }
        cursor = found.end_line + 1;
    }

    // Structural boundaries: depth changes and blank line separations.
    let mut previous_depth = lines[0].depth;
    let mut saw_blank = false;
    for line in lines.iter().skip(1) {
        if line.blank {
            saw_blank = true;
            continue;
        }
        let forced_single_before = boundaries.get(&(line.index - 1)).is_some_and(|b| b.single);
        if (line.depth != previous_depth || saw_blank || forced_single_before) && !boundaries.contains_key(&line.index)
        {
            add(&mut boundaries, line.index, Boundary::default());
        }
        previous_depth = line.depth;
        saw_blank = false;
    }

    // A single line boundary also closes, so the following line starts a new block.
    let singles: Vec<usize> = boundaries
        .iter()
        .filter(|(_, b)| b.single)
        .map(|(&line, _)| line)
        .collect();
    for line in singles {
        if line + 1 < lines.len() && !boundaries.contains_key(&(line + 1)) {
            boundaries.insert(line + 1, Boundary::default());
        }
    }

    let mut starts: Vec<usize> = boundaries.keys().copied().collect();
    if starts.first() != Some(&0) {
        starts.insert(0, 0);
    }

    let mut blocks: Vec<Block> = Vec::with_capacity(starts.len());
    for (i, &start_line) in starts.iter().enumerate() {
        let end_line = starts.get(i + 1).copied().unwrap_or(lines.len());
        let slice = &lines[start_line..end_line];
        let (Some(first), Some(last)) = (slice.first(), slice.last()) else {
            continue;
        };
        // Include the newline that ends the last line, unless this is the end of the text.
        let end = if end_line < lines.len() {
            lines[end_line].start
        } else {
            last.end
        };
        let boundary = boundaries.get(&start_line);
        let content = content_of(text, slice);
        let features = compute_features(
            &content,
            &FeatureContext {
                start16: first.start16,
                total16: canonical.len16,
                quote_depth: max_depth(slice),
                blockquote_depth: 0,
            },
        );
        blocks.push(Block {
            index: blocks.len(),
            source_index: blocks.len(),
            kind: classify_kind(text, slice, boundary.and_then(|b| b.kind)),
            representation: Representation::Text,
            mime_part: mime_part.to_string(),
            start: first.start,
            end,
            html_start: None,
            html_end: 0,
            content,
            dom_path: None,
            features,
            evidence: boundary.and_then(|b| b.evidence.clone()).into_iter().collect(),
        });
    }

    // Block level evidence, once positions are known.
    for block in &mut blocks {
        if block.kind == BlockKind::Blank {
            continue;
        }
        let block_lines: Vec<&str> = block.content.split('\n').collect();
        let mut found = detect_signature_phrases(&block_lines);
        found.extend(detect_inline_announcement(&block_lines));
        found.extend(detect_signature_shape(&block.features));
        found.extend(detect_disclaimer(&block.content, &block.features));
        block.evidence.extend(found);
    }

    (canonical, blocks)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tiles_the_canonical_text() {
        let input = "Hi Bob,\r\n\r\nSounds good.\r\n\r\nOn Mon, 13 Jan 2025 at 09:15, Alice <a@example.com> wrote:\r\n> Can we meet?\r\n> \r\n> Alice\r\n";
        let (canonical, blocks) = segment_text_blocks(input, "TEXT");
        let joined: String = blocks.iter().map(|b| &canonical.text[b.start..b.end]).collect();
        assert_eq!(joined, canonical.text);
        assert!(blocks.iter().any(|b| b.kind == BlockKind::ReplyHeader));
        assert!(blocks.iter().any(|b| b.kind == BlockKind::Quote));
    }
}
