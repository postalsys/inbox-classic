//! Stage 2: plain text canonicalisation.
//!
//! Offsets in the rest of the pipeline are byte offsets into the canonical string produced here.
//! Hard wrapped lines are not unwrapped: unwrapping changes offsets and can merge a quoted line
//! with a new one, which is exactly the mistake that loses content.

use unicode_normalization::UnicodeNormalization;

use crate::util::{is_blank, js_len};

/// A single canonical line with its quote depth stripped out. Offsets are bytes into the text.
#[derive(Debug, Clone)]
pub(crate) struct TextLine {
    pub index: usize,
    /// Start of the line.
    pub start: usize,
    /// Just past the line content, excluding the newline.
    pub end: usize,
    /// Start of the line in UTF-16 code units, for the position feature.
    pub start16: usize,
    /// Start of the content after the quote prefix.
    pub content_start: usize,
    pub depth: usize,
    pub blank: bool,
}

impl TextLine {
    pub fn raw<'t>(&self, text: &'t str) -> &'t str {
        &text[self.start..self.end]
    }

    pub fn content<'t>(&self, text: &'t str) -> &'t str {
        &text[self.content_start..self.end]
    }
}

pub(crate) struct CanonicalText {
    pub text: String,
    pub lines: Vec<TextLine>,
    /// Length of the text in UTF-16 code units.
    pub len16: usize,
}

/// Length in bytes of the quote prefix of a line and its depth: up to three spaces or tabs, then
/// one or more `>` each followed by at most one space or tab. `|` and `:` are not quote markers.
pub(crate) fn split_quote_prefix(line: &str) -> (usize, usize) {
    let bytes = line.as_bytes();
    let mut i = 0;
    while i < bytes.len() && matches!(bytes[i], b' ' | b'\t') {
        i += 1;
    }
    if i > 3 || bytes.get(i) != Some(&b'>') {
        return (0, 0);
    }
    let mut depth = 0;
    while bytes.get(i) == Some(&b'>') {
        depth += 1;
        i += 1;
        if matches!(bytes.get(i), Some(b' ' | b'\t')) {
            i += 1;
        }
    }
    (i, depth)
}

/// The canonical string for a decoded plain text body.
///
/// A leading BOM is dropped, CRLF and lone CR both become LF, NUL characters are removed, and the
/// result is NFC normalised. Nothing else is altered. Every offset reported for a plain text
/// segment indexes the string this returns.
pub fn canonicalise_plain_text(input: &str) -> String {
    let input = input.strip_prefix('\u{FEFF}').unwrap_or(input);
    let mut text = String::with_capacity(input.len());
    let mut chars = input.chars().peekable();
    while let Some(c) = chars.next() {
        match c {
            '\r' => {
                if chars.peek() == Some(&'\n') {
                    chars.next();
                }
                text.push('\n');
            }
            '\0' => {}
            c => text.push(c),
        }
    }
    if text.is_ascii() {
        return text;
    }
    text.nfc().collect()
}

/// Normalise decoded part text and split it into lines.
pub(crate) fn canonicalise_text(input: &str) -> CanonicalText {
    let text = canonicalise_plain_text(input);
    let mut lines = Vec::new();
    let mut offset = 0;
    let mut offset16 = 0;
    loop {
        let newline = text[offset..].find('\n').map_or(text.len(), |at| offset + at);
        let raw = &text[offset..newline];
        let (prefix, depth) = split_quote_prefix(raw);
        lines.push(TextLine {
            index: lines.len(),
            start: offset,
            end: newline,
            start16: offset16,
            content_start: offset + prefix,
            depth,
            blank: is_blank(&raw[prefix..]),
        });
        if newline == text.len() {
            break;
        }
        offset16 += js_len(raw) + 1;
        offset = newline + 1;
    }
    reattach_wrap_continuations(&text, &mut lines);
    let len16 = js_len(&text);
    CanonicalText { text, lines, len16 }
}

/// Re-attach quoted lines whose wrapped continuation lost its quote prefix.
///
/// A short unquoted line squeezed between two quoted lines of the same depth, with no blank line
/// around it, after a quoted line that ended mid sentence, is the tail of the quote. Only the
/// depth changes, so blocks still tile the text.
fn reattach_wrap_continuations(text: &str, lines: &mut [TextLine]) {
    const MAX_CONTINUATION_CHARS: usize = 60;
    for i in 1..lines.len().saturating_sub(1) {
        let line = &lines[i];
        if line.depth != 0 || line.blank || js_len(line.raw(text)) > MAX_CONTINUATION_CHARS {
            continue;
        }
        let previous = &lines[i - 1];
        let next = &lines[i + 1];
        if previous.depth == 0 || previous.blank || next.depth != previous.depth || next.blank {
            continue;
        }
        let ended = previous
            .content(text)
            .trim_end_matches(crate::jsre::is_js_ws)
            .ends_with(['.', '!', '?', ':', ';', ')', ']', '"', '\'']);
        if ended {
            continue;
        }
        lines[i].depth = previous.depth;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn measures_quote_depth() {
        assert_eq!(split_quote_prefix("> a"), (2, 1));
        assert_eq!(split_quote_prefix(">> a"), (3, 2));
        assert_eq!(split_quote_prefix("> > a"), (4, 2));
        assert_eq!(split_quote_prefix("   > a"), (5, 1));
        assert_eq!(split_quote_prefix("    > a"), (0, 0));
        assert_eq!(split_quote_prefix("| a"), (0, 0));
        assert_eq!(split_quote_prefix(": a"), (0, 0));
    }

    #[test]
    fn canonicalises() {
        assert_eq!(canonicalise_plain_text("\u{FEFF}a\r\nb\rc\0d"), "a\nb\ncd");
        assert_eq!(canonicalise_plain_text("e\u{301}"), "\u{e9}");
        let canonical = canonicalise_text("a\n> b\nc");
        let raws: Vec<&str> = canonical.lines.iter().map(|line| line.raw(&canonical.text)).collect();
        assert_eq!(raws.join("\n"), canonical.text);
    }

    #[test]
    fn reattaches_wrapped_quote_tails() {
        let canonical = canonicalise_text("> First of all, sorry for the delay in giving\nabout the\n> course. After");
        assert_eq!(canonical.lines[1].depth, 1);
        let canonical = canonicalise_text("> A question?\nAnswer\n> More");
        assert_eq!(canonical.lines[1].depth, 0);
    }
}
