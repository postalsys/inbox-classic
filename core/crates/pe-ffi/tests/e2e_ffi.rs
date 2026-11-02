//! The C API against ImapKit (core/e2e), called the way the C++ app calls it: through the
//! exported functions only, with events arriving at a C callback on worker threads.
//!
//! Skipped without Node.js and `npm ci` in core/e2e, unless PE_E2E_REQUIRED is set.

use std::ffi::{CStr, CString, c_char, c_void};
use std::ptr::null_mut;
use std::sync::Mutex;
use std::sync::mpsc::{Receiver, Sender, channel};
use std::time::Duration;

use pe_ffi::*;
use pe_testkit::{ImapKit, PASSWORD, TempDir, USER, rfc822};
use serde_json::json;

/// What the callback copies out of an event, as the C++ app would before posting it
#[derive(Debug, Clone, PartialEq, Eq)]
struct Copied {
    kind: PeEventKind,
    account: i64,
    folder: i64,
    uid: u64,
    failure: PeFailureKind,
    message: Option<String>,
}

unsafe extern "C" fn on_event(context: *mut c_void, event: *const PeEvent) {
    // SAFETY: the context is the Mutex<Sender> of the test, the event lives for the call
    let (sender, event) = unsafe { (&*(context as *const Mutex<Sender<Copied>>), &*event) };
    let message =
        (!event.message.is_null()).then(|| unsafe { CStr::from_ptr(event.message) }.to_string_lossy().into_owned());
    let _ = sender.lock().unwrap().send(Copied {
        kind: event.kind,
        account: event.account,
        folder: event.folder,
        uid: event.uid,
        failure: event.failure,
        message,
    });
}

fn text(pointer: *const c_char) -> String {
    assert!(!pointer.is_null());
    unsafe { CStr::from_ptr(pointer) }.to_str().unwrap().to_owned()
}

fn wait(events: &Receiver<Copied>, accept: impl Fn(&Copied) -> bool) -> Copied {
    loop {
        let event = events
            .recv_timeout(Duration::from_secs(10))
            .expect("an event within 10 seconds");
        if accept(&event) {
            return event;
        }
        assert_ne!(event.kind, PeEventKind::Failed, "{event:?}");
    }
}

#[test]
fn reads_mail_through_the_c_api() {
    let Some(server) = ImapKit::start(json!({})) else {
        return;
    };
    let html = "From: Sender <sender@example.com>\r\nSubject: Report\r\nContent-Type: multipart/mixed; boundary=m\r\n\r\n--m\r\nContent-Type: text/html\r\n\r\n<p>Hi<script>x()</script></p>\r\n--m\r\nContent-Type: application/pdf; name=\"..\\\\evil.pdf\"\r\nContent-Transfer-Encoding: base64\r\n\r\nJVBERg==\r\n--m--\r\n";
    let uid = server.add_message("INBOX", html, &[]);
    server.add_message("INBOX", &rfc822("Other", "x"), &["\\Seen"]);

    let dir = TempDir::new("ffi");
    let path = CString::new(dir.path().join("store.db").to_str().unwrap()).unwrap();
    let (sender, events) = channel();
    let context = Box::into_raw(Box::new(Mutex::new(sender)));
    let core = unsafe { pe_core_open(path.as_ptr(), Some(on_event), context.cast()) };
    assert!(!core.is_null());

    let c = |s: &str| CString::new(s).unwrap();
    let (name, email, user, host) = (c("Test"), c("testuser@example.com"), c(USER), c("127.0.0.1"));
    let settings = PeAccountSettings {
        name: name.as_ptr(),
        email: email.as_ptr(),
        username: user.as_ptr(),
        imap_host: host.as_ptr(),
        imap_port: server.imap,
        imap_security: PeSecurity::Plain,
        smtp_host: host.as_ptr(),
        smtp_port: server.smtp,
        smtp_security: PeSecurity::Plain,
    };
    let password = c(PASSWORD);
    let account = unsafe { pe_account_add(core, &settings, password.as_ptr()) };
    assert!(account > 0);
    let accounts = unsafe { pe_accounts(core) };
    assert_eq!(unsafe { pe_account_list_count(accounts) }, 1);
    let row = unsafe { &*pe_account_list_get(accounts, 0) };
    assert_eq!((row.id, text(row.email)), (account, "testuser@example.com".into()));
    assert!(unsafe { pe_account_list_get(accounts, 1) }.is_null());
    unsafe { pe_account_list_free(accounts) };

    assert!(unsafe { pe_sync(core, account) });
    wait(&events, |e| e.kind == PeEventKind::SyncFinished && e.account == account);

    let folders = unsafe { pe_folders(core, account) };
    let count = unsafe { pe_folder_list_count(folders) };
    let rows: Vec<&PeFolder> = (0..count)
        .map(|i| unsafe { &*pe_folder_list_get(folders, i) })
        .collect();
    let inbox = rows
        .iter()
        .find(|f| f.special_use == PeSpecialUse::Inbox)
        .expect("INBOX");
    assert_eq!(
        (text(inbox.name), inbox.total, inbox.unread, inbox.depth),
        ("INBOX".into(), 2, 1, 0)
    );
    assert!(rows.iter().any(|f| f.special_use == PeSpecialUse::Sent));
    let inbox = inbox.id;
    unsafe { pe_folder_list_free(folders) };

    let list = unsafe { pe_messages(core, inbox, PeSortField::Subject, true, 0, 50) };
    assert_eq!(unsafe { pe_message_list_count(list) }, 2);
    let first = unsafe { &*pe_message_list_get(list, 0) };
    assert_eq!(text(first.subject), "Other");
    let second = unsafe { &*pe_message_list_get(list, 1) };
    assert_eq!(
        (text(second.subject), text(second.from), second.uid),
        ("Report".into(), "Sender".into(), uid)
    );
    assert!(second.has_attachments && !second.seen);
    unsafe { pe_message_list_free(list) };

    assert!(
        unsafe { pe_message_view(core, inbox, uid, false) }.is_null(),
        "not fetched yet"
    );
    assert!(unsafe { pe_message_open(core, inbox, uid) });
    wait(&events, |e| {
        e.kind == PeEventKind::MessageReady && e.uid == uid && e.folder == inbox
    });
    let view = unsafe { pe_message_view(core, inbox, uid, false) };
    let info = unsafe { &*pe_message_view_info(view) };
    assert_eq!(text(info.subject), "Report");
    let document = text(info.document);
    assert!(document.contains("<p>Hi</p>") && !document.contains("script"));
    assert_eq!(info.attachment_count, 1);
    let attachment = unsafe { &*pe_message_view_attachment(view, 0) };
    assert_eq!(text(attachment.safe_filename), "evil.pdf");
    assert_eq!(text(attachment.mime_type), "application/pdf");
    unsafe { pe_message_view_free(view) };

    let mut len = 0usize;
    let mut filename: *mut c_char = null_mut();
    let data = unsafe { pe_attachment_data(core, inbox, uid, 0, &mut len, &mut filename) };
    assert!(!data.is_null());
    assert_eq!(unsafe { std::slice::from_raw_parts(data, len) }, b"%PDF");
    assert_eq!(text(filename), "evil.pdf");
    unsafe {
        pe_bytes_free(data, len);
        pe_string_free(filename);
    }
    assert!(unsafe { pe_attachment_data(core, inbox, uid, 1, &mut len, &mut filename) }.is_null());

    assert!(unsafe { pe_message_set_seen(core, inbox, uid, true) });
    wait(&events, |e| e.kind == PeEventKind::FolderChanged && e.folder == inbox);

    // a wrong password: a Failed event with the reason
    let wrong = c("wrong");
    assert!(unsafe { pe_account_set_password(core, account, wrong.as_ptr()) });
    let other = unsafe { pe_account_add(core, &settings, wrong.as_ptr()) };
    assert!(unsafe { pe_sync(core, other) });
    let failed = wait(&events, |e| e.kind == PeEventKind::Failed);
    assert_eq!((failed.account, failed.failure), (other, PeFailureKind::Authentication));
    assert!(failed.message.unwrap().contains("authentication"));

    unsafe { pe_core_close(core) };
    // no events after close: the context can go
    drop(unsafe { Box::from_raw(context) });
}

#[test]
fn null_and_bad_arguments() {
    unsafe {
        assert!(pe_core_open(std::ptr::null(), None, null_mut()).is_null());
        pe_core_close(null_mut());
        assert!(pe_accounts(std::ptr::null()).is_null());
        assert!(!pe_sync(std::ptr::null(), 1));
        assert_eq!(pe_account_add(std::ptr::null(), std::ptr::null(), std::ptr::null()), 0);
        assert_eq!(pe_account_list_count(std::ptr::null()), 0);
        assert!(pe_message_list_get(std::ptr::null(), 0).is_null());
        pe_message_list_free(null_mut());
        pe_message_view_free(null_mut());
        pe_bytes_free(null_mut(), 0);
    }
    // an engine without a callback, and an unknown account
    let dir = TempDir::new("ffi-null");
    let path = CString::new(dir.path().join("store.db").to_str().unwrap()).unwrap();
    let core = unsafe { pe_core_open(path.as_ptr(), None, null_mut()) };
    assert!(!core.is_null());
    unsafe {
        assert!(!pe_sync(core, 42));
        assert!(pe_message_view(core, 1, 1, false).is_null());
        let empty = pe_folders(core, 42);
        assert_eq!(pe_folder_list_count(empty), 0);
        pe_folder_list_free(empty);
        pe_core_close(core);
    }
}
