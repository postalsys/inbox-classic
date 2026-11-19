//! The answers the user sent to calendar invitations: noted when the reply is put in the Outbox, and the user's
//! status of the event only once it left it, so a reply taken back from the Outbox never changes it.

use rusqlite::params;

use crate::{AccountId, Result, Store};

impl Store {
    /// Notes a reply to the event `event_uid` of `account` with `partstat` (accepted, tentative, declined), waiting in
    /// the Outbox as the message with `message_id`
    pub fn note_invitation_reply(
        &self,
        account: AccountId,
        event_uid: &str,
        partstat: &str,
        message_id: &str,
    ) -> Result<()> {
        self.db.execute(
            "INSERT INTO invitation_replies (account_id, event_uid, partstat, message_id) VALUES (?1, ?2, ?3, ?4)",
            params![account, event_uid, partstat, message_id],
        )?;
        Ok(())
    }

    /// The message with `message_id` left the Outbox at `at`: a reply to an invitation it is now counts
    pub fn invitation_reply_sent(&self, message_id: &str, at: i64) -> Result<()> {
        self.db.execute(
            "UPDATE invitation_replies SET sent_at = ?2 WHERE message_id = ?1 AND sent_at IS NULL",
            params![message_id, at],
        )?;
        Ok(())
    }

    /// The user's status of each event of `account` they answered, by its UID: the last reply that went
    pub fn invitation_replies(&self, account: AccountId) -> Result<Vec<(String, String)>> {
        let mut statement = self.db.prepare_cached(
            "SELECT event_uid, partstat FROM invitation_replies r WHERE account_id = ?1 AND sent_at IS NOT NULL \
             AND id = (SELECT MAX(id) FROM invitation_replies WHERE account_id = r.account_id \
             AND event_uid = r.event_uid AND sent_at IS NOT NULL)",
        )?;
        statement
            .query_map([account], |row| Ok((row.get(0)?, row.get(1)?)))?
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use crate::{AccountSettings, Store};

    #[test]
    fn a_status_counts_once_the_reply_went() {
        let store = Store::open_in_memory().unwrap();
        let account = store
            .add_account(&AccountSettings {
                email: "me@example.com".into(),
                ..Default::default()
            })
            .unwrap();
        store
            .note_invitation_reply(account, "e1@example.com", "accepted", "<r1@example.com>")
            .unwrap();
        assert!(store.invitation_replies(account).unwrap().is_empty());
        store.invitation_reply_sent("<r1@example.com>", 10).unwrap();
        assert_eq!(
            store.invitation_replies(account).unwrap(),
            [("e1@example.com".to_string(), "accepted".to_string())]
        );
        // the last reply that went is the status; one still waiting is not
        store
            .note_invitation_reply(account, "e1@example.com", "declined", "<r2@example.com>")
            .unwrap();
        store
            .note_invitation_reply(account, "e1@example.com", "tentative", "<r3@example.com>")
            .unwrap();
        store.invitation_reply_sent("<r2@example.com>", 20).unwrap();
        assert_eq!(store.invitation_replies(account).unwrap()[0].1, "declined");
    }
}
