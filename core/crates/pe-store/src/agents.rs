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
    /// One line for the user: `Moved "Invoice 12" to Archive`
    pub summary: String,
    /// How to take it back, None when it can not be
    pub undo: Option<String>,
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

    /// Writes what an agent did in the log, in one transaction
    pub fn log_agent(&self, entries: &[NewLogEntry], now: i64) -> Result<()> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let mut statement = self.db.prepare_cached(
            "INSERT INTO agent_log (host_id, at, what, account_id, folder_id, uid, message_id, summary, undo) \
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
        )?;
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
                entry.undo
            ])?;
        }
        drop(statement);
        tx.commit()
    }

    /// The newest `limit` entries of the log, newest first
    pub fn agent_log(&self, limit: u64) -> Result<Vec<AgentLogEntry>> {
        self.agent_log_where("WHERE ?1 = ?1", 0, limit)
    }

    fn agent_log_where(&self, filter: &str, value: i64, limit: u64) -> Result<Vec<AgentLogEntry>> {
        let mut statement = self.db.prepare(&format!(
            "SELECT l.id, l.host_id, h.name, l.at, l.what, l.account_id, l.folder_id, l.uid, l.message_id, l.summary, \
             l.undo, l.undone FROM agent_log l JOIN agent_hosts h ON h.id = l.host_id {filter} \
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

    /// Forgets the log (a host's own goes with the host)
    pub fn clear_agent_log(&self) -> Result<()> {
        self.db.execute("DELETE FROM agent_log", [])?;
        Ok(())
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

    /// The message of an account's Outbox with `message_id` in its header, None when it is not there (sent already)
    pub fn outbox_with_message_id(&self, account: AccountId, message_id: &str) -> Result<Option<i64>> {
        let header = format!("Message-ID: {message_id}");
        self.db
            .query_row(
                "SELECT id FROM outbox WHERE account_id = ?1 AND instr(raw, CAST(?2 AS BLOB)) > 0",
                params![account, header],
                |row| row.get(0),
            )
            .optional()
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
        assert!(store.agent_log_entry(first).unwrap().unwrap().undone);
        // a host forgotten takes its log along
        store.remove_agent_host(host).unwrap();
        assert!(store.agent_log(10).unwrap().is_empty());
    }

    #[test]
    fn agents_can_be_turned_off() {
        let store = Store::open_in_memory().unwrap();
        assert!(store.agents_enabled().unwrap());
        store.set_agents_enabled(false).unwrap();
        assert!(!store.agents_enabled().unwrap());
    }
}
