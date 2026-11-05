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
    let key = key_of(message, representation, shown);
    let last = || LAST.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
    if let Some(body) = last().as_ref().filter(|(k, _)| *k == key).map(|(_, b)| b.clone()) {
        return body;
    }
    let body = folded(message, representation).unwrap_or_else(|| match representation {
        Representation::Html => shown.clone(),
        Representation::Text => text_to_html(shown),
    });
    *last() = Some((key, body.clone()));
    body
}

/// The last body folded: the same message shown again (its pictures allowed, say) is not analyzed again
static LAST: std::sync::Mutex<Option<(u64, String)>> = std::sync::Mutex::new(None);

/// A hash of everything the fold depends on: the body shown and the headers the analysis reads, keyed at random
/// for each run so no message can be made to match another
fn key_of(message: &Message, representation: Representation, shown: &str) -> u64 {
    use std::hash::{BuildHasher, Hash, Hasher};
    static KEYS: std::sync::OnceLock<std::collections::hash_map::RandomState> = std::sync::OnceLock::new();
    let mut hasher = KEYS.get_or_init(Default::default).build_hasher();
    (representation == Representation::Html).hash(&mut hasher);
    shown.hash(&mut hasher);
    message.subject.hash(&mut hasher);
    text_addresses(message.from.as_slice()).hash(&mut hasher);
    message.in_reply_to.hash(&mut hasher);
    message.reference_ids().hash(&mut hasher);
    hasher.finish()
}

/// pe-content's reading of `text` or `html` of `message`, with the headers it takes as evidence; None when the
/// analysis did not work out. Hostile mail must not take the app down: a panic in it is caught.
pub(crate) fn analysis(message: &Message, text: Option<&str>, html: Option<&str>) -> Option<pe_content::AnalyzeResult> {
    let from = text_addresses(message.from.as_slice());
    let references = message.reference_ids();
    let content = MessageContent {
        text,
        html,
        subject: message.subject.as_deref(),
        from: Some(from.as_str()).filter(|f| !f.is_empty()),
        in_reply_to: message.in_reply_to.as_deref(),
        references: references.iter().map(String::as_str).collect(),
        ..Default::default()
    };
    std::panic::catch_unwind(|| pe_content::analyze(&content, &AnalyzeOptions::default()))
        .ok()?
        .ok()
}

/// Every segment of an analysis, the hidden ones too, in the order of the body
pub(crate) fn segments(result: &pe_content::AnalyzeResult) -> Vec<&Segment> {
    let mut segments: Vec<&Segment> = result.segments.iter().chain(&result.hidden_segments).collect();
    segments.sort_by_key(|s| s.source.start);
    segments
}

fn folded_segment(segment: &Segment) -> bool {
    segment.visibility == Visibility::Hide
        || (segment.visibility == Visibility::Collapse
            && matches!(segment.label, Label::ReplyHistory | Label::ForwardedContent))
}

/// The body with its history folded, None when there is nothing to fold or the analysis did not work out
fn folded(message: &Message, representation: Representation) -> Option<String> {
    // only the part that is shown: analyzing both lets the analysis prefer the other one, and then nothing that is
    // shown would fold
    let shown_html = representation == Representation::Html;
    let result = analysis(
        message,
        message.text.as_deref().filter(|_| !shown_html),
        message.html.as_deref().filter(|_| shown_html),
    )?;
    let segments: Vec<&Segment> = segments(&result)
        .into_iter()
        .filter(|s| s.source.representation == representation)
        .collect();
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
    // a range of the HTML can start or end inside an element: only whole elements fold
    let ranges: Vec<(usize, usize)> = match representation {
        Representation::Html => ranges
            .into_iter()
            .filter_map(|(start, end)| {
                whole_elements(source, start, end).or_else(|| {
                    // the range ends inside its elements: to where they close, when nothing on the way is shown
                    let to = closing_point(source, start, end)?;
                    let all_folded = segments
                        .iter()
                        .filter(|s| s.source.start < to && s.source.end > end)
                        .all(|s| s.visibility != Visibility::Show);
                    all_folded.then(|| whole_elements(source, start, to)).flatten()
                })
            })
            .collect(),
        Representation::Text => ranges,
    };
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

/// A tag of the HTML
struct Tag {
    /// Where its `<` is
    start: usize,
    /// Just after its `>`
    end: usize,
    /// In lowercase
    name: String,
    closing: bool,
}

/// The tags of `html[start..end]` that open or close an element: not void elements, not comments
fn tags(html: &str, start: usize, end: usize) -> Vec<Tag> {
    const VOID: [&str; 14] = [
        "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr",
    ];
    let mut tags = Vec::new();
    let mut at = start;
    while let Some(offset) = html[at..end].find('<') {
        let open = at + offset;
        let rest = &html[open..end];
        if rest.starts_with("<!--") {
            at = open + rest.find("-->").map_or(rest.len(), |close| close + 3);
            continue;
        }
        let Some(length) = rest.find('>') else { break };
        let inner = &rest[1..length];
        let closing = inner.starts_with('/');
        let name: String = inner
            .trim_start_matches('/')
            .chars()
            .take_while(|c| c.is_ascii_alphanumeric())
            .collect::<String>()
            .to_ascii_lowercase();
        if !name.is_empty() && !inner.ends_with('/') && !VOID.contains(&name.as_str()) {
            tags.push(Tag {
                start: open,
                end: open + length + 1,
                name,
                closing,
            });
        }
        at = open + length + 1;
    }
    tags
}

/// Where the elements that are open at `end`, of those opened from `start` on, have all closed again; None when an
/// end tag closes one from before `start` first
fn closing_point(html: &str, start: usize, end: usize) -> Option<usize> {
    let mut open: Vec<String> = Vec::new();
    for tag in tags(html, start, html.len()) {
        if tag.start >= end && open.is_empty() {
            return Some(tag.start);
        }
        if !tag.closing {
            open.push(tag.name);
        } else if open.last() == Some(&tag.name) {
            open.pop();
        } else if !open.is_empty() {
            return None;
        }
        if tag.end > end && open.is_empty() {
            return Some(tag.end);
        }
    }
    None
}

/// The elements that start and end in `html[start..end]`: the end tags of elements that began before the range are
/// left out at its start and at its end, so a `<details>` around it nests. None when it does not nest even then (an
/// element of the range left open, an end tag in its middle that closes one from before).
fn whole_elements(html: &str, start: usize, end: usize) -> Option<(usize, usize)> {
    let tags = tags(html, start, end);
    // end tags (and the space between them) at the start belong to the elements before
    let mut first = start;
    let mut skip = 0;
    for tag in &tags {
        if !tag.closing || !html[first..tag.start].trim().is_empty() {
            break;
        }
        first = tag.end;
        skip += 1;
    }
    let mut open: Vec<&str> = Vec::new();
    let mut last = end;
    for (index, tag) in tags.iter().enumerate().skip(skip) {
        if !tag.closing {
            open.push(&tag.name);
        } else if open.last() == Some(&tag.name.as_str()) {
            open.pop();
        } else if open.is_empty() {
            // closes an element from before the range: allowed only when nothing but such end tags follow
            let rest = &tags[index..];
            let only_closes = rest.iter().all(|t| t.closing)
                && rest
                    .windows(2)
                    .all(|pair| html[pair[0].end..pair[1].start].trim().is_empty())
                && html[rest[rest.len() - 1].end..end].trim().is_empty();
            if !only_closes {
                return None;
            }
            last = tag.start;
            break;
        } else {
            return None;
        }
    }
    (open.is_empty() && !html[first..last].trim().is_empty()).then_some((first, last))
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
        // the same body under another subject or from another sender is analyzed for its own
        let message = parse(raw.as_bytes()).unwrap();
        let mut other = message.clone();
        other.subject = Some("Another".into());
        assert_ne!(
            key_of(&message, Representation::Text, "a"),
            key_of(&other, Representation::Text, "a")
        );
        assert_ne!(
            key_of(&message, Representation::Html, "a"),
            key_of(&message, Representation::Text, "a")
        );
    }

    #[test]
    fn folds_whole_elements_of_our_own_replies() {
        // what the editor sends: the quote's range starts at the end tag of the paragraph before it
        let raw = "From: UI Test <t@x.test>\r\nSubject: Re: Hello\r\nIn-Reply-To: <a@x>\r\nContent-Type: text/html\r\n\r\n\
                   <div><b>Thanks.</b></div><div><br></div><blockquote type=\"cite\"><div>----- Original Message -----</div>\
                   <div><b>From:</b> Ann &lt;ann@example.com&gt;</div><div><br></div><div>Hi, this was the question.</div>\
                   </blockquote>\r\n";
        let html = body_of(raw);
        let fold = html.find("<details").expect(&html);
        assert!(html[..fold].contains("Thanks."), "{html}");
        // the quote is inside the fold, whole
        let inside = &html[fold..html.rfind("</details>").expect(&html)];
        assert!(
            inside.contains("<blockquote") && inside.contains("</blockquote>") && inside.contains("the question"),
            "{html}"
        );
    }

    #[test]
    fn whole_elements_only() {
        let html = "<div><p>new</p><br></div><blockquote><p>old</p></blockquote></div>";
        let quote = html.find("<blockquote").unwrap();
        // from inside the div before to the end of an outer div: only the blockquote
        let start = html.find("<br>").unwrap() + 4;
        let (from, to) = whole_elements(html, start, html.len()).unwrap();
        assert_eq!(&html[from..to], "<blockquote><p>old</p></blockquote>");
        assert_eq!(from, quote);
        // an element left open, or one closed in the middle that began before: not folded
        assert_eq!(whole_elements(html, quote, quote + 15), None);
        let middle = "<div>a</div></td><p>b</p>";
        assert_eq!(whole_elements(middle, 0, middle.len()), None);
        // comments and void elements do not count
        let other = "<!-- <div> --><p>a<br><img src=x></p>";
        assert_eq!(whole_elements(other, 0, other.len()), Some((0, other.len())));
        // nothing but end tags: nothing to fold
        assert_eq!(whole_elements("</div></div>", 0, 12), None);
    }

    #[test]
    fn ranges_that_end_inside_their_elements() {
        let html = "<p>new</p><div class=q><p>old</p><p>footer</p></div><p>after</p>";
        let start = html.find("<div").unwrap();
        let inside = html.find("<p>footer").unwrap();
        // the div closes after the footer: the range can go there, not further
        let to = closing_point(html, start, inside).unwrap();
        assert_eq!(&html[start..to], "<div class=q><p>old</p><p>footer</p></div>");
        assert_eq!(whole_elements(html, start, to), Some((start, to)));
        // an element of the range left open to the end of the document
        assert_eq!(closing_point("<div><p>a", 0, 6), None);
    }

    /// Every HTML body of pe-content's conformance fixtures (email-content's test inputs and fixtures): no panic,
    /// and every fold added is still a whole fold after the sanitizer
    #[test]
    fn folds_nest_on_every_fixture() {
        let cases: serde_json::Value =
            serde_json::from_str(include_str!("../../pe-content/tests/fixtures/cases.json")).unwrap();
        let mut folded = 0;
        for case in cases.as_array().unwrap() {
            let content = &case["content"];
            let Some(html) = content["html"].as_str() else { continue };
            let subject = content["subject"]
                .as_str()
                .unwrap_or_default()
                .replace(['\r', '\n'], " ");
            let raw = format!(
                "From: someone@example.com\r\nSubject: {subject}\r\nIn-Reply-To: <x@example.com>\r\n\
                 Content-Type: text/html; charset=utf-8\r\n\r\n{html}"
            );
            let document = crate::view::build(raw.as_bytes(), false).document;
            let opened = document.matches("<details class=\"pe-fold\">").count();
            if opened > 0 {
                folded += 1;
                assert_eq!(opened, document.matches("</details>").count(), "{}", case["name"]);
                let with_summary = document.matches("<details class=\"pe-fold\"><summary").count();
                assert_eq!(opened, with_summary, "{}", case["name"]);
            }
        }
        // the HTML bodies email-content folds (hidden, or collapsed history and forwards): all of them
        assert_eq!(folded, 8);
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
