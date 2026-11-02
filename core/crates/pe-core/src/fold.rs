//! The earlier messages a reply or forward carries, folded behind a "..." button in the reading pane. Which part of a
//! body is history comes from pe-content (a port of email-content): only what it hides, and the reply history and
//! forwarded content it would collapse, is folded; inline quotes, signatures and anything uncertain stay in view.
//! Folding is a `<details>` element, which opens without a script; the document is sanitized after it is added.

use pe_content::{AnalyzeOptions, Label, MessageContent, Representation, Segment, Visibility};
use pe_mime::parser::{Message, text_addresses, text_to_html};

/// The summary of a fold: the button. Styled by the document of `pe_html::render_message`.
const SUMMARY: &str = "<summary title=\"Show the earlier messages\">&#8226;&#8226;&#8226;</summary>";

/// Compiles pe-content's patterns ahead of the first message shown, which would otherwise wait for them
pub(crate) fn warm_up() {
    let content = MessageContent {
        text: Some("Hi\n\nOn Mon, Oct 6, 2025 at 10:00 AM Ann <ann@example.com> wrote:\n> x\n"),
        ..Default::default()
    };
    let _ = std::panic::catch_unwind(|| pe_content::analyze(&content, &AnalyzeOptions::default()));
}

/// The body of `message` for the preview, as HTML (not yet sanitized), its history folded
pub(crate) fn body(message: &Message) -> String {
    let (representation, shown) = match (&message.html, &message.text) {
        (Some(html), _) => (Representation::Html, html),
        (None, Some(text)) => (Representation::Text, text),
        (None, None) => return String::new(),
    };
    let key = key_of(representation, shown);
    if let Some(body) = LAST.with_borrow(|last| last.as_ref().filter(|(k, _)| *k == key).map(|(_, b)| b.clone())) {
        return body;
    }
    let body = folded(message, representation).unwrap_or_else(|| match representation {
        Representation::Html => shown.clone(),
        Representation::Text => text_to_html(shown),
    });
    LAST.with_borrow_mut(|last| *last = Some((key, body.clone())));
    body
}

thread_local! {
    /// The last body folded on this thread: the same message shown again (its pictures allowed, say) is not
    /// analyzed again
    static LAST: std::cell::RefCell<Option<(u64, String)>> = const { std::cell::RefCell::new(None) };
}

/// A hash of the body shown, keyed at random for each run so no message can be made to match another
fn key_of(representation: Representation, shown: &str) -> u64 {
    use std::hash::{BuildHasher, Hash, Hasher};
    static KEYS: std::sync::OnceLock<std::collections::hash_map::RandomState> = std::sync::OnceLock::new();
    let mut hasher = KEYS.get_or_init(Default::default).build_hasher();
    (representation == Representation::Html).hash(&mut hasher);
    shown.hash(&mut hasher);
    hasher.finish()
}

fn folded_segment(segment: &Segment) -> bool {
    segment.visibility == Visibility::Hide
        || (segment.visibility == Visibility::Collapse
            && matches!(segment.label, Label::ReplyHistory | Label::ForwardedContent))
}

/// The body with its history folded, None when there is nothing to fold or the analysis did not work out
fn folded(message: &Message, representation: Representation) -> Option<String> {
    let from = text_addresses(message.from.as_slice());
    let references = message.reference_ids();
    // only the part that is shown: analyzing both lets the analysis prefer the other one, and then nothing that is
    // shown would fold
    let shown_html = representation == Representation::Html;
    let content = MessageContent {
        text: message.text.as_deref().filter(|_| !shown_html),
        html: message.html.as_deref().filter(|_| shown_html),
        subject: message.subject.as_deref(),
        from: Some(from.as_str()).filter(|f| !f.is_empty()),
        in_reply_to: message.in_reply_to.as_deref(),
        references: references.iter().map(String::as_str).collect(),
        ..Default::default()
    };
    // hostile mail must not take the preview down: an analysis that fails shows the message unfolded
    let result = std::panic::catch_unwind(|| pe_content::analyze(&content, &AnalyzeOptions::default()))
        .ok()?
        .ok()?;
    let mut segments: Vec<&Segment> = result
        .segments
        .iter()
        .chain(&result.hidden_segments)
        .filter(|s| s.source.representation == representation)
        .collect();
    segments.sort_by_key(|s| s.source.start);
    let source = match representation {
        Representation::Html => message.html.as_deref()?,
        Representation::Text => result.canonical_text.get(&segments.first()?.source.mime_part)?.as_str(),
    };
    let ranges = merge(
        segments
            .iter()
            .filter(|s| folded_segment(s))
            .map(|s| (s.source.start, s.source.end)),
        source,
    );
    if ranges.is_empty() {
        return None;
    }
    // what the sender wrote stays in view: a fold of everything would hide the message itself
    let mut kept = 0;
    let mut at = 0;
    for &(start, end) in &ranges {
        kept += source[at..start].trim().len();
        at = end;
    }
    if kept + source[at..].trim().len() == 0 {
        return None;
    }
    let piece = |text: &str| match representation {
        Representation::Html => text.to_string(),
        Representation::Text => text_to_html(text),
    };
    let mut out = String::with_capacity(source.len() + ranges.len() * 120);
    let mut at = 0;
    for (start, end) in ranges {
        out.push_str(&piece(&source[at..start]));
        out.push_str("<details class=\"pe-fold\">");
        out.push_str(SUMMARY);
        out.push_str(&piece(&source[start..end]));
        out.push_str("</details>");
        at = end;
    }
    out.push_str(&piece(&source[at..]));
    Some(out)
}

/// The ranges in order, the ones only whitespace apart joined, each within `source` and on character boundaries
fn merge(ranges: impl Iterator<Item = (usize, usize)>, source: &str) -> Vec<(usize, usize)> {
    let mut ranges: Vec<(usize, usize)> = ranges
        .filter(|&(start, end)| {
            start < end && end <= source.len() && source.is_char_boundary(start) && source.is_char_boundary(end)
        })
        .collect();
    ranges.sort_unstable();
    let mut merged: Vec<(usize, usize)> = Vec::new();
    for (start, end) in ranges {
        match merged.last_mut() {
            Some(last) if start <= last.1 || source[last.1..start].trim().is_empty() => last.1 = last.1.max(end),
            _ => merged.push((start, end)),
        }
    }
    merged
}

#[cfg(test)]
mod tests {
    use super::*;
    use pe_mime::parser::parse;

    fn body_of(raw: &str) -> String {
        body(&parse(raw.as_bytes()).unwrap())
    }

    #[test]
    fn folds_the_quote_of_a_gmail_reply() {
        let raw = "From: Bob <bob@example.com>\r\nTo: ann@example.com\r\nSubject: Re: Plans\r\nIn-Reply-To: <m1@example.com>\r\nContent-Type: text/html\r\n\r\n\
                   <div dir=\"ltr\">Six works for me.</div><br><div class=\"gmail_quote\"><div dir=\"ltr\" class=\"gmail_attr\">On Mon, Oct 6, 2025 at 10:00 AM Ann &lt;ann@example.com&gt; wrote:<br></div>\
                   <blockquote class=\"gmail_quote\" style=\"margin:0px 0px 0px 0.8ex\">Shall we meet at six?</blockquote></div>\r\n";
        let html = body_of(raw);
        let fold = html.find("<details").expect(&html);
        assert!(html[..fold].contains("Six works for me."), "{html}");
        assert!(html[fold..].contains("Shall we meet at six?"), "{html}");
        assert!(html.contains(SUMMARY));
    }

    #[test]
    fn folds_the_quote_of_a_plain_text_reply() {
        let raw = "From: Bob <bob@example.com>\r\nTo: ann@example.com\r\nSubject: Re: Plans\r\nIn-Reply-To: <m1@example.com>\r\n\r\n\
                   Six works for me.\r\n\r\nOn Mon, Oct 6, 2025 at 10:00 AM Ann <ann@example.com> wrote:\r\n> Shall we meet at six?\r\n> Ann\r\n";
        let html = body_of(raw);
        let fold = html.find("<details").expect(&html);
        assert!(html[..fold].contains("Six works for me."), "{html}");
        assert!(html[fold..].contains("Shall we meet at six"), "{html}");
        // the text is escaped as it was before folding
        assert!(html[fold..].contains("&#x3C;ann@example.com&#x3E;"), "{html}");
    }

    #[test]
    fn leaves_a_message_without_history_alone() {
        let raw =
            "From: Bob <bob@example.com>\r\nSubject: Hello\r\nContent-Type: text/html\r\n\r\n<p>Just a note.</p>\r\n";
        assert_eq!(body_of(raw).trim(), "<p>Just a note.</p>");
        let plain = "From: Bob <bob@example.com>\r\nSubject: Hello\r\n\r\n> quoted alone is not history\r\nText.\r\n";
        assert!(!body_of(plain).contains("<details"));
    }

    #[test]
    fn the_same_body_again_comes_from_the_cache() {
        let raw = "From: Bob <bob@example.com>\r\nSubject: Re: x\r\nIn-Reply-To: <m1@example.com>\r\n\r\n\
                   Yes.\r\n\r\nOn Mon, Oct 6, 2025 at 10:00 AM Ann <ann@example.com> wrote:\r\n> Hm?\r\n";
        let first = body_of(raw);
        assert!(first.contains("<details"), "{first}");
        assert_eq!(body_of(raw), first);
        // another body is not taken for it
        let other = body_of(&raw.replace("Yes.", "No."));
        assert!(other.contains("No.") && !other.contains("Yes."), "{other}");
        assert_ne!(key_of(Representation::Html, "a"), key_of(Representation::Text, "a"));
    }

    #[test]
    fn merges_ranges() {
        let source = "aaaa  bbbb cccc";
        assert_eq!(merge([(6, 10), (0, 4)].into_iter(), source), [(0, 10)]);
        assert_eq!(merge([(0, 4), (11, 15)].into_iter(), source), [(0, 4), (11, 15)]);
        // out of range or inside a character: left out
        assert_eq!(merge([(0, 99), (2, 2)].into_iter(), source), []);
        assert_eq!(merge([(0, 1)].into_iter(), "é"), []);
    }
}
