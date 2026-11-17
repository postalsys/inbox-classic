//! OpenPGP keys as the store keeps them: bytes and bookkeeping only. What a key is worth, and the wrapping of private
//! keys, is pe-core's (`keys.rs`) and pe-pgp's.

use rusqlite::{OptionalExtension, params};

use crate::{Result, Store};

/// A key: its certificate and, for the user's own, the private part wrapped under the master key
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StoredKey {
    /// Upper case hex
    pub fingerprint: String,
    /// The certificate, binary
    pub cert: Vec<u8>,
    /// The private key wrapped (pe-core), None for someone else's key
    pub secret: Option<Vec<u8>>,
    /// Where it came from: `own`, `file`, `paste`, `attachment`, `vcard`, `wkd`, `keyserver`, `autocrypt`
    pub source: String,
    pub added: i64,
    pub changed: i64,
}

/// An address a key holds, and whether the user compared the key's fingerprint with its owner
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct KeyAddress {
    pub fingerprint: String,
    /// Lower case
    pub address: String,
    pub verified: bool,
}

/// A correspondent: the key in use for them, a newer one waiting for the user's decision, and Autocrypt's times
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct PgpPeer {
    /// Lower case
    pub address: String,
    pub fingerprint: Option<String>,
    pub pending: Option<String>,
    pub pending_since: Option<i64>,
    /// The date of the newest message from them that was read for Autocrypt
    pub autocrypt_seen: Option<i64>,
    /// The date of the newest message whose Autocrypt header gave the key in use
    pub autocrypt_key_seen: Option<i64>,
    pub mutual: bool,
}

/// One of the user's own addresses and its key
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PgpIdentity {
    pub address: String,
    pub fingerprint: String,
    /// Send its key in the Autocrypt header
    pub autocrypt: bool,
}

fn key_row(row: &rusqlite::Row<'_>) -> rusqlite::Result<StoredKey> {
    Ok(StoredKey {
        fingerprint: row.get(0)?,
        cert: row.get(1)?,
        secret: row.get(2)?,
        source: row.get(3)?,
        added: row.get(4)?,
        changed: row.get(5)?,
    })
}

const KEY_COLUMNS: &str = "fingerprint, cert, secret, source, added, changed";

fn address_row(row: &rusqlite::Row<'_>) -> rusqlite::Result<KeyAddress> {
    Ok(KeyAddress {
        fingerprint: row.get(0)?,
        address: row.get(1)?,
        verified: row.get(2)?,
    })
}

fn identity_row(row: &rusqlite::Row<'_>) -> rusqlite::Result<PgpIdentity> {
    Ok(PgpIdentity {
        address: row.get(0)?,
        fingerprint: row.get(1)?,
        autocrypt: row.get(2)?,
    })
}

/// An address as every table here keeps it: trimmed, lower case (all of Unicode, which `COLLATE NOCASE` is not)
pub fn normal_address(address: &str) -> String {
    address.trim().to_lowercase()
}

impl Store {
    /// Every key, own keys first, then by when they were added
    pub fn pgp_keys(&self) -> Result<Vec<StoredKey>> {
        let mut statement = self.db.prepare(&format!(
            "SELECT {KEY_COLUMNS} FROM pgp_keys ORDER BY secret IS NULL, added, fingerprint"
        ))?;
        statement.query_map([], key_row)?.collect()
    }

    pub fn pgp_key(&self, fingerprint: &str) -> Result<Option<StoredKey>> {
        self.db
            .query_row(
                &format!("SELECT {KEY_COLUMNS} FROM pgp_keys WHERE fingerprint = ?1"),
                [fingerprint],
                key_row,
            )
            .optional()
    }

    /// Adds or updates a key and the addresses it holds now. A private part already kept stays when `key.secret`
    /// is None; the verified mark of an address stays while the key holds it.
    pub fn save_pgp_key(&self, key: &StoredKey, addresses: &[String]) -> Result<()> {
        // a savepoint, so that a caller's transaction (keys.rs learns a key and its addresses at once) holds it
        self.atomic(|| self.save_pgp_key_rows(key, addresses))
    }

    fn save_pgp_key_rows(&self, key: &StoredKey, addresses: &[String]) -> Result<()> {
        self.db.execute(
            "INSERT INTO pgp_keys (fingerprint, cert, secret, source, added, changed) VALUES (?1, ?2, ?3, ?4, ?5, ?6) \
             ON CONFLICT (fingerprint) DO UPDATE SET cert = excluded.cert, \
             secret = coalesce(excluded.secret, pgp_keys.secret), changed = excluded.changed",
            params![
                key.fingerprint,
                key.cert,
                key.secret,
                key.source,
                key.added,
                key.changed
            ],
        )?;
        let wanted: Vec<String> = addresses.iter().map(|a| normal_address(a)).collect();
        let held: Vec<String> = {
            let mut statement = self
                .db
                .prepare("SELECT address FROM pgp_key_addresses WHERE fingerprint = ?1")?;
            statement
                .query_map([&key.fingerprint], |row| row.get(0))?
                .collect::<Result<_>>()?
        };
        for gone in held.iter().filter(|address| !wanted.contains(address)) {
            self.db.execute(
                "DELETE FROM pgp_key_addresses WHERE fingerprint = ?1 AND address = ?2",
                params![key.fingerprint, gone],
            )?;
        }
        for address in &wanted {
            self.db.execute(
                "INSERT INTO pgp_key_addresses (fingerprint, address) VALUES (?1, ?2) ON CONFLICT DO NOTHING",
                params![key.fingerprint, address],
            )?;
        }
        Ok(())
    }

    /// Runs `f` in one immediate transaction on a shared store: a key learned and the rule of its addresses land
    /// together, never interleaved with another connection's. Rolled back when `f` fails.
    pub fn pgp_transaction<T>(&self, f: impl FnOnce() -> Result<T>) -> Result<T> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let value = f()?;
        tx.commit()?;
        Ok(value)
    }

    /// Removes a key; correspondents who used it are left without a key, own addresses without theirs
    pub fn remove_pgp_key(&self, fingerprint: &str) -> Result<()> {
        self.db
            .execute("DELETE FROM pgp_keys WHERE fingerprint = ?1", [fingerprint])?;
        Ok(())
    }

    /// The addresses of every key, or of one
    pub fn pgp_key_addresses(&self, fingerprint: Option<&str>) -> Result<Vec<KeyAddress>> {
        let mut statement = self.db.prepare(
            "SELECT fingerprint, address, verified FROM pgp_key_addresses \
             WHERE ?1 IS NULL OR fingerprint = ?1 ORDER BY fingerprint, address",
        )?;
        statement.query_map([fingerprint], address_row)?.collect()
    }

    /// Marks whether the user compared the fingerprint of `fingerprint` for `address`
    pub fn set_pgp_verified(&self, fingerprint: &str, address: &str, verified: bool) -> Result<()> {
        self.db.execute(
            "UPDATE pgp_key_addresses SET verified = ?3 WHERE fingerprint = ?1 AND address = ?2",
            params![fingerprint, normal_address(address), verified],
        )?;
        Ok(())
    }

    pub fn pgp_peer(&self, address: &str) -> Result<Option<PgpPeer>> {
        self.db
            .query_row(
                "SELECT address, fingerprint, pending, pending_since, autocrypt_seen, autocrypt_key_seen, mutual \
                 FROM pgp_peers WHERE address = ?1",
                [normal_address(address)],
                |row| {
                    Ok(PgpPeer {
                        address: row.get(0)?,
                        fingerprint: row.get(1)?,
                        pending: row.get(2)?,
                        pending_since: row.get(3)?,
                        autocrypt_seen: row.get(4)?,
                        autocrypt_key_seen: row.get(5)?,
                        mutual: row.get(6)?,
                    })
                },
            )
            .optional()
    }

    /// Every correspondent's key in use: (address, fingerprint)
    pub fn pgp_keys_in_use(&self) -> Result<Vec<(String, String)>> {
        let mut statement = self
            .db
            .prepare("SELECT address, fingerprint FROM pgp_peers WHERE fingerprint IS NOT NULL")?;
        statement.query_map([], |row| Ok((row.get(0)?, row.get(1)?)))?.collect()
    }

    pub fn set_pgp_peer(&self, peer: &PgpPeer) -> Result<()> {
        self.db.execute(
            "INSERT INTO pgp_peers (address, fingerprint, pending, pending_since, autocrypt_seen, autocrypt_key_seen, \
             mutual) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7) ON CONFLICT (address) DO UPDATE SET \
             fingerprint = excluded.fingerprint, pending = excluded.pending, pending_since = excluded.pending_since, \
             autocrypt_seen = excluded.autocrypt_seen, autocrypt_key_seen = excluded.autocrypt_key_seen, \
             mutual = excluded.mutual",
            params![
                normal_address(&peer.address),
                peer.fingerprint,
                peer.pending,
                peer.pending_since,
                peer.autocrypt_seen,
                peer.autocrypt_key_seen,
                peer.mutual
            ],
        )?;
        Ok(())
    }

    pub fn pgp_identities(&self) -> Result<Vec<PgpIdentity>> {
        let mut statement = self
            .db
            .prepare("SELECT address, fingerprint, autocrypt FROM pgp_identities ORDER BY address")?;
        statement
            .query_map([], |row| {
                Ok(PgpIdentity {
                    address: row.get(0)?,
                    fingerprint: row.get(1)?,
                    autocrypt: row.get(2)?,
                })
            })?
            .collect()
    }

    pub fn pgp_identity(&self, address: &str) -> Result<Option<PgpIdentity>> {
        self.db
            .query_row(
                "SELECT address, fingerprint, autocrypt FROM pgp_identities WHERE address = ?1",
                [normal_address(address)],
                identity_row,
            )
            .optional()
    }

    pub fn set_pgp_identity(&self, identity: &PgpIdentity) -> Result<()> {
        self.db.execute(
            "INSERT INTO pgp_identities (address, fingerprint, autocrypt) VALUES (?1, ?2, ?3) \
             ON CONFLICT (address) DO UPDATE SET fingerprint = excluded.fingerprint, autocrypt = excluded.autocrypt",
            params![
                normal_address(&identity.address),
                identity.fingerprint,
                identity.autocrypt
            ],
        )?;
        Ok(())
    }

    /// The address sends with no key
    pub fn remove_pgp_identity(&self, address: &str) -> Result<()> {
        self.db.execute(
            "DELETE FROM pgp_identities WHERE address = ?1",
            [normal_address(address)],
        )?;
        Ok(())
    }
}

/// Options' "Look up keys on keys.openpgp.org"
const KEYSERVER: &str = "pgp.keyserver";

impl Store {
    /// When `address`'s key was last looked up and whether one was found; None when it never was
    pub fn pgp_lookup(&self, address: &str) -> Result<Option<(i64, bool)>> {
        self.db
            .query_row(
                "SELECT checked, found FROM pgp_lookups WHERE address = ?1",
                [normal_address(address)],
                |row| Ok((row.get(0)?, row.get(1)?)),
            )
            .optional()
    }

    pub fn set_pgp_lookup(&self, address: &str, checked: i64, found: bool) -> Result<()> {
        self.db.execute(
            "INSERT INTO pgp_lookups (address, checked, found) VALUES (?1, ?2, ?3) \
             ON CONFLICT (address) DO UPDATE SET checked = excluded.checked, found = excluded.found",
            params![normal_address(address), checked, found],
        )?;
        Ok(())
    }

    /// Options' "Look up keys on keys.openpgp.org", on out of the box
    pub fn pgp_keyserver(&self) -> Result<bool> {
        self.bool_setting(KEYSERVER, true)
    }

    pub fn set_pgp_keyserver(&self, on: bool) -> Result<()> {
        self.set_bool_setting(KEYSERVER, on)
    }
}

/// Options' "Search in encrypted messages"
const INDEX_ENCRYPTED: &str = "pgp.index_encrypted";

impl Store {
    /// Options' "Search in encrypted messages": the text of an encrypted message opened goes into the index, on out
    /// of the box
    pub fn pgp_index_encrypted(&self) -> Result<bool> {
        self.bool_setting(INDEX_ENCRYPTED, true)
    }

    pub fn set_pgp_index_encrypted(&self, on: bool) -> Result<()> {
        self.set_bool_setting(INDEX_ENCRYPTED, on)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn key(fingerprint: &str, secret: Option<&[u8]>) -> StoredKey {
        StoredKey {
            fingerprint: fingerprint.into(),
            cert: vec![1, 2, 3],
            secret: secret.map(<[u8]>::to_vec),
            source: "file".into(),
            added: 100,
            changed: 100,
        }
    }

    #[test]
    fn keys_and_their_addresses() {
        let store = Store::open_in_memory().unwrap();
        store
            .save_pgp_key(&key("AA", None), &["Bob@Example.org".into()])
            .unwrap();
        store
            .save_pgp_key(&key("BB", Some(b"wrapped")), &["me@example.org".into()])
            .unwrap();
        let keys = store.pgp_keys().unwrap();
        assert_eq!(
            keys.iter().map(|k| k.fingerprint.as_str()).collect::<Vec<_>>(),
            ["BB", "AA"],
            "own first"
        );
        assert_eq!(
            store.pgp_key_addresses(Some("AA")).unwrap()[0].address,
            "bob@example.org",
            "lower case"
        );

        store.set_pgp_verified("AA", "bob@example.org", true).unwrap();
        // a newer copy keeps the mark of an address it still holds, drops the address it no longer holds
        let mut newer = key("AA", None);
        newer.cert = vec![9];
        newer.changed = 200;
        store
            .save_pgp_key(&newer, &["bob@example.org".into(), "b@work.example".into()])
            .unwrap();
        let held = store.pgp_key_addresses(Some("AA")).unwrap();
        assert_eq!(held.len(), 2);
        assert!(held.iter().any(|a| a.address == "bob@example.org" && a.verified));
        let saved = store.pgp_key("AA").unwrap().unwrap();
        assert_eq!((saved.cert, saved.added, saved.changed), (vec![9], 100, 200));
        store.save_pgp_key(&newer, &["b@work.example".into()]).unwrap();
        assert_eq!(store.pgp_key_addresses(Some("AA")).unwrap().len(), 1);

        // the wrapped private part stays when a public copy of the same key is saved
        store
            .save_pgp_key(&key("BB", None), &["me@example.org".into()])
            .unwrap();
        assert_eq!(
            store.pgp_key("BB").unwrap().unwrap().secret.as_deref(),
            Some(&b"wrapped"[..])
        );
    }

    #[test]
    fn removing_a_key_clears_what_pointed_at_it() {
        let store = Store::open_in_memory().unwrap();
        store
            .save_pgp_key(&key("AA", None), &["bob@example.org".into()])
            .unwrap();
        store
            .save_pgp_key(&key("CC", Some(b"w")), &["me@example.org".into()])
            .unwrap();
        store
            .set_pgp_peer(&PgpPeer {
                address: "Bob@Example.org".into(),
                fingerprint: Some("AA".into()),
                ..Default::default()
            })
            .unwrap();
        store
            .set_pgp_identity(&PgpIdentity {
                address: "me@example.org".into(),
                fingerprint: "CC".into(),
                autocrypt: true,
            })
            .unwrap();
        assert_eq!(
            store
                .pgp_peer("bob@example.org")
                .unwrap()
                .unwrap()
                .fingerprint
                .as_deref(),
            Some("AA")
        );
        store.remove_pgp_key("AA").unwrap();
        store.remove_pgp_key("CC").unwrap();
        assert_eq!(store.pgp_peer("bob@example.org").unwrap().unwrap().fingerprint, None);
        assert!(store.pgp_key_addresses(Some("AA")).unwrap().is_empty());
        assert!(store.pgp_identity("ME@example.org").unwrap().is_none());
    }

    #[test]
    fn a_transaction_holds_a_saved_key() {
        let store = Store::open_in_memory().unwrap();
        let failed: Result<()> = store.pgp_transaction(|| {
            store.save_pgp_key(&key("AA", None), &["bob@example.org".into()])?;
            Err(rusqlite::Error::InvalidQuery)
        });
        assert!(failed.is_err());
        assert!(
            store.pgp_key("AA").unwrap().is_none(),
            "rolled back with the transaction"
        );
        store
            .pgp_transaction(|| store.save_pgp_key(&key("AA", None), &["bob@example.org".into()]))
            .unwrap();
        assert!(store.pgp_key("AA").unwrap().is_some());
    }

    #[test]
    fn lookups_and_the_keyserver_setting() {
        let store = Store::open_in_memory().unwrap();
        assert_eq!(store.pgp_lookup("bob@example.org").unwrap(), None);
        store.set_pgp_lookup("Bob@Example.org", 100, false).unwrap();
        assert_eq!(store.pgp_lookup("bob@example.org").unwrap(), Some((100, false)));
        store.set_pgp_lookup("bob@example.org", 200, true).unwrap();
        assert_eq!(store.pgp_lookup("bob@example.org").unwrap(), Some((200, true)));
        assert!(store.pgp_keyserver().unwrap());
        store.set_pgp_keyserver(false).unwrap();
        assert!(!store.pgp_keyserver().unwrap());
    }

    #[test]
    fn a_pending_key() {
        let store = Store::open_in_memory().unwrap();
        store
            .save_pgp_key(&key("AA", None), &["bob@example.org".into()])
            .unwrap();
        store
            .save_pgp_key(&key("DD", None), &["bob@example.org".into()])
            .unwrap();
        let peer = PgpPeer {
            address: "bob@example.org".into(),
            fingerprint: Some("AA".into()),
            pending: Some("DD".into()),
            pending_since: Some(300),
            ..Default::default()
        };
        store.set_pgp_peer(&peer).unwrap();
        assert_eq!(store.pgp_peer(" Bob@Example.org").unwrap().unwrap(), peer);
    }
}
