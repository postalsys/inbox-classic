//! The messages selected in a list, through C: a `PeSelection` handle the windows fill from the positions of their
//! list (or one message at a time), what they are in numbers, the actions on all of them, and Edit > Undo.

use std::ffi::c_char;
use std::ptr::null_mut;

use pe_core::{Action, MessageRef, Summary};

use crate::core::{PeCore, PeSearch, PeSortField, Rows, handed, refused, search_of, take_back, with};
use crate::{guard, into_c_string};

/// Selected messages; free with `pe_selection_free`
#[derive(Default)]
pub struct PeSelection(Vec<MessageRef>);

/// The messages of `selection`, none for NULL
///
/// # Safety
/// `selection` must be NULL or a live selection.
unsafe fn refs_of(selection: *const PeSelection) -> Vec<MessageRef> {
    // SAFETY: as the caller guarantees
    unsafe { selection.as_ref() }.map(|s| s.0.clone()).unwrap_or_default()
}

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
    let refs = unsafe { refs_of(selection) };
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

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeTargetKind {
    /// "Recent", over the folders used last
    Heading = 0,
    /// A folder used last, named with its account when there are several
    Recent = 1,
    /// An account, over its folders
    Account = 2,
    /// A folder of the account above it
    Folder = 3,
}

/// A row of the Move and Copy window; its strings belong to the list
#[repr(C)]
pub struct PeTarget {
    pub kind: PeTargetKind,
    pub account: i64,
    /// 0 for a heading or an account
    pub folder: i64,
    /// UTF-8: "Inbox (current)", "Archive (Work)"
    pub label: *const c_char,
    /// How deep under its account (0 for the account and the rows of Recent)
    pub depth: u32,
    /// UTF-8: its icon ("inbox", "sent", "drafts", "deleted", "junk", "archive", "" for a plain folder)
    pub icon: *const c_char,
    /// Messages can go there
    pub choosable: bool,
}

/// The rows of the Move and Copy window; free with `pe_target_list_free`
pub struct PeTargetList(Rows<PeTarget>);

/// The rows of the Move and Copy window for messages all in `current` (0 for messages of several folders), what
/// `filter` (UTF-8, NULL or empty for none) leaves of them: "Recent" and the folders used last while nothing is typed,
/// then every account with its folders, a folder that matches with those above it. NULL on failure.
///
/// # Safety
/// `core` must be a live handle, `filter` NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_move_targets(
    core: *const PeCore,
    current: i64,
    filter: *const c_char,
) -> *mut PeTargetList {
    // SAFETY: as the caller guarantees
    let filter = unsafe { crate::core::arg(filter) }.unwrap_or_default().to_string();
    let current = (current != 0).then_some(current);
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| match core.move_targets(current, &filter) {
            Ok(rows) => handed(PeTargetList(Rows::new(&rows, |row, strings| PeTarget {
                kind: match row.kind {
                    pe_core::TargetKind::Heading => PeTargetKind::Heading,
                    pe_core::TargetKind::Recent => PeTargetKind::Recent,
                    pe_core::TargetKind::Account => PeTargetKind::Account,
                    pe_core::TargetKind::Folder => PeTargetKind::Folder,
                },
                account: row.account,
                folder: row.folder,
                label: strings.add(&row.label),
                depth: row.depth,
                icon: strings.add(row.icon),
                choosable: row.choosable,
            }))),
            Err(_) => null_mut(),
        })
    }
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_target_list_count(list: *const PeTargetList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|l| &l.0))
}

/// Row `index`, NULL past the end
///
/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_target_list_get(list: *const PeTargetList, index: usize) -> *const PeTarget {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|l| &l.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet, freed once.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_target_list_free(list: *mut PeTargetList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
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

// ---- as files ----

/// Texts (file names, paths); free with `pe_text_list_free`
pub struct PeTextList {
    texts: Vec<std::ffi::CString>,
}

fn text_list(texts: impl IntoIterator<Item = String>) -> *mut PeTextList {
    handed(PeTextList {
        texts: texts.into_iter().map(crate::c_string).collect(),
    })
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_text_list_count(list: *const PeTextList) -> usize {
    // SAFETY: as the caller guarantees
    unsafe { list.as_ref() }.map_or(0, |l| l.texts.len())
}

/// Text `index` (UTF-8), valid until the list is freed; NULL past the end
///
/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_text_list_get(list: *const PeTextList, index: usize) -> *const c_char {
    // SAFETY: as the caller guarantees
    unsafe { list.as_ref() }
        .and_then(|l| l.texts.get(index))
        .map_or(std::ptr::null(), |t| t.as_ptr())
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet, freed once.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_text_list_free(list: *mut PeTextList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// The file names the selected messages get as `.eml` files, in order and different from each other ("Lunch.eml",
/// "Lunch (2).eml"), without downloading them; NULL on failure
///
/// # Safety
/// `core` must be a live handle, `selection` a live selection.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_file_names(
    core: *const PeCore,
    selection: *const PeSelection,
) -> *mut PeTextList {
    // SAFETY: as the caller guarantees
    let refs = unsafe { refs_of(selection) };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.export_names(&refs).map_or(null_mut(), text_list)
        })
    }
}

/// Whether every selected message is downloaded, so its file can be written at once
///
/// # Safety
/// `core` must be a live handle, `selection` a live selection.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_all_downloaded(core: *const PeCore, selection: *const PeSelection) -> bool {
    // SAFETY: as the caller guarantees
    let refs = unsafe { refs_of(selection) };
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.all_downloaded(&refs).unwrap_or(false)) }
}

/// The selected messages as files; free with `pe_export_free`
pub struct PeExport {
    files: Vec<(std::ffi::CString, std::result::Result<Vec<u8>, std::ffi::CString>)>,
}

/// The selected messages as files, downloading those not here yet, waiting at most `timeout_ms` for them. BLOCKS:
/// call it from a thread of its own (a drop's data thread, a file promise's queue), never the window thread. NULL
/// on failure.
///
/// # Safety
/// `core` must be a live handle, `selection` a live selection.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_export(
    core: *const PeCore,
    selection: *const PeSelection,
    timeout_ms: u64,
) -> *mut PeExport {
    // SAFETY: as the caller guarantees
    let refs = unsafe { refs_of(selection) };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            match core.export_messages(&refs, std::time::Duration::from_millis(timeout_ms)) {
                Ok(files) => handed(PeExport {
                    files: files
                        .into_iter()
                        .map(|f| (crate::c_string(f.name), f.source.map_err(crate::c_string)))
                        .collect(),
                }),
                Err(_) => null_mut(),
            }
        })
    }
}

/// # Safety
/// `export` must be NULL or from `pe_selection_export`, not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_export_count(export: *const PeExport) -> usize {
    // SAFETY: as the caller guarantees
    unsafe { export.as_ref() }.map_or(0, |e| e.files.len())
}

/// File `index`: its name, and its bytes (`data`, `len`) or why it could not be had (`error`, `data` NULL). All valid
/// until the export is freed. False past the end.
///
/// # Safety
/// `export` must be NULL or from `pe_selection_export`, not freed yet; the out pointers valid.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_export_get(
    export: *const PeExport,
    index: usize,
    name: *mut *const c_char,
    data: *mut *const u8,
    len: *mut usize,
    error: *mut *const c_char,
) -> bool {
    // SAFETY: as the caller guarantees
    let Some((file_name, source)) = (unsafe { export.as_ref() }).and_then(|e| e.files.get(index)) else {
        return false;
    };
    if name.is_null() || data.is_null() || len.is_null() || error.is_null() {
        return false;
    }
    // SAFETY: the caller gave valid pointers
    unsafe {
        *name = file_name.as_ptr();
        match source {
            Ok(bytes) => {
                *data = bytes.as_ptr();
                *len = bytes.len();
                *error = std::ptr::null();
            }
            Err(problem) => {
                *data = std::ptr::null();
                *len = 0;
                *error = problem.as_ptr();
            }
        }
    }
    true
}

/// # Safety
/// `export` must be NULL or from `pe_selection_export`, freed once.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_export_free(export: *mut PeExport) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(export) }
}

/// Writes the selected messages into the folder `dir` as `.eml` files, never over a file there, marked as from the
/// internet where the system has such a mark (Windows; the Mac app sets its own). Returns the paths written, or NULL
/// with the reason in `error` (free with `pe_string_free`). BLOCKS as `pe_selection_export` does.
///
/// # Safety
/// `core` must be a live handle, `selection` a live selection, `dir` a NUL-terminated string, `error` NULL or valid.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_save(
    core: *const PeCore,
    selection: *const PeSelection,
    dir: *const c_char,
    timeout_ms: u64,
    error: *mut *mut c_char,
) -> *mut PeTextList {
    // SAFETY: as the caller guarantees
    let refs = unsafe { refs_of(selection) };
    // SAFETY: as the caller guarantees
    let dir = unsafe { crate::core::arg(dir) }.unwrap_or_default().to_string();
    // SAFETY: as the caller guarantees
    let outcome = unsafe {
        with(core, Err(None), |core| {
            core.save_messages(
                &refs,
                std::path::Path::new(&dir),
                std::time::Duration::from_millis(timeout_ms),
            )
            .map_err(Some)
        })
    };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the messages could not be saved") }.map_or(null_mut(), |paths| {
        text_list(paths.into_iter().map(|p| p.to_string_lossy().into_owned()))
    })
}

/// A new message forwarding the selected messages as attached `.eml` files (written from the account of the first),
/// its subject the first one's with "Fw: "; free with `pe_draft_free`. NULL with the reason in `error` (free with
/// `pe_string_free`). BLOCKS as `pe_selection_export` does, while what is not downloaded comes.
///
/// # Safety
/// `core` must be a live handle, `selection` a live selection, `error` NULL or valid.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_forward(
    core: *const PeCore,
    selection: *const PeSelection,
    timeout_ms: u64,
    error: *mut *mut c_char,
) -> *mut crate::core::PeDraft {
    // SAFETY: as the caller guarantees
    let refs = unsafe { refs_of(selection) };
    // SAFETY: as the caller guarantees
    let outcome = unsafe {
        with(core, Err(None), |core| {
            core.forward_as_attachments(&refs, std::time::Duration::from_millis(timeout_ms))
                .map_err(Some)
        })
    };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the messages could not be forwarded") }
        .map_or(null_mut(), |draft| crate::core::draft_handle(&draft))
}

/// What the status bar says once `count` messages are saved as files into the folder `place` (its path, UTF-8), by
/// its name: "Saved 3 messages to Desktop". Free with `pe_string_free`.
///
/// # Safety
/// `place` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_saved_text(count: u64, place: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let place = unsafe { crate::core::arg(place) }.unwrap_or_default().to_string();
    guard(|| into_c_string(pe_core::saved_text(count, std::path::Path::new(&place)))).unwrap_or(null_mut())
}

/// The selected messages written as `.eml` files into a new folder of the user's own, for a drag onto the desktop or a
/// file window; their paths, or NULL with the reason in `error` (free with `pe_string_free`). BLOCKS as
/// `pe_selection_export` does.
///
/// # Safety
/// `core` must be a live handle, `selection` a live selection, `error` NULL or valid.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_selection_drag_files(
    core: *const PeCore,
    selection: *const PeSelection,
    timeout_ms: u64,
    error: *mut *mut c_char,
) -> *mut PeTextList {
    // SAFETY: as the caller guarantees
    let refs = unsafe { refs_of(selection) };
    // SAFETY: as the caller guarantees
    let outcome = unsafe {
        with(core, Err(None), |core| {
            core.drag_files(&refs, std::time::Duration::from_millis(timeout_ms))
                .map_err(Some)
        })
    };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the messages could not be written") }.map_or(null_mut(), |paths| {
        text_list(paths.into_iter().map(|p| p.to_string_lossy().into_owned()))
    })
}

/// Writes `len` bytes of `data` into the folder `dir` as `name` (made safe), or `name (2).eml` and so on, never over a
/// file there (marked as from the internet on Windows); the path written, or NULL with the reason in `error`. Free
/// with `pe_string_free`. For a file a drag promised into a folder the system chose.
///
/// # Safety
/// `dir` and `name` must be NUL-terminated strings, `data` `len` bytes, `error` NULL or valid.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_write_file(
    dir: *const c_char,
    name: *const c_char,
    data: *const u8,
    len: usize,
    error: *mut *mut c_char,
) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let (dir, name) = unsafe { (crate::core::arg(dir), crate::core::arg(name)) };
    let (Some(dir), Some(name)) = (dir, name) else {
        return null_mut();
    };
    if data.is_null() && len > 0 {
        return null_mut();
    }
    let content = if len == 0 {
        &[][..]
    } else {
        // SAFETY: the caller gave `len` bytes
        unsafe { std::slice::from_raw_parts(data, len) }
    };
    let outcome =
        guard(|| pe_core::write_file(std::path::Path::new(dir), name, content).map_err(Some)).unwrap_or(Err(None));
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the file could not be written") }
        .map_or(null_mut(), |path| into_c_string(path.to_string_lossy().into_owned()))
}

/// Whether `path` (UTF-8) is a message file the app takes when files are dropped on a folder (an `.eml`), to accept or
/// refuse a drop as the mouse moves
///
/// # Safety
/// `path` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_is_message_file(path: *const c_char) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { crate::core::arg(path) }.is_some_and(|p| pe_core::is_message_file(std::path::Path::new(p)))
}

/// Puts the message files of `paths` (`count` UTF-8 paths) into `folder`, as `pe_message_import` does each, those that
/// are not message files left out. True with what the status bar says in `said` ("Put 3 messages in Archive") and
/// what to tell the user in `report` (NULL when all went in); free both with `pe_string_free`. False on failure.
///
/// # Safety
/// `core` must be a live handle, `paths` `count` NUL-terminated strings, `said` and `report` NULL or valid.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_import_files(
    core: *const PeCore,
    folder: i64,
    paths: *const *const c_char,
    count: usize,
    said: *mut *mut c_char,
    report: *mut *mut c_char,
) -> bool {
    let list: Vec<std::path::PathBuf> = if paths.is_null() || count == 0 {
        Vec::new()
    } else {
        // SAFETY: the caller gave `count` strings
        unsafe { std::slice::from_raw_parts(paths, count) }
            .iter()
            // SAFETY: as the caller guarantees
            .filter_map(|p| unsafe { crate::core::arg(*p) }.map(std::path::PathBuf::from))
            .collect()
    };
    // SAFETY: as the caller guarantees
    match unsafe { with(core, None, |core| core.import_files(folder, &list).ok()) } {
        Some((status, problems)) => {
            if !said.is_null() {
                // SAFETY: the caller gave a valid pointer
                unsafe { *said = into_c_string(status) };
            }
            if !report.is_null() {
                // SAFETY: the caller gave a valid pointer
                unsafe { *report = problems.map_or(null_mut(), into_c_string) };
            }
            true
        }
        None => false,
    }
}

/// What the status bar says while `count` messages not downloaded yet come for files or a forward: "Downloading 3
/// messages...". Free with `pe_string_free`.
#[unsafe(no_mangle)]
pub extern "C" fn pe_downloading_text(count: u64) -> *mut c_char {
    guard(|| into_c_string(pe_core::downloading_text(count))).unwrap_or(null_mut())
}
