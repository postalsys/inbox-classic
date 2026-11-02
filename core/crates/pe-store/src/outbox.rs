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
}

/// Without the message itself, which only sending needs ([`Store::queued_raw`])
const COLUMNS: &str = "id, account_id, envelope_from, envelope_to, subject, recipients, created, problem";

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
    })
}

impl Store {
    /// Puts a message, built as `raw`, in the Outbox; its id
    pub fn queue(&self, message: &Queued, raw: &[u8]) -> Result<i64> {
        self.db.execute(
            "INSERT INTO outbox (account_id, envelope_from, envelope_to, raw, subject, recipients, created, problem) \
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
            params![
                message.account_id,
                message.envelope_from,
                message.envelope_to.join("\n"),
                raw,
                message.subject,
                message.recipients,
                message.created,
                message.problem,
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
            problem: None,
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
}
