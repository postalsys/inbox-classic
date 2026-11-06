//! The rows of the Move and Copy window, the same on every platform: the folders messages were moved or copied to
//! last under "Recent", then every account with its folders as the folder tree shows them; which can be chosen, which
//! is the one the messages are in; and what a filter typed over them leaves.

use pe_store::{AccountId, FolderId};
use unicode_normalization::UnicodeNormalization;

use crate::{Core, Result};

/// How many folders "Recent" lists
const RECENT: u64 = 3;

/// What a row of the Move and Copy window is
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TargetKind {
    /// "Recent", over the folders used last
    Heading,
    /// A folder used last, named with its account when there are several ("Archive (Work)")
    Recent,
    /// An account, over its folders
    Account,
    /// A folder of the account above it
    Folder,
}

/// A row of the Move and Copy window
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TargetRow {
    pub kind: TargetKind,
    /// The account of an account's or a folder's row
    pub account: AccountId,
    /// The folder of a folder's or a recent row, 0 otherwise
    pub folder: FolderId,
    /// What it says: "Inbox (current)", "Archive (Work)"
    pub label: String,
    /// How deep it is under its account (0 for the account and the rows of Recent)
    pub depth: u32,
    /// Its icon, as [`crate::folder_kind`] names it ("inbox", "archive", "" for a plain folder)
    pub icon: &'static str,
    /// Messages can go there: a folder that holds messages, not the one they are all in
    pub choosable: bool,
}

/// `text` for comparing what is typed: lowercase, without accents
fn plain(text: &str) -> String {
    text.nfd()
        .filter(|c| !unicode_normalization::char::is_combining_mark(*c))
        .flat_map(char::to_lowercase)
        .collect()
}

impl Core {
    /// The rows of the Move and Copy window for messages all in `current` (None for messages of several folders), what
    /// `filter` leaves of them: the folders whose names have it (accents and case aside), with the accounts and folders
    /// above them; "Recent" only while nothing is typed
    pub fn move_targets(&self, current: Option<FolderId>, filter: &str) -> Result<Vec<TargetRow>> {
        let accounts = self.accounts()?;
        let names: Vec<&str> = accounts.iter().map(|a| a.settings.name.as_str()).collect();
        let filter = plain(filter.trim());
        let mut rows = Vec::new();
        let mut all = Vec::new();
        for account in &accounts {
            let title = crate::account_title(&account.settings.name, &account.settings.email, &names);
            let folders = self.folders(account.id)?;
            let infos: Vec<&pe_store::FolderInfo> = folders.iter().map(|f| &f.info).collect();
            let depths = crate::tree_depths(&infos);
            let mut own = Vec::with_capacity(folders.len());
            for (folder, depth) in folders.iter().zip(depths) {
                let name = crate::folder_name(&folder.info);
                let is_current = current == Some(folder.id);
                own.push((
                    TargetRow {
                        kind: TargetKind::Folder,
                        account: account.id,
                        folder: folder.id,
                        label: if is_current {
                            format!("{name} (current)")
                        } else {
                            name.clone()
                        },
                        depth: depth as u32 + 1,
                        icon: crate::folder_kind(&folder.info),
                        choosable: folder.info.selectable && !is_current,
                    },
                    filter.is_empty() || plain(&name).contains(&filter),
                ));
            }
            all.push((account, title, own));
        }
        if filter.is_empty() {
            let recent: Vec<TargetRow> = self
                .recent_targets(RECENT)?
                .into_iter()
                .filter_map(|id| {
                    all.iter().find_map(|(_, title, own)| {
                        own.iter()
                            .find(|(row, _)| row.folder == id && row.choosable)
                            .map(|(row, _)| TargetRow {
                                kind: TargetKind::Recent,
                                depth: 0,
                                label: if accounts.len() > 1 {
                                    format!("{} ({title})", row.label)
                                } else {
                                    row.label.clone()
                                },
                                ..row.clone()
                            })
                    })
                })
                .collect();
            if !recent.is_empty() {
                rows.push(TargetRow {
                    kind: TargetKind::Heading,
                    account: 0,
                    folder: 0,
                    label: "Recent".into(),
                    depth: 0,
                    icon: "",
                    choosable: false,
                });
                rows.extend(recent);
            }
        }
        for (account, title, own) in all {
            // a folder that matches keeps the folders above it, for where it is
            let mut keep: Vec<bool> = own.iter().map(|(_, matches)| *matches).collect();
            for i in (0..own.len()).rev() {
                if keep[i] {
                    let mut depth = own[i].0.depth;
                    for j in (0..i).rev() {
                        if own[j].0.depth < depth {
                            keep[j] = true;
                            depth = own[j].0.depth;
                        }
                    }
                }
            }
            if !keep.iter().any(|k| *k) {
                continue;
            }
            rows.push(TargetRow {
                kind: TargetKind::Account,
                account: account.id,
                folder: 0,
                label: title,
                depth: 0,
                icon: "",
                choosable: false,
            });
            rows.extend(own.into_iter().zip(keep).filter(|(_, k)| *k).map(|((row, _), _)| row));
        }
        Ok(rows)
    }
}

#[cfg(test)]
mod tests {
    use super::plain;

    #[test]
    fn typed_text_compares_without_accents() {
        assert_eq!(plain("Élèves Ärchive"), "eleves archive");
        assert!(plain("Gelöschte Objekte").contains(&plain("gelosch")));
    }
}
