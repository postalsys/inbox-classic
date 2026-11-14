//! Undo Send: a message the user sends waits in the Outbox for a few seconds (the store's `send_delay`) before it
//! goes, and while it waits it can be taken back, into a compose window as it was. Quitting sends what waits.

use std::sync::Mutex;

use pe_i18n::Text;
use pe_store::AccountId;

use crate::worker::{Command, unix_now};
use crate::{Core, Draft, Error, Event, Outgoing, Result, compose};

/// The message the user sent last, while it waits
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Waiting {
    message_id: String,
    subject: String,
    /// When it goes, seconds since the Unix epoch
    until: i64,
    /// Edit > Undo takes it back: nothing was moved, deleted or junked since
    last: bool,
}

pub(crate) type LastSent = Mutex<Option<Waiting>>;

impl Core {
    /// How many seconds a message the user sends waits before it goes, to be taken back
    pub fn send_delay(&self) -> Result<u64> {
        Ok(self.store().send_delay()?)
    }

    pub fn set_send_delay(&self, seconds: u64) -> Result<()> {
        Ok(self.store().set_send_delay(seconds)?)
    }

    /// Sends a message from an account in the background, through the Outbox: after [`Core::send_delay`] seconds,
    /// in which [`Core::undo_send`] takes it back ([`Event::SendWaiting`] says so), or at once without a delay. Then
    /// [`Event::MessageSent`] follows, or [`Event::Failed`] with the message left waiting in the Outbox for the next
    /// Send/Recv. Recipients that are no addresses and attachments that are not there fail right away.
    pub fn send(&self, account: AccountId, mut outgoing: Outgoing) -> Result<()> {
        // a typo in an address is told now, while the message is still open in its window
        compose::check(&outgoing).map_err(Error::Compose)?;
        let delay = self.store().send_delay()? as i64;
        if delay == 0 {
            return self.send_command(
                account,
                Command::Send {
                    outgoing: Box::new(outgoing),
                    not_before: None,
                    undoable: false,
                },
            );
        }
        // its Message-ID now, to find it again in the Outbox: the draft's when it was saved
        let message_id = match outgoing.message_id.as_deref().and_then(compose::draft_id) {
            Some(id) => id,
            None => pe_smtp::message::new_message_id(&self.store().account(account)?.settings.email),
        };
        outgoing.message_id = Some(message_id.clone());
        let subject = outgoing.subject.clone();
        let until = unix_now() + delay;
        self.send_command(
            account,
            Command::Send {
                outgoing: Box::new(outgoing),
                not_before: Some(until),
                undoable: true,
            },
        )?;
        // the last thing done: Edit > Undo takes back this send, not a move before it
        *self.undo.lock().unwrap_or_else(|e| e.into_inner()) = None;
        *self.last_sent.lock().unwrap_or_else(|e| e.into_inner()) = Some(Waiting {
            message_id,
            subject: subject.clone(),
            until,
            last: true,
        });
        self.post(Event::SendWaiting {
            account,
            subject,
            seconds: delay as u64,
        })
    }

    /// Whether Edit > Undo takes back a message sent (Undo Send) rather than a move: the last thing done was sending
    /// it, and it still waits
    pub fn undo_is_send(&self) -> bool {
        let last = self.last_sent.lock().unwrap_or_else(|e| e.into_inner());
        last.as_ref().is_some_and(|w| w.last && w.until > unix_now())
    }

    /// Something was moved, deleted or junked: Edit > Undo takes that back now, the send only its own Undo button
    pub(crate) fn sent_not_last(&self) {
        if let Some(waiting) = self.last_sent.lock().unwrap_or_else(|e| e.into_inner()).as_mut() {
            waiting.last = false;
        }
    }

    /// What the status bar says while the message the user sent last waits, counting down ("Sending “Plans” in 8
    /// seconds"); None once it went or was taken back. The windows ask once a second while it is there.
    pub fn send_waiting_text(&self) -> Option<String> {
        let last = self.last_sent.lock().unwrap_or_else(|e| e.into_inner());
        let waiting = last.as_ref()?;
        let left = waiting.until - unix_now();
        (left > 0).then(|| {
            pe_i18n::tr_args(
                Text::UiSendingIn,
                &[
                    ("subject", (&crate::quoted_subject(&waiting.subject)).into()),
                    ("count", left.into()),
                ],
            )
        })
    }

    /// Takes back the message the user sent last while it waits: out of the Outbox, to open again with its account
    /// as it was, its files written out to be attached again; and what the status bar says, that it was not sent or
    /// that it went already (then without the message)
    pub fn undo_send(&self) -> Result<(Option<(AccountId, Draft)>, String)> {
        let Some(waiting) = self.last_sent.lock().unwrap_or_else(|e| e.into_inner()).take() else {
            return Ok((None, String::new()));
        };
        let subject = crate::quoted_subject(&waiting.subject);
        let Some((account, raw)) = self.store().take_back(&waiting.message_id, unix_now())? else {
            return Ok((
                None,
                pe_i18n::tr_args(Text::UiSendTooLate, &[("subject", (&subject).into())]),
            ));
        };
        let (mut draft, files) = compose::reopen(&raw);
        draft.message_id = Some(waiting.message_id.clone());
        // a folder for the files named by the Message-ID's own letters and digits only
        let name: String = waiting
            .message_id
            .chars()
            .filter(char::is_ascii_alphanumeric)
            .take(40)
            .collect();
        if !files.is_empty() {
            draft.attachments = crate::attachments_out(&format!("unsent-{name}"), files)?;
        }
        self.post(Event::OutboxChanged { account })?;
        let said = pe_i18n::tr_args(Text::UiSendUndone, &[("subject", (&subject).into())]);
        Ok((Some((account, draft)), said))
    }

    /// Quitting: what the user sent and still waits goes now, not at the next start
    pub fn send_waiting_now(&self) -> Result<()> {
        self.last_sent.lock().unwrap_or_else(|e| e.into_inner()).take();
        for account in self.store().send_undoable_now()? {
            self.send_command(account, Command::SendOutbox)?;
        }
        Ok(())
    }
}
