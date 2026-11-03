//! `mailto:` links (RFC 6068), as Windows hands them to the default mail program: the addresses of the link and
//! its `to`, `cc`, `bcc`, `subject` and `body` fields as a new message. Every other field (`from`, `in-reply-to`,
//! anything a page made up) is left out, so a link can not make a message that looks like it came from elsewhere;
//! line breaks are taken out of what goes in a header, and the body is text, escaped into the editor's HTML.

use crate::Draft;

/// The most of a link that is read: a link is typed or clicked, not a book
const MAX_LINK: usize = 64 * 1024;

/// `%XX` decoded as UTF-8 (what is not UTF-8 is replaced); `+` stays a plus, as RFC 6068 has it
fn decode(text: &str) -> String {
    let bytes = text.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%'
            && i + 2 < bytes.len()
            && let (Some(high), Some(low)) = (hex(bytes[i + 1]), hex(bytes[i + 2]))
        {
            out.push(high << 4 | low);
            i += 3;
            continue;
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

fn hex(c: u8) -> Option<u8> {
    (c as char).to_digit(16).map(|d| d as u8)
}

/// What goes in a header field: one line
fn one_line(text: &str) -> String {
    text.chars()
        .map(|c| if c.is_control() { ' ' } else { c })
        .collect::<String>()
        .trim()
        .to_string()
}

/// Addresses added to a field, comma separated
fn append(field: &mut String, addresses: &str) {
    let addresses = one_line(addresses);
    if addresses.is_empty() {
        return;
    }
    if !field.is_empty() {
        field.push_str(", ");
    }
    field.push_str(&addresses);
}

/// Text as the editor's HTML: escaped, its lines as lines
fn body_html(text: &str) -> String {
    let text = text.replace("\r\n", "\n");
    text.split('\n')
        .map(|line| {
            let escaped = line
                .replace('&', "&amp;")
                .replace('<', "&lt;")
                .replace('>', "&gt;")
                .replace('"', "&quot;");
            if escaped.is_empty() {
                "<div><br></div>".to_string()
            } else {
                format!("<div>{escaped}</div>")
            }
        })
        .collect()
}

/// A new message from a `mailto:` link; None for what is no such link
pub fn draft(link: &str) -> Option<Draft> {
    let link = link.trim();
    if link.len() > MAX_LINK || link.len() < 7 || !link[..7].eq_ignore_ascii_case("mailto:") {
        return None;
    }
    let rest = &link[7..];
    let (path, query) = rest.split_once('?').unwrap_or((rest, ""));
    let mut draft = Draft::default();
    append(&mut draft.to, &decode(path));
    let mut body = None;
    for field in query.split('&').filter(|f| !f.is_empty()) {
        let (name, value) = field.split_once('=').unwrap_or((field, ""));
        let value = decode(value);
        match decode(name).to_ascii_lowercase().as_str() {
            "to" => append(&mut draft.to, &value),
            "cc" => append(&mut draft.cc, &value),
            "bcc" => append(&mut draft.bcc, &value),
            "subject" if draft.subject.is_empty() => draft.subject = one_line(&value),
            "body" if body.is_none() => body = Some(value),
            _ => {}
        }
    }
    draft.body = body.map(|b| body_html(&b)).unwrap_or_default();
    Some(draft)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_the_fields_of_a_link() {
        let d = draft("mailto:ann@example.com,Bob%20%3Cbob@example.com%3E?subject=Hello%20%C3%B5ie&cc=c@example.com&body=Line%201%0D%0ALine%20%3Cb%3E2%3C%2Fb%3E").unwrap();
        assert_eq!(d.to, "ann@example.com,Bob <bob@example.com>");
        assert_eq!(d.cc, "c@example.com");
        assert_eq!(d.subject, "Hello õie");
        assert_eq!(d.body, "<div>Line 1</div><div>Line &lt;b&gt;2&lt;/b&gt;</div>");
        // case does not matter, to= adds to the path's, + is a plus
        let d = draft("MAILTO:?To=a@example.com&to=b@example.com&BCC=x@example.com&subject=1+1").unwrap();
        assert_eq!(
            (d.to.as_str(), d.bcc.as_str(), d.subject.as_str()),
            ("a@example.com, b@example.com", "x@example.com", "1+1")
        );
    }

    #[test]
    fn keeps_a_link_from_making_other_headers() {
        // a line break in a field is no new header, and fields other than the five are left out
        let d = draft("mailto:a@example.com%0D%0ABcc:%20evil@example.com?subject=Hi%0D%0AFrom:%20boss@example.com&from=boss@example.com&in-reply-to=%3Cx@y%3E").unwrap();
        assert_eq!(d.to, "a@example.com  Bcc: evil@example.com");
        assert_eq!(d.subject, "Hi  From: boss@example.com");
        assert!(d.bcc.is_empty() && d.in_reply_to.is_none());
        // the first subject and body count
        let d = draft("mailto:a@example.com?subject=one&subject=two&body=x&body=y").unwrap();
        assert_eq!((d.subject.as_str(), d.body.as_str()), ("one", "<div>x</div>"));
    }

    #[test]
    fn refuses_what_is_no_mailto_link() {
        assert!(draft("https://example.com").is_none());
        assert!(draft("mailto").is_none());
        assert!(draft(&format!("mailto:{}", "a".repeat(MAX_LINK))).is_none());
        // broken escapes stay as they are
        assert_eq!(draft("mailto:a%zz@example.com%").unwrap().to, "a%zz@example.com%");
        assert_eq!(draft("mailto:").unwrap().to, "");
    }
}
