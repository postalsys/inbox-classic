//! Calendar invitations (iCalendar, RFC 5545, as RFC 5546 sends them): what the reading pane says of the first
//! event of a message's `text/calendar` part. Times are instants (seconds since the Unix epoch) the window shows in
//! the reader's own time zone; a time zone the file defines (VTIMEZONE, with its yearly daylight-saving rules) is
//! applied here. A time without a zone the file defines is shown as written (`floating`).

/// What a calendar part asks of its reader
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Method {
    /// An invitation (REQUEST), or an event to add (PUBLISH, or none said)
    #[default]
    Request,
    /// An event changed since it was sent
    Update,
    /// The event will not take place (CANCEL, or STATUS:CANCELLED)
    Cancel,
    /// An answer of an attendee (REPLY)
    Reply,
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Invitation {
    pub method: Method,
    pub summary: String,
    pub start: Option<i64>,
    pub end: Option<i64>,
    /// Dates without times: `end` is the day after the last
    pub all_day: bool,
    /// The times are as written, in no zone the file defines: shown without converting them
    pub floating: bool,
    pub location: String,
    /// The organizer's name, or address
    pub organizer: String,
    pub attendees: usize,
    /// How it repeats, in words; empty for once
    pub repeats: String,
}

use crate::contentline::{Line, lines};

/// A TEXT value unescaped (RFC 5545 3.3.11)
fn text(value: &str) -> String {
    crate::contentline::unescape(value).trim().to_string()
}

fn param<'a>(params: &'a [(String, String)], name: &str) -> Option<&'a str> {
    params.iter().find(|(k, _)| k == name).map(|(_, v)| v.as_str())
}

/// Days since 1970-01-01 of a date; a month or day out of range counts for nothing
fn days(year: i64, month: i64, day: i64) -> i64 {
    let (Ok(month), Ok(day)) = (u32::try_from(month.clamp(1, 12)), u32::try_from(day.clamp(1, 31))) else {
        return 0;
    };
    pe_mime::date::days_from_civil(year.clamp(-9999, 9999), month, day)
}

/// `YYYYMMDD` or `YYYYMMDDTHHMMSS[Z]`: seconds of the wall time as if it were UTC, whether it is a date, and
/// whether it is UTC
fn date_time(value: &str) -> Option<(i64, bool, bool)> {
    let value = value.trim();
    let number = |range: std::ops::Range<usize>| value.get(range)?.parse::<i64>().ok();
    let date = days(number(0..4)?, number(4..6)?, number(6..8)?) * 86400;
    if value.len() == 8 {
        return Some((date, true, false));
    }
    if value.as_bytes().get(8) != Some(&b'T') {
        return None;
    }
    let time = number(9..11)? * 3600 + number(11..13)? * 60 + number(13..15)?;
    Some((date + time, false, value.ends_with('Z')))
}

/// A yearly daylight-saving rule of a VTIMEZONE: from the local time `at` of a day in a month on, `offset` seconds
/// from UTC
#[derive(Debug, Clone)]
struct Transition {
    /// The first time it applies, wall time as if UTC
    start: i64,
    /// `BYMONTH` and `BYDAY` (`-1SU`: the last Sunday), when it repeats every year
    rule: Option<(i64, i64, i64)>,
    offset: i64,
}

impl Transition {
    /// When it happens in `year`, wall time as if UTC
    fn in_year(&self, year: i64) -> Option<i64> {
        let time_of_day = self.start.rem_euclid(86400);
        let Some((month, week, weekday)) = self.rule else {
            return Some(self.start);
        };
        let first = days(year, month, 1);
        let next_month = if month == 12 {
            days(year + 1, 1, 1)
        } else {
            days(year, month + 1, 1)
        };
        // 1970-01-01 was a Thursday; weekdays from Sunday = 0
        let weekday_of = |day: i64| (day + 4).rem_euclid(7);
        let day = if week > 0 {
            first + (weekday - weekday_of(first)).rem_euclid(7) + (week - 1) * 7
        } else {
            let last = next_month - 1;
            last - (weekday_of(last) - weekday).rem_euclid(7) + (week + 1) * 7
        };
        (first..next_month).contains(&day).then_some(day * 86400 + time_of_day)
    }
}

/// `-1SU`, `2MO`, `SU` (the first)
fn by_day(value: &str) -> Option<(i64, i64)> {
    let value = value.split(',').next()?.trim();
    let split = value.len().checked_sub(2)?;
    // `get`, not slicing: a rule in another script has no byte boundary there
    let (week, day) = (value.get(..split)?, value.get(split..)?);
    let weekday = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"]
        .iter()
        .position(|d| *d == day)? as i64;
    let week = if week.is_empty() { 1 } else { week.parse().ok()? };
    Some((week, weekday))
}

fn offset(value: &str) -> Option<i64> {
    let value = value.trim();
    let sign = match value.as_bytes().first()? {
        b'+' => 1,
        b'-' => -1,
        _ => return None,
    };
    let hours: i64 = value.get(1..3)?.parse().ok()?;
    let minutes: i64 = value.get(3..5)?.parse().ok()?;
    Some(sign * (hours * 3600 + minutes * 60))
}

/// The UTC offset of a zone at a wall time: of the transition that came last before it
fn offset_at(transitions: &[Transition], wall: i64) -> Option<i64> {
    let year = (wall.div_euclid(86400) * 10000 / 3652425) + 1970;
    transitions
        .iter()
        .flat_map(|t| [year - 1, year, year + 1].map(|y| t.in_year(y).map(|at| (at, t.offset))))
        .flatten()
        .filter(|(at, _)| *at <= wall)
        .max_by_key(|(at, _)| *at)
        .map(|(_, offset)| offset)
}

/// A part of an RRULE (`FREQ`, `BYDAY`)
fn rule_part<'a>(rule: &'a str, name: &str) -> Option<&'a str> {
    rule.split(';')
        .filter_map(|p| p.split_once('='))
        .find(|(k, _)| k.eq_ignore_ascii_case(name))
        .map(|(_, v)| v)
}

fn repeats(rule: &str) -> String {
    use pe_i18n::{Text, tr, tr_args};
    let part = |name: &str| rule_part(rule, name).map(str::to_ascii_uppercase);
    let interval: u32 = part("INTERVAL").and_then(|i| i.parse().ok()).unwrap_or(1);
    let unit = match part("FREQ").as_deref() {
        Some("DAILY") => "day",
        Some("WEEKLY") => "week",
        Some("MONTHLY") => "month",
        Some("YEARLY") => "year",
        _ => return tr(Text::Repeats),
    };
    let mut words = tr_args(
        Text::RepeatsEvery,
        &[("unit", unit.into()), ("interval", interval.into())],
    );
    if let Some(days) = part("BYDAY").filter(|_| unit == "week") {
        let names: Vec<String> = days
            .split(',')
            .filter_map(|d| match d.trim() {
                "MO" => Some(Text::DayMonday),
                "TU" => Some(Text::DayTuesday),
                "WE" => Some(Text::DayWednesday),
                "TH" => Some(Text::DayThursday),
                "FR" => Some(Text::DayFriday),
                "SA" => Some(Text::DaySaturday),
                "SU" => Some(Text::DaySunday),
                _ => None,
            })
            .map(tr)
            .collect();
        if !names.is_empty() {
            let days = names.join(", ");
            words = tr_args(
                Text::RepeatsOn,
                &[("repeats", (&words).into()), ("days", (&days).into())],
            );
        }
    }
    if let Some(count) = part("COUNT") {
        // a number, so the language can choose "1 time" or "3 times"; as written when it is not one
        let count = match count.parse::<u64>() {
            Ok(n) => pe_i18n::Arg::from(n),
            Err(_) => (&count).into(),
        };
        words = tr_args(Text::RepeatsTimes, &[("repeats", (&words).into()), ("count", count)]);
    }
    words
}

/// The first event of a calendar part, with what its method asks; None when it has none
pub fn invitation(calendar: &str, method: Option<&str>) -> Option<Invitation> {
    let lines = lines(calendar);
    // the zones the file defines, by TZID
    let mut zones: Vec<(String, Vec<Transition>)> = Vec::new();
    let mut zone: Option<(String, Vec<Transition>)> = None;
    let mut part: Option<Transition> = None;
    let mut event: Option<Vec<&Line>> = None;
    let mut found = None;
    let mut calendar_method = method.map(|m| m.to_ascii_uppercase());
    for line in &lines {
        let (name, _, value) = line;
        match (name.as_str(), value.trim().to_ascii_uppercase().as_str()) {
            ("BEGIN", "VTIMEZONE") => zone = Some((String::new(), Vec::new())),
            ("END", "VTIMEZONE") => zones.extend(zone.take()),
            ("BEGIN", "STANDARD" | "DAYLIGHT") if zone.is_some() => {
                part = Some(Transition {
                    start: 0,
                    rule: None,
                    offset: 0,
                })
            }
            ("END", "STANDARD" | "DAYLIGHT") => {
                if let (Some(t), Some((_, list))) = (part.take(), zone.as_mut()) {
                    list.push(t);
                }
            }
            ("BEGIN", "VEVENT") if found.is_none() => event = Some(Vec::new()),
            ("END", "VEVENT") => found = found.or(event.take()),
            ("METHOD", m) if event.is_none() && calendar_method.is_none() => calendar_method = Some(m.to_string()),
            _ => {
                if let Some(t) = part.as_mut() {
                    match name.as_str() {
                        "DTSTART" => t.start = date_time(value).map_or(0, |(at, _, _)| at),
                        "TZOFFSETTO" => t.offset = offset(value).unwrap_or(0),
                        "RRULE" => {
                            let get = |key: &str| rule_part(value, key);
                            t.rule = match (
                                get("BYMONTH").and_then(|m| m.parse().ok()),
                                get("BYDAY").and_then(by_day),
                            ) {
                                (Some(month), Some((week, weekday))) => Some((month, week, weekday)),
                                _ => None,
                            };
                        }
                        _ => {}
                    }
                } else if let Some((id, _)) = zone.as_mut().filter(|_| name == "TZID") {
                    *id = value.trim().to_string();
                } else if let Some(event) = event.as_mut() {
                    event.push(line);
                }
            }
        }
    }
    let event = found?;
    let mut invitation = Invitation {
        method: match calendar_method.as_deref() {
            Some("CANCEL") => Method::Cancel,
            Some("REPLY") => Method::Reply,
            _ => Method::Request,
        },
        ..Default::default()
    };
    // an instant from a DTSTART or DTEND, in the zone it names
    let mut instant = |params: &[(String, String)], value: &str| -> Option<i64> {
        let (wall, date, utc) = date_time(value)?;
        if date {
            invitation.all_day = true;
            invitation.floating = true;
            return Some(wall);
        }
        if utc {
            return Some(wall);
        }
        let zone = param(params, "TZID").and_then(|id| zones.iter().find(|(z, _)| z == id));
        match zone.and_then(|(_, t)| offset_at(t, wall)) {
            Some(offset) => Some(wall - offset),
            None => {
                invitation.floating = true;
                Some(wall)
            }
        }
    };
    let mut duration = None;
    let mut sequence = 0;
    for (name, params, value) in event {
        match name.as_str() {
            "SUMMARY" => invitation.summary = text(value),
            "LOCATION" => invitation.location = text(value),
            "DTSTART" => invitation.start = instant(params, value),
            "DTEND" => invitation.end = instant(params, value),
            "DURATION" => duration = Some(value.as_str()),
            "ORGANIZER" => {
                let address = value.trim();
                let address = address
                    .get(..7)
                    .filter(|p| p.eq_ignore_ascii_case("mailto:"))
                    .map_or(address, |_| &address[7..]);
                invitation.organizer = param(params, "CN").map_or(address.to_string(), str::to_string);
            }
            "ATTENDEE" => invitation.attendees += 1,
            "RRULE" => invitation.repeats = repeats(value),
            "STATUS" if value.trim().eq_ignore_ascii_case("CANCELLED") => invitation.method = Method::Cancel,
            "SEQUENCE" => sequence = value.trim().parse().unwrap_or(0),
            _ => {}
        }
    }
    if invitation.method == Method::Request && sequence > 0 {
        invitation.method = Method::Update;
    }
    if invitation.end.is_none()
        && let (Some(start), Some(duration)) = (invitation.start, duration.and_then(seconds))
    {
        invitation.end = Some(start + duration);
    }
    Some(invitation)
}

/// A DURATION (`PT1H30M`, `P1D`) in seconds
fn seconds(value: &str) -> Option<i64> {
    let value = value.trim().strip_prefix('+').unwrap_or(value.trim());
    let value = value.strip_prefix('P')?;
    let (mut total, mut number) = (0i64, 0i64);
    for c in value.chars() {
        match c {
            '0'..='9' => number = number.checked_mul(10)?.checked_add(c.to_digit(10)? as i64)?,
            'W' => total = total.checked_add(std::mem::take(&mut number).checked_mul(7 * 86400)?)?,
            'D' => total = total.checked_add(std::mem::take(&mut number).checked_mul(86400)?)?,
            'H' => total = total.checked_add(std::mem::take(&mut number).checked_mul(3600)?)?,
            'M' => total = total.checked_add(std::mem::take(&mut number).checked_mul(60)?)?,
            'S' => total = total.checked_add(std::mem::take(&mut number))?,
            'T' => {}
            _ => return None,
        }
    }
    Some(total)
}

#[cfg(test)]
mod tests {
    use super::*;

    const INVITE: &str = "BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nBEGIN:VTIMEZONE\r\nTZID:Europe/Tallinn\r\n\
        BEGIN:DAYLIGHT\r\nTZOFFSETFROM:+0200\r\nTZOFFSETTO:+0300\r\nDTSTART:19700329T030000\r\nRRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU\r\nEND:DAYLIGHT\r\n\
        BEGIN:STANDARD\r\nTZOFFSETFROM:+0300\r\nTZOFFSETTO:+0200\r\nDTSTART:19701025T040000\r\nRRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU\r\nEND:STANDARD\r\n\
        END:VTIMEZONE\r\nBEGIN:VEVENT\r\nUID:1@example.com\r\nSUMMARY:Team planning\\, Q1\r\n\
        DTSTART;TZID=Europe/Tallinn:20260715T140000\r\nDTEND;TZID=Europe/Tallinn:20260715T150000\r\n\
        LOCATION:Room 2\r\nORGANIZER;CN=\"Ann Example\":mailto:ann@example.com\r\n\
        ATTENDEE;CN=Bob:mailto:bob@example.com\r\nATTENDEE:mailto:carol@example.com\r\n\
        RRULE:FREQ=WEEKLY;BYDAY=WE;COUNT=10\r\nDESCRIPTION:Bring the\\n numbers.\r\n which we have\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n";

    #[test]
    fn reads_an_invitation_in_its_time_zone() {
        let invitation = invitation(INVITE, None).unwrap();
        assert_eq!(invitation.method, Method::Request);
        assert_eq!(invitation.summary, "Team planning, Q1");
        // 14:00 in Tallinn in July is summer time, +03:00: 11:00 UTC
        assert_eq!(invitation.start, Some(days(2026, 7, 15) * 86400 + 11 * 3600));
        assert_eq!(invitation.end, Some(days(2026, 7, 15) * 86400 + 12 * 3600));
        assert!(!invitation.floating && !invitation.all_day);
        assert_eq!(
            (invitation.location.as_str(), invitation.organizer.as_str()),
            ("Room 2", "Ann Example")
        );
        assert_eq!(invitation.attendees, 2);
        assert_eq!(invitation.repeats, "Every week on Wednesday, 10 times");
        // a folded line, and an escaped line break
        assert_eq!(
            text("Bring the\\n numbers.which we have"),
            "Bring the\n numbers.which we have"
        );
        // in winter the zone is +02:00
        let winter = INVITE
            .replace("20260715T140000", "20260115T140000")
            .replace("20260715T150000", "20260115T150000");
        assert_eq!(
            super::invitation(&winter, None).unwrap().start,
            Some(days(2026, 1, 15) * 86400 + 12 * 3600)
        );
    }

    #[test]
    fn says_what_it_asks() {
        let cancel = INVITE.replace("METHOD:REQUEST", "METHOD:CANCEL");
        assert_eq!(invitation(&cancel, None).unwrap().method, Method::Cancel);
        // the part's own method counts first
        assert_eq!(invitation(INVITE, Some("reply")).unwrap().method, Method::Reply);
        let update = INVITE.replace("UID:1@example.com", "UID:1@example.com\r\nSEQUENCE:2");
        assert_eq!(invitation(&update, None).unwrap().method, Method::Update);
        let cancelled = INVITE.replace("UID:1@example.com", "UID:1@example.com\r\nSTATUS:CANCELLED");
        assert_eq!(invitation(&cancelled, None).unwrap().method, Method::Cancel);
    }

    #[test]
    fn reads_days_utc_and_floating_times() {
        let day = "BEGIN:VEVENT\nSUMMARY:Holiday\nDTSTART;VALUE=DATE:20261224\nDTEND;VALUE=DATE:20261227\nEND:VEVENT";
        let holiday = invitation(day, None).unwrap();
        assert!(holiday.all_day && holiday.floating);
        assert_eq!(holiday.end.unwrap() - holiday.start.unwrap(), 3 * 86400);
        let utc = "BEGIN:VEVENT\nDTSTART:20260101T090000Z\nDURATION:PT1H30M\nEND:VEVENT";
        let call = invitation(utc, None).unwrap();
        assert_eq!(call.start, Some(days(2026, 1, 1) * 86400 + 9 * 3600));
        assert_eq!(call.end, Some(days(2026, 1, 1) * 86400 + 10 * 3600 + 1800));
        assert!(!call.floating);
        // a zone the file does not define: as written
        let unknown = "BEGIN:VEVENT\nDTSTART;TZID=W. Europe Standard Time:20260101T090000\nEND:VEVENT";
        assert!(invitation(unknown, None).unwrap().floating);
        // no event, or broken lines: nothing, or what could be read
        assert_eq!(invitation("BEGIN:VCALENDAR\nEND:VCALENDAR", None), None);
        let broken = invitation("BEGIN:VEVENT\nDTSTART:2026\nnonsense\nSUMMARY:x\nEND:VEVENT", None).unwrap();
        assert_eq!((broken.start, broken.summary.as_str()), (None, "x"));
        // what a hostile file could write is read without a panic: huge durations, rules in other scripts
        let hostile = "BEGIN:VTIMEZONE\nTZID:z\nBEGIN:STANDARD\nDTSTART:19700101T000000\nTZOFFSETTO:+0100\n\
                       RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=\u{d5}\u{d5}\nEND:STANDARD\nEND:VTIMEZONE\nBEGIN:VEVENT\n\
                       DTSTART;TZID=z:20260101T090000\nDURATION:P99999999999999999999W\nSUMMARY:\u{f5}\nEND:VEVENT";
        let read = invitation(hostile, None).unwrap();
        assert!(read.end.is_none());
        assert_eq!(seconds("P9999999999999999999D"), None);
    }
}

// ---- the event's card ----

/// What the platform words of an instant: its day, or its time of day
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InstantPart {
    /// The day, in full: "Tuesday, 1 December 2026"
    Date,
    /// The time of day, short: "12:00"
    Time,
}

/// Words an instant (seconds since the Unix epoch) as the platform does, in the reader's time zone, or as written when
/// `floating` (in no zone: the seconds are the written time read as UTC)
type InstantFormat = std::sync::Arc<dyn Fn(i64, bool, InstantPart) -> String + Send + Sync>;

static INSTANT_FORMAT: std::sync::RwLock<Option<InstantFormat>> = std::sync::RwLock::new(None);

/// How the event cards word their days and times: the app's own words for a date and a time, in the reader's locale and
/// time zone. Set once as the app starts; without it the cards say UTC dates and times as ISO 8601 has them.
pub fn set_instant_format(format: impl Fn(i64, bool, InstantPart) -> String + Send + Sync + 'static) {
    if let Ok(mut slot) = INSTANT_FORMAT.write() {
        *slot = Some(std::sync::Arc::new(format));
    }
}

/// An instant in words, the platform's or ISO 8601's
fn instant(seconds: i64, floating: bool, part: InstantPart) -> String {
    let format = INSTANT_FORMAT.read().ok().and_then(|slot| slot.clone());
    match format {
        Some(format) => format(seconds, floating, part),
        None => iso_instant(seconds, part),
    }
}

/// A moment as the reader's day and time: "Tuesday, 1 December 2026, 12:00" (the Sent line of a quoted message)
pub(crate) fn local_date_time(seconds: i64) -> String {
    format!(
        "{}, {}",
        instant(seconds, false, InstantPart::Date),
        instant(seconds, false, InstantPart::Time)
    )
}

/// `2026-12-01` or `12:00`, in UTC
fn iso_instant(seconds: i64, part: InstantPart) -> String {
    let (days, rest) = (seconds.div_euclid(86400), seconds.rem_euclid(86400));
    match part {
        InstantPart::Time => format!("{:02}:{:02}", rest / 3600, rest % 3600 / 60),
        InstantPart::Date => {
            // days since 1970-01-01 to a civil date (Howard Hinnant's algorithm)
            let z = days + 719_468;
            let era = z.div_euclid(146_097);
            let doe = z.rem_euclid(146_097);
            let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365;
            let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
            let mp = (5 * doy + 2) / 153;
            let day = doy - (153 * mp + 2) / 5 + 1;
            let month = if mp < 10 { mp + 3 } else { mp - 9 };
            let year = yoe + era * 400 + i64::from(month <= 2);
            format!("{year:04}-{month:02}-{day:02}")
        }
    }
}

/// When an event is, in words: its day (or days) and times, as the reader's local time or as written (floating)
pub(crate) fn when(event: &Invitation) -> String {
    use pe_i18n::{Text, tr_args};
    let Some(start) = event.start else {
        return String::new();
    };
    let date = |s| instant(s, event.floating, InstantPart::Date);
    let time = |s| instant(s, event.floating, InstantPart::Time);
    // the last day of an all-day event is the day before its end
    let end = event.end.map(|end| if event.all_day { end - 86400 } else { end });
    let span = |start: String, end: String| {
        tr_args(
            Text::UiEventSpan,
            &[("start", start.as_str().into()), ("end", end.as_str().into())],
        )
    };
    if event.all_day {
        return match end.map(date) {
            Some(last) if last != date(start) => span(date(start), last),
            _ => date(start),
        };
    }
    let mut said = format!("{}, {}", date(start), time(start));
    if let Some(end) = end {
        let until = if date(end) == date(start) {
            time(end)
        } else {
            format!("{}, {}", date(end), time(end))
        };
        said = span(said, until);
    }
    if event.floating {
        tr_args(Text::UiEventFloating, &[("when", said.as_str().into())])
    } else {
        said
    }
}

/// The card of an event, its words from the catalog
pub(crate) fn card(event: &Invitation) -> pe_html::EventCard {
    use pe_i18n::{Text, tr, tr_args};
    let kind = match event.method {
        Method::Request => Text::UiInvitation,
        Method::Update => Text::UiInvitationUpdated,
        Method::Cancel => Text::UiInvitationCanceled,
        Method::Reply => Text::UiInvitationAnswer,
    };
    let title = if event.summary.is_empty() {
        tr(Text::UiNoTitle)
    } else {
        event.summary.clone()
    };
    let mut details = vec![event.location.clone()];
    if !event.organizer.is_empty() {
        details.push(tr_args(Text::UiOrganizer, &[("name", event.organizer.as_str().into())]));
    }
    details.push(event.repeats.clone());
    if event.attendees > 0 {
        details.push(tr_args(
            Text::EventAttendees,
            &[("count", (event.attendees as i64).into())],
        ));
    }
    pe_html::EventCard {
        heading: tr_args(kind, &[("title", title.as_str().into())]),
        when: when(event),
        details,
        open: tr(Text::UiOpenInCalendar),
        canceled: event.method == Method::Cancel,
    }
}

#[cfg(test)]
mod card_tests {
    use super::*;

    fn event() -> Invitation {
        Invitation {
            method: Method::Request,
            summary: "Quarterly planning".into(),
            // 2025-12-01 12:00 to 13:30 UTC
            start: Some(1_764_590_400),
            end: Some(1_764_595_800),
            location: "Room 2".into(),
            organizer: "Ann Example".into(),
            attendees: 3,
            repeats: String::new(),
            ..Default::default()
        }
    }

    #[test]
    fn the_card_of_an_invitation() {
        let card = card(&event());
        assert_eq!(card.heading, "Invitation: Quarterly planning");
        assert_eq!(card.when, "2025-12-01, 12:00 to 13:30");
        assert_eq!(card.details, ["Room 2", "Organizer: Ann Example", "", "3 attendees"]);
        assert!(!card.canceled);
        let canceled = super::card(&Invitation {
            method: Method::Cancel,
            summary: String::new(),
            ..event()
        });
        assert!(
            canceled.canceled && canceled.heading == "Canceled: (no title)",
            "{}",
            canceled.heading
        );
    }

    #[test]
    fn days_and_spans() {
        assert_eq!(iso_instant(0, InstantPart::Date), "1970-01-01");
        assert_eq!(iso_instant(951_782_400, InstantPart::Date), "2000-02-29");
        assert_eq!(iso_instant(-86_400, InstantPart::Date), "1969-12-31");
        // an all-day event of one day (its end the next midnight), and of three
        let day = Invitation {
            all_day: true,
            start: Some(1_764_547_200),
            end: Some(1_764_633_600),
            ..event()
        };
        assert_eq!(when(&day), "2025-12-01");
        assert_eq!(
            when(&Invitation {
                end: Some(1_764_806_400),
                ..day
            }),
            "2025-12-01 to 2025-12-03"
        );
        // over midnight, and as written
        let late = Invitation {
            end: Some(1_764_633_600 + 3600),
            floating: true,
            ..event()
        };
        assert_eq!(
            when(&late),
            "2025-12-01, 12:00 to 2025-12-02, 01:00 (the sender's time)"
        );
    }
}
