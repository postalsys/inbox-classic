//! Keeps the local store in step with an IMAP account: the folder list, the messages of a folder
//! (new ones, flag changes, deletions, a new UIDVALIDITY) and message sources fetched on demand.
//! Changes the server reports while a folder is selected are applied as they arrive.
#![forbid(unsafe_code)]

mod summary;
mod text_first;

pub use text_first::{SHOWN_FIRST_LIMIT, TextFirst, fetch_text_first};

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
        // the ids it answers, and Gmail's conversation, for conversations
        headers: Some(vec!["References".into()]),
        gmail_thread: true,
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
    let source = fetch_raw(client, store, folder, uid).await?;
    store.set_source(folder, uid, &source)?;
    Ok(source)
}

/// `length` bytes of a message as the server keeps it, from `from` on (fewer at its end); None when the server no
/// longer has it
pub async fn fetch_range(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    uid: u64,
    from: u64,
    length: u64,
) -> Result<Vec<u8>> {
    select_folder(client, store, folder).await?;
    let query = FetchQuery {
        source: true,
        source_range: Some((from, length)),
        ..Default::default()
    };
    let fetched = client.fetch(&Messages::uid(uid), &query).await?;
    fetched
        .into_iter()
        .find(|m| m.uid == Some(uid))
        .and_then(|m| m.source)
        .ok_or(Error::MessageGone)
}

/// A message as the server keeps it, fetched without keeping it in the store (one on its way to another account,
/// whose row is out of the list already)
pub async fn fetch_raw(client: &mut Client, store: &mut Store, folder: FolderId, uid: u64) -> Result<Vec<u8>> {
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    let query = FetchQuery {
        source: true,
        ..Default::default()
    };
    let fetched = client.fetch(&Messages::uid(uid), &query).await?;
    fetched
        .into_iter()
        .find(|m| m.uid == Some(uid))
        .and_then(|m| m.source)
        .ok_or(Error::MessageGone)
}

/// The sources of these messages of a folder, as the server keeps them, in one FETCH, without keeping them in the
/// store (the caller does, one at a time): (UID, source). A message the server no longer has is left out.
pub async fn fetch_sources(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    uids: &[u64],
) -> Result<Vec<(u64, Vec<u8>)>> {
    let Some(set) = SequenceSet::from_numbers(uids) else {
        return Ok(Vec::new());
    };
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    let query = FetchQuery {
        source: true,
        ..Default::default()
    };
    let mut found = Vec::with_capacity(uids.len());
    client
        .fetch_each(&Messages::Uids(set), &query, &mut |message| {
            if let (Some(uid), Some(source)) = (message.uid, message.source)
                && uids.contains(&uid)
            {
                found.push((uid, source));
            }
        })
        .await?;
    Ok(found)
}

/// Whether `folder` on the server has a message with this Message-ID
pub async fn has_message_id(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    message_id: &str,
) -> Result<bool> {
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    Ok(!with_message_id(client, message_id, false).await?.is_empty())
}

/// The text part of a message, fetched for the search index (only that part, and only its start), with what decoding it
/// needs: the bytes as the server keeps them
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TextPart {
    /// `text/plain` or `text/html`
    pub content_type: String,
    pub charset: Option<String>,
    /// The transfer encoding, lowercase
    pub encoding: Option<String>,
    pub bytes: Vec<u8>,
}

/// The text parts of these messages of a folder for the search index (see `BodyStructure::text_parts`), at most
/// `limit` bytes of each, in the message's order. Nothing for a message without one, or one the server no longer has.
/// Neither marks a message read (BODY.PEEK) nor caches anything.
pub async fn fetch_texts(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    uids: &[u64],
    limit: u64,
) -> Result<Vec<(u64, Vec<TextPart>)>> {
    let Some(set) = SequenceSet::from_numbers(uids) else {
        return Ok(Vec::new());
    };
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    let query = FetchQuery {
        body_structure: true,
        ..Default::default()
    };
    let structures = client.fetch(&Messages::Uids(set), &query).await?;
    // each message's parts, and the messages by part number: most want the same few, one FETCH each
    let mut found: Vec<(u64, Vec<TextPart>)> = Vec::new();
    let mut by_section: std::collections::BTreeMap<String, Vec<(usize, usize)>> = Default::default();
    for message in structures {
        let (Some(uid), Some(structure)) = (message.uid, message.body_structure) else {
            continue;
        };
        let parts = structure.text_parts();
        if parts.is_empty() {
            continue;
        }
        let at = found.len();
        let mut texts = Vec::new();
        for (index, part) in parts.into_iter().enumerate() {
            by_section.entry(part.section()).or_default().push((at, index));
            texts.push(TextPart {
                content_type: part.content_type.clone(),
                charset: part.parameters.get("charset").cloned(),
                encoding: part.encoding.clone(),
                bytes: Vec::new(),
            });
        }
        found.push((uid, texts));
    }
    for (section, wanted) in by_section {
        let numbers: Vec<u64> = wanted.iter().map(|(at, _)| found[*at].0).collect();
        let Some(set) = SequenceSet::from_numbers(&numbers) else {
            continue;
        };
        let query = FetchQuery {
            parts: vec![section.clone()],
            part_limit: Some(limit),
            ..Default::default()
        };
        for message in client.fetch(&Messages::Uids(set), &query).await? {
            let Some(bytes) = message.parts.get(&section) else {
                continue;
            };
            if let Some((at, index)) = wanted.iter().find(|(at, _)| Some(found[*at].0) == message.uid) {
                found[*at].1[*index].bytes = bytes.clone();
            }
        }
    }
    for (_, texts) in &mut found {
        texts.retain(|text| !text.bytes.is_empty());
    }
    Ok(found)
}

/// Selects a folder of the store unless it is the selected one
pub async fn select_folder(client: &mut Client, store: &mut Store, folder: FolderId) -> Result<()> {
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await
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
    uids: &[u64],
    flag: &str,
    on: bool,
) -> Result<()> {
    if on {
        change_flags(client, store, folder, uids, &[flag], &[]).await
    } else {
        change_flags(client, store, folder, uids, &[], &[flag]).await
    }
}

/// Adds flags to messages of a folder on the server and takes others away: at most one command for each. Keywords
/// the folder does not keep ($Junk, a colour bit) are left out: the server would refuse them, and nothing else
/// depends on them.
pub async fn change_flags(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    uids: &[u64],
    add: &[&str],
    remove: &[&str],
) -> Result<()> {
    let Some(set) = SequenceSet::from_numbers(uids) else {
        return Ok(());
    };
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    let permanent: Vec<String> = client.selected().map(|s| s.permanent_flags.clone()).unwrap_or_default();
    let kept = |flags: &[&str]| -> Vec<String> {
        flags
            .iter()
            .filter(|f| keeps_flag(&permanent, f))
            .map(|f| f.to_string())
            .collect()
    };
    // the store has the change already: the flags the server would report for it could overwrite a newer one
    for (action, flags) in [(StoreAction::Add, kept(add)), (StoreAction::Remove, kept(remove))] {
        if !flags.is_empty() {
            let flags: Vec<&str> = flags.iter().map(String::as_str).collect();
            client
                .store_silent(&Messages::Uids(set.clone()), action, &flags)
                .await?;
        }
    }
    Ok(())
}

/// Whether a folder with these PERMANENTFLAGS keeps `flag`: the system flags always, a keyword when it is listed or
/// new ones may be made (`\*`), and anything when the server did not say (RFC 9051 7.1)
fn keeps_flag(permanent: &[String], flag: &str) -> bool {
    flag.starts_with('\\')
        || permanent.is_empty()
        || permanent.iter().any(|f| f == "\\*" || f.eq_ignore_ascii_case(flag))
}

/// Moves a message to another folder of the account on the server (MOVE, or COPY and expunge where the server has
/// no MOVE). The store is the caller's to change; the folder it went to is the caller's to sync. Returns the UIDs the
/// messages got there, by the UIDs they had, where the server says (UIDPLUS).
pub async fn move_message(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    uids: &[u64],
    to: FolderId,
) -> Result<Vec<(u64, u64)>> {
    let Some(set) = SequenceSet::from_numbers(uids) else {
        return Ok(Vec::new());
    };
    let (from, to) = (store.folder(folder)?.info.path, store.folder(to)?.info.path);
    ensure_selected(client, &from).await?;
    let copied = client.move_messages(&Messages::Uids(set), &to).await?;
    Ok(copied.map(|copied| moved_pairs(&copied)).unwrap_or_default())
}

/// The UIDs messages had and the UIDs they got (COPYUID, in the order of the source UIDs); nothing when the two
/// sets do not match
fn moved_pairs(copied: &pe_imap::client::CopyUid) -> Vec<(u64, u64)> {
    match (copied.source.expand(u64::MAX), copied.destination.expand(u64::MAX)) {
        (Some(from), Some(to)) if from.len() == to.len() => from.into_iter().zip(to).collect(),
        _ => Vec::new(),
    }
}

/// Copies messages to another folder of the account on the server (UID COPY); the folder they went to is the
/// caller's to sync
pub async fn copy_messages(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    uids: &[u64],
    to: FolderId,
) -> Result<()> {
    let Some(set) = SequenceSet::from_numbers(uids) else {
        return Ok(());
    };
    let (from, to) = (store.folder(folder)?.info.path, store.folder(to)?.info.path);
    ensure_selected(client, &from).await?;
    client.copy(&Messages::Uids(set), &to).await?;
    Ok(())
}

/// The References of messages of `folder` (stored before they were kept), by UID: one FETCH of that header field
pub async fn fetch_references(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    uids: &[u64],
) -> Result<Vec<(u64, Vec<String>)>> {
    let Some(set) = SequenceSet::from_numbers(uids) else {
        return Ok(Vec::new());
    };
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    let query = FetchQuery {
        headers: Some(vec!["References".into()]),
        ..Default::default()
    };
    Ok(client
        .fetch(&Messages::Uids(set), &query)
        .await?
        .into_iter()
        .filter_map(|m| Some((m.uid?, summary::references_of(m.headers.as_deref().unwrap_or_default()))))
        .collect())
}

/// Gmail's labels that say what a message is rather than where it was filed: they stay when it is archived
const STATE_LABELS: [&str; 4] = ["\\Sent", "\\Draft", "\\Starred", "\\Important"];

/// Whether the account's server is Gmail's: labels (X-GM-EXT-1) over an All Mail folder that holds every message,
/// where an archive takes every label away. A server with the extension but no All Mail is not taken for Gmail.
pub fn has_labels(client: &Client, store: &Store, account: AccountId) -> Result<bool> {
    Ok(client.has_capability("X-GM-EXT-1") && store.special_folder(account, "\\All")?.is_some())
}

/// The Gmail label a message has for being in the folder at `path`: `\\Inbox` for the Inbox, the folder's own name
/// (as the server names it) for a label folder
pub fn folder_label(path: &str) -> String {
    if path.eq_ignore_ascii_case("INBOX") {
        "\\Inbox".into()
    } else {
        path.to_string()
    }
}

/// Archives messages on Gmail: `\\Inbox` and every label folder's label taken off them, so they are left in All Mail
/// only; the state labels (sent, draft, starred, important) stay. Returns the labels each one lost, by UID, for an
/// Undo to put back.
pub async fn archive_labels(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    uids: &[u64],
) -> Result<Vec<(u64, Vec<String>)>> {
    let Some(set) = SequenceSet::from_numbers(uids) else {
        return Ok(Vec::new());
    };
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    let messages = Messages::Uids(set);
    let query = FetchQuery {
        gmail_labels: true,
        ..Default::default()
    };
    let lost: Vec<(u64, Vec<String>)> = client
        .fetch(&messages, &query)
        .await?
        .into_iter()
        .filter_map(|m| {
            let mut labels: Vec<String> = m
                .labels
                .unwrap_or_default()
                .into_iter()
                .filter(|label| !STATE_LABELS.iter().any(|kept| kept.eq_ignore_ascii_case(label)))
                .collect();
            // in a folder a message has its label, whether or not the server lists it
            let own = folder_label(&path);
            if !labels.iter().any(|l| l.eq_ignore_ascii_case(&own)) {
                labels.push(own);
            }
            Some((m.uid?, labels))
        })
        .collect();
    // one command for all of them: taking away a label a message does not have changes nothing
    let mut every: Vec<String> = lost.iter().flat_map(|(_, labels)| labels.iter().cloned()).collect();
    every.sort();
    every.dedup();
    if !every.is_empty() {
        client.store_labels(&messages, StoreAction::Remove, &every).await?;
    }
    Ok(lost)
}

/// Puts labels back on messages of `folder` (All Mail), as [`archive_labels`] took them: each found on the server by
/// its Message-ID (one search each, so All Mail need not be in the store), one command a set of labels
pub async fn restore_labels(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    labelled: &[(String, Vec<String>)],
) -> Result<()> {
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    let mut by_labels: std::collections::BTreeMap<&[String], Vec<u64>> = std::collections::BTreeMap::new();
    for (message_id, labels) in labelled {
        if labels.is_empty() || message_id.trim().is_empty() {
            continue;
        }
        // SEARCH HEADER matches a part of the header: only the messages whose Message-ID is this one, whole
        let found = client
            .search(&SearchKey::Header("Message-ID".into(), message_id.clone()))
            .await?;
        let Some(set) = SequenceSet::from_numbers(&found) else {
            continue;
        };
        let query = FetchQuery {
            headers: Some(vec!["Message-ID".into()]),
            ..Default::default()
        };
        let same: Vec<u64> = client
            .fetch(&Messages::Uids(set), &query)
            .await?
            .into_iter()
            .filter(|m| m.headers.as_deref().and_then(header_message_id).as_deref() == Some(message_id.trim()))
            .filter_map(|m| m.uid)
            .collect();
        by_labels.entry(labels.as_slice()).or_default().extend(same);
    }
    for (labels, uids) in by_labels {
        if let Some(set) = SequenceSet::from_numbers(&uids) {
            client
                .store_labels(&Messages::Uids(set), StoreAction::Add, labels)
                .await?;
        }
    }
    Ok(())
}

/// The Message-ID of a header block that holds it (`Message-ID: <a@b>`, folded or not), trimmed
fn header_message_id(header: &[u8]) -> Option<String> {
    let text = String::from_utf8_lossy(header);
    let unfolded = text.replace("\r\n ", " ").replace("\r\n\t", " ").replace("\n ", " ");
    unfolded.lines().find_map(|line| {
        let (name, value) = line.split_once(':')?;
        name.trim()
            .eq_ignore_ascii_case("Message-ID")
            .then(|| value.trim().to_string())
    })
}

/// The account's Archive folder: the one the server names for it, or one made at the top (with its special use
/// where the server takes that, named "Archive" so that every server and mail program knows it otherwise). The folder
/// list is synced by the caller when it was made, which `made` says.
pub async fn archive_folder(
    client: &mut Client,
    store: &mut Store,
    account: AccountId,
) -> Result<(std::result::Result<String, FolderRefusal>, bool)> {
    if let Some(folder) = store.special_folder(account, "\\Archive")? {
        return Ok((Ok(folder.info.path), false));
    }
    let namespace = client.namespace().cloned();
    let path = match new_folder_path(store, account, None, "Archive", namespace.as_ref())? {
        Ok(path) => path,
        Err(refusal) => return Ok((Err(refusal), false)),
    };
    let made = client.create_special(&path, "\\Archive").await?;
    let _ = client.subscribe(&path).await;
    Ok((Ok(path), made))
}

/// Deletes messages for good on the server: `\\Deleted`, then expunged. With UIDPLUS only these messages are
/// expunged; without it, EXPUNGE takes every message of the folder marked deleted, as other mail programs do too.
pub async fn expunge_messages(client: &mut Client, store: &mut Store, folder: FolderId, uids: &[u64]) -> Result<()> {
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    expunge_uids(client, uids).await
}

/// Removes these messages of the selected folder for good
async fn expunge_uids(client: &mut Client, uids: &[u64]) -> Result<()> {
    let Some(set) = SequenceSet::from_numbers(uids) else {
        return Ok(());
    };
    client
        .store(&Messages::Uids(set.clone()), StoreAction::Add, &["\\Deleted"])
        .await?;
    match client.expunge(Some(&set)).await {
        Err(pe_imap::Error::Unsupported(_)) => client.expunge(None).await?,
        other => other?,
    }
    Ok(())
}

/// The messages of the selected folder with this Message-ID (`drafts`: only those with the \\Draft flag). SEARCH HEADER
/// matches any part of the header, so what it finds is checked: the same ID (case and spaces aside). A draft opened
/// again whose ID is `<` must not take the others with it.
async fn with_message_id(client: &mut Client, message_id: &str, drafts: bool) -> Result<Vec<u64>> {
    let found = client
        .search(&SearchKey::Header("Message-ID".into(), message_id.into()))
        .await?;
    let Some(set) = SequenceSet::from_numbers(&found) else {
        return Ok(Vec::new());
    };
    let query = FetchQuery {
        flags: drafts,
        envelope: true,
        ..Default::default()
    };
    let fetched = client.fetch(&Messages::Uids(set), &query).await?;
    Ok(fetched
        .into_iter()
        .filter(|m| has_id(m, message_id) && (!drafts || is_draft(m)))
        .filter_map(|m| m.uid)
        .collect())
}

fn has_id(message: &pe_imap::client::FetchedMessage, message_id: &str) -> bool {
    message
        .envelope
        .as_ref()
        .and_then(|e| e.message_id.as_deref())
        .is_some_and(|id| id.trim().eq_ignore_ascii_case(message_id.trim()))
}

fn is_draft(message: &pe_imap::client::FetchedMessage) -> bool {
    message
        .flags
        .as_ref()
        .is_some_and(|flags| flags.iter().any(|f| f.eq_ignore_ascii_case("\\Draft")))
}

/// Saves a draft in the Drafts folder `folder` in place of its earlier copies, the ones with its Message-ID. They
/// are looked up before the new copy goes in and removed after it is there, so a save that fails keeps the last one.
pub async fn save_draft(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    raw: &[u8],
    message_id: &str,
    date: i64,
) -> Result<()> {
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    let earlier = with_message_id(client, message_id, true).await?;
    client.append(&path, raw, &["\\Draft", "\\Seen"], Some(date)).await?;
    expunge_uids(client, &earlier).await
}

/// Removes the drafts with this Message-ID from the Drafts folder `folder`: the message was sent
pub async fn remove_drafts(client: &mut Client, store: &mut Store, folder: FolderId, message_id: &str) -> Result<()> {
    let path = store.folder(folder)?.info.path;
    ensure_selected(client, &path).await?;
    let drafts = with_message_id(client, message_id, true).await?;
    expunge_uids(client, &drafts).await
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
    send(set_flag(&mut *client, &mut *store, 1, &[1], "\\Seen", true));
    let _ = apply_event(store, 1, event);
}

#[cfg(test)]
mod archive_tests {
    use super::header_message_id;

    #[test]
    fn reads_the_message_id_of_a_header() {
        assert_eq!(
            header_message_id(b"Message-ID: <a@b>\r\n\r\n").as_deref(),
            Some("<a@b>")
        );
        assert_eq!(
            header_message_id(b"message-id:\r\n <a@b>\r\n").as_deref(),
            Some("<a@b>")
        );
        assert_eq!(header_message_id(b"Subject: x\r\n"), None);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keeps_keywords_the_folder_takes() {
        let flags = |list: &[&str]| list.iter().map(|f| f.to_string()).collect::<Vec<_>>();
        assert!(keeps_flag(&flags(&["\\Seen"]), "\\Flagged"));
        assert!(keeps_flag(&[], "$Junk"));
        assert!(keeps_flag(&flags(&["\\Seen", "\\*"]), "$Junk"));
        assert!(keeps_flag(&flags(&["\\Seen", "$junk"]), "$Junk"));
        assert!(!keeps_flag(&flags(&["\\Seen", "\\Flagged"]), "$Junk"));
    }

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
