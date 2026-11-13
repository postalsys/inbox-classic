//! The first words of a message for the message list's rows of several lines: what the sender wrote, without the
//! reply history and forwarded content their mail program attached (pe-content tells them apart, as it does for the
//! reading pane's folds), white space folded and the invisible padding of marketing mail taken out, cut at a word.
//! Worked out where the core has the text anyway (search.rs), so it costs no download of its own.

use pe_content::{AnalyzeOptions, Label, MessageContent};

/// The most characters a snippet keeps: more than the widest list shows
const LONGEST: usize = 200;

/// How much of the text is read for one: what the sender wrote comes first
const READ: usize = 8 * 1024;

/// The snippet of a message whose text (plain, or HTML as text) is `text`; empty when it has none
pub(crate) fn of(text: &str) -> String {
    let head = head(text, READ);
    let written = std::panic::catch_unwind(|| written(head))
        .ok()
        .flatten()
        .unwrap_or_default();
    let mut shown = clean(&written);
    // nothing of the sender's own (a forward without a word, or what the analysis could not read): the text as it is,
    // without its quoted lines
    if shown.is_empty() {
        let unquoted: Vec<&str> = head
            .lines()
            .filter(|line| !line.trim_start().starts_with('>'))
            .collect();
        shown = clean(&unquoted.join("\n"));
    }
    if shown.is_empty() {
        shown = clean(head);
    }
    shorten(shown)
}

/// The start of `text`, at most `bytes` long, cut at a character
fn head(text: &str, bytes: usize) -> &str {
    if text.len() <= bytes {
        return text;
    }
    let mut end = bytes;
    while !text.is_char_boundary(end) {
        end -= 1;
    }
    &text[..end]
}

/// What pe-content takes for the sender's own words in `text`, in order; None when the analysis did not work out
fn written(text: &str) -> Option<String> {
    let content = MessageContent {
        text: Some(text),
        ..Default::default()
    };
    let options = AnalyzeOptions {
        max_content_chars: Some(READ),
        ..Default::default()
    };
    let result = pe_content::analyze(&content, &options).ok()?;
    let own: Vec<&str> = result
        .segments
        .iter()
        .filter(|segment| matches!(segment.label, Label::NewContent | Label::Unknown))
        .map(|segment| segment.text.as_str())
        .collect();
    Some(own.join("\n"))
}

/// Characters that take no room but pad a line, as marketing mail fills its preview with them so the list shows
/// nothing of the rest
fn invisible(c: char) -> bool {
    matches!(
        c,
        '\u{00AD}' | '\u{034F}' | '\u{061C}' | '\u{115F}' | '\u{1160}' | '\u{17B4}' | '\u{17B5}' | '\u{180E}'
            | '\u{200B}'..='\u{200F}' | '\u{202A}'..='\u{202E}' | '\u{2060}'..='\u{206F}' | '\u{3164}' | '\u{FEFF}'
            | '\u{FFA0}'
    )
}

/// White space folded to single spaces, the invisible characters and control characters out
fn clean(text: &str) -> String {
    let mut out = String::with_capacity(text.len().min(LONGEST * 4));
    let mut space = false;
    for c in text.chars() {
        if invisible(c) {
            continue;
        }
        if c.is_whitespace() || c.is_control() {
            space = !out.is_empty();
            continue;
        }
        if space {
            out.push(' ');
            space = false;
        }
        out.push(c);
        // far more than will be kept: the rest is not needed
        if out.len() > LONGEST * 8 {
            break;
        }
    }
    out
}

/// At most [`LONGEST`] characters, cut after a word where one ends near the end
fn shorten(text: String) -> String {
    let Some((cut, _)) = text.char_indices().nth(LONGEST) else {
        return text;
    };
    let kept = &text[..cut];
    // a word cut in half is left out, unless the text is one long word
    let end = match kept.rfind(' ') {
        Some(space) if kept[..space].chars().count() > LONGEST * 3 / 4 => space,
        _ => cut,
    };
    kept[..end].trim_end().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn leaves_out_the_reply_history() {
        let text = "Works for me, see you there.\n\nOn Mon, Oct 6, 2025 at 10:00 AM Ann <ann@example.com> wrote:\n\
                    > Lunch on Thursday?\n> Ann\n";
        assert_eq!(of(text), "Works for me, see you there.");
    }

    #[test]
    fn folds_white_space_and_drops_padding() {
        let text = "Big\u{200C} \u{034F}\u{00A0}\u{00A0}sale\u{FEFF}\r\n\r\n\ttoday   only";
        assert_eq!(of(text), "Big sale today only");
    }

    #[test]
    fn cuts_at_a_word() {
        let text = "word ".repeat(100);
        let snippet = of(&text);
        assert!(snippet.chars().count() <= LONGEST, "{}", snippet.len());
        assert!(snippet.ends_with("word"), "{snippet}");
        let long = "x".repeat(500);
        assert_eq!(of(&long).chars().count(), LONGEST);
    }

    #[test]
    fn counts_characters_not_bytes() {
        let text = "Õie ".repeat(100);
        let snippet = of(&text);
        assert!(snippet.chars().count() <= LONGEST);
        assert!(snippet.starts_with("Õie Õie"));
    }

    #[test]
    fn a_message_without_text_has_none() {
        assert_eq!(of(""), "");
        assert_eq!(of("  \r\n\u{200B}\n"), "");
    }

    #[test]
    fn a_forward_without_words_shows_what_was_forwarded() {
        let text = "---------- Forwarded message ---------\nFrom: Ann <ann@example.com>\nDate: Mon, Oct 6, 2025\n\
                    Subject: Plans\nTo: Bo <bo@example.com>\n\nThe ferry leaves at nine.\n";
        assert!(of(text).contains("ferry leaves at nine"), "{}", of(text));
    }
}
