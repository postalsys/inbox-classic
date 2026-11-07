//! The address book of the windows: people and groups kept by the user, a message's sender added, vCard and CSV
//! files read in and written out, and the completion of address fields that offers the book first.

use std::path::{Path, PathBuf};

use pe_i18n::{Text, tr, tr_args};
pub use pe_store::display_name;
use pe_store::{Card, CardId, Group, GroupId, Member};

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

/// A person of the address book as its lists show them: a card, or in a group an address typed into it
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct BookRow {
    /// 0 for an address typed into a group
    pub card: CardId,
    /// The name shown: the name, or the address of someone without one
    pub name: String,
    /// The default address, empty for none
    pub address: String,
    /// The first phone number, empty for none
    pub phone: String,
    pub company: String,
    /// As it goes in an address field ([`card_label`]), empty without an address
    pub label: String,
}

impl BookRow {
    fn new(card: CardId, name: &str, address: &str, phone: &str, company: &str) -> BookRow {
        BookRow {
            card,
            name: shown_name(name, address).to_string(),
            address: address.to_string(),
            phone: phone.to_string(),
            company: company.to_string(),
            label: label_of(name, address),
        }
    }

    fn of_card(card: &Card) -> BookRow {
        let address = card.addresses.first().map_or("", String::as_str);
        let phone = card.phones.first().map_or("", |(_, number)| number.as_str());
        BookRow::new(card.id, &card.name, address, phone, &card.company)
    }
}

/// The name a contact is shown by: its name, or its address when it has none
fn shown_name<'a>(name: &'a str, address: &'a str) -> &'a str {
    if name.trim().is_empty() { address } else { name }
}

/// `name` and `address` as they go in an address field, empty without an address
fn label_of(name: &str, address: &str) -> String {
    if address.contains('@') {
        address_label(name, address)
    } else {
        String::new()
    }
}

/// A card as it goes in an address field: its name and default address (`Mary Smith <mary@example.com>`), empty for
/// a card without an address
pub fn card_label(card: &Card) -> String {
    label_of(&card.name, card.addresses.first().map_or("", String::as_str))
}

/// A member of a group as it goes in an address field, empty without an address
pub fn member_label(member: &Member) -> String {
    label_of(&member.name, &member.address)
}

/// A group as it goes in an address field: its members with an address, separated by commas
pub fn group_label(group: &Group) -> String {
    group
        .members
        .iter()
        .map(member_label)
        .filter(|label| !label.is_empty())
        .collect::<Vec<_>>()
        .join(", ")
}

/// `members` with those of `added` that are not in them yet: a card once, an address once (whether of a card or typed,
/// ignoring case). What Group Properties adds people with, and how a group is saved.
pub fn add_members(members: &[Member], added: &[Member]) -> Vec<Member> {
    let mut out = members.to_vec();
    for member in added {
        let address = member.address.trim();
        let known = out.iter().any(|m| {
            (m.card.is_some() && m.card == member.card)
                || (!address.is_empty() && m.address.trim().eq_ignore_ascii_case(address))
        });
        if !known {
            out.push(member.clone());
        }
    }
    out
}

/// Whether `address` is one mailbox alone (`mary@example.com`), nothing that would make a field of more recipients
/// or another one than it seems (`a@x>, b@y`, `"a@x" <b@y>`)
pub fn is_mailbox(address: &str) -> bool {
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

/// A card as the book keeps it: only the addresses that are one mailbox each, and without a name of its own or a first
/// or last name, known by its default address
fn checked(card: &Card) -> Card {
    let addresses: Vec<String> = card.addresses.iter().filter(|a| is_mailbox(a)).cloned().collect();
    let name = if card.name.trim().is_empty() && display_name(&card.first, &card.last).is_empty() {
        addresses.first().cloned().unwrap_or_default()
    } else {
        card.name.clone()
    };
    Card {
        name,
        addresses,
        ..card.clone()
    }
}

/// What reading files of cards did
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Imported {
    /// Cards added
    pub added: u64,
    /// Cards left out because one with the same address is in the book already
    pub skipped: u64,
    /// The files that could not be read, and why
    pub failed: Vec<(PathBuf, String)>,
}

impl Imported {
    /// The files that could not be read, a line each (`book.vcf: why`); empty when every file was read
    pub fn failures(&self) -> String {
        self.failed
            .iter()
            .map(|(path, reason)| {
                let file = path.file_name().map_or_else(
                    || path.to_string_lossy().into_owned(),
                    |name| name.to_string_lossy().into_owned(),
                );
                tr_args(
                    Text::CardsFileFailed,
                    &[("file", (&file).into()), ("reason", reason.into())],
                )
            })
            .collect::<Vec<_>>()
            .join("\n")
    }
}

/// What Add Sender to Address Book did
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct SenderAdded {
    /// The card of the sender (0 when the sender has no address)
    pub card: CardId,
    /// Whether the card is new
    pub added: bool,
    /// What the status bar says: added, there already, or no address to add
    pub status: String,
}

/// The text of an address field with `added` put at its end after a comma: the labels of people and groups as
/// [`Completion`] gives them (or the address book's rows), separated by commas. An address already in the field, or
/// given twice, goes in once. What Select Recipients and Write To put in To, Cc or Bcc.
pub fn add_to_field(field: &str, added: &str) -> String {
    use pe_mime::parser::parse_addresses;
    let mut known: Vec<String> = parse_addresses(field)
        .iter()
        .flat_map(|parsed| parsed.mailboxes())
        .map(|mailbox| mailbox.address.to_lowercase())
        .collect();
    let mut out = field.trim_end().trim_end_matches([',', ';']).trim_end().to_string();
    for parsed in parse_addresses(added) {
        for mailbox in parsed.mailboxes() {
            let address = mailbox.address.trim();
            if !address.contains('@') || known.contains(&address.to_lowercase()) {
                continue;
            }
            known.push(address.to_lowercase());
            if !out.is_empty() {
                out.push_str(", ");
            }
            out.push_str(&address_label(&mailbox.name, address));
        }
    }
    out
}

impl Core {
    /// The people of the address book, by name; with `filter`, those whose name (a word of it), nickname, company or
    /// an address starts with it
    pub fn cards(&self, filter: &str) -> Result<Vec<Card>> {
        Ok(self.store().cards(filter)?)
    }

    /// [`Core::cards`] as the book's rows
    pub fn card_rows(&self, filter: &str) -> Result<Vec<BookRow>> {
        Ok(self.cards(filter)?.iter().map(BookRow::of_card).collect())
    }

    pub fn card(&self, id: CardId) -> Result<Option<Card>> {
        Ok(self.store().card(id)?)
    }

    /// Saves a card (a new one when its id is 0); its id. An address that is not one mailbox alone is left out; a card
    /// with no name, first or last name is known by its default address, and one without an address too is refused.
    pub fn save_card(&self, card: &Card) -> Result<CardId> {
        let card = checked(card);
        if card.name.trim().is_empty() && display_name(&card.first, &card.last).is_empty() {
            return Err(Error::Invalid(tr(Text::CardNameNeeded)));
        }
        Ok(self.store().save_card(&card)?)
    }

    pub fn delete_cards(&self, ids: &[CardId]) -> Result<()> {
        Ok(self.store().delete_cards(ids)?)
    }

    /// Delete of the address book: the cards `cards` out of the book (and the groups they are in), and the addresses
    /// typed into `group` (`addresses`) out of it
    pub fn delete_from_book(&self, group: Option<GroupId>, cards: &[CardId], addresses: &[String]) -> Result<()> {
        Ok(self.store().delete_from_book(group, cards, addresses)?)
    }

    /// The groups, by name; with `filter`, those whose name (a word of it) starts with it
    pub fn groups(&self, filter: &str) -> Result<Vec<Group>> {
        Ok(self.store().groups(filter)?)
    }

    pub fn group(&self, id: GroupId) -> Result<Option<Group>> {
        Ok(self.store().group(id)?)
    }

    /// The people of group `id` as the book's rows, in their order; with `filter`, those found by it as
    /// [`Core::cards`] finds them. [`Error::NotFound`] when there is no such group.
    pub fn group_people(&self, id: GroupId, filter: &str) -> Result<Vec<BookRow>> {
        if self.store().group(id)?.is_none() {
            return Err(Error::NotFound);
        }
        Ok(self
            .store()
            .group_people(id, filter)?
            .iter()
            .map(|m| BookRow::new(m.card.unwrap_or(0), &m.name, &m.address, &m.phone, &m.company))
            .collect())
    }

    /// Saves a group (a new one when its id is 0); its id. A card or an address in it twice (a card's default address
    /// typed again, too) is kept once.
    pub fn save_group(&self, group: &Group) -> Result<GroupId> {
        let mut members = Vec::with_capacity(group.members.len());
        for member in &group.members {
            let mut member = member.clone();
            if let Some(id) = member.card
                && let Some(card) = self.store().card(id)?
            {
                member.address = card.addresses.first().cloned().unwrap_or_default();
            }
            members.push(member);
        }
        Ok(self.store().save_group(&Group {
            members: add_members(&[], &members),
            ..group.clone()
        })?)
    }

    pub fn delete_group(&self, id: GroupId) -> Result<()> {
        Ok(self.store().delete_group(id)?)
    }

    /// The sender of message `uid` of `folder` into the address book: the card that has their address already, or a
    /// new one with their name and address; with what the status bar says. [`Error::NotFound`] when the message is not
    /// there.
    pub fn add_sender(&self, folder: FolderId, uid: u64) -> Result<SenderAdded> {
        let message = self.store().message(folder, uid)?.ok_or(Error::NotFound)?;
        let address = message.info.from_address.trim().to_string();
        if !is_mailbox(&address) {
            return Ok(SenderAdded {
                status: tr(Text::UiSenderNone),
                ..Default::default()
            });
        }
        // the store's lock is not held while the card is saved
        let known = self.store().card_by_address(&address)?;
        let (id, added) = match known {
            Some(card) => (card.id, false),
            None => {
                let name = message.info.from_name.trim();
                let mut words = name.split_whitespace();
                let first = words.next().unwrap_or_default().to_string();
                let last = words.collect::<Vec<_>>().join(" ");
                let card = Card {
                    name: name.to_string(),
                    first,
                    last,
                    addresses: vec![address.clone()],
                    ..Default::default()
                };
                (self.save_card(&card)?, true)
            }
        };
        let name = self
            .store()
            .card(id)?
            .map(|card| BookRow::of_card(&card).name)
            .unwrap_or(address);
        let status = tr_args(
            if added {
                Text::UiSenderAdded
            } else {
                Text::UiSenderKnown
            },
            &[("name", (&name).into())],
        );
        Ok(SenderAdded {
            card: id,
            added,
            status,
        })
    }

    /// Reads vCard (`.vcf`) and CSV files into the address book: a card whose addresses are all in the book already is
    /// left out (counted as skipped). A file that can not be read, or is too big to be an address book, is named in
    /// [`Imported::failed`] and the others are read all the same.
    pub fn import_cards<P: AsRef<Path>>(&self, paths: &[P]) -> Imported {
        let mut imported = Imported::default();
        for path in paths {
            let path = path.as_ref();
            match self.import_file(path) {
                Ok((added, skipped)) => {
                    imported.added += added;
                    imported.skipped += skipped;
                }
                Err(error) => imported.failed.push((path.to_path_buf(), error.to_string())),
            }
        }
        imported
    }

    /// One file of [`Core::import_cards`]: (added, skipped)
    fn import_file(&self, path: &Path) -> Result<(u64, u64)> {
        let size = std::fs::metadata(path)
            .map_err(|error| Error::Unavailable(error.to_string()))?
            .len();
        if size > crate::vcard::MAX_FILE as u64 {
            return Err(Error::Unavailable(tr(Text::CardsFileTooBig)));
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
        Ok(self.store().import_cards(&cards)?)
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
                label: label_of(&name, &address),
                name,
                address,
                group: false,
            });
        }
        for group in groups {
            let label = group_label(&group);
            if label.is_empty() {
                continue;
            }
            found.push(Completion {
                name: group.name,
                address: String::new(),
                label,
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
    fn adds_to_a_field_once() {
        assert_eq!(
            add_to_field("", "Mary Smith <mary@example.com>, dave@example.com"),
            "Mary Smith <mary@example.com>, dave@example.com"
        );
        // what is there stays as typed; an address there already, or twice in what is added, goes in once
        assert_eq!(
            add_to_field(
                "ann@example.com, ",
                "Mary Smith <mary@example.com>, ANN@example.com, \"Smith, Mary\" <mary@example.com>, nobody"
            ),
            "ann@example.com, Mary Smith <mary@example.com>"
        );
        assert_eq!(
            add_to_field("x", "\"Doe, John\" <john@example.org>"),
            "x, \"Doe, John\" <john@example.org>"
        );
        assert_eq!(add_to_field("ann@example.com", ""), "ann@example.com");
    }

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

    fn member(card: Option<CardId>, name: &str, address: &str) -> Member {
        Member {
            card,
            name: name.into(),
            address: address.into(),
        }
    }

    #[test]
    fn one_label_rule() {
        let card = Card {
            name: "Smith, Mary".into(),
            addresses: vec!["mary@example.com".into(), "m@work.example".into()],
            ..Default::default()
        };
        assert_eq!(card_label(&card), "\"Smith, Mary\" <mary@example.com>");
        assert_eq!(card_label(&Card::default()), "", "no address, no label");
        let group = Group {
            members: vec![
                member(Some(1), "Mary Smith", "mary@example.com"),
                member(Some(2), "Bob", ""),
                member(None, "", "dave@example.com"),
            ],
            ..Default::default()
        };
        assert_eq!(group_label(&group), "Mary Smith <mary@example.com>, dave@example.com");
        assert_eq!(member_label(&group.members[1]), "");
    }

    #[test]
    fn members_once() {
        let list = vec![
            member(Some(1), "Mary", "mary@example.com"),
            member(None, "", "dave@example.com"),
        ];
        let added = [
            member(Some(1), "", ""),
            member(None, "", "MARY@example.com"),
            member(Some(3), "Ann", "Dave@Example.com"),
            member(None, "Zoe", "zoe@example.com"),
            member(None, "", "zoe@EXAMPLE.com"),
            member(Some(4), "Bob", ""),
            member(Some(4), "Bob", ""),
        ];
        let out = add_members(&list, &added);
        assert_eq!(
            out.iter().map(|m| (m.card, m.address.as_str())).collect::<Vec<_>>(),
            [
                (Some(1), "mary@example.com"),
                (None, "dave@example.com"),
                (None, "zoe@example.com"),
                (Some(4), "")
            ]
        );
    }

    #[test]
    fn a_nameless_card_is_known_by_its_address() {
        assert_eq!(display_name(" Mary ", " Smith "), "Mary Smith");
        assert_eq!(display_name("", "Smith"), "Smith");
        let card = checked(&Card {
            addresses: vec!["a@x>, b@y".into(), "ann@example.com".into()],
            ..Default::default()
        });
        assert_eq!((card.name.as_str(), card.addresses.len()), ("ann@example.com", 1));
        let named = checked(&Card {
            first: "Ann".into(),
            addresses: vec!["ann@example.com".into()],
            ..Default::default()
        });
        assert_eq!(named.name, "", "the store makes it of first and last");
    }

    fn opened(dir: &pe_testkit::TempDir) -> Core {
        let options = crate::Options {
            passwords: crate::PasswordStore::Memory,
            ..Default::default()
        };
        Core::open_with(dir.path().join("store.db"), options, |_| {}).unwrap()
    }

    #[test]
    fn the_book_through_the_core() {
        pe_i18n::set_language("en");
        let dir = pe_testkit::TempDir::new("core-book");
        let core = opened(&dir);

        // saving: known by the address without a name, refused without both
        let ann = core
            .save_card(&Card {
                addresses: vec!["ann@example.com".into()],
                ..Default::default()
            })
            .unwrap();
        assert_eq!(core.card(ann).unwrap().unwrap().name, "ann@example.com");
        let refused = core.save_card(&Card {
            addresses: vec!["not one".into()],
            ..Default::default()
        });
        assert_eq!(
            refused.unwrap_err().to_string(),
            "The contact has no name and no e-mail address."
        );
        let mary = core
            .save_card(&Card {
                first: "Mary".into(),
                last: "Smith".into(),
                company: "Acme".into(),
                phones: vec![("cell".into(), "+1 555 0100".into())],
                addresses: vec!["mary@example.com".into()],
                ..Default::default()
            })
            .unwrap();
        assert_eq!(
            core.card_rows("smi").unwrap(),
            [BookRow {
                card: mary,
                name: "Mary Smith".into(),
                address: "mary@example.com".into(),
                phone: "+1 555 0100".into(),
                company: "Acme".into(),
                label: "Mary Smith <mary@example.com>".into(),
            }]
        );

        // a group saved with each one once, its people as the same rows
        let team = core
            .save_group(&Group {
                name: "Team".into(),
                members: vec![
                    member(Some(mary), "", ""),
                    member(None, "", "MARY@example.com"),
                    member(None, "", "dave@example.org"),
                    member(None, "Dave", "Dave@example.org"),
                ],
                ..Default::default()
            })
            .unwrap();
        let people = core.group_people(team, "").unwrap();
        assert_eq!(people[0], core.card_rows("mary").unwrap()[0], "both views agree");
        assert_eq!(
            people[1],
            BookRow {
                card: 0,
                name: "dave@example.org".into(),
                address: "dave@example.org".into(),
                label: "dave@example.org".into(),
                ..Default::default()
            }
        );
        assert_eq!(people.len(), 2);
        assert_eq!(core.group_people(team, "acme").unwrap().len(), 1);
        assert!(matches!(core.group_people(999, ""), Err(Error::NotFound)));
        assert_eq!(core.groups("te").unwrap().len(), 1);
        assert!(core.groups("x").unwrap().is_empty());

        // Delete: Mary out of the book, Dave's typed address out of the group
        core.delete_from_book(Some(team), &[mary], &["DAVE@example.org".into()])
            .unwrap();
        assert!(core.group_people(team, "").unwrap().is_empty());
        assert!(core.card(mary).unwrap().is_none());

        // several files: the counts of those read, the others named
        let good = dir.path().join("good.vcf");
        std::fs::write(
            &good,
            "BEGIN:VCARD\r\nFN:Zoe\r\nEMAIL:zoe@example.com\r\nEND:VCARD\r\n\
             BEGIN:VCARD\r\nFN:Ann\r\nEMAIL:ann@example.com\r\nEND:VCARD\r\n",
        )
        .unwrap();
        let gone = dir.path().join("gone.csv");
        let imported = core.import_cards(&[&gone, &good]);
        assert_eq!((imported.added, imported.skipped), (1, 1));
        assert_eq!(imported.failed.len(), 1);
        assert_eq!(imported.failed[0].0, gone);
        assert!(imported.failures().starts_with("gone.csv: "), "{}", imported.failures());
        assert!(core.import_cards::<&Path>(&[]).failures().is_empty());
    }

    #[test]
    fn the_sender_with_what_the_status_bar_says() {
        pe_i18n::set_language("en");
        let dir = pe_testkit::TempDir::new("core-sender");
        let core = opened(&dir);
        let folder = {
            let store = core.store();
            let account = store
                .add_account(&pe_store::AccountSettings {
                    email: "me@example.com".into(),
                    ..Default::default()
                })
                .unwrap();
            let inbox = pe_store::FolderInfo {
                path: "INBOX".into(),
                name: "INBOX".into(),
                selectable: true,
                ..Default::default()
            };
            store.set_folders(account, &[inbox]).unwrap();
            let folder = store.folders(account).unwrap()[0].id;
            let from = |uid: u64, name: &str, address: &str| pe_store::MessageInfo {
                uid,
                from_name: name.into(),
                from_address: address.into(),
                ..Default::default()
            };
            store
                .add_messages(
                    folder,
                    &[
                        from(1, "Mary Smith", "mary@example.com"),
                        from(2, "", "nobody@example.com"),
                        from(3, "Nobody", ""),
                    ],
                )
                .unwrap();
            folder
        };
        let added = core.add_sender(folder, 1).unwrap();
        assert!(added.card > 0 && added.added);
        assert_eq!(added.status, "Mary Smith was added to the Address Book.");
        let card = core.card(added.card).unwrap().unwrap();
        assert_eq!((card.first.as_str(), card.last.as_str()), ("Mary", "Smith"));
        let again = core.add_sender(folder, 1).unwrap();
        assert_eq!((again.card, again.added), (added.card, false));
        assert_eq!(again.status, "Mary Smith is already in the Address Book.");
        let nameless = core.add_sender(folder, 2).unwrap();
        assert_eq!(nameless.status, "nobody@example.com was added to the Address Book.");
        assert_eq!(core.card(nameless.card).unwrap().unwrap().name, "nobody@example.com");
        let none = core.add_sender(folder, 3).unwrap();
        assert_eq!(
            (none.card, none.status.as_str()),
            (0, "The sender of this message has no e-mail address to add.")
        );
        assert!(matches!(core.add_sender(folder, 9), Err(Error::NotFound)));
    }
}
