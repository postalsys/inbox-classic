//! The mail engine the C API wraps: accounts and their passwords, one sync worker per account,
//! and what the windows show, the folder tree, the message list and the message view.
//!
//! Each worker owns an IMAP connection and a connection to the store of its own; the windows read
//! through another one. SQLite in WAL mode lets them read while a worker writes. Work the
//! windows start runs on the workers and reports back as [`Event`]s, on a worker thread.
#![forbid(unsafe_code)]

mod view;
mod worker;

use std::collections::{HashMap, HashSet};
use std::fmt;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, MutexGuard};

use pe_store::{Account, AccountId, AccountSettings, Folder, FolderId, Message, Sort, Store};
use tokio::sync::mpsc::{UnboundedSender, unbounded_channel};

pub use view::{AttachmentView, MessageView};
use worker::{Command, Worker};

/// What the engine tells the windows. Delivered on a worker thread.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Event {
    SyncStarted {
        account: AccountId,
    },
    SyncFinished {
        account: AccountId,
    },
    /// The folder list of an account changed
    FoldersChanged {
        account: AccountId,
    },
    /// The messages of a folder, or their flags, changed
    FolderChanged {
        account: AccountId,
        folder: FolderId,
    },
    /// The source of a message is in the store, [`Core::message_view`] can show it
    MessageReady {
        folder: FolderId,
        uid: u64,
    },
    /// Work for an account failed; `kind` says what to do about it
    Failed {
        account: AccountId,
        kind: FailureKind,
        message: String,
    },
}

/// What a failure asks of the user
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FailureKind {
    /// Not reachable now, try again later
    Network,
    /// TLS failed: a certificate or a missing STARTTLS to show
    Security,
    /// The password or token was refused, or there is none
    Authentication,
    /// The server refused something, or the local store failed
    Other,
}

#[derive(Debug)]
pub enum Error {
    Store(pe_store::Error),
    /// The account, folder or message is not there
    NotFound,
    /// The engine is shutting down
    Closed,
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::Store(error) => write!(f, "local store: {error}"),
            Error::NotFound => f.write_str("not found"),
            Error::Closed => f.write_str("shutting down"),
        }
    }
}

impl std::error::Error for Error {}

impl From<pe_store::Error> for Error {
    fn from(error: pe_store::Error) -> Self {
        Error::Store(error)
    }
}

pub type Result<T> = std::result::Result<T, Error>;

pub(crate) type EventSink = Arc<dyn Fn(Event) + Send + Sync>;

/// The passwords of the accounts, in memory: the user gives them once per run until the
/// Windows Credential Manager keeps them
#[derive(Clone, Default)]
pub(crate) struct Secrets(Arc<Mutex<SecretMap>>);

#[derive(Default)]
struct SecretMap {
    passwords: HashMap<AccountId, String>,
    /// Accounts whose password was refused and reported: reported once until a new one is set
    refused: HashSet<AccountId>,
}

impl Secrets {
    fn map(&self) -> MutexGuard<'_, SecretMap> {
        self.0.lock().unwrap_or_else(|poisoned| poisoned.into_inner())
    }

    pub(crate) fn get(&self, account: AccountId) -> Option<String> {
        self.map().passwords.get(&account).cloned()
    }

    fn set(&self, account: AccountId, password: &str) {
        let mut map = self.map();
        map.passwords.insert(account, password.to_string());
        map.refused.remove(&account);
    }

    fn remove(&self, account: AccountId) {
        let mut map = self.map();
        map.passwords.remove(&account);
        map.refused.remove(&account);
    }

    /// Whether a refused password is news: true the first time after it was set
    pub(crate) fn first_refusal(&self, account: AccountId) -> bool {
        self.map().refused.insert(account)
    }
}

pub struct Core {
    path: PathBuf,
    /// The store the windows read and change
    store: Mutex<Store>,
    /// Taken when closing
    runtime: Option<tokio::runtime::Runtime>,
    workers: Mutex<HashMap<AccountId, UnboundedSender<Command>>>,
    secrets: Secrets,
    events: EventSink,
    /// Set when closing: no event is delivered after
    closed: Arc<AtomicBool>,
}

impl Core {
    /// Opens the store at `path` (created when missing) and starts the engine. `events` is called
    /// on worker threads, never on the thread that called into the engine.
    pub fn open(path: impl AsRef<Path>, events: impl Fn(Event) + Send + Sync + 'static) -> Result<Core> {
        let path = path.as_ref().to_path_buf();
        let store = Store::open(&path)?;
        let runtime = tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .thread_name("pe-worker")
            .enable_all()
            .build()
            .map_err(|_| Error::Closed)?;
        let closed = Arc::new(AtomicBool::new(false));
        let open = closed.clone();
        Ok(Core {
            path,
            store: Mutex::new(store),
            runtime: Some(runtime),
            workers: Mutex::default(),
            secrets: Secrets::default(),
            events: Arc::new(move |event| {
                if !open.load(Ordering::Acquire) {
                    events(event);
                }
            }),
            closed,
        })
    }

    fn store(&self) -> MutexGuard<'_, Store> {
        // a panic while the store was held left nothing half written: transactions roll back
        self.store.lock().unwrap_or_else(|poisoned| poisoned.into_inner())
    }

    fn runtime(&self) -> Result<&tokio::runtime::Runtime> {
        self.runtime.as_ref().ok_or(Error::Closed)
    }

    /// Delivers an event on a worker thread
    fn post(&self, event: Event) -> Result<()> {
        let events = self.events.clone();
        self.runtime()?.spawn(async move { events(event) });
        Ok(())
    }

    pub fn add_account(&self, settings: &AccountSettings, password: &str) -> Result<AccountId> {
        let id = self.store().add_account(settings)?;
        self.secrets.set(id, password);
        Ok(id)
    }

    pub fn update_account(&self, id: AccountId, settings: &AccountSettings) -> Result<()> {
        self.store().update_account(id, settings)?;
        // the worker connects again with the new settings
        self.stop_worker(id);
        Ok(())
    }

    pub fn remove_account(&self, id: AccountId) -> Result<()> {
        self.stop_worker(id);
        self.secrets.remove(id);
        self.store().remove_account(id)?;
        Ok(())
    }

    pub fn set_password(&self, id: AccountId, password: &str) {
        self.secrets.set(id, password);
    }

    pub fn accounts(&self) -> Result<Vec<Account>> {
        Ok(self.store().accounts()?)
    }

    pub fn folders(&self, account: AccountId) -> Result<Vec<Folder>> {
        Ok(self.store().folders(account)?)
    }

    pub fn messages(&self, folder: FolderId, sort: Sort, offset: u64, limit: u64) -> Result<Vec<Message>> {
        Ok(self.store().messages(folder, sort, offset, limit)?)
    }

    /// One folder with its counts
    pub fn folder(&self, folder: FolderId) -> Result<Folder> {
        Ok(self.store().folder(folder)?)
    }

    /// Where a message is in the message list in this order
    pub fn message_index(&self, folder: FolderId, sort: Sort, uid: u64) -> Result<Option<u64>> {
        Ok(self.store().message_index(folder, sort, uid)?)
    }

    /// Syncs the folder list and every folder of an account, in the background
    pub fn sync(&self, account: AccountId) -> Result<()> {
        self.send(account, Command::Sync)
    }

    /// Gets the source of a message to the store, in the background; [`Event::MessageReady`]
    /// follows, right away when it is cached
    pub fn open_message(&self, folder: FolderId, uid: u64) -> Result<()> {
        let account = self.store().folder(folder)?.account_id;
        self.send(account, Command::FetchSource { folder, uid })
    }

    /// The message as the preview shows it, None when its source is not in the store yet
    pub fn message_view(&self, folder: FolderId, uid: u64, allow_remote_images: bool) -> Result<Option<MessageView>> {
        let (source, received) = {
            let store = self.store();
            let received = store.message(folder, uid)?.and_then(|m| m.info.internal_date);
            (store.source(folder, uid)?, received)
        };
        Ok(source.map(|source| {
            let mut view = view::build(&source, allow_remote_images);
            // without a Date header, the date the list shows: when the server got it
            view.date = view.date.or(received);
            view
        }))
    }

    /// The content of the `index`th attachment of [`MessageView::attachments`], with the name to
    /// save it under
    pub fn attachment(&self, folder: FolderId, uid: u64, index: usize) -> Result<Option<(String, Vec<u8>)>> {
        let source = self.store().source(folder, uid)?;
        Ok(source.and_then(|source| view::attachment(&source, index)))
    }

    /// Marks a message read or unread: in the store now, on the server in the background
    pub fn set_seen(&self, folder: FolderId, uid: u64, seen: bool) -> Result<()> {
        let (account, changed) = {
            let store = self.store();
            let account = store.folder(folder)?.account_id;
            (account, store.set_flag(folder, uid, "\\Seen", seen)?)
        };
        if changed {
            self.post(Event::FolderChanged { account, folder })?;
        }
        self.send(account, Command::SetSeen { folder, uid, seen })
    }

    fn send(&self, account: AccountId, command: Command) -> Result<()> {
        let mut workers = self.workers.lock().unwrap_or_else(|p| p.into_inner());
        let command = match workers.get(&account) {
            Some(sender) => match sender.send(command) {
                Ok(()) => return Ok(()),
                // the worker stopped: a new one takes the command
                Err(returned) => returned.0,
            },
            None => command,
        };
        self.store().account(account).map_err(|_| Error::NotFound)?;
        let (sender, receiver) = unbounded_channel();
        sender.send(command).map_err(|_| Error::Closed)?;
        let worker = Worker::new(account, self.path.clone(), self.secrets.clone(), self.events.clone());
        self.runtime()?.spawn(worker.run(receiver));
        workers.insert(account, sender);
        Ok(())
    }

    fn stop_worker(&self, account: AccountId) {
        // dropping the sender ends the worker once its current command is done
        self.workers.lock().unwrap_or_else(|p| p.into_inner()).remove(&account);
    }
}

/// How long closing waits for the workers
const SHUTDOWN_GRACE: std::time::Duration = std::time::Duration::from_secs(2);

impl Drop for Core {
    fn drop(&mut self) {
        self.closed.store(true, Ordering::Release);
        self.workers.lock().unwrap_or_else(|p| p.into_inner()).clear();
        if let Some(runtime) = self.runtime.take() {
            // workers that are waiting for the network are cancelled
            runtime.shutdown_timeout(SHUTDOWN_GRACE);
        }
    }
}
