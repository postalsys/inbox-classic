//! The senders whose pictures load without asking: an address (`ann@shop.com`) or a whole domain (`shop.com`), which
//! the reading pane's pictures bar adds and Options lists. The core loads them only when the provider confirms the
//! message comes from that domain, and matches a sender against the list (pe-core `pictures.rs`); here is just the list, and the setting that loads every
//! message's pictures.

use rusqlite::params;

use crate::{Result, Store};

/// A sender whose pictures load: an address, or every address of a domain
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TrustedSender {
    pub id: i64,
    /// The address or the domain, in lower case
    pub value: String,
    /// The whole domain, rather than one address
    pub domain: bool,
}

/// The setting of Options' "Download pictures in all messages"
const ALWAYS: &str = "pictures.always";

impl Store {
    /// Trusts `value`, an address or (with `domain`) a domain, in lower case; trusting it again changes nothing
    pub fn trust_sender(&self, value: &str, domain: bool) -> Result<()> {
        let value = value.trim().to_lowercase();
        if value.is_empty() || domain == value.contains('@') {
            return Err(rusqlite::Error::InvalidParameterName(value));
        }
        self.db.execute(
            "INSERT INTO trusted_senders (value, domain, added) VALUES (?1, ?2, strftime('%s', 'now')) \
             ON CONFLICT (value) DO NOTHING",
            params![value, domain],
        )?;
        Ok(())
    }

    pub fn untrust_sender(&self, id: i64) -> Result<()> {
        self.db.execute("DELETE FROM trusted_senders WHERE id = ?1", [id])?;
        Ok(())
    }

    /// The list, domains and addresses in alphabetical order
    pub fn trusted_senders(&self) -> Result<Vec<TrustedSender>> {
        let mut statement = self
            .db
            .prepare("SELECT id, value, domain FROM trusted_senders ORDER BY value")?;
        statement
            .query_map([], |row| {
                Ok(TrustedSender {
                    id: row.get(0)?,
                    value: row.get(1)?,
                    domain: row.get(2)?,
                })
            })?
            .collect()
    }

    /// Options' "Download pictures in all messages"
    pub fn always_load_pictures(&self) -> Result<bool> {
        self.bool_setting(ALWAYS, false)
    }

    pub fn set_always_load_pictures(&self, on: bool) -> Result<()> {
        self.set_bool_setting(ALWAYS, on)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn senders_trusted_by_address_or_domain() {
        let store = Store::open_in_memory().unwrap();
        store.trust_sender(" Ann@Shop.com ", false).unwrap();
        store.trust_sender("ann@shop.com", false).unwrap();
        store.trust_sender("News.example", true).unwrap();
        assert!(store.trust_sender("shop.com", false).is_err(), "an address has an @");
        assert!(store.trust_sender("ann@shop.com", true).is_err(), "a domain has none");
        let list = store.trusted_senders().unwrap();
        assert_eq!(
            list.iter().map(|t| (t.value.as_str(), t.domain)).collect::<Vec<_>>(),
            [("ann@shop.com", false), ("news.example", true)]
        );
        store.untrust_sender(list[0].id).unwrap();
        assert_eq!(store.trusted_senders().unwrap().len(), 1);

        assert!(!store.always_load_pictures().unwrap(), "off out of the box");
        store.set_always_load_pictures(true).unwrap();
        assert!(store.always_load_pictures().unwrap());
    }
}
