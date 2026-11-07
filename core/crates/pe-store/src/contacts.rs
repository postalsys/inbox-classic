//! The address book that completes addresses as they are typed: the people written to (the recipients of the
//! messages in Sent Items) and heard from (the senders of the rest, Junk left out), ranked by how often and how lately.
//! It fills itself from the messages the store gets; a person forgotten stays out.

use rusqlite::params;

use crate::{FolderId, MessageInfo, Result, Store};

/// Someone the address book knows
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Contact {
    pub name: String,
    pub address: String,
}

/// How much one message written to someone counts against one heard from them
const SENT_WEIGHT: i64 = 3;

/// The LIKE patterns of what is typed, matched at the start (`typed%`) and at the start of a word after the first
/// (`% typed%`), its wildcards taken as themselves
pub(crate) fn like_starts(typed: &str) -> (String, String) {
    let escaped = like_escaped(typed.trim());
    (format!("{escaped}%"), format!("% {escaped}%"))
}

/// The words of LIKE that match themselves
pub(crate) fn like_escaped(text: &str) -> String {
    let mut escaped = String::with_capacity(text.len());
    for c in text.chars() {
        if matches!(c, '%' | '_' | '\\') {
            escaped.push('\\');
        }
        escaped.push(c);
    }
    escaped
}

impl Store {
    /// The people of messages the store does not have yet, into the address book: the recipients when the folder is
    /// Sent Items, the sender otherwise, nobody from Junk
    pub(crate) fn note_correspondents(&self, folder: FolderId, messages: &[MessageInfo]) -> Result<()> {
        let special = self.folder(folder)?.info.special_use;
        if special.as_deref() == Some("\\Junk") {
            return Ok(());
        }
        let sent = special.as_deref() == Some("\\Sent");
        let mut known = self
            .db
            .prepare_cached("SELECT 1 FROM messages WHERE folder_id = ?1 AND uid = ?2")?;
        let mut note = self.db.prepare_cached(
            "INSERT INTO contacts (address, name, sent, received, last) VALUES (?1, ?2, ?3, ?4, ?5) \
             ON CONFLICT (address) DO UPDATE SET \
             name = CASE WHEN excluded.name != '' AND excluded.last >= last THEN excluded.name ELSE name END, \
             sent = sent + excluded.sent, received = received + excluded.received, last = MAX(last, excluded.last)",
        )?;
        for message in messages {
            if known.exists(params![folder, message.uid])? {
                continue;
            }
            let when = message.date.or(message.internal_date).unwrap_or(0);
            let people: Vec<(&str, &str)> = if sent {
                message
                    .correspondents
                    .iter()
                    .map(|(name, address)| (name.as_str(), address.as_str()))
                    .collect()
            } else {
                vec![(message.from_name.as_str(), message.from_address.as_str())]
            };
            for (name, address) in people {
                let address = address.trim();
                if !address.contains('@') {
                    continue;
                }
                note.execute(params![address, name.trim(), sent as i64, !sent as i64, when])?;
            }
        }
        Ok(())
    }

    /// The people whose address or name (a word of it) starts with `typed`, best first: written to more often, then
    /// heard from, then lately
    pub fn contacts_matching(&self, typed: &str, limit: usize) -> Result<Vec<Contact>> {
        let typed = typed.trim();
        if typed.is_empty() {
            return Ok(Vec::new());
        }
        let (start, word) = like_starts(typed);
        let mut statement = self.db.prepare_cached(
            "SELECT name, address FROM contacts WHERE hidden = 0 \
             AND (address LIKE ?1 ESCAPE '\\' OR name LIKE ?1 ESCAPE '\\' OR name LIKE ?2 ESCAPE '\\') \
             ORDER BY sent * ?3 + received DESC, last DESC, address LIMIT ?4",
        )?;
        statement
            .query_map(params![start, word, SENT_WEIGHT, limit as i64], |row| {
                Ok(Contact {
                    name: row.get(0)?,
                    address: row.get(1)?,
                })
            })?
            .collect()
    }

    /// Takes someone out of the completions, for good: mail from them later does not bring them back
    pub fn forget_contact(&self, address: &str) -> Result<()> {
        self.db
            .execute("UPDATE contacts SET hidden = 1 WHERE address = ?1", [address.trim()])?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use crate::{AccountSettings, FolderInfo, MessageInfo, Store};

    fn message(uid: u64, from: (&str, &str), to: &[(&str, &str)], date: i64) -> MessageInfo {
        MessageInfo {
            uid,
            date: Some(date),
            from_name: from.0.into(),
            from_address: from.1.into(),
            correspondents: to.iter().map(|(n, a)| (n.to_string(), a.to_string())).collect(),
            ..Default::default()
        }
    }

    fn folders(store: &Store) -> (i64, i64, i64) {
        let account = store.add_account(&AccountSettings::example("me@example.com")).unwrap();
        let info = |path: &str, special: Option<&str>| FolderInfo {
            path: path.into(),
            name: path.into(),
            delimiter: Some("/".into()),
            special_use: special.map(String::from),
            selectable: true,
            ..Default::default()
        };
        store
            .set_folders(
                account,
                &[
                    info("INBOX", None),
                    info("Sent", Some("\\Sent")),
                    info("Junk", Some("\\Junk")),
                ],
            )
            .unwrap();
        let id = |path| store.find_folder(account, path).unwrap().unwrap().id;
        (id("INBOX"), id("Sent"), id("Junk"))
    }

    #[test]
    fn completes_from_people_written_to_and_heard_from() {
        let store = Store::open_in_memory().unwrap();
        let (inbox, sent, junk) = folders(&store);
        store
            .add_messages(
                inbox,
                &[message(
                    1,
                    ("Anna Lind", "anna@example.com"),
                    &[("Me", "me@example.com")],
                    10,
                )],
            )
            .unwrap();
        store
            .add_messages(inbox, &[message(2, ("Andres", "andres@example.com"), &[], 20)])
            .unwrap();
        // written to twice: first, though heard from less lately
        store
            .add_messages(
                sent,
                &[message(1, ("Me", "me@example.com"), &[("", "andrew@example.com")], 5)],
            )
            .unwrap();
        store
            .add_messages(
                sent,
                &[message(
                    2,
                    ("Me", "me@example.com"),
                    &[("Andrew Ng", "Andrew@example.com")],
                    6,
                )],
            )
            .unwrap();
        // nobody from Junk
        store
            .add_messages(junk, &[message(1, ("Anyone", "an@spam.example"), &[], 30)])
            .unwrap();
        let found = |typed: &str| -> Vec<String> {
            store
                .contacts_matching(typed, 10)
                .unwrap()
                .into_iter()
                .map(|c| format!("{} <{}>", c.name, c.address))
                .collect()
        };
        assert_eq!(
            found("an"),
            [
                "Andrew Ng <andrew@example.com>",
                "Andres <andres@example.com>",
                "Anna Lind <anna@example.com>"
            ]
        );
        // a word of the name, case does not matter
        assert_eq!(found("LIND"), ["Anna Lind <anna@example.com>"]);
        assert_eq!(found("ng"), ["Andrew Ng <andrew@example.com>"]);
        // LIKE's wildcards are only themselves
        assert!(found("%").is_empty() && found("_").is_empty());
        assert!(found(" ").is_empty());
        // a message seen again (a sync) counts once
        store
            .add_messages(inbox, &[message(2, ("Andres", "andres@example.com"), &[], 20)])
            .unwrap();
        assert_eq!(found("andres"), ["Andres <andres@example.com>"]);
        // forgotten, and mail later does not bring them back
        store.forget_contact("andres@example.com").unwrap();
        store
            .add_messages(inbox, &[message(3, ("Andres", "andres@example.com"), &[], 40)])
            .unwrap();
        assert!(found("andres").is_empty());
    }
}
