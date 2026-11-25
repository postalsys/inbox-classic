//! What agents read beyond one message: a conversation, the overview of their accounts, what came since they last
//! looked, and the people they may write to. Always of the accounts the program may use, counted in the store; the
//! text of each message is read through the one wall, [`Core::agent_message`].

use pe_store::{AccountCounts, AccountId, Message, Person, Scope, Search};

use super::AgentHost;
use crate::{Core, Result};

/// One account as an agent's overview shows it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AccountOverview {
    pub account: AccountId,
    pub name: String,
    pub email: String,
    pub counts: AccountCounts,
    /// The messages waiting in its Outbox
    pub outbox: u64,
}

/// A search of everything the program `host` may read
pub fn everywhere(host: &AgentHost) -> Search {
    Search {
        scope: Scope::Everywhere,
        accounts: Some(host.accounts.clone()),
        ..Default::default()
    }
}

/// The messages of a conversation, one of each: the same message in several folders (a Gmail label and All Mail) is
/// the one not in an all-mail folder
fn one_each(messages: Vec<Message>, all_mail: &[pe_store::FolderId]) -> Vec<Message> {
    let mut kept: Vec<Message> = Vec::with_capacity(messages.len());
    for message in messages {
        let same = message
            .info
            .message_id
            .as_ref()
            .and_then(|id| kept.iter().position(|k| k.info.message_id.as_ref() == Some(id)));
        match same {
            Some(at) if all_mail.contains(&kept[at].folder_id) && !all_mail.contains(&message.folder_id) => {
                kept[at] = message;
            }
            Some(_) => {}
            None => kept.push(message),
        }
    }
    kept
}

impl Core {
    /// Each account `host` may use, with its counts kept in the store and its Outbox
    pub fn agent_overview(&self, host: &AgentHost) -> Result<Vec<AccountOverview>> {
        let store = self.store();
        let outbox = store.outbox(None)?;
        let mut accounts = Vec::new();
        for account in store.accounts()? {
            if !host.accounts.contains(&account.id) {
                continue;
            }
            accounts.push(AccountOverview {
                account: account.id,
                name: account.settings.name.clone(),
                email: account.settings.email.clone(),
                counts: store.account_counts(account.id)?,
                outbox: outbox.iter().filter(|q| q.account_id == account.id).count() as u64,
            });
        }
        Ok(accounts)
    }

    /// The messages of conversation `thread` that `host` may read, oldest first, each message once
    pub fn agent_conversation(&self, host: &AgentHost, thread: i64) -> Result<Vec<Message>> {
        let store = self.store();
        let messages = store.thread_messages(&everywhere(host), thread)?;
        let mut all_mail = Vec::new();
        for &account in &host.accounts {
            all_mail.extend(store.special_folder(account, "\\All")?.map(|f| f.id));
        }
        Ok(one_each(messages, &all_mail))
    }

    /// The newest message stored, by its id: an agent's cursor for [`Core::stored_since`]
    pub fn newest_message(&self) -> Result<i64> {
        Ok(self.store().newest_message()?)
    }

    /// What `search` finds of the messages stored after `since`, in the order they were stored, at most `limit`
    pub fn stored_since(&self, search: &Search, since: i64, limit: u64) -> Result<Vec<Message>> {
        Ok(self.store().stored_since(search, since, limit)?)
    }

    /// Who wrote in each of conversations `threads` in what `search` finds, at most `most` a conversation
    pub fn thread_senders(
        &self,
        search: &Search,
        threads: &[i64],
        most: usize,
    ) -> Result<std::collections::HashMap<i64, Vec<(String, String)>>> {
        Ok(self.store().thread_senders(search, threads, most)?)
    }

    /// The people whose name or address starts with `typed`, for an agent: the address book's, and those of mail when
    /// it may use every account (the people of mail are not kept by account); and whether it may, so those are in
    pub fn agent_people(&self, host: &AgentHost, typed: &str, limit: usize) -> Result<(Vec<Person>, bool)> {
        let store = self.store();
        let every = store.accounts()?.iter().all(|a| host.accounts.contains(&a.id));
        Ok((store.people_matching(typed, limit, every)?, every))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn message(folder: i64, id: &str) -> Message {
        Message {
            id: 0,
            folder_id: folder,
            info: pe_store::MessageInfo {
                message_id: Some(id.into()),
                ..Default::default()
            },
            cached: false,
            thread: None,
            mark: Default::default(),
            snippet: None,
            sender_auth: 0,
            logo: None,
            contact: None,
            snippet_is_state: false,
            reactions: Vec::new(),
        }
    }

    #[test]
    fn a_conversation_has_each_message_once() {
        // All Mail (9) holds them again; the label's copy is the one kept, whichever came first
        let kept = one_each(
            vec![
                message(9, "<a>"),
                message(1, "<a>"),
                message(1, "<b>"),
                message(9, "<b>"),
                message(2, "<c>"),
            ],
            &[9],
        );
        let shown: Vec<(i64, &str)> = kept
            .iter()
            .map(|m| (m.folder_id, m.info.message_id.as_deref().unwrap()))
            .collect();
        assert_eq!(shown, [(1, "<a>"), (1, "<b>"), (2, "<c>")]);
    }
}
