//! The messages of a folder: what the message list shows, the flags, and the cached sources

use rusqlite::{OptionalExtension, Row, params};

use crate::{AccountId, FolderId, Result, Store};

/// A message as the message list shows it, from ENVELOPE, FLAGS, INTERNALDATE, RFC822.SIZE and
/// BODYSTRUCTURE
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct MessageInfo {
    pub uid: u64,
    pub modseq: Option<u64>,
    /// As the store keeps them: sorted, without `\Recent`
    pub flags: Vec<String>,
    /// When the server got the message, seconds since the Unix epoch
    pub internal_date: Option<i64>,
    /// The Date header, seconds since the Unix epoch
    pub date: Option<i64>,
    pub size: Option<u64>,
    pub subject: String,
    pub from_name: String,
    pub from_address: String,
    /// The To recipients as the list shows them, `Andris, b@example.com`
    pub recipients: String,
    pub message_id: Option<String>,
    pub in_reply_to: Option<String>,
    pub has_attachments: bool,
    /// Everyone the message names, decoded, for the search: names and addresses of From, Sender and Reply-To, and of
    /// To, Cc and Bcc; empty when only the list's own fields are known
    pub sender_people: String,
    pub recipient_people: String,
    /// The names of its files, one per line, and how many there are
    pub attachment_names: String,
    pub attachment_count: u32,
    /// To, Cc and Bcc as names and addresses, decoded, for the address book ([`crate::contacts`]); not kept with the
    /// message, so empty for one read from the store
    pub correspondents: Vec<(String, String)>,
    /// The Message-IDs its References header names, oldest first, at most [`crate::threads::MAX_REFERENCES`]
    pub references: Vec<String>,
    /// Gmail's conversation id (X-GM-THRID), which decides the conversation on Gmail; not kept with the message
    pub gmail_thread: Option<u64>,
    /// The conversation it is in, below 0 until threaded (read from the store; not written by `add_messages`)
    pub thread_id: Option<i64>,
}

/// The colour of a flag, as Apple Mail keeps it: `\\Flagged` with three keyword bits, `$MailFlagBit0` to
/// `$MailFlagBit2`, none of them for red. Other mail programs see a flag; Apple Mail and this one see its colour.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
#[repr(u8)]
pub enum FlagColor {
    Red = 1,
    Orange = 2,
    Yellow = 3,
    Green = 4,
    Blue = 5,
    Purple = 6,
    Gray = 7,
}

/// The keyword bits of a flag's colour, bit 0 first
pub const FLAG_COLOR_BITS: [&str; 3] = ["$MailFlagBit0", "$MailFlagBit1", "$MailFlagBit2"];

impl FlagColor {
    pub const ALL: [FlagColor; 7] = [
        FlagColor::Red,
        FlagColor::Orange,
        FlagColor::Yellow,
        FlagColor::Green,
        FlagColor::Blue,
        FlagColor::Purple,
        FlagColor::Gray,
    ];

    /// Its keyword bits: red none, orange bit 0, yellow bit 1, green 0 and 1, blue 2, purple 0 and 2, gray 1 and 2
    pub fn bits(self) -> u8 {
        self as u8 - 1
    }

    /// The one numbered as C names it (1 red to 7 gray)
    pub fn from_number(number: u8) -> Option<FlagColor> {
        FlagColor::ALL.get(usize::from(number).checked_sub(1)?).copied()
    }

    /// The colour of a message with `flags`; None when it is not flagged. All three bits (which Apple Mail does not
    /// set) read as red.
    pub fn of(flags: &[String]) -> Option<FlagColor> {
        let has = |flag: &str| flags.iter().any(|f| f.eq_ignore_ascii_case(flag));
        if !has("\\Flagged") {
            return None;
        }
        let bits = FLAG_COLOR_BITS
            .iter()
            .enumerate()
            .fold(0u8, |bits, (i, bit)| if has(bit) { bits | 1 << i } else { bits });
        Some(FlagColor::ALL.get(usize::from(bits)).copied().unwrap_or(FlagColor::Red))
    }
}

impl MessageInfo {
    pub fn has_flag(&self, flag: &str) -> bool {
        self.flags.iter().any(|f| f.eq_ignore_ascii_case(flag))
    }

    /// The colour of its flag, None when it is not flagged
    pub fn flag_color(&self) -> Option<FlagColor> {
        FlagColor::of(&self.flags)
    }

    pub fn seen(&self) -> bool {
        self.has_flag("\\Seen")
    }

    pub fn flagged(&self) -> bool {
        self.has_flag("\\Flagged")
    }

    pub fn answered(&self) -> bool {
        self.has_flag("\\Answered")
    }

    pub fn deleted(&self) -> bool {
        self.has_flag("\\Deleted")
    }

    /// The sender as the list shows it: the name, the address when there is none (the From
    /// order sorts the same way)
    pub fn sender(&self) -> &str {
        if self.from_name.is_empty() {
            &self.from_address
        } else {
            &self.from_name
        }
    }

    /// The date the list shows: the Date header, the received date when there is none (the
    /// Date order sorts the same way)
    pub fn display_date(&self) -> Option<i64> {
        self.date.or(self.internal_date)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Message {
    pub id: i64,
    pub folder_id: FolderId,
    pub info: MessageInfo,
    /// Whether the source is cached
    pub cached: bool,
    /// Its row's place in a list grouped by conversation; None in a list of one row a message
    pub thread: Option<crate::ThreadPlace>,
}

impl Message {
    /// Whether its row is bold: it is unread, or it is a collapsed conversation's row and one of its messages is
    pub fn bold(&self) -> bool {
        !self.info.seen() || self.thread.is_some_and(|t| t.collapsed() && t.unread > 0)
    }

    /// Where it is
    pub fn at(&self) -> crate::MessageRef {
        crate::MessageRef {
            folder: self.folder_id,
            uid: self.info.uid,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum SortField {
    /// The Date header, the received date when there is none
    #[default]
    Date,
    Received,
    From,
    /// The recipients, as Sent Items and Drafts list them: the core turns a From sort into this one there. No index:
    /// those folders are small, and one would cost a write for every message of every folder.
    To,
    Subject,
    Size,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Sort {
    pub field: SortField,
    pub ascending: bool,
}

impl Sort {
    /// The ORDER BY, each matching an index of the schema
    pub(crate) fn order_by(self) -> String {
        let column = match self.field {
            SortField::Date => "COALESCE(date, internal_date)",
            SortField::Received => "internal_date",
            SortField::From => "(CASE from_name WHEN '' THEN from_address ELSE from_name END) COLLATE NOCASE",
            SortField::To => "recipients COLLATE NOCASE",
            SortField::Subject => "subject COLLATE NOCASE",
            SortField::Size => "size",
        };
        let direction = if self.ascending { "ASC" } else { "DESC" };
        // the id last: the same UID in two folders has one order across folders too (an index ends with the rowid, so
        // the indexes still serve the order)
        format!("{column} {direction}, uid {direction}, id {direction}")
    }
}

/// Flags as the store keeps them: sorted and once each, so the same flags in another order are no
/// change, and without `\Recent`, which differs from one connection to the next
fn canonical_flags(flags: &[String]) -> String {
    let mut kept: Vec<&str> = flags
        .iter()
        .map(String::as_str)
        .filter(|f| !f.is_empty() && !f.eq_ignore_ascii_case("\\Recent"))
        .collect();
    kept.sort_unstable();
    kept.dedup();
    kept.join(" ")
}

pub(crate) fn split_flags(flags: &str) -> Vec<String> {
    flags.split(' ').filter(|f| !f.is_empty()).map(str::to_string).collect()
}

fn is_seen(canonical: &str) -> bool {
    canonical.split(' ').any(|f| f.eq_ignore_ascii_case("\\Seen"))
}

pub(crate) const COLUMNS: &str = "id, folder_id, uid, modseq, flags, internal_date, date, size, subject, from_name, \
     from_address, recipients, message_id, in_reply_to, has_attachments, \
     EXISTS (SELECT 1 FROM bodies b WHERE b.message_id = messages.id), sender_people, recipient_people, \
     attachment_names, attachment_count, refs, thread_id";

pub(crate) fn from_row(row: &Row) -> rusqlite::Result<Message> {
    Ok(Message {
        id: row.get(0)?,
        folder_id: row.get(1)?,
        cached: row.get(15)?,
        thread: None,
        info: MessageInfo {
            uid: row.get(2)?,
            modseq: row.get(3)?,
            flags: split_flags(&row.get::<_, String>(4)?),
            internal_date: row.get(5)?,
            date: row.get(6)?,
            size: row.get(7)?,
            subject: row.get(8)?,
            from_name: row.get(9)?,
            from_address: row.get(10)?,
            recipients: row.get(11)?,
            message_id: row.get(12)?,
            in_reply_to: row.get(13)?,
            has_attachments: row.get(14)?,
            sender_people: row.get(16)?,
            recipient_people: row.get(17)?,
            attachment_names: row.get(18)?,
            attachment_count: row.get(19)?,
            correspondents: Vec::new(),
            references: crate::threads::split_references(&row.get::<_, Option<String>>(20)?.unwrap_or_default()),
            gmail_thread: None,
            thread_id: row.get(21)?,
        },
    })
}

impl Store {
    /// Adds messages to a folder. For a UID it has, only the flags are updated: within one
    /// UIDVALIDITY the rest of a message never changes.
    pub fn add_messages(&self, folder: FolderId, messages: &[MessageInfo]) -> Result<()> {
        // the people of the messages new to the store go in the address book, before they are in the store
        self.note_correspondents(folder, messages)?;
        let account: AccountId =
            self.db
                .query_row("SELECT account_id FROM folders WHERE id = ?1", [folder], |row| {
                    row.get(0)
                })?;
        let mut known = self
            .db
            .prepare_cached("SELECT 1 FROM messages WHERE folder_id = ?1 AND uid = ?2")?;
        let mut statement = self.db.prepare_cached(
            "INSERT INTO messages (folder_id, uid, modseq, flags, seen, internal_date, date, size, subject, from_name, \
             from_address, recipients, message_id, in_reply_to, has_attachments, sender_people, recipient_people, \
             attachment_names, attachment_count, refs) \
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17, ?18, ?19, ?20) \
             ON CONFLICT (folder_id, uid) DO UPDATE SET modseq = excluded.modseq, flags = excluded.flags, \
             seen = excluded.seen",
        )?;
        let mut threaded = self
            .db
            .prepare_cached("UPDATE messages SET thread_id = ?3 WHERE folder_id = ?1 AND uid = ?2")?;
        for m in messages {
            let new = !known.exists(params![folder, m.uid])?;
            let flags = canonical_flags(&m.flags);
            statement.execute(params![
                folder,
                m.uid,
                m.modseq,
                flags,
                is_seen(&flags),
                m.internal_date,
                m.date,
                m.size,
                m.subject,
                m.from_name,
                m.from_address,
                m.recipients,
                m.message_id,
                m.in_reply_to,
                m.has_attachments,
                m.sender_people,
                m.recipient_people,
                m.attachment_names,
                m.attachment_count,
                m.references.join(" ")
            ])?;
            // a message new to the store goes into its conversation at once (one already here keeps its own)
            if new {
                let thread = self.thread_of(account, &crate::threads::thread_keys(m))?;
                threaded.execute(params![folder, m.uid, thread])?;
            }
        }
        Ok(())
    }

    /// Sets the flags of a message; false when they were already these, or the folder has no
    /// message with this UID
    pub fn set_flags(&self, folder: FolderId, uid: u64, flags: &[String], modseq: Option<u64>) -> Result<bool> {
        let mut statement = self.db.prepare_cached(
            "UPDATE messages SET flags = ?3, seen = ?4, modseq = COALESCE(?5, modseq) \
             WHERE folder_id = ?1 AND uid = ?2 AND flags != ?3",
        )?;
        let flags = canonical_flags(flags);
        let changed = statement.execute(params![folder, uid, flags, is_seen(&flags), modseq])?;
        Ok(changed > 0)
    }

    /// Sets or clears one flag of a message; false when it already was so, or there is no such
    /// message
    pub fn set_flag(&self, folder: FolderId, uid: u64, flag: &str, on: bool) -> Result<bool> {
        // the write lock first: a transaction that read and then writes can not wait for another connection's write
        // (the workers write in the background), it would fail at once with "database is locked"
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let Some(message) = self.message(folder, uid)? else {
            return Ok(false);
        };
        let mut flags = message.info.flags;
        flags.retain(|f| !f.eq_ignore_ascii_case(flag));
        if on {
            flags.push(flag.to_string());
        }
        let changed = self.set_flags(folder, uid, &flags, None)?;
        tx.commit()?;
        Ok(changed)
    }

    /// Sets or clears one flag of messages of a folder in one transaction; the UIDs whose flags changed. Refused
    /// (`QueryReturnedNoRows`) when one of them is not there, and then none changes.
    pub fn set_flag_many(&self, folder: FolderId, uids: &[u64], flag: &str, on: bool) -> Result<Vec<u64>> {
        if on {
            self.change_flags_many(folder, uids, &[flag], &[])
        } else {
            self.change_flags_many(folder, uids, &[], &[flag])
        }
    }

    /// Adds the flags `add` to messages of a folder and takes `remove` away, in one transaction; the UIDs of those
    /// that changed. Refused when one of them is not there.
    pub fn change_flags_many(&self, folder: FolderId, uids: &[u64], add: &[&str], remove: &[&str]) -> Result<Vec<u64>> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let mut changed = Vec::new();
        for &uid in uids {
            let message = self.message(folder, uid)?.ok_or(rusqlite::Error::QueryReturnedNoRows)?;
            let mut flags = message.info.flags;
            flags.retain(|f| !add.iter().chain(remove).any(|x| f.eq_ignore_ascii_case(x)));
            flags.extend(add.iter().map(|f| f.to_string()));
            if self.set_flags(folder, uid, &flags, None)? {
                changed.push(uid);
            }
        }
        tx.commit()?;
        Ok(changed)
    }

    /// How many messages are unread in the Inboxes of all accounts, for the tray and the taskbar
    pub fn inbox_unread(&self) -> Result<u64> {
        self.db.query_row(
            &format!(
                "SELECT COUNT(*) FROM messages WHERE folder_id IN ({}) AND seen = 0",
                crate::search::INBOXES
            ),
            [],
            |row| row.get(0),
        )
    }

    /// The unread messages of a folder from UID `uid` on, the newest first
    pub fn unseen_from(&self, folder: FolderId, uid: u64) -> Result<Vec<Message>> {
        self.db
            .prepare_cached(&format!(
                "SELECT {COLUMNS} FROM messages WHERE folder_id = ?1 AND uid >= ?2 AND seen = 0 ORDER BY uid DESC"
            ))?
            .query_map(params![folder, uid], from_row)?
            .collect()
    }

    /// Marks every unread message of a folder read; their UIDs, for the server
    pub fn mark_all_seen(&self, folder: FolderId) -> Result<Vec<u64>> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let unread: Vec<(u64, String)> = self
            .db
            .prepare_cached("SELECT uid, flags FROM messages WHERE folder_id = ?1 AND seen = 0 ORDER BY uid")?
            .query_map(params![folder], |row| Ok((row.get(0)?, row.get(1)?)))?
            .collect::<rusqlite::Result<_>>()?;
        for (uid, flags) in &unread {
            let mut flags = split_flags(flags);
            flags.push("\\Seen".into());
            self.set_flags(folder, *uid, &flags, None)?;
        }
        tx.commit()?;
        Ok(unread.into_iter().map(|(uid, _)| uid).collect())
    }

    /// Whether the source of a message is cached
    pub fn has_source(&self, folder: FolderId, uid: u64) -> Result<bool> {
        self.db.query_row(
            "SELECT EXISTS (SELECT 1 FROM bodies b JOIN messages m ON m.id = b.message_id \
             WHERE m.folder_id = ?1 AND m.uid = ?2)",
            params![folder, uid],
            |row| row.get(0),
        )
    }

    /// Removes messages by UID, with their cached sources; returns how many there were
    pub fn remove_messages(&self, folder: FolderId, uids: &[u64]) -> Result<usize> {
        let mut statement = self
            .db
            .prepare_cached("DELETE FROM messages WHERE folder_id = ?1 AND uid = ?2")?;
        let mut removed = 0;
        for uid in uids {
            removed += statement.execute(params![folder, uid])?;
        }
        Ok(removed)
    }

    /// The UIDs of the cached messages of a folder, ascending
    pub fn uids(&self, folder: FolderId) -> Result<Vec<u64>> {
        let mut statement = self
            .db
            .prepare_cached("SELECT uid FROM messages WHERE folder_id = ?1 ORDER BY uid")?;
        statement.query_map([folder], |row| row.get(0))?.collect()
    }

    /// The highest cached UID of a folder
    pub fn max_uid(&self, folder: FolderId) -> Result<Option<u64>> {
        self.db
            .query_row("SELECT MAX(uid) FROM messages WHERE folder_id = ?1", [folder], |row| {
                row.get(0)
            })
    }

    /// A page of the message list
    pub fn messages(&self, folder: FolderId, sort: Sort, offset: u64, limit: u64) -> Result<Vec<Message>> {
        self.search(&crate::Search::folder(folder), sort, offset, limit)
    }

    /// Where a message is in the message list in this order, None when the folder does not have it
    pub fn message_index(&self, folder: FolderId, sort: Sort, uid: u64) -> Result<Option<u64>> {
        self.search_index(&crate::Search::folder(folder), sort, folder, uid)
    }

    pub fn message(&self, folder: FolderId, uid: u64) -> Result<Option<Message>> {
        self.db
            .query_row(
                &format!("SELECT {COLUMNS} FROM messages WHERE folder_id = ?1 AND uid = ?2"),
                params![folder, uid],
                from_row,
            )
            .optional()
    }

    /// Caches the source of a message; false when the folder has no message with this UID
    pub fn set_source(&self, folder: FolderId, uid: u64, source: &[u8]) -> Result<bool> {
        let changed = self.db.execute(
            "INSERT OR REPLACE INTO bodies (message_id, source) \
             SELECT id, ?3 FROM messages WHERE folder_id = ?1 AND uid = ?2",
            params![folder, uid, source],
        )?;
        Ok(changed > 0)
    }

    /// The cached source of a message
    /// At most the first `limit` bytes of the source, without reading the rest (attachments and all)
    pub fn source_start(&self, folder: FolderId, uid: u64, limit: usize) -> Result<Option<Vec<u8>>> {
        self.db
            .query_row(
                "SELECT substr(b.source, 1, ?3) FROM bodies b JOIN messages m ON m.id = b.message_id \
                 WHERE m.folder_id = ?1 AND m.uid = ?2",
                params![folder, uid, limit as i64],
                |row| row.get(0),
            )
            .optional()
    }

    pub fn source(&self, folder: FolderId, uid: u64) -> Result<Option<Vec<u8>>> {
        self.db
            .query_row(
                "SELECT b.source FROM bodies b JOIN messages m ON m.id = b.message_id WHERE m.folder_id = ?1 AND m.uid = ?2",
                params![folder, uid],
                |row| row.get(0),
            )
            .optional()
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn flag_colors_as_apple_mail_keeps_them() {
        let flags = |list: &[&str]| list.iter().map(|f| f.to_string()).collect::<Vec<_>>();
        assert_eq!(FlagColor::of(&flags(&["$MailFlagBit0"])), None);
        assert_eq!(FlagColor::of(&flags(&["\\Flagged"])), Some(FlagColor::Red));
        assert_eq!(
            FlagColor::of(&flags(&["\\Flagged", "$MailFlagBit0"])),
            Some(FlagColor::Orange)
        );
        assert_eq!(
            FlagColor::of(&flags(&["\\Flagged", "$mailflagbit1"])),
            Some(FlagColor::Yellow)
        );
        assert_eq!(
            FlagColor::of(&flags(&["\\Flagged", "$MailFlagBit0", "$MailFlagBit1"])),
            Some(FlagColor::Green)
        );
        assert_eq!(
            FlagColor::of(&flags(&["\\Flagged", "$MailFlagBit2"])),
            Some(FlagColor::Blue)
        );
        assert_eq!(
            FlagColor::of(&flags(&["\\Flagged", "$MailFlagBit0", "$MailFlagBit2"])),
            Some(FlagColor::Purple)
        );
        assert_eq!(
            FlagColor::of(&flags(&["\\Flagged", "$MailFlagBit1", "$MailFlagBit2"])),
            Some(FlagColor::Gray)
        );
        let all = ["\\Flagged", "$MailFlagBit0", "$MailFlagBit1", "$MailFlagBit2"];
        assert_eq!(FlagColor::of(&flags(&all)), Some(FlagColor::Red));
        for color in FlagColor::ALL {
            assert_eq!(FlagColor::from_number(color as u8), Some(color));
        }
        assert_eq!(FlagColor::from_number(0), None);
        assert_eq!(FlagColor::from_number(8), None);
    }

    use super::*;
    use crate::{AccountSettings, FolderInfo};

    fn setup() -> (Store, FolderId) {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let inbox = FolderInfo {
            path: "INBOX".into(),
            name: "INBOX".into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(account, &[inbox]).unwrap();
        let folder = store.folders(account).unwrap()[0].id;
        (store, folder)
    }

    fn flags(list: &[&str]) -> Vec<String> {
        list.iter().map(|f| f.to_string()).collect()
    }

    fn message(uid: u64, subject: &str, from: &str, date: i64, list: &[&str]) -> MessageInfo {
        MessageInfo {
            uid,
            flags: flags(list),
            internal_date: Some(date + 60),
            date: Some(date),
            size: Some(uid * 100),
            subject: subject.into(),
            from_name: from.into(),
            from_address: format!("{}@example.com", from.to_lowercase()),
            ..Default::default()
        }
    }

    #[test]
    fn message_list_pages_and_sorts() {
        let (store, folder) = setup();
        store
            .add_messages(
                folder,
                &[
                    message(1, "b", "Zed", 300, &["\\Seen"]),
                    message(2, "a", "Ann", 100, &[]),
                    message(3, "C", "", 200, &["\\Seen", "\\Flagged"]),
                ],
            )
            .unwrap();
        let uids = |sort: Sort| -> Vec<u64> {
            store
                .messages(folder, sort, 0, 10)
                .unwrap()
                .iter()
                .map(|m| m.info.uid)
                .collect()
        };
        assert_eq!(uids(Sort::default()), [1, 3, 2]);
        let by = |field, ascending| Sort { field, ascending };
        assert_eq!(uids(by(SortField::Subject, true)), [2, 1, 3]);
        // no name: sorted by address, "@example.com"
        assert_eq!(uids(by(SortField::From, true)), [3, 2, 1]);
        assert_eq!(uids(by(SortField::Size, false)), [3, 2, 1]);
        assert_eq!(uids(by(SortField::Received, true)), [2, 3, 1]);
        for sort in [Sort::default(), by(SortField::Subject, true), by(SortField::From, true)] {
            for (position, uid) in uids(sort).into_iter().enumerate() {
                assert_eq!(store.message_index(folder, sort, uid).unwrap(), Some(position as u64));
            }
        }
        assert_eq!(store.message_index(folder, Sort::default(), 99).unwrap(), None);
        let page = store.messages(folder, Sort::default(), 1, 1).unwrap();
        assert_eq!(page.len(), 1);
        let info = &page[0].info;
        assert_eq!(info.uid, 3);
        assert!(info.seen() && info.flagged() && !info.answered());
        assert_eq!((info.sender(), info.display_date()), ("@example.com", Some(200)));
        assert_eq!(info.flags, ["\\Flagged", "\\Seen"], "sorted");

        let folder_row = store.folder(folder).unwrap();
        assert_eq!((folder_row.total, folder_row.unread), (3, 1));
        assert_eq!(store.uids(folder).unwrap(), [1, 2, 3]);
        assert_eq!(store.max_uid(folder).unwrap(), Some(3));
    }

    #[test]
    fn flags_updates_and_removal() {
        let (store, folder) = setup();
        assert_eq!(store.max_uid(folder).unwrap(), None);
        store
            .add_messages(folder, &[message(5, "x", "A", 1, &["\\Recent"])])
            .unwrap();
        assert!(
            store.message(folder, 5).unwrap().unwrap().info.flags.is_empty(),
            "no \\Recent"
        );
        assert!(
            store
                .set_flags(folder, 5, &flags(&["\\Seen", "\\Answered"]), Some(42))
                .unwrap()
        );
        assert!(!store.set_flags(folder, 6, &[], None).unwrap());
        // the same flags in another order, with \Recent: no change
        assert!(
            !store
                .set_flags(folder, 5, &flags(&["\\Answered", "\\Recent", "\\Seen"]), Some(43))
                .unwrap()
        );
        let m = store.message(folder, 5).unwrap().unwrap().info;
        assert!(m.seen() && m.answered() && !m.deleted());
        assert_eq!(m.modseq, Some(42));
        // a flag update without MODSEQ keeps the last one
        store.set_flags(folder, 5, &flags(&["\\Deleted"]), None).unwrap();
        let m = store.message(folder, 5).unwrap().unwrap().info;
        assert!(m.deleted() && !m.seen());
        assert_eq!(m.modseq, Some(42));
        assert_eq!(store.folder(folder).unwrap().unread, 1);
        // the folder is an Inbox: the tray counts it, and what came from UID 5 on is unread
        assert_eq!(store.inbox_unread().unwrap(), 1);
        let fresh: Vec<u64> = store
            .unseen_from(folder, 5)
            .unwrap()
            .iter()
            .map(|m| m.info.uid)
            .collect();
        assert_eq!(fresh, [5]);
        assert!(store.unseen_from(folder, 6).unwrap().is_empty());

        // adding again updates the flags, the rest stays
        let mut again = message(5, "y", "A", 1, &["\\Seen"]);
        again.modseq = Some(50);
        store.add_messages(folder, &[again]).unwrap();
        let m = store.message(folder, 5).unwrap().unwrap().info;
        assert_eq!(
            (m.subject.as_str(), m.flags.as_slice(), m.modseq),
            ("x", &flags(&["\\Seen"])[..], Some(50))
        );
        assert!(store.set_flag(folder, 5, "\\Flagged", true).unwrap());
        assert!(!store.set_flag(folder, 5, "\\Flagged", true).unwrap());
        assert!(!store.set_flag(folder, 6, "\\Flagged", true).unwrap());
        let m = store.message(folder, 5).unwrap().unwrap().info;
        assert_eq!(m.flags, flags(&["\\Flagged", "\\Seen"]));
        assert!(store.set_flag(folder, 5, "\\seen", false).unwrap());
        assert_eq!(store.folder(folder).unwrap().unread, 1);
        // all read at once: the unread ones, their other flags kept
        store
            .add_messages(folder, &[message(7, "z", "A", 1, &["$Junk"])])
            .unwrap();
        assert_eq!(store.mark_all_seen(folder).unwrap(), [5, 7]);
        assert_eq!(store.folder(folder).unwrap().unread, 0);
        assert_eq!(
            store.message(folder, 7).unwrap().unwrap().info.flags,
            flags(&["$Junk", "\\Seen"])
        );
        assert!(store.mark_all_seen(folder).unwrap().is_empty());
        store.remove_messages(folder, &[7]).unwrap();
        assert_eq!(store.remove_messages(folder, &[5, 6]).unwrap(), 1);
        assert!(store.message(folder, 5).unwrap().is_none());
    }

    #[test]
    fn sources_are_cached_and_go_with_their_message() {
        let (store, folder) = setup();
        store.add_messages(folder, &[message(1, "x", "A", 1, &[])]).unwrap();
        assert!(!store.set_source(folder, 2, b"nope").unwrap());
        assert!(!store.has_source(folder, 1).unwrap());
        assert!(store.set_source(folder, 1, b"Subject: x\r\n\r\nhi").unwrap());
        assert_eq!(
            store.source(folder, 1).unwrap().as_deref(),
            Some(&b"Subject: x\r\n\r\nhi"[..])
        );
        // its start only, without reading the rest
        assert_eq!(
            store.source_start(folder, 1, 10).unwrap().as_deref(),
            Some(&b"Subject: x"[..])
        );
        assert_eq!(store.source_start(folder, 9, 10).unwrap(), None);
        assert!(store.message(folder, 1).unwrap().unwrap().cached);
        assert!(store.has_source(folder, 1).unwrap());
        // new flags keep the source
        store
            .add_messages(folder, &[message(1, "x", "A", 1, &["\\Seen"])])
            .unwrap();
        assert!(store.message(folder, 1).unwrap().unwrap().cached);
        store.remove_messages(folder, &[1]).unwrap();
        assert!(store.source(folder, 1).unwrap().is_none());
        let orphans: i64 = store
            .db
            .query_row("SELECT COUNT(*) FROM bodies", [], |r| r.get(0))
            .unwrap();
        assert_eq!(orphans, 0);
    }

    #[test]
    fn a_new_uid_validity_drops_the_messages() {
        let (store, folder) = setup();
        store.add_messages(folder, &[message(1, "x", "A", 1, &[])]).unwrap();
        store.set_source(folder, 1, b"x").unwrap();
        store.reset_folder(folder, Some(2)).unwrap();
        assert!(store.uids(folder).unwrap().is_empty());
    }
}
