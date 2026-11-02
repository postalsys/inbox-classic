//! The worker of an account: runs the commands the windows send, one at a time, on the
//! account's IMAP connection, connecting when there is none, and applies what the server reports
//! meanwhile.

use std::collections::BTreeSet;

use std::path::PathBuf;

use pe_imap::{Client, Credentials, ErrorKind, Event as ImapEvent};
use pe_net::Trust;
use pe_store::{AccountId, FolderId, Store};
use pe_sync::{
    Change, apply_event, expunge_message, fetch_source, imap_config, move_message, set_flag, smtp_config, sync_folder,
    sync_folders,
};
use tokio::sync::mpsc::{UnboundedReceiver, error::TryRecvError};

use crate::{Event, EventSink, FailureKind, Secrets};

#[derive(Debug, PartialEq, Eq)]
pub(crate) enum Command {
    Sync,
    FetchSource {
        folder: FolderId,
        uid: u64,
    },
    SetFlag {
        folder: FolderId,
        uid: u64,
        flag: &'static str,
        on: bool,
    },
    /// `removed` is the row taken out of the store, put back when the server does not do it
    Move {
        folder: FolderId,
        uid: u64,
        to: FolderId,
        removed: Box<pe_store::MessageInfo>,
    },
    Expunge {
        folder: FolderId,
        uid: u64,
        removed: Box<pe_store::MessageInfo>,
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
    Send(Box<crate::Outgoing>),
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

pub(crate) struct Worker {
    account: AccountId,
    path: PathBuf,
    secrets: Secrets,
    trust: Trust,
    oauth: crate::OAuthProviders,
    /// The access token of an OAuth account and when it runs out
    access_token: Option<(String, i64)>,
    events: EventSink,
    connection: Option<(Client, UnboundedReceiver<ImapEvent>)>,
}

impl Worker {
    pub(crate) fn new(
        account: AccountId,
        path: PathBuf,
        secrets: Secrets,
        trust: Trust,
        oauth: crate::OAuthProviders,
        events: EventSink,
    ) -> Self {
        Worker {
            account,
            path,
            secrets,
            trust,
            oauth,
            access_token: None,
            events,
            connection: None,
        }
    }

    pub(crate) async fn run(mut self, mut commands: UnboundedReceiver<Command>) {
        // its own connection to the store, opened here and not on the thread that asked for work
        let mut store = match Store::open(&self.path) {
            Ok(store) => store,
            Err(error) => return self.fail(error.into()),
        };
        while let Some(command) = commands.recv().await {
            let sync = command == Command::Sync;
            if sync {
                self.emit(Event::SyncStarted { account: self.account });
            }
            let mut outcome = self.handle(&mut store, command).await;
            if outcome.is_ok() {
                outcome = self.apply_server_events(&mut store).await;
            }
            if let Err(failure) = outcome {
                self.fail(failure);
            }
            // after the failure and the changes it found, so the window knows the sync is done
            if sync {
                self.emit(Event::SyncFinished { account: self.account });
            }
        }
        if let Some((mut client, _)) = self.connection.take() {
            let _ = client.logout().await;
        }
    }

    fn emit(&self, event: Event) {
        (self.events)(event);
    }

    fn fail(&mut self, failure: Failure) {
        if failure.kind != FailureKind::Other {
            // the connection is no good now, the next command connects again
            self.connection = None;
        }
        if failure.kind == FailureKind::Authentication {
            // an access token that was refused is no good either
            self.access_token = None;
        }
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
            Command::Sync => self.sync_all(store).await,
            Command::FetchSource { folder, uid } => {
                if !store.has_source(folder, uid)? {
                    fetch_source(self.client(store).await?, store, folder, uid).await?;
                }
                self.emit(Event::MessageReady { folder, uid });
                Ok(())
            }
            Command::SetFlag { folder, uid, flag, on } => {
                Ok(set_flag(self.client(store).await?, store, folder, uid, flag, on).await?)
            }
            Command::Move {
                folder,
                uid,
                to,
                removed,
            } => {
                let moved = match self.client(store).await {
                    Ok(client) => move_message(client, store, folder, uid, to)
                        .await
                        .map_err(Failure::from),
                    Err(failure) => Err(failure),
                };
                self.restore_on_failure(store, folder, *removed, moved)?;
                // the message shows up in the folder it went to
                self.sync_one(store, to).await
            }
            Command::Expunge { folder, uid, removed } => {
                let expunged = match self.client(store).await {
                    Ok(client) => expunge_message(client, store, folder, uid).await.map_err(Failure::from),
                    Err(failure) => Err(failure),
                };
                self.restore_on_failure(store, folder, *removed, expunged)
            }
            Command::CreateFolder { parent, name } => {
                let client = self.client(store).await?;
                let namespace = client.namespace().cloned();
                let path = pe_sync::new_folder_path(store, self.account, parent, &name, namespace.as_ref())?.map_err(
                    |refusal| Failure {
                        kind: FailureKind::Other,
                        message: refusal.to_string(),
                    },
                )?;
                pe_sync::create_folder(self.client(store).await?, &path).await?;
                self.sync_folder_list(store).await
            }
            Command::RenameFolder { folder, path } => {
                pe_sync::rename_folder(self.client(store).await?, store, folder, &path).await?;
                self.sync_folder_list(store).await
            }
            Command::DeleteFolder { folder } => {
                pe_sync::delete_folder(self.client(store).await?, store, folder).await?;
                self.sync_folder_list(store).await
            }
            Command::Send(outgoing) => self.send(store, *outgoing).await,
        }
    }

    /// A message the windows took out of a folder before the server moved or deleted it: back in when the server did
    /// not (offline, refused), so it is not lost from view while it is still on the server
    fn restore_on_failure(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        removed: pe_store::MessageInfo,
        outcome: Outcome,
    ) -> Outcome {
        if outcome.is_err() {
            store.add_messages(folder, &[removed])?;
            self.emit(Event::FolderChanged {
                account: self.account,
                folder,
            });
        }
        outcome
    }

    /// Sends over SMTP, then puts a copy in the Sent folder
    async fn send(&mut self, store: &mut Store, outgoing: crate::Outgoing) -> Outcome {
        let account = store.account(self.account)?;
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map_or(0, |d| d.as_secs() as i64);
        // reads the attachments: off the threads that run the network
        let settings = account.settings.clone();
        let built = tokio::task::spawn_blocking(move || {
            crate::compose::message(&settings, &outgoing, now).map(|message| pe_smtp::build(&message))
        })
        .await
        .map_err(|_| Failure {
            kind: FailureKind::Other,
            message: "the message could not be built".into(),
        })??;
        let mut config = smtp_config(&account, self.credentials(&account).await?);
        config.trust = self.trust.clone();
        let mut smtp = pe_smtp::Client::connect(config).await?;
        smtp.send(&built.envelope, &built.raw).await?;
        smtp.quit().await;
        // sent: whatever happens to the copy, sending it again would send it twice
        self.emit(Event::MessageSent { account: self.account });
        self.save_sent(store, &built.raw, now).await.map_err(|failure| Failure {
            kind: FailureKind::Other,
            message: format!(
                "the message was sent, but no copy could be saved in Sent: {}",
                failure.message
            ),
        })
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
    async fn credentials(&mut self, account: &pe_store::Account) -> Result<Credentials, Failure> {
        let no_secret = |what: &str| Failure {
            kind: FailureKind::Authentication,
            message: format!("no {what} for this account"),
        };
        let user = account.settings.username.clone();
        let pe_store::Auth::OAuth2(provider) = &account.settings.auth else {
            let password = self.secrets.get(self.account).ok_or_else(|| no_secret("password"))?;
            return Ok(Credentials::Password { user, password });
        };
        let now = pe_oauth::now();
        if let Some((token, expires_at)) = &self.access_token
            && *expires_at > now
        {
            return Ok(Credentials::OAuth2 {
                user,
                access_token: token.clone(),
            });
        }
        let provider = pe_oauth::ProviderKind::parse(provider)
            .and_then(|kind| self.oauth.provider(kind))
            .ok_or_else(|| Failure {
                kind: FailureKind::Other,
                message: format!("this build can not sign in to {provider}"),
            })?;
        // an access token is for the provider's own servers only
        let settings = &account.settings;
        if !settings.imap_host.eq_ignore_ascii_case(&provider.imap.host)
            || !settings.smtp_host.eq_ignore_ascii_case(&provider.smtp.host)
        {
            return Err(Failure {
                kind: FailureKind::Other,
                message: format!(
                    "the servers of this account are not those of {}",
                    provider.kind.as_str()
                ),
            });
        }
        let refresh_token = self.secrets.get(self.account).ok_or_else(|| no_secret("sign-in"))?;
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
                    message: format!("the new sign-in could not be saved for the next start: {error}"),
                });
            }
        }
        self.access_token = Some((tokens.access_token.clone(), tokens.expires_at));
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
                    message: format!("{}: {}", folder.info.path, failure.message),
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
        let report = sync_folder(self.client(store).await?, store, folder).await?;
        if report != pe_sync::Report::default() {
            self.emit(Event::FolderChanged {
                account: self.account,
                folder,
            });
        }
        Ok(())
    }

    /// Applies the changes the server reported during the last command; folders that only a
    /// sync can bring up to date are synced
    async fn apply_server_events(&mut self, store: &mut Store) -> Outcome {
        let mut resync = BTreeSet::new();
        loop {
            let Some((_, events)) = self.connection.as_mut() else {
                return Ok(());
            };
            let event = match events.try_recv() {
                Ok(event) => event,
                Err(TryRecvError::Empty) => break,
                Err(TryRecvError::Disconnected) => {
                    self.connection = None;
                    break;
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
            let mut config = imap_config(&account, self.credentials(&account).await?);
            config.trust = self.trust.clone();
            self.connection = Some(Client::connect(config).await?);
        }
        Ok(&mut self.connection.as_mut().expect("connected").0)
    }
}
