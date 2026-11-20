//! The servers of the world: one ImapKit an account (ImapKit has one mailbox tree), started from the storage files
//! world.rs wrote, and what they hold, asked over ImapKit's REST API: the truth the checks compare the window with.

use std::collections::HashMap;
use std::path::PathBuf;

use pe_testkit::ImapKit;
use serde_json::{Value, json};

use crate::world::World;

/// An account's server
pub struct AccountServer {
    pub name: String,
    pub email: String,
    pub kit: ImapKit,
}

/// A mailbox as the server counts it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Counted {
    /// The path as the user sees it
    pub path: String,
    pub messages: u64,
    pub unseen: u64,
    pub special_use: Option<String>,
}

/// A message as the server lists it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Listed {
    pub uid: u64,
    pub flags: Vec<String>,
}

impl Listed {
    pub fn seen(&self) -> bool {
        self.flags.iter().any(|f| f == "\\Seen")
    }

    pub fn flagged(&self) -> bool {
        self.flags.iter().any(|f| f == "\\Flagged")
    }
}

/// The world's servers, running until dropped
pub struct Servers {
    pub accounts: Vec<AccountServer>,
}

impl Servers {
    /// One ImapKit an account of `world`, started from `storages` (world.rs `write`); None when ImapKit can not run
    /// (core/e2e has no node_modules)
    pub fn start(world: &World, storages: &[PathBuf]) -> Option<Servers> {
        let mut accounts = Vec::new();
        for (account, storage) in world.accounts.iter().zip(storages) {
            let kit = ImapKit::start(json!({ "storageFile": storage }))?;
            accounts.push(AccountServer {
                name: account.name.clone(),
                email: account.email.clone(),
                kit,
            });
        }
        Some(Servers { accounts })
    }

    pub fn account(&self, name: &str) -> Option<&AccountServer> {
        self.accounts.iter().find(|a| a.name == name)
    }
}

/// A path as the user sees it in ImapKit's storage names: modified UTF-7 a level
pub fn storage_name(path: &str) -> String {
    path.split('/').map(pe_imap::utf7::encode).collect::<Vec<_>>().join("/")
}

/// The path the user sees of a storage name
pub fn user_path(name: &str) -> String {
    pe_core::folder_path_decoded(name)
}

impl AccountServer {
    /// Every mailbox with its counts, by the path the user sees
    pub fn counted(&self) -> Vec<Counted> {
        self.kit
            .mailboxes()
            .iter()
            .filter(|m| m["selectable"].as_bool().unwrap_or(true))
            .map(|m| Counted {
                path: user_path(m["path"].as_str().unwrap_or_default()),
                messages: m["messages"].as_u64().unwrap_or(0),
                unseen: m["unseen"].as_u64().unwrap_or(0),
                special_use: m["specialUse"]
                    .as_array()
                    .and_then(|s| s.first())
                    .and_then(Value::as_str)
                    .map(str::to_string),
            })
            .collect()
    }

    /// The messages of `path` by UID, without their sources
    pub fn listed(&self, path: &str) -> HashMap<u64, Listed> {
        self.kit
            .message_list(&storage_name(path))
            .iter()
            .filter_map(|m| {
                let uid = m["uid"].as_u64()?;
                let flags = m["flags"]
                    .as_array()
                    .map(|f| f.iter().filter_map(|x| x.as_str().map(str::to_string)).collect())
                    .unwrap_or_default();
                Some((uid, Listed { uid, flags }))
            })
            .collect()
    }

    /// A message delivered to `path` as another client or the server's own delivery would; its UID
    pub fn deliver(&self, path: &str, raw: &str, flags: &[&str]) -> u64 {
        self.kit.add_message(&storage_name(path), raw, flags)
    }

    /// Flags changed by another client
    pub fn flags(&self, path: &str, uids: &[u64], flags: &[&str], action: &str) {
        self.kit.set_flags(&storage_name(path), uids, flags, action);
    }

    /// Messages expunged by another client
    pub fn expunge(&self, path: &str, uids: &[u64]) {
        self.kit.expunge(&storage_name(path), uids);
    }

    /// A folder renamed by another client
    pub fn rename(&self, path: &str, to: &str) {
        self.kit.request(
            "POST",
            &format!("/v1/mailboxes/{}/rename", pe_testkit::encode_path(&storage_name(path))),
            Some(json!({ "newPath": storage_name(to) })),
        );
    }

    /// The folder's UIDVALIDITY changed, as a server that rebuilt it does: every UID new
    pub fn new_uidvalidity(&self, path: &str) {
        self.kit.request(
            "POST",
            &format!(
                "/v1/mailboxes/{}/uidvalidity",
                pe_testkit::encode_path(&storage_name(path))
            ),
            Some(json!({})),
        );
    }

    /// A fault of the server's (ImapKit's script rule: `on`, `match`, `delay`, `close`, `send`, `times`); its id
    pub fn fault(&self, rule: Value) -> String {
        let answer = self.kit.request("POST", "/v1/script/rules", Some(rule));
        answer["id"]
            .as_str()
            .map_or_else(|| answer["id"].to_string(), str::to_string)
    }

    /// Every fault taken away
    pub fn mend(&self) {
        self.kit.request("DELETE", "/v1/script/rules", None);
    }

    /// The account's password changed on the server (as by its owner elsewhere), or set back
    pub fn set_password(&self, password: &str) {
        self.kit.request(
            "PUT",
            &format!("/v1/users/{}", pe_testkit::USER),
            Some(json!({ "password": password })),
        );
    }

    /// The IMAP sessions open now
    pub fn sessions(&self) -> usize {
        match self.kit.request("GET", "/v1/sessions", None) {
            Value::Array(sessions) => sessions.len(),
            _ => 0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn paths_go_to_storage_names_and_back() {
        for path in [
            "INBOX",
            "Projects/Projects 01",
            "Ελληνικά/budget 1",
            "日本語/notes 2/plan 3",
        ] {
            assert_eq!(user_path(&storage_name(path)), path);
        }
        assert_eq!(storage_name("Ελληνικά"), pe_imap::utf7::encode("Ελληνικά"));
    }
}
