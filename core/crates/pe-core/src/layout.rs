//! The main window's layout, decided the same way by the three apps: Classic (the folders, then the message list
//! above the reading pane) or Columns (folders, list and message side by side). Automatic follows the window's width,
//! with a gap between the width that turns it to Columns and the one that turns it back, so dragging the window's edge
//! near the line does not flip the panes to and fro. Widths are in the platforms' own independent units (96 DPI pixels
//! on Windows, points on the Mac, sp on Linux). Also the list's short dates and which way a new sort starts.

/// What the user chose in View > Layout or Options
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum LayoutMode {
    #[default]
    Automatic,
    Classic,
    Columns,
}

/// What the window shows
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Layout {
    #[default]
    Classic,
    Columns,
}

/// Automatic turns to Columns at this width or wider
pub const COLUMNS_FROM: u32 = 1320;
/// and back to Classic below this one
pub const CLASSIC_BELOW: u32 = 1200;
/// Columns chosen holds down to this width; narrower, the window shows Classic without changing the choice
pub const COLUMNS_FLOOR: u32 = 900;

/// The layout of a window `width` wide that shows `current` now, for `mode`
pub fn layout_for(mode: LayoutMode, width: u32, current: Layout) -> Layout {
    match mode {
        LayoutMode::Classic => Layout::Classic,
        LayoutMode::Columns if width >= COLUMNS_FLOOR => Layout::Columns,
        LayoutMode::Columns => Layout::Classic,
        LayoutMode::Automatic if width >= COLUMNS_FROM => Layout::Columns,
        LayoutMode::Automatic if width < CLASSIC_BELOW => Layout::Classic,
        LayoutMode::Automatic => current,
    }
}

/// How a row of the Columns list writes its date, in the system's own formats
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DateStyle {
    /// Today's: the time
    Time,
    /// The last six days': the weekday
    Weekday,
    /// This year's: the day and month
    DayMonth,
    /// Older, or later than now: the whole date
    Full,
}

/// The style of `date` seen at `now`, both seconds since the Unix epoch, in a time zone `offset` seconds east of UTC
pub fn date_style(date: i64, now: i64, offset: i64) -> DateStyle {
    let day = |seconds: i64| (seconds + offset).div_euclid(86_400);
    let (then, today) = (day(date), day(now));
    if then > today {
        return DateStyle::Full;
    }
    if then == today {
        return DateStyle::Time;
    }
    if today - then < 7 {
        return DateStyle::Weekday;
    }
    if year_of_day(then) == year_of_day(today) {
        DateStyle::DayMonth
    } else {
        DateStyle::Full
    }
}

/// The year of a day counted from 1970-01-01 (the civil calendar)
fn year_of_day(days: i64) -> i64 {
    // Howard Hinnant's days_from_civil, backwards
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let month = if mp < 10 { mp + 3 } else { mp - 9 };
    yoe + era * 400 + i64::from(month <= 2)
}

/// Whether a list newly sorted by `field` starts with the smallest first: names and subjects A to Z, dates and sizes
/// the newest and largest first
pub fn sort_starts_ascending(field: pe_store::SortField) -> bool {
    !matches!(
        field,
        pe_store::SortField::Date | pe_store::SortField::Received | pe_store::SortField::Size
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn automatic_follows_the_width_with_a_gap() {
        let auto = |width, current| layout_for(LayoutMode::Automatic, width, current);
        assert_eq!(auto(1400, Layout::Classic), Layout::Columns);
        assert_eq!(auto(1320, Layout::Classic), Layout::Columns);
        // between the two: what it is
        assert_eq!(auto(1250, Layout::Classic), Layout::Classic);
        assert_eq!(auto(1250, Layout::Columns), Layout::Columns);
        assert_eq!(auto(1200, Layout::Columns), Layout::Columns);
        assert_eq!(auto(1199, Layout::Columns), Layout::Classic);
    }

    #[test]
    fn a_choice_holds() {
        assert_eq!(layout_for(LayoutMode::Classic, 2000, Layout::Columns), Layout::Classic);
        assert_eq!(layout_for(LayoutMode::Columns, 1000, Layout::Classic), Layout::Columns);
        assert_eq!(layout_for(LayoutMode::Columns, 900, Layout::Classic), Layout::Columns);
        // too narrow for three panes: Classic, the choice kept
        assert_eq!(layout_for(LayoutMode::Columns, 899, Layout::Columns), Layout::Classic);
    }

    #[test]
    fn short_dates() {
        // Friday 2026-11-13 15:00 UTC
        let now = 1_794_582_000;
        let hour = 3600;
        let day = 86_400;
        assert_eq!(date_style(now - hour, now, 0), DateStyle::Time);
        // midnight in the user's zone: two hours east, 01:00 local is still today, 23:00 the day before is not
        assert_eq!(
            date_style(now - 15 * hour + hour - 2 * hour, now, 2 * hour),
            DateStyle::Time
        );
        assert_eq!(
            date_style(now - 16 * hour - 2 * hour, now, 2 * hour),
            DateStyle::Weekday
        );
        assert_eq!(date_style(now - 6 * day, now, 0), DateStyle::Weekday);
        assert_eq!(date_style(now - 7 * day, now, 0), DateStyle::DayMonth);
        // 2026-01-01 12:00, and 2025-12-31 12:00
        assert_eq!(date_style(1_767_268_800, now, 0), DateStyle::DayMonth);
        assert_eq!(date_style(1_767_182_400, now, 0), DateStyle::Full);
        // a date to come
        assert_eq!(date_style(now + day, now, 0), DateStyle::Full);
    }

    #[test]
    fn years_of_days() {
        assert_eq!(year_of_day(0), 1970);
        assert_eq!(year_of_day(-1), 1969);
        // 2024-02-29, 2024-12-31, 2025-01-01
        assert_eq!(year_of_day(19_782), 2024);
        assert_eq!(year_of_day(20_088), 2024);
        assert_eq!(year_of_day(20_089), 2025);
    }

    #[test]
    fn sorts_start_their_way() {
        assert!(!sort_starts_ascending(pe_store::SortField::Date));
        assert!(!sort_starts_ascending(pe_store::SortField::Size));
        assert!(sort_starts_ascending(pe_store::SortField::From));
        assert!(sort_starts_ascending(pe_store::SortField::Subject));
    }
}
