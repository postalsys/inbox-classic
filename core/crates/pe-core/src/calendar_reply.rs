//! An attendee's answer to a calendar invitation (iTIP, RFC 5546 3.2.3): a `METHOD:REPLY` file for the first event of
//! an invitation, naming the user's own attendee line with their answer, for the organizer's calendar to take in.
//! Only the core writes one, from the invitation as it came; nothing of what an agent writes goes into it.

use crate::contentline::{Line, escape, folded, split, unfold};

/// What the user answers
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Response {
    Accept,
    Tentative,
    Decline,
}

impl Response {
    /// Its PARTSTAT
    pub(crate) fn partstat(self) -> &'static str {
        match self {
            Response::Accept => "ACCEPTED",
            Response::Tentative => "TENTATIVE",
            Response::Decline => "DECLINED",
        }
    }

    /// The user's status it gives, as an agent is told it (`accepted`)
    pub fn status(self) -> &'static str {
        match self {
            Response::Accept => "accepted",
            Response::Tentative => "tentative",
            Response::Decline => "declined",
        }
    }
}

/// The answer to an invitation, ready to send
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Reply {
    /// The event's UID
    pub uid: String,
    /// The organizer's address, whom the reply goes to
    pub organizer: String,
    /// The user's address the invitation names, which the reply goes from
    pub attendee: String,
    /// The iCalendar file, CRLF line breaks
    pub ics: String,
}

/// An address of a `mailto:` value
fn address(value: &str) -> String {
    let value = value.trim();
    value
        .get(..7)
        .filter(|p| p.eq_ignore_ascii_case("mailto:"))
        .map_or(value, |_| &value[7..])
        .trim()
        .to_string()
}

/// A parameter value as a content line writes it: quoted when it has what would end it
fn param_value(value: &str) -> String {
    let value: String = value.chars().filter(|c| !c.is_control() && *c != '"').collect();
    if value.contains([':', ';', ',']) {
        format!("\"{value}\"")
    } else {
        value
    }
}

/// The user's attendee line with `partstat`: its other parameters kept but RSVP, which a reply does not ask
fn attendee_line(params: &[(String, String)], value: &str, partstat: &str) -> String {
    let mut line = String::from("ATTENDEE");
    for (name, param) in params {
        if name != "PARTSTAT" && name != "RSVP" {
            line.push_str(&format!(";{name}={}", param_value(param)));
        }
    }
    line.push_str(&format!(";PARTSTAT={partstat}:{}", value.trim()));
    line
}

/// The lines of the first event of `calendar`, unfolded and taken apart, each with its text as written
fn first_event(calendar: &str) -> Vec<(Line, String)> {
    let mut event = Vec::new();
    let mut inside = false;
    for text in unfold(calendar) {
        let Some(line) = split(&text) else {
            continue;
        };
        match (line.0.as_str(), line.2.trim().to_ascii_uppercase().as_str()) {
            ("BEGIN", "VEVENT") if !inside => inside = true,
            ("END", "VEVENT") if inside => return event,
            // a component inside the event (an alarm) is not the event's
            ("BEGIN", _) if inside => return event,
            _ if inside => event.push((line, text)),
            _ => {}
        }
    }
    event
}

/// The UID of the first event of `calendar`
pub(crate) fn event_uid(calendar: &str) -> Option<String> {
    first_event(calendar)
        .into_iter()
        .find(|((name, _, _), _)| name == "UID")
        .map(|((_, _, value), _)| value.trim().to_string())
}

/// The answer `response` of the user (one of `own`, the account's addresses) to the first event of `calendar`, an
/// invitation, written at `now`. None when the event names no UID, no organizer, or none of `own` as an attendee.
pub(crate) fn reply(calendar: &str, own: &[String], response: Response, now: i64) -> Option<Reply> {
    let event = first_event(calendar);
    let find = |name: &str| event.iter().find(|((n, _, _), _)| n == name);
    let uid = find("UID")?.0.2.trim().to_string();
    let organizer = find("ORGANIZER")?;
    let attendee = event.iter().find_map(|((name, params, value), _)| {
        let mine = name == "ATTENDEE" && own.iter().any(|o| o.eq_ignore_ascii_case(&address(value)));
        mine.then(|| (attendee_line(params, value, response.partstat()), address(value)))
    })?;
    let stamp = pe_mime::date::DateTime::from_timestamp(now);
    let mut lines = vec![
        "BEGIN:VCALENDAR".to_string(),
        "PRODID:-//Inbox Classic//EN".into(),
        "VERSION:2.0".into(),
        "METHOD:REPLY".into(),
        "BEGIN:VEVENT".into(),
        format!("UID:{uid}"),
        format!(
            "DTSTAMP:{:04}{:02}{:02}T{:02}{:02}{:02}Z",
            stamp.year, stamp.month, stamp.day, stamp.hour, stamp.minute, stamp.second
        ),
    ];
    // as the invitation has them: which occurrence, which version, whose
    for name in ["RECURRENCE-ID", "SEQUENCE", "DTSTART", "DTEND"] {
        lines.extend(
            find(name)
                .filter(|((_, params, _), _)| plain_time(params))
                .map(|(_, text)| text.clone()),
        );
    }
    lines.push(organizer.1.clone());
    lines.push(attendee.0);
    if let Some(((_, _, summary), _)) = find("SUMMARY") {
        lines.push(format!("SUMMARY:{}", escape(&crate::contentline::unescape(summary))));
    }
    lines.extend(["END:VEVENT".into(), "END:VCALENDAR".into()]);
    Some(Reply {
        uid,
        organizer: address(&organizer.0.2),
        attendee: attendee.1,
        ics: lines.iter().map(|line| folded(line)).collect(),
    })
}

/// Whether a time's line can go without the time zones the invitation defines: one of no zone (UTC, a date or
/// floating), as the reply carries none
fn plain_time(params: &[(String, String)]) -> bool {
    !params.iter().any(|(name, _)| name == "TZID")
}

#[cfg(test)]
mod tests {
    use super::*;

    const INVITE: &str = "BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nUID:1@example.com\r\nSEQUENCE:2\r\n\
        SUMMARY:Team planning\\, Q1\r\nDTSTART;TZID=Europe/Tallinn:20260715T140000\r\nDTEND:20260715T120000Z\r\n\
        ORGANIZER;CN=\"Ann Example\":mailto:ann@example.com\r\n\
        ATTENDEE;CN=Bob;RSVP=TRUE;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT:mailto:Bob@Example.com\r\n\
        ATTENDEE:mailto:carol@example.com\r\nBEGIN:VALARM\r\nUID:alarm\r\nEND:VALARM\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n";

    #[test]
    fn answers_as_the_attendee_the_invitation_names() {
        let reply = reply(INVITE, &["bob@example.com".into()], Response::Decline, 1_783_000_000).unwrap();
        assert_eq!(reply.uid, "1@example.com");
        assert_eq!(reply.organizer, "ann@example.com");
        assert_eq!(reply.attendee, "Bob@Example.com");
        let ics = &crate::contentline::unfold(&reply.ics).join("\r\n");
        assert!(reply.ics.lines().all(|line| line.len() <= 76), "{}", reply.ics);
        assert!(
            ics.starts_with("BEGIN:VCALENDAR\r\n") && ics.ends_with("END:VCALENDAR"),
            "{ics}"
        );
        assert!(ics.contains("\r\nMETHOD:REPLY\r\n"), "{ics}");
        assert!(ics.contains("\r\nSEQUENCE:2\r\n"), "{ics}");
        assert!(
            ics.contains("ORGANIZER;CN=\"Ann Example\":mailto:ann@example.com"),
            "{ics}"
        );
        assert!(
            ics.contains("ATTENDEE;CN=Bob;ROLE=REQ-PARTICIPANT;PARTSTAT=DECLINED:mailto:Bob@Example.com"),
            "{ics}"
        );
        assert!(ics.contains("SUMMARY:Team planning\\, Q1\r\n"), "{ics}");
        // a time in a zone the reply does not carry is left out; one in UTC is kept; nothing of the alarm
        assert!(
            !ics.contains("DTSTART") && ics.contains("DTEND:20260715T120000Z"),
            "{ics}"
        );
        assert!(
            !ics.contains("carol") && !ics.contains("alarm") && !ics.contains("RSVP"),
            "{ics}"
        );
        // what is written is read back as the user's answer
        assert_eq!(
            crate::calendar::attendee_status(ics, &["bob@example.com".into()]).as_deref(),
            Some("declined")
        );
    }

    #[test]
    fn no_answer_without_the_user_or_the_organizer() {
        assert!(reply(INVITE, &["dave@example.com".into()], Response::Accept, 0).is_none());
        let no_organizer = INVITE.replace("ORGANIZER", "X-ORGANIZER");
        assert!(reply(&no_organizer, &["bob@example.com".into()], Response::Accept, 0).is_none());
        assert_eq!(Response::Tentative.status(), "tentative");
    }
}
