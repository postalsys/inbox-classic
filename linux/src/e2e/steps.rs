//! The later steps of the UI test, in the order of scripts/ui-e2e.ps1: unsubscribing from a list, a calendar
//! invitation, a brand's logo, Mark All Read, dragging onto a folder, several messages and Undo, junk, folders,
//! closing a message, an e-mail link handed over by a second start, address completion, a signature, a Gmail address,
//! and closing the app.

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
    folder_of(0, name)
}

/// The id of a folder of the account at `index` (0 the first) by the name the tree gives it
pub(super) fn folder_of(index: usize, name: &str) -> Option<i64> {
    let core = &shell().core;
    let account = core.accounts().ok()?.get(index)?.id;
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
        "Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=list.example.com\r\n\
         DKIM-Signature: v=1; d=list.example.com; s=s1; h=from:subject:list-unsubscribe:list-unsubscribe-post; bh=x; \
         b=y\r\nFrom: Weekly List <news@list.example.com>\r\nTo: testuser@inboxclassic.test\r\n\
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
    let done = wait_until(10, || {
        shell().main().status_texts().0.contains("Unsubscribe request accepted")
    })
    .await;
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
        "From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\n\
         Subject: Invitation: Quarterly planning\r\nDate: {}\r\nMessage-ID: <planning-invite@example.com>\r\n\
         Content-Type: multipart/mixed; boundary=inv\r\n\r\n--inv\r\nContent-Type: text/plain\r\n\r\n\
         Let us plan the quarter.\r\n--inv\r\nContent-Type: text/calendar; method=REQUEST; charset=utf-8\r\n\r\n\
         BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nUID:planning@example.com\r\n\
         SUMMARY:Quarterly planning\r\nDTSTART:20261201T100000Z\r\nDTEND:20261201T113000Z\r\nLOCATION:Room 2\r\n\
         ORGANIZER;CN=Ann Example:mailto:ann@example.com\r\nATTENDEE;CN=Test:mailto:testuser@inboxclassic.test\r\n\
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
        "Authentication-Results: mx.inboxclassic.test; dmarc=pass header.from=brand.example; bimi=pass \
         header.d=brand.example\r\nBIMI-Indicator: {indicator}\r\nFrom: Brand <hello@brand.example>\r\n\
         To: testuser@inboxclassic.test\r\nSubject: News from the brand\r\nDate: {}\r\n\
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

pub async fn collapsed_account(d: &Driver) {
    d.step("a collapsed account");
    let core = &shell().core;
    let account = core.accounts().ok().and_then(|a| a.first().map(|a| a.id)).unwrap_or(0);
    let inbox = core
        .folders(account)
        .unwrap_or_default()
        .into_iter()
        .find(|f| pe_core::folder_name(&f.info) == "Inbox");
    let inbox_unread = inbox.as_ref().map_or(0, |f| f.unread);
    let inbox_id = inbox.map_or(0, |f| f.id);
    let tree = || shell().main().folders.clone();
    let label = |id: i64| tree().markup_of(id).unwrap_or_default();
    d.check(
        inbox_unread >= 1,
        &format!("the Inbox has unread messages ({})", label(inbox_id)),
    );
    tree().set_expanded(-account, false);
    let counted = |markup: &str| {
        markup
            .rsplit_once(" (")
            .and_then(|(_, n)| n.trim_end_matches(")</b>").parse::<u64>().ok())
            .unwrap_or(0)
    };
    d.check(
        wait_until(5, || counted(&label(-account)) >= inbox_unread).await,
        &format!(
            "collapsed, the account shows the unread messages of its folders ({})",
            label(-account)
        ),
    );
    d.check(label(-account).starts_with("<b>"), "and is bold");
    d.shot(&main_window(), "folders-5-collapsed").await;
    tree().set_expanded(-account, true);
    d.check(
        wait_until(5, || {
            counted(&label(-account)) == 0 && counted(&label(inbox_id)) == inbox_unread
        })
        .await,
        "expanded, the count is back on the Inbox alone",
    );
}

/// The lines the test's agent (scripts/ui-e2e/agent.mjs) wrote: the result of `step`
fn agent_said(file: &std::path::Path, step: &str) -> Option<Value> {
    let text = std::fs::read_to_string(file).ok()?;
    text.lines()
        .filter_map(|line| serde_json::from_str::<Value>(line).ok())
        .find(|entry| entry["step"] == step)
        .map(|entry| entry["result"].clone())
}

/// An AI agent through --mcp: let in, reading and marking messages read as the window shows, sending only after a yes
pub async fn agent(d: &Driver) {
    d.step("an AI agent");
    select_folder("Inbox");
    // two new messages for the agent to read, whatever the steps before left unread
    let rows_before = rows();
    for (from, subject, body) in [
        (
            "Maria Lopez <maria@example.org>",
            "Quarterly report draft",
            "Here is the draft of the quarterly report. Comments by Thursday?",
        ),
        (
            "Sam Lee <sam@example.org>",
            "Team lunch on Friday",
            "Who is in for lunch on Friday at noon?",
        ),
    ] {
        let id = glib::uuid_string_random();
        let raw = format!(
            "From: {from}\r\nTo: testuser@inboxclassic.test\r\nSubject: {subject}\r\nMessage-ID: <{id}@example.org>\r\n\r\n{body}\r\n"
        );
        let _ = d.add_message(&raw, &[]);
    }
    run_command(Command::Sync);
    wait_until(20, || rows() >= rows_before + 2).await;
    let unread = || d.unread_at(d.ports.rest);
    let before = unread();
    d.shot(&main_window(), "agents-1-before").await;
    // the agent: Node.js under a name of its own, as an agent host would be, starting the relay (--mcp)
    let out = d.out.join("agent.jsonl");
    let host = d.out.join("My AI agent");
    let node = std::process::Command::new("sh")
        .args(["-c", "command -v node"])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default();
    let _ = std::fs::remove_file(&host);
    let copied = std::fs::copy(&node, &host).is_ok();
    d.check(copied, &format!("the test's agent is ready ({node})"));
    let script = harness_dir().join("../../scripts/ui-e2e/agent.mjs");
    let mut agent = std::process::Command::new(&host)
        .arg(&script)
        .env("APP", std::env::current_exe().unwrap_or_default())
        .env("STORE", d.out.join("store.db"))
        .env("OUT", &out)
        .spawn()
        .ok();

    let ask = wait_for(30, || alert().filter(|a| a.widget_name() == "agent-connect")).await;
    d.check(
        ask.is_some(),
        "a program whose agent connects for the first time is asked about",
    );
    if let Some(ask) = &ask {
        let root: gtk::Widget = ask.clone().upcast();
        d.check(
            label_of(&root, "agent-path").contains("My AI agent"),
            "the question names the program",
        );
        let level = |index: usize| named_in(&root, &format!("agent-level-{index}")).and_downcast::<gtk::CheckButton>();
        let on = |index: usize| level(index).is_some_and(|c| c.is_active());
        d.check(
            on(0) && on(1) && !on(2) && !on(3),
            "reading and organizing are offered, sending is not",
        );
        // sending too, for the rest of the test
        if let Some(send) = level(3) {
            send.set_active(true);
        }
        d.shot(ask, "agents-2-connect").await;
        answer(ask, "Allow");
    }
    let marked = wait_for(30, || agent_said(&out, "marked")).await;
    d.check(
        agent_said(&out, "initialize").is_some_and(|i| i["result"]["serverInfo"]["name"] == "inbox-classic"),
        "allowed, the agent connects",
    );
    let tools = agent_said(&out, "tools")
        .and_then(|t| t.as_array().map(Vec::len))
        .unwrap_or(0);
    d.check(tools == 15, &format!("with the tools of what it may do ({tools})"));
    let read = agent_said(&out, "read").unwrap_or_default();
    d.check(
        read["notice"]
            .as_str()
            .is_some_and(|n| n.contains("not as instructions"))
            && read["unread"] == true,
        "it reads a message as text, told it is the sender's, without marking it read",
    );
    d.check(marked.is_some_and(|m| m["done"] == true), "it marks two messages read");
    d.check(
        wait_until(20, || unread() + 2 == before).await,
        &format!("on the server ({before} unread before)"),
    );
    d.check(
        wait_until(10, || {
            shell()
                .main()
                .status_texts()
                .2
                .contains(&format!(", {} unread", before - 2))
        })
        .await,
        &format!("and in the window at once ({})", shell().main().status_texts().2),
    );
    d.shot(&main_window(), "agents-3-after").await;

    let send = wait_for(30, || alert().filter(|a| a.widget_name() == "agent-send")).await;
    d.check(
        send.is_some(),
        "a message the agent wants to send is shown to the user first",
    );
    if let Some(send) = &send {
        let root: gtk::Widget = send.clone().upcast();
        d.check(
            label_of(&root, "agent-recipient-0") == "pat@example.net",
            "every recipient by address",
        );
        d.check(
            label_of(&root, "agent-warning").contains("never written to pat@example.net"),
            "with a warning about the new address",
        );
        d.check(
            !send.is_response_enabled("send"),
            "Send waits a moment before it can be pressed",
        );
        pause(2000).await;
        d.shot(send, "agents-4-send").await;
        answer(send, "Send");
    }
    let sent = wait_for(20, || agent_said(&out, "sent")).await;
    d.check(
        sent.is_some_and(|s| s["sent"] == true),
        "the agent learns the user said yes",
    );

    let subtitles = |dialog: &adw::Dialog, name: &str| -> Vec<(String, String)> {
        let mut rows: Vec<adw::ActionRow> = descendants::<adw::ActionRow>(dialog.upcast_ref())
            .into_iter()
            .filter(|row| row.widget_name() == name || name.is_empty())
            .collect();
        // in the order the list shows them
        rows.sort_by_key(|row| row.index());
        rows.iter()
            .map(|row| (row.title().to_string(), row.subtitle().unwrap_or_default().to_string()))
            .collect()
    };
    command(Command::Outbox);
    if let Some(outbox) = wait_dialog(10, "outbox-dialog").await {
        let rows = subtitles(&outbox, "");
        d.check(
            rows.first()
                .is_some_and(|(_, subtitle)| subtitle.contains("Queued by an AI agent; sends at")),
            "it waits in the Outbox, where it can still be deleted",
        );
        d.shot(&outbox, "agents-5-outbox").await;
        outbox.close();
        wait_gone(10, "outbox-dialog").await;
    }
    command(Command::AiAgents);
    match wait_dialog(10, "agents-dialog").await {
        Some(agents) => {
            let hosts = subtitles(&agents, "agents-host");
            d.check(
                hosts.first().is_some_and(|(name, access)| {
                    name == "My AI agent" && access.starts_with("Read, organize and send with your yes")
                }),
                &format!("it lists the program and what it may do ({hosts:?})"),
            );
            let entries = subtitles(&agents, "agents-entry");
            d.check(
                entries
                    .first()
                    .is_some_and(|(what, _)| what.starts_with("Sent \"Lunch on Friday?\" to pat@example.net"))
                    && entries.get(1).is_some_and(|(what, _)| what.starts_with("Marked read")),
                &format!("and what its agent did, newest first ({entries:?})"),
            );
            d.shot(&agents, "agents-6-window").await;
            click(agents.upcast_ref(), "agents-undo");
            d.check(
                wait_until(10, || {
                    subtitles(&agents, "agents-entry")
                        .first()
                        .is_some_and(|(what, _)| what.contains("taken back"))
                })
                .await,
                "Undo takes the message back",
            );
            agents.close();
            wait_gone(10, "agents-dialog").await;
        }
        None => d.check(false, "Tools > AI Agents opens"),
    }
    d.check(
        shell().core.outbox().unwrap_or_default().is_empty(),
        "and the Outbox is empty",
    );
    if let Some(agent) = agent.as_mut() {
        let _ = agent.kill();
        let _ = agent.wait();
    }
}

pub async fn mark_all_read(d: &Driver) {
    d.step("marking all read");
    select_folder("Inbox");
    wait_until(10, || rows() >= 5).await;
    let unread_on_server = || d.unread_at(d.ports.rest);
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
            "From: Dana <dana@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: {subject}\r\nDate: {}\r\n\
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
    let payload = |m: &pe_store::Message| {
        vec![pe_store::MessageRef {
            folder: m.folder_id,
            uid: m.info.uid,
        }]
    };
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

pub async fn several_messages(d: &Driver) {
    d.step("several messages");
    let main = shell().main();
    let core = &shell().core;
    select_folder("Inbox");
    wait_until(10, || rows() >= 5).await;
    let listed = rows();
    // the first row stays out of it: the junk step after this one takes it
    select_row(1).await;
    main.list.selection.select_item(2, false);
    main.list.selection.select_item(3, false);
    pause(500).await;
    d.check(
        main.list.selected_count() == 3,
        "Ctrl+click adds two more messages: three are selected",
    );
    let refs = main.selected_refs();
    let subjects: Vec<String> = refs
        .iter()
        .filter_map(|r| core.message(r.folder, r.uid).ok().flatten())
        .map(|m| m.info.subject)
        .collect();
    let needles: Vec<String> = subjects.iter().map(|s| format!("Subject: {s}")).collect();
    let all_on_server = |mailbox: &str| needles.iter().all(|n| d.find(mailbox, n).is_some());
    let none_on_server = |mailbox: &str| needles.iter().all(|n| d.find(mailbox, n).is_none());
    run_command(Command::MarkUnread);
    let summary = || main.reader.summary_shown().unwrap_or_default();
    let said = wait_until(10, || summary().0 == "3 messages selected" && summary().1 == "3 unread").await;
    d.check(
        said,
        &format!(
            "the reading pane says 3 messages are selected, and how many of them are unread ({:?})",
            summary()
        ),
    );
    let counts = main.status_texts().2;
    d.check(
        counts.ends_with(", 3 selected"),
        &format!("the status bar says 3 selected ({counts})"),
    );
    let enabled = |command: Command| {
        main.window()
            .lookup_action(command.name())
            .is_some_and(|a| a.is_enabled())
    };
    d.check(
        !enabled(Command::Reply) && enabled(Command::MarkRead),
        "Reply is off for several, Mark as Read is on",
    );
    d.shot(main.window(), "select-1-several").await;
    run_command(Command::MarkRead);
    d.check(
        wait_until(20, || needles.iter().all(|n| d.seen(n))).await,
        "Mark as Read marks the three read on the server",
    );
    command(Command::Move);
    match wait_dialog(10, "move-dialog").await {
        Some(dialog) => {
            if let Some(archive) = folder_id("Archive") {
                pick_folder(&dialog, archive);
            }
            click(dialog.upcast_ref(), "dialog-ok");
        }
        None => d.check(false, "Move to Folder asks where"),
    }
    d.check(
        wait_until(20, || all_on_server("Archive")).await,
        &format!("Move to Folder moves the three to Archive ({})", subjects.join(", ")),
    );
    d.check(wait_until(10, || rows() == listed - 3).await, "and out of the list");
    let status = main.status_texts().0;
    d.check(
        status == "Moved 3 messages to Archive",
        &format!("the status bar says they were moved to Archive ({status})"),
    );
    run_command(Command::Undo);
    let back = wait_until(10, || main.status_texts().0 == "Moved 3 messages back to Inbox").await;
    d.check(
        back,
        &format!(
            "Edit > Undo Move brings them back to the Inbox ({})",
            main.status_texts().0
        ),
    );
    d.check(
        wait_until(20, || all_on_server("INBOX") && none_on_server("Archive")).await,
        "and on the server",
    );
    wait_until(10, || rows() == listed).await;
    let selected_subjects = || {
        let mut found: Vec<String> = main
            .selected_refs()
            .iter()
            .filter_map(|r| core.message(r.folder, r.uid).ok().flatten())
            .map(|m| m.info.subject)
            .collect();
        found.sort();
        found
    };
    let mut expected = subjects.clone();
    expected.sort();
    d.check(
        wait_until(20, || selected_subjects() == expected).await,
        &format!(
            "the three that came back are selected ({})",
            selected_subjects().join(", ")
        ),
    );
    pause(500).await;
    d.shot(main.window(), "select-2-undo").await;
    run_command(Command::SelectAll);
    pause(300).await;
    d.check(
        main.list.selected_count() == u64::from(rows()),
        &format!(
            "Select All selects every message of the list ({} of {})",
            main.list.selected_count(),
            rows()
        ),
    );
    select_row(0).await;
    let shown = wait_until(10, || {
        main.reader.summary_shown().is_none() && !main.reader.header_text().starts_with(" |")
    })
    .await;
    d.check(shown, "one message selected again is shown in the reading pane");
}

/// SCENARIO 32: messages dragged out as .eml files, saved several at once, forwarded as attachments, and .eml files
/// dropped onto a folder
pub async fn messages_as_files(d: &Driver) {
    d.step("messages as files");
    let main = shell().main();
    let core = &shell().core;
    select_folder("Inbox");
    wait_until(10, || rows() >= 3).await;
    let listed = rows();
    // one the app has not downloaded: it comes now, on top
    let raw = |subject: &str, body: &str| {
        let id: String = subject.chars().filter(char::is_ascii_alphanumeric).collect();
        format!(
            "From: Nina Berg <nina@example.org>\r\nTo: testuser@inboxclassic.test\r\nSubject: {subject}\r\n\
             Message-ID: <{id}@example.org>\r\nDate: Fri, 6 Nov 2026 10:00:00 +0000\r\n\r\n{body}\r\n"
        )
    };
    let _ = d.add_message(&raw("Not opened yet", "Downloaded for the drag."), &[]);
    run_command(Command::Sync);
    d.check(
        wait_until(30, || rows() == listed + 1).await,
        "a message not downloaded yet is in the list",
    );
    // the one added and the two after it in the list
    let position = folder_id("Inbox").and_then(|inbox| {
        core.search(&pe_core::Search::folder(inbox), main.list.sort(), 0, 200)
            .unwrap_or_default()
            .iter()
            .position(|m| m.info.subject == "Not opened yet")
    });
    let first = position.unwrap_or(0) as u32;
    let first = first.min(rows().saturating_sub(3));
    // a neighbour first: the one added selected alone would be opened, and downloaded, by the reading pane
    let alone = if position.is_some_and(|p| p as u32 == first) {
        first + 1
    } else {
        first
    };
    select_row(alone).await;
    for index in first..first + 3 {
        main.list.selection.select_item(index, false);
    }
    wait_until(10, || main.selected_refs().len() == 3).await;
    let refs = main.selected_refs();
    let added = refs.iter().copied().find(|r| {
        core.message(r.folder, r.uid)
            .ok()
            .flatten()
            .is_some_and(|m| m.info.subject == "Not opened yet")
    });
    let names = core.export_names(&refs).unwrap_or_default();
    d.check(
        refs.len() == 3 && added.is_some_and(|r| !core.all_downloaded(&[r]).unwrap_or(true)),
        "three selected, one of them not downloaded yet",
    );

    // what a file manager reads of the drag: text/uri-list, the files written then
    let provider = crate::files::drag_content(refs.clone());
    let stream = gio::MemoryOutputStream::new_resizable();
    let written = provider
        .write_mime_type_future("text/uri-list", &stream, glib::Priority::DEFAULT)
        .await;
    let _ = stream.close(gio::Cancellable::NONE);
    let list = String::from_utf8_lossy(&stream.steal_as_bytes()).into_owned();
    let paths: Vec<std::path::PathBuf> = list
        .lines()
        .filter_map(|line| gio::File::for_uri(line.trim()).path())
        .collect();
    let file_names: Vec<String> = paths
        .iter()
        .filter_map(|p| p.file_name().map(|n| n.to_string_lossy().into_owned()))
        .collect();
    d.check(
        written.is_ok() && file_names == names && names.iter().all(|n| n.ends_with(".eml")),
        &format!(
            "three messages dragged out of the list become three .eml files, named after their subjects ({})",
            file_names.join(", ")
        ),
    );
    let same = refs.iter().zip(&paths).all(|(r, path)| {
        let source = core
            .message_source(r.folder, r.uid)
            .ok()
            .flatten()
            .map(|(_, bytes)| bytes);
        source.is_some() && std::fs::read(path).ok() == source
    });
    d.check(same, "with what each message is, byte for byte");
    d.check(
        added.is_some_and(|r| core.all_downloaded(&[r]).unwrap_or(false)),
        "one not downloaded yet is downloaded for it",
    );
    d.check(
        !provider.formats().contain_mime_type("text/plain"),
        "other programs are offered files, not text",
    );
    // the three in sight for the picture
    main.list.reveal(&[u64::from(first), u64::from(first) + 2]);
    main.list.view.scroll_to(
        first + 2,
        None::<&gtk::ColumnViewColumn>,
        gtk::ListScrollFlags::NONE,
        None,
    );
    pause(500).await;
    d.shot(main.window(), "files-4-drag-out").await;

    // Save As with the three: into a folder, never over a file there
    let dir = d.out.join("saved-several");
    let _ = std::fs::remove_dir_all(&dir);
    let _ = std::fs::create_dir_all(&dir);
    if let Some(first) = names.first() {
        let _ = std::fs::write(dir.join(first), "mine");
    }
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![dir.clone()]));
    run_command(Command::SaveAs);
    let said = wait_until(30, || main.status_texts().0 == "Saved 3 messages to saved-several").await;
    let in_dir = std::fs::read_dir(&dir).map(|e| e.count()).unwrap_or(0);
    let kept = names
        .first()
        .and_then(|n| std::fs::read_to_string(dir.join(n)).ok())
        .is_some_and(|c| c == "mine");
    d.check(
        said && in_dir == 4 && kept,
        &format!(
            "Save As with three selected asks for a folder and saves the three there, never over a file that is there \
             ({}, {in_dir} files)",
            main.status_texts().0
        ),
    );

    // Forward with the three: one message, them attached
    let first_subject = refs
        .first()
        .and_then(|r| core.message(r.folder, r.uid).ok().flatten())
        .map(|m| m.info.subject)
        .unwrap_or_default();
    run_command(Command::Forward);
    match wait_compose(30).await {
        Some(c) => {
            let attached = c.attached();
            d.check(
                attached.len() == 3 && attached.iter().all(|p| p.extension().is_some_and(|e| e == "eml")),
                &format!(
                    "Forward with three selected writes one new message with the three attached as .eml files ({})",
                    attached.len()
                ),
            );
            d.check(
                c.subject.text() == format!("Fw: {first_subject}"),
                &format!("its subject is the first one's, with Fw: ({})", c.subject.text()),
            );
            d.shot(&c.window, "files-5-forward").await;
            close_compose(&c).await;
        }
        None => d.check(false, "Forward with three selected writes one new message"),
    }

    // the one added is not the steps' after this one: it goes
    if let Some(added) = added {
        let _ = core.act(&[added], pe_core::Action::Delete);
    }
    wait_until(10, || rows() == listed).await;

    // .eml files from a file manager onto Archive
    let drop_dir = d.out.join("dropped");
    let _ = std::fs::remove_dir_all(&drop_dir);
    let _ = std::fs::create_dir_all(&drop_dir);
    let mut dropped = Vec::new();
    for (n, subject) in ["Dropped one", "Dropped two", "Dropped three"].iter().enumerate() {
        let path = drop_dir.join(format!("{n}.eml"));
        let _ = std::fs::write(&path, raw(subject, "Dropped onto a folder."));
        dropped.push(path);
    }
    let text = drop_dir.join("notes.txt");
    let _ = std::fs::write(&text, "not a message");
    let mut with_text = dropped.clone();
    with_text.push(text.clone());
    d.check(
        !crate::files::takes(std::slice::from_ref(&text)),
        "a file that is not a message is turned away",
    );
    match folder_id("Archive") {
        Some(archive) => {
            let mailbox = main.clone();
            crate::app::spawn(async move { mailbox.drop_files(Some(archive), with_text).await });
        }
        None => d.check(false, "the tree has Archive"),
    }
    // the messages go in; the file that is not one is named
    match wait_alert(30).await {
        Some(report) => {
            let text = alert_text(&report);
            d.check(
                text.contains("notes.txt"),
                &format!("dropped with them, it is left out and named ({text})"),
            );
            answer(&report, "OK");
        }
        None => d.check(false, "dropped with them, it is left out and named"),
    }
    d.check(
        wait_until(30, || {
            ["Dropped one", "Dropped two", "Dropped three"]
                .iter()
                .all(|s| d.find("Archive", &format!("Subject: {s}")).is_some())
        })
        .await,
        ".eml files dropped onto Archive in the folder tree are put in it, on the server",
    );
    let said = main.status_texts().0;
    d.check(
        said == "Put 3 messages in Archive",
        &format!("the status bar says they were put in Archive ({said})"),
    );
    select_folder("Archive");
    wait_until(20, || rows() >= 3).await;
    // one of them shown, as it came
    let dropped_at = folder_id("Archive").and_then(|archive| {
        core.search(&pe_core::Search::folder(archive), main.list.sort(), 0, 200)
            .unwrap_or_default()
            .iter()
            .position(|m| m.info.subject == "Dropped three")
    });
    select_row(dropped_at.unwrap_or(0) as u32).await;
    d.shot(main.window(), "files-6-drop-in").await;
    select_folder("Inbox");
}

/// SCENARIO 33: flag colours, as Apple Mail keeps them on the server
pub async fn flag_colors(d: &Driver) {
    d.step("flag colours");
    let main = shell().main();
    let core = &shell().core;
    select_folder("Inbox");
    wait_until(10, || rows() >= 3).await;
    let listed = rows();
    // dated now, so it is on top with the others the step flags, all in sight
    let raw = format!(
        "From: Nina Berg <nina@example.org>\r\nTo: testuser@inboxclassic.test\r\nSubject: Flagged in Apple Mail\r\n\
         Message-ID: <flagged-in-apple-mail@example.org>\r\nDate: {}\r\n\r\nPurple there.\r\n",
        date_now(0)
    );
    // purple as Apple Mail sets it: the flag, bits 0 and 2
    let _ = d.add_message(&raw, &["\\Flagged", "$MailFlagBit0", "$MailFlagBit2"]);
    run_command(Command::Sync);
    d.check(
        wait_until(30, || rows() == listed + 1).await,
        "a message flagged by another program is in the list",
    );
    let Some(inbox) = folder_id("Inbox") else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    let listing = || {
        core.search(&pe_core::Search::folder(inbox), main.list.sort(), 0, 200)
            .unwrap_or_default()
    };
    // the flags the list draws, by the colour each says
    let drawn = || -> Vec<String> {
        let view: gtk::Widget = main.list.view.clone().upcast();
        descendants::<gtk::DrawingArea>(&view)
            .iter()
            .filter(|a| a.is_mapped())
            .filter_map(|a| a.tooltip_text().map(|t| t.to_string()))
            .collect()
    };
    main.list
        .view
        .scroll_to(0, None::<&gtk::ColumnViewColumn>, gtk::ListScrollFlags::NONE, None);
    d.check(
        wait_until(10, || drawn().iter().any(|c| c == "Purple")).await,
        &format!(
            "a message flagged purple by another program (Apple Mail) shows a purple flag ({})",
            drawn().join(", ")
        ),
    );

    // three that have no flag, near the top so their flags are in sight
    let plain: Vec<(u32, String)> = listing()
        .iter()
        .enumerate()
        .filter(|(_, m)| m.info.flag_color().is_none())
        .take(3)
        .map(|(i, m)| (i as u32, m.info.subject.clone()))
        .collect();
    if plain.len() < 3 {
        d.check(false, "the Inbox has three messages without a flag");
        return;
    }
    let flags_of = |subject: &str| d.flags("INBOX", &format!("Subject: {subject}"));
    let has = |subject: &str, flag: &str| flags_of(subject).iter().any(|f| f == flag);
    let flag_in = |number: i32| {
        gio::prelude::ActionGroupExt::activate_action(main.window(), "flag-color", Some(&number.to_variant()))
    };

    // the Flag menu: the seven colours and Clear Flag
    select_row(plain[0].0).await;
    let list_view: gtk::Widget = main.list.view.clone().upcast();
    main.flag_menu_at(&list_view, 60.0, 60.0);
    // the colour names, then Clear Flag
    let labels: Vec<String> = menu_labels(main.message_popover.borrow().as_ref())
        .iter()
        .map(|l| l.trim().to_string())
        .collect();
    if let Some(popover) = main.message_popover.borrow().as_ref() {
        popover.popdown();
    }
    d.check(
        labels
            == [
                "Red",
                "Orange",
                "Yellow",
                "Green",
                "Blue",
                "Purple",
                "Gray",
                "Clear Flag",
            ],
        &format!(
            "Message > Flag has the seven colours of Apple Mail and Clear Flag ({})",
            labels.join(", ")
        ),
    );

    // orange on one: the flag and bit 0
    let orange = plain[0].1.clone();
    flag_in(2);
    d.check(
        wait_until(20, || {
            has(&orange, "\\Flagged") && has(&orange, "$MailFlagBit0") && !has(&orange, "$MailFlagBit1")
        })
        .await,
        &format!(
            "Orange flags the message orange: \\Flagged and $MailFlagBit0 on the server ({})",
            flags_of(&orange).join(" ")
        ),
    );
    d.check(
        main.status_texts().0 == "Flagged 1 message orange",
        &format!("the status bar says so ({})", main.status_texts().0),
    );
    d.check(
        wait_until(10, || drawn().iter().any(|c| c == "Orange")).await,
        "the flag column shows it in orange",
    );

    // blue on two selected: bit 2 on both
    let (blue_a, blue_b) = (plain[1].1.clone(), plain[2].1.clone());
    select_row(plain[1].0).await;
    main.list.selection.select_item(plain[2].0, false);
    wait_until(10, || main.selected_refs().len() == 2).await;
    flag_in(5);
    d.check(
        wait_until(20, || {
            [&blue_a, &blue_b]
                .iter()
                .all(|s| has(s, "\\Flagged") && has(s, "$MailFlagBit2") && !has(s, "$MailFlagBit0"))
        })
        .await,
        "Blue on two selected messages flags both blue: $MailFlagBit2",
    );
    let marks = wait_until(10, || {
        main.window().action_state("flag-color").and_then(|v| v.get::<i32>()) == Some(5)
    })
    .await;
    let marked = main.window().action_state("flag-color").and_then(|v| v.get::<i32>());
    d.check(
        marks,
        &format!("the Flag menu marks the colour the selected messages have ({marked:?})"),
    );

    // the picture: the colours in the list, the Flag menu over it
    main.list
        .view
        .scroll_to(0, None::<&gtk::ColumnViewColumn>, gtk::ListScrollFlags::NONE, None);
    wait_until(10, || drawn().iter().filter(|c| *c == "Blue").count() == 2).await;
    main.flag_menu_at(&list_view, 70.0, 150.0);
    pause(400).await;
    d.shot(main.window(), "flags-1-colors").await;
    if let Some(popover) = main.message_popover.borrow().as_ref() {
        popover.popdown();
    }

    // Clear Flag on the four: the flag and its colour go
    let purple = listing()
        .iter()
        .position(|m| m.info.subject == "Flagged in Apple Mail")
        .map(|p| p as u32);
    select_row(plain[0].0).await;
    for index in [plain[1].0, plain[2].0].into_iter().chain(purple) {
        main.list.selection.select_item(index, false);
    }
    wait_until(10, || main.selected_refs().len() == 4).await;
    gio::prelude::ActionGroupExt::activate_action(main.window(), "flag-clear", None);
    let all = [
        orange.as_str(),
        blue_a.as_str(),
        blue_b.as_str(),
        "Flagged in Apple Mail",
    ];
    d.check(
        wait_until(20, || {
            all.iter().all(|s| {
                flags_of(s)
                    .iter()
                    .all(|f| f != "\\Flagged" && !f.starts_with("$MailFlagBit"))
            })
        })
        .await,
        "Clear Flag takes the flag and its colour away on the server",
    );
    // the one added is not the steps' after this one: it goes
    if let Some(added) = listing()
        .iter()
        .find(|m| m.info.subject == "Flagged in Apple Mail")
        .map(|m| pe_core::MessageRef {
            folder: inbox,
            uid: m.info.uid,
        })
    {
        let _ = core.act(&[added], pe_core::Action::Delete);
    }
    wait_until(10, || rows() == listed).await;
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
    archive(d).await;
}

/// Archive: the message into the Archive folder, then back with Undo
async fn archive(d: &Driver) {
    d.step("archive");
    let main = shell().main();
    wait_until(20, || rows() >= 3).await;
    let row = wait_for(20, || {
        let all = pe_core::Search::folder(folder_id("Inbox")?);
        shell()
            .core
            .search(&all, main.list.sort(), 0, 50)
            .ok()?
            .iter()
            .position(|m| m.info.subject == "Copy me")
    })
    .await;
    select_row(row.unwrap_or(0) as u32).await;
    d.check(main.can_archive(), "Archive is on for a message of the Inbox");
    run_command(Command::Archive);
    let archived = wait_for(20, || d.find("Archive", "Subject: Copy me")).await;
    d.check(archived.is_some(), "Archive moves the message to Archive on the server");
    d.check(d.find("INBOX", "Subject: Copy me").is_none(), "and out of the Inbox");
    let said = wait_until(10, || main.status_texts().0.starts_with("Archived 1 message")).await;
    d.check(
        said,
        &format!("the status bar says it was archived ({})", main.status_texts().0),
    );
    d.shot(main.window(), "organize-8-archive").await;
    run_command(Command::Undo);
    let back = wait_for(20, || d.find("INBOX", "Subject: Copy me")).await;
    d.check(back.is_some(), "Undo puts it back in the Inbox");
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
    set_text(first.upcast_ref(), "start-email", "inboxclassic.test@gmail.com");
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

/// A server that takes connections and says nothing, until it is stopped: a download that waits
struct SilentServer {
    port: u16,
    clients: std::sync::Arc<std::sync::Mutex<Vec<std::net::TcpStream>>>,
}

impl SilentServer {
    fn start() -> SilentServer {
        let listener = std::net::TcpListener::bind("127.0.0.1:0").expect("a socket for the silent server");
        let port = listener.local_addr().map(|a| a.port()).unwrap_or(0);
        let clients: std::sync::Arc<std::sync::Mutex<Vec<std::net::TcpStream>>> = Default::default();
        let kept = clients.clone();
        std::thread::spawn(move || {
            for stream in listener.incoming().flatten() {
                kept.lock().unwrap().push(stream);
            }
        });
        SilentServer { port, clients }
    }

    /// every connection closed
    fn stop(&self) {
        for stream in self.clients.lock().unwrap().drain(..) {
            let _ = stream.shutdown(std::net::Shutdown::Both);
        }
    }
}

pub async fn not_downloaded(d: &Driver) {
    d.step("a message that is not downloaded yet");
    let main = main_window();
    let raw = format!(
        "From: Hal Example <hal@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Waiting on the server\r\n\
         Message-ID: <waiting@example.com>\r\nDate: {}\r\n\r\nHere at last.\r\n",
        date_now(0)
    );
    let _ = d.add_message(&raw, &[]);
    run_command(Command::Sync);
    select_folder("Inbox");
    wait_for(20, || d.find("INBOX", "Subject: Waiting on the server")).await;
    pause(1500).await;
    // a server that takes the connection and says nothing: the download waits
    let silent = SilentServer::start();
    set_port(d, "form-5", &silent.port.to_string()).await;
    show_found("subject:\"Waiting on the server\"").await;
    let reader = &shell().main().reader;
    let header = reader.header_text();
    d.check(
        header.contains("Waiting on the server") && header.contains("Hal Example"),
        &format!("the header shows the message's sender and subject at once ({header})"),
    );
    d.check(
        wait_until(10, || reader.preview.shown().contains("Downloading the message")).await,
        "the pane says the message is being downloaded",
    );
    d.shot(&main, "read-13-downloading").await;
    // the server gone: why, and Try Again
    silent.stop();
    d.check(
        wait_until(20, || reader.shows_failure()).await,
        "a message that can not be downloaded has Try Again",
    );
    d.check(
        reader.preview.shown().contains("could not be downloaded"),
        "and the pane says why",
    );
    d.shot(&main, "read-12-not-downloaded").await;
    // the server back: the account syncs, and the message is tried again by itself
    set_port(d, "form-5", &d.ports.imap.to_string()).await;
    d.check(
        wait_until(30, || reader.preview.shown().contains("Here at last")).await,
        "once the account is back the message shows by itself",
    );
    d.check(!reader.shows_failure(), "and Try Again goes");
    search("").await;
    select_folder("Inbox");
}

/// The second account's mail on its own server, for All Inboxes: unread, dated a little ahead so it is the newest in
/// the list (over what the steps before added), around the first account's message of the step
pub fn seed_second(d: &Driver) {
    for (from, subject, body, minutes) in [
        (
            "Priya Shah <priya@work.example>",
            "Contract renewal for next year",
            "The renewal is ready to sign. Could you look it over before Friday?",
            10,
        ),
        (
            "Tom Becker <tom@work.example>",
            "Offsite agenda",
            "Here is the agenda for the offsite. Add anything you want to talk about.",
            8,
        ),
    ] {
        let raw = format!(
            "From: {from}\r\nTo: testuser2@inboxclassic.test\r\nSubject: {subject}\r\nDate: {}\r\n\
             Message-ID: <{}@work.example>\r\n\r\n{body}\r\n",
            date_now(minutes),
            subject.replace(' ', "-")
        );
        if let Err(error) = d.add_message_at(d.ports.second_rest, &raw, &[]) {
            d.check(false, &format!("the second account's mail went into ImapKit ({error})"));
        }
    }
}

/// The second account's Inbox
pub fn second_inbox() -> Option<i64> {
    folder_of(1, "Inbox")
}

/// The mail of both accounts' Inboxes in one list, a reply from the account of a message, Mark All Read of both
pub async fn all_inboxes(d: &Driver) {
    d.step("All Inboxes");
    let main = shell().main();
    let (Some(inbox), Some(second)) = (folder_id("Inbox"), second_inbox()) else {
        d.check(false, "both accounts have an Inbox");
        return;
    };
    // a new message for the first account too, so both have unread mail
    let raw = format!(
        "From: Maria Lopez <maria@example.org>\r\nTo: testuser@inboxclassic.test\r\nSubject: Photos from the trip\r\n\
         Date: {}\r\nMessage-ID: <trip-photos@example.org>\r\n\r\nThe photos from the trip are in the shared album.\r\n",
        date_now(9)
    );
    let _ = d.add_message(&raw, &[]);
    command(Command::Sync);
    wait_until(20, || shell().core.folder(inbox).is_ok_and(|f| f.unread >= 1)).await;
    d.check(
        main.folders.markup_of(crate::folders::ALL_INBOXES).is_some()
            && main.folders.top_id() == Some(crate::folders::ALL_INBOXES),
        "All Inboxes is at the top of the tree, above the accounts",
    );
    main.folders.select(crate::folders::ALL_INBOXES);
    let both = |f: i64| shell().core.folder(f).map_or(0, |f| f.total);
    let expected = both(inbox) + both(second);
    d.check(
        wait_until(10, || u64::from(rows()) == expected).await,
        &format!("it lists the mail of both accounts' Inboxes ({} of {expected})", rows()),
    );
    // the rows as the list has them, from the core
    let all = pe_core::Search {
        scope: pe_core::Scope::AllInboxes,
        ..Default::default()
    };
    let listed = shell().core.search(&all, main.list.sort(), 0, 4).unwrap_or_default();
    let folders: Vec<i64> = listed.iter().map(|m| m.folder_id).collect();
    d.check(
        folders.contains(&inbox) && folders.contains(&second),
        "newest first, the two accounts' messages among each other",
    );
    let row = main.row_folder(second);
    let title = main.list.columns.folder.title().unwrap_or_default();
    d.check(
        row == "Work" && title == "Account",
        &format!("the Account column names the account of each ({title}: {row})"),
    );
    let counts = main.status_texts().2;
    d.check(
        counts.starts_with(&format!("{expected} messages")),
        &format!("the status bar counts both Inboxes ({counts})"),
    );
    // the newest message, the second account's
    select_row(0).await;
    pause(500).await;
    d.shot(&main_window(), "all-inboxes-1-list").await;
    // its right-click menu: Mark All Read alone, no folder commands
    let tree: gtk::Widget = main.folders.view.clone().upcast();
    main.folder_menu(&tree, 180.0, 20.0);
    let labels = menu_labels(main.folder_popover.borrow().as_ref());
    d.check(
        labels == ["Mark All Read"],
        &format!("its right-click menu has Mark All Read alone ({})", labels.join(", ")),
    );
    d.shot(&main_window(), "all-inboxes-2-menu").await;
    if let Some(popover) = main.folder_popover.borrow().as_ref() {
        popover.popdown();
    }
    if let Some(index) = folders.iter().position(|f| *f == second) {
        select_row(index as u32).await;
    }
    run_command(Command::Reply);
    match wait_compose(10).await {
        Some(c) => {
            let from = compose_from(&c);
            d.check(
                from == "Work <testuser2@inboxclassic.test>",
                &format!("a reply goes from the account of the message ({from})"),
            );
            close_compose(&c).await;
        }
        None => d.check(false, "Reply opens a compose window"),
    }
    let unread = |rest: u16| d.unread_at(rest);
    run_command(Command::MarkAllRead);
    d.check(
        wait_until(20, || unread(d.ports.rest) == 0 && unread(d.ports.second_rest) == 0).await,
        &format!(
            "Mark All Read marks both Inboxes read on the servers ({} and {} unread)",
            unread(d.ports.rest),
            unread(d.ports.second_rest)
        ),
    );
}

/// SCENARIO 41: Move and Copy to Folder offer every account's folders in a tree with a filter; a message moved to the
/// second account goes there with its flags and leaves the first, Undo brings it back, Copy keeps it, the folder used
/// last is under Recent, and a drag onto the other account moves it
pub async fn between_accounts(d: &Driver) {
    d.step("moving between accounts");
    let main = shell().main();
    let core = &shell().core;
    let accounts: Vec<i64> = core.accounts().unwrap_or_default().iter().map(|a| a.id).collect();
    let (Some(inbox), Some(archive2), [first, second, ..]) =
        (folder_id("Inbox"), folder_of(1, "Archive"), &accounts[..])
    else {
        d.check(false, "two accounts, the second with Archive");
        return;
    };
    let second_rest = d.ports.second_rest;
    let on_second = |mailbox: &str, subject: &str| {
        d.messages_at(second_rest, mailbox)
            .into_iter()
            .find(|m| raw_text(m).contains(&format!("Subject: {subject}")))
    };
    let on_first = |mailbox: &str, subject: &str| d.find(mailbox, &format!("Subject: {subject}"));
    for (subject, minutes, flags) in [
        ("Quarterly figures", 13, &["\\Flagged"][..]),
        ("Board minutes", 12, &[][..]),
        ("Travel booking", 11, &[][..]),
    ] {
        let raw = format!(
            "From: Nina Berg <nina@example.org>\r\nTo: testuser@inboxclassic.test\r\nSubject: {subject}\r\nDate: {}\r\n\
             Message-ID: <{}@example.org>\r\n\r\nFor the move between accounts.\r\n",
            date_now(minutes),
            subject.replace(' ', "-")
        );
        let _ = d.add_message(&raw, flags);
    }
    command(Command::Sync);
    select_folder("Inbox");
    let listed = |subject: &str| {
        core.search(&pe_core::Search::folder(inbox), main.list.sort(), 0, 100)
            .unwrap_or_default()
            .iter()
            .position(|m| m.info.subject == subject)
    };
    wait_until(30, || listed("Travel booking").is_some()).await;
    // selects the message with `subject`, and waits until the window has taken it
    let select = |subject: &str| {
        if let Some(index) = listed(subject) {
            main.list.select(index as u32);
        }
        let subject = subject.to_string();
        let main = main.clone();
        async move {
            wait_until(10, || {
                main.list.selected().is_some_and(|(_, m)| m.info.subject == subject) && main.selected_refs().len() == 1
            })
            .await
        }
    };

    // the window: both accounts' folders, the filter, the current folder, the button
    select("Quarterly figures").await;
    let in_inbox = rows();
    command(Command::Move);
    let Some(dialog) = wait_dialog(10, "move-dialog").await else {
        d.check(false, "Move to Folder shows the folders of both accounts");
        return;
    };
    let root: gtk::Widget = dialog.clone().upcast();
    let list = named_in(&root, "move-folders").and_downcast::<gtk::ListBox>();
    let row_named = |name: &str| -> Option<gtk::ListBoxRow> {
        let list = list.as_ref()?;
        let mut index = 0;
        while let Some(row) = list.row_at_index(index) {
            if row.widget_name() == name {
                return Some(row);
            }
            index += 1;
        }
        None
    };
    d.check(
        row_named(&format!("move-account-{first}")).is_some()
            && row_named(&format!("move-account-{second}")).is_some()
            && row_named(&format!("move-folder-{archive2}")).is_some()
            && named_in(&root, "move-filter").is_some(),
        "Move to Folder shows the folders of both accounts in a tree, with a filter box",
    );
    d.check(
        row_named(&format!("move-folder-{inbox}")).is_some_and(|r| !r.is_activatable()),
        "the folder the message is in is shown but can not be chosen",
    );
    let button = named_in(&root, "dialog-ok")
        .and_downcast::<gtk::Button>()
        .and_then(|b| b.label())
        .unwrap_or_default();
    d.check(button == "Move", &format!("the button says Move ({button})"));
    pause(400).await;
    d.shot(&dialog, "move-1-dialog").await;
    set_text(&root, "move-filter", "arch");
    let shown = |name: &str| row_named(name).is_some_and(|r| r.is_child_visible());
    d.check(
        wait_until(10, || {
            shown(&format!("move-folder-{archive2}")) && !shown(&format!("move-folder-{inbox}"))
        })
        .await,
        "typing in the filter narrows the tree to the folders that match",
    );
    pick_folder(&dialog, archive2);
    click(&root, "dialog-ok");
    d.check(
        wait_until(10, || rows() == in_inbox - 1).await,
        "a message of the first account moved to the second account's Archive leaves the list at once",
    );
    let done = wait_until(30, || main.status_texts().0 == "Moved 1 message to Archive").await;
    d.check(
        done,
        &format!(
            "the status bar says how far the move is, then that it is done ({})",
            main.status_texts().0
        ),
    );
    let arrived = wait_for(30, || on_second("Archive", "Quarterly figures")).await;
    let flagged = arrived
        .as_ref()
        .and_then(|m| m["flags"].as_array().cloned())
        .is_some_and(|f| f.iter().any(|f| f == "\\Flagged"));
    d.check(
        arrived.is_some() && flagged,
        "it is in the second account's Archive on its server, with its flags",
    );
    d.check(
        wait_until(20, || on_first("INBOX", "Quarterly figures").is_none()).await,
        "and gone from the first account's server",
    );
    // the second account's Archive, with the message there
    wait_until(20, || core.folder(archive2).is_ok_and(|f| f.total >= 1)).await;
    main.folders.select(archive2);
    wait_until(10, || rows() >= 1).await;
    select_row(0).await;
    d.shot(&main_window(), "move-2-accounts").await;
    select_folder("Inbox");
    pause(500).await;

    run_command(Command::Undo);
    d.check(
        wait_until(30, || {
            on_first("INBOX", "Quarterly figures").is_some() && on_second("Archive", "Quarterly figures").is_none()
        })
        .await,
        "Edit > Undo Move brings it back to the first account",
    );

    // a copy keeps it
    wait_until(20, || listed("Board minutes").is_some()).await;
    select("Board minutes").await;
    command(Command::Copy);
    match wait_dialog(10, "move-dialog").await {
        Some(dialog) => {
            let label = named_in(dialog.upcast_ref(), "dialog-ok")
                .and_downcast::<gtk::Button>()
                .and_then(|b| b.label())
                .unwrap_or_default();
            d.check(label == "Copy", &format!("Copy to Folder's button says Copy ({label})"));
            pick_folder(&dialog, archive2);
            click(dialog.upcast_ref(), "dialog-ok");
        }
        None => d.check(false, "Copy to Folder asks where"),
    }
    d.check(
        wait_for(30, || on_second("Archive", "Board minutes")).await.is_some()
            && on_first("INBOX", "Board minutes").is_some(),
        "Copy to Folder copies a message to the second account's Archive and keeps it in the Inbox",
    );

    // the folder used last, on top
    command(Command::Move);
    match wait_dialog(10, "move-dialog").await {
        Some(dialog) => {
            let recent = named_in(dialog.upcast_ref(), &format!("move-recent-{archive2}")).is_some();
            d.check(
                recent,
                "the next Move to Folder offers Archive of the second account under Recent",
            );
            click(dialog.upcast_ref(), "dialog-cancel");
            wait_gone(10, "move-dialog").await;
        }
        None => d.check(false, "Move to Folder opens again"),
    }

    // a drag onto the other account's folder
    select("Travel booking").await;
    if let Some((_, message)) = main.list.selected() {
        let payload = vec![pe_store::MessageRef {
            folder: message.folder_id,
            uid: message.info.uid,
        }];
        d.check(
            main.can_drop(&payload, archive2),
            "a folder of the second account takes a dragged message",
        );
        main.drop_message(&payload, archive2, false);
    }
    d.check(
        wait_for(30, || on_second("Archive", "Travel booking")).await.is_some()
            && wait_until(20, || on_first("INBOX", "Travel booking").is_none()).await,
        "a message dragged onto a folder of the second account is moved there",
    );
}

// ---- 46. Options and the language ----

/// The words a window shows: its labels (buttons' included) and the message list's column titles, but not the mail's
/// own (the rows of the list and the tree, and the reading pane's header, which hold names and subjects)
fn shown_words(root: &gtk::Widget) -> Vec<(String, bool)> {
    let data: Vec<gtk::Widget> = [
        "folder-tree",
        "message-list",
        "reader-subject",
        "reader-from",
        "reader-to",
        "reader-date",
        "reader-attachments",
        "reader-invitation",
    ]
    .iter()
    .filter_map(|name| named_in(root, name))
    .collect();
    let titles: Vec<String> = named_in(root, "message-list")
        .and_downcast::<gtk::ColumnView>()
        .map(|view| {
            let columns = view.columns();
            (0..columns.n_items())
                .filter_map(|i| columns.item(i).and_downcast::<gtk::ColumnViewColumn>())
                .filter(|c| c.is_visible())
                .filter_map(|c| c.title().map(|t| t.to_string()))
                .filter(|t| !t.is_empty())
                .collect()
        })
        .unwrap_or_default();
    descendants::<gtk::Label>(root)
        .into_iter()
        .filter(|label| label.is_mapped() && label.text().chars().any(char::is_alphabetic))
        .filter(|label| {
            let in_data = data.iter().any(|d| label == d || label.is_ancestor(d));
            !in_data || titles.iter().any(|t| *t == label.text())
        })
        // the outgoing part of the status bar names a message's subject, which may be cut off as long as it is
        .map(|label| {
            let cut = label.layout().is_ellipsized() && label.widget_name() != "outgoing";
            (label.text().to_string(), cut)
        })
        // the toolbar's buttons are icons that say what they do in their tooltips
        .chain(
            descendants::<gtk::Widget>(root)
                .into_iter()
                .filter(|w| w.is_mapped() && !data.iter().any(|d| w.is_ancestor(d)))
                .filter_map(|w| w.tooltip_text())
                .map(|tip| (tip.to_string(), false)),
        )
        .collect()
}

/// The words in English left in a window in the pseudo-language (any that does not start with its bracket), and
/// those cut off
fn not_pseudo(root: &gtk::Widget, data: &[&str]) -> (Vec<String>, Vec<String>) {
    let words = shown_words(root);
    let english = words
        .iter()
        .filter(|(text, _)| !text.starts_with('[') && !data.iter().any(|d| text.contains(d)))
        .map(|(text, _)| text.clone())
        .collect();
    let cut = words
        .iter()
        .filter(|(_, cut)| *cut)
        .map(|(text, _)| text.clone())
        .collect();
    (english, cut)
}

/// The main window again, in `language`, with the Inbox and its first message shown
async fn in_language(language: &str) {
    pe_core::i18n::set_language(language);
    shell().remake_main();
    pause(1000).await;
    select_folder(&pe_core::i18n::tr(pe_core::i18n::Text::FolderInbox));
    wait_until(10, || rows() >= 1).await;
    select_row(0).await;
}

pub async fn languages(d: &Driver) {
    d.step("Preferences and the language");
    command(Command::Options);
    let Some(dialog) = wait_dialog(10, "preferences-dialog").await else {
        d.check(false, "the main menu's Preferences opens");
        return;
    };
    let root = dialog.clone().upcast::<gtk::Widget>();
    let row = named_in(&root, "preferences-language").and_downcast::<adw::ComboRow>();
    let names: Vec<String> = row
        .as_ref()
        .and_then(|r| r.model())
        .and_downcast::<gtk::StringList>()
        .map(|list| {
            (0..list.n_items())
                .filter_map(|i| list.string(i))
                .map(|s| s.to_string())
                .collect()
        })
        .unwrap_or_default();
    d.check(
        names.first().is_some_and(|n| n == "System default (English)")
            && names[1..] == ["English", "Deutsch", "Eesti", "Español", "Français"],
        &format!(
            "Language lists System default, with the language it is now, and the five by their own names ({names:?})"
        ),
    );
    d.check(
        named_in(&root, "preferences-notify").is_some(),
        "Preferences has Notify of New Mail",
    );
    let Some(row) = row else { return };
    // the list open for the picture
    adw::prelude::ActionRowExt::activate(&row);
    pause(500).await;
    d.shot(&dialog, "options-1-language").await;
    for popover in descendants::<gtk::Popover>(&root) {
        popover.popdown();
    }
    row.set_selected(2);
    match wait_alert(5).await {
        Some(alert) => {
            let text = alert_text(&alert);
            d.check(
                text.contains("restarts to change the language"),
                &format!("a language chosen says the app starts again to change it ({text})"),
            );
            let buttons: Vec<String> = descendants::<gtk::Button>(alert.upcast_ref())
                .iter()
                .filter_map(|b| {
                    b.child()
                        .and_downcast::<gtk::Label>()
                        .map(|l| l.text().to_string())
                        .or(b.label().map(|l| l.to_string()))
                })
                .collect();
            d.check(
                buttons.iter().any(|b| b == "Restart Now") && buttons.iter().any(|b| b == "Later"),
                &format!("with Restart Now and Later ({buttons:?})"),
            );
            answer(&alert, "Later");
        }
        None => d.check(false, "a language chosen says the app starts again to change it"),
    }
    d.check(
        shell().settings.text(crate::settings::LANGUAGE).as_deref() == Some("de"),
        "the language chosen is kept for the next start",
    );
    // back to the system's, which takes the setting out
    row.set_selected(0);
    pause(300).await;
    d.check(
        shell().settings.text(crate::settings::LANGUAGE).is_none() && alert().is_none(),
        "System default, the language in use already, asks nothing",
    );
    dialog.close();
    wait_gone(10, "preferences-dialog").await;

    d.step("in German");
    in_language("de").await;
    let main = main_window();
    let words: Vec<String> = shown_words(&main).into_iter().map(|(w, _)| w).collect();
    let german = ["Antworten", "Weiterleiten", "Von", "Betreff"];
    d.check(
        german.iter().all(|w| words.iter().any(|shown| shown == w)),
        &format!("started in German, the toolbar and the columns are in German ({words:?})"),
    );
    d.check(
        folder_id("Posteingang").is_some() && folder_id("Archiv").is_some(),
        "the special folders are in German, Archive among them",
    );
    let menu = named_in(&main, "primary-menu").and_downcast::<gtk::MenuButton>();
    if let Some(menu) = &menu {
        menu.popup();
        pause(500).await;
        let labels = menu_labels(menu.popover().and_downcast::<gtk::PopoverMenu>().as_ref());
        d.check(
            labels.iter().any(|l| l == "Datei") && labels.iter().any(|l| l == "Einstellungen"),
            &format!("the main menu is in German ({labels:?})"),
        );
    }
    d.shot(&main, "lang-1-german").await;
    if let Some(menu) = &menu {
        menu.popdown();
    }

    d.step("in the pseudo-language");
    in_language("qps").await;
    let main = main_window();
    // what the mail says, and the account's name and address
    let data = ["Alex Morgan", "testuser", "@", "Inbox Classic"];
    let (english, cut) = not_pseudo(&main, &data);
    d.check(
        english.is_empty(),
        &format!("nothing in the main window is left in English ({english:?})"),
    );
    d.check(
        cut.is_empty(),
        &format!("nothing in the main window is cut off ({cut:?})"),
    );
    d.shot(&main, "lang-2-pseudo-main").await;
    command(Command::NewAccount);
    match wait_dialog(10, "account-start").await {
        Some(form) => {
            let root = form.clone().upcast::<gtk::Widget>();
            let (english, cut) = not_pseudo(&root, &data);
            d.check(
                english.is_empty(),
                &format!("nothing in the account form is left in English ({english:?})"),
            );
            d.check(
                cut.is_empty(),
                &format!("nothing in the account form is cut off ({cut:?})"),
            );
            d.shot(&form, "lang-3-pseudo-form").await;
            form.close();
            wait_gone(10, "account-start").await;
        }
        None => d.check(false, "File > New Account opens in the pseudo-language"),
    }
    in_language("en").await;
}
