//! The card at the top of a message with a one-time code (a sign-in, verification or approval code): the code in large
//! type, the domain it is for above and below it, and Copy. The core fills an [`OtpCard`] with words of the catalog and
//! the code it found (an `OTP-Token` header, or the body as pe-otp reads it), only for a message the provider says the
//! domain signed; this writes it as markup of ours, every value escaped, without a script. Copy is a link the apps take
//! ([`COPY_CODE_LINK`]), as the preview runs no scripts. It sits above the sanitized message, under a class and in a
//! cascade layer the message can not name, so the message's own style elements can not restyle or hide it.

use crate::editor::{nonce, text};

/// The link of the card's Copy: the apps take a click on it (their web views cancel every navigation) and put the
/// code of the view on the clipboard. It is no URL a message can carry: the sanitizer keeps only http(s), mailto, cid
/// and data links.
pub const COPY_CODE_LINK: &str = "inboxclassic:copy-code";

/// Whether a link clicked in the reading pane is the card's [`COPY_CODE_LINK`]
pub fn is_copy_code_link(uri: &str) -> bool {
    crate::bounce::is_link(uri, COPY_CODE_LINK)
}

/// What the card says, its words from the catalog
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct OtpCard {
    /// "Code from example.com"
    pub heading: String,
    /// The code as the message prints it ("482 913"); what Copy copies is the app's, from the view
    pub code: String,
    /// "Enter it only on a page of example.com."
    pub note: String,
    /// The words of the Copy link
    pub copy: String,
    /// Said under the note when the message is old enough for the code to have expired
    pub old: Option<String>,
}

/// The longest the words of the card are shown, and the code
const MAX_WORDS: usize = 320;
const MAX_CODE: usize = 64;

fn shown(value: &str, max: usize) -> String {
    text(&value.chars().take(max).collect::<String>())
}

/// The rules of the card, `C` standing for its class: blue as a notice of the app, the code large and monospaced, Copy
/// a button-like link, left out of a printout
const RULES: &[(&str, &str)] = &[
    (
        "C",
        "display:block;box-sizing:border-box;max-width:720px;margin:0 0 12px;padding:10px 14px;border:1px solid #b9cbe8;border-left:4px solid #2f6fcf;\
         border-radius:6px;background:#f3f7fd;color:#1d1d1f;font:10pt Arial,sans-serif;text-align:left;\
         visibility:visible;opacity:1;position:static",
    ),
    (
        "C .h,C .n,C .o",
        "display:block;color:#555;font:9pt Arial,sans-serif;margin:0",
    ),
    ("C .h b", "color:#1d1d1f;font-weight:bold"),
    (
        "C .r",
        "display:flex;align-items:center;gap:14px;flex-wrap:wrap;margin:6px 0",
    ),
    (
        "C .c",
        "font:bold 22pt ui-monospace,Menlo,Consolas,'DejaVu Sans Mono',monospace;letter-spacing:2px;color:#1d1d1f;\
         user-select:all;-webkit-user-select:all",
    ),
    (
        "C a.b",
        "display:inline-block;padding:3px 14px;border:1px solid #9db6dd;border-radius:6px;background:#fff;\
         color:#1f5fbf;font:bold 9pt Arial,sans-serif;text-decoration:none;cursor:pointer",
    ),
    ("C a.b:hover", "background:#e8f0fb"),
    ("C a.b:focus-visible", "outline:2px solid #2f6fcf;outline-offset:1px"),
    ("C .o", "margin-top:4px;color:#8a5a00"),
];

fn style(class: &str) -> String {
    let mut css = format!("<style>@layer {class}{{");
    for (selectors, declarations) in RULES {
        css.push_str(&selectors.replace('C', &format!(".{class}")));
        css.push('{');
        for declaration in declarations.split(';') {
            css.push_str(declaration);
            css.push_str("!important;");
        }
        css.push('}');
    }
    // the code stays on paper, Copy does not
    css.push_str(&format!("@media print{{.{class} a.b{{display:none!important}}}}"));
    css.push_str("}</style>");
    css
}

/// The card as markup for the top of the reading pane's document, with its own style element
pub fn otp_card(card: &OtpCard) -> String {
    let class = format!("pe-otp-{}", nonce());
    let mut out = style(&class);
    out.push_str(&format!(
        "<div class=\"{class}\" role=\"note\"><div class=\"h\">{}</div>\
         <div class=\"r\"><span class=\"c\">{}</span><a class=\"b\" href=\"{COPY_CODE_LINK}\" role=\"button\">{}</a></div>\
         <div class=\"n\">{}</div>",
        shown(&card.heading, MAX_WORDS),
        shown(&card.code, MAX_CODE),
        shown(&card.copy, MAX_WORDS),
        shown(&card.note, MAX_WORDS),
    ));
    if let Some(old) = &card.old {
        out.push_str(&format!("<div class=\"o\">{}</div>", shown(old, MAX_WORDS)));
    }
    out.push_str("</div>");
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{Cards, RenderOptions, render_view_cards};

    fn card() -> OtpCard {
        OtpCard {
            heading: "Code from accounts.example.com".into(),
            code: "482 913".into(),
            note: "Enter it only on a page of example.com.".into(),
            copy: "Copy".into(),
            old: None,
        }
    }

    #[test]
    fn the_card_shows_the_code_and_copy() {
        let markup = otp_card(&card());
        assert!(markup.contains("<span class=\"c\">482 913</span>"), "{markup}");
        assert!(markup.contains(&format!("href=\"{COPY_CODE_LINK}\"")));
        assert!(markup.contains("Enter it only on a page of example.com."));
        assert!(!markup.contains("<script"));
        assert!(!markup.contains("class=\"o\""));
    }

    #[test]
    fn values_are_escaped_and_cut() {
        let markup = otp_card(&OtpCard {
            code: format!("<b>{}", "1".repeat(200)),
            heading: "Code from <script>x</script>".into(),
            old: Some("Sent long ago & expired".into()),
            ..card()
        });
        assert!(!markup.contains("<b>1") && !markup.contains("<script>x"), "{markup}");
        assert!(markup.contains("&lt;b&gt;"));
        assert!(markup.contains("Sent long ago &amp; expired"));
        assert!(markup.contains(&"1".repeat(MAX_CODE - 3)) && !markup.contains(&"1".repeat(MAX_CODE - 2)));
    }

    #[test]
    fn the_card_is_above_the_message_and_the_bounce() {
        let document = render_view_cards(
            "<p>Your code is 482913</p>",
            &RenderOptions::default(),
            &[],
            &[],
            &Cards {
                otp: Some(&card()),
                bounce: None,
            },
        )
        .document;
        let card_at = document.find("482 913").unwrap();
        assert!(card_at < document.find("Your code is").unwrap());
        assert!(document.contains("@media print{.pe-otp-"));
    }

    #[test]
    fn copy_links() {
        assert!(is_copy_code_link("inboxclassic:copy-code"));
        assert!(is_copy_code_link(" INBOXCLASSIC:copy-code/ "));
        assert!(!is_copy_code_link("inboxclassic:copy-codes"));
        assert!(!is_copy_code_link("https://example.com/inboxclassic:copy-code"));
    }
}
