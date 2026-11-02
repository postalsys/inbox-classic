//! Dates of messages: the Date header (RFC 5322, with the obsolete forms mail software still
//! sends), as seconds since the Unix epoch, and the calendar arithmetic the IMAP and SMTP date
//! formats are built on.

/// Month names as dates write them
pub const MONTHS: [&str; 12] = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

/// Days since 1970-01-01 of a civil date (Howard Hinnant's algorithm)
pub fn days_from_civil(year: i64, month: u32, day: u32) -> i64 {
    let year = if month <= 2 { year - 1 } else { year };
    let era = year.div_euclid(400);
    let year_of_era = year - era * 400;
    let month = i64::from(month);
    let day_of_year = (153 * (if month > 2 { month - 3 } else { month + 9 }) + 2) / 5 + i64::from(day) - 1;
    let day_of_era = year_of_era * 365 + year_of_era / 4 - year_of_era / 100 + day_of_year;
    era * 146_097 + day_of_era - 719_468
}

/// The civil date of days since 1970-01-01
fn civil_from_days(days: i64) -> (i64, u32, u32) {
    let days = days + 719_468;
    let era = days.div_euclid(146_097);
    let day_of_era = days - era * 146_097;
    let year_of_era = (day_of_era - day_of_era / 1460 + day_of_era / 36_524 - day_of_era / 146_096) / 365;
    let day_of_year = day_of_era - (365 * year_of_era + year_of_era / 4 - year_of_era / 100);
    let mp = (5 * day_of_year + 2) / 153;
    let day = (day_of_year - (153 * mp + 2) / 5 + 1) as u32;
    let month = if mp < 10 { mp + 3 } else { mp - 9 } as u32;
    let year = year_of_era + era * 400 + i64::from(month <= 2);
    (year, month, day)
}

/// A timestamp in UTC
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DateTime {
    pub year: i64,
    /// 1 to 12
    pub month: u32,
    pub day: u32,
    pub hour: i64,
    pub minute: i64,
    pub second: i64,
}

impl DateTime {
    pub fn from_timestamp(timestamp: i64) -> Self {
        let (year, month, day) = civil_from_days(timestamp.div_euclid(86_400));
        let seconds = timestamp.rem_euclid(86_400);
        DateTime {
            year,
            month,
            day,
            hour: seconds / 3600,
            minute: seconds % 3600 / 60,
            second: seconds % 60,
        }
    }

    pub fn month_name(&self) -> &'static str {
        MONTHS[self.month as usize - 1]
    }
}

/// `2025-10-06T10:00:00.000Z`, the form JavaScript's `toISOString` gives
pub fn to_iso(timestamp: i64) -> String {
    let t = DateTime::from_timestamp(timestamp);
    format!(
        "{:04}-{:02}-{:02}T{:02}:{:02}:{:02}.000Z",
        t.year, t.month, t.day, t.hour, t.minute, t.second
    )
}

/// The number of a month name, `Oct` or `October`
pub fn month_number(name: &str) -> Option<u32> {
    let name = name.get(..3)?;
    MONTHS
        .iter()
        .position(|m| m.eq_ignore_ascii_case(name))
        .map(|i| i as u32 + 1)
}

/// `+0200`, `-0700`, `GMT`, `UT`, `Z`, `EST` ... in seconds east of UTC. Unknown zones are UTC,
/// as RFC 5322 section 4.3 says for military zones.
pub fn zone_offset(zone: &str) -> i64 {
    let sign = match zone.as_bytes().first() {
        Some(b'+') => 1,
        Some(b'-') => -1,
        _ => 0,
    };
    if sign != 0
        && let Some(digits) = zone.get(1..5)
        && let (Ok(hours), Ok(minutes)) = (digits[..2].parse::<i64>(), digits[2..].parse::<i64>())
    {
        return sign * (hours * 3600 + minutes * 60);
    }
    let hours = [
        ("EDT", -4),
        ("EST", -5),
        ("CDT", -5),
        ("CST", -6),
        ("MDT", -6),
        ("MST", -7),
        ("PDT", -7),
        ("PST", -8),
    ]
    .iter()
    .find(|(name, _)| zone.eq_ignore_ascii_case(name))
    .map_or(0, |(_, hours)| *hours);
    hours * 3600
}

/// `10:00` or `10:00:00` in seconds
pub fn parse_time(time: &str) -> Option<i64> {
    let mut fields = time.split(':');
    let hours: i64 = fields.next()?.parse().ok()?;
    let minutes: i64 = fields.next()?.parse().ok()?;
    let seconds: i64 = fields.next().map_or(Some(0), |s| s.parse().ok())?;
    if fields.next().is_some() || hours > 23 || minutes > 59 || seconds > 60 {
        return None;
    }
    Some(hours * 3600 + minutes * 60 + seconds)
}

/// Seconds since the Unix epoch of a date, a time of day in seconds and a zone offset
pub fn timestamp(year: i64, month: u32, day: u32, time: i64, offset: i64) -> Option<i64> {
    if !(1..=31).contains(&day) || !(1..=12).contains(&month) {
        return None;
    }
    Some(days_from_civil(year, month, day) * 86_400 + time - offset)
}

/// A Date header value: `Mon, 6 Oct 2025 10:00:00 +0000`, the day name optional, two and three
/// digit years (obsolete syntax), comments such as `(EEST)` ignored
pub fn parse_date(value: &str) -> Option<i64> {
    // comments, and the comma after the day name
    let mut clean = String::with_capacity(value.len());
    let mut depth = 0;
    for c in value.chars() {
        match c {
            '(' => depth += 1,
            ')' if depth > 0 => depth -= 1,
            _ if depth == 0 => clean.push(if c == ',' { ' ' } else { c }),
            _ => {}
        }
    }
    let mut fields: Vec<&str> = clean.split_whitespace().collect();
    if fields
        .first()
        .is_some_and(|f| f.chars().all(char::is_alphabetic) && month_number(f).is_none())
    {
        fields.remove(0);
    }
    let [day, month, year, time, rest @ ..] = fields.as_slice() else {
        return None;
    };
    let digits = year.chars().take_while(char::is_ascii_digit).count();
    let year: i64 = year.parse().ok()?;
    let year = match digits {
        2 if year < 50 => 2000 + year,
        2 | 3 => 1900 + year,
        _ => year,
    };
    let offset = rest.first().map_or(0, |zone| zone_offset(zone));
    timestamp(year, month_number(month)?, day.parse().ok()?, parse_time(time)?, offset)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_date_headers() {
        let expected = Some(1_759_744_800);
        assert_eq!(parse_date("Mon, 6 Oct 2025 10:00:00 +0000"), expected);
        assert_eq!(parse_date("6 Oct 2025 12:00:00 +0200"), expected);
        assert_eq!(parse_date("Mon, 06 Oct 2025 03:00:00 -0700 (PDT)"), expected);
        assert_eq!(parse_date("Mon, 6 Oct 2025 10:00 GMT"), expected);
        assert_eq!(parse_date("Mon,6 Oct 2025 06:00:00 EDT"), expected);
        assert_eq!(parse_date("Mon, 6 October 2025 10:00:00 Z"), expected);
        assert_eq!(
            parse_date("Thu, 23 Oct 03 23:28:34 -0700"),
            parse_date("Thu, 23 Oct 2003 23:28:34 -0700")
        );
        assert_eq!(
            parse_date("Thu, 23 Oct 99 23:28:34 -0700"),
            parse_date("Thu, 23 Oct 1999 23:28:34 -0700")
        );
        assert_eq!(parse_date("not a date"), None);
        assert_eq!(parse_date("Mon, 32 Oct 2025 10:00:00 +0000"), None);
        assert_eq!(parse_date("Mon, 6 Foo 2025 10:00:00 +0000"), None);
        assert_eq!(parse_date("Mon, 6 Oct 2025 25:00:00 +0000"), None);
    }

    #[test]
    fn calendar() {
        assert_eq!(to_iso(0), "1970-01-01T00:00:00.000Z");
        assert_eq!(to_iso(1_759_744_800), "2025-10-06T10:00:00.000Z");
        assert_eq!(to_iso(951_782_400), "2000-02-29T00:00:00.000Z");
        assert_eq!(to_iso(-86_400), "1969-12-31T00:00:00.000Z");
        assert_eq!(DateTime::from_timestamp(1_759_744_800).month_name(), "Oct");
        assert_eq!(month_number("oct"), Some(10));
        assert_eq!(zone_offset("+0530"), 19_800);
        assert_eq!(zone_offset("pst"), -28_800);
        assert_eq!(zone_offset("-07"), 0);
    }
}
