//! Words and numbers the windows of every platform show the same way, made here so the three agree, in the language in
//! use (pe-i18n)

use pe_i18n::{Text, tr, tr_args};

/// The limits of downloaded messages Settings offers, in megabytes
pub const DOWNLOAD_LIMITS_MB: [u64; 6] = [250, 500, 1024, 2048, 5120, 10240];

/// A limit of [`DOWNLOAD_LIMITS_MB`] as Settings shows it: "500 MB", "2 GB"
pub fn download_limit_text(megabytes: u64) -> String {
    if megabytes >= 1024 && megabytes.is_multiple_of(1024) {
        tr_args(Text::SizeGb, &[("size", (&(megabytes / 1024).to_string()).into())])
    } else {
        tr_args(Text::SizeMb, &[("size", (&megabytes.to_string()).into())])
    }
}

/// The place in [`DOWNLOAD_LIMITS_MB`] that Settings shows for a limit: its own, or the nearest one below it
pub fn download_limit_index(megabytes: u64) -> usize {
    DOWNLOAD_LIMITS_MB
        .iter()
        .rposition(|&choice| choice <= megabytes)
        .unwrap_or(0)
}

/// The waits before a message goes that Options offers, in seconds (Undo Send)
pub const SEND_DELAYS: [u64; 5] = [0, 5, 10, 20, 30];

/// A wait of [`SEND_DELAYS`] as Options shows it: "Off", "10 seconds"
pub fn send_delay_text(seconds: u64) -> String {
    if seconds == 0 {
        tr(Text::SendDelayOff)
    } else {
        tr_args(Text::SendDelaySeconds, &[("count", seconds.into())])
    }
}

/// The place in [`SEND_DELAYS`] that Options shows for a wait: its own, or the nearest one below it
pub fn send_delay_index(seconds: u64) -> usize {
    SEND_DELAYS.iter().rposition(|&choice| choice <= seconds).unwrap_or(0)
}

/// The initials the list shows for a sender without a picture: the first letters of the first and the last word of
/// the name ("Ann Lee", "Lee, Ann" and "Ann B. Lee" give AL), one for a name of one word (a Chinese name gives its first
/// character), else the first letter of the address; empty when there is no letter (an emoji for a name)
pub fn initials(name: &str, address: &str) -> String {
    let words = |text: &str| -> Vec<char> {
        text.split(|c: char| c.is_whitespace() || matches!(c, '"' | '\'' | '(' | ')' | '<' | '>' | ',' | ';'))
            .filter_map(|word| word.chars().find(|c| c.is_alphabetic()))
            .collect()
    };
    // a comment in parentheses ("Ann Lee (Shop)") is no part of the name
    let mut bare = String::new();
    let mut depth = 0usize;
    for c in name.chars() {
        match c {
            '(' => depth += 1,
            ')' => depth = depth.saturating_sub(1),
            _ if depth == 0 => bare.push(c),
            _ => {}
        }
    }
    let name = bare.as_str();
    // "Lee, Ann": the given name first
    let ordered = match name.split_once(',') {
        Some((last, first)) if !first.trim().is_empty() && !last.trim().is_empty() => format!("{first} {last}"),
        _ => name.to_string(),
    };
    let letters = words(&ordered);
    let chosen: Vec<char> = match letters.as_slice() {
        [] => address.chars().find(|c| c.is_alphabetic()).into_iter().collect(),
        [one] => vec![*one],
        [first, .., last] => vec![*first, *last],
    };
    // one letter each, as wide as the circle holds ("ß" is no "SS")
    chosen.into_iter().filter_map(|c| c.to_uppercase().next()).collect()
}

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

/// What the status bar says while a large message opened is downloaded: "Downloading 4.2 MB of 15.0 MB"
pub fn download_progress_text(done: u64, total: u64) -> String {
    tr_args(
        Text::DownloadProgress,
        &[
            ("done", (&format_size(done)).into()),
            ("total", (&format_size(total)).into()),
        ],
    )
}

/// What the status bar says once a large message opened is all here: "Downloaded 15.0 MB"
pub fn download_done_text(size: u64) -> String {
    tr_args(Text::DownloadDone, &[("size", (&format_size(size)).into())])
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

/// A subject in the quotes of the language ("“Plans”"), or "(no subject)"
pub fn quoted_subject(subject: &str) -> String {
    if subject.is_empty() {
        tr(Text::UiNoSubject)
    } else {
        tr_args(Text::UiQuoted, &[("subject", subject.into())])
    }
}

/// The title and the text of the notification of new mail (`count` messages, the newest from `from` about
/// `subject`): who it is from over its subject, or how many over the newest; a watched conversation's says so in the
/// title
pub(crate) fn new_mail_words(count: usize, from: &str, subject: &str, watched: bool) -> (String, String) {
    let no_subject = tr(Text::UiNoSubject);
    let subject = if subject.is_empty() {
        no_subject.as_str()
    } else {
        subject
    };
    let newest = || {
        tr_args(
            Text::UiNewestFrom,
            &[("sender", from.into()), ("subject", subject.into())],
        )
    };
    match (watched, count <= 1) {
        (true, true) => (tr(Text::UiWatchedConversation), format!("{from}\n{subject}")),
        (true, false) => (tr(Text::UiWatchedConversation), newest()),
        (false, true) => (from.to_string(), subject.to_string()),
        (false, false) => (tr_args(Text::UiNewMessages, &[("count", count.into())]), newest()),
    }
}

/// A reason the core gives, written to follow "Work: " in the status bar ("the Inbox and the special folders can not
/// be renamed or deleted"), as a sentence of its own for an alert: its first letter capital, a full stop at its end
pub fn sentence(reason: &str) -> String {
    let reason = reason.trim();
    let mut chars = reason.chars();
    let Some(first) = chars.next() else {
        return String::new();
    };
    let mut text: String = first.to_uppercase().chain(chars).collect();
    if !text.ends_with(['.', '!', '?', '\u{2026}']) {
        text.push('.');
    }
    text
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

/// What an account is called among others: its own name for the folder list ("Gmail") when it has one, the name on
/// its mail otherwise, its address when it has neither
pub fn account_shown_name<'a>(account_name: &'a str, name: &'a str, email: &'a str) -> &'a str {
    [account_name.trim(), name.trim()]
        .into_iter()
        .find(|shown| !shown.is_empty())
        .unwrap_or(email)
}

/// What the folder tree, All Inboxes and the lists of folders call each of the accounts, in their order: the shown
/// name (`account_shown_name`), with the address added where two accounts are shown the same
pub fn account_titles(accounts: &[pe_store::Account]) -> Vec<String> {
    let shown: Vec<&str> = accounts
        .iter()
        .map(|a| account_shown_name(&a.account_name, &a.settings.name, &a.settings.email))
        .collect();
    accounts
        .iter()
        .zip(&shown)
        .map(|(a, name)| account_title(name, &a.settings.email, &shown))
        .collect()
}

/// The account name a new account starts with: its provider's ("Gmail", "Outlook.com", "iCloud") for an address of a
/// provider that people know by name, the address's domain otherwise ("example.com"); the user can change it
pub fn default_account_name(email: &str) -> String {
    let domain = email
        .rsplit_once('@')
        .map(|(_, domain)| domain.trim().trim_end_matches('.').to_lowercase())
        .unwrap_or_default();
    let first = domain.split('.').next().unwrap_or_default();
    let provider = match domain.as_str() {
        "gmail.com" | "googlemail.com" => Some("Gmail"),
        "outlook.com" | "hotmail.com" | "live.com" | "msn.com" => Some("Outlook.com"),
        "icloud.com" | "me.com" | "mac.com" => Some("iCloud"),
        "aol.com" => Some("AOL"),
        "proton.me" | "protonmail.com" | "pm.me" => Some("Proton Mail"),
        "fastmail.com" | "fastmail.fm" => Some("Fastmail"),
        "zoho.com" | "zohomail.com" => Some("Zoho Mail"),
        "mail.ru" => Some("Mail.ru"),
        _ => match first {
            // the same provider under a country's domain: yahoo.co.uk, outlook.de, gmx.net, yandex.ru
            "yahoo" | "ymail" => Some("Yahoo"),
            "outlook" | "hotmail" | "live" => Some("Outlook.com"),
            "gmx" => Some("GMX"),
            "yandex" => Some("Yandex"),
            "web" if domain == "web.de" => Some("WEB.DE"),
            _ => None,
        },
    };
    provider.map(str::to_string).unwrap_or(domain)
}

/// What the folder tree calls the account shown as `name` among accounts shown as `names`: its name, with its address
/// added when another one has the same name, the address alone without a name
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
    /// The message selected is being downloaded ([`crate::Core::open_message`]); how large it is, when known
    Downloading { size: Option<u64> },
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
        ReaderState::Downloading { size } => {
            let detail = match size {
                Some(size) => tr_args(Text::ReaderDownloadingSize, &[("size", (&format_size(size)).into())]),
                None => tr(Text::ReaderDownloadingDetail),
            };
            pe_html::status_page(&tr(Text::ReaderDownloading), &detail, true)
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
mod download_limit_tests {
    use super::*;

    #[test]
    fn limits_are_said_in_megabytes_or_gigabytes() {
        assert_eq!(download_limit_text(500), "500 MB");
        assert_eq!(download_limit_text(1024), "1 GB");
        assert_eq!(download_limit_text(10240), "10 GB");
        assert_eq!(download_limit_index(1024), 2);
        assert_eq!(download_limit_index(3000), 3);
        assert_eq!(download_limit_index(50), 0);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn send_delays_in_words() {
        assert_eq!(send_delay_text(0), "Off");
        assert_eq!(send_delay_text(10), "10 seconds");
        assert_eq!(send_delay_index(10), 2);
        assert_eq!(send_delay_index(7), 1);
        assert_eq!(send_delay_index(99), 4);
    }

    #[test]
    fn initials_of_senders() {
        assert_eq!(initials("Ann Lee", "ann@example.com"), "AL");
        assert_eq!(initials("Ann B. Lee", ""), "AL");
        assert_eq!(initials("Lee, Ann", ""), "AL");
        assert_eq!(initials("\"Ann Lee\"", ""), "AL");
        assert_eq!(initials("Ann", ""), "A");
        assert_eq!(initials("", "mari@example.com"), "M");
        assert_eq!(initials("", "123@example.com"), "E");
        assert_eq!(initials("Õie Sääsk", ""), "ÕS");
        assert_eq!(initials("Иван Петров", ""), "ИП");
        assert_eq!(initials("Γιώργος Παπαδόπουλος", ""), "ΓΠ");
        assert_eq!(initials("王小明", ""), "王");
        assert_eq!(initials("ann lee (Shop)", ""), "AL");
        assert_eq!(initials("🎉", "news@shop.example"), "N");
        assert_eq!(initials("🎉", ""), "");
        assert_eq!(initials("ß", ""), "S");
    }

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
    fn new_mail_notification_words() {
        let words = |count, subject, watched| new_mail_words(count, "Pat Doe", subject, watched);
        assert_eq!(words(1, "Trip", false), ("Pat Doe".into(), "Trip".into()));
        assert_eq!(
            words(1, "Re: Trip", true),
            ("Watched conversation".into(), "Pat Doe\nRe: Trip".into())
        );
        assert_eq!(words(2, "Trip", true).0, "Watched conversation");
        assert_eq!(words(2, "", true).1, "Latest message from Pat Doe: (no subject)");
        assert_eq!(
            words(3, "Trip", false),
            ("3 new messages".into(), "Latest message from Pat Doe: Trip".into())
        );
    }

    #[test]
    fn the_reading_pane_says_why() {
        assert!(reader_page(ReaderState::NoMessage).contains("There is no message selected."));
        let downloading = reader_page(ReaderState::Downloading { size: None });
        assert!(
            reader_page(ReaderState::Downloading {
                size: Some(2 * 1024 * 1024)
            })
            .contains("The message is 2.0 MB.")
        );
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
    fn an_account_name_of_its_own_comes_first() {
        let account = |account_name: &str, name: &str, email: &str| pe_store::Account {
            id: 1,
            settings: pe_store::AccountSettings {
                name: name.into(),
                email: email.into(),
                ..Default::default()
            },
            account_name: account_name.into(),
        };
        let accounts = [
            account("Gmail", "Andris Reinman", "andris@gmail.com"),
            account("", "Andris Reinman", "andris@postalsys.com"),
            account("", "", "support@postalsys.com"),
        ];
        assert_eq!(
            account_titles(&accounts),
            ["Gmail", "Andris Reinman", "support@postalsys.com"]
        );
        // two of the same name, whatever made it, are told apart by their addresses
        let same = [
            account("Work", "Ann", "ann@work.example"),
            account("", "Work", "ann@other.example"),
        ];
        assert_eq!(
            account_titles(&same),
            ["Work (ann@work.example)", "Work (ann@other.example)"]
        );
    }

    #[test]
    fn a_reason_becomes_a_sentence() {
        assert_eq!(
            sentence("the Inbox and the special folders can not be renamed or deleted"),
            "The Inbox and the special folders can not be renamed or deleted."
        );
        assert_eq!(
            sentence("\"x\" is not an e-mail address"),
            "\"x\" is not an e-mail address."
        );
        assert_eq!(sentence("Already one."), "Already one.");
        assert_eq!(sentence("ärger?"), "Ärger?");
        assert_eq!(sentence("  "), "");
    }

    #[test]
    fn a_new_account_is_named_by_its_provider_or_domain() {
        assert_eq!(default_account_name("ann@gmail.com"), "Gmail");
        assert_eq!(default_account_name("ann@Hotmail.com"), "Outlook.com");
        assert_eq!(default_account_name("ann@outlook.de"), "Outlook.com");
        assert_eq!(default_account_name("ann@yahoo.co.uk"), "Yahoo");
        assert_eq!(default_account_name("ann@me.com"), "iCloud");
        assert_eq!(default_account_name("ann@gmx.net"), "GMX");
        assert_eq!(default_account_name("ann@web.de"), "WEB.DE");
        assert_eq!(default_account_name("andris@postalsys.com"), "postalsys.com");
        assert_eq!(default_account_name("ann@Gmail.com."), "Gmail");
        assert_eq!(default_account_name("weird"), "");
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
