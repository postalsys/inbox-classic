//! The C API against ImapKit (core/e2e), called the way the C++ app calls it: through the
//! exported functions only, with events arriving at a C callback on worker threads.
//!
//! Skipped without Node.js and `npm ci` in core/e2e, unless PE_E2E_REQUIRED is set.

use std::ffi::{CStr, CString, c_char, c_void};
use std::ptr::null_mut;
use std::sync::Mutex;
use std::sync::mpsc::{Receiver, Sender, channel};
use std::time::Duration;

use base64::Engine;
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
    // the server's certificate from a file, as `--pin-certificate` gives it, and passwords for this run only
    let certificate = dir.path().join("server.der");
    std::fs::write(&certificate, &server.cert).unwrap();
    let certificate = CString::new(certificate.to_str().unwrap()).unwrap();
    let core = unsafe {
        pe_core_open_with(
            path.as_ptr(),
            PE_OPEN_MEMORY_PASSWORDS,
            certificate.as_ptr(),
            Some(on_event),
            context.cast(),
        )
    };
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
        // ImapKit's SMTP server takes AUTH after STARTTLS only
        smtp_security: PeSecurity::StartTls,
    };
    let password = c(PASSWORD);
    let account = unsafe { pe_account_add(core, &settings, password.as_ptr()) };
    assert!(account > 0);
    let accounts = unsafe { pe_accounts(core) };
    assert_eq!(unsafe { pe_account_list_count(accounts) }, 1);
    let row = unsafe { &*pe_account_list_get(accounts, 0) };
    assert_eq!((row.id, text(row.email)), (account, "testuser@example.com".into()));
    // as From and the account menus show it
    assert_eq!(text(row.label), "Test <testuser@example.com>");
    assert!(unsafe { pe_account_list_get(accounts, 1) }.is_null());
    unsafe { pe_account_list_free(accounts) };

    // its settings, as Properties shows them, and changed
    let view = unsafe { pe_account_settings(core, account) };
    let stored = unsafe { &*pe_account_settings_info(view) };
    assert_eq!((text(stored.name), stored.imap_port), ("Test".to_string(), server.imap));
    assert_eq!(stored.smtp_security, PeSecurity::StartTls);
    unsafe { pe_account_settings_free(view) };
    let renamed = c("Renamed");
    let changed = PeAccountSettings {
        name: renamed.as_ptr(),
        ..settings
    };
    assert!(unsafe { pe_account_update(core, account, &changed) });
    let view = unsafe { pe_account_settings(core, account) };
    assert_eq!(text(unsafe { &*pe_account_settings_info(view) }.name), "Renamed");
    unsafe { pe_account_settings_free(view) };
    assert!(unsafe { pe_account_settings(core, 4242) }.is_null());

    // a signature: kept sanitized, and the block a new message starts with
    let owned = |text: *mut c_char| {
        let value = unsafe { CStr::from_ptr(text) }.to_str().unwrap().to_string();
        unsafe { pe_string_free(text) };
        value
    };
    assert_eq!(owned(unsafe { pe_signature_block(core, account) }), "");
    let signature = c("<p><b>Ann</b></p><script>x()</script>");
    assert!(unsafe { pe_account_set_signature(core, account, signature.as_ptr()) });
    assert_eq!(
        owned(unsafe { pe_account_signature(core, account) }),
        "<p><b>Ann</b></p>"
    );
    assert!(
        owned(unsafe { pe_signature_block(core, account) })
            .ends_with("<div class=\"pe-signature\">-- <br><p><b>Ann</b></p></div>")
    );
    assert!(!unsafe { pe_account_set_signature(core, 4242, signature.as_ptr()) });
    assert!(unsafe { pe_account_signature(core, 4242) }.is_null());
    assert!(unsafe { pe_account_settings_info(std::ptr::null()) }.is_null());

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
        (
            text(inbox.path),
            text(inbox.name),
            inbox.total,
            inbox.unread,
            inbox.depth
        ),
        ("INBOX".into(), "Inbox".into(), 2, 1, 0)
    );
    assert!(rows.iter().any(|f| f.special_use == PeSpecialUse::Sent));
    // what a collapsed account shows: the unread messages of its folders, none hidden under the Inbox
    assert_eq!(inbox.unread_below, 0);
    assert_eq!(unsafe { pe_folder_list_unread(folders) }, 1);
    assert_eq!(unsafe { pe_folder_list_unread(std::ptr::null()) }, 0);
    let inbox = inbox.id;
    unsafe { pe_folder_list_free(folders) };

    // a search: what it finds, counted the same, in the folder or in every folder, by state, with Gmail's operators
    let find = c("report");
    let folder_search = |text: *const c_char| PeSearch {
        folder: inbox,
        all_inboxes: false,
        show: PeShow::All,
        text,
    };
    let found = unsafe { pe_messages(core, &folder_search(find.as_ptr()), PeSortField::Subject, true, 0, 50) };
    assert_eq!(unsafe { pe_message_list_count(found) }, 1);
    assert_eq!(unsafe { &*pe_message_list_get(found, 0) }.folder, inbox);
    unsafe { pe_message_list_free(found) };
    let (mut total, mut unread) = (0u64, 0u64);
    assert!(unsafe { pe_message_count(core, &folder_search(find.as_ptr()), &mut total, &mut unread) });
    assert_eq!((total, unread), (1, 1));
    assert!(unsafe { pe_message_count(core, &folder_search(std::ptr::null()), &mut total, &mut unread) });
    assert_eq!(total, 2);
    let everywhere = PeSearch {
        folder: 0,
        all_inboxes: false,
        show: PeShow::Unread,
        text: std::ptr::null(),
    };
    assert!(unsafe { pe_message_count(core, &everywhere, &mut total, &mut unread) });
    assert_eq!((total, unread), (1, 1));
    // the Inbox of every account (one account here): its two messages, one unread
    let all_inboxes = PeSearch {
        folder: 0,
        all_inboxes: true,
        show: PeShow::All,
        text: std::ptr::null(),
    };
    assert!(unsafe { pe_message_count(core, &all_inboxes, &mut total, &mut unread) });
    assert_eq!((total, unread), (2, 1));
    assert!(!pe_all_inboxes_shown(1) && pe_all_inboxes_shown(2));
    let operators = c("has:attachment -is:read");
    assert!(unsafe { pe_message_count(core, &folder_search(operators.as_ptr()), &mut total, &mut unread) });
    assert_eq!(total, 1);
    let list = unsafe {
        pe_messages(
            core,
            &folder_search(std::ptr::null()),
            PeSortField::Subject,
            true,
            0,
            50,
        )
    };
    assert_eq!(unsafe { pe_message_list_count(list) }, 2);
    let first = unsafe { &*pe_message_list_get(list, 0) };
    assert_eq!(text(first.subject), "Other");
    let second = unsafe { &*pe_message_list_get(list, 1) };
    assert_eq!(
        (text(second.subject), text(second.from), second.uid),
        ("Report".into(), "Sender".into(), uid)
    );
    assert!(second.has_attachments && !second.seen);
    assert_eq!(
        unsafe {
            pe_message_index(
                core,
                &folder_search(std::ptr::null()),
                PeSortField::Subject,
                true,
                inbox,
                uid,
            )
        },
        1
    );
    assert_eq!(
        unsafe {
            pe_message_index(
                core,
                &folder_search(std::ptr::null()),
                PeSortField::Subject,
                false,
                inbox,
                uid,
            )
        },
        0
    );
    assert_eq!(
        unsafe {
            pe_message_index(
                core,
                &folder_search(std::ptr::null()),
                PeSortField::Subject,
                true,
                inbox,
                uid + 99,
            )
        },
        -1
    );
    let (mut total, mut unread) = (0u64, 0u64);
    assert!(unsafe { pe_folder_counts(core, inbox, &mut total, &mut unread) });
    assert_eq!((total, unread), (2, 1));
    assert!(!unsafe { pe_folder_counts(core, inbox + 99, &mut total, &mut unread) });
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

    // the same view built on a worker, as the reading pane asks for it
    let request = unsafe { pe_message_view_start(core, inbox, uid, true) };
    assert_ne!(request, 0);
    wait(&events, |e| e.kind == PeEventKind::ViewReady && e.uid == request);
    let view = unsafe { pe_message_view_result(core, request) };
    assert!(!view.is_null());
    let info = unsafe { &*pe_message_view_info(view) };
    assert_eq!((text(info.subject), info.attachment_count), ("Report".to_string(), 1));
    assert!(text(info.document).contains("<p>Hi</p>"));
    unsafe { pe_message_view_free(view) };
    // once only, and a cancelled request gives nothing
    assert!(unsafe { pe_message_view_result(core, request) }.is_null());
    let dropped = unsafe { pe_message_view_start(core, inbox, uid, false) };
    unsafe { pe_message_view_cancel(core, dropped) };
    assert!(unsafe { pe_message_view_result(core, dropped) }.is_null());

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

    // View Source: the whole message as text, its window named for it
    let mut title: *mut c_char = null_mut();
    let source = unsafe { pe_message_source_text(core, inbox, uid, &mut title) };
    let shown = text(source);
    assert!(
        shown.contains("Subject: Report\r\n") && shown.contains("<script>x()</script>") && shown.contains("JVBERg==")
    );
    assert_eq!(text(title), "Message Source: Report");
    unsafe {
        pe_string_free(source);
        pe_string_free(title);
    }
    assert!(unsafe { pe_message_source_text(core, inbox, uid + 99, &mut title) }.is_null());
    assert!(unsafe { pe_message_source_text(core, inbox, uid, std::ptr::null_mut()) }.is_null());

    // AI agents: on, none decided about, nothing done yet; the setup an agent's settings take
    assert!(unsafe { pe_agents_enabled(core) });
    assert!(unsafe { pe_agents_set_enabled(core, false) } && !unsafe { pe_agents_enabled(core) });
    assert!(unsafe { pe_agents_set_enabled(core, true) });
    let hosts = unsafe { pe_agent_hosts(core) };
    assert_eq!(unsafe { pe_agent_host_list_count(hosts) }, 0);
    assert!(unsafe { pe_agent_host_list_get(hosts, 0) }.is_null());
    unsafe { pe_agent_host_list_free(hosts) };
    let log = unsafe { pe_agent_log(core, 10) };
    assert_eq!(unsafe { pe_agent_log_count(log) }, 0);
    unsafe { pe_agent_log_free(log) };
    assert_eq!(unsafe { pe_agent_ask_kind(core, 1) }, PeAgentAskKind::None);
    assert!(unsafe { pe_agent_send_info(core, 1) }.is_null());
    assert!(!unsafe { pe_agent_answer_connect(core, 1, true, PE_AGENT_DEFAULT, std::ptr::null(), 0) });
    let given = unsafe { pe_mcp_config(path.as_ptr()) };
    let config = text(given);
    unsafe { pe_string_free(given) };
    assert!(
        config.contains("\"--mcp\"") && config.contains("\"--store\""),
        "{config}"
    );
    // the server for agents starts once, for this store
    assert!(unsafe { pe_mcp_start(core) } && unsafe { pe_mcp_start(core) });

    assert!(unsafe { pe_message_set_seen(core, inbox, uid, true) });
    wait(&events, |e| e.kind == PeEventKind::FolderChanged && e.folder == inbox);
    assert!(unsafe { pe_folder_mark_all_read(core, inbox) });
    assert_eq!(unsafe { pe_inbox_unread(core) }, 0);
    assert_eq!(unsafe { pe_inbox_unread(std::ptr::null()) }, 0);

    // the sender is in the address book, found by a word of the name or the address, until forgotten
    let typed = c("send");
    let contacts = unsafe { pe_contacts(core, typed.as_ptr(), 5) };
    assert!(unsafe { pe_contact_list_count(contacts) } >= 1);
    let first = unsafe { &*pe_contact_list_get(contacts, 0) };
    assert_eq!(text(first.label), "Sender <sender@example.com>");
    assert!(unsafe { pe_contact_list_get(contacts, 99) }.is_null());
    unsafe { pe_contact_list_free(contacts) };
    let address = c("sender@example.com");
    assert!(unsafe { pe_contact_forget(core, address.as_ptr()) });
    let contacts = unsafe { pe_contacts(core, typed.as_ptr(), 5) };
    assert_eq!(unsafe { pe_contact_list_count(contacts) }, 0);
    unsafe { pe_contact_list_free(contacts) };
    // Add Sender to Address Book: a new card with the sender's name and address, the same one again after; the
    // completion then offers the book's person
    let mut added = false;
    let card = unsafe { pe_book_add_sender(core, inbox, uid, &mut added) };
    assert!(card > 0 && added);
    assert_eq!(unsafe { pe_book_add_sender(core, inbox, uid, &mut added) }, card);
    assert!(!added);
    assert_eq!(unsafe { pe_book_add_sender(core, inbox, 999_999, &mut added) }, 0);
    let contacts = unsafe { pe_contacts(core, typed.as_ptr(), 5) };
    assert_eq!(unsafe { pe_contact_list_count(contacts) }, 1);
    let first = unsafe { &*pe_contact_list_get(contacts, 0) };
    assert_eq!(
        (text(first.label), first.group),
        ("Sender <sender@example.com>".to_string(), false)
    );
    unsafe { pe_contact_list_free(contacts) };
    assert!(unsafe { pe_cards_delete(core, &card, 1) });
    assert!(!unsafe { pe_folder_mark_all_read(core, 999_999) });

    // a reply drafted in Rust, sent through the C API
    let draft = unsafe { pe_message_draft(core, inbox, uid, PeDraftKind::Reply) };
    let info = unsafe { &*pe_draft_info(draft) };
    assert_eq!(
        (text(info.to), text(info.subject)),
        ("Sender <sender@example.com>".to_string(), "Re: Report".to_string())
    );
    let attachment_path = dir.path().join("note.txt");
    std::fs::write(&attachment_path, b"attached note").unwrap();
    let attachment_path = c(attachment_path.to_str().unwrap());
    let attachments = [attachment_path.as_ptr()];
    let (body, empty, html) = (c("My answer"), c(""), c("<p>My <b>answer</b></p>"));
    assert!(info.quote_folded && text(info.quote).contains("Original Message"));
    let outgoing = PeOutgoing {
        to: info.to,
        cc: empty.as_ptr(),
        bcc: empty.as_ptr(),
        subject: info.subject,
        text: empty.as_ptr(),
        html: html.as_ptr(),
        quote: info.quote,
        in_reply_to: info.in_reply_to,
        references: info.references,
        attachments: attachments.as_ptr(),
        attachment_count: 1,
        message_id: std::ptr::null(),
        draft_account: 0,
        quote_plain: !info.quote_text.is_null(),
        quote_text: info.quote_text,
    };
    assert!(unsafe { pe_message_send(core, account, &outgoing, null_mut()) });
    unsafe { pe_draft_free(draft) };
    wait(&events, |e| e.kind == PeEventKind::MessageSent && e.account == account);
    let delivered = server.messages("INBOX");
    let raw = delivered.last().unwrap()["raw"].as_str().unwrap();
    let raw = String::from_utf8(base64::engine::general_purpose::STANDARD.decode(raw).unwrap()).unwrap();
    assert!(
        raw.contains("Subject: Re: Report\r\n") && raw.contains("filename=note.txt"),
        "{raw}"
    );
    // the editor's HTML with the quote after it, and the text made from them
    assert!(
        raw.contains("<b>answer</b>") && raw.contains("Original Message"),
        "{raw}"
    );
    assert!(
        raw.contains("Content-Type: text/plain") && !raw.contains("<script"),
        "{raw}"
    );
    assert!(!unsafe { pe_message_send(core, account, std::ptr::null(), null_mut()) });
    // a typo in the address: refused right away, with the reason
    let bad = c("not an address");
    // its own strings: the draft the first message came from is freed
    let typo = PeOutgoing {
        to: bad.as_ptr(),
        cc: empty.as_ptr(),
        bcc: empty.as_ptr(),
        subject: empty.as_ptr(),
        text: body.as_ptr(),
        html: std::ptr::null(),
        quote: std::ptr::null(),
        in_reply_to: std::ptr::null(),
        references: std::ptr::null(),
        attachments: std::ptr::null(),
        attachment_count: 0,
        message_id: std::ptr::null(),
        draft_account: 0,
        quote_plain: false,
        quote_text: std::ptr::null(),
    };
    let mut reason: *mut c_char = null_mut();
    assert!(!unsafe { pe_message_send(core, account, &typo, &mut reason) });
    assert!(text(reason).contains("not an e-mail address"), "{}", text(reason));
    unsafe { pe_string_free(reason) };

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

/// Sign-in apps through the C API, against ImapKit's OpenID Connect provider: the presets, a check, saving, the
/// manager's rows (no secret in them), signing in with the app and the account that names it
#[test]
fn sign_in_apps_through_the_c_api() {
    let config = json!({ "users": { "alice@example.com": { "password": "pw", "displayName": "Alice" } }, "oauth": {} });
    let Some(server) = ImapKit::start(config) else {
        return;
    };
    let issuer = server.oauth.clone().expect("ImapKit with its OAuth provider");
    let dir = TempDir::new("ffi-apps");
    let path = CString::new(dir.path().join("store.db").to_str().unwrap()).unwrap();
    let certificate = dir.path().join("server.der");
    std::fs::write(&certificate, &server.cert).unwrap();
    let certificate = CString::new(certificate.to_str().unwrap()).unwrap();
    let (sender, events) = channel();
    let context = Box::into_raw(Box::new(Mutex::new(sender)));
    let core = unsafe {
        pe_core_open_with(
            path.as_ptr(),
            PE_OPEN_MEMORY_PASSWORDS,
            certificate.as_ptr(),
            Some(on_event),
            context.cast(),
        )
    };
    assert!(!core.is_null());
    let c = |s: &str| CString::new(s).unwrap();

    // the presets fill in Google and Microsoft
    let presets = pe_sign_in_presets();
    let count = unsafe { pe_sign_in_preset_list_count(presets) };
    let names: Vec<String> = (0..count)
        .map(|i| text(unsafe { &*pe_sign_in_preset_list_get(presets, i) }.name))
        .collect();
    assert_eq!(names, ["Google", "Microsoft"]);
    let google = unsafe { &*pe_sign_in_preset_list_get(presets, 0) };
    assert_eq!(
        (text(google.imap_host), google.imap_port),
        ("imap.gmail.com".into(), 993)
    );
    unsafe { pe_sign_in_preset_list_free(presets) };
    let redirect = unsafe { pe_sign_in_redirect_uri(c("https://accounts.google.com").as_ptr()) };
    assert_eq!(text(redirect), "http://127.0.0.1");
    unsafe { pe_string_free(redirect) };

    // a check, then saving with a client secret
    let mut reason = null_mut();
    assert_eq!(
        unsafe { pe_sign_in_app_check(core, c("ftp://x").as_ptr(), &mut reason) },
        0
    );
    assert!(text(reason).contains("https://"));
    unsafe { pe_string_free(reason) };
    let check = unsafe { pe_sign_in_app_check(core, c(&issuer).as_ptr(), null_mut()) };
    assert!(check > 0);
    wait(&events, |e| e.kind == PeEventKind::SignInAppChecked && e.uid == check);
    let mut found = null_mut();
    assert!(unsafe { pe_sign_in_app_check_result(core, check, &mut found) });
    assert!(text(found).contains(&format!("{issuer}/token")));
    unsafe { pe_string_free(found) };
    let (name, client, scopes, host) = (
        c("ImapKit"),
        c("imapkit-approve"),
        c("openid email profile offline_access mail"),
        c("127.0.0.1"),
    );
    let issuer_c = c(&issuer);
    let form = PeSignInAppForm {
        name: name.as_ptr(),
        issuer: issuer_c.as_ptr(),
        client_id: client.as_ptr(),
        scopes: scopes.as_ptr(),
        imap_host: host.as_ptr(),
        imap_port: server.imaps,
        imap_security: PeSecurity::Tls,
        smtp_host: host.as_ptr(),
        smtp_port: server.smtp,
        smtp_security: PeSecurity::StartTls,
    };
    let plain = PeSignInAppForm {
        imap_security: PeSecurity::Plain,
        ..form
    };
    let mut reason = null_mut();
    assert_eq!(
        unsafe { pe_sign_in_app_save(core, 0, &plain, PeSecretChange::Keep, std::ptr::null(), &mut reason) },
        0
    );
    assert!(text(reason).contains("SSL/TLS"));
    unsafe { pe_string_free(reason) };
    let app = unsafe { pe_sign_in_app_save(core, 0, &form, PeSecretChange::Keep, std::ptr::null(), null_mut()) };
    assert!(app > 0);
    // a secret saved for one issuer is not kept when the issuer changes
    let secret = c("s3cret");
    assert_eq!(
        unsafe { pe_sign_in_app_save(core, app, &form, PeSecretChange::Set, secret.as_ptr(), null_mut()) },
        app
    );
    let microsoft = c("https://login.microsoftonline.com/common/v2.0");
    let moved = PeSignInAppForm {
        issuer: microsoft.as_ptr(),
        ..form
    };
    let check = unsafe { pe_sign_in_app_check(core, microsoft.as_ptr(), null_mut()) };
    wait(&events, |e| e.kind == PeEventKind::SignInAppChecked && e.uid == check);
    let mut found = null_mut();
    if unsafe { pe_sign_in_app_check_result(core, check, &mut found) } {
        // only with the network: the check of Microsoft's issuer has to work for the save to get as far
        let mut reason = null_mut();
        assert_eq!(
            unsafe { pe_sign_in_app_save(core, app, &moved, PeSecretChange::Keep, std::ptr::null(), &mut reason) },
            0
        );
        assert!(text(reason).contains("client secret again"));
        unsafe { pe_string_free(reason) };
    }
    unsafe { pe_string_free(found) };
    assert_eq!(
        unsafe { pe_sign_in_app_save(core, app, &form, PeSecretChange::Remove, std::ptr::null(), null_mut()) },
        app
    );

    // the manager's rows: the built-in clients first, Google off; the app on, with its settings
    let rows = unsafe { pe_sign_in_apps(core) };
    assert_eq!(unsafe { pe_sign_in_app_list_count(rows) }, 3);
    let row = |i| unsafe { &*pe_sign_in_app_list_get(rows, i) };
    assert_eq!((row(0).provider, row(0).enabled), (PeOAuthProvider::Microsoft, true));
    assert_eq!((row(1).provider, row(1).enabled), (PeOAuthProvider::Google, false));
    assert!(text(row(1).off_reason).contains("test users"));
    assert_eq!(
        (row(2).provider, row(2).id, row(2).enabled),
        (PeOAuthProvider::App, app, true)
    );
    assert_eq!(
        (text(row(2).client_id), row(2).imap_port),
        ("imapkit-approve".into(), server.imaps)
    );
    assert!(!row(2).has_secret && text(row(2).used_by).is_empty());
    unsafe { pe_sign_in_app_list_free(rows) };
    assert!(unsafe { pe_sign_in_app_set_enabled(core, PeOAuthProvider::Google, 0, true) });
    assert!(!unsafe { pe_sign_in_app_set_enabled(core, PeOAuthProvider::App, app + 1, true) });

    // signing in with it, through the browser
    let mut url = null_mut();
    let request = unsafe {
        pe_sign_in_begin(
            core,
            PeOAuthProvider::App,
            app,
            c("alice@example.com").as_ptr(),
            &mut url,
        )
    };
    assert!(request > 0);
    assert!(pe_testkit::oauth_follow(&text(url)).contains("You are signed in"));
    unsafe { pe_string_free(url) };
    wait(&events, |e| e.kind == PeEventKind::SignInDone && e.uid == request);
    assert!(unsafe { pe_sign_in_result(core, request, null_mut()) });
    let account = unsafe { pe_account_add_signed_in(core, request, std::ptr::null()) };
    assert!(account > 0);
    let accounts = unsafe { pe_accounts(core) };
    let row = unsafe { &*pe_account_list_get(accounts, 0) };
    assert_eq!((row.oauth, row.app), (PeOAuthProvider::App, app));
    assert_eq!(text(row.signs_in_with), "ImapKit");
    unsafe { pe_account_list_free(accounts) };
    let mut reason = null_mut();
    assert!(!unsafe { pe_sign_in_app_remove(core, app, &mut reason) });
    assert!(text(reason).contains("alice@example.com"));
    unsafe { pe_string_free(reason) };

    unsafe { pe_core_close(core) };
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
        assert!(pe_messages(std::ptr::null(), std::ptr::null(), PeSortField::Date, false, 0, 10).is_null());
        let (mut total, mut unread) = (0u64, 0u64);
        assert!(!pe_message_count(
            std::ptr::null(),
            std::ptr::null(),
            &mut total,
            &mut unread
        ));
        assert_eq!(pe_search_unindexed_count(std::ptr::null()), 0);
        assert!(pe_search_place(std::ptr::null()).is_null());
        assert!(pe_mailto_draft(std::ptr::null()).is_null());
        let link = CString::new("mailto:ann@example.com?subject=Hi&body=Hello").unwrap();
        let draft = pe_mailto_draft(link.as_ptr());
        let info = &*pe_draft_info(draft);
        assert_eq!(CStr::from_ptr(info.to).to_str().unwrap(), "ann@example.com");
        assert_eq!(CStr::from_ptr(info.subject).to_str().unwrap(), "Hi");
        assert_eq!(CStr::from_ptr(info.body).to_str().unwrap(), "<div>Hello</div>");
        pe_draft_free(draft);
        let web = CString::new("https://example.com").unwrap();
        assert!(pe_mailto_draft(web.as_ptr()).is_null());
        let typed = CString::new("report in:sent").unwrap();
        let place = pe_search_place(typed.as_ptr());
        assert_eq!(CStr::from_ptr(place).to_str().unwrap(), "Sent Items");
        pe_string_free(place);
        pe_message_list_free(null_mut());
        pe_message_view_free(null_mut());
        pe_bytes_free(null_mut(), 0);
        assert!(pe_sign_in_apps(std::ptr::null()).is_null());
        assert_eq!(pe_sign_in_app_list_count(std::ptr::null()), 0);
        assert!(pe_sign_in_app_list_get(std::ptr::null(), 0).is_null());
        pe_sign_in_app_list_free(null_mut());
        pe_sign_in_preset_list_free(null_mut());
        assert_eq!(pe_sign_in_app_check(std::ptr::null(), std::ptr::null(), null_mut()), 0);
        assert!(!pe_sign_in_app_check_result(std::ptr::null(), 1, null_mut()));
        assert_eq!(
            pe_sign_in_app_save(
                std::ptr::null(),
                0,
                std::ptr::null(),
                PeSecretChange::Set,
                std::ptr::null(),
                null_mut()
            ),
            0
        );
        assert!(!pe_sign_in_app_remove(std::ptr::null(), 1, null_mut()));
        assert!(!pe_sign_in_app_set_enabled(
            std::ptr::null(),
            PeOAuthProvider::None,
            0,
            true
        ));
        let mut url = null_mut();
        assert_eq!(
            pe_sign_in_begin(std::ptr::null(), PeOAuthProvider::None, 0, std::ptr::null(), &mut url),
            0
        );
        let redirect = pe_sign_in_redirect_uri(std::ptr::null());
        assert_eq!(text(redirect), "http://localhost");
        pe_string_free(redirect);
        let hint = pe_sign_in_register_hint(std::ptr::null());
        assert!(text(hint).contains("redirect URI"));
        pe_string_free(hint);
    }
    // a lookup of an address without a domain finishes with nothing
    unsafe {
        assert_eq!(
            pe_autoconfig_start(std::ptr::null(), std::ptr::null(), std::ptr::null()),
            0
        );
        assert!(pe_autoconfig_result(std::ptr::null(), 1).is_null());
        assert!(pe_autoconfig_info(std::ptr::null()).is_null());
        pe_autoconfig_free(null_mut());
    }

    // an engine without a callback, and an unknown account
    let dir = TempDir::new("ffi-null");
    let path = CString::new(dir.path().join("store.db").to_str().unwrap()).unwrap();
    // a certificate file that is missing or holds no certificate opens nothing
    let missing = CString::new(dir.path().join("missing.pem").to_str().unwrap()).unwrap();
    let flags = PE_OPEN_MEMORY_PASSWORDS;
    assert!(unsafe { pe_core_open_with(path.as_ptr(), flags, missing.as_ptr(), None, null_mut()) }.is_null());
    let junk = dir.path().join("junk.pem");
    std::fs::write(&junk, "not a certificate").unwrap();
    let junk = CString::new(junk.to_str().unwrap()).unwrap();
    assert!(unsafe { pe_core_open_with(path.as_ptr(), flags, junk.as_ptr(), None, null_mut()) }.is_null());

    let core = unsafe { pe_core_open(path.as_ptr(), None, null_mut()) };
    assert!(!core.is_null());
    unsafe {
        assert!(!pe_sync(core, 42));
        assert!(pe_message_view(core, 1, 1, false).is_null());
        assert_eq!(pe_message_view_start(std::ptr::null(), 1, 1, false), 0);
        assert!(!pe_message_set_seen(std::ptr::null(), 1, 1, true));
        let mut reason: *mut c_char = null_mut();
        let bad = CString::new("").unwrap();
        assert!(!pe_folder_create(core, 42, 0, bad.as_ptr(), &mut reason));
        assert!(!reason.is_null());
        pe_string_free(reason);
        assert!(!pe_folder_rename(core, 1, bad.as_ptr(), null_mut()));
        assert!(!pe_folder_delete(std::ptr::null(), 1, null_mut()));
        let (mut len, mut name) = (0usize, null_mut());
        assert!(pe_message_source(core, 1, 1, &mut len, &mut name).is_null());
        let missing = CString::new("/no/such/file.eml").unwrap();
        assert!(!pe_message_import(core, 1, missing.as_ptr(), null_mut()));
        // drafts: nothing to open, no account to save in
        assert!(pe_draft_open(core, 1, 1).is_null());
        assert!(pe_message_headers(core, 1, 1).is_null());
        let dir = CString::new(".").unwrap();
        assert!(!pe_save_attachments(core, 1, 1, dir.as_ptr(), null_mut(), null_mut()));
        assert!(!pe_save_attachments(
            core,
            1,
            1,
            std::ptr::null(),
            null_mut(),
            null_mut()
        ));
        assert!(pe_message_headers(std::ptr::null(), 1, 1).is_null());
        assert!(pe_draft_open(std::ptr::null(), 1, 1).is_null());
        let mut id: *mut c_char = null_mut();
        assert!(!pe_draft_save(core, 42, std::ptr::null(), &mut id, null_mut()));
        assert!(id.is_null());
        assert!(pe_message_view_result(core, 12345).is_null());
        pe_message_view_cancel(core, 12345);
        let empty = pe_folders(core, 42);
        assert_eq!(pe_folder_list_count(empty), 0);
        pe_folder_list_free(empty);
        pe_core_close(core);
    }
}
