//! Autocrypt (Level 1): keys carried in the mail itself.
//!
//! **Read** from a message opened: its one `Autocrypt` header, when the message has one From, the header's `addr` is
//! that From, it is not in Junk E-mail and not a report (a bounce carries someone else's mail). Messages are taken by
//! their date, so reading an old one after a newer one changes nothing. `Autocrypt-Gossip` (the other recipients'
//! keys) is read only inside an encrypted message, for its To and Cc addresses, and only for addresses without a key.
//! What is read is learned as any key is (keys.rs): a different key for an address that has one waits for the user.
//!
//! **Sent** from an address whose key says so (Account Properties > Security, on by default): the `Autocrypt`
//! header with the smallest copy of the key; inside an encrypted message to several people, their keys as gossip.
//! Never `prefer-encrypt=mutual`: encryption here is the user's choice for each message.

use pe_mime::parser::{self, Message};

use crate::keys::{KeySource, Learned};
use crate::{Core, Result};

/// What a message opened said for Autocrypt, to learn once the window has its view
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Seen {
    /// The sender
    pub address: String,
    /// Its header's key, binary; None when the message has no (valid) header
    pub keydata: Option<Vec<u8>>,
    pub mutual: bool,
    /// The message's date (never later than when it was read)
    pub date: i64,
    /// The keys of other recipients the sender gossiped inside the encryption
    pub gossip: Vec<(String, Vec<u8>)>,
}

/// The addresses of every From header
fn senders(message: &Message) -> Vec<String> {
    message
        .headers
        .iter()
        .filter(|header| header.key == "from")
        .flat_map(|header| parser::parse_addresses(&header.value))
        .flat_map(|address| {
            address
                .mailboxes()
                .iter()
                .map(|m| pe_store::normal_address(&m.address))
                .collect::<Vec<_>>()
        })
        .collect()
}

/// The Autocrypt of a message: None when it may say nothing (several senders, Junk E-mail, a report)
pub(crate) fn seen(message: &Message, junk: bool, now: i64) -> Option<Seen> {
    let [from] = senders(message).try_into().ok()?;
    if junk {
        return None;
    }
    let report = message.headers.iter().any(|header| {
        header.key == "content-type" && header.value.to_ascii_lowercase().starts_with("multipart/report")
    }) || pe_bounce::detect::may_be_bounce(message);
    if report {
        return None;
    }
    let headers: Vec<pe_pgp::autocrypt::Header> = message
        .headers
        .iter()
        .filter(|header| header.key == "autocrypt")
        .filter_map(|header| pe_pgp::autocrypt::parse(&header.value))
        .filter(|header| header.addr == from)
        .collect();
    // two headers for the address: neither counts (Autocrypt 2.3)
    let header = match headers.as_slice() {
        [one] => Some(one.clone()),
        _ => None,
    };
    let date = message.timestamp.map_or(now, |date| date.min(now));
    Some(Seen {
        address: from,
        mutual: header.as_ref().is_some_and(|header| header.mutual),
        keydata: header.map(|header| header.keydata),
        date,
        gossip: Vec::new(),
    })
}

/// The gossip of an encrypted payload's own headers: each for an address of `recipients` (the message's To and Cc)
pub(crate) fn gossip(payload: &[u8], recipients: &[String]) -> Vec<(String, Vec<u8>)> {
    let outline = pe_mime::outline::outline(payload);
    let Some(root) = outline.root() else { return Vec::new() };
    let Ok(headers) = parser::parse(&payload[..root.body]) else {
        return Vec::new();
    };
    headers
        .headers
        .iter()
        .filter(|header| header.key == "autocrypt-gossip")
        .filter_map(|header| pe_pgp::autocrypt::parse(&header.value))
        .filter(|header| recipients.contains(&header.addr))
        .map(|header| (header.addr, header.keydata))
        .take(32)
        .collect()
}

/// The To and Cc addresses of a message, lower case
pub(crate) fn recipients(message: &Message) -> Vec<String> {
    message
        .to
        .iter()
        .chain(&message.cc)
        .flat_map(|address| {
            address
                .mailboxes()
                .iter()
                .map(|m| pe_store::normal_address(&m.address))
                .collect::<Vec<_>>()
        })
        .collect()
}

/// The `Autocrypt` header of an own address with its key (`cert`, binary), folded at its spaces
pub(crate) fn header(address: &str, cert: &pe_pgp::Cert, now: i64) -> Option<String> {
    let minimal = cert.minimal(address, now)?;
    let value = pe_pgp::autocrypt::build(address, &minimal.to_bytes(), false);
    Some(format!("Autocrypt: {}\r\n", value.replace(' ', "\r\n ")))
}

/// An `Autocrypt-Gossip` header for a recipient's key
pub(crate) fn gossip_header(address: &str, cert: &pe_pgp::Cert, now: i64) -> Option<String> {
    let minimal = cert.minimal(address, now)?;
    let value = pe_pgp::autocrypt::build(address, &minimal.to_bytes(), false);
    Some(format!("Autocrypt-Gossip: {}\r\n", value.replace(' ', "\r\n ")))
}

impl Core {
    /// Learns what a message opened said for Autocrypt ([`Seen`]): the sender's key when the message is newer than
    /// the last one read for them, the gossiped keys of addresses without one
    pub(crate) fn learn_autocrypt(&self, seen: &Seen) -> Result<()> {
        // a key is judged as it is now: the date only orders the messages
        let now = crate::worker::unix_now();
        let peer = self.store().pgp_peer(&seen.address)?.unwrap_or_default();
        if peer.autocrypt_seen.is_some_and(|last| seen.date <= last) {
            return Ok(());
        }
        // only for the address it was checked for: other user ids a stranger put on the key change nobody's key
        let cert = seen
            .keydata
            .as_deref()
            .and_then(|bytes| pe_pgp::read_certs(bytes).ok())
            .and_then(|certs| certs.into_iter().find(|cert| cert.has_address(&seen.address, now)))
            .and_then(|cert| cert.minimal(&seen.address, now));
        if let Some(cert) = &cert {
            self.book(|book| book.learn(cert, KeySource::Autocrypt))?;
        }
        let store = self.store();
        let mut peer = store.pgp_peer(&seen.address)?.unwrap_or_else(|| pe_store::PgpPeer {
            address: seen.address.clone(),
            ..Default::default()
        });
        peer.autocrypt_seen = Some(seen.date);
        if cert.is_some() {
            peer.autocrypt_key_seen = Some(seen.date);
            peer.mutual = seen.mutual;
        }
        store.set_pgp_peer(&peer)?;
        drop(store);
        for (address, bytes) in &seen.gossip {
            let has_key = self
                .store()
                .pgp_peer(address)?
                .and_then(|peer| peer.fingerprint)
                .is_some();
            if has_key {
                continue;
            }
            let Some(cert) = pe_pgp::read_certs(bytes)
                .ok()
                .and_then(|certs| certs.into_iter().next())
            else {
                continue;
            };
            if let Some(cert) = cert.minimal(address, now) {
                let learned = self.book(|book| book.learn(&cert, KeySource::Autocrypt))?;
                debug_assert!(learned.iter().all(|(_, what)| *what != Learned::Pending));
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn message(headers: &str) -> Message {
        parser::parse(format!("{headers}\r\n\r\nbody\r\n").as_bytes()).unwrap()
    }

    #[test]
    fn the_rules_of_reading() {
        let key = "keydata=AQID";
        let one = message(&format!(
            "From: Ann <ann@example.org>\r\nDate: Sun, 15 Nov 2026 10:00:00 +0000\r\nAutocrypt: addr=ann@example.org; {key}"
        ));
        let found = seen(&one, false, 1_900_000_000).unwrap();
        assert_eq!(
            (found.address.as_str(), found.keydata.as_deref()),
            ("ann@example.org", Some(&[1u8, 2, 3][..]))
        );
        // the header's address must be the sender's
        let other = message(&format!(
            "From: ann@example.org\r\nAutocrypt: addr=bob@example.org; {key}"
        ));
        assert_eq!(seen(&other, false, 0).unwrap().keydata, None);
        // two headers for the address: neither
        let two = message(&format!(
            "From: ann@example.org\r\nAutocrypt: addr=ann@example.org; {key}\r\nAutocrypt: addr=ann@example.org; {key}"
        ));
        assert_eq!(seen(&two, false, 0).unwrap().keydata, None);
        // two senders, Junk, a report: nothing at all
        assert!(
            seen(
                &message(&format!(
                    "From: a@example.org, b@example.org\r\nAutocrypt: addr=a@example.org; {key}"
                )),
                false,
                0
            )
            .is_none()
        );
        assert!(seen(&one, true, 0).is_none());
        let report = message(&format!(
            "From: ann@example.org\r\nContent-Type: multipart/report; report-type=delivery-status; boundary=x\r\nAutocrypt: addr=ann@example.org; {key}"
        ));
        assert!(seen(&report, false, 0).is_none());
        // a date in the future counts as now
        let future = message(&format!(
            "From: ann@example.org\r\nDate: Sun, 15 Nov 2099 10:00:00 +0000\r\nAutocrypt: addr=ann@example.org; {key}"
        ));
        assert_eq!(seen(&future, false, 1_000).unwrap().date, 1_000);
    }

    #[test]
    fn gossip_for_recipients_only() {
        let payload = "Autocrypt-Gossip: addr=bob@example.org; keydata=AQID\r\nAutocrypt-Gossip: addr=eve@example.org; keydata=AQID\r\n\
                       Content-Type: text/plain\r\n\r\nhi";
        let found = gossip(payload.as_bytes(), &["bob@example.org".into()]);
        assert_eq!(found, [("bob@example.org".to_string(), vec![1, 2, 3])]);
    }
}
