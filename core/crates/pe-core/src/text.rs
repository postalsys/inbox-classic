//! Words and numbers the windows of every platform show the same way, made here so the three agree, in the language in
//! use (pe-i18n)

use pe_i18n::{Text, tr, tr_args};

/// A size as the windows show it: `512 bytes`, `13 KB` (rounded up, as Explorer does), `2.4 MB`
pub fn format_size(bytes: u64) -> String {
    if bytes < 1024 {
        tr_args(Text::SizeBytes, &[("count", bytes.into())])
    } else if bytes < 1024 * 1024 {
        tr_args(Text::SizeKb, &[("size", (&bytes.div_ceil(1024).to_string()).into())])
    } else {
        let size = format!("{:.1}", bytes as f64 / (1024.0 * 1024.0)).replace('.', &tr(Text::DecimalSeparator));
        tr_args(Text::SizeMb, &[("size", (&size).into())])
    }
}

/// "1 message", "3 messages"
pub fn messages(count: u64) -> String {
    tr_args(Text::Messages, &[("count", count.into())])
}

/// What the status bar says once messages are saved as files into the folder `place`, by its name: "Saved 3 messages
/// to Desktop"
pub fn saved_text(count: u64, place: &std::path::Path) -> String {
    let name = place
        .file_name()
        .map_or_else(|| place.display().to_string(), |n| n.to_string_lossy().into_owned());
    tr_args(
        Text::SavedTo,
        &[
            ("messages", (&messages(count)).into()),
            ("count", count.into()),
            ("folder", (&name).into()),
        ],
    )
}

/// What the status bar says while messages not downloaded yet come for files or a forward: "Downloading 3 messages..."
pub fn downloading_text(count: u64) -> String {
    tr_args(
        Text::DownloadingMessages,
        &[("messages", (&messages(count)).into()), ("count", count.into())],
    )
}

/// The counts of a list in the status bar: "12 messages, 3 unread" for a folder, "12 found, 3 unread" for a search
/// ("No messages found" for none), and ", 2 selected" when more than one is
pub fn list_counts(total: u64, unread: u64, selected: u64, searching: bool) -> String {
    if searching && total == 0 {
        return tr(Text::ListCountsNone);
    }
    let messages = messages(total);
    let args = [
        ("messages", (&messages).into()),
        ("found", total.into()),
        ("unread", unread.into()),
        ("selected", selected.into()),
    ];
    let text = match (searching, selected > 1) {
        (false, false) => Text::ListCounts,
        (false, true) => Text::ListCountsSelected,
        (true, false) => Text::ListCountsFound,
        (true, true) => Text::ListCountsFoundSelected,
    };
    tr_args(text, &args)
}

/// "Name <address>", the address alone when the name is empty or the same: how From and the account menus show an
/// account
pub fn account_label(name: &str, email: &str) -> String {
    let name = name.trim();
    if name.is_empty() || name == email {
        email.to_string()
    } else {
        format!("{name} <{email}>")
    }
}

/// What the folder tree calls the account named `name` among accounts with `names`: its name, with its address added
/// when another one has the same name, the address alone without a name
pub fn account_title(name: &str, email: &str, names: &[&str]) -> String {
    let name = name.trim();
    if name.is_empty() {
        return email.to_string();
    }
    let same = names
        .iter()
        .filter(|other| other.trim().eq_ignore_ascii_case(name))
        .count();
    if same > 1 {
        format!("{name} ({email})")
    } else {
        name.to_string()
    }
}

/// The name a folder shows under: the one Outlook Express gives a special folder (Sent Items, Deleted Items), the
/// folder's own name otherwise
pub fn folder_name(folder: &pe_store::FolderInfo) -> String {
    use pe_imap::SpecialUse;
    match folder.special_use.as_deref().and_then(SpecialUse::from_flag) {
        Some(SpecialUse::Inbox) => tr(Text::FolderInbox),
        Some(SpecialUse::Sent) => tr(Text::FolderSent),
        Some(SpecialUse::Trash) => tr(Text::FolderDeleted),
        Some(SpecialUse::Drafts) => tr(Text::FolderDrafts),
        Some(SpecialUse::Junk) => tr(Text::FolderJunk),
        Some(SpecialUse::Archive) => tr(Text::FolderArchive),
        _ => folder.name.clone(),
    }
}

/// The unread messages a folder tree hides when a row is collapsed: for each folder (in tree order, as
/// [`crate::Core::folders`] lists them, with the [`crate::tree_depths`] of their infos) the unread messages of the folders
/// under it, and for the account the unread messages of all its folders. Junk E-mail and Deleted Items count for neither,
/// so a spam folder does not keep a collapsed account bold. A collapsed row shows its own unread messages plus these; an
/// expanded one its own alone.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct HiddenUnread {
    /// Of each folder, in the order given
    pub below: Vec<u64>,
    /// Of the whole account
    pub account: u64,
}

pub fn hidden_unread(folders: &[pe_store::Folder], depths: &[usize]) -> HiddenUnread {
    use pe_imap::SpecialUse;
    let counted: Vec<u64> = folders
        .iter()
        .map(
            |folder| match folder.info.special_use.as_deref().and_then(SpecialUse::from_flag) {
                Some(SpecialUse::Junk | SpecialUse::Trash) => 0,
                _ => folder.unread,
            },
        )
        .collect();
    let depth = |i: usize| depths.get(i).copied().unwrap_or(0);
    let below = (0..folders.len())
        .map(|i| {
            (i + 1..folders.len())
                .take_while(|&j| depth(j) > depth(i))
                .map(|j| counted[j])
                .sum()
        })
        .collect();
    HiddenUnread {
        below,
        account: counted.iter().sum(),
    }
}

/// What kind of special folder a folder is, in a word for agents (`inbox`, `sent`, `drafts`, `deleted`, `junk`,
/// `archive`), empty for another folder
pub fn folder_kind(folder: &pe_store::FolderInfo) -> &'static str {
    use pe_imap::SpecialUse;
    match folder.special_use.as_deref().and_then(SpecialUse::from_flag) {
        Some(SpecialUse::Inbox) => "inbox",
        Some(SpecialUse::Sent) => "sent",
        Some(SpecialUse::Drafts) => "drafts",
        Some(SpecialUse::Trash) => "deleted",
        Some(SpecialUse::Junk) => "junk",
        Some(SpecialUse::Archive) => "archive",
        _ if folder.path.eq_ignore_ascii_case("INBOX") => "inbox",
        _ => "",
    }
}

/// What the windows say beside Try Again over a message that could not be downloaded
pub fn retry_note() -> String {
    tr(Text::ReaderRetryNote)
}

/// What the reading pane shows when it shows no message
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ReaderState<'a> {
    /// No message is selected
    NoMessage,
    /// The message selected is being downloaded ([`crate::Core::open_message`])
    Downloading,
    /// It could not be downloaded ([`crate::Event::MessageFailed`]): `kind` and the server's `reason`
    Failed { kind: crate::FailureKind, reason: &'a str },
}

/// The page of the reading pane for `state` (pe_html::status_page): the same words on every platform. A failure says
/// what happened; the windows put [`retry_note`] and Try Again over it, and try again on their own once the account
/// syncs.
pub fn reader_page(state: ReaderState) -> String {
    use crate::FailureKind;
    match state {
        ReaderState::NoMessage => pe_html::status_page(&tr(Text::ReaderNoMessage), "", false),
        ReaderState::Downloading => {
            pe_html::status_page(&tr(Text::ReaderDownloading), &tr(Text::ReaderDownloadingDetail), true)
        }
        ReaderState::Failed { kind, reason } => {
            let reason = reason.trim().trim_end_matches('.');
            // what happened, and for a sign-in what to do; what happens next is beside Try Again
            let text = match kind {
                FailureKind::Network => Text::ReaderFailedNetwork,
                FailureKind::Authentication => Text::ReaderFailedSignIn,
                FailureKind::Security => Text::ReaderFailedSecurity,
                FailureKind::Other => Text::ReaderFailedOther,
            };
            let detail = tr_args(text, &[("reason", reason.into())]);
            pe_html::status_page(&tr(Text::ReaderFailed), &detail, false)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn folder(path: &str, special_use: Option<&str>, unread: u64) -> pe_store::Folder {
        pe_store::Folder {
            id: 0,
            account_id: 1,
            info: pe_store::FolderInfo {
                path: path.into(),
                name: path.rsplit('/').next().unwrap_or(path).into(),
                delimiter: Some("/".into()),
                flags: Vec::new(),
                special_use: special_use.map(Into::into),
                subscribed: true,
                selectable: true,
            },
            state: Default::default(),
            total: unread,
            unread,
        }
    }

    #[test]
    fn a_collapsed_row_counts_what_it_hides() {
        let folders = [
            folder("INBOX", Some("\\Inbox"), 3),
            folder("INBOX/Lists", None, 2),
            folder("INBOX/Lists/Rust", None, 4),
            folder("Junk", Some("\\Junk"), 50),
            folder("Projects", None, 0),
            folder("Projects/Old", None, 1),
            folder("Projects/Spam", Some("\\Junk"), 9),
            folder("Trash", Some("\\Trash"), 7),
        ];
        let infos: Vec<_> = folders.iter().map(|f| &f.info).collect();
        let depths = crate::tree_depths(&infos);
        let hidden = hidden_unread(&folders, &depths);
        assert_eq!(hidden.below, [6, 4, 0, 0, 1, 0, 0, 0]);
        // Junk and Deleted Items do not light up the account
        assert_eq!(hidden.account, 10);
        assert_eq!(hidden_unread(&[], &[]), HiddenUnread::default());
    }

    #[test]
    fn the_reading_pane_says_why() {
        assert!(reader_page(ReaderState::NoMessage).contains("There is no message selected."));
        let downloading = reader_page(ReaderState::Downloading);
        assert!(downloading.contains("Downloading the message") && downloading.contains("class=\"spin\""));
        let offline = reader_page(ReaderState::Failed {
            kind: crate::FailureKind::Network,
            reason: "connection refused.",
        });
        assert!(offline.contains("could not be downloaded") && offline.contains("(connection refused)"));
        assert!(!offline.contains("class=\"spin\""));
        let refused = reader_page(ReaderState::Failed {
            kind: crate::FailureKind::Authentication,
            reason: "AUTHENTICATIONFAILED",
        });
        assert!(refused.contains("did not accept the sign-in"));
    }

    #[test]
    fn accounts_with_the_same_name_are_told_apart_in_the_tree() {
        let names = ["Ann", "ann ", "Work"];
        assert_eq!(account_title("Ann", "ann@hotmail.com", &names), "Ann (ann@hotmail.com)");
        assert_eq!(account_title("Work", "ann@work.example", &names), "Work");
        assert_eq!(account_title(" ", "ann@example.com", &names), "ann@example.com");
    }

    #[test]
    fn accounts_are_labeled_by_name_and_address() {
        assert_eq!(account_label("Ann", "ann@example.com"), "Ann <ann@example.com>");
        assert_eq!(account_label("  ", "ann@example.com"), "ann@example.com");
        assert_eq!(account_label("ann@example.com", "ann@example.com"), "ann@example.com");
    }

    #[test]
    fn special_folders_have_their_usual_names() {
        let folder = |name: &str, special: Option<&str>| pe_store::FolderInfo {
            path: name.into(),
            name: name.into(),
            special_use: special.map(str::to_string),
            ..Default::default()
        };
        assert_eq!(folder_name(&folder("Sent", Some("\\Sent"))), "Sent Items");
        assert_eq!(folder_name(&folder("Trash", Some("\\Trash"))), "Deleted Items");
        assert_eq!(folder_name(&folder("Spam", Some("\\Junk"))), "Junk E-mail");
        assert_eq!(folder_name(&folder("Archive", Some("\\Archive"))), "Archive");
        assert_eq!(folder_name(&folder("Projects", None)), "Projects");
    }

    #[test]
    fn sizes() {
        assert_eq!(format_size(0), "0 bytes");
        assert_eq!(format_size(1023), "1023 bytes");
        assert_eq!(format_size(1024), "1 KB");
        assert_eq!(format_size(1025), "2 KB");
        assert_eq!(format_size(1024 * 1024 - 1), "1024 KB");
        assert_eq!(format_size(1024 * 1024), "1.0 MB");
        assert_eq!(format_size(2_500_000), "2.4 MB");
    }
}
