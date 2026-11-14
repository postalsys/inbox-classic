//! The Outbox: messages waiting to be sent, built as they go over SMTP, with what went wrong the last time. A message
//! leaves it only once the server took it, so a send that fails (offline, refused) does not lose it.

use rusqlite::{OptionalExtension, params};

use crate::{AccountId, Result, Store};

/// A message in the Outbox
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Queued {
    pub id: i64,
    pub account_id: AccountId,
    pub envelope_from: String,
    pub envelope_to: Vec<String>,
    pub subject: String,
    /// For display: the recipients as they read
    pub recipients: String,
    /// Seconds since the Unix epoch
    pub created: i64,
    /// Why the last try did not work, None before the first
    pub problem: Option<String>,
    /// It waits until then before it goes, seconds since the Unix epoch
    pub not_before: Option<i64>,
    /// Its Message-ID, by which Undo Send finds it
    pub message_id: Option<String>,
    /// Sent by the user, waiting for `not_before` so that it can be taken back (Undo Send): sent at once on quitting
    pub undoable: bool,
}

/// Without the message itself, which only sending needs ([`Store::queued_raw`])
const COLUMNS: &str = "id, account_id, envelope_from, envelope_to, subject, recipients, created, problem, not_before, message_id, undoable";

fn from_row(row: &rusqlite::Row) -> rusqlite::Result<Queued> {
    let to: String = row.get(3)?;
    Ok(Queued {
        id: row.get(0)?,
        account_id: row.get(1)?,
        envelope_from: row.get(2)?,
        envelope_to: to.lines().map(str::to_string).collect(),
        subject: row.get(4)?,
        recipients: row.get(5)?,
        created: row.get(6)?,
        problem: row.get(7)?,
        not_before: row.get(8)?,
        message_id: row.get(9)?,
        undoable: row.get(10)?,
    })
}

/// How many seconds a message the user sent waits to be taken back, out of the box
pub const DEFAULT_SEND_DELAY: u64 = 10;
/// and at most
pub const MAX_SEND_DELAY: u64 = 30;
const SEND_DELAY: &str = "send.delay";

impl Store {
    /// How many seconds a message the user sent waits in the Outbox before it goes, to be taken back (Undo Send)
    pub fn send_delay(&self) -> Result<u64> {
        Ok(self
            .text_setting(SEND_DELAY)?
            .and_then(|value| value.parse().ok())
            .unwrap_or(DEFAULT_SEND_DELAY))
    }

    pub fn set_send_delay(&self, seconds: u64) -> Result<()> {
        self.set_text_setting(SEND_DELAY, &seconds.min(MAX_SEND_DELAY).to_string())
    }

    /// Puts a message, built as `raw`, in the Outbox; its id
    pub fn queue(&self, message: &Queued, raw: &[u8]) -> Result<i64> {
        self.db.execute(
            "INSERT INTO outbox (account_id, envelope_from, envelope_to, raw, subject, recipients, created, problem, \
             not_before, message_id, undoable) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
            params![
                message.account_id,
                message.envelope_from,
                message.envelope_to.join("\n"),
                raw,
                message.subject,
                message.recipients,
                message.created,
                message.problem,
                message.not_before,
                message.message_id,
                message.undoable,
            ],
        )?;
        Ok(self.db.last_insert_rowid())
    }

    /// The Outbox, oldest first: of one account, or all when None
    pub fn outbox(&self, account: Option<AccountId>) -> Result<Vec<Queued>> {
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT {COLUMNS} FROM outbox WHERE ?1 IS NULL OR account_id = ?1 ORDER BY id"
        ))?;
        statement.query_map([account], from_row)?.collect()
    }

    pub fn queued(&self, id: i64) -> Result<Option<Queued>> {
        self.db
            .query_row(&format!("SELECT {COLUMNS} FROM outbox WHERE id = ?1"), [id], from_row)
            .optional()
    }

    /// The messages of an account that may go at `now`: those that do not wait for a later time, oldest first
    pub fn outbox_due(&self, account: AccountId, now: i64) -> Result<Vec<Queued>> {
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT {COLUMNS} FROM outbox WHERE account_id = ?1 AND COALESCE(not_before, 0) <= ?2 ORDER BY id"
        ))?;
        statement.query_map(params![account, now], from_row)?.collect()
    }

    /// When the next message of an account that waits for its time may go, None when none waits
    pub fn outbox_next_due(&self, account: AccountId) -> Result<Option<i64>> {
        self.db.query_row(
            "SELECT MIN(not_before) FROM outbox WHERE account_id = ?1 AND not_before IS NOT NULL",
            [account],
            |row| row.get(0),
        )
    }

    /// The messages of an account whose time came no longer wait: they go as any other from now on
    pub fn clear_not_before(&self, account: AccountId, now: i64) -> Result<()> {
        self.db.execute(
            "UPDATE outbox SET not_before = NULL WHERE account_id = ?1 AND not_before <= ?2",
            params![account, now],
        )?;
        Ok(())
    }

    /// Takes back the message with `message_id` that the user sent and that still waits at `now` (Undo Send): out of
    /// the Outbox, its source to write it again, with its account; None once it is going or gone. A message whose time
    /// came is never taken, so one the worker may be sending is not: taking it is one statement, which the worker's own reads
    /// of the Outbox can not come between.
    pub fn take_back(&self, message_id: &str, now: i64) -> Result<Option<(AccountId, Vec<u8>)>> {
        self.db
            .query_row(
                "DELETE FROM outbox WHERE message_id = ?1 AND undoable = 1 AND not_before > ?2 \
                 RETURNING account_id, raw",
                params![message_id, now],
                |row| Ok((row.get(0)?, row.get(1)?)),
            )
            .optional()
    }

    /// The messages the user sent that still wait to be taken back go now (quitting): the accounts they are of
    pub fn send_undoable_now(&self) -> Result<Vec<AccountId>> {
        let mut statement = self
            .db
            .prepare_cached("SELECT DISTINCT account_id FROM outbox WHERE undoable = 1 AND not_before IS NOT NULL")?;
        let accounts = statement
            .query_map([], |row| row.get(0))?
            .collect::<Result<Vec<AccountId>>>()?;
        self.db
            .execute("UPDATE outbox SET not_before = NULL WHERE undoable = 1", [])?;
        Ok(accounts)
    }

    /// The message itself, as it goes over SMTP
    pub fn queued_raw(&self, id: i64) -> Result<Option<Vec<u8>>> {
        self.db
            .query_row("SELECT raw FROM outbox WHERE id = ?1", [id], |row| row.get(0))
            .optional()
    }

    /// How many messages wait, of one account or all when None
    pub fn outbox_count(&self, account: Option<AccountId>) -> Result<usize> {
        let count: i64 = self.db.query_row(
            "SELECT COUNT(*) FROM outbox WHERE ?1 IS NULL OR account_id = ?1",
            [account],
            |row| row.get(0),
        )?;
        Ok(count as usize)
    }

    /// The accounts that have something in the Outbox
    pub fn outbox_accounts(&self) -> Result<Vec<AccountId>> {
        let mut statement = self
            .db
            .prepare_cached("SELECT DISTINCT account_id FROM outbox ORDER BY account_id")?;
        statement.query_map([], |row| row.get(0))?.collect()
    }

    /// Takes a message out of the Outbox (sent, or deleted by the user); false when it was not there
    pub fn unqueue(&self, id: i64) -> Result<bool> {
        Ok(self.db.execute("DELETE FROM outbox WHERE id = ?1", [id])? > 0)
    }

    /// Notes why a message was not sent
    pub fn set_problem(&self, id: i64, problem: &str) -> Result<()> {
        self.db
            .execute("UPDATE outbox SET problem = ?2 WHERE id = ?1", params![id, problem])?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::AccountSettings;

    fn queued(account: AccountId, subject: &str) -> Queued {
        Queued {
            id: 0,
            account_id: account,
            envelope_from: "a@example.com".into(),
            envelope_to: vec!["b@example.com".into(), "c@example.com".into()],
            subject: subject.into(),
            recipients: "Bob, c@example.com".into(),
            created: 1_700_000_000,
            not_before: None,
            problem: None,
            message_id: None,
            undoable: false,
        }
    }

    #[test]
    fn keeps_messages_until_they_are_sent() {
        let store = Store::open_in_memory().unwrap();
        let first = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let second = store.add_account(&AccountSettings::example("z@example.com")).unwrap();
        let one = store
            .queue(&queued(first, "One"), b"Subject: One\r\n\r\nx\r\n")
            .unwrap();
        let two = store
            .queue(&queued(second, "Two"), b"Subject: Two\r\n\r\nx\r\n")
            .unwrap();
        assert_eq!(store.outbox_count(None).unwrap(), 2);
        assert_eq!(store.outbox_count(Some(second)).unwrap(), 1);
        assert_eq!(store.outbox_accounts().unwrap(), [first, second]);
        assert_eq!(store.outbox(None).unwrap().len(), 2);
        let mine = store.outbox(Some(first)).unwrap();
        assert_eq!(mine.len(), 1);
        assert_eq!(mine[0].envelope_to, ["b@example.com", "c@example.com"]);
        assert_eq!(store.queued_raw(one).unwrap().unwrap(), b"Subject: One\r\n\r\nx\r\n");

        store.set_problem(one, "the server did not answer").unwrap();
        assert_eq!(
            store.queued(one).unwrap().unwrap().problem.as_deref(),
            Some("the server did not answer")
        );
        assert!(store.unqueue(one).unwrap());
        assert!(!store.unqueue(one).unwrap());
        // an account that goes takes its queue along
        store.remove_account(second).unwrap();
        assert!(store.queued(two).unwrap().is_none());
        assert!(store.outbox(None).unwrap().is_empty());
    }

    #[test]
    fn a_message_can_wait_for_its_time() {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        store.queue(&queued(account, "now"), b"raw").unwrap();
        let later = store
            .queue(
                &Queued {
                    not_before: Some(1_000),
                    ..queued(account, "later")
                },
                b"raw",
            )
            .unwrap();
        assert_eq!(store.outbox_next_due(account).unwrap(), Some(1_000));
        let subjects = |now| {
            store
                .outbox_due(account, now)
                .unwrap()
                .into_iter()
                .map(|q| q.subject)
                .collect::<Vec<_>>()
        };
        assert_eq!(subjects(999), ["now"]);
        assert_eq!(subjects(1_000), ["now", "later"]);
        assert_eq!(store.queued(later).unwrap().unwrap().not_before, Some(1_000));
        store.unqueue(later).unwrap();
        assert_eq!(store.outbox_next_due(account).unwrap(), None);
    }

    #[test]
    fn a_message_sent_can_be_taken_back_while_it_waits() {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let waiting = |subject: &str, id: &str, undoable| Queued {
            not_before: Some(1_000),
            message_id: Some(id.into()),
            undoable,
            ..queued(account, subject)
        };
        store.queue(&waiting("mine", "<1@x>", true), b"mine").unwrap();
        store.queue(&waiting("agent", "<2@x>", false), b"agent").unwrap();
        // an agent's message is not the user's to take back this way
        assert_eq!(store.take_back("<2@x>", 990).unwrap(), None);
        // its time came: it may be going
        assert_eq!(store.take_back("<1@x>", 1_000).unwrap(), None);
        assert_eq!(
            store.take_back("<1@x>", 999).unwrap(),
            Some((account, b"mine".to_vec()))
        );
        assert_eq!(store.take_back("<1@x>", 999).unwrap(), None);
        assert_eq!(store.outbox_count(None).unwrap(), 1);
    }

    #[test]
    fn the_wait_is_ten_seconds_until_set() {
        let store = Store::open_in_memory().unwrap();
        assert_eq!(store.send_delay().unwrap(), DEFAULT_SEND_DELAY);
        store.set_send_delay(0).unwrap();
        assert_eq!(store.send_delay().unwrap(), 0);
        store.set_send_delay(600).unwrap();
        assert_eq!(store.send_delay().unwrap(), MAX_SEND_DELAY);
    }

    #[test]
    fn quitting_sends_what_the_user_sent_and_keeps_the_agents_wait() {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let mine = store
            .queue(
                &Queued {
                    not_before: Some(1_000),
                    undoable: true,
                    ..queued(account, "mine")
                },
                b"raw",
            )
            .unwrap();
        let agent = store
            .queue(
                &Queued {
                    not_before: Some(1_000),
                    ..queued(account, "agent")
                },
                b"raw",
            )
            .unwrap();
        assert_eq!(store.send_undoable_now().unwrap(), [account]);
        assert_eq!(store.queued(mine).unwrap().unwrap().not_before, None);
        assert_eq!(store.queued(agent).unwrap().unwrap().not_before, Some(1_000));
        assert!(store.send_undoable_now().unwrap().is_empty());
    }
}
