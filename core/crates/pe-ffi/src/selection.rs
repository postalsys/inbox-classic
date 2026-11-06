//! The messages selected in a list, through C: a `PeSelection` handle the windows fill from the positions of their
//! list (or one message at a time), what they are in numbers, the actions on all of them, and Edit > Undo.

use std::ffi::c_char;
use std::ptr::null_mut;

use pe_core::{Action, MessageRef, Summary};

use crate::core::{PeCore, PeSearch, PeSortField, handed, refused, search_of, take_back, with};
use crate::{guard, into_c_string};

/// Selected messages; free with `pe_selection_free`
#[derive(Default)]
pub struct PeSelection(Vec<MessageRef>);

/// An empty selection
#[unsafe(no_mangle)]
pub extern "C" fn pe_selection_new() -> *mut PeSelection {
    guard(|| handed(PeSelection::default())).unwrap_or(null_mut())
}

/// # Safety
/// `selection` must be NULL or a selection that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_free(selection: *mut PeSelection) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(selection) }
}

/// Empties it
///
/// # Safety
/// `selection` must be NULL or a live selection.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_clear(selection: *mut PeSelection) {
    // SAFETY: as the caller guarantees
    if let Some(selection) = unsafe { selection.as_mut() } {
        selection.0.clear();
    }
}

/// Adds the message `uid` of `folder`
///
/// # Safety
/// `selection` must be NULL or a live selection.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_add(selection: *mut PeSelection, folder: i64, uid: u64) {
    // SAFETY: as the caller guarantees
    if let Some(selection) = unsafe { selection.as_mut() } {
        selection.0.push(MessageRef { folder, uid });
    }
}

/// How many messages it has
///
/// # Safety
/// `selection` must be NULL or a live selection.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_count(selection: *const PeSelection) -> usize {
    // SAFETY: as the caller guarantees
    unsafe { selection.as_ref() }.map_or(0, |s| s.0.len())
}

/// Message `index` of it (in the list's order when it was filled from ranges); false past the end
///
/// # Safety
/// `selection` must be NULL or a live selection, `folder` and `uid` valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_get(
    selection: *const PeSelection,
    index: usize,
    folder: *mut i64,
    uid: *mut u64,
) -> bool {
    // SAFETY: as the caller guarantees
    let Some(at) = (unsafe { selection.as_ref() }).and_then(|s| s.0.get(index)) else {
        return false;
    };
    if folder.is_null() || uid.is_null() {
        return false;
    }
    // SAFETY: the caller gave valid pointers
    unsafe { (*folder, *uid) = (at.folder, at.uid) };
    true
}

/// Fills it with the messages at the positions `starts[i]` (included) to `ends[i]` (not) of the list `search` and
/// `sort` make, in place of what it had. A list selection is ranges of positions; the messages they are stay the same
/// when the list changes.
///
/// # Safety
/// `core` must be a live handle, `selection` a live selection, `search` a valid search, `starts` and `ends` NULL or
/// `count` values each.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_set_ranges(
    core: *const PeCore,
    selection: *mut PeSelection,
    search: *const PeSearch,
    sort: PeSortField,
    ascending: bool,
    starts: *const u64,
    ends: *const u64,
    count: usize,
) -> bool {
    // SAFETY: as the caller guarantees
    let Some(selection) = (unsafe { selection.as_mut() }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    let Some(search) = (unsafe { search_of(search) }) else {
        return false;
    };
    let ranges: Vec<(u64, u64)> = if count == 0 || starts.is_null() || ends.is_null() {
        Vec::new()
    } else {
        // SAFETY: the caller gave `count` values in each
        let (starts, ends) = unsafe {
            (
                std::slice::from_raw_parts(starts, count),
                std::slice::from_raw_parts(ends, count),
            )
        };
        starts.iter().copied().zip(ends.iter().copied()).collect()
    };
    let sort = crate::core::sort_of(sort, ascending);
    // SAFETY: as the caller guarantees
    let refs = unsafe { with(core, None, |core| core.refs_in_ranges(&search, sort, &ranges).ok()) };
    match refs {
        Some(refs) => {
            selection.0 = refs;
            true
        }
        None => false,
    }
}

/// Positions in a list; free with `pe_positions_free`
pub struct PePositions(Vec<u64>);

/// Where the selected messages are now in the list `search` and `sort` make, ascending, to select them again after it
/// changed; those no longer in it are left out. NULL on failure.
///
/// # Safety
/// `core` must be a live handle, `selection` a live selection, `search` a valid search.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_positions(
    core: *const PeCore,
    selection: *const PeSelection,
    search: *const PeSearch,
    sort: PeSortField,
    ascending: bool,
) -> *mut PePositions {
    // SAFETY: as the caller guarantees
    let Some(selection) = (unsafe { selection.as_ref() }) else {
        return null_mut();
    };
    // SAFETY: as the caller guarantees
    let Some(search) = (unsafe { search_of(search) }) else {
        return null_mut();
    };
    let sort = crate::core::sort_of(sort, ascending);
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.positions(&search, sort, &selection.0)
                .map_or(null_mut(), |found| handed(PePositions(found)))
        })
    }
}

/// # Safety
/// `positions` must be NULL or from `pe_selection_positions`, not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_positions_count(positions: *const PePositions) -> usize {
    // SAFETY: as the caller guarantees
    unsafe { positions.as_ref() }.map_or(0, |p| p.0.len())
}

/// Position `index`; 0 past the end
///
/// # Safety
/// `positions` must be NULL or from `pe_selection_positions`, not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_positions_get(positions: *const PePositions, index: usize) -> u64 {
    // SAFETY: as the caller guarantees
    unsafe { positions.as_ref() }
        .and_then(|p| p.0.get(index).copied())
        .unwrap_or(0)
}

/// # Safety
/// `positions` must be NULL or from `pe_selection_positions`, freed once.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_positions_free(positions: *mut PePositions) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(positions) }
}

/// The selected messages in numbers (those gone meanwhile are not counted)
#[repr(C)]
#[derive(Debug, Clone, Copy, Default)]
pub struct PeSelectionSummary {
    pub count: u64,
    pub unread: u64,
    pub flagged: u64,
    /// Every one is in a Junk folder: Mark as Not Junk applies, not Mark as Junk
    pub in_junk: bool,
    /// How many accounts and folders they are in
    pub accounts: u64,
    pub folders: u64,
    /// How many of them Delete removes for good
    pub for_good: u64,
}

impl From<&PeSelectionSummary> for Summary {
    fn from(s: &PeSelectionSummary) -> Self {
        Summary {
            count: s.count,
            unread: s.unread,
            flagged: s.flagged,
            in_junk: s.in_junk,
            accounts: s.accounts,
            folders: s.folders,
            for_good: s.for_good,
        }
    }
}

impl From<Summary> for PeSelectionSummary {
    fn from(s: Summary) -> Self {
        PeSelectionSummary {
            count: s.count,
            unread: s.unread,
            flagged: s.flagged,
            in_junk: s.in_junk,
            accounts: s.accounts,
            folders: s.folders,
            for_good: s.for_good,
        }
    }
}

/// Fills `summary`; false on failure
///
/// # Safety
/// `core` must be a live handle, `selection` a live selection, `summary` a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_summary(
    core: *const PeCore,
    selection: *const PeSelection,
    summary: *mut PeSelectionSummary,
) -> bool {
    // SAFETY: as the caller guarantees
    let Some(selection) = (unsafe { selection.as_ref() }) else {
        return false;
    };
    if summary.is_null() {
        return false;
    }
    // SAFETY: as the caller guarantees
    let Some(found) = (unsafe { with(core, None, |core| core.summary(&selection.0).ok()) }) else {
        return false;
    };
    // SAFETY: the caller gave a valid pointer
    unsafe { *summary = found.into() };
    true
}

/// The reading pane's page over several messages ("3 messages selected", "2 unread" under it), in the style of
/// `pe_reader_page`. Free with `pe_string_free`.
///
/// # Safety
/// `summary` must be a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_page(summary: *const PeSelectionSummary) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let Some(summary) = (unsafe { summary.as_ref() }) else {
        return null_mut();
    };
    guard(|| into_c_string(Summary::from(summary).page())).unwrap_or(null_mut())
}

/// What to ask before Delete when it removes some of the messages of `summary` for good, NULL when it removes none.
/// Free with `pe_string_free`.
///
/// # Safety
/// `summary` must be a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_delete_question(summary: *const PeSelectionSummary) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let Some(summary) = (unsafe { summary.as_ref() }) else {
        return null_mut();
    };
    guard(|| {
        Summary::from(summary)
            .delete_question()
            .map_or(null_mut(), into_c_string)
    })
    .unwrap_or(null_mut())
}

/// The Move or Copy window's words for the messages of `summary`: its title ("Move 3 Messages", `prompt` false) or
/// what it says over the folders ("Move the 3 selected messages to:", `prompt` true); `copy` for Copy to Folder. Free
/// with `pe_string_free`.
///
/// # Safety
/// `summary` must be a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_move_text(
    summary: *const PeSelectionSummary,
    copy: bool,
    prompt: bool,
) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let Some(summary) = (unsafe { summary.as_ref() }) else {
        return null_mut();
    };
    guard(|| {
        let summary = Summary::from(summary);
        into_c_string(if prompt {
            summary.move_prompt(copy)
        } else {
            summary.move_title(copy)
        })
    })
    .unwrap_or(null_mut())
}

/// Whether Flag flags the messages of `summary` (one is not flagged) or takes the flags away (all are), for the label
/// of the command
///
/// # Safety
/// `summary` must be a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_flags(summary: *const PeSelectionSummary) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { summary.as_ref() }.is_some_and(|s| Summary::from(s).flags())
}

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeAction {
    Read = 0,
    Unread = 1,
    Flag = 2,
    Unflag = 3,
    /// Flag them when one is not flagged, take the flags away when all are (`pe_selection_flags`)
    ToggleFlag = 9,
    Junk = 4,
    NotJunk = 5,
    /// Into Deleted Items, or for good (ask first: `pe_selection_delete_question`)
    Delete = 6,
    /// Into the folder `to`, of the same account or another (in the background then: `Transferring`)
    Move = 7,
    Copy = 8,
}

/// Does `action` to the selected messages, each folder's with one command: in the store now (`FolderChanged`), on the
/// server in the background. Returns what the status bar says ("Moved 3 messages to Archive"), or NULL with the
/// reason in `error` (NULL or a pointer to a string to free with `pe_string_free`). Free the text with
/// `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle, `selection` a live selection, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_act(
    core: *const PeCore,
    selection: *const PeSelection,
    action: PeAction,
    to: i64,
    error: *mut *mut c_char,
) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let refs = unsafe { selection.as_ref() }.map(|s| s.0.clone()).unwrap_or_default();
    let action = match action {
        PeAction::Read => Action::Read(true),
        PeAction::Unread => Action::Read(false),
        PeAction::Flag => Action::Flag(true),
        PeAction::Unflag => Action::Flag(false),
        PeAction::ToggleFlag => Action::ToggleFlag,
        PeAction::Junk => Action::Junk(true),
        PeAction::NotJunk => Action::Junk(false),
        PeAction::Delete => Action::Delete,
        PeAction::Move => Action::Move(to),
        PeAction::Copy => Action::Copy(to),
    };
    // SAFETY: as the caller guarantees
    let outcome = unsafe { with(core, Err(None), |core| core.act(&refs, action).map_err(Some)) };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the messages could not be changed") }.map_or(null_mut(), into_c_string)
}

/// The folders messages were moved or copied to last, newest first, for the Move and Copy window: up to `max` ids
/// written to `folders`; returns how many
///
/// # Safety
/// `core` must be a live handle, `folders` NULL or room for `max` ids.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_recent_targets(core: *const PeCore, folders: *mut i64, max: usize) -> usize {
    if folders.is_null() || max == 0 {
        return 0;
    }
    // SAFETY: as the caller guarantees
    let found = unsafe {
        with(core, Vec::new(), |core| {
            core.recent_targets(max as u64).unwrap_or_default()
        })
    };
    for (i, folder) in found.iter().take(max).enumerate() {
        // SAFETY: the caller gave room for `max`
        unsafe { *folders.add(i) = *folder };
    }
    found.len().min(max)
}

/// What Edit > Undo says, "Undo Move"; NULL when there is nothing to take back. Free with `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_undo_label(core: *const PeCore) -> *mut c_char {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.undo_label().map_or(null_mut(), into_c_string)
        })
    }
}

/// Takes back the last move, delete or junk. Returns what the status bar says, or NULL with the reason in `error` as
/// `pe_selection_act` does.
///
/// # Safety
/// `core` must be a live handle, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_undo(core: *const PeCore, error: *mut *mut c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let outcome = unsafe { with(core, Err(None), |core| core.undo().map_err(Some)) };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "nothing to undo") }.map_or(null_mut(), into_c_string)
}

/// Fills `selection` with the messages the last `pe_undo` brought back that are in their folders again, to select
/// them after the list reloads; empty while none is there yet. Forgotten once all are there. False on failure.
///
/// # Safety
/// `core` must be a live handle, `selection` a live selection.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_undo_restored(core: *const PeCore, selection: *mut PeSelection) -> bool {
    // SAFETY: as the caller guarantees
    let Some(selection) = (unsafe { selection.as_mut() }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    match unsafe { with(core, None, |core| core.restored().ok()) } {
        Some(found) => {
            selection.0 = found;
            true
        }
        None => false,
    }
}

/// The counts of a list in the status bar: "12 messages, 3 unread" for a folder, "12 found, 3 unread" for a search
/// (`searching`), with ", 2 selected" when more than one is. Free with `pe_string_free`.
#[unsafe(no_mangle)]
pub extern "C" fn pe_list_counts(total: u64, unread: u64, selected: u64, searching: bool) -> *mut c_char {
    guard(|| into_c_string(pe_core::list_counts(total, unread, selected, searching))).unwrap_or(null_mut())
}
