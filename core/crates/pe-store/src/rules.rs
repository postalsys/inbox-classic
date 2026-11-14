//! Message rules: a search query and what to do with the new mail of an Inbox that matches it, kept in the order the
//! user put them in (pe-core rules.rs runs them)

use rusqlite::{OptionalExtension, params};

use crate::{AccountId, FolderId, Result, Store};

pub type RuleId = i64;

/// A message rule
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Rule {
    pub id: RuleId,
    pub enabled: bool,
    pub name: String,
    /// The account whose Inbox it is for, None for every account's
    pub account: Option<AccountId>,
    /// What the new mail has to match, in the search box's words
    pub query: String,
    /// Moved to this folder (of the account the folder is in)
    pub move_to: Option<FolderId>,
    pub mark_read: bool,
    pub flag: bool,
    pub archive: bool,
    pub junk: bool,
    /// Into Deleted Items
    pub remove: bool,
    /// Not announced as new mail
    pub quiet: bool,
}

impl Rule {
    /// Whether it does anything with what it matches
    pub fn acts(&self) -> bool {
        self.mark_read || self.flag || self.quiet || self.archive || self.junk || self.remove || self.move_to.is_some()
    }

    /// Whether it runs on the new mail of `account`'s Inbox
    pub fn applies_to(&self, account: AccountId) -> bool {
        self.enabled && self.account.is_none_or(|a| a == account) && !self.query.trim().is_empty()
    }
}

const COLUMNS: &str = "id, enabled, name, account_id, query, move_to, mark_read, flag, archive, junk, remove, quiet";

fn from_row(row: &rusqlite::Row) -> rusqlite::Result<Rule> {
    Ok(Rule {
        id: row.get(0)?,
        enabled: row.get(1)?,
        name: row.get(2)?,
        account: row.get(3)?,
        query: row.get(4)?,
        move_to: row.get(5)?,
        mark_read: row.get(6)?,
        flag: row.get(7)?,
        archive: row.get(8)?,
        junk: row.get(9)?,
        remove: row.get(10)?,
        quiet: row.get(11)?,
    })
}

impl Store {
    /// The rules, in their order
    pub fn rules(&self) -> Result<Vec<Rule>> {
        let mut statement = self
            .db
            .prepare_cached(&format!("SELECT {COLUMNS} FROM rules ORDER BY position, id"))?;
        statement.query_map([], from_row)?.collect()
    }

    pub fn rule(&self, id: RuleId) -> Result<Option<Rule>> {
        self.db
            .query_row(&format!("SELECT {COLUMNS} FROM rules WHERE id = ?1"), [id], from_row)
            .optional()
    }

    /// Saves a rule: a new one (id 0) last, its id; one there is changed where it is
    pub fn save_rule(&self, rule: &Rule) -> Result<RuleId> {
        let values = params![
            rule.enabled,
            rule.name,
            rule.account,
            rule.query,
            rule.move_to,
            rule.mark_read,
            rule.flag,
            rule.archive,
            rule.junk,
            rule.remove,
            rule.quiet,
            rule.id,
        ];
        if rule.id != 0 {
            self.db.execute(
                "UPDATE rules SET enabled = ?1, name = ?2, account_id = ?3, query = ?4, move_to = ?5, mark_read = ?6, \
                 flag = ?7, archive = ?8, junk = ?9, remove = ?10, quiet = ?11 WHERE id = ?12",
                values,
            )?;
            return Ok(rule.id);
        }
        self.db.execute(
            "INSERT INTO rules (enabled, name, account_id, query, move_to, mark_read, flag, archive, junk, remove, \
             quiet, position) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, \
             (SELECT COALESCE(MAX(position), 0) + 1 FROM rules) + 0 * ?12)",
            values,
        )?;
        Ok(self.db.last_insert_rowid())
    }

    pub fn delete_rule(&self, id: RuleId) -> Result<()> {
        self.db.execute("DELETE FROM rules WHERE id = ?1", [id])?;
        Ok(())
    }

    /// Moves a rule one place up (earlier) or down; false when it is first or last already
    pub fn move_rule(&self, id: RuleId, up: bool) -> Result<bool> {
        let ids: Vec<RuleId> = self.rules()?.iter().map(|r| r.id).collect();
        let Some(at) = ids.iter().position(|&r| r == id) else {
            return Ok(false);
        };
        let other = if up {
            at.checked_sub(1)
        } else {
            Some(at + 1).filter(|&o| o < ids.len())
        };
        let Some(other) = other else {
            return Ok(false);
        };
        let mut order = ids;
        order.swap(at, other);
        for (position, rule) in order.iter().enumerate() {
            self.db.execute(
                "UPDATE rules SET position = ?2 WHERE id = ?1",
                params![rule, position as i64],
            )?;
        }
        Ok(true)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::AccountSettings;

    #[test]
    fn rules_are_kept_in_order_changed_moved_and_deleted() {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let rule = |name: &str| Rule {
            enabled: true,
            name: name.into(),
            query: format!("from:{name}"),
            mark_read: true,
            ..Default::default()
        };
        let first = store.save_rule(&rule("one")).unwrap();
        let second = store
            .save_rule(&Rule {
                account: Some(account),
                ..rule("two")
            })
            .unwrap();
        let names = |store: &Store| store.rules().unwrap().into_iter().map(|r| r.name).collect::<Vec<_>>();
        assert_eq!(names(&store), ["one", "two"]);
        assert!(store.move_rule(second, true).unwrap());
        assert_eq!(names(&store), ["two", "one"]);
        assert!(!store.move_rule(second, true).unwrap());
        let mut changed = store.rule(first).unwrap().unwrap();
        changed.enabled = false;
        changed.query = "list:news".into();
        store.save_rule(&changed).unwrap();
        assert_eq!(store.rule(first).unwrap().unwrap(), changed);
        store.delete_rule(second).unwrap();
        assert_eq!(names(&store), ["one"]);
        // an account that goes takes its rules along
        store
            .save_rule(&Rule {
                account: Some(account),
                ..rule("three")
            })
            .unwrap();
        store.remove_account(account).unwrap();
        assert_eq!(names(&store), ["one"]);
    }
}
