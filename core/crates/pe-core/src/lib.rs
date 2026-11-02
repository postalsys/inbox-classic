//! The mail engine the C API wraps: accounts and their passwords, one sync worker per account,
//! and what the windows show, the folder tree, the message list and the message view.
//!
//! Each worker owns an IMAP connection and a connection to the store of its own; the windows read
//! through another one. SQLite in WAL mode lets them read while a worker writes. Work the
//! windows start runs on the workers and reports back as [`Event`]s, on a worker thread.
#![forbid(unsafe_code)]

mod compose;
mod fold;
mod requests;
mod secrets;
mod view;
mod worker;

use std::collections::HashMap;
use std::fmt;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, MutexGuard};

use pe_net::Trust;
use pe_store::{Account, AccountId, AccountSettings, Folder, FolderId, Message, Sort, Store};
use tokio::sync::mpsc::{UnboundedSender, unbounded_channel};

pub use compose::{ComposeError, Draft, DraftKind, Outgoing};
/// The rules of the folder tree the windows show: how deep a folder is, and which stay as they are
pub use pe_sync::{is_special as is_fixed_folder, tree_depths};
use requests::Requests;
pub use secrets::PasswordStore;
use secrets::Secrets;
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
    /// A message was sent, and is in the Sent folder when the account has one
    MessageSent {
        account: AccountId,
    },
    /// The servers of an address were looked up: [`Core::autoconfig_result`]
    AutoconfigDone {
        request: u64,
    },
    /// A sign-in in the browser finished: [`Core::sign_in_result`]
    SignInDone {
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
    pub(crate) fn provider(&self, kind: pe_oauth::ProviderKind) -> Option<pe_oauth::Provider> {
        match self.0.iter().find(|p| p.kind == kind) {
            Some(provider) => Some(provider.clone()),
            None => pe_oauth::Provider::builtin(kind),
        }
    }
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
    workers: Mutex<HashMap<AccountId, (UnboundedSender<Command>, tokio::task::AbortHandle)>>,
    secrets: Secrets,
    trust: Trust,
    events: EventSink,
    /// Set when closing: no event is delivered after
    closed: Arc<AtomicBool>,
    /// Lookups of servers; None when the address has no domain
    autoconfig: Requests<Option<pe_autoconfig::Settings>>,
    /// Message views built off the window thread: parsing, folding and sanitizing a large message takes a while
    views: Requests<Option<MessageView>>,
    /// The view request the reading pane waits for; an older one gives up
    newest_view: Arc<std::sync::atomic::AtomicU64>,
    /// Sign-ins in the browser: the provider and the refresh token, or why not
    sign_ins: Requests<std::result::Result<(pe_oauth::ProviderKind, String), String>>,
    oauth: OAuthProviders,
    next_request: std::sync::atomic::AtomicU64,
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
        let closed = Arc::new(AtomicBool::new(false));
        let open = closed.clone();
        Ok(Core {
            path,
            store: Mutex::new(store),
            runtime: Some(runtime),
            workers: Mutex::default(),
            secrets,
            trust,
            events: Arc::new(move |event| {
                if !open.load(Ordering::Acquire) {
                    events(event);
                }
            }),
            closed,
            autoconfig: Requests::default(),
            views: Requests::default(),
            newest_view: Arc::default(),
            sign_ins: Requests::default(),
            oauth: OAuthProviders(Arc::new(options.oauth_providers)),
            next_request: std::sync::atomic::AtomicU64::new(1),
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

    /// Changes the settings of an account; how it signs in stays, only signing in again changes that
    pub fn update_account(&self, id: AccountId, settings: &AccountSettings) -> Result<()> {
        let mut settings = settings.clone();
        settings.auth = self.store().account(id)?.settings.auth;
        if let pe_store::Auth::OAuth2(name) = &settings.auth
            && let Some(provider) = pe_oauth::ProviderKind::parse(name).and_then(|kind| self.oauth.provider(kind))
        {
            settings = with_provider(&settings, &provider);
        }
        self.store().update_account(id, &settings)?;
        // the worker connects again with the new settings
        self.stop_worker(id);
        Ok(())
    }

    pub fn remove_account(&self, id: AccountId) -> Result<()> {
        // now, not after its current command: a sync it was running would write into the next account that gets
        // this id
        if let Some((_, task)) = self.workers.lock().unwrap_or_else(|p| p.into_inner()).remove(&id) {
            task.abort();
        }
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

    /// A page of the messages of a folder that have `find` in their subject, sender or recipients (all of them for
    /// an empty one)
    pub fn messages_matching(
        &self,
        folder: FolderId,
        sort: Sort,
        find: &str,
        offset: u64,
        limit: u64,
    ) -> Result<Vec<Message>> {
        Ok(self.store().messages_matching(folder, sort, find, offset, limit)?)
    }

    /// How many messages [`Core::messages_matching`] finds, and how many of them are unread
    pub fn count_matching(&self, folder: FolderId, find: &str) -> Result<(u64, u64)> {
        Ok(self.store().count_matching(folder, find)?)
    }

    /// Where a message is in the list of [`Core::messages_matching`]
    pub fn message_index_matching(&self, folder: FolderId, sort: Sort, find: &str, uid: u64) -> Result<Option<u64>> {
        Ok(self.store().message_index_matching(folder, sort, find, uid)?)
    }

    /// One folder with its counts
    pub fn folder(&self, folder: FolderId) -> Result<Folder> {
        Ok(self.store().folder(folder)?)
    }

    /// Where a message is in the message list in this order
    pub fn message_index(&self, folder: FolderId, sort: Sort, uid: u64) -> Result<Option<u64>> {
        Ok(self.store().message_index(folder, sort, uid)?)
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

    /// Stops a lookup the user no longer waits for, and forgets it
    pub fn autoconfig_cancel(&self, request: u64) {
        self.autoconfig.cancel(request);
    }

    /// Whether this build can sign in to the provider of this IMAP server with OAuth
    pub fn oauth_provider_for(&self, imap_host: &str) -> Option<pe_oauth::ProviderKind> {
        let kind = pe_oauth::ProviderKind::for_imap_host(imap_host)?;
        self.oauth.provider(kind).map(|_| kind)
    }

    /// Starts signing in to `kind` for `email`: the page to open in the browser, and the request
    /// [`Event::SignInDone`] comes with once the browser came back or the time ran out
    pub fn sign_in_begin(&self, kind: pe_oauth::ProviderKind, email: &str) -> Result<(u64, String)> {
        let provider = self.oauth.provider(kind).ok_or(Error::NotFound)?;
        let sign_in = pe_oauth::SignIn::begin(provider, email).map_err(|e| Error::Unavailable(e.to_string()))?;
        let url = sign_in.url.clone();
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        let work = async move {
            let tokens = sign_in
                .finish(pe_oauth::SIGN_IN_TIMEOUT)
                .await
                .map_err(|e| e.to_string())?;
            let refresh = tokens.refresh_token.ok_or("the provider gave no refresh token")?;
            Ok((kind, refresh))
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

    /// The provider and refresh token of a finished sign-in, taken
    fn take_sign_in(&self, request: u64) -> Result<(pe_oauth::Provider, String)> {
        let (kind, refresh_token) = self
            .sign_ins
            .take(request)
            .and_then(|r| r.ok())
            .ok_or(Error::NotFound)?;
        let provider = self.oauth.provider(kind).ok_or(Error::NotFound)?;
        Ok((provider, refresh_token))
    }

    /// Adds an account that signs in with what the sign-in `request` got, at the servers of the provider: its
    /// access tokens go nowhere else, whatever a configuration file said
    pub fn add_account_oauth(&self, settings: &AccountSettings, request: u64) -> Result<AccountId> {
        let (provider, refresh_token) = self.take_sign_in(request)?;
        self.add_account(&with_provider(settings, &provider), &refresh_token)
    }

    /// Gives an OAuth account the refresh token of a new sign-in, after the old one was refused
    pub fn reauthorize(&self, account: AccountId, request: u64) -> Result<()> {
        let (provider, refresh_token) = self.take_sign_in(request)?;
        let settings = with_provider(&self.store().account(account)?.settings, &provider);
        self.store().update_account(account, &settings)?;
        self.stop_worker(account);
        self.keep_password(account, &refresh_token);
        Ok(())
    }

    /// Syncs the folder list and every folder of an account, in the background
    pub fn sync(&self, account: AccountId) -> Result<()> {
        self.send_command(account, Command::Sync)
    }

    /// Gets the source of a message to the store, in the background; [`Event::MessageReady`]
    /// follows, right away when it is cached
    pub fn open_message(&self, folder: FolderId, uid: u64) -> Result<()> {
        let account = self.store().folder(folder)?.account_id;
        self.send_command(account, Command::FetchSource { folder, uid })
    }

    /// The source of a message and the date the server got it, for a view
    fn view_source(&self, folder: FolderId, uid: u64) -> Result<Option<(Vec<u8>, Option<i64>)>> {
        let store = self.store();
        let received = store.message(folder, uid)?.and_then(|m| m.info.internal_date);
        Ok(store.source(folder, uid)?.map(|source| (source, received)))
    }

    /// The message as the preview shows it, None when its source is not in the store yet. Built on the calling
    /// thread, for tests and tools; the windows use [`Core::message_view_start`].
    pub fn message_view(&self, folder: FolderId, uid: u64, allow_remote_images: bool) -> Result<Option<MessageView>> {
        Ok(self
            .view_source(folder, uid)?
            .and_then(|(source, received)| finish_view(&source, received, allow_remote_images, &|| false)))
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
            let (source, received) = found?;
            let dropped = move || newest.load(Ordering::Relaxed) != request;
            let built =
                tokio::task::spawn_blocking(move || finish_view(&source, received, allow_remote_images, &dropped));
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
        // the subject made safe first, the extension after: a subject of only `???` is not left without one
        let stem = pe_mime::parser::safe_filename(Some(&subject.replace(['/', '\\'], "-")), "message/rfc822");
        let stem = if stem.starts_with("attachment.") {
            "message".to_string()
        } else {
            stem
        };
        Ok(Some((format!("{stem}.eml"), source)))
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

    /// Sends a message from an account in the background: [`Event::MessageSent`] or [`Event::Failed`] follows.
    /// Recipients that are no addresses and attachments that are not there fail right away.
    pub fn send(&self, account: AccountId, outgoing: Outgoing) -> Result<()> {
        self.queue(account, outgoing, true)
    }

    /// Puts a message in the Outbox; it goes with the next Send/Recv (Send Later)
    pub fn send_later(&self, account: AccountId, outgoing: Outgoing) -> Result<()> {
        self.queue(account, outgoing, false)
    }

    fn queue(&self, account: AccountId, outgoing: Outgoing, now: bool) -> Result<()> {
        // a typo in an address is told now, while the message is still open in its window
        compose::check(&outgoing).map_err(Error::Compose)?;
        self.send_command(
            account,
            Command::Send {
                outgoing: Box::new(outgoing),
                now,
            },
        )
    }

    /// The messages waiting in the Outbox, of every account, oldest first
    pub fn outbox(&self) -> Result<Vec<pe_store::Queued>> {
        Ok(self.store().outbox(None)?)
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

    /// Flags a message or takes its flag away: in the store now, on the server in the background
    pub fn set_flagged(&self, folder: FolderId, uid: u64, flagged: bool) -> Result<()> {
        self.set_flag(folder, uid, "\\Flagged", flagged)
    }

    fn set_flag(&self, folder: FolderId, uid: u64, flag: &'static str, on: bool) -> Result<()> {
        let (account, changed) = {
            let store = self.store();
            let account = store.folder(folder)?.account_id;
            (account, store.set_flag(folder, uid, flag, on)?)
        };
        if changed {
            self.post(Event::FolderChanged { account, folder })?;
        }
        self.send_command(account, Command::SetFlag { folder, uid, flag, on })
    }

    /// Moves a message to another folder of its account: out of the store now, on the server in the background,
    /// which then syncs the folder it went to. When the server does not move it, it comes back into the folder.
    pub fn move_message(&self, folder: FolderId, uid: u64, to: FolderId) -> Result<()> {
        {
            let store = self.store();
            let target = store.folder(to)?;
            if target.account_id != store.folder(folder)?.account_id || !target.info.selectable || to == folder {
                return Err(Error::NotFound);
            }
        }
        self.remove_then(folder, uid, |removed| Command::Move {
            folder,
            uid,
            to,
            removed,
        })
    }

    /// Deletes a message as Outlook Express does: into Deleted Items (the account's `\\Trash`), or for good when it
    /// is in there already or the account has none ([`Core::deletes_for_good`]). Out of the store now, on the server
    /// in the background.
    pub fn delete_message(&self, folder: FolderId, uid: u64) -> Result<()> {
        match self.trash_for(folder)? {
            Some(trash) => self.move_message(folder, uid, trash),
            None => self.remove_then(folder, uid, |removed| Command::Expunge { folder, uid, removed }),
        }
    }

    /// Whether deleting from `folder` removes a message for good: it is Deleted Items, or the account has none
    pub fn deletes_for_good(&self, folder: FolderId) -> Result<bool> {
        Ok(self.trash_for(folder)?.is_none())
    }

    /// The Deleted Items folder a message of `folder` goes to, None when it is that folder or there is none
    fn trash_for(&self, folder: FolderId) -> Result<Option<FolderId>> {
        let store = self.store();
        let account = store.folder(folder)?.account_id;
        Ok(store
            .special_folder(account, "\\Trash")?
            .map(|trash| trash.id)
            .filter(|&trash| trash != folder))
    }

    /// Takes a message out of the store, tells the windows, and hands the server the work `command` makes of the row
    /// (put back when the server does not do it)
    fn remove_then(
        &self,
        folder: FolderId,
        uid: u64,
        command: impl FnOnce(Box<pe_store::MessageInfo>) -> Command,
    ) -> Result<()> {
        let (account, removed) = {
            let store = self.store();
            let account = store.folder(folder)?.account_id;
            let removed = store.message(folder, uid)?.ok_or(Error::NotFound)?.info;
            store.remove_messages(folder, &[uid])?;
            (account, removed)
        };
        self.post(Event::FolderChanged { account, folder })?;
        self.send_command(account, command(Box::new(removed)))
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
        let mut workers = self.workers.lock().unwrap_or_else(|p| p.into_inner());
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
            self.path.clone(),
            self.secrets.clone(),
            self.trust.clone(),
            self.oauth.clone(),
            self.events.clone(),
        );
        let task = self.runtime()?.spawn(worker.run(receiver));
        workers.insert(account, (sender, task.abort_handle()));
        Ok(())
    }

    fn stop_worker(&self, account: AccountId) {
        // dropping the sender ends the worker once its current command is done
        self.workers.lock().unwrap_or_else(|p| p.into_inner()).remove(&account);
    }
}

fn store_security(security: pe_net::Security) -> pe_store::Security {
    match security {
        pe_net::Security::Tls => pe_store::Security::Tls,
        pe_net::Security::StartTls => pe_store::Security::StartTls,
        pe_net::Security::Plain => pe_store::Security::Plain,
    }
}

/// `settings` at the servers of `provider`, signing in with it
fn with_provider(settings: &AccountSettings, provider: &pe_oauth::Provider) -> AccountSettings {
    AccountSettings {
        imap_host: provider.imap.host.clone(),
        imap_port: provider.imap.port,
        imap_security: store_security(provider.imap.security),
        smtp_host: provider.smtp.host.clone(),
        smtp_port: provider.smtp.port,
        smtp_security: store_security(provider.smtp.security),
        auth: pe_store::Auth::OAuth2(provider.kind.as_str().to_string()),
        ..settings.clone()
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

/// The view of a message's source, its date the server's when it has no Date header; None when `dropped` said to
/// give up
fn finish_view(
    source: &[u8],
    received: Option<i64>,
    allow_remote_images: bool,
    dropped: &dyn Fn() -> bool,
) -> Option<MessageView> {
    let mut view = view::build_unless(source, allow_remote_images, dropped)?;
    // without a Date header, the date the list shows: when the server got it
    view.date = view.date.or(received);
    Some(view)
}
