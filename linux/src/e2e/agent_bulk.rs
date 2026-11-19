//! Step 28 of the UI test, continued: the agent answers an invitation through the Send question (its line, no Edit
//! First), changes many messages at once and takes that back, and the AI Agents window shows the change as one row
//! with one Undo and takes back what the program did with Undo Since.

use super::steps::{agent_said, date_now, folder_id};
use super::*;
use pe_core::i18n::Text;

const NEWSLETTER_SUBJECT: &str = "Club newsletter";

/// The two newsletters and the invitation in the Inbox, then the agent's go; its invitation answer and its changes
pub(super) async fn bulk_and_invitation(d: &Driver, out: &std::path::Path) {
    d.step("an agent's change of many messages, Undo Since and an invitation answer");
    for n in 1..=2 {
        let raw = format!(
            "From: Book Club <club@example.org>\r\nTo: testuser@inboxclassic.test\r\nSubject: {NEWSLETTER_SUBJECT} \
             {n}\r\nDate: {}\r\nMessage-ID: <club-{n}@example.org>\r\n\r\nThis month's books.\r\n",
            date_now(-30)
        );
        let _ = d.add_message(&raw, &[]);
    }
    let invite = format!(
        "From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\n\
         Subject: Invitation: Roadmap review\r\nDate: {}\r\nMessage-ID: <roadmap-invite@example.com>\r\n\
         MIME-Version: 1.0\r\nContent-Type: multipart/alternative; boundary=inv\r\n\r\n--inv\r\n\
         Content-Type: text/plain\r\n\r\nThe roadmap review.\r\n--inv\r\n\
         Content-Type: text/calendar; method=REQUEST; charset=utf-8\r\n\r\n\
         BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nUID:roadmap@example.com\r\nSEQUENCE:0\r\n\
         SUMMARY:Roadmap review\r\nDTSTART:20261204T140000Z\r\nDTEND:20261204T150000Z\r\n\
         ORGANIZER;CN=Ann Example:mailto:ann@example.com\r\n\
         ATTENDEE;CN=Test;RSVP=TRUE;PARTSTAT=NEEDS-ACTION:mailto:testuser@inboxclassic.test\r\n\
         END:VEVENT\r\nEND:VCALENDAR\r\n--inv--\r\n",
        date_now(-30)
    );
    let _ = d.add_message(&invite, &[]);
    run_command(Command::Sync);
    let inbox = folder_id("Inbox");
    let arrived = wait_until(30, || {
        inbox.is_some_and(|inbox| {
            let subjects: Vec<String> = listed_in_folder(inbox, 0, 500)
                .into_iter()
                .map(|m| m.info.subject)
                .collect();
            subjects.iter().filter(|s| s.starts_with(NEWSLETTER_SUBJECT)).count() == 2
                && subjects.iter().any(|s| s == "Invitation: Roadmap review")
        })
    })
    .await;
    d.check(arrived, "two newsletters and an invitation arrive");
    // the agent's go (scripts/ui-e2e/agent.mjs)
    let _ = std::fs::write(out.with_extension("jsonl.bulk"), "");
    invitation_answer(d, out).await;
    bulk_change(d, out).await;
    // the answer sent (it waits 30 seconds in the Outbox), so Undo Since finds it gone either way and says so; the
    // test server delivers it into the Inbox, where the steps after this one must not find it
    let sent = wait_until(60, || shell().core.outbox().is_ok_and(|o| o.is_empty())).await;
    d.check(sent, "the invitation answer leaves the Outbox");
    wait_until(20, || d.find("INBOX", "Subject: Accepted: Roadmap review").is_some()).await;
    undo_since(d).await;
    remove_messages(d).await;
}

/// The step's messages taken away from the server and the list, so the steps after it find the Inbox as before
async fn remove_messages(d: &Driver) {
    for message in d.messages("INBOX") {
        let raw = raw_text(&message);
        if (raw.contains("From: Book Club <club@example.org>")
            || raw.contains("<roadmap-invite@example.com>")
            || raw.contains("Subject: Accepted: Roadmap review"))
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
    let inbox = folder_id("Inbox");
    let gone = wait_until(30, || {
        inbox.is_some_and(|inbox| {
            !listed_in_folder(inbox, 0, 500)
                .iter()
                .any(|m| m.info.subject.starts_with(NEWSLETTER_SUBJECT) || m.info.subject.ends_with("Roadmap review"))
        })
    })
    .await;
    d.check(gone, "the step's messages are taken away");
}

/// The Send question of the agent's answer to the invitation: its line above the text, no Edit First
async fn invitation_answer(d: &Driver, out: &std::path::Path) {
    let ask = wait_for(60, || alert().filter(|a| a.widget_name() == "agent-send")).await;
    let Some(ask) = ask else {
        let said = agent_said(out, "error").or_else(|| agent_said(out, "invitation"));
        d.check(
            false,
            &format!("the agent's answer to the invitation is asked about ({said:?})"),
        );
        return;
    };
    let root: gtk::Widget = ask.clone().upcast();
    wait_until(10, || named_in(&root, "agent-invitation").is_some()).await;
    let line = label_of(&root, "agent-invitation");
    d.check(
        line.starts_with("This message accepts the invitation \u{201c}Roadmap review\u{201d}")
            && ask
                .heading()
                .is_some_and(|h| h.contains("Accepted: Roadmap review") || h.contains("My AI agent")),
        &format!("the Send question of the invitation answer says what it answers, above the text ({line})"),
    );
    d.check(
        !ask.has_response("compose")
            && ask.has_response("send")
            && ask.default_response().as_deref() == Some("dont")
            && ask.close_response() == "dont",
        "and has no Edit First; Don't Send is the default",
    );
    pause(2000).await;
    d.shot(&ask, "agents-13-invitation").await;
    answer(&ask, "Send");
    let sent = wait_for(30, || agent_said(out, "invitation")).await;
    let status = wait_for(10, || agent_said(out, "invitation-status")).await;
    d.check(
        sent.as_ref().is_some_and(|s| s["status"] == "sent")
            && status.as_ref().is_some_and(|s| s["your_status"] == "needs-action"),
        &format!(
            "the agent learns it was sent; the invitation's status waits until it has gone ({sent:?}; {status:?})"
        ),
    );
}

/// The agent's dry run, its change of the two newsletters, taken back by the agent, and made again
async fn bulk_change(d: &Driver, out: &std::path::Path) {
    let preview = wait_for(30, || agent_said(out, "bulk-preview"))
        .await
        .unwrap_or_default();
    d.check(
        preview["matches"] == 2 && preview["samples"].as_array().is_some_and(|s| s.len() == 2),
        &format!("the agent's dry run counts the two newsletters ({preview})"),
    );
    let changed = wait_for(30, || agent_said(out, "bulk")).await.unwrap_or_default();
    let undone = wait_for(30, || agent_said(out, "bulk-undone"))
        .await
        .unwrap_or_default();
    d.check(
        changed["changed"] == 2 && changed["change_id"].is_i64(),
        &format!("with its token it marks both read ({changed})"),
    );
    d.check(
        undone["undone"] == true && undone["messages_taken_back"] == 2,
        &format!("the agent takes its change back ({undone})"),
    );
    let again = wait_for(30, || agent_said(out, "bulk-again")).await.unwrap_or_default();
    let read = |subject: &str| d.seen(subject);
    let both_read = wait_until(20, || {
        read(&format!("{NEWSLETTER_SUBJECT} 1")) && read(&format!("{NEWSLETTER_SUBJECT} 2"))
    })
    .await;
    d.check(
        again["changed"] == 2 && both_read,
        &format!("its second change marks both read, on the server ({again})"),
    );
    let _ = wait_for(30, || agent_said(out, "done")).await;
}

/// The rows of what agents did, in the order the log shows them
fn entry_rows(agents: &adw::Dialog) -> Vec<adw::ActionRow> {
    let mut rows: Vec<adw::ActionRow> = descendants::<adw::ActionRow>(agents.upcast_ref())
        .into_iter()
        .filter(|row| row.widget_name() == "agents-entry")
        .collect();
    rows.sort_by_key(|row| row.index());
    rows
}

/// The change is one row of the log with one Undo; Undo Since asks with the count, takes back and says what it did
async fn undo_since(d: &Driver) {
    command(Command::AiAgents);
    let Some(agents) = wait_dialog(10, "agents-dialog").await else {
        d.check(false, "Tools > AI Agents opens for Undo Since");
        return;
    };
    let rows = entry_rows(&agents);
    let titles: Vec<String> = rows.iter().map(|row| row.title().to_string()).collect();
    // the catalog's words of the change of the two newsletters, and of it taken back
    let bulk = pe_core::i18n::tr_args(
        Text::AgentLogBulkRead,
        &[("count", 2u64.into()), ("query", "subject:\"Club newsletter\"".into())],
    );
    let bulk_back = pe_core::i18n::tr_args(Text::AgentLogTakenBack, &[("entry", (&bulk).into())]);
    let first = rows.iter().position(|row| row.title() == bulk);
    let taken_back = titles.iter().filter(|t| **t == bulk_back).count();
    d.check(
        first.is_some() && taken_back == 1,
        &format!("the change of many messages is one row of the log, the one taken back marked so ({titles:?})"),
    );
    if let Some(row) = first.and_then(|at| rows.get(at))
        && let Some(log) = row.parent().and_downcast::<gtk::ListBox>()
    {
        log.select_row(Some(row));
    }
    let undo = named_in(agents.upcast_ref(), "agents-undo").is_some_and(|u| u.is_sensitive());
    d.check(undo, "with one Undo");
    d.shot(&agents, "agents-11-bulk").await;

    let since = named_in(agents.upcast_ref(), "agents-undo-since");
    let hosts = named_in(agents.upcast_ref(), "agents-hosts").and_downcast::<gtk::ListBox>();
    if let Some(hosts) = &hosts {
        hosts.unselect_all();
    }
    d.check(
        since.as_ref().is_some_and(|b| !b.is_sensitive()),
        "Undo Since is off with no program selected",
    );
    let Some(hosts) = hosts else { return };
    let agent_row = descendants::<adw::ActionRow>(hosts.upcast_ref())
        .into_iter()
        .find(|row| row.title() == "My AI agent");
    if let Some(row) = &agent_row {
        hosts.select_row(Some(row));
    }
    d.check(
        since.as_ref().is_some_and(|b| b.is_sensitive()),
        "and on with the program selected",
    );
    click(agents.upcast_ref(), "agents-undo-since");
    let Some(ask) = wait_for(10, || alert().filter(|a| a.widget_name() == "agent-undo-since")).await else {
        d.check(false, "Undo Since asks first");
        return;
    };
    let root: gtk::Widget = ask.clone().upcast();
    let spans = named_in(&root, "agent-undo-span").and_downcast::<gtk::DropDown>();
    let labels: Vec<String> = spans
        .as_ref()
        .and_then(|s| s.model())
        .and_downcast::<gtk::StringList>()
        .map(|list| {
            (0..list.n_items())
                .filter_map(|i| list.string(i))
                .map(|s| s.to_string())
                .collect()
        })
        .unwrap_or_default();
    d.check(
        spans.as_ref().is_some_and(|s| s.selected() == 0)
            && label_of(&root, "agent-undo-span-label") == crate::words::plain(Text::UiUndoSinceSpan)
            && labels.len() == 6
            && labels.first() == pe_core::agents::undo_span_label(0).as_ref()
            && labels.last() == pe_core::agents::undo_span_label(5).as_ref(),
        &format!("it asks what to take back, in spans, In the last 15 minutes first ({labels:?})"),
    );
    let host_id = shell()
        .core
        .agent_hosts()
        .unwrap_or_default()
        .into_iter()
        .find(|h| h.name == "My AI agent")
        .map(|h| h.id);
    let count = host_id
        .and_then(|id| {
            shell()
                .core
                .agent_undoable_since(id, pe_core::agents::undo_span_since(0)?)
                .ok()
        })
        .unwrap_or(0);
    let question = label_of(&root, "agent-undo-question");
    let asked = pe_core::i18n::tr_args(
        Text::AgentUndoSinceQuestion,
        &[("program", "My AI agent".into()), ("count", count.into())],
    );
    d.check(
        count >= 1
            && question == asked
            && label_of(&root, "agent-undo-detail") == pe_core::i18n::tr(Text::AgentUndoSinceDetail),
        &format!("with the count of the changes it would take back ({question})"),
    );
    d.check(
        ask.default_response().as_deref() == Some("cancel")
            && ask.close_response() == "cancel"
            && ask.response_appearance("take") == adw::ResponseAppearance::Destructive,
        "Cancel is the default and Esc, Take Back shown as what changes mail",
    );
    pause(500).await;
    d.shot(&ask, "agents-12-undo-since").await;
    let ask = undo_since_looks(d, &agents, ask).await;
    let Some(ask) = ask else {
        d.check(false, "Undo Since asks again after the other looks");
        return;
    };
    let root: gtk::Widget = ask.clone().upcast();
    let spans = named_in(&root, "agent-undo-span").and_downcast::<gtk::DropDown>();
    // the longest span asks the same, with as many or more
    if let Some(spans) = &spans {
        spans.set_selected(5);
    }
    let longer = label_of(&root, "agent-undo-question");
    let longer_count = host_id
        .and_then(|id| {
            shell()
                .core
                .agent_undoable_since(id, pe_core::agents::undo_span_since(5)?)
                .ok()
        })
        .unwrap_or(0);
    let longer_asked = pe_core::i18n::tr_args(
        Text::AgentUndoSinceQuestion,
        &[("program", "My AI agent".into()), ("count", longer_count.into())],
    );
    d.check(
        longer == longer_asked && ask.has_response("take"),
        &format!("another span asks again ({longer})"),
    );
    answer(&ask, "Take Back");
    let report = wait_for(20, || {
        alert().filter(|a| a.widget_name() != "agent-undo-since" && a.is_mapped())
    })
    .await;
    let said = report.as_ref().map(alert_text).unwrap_or_default();
    d.check(
        longer_count > 0
            && said.contains(&pe_core::i18n::tr_args(
                Text::AgentUndoDone,
                &[("count", longer_count.into())],
            )),
        &format!("Take Back says what it took back, and what it left ({said})"),
    );
    if let Some(report) = &report {
        report.close();
    }
    d.check(
        wait_until(10, || {
            entry_rows(&agents)
                .iter()
                .filter(|row| row.title() == bulk_back)
                .count()
                == 2
        })
        .await,
        "the log shows the change taken back",
    );
    d.check(
        wait_until(20, || {
            !d.seen(&format!("{NEWSLETTER_SUBJECT} 1")) && !d.seen(&format!("{NEWSLETTER_SUBJECT} 2"))
        })
        .await,
        "and the newsletters are unread again, on the server",
    );
    // asked again: only what is left is counted (the answer that had left the Outbox), Close alone when nothing is
    click(agents.upcast_ref(), "agents-undo-since");
    if let Some(again) = wait_for(10, || alert().filter(|a| a.widget_name() == "agent-undo-since")).await {
        let root: gtk::Widget = again.clone().upcast();
        let left = host_id
            .and_then(|id| {
                shell()
                    .core
                    .agent_undoable_since(id, pe_core::agents::undo_span_since(0)?)
                    .ok()
            })
            .unwrap_or(u64::MAX);
        let question = label_of(&root, "agent-undo-question");
        let answers = if left == 0 {
            question.contains("has no changes in this period")
                && again.has_response("close")
                && !again.has_response("take")
        } else {
            again.has_response("take") && again.has_response("cancel")
        };
        d.check(
            left < count && answers,
            &format!("asked again, it counts only what is left, with only Close when nothing is ({left}; {question})"),
        );
        again.close();
    } else {
        d.check(false, "Undo Since asks again");
    }
    pause(300).await;
    agents.close();
    wait_gone(10, "agents-dialog").await;
}

/// The question of Undo Since in the dark style, in German and in the pseudo-language, for fit; asked again in English
async fn undo_since_looks(d: &Driver, agents: &adw::Dialog, ask: adw::AlertDialog) -> Option<adw::AlertDialog> {
    let styles = adw::StyleManager::default();
    styles.set_color_scheme(adw::ColorScheme::ForceDark);
    wait_until(5, || styles.is_dark()).await;
    pause(300).await;
    d.shot(&ask, "agents-12-undo-since-dark").await;
    styles.set_color_scheme(adw::ColorScheme::Default);
    ask.close();
    for language in ["de", "qps", "en"] {
        wait_until(5, || alert().is_none_or(|a| a.widget_name() != "agent-undo-since")).await;
        pe_core::i18n::set_language(language);
        click(agents.upcast_ref(), "agents-undo-since");
        let Some(again) = wait_for(10, || alert().filter(|a| a.widget_name() == "agent-undo-since")).await else {
            pe_core::i18n::set_language("en");
            return None;
        };
        if language == "en" {
            return Some(again);
        }
        pause(500).await;
        d.shot(&again, &format!("agents-12-undo-since-{language}")).await;
        again.close();
    }
    None
}
