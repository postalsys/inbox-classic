//! The common representation both the HTML and the plain text body are turned into: visible text,
//! the style of every stretch of it, and the blocks (paragraphs, table cells, lines) it is split in.
//! A port of otp-detect's src/doc.ts. Offsets are byte offsets into `text`; [`Doc::units`] turns
//! them into the UTF-16 offsets the features count in.

use std::rc::Rc;
use std::sync::LazyLock;

use pe_jsre::{JsRegex, is_space};

use crate::js::Units;

pub const DEFAULT_FONT_SIZE: f64 = 16.0;

#[derive(Debug, Clone, PartialEq)]
pub struct Style {
    /// Pixels; NaN where otp-detect ends up with something that is not a number
    pub font_size: f64,
    pub bold: bool,
    pub letter_spacing: bool,
    pub link: bool,
    pub heading: bool,
    pub mono: bool,
    pub hidden: bool,
    /// Inside quoted reply history or a forwarded message
    pub quote: bool,
}

pub const DEFAULT_STYLE: Style = Style {
    font_size: DEFAULT_FONT_SIZE,
    bold: false,
    letter_spacing: false,
    link: false,
    heading: false,
    mono: false,
    hidden: false,
    quote: false,
};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Source {
    Html,
    Text,
}

impl Source {
    pub fn name(self) -> &'static str {
        match self {
            Source::Html => "html",
            Source::Text => "text",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Span {
    pub start: usize,
    pub end: usize,
}

#[derive(Debug, Clone)]
pub struct StyledSpan {
    pub start: usize,
    pub end: usize,
    /// Shared by the text of one element: spans merge when they have the very same style object,
    /// as otp-detect compares them by identity
    pub style: Rc<Style>,
}

pub struct Doc {
    pub source: Source,
    pub text: String,
    /// Consecutive, non-overlapping, sorted by start; text between spans is whitespace
    pub spans: Vec<StyledSpan>,
    /// Every block, innermost ones included, sorted by start
    pub blocks: Vec<Span>,
    /// UTF-16 offset where reply history or a forwarded message starts, the length if none
    pub quote_start: usize,
    pub units: Units,
}

impl Doc {
    /// The length of the text in UTF-16 code units
    pub fn len_units(&self) -> usize {
        self.units.at(self.text.len())
    }
}

/// `[\s ​‌‍  ﻿]`
fn is_collapsed_space(c: char) -> bool {
    is_space(c) || matches!(c, '\u{200B}' | '\u{200C}' | '\u{200D}')
}

// "On Tue, 1 Jan 2025 John wrote:", Outlook and forward separators, and the same in Estonian
static ATTRIBUTION: LazyLock<JsRegex> = LazyLock::new(|| {
    JsRegex::fixed(
        r"^(?:-{2,}\s*(?:original message|forwarded message|edastatud kiri|algne kiri)\s*-{2,}|-{5,}|on .{3,200}(?:wrote|kirjutas):|.{3,120}kirjutas(?: .{0,80})?:|from: .{3,200}\n(?:sent|date): )",
        "im",
    )
});

/// The UTF-16 offset of the first attribution line, the length of the text if none. The expression
/// has no `u` flag, so its `.` is one UTF-16 code unit and a character outside the BMP takes two:
/// it reads such a character as two U+FFFD, which like the two halves match `.` and nothing else
/// of it.
fn attribution_start(text: &str, units: &Units) -> usize {
    if !text.chars().any(|c| c.len_utf16() == 2) {
        return units.at(ATTRIBUTION.re().find(text).map_or(text.len(), |m| m.start()));
    }
    let mut wide = String::with_capacity(text.len() + 8);
    for c in text.chars() {
        if c.len_utf16() == 2 {
            wide.push_str("\u{FFFD}\u{FFFD}");
        } else {
            wide.push(c);
        }
    }
    let wide_units = Units::new(&wide);
    wide_units.at(ATTRIBUTION.re().find(&wide).map_or(wide.len(), |m| m.start()))
}

pub struct DocBuilder {
    source: Source,
    text: String,
    spans: Vec<StyledSpan>,
    blocks: Vec<Span>,
    open_blocks: Vec<usize>,
}

impl DocBuilder {
    pub fn new(source: Source) -> DocBuilder {
        DocBuilder {
            source,
            text: String::new(),
            spans: Vec::new(),
            blocks: Vec::new(),
            open_blocks: Vec::new(),
        }
    }

    fn last(&self) -> Option<char> {
        self.text.chars().next_back()
    }

    pub fn text(&mut self, raw: &str, style: &Rc<Style>) {
        let at_line_start = matches!(self.last(), None | Some('\n' | ' '));
        let start = self.text.len();
        let mut in_space = false;
        for c in raw.chars() {
            if is_collapsed_space(c) {
                if !in_space && !(at_line_start && self.text.len() == start) {
                    self.text.push(' ');
                }
                in_space = true;
            } else {
                self.text.push(c);
                in_space = false;
            }
        }
        if self.text.len() == start {
            return;
        }
        let end = self.text.len();
        match self.spans.last_mut() {
            Some(span) if Rc::ptr_eq(&span.style, style) && span.end == start => span.end = end,
            _ => self.spans.push(StyledSpan {
                start,
                end,
                style: style.clone(),
            }),
        }
    }

    fn drop_trailing_space(&mut self) {
        if self.last() != Some(' ') {
            return;
        }
        self.text.pop();
        let len = self.text.len();
        if let Some(span) = self.spans.last_mut()
            && span.end > len
        {
            span.end = len;
        }
    }

    pub fn newline(&mut self) {
        self.drop_trailing_space();
        if !self.text.is_empty() && self.last() != Some('\n') {
            self.text.push('\n');
        }
    }

    pub fn open_block(&mut self) {
        self.newline();
        self.open_blocks.push(self.text.len());
    }

    pub fn close_block(&mut self) {
        let Some(start) = self.open_blocks.pop() else {
            return;
        };
        // Text is collapsed as it is added, so at most one whitespace character trails it
        let end = self.text.len() - usize::from(matches!(self.last(), Some('\n' | ' ')));
        if end > start {
            self.blocks.push(Span { start, end });
        }
        self.newline();
    }

    pub fn finish(mut self) -> Doc {
        while !self.open_blocks.is_empty() {
            self.close_block();
        }
        let len = self.text.trim_end_matches(is_space).len();
        self.text.truncate(len);
        let text = self.text;
        let mut spans = self.spans;
        spans.retain(|s| s.start < len);
        for span in &mut spans {
            span.end = span.end.min(len);
        }
        // Every line is a block too, which covers plain text and HTML without block elements
        let mut blocks = self.blocks;
        let mut offset = 0;
        for line in text.split('\n') {
            if !line.is_empty() {
                blocks.push(Span {
                    start: offset,
                    end: offset + line.len(),
                });
            }
            offset += line.len() + 1;
        }
        blocks.sort_by(|a, b| a.start.cmp(&b.start).then(b.end.cmp(&a.end)));
        let units = Units::new(&text);
        let quote_start = attribution_start(&text, &units);
        Doc {
            source: self.source,
            text,
            spans,
            blocks,
            quote_start,
            units,
        }
    }
}

/// The plain text body as a document; lines starting with `>` are quoted
pub fn render_text(input: &str) -> Doc {
    let plain = Rc::new(DEFAULT_STYLE);
    let quoted = Rc::new(Style {
        quote: true,
        ..DEFAULT_STYLE
    });
    let mut doc = DocBuilder::new(Source::Text);
    let normalized = input.replace("\r\n", "\n").replace('\r', "\n");
    for line in normalized.split('\n') {
        let is_quoted = line.trim_start_matches(is_space).starts_with('>');
        doc.text(line, if is_quoted { &quoted } else { &plain });
        doc.newline();
    }
    doc.finish()
}

/// The style at a byte offset; whitespace between spans takes the style of the span before it
pub fn style_at(doc: &Doc, offset: usize) -> &Style {
    let i = doc.spans.partition_point(|s| s.start <= offset);
    if i == 0 {
        &DEFAULT_STYLE
    } else {
        &doc.spans[i - 1].style
    }
}

/// The smallest block that contains the whole range, sizes compared in UTF-16 code units
pub fn block_around(doc: &Doc, start: usize, end: usize) -> Span {
    let size = |s: &Span| doc.units.at(s.end) - doc.units.at(s.start);
    let mut best = Span {
        start: 0,
        end: doc.text.len(),
    };
    let mut best_size = size(&best);
    for block in &doc.blocks {
        if block.start > start {
            break;
        }
        if block.end >= end {
            let block_size = size(block);
            if block_size < best_size {
                best = *block;
                best_size = block_size;
            }
        }
    }
    best
}
