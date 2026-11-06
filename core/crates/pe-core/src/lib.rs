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
pub mod calendar;
mod compose;
mod export;
mod fold;
pub mod mailto;
mod requests;
mod search;
mod secrets;
mod selection;
mod sign_in_apps;
mod targets;
mod text;
pub mod unsubscribe;
mod view;
mod worker;

use std::collections::HashMap;
use std::fmt;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, MutexGuard};

use pe_net::Trust;
use pe_store::{Account, AccountId, AccountSettings, Folder, FolderId, Message, Sort, Store};
pub use pe_store::{MessageRef, Scope, Search, Show};
pub use selection::{Action, Summary};
pub use targets::{TargetKind, TargetRow};
use tokio::sync::mpsc::{UnboundedSender, unbounded_channel};

pub use compose::{ComposeError, Draft, DraftKind, Outgoing, address_label};
pub use export::Exported;
/// The rules of the folder tree the windows show: how deep a folder is, and which stay as they are
pub use pe_sync::{is_special as is_fixed_folder, tree_depths};
use requests::Requests;
pub use secrets::PasswordStore;
use secrets::Secrets;
use sign_in_apps::{Discoveries, with_provider};
pub use sign_in_apps::{SecretChange, SignInAppEntry, SignInAppForm, SignInWith, builtin_name, builtin_off_reason};
pub use text::{
    HiddenUnread, RETRY_NOTE, ReaderState, account_label, account_title, downloading_text, folder_kind, folder_name,
    format_size, hidden_unread, list_counts, messages, reader_page, saved_text,
};
pub use view::{AttachmentView, MessageView};
use worker::{Command, Role, Worker};

/// The version of the core, which the About boxes show
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

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
    /// The source of a message is in the store, [`Core::message_view`] can show it
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
    /// The one-click unsubscribe `request` ([`Core::unsubscribe`]) is done, or failed for `problem`
    Unsubscribed {
        request: u64,
        problem: Option<String>,
    },
    /// New unread mail came in the Inbox of `account` (`count` messages), `uid` the newest, from `from` about
    /// `subject`
    NewMail {
        account: AccountId,
        folder: FolderId,
        uid: u64,
        count: usize,
        from: String,
        subject: String,
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
    /// Messages going to another account: how far it is ("Moving 3 of 12 messages to Archive..."), and at the end what
    /// was done ("Moved 12 messages to Archive")
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

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::Store(error) => write!(f, "local store: {error}"),
            Error::NotFound => f.write_str("not found"),
            Error::Closed => f.write_str("shutting down"),
            Error::Compose(error) => write!(f, "{error}"),
            Error::Unavailable(reason) => write!(f, "{reason}"),
            Error::Folder(refusal) => write!(f, "{refusal}"),
            Error::OtherAccount(email) => write!(f, "the browser signed in to {email}, not to this account"),
            Error::Invalid(reason) => f.write_str(reason),
            Error::InUse(accounts) => write!(
                f,
                "it can not be removed while accounts sign in with it: {}",
                accounts.join(", ")
            ),
            Error::TurnedOff => f.write_str("this sign-in app is turned off for new accounts"),
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
    /// The access token of each OAuth account, which its worker and its reader share
    tokens: worker::Tokens,
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
    /// The SVGs fetched from BIMI-Location for this run, by address (None: there was none to have)
    logo_svgs: Arc<std::sync::Mutex<HashMap<String, Option<Vec<u8>>>>>,
    /// Message views built off the window thread: parsing, folding and sanitizing a large message takes a while
    views: Requests<Option<MessageView>>,
    /// The view request the reading pane waits for; an older one gives up
    newest_view: Arc<std::sync::atomic::AtomicU64>,
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
            .enable_all()
            .build()
            .map_err(|_| Error::Closed)?;
        // the patterns that fold earlier messages compile meanwhile, not when the first message is shown
        runtime.spawn_blocking(fold::warm_up);
        // what was cached before the search index read sources (an older version), on a connection of its own
        let indexed = path.clone();
        runtime.spawn_blocking(move || {
            if let Ok(mut store) = Store::open(&indexed) {
                let _ = search::index_pending(&mut store);
            }
        });
        let closed = Arc::new(AtomicBool::new(false));
        let open = closed.clone();
        Ok(Core {
            path,
            store: Mutex::new(store),
            runtime: Some(runtime),
            workers: Mutex::default(),
            readers: Mutex::default(),
            tokens: worker::Tokens::default(),
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
            logo_svgs: Arc::default(),
            views: Requests::default(),
            newest_view: Arc::default(),
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
                message: format!("the password could not be saved for the next start: {error}"),
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
        for workers in [&self.workers, &self.readers] {
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
        Ok(self.store().search(search, sort, offset, limit)?)
    }

    /// How many messages [`Core::search`] finds, and how many of them are unread
    pub fn count_search(&self, search: &Search) -> Result<(u64, u64)> {
        Ok(self.store().count_search(search)?)
    }

    /// Where the message `uid` of `folder` is in what [`Core::search`] finds
    pub fn search_index(&self, search: &Search, sort: Sort, folder: FolderId, uid: u64) -> Result<Option<u64>> {
        Ok(self.store().search_index(search, sort, folder, uid)?)
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
                Ok(response) => Some(format!("the list answered {}", response.status)),
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
    /// at a BIMI-Location is fetched once a run, without cookies, at most [`bimi::MAX_SVG`]. Refused for a message
    /// without a logo the receiving server passed, or not downloaded yet.
    pub fn logo_start(&self, folder: FolderId, uid: u64, size: u32) -> Result<u64> {
        let start = self
            .store()
            .source_start(folder, uid, view::MAX_HEADER_TEXT)?
            .ok_or(Error::NotFound)?;
        let headers = pe_mime::parser::parse(&start).map_err(|_| Error::NotFound)?.headers;
        let logo = bimi::of(&headers, &self.trusted(folder)?).ok_or(Error::NotFound)?;
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        let svgs = self.logo_svgs.clone();
        let work = async move {
            let svg = match logo {
                bimi::Logo::Indicator(svg) => Some(svg),
                bimi::Logo::Location(url) => {
                    let known = svgs.lock().unwrap_or_else(|p| p.into_inner()).get(&url).cloned();
                    match known {
                        Some(svg) => svg,
                        None => {
                            let fetched = match pe_net::http::get(&url, std::time::Duration::from_secs(15)).await {
                                Ok(response) if response.status == 200 && response.body.len() <= bimi::MAX_SVG => {
                                    Some(response.body)
                                }
                                _ => None,
                            };
                            svgs.lock()
                                .unwrap_or_else(|p| p.into_inner())
                                .insert(url, fetched.clone());
                            fetched
                        }
                    }
                }
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
            let refresh_token = tokens.refresh_token.ok_or("the provider gave no refresh token")?;
            let identity = tokens
                .identity
                .ok_or("the provider did not say which account signed in")?;
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
        found.unwrap_or_else(|| Err("signing in has not finished".into()))
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
        self.send_command(account, Command::Sync)
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
        self.send_to(
            &self.readers,
            Role::Reader,
            account,
            Command::FetchSource { folder, uid },
        )
    }

    /// The source of a message and the date the server got it, for a view
    fn view_source(&self, folder: FolderId, uid: u64) -> Result<Option<ViewSource>> {
        let store = self.store();
        let received = store.message(folder, uid)?.and_then(|m| m.info.internal_date);
        // with the store at hand: trusted() takes it again
        let trusted = authres::trusted(&store.account(store.folder(folder)?.account_id)?.settings);
        Ok(store.source(folder, uid)?.map(|source| (source, received, trusted)))
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
        Ok(self.view_source(folder, uid)?.and_then(|(source, received, trusted)| {
            finish_view(&source, received, allow_remote_images, &trusted, &|| false)
        }))
    }

    /// Builds the view of a message in the background: [`Event::ViewReady`] follows with the request this returns.
    /// The source is read now; parsing, folding and sanitizing it happen on a worker thread. A view started after
    /// it, or [`Core::message_view_cancel`], makes it give up between those steps: one is shown at a time.
    pub fn message_view_start(&self, folder: FolderId, uid: u64, allow_remote_images: bool) -> Result<u64> {
        let found = self.view_source(folder, uid)?;
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        self.newest_view.store(request, Ordering::Relaxed);
        let newest = self.newest_view.clone();
        let work = async move {
            let (source, received, trusted) = found?;
            let dropped = move || newest.load(Ordering::Relaxed) != request;
            let built = tokio::task::spawn_blocking(move || {
                finish_view(&source, received, allow_remote_images, &trusted, &dropped)
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
            "Message Source".to_string()
        } else {
            format!("Message Source: {}", view::header_text(subject.as_bytes()).trim_end())
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
    pub fn import_message(&self, folder: FolderId, path: &std::path::Path) -> Result<()> {
        const LIMIT: u64 = 50 * 1024 * 1024;
        let account = self.store().folder(folder)?.account_id;
        let not_one = |why: &str| Error::Unavailable(format!("{} {why}", path.display()));
        // opened once, read up to just past the limit: a file that grows meanwhile is still refused
        let file = std::fs::File::open(path).map_err(|e| not_one(&format!("can not be read: {e}")))?;
        let mut raw = Vec::new();
        std::io::Read::read_to_end(&mut std::io::Read::take(file, LIMIT + 1), &mut raw)
            .map_err(|e| not_one(&format!("can not be read: {e}")))?;
        if raw.len() as u64 > LIMIT {
            return Err(not_one("is larger than 50 MB"));
        }
        let parsed = pe_mime::parser::parse(&raw).map_err(|_| not_one("is not an e-mail message"))?;
        // a message has headers a mail program wrote; a text file parsed as one has none of these
        let looks_like_one = parsed.from.is_some() || parsed.message_id.is_some() || parsed.timestamp.is_some();
        if !looks_like_one {
            return Err(not_one("is not an e-mail message"));
        }
        self.send_command(
            account,
            Command::Append {
                folder,
                raw,
                date: parsed.timestamp,
            },
        )
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
        let Some(source) = self.store().source(folder, uid)? else {
            return Ok(None);
        };
        let files = view::attachments(&source);
        let saved = files
            .iter()
            .filter(|(name, content)| view::write_new(dir, name, content).is_ok())
            .count();
        Ok(Some((saved, files.len())))
    }

    /// The calendar part of a message written to `dir` as `invitation.ics` (a number added when that is taken), for
    /// the calendar program to open; its path, None when the message has none or is not downloaded yet
    pub fn invitation_file(&self, folder: FolderId, uid: u64, dir: &Path) -> Result<Option<PathBuf>> {
        let Some(source) = self.store().source(folder, uid)? else {
            return Ok(None);
        };
        let Ok(message) = pe_mime::parser::parse(&source) else {
            return Ok(None);
        };
        let Some(part) = view::calendar_part(&message.attachments) else {
            return Ok(None);
        };
        // its bytes as they came, whatever their charset
        let written = std::fs::create_dir_all(dir).and_then(|_| view::write_new(dir, "invitation.ics", &part.content));
        written.map(Some).map_err(|error| Error::Unavailable(error.to_string()))
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
    pub fn save_draft(&self, account: AccountId, mut outgoing: Outgoing) -> Result<String> {
        let email = self.store().account(account)?.settings.email;
        if compose::drafts_folder(&self.store(), account)?.is_none() {
            return Err(Error::Unavailable(compose::NO_DRAFTS.into()));
        }
        // an ID that does not tell this draft apart is replaced: the copy saved under it stays
        let message_id = outgoing
            .message_id
            .as_deref()
            .and_then(compose::draft_id)
            .unwrap_or_else(|| pe_smtp::message::new_message_id(&email));
        outgoing.message_id = Some(message_id.clone());
        self.send_command(
            account,
            Command::SaveDraft {
                outgoing: Box::new(outgoing),
            },
        )?;
        Ok(message_id)
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
                Error::Unavailable(format!("an attachment of the draft could not be kept: {error}"))
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

    /// A reply, a reply to all or a forward of a message whose source is in the store
    pub fn draft(&self, folder: FolderId, uid: u64, kind: DraftKind) -> Result<Option<Draft>> {
        let store = self.store();
        let account = store.account(store.folder(folder)?.account_id)?;
        let date = store.message(folder, uid)?.and_then(|m| m.info.display_date());
        let source = store.source(folder, uid)?;
        Ok(source.map(|source| compose::draft(&source, kind, &account.settings.email, date)))
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
            store.remove_messages(folder, uids)?;
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
        let missing = if junk { "Junk E-mail" } else { "Inbox" };
        target
            .map(|f| f.id)
            .ok_or_else(|| Error::Unavailable(format!("This account has no {missing} folder to move the messages to.")))
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
            store.remove_messages(folder, uids)?;
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

    fn send_command(&self, account: AccountId, command: Command) -> Result<()> {
        self.send_to(&self.workers, Role::Main, account, command)
    }

    /// Hands `command` to the worker of `account` in `workers` (of `role`), started when there is none or it stopped
    fn send_to(&self, workers: &Workers, role: Role, account: AccountId, command: Command) -> Result<()> {
        let mut workers = workers.lock().unwrap_or_else(|p| p.into_inner());
        let command = match workers.get(&account) {
            Some((sender, _)) => match sender.send(command) {
                Ok(()) => return Ok(()),
                // the worker stopped: a new one takes the command
                Err(returned) => returned.0,
            },
            None => command,
        };
        self.store().account(account).map_err(|_| Error::NotFound)?;
        let (sender, receiver) = unbounded_channel();
        sender.send(command).map_err(|_| Error::Closed)?;
        let worker = Worker::new(
            account,
            role,
            self.path.clone(),
            self.secrets.clone(),
            self.trust.clone(),
            self.oauth.clone(),
            self.tokens.clone(),
            self.events.clone(),
        );
        let task = self.runtime()?.spawn(worker.run(receiver));
        workers.insert(account, (sender, task.abort_handle()));
        Ok(())
    }

    fn stop_worker(&self, account: AccountId) {
        // dropping the sender ends the worker once its current command is done; the reader too, and the token goes,
        // as the settings it was for changed
        self.workers.lock().unwrap_or_else(|p| p.into_inner()).remove(&account);
        self.readers.lock().unwrap_or_else(|p| p.into_inner()).remove(&account);
        self.tokens.lock().unwrap_or_else(|p| p.into_inner()).remove(&account);
    }
}

/// The Deleted Items folder a message of `folder` goes to in `store`, None when it is that folder or there is none
pub(crate) fn trash_in(store: &Store, folder: FolderId) -> Result<Option<FolderId>> {
    let account = store.folder(folder)?.account_id;
    Ok(store
        .special_folder(account, "\\Trash")?
        .map(|trash| trash.id)
        .filter(|&trash| trash != folder))
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
fn private_dir(name: &str) -> std::io::Result<PathBuf> {
    let root = if cfg!(all(unix, not(target_os = "macos"))) {
        std::env::var_os("XDG_RUNTIME_DIR")
            .map(PathBuf::from)
            .filter(|dir| dir.is_absolute())
            .unwrap_or_else(std::env::temp_dir)
    } else {
        std::env::temp_dir()
    };
    let parent = root.join("InboxClassic");
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

/// Makes a folder, failing when it is there; on Unix readable by this user only
fn new_dir(dir: &std::path::Path) -> std::io::Result<()> {
    let mut builder = std::fs::DirBuilder::new();
    #[cfg(unix)]
    std::os::unix::fs::DirBuilderExt::mode(&mut builder, 0o700);
    builder.create(dir)
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
        self.workers.lock().unwrap_or_else(|p| p.into_inner()).clear();
        self.readers.lock().unwrap_or_else(|p| p.into_inner()).clear();
        if let Some(runtime) = self.runtime.take() {
            // workers that are waiting for the network are cancelled
            runtime.shutdown_timeout(SHUTDOWN_GRACE);
        }
    }
}

/// The view of a message's source, its date the server's when it has no Date header; None when `dropped` said to
/// give up
/// The source of a message, the date the server got it, and the domains whose verdicts its account trusts
type ViewSource = (Vec<u8>, Option<i64>, Vec<String>);

fn finish_view(
    source: &[u8],
    received: Option<i64>,
    allow_remote_images: bool,
    trusted: &[String],
    dropped: &dyn Fn() -> bool,
) -> Option<MessageView> {
    let mut view = view::build_unless(source, allow_remote_images, trusted, dropped)?;
    // without a Date header, the date the list shows: when the server got it
    view.date = view.date.or(received);
    Some(view)
}

#[cfg(test)]
mod write_out_tests {
    #[test]
    fn files_written_out_in_a_folder_of_this_users_own() {
        let files = vec![("a.eml".to_string(), b"one".to_vec()), ("a.eml".to_string(), b"two".to_vec())];
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
