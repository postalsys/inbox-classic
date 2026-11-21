//! The journeys of scripts/ui-e2e/DEEP.md: fixed sequences in the big world, each with its own checks besides those
//! that always hold. They run first, on the world as it was made, so what the world says (a folder's newest message)
//! is still what the server has. A step a target can not do is skipped there and reported.

use serde_json::json;

use crate::model::{Act, List, Seen, SortBy, UNSUPPORTED};
use crate::run::{JourneyResult, Run, Stop};
use crate::world::{Account, Kind};

type Journey = fn(&mut Run<'_>, &mut Vec<String>) -> Result<(), Stop>;

/// Every journey, in the order of DEEP.md
pub const ALL: &[(&str, &str, Journey)] = &[
    ("D1", "The first sync", first_sync),
    ("D2", "Pages", pages),
    ("D3", "Fast fingers", fast_fingers),
    ("D4", "The list changes under the window", changes_under),
    ("D5", "Selection across pages", selection),
    ("D6", "Views of many folders", views),
    ("D7", "Conversations", conversations),
    ("D8", "Finding", finding),
    ("D9", "Bulk commands", bulk),
    ("D10", "Writing", writing),
    ("D11", "The folder tree", tree),
    ("D12", "Every kind of message", kinds),
    ("D13", "The connection", connection),
    ("D14", "Restarts", restarts),
];

/// Runs the journeys `only` names (all of them when empty)
pub fn run_all(run: &mut Run<'_>, only: &[String]) -> Result<(), Stop> {
    for (id, name, journey) in ALL {
        if !only.is_empty() && !only.iter().any(|o| o.eq_ignore_ascii_case(id)) {
            continue;
        }
        println!("== {id} {name}");
        run.part = (*id).to_string();
        let failures = run.failed.len();
        let began = run.elapsed();
        let mut skipped = Vec::new();
        let outcome = journey(run, &mut skipped);
        run.journeys.push(JourneyResult {
            id,
            name,
            failures: run.failed.len() - failures,
            skipped,
            seconds: run.elapsed() - began,
        });
        outcome?;
    }
    Ok(())
}

fn account<'w>(run: &Run<'w>, kind: Kind) -> &'w Account {
    run.world
        .accounts
        .iter()
        .find(|a| a.kind == kind)
        .expect("every kind of account is in the world")
}

fn inbox(account: &Account) -> List {
    List::folder(&account.name, "INBOX")
}

/// An act a target may not be able to do: false (and noted) when it can not
fn try_act(run: &mut Run<'_>, act: Act, skipped: &mut Vec<String>) -> Result<bool, Stop> {
    match run.act(act.clone()) {
        Err(Stop::Broken(why)) if why.ends_with(UNSUPPORTED) => {
            skipped.push(format!("{} is not possible on {}", act.describe(), run.target.name()));
            Ok(false)
        }
        other => other.map(|()| true),
    }
}

/// The subject of the message shown, from the rows in sight
fn shown_subject(seen: &Seen) -> Option<String> {
    let shown = seen.shown.as_ref()?;
    seen.sight
        .iter()
        .find(|r| r.message.as_ref() == Some(shown))
        .map(|r| r.subject.clone())
}

fn first_sync(run: &mut Run<'_>, _: &mut Vec<String>) -> Result<(), Stop> {
    // the target synced every account when it started: every folder of every account counted as the server counts
    // it (the check of the tree), and each Inbox listed whole
    for account in run.world.accounts.clone() {
        run.act(Act::Open(inbox(&account)))?;
        run.settled()?;
    }
    Ok(())
}

fn pages(run: &mut Run<'_>, _: &mut Vec<String>) -> Result<(), Stop> {
    let work = account(run, Kind::Work);
    let folder = work.folder("INBOX").expect("Work has an Inbox");
    let newest = folder.newest().map(|(_, m)| m.subject.clone());
    run.act(Act::Open(inbox(work)))?;
    let seen = run.settled()?;
    run.expect(
        seen.selected.len() == 1 && shown_subject(&seen) == newest,
        format!(
            "come to for the first time, the Inbox shows its newest message ({:?})",
            shown_subject(&seen)
        ),
    );
    // a row far down shown, Flagged and back: the same row, filled and shown (the incident of 0.19.0)
    let far = (seen.rows * 2 / 9).max(1).min(seen.rows.saturating_sub(1));
    run.act(Act::Scroll(far.saturating_sub(5)))?;
    run.act(Act::Click(far))?;
    let clicked = run.settled()?;
    let left = shown_subject(&clicked);
    run.act(Act::Open(List::Flagged))?;
    run.settled()?;
    run.act(Act::Open(inbox(work)))?;
    let back = run.settled()?;
    run.expect(
        back.selected == [far] && shown_subject(&back) == left && left.is_some(),
        format!(
            "back from Flagged, row {far} is selected, in sight and shown ({:?}, selected {:?}; {left:?} before)",
            shown_subject(&back),
            back.selected
        ),
    );
    // its message deleted by another client meanwhile: the newest again
    if let Some(gone) = back.shown.clone() {
        run.act(Act::Open(List::Flagged))?;
        run.settled()?;
        run.server(format!("expunges {gone:?}"), |s| {
            if let Some(a) = s.account(&gone.account)
                && !a.present(&gone.path, &[gone.uid]).is_empty()
            {
                a.expunge(&gone.path, &[gone.uid]);
            }
        })?;
        run.act(Act::Sync)?;
        run.settled()?;
        run.act(Act::Open(inbox(work)))?;
        let again = run.settled()?;
        run.expect(
            again.selected.len() == 1 && shown_subject(&again) == newest,
            format!(
                "its message gone, the Inbox shows its newest again ({:?})",
                shown_subject(&again)
            ),
        );
    }
    run.act(Act::End)?;
    let end = run.settled()?;
    run.expect(
        end.sight.last().is_some_and(|r| r.row + 1 == end.rows),
        "End shows the last rows",
    );
    run.act(Act::Click(end.rows.saturating_sub(1)))?;
    run.settled()?;
    run.act(Act::Home)?;
    run.act(Act::PageDown(40))?;
    let paged = run.settled()?;
    if let Some(row) = paged.sight.get(3).map(|r| r.row) {
        run.act(Act::Click(row))?;
        run.settled()?;
    }
    run.act(Act::Scroll(paged.rows / 2))?;
    run.settled()?;
    // the folders on the edges of the pages, each from the big Inbox and back
    for path in [
        "Edges/Exactly 100",
        "Edges/Exactly 800",
        "Edges/Exactly 801",
        "Edges/Empty",
    ] {
        if work.folder(path).is_none() {
            continue;
        }
        run.act(Act::Open(List::folder(&work.name, path)))?;
        let edge = run.settled()?;
        run.expect(
            (edge.rows == 0) == edge.selected.is_empty(),
            format!("{path}: a message selected, unless it is empty ({} rows)", edge.rows),
        );
        run.act(Act::End)?;
        run.settled()?;
        run.act(Act::Open(inbox(work)))?;
        run.settled()?;
    }
    for by in SortBy::ALL {
        for ascending in [true, false] {
            run.act(Act::Sort(by, ascending))?;
            run.act(Act::Scroll(1000))?;
            run.settled()?;
        }
    }
    run.act(Act::Sort(SortBy::Date, false))?;
    run.act(Act::UnreadOnly(true))?;
    run.settled()?;
    run.act(Act::UnreadOnly(false))?;
    run.act(Act::Group(true))?;
    run.settled()?;
    run.act(Act::Group(false))?;
    run.settled()?;
    Ok(())
}

fn fast_fingers(run: &mut Run<'_>, _: &mut Vec<String>) -> Result<(), Stop> {
    let work = account(run, Kind::Work);
    let home = account(run, Kind::Home);
    // ten folders clicked without waiting, then the Inbox: none of the ten opened a message
    let passed: Vec<(List, String, u64, bool)> = home
        .folders
        .iter()
        .filter(|f| !f.mails.is_empty() && f.path != "INBOX")
        .take(10)
        .filter_map(|f| {
            let (uid, mail) = f.newest()?;
            Some((
                List::folder(&home.name, &f.path),
                f.path.clone(),
                uid,
                mail.flags.contains(&"\\Seen"),
            ))
        })
        .collect();
    for (list, ..) in &passed {
        run.act(Act::Open(list.clone()))?;
    }
    run.act(Act::Open(inbox(work)))?;
    let seen = run.settled()?;
    run.expect(
        seen.list == Some(inbox(work)),
        "the last folder clicked is the one shown",
    );
    let server = run.servers.account(&home.name).expect("Home's server");
    for (_, path, uid, was_seen) in &passed {
        if *was_seen {
            continue;
        }
        let still = server.listed(path).get(uid).is_some_and(|m| !m.seen());
        run.expect(
            still,
            format!("{path} was passed through: its newest message is still unread"),
        );
    }
    // the sort changed three times without waiting
    run.act(Act::Sort(SortBy::Subject, true))?;
    run.act(Act::Sort(SortBy::Size, false))?;
    run.act(Act::Sort(SortBy::Date, false))?;
    run.settled()?;
    // a search typed a letter at a time, then cleared at once
    for typed in ["b", "bu", "bud", "budg", "budget"] {
        run.act(Act::Search(typed.into()))?;
    }
    run.act(Act::Search(String::new()))?;
    let cleared = run.settled()?;
    run.expect(
        cleared.search.is_empty(),
        "the search cleared, the folder's list is back",
    );
    // a row clicked, another folder, and back before anything came
    run.act(Act::Click(3))?;
    run.act(Act::Open(List::Flagged))?;
    run.act(Act::Open(inbox(work)))?;
    run.settled()?;
    Ok(())
}

fn changes_under(run: &mut Run<'_>, _: &mut Vec<String>) -> Result<(), Stop> {
    let work = account(run, Kind::Work);
    run.act(Act::Open(inbox(work)))?;
    let seen = run.settled()?;
    run.act(Act::Scroll(seen.rows / 2))?;
    run.settled()?;
    let before = seen.rows;
    let mail = crate::walk::new_mail_maker(run.world.seed);
    let count = 200.min(before / 10).max(5);
    run.server(format!("delivers {count} messages to Work's Inbox"), |s| {
        if let Some(a) = s.account(&work.name) {
            for n in 0..count {
                a.deliver("INBOX", &mail(n), &[]);
            }
        }
    })?;
    run.act(Act::Sync)?;
    let grown = run.settled()?;
    run.expect(
        grown.rows == before + count,
        format!("the list grew by {count} ({before} to {})", grown.rows),
    );
    // at the top, a message shown, new mail: the same one stays shown
    run.act(Act::Home)?;
    run.act(Act::Click(2))?;
    let shown = run.settled()?.shown;
    run.server("delivers 5 more".into(), |s| {
        if let Some(a) = s.account(&work.name) {
            for n in 0..5 {
                a.deliver("INBOX", &mail(1000 + n), &[]);
            }
        }
    })?;
    run.act(Act::Sync)?;
    let after = run.settled()?;
    run.expect(after.shown == shown, "new mail above it: the message shown stays shown");
    // another client deletes the message shown
    if let Some(gone) = after.shown.clone() {
        run.server(format!("expunges the message shown {gone:?}"), |s| {
            if let Some(a) = s.account(&gone.account)
                && !a.present(&gone.path, &[gone.uid]).is_empty()
            {
                a.expunge(&gone.path, &[gone.uid]);
            }
        })?;
        run.act(Act::Sync)?;
        let left = run.settled()?;
        run.expect(
            left.shown.as_ref() != Some(&gone),
            "the message another client deleted is no longer shown",
        );
    }
    // at the end of the list, another client deletes many of the oldest
    run.act(Act::End)?;
    run.settled()?;
    let server = run.servers.account(&work.name).expect("Work's server");
    let mut uids: Vec<u64> = server.listed("INBOX").keys().copied().collect();
    uids.sort_unstable();
    let oldest: Vec<u64> = uids.iter().take(uids.len() / 6).copied().collect();
    run.server(format!("expunges {} of the oldest messages", oldest.len()), |s| {
        if let Some(a) = s.account(&work.name) {
            for chunk in oldest.chunks(500) {
                a.expunge("INBOX", chunk);
            }
        }
    })?;
    run.act(Act::Sync)?;
    run.settled()?;
    // flags changed by another client on the rows in sight
    let sight = run.check(false)?;
    let uids: Vec<u64> = sight
        .sight
        .iter()
        .filter_map(|r| r.message.as_ref())
        .map(|m| m.uid)
        .collect();
    run.server("flags the rows in sight".into(), |s| {
        if let Some(a) = s.account(&work.name) {
            // a window behind shows some the server no longer has, which the checks report
            let uids = a.present("INBOX", &uids);
            if !uids.is_empty() {
                a.flags("INBOX", &uids, &["\\Flagged"], "add");
            }
        }
    })?;
    run.act(Act::Sync)?;
    run.settled()?;
    // the folder shown renamed, and another's UIDVALIDITY changed
    let shown_folder = "Teams/Teams 18";
    if work.folder(shown_folder).is_some() {
        run.act(Act::Open(List::folder(&work.name, shown_folder)))?;
        run.settled()?;
        run.server("renames the folder shown".into(), |s| {
            if let Some(a) = s.account(&work.name) {
                a.rename(shown_folder, "Teams/Teams 18 renamed");
            }
        })?;
        run.act(Act::Sync)?;
        run.settled()?;
    }
    if work.folder("Teams/Teams 17").is_some() {
        run.act(Act::Open(List::folder(&work.name, "Teams/Teams 17")))?;
        run.settled()?;
        run.server("gives Teams 17 a new UIDVALIDITY".into(), |s| {
            if let Some(a) = s.account(&work.name) {
                a.new_uidvalidity("Teams/Teams 17");
            }
        })?;
        run.act(Act::Sync)?;
        run.settled()?;
    }
    Ok(())
}

fn selection(run: &mut Run<'_>, _: &mut Vec<String>) -> Result<(), Stop> {
    let work = account(run, Kind::Work);
    run.act(Act::Open(inbox(work)))?;
    run.settled()?;
    run.act(Act::SelectAll)?;
    run.act(Act::Read)?;
    run.settled()?;
    let unseen = run
        .servers
        .account(&work.name)
        .and_then(|a| a.counted().into_iter().find(|c| c.path == "INBOX"))
        .map_or(u64::MAX, |c| c.unseen);
    run.expect(
        unseen == 0,
        format!("Select All, Mark as Read: the server has none unread ({unseen})"),
    );
    run.act(Act::SelectAll)?;
    run.act(Act::Unread)?;
    run.settled()?;
    // a Shift range across pages not read, moved, and Undo
    run.act(Act::Home)?;
    run.act(Act::Click(50))?;
    run.act(Act::ShiftClick(2300))?;
    let before = run
        .servers
        .account(&work.name)
        .and_then(|a| a.counted().into_iter().find(|c| c.path == "Archive"))
        .map_or(0, |c| c.messages);
    let moved = run.check(false)?.selected.len() as u64;
    run.act(Act::MoveTo(List::folder(&work.name, "Archive")))?;
    run.settled()?;
    let archive = |run: &Run<'_>| {
        run.servers
            .account(&work.name)
            .and_then(|a| a.counted().into_iter().find(|c| c.path == "Archive"))
            .map_or(0, |c| c.messages)
    };
    run.expect(
        archive(run) == before + moved,
        format!("the {moved} messages are in Archive ({} there)", archive(run)),
    );
    run.act(Act::Undo)?;
    run.settled()?;
    let now = archive(run);
    let inbox_now = run
        .servers
        .account(&work.name)
        .and_then(|a| a.counted().into_iter().find(|c| c.path == "INBOX"))
        .map_or(0, |c| c.messages);
    run.expect(
        now == before,
        format!("Undo brings them back ({now} in Archive, {before} before; {inbox_now} in the Inbox)"),
    );
    Ok(())
}

fn views(run: &mut Run<'_>, _: &mut Vec<String>) -> Result<(), Stop> {
    for list in [
        List::AllInboxes,
        List::AllSent,
        List::AllDrafts,
        List::Flagged,
        List::AllInboxes,
    ] {
        run.act(Act::Open(list))?;
        run.settled()?;
        run.act(Act::End)?;
        run.settled()?;
    }
    // each list remembers its own message
    run.act(Act::Click(3))?;
    let all = run.settled()?.shown;
    let work = account(run, Kind::Work);
    run.act(Act::Open(inbox(work)))?;
    run.settled()?;
    run.act(Act::Open(List::AllInboxes))?;
    let back = run.settled()?;
    run.expect(
        back.shown == all,
        "All Inboxes shows the message it showed when it was left",
    );
    Ok(())
}

fn conversations(run: &mut Run<'_>, _: &mut Vec<String>) -> Result<(), Stop> {
    let work = account(run, Kind::Work);
    run.act(Act::Open(inbox(work)))?;
    run.act(Act::Group(true))?;
    let grouped = run.settled()?;
    run.expect(grouped.grouped && grouped.rows > 0, "grouped by conversation");
    for row in [99, 100, 0] {
        run.act(Act::Click(row.min(grouped.rows.saturating_sub(1))))?;
        run.settled()?;
    }
    run.act(Act::End)?;
    run.settled()?;
    run.act(Act::Group(false))?;
    run.settled()?;
    Ok(())
}

fn finding(run: &mut Run<'_>, _: &mut Vec<String>) -> Result<(), Stop> {
    let work = account(run, Kind::Work);
    run.act(Act::Open(inbox(work)))?;
    run.act(Act::Search("budget".into()))?;
    let found = run.settled()?;
    run.expect(found.rows > 0, format!("a common word finds many ({})", found.rows));
    run.act(Act::End)?;
    run.act(Act::Click(found.rows.saturating_sub(1)))?;
    run.settled()?;
    run.act(Act::Search("subject:review".into()))?;
    run.settled()?;
    run.act(Act::Search(String::new()))?;
    run.act(Act::Open(List::AllInboxes))?;
    run.act(Act::Search("notes".into()))?;
    run.settled()?;
    run.act(Act::Search(String::new()))?;
    run.settled()?;
    Ok(())
}

fn bulk(run: &mut Run<'_>, _: &mut Vec<String>) -> Result<(), Stop> {
    let work = account(run, Kind::Work);
    // Mark All Read on the big Inbox; the window stays usable
    run.act(Act::Open(inbox(work)))?;
    run.act(Act::MarkAllRead)?;
    run.act(Act::Scroll(500))?;
    run.settled()?;
    // a folder of hundreds deleted to Deleted Items, then Empty Folder there
    run.act(Act::Open(List::folder(&work.name, "Edges/Exactly 800")))?;
    run.act(Act::SelectAll)?;
    run.act(Act::Delete)?;
    run.settled()?;
    run.act(Act::Open(List::folder(&work.name, "Trash")))?;
    run.settled()?;
    run.act(Act::EmptyFolder)?;
    let empty = run.settled()?;
    run.expect(
        empty.rows == 0,
        format!("Empty Folder leaves Deleted Items empty ({})", empty.rows),
    );
    Ok(())
}

fn tree(run: &mut Run<'_>, _: &mut Vec<String>) -> Result<(), Stop> {
    let home = account(run, Kind::Home);
    let deep: Vec<String> = home
        .folders
        .iter()
        .filter(|f| f.path.matches('/').count() >= 3)
        .take(12)
        .map(|f| f.path.clone())
        .collect();
    for path in deep {
        run.act(Act::Open(List::folder(&home.name, &path)))?;
        run.settled()?;
    }
    Ok(())
}

fn kinds(run: &mut Run<'_>, _: &mut Vec<String>) -> Result<(), Stop> {
    let lists = account(run, Kind::Lists);
    run.act(Act::Open(inbox(lists)))?;
    for words in [
        "Undelivered",
        "Invitation",
        "sign-in code",
        "Encrypted",
        "Weekly digest",
        "Huge",
    ] {
        run.act(Act::Search(words.into()))?;
        let found = run.settled()?;
        run.expect(
            found.rows > 0,
            format!("\"{words}\" finds its messages ({})", found.rows),
        );
        if found.rows > 0 {
            run.act(Act::Click(0))?;
            let shown = run.settled()?;
            run.expect(
                shown.shown.is_some(),
                format!("a message found with \"{words}\" is shown"),
            );
        }
    }
    run.act(Act::Search(String::new()))?;
    run.settled()?;
    Ok(())
}

fn restarts(run: &mut Run<'_>, skipped: &mut Vec<String>) -> Result<(), Stop> {
    let work = account(run, Kind::Work);
    run.act(Act::Open(List::folder(&work.name, "Archive")))?;
    run.act(Act::Click(4))?;
    let archive = run.settled()?;
    run.act(Act::Open(inbox(work)))?;
    run.act(Act::Click(7))?;
    let before = run.settled()?;
    if !try_act(run, Act::Restart, skipped)? {
        return Ok(());
    }
    let after = run.settled()?;
    run.expect(
        after.list == before.list && after.shown == before.shown,
        format!(
            "after a restart the same list and message ({:?} {:?})",
            after.list, after.shown
        ),
    );
    run.act(Act::Open(List::folder(&work.name, "Archive")))?;
    let again = run.settled()?;
    run.expect(
        again.shown == archive.shown,
        "Archive still opens with the message left in it",
    );
    Ok(())
}

/// The subjects of a folder on the server, each as often as it is there
fn subjects(run: &Run<'_>, account: &str, path: &str) -> Vec<String> {
    run.servers
        .account(account)
        .map(|a| a.kit.subjects(&crate::servers::storage_name(path)))
        .unwrap_or_default()
}

fn writing(run: &mut Run<'_>, skipped: &mut Vec<String>) -> Result<(), Stop> {
    let work = account(run, Kind::Work);
    run.act(Act::Open(inbox(work)))?;
    run.act(Act::Click(5))?;
    run.settled()?;
    // five sent in a row, without waiting between them
    let sent: Vec<String> = (1..=5)
        .map(|n| format!("Sent in the deep test {} {n}", run.world.seed))
        .collect();
    for subject in &sent {
        let act = Act::Send {
            to: "someone@example.com".into(),
            subject: subject.clone(),
        };
        if !try_act(run, act, skipped)? {
            return Ok(());
        }
    }
    // what was sent comes back to the test's servers (ImapKit delivers it to the account's own Inbox) while the sync
    // that sent it runs: counted after the next one
    run.target.settle().map_err(Stop::Broken)?;
    run.act(Act::Sync)?;
    run.settled()?;
    let there = subjects(run, &work.name, "Sent");
    for subject in &sent {
        let times = there.iter().filter(|s| *s == subject).count();
        run.expect(times == 1, format!("\"{subject}\" is in Sent once ({times})"));
    }
    run.act(Act::Open(List::AllSent))?;
    run.settled()?;
    Ok(())
}

fn connection(run: &mut Run<'_>, skipped: &mut Vec<String>) -> Result<(), Stop> {
    let work = account(run, Kind::Work);
    let counted = |run: &Run<'_>, path: &str| {
        run.servers
            .account(&work.name)
            .and_then(|a| a.counted().into_iter().find(|c| c.path == path))
            .map_or(0, |c| c.messages)
    };
    // the connection dropped in the middle of a move: the server has each message once at the end
    run.act(Act::Open(inbox(work)))?;
    run.settled()?;
    run.act(Act::Click(40))?;
    run.act(Act::ShiftClick(260))?;
    let moved = run.check(false)?.selected.len() as u64;
    let (inbox_before, archive_before) = (counted(run, "INBOX"), counted(run, "Archive"));
    run.server("drops the connection at the next MOVE".into(), |s| {
        if let Some(a) = s.account(&work.name) {
            a.fault(json!({ "on": "command", "match": "MOVE", "close": true, "times": 1 }));
        }
    })?;
    run.act(Act::MoveTo(List::folder(&work.name, "Archive")))?;
    run.settled()?;
    run.act(Act::Sync)?;
    run.settled()?;
    let (inbox_after, archive_after) = (counted(run, "INBOX"), counted(run, "Archive"));
    // moved, or taken back as the server did not do it: either way each message once, none half way
    let whole = archive_after == archive_before + moved || archive_after == archive_before;
    run.expect(
        inbox_after + archive_after == inbox_before + archive_before && whole,
        format!(
            "after a dropped connection each of the {moved} messages is in the Inbox or Archive once, all of them in one (Inbox {inbox_before} to {inbox_after}, Archive {archive_before} to {archive_after})"
        ),
    );
    // one slow command: the other accounts' mail reads meanwhile
    let lists = account(run, Kind::Lists);
    run.server("makes the next two FETCH commands of Lists slow".into(), |s| {
        if let Some(a) = s.account(&lists.name) {
            a.fault(json!({ "on": "command", "match": "FETCH", "delay": 4000, "times": 2 }));
        }
    })?;
    run.act(Act::Open(inbox(lists)))?;
    run.act(Act::Click(1))?;
    run.act(Act::Open(inbox(work)))?;
    run.act(Act::Click(2))?;
    run.settled()?;
    // a server that refuses the extra connections
    let home = account(run, Kind::Home);
    run.server("refuses the next three connections to Home".into(), |s| {
        if let Some(a) = s.account(&home.name) {
            a.fault(json!({ "on": "greeting", "send": "* BYE Too many connections\r\n", "close": true, "times": 3 }));
        }
    })?;
    run.act(Act::Sync)?;
    run.act(Act::Open(inbox(home)))?;
    run.settled()?;
    run.act(Act::Sync)?;
    run.settled()?;
    // Broken's password changed elsewhere, then set back: the other accounts work meanwhile. An app asks for the new
    // password in a window of its own, which the drivers do not answer: the core's run only
    if run.target.name() != "core" {
        skipped.push(format!(
            "a password changed elsewhere is not tried on {}: the app asks for it",
            run.target.name()
        ));
        for server in &run.servers.accounts {
            server.mend();
        }
        return Ok(());
    }
    let broken = account(run, Kind::Broken);
    run.server("changes Broken's password".into(), |s| {
        if let Some(a) = s.account(&broken.name) {
            a.set_password("changed elsewhere");
        }
    })?;
    run.act(Act::Sync)?;
    run.act(Act::Open(List::AllInboxes))?;
    run.check(false)?;
    run.server("sets Broken's password back".into(), |s| {
        if let Some(a) = s.account(&broken.name) {
            a.set_password(pe_testkit::PASSWORD);
        }
    })?;
    run.act(Act::Sync)?;
    run.settled()?;
    for server in &run.servers.accounts {
        server.mend();
    }
    Ok(())
}
