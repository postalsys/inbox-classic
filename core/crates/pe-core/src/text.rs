//! Words and numbers the windows of every platform show the same way, made here so the three agree

/// A size as the windows show it: `512 bytes`, `13 KB` (rounded up, as Explorer does), `2.4 MB`
pub fn format_size(bytes: u64) -> String {
    if bytes < 1024 {
        format!("{bytes} bytes")
    } else if bytes < 1024 * 1024 {
        format!("{} KB", bytes.div_ceil(1024))
    } else {
        format!("{:.1} MB", bytes as f64 / (1024.0 * 1024.0))
    }
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
        Some(SpecialUse::Inbox) => "Inbox".into(),
        Some(SpecialUse::Sent) => "Sent Items".into(),
        Some(SpecialUse::Trash) => "Deleted Items".into(),
        Some(SpecialUse::Drafts) => "Drafts".into(),
        Some(SpecialUse::Junk) => "Junk E-mail".into(),
        _ => folder.name.clone(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

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
