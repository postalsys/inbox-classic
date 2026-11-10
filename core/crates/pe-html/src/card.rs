//! What the cards of the app above a message share: a bounce's ([`crate::bounce`]), a one-time code's ([`crate::otp`])
//! and a calendar event's ([`crate::event`]). One frame for all of them, as a notice of the app inside the message: a
//! tinted panel with a coloured edge, a heading with its picture, lines of plain words, and actions drawn as push
//! buttons. The tone says what kind of news it is: a failure in red, a delay or a cancellation in amber, information in
//! blue.
//!
//! Each card is markup of ours above the sanitized message, every value escaped, without a script. Its rules sit in a
//! cascade layer named by a nonce class the message can not guess, each declaration important: an important
//! declaration of the first layer beats any of the message's, whatever its selector, so the message's own style
//! elements can not restyle, move or hide a card.

use crate::editor::text;

/// What kind of news a card is
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Tone {
    /// Something failed: red
    Failure,
    /// Not yet, or not any more: amber
    Delay,
    /// Information: blue
    Info,
}

impl Tone {
    fn class(self) -> &'static str {
        match self {
            Tone::Failure => "F",
            Tone::Delay => "D",
            Tone::Info => "I",
        }
    }
}

/// The picture beside a card's heading, 20 by 20, drawn in the card's colour
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Icon {
    /// An envelope: a message that was not delivered
    Envelope,
    /// A clock: one that is not delivered yet
    Clock,
    /// A key: a one-time code
    Key,
    /// A calendar page: an event
    Calendar,
}

fn icon_paths(icon: Icon) -> &'static str {
    match icon {
        Icon::Envelope => {
            "<rect x=\"2.5\" y=\"4.5\" width=\"15\" height=\"11\" rx=\"1.5\"/><path d=\"M3 5.5l7 5.5 7-5.5\"/>"
        }
        Icon::Clock => "<circle cx=\"10\" cy=\"10\" r=\"7.5\"/><path d=\"M10 5.5V10l3 2\"/>",
        Icon::Key => "<circle cx=\"6.5\" cy=\"10\" r=\"3.5\"/><path d=\"M10 10h7.5M15 10v3M17.5 10v2.5\"/>",
        Icon::Calendar => {
            "<rect x=\"3\" y=\"4\" width=\"14\" height=\"13\" rx=\"1.5\"/><path d=\"M3 8h14M7 2.5v3M13 2.5v3\"/>\
             <path d=\"M6.5 11h1M9.5 11h1M12.5 11h1M6.5 14h1M9.5 14h1\"/>"
        }
    }
}

/// The rules every card has, `C` standing for its class
const BASE: &[(&str, &str)] = &[
    // the elements of the card as the browser draws them, whatever the message's style elements say
    (
        "C,C div,C p,C span,C a,C b,C details,C summary,C pre,C svg",
        "all:revert;visibility:visible;opacity:1;position:static;float:none;transform:none;filter:none;clip-path:none",
    ),
    (
        "C",
        "display:block;box-sizing:border-box;margin:0 0 12px;padding:9px 12px 10px;max-width:720px;\
         border:1px solid var(--line);border-left:3px solid var(--accent);border-radius:4px;background:var(--tint);\
         color:#1f1f1f;font:9.5pt/1.4 system-ui,-apple-system,'Segoe UI',Arial,sans-serif;text-align:left;\
         direction:ltr;overflow-wrap:anywhere",
    ),
    ("C.F", "--accent:#c42b1c;--tint:#fdf5f4;--line:#f1d4d0;--disc:#f9e2df"),
    ("C.D", "--accent:#9a5b00;--tint:#fff9ee;--line:#f0dfbd;--disc:#fbecd0"),
    ("C.I", "--accent:#0f5fb3;--tint:#f4f8fd;--line:#cfdcee;--disc:#e1ebf8"),
    // the heading, its picture beside it
    ("C .hd", "display:flex;align-items:center;gap:8px;margin:0"),
    ("C .hd svg", "flex:0 0 auto;width:18px;height:18px"),
    (
        "C .h",
        "display:block;margin:0;font-weight:600;font-size:10.5pt;line-height:1.3;color:var(--accent)",
    ),
    // lines under the heading, in line with its words
    ("C .l", "display:block;margin:3px 0 0 26px;color:#4d4d4d"),
    ("C .m", "display:block;margin:3px 0 0 26px;color:#1f1f1f"),
    ("C a", "color:#0b5cad;text-decoration:underline;cursor:pointer"),
    ("C .k", "display:block;margin:3px 0 0 26px"),
    // actions: push buttons, as the window's own
    (
        "C .x",
        "display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin:8px 0 0 26px",
    ),
    (
        "C a.btn",
        "display:inline-block;box-sizing:border-box;min-width:76px;padding:3px 12px;border:1px solid #a7a7a7;\
         border-radius:3px;background:linear-gradient(#fdfdfd,#ececec);color:#1f1f1f;font:9pt/1.3 system-ui,\
         -apple-system,'Segoe UI',Arial,sans-serif;text-align:center;text-decoration:none;cursor:default;\
         white-space:nowrap",
    ),
    (
        "C a.btn:hover",
        "border-color:#3c7fd1;background:linear-gradient(#f6faff,#dcebfb)",
    ),
    ("C a.btn:active", "background:#cfe2f7"),
    ("C a.btn:focus-visible", "outline:2px solid #3c7fd1;outline-offset:1px"),
    ("C svg", "display:block;width:20px;height:20px;overflow:visible"),
    (
        "C svg *",
        "fill:none;stroke:var(--accent);stroke-width:1.5;stroke-linecap:round;stroke-linejoin:round;visibility:visible",
    ),
];

/// The style element of a card with `class`: the shared rules, then the card's own, in a layer of the class's name.
/// On paper a card keeps its words and loses its buttons.
pub(crate) fn style(class: &str, own: &[(&str, &str)]) -> String {
    let mut css = format!("<style>@layer {class}{{");
    for (selectors, declarations) in BASE.iter().chain(own) {
        css.push_str(&selectors.replace('C', &format!(".{class}")));
        css.push('{');
        for declaration in declarations.split(';') {
            css.push_str(declaration);
            css.push_str("!important;");
        }
        css.push('}');
    }
    css.push_str(&format!("@media print{{.{class} .x{{display:none!important}}}}"));
    css.push_str("}</style>");
    css
}

/// The opening of a card of `class` in `tone`, with its heading and picture
pub(crate) fn open(class: &str, tone: Tone, icon: Icon, heading: &str) -> String {
    format!(
        "<div class=\"{class} {}\" role=\"note\"><div class=\"hd\"><svg viewBox=\"0 0 20 20\" aria-hidden=\"true\">{}</svg>\
         <div class=\"h\">{}</div></div>",
        tone.class(),
        icon_paths(icon),
        shown(heading, MAX_VALUE)
    )
}

/// A push button of a card that follows `link` (one of the document's own, which the apps take)
pub(crate) fn button(link: &str, words: &str) -> String {
    format!(
        "<a class=\"btn\" href=\"{link}\" role=\"button\">{}</a>",
        shown(words, MAX_VALUE)
    )
}

/// The longest a value of a card is shown: an address, a line, a name
pub(crate) const MAX_VALUE: usize = 320;

/// A value of a card as text in HTML: cut at `max` characters, escaped. The core has made it safe to show already
/// (control characters and direction marks as spaces).
pub(crate) fn shown(value: &str, max: usize) -> String {
    let mut out: String = value.chars().take(max).collect();
    if value.chars().nth(max).is_some() {
        out.push('…');
    }
    text(&out)
}

/// Whether `uri`, as a web view names a clicked link, is the document's own `link` (a trailing slash allowed)
pub(crate) fn is_link(uri: &str, link: &str) -> bool {
    let uri = uri.trim();
    uri.strip_suffix('/').unwrap_or(uri).eq_ignore_ascii_case(link)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_rule_is_important_and_in_the_layer() {
        let css = style("pe-x-1", &[("C .z", "color:red;margin:0")]);
        assert!(css.starts_with("<style>@layer pe-x-1{"));
        assert!(css.contains(".pe-x-1 .z{color:red!important;margin:0!important;}"));
        assert!(css.contains("@media print{.pe-x-1 .x{display:none!important}}"));
        // no declaration without its important
        assert_eq!(css.matches(';').count(), css.matches("!important;").count());
    }

    #[test]
    fn headings_and_buttons_are_escaped() {
        let card = open("pe-x-1", Tone::Info, Icon::Key, "<b>Code</b>");
        assert!(
            card.contains("&lt;b&gt;Code&lt;/b&gt;") && card.contains("class=\"pe-x-1 I\""),
            "{card}"
        );
        let button = button("inboxclassic:x", "Copy & go");
        assert!(button.contains("Copy &amp; go") && button.contains("href=\"inboxclassic:x\""));
    }
}
