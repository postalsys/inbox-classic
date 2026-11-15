//! The folder list of the main window, row by row, for the three apps to draw as it is.
//!
//! It starts with the Inbox. One account: Inbox, Flagged, then the rest of its folders, with no heading for the
//! account. Several accounts: All Inboxes (each account's Inbox under it, named after the account), Flagged, then each
//! account's heading with its folders but the Inbox. The folders an Inbox holds move up a level: they come first among
//! the account's folders, as the Inbox has no row of its own to hold them under an account.

use pe_imap::SpecialUse;
use pe_store::{AccountId, Folder, FolderId};

use crate::{Core, Result, account_titles, emptiable, text};

/// What a row of the folder list is
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TreeRowKind {
    /// Every account's Inbox in one list (several accounts)
    AllInboxes,
    /// An account's Inbox under All Inboxes, named after the account (several accounts)
    AccountInbox,
    /// Every flagged message of every account
    Flagged,
    /// An account's heading, with its folders under it (several accounts)
    Account,
    /// A folder: one account's Inbox (with one account), or any other folder
    Folder,
}

/// One row of the folder list, in its order
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TreeRow {
    pub kind: TreeRowKind,
    /// The account it belongs to, 0 for All Inboxes and Flagged
    pub account: AccountId,
    /// The folder it shows, 0 for All Inboxes, Flagged and a heading
    pub folder: FolderId,
    /// How far in: 0 at the top
    pub depth: usize,
    /// What it says
    pub label: String,
    /// What the folder bar and the window's title say when it is chosen: "Inbox - Gmail" for an account's Inbox
    /// under All Inboxes, else its label
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
    /// It can be dragged up and down among its own kind to order the accounts: a heading, or an Inbox under All
    /// Inboxes
    pub reorders_accounts: bool,
    /// The kind of special folder it is, in a word for its icon (`inbox`, `sent`, `drafts`, `deleted`, `junk`,
    /// `archive`, `flagged` for a server's own flagged folder, `all` for one of all mail), empty for any other
    pub icon: &'static str,
}

impl TreeRow {
    /// It is shown bold: unread mail in it, or (collapsed) under it; Flagged never is
    pub fn bold(&self, collapsed: bool) -> bool {
        self.kind != TreeRowKind::Flagged && self.unread + if collapsed { self.hidden } else { 0 } > 0
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

fn is_inbox(folder: &Folder) -> bool {
    text::folder_kind(&folder.info) == "inbox"
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
    for (_, depth) in inbox.iter_mut() {
        *depth = depth.saturating_sub(inbox_depth);
    }
    for (_, depth) in inbox.iter_mut().skip(1) {
        *depth -= 1;
    }
    inbox.extend(rows);
    inbox
}

/// A folder's row
fn folder_row(folder: &Folder, depth: usize) -> TreeRow {
    let label = text::folder_name(&folder.info);
    TreeRow {
        kind: TreeRowKind::Folder,
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
        icon: icon(folder),
    }
}

/// Each row's `hidden` and `parent` from the rows under it, by their depths
fn fill_below(rows: &mut [TreeRow], counts: &[u64]) {
    for i in 0..rows.len() {
        let below: Vec<usize> = (i + 1..rows.len())
            .take_while(|&j| rows[j].depth > rows[i].depth)
            .collect();
        rows[i].parent = !below.is_empty();
        rows[i].hidden = below.iter().map(|&j| counts[j]).sum();
    }
}

/// The rows of the folder list of `accounts` (each with its folders, in the accounts' order) and the number of
/// flagged messages
pub(crate) fn rows(accounts: Vec<(pe_store::Account, Vec<Folder>)>, flagged: u64) -> Vec<TreeRow> {
    if accounts.is_empty() {
        return Vec::new();
    }
    let titles = account_titles(&accounts.iter().map(|(a, _)| a.clone()).collect::<Vec<_>>());
    let several = accounts.len() > 1;
    let mut rows = Vec::new();
    // what each row adds to a collapsed row above it
    let mut counts = Vec::new();
    let flagged_row = TreeRow {
        kind: TreeRowKind::Flagged,
        account: 0,
        folder: 0,
        depth: 0,
        label: pe_i18n::tr(pe_i18n::Text::UiFlaggedFolder),
        title: pe_i18n::tr(pe_i18n::Text::UiFlaggedFolder),
        unread: flagged,
        hidden: 0,
        parent: false,
        selectable: true,
        drop_target: false,
        reorders_accounts: false,
        icon: "",
    };
    let ordered: Vec<(AccountId, Vec<(Folder, usize)>)> = accounts
        .into_iter()
        .map(|(account, folders)| (account.id, ordered(folders)))
        .collect();
    if !several {
        let (_, folders) = &ordered[0];
        let mut rest = folders.iter();
        if let Some((folder, depth)) = folders.first().filter(|(folder, _)| is_inbox(folder)) {
            rows.push(folder_row(folder, *depth));
            counts.push(counted(folder));
            rest.next();
        }
        rows.push(flagged_row);
        counts.push(0);
        for (folder, depth) in rest {
            rows.push(folder_row(folder, *depth));
            counts.push(counted(folder));
        }
        fill_below(&mut rows, &counts);
        return rows;
    }
    let all_inboxes = pe_i18n::tr(pe_i18n::Text::UiAllInboxes);
    rows.push(TreeRow {
        kind: TreeRowKind::AllInboxes,
        account: 0,
        folder: 0,
        depth: 0,
        label: all_inboxes.clone(),
        title: all_inboxes,
        unread: 0,
        hidden: 0,
        parent: false,
        selectable: true,
        drop_target: false,
        reorders_accounts: false,
        icon: "inbox",
    });
    counts.push(0);
    for ((account, folders), title) in ordered.iter().zip(&titles) {
        if let Some((inbox, _)) = folders.first().filter(|(folder, _)| is_inbox(folder)) {
            rows.push(TreeRow {
                kind: TreeRowKind::AccountInbox,
                account: *account,
                depth: 1,
                label: title.clone(),
                title: format!("{} - {title}", text::folder_name(&inbox.info)),
                drop_target: inbox.info.selectable,
                reorders_accounts: true,
                ..folder_row(inbox, 1)
            });
            counts.push(counted(inbox));
        }
    }
    rows.push(flagged_row);
    counts.push(0);
    for ((account, folders), title) in ordered.iter().zip(&titles) {
        rows.push(TreeRow {
            kind: TreeRowKind::Account,
            account: *account,
            folder: 0,
            depth: 0,
            label: title.clone(),
            title: title.clone(),
            unread: 0,
            hidden: 0,
            parent: false,
            selectable: false,
            drop_target: false,
            reorders_accounts: true,
            icon: "",
        });
        counts.push(0);
        let skip = usize::from(folders.first().is_some_and(|(folder, _)| is_inbox(folder)));
        for (folder, depth) in &folders[skip..] {
            let mut row = folder_row(folder, depth + 1);
            // which account's, in the folder bar and the title: "Archive - Work"
            row.title = format!("{} - {title}", row.label);
            rows.push(row);
            counts.push(counted(folder));
        }
    }
    fill_below(&mut rows, &counts);
    // All Inboxes counts its Inboxes as a folder does (it is no folder of its own)
    if let Some(row) = rows.iter_mut().find(|row| row.kind == TreeRowKind::AllInboxes) {
        row.unread = row.hidden;
        row.hidden = 0;
    }
    rows
}

impl Core {
    /// The folder list of the main window, row by row in its order ([`TreeRow`])
    pub fn folder_tree(&self) -> Result<Vec<TreeRow>> {
        let store = self.store();
        let mut accounts = Vec::new();
        for account in store.accounts()? {
            let folders = store.folders(account.id)?;
            accounts.push((account, folders));
        }
        drop(store);
        Ok(rows(accounts, self.flagged_count()?))
    }

    /// Every folder in the order the folder list shows them (an Inbox once): the order Next Unread goes in
    pub(crate) fn folder_order(&self) -> Result<Vec<FolderId>> {
        let mut order: Vec<FolderId> = Vec::new();
        for row in self.folder_tree()? {
            if row.folder != 0 && !order.contains(&row.folder) {
                order.push(row.folder);
            }
        }
        Ok(order)
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
    }

    #[test]
    fn several_accounts_keep_the_inboxes_under_all_inboxes() {
        pe_i18n::set_language("en");
        let rows = rows(
            vec![
                (account(1, "ann@example.org"), folders(1, 0)),
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
                "Flagged Flagged",
                "Account example.org",
                "  Folder Receipts",
                "  Folder Sent Items",
                "  Folder Junk E-mail",
                "  Folder Projects",
                "    Folder Alpha",
                "Account work.example",
                "  Folder Receipts",
                "  Folder Sent Items",
                "  Folder Junk E-mail",
                "  Folder Projects",
                "    Folder Alpha",
            ]
        );
        // All Inboxes counts both Inboxes; a heading hides its folders' unread (not Junk E-mail's)
        assert_eq!(rows[0].unread, 4);
        assert_eq!(rows[1].title, "Inbox - example.org");
        assert_eq!(rows[6].title, "Sent Items - example.org");
        assert_eq!(rows[4].hidden, 4);
        assert!(!rows[4].selectable && rows[4].reorders_accounts && rows[1].reorders_accounts);
        assert!(rows[1].drop_target && !rows[0].drop_target && !rows[4].drop_target);
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
