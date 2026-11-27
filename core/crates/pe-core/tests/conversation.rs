//! A conversation in the reading pane: its messages in every folder of the account, the read ones folded to a row,
//! the unread ones and the selected one open, each open message a view of its own, and what a click on a message, its
//! arrow, Next and Previous, Open All and Fold All do.

use pe_core::{Action, Core, Event, Options, PasswordStore, Selected};
use pe_store::{AccountSettings, Auth, FolderInfo, MessageInfo, MessageRef, Security, Store};
use std::sync::{Arc, Mutex};

struct World {
    core: Arc<Core>,
    /// the core's events, as the windows get them
    events: Arc<Mutex<Vec<Event>>>,
    dir: pe_testkit::TempDir,
    inbox: i64,
    sent: i64,
    drafts: i64,
}

fn raw(id: &str, answers: &str, from: &str, text: &str) -> String {
    let refs = if answers.is_empty() {
        String::new()
    } else {
        format!("In-Reply-To: {answers}\r\nReferences: {answers}\r\n")
    };
    format!(
        "From: {from}\r\nTo: Me <me@example.org>\r\nSubject: Plans for the trip\r\nMessage-ID: {id}\r\n{refs}\
         Date: Sun, 22 Nov 2026 09:04:00 +0000\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n{text}\r\n"
    )
}

/// The account me@example.org with an Inbox, Sent Items and Drafts, and a conversation: Dave's question (read), Carol's
/// answer (unread), the user's own answer in Sent Items, a draft, and Bob's answer (unread, not downloaded yet)
fn world(name: &str) -> World {
    let dir = pe_testkit::TempDir::new(name);
    let path = dir.path().join("store.db");
    let store = Store::open(&path).unwrap();
    let account = store
        .add_account(&AccountSettings {
            name: "Me".into(),
            email: "me@example.org".into(),
            username: "me@example.org".into(),
            imap_host: "imap.invalid".into(),
            imap_port: 993,
            imap_security: Security::Tls,
            smtp_host: "smtp.invalid".into(),
            smtp_port: 465,
            smtp_security: Security::Tls,
            auth: Auth::Password,
        })
        .unwrap();
    let folder = |path: &str, special: Option<&str>| FolderInfo {
        path: path.into(),
        name: path.into(),
        selectable: true,
        special_use: special.map(str::to_string),
        ..Default::default()
    };
    store
        .set_folders(
            account,
            &[
                folder("INBOX", None),
                folder("Sent", Some("\\Sent")),
                folder("Drafts", Some("\\Drafts")),
            ],
        )
        .unwrap();
    let id = |path: &str| {
        store
            .folders(account)
            .unwrap()
            .into_iter()
            .find(|f| f.info.path == path)
            .unwrap()
            .id
    };
    let (inbox, sent, drafts) = (id("INBOX"), id("Sent"), id("Drafts"));
    let put = |folder: i64,
               uid: u64,
               at: i64,
               message_id: &str,
               answers: &str,
               from: &str,
               text: Option<&str>,
               seen: bool| {
        let info = MessageInfo {
            uid,
            date: Some(at),
            internal_date: Some(at),
            subject: "Plans for the trip".into(),
            from_name: from.split(" <").next().unwrap().into(),
            from_address: from.split(" <").nth(1).map_or(from, |a| a.trim_end_matches('>')).into(),
            message_id: Some(message_id.into()),
            references: if answers.is_empty() {
                Vec::new()
            } else {
                vec![answers.into()]
            },
            flags: if seen { vec!["\\Seen".into()] } else { Vec::new() },
            ..Default::default()
        };
        store.add_messages(folder, &[info]).unwrap();
        if let Some(text) = text {
            store
                .set_source(folder, uid, raw(message_id, answers, from, text).as_bytes())
                .unwrap();
        }
    };
    put(
        inbox,
        1,
        100,
        "<a@x>",
        "",
        "Dave <dave@example.com>",
        Some("Where do we go?"),
        true,
    );
    put(
        inbox,
        2,
        200,
        "<b@x>",
        "<a@x>",
        "Carol <carol@example.com>",
        Some("The lake."),
        false,
    );
    put(
        sent,
        1,
        300,
        "<c@x>",
        "<a@x>",
        "Me <me@example.org>",
        Some("The lake works for me."),
        true,
    );
    put(
        drafts,
        1,
        350,
        "<d@x>",
        "<a@x>",
        "Me <me@example.org>",
        Some("I will book the cabin."),
        true,
    );
    put(inbox, 3, 400, "<e@x>", "<a@x>", "Bob <bob@example.com>", None, false);
    drop(store);
    let events: Arc<Mutex<Vec<Event>>> = Arc::default();
    let told = events.clone();
    let core = Core::open_with(
        &path,
        Options {
            passwords: PasswordStore::Memory,
            ..Default::default()
        },
        move |event| told.lock().unwrap().push(event),
    )
    .unwrap();
    World {
        core: Arc::new(core),
        events,
        dir,
        inbox,
        sent,
        drafts,
    }
}

/// Waits up to 10 seconds for an event `wanted` finds; false when none came
fn wait(w: &World, wanted: impl Fn(&Event) -> bool) -> bool {
    for _ in 0..200 {
        if w.events.lock().unwrap().iter().any(&wanted) {
            return true;
        }
        std::thread::sleep(std::time::Duration::from_millis(50));
    }
    false
}

fn at(folder: i64, uid: u64) -> MessageRef {
    MessageRef { folder, uid }
}

/// The document each entry's frame shows: the selected one's is the view's own, the others' their own views'; None
/// for a folded message or one still downloading
fn documents(view: &pe_core::MessageView) -> Vec<Option<String>> {
    let info = view.conversation.as_ref().expect("a conversation's view");
    info.entries
        .iter()
        .map(|entry| match (entry.selected, &entry.view) {
            (true, _) => Some(view.document.clone()),
            (false, Some(own)) => Some(own.document.clone()),
            (false, None) => None,
        })
        .collect()
}

#[test]
fn the_conversation_stacks_its_messages_at_the_first_unread() {
    pe_core::i18n::set_language("en");
    let w = world("conversation-stack");
    let focus = at(w.inbox, 2);
    let view = w.core.conversation_view(focus, false, false).unwrap();
    let info = view.conversation.clone().expect("a conversation's view");
    assert_eq!(
        info.count, 5,
        "the Inbox's three, the reply in Sent Items and the draft"
    );
    assert_eq!(
        info.waiting,
        [at(w.inbox, 3)],
        "Bob's answer is not downloaded yet: asked for"
    );
    assert_eq!(info.subject, "Plans for the trip");
    assert_eq!(info.summary, "5 messages, 2 unread");
    assert_eq!(info.people, "Dave, Carol, You, Bob");
    assert_eq!(
        info.line, "5 messages, 2 unread \u{00B7} Dave, Carol, You, Bob",
        "the line under the subject"
    );
    // Dave's read question folded, Carol's unread answer open and selected, Bob's open but on its way
    let open: Vec<bool> = documents(&view).iter().map(Option::is_some).collect();
    assert_eq!(open, [false, true, false, false, false]);
    assert!(view.document.contains("The lake.") && view.from.contains("Carol"));
    let rows: Vec<(&str, &str, &str)> = info
        .entries
        .iter()
        .map(|e| (e.from.as_str(), e.folder.as_str(), e.note.as_str()))
        .collect();
    assert_eq!(
        rows,
        [
            ("Dave", "", ""),
            ("Carol", "", ""),
            ("You", "Sent Items", ""),
            ("You", "Drafts", "Draft"),
            ("Bob", "", "Downloading…"),
        ]
    );
    assert!(info.entries[1].selected && info.entries[4].open && info.entries[4].unread);
    assert_eq!(info.entries[2].found_in, "Found in Sent Items");
    assert!(info.entries[3].draft);
    // Print prints the selected message alone
    let printed = view.print_document.as_deref().unwrap_or(&view.document);
    assert!(printed.contains("The lake.") && !printed.contains("Where do we go?"));
}

#[test]
fn a_click_selects_the_arrow_folds_and_the_shown_ones_are_marked_read() {
    pe_core::i18n::set_language("en");
    let w = world("conversation-click");
    let focus = at(w.inbox, 2);
    w.core.conversation_view(focus, false, false).unwrap();
    // Dave's row: his message opens and is selected
    assert_eq!(w.core.conversation_select(focus, 0), Some(at(w.inbox, 1)));
    let view = w.core.conversation_view(at(w.inbox, 1), false, false).unwrap();
    let docs = documents(&view);
    assert!(docs[0].as_deref().is_some_and(|d| d.contains("Where do we go?")));
    assert!(docs[1].as_deref().is_some_and(|d| d.contains("The lake.")));
    assert!(view.from.contains("Dave"));
    // Carol's open message clicked: only selected, Dave's stays open
    assert_eq!(w.core.conversation_select(at(w.inbox, 1), 1), Some(focus));
    let view = w.core.conversation_view(focus, false, false).unwrap();
    assert!(documents(&view)[0].is_some() && view.from.contains("Carol"));
    // the reply in Sent Items opens with its arrow and is selected
    assert_eq!(w.core.conversation_toggle(focus, 2), Some(at(w.sent, 1)));
    let view = w.core.conversation_view(at(w.sent, 1), false, false).unwrap();
    assert!(view.document.contains("The lake works for me."));
    // Carol's arrow: hers folds, the selection stays
    assert_eq!(w.core.conversation_toggle(at(w.sent, 1), 1), Some(at(w.sent, 1)));
    let view = w.core.conversation_view(at(w.sent, 1), false, false).unwrap();
    assert!(documents(&view)[1].is_none());
    // shown: the unread messages it showed open are marked read (Carol's was folded by then: it stays unread)
    let _ = w.core.conversation_shown(at(w.sent, 1));
    let store = Store::open(w.dir.path().join("store.db")).unwrap();
    assert!(!store.message(w.inbox, 2).unwrap().unwrap().info.seen());
    // opened again at Carol's, then shown: hers is marked read
    w.core.conversation_select(at(w.sent, 1), 1);
    w.core.conversation_view(focus, false, false).unwrap();
    let _ = w.core.conversation_shown(focus);
    assert!(store.message(w.inbox, 2).unwrap().unwrap().info.seen());
}

#[test]
fn next_previous_open_all_and_fold_all() {
    pe_core::i18n::set_language("en");
    let w = world("conversation-keys");
    let focus = at(w.inbox, 2);
    w.core.conversation_view(focus, false, false).unwrap();
    assert_eq!(w.core.conversation_step(focus, -1), Some(at(w.inbox, 1)));
    assert_eq!(w.core.conversation_step(at(w.inbox, 1), -1), None, "the first message");
    assert_eq!(w.core.conversation_step(at(w.inbox, 1), 1), Some(focus));
    assert_eq!(w.core.conversation_open_all(focus, true), Some(focus));
    let view = w.core.conversation_view(focus, false, false).unwrap();
    let open: Vec<bool> = view.conversation.unwrap().entries.iter().map(|e| e.open).collect();
    assert_eq!(open, [true; 5]);
    assert_eq!(w.core.conversation_open_all(focus, false), Some(focus));
    let view = w.core.conversation_view(focus, false, false).unwrap();
    let open: Vec<bool> = view.conversation.unwrap().entries.iter().map(|e| e.open).collect();
    assert_eq!(
        open,
        [false, true, false, false, false],
        "every one folded but the selected"
    );
}

#[test]
fn a_signed_message_shows_in_the_stack_with_its_labels() {
    pe_core::i18n::set_language("en");
    let w = world("conversation-sealed");
    let store = Store::open(w.dir.path().join("store.db")).unwrap();
    // inline signed text: the store sees a plain message, the view finds the signature
    let signed = "-----BEGIN PGP SIGNED MESSAGE-----\r\nHash: SHA256\r\n\r\nPay the new account.\r\n\
                  -----BEGIN PGP SIGNATURE-----\r\n\r\niQEzBAEBCAAdFiEE\r\n=abcd\r\n-----END PGP SIGNATURE-----";
    store
        .add_messages(
            w.inbox,
            &[MessageInfo {
                uid: 11,
                date: Some(450),
                internal_date: Some(450),
                subject: "Re: Plans for the trip".into(),
                message_id: Some("<p@x>".into()),
                references: vec!["<a@x>".into()],
                ..Default::default()
            }],
        )
        .unwrap();
    store
        .set_source(
            w.inbox,
            11,
            raw("<p@x>", "<a@x>", "Pat <pat@example.com>", signed).as_bytes(),
        )
        .unwrap();
    // opened by Open All: its own view, the page of its labelled parts, with pictures asked for the conversation
    let focus = at(w.inbox, 2);
    w.core.conversation_view(focus, false, false).unwrap();
    w.core.conversation_open_all(focus, true);
    let view = w.core.conversation_view(focus, true, false).unwrap();
    let info = view.conversation.clone().unwrap();
    assert_eq!(info.count, 6);
    let pat = info.entries.iter().find(|e| e.at == at(w.inbox, 11)).unwrap();
    let own = pat.view.as_deref().expect("its own view in the stack");
    assert!(own.protection.is_some(), "with its labels");
    assert!(
        !own.document.contains("img-src data: http"),
        "never the conversation's pictures: its own page lets none load"
    );
    // opened at it, it is the selected message of the conversation, its labels on it
    let view = w.core.conversation_view(at(w.inbox, 11), false, false).unwrap();
    assert!(view.conversation.is_some() && view.protection.is_some());
}

#[test]
fn newest_first_and_the_printout() {
    pe_core::i18n::set_language("en");
    let w = world("conversation-order");
    let view = w.core.conversation_view(at(w.inbox, 2), false, true).unwrap();
    let senders: Vec<String> = view
        .conversation
        .unwrap()
        .entries
        .iter()
        .map(|e| e.from.clone())
        .collect();
    assert_eq!(senders, ["Bob", "You", "You", "Carol", "Dave"], "newest first");
    let printout = w.core.conversation_printout(at(w.inbox, 2), false).unwrap();
    assert!(!printout.is_empty());
    let (dave, carol) = (
        printout.find("Where do we go?").unwrap(),
        printout.find("The lake.").unwrap(),
    );
    assert!(dave < carol, "printed in the conversation's order");
    assert!(printout.contains("I will book the cabin."), "the draft too");
}

#[test]
fn a_message_alone_is_shown_by_itself() {
    pe_core::i18n::set_language("en");
    let w = world("conversation-alone");
    let store = Store::open(w.dir.path().join("store.db")).unwrap();
    let lonely = MessageInfo {
        uid: 9,
        date: Some(500),
        subject: "Alone".into(),
        message_id: Some("<z@x>".into()),
        ..Default::default()
    };
    store.add_messages(w.inbox, &[lonely]).unwrap();
    store
        .set_source(
            w.inbox,
            9,
            raw("<z@x>", "", "Zed <z@example.com>", "Just me.").as_bytes(),
        )
        .unwrap();
    let view = w.core.conversation_view(at(w.inbox, 9), false, false).unwrap();
    assert!(view.conversation.is_none() && view.document.contains("Just me."));
}

#[test]
fn whole_conversation_takes_the_other_folders_messages() {
    pe_core::i18n::set_language("en");
    let w = world("conversation-elsewhere");
    // the collapsed row's messages in the Inbox
    let row = Selected::Listed(vec![at(w.inbox, 1), at(w.inbox, 2), at(w.inbox, 3)]);
    let delete = w.core.conversation_elsewhere(&row, Action::Delete).unwrap();
    assert_eq!(
        delete,
        [at(w.sent, 1), at(w.drafts, 1)],
        "Delete takes the reply and the draft too"
    );
    assert!(
        w.core.conversation_elsewhere(&row, Action::Archive).unwrap().is_empty(),
        "Archive leaves Sent Items and Drafts"
    );
    assert!(
        w.core
            .conversation_elsewhere(&row, Action::Read(true))
            .unwrap()
            .is_empty()
    );
    // one message of the conversation chosen by itself: no question
    let one = Selected::Listed(vec![at(w.inbox, 2)]);
    assert!(w.core.conversation_elsewhere(&one, Action::Delete).unwrap().is_empty());
    assert_eq!(
        pe_core::conversation::elsewhere_question(2),
        "This conversation also has 2 messages in other folders."
    );
}

#[test]
fn a_message_unread_since_the_conversation_was_shown_opens() {
    pe_core::i18n::set_language("en");
    let w = world("conversation-unread-since");
    let focus = at(w.inbox, 2);
    let view = w.core.conversation_view(focus, false, false).unwrap();
    assert!(documents(&view)[0].is_none(), "Dave's read question folded");
    // marked unread elsewhere (or a reply that came): open the next time it is shown
    let store = Store::open(w.dir.path().join("store.db")).unwrap();
    store.set_flag(w.inbox, 1, "\\Seen", false).unwrap();
    let view = w.core.conversation_view(focus, false, false).unwrap();
    assert!(
        documents(&view)[0]
            .as_deref()
            .is_some_and(|d| d.contains("Where do we go?"))
    );
    // an unread message the user folds stays folded
    w.core.conversation_toggle(focus, 0);
    let view = w.core.conversation_view(focus, false, false).unwrap();
    assert!(documents(&view)[0].is_none());
}

/// An open message downloaded while its conversation's view was built on a worker is told again when the window
/// takes the view: its own MessageReady came while the window still had the view before, which did not wait for it
#[test]
fn a_message_that_arrives_while_its_conversation_is_built_is_told_again() {
    pe_core::i18n::set_language("en");
    let w = world("conversation-arrived");
    let bob = at(w.inbox, 3);
    let request = w.core.conversation_view_start(at(w.inbox, 2), false, false).unwrap();
    assert!(wait(&w, |e| *e == Event::ViewReady { request }), "the view is built");
    // Bob's answer is downloaded now, after the view that waits for it was built
    let store = Store::open(w.dir.path().join("store.db")).unwrap();
    store
        .set_source(
            bob.folder,
            bob.uid,
            raw("<e@x>", "<a@x>", "Bob <bob@example.com>", "Count me in.").as_bytes(),
        )
        .unwrap();
    drop(store);
    w.events.lock().unwrap().clear();
    let view = w.core.message_view_result(request).unwrap();
    assert_eq!(
        view.conversation.as_ref().unwrap().waiting,
        [bob],
        "it waits for Bob's answer, built before it came"
    );
    assert!(
        wait(&w, |e| *e
            == Event::MessageReady {
                folder: bob.folder,
                uid: bob.uid
            }),
        "and Bob's answer is told again, so the window builds the conversation again"
    );
}
