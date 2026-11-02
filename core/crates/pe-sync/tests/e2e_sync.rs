//! The sync against ImapKit (core/e2e): a fresh store filled from the server, then changes made
//! on the server by "another client" through ImapKit's REST API, found by the next sync or by
//! the events of the selected folder.
//!
//! Skipped without Node.js and `npm ci` in core/e2e, unless PE_E2E_REQUIRED is set.

use pe_imap::{Client, Event};
use pe_net::Security;
use pe_store::{AccountId, AccountSettings, FolderId, Sort, Store};
use pe_sync::{
    Change, Report, apply_event, expunge_message, fetch_source, move_message, set_flag, sync_folder, sync_folders,
};
use pe_testkit::{ImapKit, USER, password, rfc822, wait_for};
use serde_json::{Value, json};
use tokio::sync::mpsc::UnboundedReceiver;

struct Setup {
    server: ImapKit,
    client: Client,
    events: UnboundedReceiver<Event>,
    store: Store,
    account: AccountId,
}

async fn setup(config: Value) -> Option<Setup> {
    let server = ImapKit::start(config)?;
    let (client, events) = Client::connect(server.imap_config(Security::Plain, password()))
        .await
        .expect("connect");
    let store = Store::open_in_memory().unwrap();
    let account = store
        .add_account(&AccountSettings {
            name: "Test".into(),
            email: "testuser@example.com".into(),
            username: USER.into(),
            imap_host: "127.0.0.1".into(),
            imap_port: server.imap,
            imap_security: pe_store::Security::Plain,
            smtp_host: "127.0.0.1".into(),
            smtp_port: server.smtp,
            smtp_security: pe_store::Security::Plain,
            auth: pe_store::Auth::Password,
        })
        .unwrap();
    Some(Setup {
        server,
        client,
        events,
        store,
        account,
    })
}

macro_rules! setup {
    ($config:expr) => {
        match setup($config).await {
            Some(setup) => setup,
            None => return,
        }
    };
}

impl Setup {
    async fn folder(&mut self, path: &str) -> FolderId {
        sync_folders(&mut self.client, &mut self.store, self.account)
            .await
            .unwrap();
        self.store.find_folder(self.account, path).unwrap().expect(path).id
    }

    async fn sync(&mut self, folder: FolderId) -> Report {
        sync_folder(&mut self.client, &mut self.store, folder).await.unwrap()
    }

    fn subjects(&self, folder: FolderId) -> Vec<String> {
        let sort = Sort {
            field: pe_store::SortField::Received,
            ascending: true,
        };
        self.store
            .messages(folder, sort, 0, 10_000)
            .unwrap()
            .into_iter()
            .map(|m| m.info.subject)
            .collect()
    }

    /// Applies events until one changes `folder`
    async fn wait_for_change(&mut self, folder: FolderId) -> Change {
        let (store, account) = (&mut self.store, self.account);
        let mut change = Change::None;
        wait_for(&mut self.events, |event| {
            change = apply_event(store, account, event).unwrap();
            matches!(change, Change::Updated(id) | Change::NeedsSync(id) if id == folder)
        })
        .await;
        change
    }
}

const ATTACHMENT: &str = "From: Sender <sender@example.com>\r\nTo: a@example.com, Bob <b@example.com>\r\nSubject: With a file\r\nDate: Tue, 7 Oct 2025 10:00:00 +0000\r\nMIME-Version: 1.0\r\nContent-Type: multipart/mixed; boundary=x\r\n\r\n--x\r\nContent-Type: text/plain\r\n\r\nsee attached\r\n--x\r\nContent-Type: application/pdf; name=a.pdf\r\nContent-Transfer-Encoding: base64\r\n\r\nJVBERg==\r\n--x--\r\n";

// imapflow's sync tests run with CONDSTORE and without: both ways of finding flag changes
async fn full_sync(config: Value) {
    let mut s = setup!(config);
    let first = s.server.add_message("INBOX", &rfc822("One", "1"), &["\\Seen"]);
    let second = s.server.add_message("INBOX", &rfc822("Two", "2"), &[]);
    s.server.add_message("INBOX", ATTACHMENT, &["\\Flagged"]);

    let folders = sync_folders(&mut s.client, &mut s.store, s.account).await.unwrap();
    assert!(folders.iter().any(|f| f.info.path == "INBOX"));
    let sent = folders.iter().find(|f| f.info.path == "Sent").expect("Sent");
    assert_eq!(sent.info.special_use.as_deref(), Some("\\Sent"));
    let inbox = s.folder("INBOX").await;

    let report = s.sync(inbox).await;
    assert_eq!(
        report,
        Report {
            added: 3,
            ..Default::default()
        }
    );
    assert_eq!(s.subjects(inbox), ["One", "Two", "With a file"]);
    let folder = s.store.folder(inbox).unwrap();
    assert_eq!((folder.total, folder.unread), (3, 2));
    assert!(folder.state.uid_validity.is_some() && folder.state.uid_next.is_some());
    let page = s.store.messages(inbox, Sort::default(), 0, 1).unwrap();
    let newest = &page[0].info;
    assert_eq!(newest.subject, "With a file");
    assert!(newest.flagged() && newest.has_attachments);
    assert_eq!(newest.recipients, "a@example.com, Bob");
    assert_eq!(newest.from_name, "Sender");

    // nothing changed: nothing to do
    assert_eq!(s.sync(inbox).await, Report::default());

    // another client reads, adds, deletes
    s.server.set_flags("INBOX", &[second], &["\\Seen"], "add");
    s.server.set_flags("INBOX", &[first], &["\\Seen"], "remove");
    s.server.add_message("INBOX", &rfc822("Four", "4"), &[]);
    s.server.expunge("INBOX", &[first]);
    let report = s.sync(inbox).await;
    assert_eq!(
        report,
        Report {
            added: 1,
            removed: 1,
            flags_changed: 1,
            reset: false
        }
    );
    assert_eq!(s.subjects(inbox), ["Two", "With a file", "Four"]);
    assert!(s.store.message(inbox, second).unwrap().unwrap().info.seen());
    assert_eq!(s.sync(inbox).await, Report::default());
}

#[tokio::test]
async fn syncs_with_condstore() {
    full_sync(json!({})).await;
}

#[tokio::test]
async fn syncs_without_condstore() {
    full_sync(json!({ "plugins": ["SPECIAL-USE", "UIDPLUS"] })).await;
}

#[tokio::test]
async fn sources_are_fetched_once() {
    let mut s = setup!(json!({}));
    let uid = s.server.add_message("INBOX", ATTACHMENT, &[]);
    let inbox = s.folder("INBOX").await;
    s.sync(inbox).await;
    let source = fetch_source(&mut s.client, &mut s.store, inbox, uid).await.unwrap();
    assert_eq!(source, ATTACHMENT.as_bytes());
    assert!(s.store.message(inbox, uid).unwrap().unwrap().cached);
    // reading the source did not mark the message as seen
    assert!(!s.store.message(inbox, uid).unwrap().unwrap().info.seen());
    assert_eq!(s.server.messages("INBOX")[0]["flags"], json!([]));

    // cached: still there after the server lost it
    s.server.expunge("INBOX", &[uid]);
    let cached = fetch_source(&mut s.client, &mut s.store, inbox, uid).await.unwrap();
    assert_eq!(cached, ATTACHMENT.as_bytes());

    let missing = fetch_source(&mut s.client, &mut s.store, inbox, uid + 100).await;
    assert!(matches!(missing, Err(pe_sync::Error::MessageGone)), "{missing:?}");
}

#[tokio::test]
async fn events_of_the_selected_folder() {
    let mut s = setup!(json!({}));
    let uid = s.server.add_message("INBOX", &rfc822("One", "1"), &[]);
    let inbox = s.folder("INBOX").await;
    s.sync(inbox).await;

    s.server.set_flags("INBOX", &[uid], &["\\Seen"], "add");
    s.client.noop().await.unwrap();
    assert_eq!(s.wait_for_change(inbox).await, Change::Updated(inbox));
    assert!(s.store.message(inbox, uid).unwrap().unwrap().info.seen());

    s.server.add_message("INBOX", &rfc822("Two", "2"), &[]);
    s.client.noop().await.unwrap();
    assert_eq!(s.wait_for_change(inbox).await, Change::NeedsSync(inbox));
    assert_eq!(s.sync(inbox).await.added, 1);
}

#[tokio::test]
async fn a_new_uid_validity_starts_over() {
    let mut s = setup!(json!({}));
    s.client.create("Work").await.unwrap();
    let work = s.folder("Work").await;
    s.server.add_message("Work", &rfc822("Old", "1"), &[]);
    s.sync(work).await;
    let old_validity = s.store.folder(work).unwrap().state.uid_validity;

    // the folder is deleted and made again: same name, other messages
    s.client.unselect().await.unwrap();
    s.client.delete("Work").await.unwrap();
    s.client.create("Work").await.unwrap();
    s.server.add_message("Work", &rfc822("New", "2"), &[]);
    let report = s.sync(work).await;
    assert!(report.reset, "{report:?}");
    assert_ne!(s.store.folder(work).unwrap().state.uid_validity, old_validity);
    assert_eq!(s.subjects(work), ["New"]);
}

#[tokio::test]
async fn folders_follow_the_server() {
    let mut s = setup!(json!({}));
    s.client.create("Projects").await.unwrap();
    let projects = s.folder("Projects").await;
    s.server.add_message("Projects", &rfc822("Plan", "1"), &[]);
    s.sync(projects).await;
    s.client.unselect().await.unwrap();
    s.client.rename("Projects", "Archive2025").await.unwrap();
    sync_folders(&mut s.client, &mut s.store, s.account).await.unwrap();
    assert!(s.store.find_folder(s.account, "Projects").unwrap().is_none());
    let renamed = s
        .store
        .find_folder(s.account, "Archive2025")
        .unwrap()
        .expect("renamed folder");
    assert_eq!(renamed.total, 0, "a new folder to the store");
    assert_eq!(s.sync(renamed.id).await.added, 1);
}

#[tokio::test]
async fn large_folders_arrive_in_batches() {
    let mut s = setup!(json!({}));
    // more than two batches of new messages, and more than ImapKit's MESSAGELIMIT of 1000 for one
    // command
    for i in 0..1100 {
        s.server
            .add_message("INBOX", &rfc822(&format!("Message {i}"), "x"), &[]);
    }
    let inbox = s.folder("INBOX").await;
    assert_eq!(s.sync(inbox).await.added, 1100);
    let folder = s.store.folder(inbox).unwrap();
    assert_eq!((folder.total, folder.unread), (1100, 1100));
    let subjects = s.subjects(inbox);
    assert_eq!(
        (subjects[0].as_str(), subjects[1099].as_str()),
        ("Message 0", "Message 1099")
    );
    assert_eq!(s.sync(inbox).await, Report::default());

    // flag changes and deletions past the server's MESSAGELIMIT of 1000 are found too
    let uids: Vec<u64> = s.store.uids(inbox).unwrap();
    s.server.set_flags("INBOX", &uids[..3], &["\\Seen"], "add");
    s.server.expunge("INBOX", &uids[3..5]);
    let report = s.sync(inbox).await;
    assert_eq!((report.flags_changed, report.removed), (3, 2), "{report:?}");
}

/// Flagging, moving and deleting on the server, as the windows ask for them
async fn message_actions(config: Value) {
    let mut s = setup!(config);
    let keep = s.server.add_message("INBOX", &rfc822("Keep", "1"), &[]);
    let moved = s.server.add_message("INBOX", &rfc822("Move me", "2"), &[]);
    let deleted = s.server.add_message("INBOX", &rfc822("Delete me", "3"), &[]);
    let inbox = s.folder("INBOX").await;
    let archive = s.folder("Archive").await;
    s.sync(inbox).await;

    set_flag(&mut s.client, &mut s.store, inbox, keep, "\\Flagged", true)
        .await
        .unwrap();
    assert!(s.server.flags("INBOX", keep).contains(&"\\Flagged".to_string()));
    set_flag(&mut s.client, &mut s.store, inbox, keep, "\\Flagged", false)
        .await
        .unwrap();
    assert!(!s.server.flags("INBOX", keep).contains(&"\\Flagged".to_string()));

    move_message(&mut s.client, &mut s.store, inbox, moved, archive)
        .await
        .unwrap();
    assert_eq!(s.server.subjects("Archive"), ["Move me"]);
    assert_eq!(s.server.subjects("INBOX"), ["Keep", "Delete me"]);

    expunge_message(&mut s.client, &mut s.store, inbox, deleted)
        .await
        .unwrap();
    assert_eq!(s.server.subjects("INBOX"), ["Keep"]);
    // the sync agrees with the server
    s.sync(inbox).await;
    s.sync(archive).await;
    assert_eq!(s.subjects(inbox), ["Keep"]);
    assert_eq!(s.subjects(archive), ["Move me"]);
}

#[tokio::test]
async fn message_actions_with_move_and_uidplus() {
    message_actions(json!({})).await;
}

#[tokio::test]
async fn message_actions_without_move_and_uidplus() {
    // COPY and EXPUNGE, as on servers that have neither
    message_actions(json!({ "plugins": ["SPECIAL-USE"] })).await;
}
