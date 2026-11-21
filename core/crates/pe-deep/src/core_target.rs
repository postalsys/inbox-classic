//! The core without a window: a target that does what the three apps do with the core (a list loaded off the window
//! thread with what is selected, its pages asked for as they come in sight and kept eight at a time, the message
//! shown remembered for the list, the user's actions off the window thread, the list read again when the store says
//! it changed), so the same seed tells a bug of the core from one of a window. It needs no desktop.

use std::collections::{BTreeSet, HashMap};
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::mpsc::{Receiver, RecvTimeoutError, channel};
use std::time::{Duration, Instant};

use pe_core::{
    Action, Core, Event, ListView, MarkRead, MessageRef, Reselect, Reselected, Reselection, Scope, Selected,
};
use pe_store::{FolderId, Show, Sort};

use crate::model::{Act, List, Message, Row, Seen, Target};
use crate::servers::AccountServer;

/// The rows a window has in sight
pub const SIGHT: u64 = 30;
/// The pages a window keeps, as the apps do
const KEPT: usize = 8;
const PAGE: u64 = pe_core::LIST_PAGE;

pub struct CoreTarget {
    dir: PathBuf,
    core: Option<Arc<Core>>,
    events: Option<Receiver<Event>>,
    patience: Duration,
    /// Each account's id and name, each folder's account and path
    accounts: Vec<(i64, String)>,
    folders: HashMap<FolderId, (String, String)>,
    view: ListView,
    list: Option<List>,
    rows: u64,
    /// The pages read, the one used last at the end
    pages: Vec<(u64, Vec<pe_store::Message>)>,
    first: u64,
    selected: BTreeSet<u64>,
    all: Option<Selected>,
    anchor: Option<u64>,
    shown: Option<MessageRef>,
    /// The list chosen and not drawn yet: the core selects the message it showed when it was left
    arrived: bool,
    /// The row to select once the list is read again after messages left it
    after: Option<u64>,
    /// The store changed since the list was read: read it again once nothing else comes
    stale: bool,
    /// ImapKit's certificate, pinned
    cert: Vec<u8>,
}

impl CoreTarget {
    pub fn new(dir: PathBuf) -> CoreTarget {
        CoreTarget {
            dir,
            core: None,
            events: None,
            patience: pe_testkit::patience() * 10,
            accounts: Vec::new(),
            folders: HashMap::new(),
            view: ListView::new(),
            list: None,
            rows: 0,
            pages: Vec::new(),
            first: 0,
            selected: BTreeSet::new(),
            all: None,
            anchor: None,
            shown: None,
            arrived: false,
            after: None,
            stale: false,
            cert: Vec::new(),
        }
    }

    pub fn store_path(&self) -> PathBuf {
        self.dir.join("store.db")
    }

    fn core(&self) -> Result<&Arc<Core>, String> {
        self.core.as_ref().ok_or_else(|| "the core is not open".to_string())
    }

    /// The events that came, taken in: syncs begun and ended, actions done, the store changed
    fn take(&mut self, event: &Event) {
        match event {
            Event::FolderChanged { .. } | Event::FoldersChanged { .. } | Event::ActionUndone { .. } => {
                self.stale = true;
            }
            Event::Acted { .. } => self.stale = true,
            _ => {}
        }
    }

    /// Waits for the event `wanted` accepts, taking in the others meanwhile
    fn wait_for(&mut self, mut wanted: impl FnMut(&Event) -> bool, what: &str) -> Result<(), String> {
        let until = Instant::now() + self.patience;
        loop {
            let left = until.saturating_duration_since(Instant::now());
            let event = self
                .events
                .as_ref()
                .ok_or("no events")?
                .recv_timeout(left)
                .map_err(|_| format!("{what} did not come within {:?}", self.patience))?;
            let done = wanted(&event);
            self.take(&event);
            if done {
                return Ok(());
            }
        }
    }

    fn folder_id(&self, account: &str, path: &str) -> Result<FolderId, String> {
        self.folders
            .iter()
            .find(|(_, (a, p))| a == account && p == path)
            .map(|(id, _)| *id)
            .ok_or_else(|| format!("no folder {account}/{path}"))
    }

    fn learn_folders(&mut self) -> Result<(), String> {
        let core = self.core()?.clone();
        self.folders.clear();
        for (id, name) in &self.accounts {
            for folder in core.folders(*id).map_err(|e| e.to_string())? {
                let path = crate::servers::user_path(&folder.info.path);
                self.folders.insert(folder.id, (name.clone(), path));
            }
        }
        Ok(())
    }

    fn scope_of(&self, list: &List) -> Result<Scope, String> {
        Ok(match list {
            List::Folder { account, path } => Scope::Folder(self.folder_id(account, path)?),
            List::AllInboxes => Scope::AllInboxes,
            List::Flagged => Scope::Flagged,
            List::AllSent => Scope::AllSent,
            List::AllDrafts => Scope::AllDrafts,
        })
    }

    /// The list read again with what is selected, as the apps ask for it: the core finds it where it is now
    fn load(&mut self) -> Result<(), String> {
        let core = self.core()?.clone();
        let mut reselect = Reselect {
            after: self.after.take(),
            arrived: std::mem::take(&mut self.arrived),
            ..Reselect::default()
        };
        if let Some(all) = &self.all {
            reselect.selected = all.clone();
        } else if self.selected.len() > 1 {
            let ranges: Vec<(u64, u64)> = self.selected.iter().map(|r| (*r, r + 1)).collect();
            reselect.selected = Selected::Listed(self.view.refs_in_ranges(&core, &ranges).map_err(|e| e.to_string())?);
        } else if let Some(shown) = self.shown {
            reselect.selected = Selected::Listed(vec![shown]);
            reselect.hint = self.selected.first().copied();
        }
        let request = core.list_load(&self.view, reselect).map_err(|e| e.to_string())?;
        self.wait_for(
            |e| matches!(e, Event::ListReady { request: r } if *r == request),
            "the list",
        )?;
        self.stale = false;
        let load = core
            .list_load_result(request)
            .ok_or("no list read")?
            .map_err(|e| format!("the list could not be read: {e}"))?;
        self.rows = load.rows;
        self.pages = vec![(load.offset, load.messages)];
        self.drawn(load.reselected);
        self.fill_sight()
    }

    /// The selection the load made, as the apps draw it: Select All kept, the messages kept where they are now, or a
    /// new selection (the row after a removal, what Undo brought back, the message a list come to opens with), shown
    fn drawn(&mut self, reselected: Reselected) {
        match reselected.how {
            Reselection::All => {
                self.selected = (0..self.rows).collect();
                self.all = Some(reselected.selection);
            }
            Reselection::None => {
                self.selected.clear();
                self.all = None;
                self.shown = None;
            }
            Reselection::Kept => {
                self.selected = reselected.rows.iter().copied().collect();
                self.all = None;
            }
            Reselection::After | Reselection::Arrived | Reselection::Restored => {
                self.selected = reselected.rows.iter().copied().collect();
                self.all = None;
                self.shown = match &reselected.selection {
                    Selected::Listed(refs) if self.selected.len() == 1 => refs.first().copied(),
                    _ => None,
                };
                self.anchor = self.selected.first().copied();
            }
        }
        if let Some(focus) = reselected.focus
            && (focus < self.first || focus >= self.first + SIGHT)
        {
            self.first = focus.saturating_sub(SIGHT / 2);
        }
    }

    /// The store changed: the tree read again (a folder may be gone, renamed elsewhere), then the list, as the apps
    /// do; a list whose folder is gone shows nothing, as the apps then choose no row
    fn read_again(&mut self) -> Result<(), String> {
        self.learn_folders()?;
        if let Some(List::Folder { account, path }) = &self.list
            && self.folder_id(account, path).is_err()
        {
            self.list = None;
            self.view.set_scope(None);
            self.rows = 0;
            self.pages.clear();
            self.selected.clear();
            self.shown = None;
            self.stale = false;
            return Ok(());
        }
        self.load()
    }

    /// A page asked for and read
    fn page(&mut self, offset: u64) -> Result<(), String> {
        if let Some(index) = self.pages.iter().position(|(at, _)| *at == offset) {
            let page = self.pages.remove(index);
            self.pages.push(page);
            return Ok(());
        }
        let core = self.core()?.clone();
        let request = core.list_load_page(&self.view, offset).map_err(|e| e.to_string())?;
        self.wait_for(
            |e| matches!(e, Event::ListPageReady { request: r } if *r == request),
            "a page",
        )?;
        let page = core
            .list_load_result(request)
            .ok_or("no page read")?
            .map_err(|e| format!("a page could not be read: {e}"))?;
        if self.pages.len() >= KEPT {
            self.pages.remove(0);
        }
        self.pages.push((offset, page.messages));
        Ok(())
    }

    /// The pages of the rows in sight read
    fn fill_sight(&mut self) -> Result<(), String> {
        self.first = self.first.min(self.rows.saturating_sub(SIGHT));
        let end = (self.first + SIGHT).min(self.rows);
        let mut offset = self.first / PAGE * PAGE;
        while offset < end {
            self.page(offset)?;
            offset += PAGE;
        }
        Ok(())
    }

    fn message_at(&self, row: u64) -> Option<&pe_store::Message> {
        let offset = row / PAGE * PAGE;
        let (_, page) = self.pages.iter().find(|(at, _)| *at == offset)?;
        page.get((row - offset) as usize)
    }

    fn reference(&self, row: u64) -> Option<MessageRef> {
        self.message_at(row).map(|m| MessageRef {
            folder: m.folder_id,
            uid: m.info.uid,
        })
    }

    fn see(&mut self, row: u64) -> Result<(), String> {
        if row < self.first || row >= self.first + SIGHT {
            self.first = row.saturating_sub(SIGHT / 2);
        }
        self.fill_sight()
    }

    fn click(&mut self, row: u64) -> Result<(), String> {
        if row >= self.rows {
            return Err(format!("no row {row} in a list of {}", self.rows));
        }
        self.see(row)?;
        self.all = None;
        self.selected = BTreeSet::from([row]);
        self.anchor = Some(row);
        self.shown = self.reference(row);
        if let Some(shown) = self.shown {
            let core = self.core()?.clone();
            core.list_shown(&self.view, shown).map_err(|e| e.to_string())?;
        }
        Ok(())
    }

    /// What is selected, as the core takes it for an action
    fn selection(&self) -> Result<Selected, String> {
        if let Some(all) = &self.all {
            return Ok(all.clone());
        }
        let core = self.core()?;
        let ranges: Vec<(u64, u64)> = self.selected.iter().map(|r| (*r, r + 1)).collect();
        Ok(Selected::Listed(
            self.view.refs_in_ranges(core, &ranges).map_err(|e| e.to_string())?,
        ))
    }

    fn act_on(&mut self, action: Action, leaves: bool) -> Result<(), String> {
        let selected = self.selection()?;
        if selected.count() == 0 {
            return Ok(());
        }
        let core = self.core()?.clone();
        core.act_start(selected, action).map_err(|e| e.to_string())?;
        if leaves {
            // the row after the messages that left, selected once the list is read again
            self.after = self.selected.first().copied().or(Some(0));
            self.selected.clear();
            self.all = None;
            self.shown = None;
        }
        Ok(())
    }
}

impl CoreTarget {
    /// The core opened on the target's store, its events taken in here
    fn open_core(&mut self) -> Result<Arc<Core>, String> {
        let (sender, events) = channel();
        let sender = std::sync::Mutex::new(sender);
        let options = pe_core::Options {
            trust: pe_net::Trust::Pinned(vec![self.cert.clone()]),
            passwords: pe_core::PasswordStore::Memory,
            ..Default::default()
        };
        let core = Core::open_with(self.store_path(), options, move |event| {
            let _ = sender.lock().unwrap_or_else(|e| e.into_inner()).send(event);
        })
        .map_err(|e| e.to_string())?;
        core.set_download_ahead(pe_store::Ahead::Never)
            .map_err(|e| e.to_string())?;
        // a message sent goes at once
        core.set_send_delay(0).map_err(|e| e.to_string())?;
        let core = Arc::new(core);
        self.core = Some(core.clone());
        self.events = Some(events);
        Ok(core)
    }

    /// The app closed and started again: the core opened on the same store, the passwords given again (they are kept
    /// in memory), every account synced, and the row of the tree the app was closed on chosen, as the apps start
    fn restart(&mut self) -> Result<(), String> {
        self.core = None;
        self.events = None;
        let core = self.open_core()?;
        for (id, _) in &self.accounts {
            core.set_password(*id, pe_testkit::PASSWORD);
            core.sync(*id).map_err(|e| e.to_string())?;
        }
        self.list = None;
        self.view = ListView::new();
        self.pages.clear();
        self.rows = 0;
        self.selected.clear();
        self.shown = None;
        let key = core
            .tree_start()
            .map_err(|e| e.to_string())?
            .unwrap_or_else(|| "inboxes".into());
        let list = match key.as_str() {
            "inboxes" => List::AllInboxes,
            "flagged" => List::Flagged,
            "sent" => List::AllSent,
            "drafts" => List::AllDrafts,
            other => {
                let id: FolderId = other
                    .strip_prefix("folder:")
                    .and_then(|n| n.parse().ok())
                    .ok_or("no row to start with")?;
                let (account, path) = self
                    .folders
                    .get(&id)
                    .cloned()
                    .ok_or("the folder started with is gone")?;
                List::Folder { account, path }
            }
        };
        self.act(&Act::Open(list))
    }
}

impl Target for CoreTarget {
    fn name(&self) -> &str {
        "core"
    }

    fn start(&mut self, accounts: &[AccountServer]) -> Result<(), String> {
        std::fs::create_dir_all(&self.dir).map_err(|e| e.to_string())?;
        self.cert = accounts.first().ok_or("no account")?.kit.cert.clone();
        let core = self.open_core()?;
        for server in accounts {
            let mut settings = server.kit.account_settings();
            // ImapKit's SMTP server takes AUTH after STARTTLS only
            settings.smtp_security = pe_store::Security::StartTls;
            settings.name = server.name.clone();
            settings.email = server.email.clone();
            let id = core
                .add_account(&settings, pe_testkit::PASSWORD)
                .map_err(|e| e.to_string())?;
            self.accounts.push((id, server.name.clone()));
            core.sync(id).map_err(|e| e.to_string())?;
        }
        self.settle()?;
        self.learn_folders()
    }

    fn act(&mut self, act: &Act) -> Result<(), String> {
        let core = self.core()?.clone();
        match act {
            Act::Open(list) => {
                let scope = self.scope_of(list)?;
                if self.list.as_ref() == Some(list) {
                    return Ok(());
                }
                let key = match (list, scope) {
                    (List::AllInboxes, _) => "inboxes".to_string(),
                    (List::Flagged, _) => "flagged".to_string(),
                    (List::AllSent, _) => "sent".to_string(),
                    (List::AllDrafts, _) => "drafts".to_string(),
                    (_, Scope::Folder(id)) => format!("folder:{id}"),
                    _ => String::new(),
                };
                // the row the app starts with next time, as the apps say it when a row is chosen
                core.tree_chosen(&key).map_err(|e| e.to_string())?;
                self.view.set_text("");
                self.view.set_scope(Some(scope));
                self.list = Some(list.clone());
                self.selected.clear();
                self.all = None;
                self.shown = None;
                self.first = 0;
                self.arrived = true;
                self.load()?;
            }
            Act::Scroll(row) => {
                self.first = *row;
                self.fill_sight()?;
            }
            Act::Home => {
                self.first = 0;
                self.fill_sight()?;
            }
            Act::End => {
                self.first = self.rows.saturating_sub(SIGHT);
                self.fill_sight()?;
            }
            Act::PageDown(times) => {
                self.first = (self.first + SIGHT * u64::from(*times)).min(self.rows.saturating_sub(SIGHT));
                self.fill_sight()?;
            }
            Act::Click(row) => self.click(*row)?,
            Act::ShiftClick(row) => {
                let from = self.anchor.unwrap_or(0);
                let (a, b) = (from.min(*row), from.max(*row).min(self.rows.saturating_sub(1)));
                if a == b {
                    // a range of one row is that row clicked, as the windows open it
                    return self.click(a);
                }
                self.selected = (a..=b).collect();
                self.all = None;
                self.shown = None;
            }
            Act::SelectAll => {
                self.all = Some(self.view.select_all(&core).map_err(|e| e.to_string())?);
                self.selected = (0..self.rows).collect();
                self.shown = None;
            }
            Act::Delete => self.act_on(Action::Delete, true)?,
            Act::MoveTo(list) => {
                let List::Folder { account, path } = list else {
                    return Err("messages move to a folder".into());
                };
                let folder = self.folder_id(account, path)?;
                self.act_on(Action::Move(folder), true)?;
            }
            Act::Flag => self.act_on(Action::ToggleFlag, false)?,
            Act::Read => self.act_on(Action::Read(true), false)?,
            Act::Unread => self.act_on(Action::Read(false), false)?,
            Act::Sort(by, ascending) => {
                self.view.set_sort(Sort {
                    field: (*by).into(),
                    ascending: *ascending,
                });
                self.load()?;
            }
            Act::Search(text) => {
                self.view.set_text(text);
                self.selected.clear();
                self.all = None;
                self.shown = None;
                self.first = 0;
                self.load()?;
            }
            Act::Group(on) => {
                self.view.set_grouped(*on);
                self.load()?;
            }
            Act::UnreadOnly(on) => {
                self.view.set_show(if *on { Show::Unread } else { Show::All });
                self.load()?;
            }
            Act::Undo => {
                // nothing to undo: the status bar says so, nothing else happens
                let _ = core.undo();
                self.stale = true;
            }
            Act::Sync => {
                for (id, _) in &self.accounts {
                    core.sync(*id).map_err(|e| e.to_string())?;
                }
            }
            Act::MarkAllRead => {
                let what = match &self.list {
                    Some(List::Folder { account, path }) => MarkRead::Folder(self.folder_id(account, path)?),
                    Some(List::AllInboxes) => MarkRead::AllInboxes,
                    _ => return Err(crate::model::UNSUPPORTED.into()),
                };
                core.mark_read_start(what).map_err(|e| e.to_string())?;
            }
            Act::EmptyFolder => {
                let Some(List::Folder { account, path }) = &self.list else {
                    return Err("Empty Folder is a folder's".into());
                };
                let folder = self.folder_id(account, path)?;
                core.empty_folder(folder).map_err(|e| e.to_string())?;
                self.after = Some(0);
                self.stale = true;
            }
            Act::Restart => self.restart()?,
            Act::Send { to, subject } => {
                let from = match &self.list {
                    Some(List::Folder { account, .. }) => self.accounts.iter().find(|(_, n)| n == account),
                    _ => self.accounts.first(),
                };
                let account = from.map(|(id, _)| *id).ok_or("no account to send from")?;
                let outgoing = pe_core::Outgoing {
                    to: to.clone(),
                    subject: subject.clone(),
                    text: "Written in the deep test.".into(),
                    ..Default::default()
                };
                core.send(account, outgoing).map_err(|e| e.to_string())?;
            }
        }
        Ok(())
    }

    fn settle(&mut self) -> Result<(), String> {
        let until = Instant::now() + self.patience;
        // once the core is quiet, a sync of the accounts the list shows: it finishes only after the commands queued
        // before it, so the server has what the user did
        let mut barrier = false;
        loop {
            let event = self
                .events
                .as_ref()
                .ok_or("no events")?
                .recv_timeout(Duration::from_millis(300));
            match event {
                Ok(event) => self.take(&event),
                Err(RecvTimeoutError::Disconnected) => return Err("the core closed".into()),
                Err(RecvTimeoutError::Timeout) if self.core()?.quiet() => {
                    if !barrier {
                        barrier = true;
                        self.core()?.sync_barrier().map_err(|e| e.to_string())?;
                        continue;
                    }
                    if self.stale && self.list.is_some() {
                        self.read_again()?;
                        continue;
                    }
                    return Ok(());
                }
                Err(RecvTimeoutError::Timeout) => {}
            }
            if Instant::now() > until {
                return Err(format!("still busy after {:?}", self.patience));
            }
        }
    }

    fn observe(&mut self) -> Result<Seen, String> {
        let end = (self.first + SIGHT).min(self.rows);
        let sight = (self.first..end)
            .map(|row| match self.message_at(row) {
                Some(m) => {
                    let (account, path) = self.folders.get(&m.folder_id).cloned().unwrap_or_default();
                    Row {
                        row,
                        blank: false,
                        message: Some(Message {
                            account,
                            path,
                            uid: m.info.uid,
                        }),
                        subject: m.info.subject.clone(),
                        date: m.info.date.or(m.info.internal_date).unwrap_or(0),
                    }
                }
                None => Row {
                    row,
                    blank: true,
                    message: None,
                    subject: String::new(),
                    date: 0,
                },
            })
            .collect();
        let shown = self.shown.and_then(|m| {
            let (account, path) = self.folders.get(&m.folder)?.clone();
            Some(Message {
                account,
                path,
                uid: m.uid,
            })
        });
        let core = self.core()?.clone();
        let mut tree = Vec::new();
        for (id, name) in &self.accounts {
            for folder in core.folders(*id).map_err(|e| e.to_string())? {
                tree.push((
                    name.clone(),
                    crate::servers::user_path(&folder.info.path),
                    folder.unread,
                ));
            }
        }
        Ok(Seen {
            list: self.list.clone(),
            rows: self.rows,
            sight,
            selected: self.selected.iter().copied().collect(),
            shown,
            search: self.view.text().to_string(),
            grouped: self.view.grouped(),
            unread_only: self.view.show() == Show::Unread,
            tree,
            // it reads the list chosen before it answers, so it never draws the one before
            pending: false,
        })
    }

    fn health(&mut self) -> Option<crate::health::Sample> {
        Some(crate::health::Sample {
            memory_kib: crate::health::memory_kib(std::process::id()),
            open_files: crate::health::own_open_files(),
            store_bytes: crate::health::store_bytes(&self.store_path()),
            ..Default::default()
        })
    }
}
