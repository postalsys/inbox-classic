//! What the conductor asks of a target and what a target says it shows: the words of the drivers' protocol, one JSON
//! object a line each way (`docs/deep-test-plan.md`, "The drivers"). A target is the core without a window
//! (core_target.rs) or an app's UI test, through its driver (driver.rs).

use serde_json::{Value, json};

/// A list of the folder tree
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum List {
    /// A folder of an account (by the account's name), its path as the user sees it, `/` between levels
    Folder {
        account: String,
        path: String,
    },
    AllInboxes,
    Flagged,
    AllSent,
    AllDrafts,
}

impl List {
    pub fn folder(account: &str, path: &str) -> List {
        List::Folder {
            account: account.into(),
            path: path.into(),
        }
    }

    pub fn to_json(&self) -> Value {
        match self {
            List::Folder { account, path } => json!({ "account": account, "path": path }),
            List::AllInboxes => json!("inboxes"),
            List::Flagged => json!("flagged"),
            List::AllSent => json!("sent"),
            List::AllDrafts => json!("drafts"),
        }
    }

    pub fn from_json(value: &Value) -> Option<List> {
        Some(match value {
            Value::String(kind) => match kind.as_str() {
                "inboxes" => List::AllInboxes,
                "flagged" => List::Flagged,
                "sent" => List::AllSent,
                "drafts" => List::AllDrafts,
                _ => return None,
            },
            Value::Object(_) => List::Folder {
                account: value["account"].as_str()?.into(),
                path: value["path"].as_str()?.into(),
            },
            _ => return None,
        })
    }

    pub fn label(&self) -> String {
        match self {
            List::Folder { account, path } => format!("{account}/{path}"),
            List::AllInboxes => "All Inboxes".into(),
            List::Flagged => "Flagged".into(),
            List::AllSent => "All Sent".into(),
            List::AllDrafts => "All Drafts".into(),
        }
    }
}

/// What the list is sorted by
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SortBy {
    Date,
    Subject,
    From,
    Size,
}

impl From<SortBy> for pe_store::SortField {
    fn from(by: SortBy) -> pe_store::SortField {
        match by {
            SortBy::Date => pe_store::SortField::Date,
            SortBy::Subject => pe_store::SortField::Subject,
            SortBy::From => pe_store::SortField::From,
            SortBy::Size => pe_store::SortField::Size,
        }
    }
}

impl SortBy {
    pub const ALL: [SortBy; 4] = [SortBy::Date, SortBy::Subject, SortBy::From, SortBy::Size];

    pub fn name(self) -> &'static str {
        match self {
            SortBy::Date => "date",
            SortBy::Subject => "subject",
            SortBy::From => "from",
            SortBy::Size => "size",
        }
    }

    pub fn parse(name: &str) -> Option<SortBy> {
        SortBy::ALL.into_iter().find(|s| s.name() == name)
    }
}

/// One thing a user does: what the target's hand does, a click or a key, never a call into the core of the app's
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Act {
    /// A row of the folder tree chosen
    Open(List),
    /// The list scrolled so `row` is the first in sight
    Scroll(u64),
    /// Home and End
    Home,
    End,
    /// Page Down `times` times
    PageDown(u32),
    /// A click on a row: it alone selected, its message shown
    Click(u64),
    /// Shift+click: from the row selected to `row`
    ShiftClick(u64),
    SelectAll,
    Delete,
    MoveTo(List),
    /// Flag, Mark as Read and Mark as Unread on what is selected
    Flag,
    Read,
    Unread,
    Sort(SortBy, bool),
    /// Words typed in the Find box, all at once; empty clears it
    Search(String),
    /// Conversations on or off
    Group(bool),
    /// Unread Only on or off
    UnreadOnly(bool),
    Undo,
    /// Send/Recv
    Sync,
    /// Mark All Read on the list's folder
    MarkAllRead,
    /// Empty Folder (Deleted Items, Junk E-mail), the question answered yes
    EmptyFolder,
    /// The app closed and started again on the same store
    Restart,
    /// A new message written and sent from the account of the list shown (the first account's for a list of many)
    Send {
        to: String,
        subject: String,
    },
}

impl Act {
    pub fn to_json(&self) -> Value {
        match self {
            Act::Open(list) => json!({ "act": "open", "list": list.to_json() }),
            Act::Scroll(row) => json!({ "act": "scroll", "row": row }),
            Act::Home => json!({ "act": "home" }),
            Act::End => json!({ "act": "end" }),
            Act::PageDown(times) => json!({ "act": "pagedown", "times": times }),
            Act::Click(row) => json!({ "act": "click", "row": row }),
            Act::ShiftClick(row) => json!({ "act": "shiftclick", "row": row }),
            Act::SelectAll => json!({ "act": "selectall" }),
            Act::Delete => json!({ "act": "delete" }),
            Act::MoveTo(list) => json!({ "act": "move", "list": list.to_json() }),
            Act::Flag => json!({ "act": "flag" }),
            Act::Read => json!({ "act": "read" }),
            Act::Unread => json!({ "act": "unread" }),
            Act::Sort(by, ascending) => json!({ "act": "sort", "by": by.name(), "ascending": ascending }),
            Act::Search(text) => json!({ "act": "search", "text": text }),
            Act::Group(on) => json!({ "act": "group", "on": on }),
            Act::UnreadOnly(on) => json!({ "act": "unreadonly", "on": on }),
            Act::Undo => json!({ "act": "undo" }),
            Act::Sync => json!({ "act": "sync" }),
            Act::MarkAllRead => json!({ "act": "markallread" }),
            Act::EmptyFolder => json!({ "act": "emptyfolder" }),
            Act::Restart => json!({ "act": "restart" }),
            Act::Send { to, subject } => json!({ "act": "send", "to": to, "subject": subject }),
        }
    }

    pub fn from_json(value: &Value) -> Option<Act> {
        let row = || value["row"].as_u64();
        let on = || value["on"].as_bool();
        Some(match value["act"].as_str()? {
            "open" => Act::Open(List::from_json(&value["list"])?),
            "scroll" => Act::Scroll(row()?),
            "home" => Act::Home,
            "end" => Act::End,
            "pagedown" => Act::PageDown(value["times"].as_u64()? as u32),
            "click" => Act::Click(row()?),
            "shiftclick" => Act::ShiftClick(row()?),
            "selectall" => Act::SelectAll,
            "delete" => Act::Delete,
            "move" => Act::MoveTo(List::from_json(&value["list"])?),
            "flag" => Act::Flag,
            "read" => Act::Read,
            "unread" => Act::Unread,
            "sort" => Act::Sort(SortBy::parse(value["by"].as_str()?)?, value["ascending"].as_bool()?),
            "search" => Act::Search(value["text"].as_str()?.into()),
            "group" => Act::Group(on()?),
            "unreadonly" => Act::UnreadOnly(on()?),
            "undo" => Act::Undo,
            "sync" => Act::Sync,
            "markallread" => Act::MarkAllRead,
            "emptyfolder" => Act::EmptyFolder,
            "restart" => Act::Restart,
            "send" => Act::Send {
                to: value["to"].as_str()?.into(),
                subject: value["subject"].as_str()?.into(),
            },
            _ => return None,
        })
    }

    /// One line for the report and the replay
    pub fn describe(&self) -> String {
        match self {
            Act::Open(list) => format!("open {}", list.label()),
            Act::MoveTo(list) => format!("move to {}", list.label()),
            other => other.to_json().to_string(),
        }
    }
}

/// A message, as the server names it
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct Message {
    pub account: String,
    /// Its folder's path as the user sees it
    pub path: String,
    pub uid: u64,
}

impl Message {
    fn to_json(&self) -> Value {
        json!({ "account": self.account, "path": self.path, "uid": self.uid })
    }

    fn from_json(value: &Value) -> Option<Message> {
        Some(Message {
            account: value["account"].as_str()?.into(),
            path: value["path"].as_str()?.into(),
            uid: value["uid"].as_u64()?,
        })
    }
}

/// A row in sight
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Row {
    pub row: u64,
    /// Not drawn yet: its page is not there
    pub blank: bool,
    /// The message it shows (a conversation's row: its newest), None while blank
    pub message: Option<Message>,
    pub subject: String,
    /// Seconds since the epoch, as the list sorts by it
    pub date: i64,
}

/// What the window shows, as the target reads it off its controls
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Seen {
    /// The list of the tree chosen
    pub list: Option<List>,
    /// The rows the list has
    pub rows: u64,
    /// The rows in sight, top to bottom
    pub sight: Vec<Row>,
    /// The rows selected, ascending
    pub selected: Vec<u64>,
    /// The message the reading pane shows
    pub shown: Option<Message>,
    /// The words of the Find box
    pub search: String,
    pub grouped: bool,
    pub unread_only: bool,
    /// The folders of the tree with the unread count each shows: (account, path, unread)
    pub tree: Vec<(String, String, u64)>,
    /// The list chosen is being read and the list before is still drawn (dimmed): the rows are that list's
    pub pending: bool,
    /// What the window says of its own state (its loads and pages), shown in the report beside a failure
    pub notes: String,
}

impl Seen {
    pub fn to_json(&self) -> Value {
        json!({
            "list": self.list.as_ref().map(List::to_json),
            "rows": self.rows,
            "sight": self.sight.iter().map(|r| json!({
                "row": r.row, "blank": r.blank, "message": r.message.as_ref().map(Message::to_json),
                "subject": r.subject, "date": r.date,
            })).collect::<Vec<_>>(),
            "selected": self.selected,
            "shown": self.shown.as_ref().map(Message::to_json),
            "search": self.search,
            "grouped": self.grouped,
            "unreadOnly": self.unread_only,
            "tree": self.tree.iter().map(|(a, p, u)| json!([a, p, u])).collect::<Vec<_>>(),
            "pending": self.pending,
            "notes": self.notes,
        })
    }

    pub fn from_json(value: &Value) -> Option<Seen> {
        let sight = value["sight"]
            .as_array()?
            .iter()
            .map(|r| {
                Some(Row {
                    row: r["row"].as_u64()?,
                    blank: r["blank"].as_bool().unwrap_or(false),
                    message: Message::from_json(&r["message"]),
                    subject: r["subject"].as_str().unwrap_or_default().into(),
                    date: r["date"].as_i64().unwrap_or(0),
                })
            })
            .collect::<Option<Vec<_>>>()?;
        let tree = value["tree"]
            .as_array()
            .map(|t| {
                t.iter()
                    .filter_map(|e| Some((e[0].as_str()?.into(), e[1].as_str()?.into(), e[2].as_u64()?)))
                    .collect()
            })
            .unwrap_or_default();
        Some(Seen {
            list: List::from_json(&value["list"]),
            rows: value["rows"].as_u64()?,
            sight,
            selected: value["selected"]
                .as_array()
                .map(|s| s.iter().filter_map(Value::as_u64).collect())
                .unwrap_or_default(),
            shown: Message::from_json(&value["shown"]),
            search: value["search"].as_str().unwrap_or_default().into(),
            grouped: value["grouped"].as_bool().unwrap_or(false),
            unread_only: value["unreadOnly"].as_bool().unwrap_or(false),
            tree,
            pending: value["pending"].as_bool().unwrap_or(false),
            notes: value["notes"].as_str().unwrap_or_default().into(),
        })
    }

    /// The row in sight at `row`
    pub fn at(&self, row: u64) -> Option<&Row> {
        self.sight.iter().find(|r| r.row == row)
    }
}

/// What a target answers for an act it can not do (a driver without a way to start its app again): the step is
/// skipped there, and the report says so
pub const UNSUPPORTED: &str = "unsupported";

/// A target: the core without a window, or an app through its driver
pub trait Target {
    fn name(&self) -> &str;
    /// The accounts of the world added, with their servers, and their first sync done
    fn start(&mut self, accounts: &[crate::servers::AccountServer]) -> Result<(), String>;
    /// One act of the user's, done as soon as the window takes it (a list chosen is not waited for)
    fn act(&mut self, act: &Act) -> Result<(), String>;
    /// Waits until nothing is under way: no sync, no command, no list or page being read; Err when it does not end
    /// within the patience
    fn settle(&mut self) -> Result<(), String>;
    /// What the window shows now
    fn observe(&mut self) -> Result<Seen, String>;
    /// The process's resident memory, open files and the store's size, for health.rs; None where it can not tell
    fn health(&mut self) -> Option<crate::health::Sample> {
        None
    }
    /// A picture of the window, when the target can take one, saved at `path`
    fn screenshot(&mut self, _path: &std::path::Path) {}
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn acts_and_what_is_seen_go_through_the_protocol() {
        let acts = [
            Act::Open(List::folder("Work", "Projects/Projects 01")),
            Act::Open(List::Flagged),
            Act::Scroll(4200),
            Act::Sort(SortBy::Subject, true),
            Act::Search("budget".into()),
            Act::MoveTo(List::folder("Home", "Ελληνικά")),
            Act::PageDown(3),
        ];
        for act in acts {
            assert_eq!(Act::from_json(&act.to_json()), Some(act));
        }
        let seen = Seen {
            list: Some(List::AllInboxes),
            rows: 18044,
            sight: vec![Row {
                row: 4,
                blank: false,
                message: Some(Message {
                    account: "Work".into(),
                    path: "INBOX".into(),
                    uid: 77,
                }),
                subject: "Budget #77".into(),
                date: 1_700_000_000,
            }],
            selected: vec![4],
            shown: None,
            search: String::new(),
            grouped: true,
            unread_only: false,
            tree: vec![("Work".into(), "INBOX".into(), 12)],
            pending: true,
            notes: "load 0".into(),
        };
        assert_eq!(Seen::from_json(&seen.to_json()), Some(seen));
    }
}
