//! Plain text and HTML of a message turned into each other, and the header block shown for an
//! attached message. A port of postal-mime's text-format.ts.

use std::sync::LazyLock;

use regex::{Captures, Regex};

use super::address::ParsedAddress;
use super::entities::ENTITIES;
use crate::Address;
use crate::date::DateTime;

fn regex(pattern: &str) -> Regex {
    Regex::new(pattern).expect("valid pattern")
}

/// Windows-1252 characters that numeric references in the C1 range stand for
fn c1(code: u32) -> u32 {
    match code {
        0x80 => 0x20ac,
        0x82 => 0x201a,
        0x83 => 0x0192,
        0x84 => 0x201e,
        0x85 => 0x2026,
        0x86 => 0x2020,
        0x87 => 0x2021,
        0x88 => 0x02c6,
        0x89 => 0x2030,
        0x8a => 0x0160,
        0x8b => 0x2039,
        0x8c => 0x0152,
        0x8e => 0x017d,
        0x91 => 0x2018,
        0x92 => 0x2019,
        0x93 => 0x201c,
        0x94 => 0x201d,
        0x95 => 0x2022,
        0x96 => 0x2013,
        0x97 => 0x2014,
        0x98 => 0x02dc,
        0x99 => 0x2122,
        0x9a => 0x0161,
        0x9b => 0x203a,
        0x9c => 0x0153,
        0x9e => 0x017e,
        0x9f => 0x0178,
        other => other,
    }
}

/// `&amp;`, `&#228;`, `&#xE4;`, and the named references browsers know without the `;`
pub fn decode_html_entities(text: &str) -> String {
    static ENTITY: LazyLock<Regex> = LazyLock::new(|| regex(r"(?i)&(#\d+|#x[a-f0-9]+|[a-z]+\d*);?"));
    ENTITY
        .replace_all(text, |caps: &Captures| {
            let matched = &caps[0];
            if let Ok(index) = ENTITIES.binary_search_by(|(name, _)| name.cmp(&matched)) {
                return ENTITIES[index].1.to_string();
            }
            let entity = &caps[1];
            if !entity.starts_with('#') || !matched.ends_with(';') {
                return matched.to_string();
            }
            let code = match entity[1..].strip_prefix(['x', 'X']) {
                Some(hex) => u32::from_str_radix(hex, 16).ok(),
                None => entity[1..].parse().ok(),
            };
            match code {
                Some(code) if code != 0 && !(0xd800..=0xdfff).contains(&code) && code <= 0x10ffff => {
                    char::from_u32(c1(code)).map_or_else(|| "\u{fffd}".into(), String::from)
                }
                _ => "\u{fffd}".into(),
            }
        })
        .into_owned()
}

/// JavaScript's trim: white space and the byte order mark
fn js_trim(text: &str) -> &str {
    text.trim_matches(|c: char| c.is_whitespace() || c == '\u{feff}')
}

/// Text for HTML: `<`, `>`, `"`, `'`, `?` and `&` as references
pub fn escape_html(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    for c in js_trim(text).chars() {
        if matches!(c, '<' | '>' | '"' | '\'' | '?' | '&') {
            out.push_str(&format!("&#x{:02X};", c as u32));
        } else {
            out.push(c);
        }
    }
    out
}

/// Plain text as HTML
pub fn text_to_html(text: &str) -> String {
    format!("<div>{}</div>", escape_html(text).replace('\n', "<br />"))
}

/// An address for a mailto: link, anything outside the URL safe characters percent encoded
fn encode_mailto(address: &str) -> String {
    let mut out = String::new();
    for c in address.chars() {
        if c.is_ascii_alphanumeric() || "-._~!$'()*+,;:@".contains(c) {
            out.push(c);
        } else {
            for byte in c.encode_utf8(&mut [0; 4]).bytes() {
                out.push_str(&format!("%{byte:02X}"));
            }
        }
    }
    out
}

/// Replaces each block from `open` to `close`; `to_gt` extends the opener or the closer to the
/// next `>`. Stops at the first block that does not close.
fn replace_blocks(
    text: &str,
    open: &Regex,
    open_to_gt: bool,
    close: &Regex,
    close_to_gt: bool,
    replacement: &str,
) -> String {
    let mut out = String::new();
    let mut copied = 0;
    let mut search = 0;
    while let Some(opener) = open.find_at(text, search) {
        let start = opener.start();
        let mut from = opener.end();
        if open_to_gt {
            let Some(gt) = text[from..].find('>') else { break };
            from += gt + 1;
        }
        let Some(closer) = close.find_at(text, from) else { break };
        let mut end = closer.end();
        if close_to_gt {
            let Some(gt) = text[end..].find('>') else { break };
            end += gt + 1;
        }
        out.push_str(&text[copied..start]);
        out.push_str(replacement);
        copied = end;
        search = end;
    }
    out.push_str(&text[copied..]);
    out
}

/// Replaces each tag that starts with `prefix` and matches `pattern` right there
fn replace_tags(text: &str, prefix: &Regex, pattern: &Regex, replacement: impl Fn(&Captures) -> String) -> String {
    let mut out = String::new();
    let mut copied = 0;
    let mut search = 0;
    while let Some(candidate) = prefix.find_at(text, search) {
        let start = candidate.start();
        let Some(gt) = text[start..].find('>') else { break };
        match pattern.captures(&text[start..]) {
            Some(caps) => {
                out.push_str(&text[copied..start]);
                out.push_str(&replacement(&caps));
                copied = start + caps.get(0).map_or(0, |m| m.end());
                search = copied;
            }
            None => search = start + gt + 1,
        }
    }
    out.push_str(&text[copied..]);
    out
}

/// Everything up to and including the tag of the last `prefix` before the last `>`
fn strip_through_last_tag(text: &str, prefix: &Regex) -> String {
    let limit = text.rfind('>');
    let last = prefix
        .find_iter(text)
        .map(|m| m.start())
        .take_while(|&start| limit.is_some_and(|l| start < l))
        .last();
    match last {
        Some(start) => text[start..]
            .find('>')
            .map_or(String::new(), |gt| text[start + gt + 1..].to_string()),
        None => text.to_string(),
    }
}

/// Everything from the first `prefix` on, if a tag closes after it
fn strip_from_first_tag(text: &str, prefix: &Regex) -> String {
    match (prefix.find(text), text.rfind('>')) {
        (Some(found), Some(limit)) if found.start() < limit => text[..found.start()].to_string(),
        _ => text.to_string(),
    }
}

struct HtmlPatterns {
    line_breaks: Regex,
    comment_open: Regex,
    comment_close: Regex,
    br: Regex,
    blocks: Regex,
    script_open: Regex,
    script_close: Regex,
    style_open: Regex,
    style_close: Regex,
    body: Regex,
    head_close: Regex,
    doctype: Regex,
    body_close: Regex,
    html_close: Regex,
    link_prefix: Regex,
    link: Regex,
    inline: Regex,
    li_prefix: Regex,
    li: Regex,
    hr: Regex,
    tag: Regex,
    spaces: Regex,
    blank_lines: Regex,
    many_breaks: Regex,
    leading_breaks: Regex,
    trailing_breaks: Regex,
}

static HTML: LazyLock<HtmlPatterns> = LazyLock::new(|| {
    // JavaScript's \b is ASCII
    HtmlPatterns {
        line_breaks: regex("\r\n|[\n\r\u{2028}\u{2029}]"),
        comment_open: regex("<!--"),
        comment_close: regex("-->"),
        br: regex(r"(?i)<br(?-u:\b)[^>]*>"),
        blocks: regex(r"(?i)</?(p|div|table|tr|td|th)(?-u:\b)[^>]*>"),
        script_open: regex(r"(?i)<script(?-u:\b)"),
        script_close: regex(r"(?i)</script(?-u:\b)"),
        style_open: regex(r"(?i)<style(?-u:\b)"),
        style_close: regex(r"(?i)</style(?-u:\b)"),
        body: regex(r"(?i)<body(?-u:\b)"),
        head_close: regex(r"(?i)</head(?-u:\b)"),
        doctype: regex(r"(?i)<!doctype(?-u:\b)"),
        body_close: regex(r"(?i)</body(?-u:\b)"),
        html_close: regex(r"(?i)</html(?-u:\b)"),
        link_prefix: regex(r"(?i)<a(?-u:\b)"),
        link: regex(r#"(?i)^<a(?-u:\b)[^>]*href\s*=\s*["']?([^\s"']+)[^>]*>"#),
        inline: regex(r"(?i)</?(span|em|i|strong|b|u|a)(?-u:\b)[^>]*>"),
        li_prefix: regex(r"(?i)<li(?-u:\b)"),
        li: regex("(?i)^<li(?-u:\\b)[^>]*>[\n\u{1}\\s]*"),
        hr: regex(r"<hr(?-u:\b)[^>]*>"),
        tag: regex("<[^>]*>"),
        spaces: regex("[ \t]+"),
        blank_lines: regex(r"(?m)^\s+$"),
        many_breaks: regex("\n\n+"),
        leading_breaks: regex("^\n+"),
        trailing_breaks: regex("\n+$"),
    }
});

/// HTML as plain text: blocks as line breaks, links with their address, tags and scripts gone
pub fn html_to_text(html: &str) -> String {
    let p = &*HTML;
    let mut text = p.line_breaks.replace_all(html, "\u{1}").into_owned();
    text = replace_blocks(&text, &p.comment_open, false, &p.comment_close, false, " ");
    text = p.br.replace_all(&text, "\n").into_owned();
    text = p.blocks.replace_all(&text, "\n\n").into_owned();
    text = replace_blocks(&text, &p.script_open, true, &p.script_close, true, " ");
    text = replace_blocks(&text, &p.style_open, true, &p.style_close, true, " ");
    for prefix in [&p.body, &p.head_close, &p.doctype] {
        text = strip_through_last_tag(&text, prefix);
    }
    for prefix in [&p.body_close, &p.html_close] {
        text = strip_from_first_tag(&text, prefix);
    }
    text = replace_tags(&text, &p.link_prefix, &p.link, |caps| format!(" ({}) ", &caps[1]));
    text = p.inline.replace_all(&text, "").into_owned();
    text = replace_tags(&text, &p.li_prefix, &p.li, |_| "* ".into());
    text = p.hr.replace_all(&text, "\n-------------\n").into_owned();
    text = p.tag.replace_all(&text, " ").into_owned();
    text = text.replace('\u{1}', "\n");
    text = p.spaces.replace_all(&text, " ").into_owned();
    text = p.blank_lines.replace_all(&text, "").into_owned();
    text = p.many_breaks.replace_all(&text, "\n\n").into_owned();
    text = p.leading_breaks.replace(&text, "\n").into_owned();
    text = p.trailing_breaks.replace(&text, "\n").into_owned();
    decode_html_entities(&text)
}

/// The fields of an attached message that its header block shows
pub struct HeaderFields<'a> {
    pub from: Option<&'a ParsedAddress>,
    pub subject: Option<&'a str>,
    /// The Date header as written, shown when it does not parse
    pub date: Option<&'a str>,
    pub timestamp: Option<i64>,
    pub to: &'a [ParsedAddress],
    pub cc: &'a [ParsedAddress],
    pub bcc: &'a [ParsedAddress],
}

impl HeaderFields<'_> {
    /// The date for `data-date`, in ISO form when it parses, and the date to show
    fn dates(&self) -> Option<(String, String)> {
        match self.timestamp {
            Some(timestamp) => Some((crate::date::to_iso(timestamp), format_date(timestamp))),
            None => self.date.map(|date| (date.to_string(), date.to_string())),
        }
    }
}

/// `10/6/2025, 10:00:00` in UTC, the form postal-mime gets from Intl for en-US
fn format_date(timestamp: i64) -> String {
    let t = DateTime::from_timestamp(timestamp);
    format!(
        "{}/{}/{}, {:02}:{:02}:{:02}",
        t.month, t.day, t.year, t.hour, t.minute, t.second
    )
}

/// An address list as text, `Name <address>, group: a@b.c;`
pub fn text_addresses(addresses: &[ParsedAddress]) -> String {
    let mailbox = |name: &str, address: &str| {
        if name.is_empty() {
            address.to_string()
        } else {
            format!("{name} <{address}>")
        }
    };
    let mut parts = Vec::new();
    for (i, address) in addresses.iter().enumerate() {
        if i > 0 {
            parts.push(", ".to_string());
        }
        match address {
            ParsedAddress::Mailbox(Address { name, address }) => parts.push(mailbox(name, address)),
            ParsedAddress::Group { name, members } => {
                parts.push(format!("{name}:"));
                for (j, member) in members.iter().enumerate() {
                    if j > 0 {
                        parts.push(", ".into());
                    }
                    parts.push(mailbox(&member.name, &member.address));
                }
                parts.push(";".into());
            }
        }
    }
    parts.concat()
}

fn html_addresses(addresses: &[ParsedAddress]) -> String {
    let mailbox = |name: &str, address: &str| {
        let label = if name.is_empty() {
            format!("<{address}>")
        } else {
            name.to_string()
        };
        format!(
            "<a href=\"mailto:{}\" class=\"postal-email-address\">{}</a>",
            escape_html(&encode_mailto(address)),
            escape_html(&label)
        )
    };
    let separator = "<span class=\"postal-email-address-separator\">, </span>";
    let mut parts = Vec::new();
    for (i, address) in addresses.iter().enumerate() {
        if i > 0 {
            parts.push(separator.to_string());
        }
        match address {
            ParsedAddress::Mailbox(Address { name, address }) => parts.push(mailbox(name, address)),
            ParsedAddress::Group { name, members } => {
                parts.push(format!(
                    "<span class=\"postal-email-address-group\">{}:</span>",
                    escape_html(name)
                ));
                for (j, member) in members.iter().enumerate() {
                    if j > 0 {
                        parts.push(separator.to_string());
                    }
                    parts.push(mailbox(&member.name, &member.address));
                }
                parts.push("<span class=\"postal-email-address-group\">;</span>".into());
            }
        }
    }
    parts.join(" ")
}

/// Folds a long header value at white space, `\r\n` between the lines
fn fold_lines(text: &str, length: usize) -> String {
    let chars: Vec<char> = text.chars().collect();
    let mut out = String::new();
    let mut pos = 0;
    while pos < chars.len() {
        let mut line: Vec<char> = chars[pos..(pos + length).min(chars.len())].to_vec();
        if line.len() < length {
            out.extend(line);
            break;
        }
        if let Some(newline) = line.iter().position(|c| *c == '\n' || *c == '\r') {
            let mut end = newline + 1;
            if line[newline] == '\r' && line.get(newline + 1) == Some(&'\n') {
                end += 1;
            }
            out.extend(&line[..end]);
            pos += end;
            continue;
        }
        match line.iter().rposition(|c| c.is_whitespace()) {
            // break after the last white space, which stays on this line
            Some(space) => line.truncate(space + 1),
            None => {
                // no white space: the word goes on to its end, with the white space after it
                let rest = &chars[pos + line.len()..];
                let word = rest.iter().take_while(|c| !c.is_whitespace()).count();
                if word > 0 {
                    let spaces = rest[word..].iter().take_while(|c| c.is_whitespace()).count();
                    line.extend(&rest[..word + spaces]);
                }
            }
        }
        pos += line.len();
        out.extend(line);
        if pos < chars.len() {
            out.push_str("\r\n");
        }
    }
    out
}

fn header_rows(fields: &HeaderFields) -> Vec<(&'static str, String)> {
    let mut rows = Vec::new();
    if let Some(from) = fields.from {
        rows.push(("From", text_addresses(std::slice::from_ref(from))));
    }
    if let Some(subject) = fields.subject {
        rows.push(("Subject", subject.to_string()));
    }
    if let Some((_, shown)) = fields.dates() {
        rows.push(("Date", shown));
    }
    for (key, list) in [("To", fields.to), ("Cc", fields.cc), ("Bcc", fields.bcc)] {
        if !list.is_empty() {
            rows.push((key, text_addresses(list)));
        }
    }
    rows
}

/// The header block of an attached message in plain text, between lines of dashes
pub fn format_text_header(fields: &HeaderFields) -> String {
    let rows = header_rows(fields);
    let key_width = rows.iter().map(|(key, _)| key.len()).max().unwrap_or(0);
    let mut lines = Vec::new();
    for (key, value) in &rows {
        let padding = " ".repeat(key_width - key.len());
        let prefix = format!("{key}: {padding}");
        let empty = format!("{} {padding}", " ".repeat(key.len() + 1));
        let folded = fold_lines(value, 80);
        for (i, line) in folded
            .split('\n')
            .map(|l| js_trim(l.trim_end_matches('\r')))
            .enumerate()
        {
            lines.push(format!("{}{line}", if i == 0 { &prefix } else { &empty }));
        }
    }
    let width = lines.iter().map(|l| l.chars().count()).max().unwrap_or(0);
    let marker = "-".repeat(width);
    format!("\n{marker}\n{}\n{marker}\n", lines.join("\n"))
}

/// The header block of an attached message in HTML
pub fn format_html_header(fields: &HeaderFields) -> String {
    let row = |key: &str, class: &str, value: String| {
        format!(
            "<div class=\"postal-email-header-key\">{key}</div><div class=\"postal-email-header-value{class}\">{value}</div>"
        )
    };
    let mut rows = Vec::new();
    if let Some(from) = fields.from {
        rows.push(row("From", "", html_addresses(std::slice::from_ref(from))));
    }
    if let Some(subject) = fields.subject {
        rows.push(row("Subject", " postal-email-header-subject", escape_html(subject)));
    }
    if let Some((date, shown)) = fields.dates() {
        rows.push(format!(
            "<div class=\"postal-email-header-key\">Date</div><div class=\"postal-email-header-value postal-email-header-date\" data-date=\"{}\">{}</div>",
            escape_html(&date),
            escape_html(&shown)
        ));
    }
    for (key, list) in [("To", fields.to), ("Cc", fields.cc), ("Bcc", fields.bcc)] {
        if !list.is_empty() {
            rows.push(row(key, "", html_addresses(list)));
        }
    }
    if rows.is_empty() {
        return "<div class=\"postal-email-header\"></div>".into();
    }
    format!(
        "<div class=\"postal-email-header\"><div class=\"postal-email-header-row\">{}</div></div>",
        rows.join("</div>\n<div class=\"postal-email-header-row\">")
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn entities() {
        assert_eq!(
            decode_html_entities("a &amp; b &lt;c&gt; &#228; &#xE4; &auml &bogus; &#0;"),
            "a & b <c> ä ä ä &bogus; \u{fffd}"
        );
        assert_eq!(decode_html_entities("&#150;"), "–");
    }

    #[test]
    fn html_and_text() {
        assert_eq!(text_to_html(" a < b\nc "), "<div>a &#x3C; b<br />c</div>");
        let html = "<html><head><style>p{}</style></head><body><p>Hello <b>world</b></p><ul><li>one</li></ul><a href=\"https://x.ee\">link</a><script>x()</script><!-- c --></body></html>";
        assert_eq!(html_to_text(html), "\nHello world\n\n * one (https://x.ee) link ");
    }

    #[test]
    fn header_blocks() {
        let from = ParsedAddress::Mailbox(Address {
            name: "Andris".into(),
            address: "a@b.c".into(),
        });
        let fields = HeaderFields {
            from: Some(&from),
            subject: Some("Hi"),
            date: Some("Mon, 6 Oct 2025 10:00:00 +0000"),
            timestamp: Some(1_759_744_800),
            to: &[],
            cc: &[],
            bcc: &[],
        };
        assert_eq!(
            format_text_header(&fields),
            "\n----------------------------\nFrom:    Andris <a@b.c>\nSubject: Hi\nDate:    10/6/2025, 10:00:00\n----------------------------\n"
        );
        assert!(
            format_html_header(&fields).contains("data-date=\"2025-10-06T10:00:00.000Z\">10/6/2025, 10:00:00</div>")
        );
    }
}
