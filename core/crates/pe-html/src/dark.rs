//! Messages on a dark background when the window is dark (the Mac and Linux, which follow the system's appearance;
//! Windows keeps its classic light look and never turns this on). The documents carry both looks and the web view
//! picks one by `prefers-color-scheme`, so a change of the system's appearance needs no reload. What a message looks
//! like in the dark is decided here, in Rust, while its sanitized markup is wrapped:
//!
//! - a message that brings its own dark styles is shown as it asks;
//! - one that sets no backgrounds (what people write in their mail programs) is shown dark, its text colors that would
//!   be too dark to read there marked to be lightened;
//! - one with backgrounds of its own (newsletters, receipts) is left light, as it was designed, as Apple Mail does.
//!
//! Printing is always light. Only colors the sanitizer kept are looked at; nothing is fetched to decide.

#[cfg(not(test))]
use std::sync::atomic::{AtomicBool, Ordering};

/// Whether documents may be dark: the Mac and Linux turn it on (Options' switch), Windows never does
#[cfg(not(test))]
static DARK: AtomicBool = AtomicBool::new(false);

#[cfg(test)]
thread_local! {
    /// The switch in tests, one for each test's thread, so the tests that turn it on do not race the others
    static TEST_DARK: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
}

/// Lets documents follow a dark window (`true`), or keeps them light
pub fn set_dark(on: bool) {
    #[cfg(test)]
    TEST_DARK.with(|dark| dark.set(on));
    #[cfg(not(test))]
    DARK.store(on, Ordering::Relaxed);
}

/// Whether documents may be dark
pub fn dark() -> bool {
    #[cfg(test)]
    return TEST_DARK.with(std::cell::Cell::get);
    #[cfg(not(test))]
    DARK.load(Ordering::Relaxed)
}

/// How a message looks in a dark window
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Look {
    /// Light, also in the dark: as designed, or dark mode is off
    Light,
    /// Dark around it; `adapt`: its dark text colors lightened (it brings no dark styles of its own)
    Dark { adapt: bool },
}

/// How `body` (sanitized markup) looks when the window is dark
pub(crate) fn look(body: &str) -> Look {
    look_with(body, dark())
}

fn look_with(body: &str, dark: bool) -> Look {
    if !dark {
        return Look::Light;
    }
    let lower = body.to_ascii_lowercase();
    if own_dark_styles(&lower) {
        return Look::Dark { adapt: false };
    }
    if has_backgrounds(&lower) {
        return Look::Light;
    }
    Look::Dark { adapt: true }
}

/// Whether a style element of the markup has styles for a dark window (`prefers-color-scheme` in it, not merely in
/// the text)
fn own_dark_styles(lower: &str) -> bool {
    lower.split("<style").skip(1).any(|rest| {
        let css = rest.split("</style").next().unwrap_or("");
        css.contains("prefers-color-scheme")
    })
}

/// Whether markup paints backgrounds of its own: a bgcolor or background attribute, or a background in CSS that is not
/// transparent or none
fn has_backgrounds(lower: &str) -> bool {
    if lower.contains("bgcolor=") || lower.contains(" background=") {
        return true;
    }
    let mut rest = lower;
    while let Some(at) = rest.find("background") {
        let after = &rest[at + "background".len()..];
        // background:, background-color:, background-image:
        let value = after
            .strip_prefix(':')
            .or_else(|| after.strip_prefix("-color:"))
            .or_else(|| after.strip_prefix("-image:"));
        if let Some(value) = value {
            let value = value.trim_start();
            let none = ["transparent", "none", "inherit", "initial", "unset"]
                .iter()
                .any(|v| value.starts_with(v));
            if !none {
                return true;
            }
        }
        rest = after;
    }
    false
}

/// `body` with every element whose own text color would be too dark to read on a dark background marked
/// (`data-pe-dark`), for the dark style to lighten. The markup is the sanitizer's: attributes quoted with `"`, a `"`
/// inside one written `&quot;`.
pub(crate) fn mark_dark_text(body: &str) -> String {
    let mut out = String::with_capacity(body.len() + 64);
    let mut rest = body;
    while let Some(start) = rest.find('<') {
        out.push_str(&rest[..start]);
        let tag = &rest[start..];
        let Some(end) = tag.find('>') else {
            out.push_str(tag);
            return out;
        };
        let open = &tag[..end];
        let is_element = open[1..].starts_with(|c: char| c.is_ascii_alphabetic());
        if is_element && colors_of(open).any(|c| is_dark(&c)) {
            let (head, closing) = match open.strip_suffix('/') {
                Some(head) => (head, "/>"),
                None => (open, ">"),
            };
            out.push_str(head);
            out.push_str(" data-pe-dark=\"\"");
            out.push_str(closing);
        } else {
            out.push_str(&tag[..=end]);
        }
        rest = &tag[end + 1..];
    }
    out.push_str(rest);
    out
}

/// The text colors an opening tag sets: `color` in its style attribute, and a font's `color` attribute
fn colors_of(open: &str) -> impl Iterator<Item = String> {
    let lower = open.to_ascii_lowercase();
    let mut colors = Vec::new();
    if let Some(style) = attribute(&lower, "style") {
        for declaration in style.split(';') {
            if let Some((name, value)) = declaration.split_once(':')
                && name.trim() == "color"
            {
                colors.push(value.replace("!important", "").trim().to_string());
            }
        }
    }
    if lower.starts_with("<font")
        && let Some(color) = attribute(&lower, "color")
    {
        colors.push(color.trim().to_string());
    }
    colors.into_iter()
}

/// The value of attribute `name` of an opening tag (lowercase), as quoted
fn attribute<'a>(open: &'a str, name: &str) -> Option<&'a str> {
    let key = format!(" {name}=\"");
    let at = open.find(&key)? + key.len();
    let end = open[at..].find('"')?;
    Some(&open[at..at + end])
}

/// Whether a CSS color is too dark to read on a dark background: relative luminance under 0.1, which leaves less than
/// 2.5 to 1 of contrast against it (red and blue text stay as they are)
fn is_dark(color: &str) -> bool {
    rgb(color).is_some_and(|(r, g, b)| {
        let linear = |c: u8| {
            let c = f64::from(c) / 255.0;
            if c <= 0.03928 {
                c / 12.92
            } else {
                ((c + 0.055) / 1.055).powf(2.4)
            }
        };
        0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b) < 0.1
    })
}

/// A CSS color as red, green and blue: #rgb, #rrggbb, rgb(r, g, b) and the dark names; None for anything else
fn rgb(color: &str) -> Option<(u8, u8, u8)> {
    let color = color.trim();
    if let Some(hex) = color.strip_prefix('#') {
        let digit = |s: &str| u8::from_str_radix(s, 16).ok();
        return match hex.len() {
            3 | 4 => {
                let one = |i: usize| digit(&hex[i..=i]).map(|v| v * 17);
                Some((one(0)?, one(1)?, one(2)?))
            }
            6 | 8 => Some((digit(&hex[0..2])?, digit(&hex[2..4])?, digit(&hex[4..6])?)),
            _ => None,
        };
    }
    if let Some(inner) = color.strip_prefix("rgb(").or_else(|| color.strip_prefix("rgba(")) {
        let parts: Vec<u8> = inner
            .trim_end_matches(')')
            .split([',', ' ', '/'])
            .filter(|p| !p.is_empty())
            .take(3)
            .map(|p| p.trim().parse::<f64>().ok().map(|v| v.clamp(0.0, 255.0) as u8))
            .collect::<Option<_>>()?;
        return (parts.len() == 3).then(|| (parts[0], parts[1], parts[2]));
    }
    match color {
        "black" => Some((0, 0, 0)),
        "navy" => Some((0, 0, 128)),
        "maroon" => Some((128, 0, 0)),
        "darkblue" => Some((0, 0, 139)),
        "dimgray" | "dimgrey" => Some((105, 105, 105)),
        "gray" | "grey" => Some((128, 128, 128)),
        _ => None,
    }
}

/// The colors of a dark document around a message, the fold button and the text marked by [`mark_dark_text`]: on the
/// screen only, so paper stays light
pub(crate) const DOCUMENT_DARK: &str = "@media screen and (prefers-color-scheme:dark){\
    html{background:#1e1f22;color:#e3e3e6}\
    a{color:#8ab4f8}\
    details.pe-fold>summary{color:#c6c6ca;background:#36373b;border-color:#55565b}\
    details.pe-fold>summary:hover{background:#45464b;color:#fff}\
    [data-pe-dark]{color:#e3e3e6!important}}";

/// The dark colors of the pages the core shows in place of a message (downloading, not downloaded)
pub(crate) const PAGE_DARK: &str = "@media screen and (prefers-color-scheme:dark){\
    html{background:#1e1f22}body{color:#d6d6da}.detail{color:#a6a6ab}\
    .spin{border-color:#4a4b50;border-top-color:#b0b0b5}}";

/// The dark colors of a card of `class`, in its layer
pub(crate) fn card_dark(class: &str) -> String {
    let c = format!(".{class}");
    format!(
        "@media screen and (prefers-color-scheme:dark){{\
        {c}{{background:#2a2b2f!important;color:#e3e3e6!important;border-color:#45464b!important;\
        border-left-color:var(--accent)!important}}\
        {c}.F{{--accent:#ff8a7a!important;--disc:#4a2a27!important}}\
        {c}.D{{--accent:#e8b55c!important;--disc:#45371f!important}}\
        {c}.I{{--accent:#8ab4f8!important;--disc:#26354a!important}}\
        {c},{c} *{{--line:#45464b!important}}{c} .y{{--accent:#e8b55c!important;--disc:#45371f!important}}\
        {c} .l{{color:#b9b9be!important}}{c} .m{{color:#e3e3e6!important}}{c} a{{color:#8ab4f8!important}}\
        {c} .a,{c} .t,{c} .c{{color:#e3e3e6!important}}{c} .o{{color:#e8b55c!important}}\
        {c} .e,{c} .n,{c} .s,{c} summary{{color:#b9b9be!important}}\
        {c} pre{{background:#1e1f22!important;color:#e3e3e6!important}}\
        {c} a.btn{{background:#3a3b40!important;color:#e3e3e6!important;border-color:#5a5b61!important}}\
        {c} a.btn:hover{{background:#45474d!important;border-color:#8ab4f8!important}}}}"
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A message that only names prefers-color-scheme in its text brings no dark styles; one with them in a style
    /// element does
    #[test]
    fn own_dark_styles_are_in_a_style_element() {
        assert!(!own_dark_styles("<p>we support prefers-color-scheme now</p>"));
        assert!(own_dark_styles(
            "<style>@media (prefers-color-scheme: dark){p{color:#eee}}</style><p>hi</p>"
        ));
        assert_eq!(
            look_with("<p>about prefers-color-scheme</p>", true),
            Look::Dark { adapt: true }
        );
    }

    /// The marking relies on the sanitizer escaping < and > in attribute values: a value that looks like the end of a
    /// tag stays text, and no element appears from it
    #[test]
    fn marking_never_makes_markup_from_an_attribute() {
        let clean = crate::sanitize("<p style=\"color:#000\" title=\"a><img src=x>\">dark</p>");
        let marked = mark_dark_text(&clean);
        assert!(!marked.contains("<img"), "{marked}");
        assert_eq!(marked.matches('<').count(), clean.matches('<').count(), "{marked}");
    }

    /// Every text a card writes in its own dark colors is given a light one, and the bounce card's server message no
    /// white box
    #[test]
    fn cards_have_light_text_in_the_dark() {
        let css = card_dark("k");
        for selector in [
            ".k .a",
            ".k .t",
            ".k .c",
            ".k .e",
            ".k .n",
            ".k .s",
            ".k summary",
            ".k pre",
            ".k .l",
            ".k .m",
        ] {
            assert!(css.contains(selector), "{selector} missing from {css}");
        }
        assert!(css.contains("--line:#45464b"));
    }

    #[test]
    fn tells_dark_colors() {
        for dark in [
            "#000",
            "#222222",
            "rgb(34, 34, 34)",
            "black",
            "navy",
            "#1f1f1f",
            "rgba(0,0,0,0.8)",
        ] {
            assert!(is_dark(dark), "{dark}");
        }
        for light in [
            "#fff",
            "#ff0000",
            "rgb(200,200,200)",
            "white",
            "#e3e3e3",
            "red",
            "inherit",
        ] {
            assert!(!is_dark(light), "{light}");
        }
    }

    #[test]
    fn marks_text_too_dark_and_leaves_the_rest() {
        let body = "<p style=\"color:#222222;margin:0\">dark</p><span style=\"color: red\">red</span>\
                    <font color=\"#000\">old</font><br/><img src=\"data:x\"/>";
        assert_eq!(
            mark_dark_text(body),
            "<p style=\"color:#222222;margin:0\" data-pe-dark=\"\">dark</p><span style=\"color: red\">red</span>\
             <font color=\"#000\" data-pe-dark=\"\">old</font><br/><img src=\"data:x\"/>"
        );
        // a background color is no text color
        assert_eq!(
            mark_dark_text("<p style=\"background-color:#000\">x</p>"),
            "<p style=\"background-color:#000\">x</p>"
        );
    }

    #[test]
    fn tells_written_mail_from_designed_mail() {
        set_dark(true);
        assert_eq!(
            look("<div dir=\"ltr\">Hi Ann,<br>see you</div>"),
            Look::Dark { adapt: true }
        );
        assert_eq!(
            look("<table bgcolor=\"#f4f4f4\"><tr><td>Sale</td></tr></table>"),
            Look::Light
        );
        assert_eq!(
            look("<div style=\"background-color: #ffffff\">Receipt</div>"),
            Look::Light
        );
        assert_eq!(
            look("<div style=\"background:transparent\">x</div>"),
            Look::Dark { adapt: true }
        );
        assert_eq!(
            look("<style>@media (prefers-color-scheme: dark){body{background:#000}}</style><p>x</p>"),
            Look::Dark { adapt: false }
        );
        assert_eq!(look_with("<p>x</p>", false), Look::Light);
    }
}
