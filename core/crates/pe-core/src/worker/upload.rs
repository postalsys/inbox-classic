//! Uploads on a connection of their own (docs/open-speed-plan.md, phase 4): a draft saved, the copy of a message sent
//! in Sent Items (APPEND, often megabytes) and the drafts removed once a message is sent go to the account's uploader,
//! a worker of its own fed by a queue, so the main worker hands them over and stays on the Inbox (IDLE) and the
//! user's commands. The queue keeps their order: drafts are removed after a save of theirs under way. The uploader's
//! connection is closed after [`IDLE_FOR`] without uploads. When it can not have one, it hands each upload back to
//! the main worker, which does it as before.

use std::time::{Duration, Instant};

use pe_store::{AccountId, FolderId, Store};
use tokio::sync::mpsc::{UnboundedReceiver, UnboundedSender};

use super::{Command, Outcome, Worker};
use crate::Event;

use super::IDLE_FOR;

/// How long after the uploader handed an upload back to the main worker the next go there too
const HAND_BACK_FOR: Duration = Duration::from_secs(60);

/// What the uploader does
#[derive(Debug)]
pub(crate) enum Upload {
    /// A draft into Drafts, in place of the copy saved before (by its Message-ID); then the copy in the Drafts of
    /// the account it went from before goes
    Draft {
        drafts: FolderId,
        raw: Vec<u8>,
        message_id: String,
        time: i64,
        moved_from: Option<AccountId>,
    },
    /// The copy of a message sent, into Sent Items
    Sent { sent: FolderId, raw: Vec<u8>, date: i64 },
    /// The drafts of a message sent removed from Drafts
    RemoveDrafts { drafts: FolderId, message_id: String },
}

impl Upload {
    /// The folder it changes
    pub(super) fn folder(&self) -> FolderId {
        match self {
            Upload::Draft { drafts, .. } | Upload::RemoveDrafts { drafts, .. } => *drafts,
            Upload::Sent { sent, .. } => *sent,
        }
    }
}

impl Worker {
    /// Hands an upload to the account's uploader, made when there is none
    pub(super) fn upload_apart(&mut self, upload: Upload) {
        if let Some(uploader) = self.uploader.as_ref().filter(|uploader| !uploader.is_closed()) {
            // a queue whose uploader ended meanwhile: a new one
            if let Err(returned) = uploader.send(upload) {
                return self.start_uploader(returned.0);
            }
            return;
        }
        self.start_uploader(upload);
    }

    fn start_uploader(&mut self, upload: Upload) {
        let (sender, uploads) = tokio::sync::mpsc::unbounded_channel();
        let _ = sender.send(upload);
        let mut uploader = self.sibling(self.account);
        uploader.main = self.main.clone();
        tokio::spawn(async move { uploader.upload_all(uploads).await });
        self.uploader = Some(sender);
    }

    /// The uploader's life: each upload in turn, on its own connection while it has uploads
    async fn upload_all(&mut self, mut uploads: UnboundedReceiver<Upload>) {
        let mut store = match Store::open(&self.ctx.path) {
            Ok(store) => store,
            Err(_) => {
                while let Some(upload) = uploads.recv().await {
                    self.hand_back(upload);
                }
                return;
            }
        };
        let mut handed_back = None;
        loop {
            let connected = self.connection.is_some();
            let upload = tokio::select! {
                upload = uploads.recv() => upload,
                () = tokio::time::sleep(IDLE_FOR), if connected => {
                    self.log_out().await;
                    continue;
                }
            };
            let Some(upload) = upload else { break };
            // after one handed back, the next go the same way for a while, so they keep their order (a draft's
            // removal after its save)
            let handing_back = handed_back.is_some_and(|at: Instant| at.elapsed() < HAND_BACK_FOR);
            if handing_back || self.limited_lately() || self.client(&mut store).await.is_err() {
                handed_back = Some(Instant::now());
                self.hand_back(upload);
                continue;
            }
            let outcome = self.upload(&mut store, &upload).await;
            self.uploaded(&upload, &outcome);
            match outcome {
                Ok(()) => self.to_main(Command::SyncFolder {
                    folder: upload.folder(),
                }),
                Err(failure) => self.reset_after(&failure),
            }
        }
        self.log_out().await;
    }

    /// The main worker does an upload that the uploader could not
    fn hand_back(&self, upload: Upload) {
        self.to_main(Command::Upload {
            upload: Box::new(upload),
        });
    }

    fn to_main(&self, command: Command) {
        if let Some(main) = self
            .main
            .as_ref()
            .and_then(tokio::sync::mpsc::WeakUnboundedSender::upgrade)
        {
            let _ = main.send(command);
        }
    }

    /// An upload on this worker's connection
    pub(super) async fn upload(&mut self, store: &mut Store, upload: &Upload) -> Outcome {
        match upload {
            Upload::Draft {
                drafts,
                raw,
                message_id,
                time,
                moved_from,
            } => {
                let client = self.client(store).await?;
                pe_sync::save_draft(client, store, *drafts, raw, message_id, *time).await?;
                // saved here: the copy in the Drafts of the account it went from before goes
                if let Some(from) = moved_from {
                    self.remove_draft_of(store, *from, message_id).await;
                }
                Ok(())
            }
            Upload::Sent { sent, raw, date } => {
                let path = store.folder(*sent)?.info.path;
                let client = self.client(store).await?;
                client.append(&path, raw, &["\\Seen"], Some(*date)).await?;
                Ok(())
            }
            Upload::RemoveDrafts { drafts, message_id } => {
                let client = self.client(store).await?;
                Ok(pe_sync::remove_drafts(client, store, *drafts, message_id).await?)
            }
        }
    }

    /// What an upload says: a draft's window hears how its save went, a sent message's missing copy and drafts left
    /// are told in the status bar
    pub(super) fn uploaded(&self, upload: &Upload, outcome: &Outcome) {
        let problem = outcome.as_ref().err().map(|failure| failure.message.clone());
        match (upload, problem) {
            (Upload::Draft { message_id, .. }, problem) => self.emit(Event::DraftSaved {
                account: self.account,
                message_id: message_id.clone(),
                problem,
            }),
            (_, None) => {}
            (Upload::Sent { .. }, Some(reason)) => self.sent_but(pe_i18n::tr_args(
                pe_i18n::Text::ErrorSentNoCopy,
                &[("reason", (&reason).into())],
            )),
            (Upload::RemoveDrafts { .. }, Some(reason)) => self.emit(Event::Failed {
                account: self.account,
                kind: crate::FailureKind::Other,
                message: pe_i18n::tr_args(pe_i18n::Text::ErrorDraftNotRemoved, &[("reason", (&reason).into())]),
            }),
        }
    }
}

/// The uploader of a main worker, see [`Worker::upload_apart`]
pub(crate) type Uploader = UnboundedSender<Upload>;
