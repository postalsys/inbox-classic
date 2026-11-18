//! A message's own CSS made safe for the web view's decoders: no picture or font a sender wrote into it reaches them.
//!
//! - Every `url()` that is not an address on the internet (`http:`, `https:`, `//`) becomes `none`: a `data:`
//!   picture in a background, a list marker, a border image or `content` would otherwise be decoded by the web view as
//!   the sender wrote it (the CSP of a printout allows `data:` for the core's own encodes). Pictures on the internet
//!   stay, blocked by the CSP and the apps until the user allows them, as before.
//! - A string that names a `data:` address (`image-set("data:...")`, `image("data:...")`) becomes empty.
//! - `@font-face` rules are taken out: a sender's font would be parsed by the system's font parsers (the documents'
//!   CSP has `font-src 'none'` too).
//!
//! The text is read as CSS reads it (CSS Syntax 3): comments, strings and escapes are understood, so `u\72l(`, an
//! escaped `@font-face` or a `data:` written with escapes is found as the browser would find it. Anything taken out is
//! replaced by a word or a space, and no `</` is ever left in the result, so the text of a style element can not be
//! ended early by what was taken out of it.

use std::borrow::Cow;

/// `css` (a style attribute's value, or a style element's text) without pictures or fonts of the sender's own
pub(crate) fn clean(css: &str) -> Cow<'_, str> {
    // as a URL parser reads it: tabs and newlines are no part of an address
    let lower: String = css
        .chars()
        .filter(|c| !matches!(c, '\t' | '\n' | '\r'))
        .map(|c| c.to_ascii_lowercase())
        .collect();
    // quick: nothing that could be a url(), a data: string, a picture function or a font rule, escaped or not
    let words = ["url(", "data:", "@font", "image", "src("];
    if !lower.contains('\\') && !words.iter().any(|word| lower.contains(word)) {
        return Cow::Borrowed(css);
    }
    let out = Cleaner::new(css).run();
    Cow::Owned(out.replace("</", "<\\/"))
}

/// The text of every style element of a sanitized body cleaned ([`clean`]); the sanitizer writes them as
/// `<style>...</style>`, their text as it was
pub(crate) fn clean_style_elements(body: &str) -> String {
    let mut out = String::with_capacity(body.len());
    let mut rest = body;
    while let Some(at) = rest.find("<style") {
        let Some(open) = rest[at..].find('>').map(|end| at + end + 1) else {
            break;
        };
        out.push_str(&rest[..open]);
        rest = &rest[open..];
        let end = rest.find("</style").unwrap_or(rest.len());
        out.push_str(&clean(&rest[..end]));
        rest = &rest[end..];
    }
    out.push_str(rest);
    out
}

struct Cleaner {
    chars: Vec<char>,
    at: usize,
    out: String,
    /// The functions open at the cursor, innermost last: true for one whose strings name pictures
    /// ([`is_picture_function`])
    functions: Vec<bool>,
}

/// A function whose strings are addresses of pictures or fonts
fn is_picture_function(name: &str) -> bool {
    ["image-set", "-webkit-image-set", "image", "src"]
        .iter()
        .any(|function| name.eq_ignore_ascii_case(function))
}

impl Cleaner {
    fn new(text: &str) -> Self {
        Cleaner {
            chars: text.chars().collect(),
            at: 0,
            out: String::with_capacity(text.len()),
            functions: Vec::new(),
        }
    }

    fn peek(&self, ahead: usize) -> Option<char> {
        self.chars.get(self.at + ahead).copied()
    }

    fn run(mut self) -> String {
        while let Some(c) = self.peek(0) {
            match c {
                '/' if self.peek(1) == Some('*') => {
                    let start = self.at;
                    self.skip_comment();
                    self.copy_from(start);
                }
                '"' | '\'' => {
                    let start = self.at;
                    let value = self.string();
                    // a string of a picture function is an address, kept only on the internet
                    let picture = self.functions.iter().any(|&picture| picture);
                    if is_data(&value) || (picture && !is_remote(&value)) {
                        self.out.push_str("\"\"");
                    } else {
                        self.copy_from(start);
                    }
                }
                '@' if self.starts_ident(1) => {
                    let start = self.at;
                    self.at += 1;
                    let name = self.name();
                    if name.eq_ignore_ascii_case("font-face") {
                        self.skip_rule();
                        self.out.push(' ');
                    } else {
                        self.copy_from(start);
                    }
                }
                _ if self.starts_ident(0) => {
                    let start = self.at;
                    let name = self.name();
                    if self.peek(0) == Some('(') && name.eq_ignore_ascii_case("url") {
                        self.at += 1;
                        self.url(start);
                    } else if self.peek(0) == Some('(') {
                        self.at += 1;
                        self.copy_from(start);
                        self.functions.push(is_picture_function(&name));
                    } else {
                        self.copy_from(start);
                    }
                }
                '(' | ')' => {
                    if c == '(' {
                        self.functions.push(false);
                    } else {
                        self.functions.pop();
                    }
                    self.out.push(c);
                    self.at += 1;
                }
                _ => {
                    self.out.push(c);
                    self.at += 1;
                }
            }
        }
        self.out
    }

    fn copy_from(&mut self, start: usize) {
        self.out.extend(&self.chars[start..self.at]);
    }

    fn skip_comment(&mut self) {
        self.at += 2;
        while self.at < self.chars.len() {
            if self.peek(0) == Some('*') && self.peek(1) == Some('/') {
                self.at += 2;
                return;
            }
            self.at += 1;
        }
    }

    /// Whether a valid escape starts `ahead` (a backslash not before a newline)
    fn escape_at(&self, ahead: usize) -> bool {
        self.peek(ahead) == Some('\\') && !matches!(self.peek(ahead + 1), None | Some('\n' | '\r' | '\x0c'))
    }

    fn name_start(c: char) -> bool {
        c.is_ascii_alphabetic() || c == '_' || !c.is_ascii()
    }

    /// Whether an identifier starts `ahead` characters on
    fn starts_ident(&self, ahead: usize) -> bool {
        match self.peek(ahead) {
            Some('-') => match self.peek(ahead + 1) {
                Some(c) if Self::name_start(c) || c == '-' => true,
                _ => self.escape_at(ahead + 1),
            },
            Some(c) if Self::name_start(c) => true,
            Some('\\') => self.escape_at(ahead),
            _ => false,
        }
    }

    /// An escape's character (the backslash at the cursor), the cursor past it
    fn escaped(&mut self) -> char {
        self.at += 1;
        let mut hex = String::new();
        while hex.len() < 6 && self.peek(0).is_some_and(|c| c.is_ascii_hexdigit()) {
            hex.push(self.peek(0).unwrap_or_default());
            self.at += 1;
        }
        if hex.is_empty() {
            let c = self.peek(0).unwrap_or('\u{fffd}');
            self.at += 1;
            return c;
        }
        if self.peek(0).is_some_and(|c| c.is_ascii_whitespace()) {
            self.at += 1;
        }
        u32::from_str_radix(&hex, 16)
            .ok()
            .and_then(char::from_u32)
            .filter(|&c| c != '\0')
            .unwrap_or('\u{fffd}')
    }

    /// A name, its escapes decoded
    fn name(&mut self) -> String {
        let mut name = String::new();
        loop {
            match self.peek(0) {
                Some(c) if c.is_ascii_alphanumeric() || c == '-' || c == '_' || !c.is_ascii() => {
                    name.push(c);
                    self.at += 1;
                }
                Some('\\') if self.escape_at(0) => name.push(self.escaped()),
                _ => return name,
            }
        }
    }

    /// A string (the quote at the cursor), its value decoded, the cursor past its end
    fn string(&mut self) -> String {
        let quote = self.peek(0).unwrap_or('"');
        self.at += 1;
        let mut value = String::new();
        while let Some(c) = self.peek(0) {
            match c {
                c if c == quote => {
                    self.at += 1;
                    break;
                }
                // a bad string ends at the newline, which is left
                '\n' | '\r' | '\x0c' => break,
                '\\' => match self.peek(1) {
                    None => self.at += 1,
                    Some('\n' | '\r' | '\x0c') => self.at += 2,
                    Some(_) => value.push(self.escaped()),
                },
                c => {
                    value.push(c);
                    self.at += 1;
                }
            }
        }
        value
    }

    fn skip_whitespace(&mut self) {
        while self.peek(0).is_some_and(|c| c.is_ascii_whitespace()) {
            self.at += 1;
        }
    }

    /// A `url(` that starts at `start` (the cursor past its parenthesis): kept when its address is on the internet,
    /// else `none`. Of a quoted one only `url(` and its string are kept, what follows read as any CSS, its `)` closing
    /// the function
    fn url(&mut self, start: usize) {
        self.skip_whitespace();
        if matches!(self.peek(0), Some('"' | '\'')) {
            let value = self.string();
            if is_remote(&value) {
                self.copy_from(start);
                self.functions.push(false);
            } else {
                self.skip_function();
                self.out.push_str("none");
            }
            return;
        }
        if is_remote(&self.unquoted_url()) {
            self.copy_from(start);
        } else {
            self.out.push_str("none");
        }
    }

    /// Past the `)` that ends the function the cursor is in, its comments, strings, escapes and inner functions
    /// skipped
    fn skip_function(&mut self) {
        let mut depth = 0usize;
        while let Some(c) = self.peek(0) {
            match c {
                '/' if self.peek(1) == Some('*') => {
                    self.skip_comment();
                    continue;
                }
                '"' | '\'' => {
                    self.string();
                    continue;
                }
                '\\' => {
                    self.at += 2;
                    continue;
                }
                '(' => depth += 1,
                ')' if depth == 0 => {
                    self.at += 1;
                    return;
                }
                ')' => depth -= 1,
                _ => {}
            }
            self.at += 1;
        }
    }

    /// The address of an unquoted `url(` (the cursor at its start), the cursor past its `)`
    fn unquoted_url(&mut self) -> String {
        let mut value = String::new();
        while let Some(c) = self.peek(0) {
            match c {
                ')' => {
                    self.at += 1;
                    break;
                }
                '\\' if self.escape_at(0) => value.push(self.escaped()),
                c => {
                    value.push(c);
                    self.at += 1;
                }
            }
        }
        value
    }

    /// Past the rule at the cursor (its prelude, then its block or its `;`)
    fn skip_rule(&mut self) {
        let mut depth = 0usize;
        while let Some(c) = self.peek(0) {
            match c {
                '/' if self.peek(1) == Some('*') => {
                    self.skip_comment();
                    continue;
                }
                '"' | '\'' => {
                    self.string();
                    continue;
                }
                '\\' => {
                    self.at += 2;
                    continue;
                }
                ';' if depth == 0 => {
                    self.at += 1;
                    return;
                }
                '{' => depth += 1,
                '}' => {
                    self.at += 1;
                    if depth <= 1 {
                        return;
                    }
                    depth -= 1;
                    continue;
                }
                _ => {}
            }
            self.at += 1;
        }
    }
}

/// An address as a URL parser reads it: without tabs and newlines, without the controls and spaces around it,
/// lowercased
fn normalized(address: &str) -> String {
    address
        .trim_matches(|c: char| c <= ' ')
        .chars()
        .filter(|c| !matches!(c, '\t' | '\n' | '\r'))
        .map(|c| c.to_ascii_lowercase())
        .collect()
}

/// An address on the internet: http(s), or protocol-relative (the pictures the remote-pictures rule handles)
fn is_remote(address: &str) -> bool {
    let address = normalized(address);
    address.starts_with("http:") || address.starts_with("https:") || address.starts_with("//")
}

/// A string that names a `data:` address
fn is_data(value: &str) -> bool {
    normalized(value).starts_with("data:")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn data_pictures_are_taken_out_wherever_they_are() {
        for (css, want) in [
            ("background:url(data:image/png;base64,AAAA) red", "background:none red"),
            (
                "list-style-image:URL( \"data:image/gif;base64,R0lG\" )",
                "list-style-image:none",
            ),
            ("border-image:url('data:x') 30", "border-image:none 30"),
            ("content:url(data:image/svg+xml,%3Csvg%3E)", "content:none"),
            ("background:u\\72l(data:x)", "background:none"),
            ("background:url(d\\61ta:x)", "background:none"),
            (
                "background:image-set(\"data:image/png;base64,AA\" 1x)",
                "background:image-set(\"\" 1x)",
            ),
            ("background:image-set('d\\61ta:x' 1x)", "background:image-set(\"\" 1x)"),
            ("background:url(cid:x)", "background:none"),
            ("background:url(/pv/x-1-0)", "background:none"),
            ("background:url(part-1)", "background:none"),
        ] {
            assert_eq!(clean(css), want, "{css}");
        }
    }

    /// An address read as a URL parser reads it (tabs and newlines out, controls before it trimmed), and every string
    /// of a picture function that is not on the internet emptied
    #[test]
    fn hidden_data_addresses_are_taken_out() {
        for (css, want) in [
            ("background:image-set('da\tta:x' 1x)", "background:image-set(\"\" 1x)"),
            ("background:image-set('da\\9 ta:x' 1x)", "background:image-set(\"\" 1x)"),
            ("background:image-set('\\1 data:x' 1x)", "background:image-set(\"\" 1x)"),
            (
                "background:image-set('\u{1}data:x' 1x)",
                "background:image-set(\"\" 1x)",
            ),
            ("content:'da\\a ta:x'", "content:\"\""),
            ("background:url(da\tta:x)", "background:none"),
            (
                "background:-webkit-image-set('a.png' 1x, \"https://a/b.png\" 2x)",
                "background:-webkit-image-set(\"\" 1x, \"https://a/b.png\" 2x)",
            ),
            ("background:image('x.png')", "background:image(\"\")"),
            ("src:src('x.woff')", "src:src(\"\")"),
            ("background:image-set(('x.png') 1x)", "background:image-set((\"\") 1x)"),
            // a remote address with tabs in its scheme is still remote
            (
                "background:url('ht\ttps://a/b.png')",
                "background:url('ht\ttps://a/b.png')",
            ),
        ] {
            assert_eq!(clean(css), want, "{css:?}");
        }
    }

    /// What follows the string of a quoted `url()` is read as CSS: a parenthesis in a comment or an escape does not
    /// carry a picture function past the cleaner
    #[test]
    fn what_follows_a_quoted_url_is_cleaned() {
        for (css, want) in [
            (
                "background:url(\"https://a/\" /*(*/), image-set(\"data:x\" 1x) /*)*/",
                "background:url(\"https://a/\" /*(*/), image-set(\"\" 1x) /*)*/",
            ),
            (
                "background:url(\"https://a/\" \\(), image-set('d\\61ta:x' 1x)",
                "background:url(\"https://a/\" \\(), image-set(\"\" 1x)",
            ),
            ("background:url(\"data:x\" /*)*/ junk) red", "background:none red"),
        ] {
            assert_eq!(clean(css), want, "{css:?}");
        }
    }

    #[test]
    fn remote_pictures_and_plain_css_stay() {
        for css in [
            "background:url(https://example.com/a.png)",
            "background:url( \"HTTP://example.com/a.png\" )",
            "background:url(//example.com/a.png)",
            "color:red;content:\"\\2022 data\";font-family:'Data Sans'",
            "p{margin:0}/* url(data:x) in a comment */",
        ] {
            assert_eq!(clean(css), css, "{css}");
        }
    }

    #[test]
    fn font_faces_are_taken_out() {
        let css = "@font-face{font-family:X;src:url(data:font/woff2;base64,AAAA)}p{color:red}\
                   @FONT-FACE {src:url(\"}\")}@f\\6fnt-face{src:local(x)}h1{margin:0}";
        assert_eq!(clean(css), " p{color:red}  h1{margin:0}");
        // a media query around one: only the rule goes
        assert_eq!(
            clean("@media print{@font-face{src:url(x)}p{color:red}}"),
            "@media print{ p{color:red}}"
        );
    }

    /// What was taken out can not join what is around it into the end of the style element
    #[test]
    fn nothing_taken_out_ends_the_style_element() {
        let css = "p{}<@font-face{}/style><img src=x onerror=alert(1)>";
        let out = clean(css);
        assert!(!out.to_ascii_lowercase().contains("</style"), "{out}");
        let body = format!("<style>{css}</style><p>x</p>");
        let cleaned = clean_style_elements(&body);
        assert_eq!(cleaned.matches("</style>").count(), 1, "{cleaned}");
        assert!(cleaned.ends_with("</style><p>x</p>"), "{cleaned}");
    }

    #[test]
    fn broken_css_ends_without_a_panic() {
        for css in [
            "url(",
            "url(\"data:",
            "@font-face{",
            "\\",
            "'\\",
            "@font-face",
            "u\\",
            "url(data:x\\",
        ] {
            let _ = clean(css);
        }
        assert_eq!(clean("a:url(data:x"), "a:none");
    }
}
