//! Markdown an AI agent writes, made into the HTML of a message: CommonMark with tables and strikethrough, never the
//! HTML an agent puts in it (shown as the text it is) nor pictures (their words stand in for them: a picture from the
//! web in a message tells its sender when it is read). The result is sanitized here, and once more as every message
//! that goes ([`crate::outgoing_html`]).

use pulldown_cmark::{Event, Options, Parser, Tag, TagEnd, html};

/// `markdown` as sanitized HTML for a message's body
pub fn markdown_html(markdown: &str) -> String {
    let options = Options::ENABLE_TABLES | Options::ENABLE_STRIKETHROUGH;
    let mut in_image = 0usize;
    let events = Parser::new_ext(markdown, options).filter_map(|event| match event {
        // a picture's words, without the picture
        Event::Start(Tag::Image { .. }) => {
            in_image += 1;
            None
        }
        Event::End(TagEnd::Image) => {
            in_image = in_image.saturating_sub(1);
            None
        }
        // HTML written into the Markdown is text, as written
        Event::Html(text) | Event::InlineHtml(text) => Some(Event::Text(text)),
        other => Some(other),
    });
    let mut out = String::new();
    html::push_html(&mut out, events);
    crate::sanitize(&out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn markdown_becomes_mail_html() {
        let html = markdown_html("# Plan\n\nHello **Ann**, see [the list](https://example.com/a).\n\n- one\n- two\n");
        assert!(html.contains("<h1>Plan</h1>"), "{html}");
        assert!(html.contains("<strong>Ann</strong>"), "{html}");
        assert!(html.contains("<li>one</li>"), "{html}");
        assert!(html.contains("href=\"https://example.com/a\""), "{html}");
        let table = markdown_html("| a | b |\n|---|---|\n| 1 | 2 |\n");
        assert!(table.contains("<table>") && table.contains("<td>2</td>"), "{table}");
    }

    #[test]
    fn html_in_it_is_only_text() {
        let html = markdown_html("Hi <script>alert(1)</script> <b onclick=\"x()\">there</b>\n\n<div>block</div>\n");
        assert!(
            !html.contains("<script") && !html.contains("<b") && !html.contains("<div"),
            "{html}"
        );
        assert!(html.contains("&lt;script&gt;"), "{html}");
        let link = markdown_html("[click](javascript:alert(1))");
        assert!(!link.contains("javascript:"), "{link}");
    }

    #[test]
    fn pictures_leave_their_words() {
        let html = markdown_html("Look: ![a chart of sales](https://tracker.example/p.png)");
        assert!(!html.contains("<img") && !html.contains("tracker.example"), "{html}");
        assert!(html.contains("a chart of sales"), "{html}");
    }
}
