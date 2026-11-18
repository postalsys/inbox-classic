//! AI agents (MCP clients): the programs the user let in or turned away, what each may do and with which accounts, and
//! the log of what they did, with what takes each change back. The rules themselves are pe-core's (agents.rs); this
//! keeps them.

use rusqlite::{OptionalExtension, params};

use crate::{AccountId, FolderId, Result, Store};

pub type AgentHostId = i64;

/// What an agent may do, as bits
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct AgentLevels(pub u32);

impl AgentLevels {
    /// Accounts, folders, the message list, search and messages
    pub const READ: u32 = 1;
    /// Read state, flags, junk, moves, deletes to Deleted Items, new folders, unsubscribing
    pub const ORGANIZE: u32 = 2;
    /// Drafts in the Drafts folder
    pub const DRAFTS: u32 = 4;
    /// Sending, each message after the user says yes
    pub const SEND: u32 = 8;
    /// What a new agent is offered
    pub const DEFAULT: AgentLevels = AgentLevels(Self::READ | Self::ORGANIZE);

    pub fn has(self, level: u32) -> bool {
        self.0 & level == level
    }
}

/// A program that runs AI agents, as the user decided about it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AgentHost {
    pub id: AgentHostId,
    /// The program's file, what tells it apart
    pub path: String,
    /// What it is called in the windows
    pub name: String,
    /// False for one the user turned away: it is not asked about again
    pub allowed: bool,
    pub levels: AgentLevels,
    pub accounts: Vec<AccountId>,
    /// Seconds since the Unix epoch
    pub created: i64,
    pub last_used: Option<i64>,
}

/// What an agent did, for the log
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct NewLogEntry {
    pub host: AgentHostId,
    /// The tool, `move_messages`
    pub what: String,
    pub account: Option<AccountId>,
    pub folder: Option<FolderId>,
    pub uid: Option<u64>,
    pub message_id: Option<String>,
    /// One line for the user, `Moved "Invoice 12" to Archive`, in the language of the time it was written: what
    /// entries written before `kind` say, its fallback
    pub summary: String,
    /// How to take it back, None when it can not be
    pub undo: Option<String>,
    /// What it says, by the catalog id of its words (`agent-log-moved`), put into words when it is shown
    pub kind: Option<String>,
    /// The values of those words, as pe-core writes them
    pub args: Option<String>,
    /// The request of the agent it came from (MCP's request id, as JSON)
    pub call_id: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AgentLogEntry {
    pub id: i64,
    /// The host's name, for the log window
    pub host_name: String,
    pub at: i64,
    pub entry: NewLogEntry,
    pub undone: bool,
}

/// What an agent read, for the log's summary of each hour
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct NewRead {
    pub host: AgentHostId,
    /// `message`, `conversation`, `attachment`, `search`, `people`, `list` or `changes`
    pub what: String,
    /// The messages it read, listed or found
    pub count: u64,
    /// The subject read, the query searched or the folder listed; never a message's text
    pub subject: String,
    /// An attachment's name
    pub detail: String,
    pub call_id: Option<String>,
}

/// A read of the log, with when it was
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AgentRead {
    pub at: i64,
    pub read: NewRead,
}

/// What a program read in an hour, in numbers
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct ReadSummary {
    pub host: AgentHostId,
    pub host_name: String,
    /// The start of the hour, seconds since the Unix epoch
    pub hour: i64,
    /// The last read of it
    pub last: i64,
    /// Messages read, alone or in their conversations
    pub messages: u64,
    pub attachments: u64,
    /// Searches, of messages or of people
    pub searches: u64,
    /// Lists looked at: of a folder, or of what came
    pub lists: u64,
}

/// How long the log keeps what agents did and read, in seconds: 30 days
pub const LOG_KEPT: i64 = 30 * 86_400;
/// The most entries the log keeps of what agents did, and of what they read
pub const LOG_ENTRIES: u64 = 5_000;
pub const LOG_READS: u64 = 50_000;

const HOST_COLUMNS: &str = "id, path, name, allowed, levels, accounts, created, last_used";

fn host_from_row(row: &rusqlite::Row) -> rusqlite::Result<AgentHost> {
    let accounts: String = row.get(5)?;
    Ok(AgentHost {
        id: row.get(0)?,
        path: row.get(1)?,
        name: row.get(2)?,
        allowed: row.get(3)?,
        levels: AgentLevels(row.get(4)?),
        accounts: accounts.split(',').filter_map(|id| id.trim().parse().ok()).collect(),
        created: row.get(6)?,
        last_used: row.get(7)?,
    })
}

fn joined(accounts: &[AccountId]) -> String {
    accounts.iter().map(i64::to_string).collect::<Vec<_>>().join(",")
}

impl Store {
    pub fn agent_hosts(&self) -> Result<Vec<AgentHost>> {
        let mut statement = self.db.prepare(&format!(
            "SELECT {HOST_COLUMNS} FROM agent_hosts ORDER BY name COLLATE NOCASE, id"
        ))?;
        statement.query_map([], host_from_row)?.collect()
    }

    pub fn agent_host(&self, id: AgentHostId) -> Result<Option<AgentHost>> {
        self.db
            .query_row(
                &format!("SELECT {HOST_COLUMNS} FROM agent_hosts WHERE id = ?1"),
                [id],
                host_from_row,
            )
            .optional()
    }

    /// The host whose program is `path`, if the user decided about it
    pub fn agent_host_by_path(&self, path: &str) -> Result<Option<AgentHost>> {
        self.db
            .query_row(
                &format!("SELECT {HOST_COLUMNS} FROM agent_hosts WHERE path = ?1"),
                [path],
                host_from_row,
            )
            .optional()
    }

    /// Keeps what the user decided about the program at `path`, in place of what was decided before; its id
    pub fn save_agent_host(
        &self,
        path: &str,
        name: &str,
        allowed: bool,
        levels: AgentLevels,
        accounts: &[AccountId],
        now: i64,
    ) -> Result<AgentHostId> {
        self.db.query_row(
            "INSERT INTO agent_hosts (path, name, allowed, levels, accounts, created) VALUES (?1, ?2, ?3, ?4, ?5, ?6) \
             ON CONFLICT (path) DO UPDATE SET name = excluded.name, allowed = excluded.allowed, \
             levels = excluded.levels, accounts = excluded.accounts RETURNING id",
            params![path, name, allowed, levels.0, joined(accounts), now],
            |row| row.get(0),
        )
    }

    /// Changes what a host may do; false when there is no such host
    pub fn update_agent_host(
        &self,
        id: AgentHostId,
        allowed: bool,
        levels: AgentLevels,
        accounts: &[AccountId],
    ) -> Result<bool> {
        let changed = self.db.execute(
            "UPDATE agent_hosts SET allowed = ?1, levels = ?2, accounts = ?3 WHERE id = ?4",
            params![allowed, levels.0, joined(accounts), id],
        )?;
        Ok(changed > 0)
    }

    pub fn touch_agent_host(&self, id: AgentHostId, now: i64) -> Result<()> {
        self.db
            .execute("UPDATE agent_hosts SET last_used = ?1 WHERE id = ?2", params![now, id])?;
        Ok(())
    }

    /// Forgets a host and its log: the next time it connects, the user is asked again
    pub fn remove_agent_host(&self, id: AgentHostId) -> Result<bool> {
        Ok(self.db.execute("DELETE FROM agent_hosts WHERE id = ?1", [id])? > 0)
    }

    /// Whether agents may connect at all: yes until turned off
    pub fn agents_enabled(&self) -> Result<bool> {
        self.bool_setting("agents.enabled", true)
    }

    pub fn set_agents_enabled(&self, enabled: bool) -> Result<()> {
        self.set_bool_setting("agents.enabled", enabled)
    }

    /// Writes what an agent did in the log, in one transaction; the entries' ids, in their order
    pub fn log_agent(&self, entries: &[NewLogEntry], now: i64) -> Result<Vec<i64>> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let mut statement = self.db.prepare_cached(
            "INSERT INTO agent_log (host_id, at, what, account_id, folder_id, uid, message_id, summary, undo, kind, \
             args, call_id) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)",
        )?;
        let mut ids = Vec::with_capacity(entries.len());
        for entry in entries {
            statement.execute(params![
                entry.host,
                now,
                entry.what,
                entry.account,
                entry.folder,
                entry.uid,
                entry.message_id,
                entry.summary,
                entry.undo,
                entry.kind,
                entry.args,
                entry.call_id
            ])?;
            ids.push(self.db.last_insert_rowid());
        }
        drop(statement);
        self.forget_old("agent_log", now, LOG_ENTRIES)?;
        tx.commit()?;
        Ok(ids)
    }

    /// Forgets the rows of `table` older than [`LOG_KEPT`] and those past the newest `most`
    fn forget_old(&self, table: &str, now: i64, most: u64) -> Result<()> {
        self.db
            .prepare_cached(&format!("DELETE FROM {table} WHERE at < ?1"))?
            .execute([now - LOG_KEPT])?;
        self.db
            .prepare_cached(&format!(
                "DELETE FROM {table} WHERE id <= (SELECT id FROM {table} ORDER BY id DESC LIMIT 1 OFFSET ?1)"
            ))?
            .execute([most])?;
        Ok(())
    }

    /// Says in entry `id` of the log what came of it after all (an unsubscribe the list refused), as
    /// [`NewLogEntry::kind`] and its values
    pub fn set_agent_log_kind(&self, id: i64, kind: &str, args: &str) -> Result<()> {
        self.db.execute(
            "UPDATE agent_log SET kind = ?1, args = ?2 WHERE id = ?3",
            params![kind, args, id],
        )?;
        Ok(())
    }

    /// The newest `limit` entries of the log the user did not clear, newest first
    pub fn agent_log(&self, limit: u64) -> Result<Vec<AgentLogEntry>> {
        self.agent_log_where("WHERE l.hidden = ?1", 0, limit)
    }

    fn agent_log_where(&self, filter: &str, value: i64, limit: u64) -> Result<Vec<AgentLogEntry>> {
        let mut statement = self.db.prepare(&format!(
            "SELECT l.id, l.host_id, h.name, l.at, l.what, l.account_id, l.folder_id, l.uid, l.message_id, l.summary, \
             l.undo, l.undone, l.kind, l.args, l.call_id FROM agent_log l JOIN agent_hosts h ON h.id = l.host_id {filter} \
             ORDER BY l.at DESC, l.id DESC LIMIT ?2"
        ))?;
        statement
            .query_map(params![value, limit], |row| {
                Ok(AgentLogEntry {
                    id: row.get(0)?,
                    host_name: row.get(2)?,
                    at: row.get(3)?,
                    entry: NewLogEntry {
                        host: row.get(1)?,
                        what: row.get(4)?,
                        account: row.get(5)?,
                        folder: row.get(6)?,
                        uid: row.get(7)?,
                        message_id: row.get(8)?,
                        summary: row.get(9)?,
                        undo: row.get(10)?,
                        kind: row.get(12)?,
                        args: row.get(13)?,
                        call_id: row.get(14)?,
                    },
                    undone: row.get(11)?,
                })
            })?
            .collect()
    }

    pub fn agent_log_entry(&self, id: i64) -> Result<Option<AgentLogEntry>> {
        Ok(self.agent_log_where("WHERE l.id = ?1", id, 1)?.into_iter().next())
    }

    pub fn set_agent_log_undone(&self, id: i64) -> Result<()> {
        self.db.execute("UPDATE agent_log SET undone = 1 WHERE id = ?1", [id])?;
        Ok(())
    }

    /// Clears the log from the window: what agents read is forgotten, what they did only hidden, as the limits
    /// still count it and an agent's drafts stay its own (both age out, [`LOG_KEPT`]); a host's own goes with the host
    pub fn clear_agent_log(&self) -> Result<()> {
        self.db
            .execute("UPDATE agent_log SET hidden = 1 WHERE hidden = 0", [])?;
        self.db.execute("DELETE FROM agent_reads", [])?;
        Ok(())
    }

    /// Writes what agents read, in one transaction
    pub fn log_reads(&self, reads: &[NewRead], now: i64) -> Result<()> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let mut statement = self.db.prepare_cached(
            "INSERT INTO agent_reads (host_id, at, what, count, subject, detail, call_id) \
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        )?;
        for read in reads {
            statement.execute(params![
                read.host,
                now,
                read.what,
                read.count,
                read.subject,
                read.detail,
                read.call_id
            ])?;
        }
        drop(statement);
        self.forget_old("agent_reads", now, LOG_READS)?;
        tx.commit()
    }

    /// What each program read in each hour, the newest `limit` hours of reading first
    pub fn read_summaries(&self, limit: u64) -> Result<Vec<ReadSummary>> {
        let mut statement = self.db.prepare(
            "SELECT r.host_id, h.name, (r.at / 3600) * 3600 AS hour, MAX(r.at), \
             SUM(CASE WHEN r.what IN ('message', 'conversation') THEN r.count ELSE 0 END), \
             SUM(r.what = 'attachment'), SUM(r.what IN ('search', 'people')), SUM(r.what IN ('list', 'changes')) \
             FROM agent_reads r JOIN agent_hosts h ON h.id = r.host_id \
             GROUP BY r.host_id, hour ORDER BY MAX(r.at) DESC LIMIT ?1",
        )?;
        statement
            .query_map([limit], |row| {
                Ok(ReadSummary {
                    host: row.get(0)?,
                    host_name: row.get(1)?,
                    hour: row.get(2)?,
                    last: row.get(3)?,
                    messages: row.get(4)?,
                    attachments: row.get(5)?,
                    searches: row.get(6)?,
                    lists: row.get(7)?,
                })
            })?
            .collect()
    }

    /// What program `host` read in the hour that starts at `hour`, in the order it read
    pub fn reads_of_hour(&self, host: AgentHostId, hour: i64) -> Result<Vec<AgentRead>> {
        let mut statement = self.db.prepare(
            "SELECT at, what, count, subject, detail, call_id FROM agent_reads \
             WHERE host_id = ?1 AND at >= ?2 AND at < ?2 + 3600 ORDER BY at, id",
        )?;
        statement
            .query_map(params![host, hour], |row| {
                Ok(AgentRead {
                    at: row.get(0)?,
                    read: NewRead {
                        host,
                        what: row.get(1)?,
                        count: row.get(2)?,
                        subject: row.get(3)?,
                        detail: row.get(4)?,
                        call_id: row.get(5)?,
                    },
                })
            })?
            .collect()
    }

    /// Whether the user wrote to `address` before (the address book counts the messages sent to it)
    pub fn written_to(&self, address: &str) -> Result<bool> {
        let sent: Option<i64> = self
            .db
            .query_row("SELECT sent FROM contacts WHERE address = ?1", [address], |row| {
                row.get(0)
            })
            .optional()?;
        Ok(sent.unwrap_or(0) > 0)
    }

    /// The UID of the message of `folder` with `message_id`, None when the store has none
    pub fn uid_of_message_id(&self, folder: FolderId, message_id: &str) -> Result<Option<u64>> {
        self.db
            .query_row(
                "SELECT uid FROM messages WHERE folder_id = ?1 AND message_id = ?2 ORDER BY uid DESC LIMIT 1",
                params![folder, message_id],
                |row| row.get(0),
            )
            .optional()
    }

    /// The message of an account's Outbox with `message_id`, None when it is not there (sent already)
    pub fn outbox_with_message_id(&self, account: AccountId, message_id: &str) -> Result<Option<i64>> {
        self.db
            .query_row(
                "SELECT id FROM outbox WHERE account_id = ?1 AND message_id = ?2",
                params![account, message_id],
                |row| row.get(0),
            )
            .optional()
    }

    /// The account of the draft with `message_id` that host `host` saved (its log's `save_draft` or `replace_draft`),
    /// None when it saved none or discarded it since (`discard_draft`): an agent changes only drafts of its own
    pub fn agent_draft(&self, host: AgentHostId, message_id: &str) -> Result<Option<AccountId>> {
        let last: Option<(String, Option<AccountId>)> = self
            .db
            .query_row(
                "SELECT what, account_id FROM agent_log WHERE host_id = ?1 AND message_id = ?2 \
                 AND what IN ('save_draft', 'replace_draft', 'discard_draft') ORDER BY at DESC, id DESC LIMIT 1",
                params![host, message_id],
                |row| Ok((row.get(0)?, row.get(1)?)),
            )
            .optional()?;
        Ok(last.and_then(|(what, account)| account.filter(|_| what != "discard_draft")))
    }

    /// The user saved the draft with `message_id`: when an agent saved it, it is the user's from then on, even while
    /// the copy in Drafts is still the agent's (their own is on its way to the server). Drafts no agent saved are
    /// not kept.
    pub fn take_draft(&self, message_id: &str) -> Result<()> {
        self.db.execute(
            "INSERT OR IGNORE INTO drafts_taken (message_id) SELECT ?1 WHERE EXISTS (SELECT 1 FROM agent_log \
             WHERE message_id = ?1 AND what IN ('save_draft', 'replace_draft'))",
            [message_id],
        )?;
        Ok(())
    }

    /// Whether the user saved the agent's draft with `message_id` ([`Store::take_draft`]): no agent changes it then
    pub fn draft_taken(&self, message_id: &str) -> Result<bool> {
        self.db.query_row(
            "SELECT EXISTS (SELECT 1 FROM drafts_taken WHERE message_id = ?1)",
            [message_id],
            |row| row.get(0),
        )
    }

    /// How many entries of `what` a host logged since `since`: the rate limits count them
    pub fn agent_log_count(&self, host: AgentHostId, what: &str, since: i64) -> Result<u64> {
        self.db.query_row(
            "SELECT COUNT(*) FROM agent_log WHERE host_id = ?1 AND what = ?2 AND at >= ?3",
            params![host, what, since],
            |row| row.get(0),
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hosts_are_kept_by_their_program() {
        let store = Store::open_in_memory().unwrap();
        assert!(store.agent_hosts().unwrap().is_empty());
        let id = store
            .save_agent_host(
                "/Applications/Agent.app",
                "Agent",
                true,
                AgentLevels::DEFAULT,
                &[1, 2],
                100,
            )
            .unwrap();
        let host = store.agent_host_by_path("/Applications/Agent.app").unwrap().unwrap();
        assert_eq!(host.id, id);
        assert_eq!(host.accounts, [1, 2]);
        assert!(host.levels.has(AgentLevels::READ) && !host.levels.has(AgentLevels::SEND));
        // deciding again keeps the id
        let again = store
            .save_agent_host("/Applications/Agent.app", "Agent", false, AgentLevels(0), &[], 200)
            .unwrap();
        assert_eq!(again, id);
        assert!(!store.agent_host(id).unwrap().unwrap().allowed);
        assert!(store.update_agent_host(id, true, AgentLevels(15), &[3]).unwrap());
        let host = store.agent_host(id).unwrap().unwrap();
        assert_eq!(
            (host.allowed, host.levels.0, host.accounts.as_slice()),
            (true, 15, &[3][..])
        );
        store.touch_agent_host(id, 300).unwrap();
        assert_eq!(store.agent_host(id).unwrap().unwrap().last_used, Some(300));
        assert!(store.remove_agent_host(id).unwrap());
        assert!(store.agent_host(id).unwrap().is_none());
    }

    #[test]
    fn the_log_keeps_what_agents_did() {
        let store = Store::open_in_memory().unwrap();
        let host = store
            .save_agent_host("/usr/bin/agent", "Agent", true, AgentLevels::DEFAULT, &[], 1)
            .unwrap();
        let entry = NewLogEntry {
            host,
            what: "set_read".into(),
            summary: "Marked \"Hi\" read".into(),
            undo: Some("seen:1:7:0".into()),
            ..Default::default()
        };
        store.log_agent(std::slice::from_ref(&entry), 10).unwrap();
        let send = NewLogEntry {
            what: "send".into(),
            ..entry.clone()
        };
        store.log_agent(&[send], 20).unwrap();
        let log = store.agent_log(10).unwrap();
        let first = log[1].id;
        assert_eq!(log.len(), 2);
        assert_eq!(log[0].entry.what, "send");
        assert_eq!(log[1].host_name, "Agent");
        assert_eq!(store.agent_log_count(host, "send", 15).unwrap(), 1);
        assert_eq!(store.agent_log_count(host, "send", 25).unwrap(), 0);
        store.set_agent_log_undone(first).unwrap();
        store.set_agent_log_kind(first, "agent-log-read", "x").unwrap();
        let changed = store.agent_log_entry(first).unwrap().unwrap().entry;
        assert_eq!(
            (changed.kind.as_deref(), changed.args.as_deref()),
            (Some("agent-log-read"), Some("x"))
        );
        assert!(store.agent_log_entry(first).unwrap().unwrap().undone);
        // the drafts it saved are its own until it discards them; another host's are not
        let draft = |what: &str| NewLogEntry {
            host,
            what: what.into(),
            account: Some(4),
            message_id: Some("<d@x>".into()),
            ..Default::default()
        };
        assert_eq!(store.agent_draft(host, "<d@x>").unwrap(), None);
        store.log_agent(&[draft("save_draft")], 30).unwrap();
        store.log_agent(&[draft("replace_draft")], 31).unwrap();
        assert_eq!(store.agent_draft(host, "<d@x>").unwrap(), Some(4));
        assert_eq!(store.agent_draft(host + 1, "<d@x>").unwrap(), None);
        store.log_agent(&[draft("discard_draft")], 32).unwrap();
        assert_eq!(store.agent_draft(host, "<d@x>").unwrap(), None);
        // a host forgotten takes its log along
        store.remove_agent_host(host).unwrap();
        assert!(store.agent_log(10).unwrap().is_empty());
    }

    #[test]
    fn a_cleared_log_still_counts() {
        let store = Store::open_in_memory().unwrap();
        let host = store
            .save_agent_host("/usr/bin/agent", "Agent", true, AgentLevels::DEFAULT, &[], 1)
            .unwrap();
        let entry = |what: &str| NewLogEntry {
            host,
            what: what.into(),
            account: Some(1),
            message_id: Some("<d@x>".into()),
            kind: Some("agent-log-sent".into()),
            call_id: Some("7".into()),
            ..Default::default()
        };
        store.log_agent(&[entry("send"), entry("save_draft")], 100).unwrap();
        assert_eq!(store.agent_log(10).unwrap()[0].entry.call_id.as_deref(), Some("7"));
        store.clear_agent_log().unwrap();
        // out of the window, but the hour's sends still count and the draft is still the agent's
        assert!(store.agent_log(10).unwrap().is_empty());
        assert_eq!(store.agent_log_count(host, "send", 0).unwrap(), 1);
        assert_eq!(store.agent_draft(host, "<d@x>").unwrap(), Some(1));
        // 30 days later it is forgotten, when the next entry is written
        store.log_agent(&[entry("send")], 100 + LOG_KEPT + 1).unwrap();
        assert_eq!(store.agent_log_count(host, "send", 0).unwrap(), 1);
    }

    #[test]
    fn the_log_is_capped() {
        let store = Store::open_in_memory().unwrap();
        let host = store
            .save_agent_host("/usr/bin/agent", "Agent", true, AgentLevels::DEFAULT, &[], 1)
            .unwrap();
        let entries: Vec<NewLogEntry> = (0..LOG_ENTRIES + 3)
            .map(|_| NewLogEntry {
                host,
                what: "set_read".into(),
                ..Default::default()
            })
            .collect();
        store.log_agent(&entries, 10).unwrap();
        assert_eq!(store.agent_log_count(host, "set_read", 0).unwrap(), LOG_ENTRIES);
    }

    #[test]
    fn reads_are_summed_by_the_hour() {
        let store = Store::open_in_memory().unwrap();
        let host = store
            .save_agent_host("/usr/bin/agent", "Agent", true, AgentLevels::DEFAULT, &[], 1)
            .unwrap();
        let read = |what: &str, count: u64, subject: &str| NewRead {
            host,
            what: what.into(),
            count,
            subject: subject.into(),
            ..Default::default()
        };
        let hour = 3600 * 1000;
        store
            .log_reads(
                &[read("message", 1, "Lunch"), read("conversation", 3, "Plans")],
                hour + 10,
            )
            .unwrap();
        store
            .log_reads(
                &[read("search", 4, "invoice"), read("attachment", 1, "Lunch")],
                hour + 20,
            )
            .unwrap();
        store.log_reads(&[read("list", 25, "Inbox")], hour + 3600).unwrap();
        let summaries = store.read_summaries(10).unwrap();
        assert_eq!(summaries.len(), 2);
        // the newest hour first
        assert_eq!((summaries[0].hour, summaries[0].lists), (hour + 3600, 1));
        let first = &summaries[1];
        assert_eq!(
            (
                first.hour,
                first.last,
                first.messages,
                first.attachments,
                first.searches,
                first.lists
            ),
            (hour, hour + 20, 4, 1, 1, 0)
        );
        assert_eq!(first.host_name, "Agent");
        let reads = store.reads_of_hour(host, hour).unwrap();
        let subjects: Vec<&str> = reads.iter().map(|r| r.read.subject.as_str()).collect();
        assert_eq!(subjects, ["Lunch", "Plans", "invoice", "Lunch"]);
        // cleared with the log, and forgotten after 30 days
        store
            .log_reads(&[read("message", 1, "Old")], hour + LOG_KEPT + 7200)
            .unwrap();
        assert_eq!(store.read_summaries(10).unwrap().len(), 1);
        store.clear_agent_log().unwrap();
        assert!(store.read_summaries(10).unwrap().is_empty());
    }

    #[test]
    fn a_draft_the_user_saved_is_theirs() {
        let store = Store::open_in_memory().unwrap();
        let host = store
            .save_agent_host("/usr/bin/agent", "Agent", true, AgentLevels::DEFAULT, &[], 1)
            .unwrap();
        let saved = NewLogEntry {
            host,
            what: "save_draft".into(),
            account: Some(1),
            message_id: Some("<agent@x>".into()),
            ..Default::default()
        };
        store.log_agent(&[saved], 10).unwrap();
        // the user's own drafts are not kept: no agent wrote them
        store.take_draft("<mine@x>").unwrap();
        assert!(!store.draft_taken("<mine@x>").unwrap());
        assert!(!store.draft_taken("<agent@x>").unwrap());
        store.take_draft("<agent@x>").unwrap();
        store.take_draft("<agent@x>").unwrap();
        assert!(store.draft_taken("<agent@x>").unwrap());
    }

    #[test]
    fn agents_can_be_turned_off() {
        let store = Store::open_in_memory().unwrap();
        assert!(store.agents_enabled().unwrap());
        store.set_agents_enabled(false).unwrap();
        assert!(!store.agents_enabled().unwrap());
    }
}
