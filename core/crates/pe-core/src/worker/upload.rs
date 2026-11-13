//! Uploads on a connection of their own (docs/open-speed-plan.md, phase 4): a draft saved, and the copy of a message
//! sent in Sent Items (APPEND, often megabytes), go over a connection made for that one upload, in a task of their
//! own, so the main worker stays on the Inbox (IDLE) and the user's commands. One upload of an account at a time, in
//! the order they came. When that connection can not be made, the main worker uploads on its own, as before.

use std::sync::Arc;

use pe_store::{AccountId, FolderId, Store};
use tokio::sync::mpsc::WeakUnboundedSender;

use super::{Command, Failure, Outcome, Role, Worker, shared_of};
use crate::Event;

/// Each account's turn to upload: one upload at a time, so two saves of a draft do not race
pub(crate) type Uploads = std::sync::Mutex<std::collections::HashMap<AccountId, Arc<tokio::sync::Mutex<()>>>>;

/// What is uploaded
pub(super) enum Upload {
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
}

impl Upload {
    pub(super) fn folder(&self) -> FolderId {
        match self {
            Upload::Draft { drafts, .. } => *drafts,
            Upload::Sent { sent, .. } => *sent,
        }
    }
}

impl Worker {
    /// Uploads on a connection of its own, in a task of its own; the upload back when no such connection could be
    /// made, for this worker to do on its own connection
    pub(super) async fn upload_apart(&mut self, store: &mut Store, upload: Upload) -> Result<(), Upload> {
        let turn = shared_of(&self.ctx.uploads, self.account).lock_owned().await;
        let mut uploader = Worker::new(self.account, Role::Upload, self.ctx.clone());
        uploader.main = self.main.clone();
        if uploader.client(store).await.is_err() {
            return Err(upload);
        }
        tokio::spawn(async move {
            let _turn = turn;
            uploader.upload(upload).await;
            uploader.log_out().await;
        });
        Ok(())
    }

    /// The upload on this worker's connection, said to the window or the status bar as the main worker would; the
    /// main worker syncs the folder after
    async fn upload(&mut self, upload: Upload) {
        let mut store = match Store::open(&self.ctx.path) {
            Ok(store) => store,
            Err(error) => return self.upload_failed(&upload, error.into()),
        };
        let folder = upload.folder();
        let outcome = self.upload_into(&mut store, &upload).await;
        if let Upload::Draft { message_id, .. } = &upload {
            self.emit(Event::DraftSaved {
                account: self.account,
                message_id: message_id.clone(),
                problem: outcome.as_ref().err().map(|failure| failure.message.clone()),
            });
        }
        match outcome {
            Ok(()) => {
                if let Some(main) = self.main.as_ref().and_then(WeakUnboundedSender::upgrade) {
                    let _ = main.send(Command::SyncFolder { folder });
                }
            }
            Err(failure) => self.upload_failed(&upload, failure),
        }
    }

    /// The upload on this worker's connection
    pub(super) async fn upload_into(&mut self, store: &mut Store, upload: &Upload) -> Outcome {
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
        }
    }

    /// An upload that failed: a draft's window heard of it already; a sent message's missing copy is told
    fn upload_failed(&self, upload: &Upload, failure: Failure) {
        if let Upload::Sent { .. } = upload {
            self.sent_but(pe_i18n::tr_args(
                pe_i18n::Text::ErrorSentNoCopy,
                &[("reason", (&failure.message).into())],
            ));
        }
    }
}
