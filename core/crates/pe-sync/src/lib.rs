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
    let folders: Vec<FolderInfo> = listed.into_iter().map(folder_info).collect();
    store.transaction(|store| store.set_folders(account, &folders))?;
    Ok(store.folders(account)?)
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
