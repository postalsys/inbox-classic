//! An attendee's answer to a calendar invitation (iTIP, RFC 5546 3.2.3): a `METHOD:REPLY` file for the first event of
//! an invitation, naming the user's own attendee line with their answer, for the organizer's calendar to take in.
//! Only the core writes one, from the invitation as it came; nothing of what an agent writes goes into it.

use crate::contentline::{Line, escape, folded, mailto_address, split, unescape, unfold};

/// What the user answers
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Response {
    Accept,
    Tentative,
    Decline,
}

impl Response {
    pub const ALL: [Response; 3] = [Response::Accept, Response::Tentative, Response::Decline];

    /// Its name, as an agent gives it and the catalogs select by (`accept`)
    pub fn name(self) -> &'static str {
        match self {
            Response::Accept => "accept",
            Response::Tentative => "tentative",
            Response::Decline => "decline",
        }
    }

    /// The one [`Response::name`] names
    pub fn from_name(name: &str) -> Option<Response> {
        Response::ALL.into_iter().find(|r| r.name() == name)
    }

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

/// A parameter value as a content line writes it: quoted when it has what would end it
fn param_value(value: &str) -> String {
    let value: String = value.chars().filter(|c| !c.is_control() && *c != '"').collect();
    if value.contains([':', ';', ',']) {
        format!("\"{value}\"")
    } else {
        value
    }
}

/// Whether a value read from an invitation can be written into the reply: no line break or other control character
/// (but tab), which a writer could turn into a line of its own
fn clean(value: &str) -> bool {
    !value.chars().any(|c| c.is_control() && c != '\t')
}

/// A parameter name as a content line may carry it: an iana-token or an x-name
fn param_name(name: &str) -> bool {
    !name.is_empty() && name.chars().all(|c| c.is_ascii_alphanumeric() || c == '-')
}

/// A content line written from its parts, never copied: `name`, the parameters of a proper name (each value quoted
/// when it must be), and `value`. None when the value or a parameter has a control character.
fn content_line(name: &str, params: &[(String, String)], value: &str) -> Option<String> {
    if !clean(value) || params.iter().any(|(_, v)| !clean(v)) {
        return None;
    }
    let mut line = name.to_string();
    for (key, param) in params.iter().filter(|(key, _)| param_name(key)) {
        line.push_str(&format!(";{key}={}", param_value(param)));
    }
    line.push(':');
    line.push_str(value.trim());
    Some(line)
}

/// The user's attendee line with `partstat`: its other parameters kept but RSVP, which a reply does not ask
fn attendee_line(params: &[(String, String)], value: &str, partstat: &str) -> Option<String> {
    let mut kept: Vec<(String, String)> = params
        .iter()
        .filter(|(name, _)| name != "PARTSTAT" && name != "RSVP")
        .cloned()
        .collect();
    kept.push(("PARTSTAT".into(), partstat.into()));
    content_line("ATTENDEE", &kept, value)
}

/// The lines of the first event of `calendar`, unfolded and taken apart
fn first_event(calendar: &str) -> Vec<Line> {
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
            _ if inside => event.push(line),
            _ => {}
        }
    }
    event
}

/// The UID of the first event of `calendar`
pub(crate) fn event_uid(calendar: &str) -> Option<String> {
    first_event(calendar)
        .into_iter()
        .find(|(name, _, _)| name == "UID")
        .map(|(_, _, value)| value.trim().to_string())
}

/// Why an invitation can not be answered, in a sentence for the agent
const NO_UID: &str = "The invitation's event has no UID.";
const NOT_INVITED: &str = "The invitation does not name this account's address as an attendee, or names no organizer.";
const MALFORMED: &str = "The invitation's calendar file has control characters in what an answer repeats.";

/// The answer `response` of the user (one of `own`, the account's addresses) to the first event of `calendar`, an
/// invitation, written at `now`. Every line of it is written from the values read, never copied, so nothing of the
/// invitation but those values reaches the organizer. Refused, with why, when the event names no UID, no organizer,
/// or none of `own` as an attendee, or when a value the answer repeats has a control character.
pub(crate) fn reply(calendar: &str, own: &[String], response: Response, now: i64) -> Result<Reply, &'static str> {
    let event = first_event(calendar);
    let find = |name: &str| event.iter().find(|(n, _, _)| n == name);
    let uid = find("UID").ok_or(NO_UID)?.2.trim().to_string();
    let (_, organizer_params, organizer) = find("ORGANIZER").ok_or(NOT_INVITED)?;
    let (attendee_value, attendee) = event
        .iter()
        .find_map(|(name, params, value)| {
            let address = mailto_address(value);
            let mine = name == "ATTENDEE" && own.iter().any(|o| o.eq_ignore_ascii_case(address));
            mine.then(|| (value, params, address.to_string()))
        })
        .map(|(value, params, address)| (attendee_line(params, value, response.partstat()), address))
        .ok_or(NOT_INVITED)?;
    let stamp = pe_mime::date::DateTime::from_timestamp(now);
    let mut lines = vec![
        "BEGIN:VCALENDAR".to_string(),
        "PRODID:-//Inbox Classic//EN".into(),
        "VERSION:2.0".into(),
        "METHOD:REPLY".into(),
        "BEGIN:VEVENT".into(),
        content_line("UID", &[], &uid).ok_or(MALFORMED)?,
        format!(
            "DTSTAMP:{:04}{:02}{:02}T{:02}{:02}{:02}Z",
            stamp.year, stamp.month, stamp.day, stamp.hour, stamp.minute, stamp.second
        ),
    ];
    // as the invitation has them: which occurrence, which version, whose
    for name in ["RECURRENCE-ID", "SEQUENCE", "DTSTART", "DTEND"] {
        if let Some((_, params, value)) = find(name).filter(|(_, params, _)| plain_time(params)) {
            lines.push(content_line(name, params, value).ok_or(MALFORMED)?);
        }
    }
    lines.push(content_line("ORGANIZER", organizer_params, organizer).ok_or(MALFORMED)?);
    lines.push(attendee_value.ok_or(MALFORMED)?);
    if let Some((_, _, summary)) = find("SUMMARY") {
        lines.push(format!("SUMMARY:{}", escape(&unescape(summary))));
    }
    lines.extend(["END:VEVENT".into(), "END:VCALENDAR".into()]);
    Ok(Reply {
        uid,
        organizer: mailto_address(organizer).to_string(),
        attendee,
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
        assert!(ics.contains("ORGANIZER;CN=Ann Example:mailto:ann@example.com"), "{ics}");
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
        assert_eq!(
            reply(INVITE, &["dave@example.com".into()], Response::Accept, 0),
            Err(NOT_INVITED)
        );
        let no_organizer = INVITE.replace("ORGANIZER", "X-ORGANIZER");
        assert_eq!(
            reply(&no_organizer, &["bob@example.com".into()], Response::Accept, 0),
            Err(NOT_INVITED)
        );
        let no_uid = INVITE.replace("UID:1@", "X-UID:1@");
        assert_eq!(
            reply(&no_uid, &["bob@example.com".into()], Response::Accept, 0),
            Err(NO_UID)
        );
        assert_eq!(Response::Tentative.status(), "tentative");
    }

    /// The lines of a reply as they go: each line of the file (CRLF breaks, the folds undone), none of them holding a
    /// CR or LF the message's writer could turn into a line of its own
    fn sent_lines(reply: &Reply) -> Vec<String> {
        let lines = crate::contentline::unfold(&reply.ics);
        let unfolded = reply.ics.replace("\r\n ", "");
        let raw: Vec<&str> = unfolded.trim_end_matches("\r\n").split("\r\n").collect();
        assert_eq!(lines, raw, "{:?}", reply.ics);
        assert!(lines.iter().all(|line| !line.contains(['\r', '\n'])));
        lines
    }

    /// A bare CR in a line of the invitation the reply repeats (base64 lets a sender write one) never becomes a line
    /// of the reply: the reply has exactly its own lines
    #[test]
    fn a_bare_cr_in_the_invitation_adds_no_line_to_the_reply() {
        const PLAIN: &str = "BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nUID:1@example.com\r\n\
            RECURRENCE-ID:20260715T120000Z\r\nSEQUENCE:2\r\nDTEND:20260715T130000Z\r\n\
            ORGANIZER:mailto:ann@example.com\r\nATTENDEE;PARTSTAT=NEEDS-ACTION:mailto:bob@example.com\r\n\
            END:VEVENT\r\nEND:VCALENDAR\r\n";
        let expected = [
            "BEGIN:VCALENDAR",
            "PRODID:-//Inbox Classic//EN",
            "VERSION:2.0",
            "METHOD:REPLY",
            "BEGIN:VEVENT",
            "UID:1@example.com",
            "DTSTAMP:19700101T000000Z",
            "RECURRENCE-ID:20260715T120000Z",
            "SEQUENCE:2",
            "DTEND:20260715T130000Z",
            "ORGANIZER:mailto:ann@example.com",
            "ATTENDEE;PARTSTAT=ACCEPTED:mailto:bob@example.com",
            "END:VEVENT",
            "END:VCALENDAR",
        ];
        let own = ["bob@example.com".to_string()];
        assert_eq!(sent_lines(&reply(PLAIN, &own, Response::Accept, 0).unwrap()), expected);
        let injected = "\rATTENDEE;PARTSTAT=DECLINED;DELEGATED-TO=\"mailto:eve@example.com\":mailto:carol@example.com\r\
                        COMMENT:injected\rUID:2@example.com";
        // the same, and the event ended early with another after it
        let split = format!("{injected}\rEND:VEVENT\rBEGIN:VEVENT\rUID:3@example.com");
        for line in [
            "UID:1@example.com",
            "RECURRENCE-ID:20260715T120000Z",
            "SEQUENCE:2",
            "DTEND:20260715T130000Z",
            "ORGANIZER:mailto:ann@example.com",
        ] {
            let calendar = PLAIN.replace(&format!("{line}\r\n"), &format!("{line}{injected}\r\n"));
            let answer = reply(&calendar, &own, Response::Accept, 0).unwrap();
            assert_eq!(sent_lines(&answer), expected, "{line}");
            assert!(
                !answer.ics.contains("eve") && !answer.ics.contains("injected"),
                "{line}"
            );
            assert_eq!(
                (answer.uid.as_str(), answer.organizer.as_str()),
                ("1@example.com", "ann@example.com")
            );
            // an event ended before the user's attendee is not answered; one ended after it is answered as it is
            let calendar = PLAIN.replace(&format!("{line}\r\n"), &format!("{line}{split}\r\n"));
            match reply(&calendar, &own, Response::Accept, 0) {
                Ok(answer) => assert!(
                    sent_lines(&answer).iter().all(|l| expected.contains(&l.as_str())),
                    "{line}"
                ),
                Err(why) => assert_eq!(why, NOT_INVITED, "{line}"),
            }
        }
    }

    /// Any other control character in a value the reply repeats refuses the invitation
    #[test]
    fn control_characters_refuse_the_answer() {
        let own = ["bob@example.com".to_string()];
        for (from, to) in [
            ("SEQUENCE:2", "SEQUENCE:2\u{b}X"),
            ("UID:1@example.com", "UID:1@example.com\u{0}"),
            ("CN=Bob;", "CN=B\u{c}ob;"),
            ("mailto:ann@example.com", "mailto:ann@example.com\u{1b}"),
        ] {
            assert_eq!(
                reply(&INVITE.replace(from, to), &own, Response::Accept, 0),
                Err(MALFORMED),
                "{to:?}"
            );
        }
        // a parameter of a name no content line has is left out
        let odd = INVITE.replace("CN=Bob;", "X\"A:B\"=1;CN=Bob;");
        let reply = reply(&odd, &own, Response::Accept, 0).unwrap();
        assert!(!reply.ics.contains("X\"A"), "{}", reply.ics);
    }
}
