//! The later steps of the UI test, in the order of scripts/ui-e2e.ps1: unsubscribing from a list, a calendar
//! invitation, a brand's logo, Mark All Read, dragging onto a folder, junk, folders, closing a message, an e-mail link
//! handed over by a second start, address completion, a signature, a Gmail address, and closing the app.

use super::*;

/// Finds one message with the search, and shows it
async fn show_found(query: &str) -> bool {
    search(query).await;
    let one = wait_until(20, || rows() == 1).await;
    select_row(0).await;
    one
}

/// The time now (and `minutes` later) as a Date header writes it
fn date_now(minutes: i32) -> String {
    glib::DateTime::now_utc()
        .and_then(|t| t.add_minutes(minutes))
        .and_then(|t| t.format("%a, %d %b %Y %H:%M:%S +0000"))
        .map(|t| t.to_string())
        .unwrap_or_default()
}

/// The id of a folder of the first account by the name the tree gives it
fn folder_id(name: &str) -> Option<i64> {
    let core = &shell().core;
    let account = core.accounts().ok()?.first()?.id;
    core.folders(account)
        .ok()?
        .into_iter()
        .find(|f| pe_core::folder_name(&f.info) == name)
        .map(|f| f.id)
}

/// The list's server: a socket of the test, answered by hand; the request it got comes on the channel
fn list_server() -> (u16, std::sync::mpsc::Receiver<String>) {
    let listener = std::net::TcpListener::bind("127.0.0.1:0").expect("a socket for the list");
    let port = listener.local_addr().map(|a| a.port()).unwrap_or(0);
    let (sent, received) = std::sync::mpsc::channel::<String>();
    std::thread::spawn(move || {
        if let Ok((mut stream, _)) = listener.accept() {
            stream.set_read_timeout(Some(Duration::from_secs(5))).ok();
            let mut request = String::new();
            let mut buffer = [0u8; 4096];
            while !request.contains("One-Click") {
                match stream.read(&mut buffer) {
                    Ok(0) | Err(_) => break,
                    Ok(n) => request.push_str(&String::from_utf8_lossy(&buffer[..n])),
                }
            }
            let _ = stream.write_all(b"HTTP/1.0 200 OK\r\nContent-Length: 2\r\n\r\nok");
            let _ = sent.send(request);
        }
    });
    (port, received)
}

pub async fn unsubscribing(d: &Driver) {
    d.step("unsubscribing");
    let main = main_window();
    let (port, received) = list_server();
    let raw = format!(
        "Authentication-Results: mx.postalexpress.test; dkim=pass header.d=list.example.com\r\n\
         DKIM-Signature: v=1; d=list.example.com; s=s1; h=from:subject:list-unsubscribe:list-unsubscribe-post; bh=x; \
         b=y\r\nFrom: Weekly List <news@list.example.com>\r\nTo: testuser@postalexpress.test\r\n\
         Subject: Weekly list news\r\nDate: {}\r\nMessage-ID: <weekly-list@list.example.com>\r\n\
         List-Unsubscribe: <mailto:leave@list.example.com>, <http://127.0.0.1:{port}/u/42>\r\n\
         List-Unsubscribe-Post: List-Unsubscribe=One-Click\r\n\r\nThis week on the list.\r\n",
        date_now(0)
    );
    let _ = d.add_message(&raw, &[]);
    run_command(Command::Sync);
    select_folder("Inbox");
    wait_for(20, || d.find("INBOX", "Subject: Weekly list news")).await;
    pause(1500).await;
    show_found("subject:\"Weekly list news\"").await;
    let reader = &shell().main().reader;
    let shown = wait_until(15, || reader.unsubscribe.is_visible()).await;
    d.check(shown, "a message of a mailing list has Unsubscribe in its header");
    d.shot(&main, "read-8-unsubscribe").await;
    reader
        .unsubscribe
        .emit_by_name::<bool>("activate-link", &[&"unsubscribe"]);
    let sure = wait_alert(10).await;
    let names = sure.as_ref().is_some_and(|s| alert_text(s).contains("127.0.0.1"));
    d.check(names, "it asks first, naming where it goes");
    if let Some(sure) = sure {
        d.shot(&sure, "read-9-unsubscribe-ask").await;
        answer(&sure, "Yes");
    }
    let request = wait_for(15, || received.try_recv().ok()).await.unwrap_or_default();
    let first = request.lines().next().unwrap_or_default().to_string();
    let posted = request.starts_with("POST /u/42 ") && request.contains("List-Unsubscribe=One-Click");
    d.check(
        posted,
        &format!("Yes posts List-Unsubscribe=One-Click to the list ({first})"),
    );
    let done = wait_until(10, || shell().main().status_texts().0.contains("Unsubscribed")).await;
    d.check(
        done,
        &format!(
            "and the status bar says it is done ({})",
            shell().main().status_texts().0
        ),
    );
    search("").await;
}

pub async fn invitation_and_logo(d: &Driver) {
    d.step("a calendar invitation");
    let main = main_window();
    let invite = format!(
        "From: Ann Example <ann@example.com>\r\nTo: testuser@postalexpress.test\r\n\
         Subject: Invitation: Quarterly planning\r\nDate: {}\r\nMessage-ID: <planning-invite@example.com>\r\n\
         Content-Type: multipart/mixed; boundary=inv\r\n\r\n--inv\r\nContent-Type: text/plain\r\n\r\n\
         Let us plan the quarter.\r\n--inv\r\nContent-Type: text/calendar; method=REQUEST; charset=utf-8\r\n\r\n\
         BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nUID:planning@example.com\r\n\
         SUMMARY:Quarterly planning\r\nDTSTART:20261201T100000Z\r\nDTEND:20261201T113000Z\r\nLOCATION:Room 2\r\n\
         ORGANIZER;CN=Ann Example:mailto:ann@example.com\r\nATTENDEE;CN=Test:mailto:testuser@postalexpress.test\r\n\
         RRULE:FREQ=WEEKLY;BYDAY=TU;COUNT=4\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n--inv--\r\n",
        date_now(0)
    );
    let _ = d.add_message(&invite, &[]);
    run_command(Command::Sync);
    wait_for(20, || d.find("INBOX", "Subject: Invitation: Quarterly planning")).await;
    pause(1500).await;
    show_found("subject:\"Quarterly planning\"").await;
    let reader = &shell().main().reader;
    let shown = wait_until(15, || reader.invitation_shown() && reader.open_calendar.is_visible()).await;
    d.check(
        shown,
        "a message with an invitation shows the event over the text, with Open in Calendar",
    );
    d.shot(&main, "read-10-invitation").await;
    search("").await;

    d.step("a brand logo (BIMI)");
    let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.2\" baseProfile=\"tiny-ps\" viewBox=\"0 0 100 \
               100\"><title>Brand</title><rect width=\"100\" height=\"100\" rx=\"22\" fill=\"#0a5bd3\"/><circle \
               cx=\"50\" cy=\"50\" r=\"26\" fill=\"#ffffff\"/><circle cx=\"50\" cy=\"50\" r=\"13\" \
               fill=\"#0a5bd3\"/></svg>";
    let indicator = base64::engine::general_purpose::STANDARD.encode(svg);
    let branded = format!(
        "Authentication-Results: mx.postalexpress.test; dmarc=pass header.from=brand.example; bimi=pass \
         header.d=brand.example\r\nBIMI-Indicator: {indicator}\r\nFrom: Brand <hello@brand.example>\r\n\
         To: testuser@postalexpress.test\r\nSubject: News from the brand\r\nDate: {}\r\n\
         Message-ID: <brand-news@brand.example>\r\n\r\nOur news.\r\n",
        date_now(0)
    );
    let _ = d.add_message(&branded, &[]);
    run_command(Command::Sync);
    wait_for(20, || d.find("INBOX", "Subject: News from the brand")).await;
    pause(1500).await;
    show_found("subject:\"News from the brand\"").await;
    let shown = wait_until(15, || reader.logo_shown()).await;
    d.check(shown, "a sender whose logo the server passed has it beside the header");
    d.shot(&main, "read-11-logo").await;
    search("").await;
}

pub async fn mark_all_read(d: &Driver) {
    d.step("marking all read");
    select_folder("Inbox");
    wait_until(10, || rows() >= 5).await;
    let unread_on_server = || {
        d.messages("INBOX")
            .iter()
            .filter(|m| !m["flags"].as_array().is_some_and(|f| f.iter().any(|f| f == "\\Seen")))
            .count()
    };
    d.check(
        unread_on_server() >= 1,
        &format!("the Inbox has unread messages ({})", unread_on_server()),
    );
    run_command(Command::MarkAllRead);
    let none = wait_until(10, || shell().main().status_texts().2.contains(", 0 unread")).await;
    d.check(
        none,
        &format!(
            "Edit > Mark All Read: none unread in the folder ({})",
            shell().main().status_texts().2
        ),
    );
    d.check(
        wait_until(20, || unread_on_server() == 0).await,
        "and none on the server",
    );
    d.shot(&main_window(), "organize-5-all-read").await;
}

pub async fn dragging(d: &Driver) {
    d.step("dragging a message onto a folder");
    // Drag me the newest, Copy me a minute older: the first two rows
    for (subject, minutes) in [("Drag me", 3), ("Copy me", 2)] {
        let raw = format!(
            "From: Dana <dana@example.com>\r\nTo: testuser@postalexpress.test\r\nSubject: {subject}\r\nDate: {}\r\n\
             Message-ID: <{}@example.com>\r\n\r\nDragged in the UI test.\r\n",
            date_now(minutes),
            subject.replace(' ', "-")
        );
        let _ = d.add_message(&raw, &[]);
    }
    run_command(Command::Sync);
    select_folder("Inbox");
    let main = shell().main();
    let first_is = |subject: &str| main.list.selected().is_some_and(|(_, m)| m.info.subject == subject);
    wait_until(30, || {
        main.list.select(0);
        first_is("Drag me")
    })
    .await;
    let (Some(archive), Some(inbox)) = (folder_id("Archive"), folder_id("Inbox")) else {
        d.check(false, "the tree has Archive and the Inbox");
        return;
    };
    let in_inbox = rows();
    let payload = |m: &pe_store::Message| crate::messages::drag_payload(m.folder_id, m.info.uid);
    // what the drop target of a folder does with the row dragged onto it
    if let Some((_, message)) = main.list.selected() {
        d.check(
            main.can_drop(&payload(&message), archive),
            "a row can be dropped onto Archive",
        );
        main.drop_message(&payload(&message), archive, false);
    }
    let moved = wait_for(20, || d.find("Archive", "Subject: Drag me")).await;
    d.check(moved.is_some(), "a message dragged onto Archive is moved there");
    d.check(
        wait_until(10, || d.find("INBOX", "Subject: Drag me").is_none()).await,
        "and out of the Inbox",
    );
    d.check(wait_until(10, || rows() == in_inbox - 1).await, "and out of the list");
    main.list.select(0);
    pause(500).await;
    if let Some((_, message)) = main.list.selected() {
        d.check(message.info.subject == "Copy me", "the next one is the first row");
        // with Ctrl held
        main.drop_message(&payload(&message), archive, true);
        d.check(
            !main.can_drop(&payload(&message), inbox),
            "dropped on its own folder, it stays",
        );
    }
    d.check(
        wait_for(20, || d.find("Archive", "Subject: Copy me")).await.is_some(),
        "with Ctrl it is copied there",
    );
    d.check(d.find("INBOX", "Subject: Copy me").is_some(), "and stays in the Inbox");
}

pub async fn junk(d: &Driver) {
    d.step("junk and not junk");
    let main = shell().main();
    select_folder("Inbox");
    wait_until(10, || rows() >= 3).await;
    let junk_button = || {
        named("junk")
            .and_then(|b| b.downcast::<gtk::Button>().ok())
            .and_then(|b| b.action_name())
            .map(|a| a.to_string())
            .unwrap_or_default()
    };
    d.check(junk_button() == "win.junk", "the header bar has Junk in the Inbox");
    select_row(0).await;
    run_command(Command::Junk);
    let junked = wait_for(20, || d.find("Junk", "Subject: Copy me")).await;
    d.check(junked.is_some(), "Junk moves the message to Junk E-mail");
    let flags = d.flags("Junk", "Subject: Copy me");
    d.check(
        flags.iter().any(|f| f == "$Junk"),
        &format!("with the $Junk keyword ({})", flags.join(" ")),
    );
    d.check(d.find("INBOX", "Subject: Copy me").is_none(), "and out of the Inbox");
    select_folder("Junk E-mail");
    wait_until(20, || rows() >= 1).await;
    let swapped = wait_until(5, || junk_button() == "win.not-junk").await;
    d.check(swapped, "in Junk E-mail the header bar has Not Junk in its place");
    select_row(0).await;
    d.shot(main.window(), "organize-7-junk").await;
    run_command(Command::NotJunk);
    let back = wait_for(20, || d.find("INBOX", "Subject: Copy me")).await;
    d.check(back.is_some(), "Not Junk moves it back to the Inbox");
    let flags = d.flags("INBOX", "Subject: Copy me");
    let marked = flags.iter().any(|f| f == "$NotJunk") && !flags.iter().any(|f| f == "$Junk");
    d.check(
        marked,
        &format!("with $NotJunk in place of $Junk ({})", flags.join(" ")),
    );
    select_folder("Inbox");
}

/// The form that asks for a folder's name: the name typed and OK clicked
async fn answer_name(d: &Driver, title: &str, name: &str, shot: Option<&str>) {
    let form = wait_dialog(10, "folder-name-dialog").await;
    d.check(form.is_some(), &format!("{title} asks for a name"));
    if let Some(form) = form {
        set_text(form.upcast_ref(), "form-0", name);
        if let Some(shot) = shot {
            d.shot(&form, shot).await;
        }
        click(form.upcast_ref(), "dialog-ok");
        wait_gone(5, "folder-name-dialog").await;
    }
}

pub async fn folders(d: &Driver) {
    d.step("folders");
    select_folder("Archive");
    command(Command::NewFolder);
    answer_name(d, "New Folder", "Projects", Some("folders-1-new")).await;
    let made = wait_until(20, || d.mailboxes().iter().any(|m| m == "Archive/Projects")).await;
    d.check(made, "New Folder makes Archive/Projects on the server");
    let projects = wait_for(20, || folder_id("Projects")).await;
    d.check(projects.is_some(), "and it is in the tree");
    if let Some(projects) = projects {
        shell().main().folders.select(projects);
        pause(500).await;
        d.shot(&main_window(), "folders-2-tree").await;
        command(Command::RenameFolder);
        answer_name(d, "Rename Folder", "Plans", None).await;
        let renamed = wait_until(20, || {
            let all = d.mailboxes();
            all.iter().any(|m| m == "Archive/Plans") && !all.iter().any(|m| m == "Archive/Projects")
        })
        .await;
        d.check(renamed, "Rename renames it on the server");
        if let Some(plans) = wait_for(20, || folder_id("Plans")).await {
            shell().main().folders.select(plans);
            pause(300).await;
        }
        command(Command::DeleteFolder);
        let sure = wait_alert(10).await;
        d.check(sure.is_some(), "deleting a folder asks first");
        if let Some(sure) = sure {
            d.shot(&sure, "folders-3-delete").await;
            answer(&sure, "Yes");
        }
        let gone = wait_until(20, || !d.mailboxes().iter().any(|m| m == "Archive/Plans")).await;
        d.check(gone, "and Yes deletes it on the server");
    }
    // the Inbox is not renamed
    select_folder("Inbox");
    command(Command::RenameFolder);
    answer_name(d, "Rename Folder", "Mail", None).await;
    let refused = wait_alert(10).await;
    d.check(refused.is_some(), "renaming the Inbox is refused with the reason");
    if let Some(refused) = refused {
        d.shot(&refused, "folders-4-inbox").await;
        answer(&refused, "OK");
    }
}

pub async fn closing_a_message(d: &Driver) {
    d.step("closing a message that was written");
    run_command(Command::NewMail);
    let Some(c) = wait_compose(10).await else { return };
    c.editor.type_text("Never mind.");
    pause(500).await;
    c.window.close();
    let ask = wait_alert(10).await;
    d.check(ask.is_some(), "closing asks before throwing the text away");
    if let Some(ask) = ask {
        d.shot(&ask, "write-6-close").await;
        answer(&ask, "No");
    }
    d.check(wait_until(10, || !c.window.is_visible()).await, "No closes it");
    pause(1000).await;
    d.check(d.find("Drafts", "Never mind").is_none(), "without saving it");
}

pub async fn mailto(d: &Driver) {
    d.step("an e-mail link");
    // the mail program started with the link: the app already open for the store takes it over
    let link = "mailto:gina@example.com?subject=From%20a%20link&body=Hello%20Gina%2C";
    let store = d.out.join("store.db").to_string_lossy().into_owned();
    let exe = std::env::current_exe().unwrap_or_default();
    let second = Process::new(exe)
        .args([
            "--store",
            &store,
            "--memory-passwords",
            "--pin-certificate",
            &d.ports.cert,
            link,
        ])
        .spawn();
    let ended = match second {
        Ok(mut child) => wait_until(15, || child.try_wait().ok().flatten().is_some()).await,
        Err(_) => false,
    };
    d.check(ended, "a second start with a mailto: link hands it over and ends");
    let linked = wait_for(15, || compose().filter(|c| c.subject.text() == "From a link")).await;
    d.check(linked.is_some(), "the running app opens a new message from it");
    if let Some(c) = linked {
        wait_until(10, || c.editor.is_loaded()).await;
        d.check(
            c.to.text() == "gina@example.com",
            &format!("to the link's address ({})", c.to.text()),
        );
        d.shot(&c.window, "write-18-mailto").await;
        close_compose(&c).await;
    }
}

pub async fn completing(d: &Driver) {
    d.step("completing an address");
    run_command(Command::NewMail);
    let Some(c) = wait_compose(10).await else { return };
    c.to.grab_focus();
    // typed, a letter at a time
    if let Some(text) = c.to.delegate() {
        for letter in ["a", "n", "n"] {
            text.emit_by_name::<()>("insert-at-cursor", &[&letter]);
        }
    }
    let listed = wait_for(10, || crate::complete::shown_rows(&c.to).filter(|r| !r.is_empty())).await;
    d.check(
        listed.is_some(),
        "typing in To lists the people it may be, with someone heard from",
    );
    d.shot(&c.window, "write-17-complete").await;
    // a click takes one, with a comma for the next
    if let Some(row) = descendants::<gtk::ListBox>(c.to.upcast_ref())
        .first()
        .and_then(|l| l.row_at_index(0))
    {
        row.activate();
    }
    let taken = wait_until(5, || c.to.text() == "Ann Example <ann@example.com>, ").await;
    d.check(
        taken,
        &format!("a click takes the first, with a comma for the next ({})", c.to.text()),
    );
    d.check(crate::complete::shown_rows(&c.to).is_none(), "and closes the list");
    close_compose(&c).await;
}

/// Typed into the editor page of a web view (the signature editor's)
fn type_into(view: &webkit::WebView, text: &str) {
    let script = format!("pe.exec('insertText', {})", crate::webview::js_string(text));
    view.evaluate_javascript(&script, None, None, gtk::gio::Cancellable::NONE, |_| {});
}

pub async fn signature(d: &Driver) {
    d.step("a signature");
    command(Command::Accounts);
    let Some(accounts) = wait_dialog(10, "accounts-dialog").await else {
        d.check(false, "File > Accounts opens the accounts");
        return;
    };
    click(accounts.upcast_ref(), "accounts-signature");
    match wait_dialog(10, "signature-dialog").await {
        Some(dialog) => {
            let title = dialog.title();
            d.check(
                title.starts_with("Signature - "),
                &format!("titled with the account ({title})"),
            );
            pause(1500).await;
            if let Some(view) = descendants::<webkit::WebView>(dialog.upcast_ref()).first() {
                type_into(view, "Ann, signed by the UI test");
            }
            pause(600).await;
            d.shot(&dialog, "signature-1-editor").await;
            click(dialog.upcast_ref(), "dialog-ok");
            d.check(
                wait_gone(10, "signature-dialog").await,
                "OK saves it and closes the editor",
            );
        }
        None => d.check(false, "Signature opens the signature editor of the account"),
    }
    accounts.close();
    wait_gone(10, "accounts-dialog").await;
    // a new message starts with it, under the line to write on
    run_command(Command::NewMail);
    let Some(c) = wait_compose(10).await else { return };
    c.to.set_text("Fay <fay@example.com>");
    c.subject.set_text("Signed in the UI test");
    c.editor.type_text("Hello Fay.");
    pause(600).await;
    d.shot(&c.window, "signature-2-new").await;
    click(c.window.upcast_ref(), "compose-send");
    let signed = wait_for(30, || d.find("INBOX", "Subject: Signed in the UI test")).await;
    let raw = signed.as_ref().map(raw_text).unwrap_or_default();
    d.check(
        raw.contains("Ann, signed by the UI test"),
        "the message went with the signature",
    );
    let (hello, line, name) = (
        raw.find("Hello Fay"),
        raw.find("-- "),
        raw.find("Ann, signed by the UI test"),
    );
    let order = matches!((hello, line, name), (Some(h), Some(l), Some(s)) if h < l && l < s);
    d.check(order, "after what was written and the \"-- \" line");
}

pub async fn gmail(d: &Driver) {
    d.step("a Gmail address");
    command(Command::NewAccount);
    let Some(first) = wait_dialog(20, "account-start").await else {
        d.check(false, "the account form opens");
        return;
    };
    set_text(first.upcast_ref(), "start-name", "Gmail Test");
    set_text(first.upcast_ref(), "start-email", "postalexpress.test@gmail.com");
    click(first.upcast_ref(), "dialog-ok");
    // the built-in Google client is off out of the box and no sign-in app is added: the app password way follows
    let hint = wait_alert(40).await;
    d.check(
        hint.is_some(),
        "without it, Gmail wants an app password, and that is said",
    );
    let direct = dialog_named("account-start").is_none();
    d.check(
        direct,
        "with Google turned off, a Gmail address goes to the app password way",
    );
    if let Some(hint) = hint {
        d.shot(&hint, "account-5-app-password").await;
        answer(&hint, "No");
    }
    match wait_dialog(20, "account-servers").await {
        Some(servers) => {
            let imap = text_of(servers.upcast_ref(), "form-4");
            let smtp = text_of(servers.upcast_ref(), "form-7");
            d.check(
                imap == "imap.gmail.com" && smtp == "smtp.gmail.com",
                &format!("its servers were found ({imap}, {smtp})"),
            );
            d.shot(&servers, "account-6-gmail").await;
            click(servers.upcast_ref(), "dialog-cancel");
            wait_gone(10, "account-servers").await;
        }
        None => d.check(false, "its servers were found"),
    }
}

pub async fn closing(d: &Driver) {
    d.step("closing");
    run_command(Command::NewMail);
    let Some(c) = wait_compose(10).await else { return };
    c.subject.set_text("Still writing");
    c.editor.type_text("Not done yet.");
    pause(600).await;
    // without a place for the tray icon (no tray host here), Quit and the close button both end the app
    d.check(shell().tray.borrow().is_none(), "without a tray host there is no icon");
    command(Command::Exit);
    let ask = wait_alert(10).await;
    d.check(ask.is_some(), "closing the app asks about a message with changes");
    if let Some(ask) = ask {
        d.shot(&ask, "write-12-close-app").await;
        answer(&ask, "Cancel");
        pause(1000).await;
        let kept = shell().main().window().is_visible() && c.window.is_visible();
        d.check(kept, "Cancel keeps the app and the message open");
    }
    shell().main().window().close();
    if let Some(ask) = wait_alert(10).await {
        answer(&ask, "No");
    }
    d.check(
        wait_until(10, || !c.window.is_visible()).await,
        "No closes the message without saving, and the app",
    );
}
