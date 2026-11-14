//! Message rules: for the new mail of an Inbox, a search query and what to do with the messages that match it (mark
//! read, flag, move, archive, junk, delete, or not announce them). The query is the search box's own, matched by the
//! store's search limited to the messages that just arrived, so a rule finds exactly what the same search would.
//! Rules run in their order; every rule that matches does its part, and one that sends a message away (move,
//! archive, junk, delete) is the last for it. A rule never sends anything or deletes for good, and the AI agents have
//! no way to them.

use pe_i18n::{Text, tr_args};
use pe_store::{AccountId, FolderId, Rule, RuleId, Scope, Search, Store};

use crate::{Core, Error, Result};

/// Where a message goes from its Inbox by the first rule that sends it away
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub(crate) enum Away {
    Move(FolderId),
    Archive,
    Junk(FolderId),
    Delete(FolderId),
}

/// What the rules do with one message
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub(crate) struct Plan {
    pub(crate) read: bool,
    pub(crate) flag: bool,
    /// Not announced as new mail
    pub(crate) quiet: bool,
    pub(crate) away: Option<Away>,
}

impl Plan {
    fn does_something(&self) -> bool {
        self.read || self.flag || self.quiet || self.away.is_some()
    }
}

/// What `rules` (enabled, of this account or every account's, in their order) do with the messages `uids` of the
/// Inbox `folder` of `account`, by UID; those no rule matched are left out
pub(crate) fn plan(
    store: &Store,
    account: AccountId,
    folder: FolderId,
    uids: &[u64],
    rules: &[Rule],
) -> pe_store::Result<Vec<(u64, Plan)>> {
    let mut plans: Vec<(u64, Plan)> = uids.iter().map(|&uid| (uid, Plan::default())).collect();
    let trash = store.special_folder(account, "\\Trash")?.map(|f| f.id);
    let junk = store.special_folder(account, "\\Junk")?.map(|f| f.id);
    for rule in rules.iter().filter(|rule| rule.applies_to(account)) {
        // the messages not sent away by a rule before
        let open: Vec<u64> = plans
            .iter()
            .filter(|(_, p)| p.away.is_none())
            .map(|(uid, _)| *uid)
            .collect();
        if open.is_empty() {
            break;
        }
        // searched a few hundred at a time: SQLite takes only so many values in one statement
        let mut matched = std::collections::HashSet::new();
        for chunk in open.chunks(500) {
            let search = Search {
                scope: Scope::Folder(folder),
                text: rule.query.clone(),
                uids: Some(chunk.to_vec()),
                ..Default::default()
            };
            matched.extend(
                store
                    .search(&search, pe_store::Sort::default(), 0, u32::MAX as u64)?
                    .into_iter()
                    .map(|m| m.info.uid),
            );
        }
        // a folder of this account only: one of another account's is that account's rule
        let move_to = match rule.move_to {
            Some(to) if to != folder => store.folder(to).ok().filter(|f| f.account_id == account).map(|f| f.id),
            _ => None,
        };
        let away = if rule.remove {
            trash.map(Away::Delete)
        } else if rule.junk {
            junk.map(Away::Junk)
        } else if rule.archive {
            Some(Away::Archive)
        } else {
            move_to.map(Away::Move)
        };
        for (_, plan) in plans.iter_mut().filter(|(uid, _)| matched.contains(uid)) {
            plan.read |= rule.mark_read;
            plan.flag |= rule.flag;
            plan.quiet |= rule.quiet || rule.mark_read || rule.junk || rule.remove;
            if plan.away.is_none() {
                plan.away = away;
            }
        }
    }
    plans.retain(|(_, plan)| plan.does_something());
    Ok(plans)
}

impl Core {
    /// The message rules, in their order
    pub fn rules(&self) -> Result<Vec<Rule>> {
        Ok(self.store().rules()?)
    }

    pub fn rule(&self, id: RuleId) -> Result<Option<Rule>> {
        Ok(self.store().rule(id)?)
    }

    /// Why a rule's query can not be one, in words: it names a folder or a date (a rule is for the new mail of an
    /// Inbox); None when it can
    pub fn rule_query_problem(&self, query: &str) -> Option<String> {
        let refused = pe_store::Query::rule_problems(query);
        (!refused.is_empty()).then(|| tr_args(Text::RuleQueryRefused, &[("words", (&refused.join(", ")).into())]))
    }

    /// Saves a rule (a new one, id 0, last); its id. A query that can not be a rule's, or a rule that does nothing,
    /// is refused with the reason; one without a name gets its query as its name.
    pub fn save_rule(&self, rule: &Rule) -> Result<RuleId> {
        if let Some(problem) = self.rule_query_problem(&rule.query) {
            return Err(Error::Invalid(problem));
        }
        if rule.query.trim().is_empty() {
            return Err(Error::Invalid(pe_i18n::tr(Text::RuleNoQuery)));
        }
        if !rule.acts() {
            return Err(Error::Invalid(pe_i18n::tr(Text::RuleNoAction)));
        }
        // a rule without a name is called by what it matches
        let query = rule.query.trim().to_string();
        let name = match rule.name.trim() {
            "" => query.clone(),
            name => name.to_string(),
        };
        Ok(self.store().save_rule(&Rule {
            name,
            query,
            ..rule.clone()
        })?)
    }

    pub fn delete_rule(&self, id: RuleId) -> Result<()> {
        Ok(self.store().delete_rule(id)?)
    }

    pub fn move_rule(&self, id: RuleId, up: bool) -> Result<bool> {
        Ok(self.store().move_rule(id, up)?)
    }

    /// How many messages in the Inbox (of `account`, or of every account) `query` matches now, for the rule editor
    pub fn rule_matches(&self, query: &str, account: Option<AccountId>) -> Result<u64> {
        if query.trim().is_empty() || self.rule_query_problem(query).is_some() {
            return Ok(0);
        }
        let store = self.store();
        // every Inbox at once, or the one account's
        let scope = match account {
            None => Scope::AllInboxes,
            Some(account) => match store.find_folder(account, "INBOX")? {
                Some(inbox) => Scope::Folder(inbox.id),
                None => return Ok(0),
            },
        };
        let search = Search {
            scope,
            text: query.to_string(),
            ..Default::default()
        };
        Ok(store.count_search(&search)?.0)
    }

    /// The search that shows what `query` matches in the Inboxes now, as the search box would show it (the editor's
    /// Show): the query with `in:inbox`
    pub fn rule_search_text(&self, query: &str) -> String {
        format!("in:inbox {query}")
    }

    /// What a rule made from a message starts with: `list:` its mailing list, or `from:` its sender
    pub fn rule_query_of_message(&self, folder: FolderId, uid: u64) -> Result<String> {
        let store = self.store();
        if let Some(list) = store.list_id(folder, uid)? {
            return Ok(format!("list:{list}"));
        }
        let message = store.message(folder, uid)?.ok_or(Error::NotFound)?;
        Ok(format!("from:{}", message.info.from_address))
    }

    /// The folders a rule can move messages to, for its editor: each account's, in the tree's order, but its Inbox,
    /// its Sent Items, Drafts, Junk E-mail, Deleted Items and Gmail's all-mail folders, and the folders that hold no
    /// messages, each as (folder, account, the words shown: the account and the folder,
    /// indented as in the tree)
    pub fn rule_targets(&self) -> Result<Vec<(FolderId, AccountId, String)>> {
        let store = self.store();
        let accounts = store.accounts()?;
        let titles = crate::account_titles(&accounts);
        let several = accounts.len() > 1;
        let mut targets = Vec::new();
        for (account, title) in accounts.iter().zip(&titles) {
            let folders = store.folders(account.id)?;
            let infos: Vec<&pe_store::FolderInfo> = folders.iter().map(|f| &f.info).collect();
            let depths = crate::tree_depths(&infos);
            for (folder, depth) in folders.iter().zip(depths) {
                // nor the folders a rule would not move mail to (Junk and Deleted Items have actions of their own)
                let special = folder.info.special_use.as_deref();
                if !folder.info.selectable
                    || folder.info.path.eq_ignore_ascii_case("INBOX")
                    || matches!(
                        special,
                        Some("\\Sent" | "\\Drafts" | "\\Junk" | "\\Trash" | "\\All" | "\\Flagged")
                    )
                {
                    continue;
                }
                let name = format!("{}{}", "    ".repeat(depth), crate::folder_name(&folder.info));
                let label = if several {
                    format!("{title}: {}", name.trim_start())
                } else {
                    name
                };
                targets.push((folder.id, account.id, label));
            }
        }
        Ok(targets)
    }

    /// Runs one rule over the messages already in the Inbox (of its account or every account's), in the background
    pub fn apply_rule_now(&self, id: RuleId) -> Result<()> {
        let rule = self.store().rule(id)?.ok_or(Error::NotFound)?;
        let inboxes: Vec<(AccountId, FolderId)> = {
            let store = self.store();
            store
                .inboxes()?
                .into_iter()
                .filter_map(|inbox| store.folder(inbox).ok().map(|f| (f.account_id, inbox)))
                .filter(|(account, _)| rule.account.is_none_or(|a| a == *account))
                .collect()
        };
        for (account, folder) in inboxes {
            self.send_command(account, crate::worker::Command::ApplyRules { folder, rule: Some(id) })?;
        }
        Ok(())
    }
}
