//! The date formats of IMAP: INTERNALDATE date-times (`17-Jul-1996 02:44:25 -0700`) and the dates
//! of SEARCH (`17-Jul-1996`).

use pe_mime::date::{DateTime, month_number, parse_time, timestamp, zone_offset};

/// An IMAP date-time in seconds since the Unix epoch (the day can be space padded)
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

/// A timestamp as an IMAP date-time in UTC, for APPEND
pub fn format_internal_date(timestamp: i64) -> String {
    let t = DateTime::from_timestamp(timestamp);
    format!(
        "{} {:02}:{:02}:{:02} +0000",
        format_search_date(timestamp),
        t.hour,
        t.minute,
        t.second
    )
}

/// The UTC day of a timestamp as SEARCH writes dates, `06-Oct-2025`
pub fn format_search_date(timestamp: i64) -> String {
    let t = DateTime::from_timestamp(timestamp);
    format!("{:02}-{}-{:04}", t.day, t.month_name(), t.year)
}

#[cfg(test)]
mod tests {
    use super::*;

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
        assert_eq!(format_search_date(1_759_744_800), "06-Oct-2025");
    }
}
