//! The workers of an account: the main one runs the commands the windows send, one at a time, on the account's
//! IMAP connection, connecting when there is none, and applies what the server reports meanwhile; the reader,
//! on a connection of its own, only downloads the messages the user opens, so one opened during a long sync (the
//! first of a new account) comes at once and not after it.

use std::collections::{BTreeSet, HashMap};

use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;

use pe_imap::{Client, Credentials, ErrorKind, Event as ImapEvent};
use pe_net::Trust;
use pe_store::{AccountId, FolderId, Store};
use pe_sync::{
    Change, apply_event, copy_messages, expunge_messages, fetch_source, imap_config, move_message, set_flag,
    smtp_config, sync_folder, sync_folders,
};
use tokio::sync::mpsc::{UnboundedReceiver, error::TryRecvError};

use pe_i18n::{Text, tr, tr_args};

use crate::{Event, EventSink, FailureKind, Secrets};

mod transfer;

#[derive(Debug, PartialEq, Eq)]
pub(crate) enum Command {
    Sync,
    FetchSource {
        folder: FolderId,
        uid: u64,
    },
    SetFlag {
        folder: FolderId,
        uids: Vec<u64>,
        flag: &'static str,
        on: bool,
    },
    /// Flags added and taken away in one go (a flag's colour)
    SetFlags {
        folder: FolderId,
        uids: Vec<u64>,
        add: Vec<&'static str>,
        remove: Vec<&'static str>,
    },
    /// `removed` are the rows taken out of the store, put back when the server does not do it
    Move {
        folder: FolderId,
        uids: Vec<u64>,
        to: FolderId,
        removed: Vec<pe_store::MessageInfo>,
    },
    /// a copy of messages into another folder of the account
    Copy {
        folder: FolderId,
        uids: Vec<u64>,
        to: FolderId,
    },
    /// messages archived: into the Archive folder (made when there is none), on Gmail with their labels taken off;
    /// `removed` as for [`Command::Move`]
    Archive {
        folder: FolderId,
        uids: Vec<u64>,
        removed: Vec<pe_store::MessageInfo>,
    },
    /// messages deleted for good; `removed` as for [`Command::Move`]
    Expunge {
        folder: FolderId,
        uids: Vec<u64>,
        removed: Vec<pe_store::MessageInfo>,
    },
    /// A message from a file into a folder, read
    Append {
        folder: FolderId,
        raw: Vec<u8>,
        date: Option<i64>,
    },
    CreateFolder {
        parent: Option<FolderId>,
        name: String,
    },
    RenameFolder {
        folder: FolderId,
        path: String,
    },
    DeleteFolder {
        folder: FolderId,
    },
    /// Into the Outbox, and sent from there; not before `not_before` when it is given (seconds since the Unix epoch)
    Send {
        outgoing: Box<crate::Outgoing>,
        not_before: Option<i64>,
    },
    SendOutbox,
    /// Edit > Undo: messages back to the folders they came from (selection.rs)
    UndoMoves {
        moves: Vec<crate::selection::UndoMove>,
    },
    /// The messages waiting in the store to go from this account to folders of others (transfer.rs)
    Transfer,
    /// Into the Drafts folder, in place of the earlier copy; `outgoing` has its Message-ID
    SaveDraft {
        outgoing: Box<crate::Outgoing>,
    },
}

/// A failed command, for [`Event::Failed`]
struct Failure {
    kind: FailureKind,
    message: String,
}

impl From<pe_imap::Error> for Failure {
    fn from(error: pe_imap::Error) -> Self {
        let kind = match error.kind() {
            ErrorKind::Network | ErrorKind::Closed => FailureKind::Network,
            ErrorKind::Security => FailureKind::Security,
            ErrorKind::Authentication => FailureKind::Authentication,
            _ => FailureKind::Other,
        };
        Failure {
            kind,
            message: error.to_string(),
        }
    }
}

/// A login with a sign-in app's token that the mail server refused: most likely the app's scopes do not give mail
/// access, which is easy to get wrong when filling one in
fn scope_hint(failure: Failure, account: &pe_store::Account) -> Failure {
    let from_app = matches!(
        crate::SignInWith::of_auth_kind(&account.settings.auth),
        Some(crate::SignInWith::App(_))
    );
    if failure.kind != FailureKind::Authentication || !from_app {
        return failure;
    }
    Failure {
        message: tr_args(
            Text::ErrorAppScopes,
            &[("reason", failure.message.trim_end_matches('.').into())],
        ),
        ..failure
    }
}

impl From<pe_sync::Error> for Failure {
    fn from(error: pe_sync::Error) -> Self {
        match error {
            pe_sync::Error::Imap(error) => error.into(),
            other => Failure {
                kind: FailureKind::Other,
                message: other.to_string(),
            },
        }
    }
}

impl From<pe_smtp::Error> for Failure {
    fn from(error: pe_smtp::Error) -> Self {
        let kind = match error.kind() {
            pe_smtp::ErrorKind::Network => FailureKind::Network,
            pe_smtp::ErrorKind::Security => FailureKind::Security,
            pe_smtp::ErrorKind::Authentication => FailureKind::Authentication,
            _ => FailureKind::Other,
        };
        Failure {
            kind,
            message: error.to_string(),
        }
    }
}

impl From<crate::ComposeError> for Failure {
    fn from(error: crate::ComposeError) -> Self {
        Failure {
            kind: FailureKind::Other,
            message: error.to_string(),
        }
    }
}

impl From<pe_store::Error> for Failure {
    fn from(error: pe_store::Error) -> Self {
        pe_sync::Error::Store(error).into()
    }
}

type Outcome = Result<(), Failure>;

/// Builds a message from an account with `compose` (its attachments read now, off the threads that run the network)
async fn build(
    settings: pe_store::AccountSettings,
    outgoing: crate::Outgoing,
    time: i64,
    compose: fn(&pe_store::AccountSettings, &crate::Outgoing, i64) -> Result<pe_smtp::Message, crate::ComposeError>,
) -> Result<pe_smtp::Built, Failure> {
    tokio::task::spawn_blocking(move || compose(&settings, &outgoing, time).map(|message| pe_smtp::build(&message)))
        .await
        .map_err(|_| Failure {
            kind: FailureKind::Other,
            message: tr(Text::ErrorNotBuilt),
        })?
        .map_err(Failure::from)
}

/// Seconds since the Unix epoch
/// Seconds since the Unix epoch
pub(crate) fn unix_now() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_or(0, |d| d.as_secs() as i64)
}

/// A send that did not go: the reason, and that the message waits in the Outbox
fn kept(failure: Failure, waiting: usize) -> Failure {
    let note = tr_args(Text::ErrorOutboxWaits, &[("count", waiting.into())]);
    Failure {
        kind: failure.kind,
        message: format!("{} ({note})", failure.message),
    }
}

/// The access token of an OAuth account and when it runs out, shared by its two workers so a token is refreshed once,
/// not by each (a provider that rotates refresh tokens would take the second refresh as a replay)
pub(crate) type SharedToken = Arc<tokio::sync::Mutex<Option<(String, i64)>>>;

/// The [`SharedToken`] of every account: a worker that connects to another account for once (a draft to remove, a
/// message moved between accounts) uses that account's, so the token is still refreshed once
pub(crate) type Tokens = Arc<std::sync::Mutex<std::collections::HashMap<AccountId, SharedToken>>>;

/// The token `account` uses, made when it has none yet
pub(crate) fn token_of(tokens: &Tokens, account: AccountId) -> SharedToken {
    tokens
        .lock()
        .unwrap_or_else(|p| p.into_inner())
        .entry(account)
        .or_default()
        .clone()
}

/// What a worker does: everything but opening messages, or only that
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Role {
    Main,
    Reader,
}

pub(crate) struct Worker {
    account: AccountId,
    role: Role,
    path: PathBuf,
    secrets: Secrets,
    trust: Trust,
    oauth: crate::OAuthProviders,
    access_token: SharedToken,
    tokens: Tokens,
    events: EventSink,
    connection: Option<(Client, UnboundedReceiver<ImapEvent>)>,
    /// A server event that woke the Inbox from IDLE, applied first with the rest
    held: Option<ImapEvent>,
    /// The UIDNEXT of the Inbox the last wait synced it for (Wake::Behind)
    behind: Option<u64>,
    /// A command ran since the last wait: what the server has to tell since then comes with a NOOP
    worked: bool,
    /// The Gmail labels archived messages lost, by Message-ID, for Undo to put back
    archived_labels: HashMap<String, Vec<String>>,
}

/// What ended a wait on the Inbox
enum Wake {
    /// A command came, or the core is closing (None)
    Command(Option<Command>),
    /// The server said something changed
    Server,
    /// The IDLE period ran out, to be renewed
    Period,
    /// The Inbox has mail the store does not: it came between its sync and the wait
    Behind,
    /// A message in the Outbox waited for now
    Due,
}

impl Worker {
    #[allow(clippy::too_many_arguments)]
    pub(crate) fn new(
        account: AccountId,
        role: Role,
        path: PathBuf,
        secrets: Secrets,
        trust: Trust,
        oauth: crate::OAuthProviders,
        tokens: Tokens,
        events: EventSink,
    ) -> Self {
        Worker {
            account,
            role,
            path,
            secrets,
            trust,
            oauth,
            access_token: token_of(&tokens, account),
            tokens,
            events,
            connection: None,
            held: None,
            behind: None,
            worked: false,
            archived_labels: HashMap::new(),
        }
    }

    pub(crate) async fn run(mut self, mut commands: UnboundedReceiver<Command>) {
        // its own connection to the store, opened here and not on the thread that asked for work
        let mut store = match Store::open(&self.path) {
            Ok(store) => store,
            Err(error) => return self.fail(error.into()),
        };
        if self.role == Role::Reader {
            return self.read(&mut store, &mut commands).await;
        }
        while let Some(command) = self.next_command(&mut store, &mut commands).await {
            let sync = command == Command::Sync;
            if sync {
                self.emit(Event::SyncStarted { account: self.account });
            }
            self.worked = true;
            let mut outcome = self.handle(&mut store, command).await;
            if outcome.is_ok() {
                outcome = self.apply_server_events(&mut store).await;
            }
            let failure = outcome.as_ref().err().map(|failure| failure.kind);
            if let Err(failure) = outcome {
                self.fail(failure);
            }
            // after the failure and the changes it found, so the window knows the sync is done
            if sync {
                self.emit(Event::SyncFinished {
                    account: self.account,
                    failure,
                });
            }
            // the conversations of mail stored before they were kept, then its References from the server, a batch at a
            // time while nothing else waits (as the text below)
            while commands.is_empty() {
                match self.thread_stored(&mut store).await {
                    Ok(0) | Err(_) => break,
                    Ok(_) => {}
                }
            }
            // the text of the mail for the search, a batch at a time while nothing else waits; a batch that fails is
            // tried again after the next command
            while commands.is_empty() {
                match self.index_texts(&mut store).await {
                    Ok(0) | Err(_) => break,
                    Ok(_) => {}
                }
            }
        }
        if let Some((mut client, _)) = self.connection.take() {
            let _ = client.logout().await;
        }
    }

    /// The reader: the messages opened, each downloaded as it is asked for; one that can not be is reported for the
    /// reading pane ([`Event::MessageFailed`]), not as a failure of the account (the main worker reports those)
    async fn read(&mut self, store: &mut Store, commands: &mut UnboundedReceiver<Command>) {
        while let Some(mut command) = commands.recv().await {
            // only the message asked for last: those the user moved past on the way to it are not waited for
            while let Ok(next) = commands.try_recv() {
                command = next;
            }
            let Command::FetchSource { folder, uid } = command else {
                continue;
            };
            // what the server says of its folder is the main worker's to follow, not kept here
            if let Some((_, server_events)) = &mut self.connection {
                while server_events.try_recv().is_ok() {}
            }
            // a connection the server closed while it was not used shows when it is used: once more on a new one
            let had_connection = self.connection.is_some();
            let mut outcome = self.fetch_for_view(store, folder, uid).await;
            if had_connection
                && outcome
                    .as_ref()
                    .is_err_and(|failure| failure.kind == FailureKind::Network)
            {
                self.connection = None;
                outcome = self.fetch_for_view(store, folder, uid).await;
            }
            if let Err(failure) = outcome {
                self.reset_after(&failure);
                self.emit(Event::MessageFailed {
                    folder,
                    uid,
                    kind: failure.kind,
                    message: failure.message,
                });
            }
        }
        if let Some((mut client, _)) = self.connection.take() {
            let _ = client.logout().await;
        }
    }

    /// The source of a message in the store, fetched when it is not there yet; [`Event::MessageReady`] once it is,
    /// and the search indexes it by its text from then on
    async fn fetch_for_view(&mut self, store: &mut Store, folder: FolderId, uid: u64) -> Outcome {
        let source = if store.has_source(folder, uid)? {
            None
        } else {
            Some(fetch_source(self.client(store).await?, store, folder, uid).await?)
        };
        self.emit(Event::MessageReady { folder, uid });
        // the search finds it by what the parser reads in it from now on, after the window has it
        if let (Some(source), Some(message)) = (source, store.message(folder, uid)?) {
            let text = crate::search::index_text(&source);
            // its index row replaced at once, never missing for a search meanwhile
            store.transaction(|store| store.set_indexed(message.id, &text))?;
        }
        Ok(())
    }

    /// Archives messages already out of the store's `folder`: on Gmail their labels taken off (kept for Undo), elsewhere
    /// moved into the Archive folder, made first when the account has none
    async fn archive(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        uids: &[u64],
        removed: &[pe_store::MessageInfo],
    ) -> Outcome {
        let account = self.account;
        let client = self.client(store).await?;
        if pe_sync::has_labels(client, store, account)? {
            let lost = pe_sync::archive_labels(client, store, folder, uids).await?;
            for (uid, labels) in lost {
                if let Some(id) = removed.iter().find(|m| m.uid == uid).and_then(|m| m.message_id.clone()) {
                    self.archived_labels.insert(id, labels);
                }
            }
            return Ok(());
        }
        let (path, made) = pe_sync::archive_folder(client, store, account).await?;
        let path = path.map_err(|refusal| Failure {
            kind: FailureKind::Other,
            message: crate::folder_refusal(&refusal),
        })?;
        if made {
            self.sync_folder_list(store).await?;
        }
        let Some(to) = store.find_folder(self.account, &path)? else {
            return Err(Failure {
                kind: FailureKind::Other,
                message: tr(Text::NotArchivedHere),
            });
        };
        pe_sync::move_message(self.client(store).await?, store, folder, uids, to.id).await?;
        self.sync_one(store, to.id).await
    }

    /// Takes back an archive on Gmail: the labels the messages lost put back on them in All Mail, found there by
    /// their Message-IDs (the Inbox's label alone, or the label of the folder they came from, when this worker does
    /// not know them, as after a restart)
    async fn unarchive_labels(&mut self, store: &mut Store, m: &crate::selection::UndoMove) -> Outcome {
        let Some(all) = store.special_folder(self.account, "\\All")? else {
            return Ok(());
        };
        let fallback = pe_sync::folder_label(&store.folder(m.from)?.info.path);
        let labelled: Vec<(String, Vec<String>)> = m
            .message_ids
            .iter()
            .map(|id| {
                let labels = self
                    .archived_labels
                    .remove(id)
                    .unwrap_or_else(|| vec![fallback.clone()]);
                (id.clone(), labels)
            })
            .collect();
        pe_sync::restore_labels(self.client(store).await?, store, all.id, &labelled).await?;
        self.sync_one(store, m.from).await
    }

    /// Moves messages back where they came from, found by their Message-IDs in the folders they went to: after the
    /// move this takes back, which this worker ran before, and the sync of those folders that came with it. A folder
    /// the store does not show them in yet is synced first.
    async fn undo_moves(&mut self, store: &mut Store, moves: Vec<crate::selection::UndoMove>) -> Outcome {
        for mut m in moves {
            if m.archived {
                let account = self.account;
                if pe_sync::has_labels(self.client(store).await?, store, account)? {
                    self.unarchive_labels(store, &m).await?;
                    continue;
                }
                // back from the Archive folder, as a move is taken back
                match store.special_folder(self.account, "\\Archive")? {
                    Some(archive) => m.to = archive.id,
                    None => continue,
                }
            }
            let mut uids = store.uids_of_message_ids(m.to, &m.message_ids)?;
            if uids.len() < m.message_ids.len() {
                self.sync_one(store, m.to).await?;
                uids = store.uids_of_message_ids(m.to, &m.message_ids)?;
            }
            if uids.is_empty() {
                continue;
            }
            if let Some(flag) = m.flag {
                store.set_flag_many(m.to, &uids, flag, false)?;
                set_flag(self.client(store).await?, store, m.to, &uids, flag, false).await?;
            }
            if store.folder(m.from)?.account_id != self.account {
                // back to another account: through the transfers, as the move there went
                store.start_transfers(m.to, &uids, m.from, false)?;
                self.emit(Event::FolderChanged {
                    account: self.account,
                    folder: m.to,
                });
                self.transfer(store).await?;
                continue;
            }
            let mut removed = Vec::with_capacity(uids.len());
            for &uid in &uids {
                if let Some(message) = store.message(m.to, uid)? {
                    removed.push(message.info);
                }
            }
            store.remove_messages(m.to, &uids)?;
            self.emit(Event::FolderChanged {
                account: self.account,
                folder: m.to,
            });
            let moved = match self.client(store).await {
                Ok(client) => move_message(client, store, m.to, &uids, m.from)
                    .await
                    .map_err(Failure::from),
                Err(failure) => Err(failure),
            };
            self.restore_on_failure(store, m.to, &removed, moved)?;
            self.sync_one(store, m.from).await?;
        }
        Ok(())
    }

    /// Downloads the sources of `refs` (of this account) into the store, for files made of them
    /// ([`crate::Core::export_messages`]), on a connection of this worker's own that it closes after. Returns the
    /// messages that could not be had, with why.
    pub(crate) async fn fetch_sources(&mut self, refs: &[pe_store::MessageRef]) -> Vec<(pe_store::MessageRef, String)> {
        let mut store = match Store::open(&self.path) {
            Ok(store) => store,
            Err(error) => return refs.iter().map(|r| (*r, error.to_string())).collect(),
        };
        let mut failed = Vec::new();
        for r in refs {
            let outcome = match self.client(&mut store).await {
                Ok(client) => fetch_source(client, &mut store, r.folder, r.uid)
                    .await
                    .map(|_| ())
                    .map_err(Failure::from),
                Err(failure) => Err(failure),
            };
            match outcome {
                Ok(()) => {}
                // the server is not reachable, or does not take the sign-in: the rest would fail the same way
                Err(failure) if failure.kind != FailureKind::Other => {
                    let at = refs.iter().position(|x| x == r).unwrap_or(0);
                    failed.extend(refs[at..].iter().map(|x| (*x, failure.message.clone())));
                    break;
                }
                Err(failure) => failed.push((*r, failure.message)),
            }
        }
        if let Some((mut client, _)) = self.connection.take() {
            let _ = client.logout().await;
        }
        failed
    }

    /// The access token is no good: the next connect of either worker refreshes it
    fn forget_token(&self) {
        if let Ok(mut token) = self.access_token.try_lock() {
            *token = None;
        }
    }

    /// The next command. Meanwhile, while connected, the Inbox is watched (IDLE, or NOOP where the server has no IDLE),
    /// so new mail comes in as it arrives and not only with the next sync. Without a connection it just waits: the
    /// next sync connects again.
    async fn next_command(&mut self, store: &mut Store, commands: &mut UnboundedReceiver<Command>) -> Option<Command> {
        loop {
            // a message in the Outbox that waits for its time goes when it comes, whatever else waits
            let due = store
                .outbox_next_due(self.account)
                .ok()
                .flatten()
                .map(|at| Duration::from_secs(u64::try_from(at - unix_now()).unwrap_or(0)));
            if due == Some(Duration::ZERO) {
                if let Err(failure) = self.send_outbox(store).await {
                    self.fail(failure);
                }
                // what did not go (offline, refused) stays in the Outbox as any other: Send/Recv tries again
                let _ = store.clear_not_before(self.account, unix_now());
                continue;
            }
            let inbox = self
                .connection
                .as_ref()
                .filter(|(client, _)| !client.is_closed())
                .and_then(|_| store.find_folder(self.account, "INBOX").ok().flatten());
            let Some(inbox) = inbox else {
                match due {
                    Some(due) => match tokio::time::timeout(due, commands.recv()).await {
                        Ok(command) => return command,
                        Err(_) => continue,
                    },
                    None => return commands.recv().await,
                }
            };
            match self.watch(&inbox, commands, due).await {
                Ok(Wake::Command(command)) => return command,
                Ok(Wake::Due) => continue,
                Ok(Wake::Behind) => {
                    if let Err(failure) = self.sync_one(store, inbox.id).await {
                        self.fail(failure);
                    }
                }
                Ok(Wake::Server | Wake::Period) => {
                    if let Err(failure) = self.apply_server_events(store).await {
                        self.fail(failure);
                    }
                }
                // the connection is gone now (fail drops it): waiting goes on without one
                Err(failure) => self.fail(failure),
            }
        }
    }

    /// Waits on the Inbox until a command comes, the server reports a change or the IDLE period ends
    /// (or `due`, when a message of the Outbox waits that long)
    async fn watch(
        &mut self,
        inbox: &pe_store::Folder,
        commands: &mut UnboundedReceiver<Command>,
        due: Option<Duration>,
    ) -> Result<Wake, Failure> {
        let Some((client, events)) = self.connection.as_mut() else {
            return Ok(Wake::Period);
        };
        if client
            .selected()
            .is_none_or(|selected| selected.path != inbox.info.path)
        {
            client.select(&inbox.info.path).await?;
        } else if std::mem::take(&mut self.worked) {
            // what came since the last command: a server tells it with the next one, not when IDLE starts
            client.noop().await?;
        }
        if !events.is_empty() {
            return Ok(Wake::Server);
        }
        // what came while the Inbox was selected for other work is in the counts of SELECT, not in an event; once for
        // each UIDNEXT, should a sync not bring the store to it
        let next = client.selected().and_then(|selected| selected.uid_next);
        if next.is_some() && next != inbox.state.uid_next && next != self.behind {
            self.behind = next;
            return Ok(Wake::Behind);
        }
        let mut wake = Wake::Period;
        let mut held = None;
        let stop = async {
            let until_due = async {
                match due {
                    Some(due) => tokio::time::sleep(due).await,
                    None => std::future::pending().await,
                }
            };
            tokio::select! {
                command = commands.recv() => wake = Wake::Command(command),
                event = events.recv() => {
                    held = event;
                    wake = Wake::Server;
                }
                () = until_due => wake = Wake::Due,
            }
        };
        client.idle(stop).await?;
        self.held = held;
        Ok(wake)
    }

    /// One batch of conversations for mail stored before they were kept: messages put into theirs from what the store
    /// has, else the References of the newest ones fetched (one folder's, one FETCH) and joined by. How many messages
    /// that was (0: all are done). The windows hear of the folders whose conversations changed.
    async fn thread_stored(&mut self, store: &mut Store) -> Result<usize, Failure> {
        let threaded = store.thread_unthreaded(self.account, crate::THREAD_BATCH)?;
        if threaded > 0 {
            self.emit(Event::FoldersChanged { account: self.account });
            return Ok(threaded);
        }
        let batch = store.messages_without_references(self.account, crate::THREAD_BATCH)?;
        let Some(&(_, folder, _)) = batch.first() else {
            return Ok(0);
        };
        let uids: Vec<u64> = batch.iter().map(|(_, _, uid)| *uid).collect();
        let fetched = pe_sync::fetch_references(self.client(store).await?, store, folder, &uids).await?;
        let joined = store.transaction(|store| {
            let mut joined = false;
            for (message, _, uid) in &batch {
                let references = fetched
                    .iter()
                    .find(|(found, _)| found == uid)
                    .map(|(_, refs)| refs.as_slice())
                    .unwrap_or_default();
                joined |= store.set_references(*message, references)?;
            }
            Ok(joined)
        })?;
        if joined {
            self.emit(Event::FoldersChanged { account: self.account });
        }
        Ok(batch.len())
    }

    /// Fetches the text parts of the newest messages the search index does not have the text of, and indexes them;
    /// how many messages that was (0: all are indexed). A message with no text part is indexed without text.
    async fn index_texts(&mut self, store: &mut Store) -> Result<usize, Failure> {
        // the newest message's folder, so a batch selects one folder
        let batch = store.messages_to_index(self.account, crate::search::TEXT_BATCH)?;
        let Some(&(_, folder, _)) = batch.first() else {
            return Ok(0);
        };
        let messages: Vec<(i64, u64)> = batch
            .iter()
            .filter(|(_, f, _)| *f == folder)
            .map(|(message, _, uid)| (*message, *uid))
            .collect();
        {
            let uids: Vec<u64> = messages.iter().map(|(_, uid)| *uid).collect();
            let client = self.client(store).await?;
            let texts = pe_sync::fetch_texts(client, store, folder, &uids, crate::search::PART_LIMIT).await?;
            store.transaction(|store| {
                for (message, uid) in &messages {
                    let body = texts
                        .iter()
                        .find(|(found, _)| found == uid)
                        .map(|(_, parts)| crate::search::parts_text(parts))
                        .unwrap_or_default();
                    let text = pe_store::IndexText {
                        body,
                        ..Default::default()
                    };
                    store.set_indexed(*message, &text)?;
                }
                Ok(())
            })?;
        }
        Ok(messages.len())
    }

    fn emit(&self, event: Event) {
        (self.events)(event);
    }

    /// What a failure leaves no good: the connection (the next command connects again), and a refused access token
    fn reset_after(&mut self, failure: &Failure) {
        if failure.kind != FailureKind::Other {
            self.connection = None;
        }
        if failure.kind == FailureKind::Authentication {
            self.forget_token();
        }
    }

    fn fail(&mut self, failure: Failure) {
        self.reset_after(&failure);
        // a refused password is told once, not again for each command until the user gives another
        if failure.kind == FailureKind::Authentication && !self.secrets.first_refusal(self.account) {
            return;
        }
        self.emit(Event::Failed {
            account: self.account,
            kind: failure.kind,
            message: failure.message,
        });
    }

    async fn handle(&mut self, store: &mut Store, command: Command) -> Outcome {
        match command {
            Command::Sync => {
                // what waits in the Outbox goes first; a send that fails does not stop the sync
                if let Err(failure) = self.send_outbox(store).await {
                    self.fail(failure);
                }
                // and messages left on their way to another account
                if let Err(failure) = self.transfer(store).await {
                    self.fail(failure);
                }
                self.sync_all(store).await
            }
            Command::Transfer => self.transfer(store).await,
            Command::SendOutbox => self.send_outbox(store).await,
            // the reader's (Core::open_message), never sent here
            Command::FetchSource { .. } => Ok(()),
            Command::SetFlag { folder, uids, flag, on } => {
                Ok(set_flag(self.client(store).await?, store, folder, &uids, flag, on).await?)
            }
            Command::SetFlags {
                folder,
                uids,
                add,
                remove,
            } => Ok(pe_sync::change_flags(self.client(store).await?, store, folder, &uids, &add, &remove).await?),
            Command::Move {
                folder,
                uids,
                to,
                removed,
            } => {
                let moved = match self.client(store).await {
                    Ok(client) => move_message(client, store, folder, &uids, to)
                        .await
                        .map_err(Failure::from),
                    Err(failure) => Err(failure),
                };
                self.restore_on_failure(store, folder, &removed, moved)?;
                // the message shows up in the folder it went to
                self.sync_one(store, to).await
            }
            Command::UndoMoves { moves } => self.undo_moves(store, moves).await,
            Command::Archive { folder, uids, removed } => {
                let archived = self.archive(store, folder, &uids, &removed).await;
                self.restore_on_failure(store, folder, &removed, archived)
            }
            Command::Copy { folder, uids, to } => {
                copy_messages(self.client(store).await?, store, folder, &uids, to).await?;
                // the copy shows up in the folder it went to
                self.sync_one(store, to).await
            }
            Command::Expunge { folder, uids, removed } => {
                let expunged = match self.client(store).await {
                    Ok(client) => expunge_messages(client, store, folder, &uids)
                        .await
                        .map_err(Failure::from),
                    Err(failure) => Err(failure),
                };
                self.restore_on_failure(store, folder, &removed, expunged)
            }
            Command::Append { folder, raw, date } => {
                let path = store.folder(folder)?.info.path;
                self.client(store).await?.append(&path, &raw, &["\\Seen"], date).await?;
                self.sync_one(store, folder).await
            }
            Command::CreateFolder { parent, name } => {
                let client = self.client(store).await?;
                let namespace = client.namespace().cloned();
                let path = pe_sync::new_folder_path(store, self.account, parent, &name, namespace.as_ref())?.map_err(
                    |refusal| Failure {
                        kind: FailureKind::Other,
                        message: crate::folder_refusal(&refusal),
                    },
                )?;
                pe_sync::create_folder(self.client(store).await?, &path).await?;
                self.sync_folder_list(store).await?;
                if let Some(folder) = store.find_folder(self.account, &path)? {
                    self.emit(Event::FolderCreated {
                        account: self.account,
                        folder: folder.id,
                    });
                }
                Ok(())
            }
            Command::RenameFolder { folder, path } => {
                pe_sync::rename_folder(self.client(store).await?, store, folder, &path).await?;
                self.sync_folder_list(store).await
            }
            Command::DeleteFolder { folder } => {
                pe_sync::delete_folder(self.client(store).await?, store, folder).await?;
                self.sync_folder_list(store).await
            }
            Command::Send { outgoing, not_before } => self.send(store, *outgoing, not_before).await,
            Command::SaveDraft { outgoing } => self.save_draft(store, *outgoing).await,
        }
    }

    /// A message the windows took out of a folder before the server moved or deleted it: back in when the server did
    /// not (offline, refused), so it is not lost from view while it is still on the server
    fn restore_on_failure(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        removed: &[pe_store::MessageInfo],
        outcome: Outcome,
    ) -> Outcome {
        if outcome.is_err() {
            store.add_messages(folder, removed)?;
            self.emit(Event::FolderChanged {
                account: self.account,
                folder,
            });
        }
        outcome
    }

    /// Builds a message (its attachments read now), puts it in the Outbox and sends the Outbox
    async fn send(&mut self, store: &mut Store, outgoing: crate::Outgoing, not_before: Option<i64>) -> Outcome {
        let time = unix_now();
        let recipients = [outgoing.to.as_str(), outgoing.cc.as_str()]
            .iter()
            .filter(|list| !list.trim().is_empty())
            .copied()
            .collect::<Vec<_>>()
            .join(", ");
        let subject = outgoing.subject.clone();
        let draft = outgoing.message_id.as_deref().and_then(crate::compose::draft_id);
        let draft_account = outgoing.draft_account.unwrap_or(self.account);
        let built = build(
            store.account(self.account)?.settings,
            outgoing,
            time,
            crate::compose::message,
        )
        .await?;
        store.queue(
            &pe_store::Queued {
                id: 0,
                account_id: self.account,
                envelope_from: built.envelope.from,
                envelope_to: built.envelope.to,
                subject,
                recipients,
                created: time,
                problem: None,
                not_before,
            },
            &built.raw,
        )?;
        self.emit(Event::OutboxChanged { account: self.account });
        // the Outbox has it now: its draft goes, whether it goes now or waits there
        if let Some(message_id) = draft {
            self.remove_draft_of(store, draft_account, &message_id).await;
        }
        self.send_outbox(store).await
    }

    /// Removes the drafts with `message_id` from the Drafts of `account`, this one or another (From changed after the
    /// draft was saved; a connection of that account's own, for this once), after the message is safe here. A
    /// failure is told, not passed on: what was asked for is done.
    async fn remove_draft_of(&mut self, store: &mut Store, account: AccountId, message_id: &str) {
        let outcome = if account == self.account {
            self.remove_drafts(store, message_id).await
        } else {
            self.sibling(account).remove_drafts(store, message_id).await
        };
        if let Err(failure) = outcome {
            self.fail(Failure {
                kind: failure.kind,
                message: tr_args(Text::ErrorDraftNotRemoved, &[("reason", (&failure.message).into())]),
            });
        }
    }

    /// A worker for another account, for one piece of work on a connection of its own
    fn sibling(&self, account: AccountId) -> Worker {
        Worker::new(
            account,
            Role::Main,
            self.path.clone(),
            self.secrets.clone(),
            self.trust.clone(),
            self.oauth.clone(),
            self.tokens.clone(),
            self.events.clone(),
        )
    }

    /// Saves a draft in the Drafts folder, in place of the copy saved before, and says how that went to the window it
    /// came from ([`Event::DraftSaved`])
    async fn save_draft(&mut self, store: &mut Store, outgoing: crate::Outgoing) -> Outcome {
        let message_id = outgoing.message_id.clone().unwrap_or_default();
        let saved = self.store_draft(store, outgoing).await;
        self.emit(Event::DraftSaved {
            account: self.account,
            message_id,
            problem: saved.as_ref().err().map(|failure| failure.message.clone()),
        });
        self.sync_one(store, saved?).await
    }

    /// Puts a draft in the Drafts folder on the server; the id of that folder
    async fn store_draft(&mut self, store: &mut Store, outgoing: crate::Outgoing) -> Result<FolderId, Failure> {
        let drafts = crate::compose::drafts_folder(store, self.account)?.ok_or_else(|| Failure {
            kind: FailureKind::Other,
            message: tr(Text::ErrorNoDrafts),
        })?;
        let message_id = outgoing.message_id.clone().unwrap_or_default();
        let moved_from = outgoing.draft_account.filter(|from| *from != self.account);
        let time = unix_now();
        let built = build(
            store.account(self.account)?.settings,
            outgoing,
            time,
            crate::compose::draft_message,
        )
        .await?;
        let client = self.client(store).await?;
        pe_sync::save_draft(client, store, drafts.id, &built.raw, &message_id, time).await?;
        // saved here: the copy in the Drafts of the account it went from before goes
        if let Some(from) = moved_from {
            self.remove_draft_of(store, from, &message_id).await;
        }
        Ok(drafts.id)
    }

    async fn remove_drafts(&mut self, store: &mut Store, message_id: &str) -> Outcome {
        let Some(drafts) = crate::compose::drafts_folder(store, self.account)? else {
            return Ok(());
        };
        let client = self.client(store).await?;
        pe_sync::remove_drafts(client, store, drafts.id, message_id).await?;
        self.sync_one(store, drafts.id).await
    }

    /// A message went out, but something after it did not work
    fn sent_but(&self, problem: String) {
        self.emit(Event::Failed {
            account: self.account,
            kind: FailureKind::Other,
            message: tr_args(Text::ErrorSentBut, &[("problem", (&problem).into())]),
        });
    }

    /// Sends what the Outbox has for this account, oldest first: each one the server takes leaves the Outbox and gets
    /// its copy in Sent. One it refuses stays with the reason; when the network fails the rest wait for the next try.
    async fn send_outbox(&mut self, store: &mut Store) -> Outcome {
        // a message that waits for its time is left for then (next_command wakes for it)
        let queued = store.outbox_due(self.account, unix_now())?;
        if queued.is_empty() {
            return Ok(());
        }
        let account = store.account(self.account)?;
        let mut config = smtp_config(&account, self.credentials(store, &account).await?);
        config.trust = self.trust.clone();
        let mut smtp = match pe_smtp::Client::connect(config).await {
            Ok(smtp) => smtp,
            Err(error) => {
                let failure = scope_hint(Failure::from(error), &account);
                for message in &queued {
                    store.set_problem(message.id, &failure.message)?;
                }
                self.emit(Event::OutboxChanged { account: self.account });
                return Err(kept(failure, queued.len()));
            }
        };
        let mut failed = None;
        for message in queued {
            // deleted from the Outbox meanwhile
            let Some(raw) = store.queued_raw(message.id)? else {
                continue;
            };
            let envelope = pe_smtp::Envelope {
                from: message.envelope_from,
                to: message.envelope_to,
            };
            match smtp.send(&envelope, &raw).await {
                Ok(_) => {
                    // sent: whatever happens next, the others still go and this one is not counted as failed
                    let unqueued = store.unqueue(message.id);
                    self.emit(Event::MessageSent {
                        account: self.account,
                        subject: message.subject.clone(),
                    });
                    self.emit(Event::OutboxChanged { account: self.account });
                    if let Err(error) = unqueued {
                        self.sent_but(tr_args(
                            Text::ErrorSentStillInOutbox,
                            &[("error", (&error.to_string()).into())],
                        ));
                    }
                    if let Err(failure) = self.save_sent(store, &raw, message.created).await {
                        self.sent_but(tr_args(Text::ErrorSentNoCopy, &[("reason", (&failure.message).into())]));
                    }
                }
                Err(error) => {
                    let network = error.is_temporary() && matches!(error.kind(), pe_smtp::ErrorKind::Network);
                    let failure = Failure::from(error);
                    store.set_problem(message.id, &failure.message)?;
                    self.emit(Event::OutboxChanged { account: self.account });
                    failed = Some(failure);
                    // the connection is gone: the others wait for the next try
                    if network {
                        break;
                    }
                }
            }
        }
        smtp.quit().await;
        match failed {
            Some(failure) => Err(kept(failure, store.outbox_count(Some(self.account))?)),
            None => Ok(()),
        }
    }

    async fn save_sent(&mut self, store: &mut Store, raw: &[u8], date: i64) -> Outcome {
        let Some(sent) = store.special_folder(self.account, "\\Sent")? else {
            return Ok(());
        };
        let client = self.client(store).await?;
        client.append(&sent.info.path, raw, &["\\Seen"], Some(date)).await?;
        self.sync_one(store, sent.id).await
    }

    /// The password of the account, as credentials for IMAP and SMTP
    /// How to log in: the password, or for an OAuth account an access token made from its refresh token
    async fn credentials(&mut self, store: &mut Store, account: &pe_store::Account) -> Result<Credentials, Failure> {
        let no_secret = |text: Text| Failure {
            kind: FailureKind::Authentication,
            message: tr(text),
        };
        let user = account.settings.username.clone();
        let pe_store::Auth::OAuth2(provider) = &account.settings.auth else {
            let password = self
                .secrets
                .get(self.account)
                .ok_or_else(|| no_secret(Text::ErrorNoPassword))?;
            return Ok(Credentials::Password { user, password });
        };
        let now = pe_oauth::now();
        // held while refreshing, so the other worker waits for this token rather than refreshing too
        let shared = self.access_token.clone();
        let mut access_token = shared.lock().await;
        if let Some((token, expires_at)) = &*access_token
            && *expires_at > now
        {
            return Ok(Credentials::OAuth2 {
                user,
                access_token: token.clone(),
            });
        }
        let provider = self
            .oauth
            .resolve(provider, store, &self.secrets)
            .ok_or_else(|| Failure {
                kind: FailureKind::Other,
                message: tr_args(
                    Text::ErrorProviderMissing,
                    &[("provider", (&provider.to_string()).into())],
                ),
            })?;
        // an access token is for the provider's own servers only
        let settings = &account.settings;
        if !settings.imap_host.eq_ignore_ascii_case(&provider.imap.host)
            || !settings.smtp_host.eq_ignore_ascii_case(&provider.smtp.host)
        {
            return Err(Failure {
                kind: FailureKind::Other,
                message: tr(Text::ErrorProviderServers),
            });
        }
        let refresh_token = self
            .secrets
            .get(self.account)
            .ok_or_else(|| no_secret(Text::ErrorNoSignIn))?;
        let tokens = pe_oauth::refresh(&provider, &refresh_token)
            .await
            .map_err(|error| Failure {
                kind: if error.needs_sign_in() {
                    FailureKind::Authentication
                } else {
                    FailureKind::Network
                },
                message: error.to_string(),
            })?;
        if let Some(new) = tokens.refresh_token.as_deref().filter(|new| *new != refresh_token) {
            // the provider rotated it: the old one may stop working
            if let Err(error) = self.secrets.set(self.account, new) {
                self.emit(Event::Failed {
                    account: self.account,
                    kind: FailureKind::Other,
                    message: tr_args(Text::ErrorSignInNotSaved, &[("error", (&error.to_string()).into())]),
                });
            }
        }
        *access_token = Some((tokens.access_token.clone(), tokens.expires_at));
        Ok(Credentials::OAuth2 {
            user,
            access_token: tokens.access_token,
        })
    }

    async fn sync_all(&mut self, store: &mut Store) -> Outcome {
        self.sync_folders_and(store, |_| true).await
    }

    /// The folder tree from the server ([`Event::FoldersChanged`] when it changed), then the folders `which` picks.
    /// One folder the server refuses does not stop the others.
    async fn sync_folders_and(&mut self, store: &mut Store, which: impl Fn(&pe_store::Folder) -> bool) -> Outcome {
        let account = self.account;
        let before: Vec<_> = store.folders(account)?.into_iter().map(|f| f.info).collect();
        let folders = sync_folders(self.client(store).await?, store, account).await?;
        if folders.iter().map(|f| &f.info).ne(before.iter()) {
            self.emit(Event::FoldersChanged { account });
        }
        for folder in folders.iter().filter(|f| f.info.selectable && which(f)) {
            match self.sync_one(store, folder.id).await {
                // one folder the server refuses does not stop the others
                Err(failure) if failure.kind == FailureKind::Other => self.emit(Event::Failed {
                    account,
                    kind: failure.kind,
                    message: tr_args(
                        Text::ErrorInFolder,
                        &[
                            ("folder", (&folder.info.path).into()),
                            ("reason", (&failure.message).into()),
                        ],
                    ),
                }),
                result => result?,
            }
        }
        Ok(())
    }

    /// The folder tree from the server, after a folder was made, renamed or deleted: the new folders synced too
    async fn sync_folder_list(&mut self, store: &mut Store) -> Outcome {
        self.sync_folders_and(store, |folder| folder.state.uid_validity.is_none())
            .await
    }

    async fn sync_one(&mut self, store: &mut Store, folder: FolderId) -> Outcome {
        let before = store.folder(folder)?;
        let report = sync_folder(self.client(store).await?, store, folder).await?;
        if report != pe_sync::Report::default() {
            self.emit(Event::FolderChanged {
                account: self.account,
                folder,
            });
        }
        // new unread mail, above the UIDs the store knew: not with the first sync of the folder, nor after a reset,
        // which would call every message new
        if report.added > 0
            && !report.reset
            && let Some(next) = before.state.uid_next
        {
            let fresh = crate::watch::arrived(&before.info, store.unseen_from(folder, next)?);
            self.read_ignored(store, folder, &fresh.read).await?;
            if let Some(newest) = fresh.announced.first() {
                let from = newest.info.sender().to_string();
                let count = fresh.announced.len();
                let watched = newest.mark == pe_store::ThreadMark::Watch;
                let (title, mut text) = crate::text::new_mail_words(count, &from, &newest.info.subject, watched);
                // a one-time code of a fresh message, named first when the app asks for it
                if let Some(code) = self.code_of_new(store, folder, newest).await {
                    text = crate::otp::notification_text(&code, &text);
                }
                self.emit(Event::NewMail {
                    account: self.account,
                    folder,
                    uid: newest.info.uid,
                    count,
                    from,
                    subject: newest.info.subject.clone(),
                    watched,
                    title,
                    text,
                });
            }
        }
        Ok(())
    }

    /// The one-time code of a message just arrived, for its notification: only when the app turned that on, for a fresh
    /// message outside Junk E-mail, Sent Items and Drafts, whose domain the provider says signed it (as the card asks).
    /// Its source is downloaded for that, a few seconds at most; when that is slow it is announced without the code.
    async fn code_of_new(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        newest: &pe_store::Message,
    ) -> Option<crate::otp::Code> {
        if !crate::otp::in_notifications() {
            return None;
        }
        let place = store.folder(folder).ok()?;
        if matches!(
            place.info.special_use.as_deref(),
            Some("\\Junk" | "\\Sent" | "\\Drafts")
        ) {
            return None;
        }
        let at = newest.info.internal_date.or(newest.info.date)?;
        if unix_now() - at > crate::otp::FRESH_FOR_NOTIFICATIONS {
            return None;
        }
        let trusted = crate::authres::trusted(&store.account(self.account).ok()?.settings);
        let uid = newest.info.uid;
        let client = self.client(store).await.ok()?;
        let source = tokio::time::timeout(Duration::from_secs(5), fetch_source(client, store, folder, uid))
            .await
            .ok()?
            .ok()?;
        let message = pe_mime::parser::parse(&source).ok()?;
        crate::otp::of(&message, &trusted)
    }

    /// New mail of ignored conversations marked read, in the store and on the server, as Mark Read does
    async fn read_ignored(&mut self, store: &mut Store, folder: FolderId, uids: &[u64]) -> Outcome {
        if uids.is_empty() {
            return Ok(());
        }
        let changed = store.set_flag_many(folder, uids, "\\Seen", true)?;
        if changed.is_empty() {
            return Ok(());
        }
        self.emit(Event::FolderChanged {
            account: self.account,
            folder,
        });
        Ok(set_flag(self.client(store).await?, store, folder, &changed, "\\Seen", true).await?)
    }

    /// Applies the changes the server reported during the last command; folders that only a
    /// sync can bring up to date are synced
    async fn apply_server_events(&mut self, store: &mut Store) -> Outcome {
        let mut resync = BTreeSet::new();
        loop {
            let event = if let Some(event) = self.held.take() {
                event
            } else {
                let Some((_, events)) = self.connection.as_mut() else {
                    return Ok(());
                };
                match events.try_recv() {
                    Ok(event) => event,
                    Err(TryRecvError::Empty) => break,
                    Err(TryRecvError::Disconnected) => {
                        self.connection = None;
                        break;
                    }
                }
            };
            match apply_event(store, self.account, &event)? {
                Change::None => {}
                Change::Updated(folder) => self.emit(Event::FolderChanged {
                    account: self.account,
                    folder,
                }),
                Change::NeedsSync(folder) => {
                    resync.insert(folder);
                }
            }
        }
        for folder in resync {
            self.sync_one(store, folder).await?;
        }
        Ok(())
    }

    /// The connection, made when there is none or the server closed it
    async fn client(&mut self, store: &mut Store) -> Result<&mut Client, Failure> {
        if self.connection.as_ref().is_some_and(|(client, _)| client.is_closed()) {
            self.connection = None;
        }
        if self.connection.is_none() {
            // read at each connect, so changed settings are used from the next connection on
            let account = store.account(self.account)?;
            let mut config = imap_config(&account, self.credentials(store, &account).await?);
            config.trust = self.trust.clone();
            let connected = Client::connect(config).await;
            self.connection = Some(connected.map_err(|error| scope_hint(Failure::from(error), &account))?);
        }
        Ok(&mut self.connection.as_mut().expect("connected").0)
    }
}
