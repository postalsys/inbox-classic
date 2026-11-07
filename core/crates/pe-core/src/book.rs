//! The address book of the windows: people and groups kept by the user, a message's sender added, vCard and CSV
//! files read in and written out, and the completion of address fields that offers the book first.

use std::path::Path;

use pe_store::{Card, CardId, Group, GroupId};

use crate::compose::address_label;
use crate::{Core, Error, FolderId, Result};

/// Someone (or a group) to complete an address field with
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Completion {
    pub name: String,
    /// Empty for a group
    pub address: String,
    /// As it goes in the field: `Name <address>`, or for a group its members' so
    pub label: String,
    pub group: bool,
}

/// Whether `address` is one mailbox alone (`mary@example.com`), nothing that would make a field of more recipients
/// or another one than it seems (`a@x>, b@y`, `"a@x" <b@y>`)
fn is_mailbox(address: &str) -> bool {
    let address = address.trim();
    !address.is_empty()
        && !address
            .chars()
            .any(|c| c.is_control() || c.is_whitespace() || "<>,;()\"".contains(c))
        && matches!(
            pe_mime::parser::parse_addresses(address).as_slice(),
            [pe_mime::parser::ParsedAddress::Mailbox(found)] if found.address == address
        )
}

/// A card with only the addresses that are one mailbox each
fn checked(card: &Card) -> Card {
    Card {
        addresses: card.addresses.iter().filter(|a| is_mailbox(a)).cloned().collect(),
        ..card.clone()
    }
}

/// What reading a file of cards did
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Imported {
    /// Cards added
    pub added: u64,
    /// Cards left out because one with the same address is in the book already
    pub skipped: u64,
}

impl Core {
    /// The people of the address book, by name; with `filter`, those whose name, nickname, company or an address
    /// starts with it
    pub fn cards(&self, filter: &str) -> Result<Vec<Card>> {
        Ok(self.store().cards(filter)?)
    }

    pub fn card(&self, id: CardId) -> Result<Option<Card>> {
        Ok(self.store().card(id)?)
    }

    /// Saves a card (a new one when its id is 0); its id. An address that is not one mailbox alone is left out.
    pub fn save_card(&self, card: &Card) -> Result<CardId> {
        Ok(self.store().save_card(&checked(card))?)
    }

    pub fn delete_cards(&self, ids: &[CardId]) -> Result<()> {
        Ok(self.store().delete_cards(ids)?)
    }

    pub fn groups(&self) -> Result<Vec<Group>> {
        Ok(self.store().groups()?)
    }

    pub fn group(&self, id: GroupId) -> Result<Option<Group>> {
        Ok(self.store().group(id)?)
    }

    /// Saves a group (a new one when its id is 0); its id
    pub fn save_group(&self, group: &Group) -> Result<GroupId> {
        Ok(self.store().save_group(group)?)
    }

    pub fn delete_group(&self, id: GroupId) -> Result<()> {
        Ok(self.store().delete_group(id)?)
    }

    /// The sender of message `uid` of `folder` into the address book: the card that has their address already, or a
    /// new one with their name and address. Its id, and whether it is new.
    pub fn add_sender(&self, folder: FolderId, uid: u64) -> Result<(CardId, bool)> {
        let message = self.store().message(folder, uid)?.ok_or(Error::NotFound)?;
        let address = message.info.from_address.trim().to_string();
        if !address.contains('@') {
            return Err(Error::NotFound);
        }
        if let Some(card) = self.store().card_by_address(&address)? {
            return Ok((card.id, false));
        }
        let name = message.info.from_name.trim();
        let mut words = name.split_whitespace();
        let first = words.next().unwrap_or_default().to_string();
        let last = words.collect::<Vec<_>>().join(" ");
        let card = Card {
            name: if name.is_empty() {
                address.clone()
            } else {
                name.to_string()
            },
            first,
            last,
            addresses: vec![address],
            ..Default::default()
        };
        Ok((self.store().save_card(&card)?, true))
    }

    /// Reads a vCard (`.vcf`) or CSV file into the address book: a card whose addresses are all in the book already is
    /// left out (counted as skipped). Refused for a file too big to be an address book.
    pub fn import_cards(&self, path: &Path) -> Result<Imported> {
        let size = std::fs::metadata(path)
            .map_err(|error| Error::Unavailable(error.to_string()))?
            .len();
        if size > crate::vcard::MAX_FILE as u64 {
            return Err(Error::Unavailable(pe_i18n::tr(pe_i18n::Text::CardsFileTooBig)));
        }
        let bytes = std::fs::read(path).map_err(|error| Error::Unavailable(error.to_string()))?;
        let text = String::from_utf8_lossy(&bytes);
        let start = text.trim_start_matches('\u{feff}').trim_start();
        let vcard = start
            .get(..11)
            .is_some_and(|first| first.eq_ignore_ascii_case("BEGIN:VCARD"));
        let cards: Vec<Card> = if vcard {
            crate::vcard::read_vcards(&text)
        } else {
            crate::vcard::read_csv(&text)
        }
        .iter()
        .map(checked)
        .collect();
        let (added, skipped) = self.store().import_cards(&cards)?;
        Ok(Imported { added, skipped })
    }

    /// Writes cards (`ids`, or every card when it is empty) to a vCard file
    pub fn export_cards(&self, ids: &[CardId], path: &Path) -> Result<u64> {
        let cards: Vec<Card> = if ids.is_empty() {
            self.store().cards("")?
        } else {
            ids.iter()
                .filter_map(|&id| self.store().card(id).transpose())
                .collect::<pe_store::Result<_>>()?
        };
        std::fs::write(path, crate::vcard::write_vcards(&cards))
            .map_err(|error| Error::Unavailable(error.to_string()))?;
        Ok(cards.len() as u64)
    }

    /// What completes an address field from `typed`: the address book's people (each of their addresses) and groups
    /// first, then those written to or heard from, best first, at most `limit`, no address twice
    pub fn completions(&self, typed: &str, limit: usize) -> Result<Vec<Completion>> {
        let (people, groups) = self.store().book_matching(typed, limit)?;
        let mut found: Vec<Completion> = Vec::new();
        for (name, address) in people {
            found.push(Completion {
                label: address_label(&name, &address),
                name,
                address,
                group: false,
            });
        }
        for group in groups {
            let members: Vec<String> = group
                .members
                .iter()
                .filter(|m| m.address.contains('@'))
                .map(|m| address_label(&m.name, &m.address))
                .collect();
            if members.is_empty() {
                continue;
            }
            found.push(Completion {
                name: group.name,
                address: String::new(),
                label: members.join(", "),
                group: true,
            });
        }
        for contact in self.store().contacts_matching(typed, limit)? {
            if found.iter().any(|f| f.address.eq_ignore_ascii_case(&contact.address)) {
                continue;
            }
            found.push(Completion {
                label: address_label(&contact.name, &contact.address),
                name: contact.name,
                address: contact.address,
                group: false,
            });
        }
        found.truncate(limit);
        Ok(found)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn an_address_is_one_mailbox() {
        assert!(is_mailbox("mary@example.com"));
        assert!(is_mailbox(" mary@example.com "));
        for bad in [
            "boss@corp.example>, attacker@evil.example",
            "\"boss@corp.example\" <attacker@evil.example>",
            "attacker@evil.example (boss@corp.example)",
            "a@x\nBcc: b@y",
            "not an address",
            "",
        ] {
            assert!(!is_mailbox(bad), "{bad}");
        }
    }
}
