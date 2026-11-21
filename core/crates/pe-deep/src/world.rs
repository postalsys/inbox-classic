//! The world of the deep test: accounts, their folder trees and their mail, made from a seed. The same seed and
//! profile give the same world on every machine, byte for byte ([`World::digest`]). Each account becomes the storage
//! of an ImapKit of its own (ImapKit has one mailbox tree, shared by its users), written once to a file and loaded by
//! the server in seconds, so no run spends its time adding mail.

use std::fmt::Write as _;
use std::path::{Path, PathBuf};

use pe_testkit::Rng;
use serde_json::{Map, Value, json};

/// The size of a run
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Profile {
    /// A few thousand messages, every page limit still crossed: minutes, for the weekly run and a quick look
    Small,
    /// About 34,000 messages in five accounts (docs/deep-test-plan.md)
    Standard,
    /// About 150,000, for a night
    Overnight,
}

impl Profile {
    pub fn parse(name: &str) -> Option<Profile> {
        Some(match name {
            "small" => Profile::Small,
            "standard" => Profile::Standard,
            "overnight" => Profile::Overnight,
            _ => return None,
        })
    }

    pub fn name(self) -> &'static str {
        match self {
            Profile::Small => "small",
            Profile::Standard => "standard",
            Profile::Overnight => "overnight",
        }
    }

    /// How many times the standard's messages
    fn scale(self) -> f64 {
        match self {
            Profile::Small => 0.1,
            Profile::Standard => 1.0,
            Profile::Overnight => 4.5,
        }
    }

    /// The steps of the walk
    pub fn steps(self) -> u64 {
        match self {
            // a step of an app is about two seconds with its checks and the sync after it: the standard run's walk
            // takes about half an hour
            Profile::Small => 300,
            Profile::Standard => 800,
            Profile::Overnight => 12000,
        }
    }
}

/// What kind of account, and so of folders and mail
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Kind {
    /// A big Inbox, folders of projects and clients, long conversations
    Work,
    /// Hundreds of folders nested deep, names in other scripts
    Home,
    /// Gmail's folders: All Mail, labels
    Gmail,
    /// Newsletters, bounces, invitations, encrypted mail, huge messages
    Lists,
    /// A small account whose server misbehaves during the walk (faults.rs)
    Broken,
}

/// An account of the world
#[derive(Debug, Clone)]
pub struct Account {
    /// What the folder tree calls it, and the conductor names it by
    pub name: String,
    pub email: String,
    pub kind: Kind,
    pub folders: Vec<Folder>,
}

/// A folder and its mail
#[derive(Debug, Clone)]
pub struct Folder {
    /// The path as the user sees it, `/` between levels
    pub path: String,
    pub special_use: Option<&'static str>,
    pub mails: Vec<Mail>,
}

/// A message as the server holds it
#[derive(Debug, Clone)]
pub struct Mail {
    pub message_id: String,
    pub subject: String,
    /// Seconds since the epoch, the Date header
    pub date: i64,
    pub flags: Vec<&'static str>,
    pub raw: String,
}

/// The accounts made from a seed
#[derive(Debug, Clone)]
pub struct World {
    pub seed: u64,
    pub profile: Profile,
    pub accounts: Vec<Account>,
    /// The corpus its mail came from (`Corpus::name`), None for made mail
    pub corpus: Option<String>,
}

/// When the world's newest mail came: its dates go back three years from here (2026-11-01 00:00 UTC)
pub const NOW: i64 = 1_793_491_200;
const YEARS: i64 = 3 * 365 * 86_400;

/// The world's generator: a change of how mail is made is a new version, so a snapshot of an older one is not used
pub const GENERATOR: u32 = 1;

const FIRST: &[&str] = &[
    "Alex", "Maria", "Jonas", "Aiko", "Priya", "Liam", "Sofia", "Mateo", "Ingrid", "Kwame", "Elif", "Noah", "Zofia",
    "Rahul", "Chloé", "Dmitri", "Hana", "Lucas", "Amara", "Björn",
];
const LAST: &[&str] = &[
    "Morgan", "Tamm", "Kask", "Sato", "Iyer", "Walsh", "Rossi", "García", "Berg", "Mensah", "Yılmaz", "Fischer",
    "Nowak", "Gupta", "Martin", "Volkov", "Kim", "Silva", "Okafor", "Lund",
];
const WORDS: &[&str] = &[
    "budget",
    "review",
    "quarterly",
    "numbers",
    "meeting",
    "invoice",
    "contract",
    "launch",
    "draft",
    "plan",
    "travel",
    "design",
    "release",
    "notes",
    "summary",
    "proposal",
    "schedule",
    "feedback",
    "update",
    "report",
    "agenda",
    "workshop",
    "hiring",
    "roadmap",
    "server",
    "migration",
    "lunch",
    "photos",
    "tickets",
    "renewal",
];
const SCRIPTS: &[&str] = &[
    "Ελληνικά νέα",
    "Новости недели",
    "日本語のお知らせ",
    "חדשות השבוע",
    "中文通知",
    "Ünïcödé übersicht",
    "Tiếng Việt",
    "हिन्दी समाचार",
    "Türkçe özet",
    "ქართული",
    // words without spaces between them: the search finds a word inside (會議 and 会议 are other characters)
    "会议纪要",
    "見積書のご確認",
    "주간회의록",
    "請求書送付のお知らせ",
    "關於發票的問題",
];

/// A sentence in Chinese, Japanese or Korean that some texts end with, none of the words of [`SCRIPTS`]' subjects
const CJK_TEXT: &[&str] = &[
    "请查看附件中的预算报告。",
    "お世話になっております。資料を添付いたします。",
    "내일 일정을 공유드립니다.",
];

/// Real messages to fill the world with in place of made ones, for runs on this computer only: a folder of `.eml`
/// files (a mailbox export). The world made from them stays under build/, which is never committed, and CI never
/// names one, so none of it leaves the computer.
pub struct Corpus {
    files: Vec<PathBuf>,
    /// The name it gives the world's folder
    pub name: String,
}

/// A message of a corpus larger than this is passed over: the world is kept in ImapKit's memory
const CORPUS_LARGEST: u64 = 256 * 1024;

impl Corpus {
    /// The `.eml` files of `dir`, in the order of their names (so a seed picks the same ones)
    pub fn open(dir: &Path) -> std::io::Result<Corpus> {
        let mut files: Vec<PathBuf> = std::fs::read_dir(dir)?
            .filter_map(|entry| entry.ok().map(|e| e.path()))
            .filter(|path| path.extension().is_some_and(|e| e.eq_ignore_ascii_case("eml")))
            .collect();
        files.sort();
        if files.is_empty() {
            return Err(std::io::Error::other(format!("no .eml files in {}", dir.display())));
        }
        let name = dir
            .file_name()
            .map_or_else(|| "corpus".into(), |n| n.to_string_lossy().into_owned());
        Ok(Corpus { files, name })
    }

    /// A message drawn with `rng`: its source, subject, date and Message-ID
    fn draw(&self, rng: &mut Rng) -> Option<(String, String, Option<i64>, Option<String>)> {
        for _ in 0..20 {
            let path = &self.files[rng.below(self.files.len() as u64) as usize];
            if std::fs::metadata(path).map_or(true, |m| m.len() > CORPUS_LARGEST) {
                continue;
            }
            let Ok(bytes) = std::fs::read(path) else { continue };
            let Ok(parsed) = pe_mime::parser::parse(&bytes) else {
                continue;
            };
            let raw = String::from_utf8_lossy(&bytes).into_owned();
            return Some((
                raw,
                parsed.subject.unwrap_or_default(),
                parsed.timestamp,
                parsed.message_id,
            ));
        }
        None
    }
}

thread_local! {
    /// The corpus the world being made takes its mail from
    static CORPUS: std::cell::RefCell<Option<std::rc::Rc<Corpus>>> = const { std::cell::RefCell::new(None) };
}

impl World {
    /// The world of `seed` at `profile`, its ordinary mail drawn from `corpus` when one is given (the special kinds
    /// of Lists are always made, the journeys look for them)
    pub fn generate_from(seed: u64, profile: Profile, corpus: Option<Corpus>) -> World {
        let name = corpus.as_ref().map(|c| c.name.clone());
        CORPUS.with(|c| *c.borrow_mut() = corpus.map(std::rc::Rc::new));
        let mut world = World::generate(seed, profile);
        CORPUS.with(|c| *c.borrow_mut() = None);
        world.corpus = name;
        world
    }

    /// The world of `seed` at `profile`
    pub fn generate(seed: u64, profile: Profile) -> World {
        let scale = profile.scale();
        let count = |n: f64| ((n * scale).round() as usize).max(1);
        let mut rng = Rng::new(seed);
        let accounts = vec![
            work(&mut rng, count(20_000.0)),
            home(&mut rng, count(6_000.0)),
            gmail(&mut rng, count(5_000.0)),
            lists(&mut rng, count(3_000.0), profile),
            broken(&mut rng, count(200.0)),
        ];
        World {
            seed,
            profile,
            accounts,
            corpus: None,
        }
    }

    /// Every message of the world
    pub fn total(&self) -> usize {
        self.accounts
            .iter()
            .flat_map(|a| &a.folders)
            .map(|f| f.mails.len())
            .sum()
    }

    /// A short fingerprint of everything in the world (FNV-1a of the storages): the same on every machine
    pub fn digest(&self) -> String {
        let mut hash: u64 = 0xcbf2_9ce4_8422_2325;
        for account in &self.accounts {
            for byte in account.storage().to_string().bytes() {
                hash ^= u64::from(byte);
                hash = hash.wrapping_mul(0x100_0000_01b3);
            }
        }
        format!("{hash:016x}")
    }

    /// Where the storages of this world are kept: by seed, profile and generator, so a run loads one made before
    pub fn dir(&self, base: &Path) -> PathBuf {
        let corpus = self.corpus.as_ref().map(|c| format!("-{c}")).unwrap_or_default();
        base.join(format!(
            "world-{}-{}-v{GENERATOR}{corpus}",
            self.profile.name(),
            self.seed
        ))
    }

    /// The storage of each account written to `dir` (`<n>.json`) unless it is there already; their paths, in the
    /// accounts' order
    pub fn write(&self, dir: &Path) -> std::io::Result<Vec<PathBuf>> {
        std::fs::create_dir_all(dir)?;
        let mut paths = Vec::new();
        for (index, account) in self.accounts.iter().enumerate() {
            let path = dir.join(format!("{index}.json"));
            if !path.exists() {
                let partial = dir.join(format!("{index}.json.part"));
                std::fs::write(&partial, account.storage().to_string())?;
                std::fs::rename(&partial, &path)?;
            }
            // absolute: the harness reads them from its own folder
            paths.push(std::fs::canonicalize(&path)?);
        }
        Ok(paths)
    }
}

impl Folder {
    /// The newest message by date with its UID (the server numbers the storage's messages from 1 in order)
    pub fn newest(&self) -> Option<(u64, &Mail)> {
        self.mails
            .iter()
            .enumerate()
            .max_by_key(|(_, m)| m.date)
            .map(|(i, m)| (i as u64 + 1, m))
    }
}

impl Account {
    /// ImapKit's `storage` for this account: INBOX of its own, the other folders under the personal namespace, nested,
    /// their names in modified UTF-7
    pub fn storage(&self) -> Value {
        let mut root = Map::new();
        let mut inbox = json!({});
        for folder in &self.folders {
            let messages: Vec<Value> = folder
                .mails
                .iter()
                .map(|m| json!({ "raw": m.raw, "flags": m.flags, "internaldate": internal_date(m.date) }))
                .collect();
            if folder.path == "INBOX" {
                inbox = json!({ "messages": messages });
                continue;
            }
            let mut at = &mut root;
            let parts: Vec<&str> = folder.path.split('/').collect();
            for (depth, part) in parts.iter().enumerate() {
                let name = pe_imap::utf7::encode(part);
                let entry = at.entry(name).or_insert_with(|| json!({}));
                let object = entry.as_object_mut().expect("a mailbox is an object");
                if depth + 1 == parts.len() {
                    object.insert("messages".into(), Value::Array(messages.clone()));
                    if let Some(special) = folder.special_use {
                        object.insert("special-use".into(), json!(special));
                    }
                    object.insert("subscribed".into(), json!(true));
                }
                at = object
                    .entry("folders")
                    .or_insert_with(|| json!({}))
                    .as_object_mut()
                    .expect("folders are an object");
            }
        }
        json!({ "INBOX": inbox, "": { "separator": "/", "folders": Value::Object(root) } })
    }

    pub fn folder(&self, path: &str) -> Option<&Folder> {
        self.folders.iter().find(|f| f.path == path)
    }
}

/// The special folders every account has
fn specials() -> Vec<Folder> {
    [
        ("Sent", Some("\\Sent")),
        ("Drafts", Some("\\Drafts")),
        ("Archive", Some("\\Archive")),
        ("Junk", Some("\\Junk")),
        ("Trash", Some("\\Trash")),
    ]
    .into_iter()
    .map(|(path, special_use)| Folder {
        path: path.into(),
        special_use,
        mails: Vec::new(),
    })
    .collect()
}

/// Mail of an account, made in order from the oldest to the newest
struct Maker<'a> {
    rng: &'a mut Rng,
    account: &'a str,
    email: &'a str,
    made: usize,
    /// The conversation under way: its first Message-ID, its subject, and how many replies are left in it
    thread: Option<(String, String, u32)>,
}

impl Maker<'_> {
    /// A message dated `date`, in a conversation now and then
    fn mail(&mut self, date: i64, unread_chance: u64) -> Mail {
        if let Some(corpus) = CORPUS.with(|c| c.borrow().clone())
            && let Some((raw, subject, sent, message_id)) = corpus.draw(self.rng)
        {
            self.made += 1;
            let mut flags = Vec::new();
            if !self.rng.chance(unread_chance) {
                flags.push("\\Seen");
            }
            if self.rng.chance(2) {
                flags.push("\\Flagged");
            }
            return Mail {
                message_id: message_id
                    .unwrap_or_else(|| format!("<{}-{}@deep.inboxclassic.test>", self.account, self.made)),
                subject,
                // a message dated after the world's newest keeps the place of the one it stands in for
                date: sent.filter(|s| *s <= NOW).unwrap_or(date),
                flags,
                raw,
            };
        }
        self.made += 1;
        let message_id = format!("<{}-{}@deep.inboxclassic.test>", self.account, self.made);
        let (subject, references) = match self.thread.take() {
            Some((first, subject, left)) if left > 0 => {
                self.thread = Some((first.clone(), subject.clone(), left - 1));
                (format!("Re: {subject}"), Some(first))
            }
            _ => {
                let subject = self.subject();
                // one in six starts a conversation, now and then a long one
                if self.rng.chance(16) {
                    let length = if self.rng.chance(3) {
                        40 + self.rng.below(260)
                    } else {
                        1 + self.rng.below(8)
                    };
                    self.thread = Some((message_id.clone(), subject.clone(), length as u32));
                }
                (subject, None)
            }
        };
        let mut flags = Vec::new();
        if !self.rng.chance(unread_chance) {
            flags.push("\\Seen");
        }
        if self.rng.chance(2) {
            flags.push("\\Flagged");
        }
        if self.rng.chance(8) {
            flags.push("\\Answered");
        }
        let from = format!("{} {}", self.rng.pick(FIRST), self.rng.pick(LAST));
        let address = format!(
            "{}.{}@example.com",
            from.split(' ').next().unwrap_or("x"),
            self.made % 97
        )
        .to_lowercase();
        let mut headers = format!(
            "From: {from} <{address}>\r\nTo: {account} <{email}>\r\nSubject: {subject}\r\nDate: {date}\r\nMessage-ID: {message_id}\r\nMIME-Version: 1.0\r\n",
            account = self.account,
            email = self.email,
            date = rfc2822(date),
        );
        if let Some(first) = &references {
            let _ = write!(headers, "In-Reply-To: {first}\r\nReferences: {first}\r\n");
        }
        let text = self.text();
        let raw = if self.rng.chance(8) {
            let boundary = format!("b{}", self.made);
            format!(
                "{headers}Content-Type: multipart/mixed; boundary=\"{boundary}\"\r\n\r\n--{boundary}\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Transfer-Encoding: 8bit\r\n\r\n{text}\r\n--{boundary}\r\nContent-Type: text/plain; name=\"notes-{n}.txt\"\r\nContent-Disposition: attachment; filename=\"notes-{n}.txt\"\r\n\r\n{text}\r\n--{boundary}--\r\n",
                n = self.made
            )
        } else if self.rng.chance(25) {
            let boundary = format!("a{}", self.made);
            format!(
                "{headers}Content-Type: multipart/alternative; boundary=\"{boundary}\"\r\n\r\n--{boundary}\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Transfer-Encoding: 8bit\r\n\r\n{text}\r\n--{boundary}\r\nContent-Type: text/html; charset=utf-8\r\nContent-Transfer-Encoding: 8bit\r\n\r\n<p>{text}</p>\r\n--{boundary}--\r\n"
            )
        } else {
            format!(
                "{headers}Content-Type: text/plain; charset=utf-8\r\nContent-Transfer-Encoding: 8bit\r\n\r\n{text}\r\n"
            )
        };
        Mail {
            message_id,
            subject,
            date,
            flags,
            raw,
        }
    }

    fn subject(&mut self) -> String {
        if self.rng.chance(5) {
            return format!("{} {}", self.rng.pick(SCRIPTS), self.made);
        }
        let words: Vec<&str> = (0..2 + self.rng.below(4)).map(|_| *self.rng.pick(WORDS)).collect();
        let mut subject = words.join(" ");
        if let Some(first) = subject.get(..1) {
            subject.replace_range(..1, &first.to_uppercase());
        }
        format!("{subject} #{}", self.made)
    }

    fn text(&mut self) -> String {
        let words: Vec<&str> = (0..12 + self.rng.below(60)).map(|_| *self.rng.pick(WORDS)).collect();
        let text = words.join(" ");
        if self.rng.chance(5) {
            return format!("{text}\r\n{}", self.rng.pick(CJK_TEXT));
        }
        text
    }
}

/// `count` dates from three years back to [`NOW`], oldest first, a little out of order now and then (mail that came
/// late)
fn dates(rng: &mut Rng, count: usize) -> Vec<i64> {
    let step = YEARS / count.max(1) as i64;
    (0..count as i64)
        .map(|i| {
            let jitter = rng.below(step.max(2) as u64 * 3) as i64 - step;
            NOW - YEARS + i * step + jitter
        })
        .collect()
}

/// `count` messages made by `maker` into the folders `share` says: (folder index, share of the messages)
fn fill(folders: &mut [Folder], maker: &mut Maker<'_>, count: usize, share: &[(usize, f64)], unread: u64) {
    let total: f64 = share.iter().map(|(_, part)| part).sum();
    let (mut placed, mut so_far) = (0, 0.0);
    for (n, (index, part)) in share.iter().enumerate() {
        // by the running share, so the rounding of many small parts adds up to `count`
        so_far += part;
        let end = if n + 1 == share.len() {
            count
        } else {
            ((count as f64) * so_far / total).round() as usize
        };
        let here = end.saturating_sub(placed).min(count - placed);
        placed += here;
        let dates = dates(maker.rng, here);
        // the newest mail of the Inbox is unread more often
        for (i, date) in dates.into_iter().enumerate() {
            let fresh = i + 50 >= here;
            let mail = maker.mail(date, if fresh { 60 } else { unread });
            folders[*index].mails.push(mail);
        }
    }
}

fn work(rng: &mut Rng, count: usize) -> Account {
    let (name, email) = ("Work", "work@deep.inboxclassic.test");
    let mut folders = vec![Folder {
        path: "INBOX".into(),
        special_use: None,
        mails: Vec::new(),
    }];
    folders.extend(specials());
    for group in ["Projects", "Clients", "Teams"] {
        for n in 1..=18 {
            folders.push(Folder {
                path: format!("{group}/{group} {n:02}"),
                special_use: None,
                mails: Vec::new(),
            });
        }
    }
    // folders whose sizes sit on the list's page edges: exactly a page, the pages kept, one more
    for size in [100, 800, 801] {
        folders.push(Folder {
            path: format!("Edges/Exactly {size}"),
            special_use: None,
            mails: Vec::new(),
        });
    }
    folders.push(Folder {
        path: "Edges/Empty".into(),
        special_use: None,
        mails: Vec::new(),
    });
    let mut maker = Maker {
        rng,
        account: name,
        email,
        made: 0,
        thread: None,
    };
    let edges: usize = if count >= 2000 { 1701 } else { 0 };
    let rest = count.saturating_sub(edges);
    let mut share = vec![(0, 0.9), (1, 0.02), (3, 0.03)];
    let per = 0.05 / 54.0;
    share.extend((6..60).map(|i| (i, per)));
    fill(&mut folders, &mut maker, rest, &share, 8);
    if edges > 0 {
        for (index, size) in [(60, 100), (61, 800), (62, 801)] {
            fill(&mut folders, &mut maker, size, &[(index, 1.0)], 10);
        }
    }
    account(name, email, Kind::Work, folders)
}

fn home(rng: &mut Rng, count: usize) -> Account {
    let (name, email) = ("Home", "home@deep.inboxclassic.test");
    let mut folders = vec![Folder {
        path: "INBOX".into(),
        special_use: None,
        mails: Vec::new(),
    }];
    folders.extend(specials());
    // 400 folders: eight at the top, two children each, down to six levels
    let tops = [
        "Family",
        "Travel",
        "House",
        "Money",
        "Hobbies",
        "Ελληνικά",
        "Русский",
        "日本語",
    ];
    let mut paths: Vec<String> = tops.iter().map(|t| t.to_string()).collect();
    let mut next = 0;
    while paths.len() < 400 {
        let parent = paths[next].clone();
        next += 1;
        if parent.matches('/').count() >= 5 {
            continue;
        }
        for n in 1..=2 {
            if paths.len() < 400 {
                paths.push(format!("{parent}/{} {n}", rng.pick(WORDS)));
            }
        }
    }
    folders.extend(paths.into_iter().map(|path| Folder {
        path,
        special_use: None,
        mails: Vec::new(),
    }));
    let mut maker = Maker {
        rng,
        account: name,
        email,
        made: 0,
        thread: None,
    };
    let mut share = vec![(0, 0.5), (1, 0.05)];
    let per = 0.45 / 400.0;
    share.extend((6..406).map(|i| (i, per)));
    fill(&mut folders, &mut maker, count, &share, 5);
    account(name, email, Kind::Home, folders)
}

fn gmail(rng: &mut Rng, count: usize) -> Account {
    let (name, email) = ("Gmail-like", "gmail@deep.inboxclassic.test");
    let mut folders = vec![Folder {
        path: "INBOX".into(),
        special_use: None,
        mails: Vec::new(),
    }];
    for (path, special_use) in [
        ("[Gmail]/All Mail", Some("\\All")),
        ("[Gmail]/Sent Mail", Some("\\Sent")),
        ("[Gmail]/Drafts", Some("\\Drafts")),
        ("[Gmail]/Spam", Some("\\Junk")),
        ("[Gmail]/Trash", Some("\\Trash")),
        ("[Gmail]/Starred", Some("\\Flagged")),
        ("Receipts", None),
        ("Travel", None),
    ] {
        folders.push(Folder {
            path: path.into(),
            special_use,
            mails: Vec::new(),
        });
    }
    let mut maker = Maker {
        rng,
        account: name,
        email,
        made: 0,
        thread: None,
    };
    fill(
        &mut folders,
        &mut maker,
        count,
        &[(0, 0.4), (1, 0.45), (2, 0.05), (7, 0.05), (8, 0.05)],
        10,
    );
    account(name, email, Kind::Gmail, folders)
}

fn lists(rng: &mut Rng, count: usize, profile: Profile) -> Account {
    let (name, email) = ("Lists", "lists@deep.inboxclassic.test");
    let mut folders = vec![Folder {
        path: "INBOX".into(),
        special_use: None,
        mails: Vec::new(),
    }];
    folders.extend(specials());
    folders.push(Folder {
        path: "Newsletters".into(),
        special_use: None,
        mails: Vec::new(),
    });
    let mut maker = Maker {
        rng,
        account: name,
        email,
        made: 0,
        thread: None,
    };
    fill(&mut folders, &mut maker, count, &[(0, 0.6), (6, 0.4)], 30);
    // every kind of message among them, in the Inbox
    let kinds = special_kinds(&mut maker, profile);
    folders[0].mails.extend(kinds);
    folders[0].mails.sort_by_key(|m| m.date);
    account(name, email, Kind::Lists, folders)
}

/// Messages of every kind the reading pane shows apart: a list's, a bounce, an invitation, a one-time code, an
/// encrypted one (that can not be read: no key), a signed one, and huge ones
fn special_kinds(maker: &mut Maker<'_>, profile: Profile) -> Vec<Mail> {
    let mut mails = Vec::new();
    let mut kind = |maker: &mut Maker<'_>, subject: &str, extra: &str, body: &str| {
        maker.made += 1;
        let date = NOW - 3600 * maker.made as i64;
        let message_id = format!("<lists-kind-{}@deep.inboxclassic.test>", maker.made);
        let raw = format!(
            "From: Mail Delivery <mailer-daemon@example.com>\r\nTo: Lists <{email}>\r\nSubject: {subject}\r\nDate: {date}\r\nMessage-ID: {message_id}\r\nMIME-Version: 1.0\r\n{extra}{body}",
            email = maker.email,
            date = rfc2822(date)
        );
        mails.push(Mail {
            message_id,
            subject: subject.into(),
            date,
            flags: vec![],
            raw,
        });
    };
    for n in 0..20 {
        kind(
            maker,
            &format!("Weekly digest {n}"),
            "List-Unsubscribe: <mailto:leave@list.example.com>\r\nContent-Type: text/plain\r\n\r\n",
            "This week on the list.\r\n",
        );
        kind(
            maker,
            &format!("Undelivered Mail Returned to Sender {n}"),
            "Auto-Submitted: auto-replied\r\nContent-Type: multipart/report; report-type=delivery-status; boundary=\"r\"\r\n\r\n",
            "--r\r\nContent-Type: text/plain\r\n\r\nThe message could not be delivered.\r\n--r\r\nContent-Type: message/delivery-status\r\n\r\nReporting-MTA: dns; mx.example.com\r\n\r\nFinal-Recipient: rfc822; gone@example.org\r\nAction: failed\r\nStatus: 5.1.1\r\nDiagnostic-Code: smtp; 550 5.1.1 No such user\r\n--r--\r\n",
        );
        kind(
            maker,
            &format!("Invitation: planning {n}"),
            "Content-Type: text/calendar; method=REQUEST; charset=utf-8\r\n\r\n",
            &format!(
                "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nUID:deep-{n}@example.com\r\nDTSTART:20261210T100000Z\r\nDTEND:20261210T110000Z\r\nSUMMARY:Planning {n}\r\nORGANIZER:mailto:boss@example.com\r\nATTENDEE:mailto:lists@deep.inboxclassic.test\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n"
            ),
        );
        kind(
            maker,
            &format!("Your sign-in code {n}"),
            "Content-Type: text/plain\r\n\r\n",
            &format!("Your code is {:06}. It expires in 10 minutes.\r\n", 100_000 + n * 7),
        );
        kind(
            maker,
            &format!("Encrypted {n}"),
            "Content-Type: multipart/encrypted; protocol=\"application/pgp-encrypted\"; boundary=\"e\"\r\n\r\n",
            "--e\r\nContent-Type: application/pgp-encrypted\r\n\r\nVersion: 1\r\n--e\r\nContent-Type: application/octet-stream\r\n\r\n-----BEGIN PGP MESSAGE-----\r\n\r\nhQEMA0bad0bad0bad0bAQf/not+a+real+message\r\n-----END PGP MESSAGE-----\r\n--e--\r\n",
        );
    }
    // huge: 2 MB small, 8 MB standard, 40 MB overnight
    let size = match profile {
        Profile::Small => 2,
        Profile::Standard => 8,
        Profile::Overnight => 40,
    } << 20;
    for n in 0..2 {
        let line = "Huge message text, to be shown before the rest of it comes.\r\n";
        let body = line.repeat(size / line.len());
        kind(maker, &format!("Huge {n}"), "Content-Type: text/plain\r\n\r\n", &body);
    }
    mails
}

fn broken(rng: &mut Rng, count: usize) -> Account {
    let (name, email) = ("Broken", "broken@deep.inboxclassic.test");
    let mut folders = vec![Folder {
        path: "INBOX".into(),
        special_use: None,
        mails: Vec::new(),
    }];
    folders.extend(specials());
    let mut maker = Maker {
        rng,
        account: name,
        email,
        made: 0,
        thread: None,
    };
    fill(&mut folders, &mut maker, count, &[(0, 1.0)], 20);
    account(name, email, Kind::Broken, folders)
}

fn account(name: &str, email: &str, kind: Kind, folders: Vec<Folder>) -> Account {
    Account {
        name: name.into(),
        email: email.into(),
        kind,
        folders,
    }
}

const MONTHS: [&str; 12] = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];
const DAYS: [&str; 7] = ["Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"];

/// Year, month (1-12), day of `secs` (UTC), Howard Hinnant's civil_from_days
fn civil(secs: i64) -> (i64, usize, i64, i64) {
    let days = secs.div_euclid(86_400);
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let day = doy - (153 * mp + 2) / 5 + 1;
    let month = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = yoe + era * 400 + i64::from(month <= 2);
    (year, month as usize, day, secs.rem_euclid(86_400))
}

/// The Date header's form: `Mon, 6 Oct 2025 10:00:00 +0000`
pub fn rfc2822(secs: i64) -> String {
    let (year, month, day, time) = civil(secs);
    let weekday = DAYS[secs.div_euclid(86_400).rem_euclid(7) as usize];
    format!(
        "{weekday}, {day} {} {year} {:02}:{:02}:{:02} +0000",
        MONTHS[month - 1],
        time / 3600,
        time / 60 % 60,
        time % 60
    )
}

/// IMAP's INTERNALDATE: `06-Oct-2025 10:00:00 +0000`
pub fn internal_date(secs: i64) -> String {
    let (year, month, day, time) = civil(secs);
    format!(
        "{day:02}-{}-{year} {:02}:{:02}:{:02} +0000",
        MONTHS[month - 1],
        time / 3600,
        time / 60 % 60,
        time % 60
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn dates_are_written_as_mail_and_imap_write_them() {
        // 2025-10-06 10:00:00 UTC, a Monday
        assert_eq!(rfc2822(1_759_744_800), "Mon, 6 Oct 2025 10:00:00 +0000");
        assert_eq!(internal_date(1_759_744_800), "06-Oct-2025 10:00:00 +0000");
        assert_eq!(rfc2822(NOW), "Sun, 1 Nov 2026 00:00:00 +0000");
    }

    #[test]
    fn a_seed_makes_one_world() {
        let a = World::generate(7, Profile::Small);
        let b = World::generate(7, Profile::Small);
        assert_eq!(a.digest(), b.digest());
        assert_ne!(a.digest(), World::generate(8, Profile::Small).digest());
        assert_eq!(a.accounts.len(), 5);
        let home = &a.accounts[1];
        assert!(
            home.folders.len() >= 400,
            "the tree of folders ({})",
            home.folders.len()
        );
        assert!(
            home.folders.iter().any(|f| f.path.matches('/').count() >= 5),
            "six levels deep"
        );
    }

    #[test]
    fn the_standard_world_has_its_sizes() {
        let world = World::generate(1, Profile::Standard);
        let total = world.total();
        assert!((33_000..36_000).contains(&total), "about 34,000 messages ({total})");
        let work = &world.accounts[0];
        assert!(work.folder("INBOX").is_some_and(|f| f.mails.len() > 16_000));
        for (path, size) in [
            ("Edges/Exactly 100", 100),
            ("Edges/Exactly 800", 800),
            ("Edges/Exactly 801", 801),
        ] {
            assert_eq!(work.folder(path).map(|f| f.mails.len()), Some(size), "{path}");
        }
        assert_eq!(work.folder("Edges/Empty").map(|f| f.mails.len()), Some(0));
    }
}
