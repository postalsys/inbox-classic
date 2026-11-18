//! Step 28 of the UI test, continued: what the AI Agents log shows of an agent's reads (a summary of each program's
//! hour, opened to the subjects and queries), the log in another language, Clear Log that still counts the sends,
//! and the connect question of programs started from a terminal in English, German and the pseudo-language.

use super::steps::folder_id;
use super::*;

/// The rows of what agents did and the summaries of what they read, in the order the log shows them
fn log_rows(agents: &adw::Dialog) -> (Vec<String>, Vec<adw::ExpanderRow>) {
    let mut entries: Vec<adw::ActionRow> = descendants::<adw::ActionRow>(agents.upcast_ref())
        .into_iter()
        .filter(|row| row.widget_name() == "agents-entry")
        .collect();
    entries.sort_by_key(|row| row.index());
    let mut reads: Vec<adw::ExpanderRow> = descendants::<adw::ExpanderRow>(agents.upcast_ref())
        .into_iter()
        .filter(|row| row.widget_name() == "agents-reads")
        .collect();
    reads.sort_by_key(|row| row.index());
    (entries.iter().map(|row| row.title().to_string()).collect(), reads)
}

/// The reads a summary shows opened
fn reads_under(summary: &adw::ExpanderRow) -> Vec<String> {
    descendants::<adw::ActionRow>(summary.upcast_ref())
        .into_iter()
        .filter(|row| row.widget_name() == "agents-read")
        .map(|row| row.title().to_string())
        .collect()
}

/// In the open AI Agents window: the summary of what the agent read, opened to the messages it read, with no Undo
pub(super) async fn reads(d: &Driver, agents: &adw::Dialog) {
    let (_, summaries) = log_rows(agents);
    let Some(summary) = summaries.first() else {
        d.check(false, "the log sums up what the agent read");
        return;
    };
    let title = summary.title().to_string();
    d.check(
        title.starts_with("Read 1 message") && summary.subtitle().ends_with("My AI agent"),
        &format!("the log sums up what the agent read in the hour, by program ({title})"),
    );
    summary.set_expanded(true);
    summary.grab_focus();
    let shown = wait_for(10, || Some(reads_under(summary)).filter(|r| !r.is_empty())).await;
    let shown = shown.unwrap_or_default();
    d.check(
        shown.iter().any(|read| {
            read == "Read \u{201c}Team lunch on Friday\u{201d}" || read == "Read \u{201c}Quarterly report draft\u{201d}"
        }),
        &format!("opened, it lists the subjects read, never the text ({shown:?})"),
    );
    let undo = named_in(agents.upcast_ref(), "agents-undo").is_some_and(|u| u.is_sensitive());
    d.check(
        summary.is_selected() && !undo,
        "the summary is selected when opened, with nothing to undo",
    );
    // opened, and scrolled to show its reads
    pause(600).await;
    if let Some(scrolled) = summary
        .ancestor(gtk::ScrolledWindow::static_type())
        .and_downcast::<gtk::ScrolledWindow>()
    {
        let adjustment = scrolled.vadjustment();
        adjustment.set_value(adjustment.upper() - adjustment.page_size());
    }
    pause(300).await;
    d.shot(agents, "agents-9-reads").await;
    // and in the dark style
    let styles = adw::StyleManager::default();
    styles.set_color_scheme(adw::ColorScheme::ForceDark);
    wait_until(5, || styles.is_dark()).await;
    pause(300).await;
    d.shot(agents, "agents-9-reads-dark").await;
    styles.set_color_scheme(adw::ColorScheme::Default);
    summary.set_expanded(false);
}

/// The log's rows in German after the language changes: written as data, they are worded when shown
pub(super) async fn in_another_language(d: &Driver) {
    pe_core::i18n::set_language("de");
    command(Command::AiAgents);
    if let Some(agents) = wait_dialog(10, "agents-dialog").await {
        let (entries, summaries) = log_rows(&agents);
        let summary = summaries.first().map(|s| s.title().to_string()).unwrap_or_default();
        d.check(
            summary.contains("gelesen")
                && entries
                    .iter()
                    .any(|e| e.starts_with("Unterhaltung \u{201e}") && e.ends_with("\u{201c} beobachtet")),
            &format!("in German, the log's rows are in German ({summary}; {entries:?})"),
        );
        d.shot(&agents, "agents-9-reads-de").await;
        agents.close();
        wait_gone(10, "agents-dialog").await;
    } else {
        d.check(false, "Tools > AI Agents opens in German");
    }
    pe_core::i18n::set_language("en");
}

/// Clear Log empties the window, but the agent's sends still count against its limit
pub(super) async fn cleared(d: &Driver) {
    command(Command::AiAgents);
    let Some(agents) = wait_dialog(10, "agents-dialog").await else {
        d.check(false, "Tools > AI Agents opens to clear the log");
        return;
    };
    click(agents.upcast_ref(), "agents-clear");
    if let Some(ask) = wait_for(10, alert).await {
        answer(&ask, "Yes");
    }
    d.check(
        wait_until(10, || {
            let (entries, summaries) = log_rows(&agents);
            entries.is_empty() && summaries.is_empty()
        })
        .await,
        "Clear Log empties the log",
    );
    agents.close();
    wait_gone(10, "agents-dialog").await;
    let host = shell()
        .core
        .agent_hosts()
        .unwrap_or_default()
        .into_iter()
        .find(|h| h.name == "My AI agent");
    let sends = host.and_then(|host| {
        let store = pe_store::Store::open(d.out.join("store.db")).ok()?;
        let since = glib::DateTime::now_utc().ok()?.to_unix() - 3600;
        store.agent_log_count(host.id, "send", since).ok()
    });
    d.check(
        sends.is_some_and(|n| n >= 1),
        &format!("the message it sent still counts against its limit ({sends:?})"),
    );
    // the flag the agent set comes off again, so the steps after this count the Inbox's flags as before
    if let Some(inbox) = folder_id("Inbox") {
        let flagged: Vec<u64> = listed_in_folder(inbox, 0, 500)
            .iter()
            .filter(|m| m.info.subject == "Quarterly report draft" && m.info.flagged())
            .map(|m| m.info.uid)
            .collect();
        let _ = shell().core.set_flag_color_many(inbox, &flagged, None);
    }
}

/// An agent started from a terminal (`program`, a copy of the shell named as a terminal): the relay runs under it, as
/// under a terminal's shell, and asks once to be let in
fn start_from_terminal(d: &Driver, program: &str) -> Option<std::process::Child> {
    use std::os::unix::process::CommandExt;
    let dir = d.out.join("terminal");
    let _ = std::fs::create_dir_all(&dir);
    let terminal = dir.join(program);
    std::fs::copy("/bin/sh", &terminal).ok()?;
    let init = r#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"ui-test","version":"1"}}}"#;
    // a pipeline: the relay is the terminal's child (not exec'd in its place); its input stays open for the question
    std::process::Command::new(&terminal)
        .arg("-c")
        .arg(r#"{ printf '%s\n' "$INIT"; sleep 120; } | "$APP" --mcp --store "$STORE""#)
        .env("INIT", init)
        .env("APP", std::env::current_exe().unwrap_or_default())
        .env("STORE", d.out.join("store.db"))
        .stdout(Stdio::null())
        .process_group(0)
        .spawn()
        .ok()
}

/// Ends the terminal of [`start_from_terminal`] with what it runs
fn end_terminal(mut child: std::process::Child) {
    let _ = Process::new("kill").arg("--").arg(format!("-{}", child.id())).status();
    let _ = child.wait();
}

/// The connect question of programs started from a terminal: the core's words, how to give one its own access with
/// --name, nothing cut off, in English, German and the pseudo-language; turned away, the programs list says so
pub(super) async fn terminal_programs(d: &Driver) {
    d.step("an AI agent started from a terminal");
    for (language, program) in [("en", "xterm"), ("de", "foot"), ("qps", "kitty")] {
        pe_core::i18n::set_language(language);
        let child = start_from_terminal(d, program);
        d.check(
            child.is_some(),
            &format!("{language}: a terminal {program} starts an agent"),
        );
        // this terminal's question, not the one before it while that one closes
        let ask = wait_for(30, || {
            alert().filter(|a| {
                a.widget_name() == "agent-connect" && a.heading().is_some_and(|h| h.contains(&format!("({program})")))
            })
        })
        .await;
        match &ask {
            Some(ask) => {
                let root: gtk::Widget = ask.clone().upcast();
                let heading = ask.heading().unwrap_or_default().to_string();
                let body = ask.body().to_string();
                let programs = pe_core::agents::host_label(program, &format!("/x/{program}"));
                d.check(
                    heading.contains(&programs)
                        && body.contains(if language == "qps" { "--ñámé" } else { "--name" }),
                    &format!(
                        "{language}: the question is for the programs started from the terminal, and tells about \
                         --name ({heading}; {body})"
                    ),
                );
                if language == "en" {
                    d.check(
                        heading == "Programs started from a terminal (xterm) want to use your mail",
                        &format!("in English: {heading}"),
                    );
                }
                pause(400).await;
                let cut: Vec<String> = descendants::<gtk::Label>(&root)
                    .into_iter()
                    .filter(|l| l.is_mapped() && l.widget_name() != "agent-path" && l.layout().is_ellipsized())
                    .map(|l| l.text().to_string())
                    .collect();
                d.check(
                    cut.is_empty(),
                    &format!("{language}: nothing in the question is cut off ({cut:?})"),
                );
                let name = match language {
                    "en" => "agents-10-terminal".to_string(),
                    _ => format!("agents-10-terminal-{language}"),
                };
                d.shot(ask, &name).await;
                answer(ask, "Deny");
            }
            None => d.check(false, &format!("{language}: the terminal's agent is asked about")),
        }
        if let Some(child) = child {
            end_terminal(child);
        }
    }
    pe_core::i18n::set_language("en");
    command(Command::AiAgents);
    let Some(agents) = wait_dialog(10, "agents-dialog").await else {
        d.check(false, "Tools > AI Agents opens");
        return;
    };
    let hosts: Vec<String> = descendants::<adw::ActionRow>(agents.upcast_ref())
        .into_iter()
        .filter(|row| row.widget_name() == "agents-host")
        .map(|row| row.title().to_string())
        .collect();
    d.check(
        hosts.iter().any(|h| h == "Programs started from a terminal (xterm)"),
        &format!("turned away, the list of programs names them so ({hosts:?})"),
    );
    agents.close();
    wait_gone(10, "agents-dialog").await;
}
