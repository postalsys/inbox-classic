//! What the store's tests share: a store with an account, messages and the uids a search finds.

use crate::{AccountSettings, FolderId, FolderInfo, MessageInfo, Scope, Search, Sort, Store};

/// A store with the account of `address` and its INBOX and Sent
pub(crate) fn store_of(address: &str) -> (Store, FolderId, FolderId) {
    let store = Store::open_in_memory().unwrap();
    let account = store.add_account(&AccountSettings::example(address)).unwrap();
    let folder = |path: &str, special: Option<&str>| FolderInfo {
        path: path.into(),
        name: path.into(),
        special_use: special.map(String::from),
        selectable: true,
        ..Default::default()
    };
    store
        .set_folders(account, &[folder("INBOX", None), folder("Sent", Some("\\Sent"))])
        .unwrap();
    let id = |path| store.find_folder(account, path).unwrap().unwrap().id;
    let (inbox, sent) = (id("INBOX"), id("Sent"));
    (store, inbox, sent)
}

/// A message from `from` (name, address) to `recipients`, dated by its uid
pub(crate) fn message_to(uid: u64, subject: &str, from: (&str, &str), recipients: &str) -> MessageInfo {
    MessageInfo {
        uid,
        date: Some(uid as i64 * 100),
        subject: subject.into(),
        from_name: from.0.into(),
        from_address: from.1.into(),
        recipients: recipients.into(),
        ..Default::default()
    }
}

/// The uids a search finds, in order
pub(crate) fn found(store: &Store, search: &Search) -> Vec<u64> {
    let mut uids: Vec<u64> = store
        .search(search, Sort::default(), 0, 100)
        .unwrap()
        .iter()
        .map(|m| m.info.uid)
        .collect();
    uids.sort();
    uids
}

/// A search of the words typed, in a folder or everywhere
pub(crate) fn words(folder: Option<FolderId>, text: &str) -> Search {
    Search {
        scope: folder.map_or(Scope::Everywhere, Scope::Folder),
        text: text.into(),
        ..Default::default()
    }
}

/// The row id of a folder's message
pub(crate) fn id_of(store: &Store, folder: FolderId, uid: u64) -> i64 {
    store
        .db
        .query_row(
            "SELECT id FROM messages WHERE folder_id = ?1 AND uid = ?2",
            [folder, uid as i64],
            |r| r.get(0),
        )
        .unwrap()
}
