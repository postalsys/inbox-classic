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
];

pub(crate) fn migrate(db: &mut Connection) -> rusqlite::Result<()> {
    let version: usize = db.pragma_query_value(None, "user_version", |row| row.get(0))?;
    for (index, migration) in MIGRATIONS.iter().enumerate().skip(version) {
        let tx = db.transaction()?;
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
