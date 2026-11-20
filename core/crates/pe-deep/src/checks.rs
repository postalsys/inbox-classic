//! The checks that always hold, run after every step: what the window shows against what the servers have. Each
//! compares an outcome (rows, their messages, their order, the counts), never how the app got there
//! (docs/testing.md).

use std::collections::{BTreeMap, HashMap, HashSet};

use crate::model::{List, Message, Seen, SortBy};
use crate::servers::{Counted, Listed, Servers};

/// A check that did not hold
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Failure {
    /// Which check: `rows`, `blank`, `ghost`, `order`, `twice`, `pane`, `tree`, `scope`, `flagged`
    pub check: &'static str,
    pub detail: String,
}

fn failure(check: &'static str, detail: String) -> Failure {
    Failure { check, detail }
}

/// What the servers hold, read once a check: each account's mailboxes with their counts, and the messages of the
/// folders asked for
pub struct Truth<'a> {
    servers: &'a Servers,
    counted: HashMap<String, Vec<Counted>>,
    listed: HashMap<(String, String), HashMap<u64, Listed>>,
}

impl<'a> Truth<'a> {
    /// What the servers count now, for `Truth::cached` until the next read
    pub fn counted_now(&self) -> HashMap<String, Vec<Counted>> {
        self.counted.clone()
    }

    /// A check before quiet: the folders as last read (their special uses do not change), no message lists read
    pub fn cached(servers: &'a Servers, counted: HashMap<String, Vec<Counted>>) -> Truth<'a> {
        Truth {
            servers,
            counted,
            listed: HashMap::new(),
        }
    }

    pub fn read(servers: &'a Servers) -> Truth<'a> {
        let counted = servers.accounts.iter().map(|a| (a.name.clone(), a.counted())).collect();
        Truth {
            servers,
            counted,
            listed: HashMap::new(),
        }
    }

    pub fn counted(&self, account: &str, path: &str) -> Option<&Counted> {
        self.counted.get(account)?.iter().find(|c| c.path == path)
    }

    /// The folders of a special use (`\Sent`) of every account
    fn special(&self, use_: &str) -> impl Iterator<Item = &Counted> {
        self.counted
            .values()
            .flatten()
            .filter(move |c| c.special_use.as_deref() == Some(use_))
    }

    /// The messages of a folder, read the first time it is asked for
    pub fn listed(&mut self, account: &str, path: &str) -> &HashMap<u64, Listed> {
        let key = (account.to_string(), path.to_string());
        if !self.listed.contains_key(&key) {
            let listed = self
                .servers
                .account(account)
                .map(|a| a.listed(path))
                .unwrap_or_default();
            self.listed.insert(key.clone(), listed);
        }
        &self.listed[&key]
    }

    /// How many messages a list has with nothing hidden, None where the server can not say cheaply (Flagged)
    fn messages_of(&self, list: &List) -> Option<u64> {
        Some(match list {
            List::Folder { account, path } => self.counted(account, path)?.messages,
            List::AllInboxes => self
                .counted
                .values()
                .flatten()
                .filter(|c| c.path == "INBOX")
                .map(|c| c.messages)
                .sum(),
            List::AllSent => self.special("\\Sent").map(|c| c.messages).sum(),
            List::AllDrafts => self.special("\\Drafts").map(|c| c.messages).sum(),
            List::Flagged => return None,
        })
    }

    fn unseen_of(&self, list: &List) -> Option<u64> {
        match list {
            List::Folder { account, path } => Some(self.counted(account, path)?.unseen),
            List::AllInboxes => Some(
                self.counted
                    .values()
                    .flatten()
                    .filter(|c| c.path == "INBOX")
                    .map(|c| c.unseen)
                    .sum(),
            ),
            _ => None,
        }
    }

    /// Whether a message of `account` in `path` belongs in `list`
    fn in_scope(&self, list: &List, message: &Message) -> bool {
        let special = || {
            self.counted(&message.account, &message.path)
                .and_then(|c| c.special_use.clone())
        };
        match list {
            List::Folder { account, path } => *account == message.account && *path == message.path,
            List::AllInboxes => message.path == "INBOX",
            List::AllSent => special().as_deref() == Some("\\Sent"),
            List::AllDrafts => special().as_deref() == Some("\\Drafts"),
            List::Flagged => !matches!(special().as_deref(), Some("\\Trash" | "\\Junk")),
        }
    }
}

/// How the list is drawn, as the conductor set it: what the checks of order and count need to know
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Shape {
    pub sort: SortBy,
    pub ascending: bool,
}

impl Default for Shape {
    fn default() -> Shape {
        Shape {
            sort: SortBy::Date,
            ascending: false,
        }
    }
}

/// The checks after a step. `settled`: the target said nothing is under way, so what may lag (a page on its way, a
/// count the sync has not reached) must be there now.
/// `reading`: the folders of the messages shown in the last steps, left out of the counts: a message is marked read a
/// second after it is shown, which reaches the server with the sync after it, so their counts may be one behind
pub fn always(
    seen: &Seen,
    truth: &mut Truth<'_>,
    shape: Shape,
    settled: bool,
    reading: &[(String, String)],
) -> Vec<Failure> {
    let mut failures = Vec::new();
    let Some(list) = seen.list.clone() else {
        return failures;
    };
    let whole = seen.search.is_empty() && !seen.unread_only;
    // the rows the list has: every message of the list, one a row while not grouped
    if settled
        && whole
        && !seen.grouped
        && let Some(messages) = truth.messages_of(&list)
        && seen.rows != messages
    {
        let label = list.label();
        failures.push(failure(
            "rows",
            format!("{label} lists {} rows, the server has {messages} messages", seen.rows),
        ));
    }
    if settled
        && seen.search.is_empty()
        && seen.unread_only
        && !seen.grouped
        && let Some(unseen) = truth.unseen_of(&list)
        && seen.rows < unseen
    {
        let label = list.label();
        failures.push(failure(
            "rows",
            format!(
                "{label} unread only lists {} rows, the server has {unseen} unread",
                seen.rows
            ),
        ));
    }
    if settled && let Some(blank) = seen.sight.iter().find(|r| r.blank) {
        failures.push(failure(
            "blank",
            format!("row {} is in sight and blank once all is done", blank.row),
        ));
    }
    // the rows in sight: messages the server has, of this list, each once
    let mut twice = HashSet::new();
    let mut by_folder: BTreeMap<(String, String), Vec<(u64, u64)>> = BTreeMap::new();
    for row in &seen.sight {
        let Some(message) = &row.message else { continue };
        if !twice.insert(message.clone()) && !seen.grouped {
            failures.push(failure(
                "twice",
                format!("{message:?} is in sight twice (row {})", row.row),
            ));
        }
        if seen.search.is_empty() && !truth.in_scope(&list, message) {
            failures.push(failure(
                "scope",
                format!("row {} shows {message:?}, which is not of {}", row.row, list.label()),
            ));
        }
        by_folder
            .entry((message.account.clone(), message.path.clone()))
            .or_default()
            .push((row.row, message.uid));
    }
    if settled {
        for ((account, path), rows) in by_folder {
            let listed = truth.listed(&account, &path);
            for (row, uid) in rows {
                match listed.get(&uid) {
                    None => failures.push(failure(
                        "ghost",
                        format!("row {row} shows {account}/{path} UID {uid}, which the server does not have"),
                    )),
                    // words typed search every folder, whatever the list
                    Some(m) if list == List::Flagged && seen.search.is_empty() && !m.flagged() => {
                        failures.push(failure(
                            "flagged",
                            format!("row {row} of Flagged shows {account}/{path} UID {uid}, not flagged on the server"),
                        ))
                    }
                    Some(_) => {}
                }
            }
        }
    }
    // in the order of the dates, while sorted by date and one row a message
    if shape.sort == SortBy::Date && !seen.grouped {
        let drawn: Vec<&crate::model::Row> = seen.sight.iter().filter(|r| !r.blank).collect();
        for pair in drawn.windows(2) {
            let (a, b) = (pair[0], pair[1]);
            let wrong = if shape.ascending {
                a.date > b.date
            } else {
                a.date < b.date
            };
            if b.row == a.row + 1 && wrong {
                failures.push(failure(
                    "order",
                    format!(
                        "rows {} and {} are out of the order of their dates ({} {})",
                        a.row, b.row, a.date, b.date
                    ),
                ));
            }
        }
    }
    // the message of the one row selected is the one shown
    if settled
        && let [only] = seen.selected.as_slice()
        && !seen.grouped
        && let Some(row) = seen.at(*only)
        && !row.blank
        && row.message != seen.shown
    {
        failures.push(failure(
            "pane",
            format!(
                "row {only} is selected ({:?}) and the reading pane shows {:?}",
                row.message, seen.shown
            ),
        ));
    }
    if settled {
        for (account, path, unread) in &seen.tree {
            if reading.iter().any(|(a, p)| a == account && p == path) {
                continue;
            }
            if let Some(counted) = truth.counted(account, path)
                && counted.unseen != *unread
            {
                failures.push(failure(
                    "tree",
                    format!(
                        "{account}/{path} shows {unread} unread, the server has {}",
                        counted.unseen
                    ),
                ));
            }
        }
    }
    failures
}
