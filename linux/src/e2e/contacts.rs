//! Step 39a of the UI test: the Address Book. A contact and a group made in its windows, Select Recipients behind the
//! To button of a message and a group completed by its name, Add Sender to Address Book, and a vCard file imported
//! and exported; checked in the core's book and in what the windows show.

use super::*;
use crate::address_book::{self, Book};

/// The people the book lists, as (name, e-mail address)
fn listed(book: &Book) -> Vec<(String, String)> {
    book.people()
        .iter()
        .map(|p| (p.name.clone(), p.address.clone()))
        .collect()
}

fn names(book: &Book) -> Vec<String> {
    listed(book).into_iter().map(|(name, _)| name).collect()
}

/// The words of the rows of a list of the picker
fn pick_rows(root: &gtk::Widget, list: &str) -> Vec<String> {
    let Some(list) = named_in(root, list).and_downcast::<gtk::ListBox>() else {
        return Vec::new();
    };
    let mut rows = Vec::new();
    let mut index = 0;
    while let Some(row) = list.row_at_index(index) {
        let words: Vec<String> = descendants::<gtk::Label>(row.upcast_ref())
            .iter()
            .map(|l| l.text().to_string())
            .collect();
        // descendants come last first
        rows.push(words.into_iter().rev().collect::<Vec<_>>().join(" "));
        index += 1;
    }
    rows
}

const VCARDS: &str = "BEGIN:VCARD\r\nVERSION:3.0\r\nFN:Mary Smith\r\nN:Smith;Mary;;;\r\nEMAIL:mary@example.com\r\n\
END:VCARD\r\nBEGIN:VCARD\r\nVERSION:3.0\r\nFN:John Doe\r\nN:Doe;John;;;\r\nEMAIL;TYPE=work:john@example.org\r\n\
TEL;TYPE=cell:+1 555 0100\r\nBDAY:1980-04-01\r\nEND:VCARD\r\n";

pub async fn address_book(d: &Driver) {
    d.step("the Address Book");
    command(Command::AddressBook);
    let Some(book) = wait_for(10, address_book::shown).await else {
        d.check(false, "Tools > Address Book opens the Address Book");
        return;
    };
    pause(600).await;
    let root: gtk::Widget = book.window.clone().upcast();
    d.check(
        book.people().is_empty()
            && book
                .empty_text()
                .is_some_and(|t| t.starts_with("The Address Book is empty")),
        &format!("Tools > Address Book opens it, empty ({:?})", book.empty_text()),
    );
    let buttons = [
        "book-new-contact",
        "book-new-group",
        "properties",
        "book-delete",
        "book-write-to",
    ];
    d.check(
        buttons.iter().all(|name| named_in(&root, name).is_some()),
        "with New Contact, New Group, Properties, Delete and Write To",
    );

    // a contact
    click(&root, "book-new-contact");
    let Some(form) = wait_dialog(10, "contact-dialog").await else {
        d.check(false, "New Contact opens Contact Properties");
        return;
    };
    d.check(form.title() == "New Contact", "New Contact opens Contact Properties");
    let f: gtk::Widget = form.clone().upcast();
    set_text(&f, "contact-first", "Mary");
    set_text(&f, "contact-last", "Smith");
    for address in ["mary@example.com", "mary.smith@work.example"] {
        set_text(&f, "contact-new-address", address);
        click(&f, "contact-add-address");
        pause(200).await;
    }
    set_text(&f, "contact-phone-0", "+1 555 0123");
    d.check(
        text_of(&f, "contact-display") == "Mary Smith",
        "the name shown follows the first and last name",
    );
    d.check(
        named_in(&f, "contact-address-1").is_some() && named_in(&f, "contact-default-1").is_some(),
        "two addresses, the first the default",
    );
    d.shot(&form, "contacts-2-person").await;
    click(&f, "dialog-ok");
    d.check(wait_gone(10, "contact-dialog").await, "OK saves the contact");
    let mary = [("Mary Smith".to_string(), "mary@example.com".to_string())];
    let shown = wait_until(5, || listed(&book) == mary).await;
    d.check(
        shown,
        &format!(
            "and the book lists it: Mary Smith, mary@example.com ({:?})",
            listed(&book)
        ),
    );
    let saved = shell().core.cards("mary").unwrap_or_default();
    d.check(
        saved.first().is_some_and(|c| {
            c.addresses == ["mary@example.com", "mary.smith@work.example"] && c.first == "Mary" && c.last == "Smith"
        }),
        "with both addresses, mary@example.com the default",
    );
    book.find.set_text("smi");
    pause(600).await;
    d.check(names(&book) == ["Mary Smith"], "the find box finds her by \"smi\"");
    book.find.set_text("zed");
    pause(600).await;
    d.check(
        book.people().is_empty() && book.empty_text().is_some_and(|t| t.contains("zed")),
        &format!("and lists no one for \"zed\" ({:?})", book.empty_text()),
    );
    book.find.set_text("");
    pause(400).await;

    // a group of her and an address typed
    click(&root, "book-new-group");
    let Some(form) = wait_dialog(10, "group-dialog").await else {
        d.check(false, "New Group opens Group Properties");
        return;
    };
    d.check(form.title() == "New Group", "New Group opens Group Properties");
    let g: gtk::Widget = form.clone().upcast();
    set_text(&g, "group-name", "Team");
    click(&g, "group-select-members");
    match wait_dialog(10, "pick-dialog").await {
        Some(pick) => {
            let p: gtk::Widget = pick.clone().upcast();
            pause(300).await;
            d.check(
                pick_rows(&p, "pick-list").len() == 1 && pick.title() == "Select Group Members",
                &format!(
                    "Select Members lists the people of the book ({:?})",
                    pick_rows(&p, "pick-list")
                ),
            );
            if let Some(list) = named_in(&p, "pick-list").and_downcast::<gtk::ListBox>() {
                list.select_row(list.row_at_index(0).as_ref());
            }
            click(&p, "pick-add");
            pause(200).await;
            click(&p, "dialog-ok");
            wait_gone(10, "pick-dialog").await;
        }
        None => d.check(false, "Select Members opens Select Group Members"),
    }
    set_text(&g, "group-new-member", "dave@example.com");
    click(&g, "group-add-member");
    pause(300).await;
    d.check(
        named_in(&g, "group-member-0").is_some() && named_in(&g, "group-member-1").is_some(),
        "Mary Smith from Select Members and dave@example.com typed are its members",
    );
    d.shot(&form, "contacts-3-group").await;
    click(&g, "dialog-ok");
    d.check(wait_gone(10, "group-dialog").await, "OK saves the group");
    let groups = shell().core.groups("").unwrap_or_default();
    let team = groups.iter().find(|g| g.name == "Team");
    d.check(
        team.is_some_and(|t| {
            t.members.len() == 2
                && t.members[0].card.is_some()
                && t.members[0].address == "mary@example.com"
                && t.members[1].address == "dave@example.com"
        }),
        "with its two members, the contact and the address",
    );
    let row = team.map(|t| format!("book-group-{}", t.id)).unwrap_or_default();
    d.check(named_in(&root, &row).is_some(), "and it is listed on the left");
    d.check(
        book.selected_group() == team.map(|t| t.id) && listed(&book).len() == 2,
        &format!("selected, with its members on the right ({:?})", listed(&book)),
    );
    pause(300).await;
    d.shot(&book.window, "contacts-1-book").await;
    book.select_group_row(0);
    pause(300).await;

    // Select Recipients behind To
    run_command(Command::NewMail);
    let Some(c) = wait_compose(10).await else { return };
    let w: gtk::Widget = c.window.clone().upcast();
    click(&w, "compose-pick-to");
    match wait_dialog(10, "pick-dialog").await {
        Some(pick) => {
            let p: gtk::Widget = pick.clone().upcast();
            pause(300).await;
            let rows = pick_rows(&p, "pick-list");
            d.check(
                rows.len() == 2 && rows[0].starts_with("Team") && rows[1].starts_with("Mary Smith"),
                &format!("To opens Select Recipients with the group and the contact ({rows:?})"),
            );
            if let Some(list) = named_in(&p, "pick-list").and_downcast::<gtk::ListBox>() {
                list.select_all();
            }
            click(&p, "pick-to");
            pause(300).await;
            d.check(
                pick_rows(&p, "pick-to-list").len() == 2,
                "To -> puts them in the message's recipients",
            );
            d.shot(&pick, "contacts-4-pick").await;
            click(&p, "dialog-ok");
            wait_gone(10, "pick-dialog").await;
        }
        None => d.check(false, "To opens Select Recipients"),
    }
    d.check(
        c.to.text() == "Mary Smith <mary@example.com>, dave@example.com",
        &format!("OK puts them in To, each address once ({})", c.to.text()),
    );
    // a group completes by its name
    click(&w, "compose-show-cc");
    c.cc.grab_focus();
    type_letters(&c.cc, "tea");
    let offered = wait_for(10, || crate::complete::shown_rows(&c.cc).filter(|r| !r.is_empty())).await;
    let team_row = offered.as_ref().and_then(|rows| rows.iter().position(|r| r == "Team"));
    d.check(
        team_row.is_some(),
        &format!("typing \"tea\" in Cc offers the group by its name ({offered:?})"),
    );
    if let Some(row) = descendants::<gtk::ListBox>(c.cc.upcast_ref())
        .first()
        .and_then(|l| l.row_at_index(team_row.unwrap_or(0) as i32))
    {
        row.activate();
    }
    d.check(
        wait_until(5, || c.cc.text() == "Mary Smith <mary@example.com>, dave@example.com, ").await,
        &format!("taking it puts its members in Cc ({})", c.cc.text()),
    );
    close_compose(&c).await;

    // Add Sender to Address Book
    let main = shell().main();
    search(NEWSLETTER).await;
    wait_until(20, || rows() == 1).await;
    select_row(0).await;
    let list_view: gtk::Widget = main.list.view.clone().upcast();
    main.message_menu(&list_view, 60.0, 60.0);
    let labels = menu_labels(main.message_popover.borrow().as_ref());
    if let Some(popover) = main.message_popover.borrow().as_ref() {
        popover.popdown();
    }
    d.check(
        labels.iter().any(|l| l == "Add Sender to Address Book"),
        "the message list's right-click menu has Add Sender to Address Book",
    );
    run_command(Command::AddSenderToBook);
    pause(400).await;
    let status = main.status_texts().0;
    d.check(
        status == "Trail Notes was added to the Address Book.",
        &format!("Add Sender adds Trail Notes ({status})"),
    );
    let senders = |core: &pe_core::Core| {
        core.cards("news@example.com")
            .unwrap_or_default()
            .iter()
            .filter(|c| c.addresses.iter().any(|a| a == "news@example.com"))
            .count()
    };
    d.check(senders(&shell().core) == 1, "with the address news@example.com");
    run_command(Command::AddSenderToBook);
    pause(400).await;
    let status = main.status_texts().0;
    d.check(
        status == "Trail Notes is already in the Address Book." && senders(&shell().core) == 1,
        &format!("and again says the sender is in the Address Book already, without a second card ({status})"),
    );
    main.clear_find();

    // a vCard file in
    let file = d.out.join("contacts.vcf");
    let _ = std::fs::write(&file, VCARDS);
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![file]));
    book.window.present();
    let _ = WidgetExt::activate_action(&book.window, "win.import-address-book", None);
    match wait_alert(10).await {
        Some(said) => {
            let text = alert_text(&said);
            d.check(
                text.contains("Added 1 contact, skipped 1 already in the Address Book."),
                &format!("Import Address Book adds 1 and skips 1 ({text})"),
            );
            let names = names(&book);
            d.check(
                names == ["John Doe", "Mary Smith", "Trail Notes"],
                &format!("and the book lists John Doe beside Mary Smith and Trail Notes ({names:?})"),
            );
            d.shot(&book.window, "contacts-5-import").await;
            answer(&said, "OK");
            wait_until(5, || !said.is_mapped()).await;
        }
        None => d.check(false, "Import Address Book says what it did"),
    }
    let john = shell().core.cards("john").unwrap_or_default();
    d.check(
        john.first().is_some_and(|c| c.extra.contains("BDAY")),
        "what the form does not show is kept (the birthday)",
    );
    // and out
    let exported = d.out.join("exported.vcf");
    let _ = std::fs::remove_file(&exported);
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![exported.clone()]));
    let _ = WidgetExt::activate_action(&book.window, "win.export-address-book", None);
    match wait_alert(10).await {
        Some(said) => {
            let text = alert_text(&said);
            d.check(
                text.contains("3 contacts saved to exported.vcf."),
                &format!("Export Address Book writes a vCard file ({text})"),
            );
            answer(&said, "OK");
            wait_until(5, || !said.is_mapped()).await;
        }
        None => d.check(false, "Export Address Book says what it did"),
    }
    let written = std::fs::read_to_string(&exported).unwrap_or_default();
    d.check(
        ["FN:Mary Smith", "FN:John Doe", "news@example.com"]
            .iter()
            .all(|w| written.contains(w)),
        "with Mary Smith, John Doe and Trail Notes in it",
    );

    // Delete asks first
    if let Some(index) = names(&book).iter().position(|n| n == "John Doe") {
        book.select_person(index as u32);
    }
    pause(200).await;
    click(&root, "book-delete");
    match wait_alert(10).await {
        Some(ask) => {
            let text = alert_text(&ask);
            d.check(
                text.contains("Delete this contact from the Address Book?"),
                &format!("Delete asks first ({text})"),
            );
            answer(&ask, "Yes");
            wait_until(5, || !ask.is_mapped()).await;
            let gone = wait_until(5, || names(&book) == ["Mary Smith", "Trail Notes"]).await;
            d.check(gone, &format!("then removes the contact ({:?})", names(&book)));
        }
        None => d.check(false, "Delete asks first"),
    }
    book.window.close();
    wait_until(5, || address_book::shown().is_none()).await;
}
