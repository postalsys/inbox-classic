//! The card at the top of a message with a one-time code (a sign-in, verification or approval code): the code in large
//! type, the domain it is for above and below it, and Copy. The core fills an [`OtpCard`] with words of the catalog and
//! the code it found (an `OTP-Token` header, or the body as pe-otp reads it), only for a message the provider says the
//! domain signed; this writes it in the frame every card of the app has ([`crate::card`]). Copy is a link the apps take
//! ([`COPY_CODE_LINK`]), as the preview runs no scripts.

use crate::card::{Icon, MAX_VALUE, Tone, button, is_link, open, shown, style};
use crate::editor::nonce;

/// The link of the card's Copy: the apps take a click on it (their web views cancel every navigation) and put the
/// code of the view on the clipboard. It is no URL a message can carry: the sanitizer keeps only http(s), mailto, cid
/// and data links.
pub const COPY_CODE_LINK: &str = "inboxclassic:copy-code";

/// Whether a link clicked in the reading pane is the card's [`COPY_CODE_LINK`]
pub fn is_copy_code_link(uri: &str) -> bool {
    is_link(uri, COPY_CODE_LINK)
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
    /// The words of the Copy button
    pub copy: String,
    /// Said under the note when the message is old enough for the code to have expired
    pub old: Option<String>,
}

/// The longest the code is shown
const MAX_CODE: usize = 64;

/// The code card's own rules: the code large and monospaced beside Copy, an old code's warning in amber
const RULES: &[(&str, &str)] = &[
    // the code and Copy in a row; on paper the code stays, Copy goes
    (
        "C .cr",
        "display:flex;align-items:center;gap:12px;flex-wrap:wrap;margin:6px 0 2px 26px",
    ),
    ("C .cr .x", "margin:0"),
    (
        "C .c",
        "font:bold 20pt/1.15 ui-monospace,Menlo,Consolas,'DejaVu Sans Mono',monospace;letter-spacing:2px;\
         color:#1f1f1f;user-select:all;-webkit-user-select:all",
    ),
    ("C .o", "color:#9a5b00"),
];

/// The card as markup for the top of the reading pane's document, with its own style element
pub fn otp_card(card: &OtpCard) -> String {
    let class = format!("pe-otp-{}", nonce());
    let mut out = style(&class, RULES);
    out.push_str(&open(&class, Tone::Info, Icon::Key, &card.heading));
    out.push_str(&format!(
        "<div class=\"cr\"><span class=\"c\">{}</span><span class=\"x\">{}</span></div><div class=\"l\">{}</div>",
        shown(&card.code, MAX_CODE),
        button(COPY_CODE_LINK, &card.copy),
        shown(&card.note, MAX_VALUE),
    ));
    if let Some(old) = &card.old {
        out.push_str(&format!("<div class=\"l o\">{}</div>", shown(old, MAX_VALUE)));
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
        assert!(!markup.contains("class=\"l o\""));
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
                ..Default::default()
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
