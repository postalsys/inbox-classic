//! The deep test's driver of the Linux app (docs/deep-test-plan.md, core/crates/pe-deep/src/driver.rs): the app
//! started as the conductor asks (`--deep` with its store, passwords in memory and ImapKit's certificate), a request
//! read from standard input a line at a time, done as a hand does it, and answered on standard output with a line
//! that starts with `DEEP `. Built with the `e2e` feature only, as the UI test is: a release has none of it.

use pe_deep::model::{Act, List, Message, Row, Seen, UNSUPPORTED};
use serde_json::{Value, json};

use super::*;

thread_local! {
    /// The accounts the conductor named, by their names
    static ACCOUNTS: RefCell<Vec<(String, i64)>> = const { RefCell::new(Vec::new()) };
}

/// The app run with the driver reading its requests
pub fn run(arguments: crate::Arguments, argv: Vec<String>) -> glib::ExitCode {
    trace_criticals();
    glib::timeout_add_local_once(Duration::from_millis(500), || {
        glib::spawn_future_local(serve());
    });
    crate::run(arguments, argv)
}

fn reply(value: Value) {
    let mut out = std::io::stdout().lock();
    let _ = writeln!(out, "DEEP {value}");
    let _ = out.flush();
}

/// Requests one after another until standard input ends or the conductor says to quit
async fn serve() {
    loop {
        let line = gio::spawn_blocking(|| {
            let mut line = String::new();
            std::io::stdin().read_line(&mut line).map(|n| (n, line))
        })
        .await;
        let Ok(Ok((n, line))) = line else { break };
        if n == 0 {
            break;
        }
        let Ok(request) = serde_json::from_str::<Value>(&line) else {
            reply(json!({ "ok": false, "error": format!("not a request: {line}") }));
            continue;
        };
        if request.get("quit").is_some() {
            reply(json!({ "ok": true }));
            break;
        }
        // a panic in a request is its failure, not the end of the driver
        let outcome = Rc::new(RefCell::new(None));
        let into = outcome.clone();
        let caught = futures_catch(std::panic::AssertUnwindSafe(async move {
            *into.borrow_mut() = Some(handle(&request).await);
        }))
        .await;
        let answered = match (caught, outcome.borrow_mut().take()) {
            (Ok(()), Some(Ok(mut value))) => {
                value["ok"] = json!(true);
                value
            }
            (Ok(()), Some(Err(error))) => json!({ "ok": false, "error": error }),
            (Ok(()), None) => json!({ "ok": false, "error": "no answer" }),
            (Err(panic), _) => json!({ "ok": false, "error": format!("the driver panicked: {panic}") }),
        };
        reply(answered);
    }
    if let Some(app) = gio::Application::default() {
        app.quit();
    }
}

async fn handle(request: &Value) -> Result<Value, String> {
    if let Some(start) = request.get("start") {
        return start_accounts(start).await.map(|()| json!({}));
    }
    if let Some(seconds) = request.get("settle") {
        return settle(seconds.as_u64().unwrap_or(600)).await.map(|()| json!({}));
    }
    if request.get("observe").is_some() {
        return Ok(json!({ "seen": observe().to_json() }));
    }
    if request.get("health").is_some() {
        let files = std::fs::read_dir("/proc/self/fd").map_or(0, |d| d.count());
        return Ok(json!({ "open_files": files }));
    }
    if let Some(path) = request.get("screenshot").and_then(Value::as_str) {
        if let Some(texture) = capture(shell().main().window().upcast_ref()).await {
            let _ = texture.save_to_png(path);
        }
        return Ok(json!({}));
    }
    let act = Act::from_json(request).ok_or_else(|| format!("not an act: {request}"))?;
    act_on(&act).await.map(|()| json!({}))
}

/// The accounts added as the core's call does it (as the Mac's driver does; the form is the UI test's), named as the
/// conductor names them, the first sync of each asked for and waited for
async fn start_accounts(start: &Value) -> Result<(), String> {
    let core = &shell().core;
    let _ = core.set_download_ahead(pe_core::Ahead::Never);
    // a message sent goes at once
    let _ = core.set_send_delay(0);
    // one row a message, as the conductor starts: Group asks for conversations
    shell().settings.set_bool(crate::settings::GROUP_BY_CONVERSATION, false);
    shell().main().regroup();
    for account in start["accounts"].as_array().ok_or("no accounts")? {
        let text = |key: &str| account[key].as_str().unwrap_or_default().to_string();
        let port = |key: &str| account[key].as_u64().unwrap_or(0) as u16;
        let settings = pe_store::AccountSettings {
            name: text("name"),
            email: text("email"),
            username: text("username"),
            imap_host: "127.0.0.1".into(),
            imap_port: port("imap"),
            imap_security: pe_store::Security::Plain,
            smtp_host: "127.0.0.1".into(),
            smtp_port: port("smtp"),
            // ImapKit's SMTP server takes AUTH after STARTTLS only
            smtp_security: pe_store::Security::StartTls,
            auth: pe_store::Auth::Password,
        };
        let id = core
            .add_account(&settings, &text("password"))
            .map_err(|e| e.to_string())?;
        core.set_account_name(id, &text("name")).map_err(|e| e.to_string())?;
        ACCOUNTS.with(|a| a.borrow_mut().push((text("name"), id)));
        core.sync(id).map_err(|e| e.to_string())?;
    }
    shell().main().reload();
    settle(1800).await
}

fn account_id(name: &str) -> Result<i64, String> {
    ACCOUNTS
        .with(|a| a.borrow().iter().find(|(n, _)| n == name).map(|(_, id)| *id))
        .ok_or_else(|| format!("no account {name}"))
}

fn account_name(id: i64) -> String {
    ACCOUNTS.with(|a| {
        a.borrow()
            .iter()
            .find(|(_, i)| *i == id)
            .map(|(n, _)| n.clone())
            .unwrap_or_default()
    })
}

/// The folder of `account` at `path`
fn folder_id(account: &str, path: &str) -> Result<i64, String> {
    let core = &shell().core;
    core.folders(account_id(account)?)
        .map_err(|e| e.to_string())?
        .into_iter()
        .find(|f| pe_core::folder_path_decoded(&f.info.path) == path)
        .map(|f| f.id)
        .ok_or_else(|| format!("no folder {account}/{path}"))
}

/// The account and path of a folder
fn folder_place(id: i64) -> Option<(String, String)> {
    let core = &shell().core;
    let folder = core.folder(id).ok()?;
    Some((
        account_name(folder.account_id),
        pe_core::folder_path_decoded(&folder.info.path),
    ))
}

/// The row of the tree that lists `list`
fn row_of(list: &List) -> Result<i64, String> {
    Ok(match list {
        List::Folder { account, path } => folder_id(account, path)?,
        List::AllInboxes => crate::folders::ALL_INBOXES,
        List::Flagged => crate::folders::FLAGGED,
        List::AllSent => crate::folders::ALL_SENT,
        List::AllDrafts => crate::folders::ALL_DRAFTS,
    })
}

/// The rows a page of the list scrolls by
fn page_rows() -> u32 {
    shell().main().list.rows_in_sight().map_or(20, |(a, b)| (b - a).max(1))
}

async fn act_on(act: &Act) -> Result<(), String> {
    let main = shell().main();
    let rows = main.list.rows();
    let last = rows.saturating_sub(1);
    match act {
        Act::Open(list) => {
            // a click on the row: its list loads after the tree has drawn it
            if !main.folders.select(row_of(list)?, true) {
                return Err(format!("{} is not in the folder list", list.label()));
            }
        }
        Act::Scroll(row) => main.list.scroll_to((*row as u32).min(last), gtk::ListScrollFlags::NONE),
        Act::Home => main.list.scroll_to(0, gtk::ListScrollFlags::NONE),
        Act::End => main.list.scroll_to(last, gtk::ListScrollFlags::NONE),
        Act::PageDown(times) => {
            let from = main.list.rows_in_sight().map_or(0, |(_, b)| b);
            main.list
                .scroll_to((from + page_rows() * times).min(last), gtk::ListScrollFlags::NONE);
        }
        Act::Click(row) => {
            let row = *row as u32;
            if row >= rows {
                return Err(format!("no row {row} in a list of {rows}"));
            }
            main.list.select(row);
        }
        Act::ShiftClick(row) => {
            let from = main.list.selected_ranges().first().map_or(0, |(a, _)| *a);
            let to = (*row).min(u64::from(last));
            let (a, b) = (from.min(to), from.max(to));
            main.list.select_positions(&(a..=b).collect::<Vec<u64>>());
        }
        Act::SelectAll => run_command(Command::SelectAll),
        Act::Delete => command(Command::Delete),
        Act::MoveTo(List::Folder { account, path }) => {
            let to = folder_id(account, path)?;
            let refs = main.list.refs_in_ranges(&main.list.selected_ranges());
            main.drop_message(&refs, to, false);
        }
        Act::MoveTo(_) => return Err("messages move to a folder".into()),
        Act::Flag => run_command(Command::Flag),
        Act::Read => run_command(Command::MarkRead),
        Act::Unread => run_command(Command::MarkUnread),
        Act::Sort(by, ascending) => {
            main.sort_by((*by).into());
            main.sort_direction(*ascending);
        }
        Act::Search(text) => main.find.set_text(text),
        Act::Group(on) => {
            shell().settings.set_bool(crate::settings::GROUP_BY_CONVERSATION, *on);
            main.regroup();
        }
        Act::UnreadOnly(on) => main.set_hide_read(*on),
        Act::Undo => run_command(Command::Undo),
        Act::Sync => run_command(Command::Sync),
        Act::MarkAllRead => command(Command::MarkAllRead),
        Act::EmptyFolder => {
            command(Command::EmptyFolder);
            let sure = wait_alert(10).await.ok_or("Empty Folder did not ask")?;
            answer(&sure, "Empty");
        }
        Act::Send { to, subject } => {
            let before = shell().composes.borrow().len();
            run_command(Command::NewMail);
            let c = wait_for(20, || {
                let shell = shell();
                let composes = shell.composes.borrow();
                (composes.len() > before).then(|| composes.last().cloned()).flatten()
            })
            .await
            .ok_or("New Mail opened no window")?;
            wait_until(10, || c.editor.is_loaded()).await;
            c.to.set_text(to);
            c.subject.set_text(subject);
            click(c.window.upcast_ref(), "compose-send");
        }
        Act::Restart => return Err(UNSUPPORTED.into()),
    }
    // the answer comes once the app has taken the act in, a turn of the main loop later; a note it shows (nothing to
    // undo) closed, as a user who goes on does
    pause(150).await;
    if let Some(note) = alert() {
        note.close();
    }
    Ok(())
}

/// Waits until nothing is under way: the core quiet (no sync or action), then a sync of every account as a barrier
/// (it finishes after the commands queued before it), then the list neither waiting nor being read
async fn settle(seconds: u64) -> Result<(), String> {
    let core = &shell().core;
    let quiet = || core.quiet() && !list_settling();
    if !wait_until(seconds, quiet).await {
        return Err(format!("still busy after {seconds} s"));
    }
    core.sync_barrier().map_err(|e| e.to_string())?;
    // what the barrier's sync brought: the list read again once the app has heard of it
    pause(300).await;
    if !wait_until(seconds, quiet).await {
        return Err(format!("still busy after {seconds} s"));
    }
    pause(300).await;
    if !wait_until(seconds, quiet).await {
        return Err(format!("still busy after {seconds} s"));
    }
    // then the rows drawn the list as the store has it now (the core says, scripts/ui-e2e/DEEP.md): whatever is still
    // on its way to the window gets there; a row left blank or a list left behind is the checks' to report
    let main = shell().main();
    wait_until(CURRENT_WITHIN, || quiet() && main.list.drawn_current()).await;
    Ok(())
}

/// How long the rows drawn may take to be the list once all is quiet, in seconds
const CURRENT_WITHIN: u64 = 10;

/// What the window shows, read off its controls
fn observe() -> Seen {
    let main = shell().main();
    let core = &shell().core;
    let rows = main.list.rows();
    let message = |m: &pe_store::Message| {
        folder_place(m.folder_id).map(|(account, path)| Message {
            account,
            path,
            uid: m.info.uid,
        })
    };
    let sight: Vec<Row> = main
        .list
        .rows_in_sight()
        .map(|(first, last)| {
            (first..=last.min(rows.saturating_sub(1)))
                .filter(|_| rows > 0)
                .map(|row| match main.list.drawn_at(row) {
                    Some(m) => Row {
                        row: u64::from(row),
                        blank: false,
                        message: message(&m),
                        subject: m.info.subject.clone(),
                        date: m.info.date.or(m.info.internal_date).unwrap_or(0),
                    },
                    None => Row {
                        row: u64::from(row),
                        blank: true,
                        message: None,
                        subject: String::new(),
                        date: 0,
                    },
                })
                .collect()
        })
        .unwrap_or_default();
    // the estimate of the first and the last row on screen (from the scrolling, the header in it) can be a row off,
    // and a row half off the screen is not asked for until it shows: a blank one at either edge is left out
    let edge = |row: Option<&Row>| row.is_some_and(|r| r.blank);
    let mut sight = sight;
    if edge(sight.last()) {
        sight.pop();
    }
    if edge(sight.first()) {
        sight.remove(0);
    }
    let selected: Vec<u64> = main.list.selected_ranges().iter().flat_map(|(a, b)| *a..*b).collect();
    let shown = (main.reader.uid() != 0)
        .then(|| folder_place(main.reader.folder()))
        .flatten()
        .map(|(account, path)| Message {
            account,
            path,
            uid: main.reader.uid(),
        });
    let list = main.folders.selected_row().and_then(|row| {
        Some(match row.list {
            pe_core::tree::TreeList::Folder => {
                let (account, path) = folder_place(row.folder)?;
                List::Folder { account, path }
            }
            pe_core::tree::TreeList::AllInboxes => List::AllInboxes,
            pe_core::tree::TreeList::Flagged => List::Flagged,
            pe_core::tree::TreeList::AllSent => List::AllSent,
            pe_core::tree::TreeList::AllDrafts => List::AllDrafts,
            pe_core::tree::TreeList::None => return None,
        })
    });
    // the counts the tree shows come from the core's rows of it
    let tree = ACCOUNTS
        .with(|a| a.borrow().clone())
        .into_iter()
        .flat_map(|(name, id)| {
            core.folders(id)
                .unwrap_or_default()
                .into_iter()
                .map(move |f| (name.clone(), pe_core::folder_path_decoded(&f.info.path), f.unread))
        })
        .collect();
    let view = main.list.view();
    Seen {
        list,
        rows: u64::from(rows),
        sight,
        selected,
        shown,
        search: view.text().to_string(),
        grouped: view.grouped(),
        unread_only: view.show() == pe_store::Show::Unread,
        tree,
        // the list before, dimmed while the one chosen is read: its rows are not this list's
        pending: main.list_dimmed(),
    }
}
