//! The setup file through the C API, as the windows call it: an export built up with a passphrase and the app's
//! preferences, the file read (asking for the passphrase first), its rows listed, and an import into a second store
//! answered with lines. No server is needed.

use std::ffi::{CStr, CString, c_char};
use std::ptr::{null, null_mut};

use pe_ffi::*;
use pe_testkit::TempDir;

fn c(s: &str) -> CString {
    CString::new(s).unwrap()
}

fn text(pointer: *const c_char) -> String {
    assert!(!pointer.is_null());
    unsafe { CStr::from_ptr(pointer) }.to_str().unwrap().to_owned()
}

fn taken(pointer: *mut c_char) -> String {
    let found = text(pointer);
    unsafe { pe_string_free(pointer) };
    found
}

fn opened(dir: &TempDir, name: &str) -> *mut PeCore {
    let path = c(dir.path().join(name).to_str().unwrap());
    let core = unsafe { pe_core_open_with(path.as_ptr(), PE_OPEN_MEMORY_PASSWORDS, null(), None, null_mut()) };
    assert!(!core.is_null());
    core
}

fn add_account(core: *const PeCore, email: &str) -> i64 {
    let (name, email, host) = (c("Ann"), c(email), c("127.0.0.1"));
    let settings = PeAccountSettings {
        name: name.as_ptr(),
        email: email.as_ptr(),
        username: email.as_ptr(),
        imap_host: host.as_ptr(),
        imap_port: 9,
        imap_security: PeSecurity::Tls,
        smtp_host: host.as_ptr(),
        smtp_port: 9,
        smtp_security: PeSecurity::Tls,
    };
    let password = c("ann-pw");
    let id = unsafe { pe_account_add(core, &settings, password.as_ptr()) };
    assert!(id > 0);
    id
}

fn lines(lines: *mut PeSetupLines) -> Vec<(PeSetupLineKind, u32, String)> {
    assert!(!lines.is_null());
    let found = (0..unsafe { pe_setup_lines_count(lines) })
        .map(|i| {
            let line = unsafe { &*pe_setup_lines_get(lines, i) };
            (line.kind, line.part, text(line.text))
        })
        .collect();
    assert!(unsafe { pe_setup_lines_get(lines, 99) }.is_null());
    found
}

fn read(core: *const PeCore, path: &CString, passphrase: Option<&str>) -> (*mut PeSetupFile, PeSetupError, String) {
    let passphrase = passphrase.map(c);
    let mut kind = PeSetupError::None;
    let mut error: *mut c_char = null_mut();
    let file = unsafe {
        pe_setup_read(
            core,
            path.as_ptr(),
            passphrase.as_ref().map_or(null(), |p| p.as_ptr()),
            &mut kind,
            &mut error,
        )
    };
    let words = if error.is_null() { String::new() } else { taken(error) };
    (file, kind, words)
}

#[test]
fn a_setup_goes_from_one_store_to_another() {
    let dir = TempDir::new("setup-ffi");
    let a = opened(&dir, "a.db");
    let b = opened(&dir, "b.db");
    add_account(a, "ann@example.com");
    let shop = c("shop.example");
    assert!(unsafe { pe_trust_sender(a, shop.as_ptr(), true) });

    // the preferences the core knows, by name and kind
    let names = pe_setup_pref_names();
    let known: Vec<(String, PeSetupPrefKind, u32)> = (0..unsafe { pe_setup_pref_names_count(names) })
        .map(|i| {
            let row = unsafe { &*pe_setup_pref_names_get(names, i) };
            (text(row.name), row.kind, row.max)
        })
        .collect();
    unsafe { pe_setup_pref_names_free(names) };
    assert!(known.contains(&("layout".to_string(), PeSetupPrefKind::Number, 2)));
    assert!(known.contains(&("language".to_string(), PeSetupPrefKind::Language, 0)));

    let export = pe_setup_export_new(PE_SETUP_ALL);
    let (layout, two, three, width) = (c("layout"), c("2"), c("3"), c("TreeWidth"));
    assert!(unsafe { pe_setup_export_set_pref(export, layout.as_ptr(), two.as_ptr()) });
    assert!(!unsafe { pe_setup_export_set_pref(export, layout.as_ptr(), three.as_ptr()) });
    assert!(!unsafe { pe_setup_export_set_pref(export, width.as_ptr(), two.as_ptr()) });
    let path = c(dir.path().join("Ann.inboxclassic").to_str().unwrap());
    // a passphrase too short is refused with the reason
    let short = c("short");
    unsafe { pe_setup_export_set_passphrase(export, short.as_ptr()) };
    let mut error: *mut c_char = null_mut();
    let written = unsafe { pe_setup_export_write(a, export, path.as_ptr(), &mut error) };
    assert!(written.is_null());
    assert!(taken(error).contains('8'));
    let passphrase = c("correct horse battery");
    unsafe { pe_setup_export_set_passphrase(export, passphrase.as_ptr()) };
    let written = unsafe { pe_setup_export_write(a, export, path.as_ptr(), null_mut()) };
    let parts = lines(written);
    unsafe { pe_setup_lines_free(written) };
    unsafe { pe_setup_export_free(export) };
    assert_eq!(parts.len(), 8);
    assert!(parts.iter().all(|(kind, _, _)| *kind == PeSetupLineKind::Part));
    assert_eq!(parts[0].1, PE_SETUP_ACCOUNTS);
    assert_eq!(parts[0].2, "1 account");

    // asked for the passphrase, then told it is wrong
    let (file, kind, words) = read(b, &path, None);
    assert!(file.is_null());
    assert_eq!(kind, PeSetupError::NeedsPassphrase);
    assert!(!words.is_empty());
    let (file, kind, _) = read(b, &path, Some("wrong horse battery"));
    assert!(file.is_null());
    assert_eq!(kind, PeSetupError::WrongPassphrase);
    let (file, kind, _) = read(b, &c(dir.path().join("none").to_str().unwrap()), None);
    assert!(file.is_null());
    assert_eq!(kind, PeSetupError::Invalid);

    let (file, kind, _) = read(b, &path, Some("correct horse battery"));
    assert_eq!(kind, PeSetupError::None);
    let info = unsafe { &*pe_setup_file_info(file) };
    assert!(info.encrypted);
    assert_eq!(info.parts, PE_SETUP_ALL);
    assert_eq!((info.accounts, info.trusted_senders, info.preferences), (1, 1, 1));
    assert_eq!(text(info.app_version), taken_version());
    assert_eq!(unsafe { pe_setup_file_account_count(file) }, 1);
    let account = unsafe { &*pe_setup_file_account(file, 0) };
    assert_eq!(
        (
            text(account.email),
            text(account.imap),
            account.has_secret,
            account.here
        ),
        ("ann@example.com".to_string(), "127.0.0.1:9".to_string(), true, false)
    );
    assert!(account.problem.is_null());
    assert!(!text(account.note).is_empty());
    assert!(unsafe { pe_setup_file_account(file, 1) }.is_null());
    assert_eq!(unsafe { pe_setup_file_part_count(file) }, 8);
    let part = unsafe { &*pe_setup_file_part(file, 0) };
    assert_eq!(
        (part.part, text(part.text)),
        (PE_SETUP_ACCOUNTS, "1 account".to_string())
    );
    assert_eq!(unsafe { pe_setup_file_pref_count(file) }, 1);
    let pref = unsafe { &*pe_setup_file_pref(file, 0) };
    assert_eq!(
        (text(pref.name), text(pref.value)),
        ("layout".to_string(), "2".to_string())
    );
    assert_eq!(unsafe { pe_setup_file_note_count(file) }, 0);
    assert!(unsafe { pe_setup_file_note(file, 0) }.is_null());

    // nothing chosen: refused with the reason
    let mut error: *mut c_char = null_mut();
    let none = unsafe { pe_setup_import(b, file, 0, null(), 0, &mut error) };
    assert!(none.is_null());
    assert!(!taken(error).is_empty());

    let chosen = [account.index];
    let imported = unsafe { pe_setup_import(b, file, PE_SETUP_ALL, chosen.as_ptr(), 1, null_mut()) };
    let done = lines(imported);
    let mut count = 0;
    let added = unsafe { pe_setup_lines_accounts(imported, &mut count) };
    assert_eq!(count, 1);
    let added = unsafe { *added };
    unsafe { pe_setup_lines_free(imported) };
    unsafe { pe_setup_file_free(file) };
    assert!(
        done.iter()
            .any(|(kind, _, text)| *kind == PeSetupLineKind::Added && text == "Added 1 account.")
    );

    let list = unsafe { pe_accounts(b) };
    assert_eq!(unsafe { pe_account_list_count(list) }, 1);
    let row = unsafe { &*pe_account_list_get(list, 0) };
    assert_eq!((row.id, text(row.email)), (added, "ann@example.com".to_string()));
    unsafe { pe_account_list_free(list) };

    // read again, the account is here
    let (file, _, _) = read(b, &path, Some("correct horse battery"));
    assert!(unsafe { &*pe_setup_file_account(file, 0) }.here);
    unsafe { pe_setup_file_free(file) };

    // NULL handles are harmless
    unsafe {
        pe_setup_file_free(null_mut());
        pe_setup_lines_free(null_mut());
        pe_setup_export_free(null_mut());
        assert_eq!(pe_setup_file_account_count(null()), 0);
        assert!(pe_setup_file_info(null()).is_null());
        assert!(pe_setup_import(b, null(), PE_SETUP_ALL, null(), 0, null_mut()).is_null());
    }
    unsafe { pe_core_close(a) };
    unsafe { pe_core_close(b) };
}

fn taken_version() -> String {
    text(pe_version())
}
