//! Dates of messages: the Date header (RFC 5322, with the obsolete forms mail software still
//! sends) and IMAP INTERNALDATE (`17-Jul-1996 02:44:25 -0700`), as seconds since the Unix epoch.

const MONTHS: [&str; 12] = [
    "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec",
];

/// Days since 1970-01-01 of a civil date (Howard Hinnant's algorithm)
fn days_from_civil(year: i64, month: u32, day: u32) -> i64 {
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

/// `2025-10-06T10:00:00.000Z`, the form JavaScript's `toISOString` gives
pub fn to_iso(timestamp: i64) -> String {
    let (year, month, day) = civil_from_days(timestamp.div_euclid(86_400));
    let seconds = timestamp.rem_euclid(86_400);
    format!(
        "{year:04}-{month:02}-{day:02}T{:02}:{:02}:{:02}.000Z",
        seconds / 3600,
        seconds % 3600 / 60,
        seconds % 60
    )
}

fn month_number(name: &str) -> Option<u32> {
    let name = name.get(..3)?.to_ascii_lowercase();
    MONTHS.iter().position(|m| *m == name).map(|i| i as u32 + 1)
}

/// `+0200`, `-0700`, `GMT`, `UT`, `Z`, `EST` ... in seconds east of UTC. Unknown zones are UTC,
/// as RFC 5322 section 4.3 says for military zones.
fn zone_offset(zone: &str) -> i64 {
    let bytes = zone.as_bytes();
    if let (Some(sign @ (b'+' | b'-')), true) = (bytes.first(), zone.len() >= 5) {
        let digits = &zone[1..5];
        if let (Ok(hours), Ok(minutes)) = (digits[..2].parse::<i64>(), digits[2..].parse::<i64>()) {
            let offset = hours * 3600 + minutes * 60;
            return if *sign == b'-' { -offset } else { offset };
        }
    }
    let hours = match zone.to_ascii_uppercase().as_str() {
        "EDT" => -4,
        "EST" | "CDT" => -5,
        "CST" | "MDT" => -6,
        "MST" | "PDT" => -7,
        "PST" => -8,
        _ => 0,
    };
    hours * 3600
}

/// `10:00` or `10:00:00`
fn parse_time(time: &str) -> Option<i64> {
    let mut fields = time.split(':');
    let hours: i64 = fields.next()?.parse().ok()?;
    let minutes: i64 = fields.next()?.parse().ok()?;
    let seconds: i64 = fields.next().map_or(Some(0), |s| s.parse().ok())?;
    if fields.next().is_some() || hours > 23 || minutes > 59 || seconds > 60 {
        return None;
    }
    Some(hours * 3600 + minutes * 60 + seconds)
}

fn timestamp(year: i64, month: u32, day: u32, time: i64, offset: i64) -> Option<i64> {
    if !(1..=31).contains(&day) {
        return None;
    }
    Some(days_from_civil(year, month, day) * 86_400 + time - offset)
}

/// A Date header value: `Mon, 6 Oct 2025 10:00:00 +0000`, the day name optional, two and three
/// digit years (obsolete syntax), comments such as `(EEST)` ignored
pub fn parse_date(value: &str) -> Option<i64> {
    // comments, and the day name with its comma
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
    let day: u32 = day.parse().ok()?;
    let month = month_number(month)?;
    let year: i64 = year.parse().ok()?;
    let year = match (year, year_digits(fields[2])) {
        (y, 2) if y < 50 => 2000 + y,
        (y, 2 | 3) => 1900 + y,
        (y, _) => y,
    };
    let offset = rest.first().map_or(0, |zone| zone_offset(zone));
    timestamp(year, month, day, parse_time(time)?, offset)
}

fn year_digits(field: &str) -> usize {
    field.chars().take_while(char::is_ascii_digit).count()
}

/// An IMAP date-time, `17-Jul-1996 02:44:25 -0700` (the day can be space padded)
pub fn parse_internal_date(value: &str) -> Option<i64> {
    let value = value.trim();
    let (date, rest) = value.split_once(' ')?;
    let mut parts = date.split('-');
    let (day, month, year) = (parts.next()?, parts.next()?, parts.next()?);
    let mut rest = rest.split_whitespace();
    let time = parse_time(rest.next()?)?;
    let offset = zone_offset(rest.next()?);
    timestamp(
        year.parse().ok()?,
        month_number(month)?,
        day.trim().parse().ok()?,
        time,
        offset,
    )
}

/// A timestamp as an IMAP date-time in UTC, for APPEND and SEARCH
pub fn format_internal_date(timestamp: i64) -> String {
    let (year, month, day) = civil_from_days(timestamp.div_euclid(86_400));
    let seconds = timestamp.rem_euclid(86_400);
    let month = MONTHS[month as usize - 1];
    let month = format!("{}{}", month[..1].to_ascii_uppercase(), &month[1..]);
    format!(
        "{day:02}-{month}-{year:04} {:02}:{:02}:{:02} +0000",
        seconds / 3600,
        seconds % 3600 / 60,
        seconds % 60
    )
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
    fn internal_dates() {
        assert_eq!(parse_internal_date("17-Jul-1996 02:44:25 -0700"), Some(837_596_665));
        assert_eq!(parse_internal_date(" 6-Oct-2025 10:00:00 +0000"), Some(1_759_744_800));
        assert_eq!(format_internal_date(1_759_744_800), "06-Oct-2025 10:00:00 +0000");
        assert_eq!(
            parse_internal_date(&format_internal_date(837_596_665)),
            Some(837_596_665)
        );
        assert_eq!(parse_internal_date("17-Jul-1996"), None);
    }

    #[test]
    fn iso_dates() {
        assert_eq!(to_iso(0), "1970-01-01T00:00:00.000Z");
        assert_eq!(to_iso(1_759_744_800), "2025-10-06T10:00:00.000Z");
        assert_eq!(to_iso(951_782_400), "2000-02-29T00:00:00.000Z");
        assert_eq!(to_iso(-86_400), "1969-12-31T00:00:00.000Z");
    }
}
