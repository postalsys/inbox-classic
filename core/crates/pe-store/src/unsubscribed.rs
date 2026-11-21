//! The mailing lists the user asked to leave, by account, so the bar over a list's messages says so instead of offering
//! Unsubscribe again. A list is its List-Id, else its sender's address. One-click and web requests are noted when they
//! are made; a request by mail is noted when its draft is written and counts once a message to its address left the
//! Outbox, so a draft never sent asks nothing.

use rusqlite::{OptionalExtension, params};

use crate::{AccountId, Result, Store};

/// How a list was asked
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Asked {
    /// The one-click POST (RFC 8058), which the list accepted
    OneClick,
    /// A message to the list's address, sent
    Mail,
    /// The list's page opened in the browser, where the user may or may not have finished
    Web,
}

impl Asked {
    fn code(self) -> i64 {
        match self {
            Asked::OneClick => 1,
            Asked::Mail => 2,
            Asked::Web => 3,
        }
    }

    fn of(code: i64) -> Option<Asked> {
        match code {
            1 => Some(Asked::OneClick),
            2 => Some(Asked::Mail),
            3 => Some(Asked::Web),
            _ => None,
        }
    }
}

impl Store {
    /// Notes that the list `list` of `account` was asked at `at` (seconds since the Unix epoch), replacing an earlier
    /// request
    pub fn note_unsubscribed(&self, account: AccountId, list: &str, asked: Asked, at: i64) -> Result<()> {
        self.db.execute(
            "INSERT OR REPLACE INTO unsubscribed (account_id, list, method, at, mail_to) VALUES (?1, ?2, ?3, ?4, NULL)",
            params![account, list, asked.code(), at],
        )?;
        Ok(())
    }

    /// Notes a request by mail to `address` written for the list `list` of `account`: it counts once a message to that
    /// address leaves the Outbox ([`Store::unsubscribe_mail_sent`]). A request the list was asked by already stays.
    pub fn note_unsubscribe_mail(&self, account: AccountId, list: &str, address: &str) -> Result<()> {
        self.db.execute(
            "INSERT INTO unsubscribed (account_id, list, method, at, mail_to) VALUES (?1, ?2, ?3, NULL, ?4) \
             ON CONFLICT (account_id, list) DO UPDATE SET mail_to = excluded.mail_to",
            params![account, list, Asked::Mail.code(), address.trim().to_ascii_lowercase()],
        )?;
        Ok(())
    }

    /// A message of `account` to `recipients` left the Outbox at `at`: the requests by mail written to one of them now
    /// count. Whether any did.
    pub fn unsubscribe_mail_sent(&self, account: AccountId, recipients: &[String], at: i64) -> Result<bool> {
        let mut changed = 0;
        for recipient in recipients {
            changed += self.db.execute(
                "UPDATE unsubscribed SET method = ?3, at = ?4, mail_to = NULL WHERE account_id = ?1 AND mail_to = ?2",
                params![account, recipient.trim().to_ascii_lowercase(), Asked::Mail.code(), at],
            )?;
        }
        Ok(changed > 0)
    }

    /// When and how the list `list` of `account` was asked; None when it was not, or only by a draft not sent yet
    pub fn unsubscribed(&self, account: AccountId, list: &str) -> Result<Option<(Asked, i64)>> {
        let found: Option<(i64, i64)> = self
            .db
            .query_row(
                "SELECT method, at FROM unsubscribed WHERE account_id = ?1 AND list = ?2 AND at IS NOT NULL",
                params![account, list],
                |row| Ok((row.get(0)?, row.get(1)?)),
            )
            .optional()?;
        Ok(found.and_then(|(method, at)| Asked::of(method).map(|asked| (asked, at))))
    }
}

#[cfg(test)]
mod tests {
    use super::Asked;
    use crate::{AccountSettings, Store};

    fn store_with_account() -> (Store, i64) {
        let store = Store::open_in_memory().unwrap();
        let account = store
            .add_account(&AccountSettings {
                email: "me@example.com".into(),
                ..Default::default()
            })
            .unwrap();
        (store, account)
    }

    #[test]
    fn a_request_is_kept_per_list_and_account_and_replaced() {
        let (store, account) = store_with_account();
        let other = store
            .add_account(&AccountSettings {
                email: "me@example.org".into(),
                ..Default::default()
            })
            .unwrap();
        assert_eq!(store.unsubscribed(account, "news.example.com").unwrap(), None);
        store
            .note_unsubscribed(account, "news.example.com", Asked::Web, 100)
            .unwrap();
        // the list's id is compared without case, as List-Id asks
        assert_eq!(
            store.unsubscribed(account, "NEWS.example.com").unwrap(),
            Some((Asked::Web, 100))
        );
        assert_eq!(
            store.unsubscribed(other, "news.example.com").unwrap(),
            None,
            "another account's"
        );
        store
            .note_unsubscribed(account, "news.example.com", Asked::OneClick, 200)
            .unwrap();
        assert_eq!(
            store.unsubscribed(account, "news.example.com").unwrap(),
            Some((Asked::OneClick, 200))
        );
        store.remove_account(account).unwrap();
        assert_eq!(
            store.unsubscribed(account, "news.example.com").unwrap(),
            None,
            "gone with its account"
        );
    }

    #[test]
    fn a_request_by_mail_counts_once_sent() {
        let (store, account) = store_with_account();
        store
            .note_unsubscribe_mail(account, "news.example.com", "Leave@List.example.com")
            .unwrap();
        assert_eq!(
            store.unsubscribed(account, "news.example.com").unwrap(),
            None,
            "a draft only"
        );
        assert!(
            !store
                .unsubscribe_mail_sent(account, &["someone@example.com".into()], 50)
                .unwrap()
        );
        assert_eq!(store.unsubscribed(account, "news.example.com").unwrap(), None);
        assert!(
            store
                .unsubscribe_mail_sent(account, &["leave@list.example.com".into()], 60)
                .unwrap()
        );
        assert_eq!(
            store.unsubscribed(account, "news.example.com").unwrap(),
            Some((Asked::Mail, 60))
        );
        // sent again later: it was asked already, the date stays
        assert!(
            !store
                .unsubscribe_mail_sent(account, &["leave@list.example.com".into()], 90)
                .unwrap()
        );
        assert_eq!(
            store.unsubscribed(account, "news.example.com").unwrap(),
            Some((Asked::Mail, 60))
        );
    }

    #[test]
    fn a_draft_does_not_undo_a_request_made() {
        let (store, account) = store_with_account();
        store
            .note_unsubscribed(account, "news.example.com", Asked::OneClick, 100)
            .unwrap();
        store
            .note_unsubscribe_mail(account, "news.example.com", "leave@list.example.com")
            .unwrap();
        assert_eq!(
            store.unsubscribed(account, "news.example.com").unwrap(),
            Some((Asked::OneClick, 100))
        );
    }
}
