//! Previews of the attachments of signed and encrypted mail (docs/attachment-preview-plan.md, PR 4), with the UI tests'
//! message of a picture in each of two parts, the second encrypted (`scripts/ui-e2e/pgp/secure-previews.eml`): each
//! part's previews in its own document under a token of its own, never answered for another part's document; what was
//! decrypted kept in memory only, never written to disk, and gone with the view; the printout; agents never see them.

use std::path::{Path, PathBuf};
use std::sync::mpsc::{self, Receiver};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant, SystemTime};

use pe_core::keys::KeySource;
use pe_core::{Core, Event, Options, PasswordStore};
use pe_store::{AccountSettings, Auth, Security, Store};

fn fixtures() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../../scripts/ui-e2e/pgp")
}

fn fixture() -> Vec<u8> {
    std::fs::read(fixtures().join("secure-previews.eml")).unwrap()
}

/// A core with the test account's key (to decrypt) and the message as UID 1 of its Inbox; its events
fn world(dir: &pe_testkit::TempDir) -> (Arc<Core>, pe_store::FolderId, Receiver<Event>) {
    let path = dir.path().join("store.db");
    let folder = {
        let store = Store::open(&path).unwrap();
        let account = store
            .add_account(&AccountSettings {
                name: "Alex Morgan".into(),
                email: "testuser@inboxclassic.test".into(),
                username: "testuser@inboxclassic.test".into(),
                imap_host: "imap.invalid".into(),
                imap_port: 993,
                imap_security: Security::Tls,
                smtp_host: "smtp.invalid".into(),
                smtp_port: 465,
                smtp_security: Security::Tls,
                auth: Auth::Password,
            })
            .unwrap();
        let inbox = pe_store::FolderInfo {
            path: "INBOX".into(),
            name: "INBOX".into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(account, &[inbox]).unwrap();
        let folder = store.folders(account).unwrap()[0].id;
        let info = pe_store::MessageInfo {
            uid: 1,
            subject: "Two pictures, one sealed".into(),
            from_address: "alice@example.org".into(),
            ..Default::default()
        };
        store.add_messages(folder, &[info]).unwrap();
        store.set_source(folder, 1, &fixture()).unwrap();
        folder
    };
    let (sender, events) = mpsc::channel();
    let sender = Mutex::new(sender);
    let options = Options {
        passwords: PasswordStore::Memory,
        ..Default::default()
    };
    let core = Core::open_with(&path, options, move |event| {
        let _ = sender.lock().unwrap().send(event);
    })
    .unwrap();
    let read = |name: &str| std::fs::read(fixtures().join(name)).unwrap();
    let passphrase = String::from_utf8(read("me.passphrase")).unwrap();
    core.pgp_import(&read("me.asc"), Some(passphrase.trim()), KeySource::File)
        .unwrap();
    (Arc::new(core), folder, events)
}

/// The tokens in a document's preview addresses, each once
fn tokens(document: &str) -> Vec<String> {
    let mut found = Vec::new();
    for (at, _) in document.match_indices("src=\"/pv/") {
        let token = document[at + 9..at + 41].to_string();
        if !found.contains(&token) {
            found.push(token);
        }
    }
    found
}

/// The answer to `ask` once its event came
fn answered(core: &Core, events: &Receiver<Event>, ask: u64) -> Option<Arc<pe_core::previews::Picture>> {
    let until = Instant::now() + Duration::from_secs(30);
    loop {
        match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
            Ok(Event::PreviewAnswered { ask: done }) if done == ask => return core.preview_answer(ask),
            Ok(_) => {}
            Err(error) => panic!("ask {ask} not answered: {error}"),
        }
    }
}

/// The colour of the picture at 90, 75: the floor plan's shaded room, the harbour's sky
fn colour(picture: &pe_core::previews::Picture) -> [u8; 3] {
    let image = image::load_from_memory(&picture.bytes).unwrap().to_rgb8();
    image.get_pixel(90, 75).0
}

/// The page, a document per part: each part's previews in its own document under its own token, the page none; a
/// part's token answers only its own part's files, its links open only its own files, and only from the reader that
/// shows the view
#[test]
fn each_part_shows_its_own_previews_under_its_own_token() {
    let dir = pe_testkit::TempDir::new("pgp-previews-parts");
    let (core, folder, events) = world(&dir);
    let view = core.message_view(folder, 1, false).unwrap().unwrap();
    let protection = view.protection.as_ref().unwrap();
    assert_eq!(protection.parts.len(), 2);
    let names: Vec<&str> = view.attachments.iter().map(|a| a.filename.as_str()).collect();
    assert_eq!(names, ["harbour.png", "floor-plan.png"]);
    let token = view.preview_token.clone().unwrap();
    assert!(!view.document.contains("/pv/"), "{}", view.document);
    let (plain, sealed) = (&view.part_documents[0], &view.part_documents[1]);
    let (a, b) = (tokens(plain), tokens(sealed));
    assert_eq!((a.len(), b.len()), (1, 1), "{a:?} {b:?}");
    let (a, b) = (&a[0], &b[0]);
    assert!(a != b && *a != token && *b != token);
    // each document names only its own part's file, its size kept before the picture comes (the frame is measured
    // as tall as it will be)
    assert!(
        plain.contains(&format!(
            "src=\"/pv/{a}-0-0\" width=\"240\" height=\"150\" alt=\"harbour.png\" \
             style=\"width:240px!important;aspect-ratio:240/150!important\""
        )),
        "{plain}"
    );
    assert!(
        sealed.contains(&format!("src=\"/pv/{b}-1-0\" width=\"240\"")),
        "{sealed}"
    );
    assert!(!plain.contains(b.as_str()) && !sealed.contains(a.as_str()));
    assert!(!plain.contains("floor-plan") && !sealed.contains("harbour"));

    // a part's token never answers for the other part's file, nor the view's for any
    for address in [
        format!("/pv/{a}-1-0"),
        format!("/pv/{b}-0-0"),
        format!("/pv/{token}-0-0"),
        format!("/pv/{token}-1-0"),
    ] {
        assert_eq!(core.preview_ask(&address), None, "{address}");
    }
    let ask = core.preview_ask(&format!("/pv/{b}-1-0")).unwrap();
    let floor = answered(&core, &events, ask).unwrap();
    assert_eq!((floor.width, floor.height), (240, 150));
    // the floor plan's shaded room, not the harbour's water
    assert_eq!(colour(&floor), [214, 228, 247]);
    let ask = core.preview_ask(&format!("/pv/{a}-0-0")).unwrap();
    let harbour = answered(&core, &events, ask).unwrap();
    assert_eq!(colour(&harbour), [157, 195, 230]);

    // links: a part's own files, from the reader of this view only
    let link = |t: &str, n: usize| format!("inboxclassic:attachment-{t}-{n}");
    assert_eq!(core.preview_link(&link(a, 0), &token), Some(0));
    assert_eq!(core.preview_link(&link(b, 1), &token), Some(1));
    assert_eq!(core.preview_link(&link(a, 1), &token), None);
    assert_eq!(core.preview_link(&link(b, 0), &token), None);
    assert_eq!(core.preview_link(&link(b, 1), b), None);
    assert_eq!(core.preview_link(&link(&token, 1), &token), None);

    // the view ends: nothing of it answers anymore, and an answer not taken yet is gone with it (a decrypted part's
    // picture is kept nowhere else)
    let ask = core.preview_ask(&format!("/pv/{b}-1-0")).unwrap();
    let until = Instant::now() + Duration::from_secs(30);
    while !matches!(
        events.recv_timeout(until.saturating_duration_since(Instant::now())),
        Ok(Event::PreviewAnswered { ask: done }) if done == ask
    ) {
        assert!(Instant::now() < until, "not answered");
    }
    core.previews_end(&token);
    assert!(core.preview_answer(ask).is_none());
    assert_eq!(core.preview_ask(&format!("/pv/{b}-1-0")), None);
    assert_eq!(core.preview_link(&link(b, 1), &token), None);
}

/// A message file opened in a window of its own: the same parts, the same walls
#[test]
fn a_message_file_shows_each_part_s_previews() {
    let dir = pe_testkit::TempDir::new("pgp-previews-file");
    let (core, _folder, events) = world(&dir);
    let view = core.file_view(&fixtures().join("secure-previews.eml"), false).unwrap();
    let b = tokens(&view.part_documents[1]).remove(0);
    assert_eq!(core.preview_ask(&format!("/pv/{b}-0-0")), None);
    let ask = core.preview_ask(&format!("/pv/{b}-1-0")).unwrap();
    assert_eq!(colour(&answered(&core, &events, ask).unwrap()), [214, 228, 247]);
}

/// The printout: one document of every part's words (a printer prints no frames), then each part's pictures as the
/// core encoded them, named with their part; made in memory and handed to the window, never written
#[test]
fn the_printout_names_each_picture_s_part() {
    let dir = pe_testkit::TempDir::new("pgp-previews-print");
    let (core, folder, events) = world(&dir);
    let view = core.message_view(folder, 1, false).unwrap().unwrap();
    // printed as it is shown before the pictures are there: no preview address
    let plain = view.print_document.as_deref().unwrap();
    assert!(
        !plain.contains("/pv/") && plain.contains("for your eyes only"),
        "{plain}"
    );
    let request = core.print_start(view.preview_token.as_deref().unwrap()).unwrap();
    let until = Instant::now() + Duration::from_secs(30);
    loop {
        match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
            Ok(Event::PrintReady { request: done }) if done == request => break,
            Ok(_) => {}
            Err(error) => panic!("no printout: {error}"),
        }
    }
    let printed = core.print_result(request).unwrap();
    assert_eq!(
        printed.matches("<img src=\"data:image/png;base64,").count(),
        2,
        "{printed}"
    );
    assert!(printed.contains("Part 1: harbour.png") && printed.contains("Part 2: floor-plan.png"));
    assert!(!printed.contains("/pv/"), "{printed}");
}

/// Agents never see what was decrypted: the message is encrypted for them, its files refused, and no preview of it
/// is reachable through them
#[test]
fn agents_never_get_decrypted_previews() {
    let dir = pe_testkit::TempDir::new("pgp-previews-agent");
    let (core, folder, _events) = world(&dir);
    let view = core.message_view(folder, 1, false).unwrap().unwrap();
    assert!(view.preview_token.is_some());
    let agent = core.agent_message(folder, 1).unwrap().unwrap();
    assert!(agent.attachments.is_empty(), "{:?}", agent.attachments);
    assert_eq!(agent.written, pe_core::i18n::tr(pe_core::i18n::Text::AgentEncrypted));
    for index in 0..2 {
        assert!(core.agent_attachment(folder, 1, index).is_err());
    }
}

/// Every file under `dir` (a link not followed), changed since `since`
fn files_under(dir: &Path, since: SystemTime, depth: usize, out: &mut Vec<PathBuf>) {
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let Ok(meta) = entry.path().symlink_metadata() else {
            continue;
        };
        if meta.is_dir() && depth > 0 {
            files_under(&entry.path(), since, depth - 1, out);
        } else if meta.is_file() && meta.modified().is_ok_and(|m| m >= since) && meta.len() < 256 << 20 {
            out.push(entry.path());
        }
    }
}

/// Nothing decrypted reaches the disk: after the view, its pictures drawn, a printout and the view's end, no file of
/// the store's folder (the database, its journal, the crash markers and the refused list), the folder of opened
/// attachments, or the temporary folder written meanwhile holds the decrypted file, its preview, or the hash of
/// either (a marker named by it would let anyone confirm a guess of the file), as the key store test checks the
/// database for the private key
#[test]
fn nothing_decrypted_is_written_to_disk() {
    let since = SystemTime::now() - Duration::from_secs(2);
    let dir = pe_testkit::TempDir::new("pgp-previews-disk");
    let (core, folder, events) = world(&dir);
    let view = core.message_view(folder, 1, false).unwrap().unwrap();
    let token = view.preview_token.clone().unwrap();
    let b = tokens(&view.part_documents[1]).remove(0);
    let ask = core.preview_ask(&format!("/pv/{b}-1-0")).unwrap();
    let preview = answered(&core, &events, ask).unwrap();
    // read back as Save As would read it, in memory: the file as it was decrypted
    let (_, decrypted) = core.attachment(folder, 1, 1).unwrap().unwrap();
    assert!(decrypted.starts_with(b"\x89PNG"));
    let request = core.print_start(&token).unwrap();
    while !matches!(
        events.recv_timeout(Duration::from_secs(30)),
        Ok(Event::PrintReady { request: done }) if done == request
    ) {}
    assert!(core.print_result(request).is_some());
    core.previews_end(&token);
    drop(core);

    let mut files = Vec::new();
    files_under(dir.path(), SystemTime::UNIX_EPOCH, 4, &mut files);
    files_under(&std::env::temp_dir(), since, 4, &mut files);
    if let Some(runtime) = std::env::var_os("XDG_RUNTIME_DIR") {
        files_under(&Path::new(&runtime).join("InboxClassic"), since, 3, &mut files);
    }
    assert!(files.iter().any(|f| f.ends_with("store.db")), "the store was scanned");
    // 32 byte stretches of the decrypted file's pixel data and of the preview the core encoded, past their headers
    // (which are any 240 by 150 picture's)
    let stretches = |bytes: &[u8]| -> Vec<Vec<u8>> {
        let step = (bytes.len() - 96) / 8;
        (0..8).map(|n| bytes[64 + n * step..96 + n * step].to_vec()).collect()
    };
    let mut needles = stretches(&decrypted);
    needles.extend(stretches(&preview.bytes));
    let hashes = [pe_preview::key_of(&decrypted), pe_preview::key_of(&preview.bytes)];
    // the scan finds what it looks for: a copy written on purpose is found
    let control = dir.path().join("control");
    std::fs::write(&control, &decrypted).unwrap();
    assert!(leak(std::slice::from_ref(&control), &needles, &hashes).is_some());
    std::fs::remove_file(control).unwrap();
    assert_eq!(leak(&files, &needles, &hashes), None);
}

/// The first of `files` that holds one of `needles` or one of `hashes` (in its name or its content), and why
fn leak(files: &[PathBuf], needles: &[Vec<u8>], hashes: &[pe_preview::Key]) -> Option<String> {
    for file in files {
        let name = file.to_string_lossy();
        let Ok(content) = std::fs::read(file) else {
            continue;
        };
        for hash in hashes {
            let hex = hash.as_str().as_bytes();
            if name.contains(hash.as_str()) || content.windows(64).any(|w| w == hex) {
                return Some(format!("the hash of a decrypted file in {name}"));
            }
        }
        if needles
            .iter()
            .any(|needle| content.windows(32).any(|w| w == needle.as_slice()))
        {
            return Some(format!("decrypted bytes in {name}"));
        }
    }
    None
}
