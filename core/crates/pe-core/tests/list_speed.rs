//! How long the message list's calls take on a large store: three accounts and 229,000 messages, built here, each
//! call timed against a budget with room for a slower machine. CI runs it in a job of its own, built for release:
//!
//! ```text
//! cargo test --release -p pe-core --test list_speed -- --ignored --nocapture
//! ```
//!
//! `PE_SPEED_STORE=<path>` keeps the store built at that path and uses it again on the next run (the build takes
//! most of the time).

use std::sync::mpsc::{Receiver, channel};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use pe_core::{Core, Event, ListView, Options, PasswordStore, Scope, Show};
use pe_store::{AccountSettings, FolderId, FolderInfo, MessageInfo, Sort, SortField, Store};
use pe_testkit::Rng;

const WORDS: &[&str] = &[
    "report",
    "invoice",
    "meeting",
    "project",
    "update",
    "weekly",
    "quarterly",
    "budget",
    "review",
    "plan",
    "design",
    "release",
    "notes",
    "agenda",
    "proposal",
    "contract",
    "order",
    "shipping",
    "delivery",
    "account",
    "security",
    "alert",
    "newsletter",
    "offer",
    "summer",
    "team",
    "lunch",
    "travel",
    "booking",
    "confirmation",
    "receipt",
    "payment",
    "reminder",
    "draft",
    "feedback",
    "question",
    "issue",
    "support",
    "ticket",
    "status",
    "launch",
];
const FIRST: &[&str] = &[
    "Anna", "Bob", "Carla", "Dmitri", "Eve", "Frank", "Grace", "Hiro", "Ines", "Jaan", "Kaisa", "Liam", "Mari", "Nils",
    "Olga", "Peeter", "Quinn", "Rita", "Sven", "Tiina", "Uku", "Vera", "Walt", "Xenia", "Yuri", "Zoe",
];
const LAST: &[&str] = &[
    "Tamm", "Saar", "Smith", "Jones", "Kask", "Mets", "Lepik", "Brown", "Garcia", "Muller", "Rossi", "Nakamura",
    "Ivanov", "Novak", "Kowalski", "Silva", "Dubois", "Berg", "Lind", "Holm",
];

/// The messages of each account's Inbox, Sent Items and Archive
const SIZES: [(u64, u64, u64); 3] = [
    (30_000, 3_000, 10_000),
    (60_000, 6_000, 10_000),
    (100_000, 10_000, 10_000),
];

/// The mail of a folder of account `account`: `n` messages over five years, a third of them replies (conversations),
/// the newest few hundred mostly unread, 2% flagged
struct Mail<'a> {
    r: &'a mut Rng,
    account: usize,
    path: &'static str,
    n: u64,
    uid: u64,
    /// (Message-ID, subject, References) of the recent messages, which replies answer
    recent: Vec<(String, String, Vec<String>)>,
}

impl Iterator for Mail<'_> {
    type Item = MessageInfo;

    fn next(&mut self) -> Option<MessageInfo> {
        const NOW: i64 = 1_794_000_000;
        const SPAN: i64 = 5 * 365 * 86_400;
        if self.uid == self.n {
            return None;
        }
        self.uid += 1;
        let (r, uid, n, a) = (&mut *self.r, self.uid, self.n, self.account);
        let internal = NOW - SPAN + (SPAN as u64 * uid / n) as i64 + r.below(600) as i64;
        let message_id = format!("<{a}.{}.{uid}.{}@mail.example>", self.path, r.below(1 << 40));
        let (subject, references) = if !self.recent.is_empty() && r.chance(35) {
            let (parent, subject, before) = r.pick(&self.recent);
            let mut references = before.clone();
            references.push(parent.clone());
            if references.len() > 20 {
                references.remove(0);
            }
            (format!("Re: {}", subject.trim_start_matches("Re: ")), references)
        } else {
            let words: Vec<&str> = (0..2 + r.below(5)).map(|_| *r.pick(WORDS)).collect();
            (format!("{} #{}", words.join(" "), r.below(10_000)), Vec::new())
        };
        let (first, last) = (*r.pick(FIRST), *r.pick(LAST));
        let seen = if n - uid < 300 { r.chance(40) } else { r.chance(97) };
        let mut flags = Vec::new();
        if seen {
            flags.push("\\Seen".to_string());
        }
        if r.chance(2) {
            flags.push("\\Flagged".to_string());
        }
        if r.chance(10) {
            flags.push("\\Answered".to_string());
        }
        let message = MessageInfo {
            uid,
            modseq: Some(uid),
            flags,
            internal_date: Some(internal),
            date: Some(internal - r.below(900) as i64),
            size: Some(2_000 + r.below(200_000)),
            subject: subject.clone(),
            from_name: format!("{first} {last}"),
            from_address: format!(
                "{}.{}{}@corp{}.example",
                first.to_lowercase(),
                last.to_lowercase(),
                r.below(50),
                r.below(200)
            ),
            recipients: format!("User {a}"),
            message_id: Some(message_id.clone()),
            in_reply_to: references.last().cloned(),
            has_attachments: r.chance(15),
            references: references.clone(),
            // about one in a hundred encrypted and one in forty signed (OpenPGP), without changing the rest
            protection: match uid {
                _ if uid % 97 == 0 => pe_store::Protection::Encrypted,
                _ if uid % 41 == 0 => pe_store::Protection::Signed,
                _ => pe_store::Protection::None,
            },
            ..Default::default()
        };
        self.recent.push((message_id, subject, references));
        if self.recent.len() > 400 {
            self.recent.remove(0);
        }
        Some(message)
    }
}

/// Fills `store` with the synthetic accounts ([`Mail`]), 5,000 messages a transaction as a sync writes them
fn build(store: &mut Store) {
    let mut r = Rng::new(0x9e37_79b9_7f4a_7c15);
    for (a, &(inbox, sent, archive)) in SIZES.iter().enumerate() {
        let account = store
            .add_account(&AccountSettings {
                email: format!("user{a}@example.com"),
                name: format!("User {a}"),
                ..Default::default()
            })
            .unwrap();
        let folder = |path: &str, special: Option<&str>| FolderInfo {
            path: path.into(),
            name: path.into(),
            delimiter: Some("/".into()),
            special_use: special.map(str::to_string),
            selectable: true,
            subscribed: true,
            ..Default::default()
        };
        store
            .set_folders(
                account,
                &[
                    folder("INBOX", None),
                    folder("Sent", Some("\\Sent")),
                    folder("Archive", Some("\\Archive")),
                    folder("Drafts", Some("\\Drafts")),
                    folder("Trash", Some("\\Trash")),
                ],
            )
            .unwrap();
        let folders = store.folders(account).unwrap();
        for (path, n) in [("INBOX", inbox), ("Sent", sent), ("Archive", archive)] {
            let id = folders.iter().find(|f| f.info.path == path).unwrap().id;
            let mail = Mail {
                r: &mut r,
                account: a,
                path,
                n,
                uid: 0,
                recent: Vec::new(),
            };
            let all: Vec<MessageInfo> = mail.collect();
            for batch in all.chunks(5000) {
                store.transaction(|store| store.add_messages(id, batch)).unwrap();
            }
        }
    }
}

/// The store to time: the one kept at `PE_SPEED_STORE`, built there when it is not yet, or one built in a temporary
/// folder
fn store_path(dir: &pe_testkit::TempDir) -> std::path::PathBuf {
    let kept = std::env::var_os("PE_SPEED_STORE").map(std::path::PathBuf::from);
    let path = kept.clone().unwrap_or_else(|| dir.path().join("store.db"));
    if kept.is_some() && path.exists() {
        return path;
    }
    let started = Instant::now();
    let mut store = Store::open(&path).unwrap();
    build(&mut store);
    eprintln!("built {} in {:.1?}", path.display(), started.elapsed());
    path
}

fn open(path: &std::path::Path) -> (Arc<Core>, Receiver<Event>) {
    let (sender, events) = channel();
    let sender = Mutex::new(sender);
    let options = Options {
        passwords: PasswordStore::Memory,
        ..Default::default()
    };
    let core = Core::open_with(path, options, move |event| {
        let _ = sender.lock().unwrap().send(event);
    })
    .unwrap();
    (Arc::new(core), events)
}

/// The time each call took and its budget, all reported before the test fails on one over it
#[derive(Default)]
struct Report {
    rows: Vec<(String, Duration, Duration)>,
}

impl Report {
    /// The median of five runs of `f` after a first one (SQLite's cache warm), against `budget` milliseconds
    fn time<T>(&mut self, what: &str, budget: u64, mut f: impl FnMut() -> T) {
        f();
        let mut runs: Vec<Duration> = (0..5)
            .map(|_| {
                let started = Instant::now();
                std::hint::black_box(f());
                started.elapsed()
            })
            .collect();
        runs.sort();
        self.rows
            .push((what.to_string(), runs[2], Duration::from_millis(budget)));
    }

    fn check(&self) {
        let mut over = Vec::new();
        for (what, took, budget) in &self.rows {
            let mark = if took > budget { "  OVER" } else { "" };
            println!(
                "{what:<58} {:>9.2} ms  (budget {:>4} ms){mark}",
                took.as_secs_f64() * 1000.0,
                budget.as_millis()
            );
            if took > budget {
                over.push(what.as_str());
            }
        }
        assert!(over.is_empty(), "over budget: {over:?}");
    }
}

/// The budgets, in milliseconds, several times what this takes on a laptop of 2025 so that a CI machine passes: what
/// reads only a few rows of an index, or what the store keeps
const QUICK: u64 = 25;
/// A page far from any page read before, whose rows above it are skipped on the order's index
const PAGE: u64 = 40;
/// Select All's numbers, from every conversation of the list
const SUMMARY: u64 = 60;
/// A list with conversations open, which counts each conversation's rows
const OPEN: u64 = 150;
/// A search, which reads every message its words find
const SEARCH: u64 = 300;

/// The calls a list's window makes, timed: its load, pages far down and next to one read, its counts, a message's
/// place and neighbours, Next Unread, Select All. `budgets`: for the quick calls, a page far from the others, Select
/// All's numbers.
fn time_list(
    report: &mut Report,
    core: &Arc<Core>,
    events: &Receiver<Event>,
    name: &str,
    list: &ListView,
    (quick, far, summary): (u64, u64, u64),
) {
    report.time(&format!("{name}: load (counts, rows, first page)"), quick, || {
        load(core, events, list).rows
    });
    let rows = list.row_count(core).unwrap();
    report.time(&format!("{name}: a page in the middle"), far, || {
        page(core, events, list, rows / 2)
    });
    // scrolled on from it: read from its last row
    report.time(&format!("{name}: the page below it"), quick, || {
        page(core, events, list, rows / 2 + pe_core::LIST_PAGE)
    });
    // read from the end
    report.time(&format!("{name}: the last page"), quick, || {
        page(core, events, list, rows.saturating_sub(pe_core::LIST_PAGE))
    });
    report.time(&format!("{name}: counts"), quick, || list.clone().counts(core).unwrap());
    let middle = list.rows(core, rows / 2, 1).unwrap().remove(0).at();
    report.time(&format!("{name}: a message's place"), quick, || {
        list.index_of(core, middle.folder, middle.uid).unwrap()
    });
    report.time(&format!("{name}: previous and next"), quick, || {
        list.neighbours(core, middle.folder, middle.uid).unwrap()
    });
    report.time(&format!("{name}: next unread"), quick, || {
        list.next_unread_step(core, middle.folder, middle.uid).is_ok()
    });
    report.time(&format!("{name}: Select All (count and summary)"), summary, || {
        let all = list.clone().select_all(core).unwrap();
        core.summary_of(&all).unwrap().count
    });
}

/// The list of `list` loaded as a window loads it: counts, rows and the first page
fn load(core: &Arc<Core>, events: &Receiver<Event>, list: &ListView) -> pe_core::ListLoad {
    let request = core.list_load(list, Default::default()).unwrap();
    wait(events, request);
    core.list_load_result(request).unwrap().unwrap()
}

/// A page of `list` from `offset` loaded as a window loads it; how many rows it has
fn page(core: &Arc<Core>, events: &Receiver<Event>, list: &ListView, offset: u64) -> usize {
    let request = core.list_load_page(list, offset).unwrap();
    wait(events, request);
    core.list_load_result(request).unwrap().unwrap().messages.len()
}

/// The list event of `request`, the others skipped
fn wait(events: &Receiver<Event>, request: u64) {
    loop {
        match events.recv_timeout(Duration::from_secs(60)).unwrap() {
            Event::ListReady { request: r } | Event::ListPageReady { request: r } if r == request => return,
            _ => {}
        }
    }
}

fn view(scope: Scope, text: &str, grouped: bool, sort: Sort) -> ListView {
    let mut view = ListView::new();
    view.set_scope(Some(scope));
    view.set_text(text);
    view.set_grouped(grouped);
    view.set_sort(sort);
    view
}

#[test]
#[ignore = "builds a store of 229,000 messages: run with --release --ignored"]
fn list_calls_within_budget() {
    pe_core::i18n::set_language("en");
    let dir = pe_testkit::TempDir::new("list-speed");
    let path = store_path(&dir);
    let started = Instant::now();
    let (core, events) = open(&path);
    // a store kept from an older version is brought up to date here
    eprintln!("opened in {:.1?}", started.elapsed());
    let accounts = core.accounts().unwrap();
    let folder = |account: usize, path: &str| -> FolderId {
        core.folders(accounts[account].id)
            .unwrap()
            .into_iter()
            .find(|f| f.info.path == path)
            .unwrap()
            .id
    };
    let big_inbox = folder(2, "INBOX");
    let newest = Sort {
        field: SortField::Date,
        ascending: false,
    };
    let by_sender = Sort {
        field: SortField::From,
        ascending: true,
    };
    let mut report = Report::default();

    report.time("folder list (folder_tree)", QUICK, || core.folder_tree().unwrap().len());
    report.time("All Inboxes unread (tray)", QUICK, || core.inbox_unread().unwrap());

    let lists = [
        ("All Inboxes", Scope::AllInboxes, "", false, newest),
        ("All Inboxes grouped", Scope::AllInboxes, "", true, newest),
        ("All Inboxes by sender", Scope::AllInboxes, "", false, by_sender),
        ("All Inboxes grouped by sender", Scope::AllInboxes, "", true, by_sender),
        ("Inbox 100k", Scope::Folder(big_inbox), "", false, newest),
        ("Inbox 100k grouped", Scope::Folder(big_inbox), "", true, newest),
        ("Flagged", Scope::Flagged, "", false, newest),
        ("search 'report'", Scope::AllInboxes, "report", false, newest),
        ("search 'report' grouped", Scope::AllInboxes, "report", true, newest),
        // a mark rather than words: few messages have it, read from the order's index
        (
            "search 'is:encrypted'",
            Scope::AllInboxes,
            "is:encrypted",
            false,
            newest,
        ),
        (
            "search 'is:encrypted' grouped",
            Scope::AllInboxes,
            "is:encrypted",
            true,
            newest,
        ),
    ];
    for (name, scope, text, grouped, sort) in lists {
        let list = view(scope, text, grouped, sort);
        // a search reads what its words find, Flagged the flagged messages of every folder
        let (quick, page, summary) = match (text.is_empty(), scope) {
            (false, _) => (SEARCH, SEARCH, SEARCH),
            (true, Scope::Flagged) => (PAGE, PAGE, SUMMARY),
            (true, _) => (QUICK, PAGE, SUMMARY),
        };
        time_list(&mut report, &core, &events, name, &list, (quick, page, summary));
    }

    // every conversation of the big Inbox open (View > Expand All)
    let mut open = view(Scope::Folder(big_inbox), "", true, newest);
    open.expand_all(&core).unwrap();
    let name = format!("Inbox 100k, {} conversations open", open.expanded().count());
    report.time(&format!("{name}: load"), OPEN, || load(&core, &events, &open).rows);
    let rows = open.row_count(&core).unwrap();
    report.time(&format!("{name}: middle page"), OPEN, || {
        page(&core, &events, &open, rows / 2)
    });
    let middle = open.rows(&core, rows / 2, 1).unwrap().remove(0).at();
    report.time(&format!("{name}: a message's place"), OPEN, || {
        open.index_of(&core, middle.folder, middle.uid).unwrap()
    });

    // View > Hide Read Messages
    let mut unread = view(Scope::AllInboxes, "", false, newest);
    unread.set_show(Show::Unread);
    report.time("All Inboxes, unread only: load", QUICK, || {
        load(&core, &events, &unread).rows
    });
    report.check();
}
