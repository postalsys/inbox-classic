//! The folder list of the main window, row by row, for the three apps to draw as it is.
//!
//! It starts with the Inbox. One account: Inbox, Flagged, then the rest of its folders, with no heading for the
//! account. Several accounts: All Inboxes (each account's Inbox under it, named after the account), Flagged, then each
//! account's heading with its folders but the Inbox. The folders an Inbox holds move up a level: they come first among
//! the account's folders, as the Inbox has no row of its own to hold them under an account.

use pe_imap::SpecialUse;
use pe_store::{AccountId, Folder, FolderId};

use crate::{Core, Result, account_titles, all_inboxes_shown, emptiable, text};

/// What a row of the folder list is
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TreeRowKind {
    /// Every account's Inbox in one list (several accounts)
    AllInboxes,
    /// An account's Inbox under All Inboxes, named after the account (several accounts)
    AccountInbox,
    /// Every account's Sent Items in one list, each under it named after the account (several accounts)
    AllSent,
    /// Every account's Drafts in one list, each under it named after the account (several accounts)
    AllDrafts,
    /// Every flagged message of every account
    Flagged,
    /// An account's heading, with its folders under it (several accounts)
    Account,
    /// A folder: one account's Inbox (with one account), or any other folder
    Folder,
}

/// The menu a row's right-click opens
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TreeMenu {
    /// None (Flagged: its messages are of every folder)
    None,
    /// Mark All Read only (All Inboxes, no folder of its own)
    MarkRead,
    /// A folder's: Mark All Read, New Folder, Rename, Delete, Empty
    Folder,
    /// An account's
    Account,
}

/// The messages a row lists when it is chosen
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TreeList {
    /// None (a heading)
    None,
    /// Its folder's
    Folder,
    AllInboxes,
    Flagged,
    AllSent,
    AllDrafts,
}

impl TreeList {
    /// The list's scope, `folder` for a folder's own; None for a heading's, or a folder's without one
    pub fn scope(self, folder: FolderId) -> Option<pe_store::Scope> {
        use pe_store::Scope;
        match self {
            TreeList::None => None,
            TreeList::Folder if folder == 0 => None,
            TreeList::Folder => Some(Scope::Folder(folder)),
            TreeList::AllInboxes => Some(Scope::AllInboxes),
            TreeList::Flagged => Some(Scope::Flagged),
            TreeList::AllSent => Some(Scope::AllSent),
            TreeList::AllDrafts => Some(Scope::AllDrafts),
        }
    }

    /// One folder of every account (All Inboxes, All Sent, All Drafts): their messages show the account they are of
    pub fn gathers(self) -> bool {
        matches!(self, TreeList::AllInboxes | TreeList::AllSent | TreeList::AllDrafts)
    }
}

/// One row of the folder list, in its order
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TreeRow {
    pub kind: TreeRowKind,
    /// What stays the same for this row from one reading to the next, to keep its selection and opened state:
    /// `inboxes`, `sent`, `drafts`, `flagged`, `account:<id>` or `folder:<id>` (a folder keeps its key under All
    /// Inboxes, All Sent or All Drafts or not)
    pub key: String,
    /// The account it belongs to, 0 for All Inboxes and Flagged
    pub account: AccountId,
    /// The folder it shows, 0 for All Inboxes, Flagged and a heading
    pub folder: FolderId,
    /// How far in: 0 at the top
    pub depth: usize,
    /// What it says
    pub label: String,
    /// What the folder bar and the window's title say when it is chosen, and what a screen reader says for it:
    /// "Inbox - Gmail" for an account's Inbox under All Inboxes, else its label (with the account when there are
    /// several)
    pub title: String,
    /// Its own unread messages (Flagged: how many messages are flagged, which is no reason for bold)
    pub unread: u64,
    /// The unread messages of the rows under it, shown with its own while it is collapsed (Junk E-mail and Deleted
    /// Items count for none)
    pub hidden: u64,
    /// It has rows under it, so it can be opened and closed
    pub parent: bool,
    /// It lists messages when chosen (a heading does not, nor a folder the server says can not be selected)
    pub selectable: bool,
    /// Messages can be dropped on it: a folder that can be selected, or an account's Inbox under All Inboxes
    pub drop_target: bool,
    /// It can be dragged up and down among its own kind to order the accounts (Move Up and Move Down in its menu): a
    /// heading, or an Inbox under All Inboxes
    pub reorders_accounts: bool,
    /// Its menu
    pub menu: TreeMenu,
    /// What it lists when chosen
    pub list: TreeList,
    /// A row with rows under it starts open (All Inboxes, a heading) or closed (All Sent, All Drafts); whether the
    /// user's opening and closing of it is kept (All Inboxes, All Sent, All Drafts and the headings)
    pub starts_open: bool,
    pub remembers_open: bool,
    /// Where New Folder makes a folder with this row chosen: the account (0: New Folder does not apply here) and the
    /// folder to make it in (0: the top of the account, as for the Inbox, which holds no folders in the list)
    pub new_folder_account: AccountId,
    pub new_folder_parent: FolderId,
    /// A word for its icon: a special folder's (`inbox`, `sent`, `drafts`, `deleted`, `junk`, `archive`, `flagged`,
    /// `all`), `account` for a heading, empty for any other folder
    pub icon: &'static str,
}

impl TreeRow {
    /// The count it shows: its own unread, with those under it while it is collapsed
    pub fn shown(&self, collapsed: bool) -> u64 {
        self.unread + if collapsed { self.hidden } else { 0 }
    }

    /// It is shown bold: unread mail in it, or (collapsed) under it; Flagged never is
    pub fn bold(&self, collapsed: bool) -> bool {
        self.kind != TreeRowKind::Flagged && self.shown(collapsed) > 0
    }

    /// A row of no folder
    fn fixed(kind: TreeRowKind, key: String, account: AccountId, label: String, icon: &'static str) -> TreeRow {
        TreeRow {
            kind,
            key,
            account,
            folder: 0,
            depth: 0,
            title: label.clone(),
            label,
            unread: 0,
            hidden: 0,
            parent: false,
            selectable: kind != TreeRowKind::Account,
            drop_target: false,
            reorders_accounts: kind == TreeRowKind::Account,
            menu: match kind {
                TreeRowKind::AllInboxes => TreeMenu::MarkRead,
                TreeRowKind::Account => TreeMenu::Account,
                _ => TreeMenu::None,
            },
            list: match kind {
                TreeRowKind::AllInboxes => TreeList::AllInboxes,
                TreeRowKind::AllSent => TreeList::AllSent,
                TreeRowKind::AllDrafts => TreeList::AllDrafts,
                TreeRowKind::Flagged => TreeList::Flagged,
                _ => TreeList::None,
            },
            starts_open: !matches!(kind, TreeRowKind::AllSent | TreeRowKind::AllDrafts),
            remembers_open: kind != TreeRowKind::Flagged,
            new_folder_account: account,
            new_folder_parent: 0,
            icon,
        }
    }
}

/// The word of a folder's icon
fn icon(folder: &Folder) -> &'static str {
    match folder.info.special_use.as_deref().and_then(SpecialUse::from_flag) {
        Some(SpecialUse::Flagged) => "flagged",
        Some(SpecialUse::All) => "all",
        _ => text::folder_kind(&folder.info),
    }
}

/// The store's own rule for an Inbox, the one All Inboxes lists by
fn is_inbox(folder: &Folder) -> bool {
    folder.info.path.eq_ignore_ascii_case("INBOX")
}

/// The lists of every account's folder of a kind, after All Inboxes, with several accounts: All Sent and All Drafts,
/// their folders by the store's own rule ([`pe_store::Scope::includes`])
const GATHERED: [(pe_store::Scope, TreeRowKind, &str, pe_i18n::Text); 2] = [
    (
        pe_store::Scope::AllSent,
        TreeRowKind::AllSent,
        "sent",
        pe_i18n::Text::UiAllSent,
    ),
    (
        pe_store::Scope::AllDrafts,
        TreeRowKind::AllDrafts,
        "drafts",
        pe_i18n::Text::UiAllDrafts,
    ),
];

fn gathered(folder: &Folder) -> bool {
    GATHERED.iter().any(|(scope, ..)| scope.includes(&folder.info))
}

/// Counts toward a collapsed row: not Junk E-mail nor Deleted Items
fn counted(folder: &Folder) -> u64 {
    if emptiable(&folder.info) { 0 } else { folder.unread }
}

/// An account's folders in the list's order, each with its depth: the Inbox first, the folders it holds moved up a
/// level after it, then the others as the server lists them
pub(crate) fn ordered(folders: Vec<Folder>) -> Vec<(Folder, usize)> {
    let infos: Vec<&pe_store::FolderInfo> = folders.iter().map(|f| &f.info).collect();
    let depths = pe_sync::tree_depths(&infos);
    let mut rows: Vec<(Folder, usize)> = folders.into_iter().zip(depths).collect();
    let Some(at) = rows.iter().position(|(folder, _)| is_inbox(folder)) else {
        return rows;
    };
    let inbox_depth = rows[at].1;
    let held = rows[at + 1..]
        .iter()
        .take_while(|(_, depth)| *depth > inbox_depth)
        .count();
    let mut inbox: Vec<(Folder, usize)> = rows.drain(at..at + 1 + held).collect();
    // the Inbox at the top, what it held a level up after it
    for (i, (_, depth)) in inbox.iter_mut().enumerate() {
        *depth = if i == 0 { 0 } else { *depth - inbox_depth - 1 };
    }
    inbox.extend(rows);
    inbox
}

/// An account's ordered folders split into its Inbox (first, when it has one) and the rest
fn split_inbox(folders: &[(Folder, usize)]) -> (Option<&Folder>, &[(Folder, usize)]) {
    match folders.split_first() {
        Some(((inbox, _), rest)) if is_inbox(inbox) => (Some(inbox), rest),
        _ => (None, folders),
    }
}

/// A folder's row
fn folder_row(folder: &Folder, depth: usize) -> TreeRow {
    let label = text::folder_name(&folder.info);
    TreeRow {
        kind: TreeRowKind::Folder,
        key: format!("folder:{}", folder.id),
        account: folder.account_id,
        folder: folder.id,
        depth,
        title: label.clone(),
        label,
        unread: folder.unread,
        hidden: 0,
        parent: false,
        selectable: folder.info.selectable,
        drop_target: folder.info.selectable,
        reorders_accounts: false,
        menu: TreeMenu::Folder,
        list: TreeList::Folder,
        starts_open: true,
        remembers_open: false,
        new_folder_account: folder.account_id,
        // the Inbox holds no folders in the list: a folder made from it goes at the top
        new_folder_parent: if is_inbox(folder) { 0 } else { folder.id },
        icon: icon(folder),
    }
}

/// Each row's `hidden` and `parent` from the rows under it, by their depths, in one pass from the bottom: a stack of
/// the rows still open above, each with what was counted under it so far
fn fill_below(rows: &mut [(TreeRow, u64)]) {
    let mut open: Vec<(usize, u64)> = Vec::new();
    for i in (0..rows.len()).rev() {
        let depth = rows[i].0.depth;
        let mut below = 0;
        let mut parent = false;
        // the rows after it that are deeper are under it
        while let Some(&(j, sum)) = open.last() {
            if rows[j].0.depth <= depth {
                break;
            }
            // what is left on the stack deeper than it are its children: theirs were taken by them
            open.pop();
            parent = true;
            below += sum + rows[j].1;
        }
        rows[i].0.parent = parent;
        rows[i].0.hidden = below;
        open.push((i, below));
    }
}

/// The rows of one account, with no heading: Inbox, Flagged, the rest
fn one_account(folders: &[(Folder, usize)], account: AccountId, mut flagged: TreeRow) -> Vec<(TreeRow, u64)> {
    let (inbox, rest) = split_inbox(folders);
    let mut rows: Vec<(TreeRow, u64)> = inbox
        .map(|inbox| (folder_row(inbox, 0), counted(inbox)))
        .into_iter()
        .collect();
    // with one account New Folder from Flagged goes at its top
    flagged.new_folder_account = account;
    rows.push((flagged, 0));
    rows.extend(
        rest.iter()
            .map(|(folder, depth)| (folder_row(folder, *depth), counted(folder))),
    );
    rows
}

/// All Sent and All Drafts, each with every account's folder of its kind under it, named after the account; none
/// when no account has one
fn gathered_rows(accounts: &[(AccountId, Vec<(Folder, usize)>)], titles: &[String]) -> Vec<(TreeRow, u64)> {
    let mut rows = Vec::new();
    for (scope, kind, key, label) in GATHERED {
        let under: Vec<(TreeRow, u64)> = accounts
            .iter()
            .zip(titles)
            .flat_map(|((_, folders), title)| {
                folders
                    .iter()
                    .filter(|(folder, _)| scope.includes(&folder.info))
                    .map(move |(folder, _)| (account_folder_row(folder, title), counted(folder)))
            })
            .collect();
        if !under.is_empty() {
            rows.push((TreeRow::fixed(kind, key.into(), 0, pe_i18n::tr(label), key), 0));
            rows.extend(under);
        }
    }
    rows
}

/// An account's folder under All Sent or All Drafts: named after the account
fn account_folder_row(folder: &Folder, title: &str) -> TreeRow {
    TreeRow {
        label: title.to_string(),
        title: format!("{} - {title}", text::folder_name(&folder.info)),
        // its folders are listed under the account's heading: one made from here goes there
        new_folder_parent: 0,
        ..folder_row(folder, 1)
    }
}

/// The rows of several accounts: All Inboxes with each Inbox, All Sent and All Drafts with each account's, Flagged,
/// then each account's heading and its other folders
fn several_accounts(
    accounts: &[(AccountId, Vec<(Folder, usize)>)],
    titles: &[String],
    flagged: TreeRow,
) -> Vec<(TreeRow, u64)> {
    let mut rows = vec![(
        TreeRow::fixed(
            TreeRowKind::AllInboxes,
            "inboxes".into(),
            0,
            pe_i18n::tr(pe_i18n::Text::UiAllInboxes),
            "inbox",
        ),
        0,
    )];
    for ((account, folders), title) in accounts.iter().zip(titles) {
        if let (Some(inbox), _) = split_inbox(folders) {
            let row = TreeRow {
                kind: TreeRowKind::AccountInbox,
                account: *account,
                label: title.clone(),
                title: format!("{} - {title}", text::folder_name(&inbox.info)),
                reorders_accounts: true,
                ..folder_row(inbox, 1)
            };
            rows.push((row, counted(inbox)));
        }
    }
    rows.extend(gathered_rows(accounts, titles));
    rows.push((flagged, 0));
    for ((account, folders), title) in accounts.iter().zip(titles) {
        let heading = TreeRow::fixed(
            TreeRowKind::Account,
            format!("account:{account}"),
            *account,
            title.clone(),
            "account",
        );
        rows.push((heading, 0));
        // a gathered folder has its row under All Sent or All Drafts: the folders it holds move up a level in its place
        let mut lifted: Option<usize> = None;
        for (folder, depth) in split_inbox(folders).1 {
            let mut depth = *depth;
            match lifted {
                Some(at) if depth > at => depth -= 1,
                _ => lifted = None,
            }
            if gathered(folder) {
                lifted = Some(depth);
                continue;
            }
            let mut row = folder_row(folder, depth + 1);
            // which account's, in the folder bar and the title: "Archive - Work"
            row.title = format!("{} - {title}", row.label);
            rows.push((row, counted(folder)));
        }
    }
    rows
}

/// The rows of the folder list of `accounts` (each with its folders, in the accounts' order) and the number of
/// flagged messages
pub(crate) fn rows(accounts: Vec<(pe_store::Account, Vec<Folder>)>, flagged: u64) -> Vec<TreeRow> {
    if accounts.is_empty() {
        return Vec::new();
    }
    let titles = account_titles(&accounts.iter().map(|(a, _)| a.clone()).collect::<Vec<_>>());
    let mut flagged_row = TreeRow::fixed(
        TreeRowKind::Flagged,
        "flagged".into(),
        0,
        pe_i18n::tr(pe_i18n::Text::UiFlaggedFolder),
        "flagged",
    );
    flagged_row.unread = flagged;
    let ordered: Vec<(AccountId, Vec<(Folder, usize)>)> = accounts
        .into_iter()
        .map(|(account, folders)| (account.id, ordered(folders)))
        .collect();
    let mut rows = if all_inboxes_shown(ordered.len()) {
        several_accounts(&ordered, &titles, flagged_row)
    } else {
        one_account(&ordered[0].1, ordered[0].0, flagged_row)
    };
    fill_below(&mut rows);
    let mut rows: Vec<TreeRow> = rows.into_iter().map(|(row, _)| row).collect();
    // All Inboxes, All Sent and All Drafts count their folders as a folder does (they are no folders of their own)
    for row in rows.iter_mut().filter(|row| row.list.gathers()) {
        row.unread = row.hidden;
        row.hidden = 0;
    }
    rows
}

/// The row to choose after the list was read again, given the key of the one chosen before: the same row, or, when it
/// is gone (All Inboxes, Flagged or a heading after an account came or went), the Inbox of its account or the first
/// Inbox; None when the folder chosen is gone, for the app to start over
pub fn reselect(rows: &[TreeRow], key: &str) -> Option<usize> {
    if let Some(at) = rows.iter().position(|row| row.key == key) {
        return Some(at);
    }
    if key.starts_with("folder:") {
        return None;
    }
    let account: AccountId = key.strip_prefix("account:").and_then(|id| id.parse().ok()).unwrap_or(0);
    let inbox = |row: &TreeRow| row.icon == "inbox" && row.folder != 0;
    rows.iter()
        .position(|row| inbox(row) && row.account == account)
        .or_else(|| rows.iter().position(inbox))
}

impl Core {
    /// Each account with its folders, in the accounts' order
    fn accounts_with_folders(&self) -> Result<Vec<(pe_store::Account, Vec<Folder>)>> {
        let store = self.store();
        store
            .accounts()?
            .into_iter()
            .map(|account| {
                let folders = store.folders(account.id)?;
                Ok((account, folders))
            })
            .collect()
    }

    /// The folder list of the main window, row by row in its order ([`TreeRow`])
    pub fn folder_tree(&self) -> Result<Vec<TreeRow>> {
        let accounts = self.accounts_with_folders()?;
        Ok(rows(accounts, self.flagged_count()?))
    }

    /// Every folder in the order the folder list shows them, each with its counts: the order Next Unread goes in
    pub(crate) fn folder_order(&self) -> Result<Vec<Folder>> {
        let accounts = self.accounts_with_folders()?;
        let mut folders: std::collections::HashMap<FolderId, Folder> = accounts
            .iter()
            .flat_map(|(_, folders)| folders.iter().map(|folder| (folder.id, folder.clone())))
            .collect();
        // the rows' order, without counting the flagged messages it does not need
        Ok(rows(accounts, 0)
            .into_iter()
            .filter_map(|row| folders.remove(&row.folder))
            .collect())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use pe_store::{Account, AccountSettings, FolderInfo, SyncState};

    fn account(id: AccountId, email: &str) -> Account {
        Account {
            id,
            settings: AccountSettings {
                email: email.into(),
                name: "Ann".into(),
                ..Default::default()
            },
            account_name: email.split('@').nth(1).unwrap_or_default().into(),
        }
    }

    fn folder(id: FolderId, account: AccountId, path: &str, special: Option<&str>, unread: u64) -> Folder {
        Folder {
            id,
            account_id: account,
            info: FolderInfo {
                path: path.into(),
                name: path.rsplit('/').next().unwrap_or(path).into(),
                delimiter: Some("/".into()),
                special_use: special.map(str::to_string),
                selectable: true,
                ..Default::default()
            },
            state: SyncState::default(),
            total: unread,
            unread,
        }
    }

    fn shape(rows: &[TreeRow]) -> Vec<String> {
        rows.iter()
            .map(|row| format!("{}{:?} {}", "  ".repeat(row.depth), row.kind, row.label))
            .collect()
    }

    fn folders(account: AccountId, base: FolderId) -> Vec<Folder> {
        vec![
            folder(base + 1, account, "INBOX", Some("\\Inbox"), 2),
            folder(base + 2, account, "INBOX/Receipts", None, 1),
            folder(base + 3, account, "Sent", Some("\\Sent"), 0),
            folder(base + 4, account, "Junk", Some("\\Junk"), 5),
            folder(base + 5, account, "Projects", None, 0),
            folder(base + 6, account, "Projects/Alpha", None, 3),
        ]
    }

    #[test]
    fn one_account_starts_with_its_inbox_and_has_no_heading() {
        pe_i18n::set_language("en");
        let rows = rows(vec![(account(1, "ann@example.org"), folders(1, 0))], 4);
        assert_eq!(
            shape(&rows),
            [
                "Folder Inbox",
                "Flagged Flagged",
                "Folder Receipts",
                "Folder Sent Items",
                "Folder Junk E-mail",
                "Folder Projects",
                "  Folder Alpha",
            ]
        );
        // Flagged counts flagged messages, never bold; Projects hides Alpha's three when collapsed
        assert!(!rows[1].bold(true) && rows[1].unread == 4);
        assert_eq!((rows[5].parent, rows[5].hidden), (true, 3));
        assert!(!rows[0].parent, "the Inbox holds nothing now");
        assert!(rows.iter().all(|row| row.kind != TreeRowKind::Account));
        // New Folder from the Inbox or Flagged goes at the top; from Projects into it
        assert_eq!((rows[0].new_folder_account, rows[0].new_folder_parent), (1, 0));
        assert_eq!((rows[1].new_folder_account, rows[1].new_folder_parent), (1, 0));
        assert_eq!((rows[5].new_folder_account, rows[5].new_folder_parent), (1, 5));
        assert_eq!((rows[1].menu, rows[1].icon), (TreeMenu::None, "flagged"));
        assert_eq!(rows[0].menu, TreeMenu::Folder);
        assert_eq!((rows[5].shown(false), rows[5].shown(true)), (0, 3));
    }

    #[test]
    fn hidden_counts_every_level_below() {
        pe_i18n::set_language("en");
        let mut deep = folders(1, 0);
        deep.push(folder(7, 1, "Projects/Alpha/Beta", None, 2));
        deep.push(folder(8, 1, "Projects/Gamma", None, 1));
        let rows = rows(vec![(account(1, "ann@example.org"), deep)], 0);
        let at = |label: &str| rows.iter().find(|row| row.label == label).unwrap();
        assert_eq!(
            (at("Projects").hidden, at("Alpha").hidden, at("Beta").hidden),
            (6, 2, 0)
        );
        assert!(at("Alpha").parent && !at("Beta").parent && !at("Gamma").parent);
    }

    #[test]
    fn a_selection_survives_an_account_coming_and_going() {
        pe_i18n::set_language("en");
        let one = rows(vec![(account(1, "ann@example.org"), folders(1, 0))], 0);
        let two = rows(
            vec![
                (account(1, "ann@example.org"), folders(1, 0)),
                (account(2, "ann@work.example"), folders(2, 10)),
            ],
            0,
        );
        let at = |rows: &[TreeRow], key: &str| rows.iter().position(|row| row.key == key);
        // a folder keeps its key under All Inboxes or All Sent and as one account's own
        assert_eq!(reselect(&two, &one[0].key), Some(1));
        assert_eq!(reselect(&one, &two[1].key), Some(0));
        assert_eq!(reselect(&one, "folder:3"), at(&one, "folder:3"));
        // All Inboxes, All Sent or a heading gone: that account's Inbox, else the first
        assert_eq!(reselect(&one, "inboxes"), Some(0));
        assert_eq!(reselect(&one, "sent"), Some(0));
        assert_eq!(reselect(&one, "account:1"), Some(0));
        assert_eq!(reselect(&two, "account:2"), at(&two, "account:2"));
        assert_eq!(reselect(&one, "folder:99"), None);
        // a heading's menu, its New Folder at the account's top; All Inboxes only marks read, All Sent has no menu
        let heading = &two[at(&two, "account:1").unwrap()];
        assert_eq!(
            (heading.menu, heading.new_folder_account, heading.icon),
            (TreeMenu::Account, 1, "account")
        );
        assert_eq!((two[0].menu, two[0].new_folder_account), (TreeMenu::MarkRead, 0));
        let flagged = &two[at(&two, "flagged").unwrap()];
        assert_eq!(
            flagged.new_folder_account, 0,
            "Flagged of several accounts makes no folder"
        );
        let sent = &two[at(&two, "sent").unwrap()];
        assert_eq!(
            (sent.menu, sent.list, sent.icon),
            (TreeMenu::None, TreeList::AllSent, "sent")
        );
    }

    #[test]
    fn several_accounts_gather_inboxes_sent_and_drafts() {
        pe_i18n::set_language("en");
        let mut first = folders(1, 0);
        first.push(folder(7, 1, "Drafts", Some("\\Drafts"), 1));
        // listed after its parent, as servers list them
        first.insert(3, folder(8, 1, "Sent/2024", None, 2));
        let rows = rows(
            vec![
                (account(1, "ann@example.org"), first),
                (account(2, "ann@work.example"), folders(2, 10)),
            ],
            0,
        );
        assert_eq!(
            shape(&rows),
            [
                "AllInboxes All Inboxes",
                "  AccountInbox example.org",
                "  AccountInbox work.example",
                "AllSent All Sent",
                "  Folder example.org",
                "  Folder work.example",
                "AllDrafts All Drafts",
                "  Folder example.org",
                "Flagged Flagged",
                "Account example.org",
                "  Folder Receipts",
                "  Folder 2024",
                "  Folder Junk E-mail",
                "  Folder Projects",
                "    Folder Alpha",
                "Account work.example",
                "  Folder Receipts",
                "  Folder Junk E-mail",
                "  Folder Projects",
                "    Folder Alpha",
            ]
        );
        // All Inboxes counts both Inboxes, All Drafts its draft; a heading hides its folders' unread (not Junk E-mail's)
        assert_eq!(rows[0].unread, 4);
        assert_eq!((rows[6].unread, rows[6].hidden), (1, 0));
        assert_eq!(rows[1].title, "Inbox - example.org");
        assert_eq!(rows[4].title, "Sent Items - example.org");
        assert_eq!(rows[9].hidden, 6, "Receipts, 2024 and Alpha");
        // All Sent and All Drafts start closed and list their folders together, To first
        assert!(!rows[3].starts_open && rows[3].remembers_open && rows[0].starts_open);
        assert_eq!((rows[3].list, rows[4].list), (TreeList::AllSent, TreeList::Folder));
        assert_eq!(
            rows[4].new_folder_parent, 0,
            "a folder made from Sent Items goes to the account's top"
        );
        assert!(!rows[9].selectable && rows[9].reorders_accounts && rows[1].reorders_accounts);
        assert!(rows[1].drop_target && !rows[0].drop_target && !rows[9].drop_target && !rows[3].drop_target);
    }

    #[test]
    fn an_account_without_an_inbox_yet() {
        pe_i18n::set_language("en");
        let only = vec![folder(1, 1, "Archive", Some("\\Archive"), 0)];
        let rows = rows(vec![(account(1, "a@example.org"), only)], 0);
        assert_eq!(shape(&rows), ["Flagged Flagged", "Folder Archive"]);
        assert!(super::rows(Vec::new(), 0).is_empty());
    }
}
