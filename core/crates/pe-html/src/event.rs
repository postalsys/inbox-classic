//! The card at the top of a message with a calendar event (an invitation, an update, a cancellation, an answer): its
//! title, when it is, where, who organizes it and how it repeats, and Open in Calendar. The core fills an
//! [`EventCard`] with words of the catalog and the event's values (its times in the words of the platform, which the
//! app gives); this writes it in the frame every card of the app has ([`crate::card`]). Open in Calendar is a link the
//! apps take ([`OPEN_CALENDAR_LINK`]): they write the event to a file and open it in the calendar app.

use crate::card::{Icon, MAX_VALUE, Tone, button, is_link, open, shown, style};
use crate::editor::nonce;

/// The link of the card's Open in Calendar, which the apps take. It is no URL a message can carry: the sanitizer
/// keeps only http(s), mailto, cid and data links.
pub const OPEN_CALENDAR_LINK: &str = "inboxclassic:open-calendar";

/// Whether a link clicked in the reading pane is the card's [`OPEN_CALENDAR_LINK`]
pub fn is_open_calendar_link(uri: &str) -> bool {
    is_link(uri, OPEN_CALENDAR_LINK)
}

/// What the card says, its words from the catalog
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct EventCard {
    /// "Invitation: Quarterly planning"
    pub heading: String,
    /// When it is, in words: "Tuesday, 1 December 2026, 12:00 to 13:30"
    pub when: String,
    /// Where, who organizes it, how it repeats, how many are invited: shown in a line, the empty ones left out
    pub details: Vec<String>,
    /// The words of the Open in Calendar button
    pub open: String,
    /// The event will not take place: drawn as a cancellation
    pub canceled: bool,
}

/// The event card's own rules: when it is in the words' own colour
const RULES: &[(&str, &str)] = &[("C .m", "font-weight:600")];

/// The card as markup for the top of the reading pane's document, with its own style element
pub fn event_card(card: &EventCard) -> String {
    let class = format!("pe-event-{}", nonce());
    let tone = if card.canceled { Tone::Delay } else { Tone::Info };
    let mut out = style(&class, RULES);
    out.push_str(&open(&class, tone, Icon::Calendar, &card.heading));
    if !card.when.is_empty() {
        out.push_str(&format!("<div class=\"m\">{}</div>", shown(&card.when, MAX_VALUE)));
    }
    let details: Vec<String> = card
        .details
        .iter()
        .filter(|d| !d.trim().is_empty())
        .map(|d| shown(d, MAX_VALUE))
        .collect();
    if !details.is_empty() {
        out.push_str(&format!("<div class=\"l\">{}</div>", details.join(" \u{b7} ")));
    }
    out.push_str(&format!(
        "<div class=\"x\">{}</div></div>",
        button(OPEN_CALENDAR_LINK, &card.open)
    ));
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn card() -> EventCard {
        EventCard {
            heading: "Invitation: Quarterly planning".into(),
            when: "Tuesday, 1 December 2026, 12:00 to 13:30".into(),
            details: vec!["Room 2".into(), "".into(), "Organizer: Ann <ann@example.com>".into()],
            open: "Open in Calendar".into(),
            canceled: false,
        }
    }

    #[test]
    fn the_card_says_when_and_where() {
        let markup = event_card(&card());
        assert!(markup.contains("Invitation: Quarterly planning"));
        assert!(markup.contains("<div class=\"m\">Tuesday, 1 December 2026, 12:00 to 13:30</div>"));
        // the empty detail left out, the others escaped and joined
        assert!(
            markup.contains("Room 2 \u{b7} Organizer: Ann &lt;ann@example.com&gt;"),
            "{markup}"
        );
        assert!(markup.contains(&format!("href=\"{OPEN_CALENDAR_LINK}\"")));
        assert!(markup.contains(" I\" role=\"note\""));
        assert!(!markup.contains("<script"));
    }

    #[test]
    fn a_cancellation_is_amber() {
        let markup = event_card(&EventCard {
            canceled: true,
            ..card()
        });
        assert!(markup.contains(" D\" role=\"note\""), "{markup}");
    }

    #[test]
    fn calendar_links() {
        assert!(is_open_calendar_link("inboxclassic:open-calendar/"));
        assert!(!is_open_calendar_link("inboxclassic:open-calendars"));
    }
}
