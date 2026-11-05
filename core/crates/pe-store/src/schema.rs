//! The schema, versioned with `user_version`: each migration runs once, in order, in a
//! transaction with the version bump.

use rusqlite::Connection;

const MIGRATIONS: &[&str] = &[
    r#"
CREATE TABLE accounts (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    username TEXT NOT NULL,
    imap_host TEXT NOT NULL,
    imap_port INTEGER NOT NULL,
    imap_security TEXT NOT NULL,
    smtp_host TEXT NOT NULL,
    smtp_port INTEGER NOT NULL,
    smtp_security TEXT NOT NULL
);

CREATE TABLE folders (
    id INTEGER PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    path TEXT NOT NULL,
    name TEXT NOT NULL,
    delimiter TEXT,
    flags TEXT NOT NULL,
    special_use TEXT,
    subscribed INTEGER NOT NULL,
    selectable INTEGER NOT NULL,
    position INTEGER NOT NULL,
    uid_validity INTEGER,
    uid_next INTEGER,
    highest_modseq INTEGER,
    UNIQUE (account_id, path)
);

CREATE TABLE messages (
    id INTEGER PRIMARY KEY,
    folder_id INTEGER NOT NULL REFERENCES folders(id) ON DELETE CASCADE,
    uid INTEGER NOT NULL,
    modseq INTEGER,
    -- canonical: sorted, without \Recent
    flags TEXT NOT NULL,
    -- \Seen in flags, a column of its own for the unread counts
    seen INTEGER NOT NULL,
    internal_date INTEGER,
    date INTEGER,
    size INTEGER,
    subject TEXT NOT NULL,
    from_name TEXT NOT NULL,
    from_address TEXT NOT NULL,
    recipients TEXT NOT NULL,
    message_id TEXT,
    in_reply_to TEXT,
    has_attachments INTEGER NOT NULL,
    UNIQUE (folder_id, uid)
);
-- one index for each order of the message list, uid last as the order sorts
CREATE INDEX messages_by_date ON messages (folder_id, COALESCE(date, internal_date), uid);
CREATE INDEX messages_by_received ON messages (folder_id, internal_date, uid);
CREATE INDEX messages_by_from ON messages (folder_id, (CASE from_name WHEN '' THEN from_address ELSE from_name END) COLLATE NOCASE, uid);
CREATE INDEX messages_by_subject ON messages (folder_id, subject COLLATE NOCASE, uid);
CREATE INDEX messages_by_size ON messages (folder_id, size, uid);
CREATE INDEX messages_unread ON messages (folder_id) WHERE seen = 0;

CREATE TABLE bodies (
    message_id INTEGER PRIMARY KEY REFERENCES messages(id) ON DELETE CASCADE,
    source BLOB NOT NULL
);
"#,
    r#"
CREATE TABLE settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
-- names the passwords of this store's accounts apart from those of another store
INSERT INTO settings (key, value) VALUES ('profile', lower(hex(randomblob(16))));
"#,
    r#"
-- how the account signs in: 'password', or 'oauth2:<provider>'
ALTER TABLE accounts ADD COLUMN auth TEXT NOT NULL DEFAULT 'password';
"#,
    r#"
-- messages waiting to be sent, built as they go over SMTP: until the server takes them, they are not lost
CREATE TABLE outbox (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    envelope_from TEXT NOT NULL,
    -- the recipients of the envelope, one per line
    envelope_to TEXT NOT NULL,
    raw BLOB NOT NULL,
    subject TEXT NOT NULL,
    recipients TEXT NOT NULL,
    created INTEGER NOT NULL,
    -- why the last try did not work
    problem TEXT
);
"#,
    r#"
-- OAuth clients the user registered with an OpenID Connect provider, for accounts that sign in with them
-- ('oauth2:app:<id>'); the client secret is in the Credential Manager, never here
CREATE TABLE sign_in_apps (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    issuer TEXT NOT NULL,
    client_id TEXT NOT NULL,
    has_secret INTEGER NOT NULL,
    scopes TEXT NOT NULL,
    -- from the issuer's discovery document when the app was saved
    authorize_url TEXT NOT NULL,
    token_url TEXT NOT NULL,
    -- the issuer the provider names in its redirects (RFC 9207), when it does
    response_issuer TEXT,
    imap_host TEXT NOT NULL,
    imap_port INTEGER NOT NULL,
    imap_security TEXT NOT NULL,
    smtp_host TEXT NOT NULL,
    smtp_port INTEGER NOT NULL,
    smtp_security TEXT NOT NULL,
    -- offered for new accounts
    enabled INTEGER NOT NULL
);
-- whether the built-in clients are offered for new accounts: Google lets only its test users sign in with
-- Inbox Classic's until it verifies the app
INSERT INTO settings (key, value) VALUES ('sign_in.google', '0'), ('sign_in.microsoft', '1');
"#,
    r#"
-- what the search reads besides the list's own fields: everyone the message names, decoded (From, Sender and
-- Reply-To; To, Cc and Bcc), and the names and number of its files
ALTER TABLE messages ADD COLUMN sender_people TEXT NOT NULL DEFAULT '';
ALTER TABLE messages ADD COLUMN recipient_people TEXT NOT NULL DEFAULT '';
ALTER TABLE messages ADD COLUMN attachment_names TEXT NOT NULL DEFAULT '';
ALTER TABLE messages ADD COLUMN attachment_count INTEGER NOT NULL DEFAULT 0;
-- 1 once the search index has the message's text (from its text part, or its cached source)
ALTER TABLE messages ADD COLUMN text_indexed INTEGER NOT NULL DEFAULT 0;
-- the date order of a list of every folder (a search of all folders)
CREATE INDEX messages_all_by_date ON messages (COALESCE(date, internal_date), uid, id);
-- the messages whose text is still to index, newest first
CREATE INDEX messages_text_unindexed ON messages (COALESCE(date, internal_date) DESC) WHERE text_indexed = 0;
-- 1 once the search index has the text of the cached source
ALTER TABLE bodies ADD COLUMN indexed INTEGER NOT NULL DEFAULT 0;
-- the sources still to index, found without reading the others
CREATE INDEX bodies_unindexed ON bodies (message_id) WHERE indexed = 0;

-- the search index, one row per message by its id: the words of its subject, its senders, its recipients, its files
-- and, once its source is cached, its text. Contentless: the store has the text already, the index keeps only the
-- words
CREATE VIRTUAL TABLE messages_fts USING fts5(
    subject, senders, recipients, attachments, body,
    content = '', contentless_delete = 1, tokenize = 'unicode61 remove_diacritics 2'
);
INSERT INTO messages_fts (rowid, subject, senders, recipients, attachments, body)
    SELECT id, subject, from_name || ' ' || from_address, recipients, '', '' FROM messages;
CREATE TRIGGER messages_fts_add AFTER INSERT ON messages BEGIN
    INSERT INTO messages_fts (rowid, subject, senders, recipients, attachments, body) VALUES (
        new.id, new.subject,
        CASE new.sender_people WHEN '' THEN new.from_name || ' ' || new.from_address ELSE new.sender_people END,
        CASE new.recipient_people WHEN '' THEN new.recipients ELSE new.recipient_people END,
        new.attachment_names, ''
    );
END;
CREATE TRIGGER messages_fts_remove AFTER DELETE ON messages BEGIN
    DELETE FROM messages_fts WHERE rowid = old.id;
END;

"#,
    // the signature of each account, as sanitized HTML, empty for none
    r#"
ALTER TABLE accounts ADD COLUMN signature TEXT NOT NULL DEFAULT '';
"#,
    // the address book that completes addresses: the people written to and heard from (contacts.rs); to begin with,
    // the senders of the messages the store has, Sent Items and Junk left out
    r#"
CREATE TABLE contacts (
    address TEXT PRIMARY KEY COLLATE NOCASE,
    name TEXT NOT NULL DEFAULT '',
    sent INTEGER NOT NULL DEFAULT 0,
    received INTEGER NOT NULL DEFAULT 0,
    last INTEGER NOT NULL DEFAULT 0,
    hidden INTEGER NOT NULL DEFAULT 0
);
INSERT INTO contacts (address, name, received, last)
    SELECT m.from_address, m.from_name, COUNT(*), MAX(COALESCE(m.date, m.internal_date, 0))
    FROM messages m JOIN folders f ON f.id = m.folder_id
    WHERE instr(m.from_address, '@') > 0 AND COALESCE(f.special_use, '') NOT IN ('\Sent', '\Junk')
    GROUP BY m.from_address COLLATE NOCASE
    ON CONFLICT (address) DO NOTHING;
"#,
    // AI agents (MCP clients) the user let in or turned away, by the program that runs them, with what each may do,
    // and what they did (agents.rs)
    r#"
CREATE TABLE agent_hosts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    -- the program the agent runs in, as the system names its file: what tells one agent from another
    path TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    allowed INTEGER NOT NULL,
    -- what it may do, bits: 1 read, 2 organize, 4 drafts, 8 send
    levels INTEGER NOT NULL,
    -- the ids of the accounts it may use, comma separated
    accounts TEXT NOT NULL,
    created INTEGER NOT NULL,
    last_used INTEGER
);
CREATE TABLE agent_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    host_id INTEGER NOT NULL REFERENCES agent_hosts(id) ON DELETE CASCADE,
    at INTEGER NOT NULL,
    what TEXT NOT NULL,
    account_id INTEGER,
    folder_id INTEGER,
    uid INTEGER,
    message_id TEXT,
    summary TEXT NOT NULL,
    -- how to take it back, as agents.rs writes it; NULL when it can not be
    undo TEXT,
    undone INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX agent_log_by_time ON agent_log (at DESC, id DESC);
-- the rate limits count a host's entries; a host removed takes its own along
CREATE INDEX agent_log_by_host ON agent_log (host_id, what, at);
-- a message that waits before it goes (one an agent sent, with time to take it back), seconds since the Unix epoch
ALTER TABLE outbox ADD COLUMN not_before INTEGER;
"#,
];

pub(crate) fn migrate(db: &mut Connection) -> rusqlite::Result<()> {
    let version: usize = db.pragma_query_value(None, "user_version", |row| row.get(0))?;
    for (index, migration) in MIGRATIONS.iter().enumerate().skip(version) {
        let tx = db.transaction_with_behavior(rusqlite::TransactionBehavior::Immediate)?;
        tx.execute_batch(migration)?;
        tx.pragma_update(None, "user_version", index + 1)?;
        tx.commit()?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn migrations_run_once() {
        let mut db = Connection::open_in_memory().unwrap();
        migrate(&mut db).unwrap();
        migrate(&mut db).unwrap();
        let version: usize = db.pragma_query_value(None, "user_version", |row| row.get(0)).unwrap();
        assert_eq!(version, MIGRATIONS.len());
    }

    #[test]
    fn the_message_list_orders_use_indexes() {
        let mut db = Connection::open_in_memory().unwrap();
        migrate(&mut db).unwrap();
        for field in [
            crate::SortField::Date,
            crate::SortField::Received,
            crate::SortField::From,
            crate::SortField::Subject,
            crate::SortField::Size,
        ] {
            for ascending in [true, false] {
                let order = crate::Sort { field, ascending }.order_by();
                let sql =
                    format!("EXPLAIN QUERY PLAN SELECT id FROM messages WHERE folder_id = 1 ORDER BY {order} LIMIT 10");
                let plan: Vec<String> = db
                    .prepare(&sql)
                    .unwrap()
                    .query_map([], |row| row.get::<_, String>(3))
                    .unwrap()
                    .map(Result::unwrap)
                    .collect();
                let plan = plan.join("; ");
                assert!(
                    !plan.contains("TEMP B-TREE"),
                    "{field:?} sorts without an index: {plan}"
                );
            }
        }
        let plan: String = db
            .query_row(
                "EXPLAIN QUERY PLAN SELECT COUNT(*) FROM messages WHERE folder_id = 1 AND seen = 0",
                [],
                |row| row.get(3),
            )
            .unwrap();
        assert!(plan.contains("messages_unread"), "{plan}");
    }
}
