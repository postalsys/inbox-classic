//! The mail engine the C API wraps: accounts and their passwords, one sync worker per account,
//! and what the windows show, the folder tree, the message list and the message view.
//!
//! Each worker owns an IMAP connection and a connection to the store of its own; the windows read
//! through another one. SQLite in WAL mode lets them read while a worker writes. Work the
//! windows start runs on the workers and reports back as [`Event`]s, on a worker thread.
#![forbid(unsafe_code)]

pub mod agents;
mod authres;
pub mod bimi;
pub mod book;
mod bounce;
pub mod calendar;
pub mod card_pictures;
mod compose;
mod contentline;
mod export;
mod fold;
pub mod layout;
mod list_view;
pub mod mailto;
pub mod otp;
pub mod pictures;
mod requests;
mod search;
mod secrets;
mod selection;
pub mod senders;
mod sign_in_apps;
mod snippet;
mod targets;
mod text;
pub mod timing;
pub mod unsubscribe;
pub mod vcard;
mod view;
mod watch;
mod worker;

use std::collections::HashMap;
use std::fmt;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, MutexGuard};

pub use list_view::ListView;
use pe_i18n::{Text, tr, tr_args};
use pe_net::Trust;
use pe_store::{Account, AccountId, AccountSettings, Folder, FolderId, Message, Sort, Store};
pub use pe_store::{Ahead, DEFAULT_LIMIT_MB, FlagColor};
pub use pe_store::{MessageRef, Scope, Search, Show, ThreadMark};
pub use selection::{Action, Summary, color_name};
pub use targets::{TargetKind, TargetRow};

/// A special use whose folders the folder list gathers from every account (`Core::special_folders`); All Sent and All
/// Drafts would add theirs
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SpecialFolderKind {
    Inbox,
}

/// An account's folder of a special use: a row under All Inboxes
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecialFolder {
    pub account: AccountId,
    pub folder: FolderId,
    /// The account's title, as the folder tree's heading for it has it
    pub name: String,
    /// The folder told apart by its account, for the folder bar and the window's title: "Inbox - Gmail"
    pub title: String,
    pub unread: u64,
}
use tokio::sync::mpsc::{UnboundedSender, unbounded_channel};

pub use compose::{ComposeError, Draft, DraftKind, Outgoing, address_label, autosave_wait};
pub use export::{Exported, write_file};
/// The words of the windows in the language in use
pub use pe_i18n as i18n;
/// The rules of the folder tree the windows show: how deep a folder is, and which stay as they are
pub use pe_sync::{is_special as is_fixed_folder, tree_depths};
use requests::Requests;
pub use secrets::PasswordStore;
use secrets::Secrets;
use sign_in_apps::{Discoveries, with_provider};
pub use sign_in_apps::{
    SecretChange, SignInAppEntry, SignInAppForm, SignInWith, builtin_name, builtin_off_text, register_hint,
};
pub use text::{
    DOWNLOAD_LIMITS_MB, HiddenUnread, ReaderState, account_label, account_shown_name, account_title, account_titles,
    default_account_name, download_limit_index, download_limit_text, downloading_text, folder_kind, folder_name,
    format_size, hidden_unread, initials, list_counts, messages, reader_page, retry_note, saved_text, sentence,
};
pub use view::{AttachmentView, MessageView};
use worker::{Command, Role, Worker};

/// The stack of each of the core's worker threads
const WORKER_STACK: usize = 8 * 1024 * 1024;

/// The version of the core, which the About boxes show
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Which of an account's workers
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Kind {
    Main,
    /// The reader, ready before the first click
    Reader,
    /// A second reader, for a click during a large download
    Spare,
    Background,
}

impl Kind {
    fn role(self) -> Role {
        match self {
            Kind::Main => Role::Main,
            Kind::Reader | Kind::Spare => Role::Reader,
            Kind::Background => Role::Background,
        }
    }
}

/// The workers of the accounts (or their readers): the commands they take, and the task to stop
type Workers = Mutex<HashMap<AccountId, (UnboundedSender<Command>, tokio::task::AbortHandle)>>;

/// What the engine tells the windows. Delivered on a worker thread.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Event {
    SyncStarted {
        account: AccountId,
    },
    SyncFinished {
        account: AccountId,
        /// What kept the sync from finishing (told by a `Failed` before), None when it did: the account is online
        failure: Option<FailureKind>,
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
    /// The source of a message is in the store, [`Core::message_view`] can show it; for a large message, its text
    /// first ([`Core::message_downloading`] says so), the rest read from the store once it is there
    MessageReady {
        folder: FolderId,
        uid: u64,
    },
    /// The message opened ([`Core::open_message`]) could not be downloaded: `kind` and `message` say why. Opening it
    /// again tries again
    MessageFailed {
        folder: FolderId,
        uid: u64,
        kind: FailureKind,
        message: String,
    },
    /// The logo `request` ([`Core::logo_start`]) is drawn, or there was none: [`Core::logo_result`]
    LogoReady {
        request: u64,
    },
    /// The picture `request` of a row of the list ([`Core::picture_start`]) is drawn, or there was none:
    /// [`Core::picture_result`]
    PictureReady {
        request: u64,
    },
    /// The one-click unsubscribe `request` ([`Core::unsubscribe`]) is done, or failed for `problem`
    Unsubscribed {
        request: u64,
        problem: Option<String>,
    },
    /// New unread mail came in the Inbox of `account` (`count` messages), or in a watched conversation in another folder
    /// of the user's ([`Core::mark_conversations`]), `uid` the newest, from `from` about `subject`
    NewMail {
        account: AccountId,
        folder: FolderId,
        uid: u64,
        count: usize,
        from: String,
        subject: String,
        /// The newest is in a watched conversation (Watch Conversation): announced even from a folder other than the
        /// Inbox, and the notification says so
        watched: bool,
        /// The notification's title and text, in the language in use: the apps show them as they are
        title: String,
        text: String,
    },
    /// A message was sent, and is in the Sent folder when the account has one
    MessageSent {
        account: AccountId,
        subject: String,
    },
    /// The draft with `message_id` ([`Core::save_draft`]) is in the Drafts folder on the server, or was not saved
    /// for `problem`
    DraftSaved {
        account: AccountId,
        message_id: String,
        problem: Option<String>,
    },
    /// The servers of an address were looked up: [`Core::autoconfig_result`]
    AutoconfigDone {
        request: u64,
    },
    /// A sign-in in the browser finished: [`Core::sign_in_result`]
    SignInDone {
        request: u64,
    },
    /// The issuer of a sign-in app was checked: [`Core::sign_in_app_check_result`]
    SignInAppChecked {
        request: u64,
    },
    /// The view of a message is built: [`Core::message_view_result`]
    ViewReady {
        request: u64,
    },
    /// A message went into the Outbox, left it, or got a reason why it did not go
    OutboxChanged {
        account: AccountId,
    },
    /// Work for an account failed; `kind` says what to do about it
    Failed {
        account: AccountId,
        kind: FailureKind,
        message: String,
    },
    /// An AI agent needs the user to answer: [`Core::agent_ask`] says what, [`Core::agent_answer`] answers
    AgentAsk {
        request: u64,
    },
    /// What agents did changed ([`Core::agent_log`])
    AgentLogChanged,
    /// Work under way, for the status bar: messages going to another account, how far it is ("Moving 3 of 12 messages
    /// to Archive...") and at the end what was done ("Moved 12 messages to Archive"); a large message opened, how far
    /// it is ("Downloading 4.2 MB of 15.0 MB") and that it is all here ("Downloaded 15.0 MB")
    Transferring {
        text: String,
    },
    /// A folder made with [`Core::create_folder`] is there, for a window waiting for it to choose it
    FolderCreated {
        account: AccountId,
        folder: FolderId,
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
    /// A message that can not be sent as it is
    Compose(ComposeError),
    /// Something the system did not allow (a listener for a sign-in)
    Unavailable(String),
    /// A folder name or a folder that can not be used
    Folder(pe_sync::FolderRefusal),
    /// Signing in again came back from another account than this one: the address it signed in to
    OtherAccount(String),
    /// What was entered can not be used, and why
    Invalid(String),
    /// A sign-in app the accounts with these addresses sign in with
    InUse(Vec<String>),
    /// A sign-in app that is turned off for new accounts
    TurnedOff,
}

/// Why a folder name can not be, in words
pub(crate) fn folder_refusal(refusal: &pe_sync::FolderRefusal) -> String {
    match refusal {
        pe_sync::FolderRefusal::BadName => tr(Text::ErrorFolderName),
        pe_sync::FolderRefusal::Separator(separator) => {
            tr_args(Text::ErrorFolderSeparator, &[("separator", separator.into())])
        }
        pe_sync::FolderRefusal::Special => tr(Text::ErrorFolderSpecial),
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::Store(error) => f.write_str(&tr_args(Text::ErrorStore, &[("error", (&error.to_string()).into())])),
            Error::NotFound => f.write_str(&tr(Text::ErrorNotFound)),
            Error::Closed => f.write_str(&tr(Text::ErrorClosed)),
            Error::Compose(error) => write!(f, "{error}"),
            Error::Unavailable(reason) => write!(f, "{reason}"),
            Error::Folder(refusal) => f.write_str(&folder_refusal(refusal)),
            Error::OtherAccount(email) => f.write_str(&tr_args(Text::ErrorOtherAccount, &[("email", email.into())])),
            Error::Invalid(reason) => f.write_str(reason),
            Error::InUse(accounts) => f.write_str(&tr_args(
                Text::ErrorInUse,
                &[("accounts", (&accounts.join(", ")).into())],
            )),
            Error::TurnedOff => f.write_str(&tr(Text::ErrorTurnedOff)),
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

/// The OAuth providers the engine signs in with: the built-in ones (with the client IDs of this build), or the
/// ones of [`Options::oauth_providers`] in their place
#[derive(Clone, Default)]
pub(crate) struct OAuthProviders(Arc<Vec<pe_oauth::Provider>>);

impl OAuthProviders {
    pub(crate) fn provider(&self, kind: pe_oauth::ProviderKind) -> pe_oauth::Provider {
        match self.0.iter().find(|p| p.kind == kind) {
            Some(provider) => provider.clone(),
            None => pe_oauth::Provider::builtin(kind),
        }
    }
}

/// What Next Unread does next, see [`Core::next_unread_step`]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum NextUnread {
    /// Select this message of the list
    Message(MessageRef),
    /// Ask `question`, and on yes show `folder` and take the step again from its top
    Ask { folder: FolderId, question: String },
    /// No unread mail anywhere else
    None,
}

/// How many messages the worker threads, or fetches the References of, at a time in the background
pub(crate) const THREAD_BATCH: usize = 200;

/// What the main window selects when it opens, see [`Core::start_message`]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Start {
    /// All Inboxes rather than one folder
    pub all_inboxes: bool,
    /// The folder of the message, or the first account's Inbox when there is none
    pub folder: FolderId,
    /// The newest message, `None` when the list is empty
    pub uid: Option<u64>,
}

/// Whether the folder tree has All Inboxes above the accounts: with two or more of them
pub fn all_inboxes_shown(accounts: usize) -> bool {
    accounts >= 2
}

/// How the engine works with servers and passwords
#[derive(Clone, Default)]
pub struct Options {
    /// The certificates servers are checked against: the platform's, or `Trust::Pinned` ones for test servers
    /// and a self-hosted server whose certificate the user accepted (all accounts)
    pub trust: Trust,
    /// Where passwords are kept between runs; tests use [`PasswordStore::Memory`], so they never write to the
    /// Credential Manager of the user running them
    pub passwords: PasswordStore,
    /// OAuth providers in place of the built-in ones of the same kind (tests, a mock provider)
    pub oauth_providers: Vec<pe_oauth::Provider>,
}

pub struct Core {
    path: PathBuf,
    /// The store the windows read and change
    store: Mutex<Store>,
    /// Taken when closing
    runtime: Option<tokio::runtime::Runtime>,
    /// The worker of each account: where its commands go, and how to stop it in the middle of one
    workers: Workers,
    /// The readers of the accounts: their own connections that download the messages opened (`worker::Role::Reader`)
    readers: Workers,
    /// The background workers of the accounts: conversations and search text on connections of their own
    /// (`worker::Role::Background`)
    backgrounds: Workers,
    /// Wakes the background workers when new mail was stored
    nudges: Arc<worker::Nudges>,
    /// The messages opened since the app started
    opened: worker::Opened,
    /// The opens under way, and what each reader downloads now
    opening: Arc<worker::Opening>,
    /// The text shown first of the large messages being downloaded
    partials: worker::Partials,
    /// The second readers: a click during a large download goes to one (`worker::Worker::spare`)
    spares: Workers,
    /// The access token of each OAuth account, which its worker and its reader share
    tokens: worker::Tokens,
    /// How long opening messages took
    timings: timing::Timings,
    /// A new number each time the computer woke from sleep (or [`Core::woke`] was called): connections are made again
    wake: Arc<tokio::sync::watch::Sender<u64>>,
    /// The accounts whose main worker finished a sync, for their readers to connect after
    synced: Arc<worker::Synced>,
    secrets: Secrets,
    trust: Trust,
    events: EventSink,
    /// Set when closing: no event is delivered after
    closed: Arc<AtomicBool>,
    /// The questions of AI agents waiting for the user (agents.rs)
    agent_asks: Mutex<agents::Asks>,
    /// Lookups of servers; None when the address has no domain
    autoconfig: Requests<Option<pe_autoconfig::Settings>>,
    /// BIMI logos being drawn, as pixels once done
    logos: Requests<Option<Vec<u8>>>,
    /// The pictures of the list's rows being drawn, as pixels once done
    pictures: Requests<Option<Vec<u8>>>,
    /// The logos being downloaded, by their row: rows asking at once share one download
    logo_downloads: LogoDownloads,
    /// Message views built off the window thread: parsing, folding and sanitizing a large message takes a while
    views: Requests<Option<MessageView>>,
    /// The view request the reading pane waits for; an older one gives up
    newest_view: Arc<std::sync::atomic::AtomicU64>,
    /// The connection the views built in the background look up and mark bounces with, opened by the first that
    /// needs it
    view_store: ViewStore,
    /// Sign-ins in the browser: the provider and the refresh token, or why not
    sign_ins: Requests<std::result::Result<SignedIn, String>>,
    /// Checks of a sign-in app's issuer, and the discovery documents they read
    checks: Requests<std::result::Result<pe_oauth::Discovered, String>>,
    discoveries: Discoveries,
    oauth: OAuthProviders,
    next_request: std::sync::atomic::AtomicU64,
    /// What Edit > Undo takes back (selection.rs)
    undo: Mutex<Option<selection::Undo>>,
    /// What the last Undo brought back, by folder and Message-ID, for the window to select once it is there
    restored: Mutex<Vec<(FolderId, Vec<String>)>>,
}

impl Core {
    /// Opens the store at `path` (created when missing) and starts the engine. `events` is called
    /// on worker threads, never on the thread that called into the engine.
    pub fn open(path: impl AsRef<Path>, events: impl Fn(Event) + Send + Sync + 'static) -> Result<Core> {
        Self::open_with(path, Options::default(), events)
    }

    /// Like [`Core::open`], with other [`Options`]
    pub fn open_with(
        path: impl AsRef<Path>,
        options: Options,
        events: impl Fn(Event) + Send + Sync + 'static,
    ) -> Result<Core> {
        let path = path.as_ref().to_path_buf();
        let store = Store::open(&path)?;
        let secrets = Secrets::new(options.passwords, &store.profile_id()?);
        let trust = options.trust;
        let runtime = tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .thread_name("pe-worker")
            // a command's futures nest deep (a move taken back between accounts connects to the other account inside
            // it), and unoptimized builds keep large frames for each: the 2 MiB of tokio's own default ran out
            .thread_stack_size(WORKER_STACK)
            .enable_all()
            .build()
            .map_err(|_| Error::Closed)?;
        // the patterns that fold earlier messages compile meanwhile, not when the first message is shown
        runtime.spawn_blocking(fold::warm_up);
        runtime.spawn_blocking(clear_private_dirs);
        // what was cached before the search index read sources (an older version), on a connection of its own
        let indexed = path.clone();
        runtime.spawn_blocking(move || {
            if let Ok(mut store) = Store::open(&indexed) {
                let _ = search::index_pending(&mut store);
            }
        });
        let wake = Arc::new(tokio::sync::watch::Sender::new(0));
        runtime.spawn(worker::watch_sleep(wake.clone()));
        // what a move the app was in the middle of when it last ended left behind
        store.clear_moving_sources()?;
        let closed = Arc::new(AtomicBool::new(false));
        let open = closed.clone();
        Ok(Core {
            wake,
            synced: Arc::new(worker::Synced::new(Default::default())),
            path,
            store: Mutex::new(store),
            runtime: Some(runtime),
            workers: Mutex::default(),
            readers: Mutex::default(),
            backgrounds: Mutex::default(),
            nudges: Arc::default(),
            opened: worker::Opened::default(),
            opening: Arc::default(),
            partials: worker::Partials::default(),
            spares: Mutex::default(),
            tokens: worker::Tokens::default(),
            timings: timing::Timings::default(),
            secrets,
            trust,
            events: Arc::new(move |event| {
                if !open.load(Ordering::Acquire) {
                    events(event);
                }
            }),
            closed,
            agent_asks: Mutex::default(),
            autoconfig: Requests::default(),
            logos: Requests::default(),
            pictures: Requests::default(),
            logo_downloads: Arc::default(),
            views: Requests::default(),
            newest_view: Arc::default(),
            view_store: Arc::default(),
            sign_ins: Requests::default(),
            checks: Requests::default(),
            discoveries: Discoveries::default(),
            oauth: OAuthProviders(Arc::new(options.oauth_providers)),
            next_request: std::sync::atomic::AtomicU64::new(1),
            undo: Mutex::new(None),
            restored: Mutex::default(),
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

    /// Adds an account, its password kept as the [`Options`] say
    pub fn add_account(&self, settings: &AccountSettings, password: &str) -> Result<AccountId> {
        let id = self.store().add_account(settings)?;
        // named by its provider or domain to begin with ("Gmail"), the folder list's name for it
        self.store()
            .set_account_name(id, &default_account_name(&settings.email))?;
        // an account removed before may have had this id: its password goes, whatever happens to this one
        self.secrets.remove(id);
        self.keep_password(id, password);
        Ok(id)
    }

    fn keep_password(&self, account: AccountId, password: &str) {
        if let Err(error) = self.secrets.set(account, password) {
            // the password still works for this run
            let _ = self.post(Event::Failed {
                account,
                kind: FailureKind::Other,
                message: tr_args(Text::ErrorPasswordNotSaved, &[("error", (&error.to_string()).into())]),
            });
        }
    }

    /// How many messages are unread in the Inboxes of all accounts
    pub fn inbox_unread(&self) -> Result<u64> {
        Ok(self.store().inbox_unread()?)
    }

    /// The people whose address or name starts with what was typed, best first, for completing an address
    pub fn contacts(&self, typed: &str, limit: usize) -> Result<Vec<pe_store::Contact>> {
        Ok(self.store().contacts_matching(typed, limit)?)
    }

    /// Someone taken out of the completions for good
    pub fn forget_contact(&self, address: &str) -> Result<()> {
        Ok(self.store().forget_contact(address)?)
    }

    /// The signature of an account, as sanitized HTML; empty for none
    pub fn signature(&self, account: AccountId) -> Result<String> {
        Ok(self.store().signature(account)?)
    }

    /// Keeps a signature for an account, sanitized ([`pe_html::signature_html`]); empty for none
    pub fn set_signature(&self, account: AccountId, html: &str) -> Result<()> {
        Ok(self.store().set_signature(account, &pe_html::signature_html(html))?)
    }

    /// What a new message, reply or forward from an account starts with: an empty line, then its signature
    /// ([`pe_html::signature_block`]); empty without one
    pub fn signature_block(&self, account: AccountId) -> Result<String> {
        Ok(pe_html::signature_block(&self.signature(account)?))
    }

    /// Sets the account's own name for the folder list ("Gmail"); empty for the name on its mail
    pub fn set_account_name(&self, account: AccountId, name: &str) -> Result<()> {
        Ok(self.store().set_account_name(account, name)?)
    }

    /// Trusts the sender `value` (an address, or with `domain` a whole domain): their pictures load by themselves
    /// when the provider confirms the message is theirs
    pub fn trust_sender(&self, value: &str, domain: bool) -> Result<()> {
        Ok(self.store().trust_sender(value, domain)?)
    }

    pub fn untrust_sender(&self, id: i64) -> Result<()> {
        Ok(self.store().untrust_sender(id)?)
    }

    /// The trusted senders, for Options' list
    pub fn trusted_senders(&self) -> Result<Vec<pe_store::TrustedSender>> {
        Ok(self.store().trusted_senders()?)
    }

    /// Settings' "Download messages ahead": recent ones up to 1 MB (the default), all, or only when opened
    pub fn download_ahead(&self) -> Result<pe_store::Ahead> {
        Ok(self.store().download_ahead()?)
    }

    /// Changes what is downloaded ahead; the background workers start on what it adds
    pub fn set_download_ahead(&self, ahead: pe_store::Ahead) -> Result<()> {
        self.store().set_download_ahead(ahead)?;
        self.more_to_download();
        Ok(())
    }

    /// "Keep at most [n] MB of downloaded messages for each account"
    pub fn download_limit_mb(&self) -> Result<u64> {
        Ok(self.store().download_limit_mb()?)
    }

    /// Changes the limit; the oldest sources go past it with the next batch of the background workers
    pub fn set_download_limit_mb(&self, megabytes: u64) -> Result<()> {
        self.store().set_download_limit_mb(megabytes)?;
        self.more_to_download();
        Ok(())
    }

    /// The background workers of the accounts look for work again
    fn more_to_download(&self) {
        for account in self.backgrounds.lock().unwrap_or_else(|p| p.into_inner()).keys() {
            worker::nudge(&self.nudges, *account);
        }
    }

    /// Options' "Download pictures in all messages"
    pub fn always_load_pictures(&self) -> Result<bool> {
        Ok(self.store().always_load_pictures()?)
    }

    pub fn set_always_load_pictures(&self, on: bool) -> Result<()> {
        Ok(self.store().set_always_load_pictures(on)?)
    }

    /// Puts `account` at `index` in the accounts' order (0 first), which the folder list and All Inboxes' rows follow
    pub fn move_account(&self, account: AccountId, index: usize) -> Result<()> {
        Ok(self.store().move_account(account, index)?)
    }

    /// Each account's folder of a special use (its Inbox), in the accounts' order, with the account's title and the
    /// folder's unread count: the rows under All Inboxes. An account without that folder yet has no row
    pub fn special_folders(&self, special: SpecialFolderKind) -> Result<Vec<SpecialFolder>> {
        let store = self.store();
        let accounts = store.accounts()?;
        let titles = account_titles(&accounts);
        let folders = match special {
            // the store's own rule, the one All Inboxes' list uses
            SpecialFolderKind::Inbox => store.inboxes()?,
        };
        let mut found = Vec::new();
        for folder in folders {
            let folder = store.folder(folder)?;
            let Some(at) = accounts.iter().position(|a| a.id == folder.account_id) else {
                continue;
            };
            // one row an account, should a server have two that match
            if found.iter().any(|f: &SpecialFolder| f.account == folder.account_id) {
                continue;
            }
            found.push(SpecialFolder {
                account: folder.account_id,
                folder: folder.id,
                title: format!("{} - {}", text::folder_name(&folder.info), titles[at]),
                name: titles[at].clone(),
                unread: folder.unread,
            });
        }
        // in the accounts' order
        found.sort_by_key(|f| accounts.iter().position(|a| a.id == f.account));
        Ok(found)
    }

    /// Changes the settings of an account; how it signs in stays, only signing in again changes that
    pub fn update_account(&self, id: AccountId, settings: &AccountSettings) -> Result<()> {
        let mut settings = settings.clone();
        settings.auth = self.store().account(id)?.settings.auth;
        if let pe_store::Auth::OAuth2(name) = &settings.auth
            && let Some(provider) = self.oauth.resolve(name, &self.store(), &self.secrets)
        {
            settings = with_provider(&settings, &provider, &settings.auth);
        }
        self.store().update_account(id, &settings)?;
        // the worker connects again with the new settings
        self.stop_worker(id);
        Ok(())
    }

    pub fn remove_account(&self, id: AccountId) -> Result<()> {
        // now, not after its current command: a sync it was running would write into the next account that gets
        // this id
        for workers in self.all_workers() {
            if let Some((_, task)) = workers.lock().unwrap_or_else(|p| p.into_inner()).remove(&id) {
                task.abort();
            }
        }
        self.tokens.lock().unwrap_or_else(|p| p.into_inner()).remove(&id);
        self.store().remove_account(id)?;
        self.secrets.remove(id);
        Ok(())
    }

    pub fn set_password(&self, id: AccountId, password: &str) {
        self.keep_password(id, password);
    }

    pub fn account(&self, id: AccountId) -> Result<Account> {
        Ok(self.store().account(id)?)
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

    /// What the main window selects when it opens (`None` when there is no account or the first one has no Inbox
    /// yet): with two or more accounts All Inboxes and the newest message of every Inbox, with one its Inbox and its
    /// newest message (by date)
    pub fn start_message(&self) -> Result<Option<Start>> {
        let store = self.store();
        let accounts = store.accounts()?;
        let Some(account) = accounts.first() else {
            return Ok(None);
        };
        let Some(inbox) = store.find_folder(account.id, "INBOX")? else {
            return Ok(None);
        };
        let all_inboxes = all_inboxes_shown(accounts.len());
        let search = Search {
            scope: if all_inboxes {
                Scope::AllInboxes
            } else {
                Scope::Folder(inbox.id)
            },
            ..Default::default()
        };
        let newest = Sort {
            field: pe_store::SortField::Date,
            ascending: false,
        };
        let message = store.search(&search, newest, 0, 1)?.into_iter().next();
        Ok(Some(Start {
            all_inboxes,
            folder: message.as_ref().map_or(inbox.id, |m| m.folder_id),
            uid: message.map(|m| m.info.uid),
        }))
    }

    /// A page of what `search` finds (Gmail's syntax, see [`pe_store::Query`]), in the order of `sort`
    pub fn search(&self, search: &Search, sort: Sort, offset: u64, limit: u64) -> Result<Vec<Message>> {
        let sort = self.list_sort(search, sort)?;
        Ok(self.store().search(search, sort, offset, limit)?)
    }

    /// How many messages [`Core::search`] finds, and how many of them are unread, grouped by conversation or not
    pub fn count_search(&self, search: &Search) -> Result<(u64, u64)> {
        Ok(self.store().count_search(search)?)
    }

    /// The counts of the status bar for the list of `search`: those of a folder shown whole from its indexes, those
    /// of a search, All Inboxes or a folder without its ignored conversations (Hide Ignored) counted from what they
    /// find
    pub fn list_counts(&self, search: &Search) -> Result<(u64, u64)> {
        match search.scope {
            Scope::Folder(folder) if search.text.is_empty() && search.show == Show::All && !search.hide_ignored => {
                let folder = self.folder(folder)?;
                Ok((folder.total, folder.unread))
            }
            _ => self.count_search(search),
        }
    }

    /// How many rows the list of [`Core::search`] has: grouped by conversation one a conversation and the other
    /// messages of the expanded ones, otherwise one a message
    pub fn count_rows(&self, search: &Search) -> Result<u64> {
        Ok(self.store().count_rows(search)?)
    }

    /// Where the message `uid` of `folder` is in what [`Core::search`] finds
    pub fn search_index(&self, search: &Search, sort: Sort, folder: FolderId, uid: u64) -> Result<Option<u64>> {
        let sort = self.list_sort(search, sort)?;
        Ok(self.store().search_index(search, sort, folder, uid)?)
    }

    /// Whether the list of `search` names whom its messages went to rather than who sent them, as Sent Items and
    /// Drafts do; a search's results and All Inboxes name the sender. Its person column is then To, and a From sort
    /// is by the recipients.
    pub fn lists_recipients(&self, search: &Search) -> Result<bool> {
        use pe_imap::SpecialUse;
        let Scope::Folder(folder) = search.scope else {
            return Ok(false);
        };
        if !search.text.trim().is_empty() {
            return Ok(false);
        }
        let special = self.store().folder(folder)?.info.special_use;
        Ok(matches!(
            special.as_deref().and_then(SpecialUse::from_flag),
            Some(SpecialUse::Sent | SpecialUse::Drafts)
        ))
    }

    /// `sort` as the list of `search` means it: by the person column, which is the recipients where
    /// [`Core::lists_recipients`]
    pub(crate) fn list_sort(&self, search: &Search, sort: Sort) -> Result<Sort> {
        if sort.field == pe_store::SortField::From && self.lists_recipients(search)? {
            return Ok(Sort {
                field: pe_store::SortField::To,
                ..sort
            });
        }
        Ok(sort)
    }

    /// The messages before and after the message `uid` of `folder` in the list `search` and `sort` make: what Previous
    /// and Next open, with one pass over the list. None when the message is not in that list (any more): a window
    /// keeps the pair it had then, so Next still goes on from where it was.
    #[allow(clippy::type_complexity)]
    pub fn neighbours(
        &self,
        search: &Search,
        sort: Sort,
        folder: FolderId,
        uid: u64,
    ) -> Result<Option<(Option<MessageRef>, Option<MessageRef>)>> {
        let sort = self.list_sort(search, sort)?;
        Ok(self.store().neighbours(search, sort, folder, uid)?)
    }

    /// The first unread message after the message `uid` of `folder` in the list `search` and `sort` make (from the top
    /// when `uid` is 0 or not in the list): what Next Unread opens. None when there is no unread one after it.
    pub fn next_unread(&self, search: &Search, sort: Sort, folder: FolderId, uid: u64) -> Result<Option<MessageRef>> {
        let sort = self.list_sort(search, sort)?;
        Ok(self.store().next_unread(search, sort, folder, uid)?)
    }

    /// The next folder after `folder` in the folder tree with unread mail, of its account and then of the accounts
    /// after it, around to the first (Junk E-mail and Deleted Items left out, as the counts of collapsed folders leave
    /// them out): where Next Unread goes on, after asking. None when no other folder has unread mail.
    pub fn next_unread_folder(&self, folder: FolderId) -> Result<Option<FolderId>> {
        let store = self.store();
        let mut tree = Vec::new();
        for account in store.accounts()? {
            tree.extend(store.folders(account.id)?);
        }
        let start = tree.iter().position(|f| f.id == folder).map_or(0, |at| at + 1);
        // Junk E-mail and Deleted Items, the folders that can be emptied, do not count
        let counted = |f: &Folder| f.info.selectable && f.unread > 0 && !emptiable(&f.info);
        Ok((0..tree.len())
            .map(|step| &tree[(start + step) % tree.len()])
            .find(|f| f.id != folder && counted(f))
            .map(|f| f.id))
    }

    /// What Next Unread asks before it goes on to the folder `to`: "There are no more unread messages in Inbox." and,
    /// after a blank line, "Go to Archive, the next folder with unread messages?"
    pub fn next_unread_question(&self, from: FolderId, to: FolderId) -> Result<String> {
        let store = self.store();
        let accounts = store.accounts()?;
        let titles = account_titles(&accounts);
        let name = |id: FolderId| -> Result<String> {
            let folder = store.folder(id)?;
            let mut name = crate::text::folder_name(&folder.info);
            // with several accounts, which one's: as the folder list calls it
            if accounts.len() > 1
                && let Some(at) = accounts.iter().position(|a| a.id == folder.account_id)
            {
                name = format!("{name} ({})", titles[at]);
            }
            Ok(name)
        };
        Ok(tr_args(
            Text::NextUnreadQuestion,
            &[("folder", (&name(from)?).into()), ("next", (&name(to)?).into())],
        ))
    }

    /// One step of Next Unread from the message `uid` of `folder` (0 for none) in the list `search` and `sort` make: the
    /// next unread message of that list; else, when another folder has unread mail, that folder and the question to
    /// ask before going there (the window then shows that folder and takes the step again from its top); else nothing.
    pub fn next_unread_step(&self, search: &Search, sort: Sort, folder: FolderId, uid: u64) -> Result<NextUnread> {
        if let Some(found) = self.next_unread(search, sort, folder, uid)? {
            return Ok(NextUnread::Message(found));
        }
        // on from the folder the list shows, or from the message's when it shows several
        let from = match search.scope {
            Scope::Folder(shown) if search.text.trim().is_empty() => shown,
            _ => folder,
        };
        if from == 0 {
            return Ok(NextUnread::None);
        }
        Ok(match self.next_unread_folder(from)? {
            Some(next) => NextUnread::Ask {
                folder: next,
                question: self.next_unread_question(from, next)?,
            },
            None => NextUnread::None,
        })
    }

    /// Whether the message `uid` is (still) in `folder`, a single row looked up
    pub fn has_message(&self, folder: FolderId, uid: u64) -> Result<bool> {
        Ok(self.store().message(folder, uid)?.is_some())
    }

    /// The conversations of the list `search` makes that have more than one message there: what Expand All opens
    pub fn threads_with_replies(&self, search: &Search) -> Result<Vec<i64>> {
        Ok(self.store().threads_with_replies(search)?)
    }

    /// The conversation the message `uid` of `folder` is hidden in, in the list `search` makes: grouped by
    /// conversation, that conversation collapsed and the message not its first there (whose row stands for it). None
    /// when it has its own row or is not in the list. The list opens that conversation to select it.
    pub fn hidden_in(&self, search: &Search, folder: FolderId, uid: u64) -> Result<Option<i64>> {
        Ok(self.store().hidden_in(search, folder, uid)?)
    }

    /// The one folder the text of a search narrows it to (`in:sent`), by the name the app gives it; `None` for every
    /// folder
    pub fn search_place(text: &str) -> Option<String> {
        pe_store::Query::parse(text, 0).place_name()
    }

    /// How many messages the search does not know the text of yet: their text parts are fetched in the background,
    /// newest first, after each sync
    pub fn unindexed_count(&self) -> Result<u64> {
        Ok(self.store().unindexed_count()?)
    }

    /// One folder with its counts
    pub fn folder(&self, folder: FolderId) -> Result<Folder> {
        Ok(self.store().folder(folder)?)
    }

    /// Where a message is in the message list in this order
    pub fn message_index(&self, folder: FolderId, sort: Sort, uid: u64) -> Result<Option<u64>> {
        Ok(self.store().message_index(folder, sort, uid)?)
    }

    /// Unsubscribes from the mailing list of a message the one-click way (RFC 8058): a POST of
    /// `List-Unsubscribe=One-Click` to the address the message gives, without cookies, redirects not followed, in
    /// the background; [`Event::Unsubscribed`] follows with the request this returns. Refused for a message that
    /// offers no one-click way ([`crate::unsubscribe::of`]), whose source is not in the store.
    pub fn unsubscribe(&self, folder: FolderId, uid: u64) -> Result<u64> {
        // the header block is all it takes
        let start = self
            .store()
            .source_start(folder, uid, view::MAX_HEADER_TEXT)?
            .ok_or(Error::NotFound)?;
        let message = pe_mime::parser::parse(&start).map_err(|_| Error::NotFound)?;
        let Some(unsubscribe::Unsubscribe::OneClick { url }) =
            unsubscribe::of(&message.headers, &self.trusted(folder)?)
        else {
            return Err(Error::NotFound);
        };
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        let events = self.events.clone();
        self.runtime()?.spawn(async move {
            let answer = pe_net::http::post_form(
                &url,
                &[("List-Unsubscribe", "One-Click")],
                std::time::Duration::from_secs(30),
            )
            .await;
            let problem = match answer {
                Ok(response) if (200..300).contains(&response.status) => None,
                Ok(response) => Some(tr_args(
                    Text::ErrorListAnswered,
                    &[("status", u32::from(response.status).into())],
                )),
                Err(error) => Some(error.to_string()),
            };
            events(Event::Unsubscribed { request, problem });
        });
        Ok(request)
    }

    /// Looks up the servers of `email` in the background: [`Event::AutoconfigDone`] follows with the request
    /// this returns
    ///
    /// With `password`, a Microsoft Autodiscover server that asks for it (hosted Exchange) is answered, over https
    /// and only to the server that asked (see pe-autoconfig)
    pub fn autoconfig(&self, email: &str, password: Option<&str>) -> Result<u64> {
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        let email = email.to_string();
        let credentials = password
            .filter(|p| !p.is_empty())
            .map(|password| pe_autoconfig::Credentials {
                user: None,
                password: password.to_string(),
            });
        let work = async move { pe_autoconfig::discover(&email, credentials.as_ref()).await };
        self.autoconfig
            .start(self.runtime()?, request, work, self.events.clone(), |request| {
                Event::AutoconfigDone { request }
            });
        Ok(request)
    }

    /// What a lookup found, once it is done and once: None for an address without a domain, a lookup that is
    /// still running, or an unknown request
    pub fn autoconfig_result(&self, request: u64) -> Option<pe_autoconfig::Settings> {
        self.autoconfig.take(request).flatten()
    }

    /// The BIMI logo of a message ([`bimi::of`]) drawn `size` pixels square, in the background:
    /// [`Event::LogoReady`] follows with the request this returns. The SVG of BIMI-Indicator is drawn as it is; one
    /// at a BIMI-Location is the list's logo of that address, downloaded once and kept (see [`Self::picture_start`]).
    /// Refused for a message without a logo the receiving server passed, or not downloaded yet.
    pub fn logo_start(&self, folder: FolderId, uid: u64, size: u32) -> Result<u64> {
        let start = self
            .store()
            .source_start(folder, uid, view::MAX_HEADER_TEXT)?
            .ok_or(Error::NotFound)?;
        let headers = pe_mime::parser::parse(&start).map_err(|_| Error::NotFound)?.headers;
        let logo = bimi::of(&headers, &self.trusted(folder)?).ok_or(Error::NotFound)?;
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        let logos = self.logo_source();
        let work = async move {
            let svg = match logo {
                bimi::Logo::Indicator(svg) => Some(svg),
                bimi::Logo::Location(url) => logos.svg(KeptLogo::At(url)).await,
            };
            svg.and_then(|svg| bimi::render(&svg, size))
        };
        self.logos
            .start(self.runtime()?, request, work, self.events.clone(), |request| {
                Event::LogoReady { request }
            });
        Ok(request)
    }

    /// The pixels of a drawn logo (BGRA, the alpha multiplied in, `size` x `size`), taken once; None when there was
    /// none to draw or it is not done
    pub fn logo_result(&self, request: u64) -> Option<Vec<u8>> {
        self.logos.take(request).flatten()
    }

    /// The picture of a row of the list (its key, [`senders::picture`]) drawn `size` pixels square, in the background:
    /// [`Event::PictureReady`] follows with the request this returns. A brand's logo is downloaded once and kept
    /// ([`pe_store::LOGO_KEPT_MS`]; a failure is not tried again for [`pe_store::LOGO_RETRY_MS`]), never a message at
    /// a time. Refused for a key that names no picture.
    pub fn picture_start(&self, key: u64, size: u32) -> Result<u64> {
        if let Some(card) = senders::contact_card(key) {
            return self.contact_picture_start(card, size);
        }
        let Some((senders::PictureKind::Logo, id)) = senders::picture_of(key) else {
            return Err(Error::NotFound);
        };
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        let logos = self.logo_source();
        let work = async move {
            logos
                .svg(KeptLogo::Row(id))
                .await
                .and_then(|svg| bimi::render(&svg, size))
        };
        self.pictures
            .start(self.runtime()?, request, work, self.events.clone(), |request| {
                Event::PictureReady { request }
            });
        Ok(request)
    }

    /// Where the kept logos are read and written off the window thread
    fn logo_source(&self) -> LogoSource {
        LogoSource {
            path: self.path.clone(),
            view_store: self.view_store.clone(),
            downloads: self.logo_downloads.clone(),
        }
    }

    /// A card's picture drawn `size` square for the list or the reading pane, as [`Core::picture_start`] draws one: its
    /// PNG read and drawn off the window thread, on the views' store connection; [`Event::PictureReady`] without
    /// pixels when the card has no picture (any more)
    fn contact_picture_start(&self, card: pe_store::CardId, size: u32) -> Result<u64> {
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        let (path, view_store) = (self.path.clone(), self.view_store.clone());
        let work = async move {
            tokio::task::spawn_blocking(move || {
                let (png, _) = OpenStore::open(&view_store, &path)?.card_picture(card).ok()??;
                card_pictures::bgra(&png, size)
            })
            .await
            .ok()
            .flatten()
        };
        self.pictures
            .start(self.runtime()?, request, work, self.events.clone(), |request| {
                Event::PictureReady { request }
            });
        Ok(request)
    }

    /// The pixels of a drawn picture (BGRA, the alpha multiplied in, `size` x `size`), taken once; None when there was
    /// none to draw or it is not done
    pub fn picture_result(&self, request: u64) -> Option<Vec<u8>> {
        self.pictures.take(request).flatten()
    }

    /// Stops a lookup the user no longer waits for, and forgets it
    pub fn autoconfig_cancel(&self, request: u64) {
        self.autoconfig.cancel(request);
    }

    /// The provider this IMAP server belongs to, when it is one Inbox Classic signs in to with OAuth (every build has
    /// their clients)
    pub fn oauth_provider_for(&self, imap_host: &str) -> Option<pe_oauth::ProviderKind> {
        pe_oauth::ProviderKind::for_imap_host(imap_host)
    }

    /// Starts signing in with `with` for `email`: the page to open in the browser, and the request
    /// [`Event::SignInDone`] comes with once the browser came back or the time ran out. A sign-in app that is turned
    /// off can still sign in again an account that uses it; [`Core::add_signed_in_account`] refuses a new one.
    pub fn sign_in_begin(&self, with: SignInWith, email: &str) -> Result<(u64, String)> {
        let provider = self.sign_in_provider(with)?;
        let sign_in =
            pe_oauth::SignIn::begin(provider.clone(), email).map_err(|e| Error::Unavailable(e.to_string()))?;
        let url = sign_in.url.clone();
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        let work = async move {
            let tokens = sign_in
                .finish(pe_oauth::SIGN_IN_TIMEOUT)
                .await
                .map_err(|e| e.to_string())?;
            let refresh_token = tokens.refresh_token.ok_or_else(|| tr(Text::SignInNoRefresh))?;
            let identity = tokens.identity.ok_or_else(|| tr(Text::SignInNoAccount))?;
            Ok(SignedIn {
                with,
                provider,
                refresh_token,
                identity,
            })
        };
        self.sign_ins
            .start(self.runtime()?, request, work, self.events.clone(), |request| {
                Event::SignInDone { request }
            });
        Ok((request, url))
    }

    /// How a sign-in ended: Ok when there is a refresh token to add an account with (kept for that), the reason
    /// otherwise (and the sign-in is forgotten)
    pub fn sign_in_result(&self, request: u64) -> std::result::Result<(), String> {
        let found = self.sign_ins.inspect(request, |result| match result {
            Ok(_) => (Ok(()), true),
            Err(reason) => (Err(reason.clone()), false),
        });
        found.unwrap_or_else(|| Err(tr(Text::SignInNotFinished)))
    }

    /// Stops a sign-in the user no longer waits for, and forgets it
    pub fn sign_in_cancel(&self, request: u64) {
        self.sign_ins.cancel(request);
    }

    /// A finished sign-in, taken
    fn take_sign_in(&self, request: u64) -> Result<SignedIn> {
        self.sign_ins.take(request).and_then(|r| r.ok()).ok_or(Error::NotFound)
    }

    /// Adds the account the sign-in `request` was for, named `name` (when empty, as its owner is named at the
    /// provider): the address is the one signed in to, whatever was typed before, and the servers are the
    /// provider's, so its access tokens go nowhere else
    pub fn add_signed_in_account(&self, request: u64, name: &str) -> Result<AccountId> {
        let signed_in = self.take_sign_in(request)?;
        if !self.sign_in_enabled(signed_in.with)? {
            return Err(Error::TurnedOff);
        }
        let pe_oauth::Identity { email, name: owner } = signed_in.identity;
        let name = Some(name.trim())
            .filter(|n| !n.is_empty())
            .map(str::to_string)
            .or(owner)
            .unwrap_or_else(|| email.clone());
        let settings = AccountSettings {
            name,
            email: email.clone(),
            username: email,
            ..Default::default()
        };
        let auth = pe_store::Auth::OAuth2(signed_in.with.auth_name());
        self.add_account(
            &with_provider(&settings, &signed_in.provider, &auth),
            &signed_in.refresh_token,
        )
    }

    /// Gives an OAuth account the refresh token of a new sign-in, after the old one was refused; refused when the
    /// browser signed in to another account
    pub fn reauthorize(&self, account: AccountId, request: u64) -> Result<()> {
        let signed_in = self.take_sign_in(request)?;
        let current = self.store().account(account)?.settings;
        if !signed_in.identity.email.eq_ignore_ascii_case(&current.email) {
            return Err(Error::OtherAccount(signed_in.identity.email));
        }
        let refresh_token = signed_in.refresh_token;
        let auth = pe_store::Auth::OAuth2(signed_in.with.auth_name());
        let settings = with_provider(&current, &signed_in.provider, &auth);
        self.store().update_account(account, &settings)?;
        self.stop_worker(account);
        self.keep_password(account, &refresh_token);
        Ok(())
    }

    /// Syncs the folder list and every folder of an account, in the background
    pub fn sync(&self, account: AccountId) -> Result<()> {
        self.send_command(account, Command::Sync)?;
        // the reader connects after the first sync, ready for the first message opened; the background worker starts
        // then too
        self.send_to(Kind::Reader, account, Command::Connect)?;
        self.worker_of(Kind::Background, account).map(|_| ())
    }

    /// The computer woke from sleep, or the network changed: every connection is dropped and made again, the main
    /// workers sync. The core notices a sleep by itself; an app calls this when the system tells it about the network.
    pub fn woke(&self) {
        worker::tell_woke(&self.wake);
    }

    /// One message of a folder as the list shows it, None when the folder has no message with this UID
    pub fn message(&self, folder: FolderId, uid: u64) -> Result<Option<Message>> {
        Ok(self.store().message(folder, uid)?)
    }

    /// Gets the source of a message to the store, in the background, on the account's reader: a connection of its own,
    /// so it does not wait for a sync. [`Event::MessageReady`] follows, right away when it is cached, or
    /// [`Event::MessageFailed`] when it can not be downloaded
    pub fn open_message(&self, folder: FolderId, uid: u64) -> Result<()> {
        let account = self.store().folder(folder)?.account_id;
        // a large download under way is not waited for: the click goes to a second reader
        let reader = match self.opening.large_download(account) {
            true => Kind::Spare,
            false => Kind::Reader,
        };
        self.send_to(
            reader,
            account,
            Command::FetchSource {
                folder,
                uid,
                asked: std::time::Instant::now(),
            },
        )
    }

    /// Whether the last message opened came from the store, with no connection used: downloaded ahead
    pub fn last_open_from_store(&self) -> bool {
        self.timings.last_served() == Some(timing::Served::Store)
    }

    /// Whether a message's text is shown before the rest of it, which is still being downloaded: its attachments,
    /// Save As, View Source and Forward wait for it
    pub fn message_downloading(&self, folder: FolderId, uid: u64) -> bool {
        self.partials.get(folder, uid).is_some()
    }

    /// How long the last messages opened took, oldest first ([`timing::KEPT`] at most)
    pub fn open_timings(&self) -> Vec<timing::OpenTiming> {
        self.timings.all()
    }

    /// The source of a message and the date the server got it, for a view
    fn view_source(&self, folder: FolderId, uid: u64) -> Result<Option<ViewSource>> {
        let store = self.store();
        let (received, marked) = store
            .message(folder, uid)?
            .map_or((None, false), |m| (m.info.internal_date, m.info.bounce));
        // with the store at hand: trusted() takes it again
        let place = store.folder(folder)?;
        let account = place.account_id;
        let trusted = authres::trusted(&store.account(account)?.settings);
        // a code in Junk E-mail may be bait, and one in Sent Items or Drafts is the user's own
        let codes = !matches!(
            place.info.special_use.as_deref(),
            Some("\\Junk" | "\\Sent" | "\\Drafts")
        );
        // pictures load by themselves for the senders the user trusts, or every message's; never in Junk E-mail
        let junk = place.info.special_use.as_deref() == Some("\\Junk");
        let always_pictures = store.always_load_pictures()?;
        // the list matters only where it can load pictures
        let trusted_senders = match junk || always_pictures {
            true => Vec::new(),
            false => store.trusted_senders()?,
        };
        // the text of a large message being downloaded, shown before the rest (worker/large.rs)
        let (source, first) = match store.source(folder, uid)? {
            Some(source) => (Some(Arc::new(source)), None),
            None => match self.partials.get(folder, uid) {
                Some(first) => (Some(Arc::new(first.source.clone())), Some(first)),
                None => (None, None),
            },
        };
        Ok(source.map(|source| ViewSource {
            source,
            first,
            received,
            marked,
            trusted,
            codes,
            junk,
            always_pictures,
            trusted_senders,
            account,
            folder,
            uid,
        }))
    }

    /// The domains whose verdicts in a message's headers (Authentication-Results) the provider of the folder's
    /// account gives
    fn trusted(&self, folder: FolderId) -> Result<Vec<String>> {
        let store = self.store();
        Ok(authres::trusted(
            &store.account(store.folder(folder)?.account_id)?.settings,
        ))
    }

    /// The message as the preview shows it, None when its source is not in the store yet. Built on the calling
    /// thread, for tests and tools; the windows use [`Core::message_view_start`].
    pub fn message_view(&self, folder: FolderId, uid: u64, allow_remote_images: bool) -> Result<Option<MessageView>> {
        let Some(found) = self.view_source(folder, uid)? else {
            return Ok(None);
        };
        Ok(finish_view(
            &found,
            allow_remote_images,
            &|| false,
            || Some(self.store()),
            // on a worker thread, as every event
            &|event| {
                let _ = self.post(event);
            },
        ))
    }

    /// Builds the view of a message in the background: [`Event::ViewReady`] follows with the request this returns.
    /// The source is read now; parsing, folding and sanitizing it happen on a worker thread. A view started after
    /// it, or [`Core::message_view_cancel`], makes it give up between those steps: one is shown at a time.
    pub fn message_view_start(&self, folder: FolderId, uid: u64, allow_remote_images: bool) -> Result<u64> {
        let found = self.view_source(folder, uid)?;
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        self.newest_view.store(request, Ordering::Relaxed);
        let newest = self.newest_view.clone();
        let path = self.path.clone();
        let view_store = self.view_store.clone();
        let events = self.events.clone();
        let timings = self.timings.clone();
        let work = async move {
            let found = found?;
            let dropped = move || newest.load(Ordering::Relaxed) != request;
            let built = tokio::task::spawn_blocking(move || {
                let opened = || OpenStore::open(&view_store, &path);
                let view = finish_view(&found, allow_remote_images, &dropped, opened, &*events);
                timings.view_built(found.folder, found.uid, std::time::Instant::now());
                view
            });
            built.await.ok().flatten()
        };
        self.views
            .start(self.runtime()?, request, work, self.events.clone(), |request| {
                Event::ViewReady { request }
            });
        Ok(request)
    }

    /// The view a [`Core::message_view_start`] built, once: None while it is built, for an unknown request, or when
    /// the source was not in the store
    pub fn message_view_result(&self, request: u64) -> Option<MessageView> {
        self.views.take(request).flatten()
    }

    /// Drops a view no longer waited for (another message was selected)
    pub fn message_view_cancel(&self, request: u64) {
        let _ = self
            .newest_view
            .compare_exchange(request, 0, Ordering::Relaxed, Ordering::Relaxed);
        self.views.cancel(request);
    }

    /// The source of a message for File > Save As, with a name to save it under made from its subject (`.eml`);
    /// None when it is not in the store yet
    pub fn message_source(&self, folder: FolderId, uid: u64) -> Result<Option<(String, Vec<u8>)>> {
        let store = self.store();
        let Some(source) = store.source(folder, uid)? else {
            return Ok(None);
        };
        let subject = store.message(folder, uid)?.map(|m| m.info.subject).unwrap_or_default();
        Ok(Some((export::eml_name(&subject), source)))
    }

    /// The whole source of a message for View Source, as text safe to show, and the title of its window; None when it
    /// is not in the store yet ([`Core::open_message`] fetches it)
    pub fn message_source_text(&self, folder: FolderId, uid: u64) -> Result<Option<(String, String)>> {
        let (source, size, subject) = {
            let store = self.store();
            // as much as is shown, and a byte to tell that there is more
            let Some(source) = store.source_start(folder, uid, view::MAX_SOURCE_TEXT + 1)? else {
                return Ok(None);
            };
            let info = store.message(folder, uid)?.map(|m| m.info);
            let size = info.as_ref().and_then(|i| i.size).map_or(source.len(), |s| s as usize);
            (source, size, info.map(|i| i.subject).unwrap_or_default())
        };
        let title = if subject.trim().is_empty() {
            tr(Text::MessageSourceUntitled)
        } else {
            tr_args(
                Text::MessageSourceTitle,
                &[("subject", view::header_text(subject.as_bytes()).trim_end().into())],
            )
        };
        Ok(Some((title, view::source_text(&source, size))))
    }

    /// The header block of a message for Message Properties, as text safe to show; None when it is not in the store yet
    pub fn message_headers(&self, folder: FolderId, uid: u64) -> Result<Option<String>> {
        let start = self.store().source_start(folder, uid, view::MAX_HEADER_TEXT)?;
        Ok(start.map(|source| view::header_text(&source)))
    }

    /// Puts a message saved as a file (`.eml`) into a folder: on the server in the background, then
    /// [`Event::FolderChanged`]. A file that is not a message, or is too large, is refused now.
    /// Puts the message files of `paths` into `folder` as [`Core::import_message`] does each, those that are not
    /// message files ([`is_message_file`]) left out. Returns what the status bar says ("Put 3 messages in Archive"), and
    /// what to tell the user about those that did not go in ("These were not put in the folder: ..."), None when all
    /// did. For a drop of files onto a folder or Import.
    pub fn import_files(&self, folder: FolderId, paths: &[PathBuf]) -> Result<(String, Option<String>)> {
        let name = text::folder_name(&self.store().folder(folder)?.info);
        let mut problems = Vec::new();
        let mut put = 0;
        for path in paths {
            let outcome = if is_message_file(path) {
                self.import_message(folder, path)
            } else {
                Err(Error::Unavailable(tr_args(
                    Text::ErrorImportNotMail,
                    &[("path", (&path.display().to_string()).into())],
                )))
            };
            match outcome {
                Ok(()) => put += 1,
                Err(error) => problems.push(error.to_string()),
            }
        }
        let said = tr_args(
            Text::ImportPut,
            &[
                ("messages", (&text::messages(put)).into()),
                ("count", put.into()),
                ("folder", (&name).into()),
            ],
        );
        let report =
            (!problems.is_empty()).then(|| tr_args(Text::ImportNotPut, &[("problems", (&problems.join("\n")).into())]));
        Ok((said, report))
    }

    pub fn import_message(&self, folder: FolderId, path: &std::path::Path) -> Result<()> {
        let account = self.store().folder(folder)?.account_id;
        let (raw, date) = read_message_file(path)?;
        self.send_command(account, Command::Append { folder, raw, date })
    }

    /// The content of the `index`th attachment of [`MessageView::attachments`], with the name to
    /// save it under
    pub fn attachment(&self, folder: FolderId, uid: u64, index: usize) -> Result<Option<(String, Vec<u8>)>> {
        let source = self.store().source(folder, uid)?;
        Ok(source.and_then(|source| view::attachment(&source, index)))
    }

    /// The `index`th listed attachment of a message with its name to save it under and its type, from one parse; None
    /// when the message is not in the store yet or has no such attachment
    pub fn attachment_with_type(
        &self,
        folder: FolderId,
        uid: u64,
        index: usize,
    ) -> Result<Option<(String, String, Vec<u8>)>> {
        let source = self.store().source(folder, uid)?;
        Ok(source.and_then(|source| view::attachment_with_type(&source, index)))
    }

    /// Saves every attachment of a message into `dir` (a folder the user chose), each under its safe name; a file of
    /// that name there is kept and the new one numbered. How many were saved; None when the message is not here yet.
    pub fn save_attachments(&self, folder: FolderId, uid: u64, dir: &Path) -> Result<Option<(usize, usize)>> {
        let source = self.store().source(folder, uid)?;
        Ok(source.map(|source| save_all(&source, dir)))
    }

    /// [`Core::attachment`] of a message file a window shows (`file_view`)
    pub fn file_attachment(&self, path: &Path, index: usize) -> Result<Option<(String, Vec<u8>)>> {
        let (source, _) = read_message_file(path)?;
        Ok(view::attachment(&source, index))
    }

    /// [`Core::save_attachments`] of a message file
    pub fn file_save_attachments(&self, path: &Path, dir: &Path) -> Result<(usize, usize)> {
        let (source, _) = read_message_file(path)?;
        Ok(save_all(&source, dir))
    }

    /// The calendar part of a message written to `dir` as `invitation.ics` (a number added when that is taken), for
    /// the calendar program to open; its path, None when the message has none or is not downloaded yet
    pub fn invitation_file(&self, folder: FolderId, uid: u64, dir: &Path) -> Result<Option<PathBuf>> {
        match self.store().source(folder, uid)? {
            Some(source) => write_invitation(&source, dir),
            None => Ok(None),
        }
    }

    /// [`Core::invitation_file`] of a message file a window shows (`file_view`)
    pub fn file_invitation_file(&self, path: &Path, dir: &Path) -> Result<Option<PathBuf>> {
        let (source, _) = read_message_file(path)?;
        write_invitation(&source, dir)
    }

    /// Sends a message from an account in the background, through the Outbox: [`Event::MessageSent`] follows, or
    /// [`Event::Failed`] with the message left waiting in the Outbox for the next Send/Recv. Recipients that are no
    /// addresses and attachments that are not there fail right away.
    pub fn send(&self, account: AccountId, outgoing: Outgoing) -> Result<()> {
        // a typo in an address is told now, while the message is still open in its window
        compose::check(&outgoing).map_err(Error::Compose)?;
        self.send_command(
            account,
            Command::Send {
                outgoing: Box::new(outgoing),
                not_before: None,
            },
        )
    }

    /// Saves a message being written in the Drafts folder of the account, in place of the copy saved before (the one
    /// with `outgoing.message_id`), in the background; [`Event::Failed`] when it did not work. The Message-ID of the
    /// draft, to pass in `outgoing` from then on, so the next save replaces this one and sending removes it.
    pub fn save_draft(&self, account: AccountId, outgoing: Outgoing) -> Result<String> {
        self.save_draft_as(account, outgoing, false)
    }

    /// [`Core::save_draft`] while the user writes, without being asked ([`compose::autosave_wait`] says when): the
    /// same, but a copy that could not be saved is told only to the window ([`Event::DraftSaved`]), not as a failure
    pub fn autosave_draft(&self, account: AccountId, outgoing: Outgoing) -> Result<String> {
        self.save_draft_as(account, outgoing, true)
    }

    fn save_draft_as(&self, account: AccountId, mut outgoing: Outgoing, automatic: bool) -> Result<String> {
        let settings = self.store().account(account)?.settings;
        let email = settings.email.clone();
        if compose::drafts_folder(&self.store(), account)?.is_none() {
            return Err(Error::Unavailable(tr(Text::ErrorNoDrafts)));
        }
        // an ID that does not tell this draft apart is replaced: the copy saved under it stays
        let message_id = outgoing
            .message_id
            .as_deref()
            .and_then(compose::draft_id)
            .unwrap_or_else(|| pe_smtp::message::new_message_id(&email));
        outgoing.message_id = Some(message_id.clone());
        // kept here first, so that it is there to open again after a crash, with or without a connection
        self.keep_recovery(account, &settings, &outgoing, &message_id)?;
        self.send_command(
            account,
            Command::SaveDraft {
                outgoing: Box::new(outgoing),
                automatic,
            },
        )?;
        Ok(message_id)
    }

    /// The message being written kept in the store as it is saved now, without its files, which it names
    fn keep_recovery(
        &self,
        account: AccountId,
        settings: &pe_store::AccountSettings,
        outgoing: &Outgoing,
        message_id: &str,
    ) -> Result<()> {
        let now = worker::unix_now();
        let bare = Outgoing {
            attachments: Vec::new(),
            ..outgoing.clone()
        };
        let message = compose::draft_message(settings, &bare, now).map_err(Error::Compose)?;
        self.store().keep_recovery(&pe_store::Recovery {
            message_id: message_id.to_string(),
            account_id: account,
            source: pe_smtp::build(&message).raw,
            attachments: outgoing.attachments.clone(),
            saved: now,
        })?;
        Ok(())
    }

    /// The window of the message with this draft Message-ID closed (sent, saved, or not kept): its copy kept for a
    /// crash goes
    pub fn compose_closed(&self, message_id: &str) -> Result<()> {
        Ok(self.store().drop_recovery(message_id)?)
    }

    /// The messages that were being written when Inbox Classic last ended without closing their windows, oldest
    /// first, each with its account, to open again: as saved drafts are reopened ([`Core::reopen_draft`]), with the
    /// files they had that are still there
    pub fn recovered(&self) -> Result<Vec<(AccountId, Draft)>> {
        let recoveries = self.store().recoveries()?;
        let mut drafts = Vec::new();
        for recovery in recoveries {
            let (mut draft, _) = compose::reopen(&recovery.source);
            draft.message_id = Some(recovery.message_id);
            draft.attachments = recovery.attachments.into_iter().filter(|path| path.is_file()).collect();
            drafts.push((recovery.account_id, draft));
        }
        Ok(drafts)
    }

    /// Removes the draft with this Message-ID from the Drafts of `account`, in the background: a copy only the
    /// automatic saving made, of a message closed without saving ([`Event::Failed`] when that does not work). Its
    /// copy kept for a crash goes too.
    pub fn discard_draft(&self, account: AccountId, message_id: &str) -> Result<()> {
        self.store().drop_recovery(message_id)?;
        let Some(message_id) = compose::draft_id(message_id) else {
            return Ok(());
        };
        self.send_command(account, Command::RemoveDraft { message_id })
    }

    /// A saved draft (a message of the Drafts folder whose source is in the store) to go on writing; its attachments
    /// are written out to a folder of their own under the system's temporary folder, to be attached again
    pub fn reopen_draft(&self, folder: FolderId, uid: u64) -> Result<Option<Draft>> {
        let Some(source) = self.store().source(folder, uid)? else {
            return Ok(None);
        };
        let (mut draft, files) = compose::reopen(&source);
        if !files.is_empty() {
            draft.attachments = write_out(&format!("draft-{folder}-{uid}"), files).map_err(|error| {
                Error::Unavailable(tr_args(
                    Text::ErrorDraftAttachment,
                    &[("error", (&error.to_string()).into())],
                ))
            })?;
        }
        Ok(Some(draft))
    }

    /// The messages waiting in the Outbox, of every account, oldest first
    pub fn outbox(&self) -> Result<Vec<pe_store::Queued>> {
        let now = worker::unix_now();
        let mut queued = self.store().outbox(None)?;
        // a time that came is no longer waited for: the message goes with the next try, as any other
        for message in &mut queued {
            message.not_before = message.not_before.filter(|&at| at > now);
        }
        Ok(queued)
    }

    /// Takes a message out of the Outbox without sending it
    pub fn outbox_delete(&self, id: i64) -> Result<()> {
        let account = {
            let store = self.store();
            let queued = store.queued(id)?.ok_or(Error::NotFound)?;
            store.unqueue(id)?;
            queued.account_id
        };
        self.post(Event::OutboxChanged { account })
    }

    /// Sends what waits in the Outbox now, for each account that has something there
    pub fn outbox_send(&self) -> Result<()> {
        let accounts = self.store().outbox_accounts()?;
        for account in accounts {
            // the user's Send All Now sends what an agent's message waits for too
            self.store().clear_not_before(account, i64::MAX)?;
            self.send_command(account, Command::SendOutbox)?;
        }
        Ok(())
    }

    /// A reply, a reply to all or a forward of a message whose source is in the store; a forward with the message's
    /// files, written out as a reopened draft's are ([`Core::reopen_draft`]), to be attached
    pub fn draft(&self, folder: FolderId, uid: u64, kind: DraftKind) -> Result<Option<Draft>> {
        let (source, email, date) = {
            let store = self.store();
            let account = store.account(store.folder(folder)?.account_id)?;
            let date = store.message(folder, uid)?.and_then(|m| m.info.display_date());
            (store.source(folder, uid)?, account.settings.email, date)
        };
        let Some(source) = source else {
            return Ok(None);
        };
        let mut draft = compose::draft(&source, kind, &email, date);
        if kind == DraftKind::Forward {
            let files = compose::forwarded_files(&source);
            if !files.is_empty() {
                draft.attachments = write_out(&format!("forward-{folder}-{uid}"), files).map_err(|error| {
                    Error::Unavailable(tr_args(
                        Text::ErrorDraftAttachment,
                        &[("error", (&error.to_string()).into())],
                    ))
                })?;
            }
        }
        Ok(Some(draft))
    }

    /// A message file opened from Finder or File Explorer (or the command line), for a message window: its view, as
    /// a message of no folder (no account's provider vouches for it, so no trusted sender's pictures load; only the
    /// user's click, or Options' setting, loads them)
    pub fn file_view(&self, path: &std::path::Path, allow_remote_images: bool) -> Result<MessageView> {
        let (source, _) = read_message_file(path)?;
        let always = self.store().always_load_pictures()?;
        let trust = view::Trust {
            pictures: pictures::Rules {
                always,
                ..Default::default()
            },
            ..Default::default()
        };
        Ok(view::build_unless(&source, allow_remote_images, &trust, &|| false, &|_| None).unwrap_or_default())
    }

    /// Reply, Reply All or Forward to a message file, from `account`
    pub fn file_draft(&self, path: &std::path::Path, account: AccountId, kind: DraftKind) -> Result<Draft> {
        let (source, date) = read_message_file(path)?;
        let email = self.store().account(account)?.settings.email;
        let mut draft = compose::draft(&source, kind, &email, date);
        if kind == DraftKind::Forward {
            let files = compose::forwarded_files(&source);
            if !files.is_empty() {
                draft.attachments = write_out("forward-file", files).map_err(|error| {
                    Error::Unavailable(tr_args(
                        Text::ErrorDraftAttachment,
                        &[("error", (&error.to_string()).into())],
                    ))
                })?;
            }
        }
        Ok(draft)
    }

    /// Marks a message read or unread: in the store now, on the server in the background
    pub fn set_seen(&self, folder: FolderId, uid: u64, seen: bool) -> Result<()> {
        self.set_flag(folder, uid, "\\Seen", seen)
    }

    fn set_flag(&self, folder: FolderId, uid: u64, flag: &'static str, on: bool) -> Result<()> {
        self.set_flag_many(folder, &[uid], flag, on)
    }

    /// Marks every message of a folder read: in the store now, on the server in the background
    pub fn mark_all_read(&self, folder: FolderId) -> Result<()> {
        let (account, uids) = {
            let store = self.store();
            (store.folder(folder)?.account_id, store.mark_all_seen(folder)?)
        };
        if uids.is_empty() {
            return Ok(());
        }
        self.post(Event::FolderChanged { account, folder })?;
        self.send_command(
            account,
            Command::SetFlag {
                folder,
                uids,
                flag: "\\Seen",
                on: true,
            },
        )
    }

    /// Marks every message of every folder of an account read, as [`Core::mark_all_read`] marks one folder
    pub fn mark_account_read(&self, account: AccountId) -> Result<()> {
        let folders = self.store().folders(account)?;
        for folder in folders.iter().filter(|f| f.unread > 0) {
            self.mark_all_read(folder.id)?;
        }
        Ok(())
    }

    /// Marks every message of every account's Inbox read, as [`Core::mark_all_read`] marks one folder
    pub fn mark_all_inboxes_read(&self) -> Result<()> {
        let inboxes = self.store().inboxes()?;
        for inbox in inboxes {
            self.mark_all_read(inbox)?;
        }
        Ok(())
    }

    /// Moves messages to another folder of their account with one command, as a move of one would.
    /// Refused when one of them is not there, and then none moves.
    pub fn move_messages(&self, folder: FolderId, uids: &[u64], to: FolderId) -> Result<()> {
        let account = self.target_of(folder, to)?;
        if uids.is_empty() {
            return Ok(());
        }
        let removed = self.store().transaction(|store| {
            let removed = uids
                .iter()
                .map(|&uid| {
                    store
                        .message(folder, uid)?
                        .map(|m| m.info)
                        .ok_or(pe_store::Error::QueryReturnedNoRows)
                })
                .collect::<pe_store::Result<Vec<_>>>()?;
            // their sources go with them (worker.rs, Command::Move)
            store.remove_moving_messages(folder, uids)?;
            Ok(removed)
        });
        let removed = removed.map_err(|error| match error {
            pe_store::Error::QueryReturnedNoRows => Error::NotFound,
            other => Error::Store(other),
        })?;
        self.post(Event::FolderChanged { account, folder })?;
        self.send_command(
            account,
            Command::Move {
                folder,
                uids: uids.to_vec(),
                to,
                removed,
            },
        )
    }

    /// Deletes messages as [`Core::delete_message`] deletes one, into Deleted Items only: refused where that would
    /// delete them for good (in Deleted Items, or an account without one)
    pub fn trash_messages(&self, folder: FolderId, uids: &[u64]) -> Result<FolderId> {
        let trash = self.trash_for(folder)?.ok_or(Error::NotFound)?;
        self.move_messages(folder, uids, trash)?;
        Ok(trash)
    }

    /// Sets or clears a flag on messages of a folder: in the store now, on the server in the background with one
    /// command for all of them
    pub fn set_flag_many(&self, folder: FolderId, uids: &[u64], flag: &'static str, on: bool) -> Result<()> {
        let (account, changed) = {
            let store = self.store();
            let account = store.folder(folder)?.account_id;
            let changed = store
                .set_flag_many(folder, uids, flag, on)
                .map_err(|error| match error {
                    pe_store::Error::QueryReturnedNoRows => Error::NotFound,
                    other => Error::Store(other),
                })?;
            (account, changed)
        };
        if changed.is_empty() {
            return Ok(());
        }
        self.post(Event::FolderChanged { account, folder })?;
        self.send_command(
            account,
            Command::SetFlag {
                folder,
                uids: changed,
                flag,
                on,
            },
        )
    }

    /// Adds flags to messages of a folder and takes others away: in the store now in one go, on the server in the
    /// background with at most one command each (a flag and its colour change together)
    pub fn change_flags_many(
        &self,
        folder: FolderId,
        uids: &[u64],
        add: &[&'static str],
        remove: &[&'static str],
    ) -> Result<()> {
        let (account, changed) = {
            let store = self.store();
            let account = store.folder(folder)?.account_id;
            let changed = store
                .change_flags_many(folder, uids, add, remove)
                .map_err(|error| match error {
                    pe_store::Error::QueryReturnedNoRows => Error::NotFound,
                    other => Error::Store(other),
                })?;
            (account, changed)
        };
        if changed.is_empty() {
            return Ok(());
        }
        self.post(Event::FolderChanged { account, folder })?;
        self.send_command(
            account,
            Command::SetFlags {
                folder,
                uids: changed,
                add: add.to_vec(),
                remove: remove.to_vec(),
            },
        )
    }

    /// Marks messages of a folder junk (RFC 9051 `$Junk`, `$NotJunk` taken away) and moves it to the account's Junk folder, or
    /// not junk (`$NotJunk`) and moves it to the Inbox: in the store now, on the server in the background. Refused
    /// when the account has no such folder. One command for each step, whatever the number of messages.
    pub fn mark_junk_many(&self, folder: FolderId, uids: &[u64], junk: bool) -> Result<()> {
        let target = self.junk_target(folder, junk)?;
        let (on, off) = junk_keywords(junk);
        // the flags first, which the server keeps on the messages as they move; the move says the folder changed
        self.set_flag_many(folder, uids, on, true)?;
        self.set_flag_many(folder, uids, off, false)?;
        if target != folder {
            self.move_messages(folder, uids, target)?;
        }
        Ok(())
    }

    /// Copies messages of a folder into another folder of their account with one command, as a copy of one would. Refused when one of them is not there.
    pub fn copy_messages(&self, folder: FolderId, uids: &[u64], to: FolderId) -> Result<()> {
        let account = self.target_of(folder, to)?;
        if uids.is_empty() {
            return Ok(());
        }
        {
            let store = self.store();
            for &uid in uids {
                store.message(folder, uid)?.ok_or(Error::NotFound)?;
            }
        }
        self.send_command(
            account,
            Command::Copy {
                folder,
                uids: uids.to_vec(),
                to,
            },
        )
    }

    /// The account of `folder` when a message of it can go to `to`: another folder of that account, one that holds
    /// messages
    fn target_of(&self, folder: FolderId, to: FolderId) -> Result<AccountId> {
        let store = self.store();
        let target = store.folder(to)?;
        let account = store.folder(folder)?.account_id;
        if target.account_id != account || !target.info.selectable || to == folder {
            return Err(Error::NotFound);
        }
        Ok(account)
    }

    /// Deletes messages of a folder as Outlook Express does: into Deleted Items (the account's `\\Trash`), or for good when it
    /// is in there already or the account has none ([`Core::deletes_for_good`]). Out of the store now, on the server
    /// in the background, with one command.
    pub fn delete_messages(&self, folder: FolderId, uids: &[u64]) -> Result<()> {
        match self.trash_for(folder)? {
            Some(trash) => self.move_messages(folder, uids, trash),
            None => self.remove_then(folder, uids, |removed| Command::Expunge {
                folder,
                uids: uids.to_vec(),
                removed,
            }),
        }
    }

    /// Whether messages of `folder` can be archived (see [`archivable`])
    pub fn can_archive(&self, folder: FolderId) -> Result<bool> {
        Ok(archivable(&self.store().folder(folder)?.info))
    }

    /// Archives messages: out of the list now, into the account's Archive folder on the server (made when it has
    /// none), or on Gmail with every label taken off (left in All Mail), in the background. Refused where
    /// [`Core::can_archive`] says no.
    pub fn archive_messages(&self, folder: FolderId, uids: &[u64]) -> Result<()> {
        if !self.can_archive(folder)? {
            return Err(Error::Unavailable(tr(Text::NotArchivedHere)));
        }
        self.remove_then(folder, uids, |removed| Command::Archive {
            folder,
            uids: uids.to_vec(),
            removed,
        })
    }

    /// Whether `folder` can be emptied (see [`emptiable`])
    pub fn can_empty(&self, folder: FolderId) -> Result<bool> {
        Ok(emptiable(&self.store().folder(folder)?.info))
    }

    /// What to ask before emptying `folder`: "Empty Deleted Items?", a blank line, and that its 12 messages go for
    /// good; None when it can not be emptied or has nothing in it
    pub fn empty_folder_question(&self, folder: FolderId) -> Result<Option<String>> {
        let found = self.store().folder(folder)?;
        if !emptiable(&found.info) || found.total == 0 {
            return Ok(None);
        }
        let name = crate::text::folder_name(&found.info);
        Ok(Some(tr_args(
            Text::EmptyQuestion,
            &[
                ("messages", (&crate::text::messages(found.total)).into()),
                ("count", found.total.into()),
                ("folder", (&name).into()),
            ],
        )))
    }

    /// Empties Deleted Items or Junk E-mail: every message of it deleted for good, out of the list now (one change for
    /// the windows) and on the server in the background, a command per 1000 (only these messages: one that arrives
    /// meanwhile stays). Edit > Undo can not take it back, and what it could take back before is forgotten. Returns
    /// what the status bar says.
    pub fn empty_folder(&self, folder: FolderId) -> Result<String> {
        let (account, uids, removed) = {
            let store = self.store();
            let found = store.folder(folder)?;
            if !emptiable(&found.info) {
                return Err(Error::Unavailable(tr(Text::NotEmptiedHere)));
            }
            let uids = store.uids(folder)?;
            let removed = uids
                .iter()
                .map(|&uid| Ok(store.message(folder, uid)?.ok_or(Error::NotFound)?.info))
                .collect::<Result<Vec<_>>>()?;
            store.remove_messages(folder, &uids)?;
            (found.account_id, uids, removed)
        };
        let count = uids.len() as u64;
        if count > 0 {
            self.post(Event::FolderChanged { account, folder })?;
        }
        for (chunk, gone) in uids.chunks(1000).zip(removed.chunks(1000)) {
            self.send_command(
                account,
                Command::Expunge {
                    folder,
                    uids: chunk.to_vec(),
                    removed: gone.to_vec(),
                },
            )?;
        }
        *self.undo.lock().unwrap_or_else(|e| e.into_inner()) = None;
        Ok(tr_args(
            Text::DoneDeletedForGood,
            &[
                ("messages", (&crate::text::messages(count)).into()),
                ("count", count.into()),
            ],
        ))
    }

    /// Whether deleting from `folder` removes a message for good: it is Deleted Items, or the account has none
    pub fn deletes_for_good(&self, folder: FolderId) -> Result<bool> {
        Ok(self.trash_for(folder)?.is_none())
    }

    /// The Deleted Items folder a message of `folder` goes to, None when it is that folder or there is none
    fn trash_for(&self, folder: FolderId) -> Result<Option<FolderId>> {
        trash_in(&self.store(), folder)
    }

    /// The folder junk (or not junk) goes to from `folder`: the account's Junk folder, or its Inbox. Refused, saying
    /// so, when the account has none.
    pub(crate) fn junk_target(&self, folder: FolderId, junk: bool) -> Result<FolderId> {
        let store = self.store();
        let account = store.folder(folder)?.account_id;
        let target = if junk {
            store.special_folder(account, "\\Junk")?
        } else {
            store.find_folder(account, "INBOX")?
        };
        let missing = if junk { Text::NoJunkFolder } else { Text::NoInboxFolder };
        target.map(|f| f.id).ok_or_else(|| Error::Unavailable(tr(missing)))
    }

    /// Takes a message out of the store, tells the windows, and hands the server the work `command` makes of the row
    /// (put back when the server does not do it)
    fn remove_then(
        &self,
        folder: FolderId,
        uids: &[u64],
        command: impl FnOnce(Vec<pe_store::MessageInfo>) -> Command,
    ) -> Result<()> {
        if uids.is_empty() {
            return Ok(());
        }
        let (account, removed) = {
            let store = self.store();
            let account = store.folder(folder)?.account_id;
            let removed = uids
                .iter()
                .map(|&uid| Ok(store.message(folder, uid)?.ok_or(Error::NotFound)?.info))
                .collect::<Result<Vec<_>>>()?;
            // their sources kept until the command is done: an archived message keeps its own, a failed command
            // puts them back
            store.remove_moving_messages(folder, uids)?;
            (account, removed)
        };
        self.post(Event::FolderChanged { account, folder })?;
        self.send_command(account, command(removed))
    }

    /// Creates a folder `name` in `parent`, or at the top of the account: on the server in the background, then
    /// [`Event::FoldersChanged`]. A name that can not be one is refused now.
    pub fn create_folder(&self, account: AccountId, parent: Option<FolderId>, name: &str) -> Result<()> {
        let name = {
            let store = self.store();
            if let Some(parent) = parent
                && store.folder(parent)?.account_id != account
            {
                return Err(Error::NotFound);
            }
            pe_sync::folder_name(&store, account, name)?.map_err(Error::Folder)?
        };
        // the path waits for the connection: at the top it goes under the server's namespace
        self.send_command(account, Command::CreateFolder { parent, name })
    }

    /// Renames a folder (its subfolders go along): on the server in the background, then [`Event::FoldersChanged`].
    /// The Inbox and the special folders are not renamed.
    pub fn rename_folder(&self, folder: FolderId, name: &str) -> Result<()> {
        let (account, path) = {
            let store = self.store();
            let account = store.folder(folder)?.account_id;
            (
                account,
                pe_sync::renamed_path(&store, folder, name)?.map_err(Error::Folder)?,
            )
        };
        self.send_command(account, Command::RenameFolder { folder, path })
    }

    /// Deletes a folder and the messages in it: on the server in the background, then [`Event::FoldersChanged`]. The
    /// Inbox and the special folders are not deleted.
    pub fn delete_folder(&self, folder: FolderId) -> Result<()> {
        let account = {
            let store = self.store();
            let found = store.folder(folder)?;
            if pe_sync::is_special(&found.info) {
                return Err(Error::Folder(pe_sync::FolderRefusal::Special));
            }
            found.account_id
        };
        self.send_command(account, Command::DeleteFolder { folder })
    }

    /// What the workers share with the core
    fn worker_context(&self) -> worker::Context {
        worker::Context {
            path: self.path.clone(),
            secrets: self.secrets.clone(),
            trust: self.trust.clone(),
            oauth: self.oauth.clone(),
            tokens: self.tokens.clone(),
            events: self.events.clone(),
            timings: self.timings.clone(),
            wake: self.wake.subscribe(),
            synced: self.synced.clone(),
            nudges: self.nudges.clone(),
            opened: self.opened.clone(),
            opening: self.opening.clone(),
            partials: self.partials.clone(),
        }
    }

    fn send_command(&self, account: AccountId, command: Command) -> Result<()> {
        self.send_to(Kind::Main, account, command)
    }

    /// The workers of a kind
    fn workers_of(&self, kind: Kind) -> &Workers {
        match kind {
            Kind::Main => &self.workers,
            Kind::Reader => &self.readers,
            Kind::Spare => &self.spares,
            Kind::Background => &self.backgrounds,
        }
    }

    /// Hands `command` to the worker of `account` of `kind`, started when there is none or it stopped
    fn send_to(&self, kind: Kind, account: AccountId, command: Command) -> Result<()> {
        match self.worker_of(kind, account)?.send(command) {
            Ok(()) => Ok(()),
            // it stopped meanwhile: a new one takes the command
            Err(returned) => self
                .worker_of(kind, account)?
                .send(returned.0)
                .map_err(|_| Error::Closed),
        }
    }

    /// Where the commands of the worker of `account` of `kind` go, the worker started when there is none or it
    /// stopped. A reader gets the main worker to hand opens to when the server refuses it a connection.
    fn worker_of(&self, kind: Kind, account: AccountId) -> Result<UnboundedSender<Command>> {
        /// The worker's sender, while it runs
        fn live(
            workers: &HashMap<AccountId, (UnboundedSender<Command>, tokio::task::AbortHandle)>,
            account: AccountId,
        ) -> Option<UnboundedSender<Command>> {
            workers
                .get(&account)
                .map(|(sender, _)| sender.clone())
                .filter(|sender| !sender.is_closed())
        }
        let workers = self.workers_of(kind);
        if let Some(sender) = live(&workers.lock().unwrap_or_else(|p| p.into_inner()), account) {
            return Ok(sender);
        }
        self.store().account(account).map_err(|_| Error::NotFound)?;
        // taken before this kind's lock, as it takes the main workers'
        let fallback = match kind {
            Kind::Main => None,
            Kind::Reader | Kind::Spare | Kind::Background => Some(self.worker_of(Kind::Main, account)?),
        };
        let mut workers = workers.lock().unwrap_or_else(|p| p.into_inner());
        if let Some(sender) = live(&workers, account) {
            return Ok(sender);
        }
        let (sender, receiver) = unbounded_channel();
        let mut worker = Worker::new(account, kind.role(), self.worker_context());
        // the main worker's own commands, for what its uploader sends back
        if kind == Kind::Main {
            worker.main = Some(sender.downgrade());
        }
        worker.fallback = fallback;
        worker.spare = kind == Kind::Spare;
        let task = self.runtime()?.spawn(worker.run(receiver));
        workers.insert(account, (sender.clone(), task.abort_handle()));
        Ok(sender)
    }

    /// The workers of every kind
    fn all_workers(&self) -> [&Workers; 4] {
        [&self.workers, &self.readers, &self.backgrounds, &self.spares]
    }

    fn stop_worker(&self, account: AccountId) {
        // dropping the sender ends the worker once its current command is done; the reader too, and the token goes,
        // as the settings it was for changed
        for workers in self.all_workers() {
            workers.lock().unwrap_or_else(|p| p.into_inner()).remove(&account);
        }
        self.tokens.lock().unwrap_or_else(|p| p.into_inner()).remove(&account);
    }
}

/// Whether `path` names a message file the app takes when files are dropped on a folder: an `.eml` (what it is in it
/// is checked when it is put in)
pub fn is_message_file(path: &std::path::Path) -> bool {
    path.extension().is_some_and(|x| x.eq_ignore_ascii_case("eml"))
}

/// The Deleted Items folder a message of `folder` goes to in `store`, None when it is that folder or there is none
pub(crate) fn trash_in(store: &Store, folder: FolderId) -> Result<Option<FolderId>> {
    let account = store.folder(folder)?.account_id;
    Ok(store
        .special_folder(account, "\\Trash")?
        .map(|trash| trash.id)
        .filter(|&trash| trash != folder))
}

/// Whether a folder can be emptied: Deleted Items or Junk E-mail, the folders whose messages are on their way out
pub fn emptiable(folder: &pe_store::FolderInfo) -> bool {
    use pe_imap::SpecialUse;
    matches!(
        folder.special_use.as_deref().and_then(SpecialUse::from_flag),
        Some(SpecialUse::Trash | SpecialUse::Junk)
    )
}

/// Whether messages of a folder can be archived: from the Inbox and the user's own folders, not from the special ones
/// (Archive, All Mail, Sent, Drafts, Junk, Deleted Items), where they are filed already or go elsewhere
pub(crate) fn archivable(folder: &pe_store::FolderInfo) -> bool {
    use pe_imap::SpecialUse;
    folder.selectable
        && matches!(
            folder.special_use.as_deref().and_then(SpecialUse::from_flag),
            None | Some(SpecialUse::Inbox)
        )
}

/// The keyword junk sets and the one it takes away, `$Junk` and `$NotJunk` (RFC 9051), the other way round for not junk
pub(crate) fn junk_keywords(junk: bool) -> (&'static str, &'static str) {
    if junk {
        ("$Junk", "$NotJunk")
    } else {
        ("$NotJunk", "$Junk")
    }
}

/// Writes files (name, content) into a new folder of this user's own (`name` and a number that makes it new), each in
/// a folder of its own there so two of one name stay apart; their paths. Under the runtime folder on Linux (the system's
/// temporary folder there is shared by every user), under the temporary folder elsewhere (the Mac's and Windows' are
/// each user's own); readable by this user only.
fn write_out(name: &str, files: Vec<(String, Vec<u8>)>) -> std::io::Result<Vec<PathBuf>> {
    let base = private_dir(name)?;
    files
        .into_iter()
        .enumerate()
        .map(|(index, (file, content))| {
            let dir = base.join(index.to_string());
            new_dir(&dir)?;
            let path = dir.join(file);
            std::fs::write(&path, content)?;
            Ok(path)
        })
        .collect()
}

/// A new folder of this user's own for files the app writes out, `name` with a number that makes it new
pub(crate) fn private_dir(name: &str) -> std::io::Result<PathBuf> {
    let parent = private_root().join("InboxClassic");
    match new_dir(&parent) {
        Err(error) if error.kind() == std::io::ErrorKind::AlreadyExists => {}
        other => other?,
    }
    // a link to elsewhere is not followed
    if !std::fs::symlink_metadata(&parent)?.is_dir() {
        return Err(std::io::Error::other(format!("{} is not a folder", parent.display())));
    }
    for _ in 0..100 {
        let nanos = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map_or(0, |d| d.as_nanos());
        let dir = parent.join(format!("{name}-{nanos}"));
        match new_dir(&dir) {
            Ok(()) => {
                // a parent another user made first (and left open to others) is not used: the folder made in it
                // is this user's, so their owners differ
                if !same_owner(&parent, &dir)? {
                    let _ = std::fs::remove_dir(&dir);
                    return Err(std::io::Error::other(format!("{} is another user's", parent.display())));
                }
                return Ok(dir);
            }
            Err(error) if error.kind() == std::io::ErrorKind::AlreadyExists => continue,
            Err(error) => return Err(error),
        }
    }
    Err(std::io::Error::other("no new folder could be made"))
}

#[cfg(unix)]
fn same_owner(a: &std::path::Path, b: &std::path::Path) -> std::io::Result<bool> {
    use std::os::unix::fs::MetadataExt;
    Ok(std::fs::symlink_metadata(a)?.uid() == std::fs::symlink_metadata(b)?.uid())
}

#[cfg(not(unix))]
fn same_owner(_a: &std::path::Path, _b: &std::path::Path) -> std::io::Result<bool> {
    Ok(true)
}

/// Where the folders of [`private_dir`] are: the runtime folder on Linux (its temporary folder is shared by every user),
/// the temporary folder elsewhere (each user's own on the Mac and Windows)
fn private_root() -> PathBuf {
    if cfg!(all(unix, not(target_os = "macos"))) {
        std::env::var_os("XDG_RUNTIME_DIR")
            .map(PathBuf::from)
            .filter(|dir| dir.is_absolute())
            .unwrap_or_else(std::env::temp_dir)
    } else {
        std::env::temp_dir()
    }
}

/// Removes what [`private_dir`] folders earlier runs left (drafts' and forwards' attachments, dragged files), those a
/// day old: one written by another core running now (another profile, a test) is left alone
fn clear_private_dirs() {
    const AGE: std::time::Duration = std::time::Duration::from_secs(24 * 60 * 60);
    let parent = private_root().join("InboxClassic");
    // only a folder of this user's: not a link, and the folders in it removed one by one
    if std::fs::symlink_metadata(&parent).is_ok_and(|m| m.is_dir())
        && let Ok(entries) = std::fs::read_dir(&parent)
    {
        for entry in entries.flatten() {
            let old = entry
                .metadata()
                .and_then(|m| m.modified())
                .ok()
                .and_then(|at| at.elapsed().ok())
                .is_some_and(|age| age > AGE);
            if old && entry.file_type().is_ok_and(|t| t.is_dir()) {
                let _ = std::fs::remove_dir_all(entry.path());
            }
        }
    }
}

/// Makes a folder, failing when it is there; on Unix readable by this user only
fn new_dir(dir: &std::path::Path) -> std::io::Result<()> {
    #[cfg(unix)]
    let made = std::os::unix::fs::DirBuilderExt::mode(&mut std::fs::DirBuilder::new(), 0o700).create(dir);
    #[cfg(not(unix))]
    let made = std::fs::DirBuilder::new().create(dir);
    made
}

fn store_security(security: pe_net::Security) -> pe_store::Security {
    match security {
        pe_net::Security::Tls => pe_store::Security::Tls,
        pe_net::Security::StartTls => pe_store::Security::StartTls,
        pe_net::Security::Plain => pe_store::Security::Plain,
    }
}

/// What a finished sign-in got: the refresh token of the account it was for
struct SignedIn {
    with: SignInWith,
    provider: pe_oauth::Provider,
    refresh_token: String,
    identity: pe_oauth::Identity,
}

/// How long closing waits for the workers
const SHUTDOWN_GRACE: std::time::Duration = std::time::Duration::from_secs(2);

impl Drop for Core {
    fn drop(&mut self) {
        self.closed.store(true, Ordering::Release);
        for workers in self.all_workers() {
            workers.lock().unwrap_or_else(|p| p.into_inner()).clear();
        }
        if let Some(runtime) = self.runtime.take() {
            // workers that are waiting for the network are cancelled
            runtime.shutdown_timeout(SHUTDOWN_GRACE);
        }
    }
}

/// The logos being downloaded, by their row: rows asking at once share one download
type LogoDownloads = Arc<Mutex<HashMap<i64, Arc<tokio::sync::OnceCell<Option<Vec<u8>>>>>>>;

/// A kept logo: by its row (a row of the list), or by its address (the reading pane's BIMI-Location)
enum KeptLogo {
    Row(i64),
    At(String),
}

/// The kept logos, read and written on a store connection of their own ([`ViewStore`]), off the window thread
#[derive(Clone)]
struct LogoSource {
    path: PathBuf,
    view_store: ViewStore,
    downloads: LogoDownloads,
}

impl LogoSource {
    /// The SVG of a logo: kept and fresh, or downloaded once however many ask at the same time and kept (or its
    /// failure, so it is not tried again for a day); None when there is none to have
    async fn svg(&self, logo: KeptLogo) -> Option<Vec<u8>> {
        let source = self.clone();
        let (id, kept) = tokio::task::spawn_blocking(move || {
            let store = OpenStore::open(&source.view_store, &source.path)?;
            let id = match logo {
                KeptLogo::Row(id) => id,
                KeptLogo::At(url) => store.logo_id(&url).ok()?.0,
            };
            Some((id, store.logo(id).ok()??))
        })
        .await
        .ok()??;
        let now = list_view::now_ms();
        if let Some(svg) = kept.fresh_svg(now) {
            return Some(svg.to_vec());
        }
        if !kept.download_due(now) {
            return None;
        }
        let cell = self
            .downloads
            .lock()
            .unwrap_or_else(|p| p.into_inner())
            .entry(id)
            .or_default()
            .clone();
        let svg = cell
            .get_or_init(|| async {
                let svg = bimi::fetch_svg(&kept.url).await;
                let (fetched, source) = (svg.clone(), self.clone());
                let _ = tokio::task::spawn_blocking(move || {
                    if let Some(store) = OpenStore::open(&source.view_store, &source.path) {
                        let _ = store.set_logo_download(id, fetched.as_deref(), list_view::now_ms());
                    }
                })
                .await;
                svg
            })
            .await
            .clone();
        // the next ask reads the store
        self.downloads.lock().unwrap_or_else(|p| p.into_inner()).remove(&id);
        svg
    }
}

/// The store connection of the views built in the background (a connection of its own, opened only for a bounce, to
/// find the message it returns and mark it), None until one needs it
type ViewStore = Arc<Mutex<Option<Store>>>;

/// [`ViewStore`]'s connection, held while it is used
struct OpenStore<'a>(MutexGuard<'a, Option<Store>>);

impl<'a> OpenStore<'a> {
    /// The connection, opened when it is not yet; None when it can not be
    fn open(store: &'a ViewStore, path: &Path) -> Option<Self> {
        let mut held = store.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
        if held.is_none() {
            *held = Store::open(path).ok();
        }
        held.is_some().then_some(OpenStore(held))
    }
}

impl std::ops::Deref for OpenStore<'_> {
    type Target = Store;

    fn deref(&self) -> &Store {
        self.0.as_ref().expect("opened")
    }
}

/// The source of a message, the date the server got it, whether the list marks it a bounce, the domains whose
/// verdicts its account trusts, and where it is
struct ViewSource {
    source: Arc<Vec<u8>>,
    /// A large message's text shown first, whose attachments have no content: their sizes are its own
    first: Option<Arc<pe_sync::TextFirst>>,
    received: Option<i64>,
    marked: bool,
    trusted: Vec<String>,
    /// The folder may show the card of a one-time code
    codes: bool,
    /// The folder is Junk E-mail, where no pictures load by themselves
    junk: bool,
    always_pictures: bool,
    trusted_senders: Vec<pe_store::TrustedSender>,
    account: AccountId,
    folder: FolderId,
    uid: u64,
}

/// The calendar part of `source` written into `dir` as invitation.ics (numbered when that is taken), its bytes as they
/// came whatever their charset; None for a message without one
fn write_invitation(source: &[u8], dir: &Path) -> Result<Option<PathBuf>> {
    let Ok(message) = pe_mime::parser::parse(source) else {
        return Ok(None);
    };
    let Some(part) = view::calendar_part(&message.attachments) else {
        return Ok(None);
    };
    let written = std::fs::create_dir_all(dir).and_then(|_| view::write_new(dir, "invitation.ics", &part.content));
    written.map(Some).map_err(|error| Error::Unavailable(error.to_string()))
}

/// Every attachment of `source` written into `dir` under its safe name, a file there kept and the new one numbered: how
/// many were saved, of how many
fn save_all(source: &[u8], dir: &Path) -> (usize, usize) {
    let files = view::attachments(source);
    let saved = files
        .iter()
        .filter(|(name, content)| view::write_new(dir, name, content).is_ok())
        .count();
    (saved, files.len())
}

/// A message file (.eml) read whole, up to 50 MB, refused when it is no mail: for Import and for opening a file in a
/// message window; with the date of its Date header
fn read_message_file(path: &std::path::Path) -> Result<(Vec<u8>, Option<i64>)> {
    const LIMIT: u64 = 50 * 1024 * 1024;
    let shown = path.display().to_string();
    let not_one = |text: Text, error: &str| {
        Error::Unavailable(tr_args(text, &[("path", (&shown).into()), ("error", error.into())]))
    };
    // opened once, read up to just past the limit: a file that grows meanwhile is still refused
    let file = std::fs::File::open(path).map_err(|e| not_one(Text::ErrorImportUnreadable, &e.to_string()))?;
    let mut raw = Vec::new();
    std::io::Read::read_to_end(&mut std::io::Read::take(file, LIMIT + 1), &mut raw)
        .map_err(|e| not_one(Text::ErrorImportUnreadable, &e.to_string()))?;
    if raw.len() as u64 > LIMIT {
        return Err(not_one(Text::ErrorImportTooLarge, ""));
    }
    let parsed = pe_mime::parser::parse(&raw).map_err(|_| not_one(Text::ErrorImportNotMail, ""))?;
    // a message has headers a mail program wrote; a text file parsed as one has none of these
    let looks_like_one = parsed.from.is_some() || parsed.message_id.is_some() || parsed.timestamp.is_some();
    if !looks_like_one {
        return Err(not_one(Text::ErrorImportNotMail, ""));
    }
    Ok((raw, parsed.timestamp))
}

/// The view of a message's source, its date the server's when it has no Date header; None when `dropped` said to
/// give up. `store` gives the store a bounce needs: the message it returns is looked up there, and a bounce the list
/// did not mark yet (one found by the heuristics) is marked, with `events` told the folder changed.
fn finish_view<S: std::ops::Deref<Target = Store>>(
    found: &ViewSource,
    allow_remote_images: bool,
    dropped: &dyn Fn() -> bool,
    store: impl Fn() -> Option<S>,
    events: &dyn Fn(Event),
) -> Option<MessageView> {
    let find = |message_id: &str| {
        store()?
            .find_message_id(found.account, message_id)
            .ok()
            .flatten()
            // the bounce itself is not the message it returns
            .filter(|at| (at.folder, at.uid) != (found.folder, found.uid))
    };
    let trust = view::Trust {
        domains: &found.trusted,
        codes: found.codes,
        pictures: pictures::Rules {
            always: found.always_pictures,
            junk: found.junk,
            senders: &found.trusted_senders,
        },
    };
    let mut view = view::build_unless(&found.source, allow_remote_images, &trust, dropped, &find)?;
    // a large message's text first: its attachments without content, their sizes from its structure, listed by the
    // same rules
    if let Some(first) = found
        .first
        .as_ref()
        .filter(|first| first.sizes.len() == view.attachments.len())
    {
        for (attachment, size) in view.attachments.iter_mut().zip(&first.sizes) {
            attachment.size = *size;
        }
    }
    // without a Date header, the date the list shows: when the server got it
    view.date = view.date.or(found.received);
    // without a logo, the contact's picture the list's row has: one decision for both, so they never differ
    if !view.has_logo
        && let Some(row) = store().and_then(|store| store.message(found.folder, found.uid).ok().flatten())
        && let (senders::PictureKind::Contact, key) = senders::picture(&row)
    {
        view.picture = key;
    }
    if view.bounce
        && !found.marked
        && store().is_some_and(|store| store.mark_bounce(found.folder, found.uid).unwrap_or(false))
    {
        events(Event::FolderChanged {
            account: found.account,
            folder: found.folder,
        });
    }
    Some(view)
}

#[cfg(test)]
mod write_out_tests {
    #[test]
    fn files_written_out_in_a_folder_of_this_users_own() {
        let files = vec![
            ("a.eml".to_string(), b"one".to_vec()),
            ("a.eml".to_string(), b"two".to_vec()),
        ];
        let paths = super::write_out("test", files).unwrap();
        assert_eq!(std::fs::read(&paths[0]).unwrap(), b"one");
        assert_eq!(std::fs::read(&paths[1]).unwrap(), b"two");
        assert_ne!(paths[0].parent(), paths[1].parent());
        let dir = paths[0].parent().unwrap().parent().unwrap();
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            assert_eq!(std::fs::metadata(dir).unwrap().permissions().mode() & 0o777, 0o700);
        }
        std::fs::remove_dir_all(dir).unwrap();
    }
}
