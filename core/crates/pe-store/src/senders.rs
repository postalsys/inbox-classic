//! What the provider's verdicts say of each message's sender, for its picture in the message list (pe-core
//! senders.rs reads them): the header fields fetched with the summary wait in `messages.auth_headers` until the core
//! has read them, then only its bits and the logo's row are kept. The logos are kept by their address, each SVG
//! downloaded once, so the list never asks for a logo a message at a time.

use rusqlite::{OptionalExtension, params};

use crate::{AccountId, FolderId, Result, Store};

/// How long a downloaded logo is kept before it is downloaded again
pub const LOGO_KEPT_MS: i64 = 30 * 24 * 3600 * 1000;
/// How long a failed download is not tried again
pub const LOGO_RETRY_MS: i64 = 24 * 3600 * 1000;

/// A message whose verdicts the core has yet to read
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ToJudge {
    pub message: i64,
    pub folder: FolderId,
    pub from_address: String,
    pub headers: String,
}

/// A brand's logo as kept
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StoredLogo {
    pub url: String,
    /// The SVG, once downloaded
    pub svg: Option<Vec<u8>>,
    /// When it was downloaded, and when a download last failed (milliseconds since the Unix epoch)
    pub fetched: Option<i64>,
    pub failed: Option<i64>,
}

impl StoredLogo {
    /// The SVG, while it is fresh enough to show (`now` in milliseconds)
    pub fn fresh_svg(&self, now: i64) -> Option<&[u8]> {
        self.svg
            .as_deref()
            .filter(|_| self.fetched.is_some_and(|at| now - at < LOGO_KEPT_MS))
    }

    /// Whether a download is due: none fresh, and none failed lately
    pub fn download_due(&self, now: i64) -> bool {
        self.fresh_svg(now).is_none() && !self.failed.is_some_and(|at| now - at < LOGO_RETRY_MS)
    }
}

impl Store {
    /// Messages of an account whose verdicts were fetched and not read yet, a batch at most
    pub fn messages_to_judge(&self, account: AccountId, limit: usize) -> Result<Vec<ToJudge>> {
        let mut statement = self.db.prepare_cached(
            "SELECT m.id, m.folder_id, m.from_address, m.auth_headers FROM messages m INDEXED BY messages_auth_pending \
             JOIN folders f ON f.id = m.folder_id WHERE m.auth_headers IS NOT NULL AND f.account_id = ?1 LIMIT ?2",
        )?;
        statement
            .query_map(params![account, limit as i64], |row| {
                Ok(ToJudge {
                    message: row.get(0)?,
                    folder: row.get(1)?,
                    from_address: row.get(2)?,
                    headers: row.get(3)?,
                })
            })?
            .collect()
    }

    /// Messages of an account stored before their verdicts were fetched, newest first, a batch at most: (message id,
    /// folder, UID)
    pub fn messages_without_auth(&self, account: AccountId, limit: usize) -> Result<Vec<(i64, FolderId, u64)>> {
        let mut statement = self.db.prepare_cached(
            "SELECT m.id, m.folder_id, m.uid FROM messages m INDEXED BY messages_auth_unknown \
             JOIN folders f ON f.id = m.folder_id WHERE m.sender_auth IS NULL AND m.auth_headers IS NULL \
             AND m.fetch_failed = 0 AND f.account_id = ?1 ORDER BY COALESCE(m.date, m.internal_date) DESC LIMIT ?2",
        )?;
        statement
            .query_map(params![account, limit as i64], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?))
            })?
            .collect()
    }

    /// The verdicts fetched again for a message stored before (`headers`: the fields as the server gave them, empty
    /// for none), for the core to read with the others
    pub fn set_auth_headers(&self, message: i64, headers: &str) -> Result<()> {
        self.db
            .prepare_cached("UPDATE messages SET auth_headers = ?2 WHERE id = ?1 AND sender_auth IS NULL")?
            .execute(params![message, headers])?;
        Ok(())
    }

    /// What the core made of a message's verdicts: its bits, and the address of its brand's logo when they allow one.
    /// The header fields are let go; whether the logo's row is new
    pub fn set_sender_auth(&self, message: i64, bits: u8, logo_url: Option<&str>) -> Result<bool> {
        let mut new_logo = false;
        let logo = match logo_url {
            Some(url) => {
                new_logo = self
                    .db
                    .prepare_cached("INSERT OR IGNORE INTO logos (url) VALUES (?1)")?
                    .execute([url])?
                    > 0;
                Some(
                    self.db
                        .prepare_cached("SELECT id FROM logos WHERE url = ?1")?
                        .query_row([url], |row| row.get::<_, i64>(0))?,
                )
            }
            None => None,
        };
        self.db
            .prepare_cached("UPDATE messages SET sender_auth = ?2, logo_id = ?3, auth_headers = NULL WHERE id = ?1")?
            .execute(params![message, bits, logo])?;
        Ok(new_logo)
    }

    /// A logo by its row
    pub fn logo(&self, id: i64) -> Result<Option<StoredLogo>> {
        self.db
            .prepare_cached("SELECT url, svg, fetched, failed FROM logos WHERE id = ?1")?
            .query_row([id], |row| {
                Ok(StoredLogo {
                    url: row.get(0)?,
                    svg: row.get(1)?,
                    fetched: row.get(2)?,
                    failed: row.get(3)?,
                })
            })
            .optional()
    }

    /// A logo downloaded (`svg`) at `now`, or its download failed (None): kept, or not tried again for a day
    pub fn set_logo_download(&self, id: i64, svg: Option<&[u8]>, now: i64) -> Result<()> {
        match svg {
            Some(svg) => self
                .db
                .prepare_cached("UPDATE logos SET svg = ?2, fetched = ?3, failed = NULL WHERE id = ?1")?
                .execute(params![id, svg, now])?,
            None => self
                .db
                .prepare_cached("UPDATE logos SET failed = ?2 WHERE id = ?1")?
                .execute(params![id, now])?,
        };
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::MessageInfo;

    fn setup() -> (Store, AccountId, FolderId, FolderId) {
        let store = Store::open_in_memory().unwrap();
        let account = store
            .add_account(&crate::AccountSettings::example("a@example.com"))
            .unwrap();
        let folder = |path: &str, special: Option<&str>| crate::FolderInfo {
            path: path.into(),
            name: path.into(),
            selectable: true,
            special_use: special.map(Into::into),
            ..Default::default()
        };
        store
            .set_folders(account, &[folder("INBOX", None), folder("Junk", Some("\\Junk"))])
            .unwrap();
        let id = |path: &str| store.find_folder(account, path).unwrap().unwrap().id;
        let (inbox, junk) = (id("INBOX"), id("Junk"));
        (store, account, inbox, junk)
    }

    fn message(uid: u64, date: i64, headers: Option<&str>) -> MessageInfo {
        MessageInfo {
            uid,
            date: Some(date),
            from_address: "news@shop.example".into(),
            auth_headers: headers.map(str::to_string),
            ..Default::default()
        }
    }

    #[test]
    fn verdicts_read_once_and_logos_kept_by_address() {
        let (store, account, inbox, junk) = setup();
        store
            .add_messages(
                inbox,
                &[
                    message(1, 100, Some("Authentication-Results: x")),
                    message(2, 200, None),
                ],
            )
            .unwrap();
        store
            .add_messages(junk, &[message(1, 300, Some("Authentication-Results: y"))])
            .unwrap();
        let pending = store.messages_to_judge(account, 10).unwrap();
        assert_eq!(pending.len(), 2);
        assert!(pending.iter().all(|p| p.from_address == "news@shop.example"));
        // stored before: fetched again, newest first
        let without: Vec<u64> = store
            .messages_without_auth(account, 10)
            .unwrap()
            .into_iter()
            .map(|(_, _, uid)| uid)
            .collect();
        assert_eq!(without, [2]);
        let url = "https://shop.example/logo.svg";
        for judged in &pending {
            store.set_sender_auth(judged.message, 3, Some(url)).unwrap();
        }
        assert!(store.messages_to_judge(account, 10).unwrap().is_empty());
        // one row for the address, and its key on the rows; none in Junk
        let row = store.message(inbox, 1).unwrap().unwrap();
        assert_eq!(row.sender_auth, 3);
        let logo = row.logo.expect("a logo");
        assert_eq!(store.message(junk, 1).unwrap().unwrap().logo, None);
        assert_eq!(store.message(inbox, 2).unwrap().unwrap().sender_auth, 0);
        assert_eq!(store.logo(logo).unwrap().unwrap().url, url);
        let (id, _, _) = store.messages_without_auth(account, 10).unwrap()[0];
        store.set_auth_headers(id, "").unwrap();
        assert!(store.messages_without_auth(account, 10).unwrap().is_empty());
        assert_eq!(store.messages_to_judge(account, 10).unwrap().len(), 1);
    }

    #[test]
    fn logos_downloaded_once_and_failures_rested() {
        let (store, _, inbox, _) = setup();
        store.add_messages(inbox, &[message(1, 100, Some(""))]).unwrap();
        let id = store.message(inbox, 1).unwrap().unwrap().id;
        assert!(store.set_sender_auth(id, 2, Some("https://a.example/l.svg")).unwrap());
        assert!(!store.set_sender_auth(id, 2, Some("https://a.example/l.svg")).unwrap());
        let logo = store.message(inbox, 1).unwrap().unwrap().logo.unwrap();
        let now = 1_000_000_000_000;
        assert!(store.logo(logo).unwrap().unwrap().download_due(now));
        store.set_logo_download(logo, None, now).unwrap();
        let failed = store.logo(logo).unwrap().unwrap();
        assert!(!failed.download_due(now + 3600 * 1000));
        assert!(failed.download_due(now + LOGO_RETRY_MS));
        store.set_logo_download(logo, Some(b"<svg/>"), now).unwrap();
        let kept = store.logo(logo).unwrap().unwrap();
        assert_eq!(kept.fresh_svg(now + 1000), Some(&b"<svg/>"[..]));
        assert!(!kept.download_due(now + 1000));
        assert_eq!(kept.fresh_svg(now + LOGO_KEPT_MS), None);
        assert!(kept.download_due(now + LOGO_KEPT_MS));
    }
}
