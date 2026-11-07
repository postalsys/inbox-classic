//! A message list's view through the C API, as the windows will call it: a `PeListView` set to a folder, grouped by
//! conversation, read a page at a time and counted, its conversations opened and closed, and a reply hidden in a
//! collapsed one revealed. The store is filled before the core opens it, so no server is needed.

use std::ffi::{CString, c_char};
use std::ptr::{null, null_mut};

use pe_ffi::*;
use pe_store::{AccountSettings, FolderInfo, MessageInfo, Store};
use pe_testkit::TempDir;

/// A message `uid` dated `at`, with its own id and the ids it answers
fn mail(uid: u64, at: i64, id: &str, answers: &[&str], seen: bool) -> MessageInfo {
    MessageInfo {
        uid,
        date: Some(at),
        subject: id.trim_matches(['<', '>']).into(),
        message_id: Some(id.into()),
        references: answers.iter().map(|a| a.to_string()).collect(),
        flags: if seen { vec!["\\Seen".into()] } else { Vec::new() },
        ..Default::default()
    }
}

/// A store with one account whose Inbox has a conversation of three (a, b, c: uids 1, 3, 4, b unread), and one of
/// one (d: uid 2); the Inbox's id
fn filled(path: &std::path::Path) -> i64 {
    let store = Store::open(path).unwrap();
    let account = store
        .add_account(&AccountSettings {
            name: "Test".into(),
            email: "a@example.com".into(),
            ..Default::default()
        })
        .unwrap();
    let inbox = FolderInfo {
        path: "INBOX".into(),
        name: "INBOX".into(),
        selectable: true,
        ..Default::default()
    };
    store.set_folders(account, &[inbox]).unwrap();
    let inbox = store.folders(account).unwrap()[0].id;
    store
        .add_messages(
            inbox,
            &[
                mail(1, 100, "<a@x>", &[], true),
                mail(2, 200, "<d@x>", &[], true),
                mail(3, 300, "<b@x>", &["<a@x>"], false),
                mail(4, 400, "<c@x>", &["<a@x>", "<b@x>"], true),
            ],
        )
        .unwrap();
    inbox
}

/// The (uid, depth, collapsed) of every row of the view
fn rows(core: *const PeCore, view: *const PeListView) -> Vec<(u64, u32, bool)> {
    let list = unsafe { pe_list_view_messages(core, view, 0, 50) };
    assert!(!list.is_null());
    let found = (0..unsafe { pe_message_list_count(list) })
        .map(|i| {
            let row = unsafe { &*pe_message_list_get(list, i) };
            (row.uid, row.thread_depth, row.thread_collapsed)
        })
        .collect();
    unsafe { pe_message_list_free(list) };
    found
}

fn thread_of_first_row(core: *const PeCore, view: *const PeListView) -> i64 {
    let list = unsafe { pe_list_view_messages(core, view, 0, 1) };
    let thread = unsafe { &*pe_message_list_get(list, 0) }.thread;
    unsafe { pe_message_list_free(list) };
    thread
}

fn counts(core: *const PeCore, view: *const PeListView) -> (u64, u64) {
    let (mut total, mut unread) = (0u64, 0u64);
    assert!(unsafe { pe_list_view_counts(core, view, &mut total, &mut unread) });
    (total, unread)
}

#[test]
fn a_list_view_through_the_c_api() {
    let dir = TempDir::new("ffi-list-view");
    let path = dir.path().join("store.db");
    let inbox = filled(&path);
    let path = CString::new(path.to_str().unwrap()).unwrap();
    let core = unsafe { pe_core_open_with(path.as_ptr(), PE_OPEN_MEMORY_PASSWORDS, null(), None, null_mut()) };
    assert!(!core.is_null());

    let view = pe_list_view_new();
    assert!(!view.is_null());
    // no folder: nothing listed
    assert!(!unsafe { pe_list_view_active(view) });
    assert_eq!(unsafe { pe_list_view_row_count(core, view) }, 0);
    assert_eq!(counts(core, view), (0, 0));
    assert!(rows(core, view).is_empty());

    // the Inbox, newest first, one row a message
    assert!(unsafe { pe_list_view_set_scope(view, inbox, false) });
    assert!(
        !unsafe { pe_list_view_set_scope(view, inbox, false) },
        "the same folder"
    );
    assert!(unsafe { pe_list_view_active(view) } && !unsafe { pe_list_view_several_folders(view) });
    assert_eq!(counts(core, view), (4, 1));
    assert_eq!(unsafe { pe_list_view_row_count(core, view) }, 4);
    assert_eq!(rows(core, view).iter().map(|r| r.0).collect::<Vec<_>>(), [4, 3, 2, 1]);
    unsafe { pe_list_view_set_sort(view, PeSortField::Date, true) };
    assert_eq!(
        rows(core, view).iter().map(|r| r.0).collect::<Vec<_>>(),
        [1, 2, 3, 4],
        "oldest first"
    );
    unsafe { pe_list_view_set_sort(view, PeSortField::Date, false) };
    assert_eq!(unsafe { pe_list_view_index(core, view, inbox, 2) }, 2);
    assert!(!unsafe { pe_list_view_lists_recipients(core, view) });

    // grouped: a's conversation collapsed on its row, d's below it; the messages counted all the same
    assert!(unsafe { pe_list_view_set_grouped(view, true) });
    assert!(unsafe { pe_list_view_grouped(view) });
    assert_eq!(rows(core, view), [(1, 0, true), (2, 0, false)]);
    assert_eq!(unsafe { pe_list_view_row_count(core, view) }, 2);
    assert_eq!(counts(core, view), (4, 1));
    let a = thread_of_first_row(core, view);
    assert!(a != 0);

    // a reply hidden in it is revealed: its conversation opened, the reply on a row of its own
    assert_eq!(
        unsafe { pe_list_view_index(core, view, inbox, 4) },
        0,
        "its conversation's row"
    );
    assert!(
        !unsafe { pe_list_view_reveal(core, view, inbox, 2) },
        "a row of its own already"
    );
    assert!(unsafe { pe_list_view_reveal(core, view, inbox, 4) });
    assert!(unsafe { pe_list_view_is_expanded(view, a) });
    assert!(!unsafe { pe_list_view_reveal(core, view, inbox, 4) }, "shown now");
    assert_eq!(
        rows(core, view),
        [(1, 0, false), (3, 1, false), (4, 1, false), (2, 0, false)]
    );
    assert_eq!(unsafe { pe_list_view_index(core, view, inbox, 4) }, 2);

    // Previous and Next, and Next Unread, through the view's order
    let (mut pf, mut pu, mut nf, mut nu) = (0i64, 0u64, 0i64, 0u64);
    assert!(unsafe { pe_list_view_neighbours(core, view, inbox, 3, &mut pf, &mut pu, &mut nf, &mut nu) });
    assert_eq!((pf, pu, nf, nu), (inbox, 1, inbox, 4));
    let mut question: *mut c_char = null_mut();
    let step = unsafe { pe_list_view_next_unread_step(core, view, inbox, 1, &mut nf, &mut nu, &mut question) };
    assert_eq!((step, nf, nu), (PeNextUnread::Message, inbox, 3));
    assert!(question.is_null());

    // the selection's rows: an open conversation's first row is its first message alone
    let selection = pe_selection_new();
    let (starts, ends) = ([0u64, 3], [1u64, 4]);
    assert!(unsafe { pe_list_view_select_ranges(core, view, selection, starts.as_ptr(), ends.as_ptr(), 2) });
    assert_eq!(unsafe { pe_selection_count(selection) }, 2);
    let positions = unsafe { pe_list_view_positions(core, view, selection) };
    assert_eq!(unsafe { pe_positions_count(positions) }, 2);
    assert_eq!(
        (unsafe { pe_positions_get(positions, 0) }, unsafe {
            pe_positions_get(positions, 1)
        }),
        (0, 3)
    );
    unsafe { pe_positions_free(positions) };
    // Ignore Conversation leaves the list only while it hides ignored conversations
    let summary = PeSelectionSummary::default();
    assert!(!unsafe { pe_list_view_leaves_list(view, &summary, PeAction::Ignore, 0) });
    unsafe { pe_list_view_set_hide_ignored(view, true) };
    assert!(unsafe { pe_list_view_leaves_list(view, &summary, PeAction::Ignore, 0) });
    assert!(
        unsafe { pe_list_view_is_expanded(view, a) },
        "hiding ignored ones keeps them open"
    );
    unsafe { pe_list_view_set_hide_ignored(view, false) };
    unsafe { pe_selection_free(selection) };

    // a copy goes on by itself: one message at a time for a message window
    let copy = unsafe { pe_list_view_clone(view) };
    assert!(unsafe { pe_list_view_is_expanded(copy, a) });
    assert!(unsafe { pe_list_view_set_grouped(copy, false) });
    assert_eq!(unsafe { pe_list_view_row_count(core, copy) }, 4);
    assert!(
        unsafe { pe_list_view_is_expanded(view, a) },
        "the list's own stays open"
    );
    unsafe { pe_list_view_free(copy) };

    // + and -, Collapse All and Expand All
    assert!(!unsafe { pe_list_view_toggle(view, a) }, "closed");
    assert_eq!(unsafe { pe_list_view_row_count(core, view) }, 2);
    assert!(unsafe { pe_list_view_toggle(view, a) }, "open");
    assert!(unsafe { pe_list_view_collapse_all(view) });
    assert!(!unsafe { pe_list_view_collapse_all(view) });
    assert!(unsafe { pe_list_view_expand_all(core, view) });
    assert!(unsafe { pe_list_view_is_expanded(view, a) });
    assert!(!unsafe { pe_list_view_expand_all(core, view) }, "open already");
    assert!(unsafe { pe_list_view_collapse(view, a) } && !unsafe { pe_list_view_collapse(view, a) });
    assert!(unsafe { pe_list_view_expand(view, a) } && !unsafe { pe_list_view_expand(view, a) });

    // words search every folder and close the conversations
    let words = CString::new("subject:b").unwrap();
    assert!(unsafe { pe_list_view_set_text(view, words.as_ptr()) });
    assert!(unsafe { pe_list_view_searching(view) } && unsafe { pe_list_view_several_folders(view) });
    assert!(!unsafe { pe_list_view_is_expanded(view, a) });
    assert_eq!(counts(core, view), (1, 1));
    assert!(unsafe { pe_list_view_set_text(view, null()) });
    assert!(!unsafe { pe_list_view_searching(view) });
    // another folder closes them too
    unsafe { pe_list_view_expand(view, a) };
    assert!(unsafe { pe_list_view_set_scope(view, 0, true) });
    assert!(!unsafe { pe_list_view_is_expanded(view, a) });
    assert_eq!(counts(core, view), (4, 1), "All Inboxes");
    unsafe { pe_list_view_set_show(view, PeShow::Unread) };
    assert_eq!(counts(core, view), (1, 1));

    unsafe { pe_list_view_free(view) };
    unsafe { pe_core_close(core) };
}

#[test]
fn a_list_view_takes_null() {
    let mut question: *mut c_char = null_mut();
    let (mut a, mut b, mut c, mut d) = (0i64, 0u64, 0i64, 0u64);
    unsafe {
        pe_list_view_free(null_mut());
        assert!(pe_list_view_clone(null()).is_null());
        assert!(!pe_list_view_set_scope(null_mut(), 1, false));
        assert!(!pe_list_view_set_text(null_mut(), null()));
        pe_list_view_set_show(null_mut(), PeShow::Unread);
        pe_list_view_set_sort(null_mut(), PeSortField::Subject, true);
        assert!(!pe_list_view_set_grouped(null_mut(), true));
        pe_list_view_set_hide_ignored(null_mut(), true);
        assert!(!pe_list_view_searching(null()) && !pe_list_view_several_folders(null()));
        assert!(!pe_list_view_active(null()) && !pe_list_view_grouped(null()));
        assert!(!pe_list_view_is_expanded(null(), 1));
        assert!(!pe_list_view_toggle(null_mut(), 1) && !pe_list_view_expand(null_mut(), 1));
        assert!(!pe_list_view_collapse(null_mut(), 1) && !pe_list_view_collapse_all(null_mut()));
        assert!(!pe_list_view_expand_all(null(), null_mut()));
        assert!(!pe_list_view_reveal(null(), null_mut(), 1, 1));
        assert!(pe_list_view_messages(null(), null(), 0, 10).is_null());
        assert_eq!(pe_list_view_row_count(null(), null()), 0);
        assert!(!pe_list_view_counts(null(), null(), &mut b, &mut d));
        assert!(!pe_list_view_counts(null(), null(), null_mut(), null_mut()));
        assert_eq!(pe_list_view_index(null(), null(), 1, 1), -1);
        assert!(!pe_list_view_neighbours(
            null(),
            null(),
            1,
            1,
            &mut a,
            &mut b,
            &mut c,
            &mut d
        ));
        assert_eq!(
            pe_list_view_next_unread_step(null(), null(), 1, 1, &mut a, &mut b, &mut question),
            PeNextUnread::None
        );
        assert!(!pe_list_view_lists_recipients(null(), null()));
        assert!(!pe_list_view_select_ranges(
            null(),
            null(),
            null_mut(),
            null(),
            null(),
            0
        ));
        assert!(pe_list_view_positions(null(), null(), null()).is_null());
        assert!(!pe_list_view_leaves_list(null(), null(), PeAction::Delete, 0));
    }

    // a live view without a core
    let view = pe_list_view_new();
    unsafe {
        assert!(pe_list_view_set_scope(view, 1, false));
        assert!(!pe_list_view_expand_all(null(), view));
        assert!(!pe_list_view_reveal(null(), view, 1, 1));
        assert!(pe_list_view_messages(null(), view, 0, 10).is_null());
        let summary = PeSelectionSummary::default();
        assert!(pe_list_view_leaves_list(view, &summary, PeAction::Delete, 0));
        pe_list_view_free(view);
    }
}
