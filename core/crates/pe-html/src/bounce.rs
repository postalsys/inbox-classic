//! The card at the top of a bounce (a notice that a message was not delivered, or not yet): what happened to each
//! recipient in plain words, what to do about it, and the receiving server's own words folded under Details. The core
//! fills a [`BounceCard`] with words of the catalog and values from the notice; this writes it as markup of ours, every
//! value escaped, with inline SVG pictures and no script, in the frame every card of the app has ([`crate::card`]).

use crate::card::{Icon, MAX_VALUE, Tone, is_link, open, shown, style};
use crate::editor::nonce;

/// The link of "Show the message that bounced": the apps take a click on it (their web views cancel every navigation
/// and open links in the browser) and select the message of [`crate::Rendered`]'s view instead. It is no URL a message
/// can carry: the sanitizer keeps only http(s), mailto, cid and data links.
pub const BOUNCED_MESSAGE_LINK: &str = "inboxclassic:bounced-message";

/// Whether a link clicked in the reading pane is the card's [`BOUNCED_MESSAGE_LINK`]
pub fn is_bounced_message_link(uri: &str) -> bool {
    is_link(uri, BOUNCED_MESSAGE_LINK)
}

/// The picture of a reason; the 16 kinds of reason share these six
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CardPicture {
    /// The address: it does not exist, is not valid, or its mailbox is closed
    Address,
    /// A full mailbox
    Mailbox,
    /// Refused: a blocklist, the server's rules, where it came from
    Block,
    /// Spam or a virus
    Spam,
    /// A server or the connection to it
    Server,
    /// Later: greylisting, too much mail at once
    Clock,
}

/// One reason, with the recipients it is the reason for
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct CardReason {
    pub picture: Option<CardPicture>,
    /// The recipients, as the notice names them
    pub addresses: Vec<String>,
    /// "The address does not exist"
    pub title: String,
    /// Why, in plain words
    pub why: String,
    /// What to do about it
    pub advice: String,
    /// When the server tries again, the blocklists it named
    pub notes: Vec<String>,
    /// Its recipients are still being tried: drawn as a delay, also in the card of a failure
    pub delayed: bool,
}

/// What the notice says of one recipient, for Details
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct CardDetail {
    pub address: String,
    /// "Server: mx.example.com", "Status: 5.1.1"
    pub lines: Vec<String>,
    /// The receiving server's own words
    pub words: String,
}

/// The card of a bounce, its words already in the user's language
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct BounceCard {
    /// Not delivered yet, rather than not delivered
    pub delayed: bool,
    pub heading: String,
    /// Under the heading: that the server is still trying (delayed), the subject of the message
    pub lines: Vec<String>,
    /// The text of [`BOUNCED_MESSAGE_LINK`], when the message is in the store
    pub link: Option<String>,
    /// "What you can do:"
    pub advice_label: String,
    pub reasons: Vec<CardReason>,
    /// "Details"
    pub details_label: String,
    pub details: Vec<CardDetail>,
    /// The last line of Details: the server that wrote the notice
    pub details_note: String,
}

/// The longest the server's words are shown
const MAX_WORDS: usize = 4000;

/// The SVG of a picture: 20 by 20, strokes in the card's colour (the card's style sets them, a message's can not)
fn picture(picture: CardPicture) -> &'static str {
    match picture {
        // an @
        CardPicture::Address => {
            "<circle cx=\"10\" cy=\"10\" r=\"3.2\"/><path d=\"M13.2 7v4.1a2.2 2.2 0 0 0 4.4 0V10a7.6 7.6 0 1 0-3 6\"/>"
        }
        // a tray filled to the top
        CardPicture::Mailbox => {
            "<path d=\"M2.5 11.5h4l1.5 2.5h4l1.5-2.5h4\"/><path d=\"M5 3.5h10l2.5 8v5h-15v-5z\"/><path d=\"M6.5 6.5h7M6 9h8\"/>"
        }
        // a circle with a bar through it
        CardPicture::Block => "<circle cx=\"10\" cy=\"10\" r=\"7.5\"/><path d=\"M4.7 4.7l10.6 10.6\"/>",
        // a shield with an exclamation mark
        CardPicture::Spam => {
            "<path d=\"M10 2.5l6.5 2.5v5c0 3.9-2.8 6.9-6.5 7.5-3.7-.6-6.5-3.6-6.5-7.5V5z\"/><path d=\"M10 6.5v4.5M10 13.6v.2\"/>"
        }
        // two servers stacked
        CardPicture::Server => {
            "<rect x=\"3\" y=\"3.5\" width=\"14\" height=\"5.5\" rx=\"1.5\"/><rect x=\"3\" y=\"11\" width=\"14\" height=\"5.5\" rx=\"1.5\"/>\
             <path d=\"M6 6.25h.1M6 13.75h.1\"/>"
        }
        // a clock
        CardPicture::Clock => "<circle cx=\"10\" cy=\"10\" r=\"7.5\"/><path d=\"M10 5.5V10l3 2\"/>",
    }
}

/// The bounce card's own rules, beside those every card has ([`crate::card`]); `C` stands for its class
const RULES: &[(&str, &str)] = &[
    // a delayed reason in the card of a failure: its picture in the colours of a delay
    ("C .y", "--accent:#9a5b00;--disc:#fbecd0"),
    (
        "C .r",
        "display:flex;gap:10px;align-items:flex-start;margin:9px 0 0;padding:9px 0 1px;border-top:1px solid var(--line)",
    ),
    (
        "C .p",
        "display:flex;flex:0 0 auto;align-items:center;justify-content:center;width:30px;height:30px;\
         border-radius:50%;background:var(--disc);color:var(--accent)",
    ),
    ("C .b", "display:block;flex:1 1 auto;min-width:0"),
    ("C .a,C .t", "display:block;font-weight:600;color:#1f1f1f"),
    ("C .e", "display:block;color:#4d4d4d"),
    ("C .w,C .v", "display:block;margin:3px 0 0"),
    ("C .v b", "font-weight:600"),
    ("C .n", "display:block;margin:3px 0 0;color:#4d4d4d"),
    (
        "C details",
        "display:block;margin:8px 0 0;padding:6px 0 0;border-top:1px solid var(--line)",
    ),
    (
        "C summary",
        "display:list-item;cursor:pointer;color:#4d4d4d;font-weight:600",
    ),
    ("C .d", "display:block;margin:6px 0 0"),
    ("C .s", "display:block;color:#4d4d4d;font-size:9pt"),
    (
        "C pre",
        "display:block;margin:3px 0 0;padding:6px 8px;background:#fff;border:1px solid var(--line);border-radius:3px;\
         font:8.5pt/1.4 ui-monospace,Menlo,Consolas,monospace;color:#1f1f1f;white-space:pre-wrap;\
         overflow-wrap:anywhere;user-select:text",
    ),
];

/// A reason of the card, its picture beside its words
fn push_reason(out: &mut String, reason: &CardReason, advice_label: &str) {
    out.push_str(if reason.delayed {
        "<div class=\"r y\">"
    } else {
        "<div class=\"r\">"
    });
    if let Some(kind) = reason.picture {
        out.push_str(&format!(
            "<span class=\"p\"><svg viewBox=\"0 0 20 20\" aria-hidden=\"true\">{}</svg></span>",
            picture(kind)
        ));
    }
    out.push_str("<div class=\"b\">");
    out.push_str(&format!("<div class=\"t\">{}</div>", shown(&reason.title, MAX_VALUE)));
    if !reason.addresses.is_empty() {
        let addresses: Vec<String> = reason.addresses.iter().map(|a| shown(a, MAX_VALUE)).collect();
        out.push_str(&format!("<div class=\"e\">{}</div>", addresses.join(", ")));
    }
    out.push_str(&format!(
        "<div class=\"w\">{}</div><div class=\"v\"><b>{}</b> {}</div>",
        shown(&reason.why, MAX_VALUE),
        shown(advice_label, MAX_VALUE),
        shown(&reason.advice, MAX_VALUE),
    ));
    for note in &reason.notes {
        out.push_str(&format!("<div class=\"n\">{}</div>", shown(note, MAX_VALUE)));
    }
    out.push_str("</div></div>");
}

/// Details, folded: what the notice says of each recipient and the server that wrote it; nothing when it says none
fn push_details(out: &mut String, card: &BounceCard) {
    if card.details.is_empty() && card.details_note.is_empty() {
        return;
    }
    out.push_str(&format!(
        "<details><summary>{}</summary>",
        shown(&card.details_label, MAX_VALUE)
    ));
    for detail in &card.details {
        out.push_str("<div class=\"d\">");
        if !detail.address.is_empty() {
            out.push_str(&format!("<div class=\"a\">{}</div>", shown(&detail.address, MAX_VALUE)));
        }
        if !detail.lines.is_empty() {
            let lines: Vec<String> = detail.lines.iter().map(|l| shown(l, MAX_VALUE)).collect();
            out.push_str(&format!("<div class=\"s\">{}</div>", lines.join(" \u{b7} ")));
        }
        if !detail.words.is_empty() {
            out.push_str(&format!("<pre>{}</pre>", shown(&detail.words, MAX_WORDS)));
        }
        out.push_str("</div>");
    }
    if !card.details_note.is_empty() {
        out.push_str(&format!(
            "<div class=\"d s\">{}</div>",
            shown(&card.details_note, MAX_VALUE)
        ));
    }
    out.push_str("</details>");
}

/// The card as markup for the top of the reading pane's document, with its own style element
pub fn bounce_card(card: &BounceCard) -> String {
    let class = format!("pe-bounce-{}", nonce());
    let (tone, icon) = if card.delayed {
        (Tone::Delay, Icon::Clock)
    } else {
        (Tone::Failure, Icon::Envelope)
    };
    let mut out = style(&class, RULES);
    out.push_str(&open(&class, tone, icon, &card.heading));
    for line in &card.lines {
        out.push_str(&format!("<div class=\"l\">{}</div>", shown(line, MAX_VALUE)));
    }
    if let Some(link) = &card.link {
        out.push_str(&format!(
            "<div class=\"k\"><a href=\"{BOUNCED_MESSAGE_LINK}\">{}</a></div>",
            shown(link, MAX_VALUE)
        ));
    }
    for reason in &card.reasons {
        push_reason(&mut out, reason, &card.advice_label);
    }
    push_details(&mut out, card);
    out.push_str("</div>");
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{RenderOptions, render_view_with};

    fn card() -> BounceCard {
        BounceCard {
            delayed: false,
            heading: "Your message was not delivered".into(),
            lines: vec!["Subject: Hello".into()],
            link: Some("Show the message that bounced".into()),
            advice_label: "What you can do:".into(),
            reasons: vec![CardReason {
                picture: Some(CardPicture::Address),
                addresses: vec!["<b>x</b>@example.com".into()],
                title: "The address does not exist".into(),
                why: "No such mailbox.".into(),
                advice: "Check the spelling.".into(),
                notes: vec!["Blocklist: Spamhaus".into()],
                delayed: false,
            }],
            details_label: "Details".into(),
            details: vec![CardDetail {
                address: "user@example.com".into(),
                lines: vec!["Server: mx.example.com".into()],
                words: "550 <script>alert(1)</script> evil & \"quoted\"</pre></details><img src=x onerror=alert(2)>"
                    .into(),
            }],
            details_note: "Reported by: mta.example.com".into(),
        }
    }

    #[test]
    fn the_notice_is_escaped() {
        let html = bounce_card(&card());
        assert!(
            !html.contains("<script") && !html.contains("<img") && !html.contains("<b>x</b>"),
            "{html}"
        );
        assert!(html.contains("&lt;b&gt;x&lt;/b&gt;@example.com"), "{html}");
        assert!(
            html.contains("550 &lt;script&gt;alert(1)&lt;/script&gt; evil &amp; \"quoted\"&lt;/pre&gt;"),
            "{html}"
        );
        // only the card's own elements close
        assert_eq!(html.matches("</pre>").count(), 1);
        assert_eq!(html.matches("</details>").count(), 1);
        // the link of the bounced message, which the apps take
        assert!(html.contains(&format!(
            "<a href=\"{BOUNCED_MESSAGE_LINK}\">Show the message that bounced</a>"
        )));
        assert!(html.contains("<svg viewBox=\"0 0 20 20\""));
        let without = bounce_card(&BounceCard { link: None, ..card() });
        assert!(!without.contains("<a "));
    }

    #[test]
    fn a_delayed_reason_looks_like_a_delay() {
        let mut mixed = card();
        let mut later = mixed.reasons[0].clone();
        later.delayed = true;
        mixed.reasons.push(later);
        let html = bounce_card(&mixed);
        assert_eq!(html.matches("<div class=\"r\">").count(), 1, "{html}");
        assert_eq!(html.matches("<div class=\"r y\">").count(), 1, "{html}");
        assert!(html.contains(" .y{--accent:#9a5b00!important;"), "{html}");
    }

    #[test]
    fn long_values_are_cut() {
        let mut long = card();
        long.details[0].words = "x".repeat(MAX_WORDS + 50);
        long.reasons[0].addresses = vec!["a".repeat(MAX_VALUE * 3)];
        let html = bounce_card(&long);
        assert!(!html.contains(&"x".repeat(MAX_WORDS + 1)));
        assert!(html.contains(&format!("{}…", "x".repeat(MAX_WORDS))));
        assert!(!html.contains(&"a".repeat(MAX_VALUE + 1)));
    }

    #[test]
    fn its_rules_are_important_in_a_layer_of_its_own() {
        let html = bounce_card(&card());
        let class = html.split("<div class=\"").nth(1).unwrap().split(' ').next().unwrap();
        assert!(
            class.starts_with("pe-bounce-") && class.len() == "pe-bounce-".len() + 32,
            "{class}"
        );
        assert!(
            html.starts_with(&format!("<style>@layer {class}{{.{class},.{class} div")),
            "{html}"
        );
        // every declaration important
        let css = html.split("</style>").next().unwrap();
        for block in css.split('{').skip(2) {
            let declarations = block.split('}').next().unwrap();
            // (a selector of the print rules has no declaration of its own)
            for declaration in declarations
                .split(';')
                .filter(|d| d.contains(':') && !d.starts_with('.'))
            {
                assert!(declaration.ends_with("!important"), "{declaration}");
            }
        }
        // a delay looks like one
        let delayed = bounce_card(&BounceCard {
            delayed: true,
            ..card()
        });
        assert!(delayed.contains(" D\" role=\"note\""), "{delayed}");
    }

    #[test]
    fn the_document_keeps_its_csp_and_the_card_comes_first() {
        let rendered = render_view_with(
            "<style>div{display:none!important}</style><p>The original<script>bad()</script></p>",
            &RenderOptions::default(),
            &[],
            &[],
            Some(&card()),
        );
        let document = rendered.document;
        assert!(
            document
                .contains("content=\"default-src 'none'; img-src data:; style-src 'unsafe-inline'; font-src data:\""),
            "{document}"
        );
        // no script, and the CSP lets none run
        assert!(!document.contains("<script") && !document.contains("script-src"));
        let card_at = document.find("role=\"note\"").unwrap();
        let body_at = document.find("The original").unwrap();
        assert!(card_at < body_at);
        // the message's style element comes after the card's
        assert!(document.find("@layer pe-bounce-").unwrap() < document.find("div{display:none").unwrap());
    }

    #[test]
    fn knows_its_link() {
        assert!(is_bounced_message_link("inboxclassic:bounced-message"));
        assert!(is_bounced_message_link("INBOXCLASSIC:Bounced-Message/"));
        assert!(!is_bounced_message_link("https://inboxclassic.invalid/bounced-message"));
        assert!(!is_bounced_message_link("inboxclassic:bounced-message?x"));
    }
}
