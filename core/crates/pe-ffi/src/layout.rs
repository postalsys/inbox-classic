//! The main window's layout and the list's short dates, decided by the core so the three apps agree
//! (`pe_core::layout`)

use crate::core::{PeSortField, sort_of};
use crate::guard;
use pe_core::layout::{DateStyle, Layout, LayoutMode};

/// View > Layout: what the user chose (only ever made by the apps)
#[allow(dead_code)]
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeLayoutMode {
    Automatic = 0,
    Classic = 1,
    Columns = 2,
}

/// What the window shows: the message list above the reading pane, or the two side by side
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeLayout {
    Classic = 0,
    Columns = 1,
}

/// How a row of the Columns list writes its date: the time, the weekday, the day and month, or the whole date, each
/// in the system's own format
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeDateStyle {
    Time = 0,
    Weekday = 1,
    DayMonth = 2,
    Full = 3,
}

/// The layout of a window `width` wide (96 DPI pixels, points or sp) that shows `current` now, for `mode`: Automatic
/// turns to Columns at 1320 and back to Classic below 1200; Columns chosen holds down to 900
#[unsafe(no_mangle)]
pub extern "C" fn pe_layout_for(mode: PeLayoutMode, width: u32, current: PeLayout) -> PeLayout {
    let mode = match mode {
        PeLayoutMode::Automatic => LayoutMode::Automatic,
        PeLayoutMode::Classic => LayoutMode::Classic,
        PeLayoutMode::Columns => LayoutMode::Columns,
    };
    let current = match current {
        PeLayout::Classic => Layout::Classic,
        PeLayout::Columns => Layout::Columns,
    };
    match guard(|| pe_core::layout::layout_for(mode, width, current)) {
        Some(Layout::Columns) => PeLayout::Columns,
        _ => PeLayout::Classic,
    }
}

/// How the Columns list writes `date` seen at `now` (seconds since the Unix epoch) in a time zone `offset` seconds east
/// of UTC
#[unsafe(no_mangle)]
pub extern "C" fn pe_date_style(date: i64, now: i64, offset: i64) -> PeDateStyle {
    match guard(|| pe_core::layout::date_style(date, now, offset)) {
        Some(DateStyle::Time) => PeDateStyle::Time,
        Some(DateStyle::Weekday) => PeDateStyle::Weekday,
        Some(DateStyle::DayMonth) => PeDateStyle::DayMonth,
        _ => PeDateStyle::Full,
    }
}

/// Whether a list newly sorted by `field` starts with the smallest first (names and subjects), or the newest and
/// largest (dates and sizes)
#[unsafe(no_mangle)]
pub extern "C" fn pe_sort_starts_ascending(field: PeSortField) -> bool {
    guard(|| pe_core::layout::sort_starts_ascending(sort_of(field, true).field)).unwrap_or(true)
}
