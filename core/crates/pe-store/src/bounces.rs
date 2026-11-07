//! Bounces: the list's mark of a delivery failure or delay notice, and the message a bounce returns, found in the
//! account it came to

use rusqlite::{OptionalExtension, params};

use crate::{AccountId, FolderId, MessageRef, Result, Store};

/// The message of an account (?1) with a Message-ID (?2), through its conversation, which every message has a key of
/// from when it is stored: the folders of the account, each on its conversation index. Sent Items first, the newest
/// copy of a folder.
const FIND_MESSAGE_ID: &str = "SELECT m.folder_id, m.uid FROM thread_ids t \
     JOIN folders f ON f.account_id = t.account_id \
     JOIN messages m ON m.folder_id = f.id AND m.thread_id = t.thread_id \
     WHERE t.account_id = ?1 AND t.key = ?2 AND m.message_id = ?2 \
     ORDER BY f.special_use IS NOT '\\Sent', m.uid DESC LIMIT 1";

impl Store {
    /// Marks a message as a bounce; false when it already was one, or there is no such message
    pub fn mark_bounce(&self, folder: FolderId, uid: u64) -> Result<bool> {
        let changed = self.db.execute(
            "UPDATE messages SET bounce = 1 WHERE folder_id = ?1 AND uid = ?2 AND bounce = 0",
            params![folder, uid],
        )?;
        Ok(changed > 0)
    }

    /// The message of `account` with `message_id` (`<id@host>`), Sent Items first, the newest copy of a folder; None
    /// when the store has none
    pub fn find_message_id(&self, account: AccountId, message_id: &str) -> Result<Option<MessageRef>> {
        let id = message_id.trim();
        if id.len() <= 2 {
            return Ok(None);
        }
        let found = self
            .db
            .prepare_cached(FIND_MESSAGE_ID)?
            .query_row(params![account, id], |row| {
                Ok(MessageRef {
                    folder: row.get(0)?,
                    uid: row.get(1)?,
                })
            })
            .optional()?;
        if found.is_some() {
            return Ok(found);
        }
        // one stored before conversations and not threaded yet: Sent Items, where a bounced message is
        let Some(sent) = self.special_folder(account, "\\Sent")? else {
            return Ok(None);
        };
        Ok(self
            .uid_of_message_id(sent.id, id)?
            .map(|uid| MessageRef { folder: sent.id, uid }))
    }
}

#[cfg(test)]
mod tests {
    use crate::{AccountSettings, FolderInfo, MessageInfo, Search, Sort, Store};

    fn store() -> (Store, i64, i64, i64) {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let folder = |path: &str, special_use: Option<&str>| FolderInfo {
            path: path.into(),
            name: path.into(),
            special_use: special_use.map(str::to_string),
            selectable: true,
            ..Default::default()
        };
        store
            .set_folders(account, &[folder("INBOX", None), folder("Sent", Some("\\Sent"))])
            .unwrap();
        let folders = store.folders(account).unwrap();
        (store, account, folders[0].id, folders[1].id)
    }

    fn message(uid: u64, id: &str) -> MessageInfo {
        MessageInfo {
            uid,
            subject: format!("message {uid}"),
            message_id: Some(id.into()),
            ..Default::default()
        }
    }

    #[test]
    fn marks_bounces_and_searches_them() {
        let (store, _, inbox, _) = store();
        let mut report = message(2, "<r@example.com>");
        report.bounce = true;
        store
            .add_messages(
                inbox,
                &[message(1, "<a@example.com>"), report, message(3, "<c@example.com>")],
            )
            .unwrap();
        let found = |text: &str| -> Vec<u64> {
            let search = Search {
                text: text.into(),
                ..Search::folder(inbox)
            };
            let mut uids: Vec<u64> = store
                .search(&search, Sort::default(), 0, 10)
                .unwrap()
                .into_iter()
                .map(|m| m.info.uid)
                .collect();
            uids.sort();
            uids
        };
        assert_eq!(found("is:bounce"), [2]);
        assert!(store.mark_bounce(inbox, 3).unwrap());
        // once: a second mark changes nothing, and an unknown message is none
        assert!(!store.mark_bounce(inbox, 3).unwrap());
        assert!(!store.mark_bounce(inbox, 99).unwrap());
        assert!(store.message(inbox, 3).unwrap().unwrap().info.bounce);
        assert_eq!(found("is:bounce"), [2, 3]);
        assert_eq!(found("-is:bounce"), [1]);
        // a summary synced again keeps the mark the core gave it
        store.add_messages(inbox, &[message(3, "<c@example.com>")]).unwrap();
        assert!(store.message(inbox, 3).unwrap().unwrap().info.bounce);
    }

    #[test]
    fn finds_the_message_a_bounce_returns() {
        let (store, account, inbox, sent) = store();
        store
            .add_messages(
                inbox,
                &[message(5, "<same@example.com>"), message(6, "<inbox@example.com>")],
            )
            .unwrap();
        store
            .add_messages(
                sent,
                &[message(1, "<same@example.com>"), message(2, "<other@example.com>")],
            )
            .unwrap();
        let at = |folder, uid| Some(crate::MessageRef { folder, uid });
        // Sent Items first, also when another folder has a copy
        assert_eq!(
            store.find_message_id(account, "<same@example.com>").unwrap(),
            at(sent, 1)
        );
        assert_eq!(
            store.find_message_id(account, " <inbox@example.com> ").unwrap(),
            at(inbox, 6)
        );
        assert_eq!(store.find_message_id(account, "<none@example.com>").unwrap(), None);
        assert_eq!(store.find_message_id(account, "").unwrap(), None);
        // another account's message is not this one's
        assert_eq!(store.find_message_id(account + 1, "<same@example.com>").unwrap(), None);

        // stored before conversations: found in Sent Items all the same
        store.db.execute("DELETE FROM thread_ids", []).unwrap();
        assert_eq!(
            store.find_message_id(account, "<other@example.com>").unwrap(),
            at(sent, 2)
        );
        assert_eq!(store.find_message_id(account, "<inbox@example.com>").unwrap(), None);
    }

    #[test]
    fn the_lookup_uses_the_indexes() {
        let (store, ..) = store();
        let plan: Vec<String> = store
            .db
            .prepare(&format!("EXPLAIN QUERY PLAN {}", super::FIND_MESSAGE_ID))
            .unwrap()
            .query_map(rusqlite::params![1, "x"], |row| row.get::<_, String>(3))
            .unwrap()
            .map(Result::unwrap)
            .collect();
        let plan = plan.join("; ");
        assert!(!plan.contains("SCAN m") && !plan.contains("SCAN messages"), "{plan}");
    }
}
