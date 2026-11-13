//! The address book the user keeps: people (cards) with their names, addresses, phones and notes, and groups of them
//! to write to at once. Unlike the list that completes addresses on its own ([`crate::contacts`]), it holds only what
//! the user put in it (by hand, from a message's sender, or from a vCard or CSV file).

use rusqlite::{OptionalExtension, params};

use crate::contacts::like_starts;
use crate::{Result, Store};

pub type CardId = i64;
pub type GroupId = i64;

/// A person of the address book
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Card {
    /// 0 for one not saved yet
    pub id: CardId,
    /// The name shown and written to (`Mary Smith`)
    pub name: String,
    pub first: String,
    pub last: String,
    pub nickname: String,
    pub company: String,
    pub notes: String,
    /// The addresses, the default one first
    pub addresses: Vec<String>,
    /// (kind, number): `home`, `work`, `cell` or empty
    pub phones: Vec<(String, String)>,
    /// The lines of a vCard read in that are not edited here (birthday, postal address, ...), written out again on
    /// export as they came
    pub extra: String,
    /// Its picture as the core keeps it (pe-core card_pictures.rs), for a vCard read in or written out only: a card
    /// read from the store has None, and saving a card leaves its picture as it is
    pub picture: Option<Vec<u8>>,
}

/// Someone in a group: a card, or an address of no card
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Member {
    pub card: Option<CardId>,
    pub name: String,
    pub address: String,
}

/// What the address book offers for an address being typed: (name, address) of its people, and its groups
pub type BookMatches = (Vec<(String, String)>, Vec<Group>);

/// A group of people written to at once
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Group {
    /// 0 for one not saved yet
    pub id: GroupId,
    pub name: String,
    pub members: Vec<Member>,
}

/// Someone of a group as the book lists them: a member with what their card has now
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct MemberRow {
    /// None for an address typed into the group
    pub card: Option<CardId>,
    pub name: String,
    /// The card's default address, or the address typed
    pub address: String,
    /// The card's first phone number, empty for none
    pub phone: String,
    pub company: String,
}

/// The name a card without one gets from its first and last name: `Mary Smith`, `Smith`, or empty
pub fn display_name(first: &str, last: &str) -> String {
    format!("{} {}", first.trim(), last.trim()).trim().to_string()
}

/// The phones of a card as the store keeps them: a `kind\tnumber` line each
fn phones_of(text: &str) -> Vec<(String, String)> {
    text.lines()
        .filter_map(|line| line.split_once('\t'))
        .map(|(kind, number)| (kind.to_string(), number.to_string()))
        .collect()
}

/// The LIKE patterns of a filter of the book: (the start of the text, the start of a word of it); for no filter, `%`
/// for both, which the queries take as everything
fn filter_patterns(filter: &str) -> (String, String) {
    if filter.trim().is_empty() {
        ("%".to_string(), "%".to_string())
    } else {
        like_starts(filter)
    }
}

/// A card of a row of `id, name, first, last, nickname, company, notes, phones, extra`, without its addresses
fn card_row(row: &rusqlite::Row) -> rusqlite::Result<Card> {
    let phones: String = row.get(7)?;
    Ok(Card {
        id: row.get(0)?,
        name: row.get(1)?,
        first: row.get(2)?,
        last: row.get(3)?,
        nickname: row.get(4)?,
        company: row.get(5)?,
        notes: row.get(6)?,
        phones: phones_of(&phones),
        extra: row.get(8)?,
        addresses: Vec::new(),
        picture: None,
    })
}

/// The most of each a card or group keeps: more is not someone's address book, and a hostile file can not grow one
const MAX_FIELD: usize = 4096;
const MAX_NOTES: usize = 64 * 1024;
const MAX_ADDRESSES: usize = 50;
const MAX_MEMBERS: usize = 10_000;

fn capped(text: &str, max: usize) -> String {
    let text = text.trim();
    if text.len() <= max {
        return text.to_string();
    }
    let mut end = max;
    while !text.is_char_boundary(end) {
        end -= 1;
    }
    text[..end].to_string()
}

impl Store {
    /// The cards, by name; with `filter`, those whose name (a word of it), nickname, company or an address starts with
    /// it
    pub fn cards(&self, filter: &str) -> Result<Vec<Card>> {
        let (start, word) = filter_patterns(filter);
        let mut statement = self.db.prepare_cached(
            "SELECT id FROM cards WHERE ?1 = '%' OR name LIKE ?1 ESCAPE '\\' OR name LIKE ?2 ESCAPE '\\' \
             OR nickname LIKE ?1 ESCAPE '\\' OR company LIKE ?1 ESCAPE '\\' \
             OR id IN (SELECT card_id FROM card_addresses WHERE address LIKE ?1 ESCAPE '\\') \
             ORDER BY name COLLATE NOCASE, id",
        )?;
        let ids: Vec<CardId> = statement
            .query_map(params![start, word], |row| row.get(0))?
            .collect::<rusqlite::Result<_>>()?;
        self.cards_by_id(&ids)
    }

    /// Cards by their ids, in that order, with two queries whatever their number (their rows, then their addresses)
    fn cards_by_id(&self, ids: &[CardId]) -> Result<Vec<Card>> {
        let mut cards = Vec::with_capacity(ids.len());
        let mut statement = self.db.prepare_cached(
            "SELECT id, name, first, last, nickname, company, notes, phones, extra FROM cards WHERE id = ?1",
        )?;
        let mut addresses = self
            .db
            .prepare_cached("SELECT address FROM card_addresses WHERE card_id = ?1 ORDER BY position")?;
        for &id in ids {
            let Some(mut card) = statement.query_row([id], card_row).optional()? else {
                continue;
            };
            card.addresses = addresses
                .query_map([id], |row| row.get(0))?
                .collect::<rusqlite::Result<_>>()?;
            cards.push(card);
        }
        Ok(cards)
    }

    /// Whether a card has this address
    pub fn has_address(&self, address: &str) -> Result<bool> {
        self.db
            .prepare_cached("SELECT 1 FROM card_addresses WHERE address = ?1 COLLATE NOCASE LIMIT 1")?
            .exists([address.trim()])
    }

    /// Cards read from a file into the book, in one transaction: a card whose addresses are all in the book (or in a
    /// card before it in the file) is left out. (added, left out)
    pub fn import_cards(&self, cards: &[Card]) -> Result<(u64, u64)> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let (mut added, mut skipped) = (0, 0);
        for card in cards {
            let known = !card.addresses.is_empty()
                && card.addresses.iter().try_fold(true, |all, address| {
                    Ok::<_, crate::Error>(all && self.has_address(address)?)
                })?;
            if known {
                skipped += 1;
                continue;
            }
            let id = self.write_card(card)?;
            if let Some(png) = &card.picture {
                self.set_card_picture(id, png)?;
            }
            added += 1;
        }
        tx.commit()?;
        Ok((added, skipped))
    }

    /// A card by its id
    pub fn card(&self, id: CardId) -> Result<Option<Card>> {
        Ok(self.cards_by_id(&[id])?.into_iter().next())
    }

    /// The card with this address, None when no card has it
    pub fn card_by_address(&self, address: &str) -> Result<Option<Card>> {
        let id: Option<CardId> = self
            .db
            .query_row(
                "SELECT card_id FROM card_addresses WHERE address = ?1 COLLATE NOCASE ORDER BY card_id LIMIT 1",
                [address.trim()],
                |row| row.get(0),
            )
            .optional()?;
        match id {
            Some(id) => self.card(id),
            None => Ok(None),
        }
    }

    /// Saves a card: a new one when its id is 0, else in place of the one with its id. Returns its id. The fields are
    /// trimmed and capped; addresses without `@` and repeated ones are left out.
    pub fn save_card(&self, card: &Card) -> Result<CardId> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let id = self.write_card(card)?;
        tx.commit()?;
        Ok(id)
    }

    /// [`Store::save_card`] inside the caller's transaction
    fn write_card(&self, card: &Card) -> Result<CardId> {
        let phones: String = card
            .phones
            .iter()
            .filter(|(_, number)| !number.trim().is_empty())
            .take(MAX_ADDRESSES)
            .map(|(kind, number)| {
                format!(
                    "{}\t{}\n",
                    capped(&kind.replace(['\t', '\n'], " "), 32),
                    capped(&number.replace(['\t', '\n'], " "), 64)
                )
            })
            .collect();
        let name = if card.name.trim().is_empty() {
            display_name(&card.first, &card.last)
        } else {
            card.name.clone()
        };
        let fields = (
            capped(&name, MAX_FIELD),
            capped(&card.first, MAX_FIELD),
            capped(&card.last, MAX_FIELD),
            capped(&card.nickname, MAX_FIELD),
            capped(&card.company, MAX_FIELD),
            capped(&card.notes, MAX_NOTES),
            phones,
            capped(&card.extra, MAX_NOTES),
        );
        let (name, first, last, nickname, company, notes, phones, extra) = &fields;
        let id = if card.id == 0 {
            self.db.execute(
                "INSERT INTO cards (name, first, last, nickname, company, notes, phones, extra) \
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
                params![name, first, last, nickname, company, notes, phones, extra],
            )?;
            self.db.last_insert_rowid()
        } else {
            self.db.execute(
                "UPDATE cards SET name = ?1, first = ?2, last = ?3, nickname = ?4, company = ?5, notes = ?6, \
                 phones = ?7, extra = ?8 WHERE id = ?9",
                params![name, first, last, nickname, company, notes, phones, extra, card.id],
            )?;
            card.id
        };
        self.db.execute("DELETE FROM card_addresses WHERE card_id = ?1", [id])?;
        let mut kept: Vec<String> = Vec::new();
        for address in &card.addresses {
            let address = capped(address, 320);
            if address.contains('@')
                && kept.len() < MAX_ADDRESSES
                && !kept.iter().any(|a| a.eq_ignore_ascii_case(&address))
            {
                kept.push(address);
            }
        }
        for (position, address) in kept.iter().enumerate() {
            self.db.execute(
                "INSERT INTO card_addresses (card_id, address, position) VALUES (?1, ?2, ?3)",
                params![id, address, position as i64],
            )?;
        }
        Ok(id)
    }

    /// Sets a card's picture: `png` is the core's own encoding (pe-core card_pictures.rs), never a file as it came; its
    /// revision grows so the windows' picture keys change with it
    pub fn set_card_picture(&self, card: CardId, png: &[u8]) -> Result<()> {
        self.db
            .prepare_cached(
                "INSERT INTO card_pictures (card_id, png, changed) VALUES (?1, ?2, 1) \
                 ON CONFLICT (card_id) DO UPDATE SET png = excluded.png, changed = card_pictures.changed + 1",
            )?
            .execute(params![card, png])?;
        Ok(())
    }

    /// Whether a card has a picture, without reading it
    pub fn has_card_picture(&self, card: CardId) -> Result<bool> {
        self.db
            .prepare_cached("SELECT 1 FROM card_pictures WHERE card_id = ?1")?
            .exists([card])
    }

    /// The card with a picture that has `address`, and its picture's revision: (card, revision); None when no card
    /// with a picture has it
    pub fn picture_of_address(&self, address: &str) -> Result<Option<(CardId, i64)>> {
        let address = address.trim();
        if address.is_empty() {
            return Ok(None);
        }
        self.db
            .prepare_cached(
                "SELECT p.card_id, p.changed FROM card_addresses a JOIN card_pictures p ON p.card_id = a.card_id \
                 WHERE a.address = ?1 COLLATE NOCASE ORDER BY a.card_id LIMIT 1",
            )?
            .query_row([address], |row| Ok((row.get(0)?, row.get(1)?)))
            .optional()
    }

    /// Takes a card's picture away
    pub fn remove_card_picture(&self, card: CardId) -> Result<()> {
        self.db
            .prepare_cached("DELETE FROM card_pictures WHERE card_id = ?1")?
            .execute([card])?;
        Ok(())
    }

    /// A card's picture (its PNG) and its revision, None when it has none
    pub fn card_picture(&self, card: CardId) -> Result<Option<(Vec<u8>, i64)>> {
        self.db
            .prepare_cached("SELECT png, changed FROM card_pictures WHERE card_id = ?1")?
            .query_row([card], |row| Ok((row.get(0)?, row.get(1)?)))
            .optional()
    }

    /// Deletes cards (from the groups they are in too)
    pub fn delete_cards(&self, ids: &[CardId]) -> Result<()> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        for id in ids {
            self.db.execute("DELETE FROM cards WHERE id = ?1", [id])?;
        }
        tx.commit()?;
        Ok(())
    }

    /// Deletes cards from the book (from the groups they are in too) and takes the addresses typed into `group` out
    /// of it, in one transaction
    pub fn delete_from_book(&self, group: Option<GroupId>, cards: &[CardId], addresses: &[String]) -> Result<()> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        for id in cards {
            self.db.execute("DELETE FROM cards WHERE id = ?1", [id])?;
        }
        if let Some(group) = group {
            for address in addresses {
                self.db.execute(
                    "DELETE FROM card_members WHERE group_id = ?1 AND card_id IS NULL AND address = ?2 COLLATE NOCASE",
                    params![group, address.trim()],
                )?;
            }
        }
        tx.commit()?;
        Ok(())
    }

    /// The groups, by name, with their members (a card's as its name and default address are now); with `filter`,
    /// those whose name (a word of it) starts with it
    pub fn groups(&self, filter: &str) -> Result<Vec<Group>> {
        let (start, word) = filter_patterns(filter);
        let mut statement = self.db.prepare_cached(
            "SELECT id FROM card_groups WHERE ?1 = '%' OR name LIKE ?1 ESCAPE '\\' OR name LIKE ?2 ESCAPE '\\' \
             ORDER BY name COLLATE NOCASE, id",
        )?;
        let ids: Vec<GroupId> = statement
            .query_map(params![start, word], |row| row.get(0))?
            .collect::<rusqlite::Result<_>>()?;
        ids.into_iter().filter_map(|id| self.group(id).transpose()).collect()
    }

    /// The members of group `id` in their order, each with what their card has now (name, default address, first
    /// phone, company); with `filter`, those found by it as [`Store::cards`] finds people: the name (a word of it),
    /// nickname, company or an address of the card, or the name or address typed
    pub fn group_people(&self, id: GroupId, filter: &str) -> Result<Vec<MemberRow>> {
        let (start, word) = filter_patterns(filter);
        let mut statement = self.db.prepare_cached(
            "SELECT m.card_id, COALESCE(c.name, m.name), \
             COALESCE((SELECT address FROM card_addresses a WHERE a.card_id = m.card_id ORDER BY position LIMIT 1), \
             m.address), COALESCE(c.phones, ''), COALESCE(c.company, '') \
             FROM card_members m LEFT JOIN cards c ON c.id = m.card_id WHERE m.group_id = ?1 AND (?2 = '%' \
             OR COALESCE(c.name, m.name) LIKE ?2 ESCAPE '\\' OR COALESCE(c.name, m.name) LIKE ?3 ESCAPE '\\' \
             OR c.nickname LIKE ?2 ESCAPE '\\' OR c.company LIKE ?2 ESCAPE '\\' \
             OR (m.card_id IS NULL AND m.address LIKE ?2 ESCAPE '\\') \
             OR m.card_id IN (SELECT card_id FROM card_addresses WHERE address LIKE ?2 ESCAPE '\\')) \
             ORDER BY m.position",
        )?;
        let rows = statement
            .query_map(params![id, start, word], |row| {
                let phones: String = row.get(3)?;
                Ok(MemberRow {
                    card: row.get(0)?,
                    name: row.get(1)?,
                    address: row.get(2)?,
                    phone: phones_of(&phones)
                        .into_iter()
                        .next()
                        .map(|(_, n)| n)
                        .unwrap_or_default(),
                    company: row.get(4)?,
                })
            })?
            .collect::<rusqlite::Result<_>>()?;
        Ok(rows)
    }

    /// A group by its id
    pub fn group(&self, id: GroupId) -> Result<Option<Group>> {
        let Some(name) = self
            .db
            .query_row("SELECT name FROM card_groups WHERE id = ?1", [id], |row| {
                row.get::<_, String>(0)
            })
            .optional()?
        else {
            return Ok(None);
        };
        let mut statement = self.db.prepare_cached(
            "SELECT m.card_id, COALESCE(c.name, m.name), \
             COALESCE((SELECT address FROM card_addresses a WHERE a.card_id = m.card_id ORDER BY position LIMIT 1), \
             m.address) \
             FROM card_members m LEFT JOIN cards c ON c.id = m.card_id WHERE m.group_id = ?1 ORDER BY m.position",
        )?;
        let members = statement
            .query_map([id], |row| {
                Ok(Member {
                    card: row.get(0)?,
                    name: row.get(1)?,
                    address: row.get(2)?,
                })
            })?
            .collect::<rusqlite::Result<_>>()?;
        Ok(Some(Group { id, name, members }))
    }

    /// Saves a group: a new one when its id is 0. Returns its id. A member that is a card is kept by its card (its
    /// name and address follow the card); others by their address.
    pub fn save_group(&self, group: &Group) -> Result<GroupId> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let name = capped(&group.name, MAX_FIELD);
        let id = if group.id == 0 {
            self.db.execute("INSERT INTO card_groups (name) VALUES (?1)", [&name])?;
            self.db.last_insert_rowid()
        } else {
            self.db.execute(
                "UPDATE card_groups SET name = ?1 WHERE id = ?2",
                params![name, group.id],
            )?;
            group.id
        };
        self.db.execute("DELETE FROM card_members WHERE group_id = ?1", [id])?;
        for (position, member) in group.members.iter().take(MAX_MEMBERS).enumerate() {
            if member.card.is_none() && !member.address.contains('@') {
                continue;
            }
            self.db.execute(
                "INSERT INTO card_members (group_id, card_id, name, address, position) VALUES (?1, ?2, ?3, ?4, ?5)",
                params![
                    id,
                    member.card,
                    capped(&member.name, MAX_FIELD),
                    capped(&member.address, 320),
                    position as i64
                ],
            )?;
        }
        tx.commit()?;
        Ok(id)
    }

    pub fn delete_group(&self, id: GroupId) -> Result<()> {
        self.db.execute("DELETE FROM card_groups WHERE id = ?1", [id])?;
        Ok(())
    }

    /// The cards (each address of them) and groups whose name, nickname or address starts with `typed`, for the
    /// completion of address fields: (name, address) of the cards, (group name, its members) of the groups
    pub fn book_matching(&self, typed: &str, limit: usize) -> Result<BookMatches> {
        let typed = typed.trim();
        if typed.is_empty() {
            return Ok((Vec::new(), Vec::new()));
        }
        let (start, word) = like_starts(typed);
        let mut statement = self.db.prepare_cached(
            "SELECT c.name, a.address FROM cards c JOIN card_addresses a ON a.card_id = c.id \
             WHERE c.name LIKE ?1 ESCAPE '\\' OR c.name LIKE ?2 ESCAPE '\\' OR c.nickname LIKE ?1 ESCAPE '\\' \
             OR a.address LIKE ?1 ESCAPE '\\' ORDER BY c.name COLLATE NOCASE, a.position LIMIT ?3",
        )?;
        let people = statement
            .query_map(params![start, word, limit as i64], |row| Ok((row.get(0)?, row.get(1)?)))?
            .collect::<rusqlite::Result<_>>()?;
        let mut statement = self.db.prepare_cached(
            "SELECT id FROM card_groups WHERE name LIKE ?1 ESCAPE '\\' OR name LIKE ?2 ESCAPE '\\' \
             ORDER BY name COLLATE NOCASE LIMIT ?3",
        )?;
        let ids: Vec<GroupId> = statement
            .query_map(params![start, word, limit as i64], |row| row.get(0))?
            .collect::<rusqlite::Result<_>>()?;
        let groups = ids
            .into_iter()
            .filter_map(|id| self.group(id).transpose())
            .collect::<Result<_>>()?;
        Ok((people, groups))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn card(name: &str, addresses: &[&str]) -> Card {
        Card {
            name: name.into(),
            addresses: addresses.iter().map(|a| a.to_string()).collect(),
            ..Default::default()
        }
    }

    #[test]
    fn keeps_cards_and_groups() {
        let store = Store::open_in_memory().unwrap();
        let mary = store
            .save_card(&Card {
                nickname: "Mo".into(),
                phones: vec![("cell".into(), "+1 555 0100".into())],
                ..card(
                    "Mary Smith",
                    &[
                        "mary@example.com",
                        "not an address",
                        "MARY@example.com",
                        "m@work.example",
                    ],
                )
            })
            .unwrap();
        let john = store.save_card(&card("John Doe", &["john@example.com"])).unwrap();
        let saved = store.card(mary).unwrap().unwrap();
        assert_eq!(
            saved.addresses,
            ["mary@example.com", "m@work.example"],
            "no repeats, no non-addresses"
        );
        assert_eq!(saved.phones, [("cell".to_string(), "+1 555 0100".to_string())]);
        assert_eq!(store.cards("").unwrap().len(), 2);
        assert_eq!(store.cards("smi").unwrap()[0].id, mary, "a word of the name");
        assert_eq!(store.cards("mo").unwrap()[0].id, mary, "the nickname");
        assert_eq!(store.cards("john@").unwrap()[0].id, john, "an address");
        assert!(store.cards("50%").unwrap().is_empty(), "wildcards taken as themselves");
        assert_eq!(
            store.card_by_address("M@WORK.example").unwrap().map(|c| c.id),
            Some(mary)
        );

        let team = store
            .save_group(&Group {
                name: "Team".into(),
                members: vec![
                    Member {
                        card: Some(mary),
                        ..Default::default()
                    },
                    Member {
                        card: None,
                        name: "Guest".into(),
                        address: "guest@example.org".into(),
                    },
                ],
                ..Default::default()
            })
            .unwrap();
        let group = store.group(team).unwrap().unwrap();
        assert_eq!(
            group
                .members
                .iter()
                .map(|m| (m.name.as_str(), m.address.as_str()))
                .collect::<Vec<_>>(),
            [("Mary Smith", "mary@example.com"), ("Guest", "guest@example.org")]
        );
        let (people, groups) = store.book_matching("te", 10).unwrap();
        assert!(people.is_empty());
        assert_eq!(groups[0].name, "Team");
        let (people, _) = store.book_matching("mar", 10).unwrap();
        assert_eq!(people.len(), 2, "each address of Mary");

        // a deleted card leaves the group
        store.delete_cards(&[mary]).unwrap();
        assert_eq!(store.group(team).unwrap().unwrap().members.len(), 1);
        store.delete_group(team).unwrap();
        assert!(store.groups("").unwrap().is_empty());
    }

    #[test]
    fn finds_groups_and_their_people() {
        let store = Store::open_in_memory().unwrap();
        let mary = store
            .save_card(&Card {
                company: "Acme".into(),
                phones: vec![
                    ("work".into(), "+1 555 0100".into()),
                    ("cell".into(), "+1 555 0101".into()),
                ],
                ..card("Mary Smith", &["mary@example.com", "m@work.example"])
            })
            .unwrap();
        let typed = |name: &str, address: &str| Member {
            card: None,
            name: name.into(),
            address: address.into(),
        };
        let team = store
            .save_group(&Group {
                name: "Sales Team".into(),
                members: vec![
                    Member {
                        card: Some(mary),
                        ..Default::default()
                    },
                    typed("Dave", "dave@example.org"),
                    typed("", "x_y@example.org"),
                ],
                ..Default::default()
            })
            .unwrap();
        store
            .save_group(&Group {
                name: "Family".into(),
                ..Default::default()
            })
            .unwrap();
        let names =
            |filter: &str| -> Vec<String> { store.groups(filter).unwrap().into_iter().map(|g| g.name).collect() };
        assert_eq!(names(""), ["Family", "Sales Team"]);
        assert_eq!(names("team"), ["Sales Team"], "a word of the name");
        assert_eq!(names("fam"), ["Family"]);
        assert!(names("%").is_empty(), "wildcards taken as themselves");

        let people = store.group_people(team, "").unwrap();
        assert_eq!(
            people[0],
            MemberRow {
                card: Some(mary),
                name: "Mary Smith".into(),
                address: "mary@example.com".into(),
                phone: "+1 555 0100".into(),
                company: "Acme".into(),
            }
        );
        assert_eq!(people.len(), 3);
        let found = |filter: &str| -> Vec<String> {
            store
                .group_people(team, filter)
                .unwrap()
                .into_iter()
                .map(|p| p.address)
                .collect()
        };
        assert_eq!(found("smi"), ["mary@example.com"]);
        assert_eq!(found("acme"), ["mary@example.com"]);
        assert_eq!(found("m@work"), ["mary@example.com"], "any address of the card");
        assert_eq!(found("dave"), ["dave@example.org"]);
        assert_eq!(found("x_"), ["x_y@example.org"]);
        assert!(found("xay").is_empty(), "_ is itself");

        // deleted: the card out of the book, a typed address out of the group
        store
            .delete_from_book(Some(team), &[mary], &["DAVE@example.org".to_string()])
            .unwrap();
        assert!(store.card(mary).unwrap().is_none());
        assert_eq!(found(""), ["x_y@example.org"]);
    }
}
