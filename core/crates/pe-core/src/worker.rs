//! The worker of an account: runs the commands the windows send, one at a time, on the
//! account's IMAP connection, connecting when there is none, and applies what the server reports
//! meanwhile.

use std::collections::BTreeSet;

use std::path::PathBuf;

use pe_imap::{Client, Credentials, ErrorKind, Event as ImapEvent};
use pe_store::{AccountId, FolderId, Store};
use pe_sync::{Change, apply_event, fetch_source, imap_config, set_seen, sync_folder, sync_folders};
use tokio::sync::mpsc::{UnboundedReceiver, error::TryRecvError};

use crate::{Event, EventSink, FailureKind, Secrets};

#[derive(Debug, PartialEq, Eq)]
pub(crate) enum Command {
    Sync,
    FetchSource { folder: FolderId, uid: u64 },
    SetSeen { folder: FolderId, uid: u64, seen: bool },
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
    events: EventSink,
    connection: Option<(Client, UnboundedReceiver<ImapEvent>)>,
}

impl Worker {
    pub(crate) fn new(account: AccountId, path: PathBuf, secrets: Secrets, events: EventSink) -> Self {
        Worker {
            account,
            path,
            secrets,
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
            Command::SetSeen { folder, uid, seen } => {
                Ok(set_seen(self.client(store).await?, store, folder, uid, seen).await?)
            }
        }
    }

    async fn sync_all(&mut self, store: &mut Store) -> Outcome {
        let account = self.account;
        let before: Vec<_> = store.folders(account)?.into_iter().map(|f| f.info).collect();
        let folders = sync_folders(self.client(store).await?, store, account).await?;
        if folders.iter().map(|f| &f.info).ne(before.iter()) {
            self.emit(Event::FoldersChanged { account });
        }
        for folder in folders.iter().filter(|f| f.info.selectable) {
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
            let Some(password) = self.secrets.get(self.account) else {
                return Err(Failure {
                    kind: FailureKind::Authentication,
                    message: "no password for this account".into(),
                });
            };
            let credentials = Credentials::Password {
                user: account.settings.username.clone(),
                password,
            };
            self.connection = Some(Client::connect(imap_config(&account, credentials)).await?);
        }
        Ok(&mut self.connection.as_mut().expect("connected").0)
    }
}
