//! A message list's view through C: a `PeListView` handle owning what the list shows (the folder, All Inboxes or
//! none, the words searched for, what is shown, the order, grouped by conversation or not, ignored conversations
//! hidden or not) and which conversations are open, with the list's calls (a page of rows, the counts, where a message
//! is, Previous and Next, Next Unread, the selection's ranges) reading it. The windows change it as the user does and
//! keep nothing of the list's state themselves.

use std::ffi::c_char;
use std::ptr::null_mut;

use pe_core::{ListView, Summary};

use crate::core::{
    PeCore, PeMessageList, PeNextUnread, PeShow, PeSortField, arg, handed, message_list, put_neighbours,
    put_next_unread, sort_of, take_back, with, with_shared,
};
use crate::guard;
use crate::selection::{PeAction, PePositions, PeSelection, PeSelectionSummary, action_of, ranges_of};

/// What a message list shows; free with `pe_list_view_free`
pub struct PeListView(ListView);

/// How long the changes to the list shown are gathered before it is read again (a sync writes many in a row), in
/// milliseconds; when the timer runs out, `pe_list_view_stale` says whether the list needs reading at all
pub const PE_LIST_GATHER_MS: u32 = 300;
/// How long a folder chosen waits for its list before the list says "Loading...", in milliseconds, counted from the
/// first click of the wait (later clicks while it waits do not start it again)
pub const PE_LIST_LOADING_MS: u32 = 400;
/// How long the Address Book's find boxes wait after the last key before they search, in milliseconds
pub const PE_FIND_PAUSE_MS: u32 = 150;
/// How strongly the window's colour covers the rows of the list shown while the list of a folder chosen waits
/// (the rows show through at 45 percent)
pub const PE_LIST_DIM: f64 = 0.55;

// the same as the core's, which the Linux app reads (cbindgen writes literals only)
const _: () = assert!(
    PE_LIST_GATHER_MS == pe_core::LIST_GATHER_MS
        && PE_LIST_LOADING_MS == pe_core::LIST_LOADING_MS
        && PE_FIND_PAUSE_MS == pe_core::FIND_PAUSE_MS
        && PE_LIST_DIM == pe_core::LIST_DIM
);

/// Reads the view, `fallback` for NULL or a panic
///
/// # Safety
/// `view` must be NULL or a live view.
unsafe fn read<T>(view: *const PeListView, fallback: T, f: impl FnOnce(&ListView) -> T) -> T {
    // SAFETY: as the caller guarantees
    match unsafe { view.as_ref() } {
        Some(view) => guard(|| f(&view.0)).unwrap_or(fallback),
        None => fallback,
    }
}

/// Changes the view, `fallback` for NULL or a panic
///
/// # Safety
/// `view` must be NULL or a live view.
unsafe fn change<T>(view: *mut PeListView, fallback: T, f: impl FnOnce(&mut ListView) -> T) -> T {
    // SAFETY: as the caller guarantees
    match unsafe { view.as_mut() } {
        Some(view) => guard(|| f(&mut view.0)).unwrap_or(fallback),
        None => fallback,
    }
}

/// Reads the view with the core, `fallback` for NULL or a panic
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view.
unsafe fn listed<T>(
    core: *const PeCore,
    view: *const PeListView,
    fallback: T,
    f: impl FnOnce(&pe_core::Core, &ListView) -> T,
) -> T {
    // SAFETY: as the caller guarantees
    let Some(view) = (unsafe { view.as_ref() }) else {
        return fallback;
    };
    // SAFETY: as the caller guarantees
    unsafe { with(core, fallback, |core| f(core, &view.0)) }
}

/// A new view: no folder (it lists nothing until one is set), every message shown, newest first by Date, one row a
/// message, ignored conversations shown. NULL on failure.
#[unsafe(no_mangle)]
pub extern "C" fn pe_list_view_new() -> *mut PeListView {
    guard(|| handed(PeListView(ListView::new()))).unwrap_or(null_mut())
}

/// A copy of `view`, its open conversations too: what a message window goes through (with
/// `pe_list_view_set_grouped` false, one message at a time). NULL for NULL or on failure.
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_clone(view: *const PeListView) -> *mut PeListView {
    // SAFETY: as the caller guarantees
    unsafe { read(view, null_mut(), |view| handed(PeListView(view.clone()))) }
}

/// # Safety
/// `view` must be NULL or a view that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_free(view: *mut PeListView) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(view) }
}

/// The list of a row of the folder list (`PeTreeRow` `list` and `folder`): its folder's, All Inboxes', All Sent's,
/// All Drafts' or Flagged's, or none (a heading, which lists nothing without words). Every conversation is closed when
/// it is another one. False when it was the one shown already (or for NULL).
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_set_list(
    view: *mut PeListView,
    list: crate::core::PeTreeList,
    folder: i64,
) -> bool {
    let scope = pe_core::tree::TreeList::from(list).scope(folder);
    // SAFETY: as the caller guarantees
    unsafe { change(view, false, |view| view.set_scope(scope)) }
}

/// The words typed in the Find box (UTF-8, NULL or empty for none), in Gmail's syntax: words, "phrases", -word, OR,
/// from: to: subject: filename: is:unread is:starred has:attachment in: before: after: older_than: newer_than: larger:
/// smaller:. With words the list is of every folder of every account (`in:` narrows that). Every conversation is
/// closed when they change. False when they are the same (or for NULL).
///
/// # Safety
/// `view` must be NULL or a live view, `text` NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_set_text(view: *mut PeListView, text: *const c_char) -> bool {
    // SAFETY: as the caller guarantees
    let text = unsafe { arg(text) }.unwrap_or_default();
    // SAFETY: as the caller guarantees
    unsafe { change(view, false, |view| view.set_text(text)) }
}

/// Which messages are shown, whatever words are searched for
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_set_show(view: *mut PeListView, show: PeShow) {
    // SAFETY: as the caller guarantees
    unsafe { change(view, (), |view| view.set_show(show.into())) }
}

/// The order of the list (a From sort is by the recipients where `pe_list_view_lists_recipients`)
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_set_sort(view: *mut PeListView, sort: PeSortField, ascending: bool) {
    // SAFETY: as the caller guarantees
    unsafe { change(view, (), |view| view.set_sort(sort_of(sort, ascending))) }
}

/// One row a conversation (`grouped`, `PeMessage.thread` says each row's place) or one a message. Every conversation
/// is closed when it changes. False when it was so already (or for NULL).
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_set_grouped(view: *mut PeListView, grouped: bool) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { change(view, false, |view| view.set_grouped(grouped)) }
}

/// View > Hide Ignored Conversations: the messages of ignored conversations left out. The open conversations stay
/// open.
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_set_hide_ignored(view: *mut PeListView, hide: bool) {
    // SAFETY: as the caller guarantees
    unsafe { change(view, (), |view| view.set_hide_ignored(hide)) }
}

/// Whether words are searched for: the list is then of every folder (its Folder column shown)
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_searching(view: *const PeListView) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { read(view, false, ListView::searching) }
}

/// Whether the list has messages of several folders: a search (its Folder column) or All Inboxes (its Account
/// column)
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_several_folders(view: *const PeListView) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { read(view, false, ListView::several_folders) }
}

/// Whether it lists one folder of every account (All Inboxes, All Sent, All Drafts, no words): its place column is
/// Account, not Folder, and names the account alone; a message shown from elsewhere that is in it stays in it
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_gathers_accounts(view: *const PeListView) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { read(view, false, ListView::gathers_accounts) }
}

/// The folder it lists without words, for Empty Folder, Import Messages and files dropped on the list; 0 for a list
/// of several folders
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_own_folder(view: *const PeListView) -> i64 {
    // SAFETY: as the caller guarantees
    unsafe { read(view, 0, |view| view.own_folder().unwrap_or(0)) }
}

/// Whether Mark All Read applies to it: a folder's list or All Inboxes, without words
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_marks_all_read(view: *const PeListView) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { read(view, false, ListView::marks_all_read) }
}

/// Whether the list lists anything: a folder, All Inboxes or words; not an account's own item. Expand All and
/// Collapse All apply to a grouped list that does.
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_active(view: *const PeListView) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { read(view, false, ListView::active) }
}

/// Whether the list is grouped by conversation
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_grouped(view: *const PeListView) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { read(view, false, ListView::grouped) }
}

/// Whether the conversation `thread` is open
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_is_expanded(view: *const PeListView, thread: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { read(view, false, |view| view.is_expanded(thread)) }
}

/// Opens the conversation `thread` when it is closed and closes it when it is open (the + and - of its row, Right and
/// Left on it); whether it is open now. A list not grouped opens none.
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_toggle(view: *mut PeListView, thread: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { change(view, false, |view| view.toggle(thread)) }
}

/// Opens the conversation `thread`; false when it was open or the list is not grouped (the list is the same)
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_expand(view: *mut PeListView, thread: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { change(view, false, |view| view.expand(thread)) }
}

/// Closes the conversation `thread`; false when it was not open (the list is the same)
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_collapse(view: *mut PeListView, thread: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { change(view, false, |view| view.collapse(thread)) }
}

/// View > Collapse All Conversations; false when none was open
///
/// # Safety
/// `view` must be NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_collapse_all(view: *mut PeListView) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { change(view, false, ListView::collapse_all) }
}

/// View > Expand All Conversations: every conversation of the list with more than one message there opened. False
/// when that changed nothing, the list is not grouped, or on failure.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_expand_all(core: *const PeCore, view: *mut PeListView) -> bool {
    // SAFETY: as the caller guarantees
    let Some(view) = (unsafe { view.as_mut() }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| view.0.expand_all(core).unwrap_or(false)) }
}

/// The message `uid` of `folder` given a row of its own when it is hidden in a collapsed conversation (Next Unread and
/// Show Message find those): its conversation opened. True when one was opened and the list changed; false when the
/// message has its own row already, is not in the list, or on failure.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_reveal(
    core: *const PeCore,
    view: *mut PeListView,
    folder: i64,
    uid: u64,
) -> bool {
    // SAFETY: as the caller guarantees
    let Some(view) = (unsafe { view.as_mut() }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| view.0.reveal(core, folder, uid).unwrap_or(false)) }
}

/// `limit` rows of the list from `offset` on, in its order. NULL on failure; an empty list when it lists nothing.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_messages(
    core: *const PeCore,
    view: *const PeListView,
    offset: u64,
    limit: u64,
) -> *mut PeMessageList {
    // SAFETY: as the caller guarantees
    unsafe {
        listed(core, view, null_mut(), |core, view| {
            view.rows(core, offset, limit)
                .map_or(null_mut(), |messages| message_list(&messages))
        })
    }
}

/// How many rows the list has (its size): grouped, one a conversation and under each open one its other messages;
/// otherwise one a message. 0 on failure.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_row_count(core: *const PeCore, view: *const PeListView) -> u64 {
    // SAFETY: as the caller guarantees
    unsafe { listed(core, view, 0, |core, view| view.row_count(core).unwrap_or(0)) }
}

/// The counts of the status bar: how many messages the list has (grouped or not, all of them) and how many are unread;
/// a folder shown whole counted from its indexes, as `pe_folder_counts`. Both 0 when it lists nothing; false on
/// failure.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view, `total` and `unread` valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_counts(
    core: *const PeCore,
    view: *const PeListView,
    total: *mut u64,
    unread: *mut u64,
) -> bool {
    if total.is_null() || unread.is_null() {
        return false;
    }
    // SAFETY: as the caller guarantees
    let Some(counts) = (unsafe { listed(core, view, None, |core, view| view.counts(core).ok()) }) else {
        return false;
    };
    // SAFETY: the caller gave valid pointers
    unsafe { (*total, *unread) = counts };
    true
}

/// The counts of `pe_list_view_counts` and the row count of `pe_list_view_row_count` at once, as a list read again
/// wants them; false on failure.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view, `total`, `unread` and `rows` valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_counts_and_rows(
    core: *const PeCore,
    view: *const PeListView,
    total: *mut u64,
    unread: *mut u64,
    rows: *mut u64,
) -> bool {
    if total.is_null() || unread.is_null() || rows.is_null() {
        return false;
    }
    // SAFETY: as the caller guarantees
    let Some(counts) = (unsafe { listed(core, view, None, |core, view| view.counts_and_rows(core).ok()) }) else {
        return false;
    };
    // SAFETY: the caller gave valid pointers
    unsafe { (*total, *unread, *rows) = counts };
    true
}

/// Whether something was written to the store since the list was last counted (`pe_list_view_counts`,
/// `pe_list_view_counts_and_rows`), or it was never counted: read again, it might show something else. The list read
/// again `PE_LIST_GATHER_MS` after a change skips that when it is not stale, as the user's own command read it at once.
/// True on failure; false for a view listing nothing.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_stale(core: *const PeCore, view: *const PeListView) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { listed(core, view, true, |core, view| view.stale(core).unwrap_or(true)) }
}

/// The row of the message `uid` of `folder` as `pe_list_view_index` finds it, looked for first in the rows read since
/// the list was counted, nearest `hint` (the row it had before the list was read again; read the page with that row
/// first): the message shown found where it was, or a few rows lower as mail came above it, without going through
/// the whole list. A negative `hint` is `pe_list_view_index`. -1 when it is not in the list.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_index_near(
    core: *const PeCore,
    view: *const PeListView,
    folder: i64,
    uid: u64,
    hint: i64,
) -> i64 {
    // SAFETY: as the caller guarantees
    unsafe {
        listed(core, view, -1, |core, view| {
            let found = match u64::try_from(hint) {
                Ok(hint) => view.index_of_near(core, folder, uid, hint),
                Err(_) => view.index_of(core, folder, uid),
            };
            match found {
                Ok(Some(index)) => i64::try_from(index).unwrap_or(-1),
                _ => -1,
            }
        })
    }
}

/// The row of the message `uid` of `folder` (its conversation's while that is collapsed), -1 when it is not in the
/// list
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_index(
    core: *const PeCore,
    view: *const PeListView,
    folder: i64,
    uid: u64,
) -> i64 {
    // SAFETY: as the caller guarantees
    unsafe {
        listed(core, view, -1, |core, view| match view.index_of(core, folder, uid) {
            Ok(Some(index)) => i64::try_from(index).unwrap_or(-1),
            _ => -1,
        })
    }
}

/// The messages before and after the message `uid` of `folder` in the list, with one pass over it: what Previous and
/// Next open, into `previous_*` and `next_*` (a folder of 0 at an end). False when the message is not in the list (any
/// more), or on failure: a window keeps the pair it had then.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view, the four out pointers valid.
#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn pe_list_view_neighbours(
    core: *const PeCore,
    view: *const PeListView,
    folder: i64,
    uid: u64,
    previous_folder: *mut i64,
    previous_uid: *mut u64,
    next_folder: *mut i64,
    next_uid: *mut u64,
) -> bool {
    if previous_folder.is_null() || previous_uid.is_null() || next_folder.is_null() || next_uid.is_null() {
        return false;
    }
    // SAFETY: as the caller guarantees
    let found = unsafe {
        listed(core, view, None, |core, view| {
            view.neighbours(core, folder, uid).ok().flatten()
        })
    };
    // SAFETY: the caller gave valid pointers
    unsafe { put_neighbours(found, previous_folder, previous_uid, next_folder, next_uid) }
}

/// One step of Next Unread from the message `uid` of `folder` (0 for none) in the list: the next unread message of the
/// list (to select after `pe_list_view_reveal`), or the next folder with unread mail and the question to ask before
/// going there (a heading, a blank line, the question; free it with `pe_string_free`), or nothing (also when the list
/// lists nothing).
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view, the three out pointers valid.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_next_unread_step(
    core: *const PeCore,
    view: *const PeListView,
    folder: i64,
    uid: u64,
    next_folder: *mut i64,
    next_uid: *mut u64,
    question: *mut *mut c_char,
) -> PeNextUnread {
    if next_folder.is_null() || next_uid.is_null() || question.is_null() {
        return PeNextUnread::None;
    }
    // SAFETY: as the caller guarantees
    let step = unsafe {
        listed(core, view, None, |core, view| {
            view.next_unread_step(core, folder, uid).ok()
        })
    };
    // SAFETY: the caller gave valid pointers
    unsafe { put_next_unread(step, next_folder, next_uid, question) }
}

/// Whether the list names whom its messages went to (Sent Items, Drafts): its person column is then To and shows
/// `recipients`, its date column is Sent, and a From sort is by the recipients. False on failure.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_lists_recipients(core: *const PeCore, view: *const PeListView) -> bool {
    // SAFETY: as the caller guarantees
    unsafe {
        listed(core, view, false, |core, view| {
            view.lists_recipients(core).unwrap_or(false)
        })
    }
}

/// Fills `selection` with the messages at the rows `starts[i]` (included) to `ends[i]` (not) of the list, in place of
/// what it had: a collapsed conversation's row stands for all of its messages. False on failure.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view, `selection` NULL or a live selection, `starts` and `ends`
/// NULL or `count` values each.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_select_ranges(
    core: *const PeCore,
    view: *const PeListView,
    selection: *mut PeSelection,
    starts: *const u64,
    ends: *const u64,
    count: usize,
) -> bool {
    // SAFETY: as the caller guarantees
    let Some(selection) = (unsafe { selection.as_mut() }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    let ranges = unsafe { ranges_of(starts, ends, count) };
    // SAFETY: as the caller guarantees
    let refs = unsafe { listed(core, view, None, |core, view| view.refs_in_ranges(core, &ranges).ok()) };
    let Some(refs) = refs else {
        return false;
    };
    selection.0 = pe_core::Selected::Listed(refs);
    true
}

/// Select All: fills `selection` with every message of the list (a collapsed conversation's too) without listing them,
/// counted (`pe_selection_count`) from what the list counted last; the calls taking the selection list them when they
/// need them (`pe_selection_act_start` off the window thread). Only the messages stored by then: mail that comes after
/// it is neither counted nor acted on. False on failure.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view, `selection` NULL or a live selection.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_select_all(
    core: *const PeCore,
    view: *const PeListView,
    selection: *mut PeSelection,
) -> bool {
    // SAFETY: as the caller guarantees
    let Some(selection) = (unsafe { selection.as_mut() }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    match unsafe { listed(core, view, None, |core, view| view.select_all(core).ok()) } {
        Some(all) => {
            selection.0 = all;
            true
        }
        None => false,
    }
}

/// The list read again while `selection` is its Select All: true when it still is the whole list (no message stored
/// since in it), counted again, and every row is selected again; false when it is not, and then `selection` lists the
/// messages Select All had, for `pe_list_view_positions` to find (the newer rows not selected). False on failure too.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view, `selection` NULL or a live selection.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_select_all_again(
    core: *const PeCore,
    view: *const PeListView,
    selection: *mut PeSelection,
) -> bool {
    // SAFETY: as the caller guarantees
    let Some(selection) = (unsafe { selection.as_mut() }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    unsafe {
        listed(core, view, false, |core, view| {
            view.select_all_again(core, &mut selection.0).unwrap_or(false)
        })
    }
}

/// Where the messages of `selection` are now in the list, ascending, to select them again after it changed; those no
/// longer in it are left out. Free with `pe_positions_free`. NULL on failure.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view, `selection` NULL or a live selection.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_positions(
    core: *const PeCore,
    view: *const PeListView,
    selection: *const PeSelection,
) -> *mut PePositions {
    // SAFETY: as the caller guarantees
    let Some(selection) = (unsafe { selection.as_ref() }) else {
        return null_mut();
    };
    // SAFETY: as the caller guarantees
    unsafe {
        listed(core, view, null_mut(), |core, view| {
            let refs = core.selected_refs(&selection.0).unwrap_or_default();
            view.positions(core, &refs)
                .map_or(null_mut(), |found| handed(PePositions(found)))
        })
    }
}

/// The rows of the messages the last `pe_undo` brought back, and of those the store took back when the server refused
/// an action (`PE_EVENT_KIND_ACTION_UNDONE`), for the app to select once its list has them: none while none is back
/// yet. With `behind` set true and no rows, something was written since the list was last counted (with
/// `pe_list_view_counts_and_rows`): the rows found now could be others of the list shown, so the app reads the list
/// again (as after `PE_EVENT_KIND_FOLDER_CHANGED`) and asks then; the messages are kept for it. Free with
/// `pe_positions_free`. NULL on failure.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view, `behind` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_restored(
    core: *const PeCore,
    view: *const PeListView,
    behind: *mut bool,
) -> *mut PePositions {
    // SAFETY: as the caller guarantees
    let found = unsafe { listed(core, view, None, |core, view| view.restored(core).ok()) };
    // SAFETY: as the caller guarantees
    if let Some(behind) = unsafe { behind.as_mut() } {
        *behind = matches!(found, Some(None));
    }
    match found {
        Some(rows) => handed(PePositions(rows.unwrap_or_default())),
        None => null_mut(),
    }
}

/// Whether `action` (to `to`) on the messages of `summary` takes them out of the list (Ignore Conversation does while
/// it hides ignored conversations): then the app selects the row after them, as it does after Delete
///
/// # Safety
/// `view` must be NULL or a live view, `summary` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_leaves_list(
    view: *const PeListView,
    summary: *const PeSelectionSummary,
    action: PeAction,
    to: i64,
) -> bool {
    // SAFETY: as the caller guarantees
    let Some(summary) = (unsafe { summary.as_ref() }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    unsafe {
        read(view, false, |view| {
            action_of(action, to).is_some_and(|action| view.leaves_list(&Summary::from(summary), action))
        })
    }
}

// ---- loaded off the window thread ----

/// The rows a list load reads at a time (`pe_list_view_load`, `pe_list_view_load_page`)
pub const PE_LIST_PAGE: u64 = 100;

const _: () = assert!(PE_LIST_PAGE == pe_core::LIST_PAGE);

/// What a list load read, besides its rows
#[repr(C)]
#[derive(Debug, Clone, Copy, Default)]
pub struct PeListLoadInfo {
    /// The window's number for the load, as it gave it
    pub generation: u64,
    /// Where its rows start in the list
    pub offset: u64,
    /// A load of the list (`pe_list_view_load`), with the counts; false for a page, whose counts are 0
    pub counted: bool,
    /// The counts of the status bar (`pe_list_view_counts`) and the row count (`pe_list_view_row_count`)
    pub total: u64,
    pub unread: u64,
    pub rows: u64,
    /// As `pe_list_view_lists_recipients`
    pub lists_recipients: bool,
    /// The row of the message the load was asked about, -1 when it is not in the list or none was asked about
    pub index: i64,
}

/// A list load's result; free with `pe_list_load_free`
pub struct PeListLoad {
    info: PeListLoadInfo,
    messages: Vec<pe_store::Message>,
}

/// Loads the list `view` shows on a store connection of the core's own, off the window thread: its counts, its row
/// count, the first `PE_LIST_PAGE` rows and, when `folder` is not 0, the row of the message `uid` of `folder` (looked
/// for first in those rows, nearest `hint`, the row it had; -1 when not known). `ListReady` follows with the request
/// this returns in `uid` and `generation` (the window's number for the load, any it likes) in `count`. A newer load
/// of the same view cancels this one and the pages asked for before it: their events never come. What it read is
/// kept for the view, as its calls on the window thread keep what they read (a click selects from its rows,
/// `pe_list_view_stale` is false until the store changes). 0 on failure.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_load(
    core: *const PeCore,
    view: *const PeListView,
    generation: u64,
    folder: i64,
    uid: u64,
    hint: i64,
) -> u64 {
    // SAFETY: as the caller guarantees
    let Some(view) = (unsafe { view.as_ref() }) else {
        return 0;
    };
    let place = (folder != 0).then(|| (folder, uid, u64::try_from(hint).ok()));
    // SAFETY: as the caller guarantees
    unsafe { with_shared(core, 0, |core| core.list_load(&view.0, generation, place).unwrap_or(0)) }
}

/// Loads `PE_LIST_PAGE` rows of the list `view` shows from `offset` on, off the window thread as `pe_list_view_load`
/// does: `ListPageReady` follows with the request this returns in `uid` and `generation` in `count`. Ask for the page
/// after the one shown too, so it is there when scrolled to. Dropped (no event) when a load of the whole list comes
/// after it. 0 on failure.
///
/// # Safety
/// `core` must be a live handle, `view` NULL or a live view.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_view_load_page(
    core: *const PeCore,
    view: *const PeListView,
    generation: u64,
    offset: u64,
) -> u64 {
    // SAFETY: as the caller guarantees
    let Some(view) = (unsafe { view.as_ref() }) else {
        return 0;
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with_shared(core, 0, |core| {
            core.list_load_page(&view.0, generation, offset).unwrap_or(0)
        })
    }
}

/// What the load `request` read, after its `ListReady` or `ListPageReady`, taken once; NULL for a request that failed,
/// was dropped or is unknown. Free with `pe_list_load_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_load_result(core: *const PeCore, request: u64) -> *mut PeListLoad {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.list_load_result(request).map_or(null_mut(), |load| {
                handed(PeListLoad {
                    info: PeListLoadInfo {
                        generation: load.generation,
                        offset: load.offset,
                        counted: load.counted,
                        total: load.total,
                        unread: load.unread,
                        rows: load.rows,
                        lists_recipients: load.lists_recipients,
                        index: load.index.and_then(|i| i64::try_from(i).ok()).unwrap_or(-1),
                    },
                    messages: load.messages,
                })
            })
        })
    }
}

/// Drops a load nobody waits for any more (its window closed): its event does not come
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_load_cancel(core: *const PeCore, request: u64) {
    // SAFETY: as the caller guarantees
    unsafe { with(core, (), |core| core.list_load_cancel(request)) }
}

/// What the load read besides its rows, owned by it
///
/// # Safety
/// `load` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_load_info(load: *const PeListLoad) -> *const PeListLoadInfo {
    // SAFETY: as the caller guarantees
    unsafe { load.as_ref() }.map_or(std::ptr::null(), |load| &load.info)
}

/// The rows the load read (from `offset` on), as `pe_list_view_messages` gives them; free with
/// `pe_message_list_free`. NULL for NULL.
///
/// # Safety
/// `load` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_load_messages(load: *const PeListLoad) -> *mut PeMessageList {
    // SAFETY: as the caller guarantees
    let Some(load) = (unsafe { load.as_ref() }) else {
        return null_mut();
    };
    guard(|| message_list(&load.messages)).unwrap_or(null_mut())
}

/// # Safety
/// `load` must be NULL or a load that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_load_free(load: *mut PeListLoad) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(load) }
}
