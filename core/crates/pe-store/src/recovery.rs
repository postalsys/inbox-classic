//! The messages being written, kept as they were last saved until their window closes, so that a crash or a power
//! cut loses nothing: what is left here at the next start is opened again.

use std::path::PathBuf;

use rusqlite::params;

use crate::{AccountId, Result, Store};

/// A message being written, as it was last saved: the compose window's fields, as they are written into it again
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Recovery {
    /// The Message-ID of its draft, which names it
    pub message_id: String,
    pub account_id: AccountId,
    pub to: String,
    pub cc: String,
    pub bcc: String,
    pub subject: String,
    /// What was written, as the editor gave it
    pub html: String,
    /// The quoted message, as the core made it, and its plain text when the original was plain text
    pub quote: String,
    pub quote_text: Option<String>,
    pub in_reply_to: Option<String>,
    pub references: Vec<String>,
    /// The files attached, by their paths
    pub attachments: Vec<PathBuf>,
}

/// A list kept a line each
fn lines<T: AsRef<str>>(items: impl IntoIterator<Item = T>) -> String {
    items
        .into_iter()
        .map(|i| i.as_ref().to_string())
        .collect::<Vec<_>>()
        .join("\n")
}

fn unlines(text: String) -> impl Iterator<Item = String> {
    text.lines()
        .filter(|l| !l.is_empty())
        .map(str::to_string)
        .collect::<Vec<_>>()
        .into_iter()
}

impl Store {
    /// Keeps `recovery` in place of the copy kept before under its Message-ID
    pub fn keep_recovery(&self, r: &Recovery) -> Result<()> {
        self.db.execute(
            "INSERT OR REPLACE INTO compose_recovery (message_id, account_id, recipients, subject, html, quote, \
             quote_text, in_reply_to, refs, attachments) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
            params![
                r.message_id,
                r.account_id,
                // To, Cc and Bcc as typed, which have no line breaks
                lines([&r.to, &r.cc, &r.bcc]),
                r.subject,
                r.html,
                r.quote,
                r.quote_text,
                r.in_reply_to,
                lines(&r.references),
                lines(r.attachments.iter().map(|p| p.to_string_lossy())),
            ],
        )?;
        Ok(())
    }

    /// The messages kept, in the order they were last saved
    pub fn recoveries(&self) -> Result<Vec<Recovery>> {
        let mut statement = self.db.prepare(
            "SELECT message_id, account_id, recipients, subject, html, quote, quote_text, in_reply_to, refs, \
             attachments FROM compose_recovery ORDER BY rowid",
        )?;
        let rows = statement.query_map([], |row| {
            let recipients: String = row.get(2)?;
            let mut recipients = recipients.split('\n').map(str::to_string);
            Ok(Recovery {
                message_id: row.get(0)?,
                account_id: row.get(1)?,
                to: recipients.next().unwrap_or_default(),
                cc: recipients.next().unwrap_or_default(),
                bcc: recipients.next().unwrap_or_default(),
                subject: row.get(3)?,
                html: row.get(4)?,
                quote: row.get(5)?,
                quote_text: row.get(6)?,
                in_reply_to: row.get(7)?,
                references: unlines(row.get(8)?).collect(),
                attachments: unlines(row.get(9)?).map(PathBuf::from).collect(),
            })
        })?;
        rows.collect()
    }

    /// Forgets the message kept under `message_id`: its window closed, or it was sent
    pub fn drop_recovery(&self, message_id: &str) -> Result<()> {
        self.db
            .execute("DELETE FROM compose_recovery WHERE message_id = ?1", [message_id])?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::AccountSettings;

    fn kept(store: &Store, account: AccountId, id: &str) -> Recovery {
        let recovery = Recovery {
            message_id: id.into(),
            account_id: account,
            to: "Ann <ann@example.com>, bob@example.com".into(),
            bcc: "boss@example.com".into(),
            subject: format!("About {id}"),
            html: "<p>Text</p>\n<p>more</p>".into(),
            quote: "<blockquote>before</blockquote>".into(),
            quote_text: Some("> before".into()),
            in_reply_to: Some("<0@example.com>".into()),
            references: vec!["<a@example.com>".into(), "<0@example.com>".into()],
            attachments: vec![PathBuf::from("/tmp/a.pdf"), PathBuf::from("/tmp/b c.txt")],
            ..Default::default()
        };
        store.keep_recovery(&recovery).unwrap();
        recovery
    }

    #[test]
    fn keeps_replaces_and_drops() {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let first = kept(&store, account, "<1@example.com>");
        let second = kept(&store, account, "<2@example.com>");
        assert_eq!(store.recoveries().unwrap(), [first.clone(), second.clone()]);
        // saved again: the copy is replaced, not added, and is now the last saved
        let first = kept(&store, account, "<1@example.com>");
        assert_eq!(store.recoveries().unwrap(), [second, first.clone()]);
        store.drop_recovery("<2@example.com>").unwrap();
        assert_eq!(store.recoveries().unwrap(), [first]);
    }

    #[test]
    fn go_with_their_account() {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        kept(&store, account, "<1@example.com>");
        store.remove_account(account).unwrap();
        assert!(store.recoveries().unwrap().is_empty());
    }
}
