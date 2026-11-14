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
    // the Received order of a list over several folders (All Inboxes, a search of every folder) without a scan
    r#"
CREATE INDEX messages_all_by_received ON messages (internal_date, uid, id);
"#,
    // messages on their way to a folder of another account (transfers.rs): the source is copied there first, and the
    // original removed only after the server took the copy, so a crash or a failure loses nothing
    r#"
CREATE TABLE transfers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    -- the account the message comes from, whose worker moves it
    account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    from_folder INTEGER NOT NULL,
    uid INTEGER NOT NULL,
    to_folder INTEGER NOT NULL,
    -- a copy keeps the original
    copy INTEGER NOT NULL,
    message_id TEXT,
    flags TEXT NOT NULL,
    internal_date INTEGER,
    -- the message as the server keeps it, when it was here already; fetched otherwise
    source BLOB,
    -- 1 once an APPEND was tried: on another try, a copy the target has already is not made again
    tried INTEGER NOT NULL DEFAULT 0
);
-- the folders messages were last moved or copied to, which the Move and Copy window offers first
CREATE TABLE recent_targets (
    folder_id INTEGER PRIMARY KEY REFERENCES folders(id) ON DELETE CASCADE,
    used INTEGER NOT NULL
);
"#,
    // conversations: the Message-IDs a message names (References, oldest first), the conversation it is in (its own id
    // below 0 until threaded), and the ids of each account's conversations by the Message-IDs (and Gmail conversation ids) in them
    r#"
-- NULL for mail stored before: its References are fetched in the background
ALTER TABLE messages ADD COLUMN refs TEXT;
ALTER TABLE messages ADD COLUMN thread_id INTEGER NOT NULL DEFAULT 0;
-- until threaded, a message is a conversation of its own, with an id of its own below 0
UPDATE messages SET thread_id = -id;
CREATE INDEX messages_by_thread ON messages (folder_id, thread_id);
CREATE INDEX messages_unthreaded ON messages (COALESCE(date, internal_date)) WHERE thread_id < 0;
CREATE INDEX messages_unreferenced ON messages (COALESCE(date, internal_date) DESC) WHERE refs IS NULL;
CREATE TABLE thread_ids (
    account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    key TEXT NOT NULL,
    thread_id INTEGER NOT NULL,
    PRIMARY KEY (account_id, key)
) WITHOUT ROWID;
CREATE INDEX thread_ids_by_thread ON thread_ids (account_id, thread_id);
-- the conversation ids handed out, one row each: a new one is atomic whatever connection asks
CREATE TABLE threads (id INTEGER PRIMARY KEY AUTOINCREMENT);
"#,
    // the address book the user keeps (cards.rs): people, their addresses (the default first), and groups of them
    r#"
CREATE TABLE cards (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    first TEXT NOT NULL DEFAULT '',
    last TEXT NOT NULL DEFAULT '',
    nickname TEXT NOT NULL DEFAULT '',
    company TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    -- kind TAB number, a line each
    phones TEXT NOT NULL DEFAULT '',
    -- the vCard lines not edited here, written out again on export
    extra TEXT NOT NULL DEFAULT ''
);
CREATE TABLE card_addresses (
    card_id INTEGER NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    address TEXT NOT NULL,
    position INTEGER NOT NULL,
    PRIMARY KEY (card_id, address)
) WITHOUT ROWID;
CREATE INDEX card_addresses_by_address ON card_addresses (address COLLATE NOCASE);
CREATE TABLE card_groups (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);
CREATE TABLE card_members (
    group_id INTEGER NOT NULL REFERENCES card_groups(id) ON DELETE CASCADE,
    -- a card, or NULL for an address of no card
    card_id INTEGER REFERENCES cards(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL DEFAULT '',
    position INTEGER NOT NULL
);
CREATE INDEX card_members_by_group ON card_members (group_id, position);
"#,
    // bounces (delivery failure and delay notices), marked in the list: by the sync from the BODYSTRUCTURE
    // (multipart/report; report-type=delivery-status), by the core when one is opened. Mail stored before is marked
    // from its cached source: the content type of its header, which ends at the first empty line
    r#"
ALTER TABLE messages ADD COLUMN bounce INTEGER NOT NULL DEFAULT 0;
UPDATE messages SET bounce = 1 WHERE id IN (
    SELECT message_id FROM (
        SELECT message_id, lower(CAST(substr(source, 1, min(16384, coalesce(min(crlf, lf), crlf, lf, 16384))) AS TEXT))
            AS header
        FROM (
            SELECT message_id, source, nullif(instr(source, X'0D0A0D0A'), 0) AS crlf,
                nullif(instr(source, X'0A0A'), 0) AS lf
            FROM bodies
        )
    )
    WHERE instr(header, 'multipart/report') > 0 AND instr(header, 'delivery-status') > 0
);
"#,
    // Watch and Ignore Conversation (marks.rs): a conversation's mark, 1 watched and 2 ignored, by its conversation id,
    // moved along when conversations are joined
    r#"
CREATE TABLE thread_marks (
    thread_id INTEGER PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    mark INTEGER NOT NULL
);
CREATE INDEX thread_marks_by_account ON thread_marks (account_id);
"#,
    // a conversation's messages in every folder (marks.rs: the unread ones Ignore marks read, the lists that show a
    // mark; threads.rs: joining conversations), which messages_by_thread, by folder first, cannot find
    r#"
CREATE INDEX messages_of_thread ON messages (thread_id);
"#,
    // the account's own name for the folder list ("Gmail", "Work"), empty for the name on its mail (text.rs)
    r#"
ALTER TABLE accounts ADD COLUMN account_name TEXT NOT NULL DEFAULT '';
"#,
    // the accounts' order, set by dragging their rows (accounts.rs move_account); to begin with, the order they were
    // added in
    r#"
ALTER TABLE accounts ADD COLUMN position INTEGER NOT NULL DEFAULT 0;
UPDATE accounts SET position = id;
"#,
    // the Date order by the Date header but never later than the arrival (messages.rs LIST_DATE): a message dated in
    // the future no longer stays on top of the list
    r#"
DROP INDEX messages_by_date;
CREATE INDEX messages_by_date ON messages (folder_id, COALESCE(MIN(date, internal_date), date, internal_date), uid);
DROP INDEX messages_all_by_date;
CREATE INDEX messages_all_by_date ON messages (COALESCE(MIN(date, internal_date), date, internal_date), uid, id);
"#,
    // the senders whose pictures load without asking (trusted.rs): an address or a whole domain, in lower case
    r#"
CREATE TABLE trusted_senders (
    id INTEGER PRIMARY KEY,
    value TEXT NOT NULL UNIQUE,
    domain INTEGER NOT NULL,
    added INTEGER NOT NULL
);
"#,
    // when a message became read, here or on the server: View > Hide Read Messages keeps those read since it was
    // turned on (search.rs Search::read_since), so a message does not leave the list the moment it is read
    r#"
ALTER TABLE messages ADD COLUMN seen_at INTEGER;
CREATE TRIGGER messages_seen_at AFTER UPDATE OF seen ON messages WHEN NEW.seen = 1 AND OLD.seen = 0
BEGIN
    UPDATE messages SET seen_at = CAST((julianday('now') - 2440587.5) * 86400000 AS INTEGER) WHERE id = NEW.id;
END;
"#,
    // downloading ahead (download.rs): the size of each source, so an account's total is had without reading them, and
    // a mark on the messages that could not be downloaded or read, not tried again in the background
    r#"
-- the sizes in a table of their own, kept by the triggers: a total read from them reads no source, and length() of a
-- stored BLOB reads its size from the record, not the BLOB
CREATE TABLE body_sizes (
    message_id INTEGER PRIMARY KEY REFERENCES messages(id) ON DELETE CASCADE,
    size INTEGER NOT NULL
);
INSERT INTO body_sizes (message_id, size) SELECT message_id, length(source) FROM bodies;
CREATE TRIGGER bodies_sized AFTER INSERT ON bodies
BEGIN
    INSERT OR REPLACE INTO body_sizes (message_id, size) VALUES (NEW.message_id, length(NEW.source));
END;
CREATE TRIGGER bodies_unsized AFTER DELETE ON bodies
BEGIN
    DELETE FROM body_sizes WHERE message_id = OLD.message_id;
END;
ALTER TABLE messages ADD COLUMN fetch_failed INTEGER NOT NULL DEFAULT 0;
-- the sources of messages on their way to another folder of the account, given to the rows they become there
-- (COPYUID), or back to theirs when the move fails
CREATE TABLE moving_sources (
    folder_id INTEGER NOT NULL,
    uid INTEGER NOT NULL,
    source BLOB NOT NULL,
    PRIMARY KEY (folder_id, uid)
);
"#,
    // the first words of what the sender wrote, for the message list's rows of three lines (pe-core snippet.rs): NULL
    // until the core has read the message's text, empty for a message without any
    r#"
ALTER TABLE messages ADD COLUMN snippet TEXT;
-- what the search indexed before there was a snippet, newest first: fetched again in the background
CREATE INDEX messages_snippet_missing ON messages (COALESCE(date, internal_date) DESC)
    WHERE snippet IS NULL AND text_indexed = 1;
-- the sources kept are read again where they are, for theirs (pe-core search.rs index_pending)
UPDATE bodies SET indexed = 0;
"#,
    // the sender's picture in the message list (pe-core senders.rs): the provider's verdicts fetched with the
    // summary (Authentication-Results and BIMI-Location, kept only until the core read them), what the core made of
    // them (bits: the From domain confirmed, a brand logo allowed, no verdict of the provider), and the logo's address
    // in a table of its own, its SVG downloaded once and kept
    r#"
ALTER TABLE messages ADD COLUMN auth_headers TEXT;
ALTER TABLE messages ADD COLUMN sender_auth INTEGER;
ALTER TABLE messages ADD COLUMN logo_id INTEGER;
CREATE TABLE logos (
    id INTEGER PRIMARY KEY,
    url TEXT NOT NULL UNIQUE,
    svg BLOB,
    -- when the SVG was downloaded, and when a download last failed (milliseconds since the Unix epoch)
    fetched INTEGER,
    failed INTEGER
);
-- what the core has yet to read, and the mail stored before, whose verdicts are fetched again, newest first
CREATE INDEX messages_auth_pending ON messages (id) WHERE auth_headers IS NOT NULL;
CREATE INDEX messages_auth_unknown ON messages (COALESCE(date, internal_date) DESC)
    WHERE sender_auth IS NULL AND auth_headers IS NULL AND fetch_failed = 0;
"#,
    // a contact's picture (pe-core card_pictures.rs): the core's own PNG, 256 pixels square, and a revision that grows
    // each time it is set, so the windows' picture keys change with it
    r#"
CREATE TABLE card_pictures (
    card_id INTEGER PRIMARY KEY REFERENCES cards(id) ON DELETE CASCADE,
    png BLOB NOT NULL,
    changed INTEGER NOT NULL
);
"#,
    // the messages being written, as each was last saved (by hand or automatically), until their window closes: what
    // a crash left here is opened again at the next start (pe-store recovery.rs). The compose window's fields; To, Cc
    // and Bcc, the References and the paths of the files attached a line each.
    r#"
CREATE TABLE compose_recovery (
    message_id TEXT PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    recipients TEXT NOT NULL,
    subject TEXT NOT NULL,
    html TEXT NOT NULL,
    quote TEXT NOT NULL,
    quote_text TEXT,
    in_reply_to TEXT,
    refs TEXT NOT NULL,
    attachments TEXT NOT NULL
);
"#,
    // Undo Send: a message the user sent waits in the Outbox for a few seconds (the send_delay setting), found by its
    // Message-ID to be taken back; undoable marks it as the user's (an agent's wait is for the user to stop it, and is
    // kept when the app quits)
    r#"
ALTER TABLE outbox ADD COLUMN message_id TEXT;
ALTER TABLE outbox ADD COLUMN undoable INTEGER NOT NULL DEFAULT 0;
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
    fn stored_bounces_are_marked_from_their_cached_header() {
        let mut db = Connection::open_in_memory().unwrap();
        // the schema before the bounce mark
        let bounce = MIGRATIONS.iter().position(|m| m.contains("ADD COLUMN bounce")).unwrap();
        for migration in &MIGRATIONS[..bounce] {
            db.execute_batch(migration).unwrap();
        }
        db.pragma_update(None, "user_version", bounce).unwrap();
        db.execute_batch(
            "INSERT INTO accounts (id, name, email, username, imap_host, imap_port, imap_security, smtp_host, \
             smtp_port, smtp_security) VALUES (1, 'A', 'a@x', 'a', 'h', 993, 'tls', 'h', 465, 'tls');
             INSERT INTO folders (id, account_id, path, name, flags, subscribed, selectable, position) \
             VALUES (1, 1, 'INBOX', 'INBOX', '', 1, 1, 0);",
        )
        .unwrap();
        let sources: [&[u8]; 5] = [
            // a delivery report, its parameter folded onto a line of its own
            b"From: MAILER-DAEMON@x\r\nContent-Type: Multipart/Report;\r\n\treport-type=\"delivery-status\"; boundary=b\r\n\r\n--b\r\n",
            // a message that only quotes one in its body
            b"From: a@x\r\nContent-Type: text/plain\r\n\r\nContent-Type: multipart/report; report-type=delivery-status\r\n",
            // another kind of report
            b"Content-Type: multipart/report; report-type=disposition-notification\r\n\r\nx",
            // no body
            b"Content-Type: multipart/report; report-type=delivery-status",
            // bare line feeds, the body quoting one
            b"Subject: hi\n\nContent-Type: multipart/report; report-type=delivery-status\n",
        ];
        for (index, source) in sources.iter().enumerate() {
            let id = index as i64 + 1;
            db.execute(
                "INSERT INTO messages (id, folder_id, uid, flags, seen, subject, from_name, from_address, recipients, \
                 has_attachments) VALUES (?1, 1, ?1, '', 0, '', '', '', '', 0)",
                [id],
            )
            .unwrap();
            db.execute(
                "INSERT INTO bodies (message_id, source) VALUES (?1, ?2)",
                rusqlite::params![id, source],
            )
            .unwrap();
        }
        // one without a cached source stays unmarked until the sync or the core marks it
        db.execute(
            "INSERT INTO messages (id, folder_id, uid, flags, seen, subject, from_name, from_address, recipients, \
             has_attachments) VALUES (6, 1, 6, '', 0, '', '', '', '', 0)",
            [],
        )
        .unwrap();
        migrate(&mut db).unwrap();
        let marked: Vec<i64> = db
            .prepare("SELECT id FROM messages WHERE bounce = 1 ORDER BY id")
            .unwrap()
            .query_map([], |row| row.get(0))
            .unwrap()
            .map(Result::unwrap)
            .collect();
        assert_eq!(marked, [1, 4]);
    }

    /// The query plan of `sql`, its steps joined
    fn plan(db: &Connection, sql: &str) -> String {
        let steps: Vec<String> = db
            .prepare(&format!("EXPLAIN QUERY PLAN {sql}"))
            .unwrap()
            .query_map([], |row| row.get::<_, String>(3))
            .unwrap()
            .map(Result::unwrap)
            .collect();
        steps.join("; ")
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
                let plan = plan(
                    &db,
                    &format!("SELECT id FROM messages WHERE folder_id = 1 ORDER BY {order} LIMIT 10"),
                );
                assert!(
                    !plan.contains("TEMP B-TREE"),
                    "{field:?} sorts without an index: {plan}"
                );
            }
        }
        // over the Inboxes of every account (search.rs keeps it off the folder indexes for these orders)
        for field in [crate::SortField::Date, crate::SortField::Received] {
            let order = crate::Sort {
                field,
                ascending: false,
            }
            .order_by();
            let sql = format!(
                "SELECT id FROM messages WHERE +folder_id IN ({}) ORDER BY {order} LIMIT 10",
                crate::search::INBOXES
            );
            let plan = plan(&db, &sql);
            assert!(
                !plan.contains("TEMP B-TREE"),
                "{field:?} over folders sorts without an index: {plan}"
            );
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
