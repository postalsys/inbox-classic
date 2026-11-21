//! Chinese, Japanese and Korean in what the store finds and orders: a word in the middle of a subject, a sender's
//! name or a message's text is found though nothing separates it (fold.rs `segment`), a name is completed by any of
//! its characters, and full width letters and digits are searched and ordered as ASCII.

use rusqlite::Connection;

use crate::{AccountSettings, Card, FolderInfo, IndexText, MessageInfo, Scope, Search, Sort, SortField, Store};

fn store() -> (Store, i64, i64) {
    let store = Store::open_in_memory().unwrap();
    let account = store.add_account(&AccountSettings::example("me@example.com")).unwrap();
    let folder = |path: &str, special: Option<&str>| FolderInfo {
        path: path.into(),
        name: path.into(),
        special_use: special.map(String::from),
        selectable: true,
        ..Default::default()
    };
    store
        .set_folders(account, &[folder("INBOX", None), folder("Sent", Some("\\Sent"))])
        .unwrap();
    let id = |path| store.find_folder(account, path).unwrap().unwrap().id;
    let (inbox, sent) = (id("INBOX"), id("Sent"));
    (store, inbox, sent)
}

fn message(uid: u64, subject: &str, from: (&str, &str)) -> MessageInfo {
    MessageInfo {
        uid,
        date: Some(uid as i64 * 100),
        subject: subject.into(),
        from_name: from.0.into(),
        from_address: from.1.into(),
        recipients: "Me <me@example.com>".into(),
        ..Default::default()
    }
}

fn mail(store: &Store, inbox: i64) {
    store
        .add_messages(
            inbox,
            &[
                message(1, "关于下周会议的安排", ("张伟", "wei@example.cn")),
                message(2, "見積書の送付について", ("山田太郎", "yamada@example.jp")),
                message(3, "회의에서 논의한 내용", ("김민수", "minsu@example.kr")),
                message(4, "Quarterly report", ("Anna Lind", "anna@example.com")),
                message(5, "会議資料ＡＢＣ１２３", ("佐藤", "sato@example.jp")),
                message(6, "東京都の天気", ("Weather", "w@example.com")),
            ],
        )
        .unwrap();
}

fn found(store: &Store, folder: i64, text: &str) -> Vec<u64> {
    let search = Search {
        scope: Scope::Folder(folder),
        text: text.into(),
        ..Default::default()
    };
    let mut uids: Vec<u64> = store
        .search(&search, Sort::default(), 0, 100)
        .unwrap()
        .iter()
        .map(|m| m.info.uid)
        .collect();
    uids.sort();
    uids
}

fn id_of(store: &Store, folder: i64, uid: u64) -> i64 {
    store
        .db
        .query_row(
            "SELECT id FROM messages WHERE folder_id = ?1 AND uid = ?2",
            [folder, uid as i64],
            |r| r.get(0),
        )
        .unwrap()
}

#[test]
fn finds_a_word_inside_words_without_spaces() {
    let (store, inbox, _) = store();
    mail(&store, inbox);
    store
        .set_indexed(
            id_of(&store, inbox, 4),
            &IndexText {
                body: "The numbers are in. 下周的预算已经批准了。予算は承認されました。".into(),
                ..Default::default()
            },
        )
        .unwrap();
    // a word in the middle of the subject
    assert_eq!(found(&store, inbox, "会议"), [1]);
    assert_eq!(found(&store, inbox, "安排"), [1]);
    assert_eq!(found(&store, inbox, "送付"), [2]);
    assert_eq!(found(&store, inbox, "회의"), [3]);
    assert_eq!(found(&store, inbox, "논의"), [3]);
    // a character alone, in two messages (会 of 会议 and of 会議)
    assert_eq!(found(&store, inbox, "会"), [1, 5]);
    // the characters must stand together, in that order
    assert_eq!(found(&store, inbox, "议会"), [] as [u64; 0]);
    // substring search: 京都 is inside 東京都 too, the price of finding words without a dictionary
    assert_eq!(found(&store, inbox, "京都"), [6]);
    // the sender's name, the text of the message
    assert_eq!(found(&store, inbox, "from:张伟"), [1]);
    assert_eq!(found(&store, inbox, "from:太郎"), [2]);
    assert_eq!(found(&store, inbox, "预算"), [4]);
    assert_eq!(found(&store, inbox, "承認"), [4]);
    // with the operators and the other words
    assert_eq!(found(&store, inbox, "subject:会议"), [1]);
    assert_eq!(found(&store, inbox, "subject:预算"), [] as [u64; 0]);
    assert_eq!(found(&store, inbox, "会 -会议"), [5]);
    assert_eq!(found(&store, inbox, "会议 OR 회의"), [1, 3]);
    assert_eq!(found(&store, inbox, "numbers 预算"), [4]);
    assert_eq!(found(&store, inbox, "\"会议的\""), [1]);
    assert_eq!(found(&store, inbox, "会议\u{3000}安排"), [1]);
    // full width letters and digits as ASCII, either way
    assert_eq!(found(&store, inbox, "abc123"), [5]);
    assert_eq!(found(&store, inbox, "ＡＢＣ"), [5]);
    assert_eq!(found(&store, inbox, "資料abc"), [5]);
    assert_eq!(found(&store, inbox, "ｑｕａｒｔ"), [4]);
    // and Latin words as before
    assert_eq!(found(&store, inbox, "quart"), [4]);
}

#[test]
fn full_width_letters_are_ordered_as_ascii() {
    let (store, inbox, _) = store();
    store
        .add_messages(
            inbox,
            &[
                message(1, "Ｂｕｄｇｅｔ", ("Ｚｅｄ", "z@example.jp")),
                message(2, "Apples", ("Ann", "a@example.com")),
                message(3, "Cherries", ("Bob", "b@example.com")),
            ],
        )
        .unwrap();
    let order = |field: SortField| -> Vec<u64> {
        let search = Search {
            scope: Scope::Folder(inbox),
            ..Default::default()
        };
        store
            .search(&search, Sort { field, ascending: true }, 0, 100)
            .unwrap()
            .iter()
            .map(|m| m.info.uid)
            .collect()
    };
    assert_eq!(order(SortField::Subject), [2, 1, 3]);
    assert_eq!(order(SortField::From), [2, 3, 1]);
}

#[test]
fn completes_a_name_by_any_of_its_characters() {
    let (store, inbox, sent) = store();
    mail(&store, inbox);
    let mut written = message(1, "", ("Me", "me@example.com"));
    written.correspondents = vec![("李小龙".into(), "li@example.cn".into())];
    store.add_messages(sent, &[written]).unwrap();
    store
        .save_card(&Card {
            name: "王芳".into(),
            addresses: vec!["fang@example.cn".into()],
            ..Default::default()
        })
        .unwrap();
    let contacts = |typed: &str| -> Vec<String> {
        let mut found: Vec<String> = store
            .contacts_matching(typed, 10)
            .unwrap()
            .into_iter()
            .map(|c| c.address)
            .collect();
        found.sort();
        found
    };
    assert_eq!(contacts("张"), ["wei@example.cn"]);
    assert_eq!(contacts("伟"), ["wei@example.cn"]);
    assert_eq!(contacts("张伟"), ["wei@example.cn"]);
    assert_eq!(contacts("太郎"), ["yamada@example.jp"]);
    assert_eq!(contacts("민수"), ["minsu@example.kr"]);
    assert_eq!(contacts("小龙"), ["li@example.cn"]);
    assert!(contacts("伟张").is_empty());
    // Latin names still by the start of a word only
    assert_eq!(contacts("lind"), ["anna@example.com"]);
    assert!(contacts("ind").is_empty());
    let book = |typed: &str| -> Vec<String> {
        store
            .book_matching(typed, 10)
            .unwrap()
            .0
            .into_iter()
            .map(|(_, address)| address)
            .collect()
    };
    assert_eq!(book("芳"), ["fang@example.cn"]);
    assert_eq!(book("王"), ["fang@example.cn"]);
}

/// Rows the schema's trigger wrote as they are (an older version, which does not segment) are found once the
/// migration indexed them again
#[test]
fn the_migration_indexes_again_what_was_stored_before() {
    let mut db = Connection::open_in_memory().unwrap();
    let before = crate::schema::MIGRATIONS
        .iter()
        .position(|m| m.contains("CREATE TEMP TABLE segmented"))
        .unwrap();
    crate::fold::register(&db).unwrap();
    for migration in &crate::schema::MIGRATIONS[..before] {
        db.execute_batch(migration).unwrap();
    }
    db.pragma_update(None, "user_version", before).unwrap();
    db.execute_batch(
        "INSERT INTO accounts (id, name, email, username, imap_host, imap_port, imap_security, smtp_host, \
         smtp_port, smtp_security) VALUES (1, 'A', 'a@x', 'a', 'h', 993, 'tls', 'h', 465, 'tls');
         INSERT INTO folders (id, account_id, path, name, flags, subscribed, selectable, position) \
         VALUES (1, 1, 'INBOX', 'INBOX', '', 1, 1, 0);
         INSERT INTO messages (id, folder_id, uid, flags, seen, subject, from_name, from_address, recipients, \
         has_attachments, text_indexed, snippet, sort_subject) VALUES \
         (1, 1, 1, '', 0, '关于会议', '', '', '', 0, 1, '', '关于会议'), \
         (2, 1, 2, '', 0, 'Ankara', '', '', '', 0, 1, '', 'ankara'), \
         (3, 1, 3, '', 0, 'Hello', '山田', 'y@x', '', 0, 1, '', 'hello'), \
         (4, 1, 4, '', 0, 'Ｑ３ plans', '', '', '', 0, 1, '', 'ｑ３ plans'), \
         (5, 1, 5, '', 0, 'Notes', '', '', '', 0, 1, '下周的预算', 'notes');
         INSERT INTO messages (id, folder_id, uid, flags, seen, subject, from_name, from_address, recipients, \
         has_attachments, text_indexed, snippet, sort_subject, protection, decrypted, outer_subject, sender_people) \
         VALUES (6, 1, 6, '', 0, '秘密会议', '', '', '', 0, 1, '内部', '秘密会议', 2, 1, '...', 'Spy spy@x');
         INSERT INTO bodies (message_id, source, indexed) VALUES (1, x'00', 1), (2, x'00', 1), (5, x'00', 1), \
         (6, x'00', 1);",
    )
    .unwrap();
    let found = |db: &Connection, word: &str| -> Vec<i64> {
        let mut statement = db
            .prepare("SELECT rowid FROM messages_fts WHERE messages_fts MATCH ?1 ORDER BY rowid")
            .unwrap();
        statement
            .query_map([word], |row| row.get(0))
            .unwrap()
            .map(Result::unwrap)
            .collect()
    };
    assert_eq!(found(&db, "\"会 议\""), [] as [i64; 0]);
    crate::schema::migrate(&mut db).unwrap();
    assert_eq!(found(&db, "\"会 议\""), [1]);
    assert_eq!(found(&db, "senders : \"田\""), [3]);
    assert_eq!(found(&db, "q3"), [4]);
    assert_eq!(found(&db, "ankara"), [2]);
    // those with a cached source indexed from it, the other's text read again; the rest as it was
    let state = |id: i64| -> (i64, Option<i64>) {
        db.query_row(
            "SELECT m.text_indexed, b.indexed FROM messages m LEFT JOIN bodies b ON b.message_id = m.id \
             WHERE m.id = ?1",
            [id],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .unwrap()
    };
    assert_eq!(state(1), (1, Some(0)));
    assert_eq!(state(2), (1, Some(1)));
    assert_eq!(state(3), (0, None));
    assert_eq!(state(4), (0, None));
    assert_eq!(state(5), (1, Some(0)));
    // one decrypted goes back to how it came, its decrypted words out of the index, for the background pass to
    // decrypt again
    assert_eq!(found(&db, "\"秘 密\""), [] as [i64; 0]);
    assert_eq!(found(&db, "spy"), [] as [i64; 0]);
    let (subject, decrypted, snippet): (String, i64, String) = db
        .query_row(
            "SELECT subject, decrypted, snippet FROM messages WHERE id = 6",
            [],
            |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
        )
        .unwrap();
    assert_eq!((subject.as_str(), decrypted, snippet.as_str()), ("...", 0, ""));
    assert_eq!(state(6), (1, Some(0)));
    // the sort key of full width letters as ASCII
    let key: String = db
        .query_row("SELECT sort_subject FROM messages WHERE id = 4", [], |row| row.get(0))
        .unwrap();
    assert_eq!(key, "q3 plans");
}
