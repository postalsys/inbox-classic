//! A long conversation in the reading pane's stack: its read middle folded into one row, every message open with Open
//! All Messages (only the bodies near what is seen made), the previous and next message, Fold All Messages

use super::steps::select_subject;
use super::*;

const SUBJECT: &str = "Budget review";
const COUNT: usize = 20;

/// Message `n` of the conversation, dated in 2025 so the later steps find their lists as they were
fn message(n: usize) -> String {
    let answers = if n == 1 {
        String::new()
    } else {
        format!(
            "In-Reply-To: <budget{}@example.com>\r\nReferences: <budget1@example.com> <budget{}@example.com>\r\n",
            n - 1,
            n - 1
        )
    };
    format!(
        "From: Person {} <person{}@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: {}{SUBJECT}\r\n\
         Date: Tue, 9 Sep 2025 {:02}:{:02}:00 +0000\r\nMessage-ID: <budget{n}@example.com>\r\n{answers}\r\n\
         Number {n} on the budget.\r\n{figures}",
        n % 4,
        n % 4,
        if n == 1 { "" } else { "Re: " },
        8 + n / 6,
        (n * 7) % 60,
        // thirty lines each: the conversation open is many screens tall, whatever the screen
        figures = (1..=30).map(|k| format!("Line {k} of the figures.\r\n")).collect::<String>()
    )
}

pub async fn long_conversation(d: &Driver) {
    d.step("a long conversation");
    let main = shell().main();
    let added = (1..=COUNT).all(|n| {
        let flags: &[&str] = if n == COUNT { &[] } else { &["\\Seen"] };
        d.add_message(&message(n), flags).is_ok()
    });
    d.check(added, "twenty messages of one conversation are put into the Inbox");
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;
    run_command(Command::Sync);
    let stack = main.reader.stack.clone();
    // the first message, one row for the read middle, the last two read ones, the unread last one open; selected
    // again until all twenty have come in (the sync brings them a few at a time)
    let mut folded = false;
    for _ in 0..10 {
        select_subject(SUBJECT).await;
        folded = wait_until(3, || {
            stack.gaps().len() == 1 && stack.shown().len() == 4 && stack.frames().len() == 1
        })
        .await;
        if folded {
            break;
        }
        main.list.selection.unselect_all();
        pause(500).await;
    }
    d.check(
        folded,
        &format!(
            "the read middle of a long conversation is folded into one row ({} shown, {} folded)",
            stack.shown().len(),
            stack.gaps().len()
        ),
    );
    let words = stack.gaps().first().and_then(|g| g.label()).unwrap_or_default();
    d.check(words.contains("16"), &format!("which says how many it holds ({words})"));
    if let Some(gap) = stack.gaps().first() {
        gap.emit_clicked();
    }
    let listed = wait_until(20, || stack.shown().len() == COUNT && stack.gaps().is_empty()).await;
    d.check(
        listed,
        &format!("a click on it lists them all ({})", stack.shown().len()),
    );
    // every message open: shown at once, only the bodies near what is seen made
    let asked = std::time::Instant::now();
    run_command(Command::OpenAllMessages);
    let opened = wait_until(20, || stack.frames().len() == COUNT).await;
    let took = asked.elapsed().as_secs_f64();
    d.check(
        opened,
        &format!("Open All Messages opens every message ({})", stack.frames().len()),
    );
    d.check(took < 5.0, &format!("at once ({took:.1} s)"));
    let live = stack.frames().iter().filter(|f| f.1.is_some()).count();
    d.check(
        live > 0 && live < COUNT,
        &format!("only the bodies near what is seen are made ({live} of {COUNT})"),
    );
    d.shot(main.window(), "threads-7-long").await;
    // the previous message selected, then the next one again, then every one folded but it
    let selected = main.reader.message();
    run_command(Command::PreviousInConversation);
    let previous = wait_until(15, || {
        main.reader.message() != selected && stack.frames().iter().filter(|f| f.0.selected).count() == 1
    })
    .await;
    d.check(previous, "Previous Message in Conversation selects the one before");
    run_command(Command::NextInConversation);
    let next = wait_until(15, || main.reader.message() == selected).await;
    d.check(next, "Next Message in Conversation the one after");
    run_command(Command::FoldAllMessages);
    let folded = wait_until(15, || {
        stack.frames().len() == 1 && stack.frames().first().is_some_and(|f| f.0.selected)
    })
    .await;
    d.check(
        folded,
        &format!(
            "Fold All Messages folds every message but the selected one ({})",
            stack.frames().len()
        ),
    );
    // the step's messages taken away from the server and the list, so the steps after it find the Inbox as before
    for message in d.messages("INBOX") {
        if raw_text(&message).contains("Message-ID: <budget")
            && let Some(uid) = message["uid"].as_u64()
        {
            let _ = http(
                d.ports.rest,
                "DELETE",
                &format!("/v1/mailboxes/INBOX/messages/{uid}"),
                None,
            );
        }
    }
    run_command(Command::Sync);
    wait_until(20, || {
        !main
            .list_view()
            .rows(&shell().core, 0, 200)
            .is_ok_and(|rows| rows.iter().any(|m| m.info.subject.ends_with(SUBJECT)))
    })
    .await;
}
