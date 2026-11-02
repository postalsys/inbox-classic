//! Keeps the local store in step with an IMAP account: the folder list, the messages of a folder
//! (new ones, flag changes, deletions, a new UIDVALIDITY) and message sources fetched on demand.
//! Changes the server reports while a folder is selected are applied as they arrive.
#![forbid(unsafe_code)]

mod summary;

use std::collections::HashSet;
use std::fmt;

use pe_imap::client::{FetchQuery, ListedMailbox, SearchKey, Selected, StoreAction};
use pe_imap::{Client, Config, Credentials, Event, Messages, SequenceSet};
use pe_store::{Account, AccountId, Folder, FolderId, FolderInfo, MessageInfo, Store, SyncState};

/// New messages are committed in batches of this many, so the list fills while a large folder
/// downloads and an interrupted first sync goes on from where it stopped
const BATCH: usize = 500;

#[derive(Debug)]
pub enum Error {
    Imap(pe_imap::Error),
    Store(pe_store::Error),
    /// The message is not on the server any more
    MessageGone,
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::Imap(error) => write!(f, "{error}"),
            Error::Store(error) => write!(f, "local store: {error}"),
            Error::MessageGone => f.write_str("the message is not on the server any more"),
        }
    }
}

impl std::error::Error for Error {}

impl From<pe_imap::Error> for Error {
    fn from(error: pe_imap::Error) -> Self {
        Error::Imap(error)
    }
}

impl From<pe_store::Error> for Error {
    fn from(error: pe_store::Error) -> Self {
        Error::Store(error)
    }
}

pub type Result<T> = std::result::Result<T, Error>;

/// The IMAP connection settings of a stored account
pub fn imap_config(account: &Account, credentials: Credentials) -> Config {
    let settings = &account.settings;
    Config::new(
        settings.imap_host.clone(),
        settings.imap_port,
        net_security(settings.imap_security),
        credentials,
    )
}

/// The SMTP connection settings of a stored account
pub fn smtp_config(account: &Account, credentials: Credentials) -> pe_smtp::Config {
    let settings = &account.settings;
    pe_smtp::Config::new(
        settings.smtp_host.clone(),
        settings.smtp_port,
        net_security(settings.smtp_security),
        Some(credentials),
    )
}

/// The store's security setting as the connection takes it
fn net_security(security: pe_store::Security) -> pe_net::Security {
    match security {
        pe_store::Security::Tls => pe_net::Security::Tls,
        pe_store::Security::StartTls => pe_net::Security::StartTls,
        pe_store::Security::Plain => pe_net::Security::Plain,
    }
}

/// What a folder sync changed
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Report {
    pub added: usize,
    pub removed: usize,
    pub flags_changed: usize,
    /// The server has a new UIDVALIDITY, the cached messages were dropped
    pub reset: bool,
}

/// What a server event did to the store
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Change {
    None,
    /// The folder changed and its view should be refreshed
    Updated(FolderId),
    /// Something changed that only a sync of the folder can tell (new messages, an expunge by
    /// sequence number)
    NeedsSync(FolderId),
}

impl Change {
    fn updated_if(changed: bool, folder: FolderId) -> Change {
        if changed { Change::Updated(folder) } else { Change::None }
    }
}

fn folder_info(listed: ListedMailbox) -> FolderInfo {
    FolderInfo {
        selectable: listed.is_selectable(),
        special_use: listed.special_use.map(|(special, _)| special.flag().to_string()),
        path: listed.path,
        name: listed.name,
        delimiter: listed.delimiter,
        flags: listed.flags,
        subscribed: listed.subscribed,
    }
}

/// Makes the folders of `account` in the store the ones the server lists
pub async fn sync_folders(client: &mut Client, store: &mut Store, account: AccountId) -> Result<Vec<Folder>> {
    let listed = client.list().await?;
    let folders = tree_order(listed.into_iter().map(folder_info).collect());
    store.transaction(|store| store.set_folders(account, &folders))?;
    Ok(store.folders(account)?)
}

/// The folders in the order of the tree: each followed by its subfolders, the top level in the order they came in
/// (the Inbox and the special folders first, as the list sorts them). The tree of the windows is built from this
/// order, so a subfolder listed after other folders still lands in its parent. A folder whose parent is not listed
/// is at the top.
fn tree_order(folders: Vec<FolderInfo>) -> Vec<FolderInfo> {
    let parent_of = |folder: &FolderInfo| -> Option<String> {
        let delimiter = folder.delimiter.as_deref().filter(|d| !d.is_empty())?;
        folder.path.rsplit_once(delimiter).map(|(parent, _)| parent.to_string())
    };
    let paths: std::collections::HashSet<String> = folders.iter().map(|f| f.path.clone()).collect();
    let mut children: std::collections::HashMap<Option<String>, Vec<usize>> = std::collections::HashMap::new();
    for (index, folder) in folders.iter().enumerate() {
        let parent = parent_of(folder).filter(|parent| paths.contains(parent));
        children.entry(parent).or_default().push(index);
    }
    let mut order = Vec::with_capacity(folders.len());
    // depth first, without recursion: a hostile server can list folders a thousand deep
    let mut stack: Vec<usize> = children.get(&None).into_iter().flatten().rev().copied().collect();
    let mut seen = vec![false; folders.len()];
    while let Some(index) = stack.pop() {
        if std::mem::replace(&mut seen[index], true) {
            continue;
        }
        order.push(index);
        if let Some(kids) = children.get(&Some(folders[index].path.clone())) {
            stack.extend(kids.iter().rev());
        }
    }
    // a folder that is its own ancestor through odd names: kept, at the end
    order.extend((0..folders.len()).filter(|&index| !seen[index]));
    let mut folders: Vec<Option<FolderInfo>> = folders.into_iter().map(Some).collect();
    order.into_iter().filter_map(|index| folders[index].take()).collect()
}

/// How deep each folder is in the tree: the number of its ancestors that are listed, so a folder whose parent is not
/// listed (hidden by the server, not subscribed) is at the top rather than under whatever came before it
pub fn tree_depths(folders: &[&FolderInfo]) -> Vec<usize> {
    let paths: std::collections::HashSet<&str> = folders.iter().map(|f| f.path.as_str()).collect();
    folders
        .iter()
        .map(|folder| {
            let Some(delimiter) = folder.delimiter.as_deref().filter(|d| !d.is_empty()) else {
                return 0;
            };
            folder
                .path
                .match_indices(delimiter)
                .filter(|(at, _)| paths.contains(&folder.path[..*at]))
                .count()
        })
        .collect()
}

/// Brings the cached messages of a folder in line with the server. Selects the folder.
pub async fn sync_folder(client: &mut Client, store: &mut Store, folder: FolderId) -> Result<Report> {
    let cached = store.folder(folder)?;
    let selected = client.select(&cached.info.path).await?;
    let mut report = Report::default();
    let mut since = cached.state.highest_modseq;
    if cached.state.uid_validity.is_some() && cached.state.uid_validity != selected.uid_validity {
        store.transaction(|store| store.reset_folder(folder, selected.uid_validity))?;
        report.reset = true;
        since = None;
    } else if cached.state.uid_validity.is_none() {
        // before the first batch lands, so a first sync that stops halfway can tell a reset too
        let state = SyncState {
            uid_validity: selected.uid_validity,
            ..Default::default()
        };
        store.set_sync_state(folder, &state)?;
    }
    let known = store.uids(folder)?;
    if let Some(&max_known) = known.last() {
        report.flags_changed = sync_flags(client, store, folder, since, &selected, max_known).await?;
    }
    let from = known.last().map_or(1, |uid| uid + 1);
    report.added = fetch_new(client, store, folder, &selected, from).await?;
    let gone = find_gone(client, &known, &selected, report.added).await?;

    let state = SyncState {
        uid_validity: selected.uid_validity,
        uid_next: selected.uid_next,
        highest_modseq: selected.highest_modseq,
    };
    report.removed = store.transaction(|store| {
        let removed = store.remove_messages(folder, &gone)?;
        store.set_sync_state(folder, &state)?;
        Ok(removed)
    })?;
    Ok(report)
}

/// Updates the flags of the cached messages: those changed since `since` with CONDSTORE, all of
/// them otherwise. Returns how many changed.
async fn sync_flags(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    since: Option<u64>,
    selected: &Selected,
    max_known: u64,
) -> Result<usize> {
    if since.is_some() && since == selected.highest_modseq {
        return Ok(0);
    }
    let query = FetchQuery {
        flags: true,
        modseq: true,
        changed_since: since.filter(|_| selected.highest_modseq.is_some()),
        ..Default::default()
    };
    let mut changes = Vec::new();
    let range = Messages::Uids(SequenceSet::range(1, Some(max_known)));
    client
        .fetch_each(&range, &query, &mut |message| {
            if let (Some(uid), Some(flags)) = (message.uid, message.flags) {
                changes.push((uid, flags, message.modseq));
            }
        })
        .await?;
    Ok(store.transaction(|store| {
        let mut changed = 0;
        for (uid, flags, modseq) in &changes {
            changed += usize::from(store.set_flags(folder, *uid, flags, *modseq)?);
        }
        Ok(changed)
    })?)
}

/// The FETCH items of the message list
fn summary_query() -> FetchQuery {
    FetchQuery {
        flags: true,
        envelope: true,
        body_structure: true,
        internal_date: true,
        size: true,
        modseq: true,
        ..Default::default()
    }
}

/// Fetches and stores the messages from UID `from` on, in batches. Returns how many there were.
async fn fetch_new(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    selected: &Selected,
    from: u64,
) -> Result<usize> {
    // UIDNEXT says whether there is anything new; `from:*` would return the last message anyway
    if selected.exists == 0 || selected.uid_next.is_some_and(|next| next <= from) {
        return Ok(0);
    }
    let mut batch: Vec<MessageInfo> = Vec::new();
    let mut added = 0;
    let mut failed: Option<pe_store::Error> = None;
    let mut flush = |batch: &mut Vec<MessageInfo>, store: &mut Store| {
        if failed.is_none() && !batch.is_empty() {
            added += batch.len();
            if let Err(error) = store.transaction(|store| store.add_messages(folder, batch)) {
                failed = Some(error);
            }
        }
        batch.clear();
    };
    client
        .fetch_each(
            &Messages::Uids(SequenceSet::range(from, None)),
            &summary_query(),
            &mut |message| {
                // `from:*` matches the last message when from is past it
                if message.uid.is_some_and(|uid| uid >= from) {
                    batch.extend(summary::summary(message));
                    if batch.len() >= BATCH {
                        flush(&mut batch, store);
                    }
                }
            },
        )
        .await?;
    flush(&mut batch, store);
    match failed {
        Some(error) => Err(error.into()),
        None => Ok(added),
    }
}

/// The cached UIDs the server no longer has. With every new message added, as many messages as
/// the server has means none is gone and the server is not asked.
async fn find_gone(client: &mut Client, known: &[u64], selected: &Selected, added: usize) -> Result<Vec<u64>> {
    if u64::from(selected.exists) == (known.len() + added) as u64 {
        return Ok(Vec::new());
    }
    let on_server: HashSet<u64> = client.search(&SearchKey::All).await?.into_iter().collect();
    Ok(known.iter().copied().filter(|uid| !on_server.contains(uid)).collect())
}

/// The source of a message: from the cache, or fetched from the server and cached. Selects the
/// folder when it has to fetch.
pub async fn fetch_source(client: &mut Client, store: &mut Store, folder: FolderId, uid: u64) -> Result<Vec<u8>> {
    if let Some(source) = store.source(folder, uid)? {
        return Ok(source);
    }
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    let query = FetchQuery {
        source: true,
        ..Default::default()
    };
    let fetched = client.fetch(&Messages::uid(uid), &query).await?;
    let source = fetched
        .into_iter()
        .find(|m| m.uid == Some(uid))
        .and_then(|m| m.source)
        .ok_or(Error::MessageGone)?;
    store.set_source(folder, uid, &source)?;
    Ok(source)
}

/// Selects a folder unless it is the selected one
async fn ensure_selected(client: &mut Client, path: &str) -> Result<()> {
    if client.selected().is_none_or(|selected| selected.path != path) {
        client.select(path).await?;
    }
    Ok(())
}

/// Sets or clears a flag (`\\Seen`, `\\Flagged`) of a message on the server. The store is the caller's to change,
/// so the windows show it before the server has it.
pub async fn set_flag(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    uid: u64,
    flag: &str,
    on: bool,
) -> Result<()> {
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    let action = if on { StoreAction::Add } else { StoreAction::Remove };
    client.store(&Messages::uid(uid), action, &[flag]).await?;
    Ok(())
}

/// Moves a message to another folder of the account on the server (MOVE, or COPY and expunge where the server has
/// no MOVE). The store is the caller's to change; the folder it went to is the caller's to sync.
pub async fn move_message(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    uid: u64,
    to: FolderId,
) -> Result<()> {
    let (from, to) = (store.folder(folder)?.info.path, store.folder(to)?.info.path);
    ensure_selected(client, &from).await?;
    client.move_messages(&Messages::uid(uid), &to).await?;
    Ok(())
}

/// Deletes a message for good on the server: `\\Deleted`, then expunged. With UIDPLUS only this message is
/// expunged; without it, EXPUNGE takes every message of the folder marked deleted, as other mail programs do too.
pub async fn expunge_message(client: &mut Client, store: &mut Store, folder: FolderId, uid: u64) -> Result<()> {
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    let message = Messages::uid(uid);
    client.store(&message, StoreAction::Add, &["\\Deleted"]).await?;
    let only = pe_imap::SequenceSet::range(uid, Some(uid));
    match client.expunge(Some(&only)).await {
        Err(pe_imap::Error::Unsupported(_)) => client.expunge(None).await?,
        other => other?,
    }
    Ok(())
}

/// Why a folder name or a folder can not be used
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum FolderRefusal {
    /// Empty, too long, or with control characters
    BadName,
    /// The name has the character that separates folders on this server
    Separator(String),
    /// The Inbox and the special folders (Sent, Drafts, Deleted Items, ...) stay as they are
    Special,
}

impl std::fmt::Display for FolderRefusal {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            FolderRefusal::BadName => f.write_str("a folder name of 1 to 200 letters, without control characters"),
            FolderRefusal::Separator(separator) => {
                write!(f, "a folder name can not have \"{separator}\" in it on this server")
            }
            FolderRefusal::Special => f.write_str("the Inbox and the special folders can not be renamed or deleted"),
        }
    }
}

/// The separator of folder names of an account: the one its folders have, `/` when the server named none
fn separator_of(store: &Store, account: AccountId) -> pe_store::Result<String> {
    Ok(store
        .folders(account)?
        .into_iter()
        .find_map(|f| f.info.delimiter.filter(|d| !d.is_empty()))
        .unwrap_or_else(|| "/".to_string()))
}

/// A folder name as typed, checked
fn checked_name(name: &str, separator: &str) -> std::result::Result<String, FolderRefusal> {
    let name = name.trim();
    if name.is_empty() || name.chars().count() > 200 || name.chars().any(char::is_control) {
        return Err(FolderRefusal::BadName);
    }
    if name.contains(separator) {
        return Err(FolderRefusal::Separator(separator.to_string()));
    }
    Ok(name.to_string())
}

/// A folder name for `account` as typed, checked: before anything goes to the server
pub fn folder_name(
    store: &Store,
    account: AccountId,
    name: &str,
) -> pe_store::Result<std::result::Result<String, FolderRefusal>> {
    Ok(checked_name(name, &separator_of(store, account)?))
}

/// The path of a new folder `name` under `parent`, or at the top: under the prefix of the server's personal namespace
/// (`INBOX.` on servers that keep every folder under the Inbox), as the server says
pub fn new_folder_path(
    store: &Store,
    account: AccountId,
    parent: Option<FolderId>,
    name: &str,
    namespace: Option<&pe_imap::client::Namespace>,
) -> pe_store::Result<std::result::Result<String, FolderRefusal>> {
    let parent = parent.map(|parent| store.folder(parent)).transpose()?;
    let separator = match parent
        .as_ref()
        .and_then(|p| p.info.delimiter.clone())
        .filter(|d| !d.is_empty())
    {
        Some(separator) => separator,
        None => separator_of(store, account)?,
    };
    let name = match checked_name(name, &separator) {
        Ok(name) => name,
        Err(refusal) => return Ok(Err(refusal)),
    };
    Ok(Ok(match parent {
        Some(parent) => format!("{}{separator}{name}", parent.info.path),
        None => format!("{}{name}", namespace.map_or("", |n| n.prefix.as_str())),
    }))
}

/// The path `folder` gets when renamed to `name`: the same parent, the new last part
pub fn renamed_path(
    store: &Store,
    folder: FolderId,
    name: &str,
) -> pe_store::Result<std::result::Result<String, FolderRefusal>> {
    let folder = store.folder(folder)?;
    if is_special(&folder.info) {
        return Ok(Err(FolderRefusal::Special));
    }
    let separator = match folder.info.delimiter.clone().filter(|d| !d.is_empty()) {
        Some(separator) => separator,
        None => separator_of(store, folder.account_id)?,
    };
    let name = match checked_name(name, &separator) {
        Ok(name) => name,
        Err(refusal) => return Ok(Err(refusal)),
    };
    Ok(Ok(match folder.info.path.rsplit_once(separator.as_str()) {
        Some((parent, _)) => format!("{parent}{separator}{name}"),
        None => name,
    }))
}

/// The Inbox and the folders with a special use, which are not renamed or deleted
pub fn is_special(folder: &pe_store::FolderInfo) -> bool {
    folder.path.eq_ignore_ascii_case("INBOX") || folder.special_use.is_some()
}

/// Creates a folder on the server and subscribes to it; the folder list is the caller's to sync
pub async fn create_folder(client: &mut Client, path: &str) -> Result<()> {
    client.create(path).await?;
    // some servers list only subscribed folders to other mail programs
    let _ = client.subscribe(path).await;
    Ok(())
}

/// Renames a folder on the server (its subfolders go with it); the folder list is the caller's to sync
pub async fn rename_folder(client: &mut Client, store: &mut Store, folder: FolderId, new_path: &str) -> Result<()> {
    let path = store.folder(folder)?.info.path;
    if client.selected().is_some_and(|selected| selected.path == path) {
        client.unselect().await?;
    }
    client.rename(&path, new_path).await?;
    let _ = client.unsubscribe(&path).await;
    let _ = client.subscribe(new_path).await;
    Ok(())
}

/// Deletes a folder, the folders in it and their messages on the server, the deepest first: IMAP's DELETE leaves
/// subfolders behind (or refuses a folder that has some). The folder list is the caller's to sync.
pub async fn delete_folder(client: &mut Client, store: &mut Store, folder: FolderId) -> Result<()> {
    let found = store.folder(folder)?;
    let path = found.info.path;
    let mut doomed: Vec<String> = match found.info.delimiter.filter(|d| !d.is_empty()) {
        Some(delimiter) => {
            let inside = format!("{path}{delimiter}");
            store
                .folders(found.account_id)?
                .into_iter()
                .map(|f| f.info.path)
                .filter(|p| p.starts_with(&inside))
                .collect()
        }
        None => Vec::new(),
    };
    // the deepest first, the folder itself last
    doomed.sort_by_key(|p| std::cmp::Reverse(p.len()));
    doomed.push(path);
    // a selected folder that goes away can end the connection (Dovecot says BYE)
    if client
        .selected()
        .is_some_and(|selected| doomed.contains(&selected.path))
    {
        client.unselect().await?;
    }
    for path in doomed {
        client.delete(&path).await?;
        let _ = client.unsubscribe(&path).await;
    }
    Ok(())
}

/// Applies a change the server reported for the selected folder of `account`
pub fn apply_event(store: &mut Store, account: AccountId, event: &Event) -> Result<Change> {
    let mailbox = match event {
        Event::Exists { mailbox, .. }
        | Event::Expunge { mailbox, .. }
        | Event::Vanished { mailbox, .. }
        | Event::Flags { mailbox, .. } => mailbox,
        Event::Alert(_) | Event::Closed(_) => return Ok(Change::None),
    };
    let Some(folder) = store.find_folder(account, mailbox)? else {
        return Ok(Change::None);
    };
    let folder = folder.id;
    let change = match event {
        Event::Flags {
            uid: Some(uid),
            flags,
            modseq,
            ..
        } => Change::updated_if(store.set_flags(folder, *uid, flags, *modseq)?, folder),
        Event::Vanished { uids, .. } => {
            let largest = store.max_uid(folder)?.unwrap_or(0);
            let gone = uids.expand(largest).unwrap_or_default();
            let removed = store.transaction(|store| store.remove_messages(folder, &gone))?;
            Change::updated_if(removed > 0, folder)
        }
        // a FLAGS without UID, EXISTS and EXPUNGE are about sequence numbers
        _ => Change::NeedsSync(folder),
    };
    Ok(change)
}

/// The engine runs these on a multi-threaded runtime: they have to stay `Send`
#[allow(dead_code)]
fn futures_are_send(client: &mut Client, store: &mut Store, event: &Event) {
    fn send<T: Send>(_: T) {}
    send(sync_folders(&mut *client, &mut *store, 1));
    send(sync_folder(&mut *client, &mut *store, 1));
    send(fetch_source(&mut *client, &mut *store, 1, 1));
    send(set_flag(&mut *client, &mut *store, 1, 1, "\\Seen", true));
    let _ = apply_event(store, 1, event);
}

#[cfg(test)]
mod tests {
    use super::*;

    fn folder(path: &str, special: Option<&str>) -> pe_store::FolderInfo {
        pe_store::FolderInfo {
            path: path.into(),
            name: path.rsplit('.').next().unwrap().into(),
            delimiter: Some(".".into()),
            flags: Vec::new(),
            special_use: special.map(str::to_string),
            subscribed: true,
            selectable: true,
        }
    }

    #[test]
    fn folders_in_tree_order() {
        let paths = |folders: Vec<pe_store::FolderInfo>| -> Vec<String> {
            tree_order(folders).into_iter().map(|f| f.path).collect()
        };
        // the special folders first as listed, a subfolder of Archive listed last
        let listed = vec![
            folder("INBOX", None),
            folder("Sent", Some("\\Sent")),
            folder("Archive", Some("\\Archive")),
            folder("Trash", Some("\\Trash")),
            folder("Archive.2024", None),
            folder("Work", None),
            folder("Archive.2024.Q1", None),
            folder("Orphan.Child", None),
        ];
        assert_eq!(
            paths(listed),
            [
                "INBOX",
                "Sent",
                "Archive",
                "Archive.2024",
                "Archive.2024.Q1",
                "Trash",
                "Work",
                "Orphan.Child"
            ]
        );
        // deep nesting does not recurse
        let deep: Vec<_> = (1..2000).map(|n| folder(&vec!["a"; n].join("."), None)).collect();
        assert_eq!(tree_order(deep).len(), 1999);
    }

    #[test]
    fn folder_names_and_paths() {
        let store = Store::open_in_memory().unwrap();
        let account = store
            .add_account(&pe_store::AccountSettings {
                name: "T".into(),
                email: "t@example.com".into(),
                username: "t".into(),
                imap_host: "imap.example.com".into(),
                imap_port: 993,
                imap_security: pe_store::Security::Tls,
                smtp_host: "smtp.example.com".into(),
                smtp_port: 465,
                smtp_security: pe_store::Security::Tls,
                auth: pe_store::Auth::Password,
            })
            .unwrap();
        // a server that keeps its folders under the Inbox
        store
            .set_folders(
                account,
                &[
                    folder("INBOX", None),
                    folder("INBOX.Sent", Some("\\Sent")),
                    folder("INBOX.Work", None),
                ],
            )
            .unwrap();
        let id = |path: &str| store.find_folder(account, path).unwrap().unwrap().id;
        let namespace = pe_imap::client::Namespace {
            prefix: "INBOX.".into(),
            delimiter: Some(".".into()),
        };
        let path = |parent, name| new_folder_path(&store, account, parent, name, Some(&namespace)).unwrap();
        assert_eq!(path(None, " Projects "), Ok("INBOX.Projects".into()));
        assert_eq!(
            new_folder_path(&store, account, None, "Top", None).unwrap(),
            Ok("Top".into())
        );
        assert_eq!(
            folder_name(&store, account, "a.b").unwrap(),
            Err(FolderRefusal::Separator(".".into()))
        );
        assert_eq!(path(Some(id("INBOX.Work")), "2024"), Ok("INBOX.Work.2024".into()));
        assert_eq!(path(None, "a.b"), Err(FolderRefusal::Separator(".".into())));
        assert_eq!(path(None, "  "), Err(FolderRefusal::BadName));
        assert_eq!(path(None, "tab\there"), Err(FolderRefusal::BadName));
        assert_eq!(
            renamed_path(&store, id("INBOX.Work"), "Jobs").unwrap(),
            Ok("INBOX.Jobs".into())
        );
        assert_eq!(
            renamed_path(&store, id("INBOX"), "Mail").unwrap(),
            Err(FolderRefusal::Special)
        );
        assert_eq!(
            renamed_path(&store, id("INBOX.Sent"), "Out").unwrap(),
            Err(FolderRefusal::Special)
        );
    }

    #[test]
    fn depths_count_listed_ancestors() {
        let folders = [
            folder("INBOX", None),
            folder("Archive", None),
            folder("Archive.2024", None),
            folder("Archive.2024.Q1", None),
            folder("Hidden.Child", None),
        ];
        assert_eq!(tree_depths(&folders.iter().collect::<Vec<_>>()), [0, 0, 1, 2, 0]);
    }
}
