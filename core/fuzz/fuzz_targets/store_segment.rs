//! What the search index makes of every message's text and of whatever is typed in the search box: `segment` only
//! adds spaces, and is done once done; a message with the text as its subject is stored, and the text searched as
//! typed, so every query built from it is one FTS5 and SQLite take (no syntax of FTS5 can be typed, segmented or not).
#![no_main]

use std::cell::RefCell;

use libfuzzer_sys::fuzz_target;
use pe_store::{AccountSettings, FolderInfo, MessageInfo, Search, Sort, Store};

thread_local! {
    /// A store with a folder, opened once: its migrations take longer than a run
    static STORE: RefCell<Option<(Store, i64)>> = const { RefCell::new(None) };
}

fn opened() -> (Store, i64) {
    let store = Store::open_in_memory().unwrap();
    let account = store.add_account(&AccountSettings {
            email: "fuzz@example.com".into(),
            ..Default::default()
        }).unwrap();
    let inbox = FolderInfo {
        path: "INBOX".into(),
        name: "INBOX".into(),
        selectable: true,
        ..Default::default()
    };
    store.set_folders(account, &[inbox]).unwrap();
    let folder = store.find_folder(account, "INBOX").unwrap().unwrap().id;
    (store, folder)
}

fuzz_target!(|data: &[u8]| {
    let text = String::from_utf8_lossy(data);
    let segmented = pe_store::segment(&text);
    let narrowed: String = text
        .chars()
        .map(|c| match c {
            '\u{FF01}'..='\u{FF5E}' => char::from_u32(c as u32 - 0xFEE0).unwrap_or(c),
            c => c,
        })
        .filter(|c| *c != ' ')
        .collect();
    assert_eq!(segmented.replace(' ', ""), narrowed);
    assert_eq!(pe_store::segment(&segmented), segmented);

    STORE.with(|cell| {
        let mut cell = cell.borrow_mut();
        let (store, folder) = cell.get_or_insert_with(opened);
        store.remove_messages(*folder, &[1]).unwrap();
        let message = MessageInfo {
            uid: 1,
            subject: text.to_string(),
            from_name: text.to_string(),
            ..Default::default()
        };
        store.add_messages(*folder, &[message]).unwrap();
        let search = Search {
            text: text.to_string(),
            ..Default::default()
        };
        store.search(&search, Sort::default(), 0, 10).unwrap();
        store.count_search(&search).unwrap();
    });
});
