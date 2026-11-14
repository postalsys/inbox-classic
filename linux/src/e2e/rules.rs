//! Step 19g of the UI test: Message Rules. A rule made in Tools > Message Rules (Newsletters: from news@example.com,
//! moved to Archive and marked read) sorts a message that arrives; a query naming a folder is refused; Create Rule on
//! the search bar and Create Rule from Message start a rule with the words searched for and the sender. The rule is
//! deleted again for the steps after.

use super::steps::date_now;
use super::*;

const WEEKLY: &str = "Weekly news in the UI test";

/// The rows of the Message Rules window
fn rules_listed(dialog: &gtk::Widget) -> usize {
    named_in(dialog, "rules-list")
        .map(|l| descendants::<adw::ActionRow>(&l).len())
        .unwrap_or(0)
}

fn set_check(root: &gtk::Widget, name: &str, on: bool) -> bool {
    match named_in(root, name).and_downcast::<gtk::CheckButton>() {
        Some(check) => {
            check.set_active(on);
            true
        }
        None => false,
    }
}

/// What the editor says matches now
fn count_text(editor: &gtk::Widget) -> String {
    named_in(editor, "rule-count")
        .and_downcast::<adw::ActionRow>()
        .map(|r| r.title().to_string())
        .unwrap_or_default()
}

async fn open_rules(d: &Driver) -> Option<adw::Dialog> {
    command(Command::MessageRules);
    let dialog = wait_dialog(10, "rules-dialog").await;
    d.check(dialog.is_some(), "The list opens: Tools > Message Rules");
    dialog
}

pub(super) async fn message_rules(d: &Driver) {
    d.step("message rules");
    select_folder("Inbox");
    let Some(rules) = open_rules(d).await else { return };
    let rules_widget = rules.clone().upcast::<gtk::Widget>();
    // the placeholder is found once it is drawn
    let empty = wait_until(5, || {
        rules_listed(&rules_widget) == 0 && named_in(&rules_widget, "rules-none").is_some()
    })
    .await;
    d.check(empty, "there are no rules yet, and the window says so");
    d.shot(&rules, "rules-1-list").await;
    click(&rules_widget, "rules-new");
    let Some(editor) = wait_dialog(10, "rule-dialog").await else {
        d.check(false, "New opens the rule editor");
        return;
    };
    let editor_widget = editor.clone().upcast::<gtk::Widget>();
    set_text(&editor_widget, "rule-name", "Newsletters");
    set_text(&editor_widget, "rule-query", "from:news@example.com");
    let archive = shell()
        .core
        .rule_targets()
        .unwrap_or_default()
        .iter()
        .position(|(_, _, label)| label.trim() == "Archive");
    if let (Some(index), Some(to)) = (
        archive,
        named_in(&editor_widget, "rule-move-to").and_downcast::<gtk::DropDown>(),
    ) {
        to.set_selected(index as u32);
    }
    let set = archive.is_some()
        && set_check(&editor_widget, "rule-move", true)
        && set_check(&editor_widget, "rule-mark-read", true);
    d.check(set, "Name, query, Move to Archive and Mark as read set");
    // the count follows once typing stops
    pause(800).await;
    let count = count_text(&editor_widget);
    d.check(
        count.contains("Inbox"),
        &format!("the editor says how many messages in the Inbox match now ({count})"),
    );
    d.shot(&editor, "rules-2-editor").await;
    click(&editor_widget, "dialog-ok");
    d.check(wait_gone(10, "rule-dialog").await, "OK saves the rule");
    d.check(
        wait_until(5, || rules_listed(&rules_widget) == 1).await,
        "A rule is added: the list has it",
    );
    rules.close();
    wait_gone(10, "rules-dialog").await;

    // new mail from the newsletter's sender: sorted into Archive, read
    let _ = d.add_message_to(
        "INBOX",
        &format!(
            "From: News <news@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: {WEEKLY}\r\n\
             Message-ID: <weekly-rules@example.com>\r\nDate: {}\r\n\r\nThis week's news.\r\n",
            date_now(0)
        ),
    );
    shell().sync_all();
    let moved = wait_for(40, || d.find("Archive", &format!("Subject: {WEEKLY}"))).await;
    d.check(
        moved.is_some() && d.find("INBOX", &format!("Subject: {WEEKLY}")).is_none(),
        "The newsletter lands in Archive, not the Inbox",
    );
    let main = shell().main();
    let sorted = wait_until(20, || main.status_texts().0.contains("sorted by your rules")).await;
    d.check(
        sorted,
        &format!("The status bar says it was sorted ({})", main.status_texts().0),
    );
    d.shot(&main_window(), "rules-5-applied").await;

    // a rule can not name a folder: refused with the reason, the editor stays
    if let Some(rules) = open_rules(d).await {
        let rules_widget = rules.clone().upcast::<gtk::Widget>();
        click(&rules_widget, "rules-new");
        if let Some(editor) = wait_dialog(10, "rule-dialog").await {
            let editor_widget = editor.clone().upcast::<gtk::Widget>();
            set_text(&editor_widget, "rule-query", "in:sent from:x");
            set_check(&editor_widget, "rule-flag", true);
            click(&editor_widget, "dialog-ok");
            let refused = wait_alert(10).await;
            let said = refused.as_ref().map(alert_text).unwrap_or_default();
            d.check(
                said.contains("in:"),
                &format!("The reason is shown: a query with in: is refused ({said})"),
            );
            if let Some(refused) = refused {
                d.shot(&refused, "rules-6-bad-query").await;
                answer(&refused, "OK");
            }
            pause(500).await;
            d.check(dialog_named("rule-dialog").is_some(), "the editor stays open");
            click(&editor_widget, "dialog-cancel");
            wait_gone(10, "rule-dialog").await;
        } else {
            d.check(false, "New opens the rule editor again");
        }
        d.check(rules_listed(&rules_widget) == 1, "nothing more is saved");
        rules.close();
        wait_gone(10, "rules-dialog").await;
    }

    // from a search
    super::search("lunch").await;
    wait_until(10, || main.search_summary().is_some()).await;
    click(&main_window(), "search-create-rule");
    match wait_dialog(10, "rule-dialog").await {
        Some(editor) => {
            let editor_widget = editor.clone().upcast::<gtk::Widget>();
            let query = text_of(&editor_widget, "rule-query");
            d.check(
                query == "lunch",
                &format!("The editor opens with the words of the search ({query})"),
            );
            d.shot(&editor, "rules-3-from-search").await;
            click(&editor_widget, "dialog-cancel");
            wait_gone(10, "rule-dialog").await;
        }
        None => d.check(false, "Create Rule on the search bar opens the rule editor"),
    }
    main.clear_find();
    wait_until(10, || main.search_summary().is_none()).await;

    // from a message
    select_folder("Inbox");
    wait_until(10, || rows() >= 1).await;
    select_row(0).await;
    command(Command::CreateRuleFromMessage);
    match wait_dialog(10, "rule-dialog").await {
        Some(editor) => {
            let editor_widget = editor.clone().upcast::<gtk::Widget>();
            let query = text_of(&editor_widget, "rule-query");
            d.check(
                query.starts_with("from:") || query.starts_with("list:"),
                &format!("The query starts with from: the sender, or list: its list ({query})"),
            );
            d.shot(&editor, "rules-4-from-message").await;
            click(&editor_widget, "dialog-cancel");
            wait_gone(10, "rule-dialog").await;
        }
        None => d.check(false, "Create Rule from Message opens the rule editor"),
    }

    // the rule deleted again
    if let Some(rules) = open_rules(d).await {
        let rules_widget = rules.clone().upcast::<gtk::Widget>();
        if let Some(list) = named_in(&rules_widget, "rules-list").and_downcast::<gtk::ListBox>() {
            list.select_row(list.row_at_index(0).as_ref());
        }
        click(&rules_widget, "rules-delete");
        if let Some(sure) = wait_alert(10).await {
            answer(&sure, "Yes");
        }
        d.check(
            wait_until(10, || rules_listed(&rules_widget) == 0).await
                && shell().core.rules().unwrap_or_default().is_empty(),
            "Delete takes the rule away",
        );
        rules.close();
        wait_gone(10, "rules-dialog").await;
    }
}
