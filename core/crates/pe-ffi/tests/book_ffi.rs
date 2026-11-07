//! The address book through the C API, as the windows call it: cards and groups saved, listed, read back and deleted,
//! the completion that offers them first, and vCard files read in and written out. No server is needed.

use std::ffi::{CStr, CString, c_char};
use std::ptr::{null, null_mut};

use pe_ffi::*;
use pe_testkit::TempDir;

fn text(pointer: *const c_char) -> String {
    assert!(!pointer.is_null());
    unsafe { CStr::from_ptr(pointer) }.to_str().unwrap().to_owned()
}

fn taken(pointer: *mut c_char) -> String {
    let found = text(pointer);
    unsafe { pe_string_free(pointer) };
    found
}

fn c(s: &str) -> CString {
    CString::new(s).unwrap()
}

/// The (name, address, phone, label) of the rows of `pe_cards` for `filter`
fn card_rows(core: *const PeCore, filter: &str) -> Vec<(i64, String, String, String, String)> {
    let filter = c(filter);
    let list = unsafe { pe_cards(core, filter.as_ptr()) };
    assert!(!list.is_null());
    let rows = (0..unsafe { pe_card_list_count(list) })
        .map(|i| {
            let row = unsafe { &*pe_card_list_get(list, i) };
            (
                row.id,
                text(row.name),
                text(row.address),
                text(row.phone),
                text(row.label),
            )
        })
        .collect();
    assert!(unsafe { pe_card_list_get(list, 99) }.is_null());
    unsafe { pe_card_list_free(list) };
    rows
}

fn completions(core: *const PeCore, typed: &str) -> Vec<(String, String, bool)> {
    let typed = c(typed);
    let list = unsafe { pe_contacts(core, typed.as_ptr(), 10) };
    assert!(!list.is_null());
    let found = (0..unsafe { pe_contact_list_count(list) })
        .map(|i| {
            let row = unsafe { &*pe_contact_list_get(list, i) };
            (text(row.name), text(row.label), row.group)
        })
        .collect();
    unsafe { pe_contact_list_free(list) };
    found
}

#[test]
fn the_address_book_through_the_c_api() {
    let dir = TempDir::new("ffi-book");
    let path = c(dir.path().join("store.db").to_str().unwrap());
    let core = unsafe { pe_core_open_with(path.as_ptr(), PE_OPEN_MEMORY_PASSWORDS, null(), None, null_mut()) };
    assert!(!core.is_null());

    // a new contact with two addresses, the default first, and a phone
    let (first, last, company) = (c("Mary"), c("Smith"), c("Acme, Inc."));
    let addresses = [c("mary@example.com"), c("mary.smith@work.example")];
    let address_ptrs: Vec<*const c_char> = addresses.iter().map(|a| a.as_ptr()).collect();
    let number = c("+1 555 0100");
    let phones = [PePhone {
        kind: PePhoneKind::Mobile,
        number: number.as_ptr(),
    }];
    let mut card = PeCard {
        id: 0,
        name: null(),
        first: first.as_ptr(),
        last: last.as_ptr(),
        nickname: null(),
        company: company.as_ptr(),
        notes: null(),
        addresses: address_ptrs.as_ptr(),
        address_count: address_ptrs.len(),
        phones: phones.as_ptr(),
        phone_count: phones.len(),
    };
    let mut error: *mut c_char = null_mut();
    let mary = unsafe { pe_card_save(core, &card, &mut error) };
    assert!(mary > 0 && error.is_null());

    // the book lists it, its name made of first and last
    assert_eq!(
        card_rows(core, ""),
        [(
            mary,
            "Mary Smith".to_string(),
            "mary@example.com".to_string(),
            "+1 555 0100".to_string(),
            "Mary Smith <mary@example.com>".to_string()
        )]
    );
    assert_eq!(card_rows(core, "acme").len(), 1);
    assert_eq!(card_rows(core, "mary.smith@").len(), 1);
    assert!(card_rows(core, "zed").is_empty());

    // read back with every field
    let view = unsafe { pe_card(core, mary) };
    let info = unsafe { &*pe_card_info(view) };
    assert_eq!(
        (text(info.name), text(info.first), text(info.last), text(info.company)),
        ("Mary Smith".into(), "Mary".into(), "Smith".into(), "Acme, Inc.".into())
    );
    let read: Vec<String> = unsafe { std::slice::from_raw_parts(info.addresses, info.address_count) }
        .iter()
        .map(|a| text(*a))
        .collect();
    assert_eq!(read, ["mary@example.com", "mary.smith@work.example"]);
    let phone = unsafe { &*info.phones };
    assert_eq!(
        (info.phone_count, phone.kind, text(phone.number)),
        (1, PePhoneKind::Mobile, "+1 555 0100".into())
    );
    unsafe { pe_card_free(view) };
    assert!(unsafe { pe_card(core, 999_999) }.is_null());

    // saved again with the other address as the default; one that is not a mailbox alone is left out
    let swapped = [
        c("mary.smith@work.example"),
        c("mary@example.com"),
        c("boss@corp.example>, x@evil.example"),
    ];
    let swapped_ptrs: Vec<*const c_char> = swapped.iter().map(|a| a.as_ptr()).collect();
    card.id = mary;
    card.addresses = swapped_ptrs.as_ptr();
    card.address_count = swapped_ptrs.len();
    card.phones = null();
    card.phone_count = 0;
    assert_eq!(unsafe { pe_card_save(core, &card, null_mut()) }, mary);
    let rows = card_rows(core, "");
    assert_eq!(
        (rows[0].2.as_str(), rows[0].3.as_str()),
        ("mary.smith@work.example", "")
    );
    let view = unsafe { pe_card(core, mary) };
    assert_eq!(unsafe { &*pe_card_info(view) }.address_count, 2);
    unsafe { pe_card_free(view) };
    // a card that is not there is not made again
    card.id = 999_999;
    assert_eq!(unsafe { pe_card_save(core, &card, &mut error) }, 0);
    assert!(!taken(error).is_empty());
    error = null_mut();

    // a group of that contact and a typed address
    let (team, dave, dave_name) = (c("Team"), c("dave@example.com"), c("Dave"));
    let members = [
        PeMember {
            card: mary,
            name: null(),
            address: null(),
            label: null(),
        },
        PeMember {
            card: 0,
            name: dave_name.as_ptr(),
            address: dave.as_ptr(),
            label: null(),
        },
    ];
    let group = PeGroup {
        id: 0,
        name: team.as_ptr(),
        members: members.as_ptr(),
        member_count: members.len(),
    };
    let team_id = unsafe { pe_group_save(core, &group, &mut error) };
    assert!(team_id > 0 && error.is_null());
    let list = unsafe { pe_groups(core, null()) };
    assert_eq!(unsafe { pe_group_list_count(list) }, 1);
    let row = unsafe { &*pe_group_list_get(list, 0) };
    assert_eq!(
        (row.id, text(row.name), row.member_count, text(row.label)),
        (
            team_id,
            "Team".into(),
            2,
            "Mary Smith <mary.smith@work.example>, Dave <dave@example.com>".into()
        )
    );
    unsafe { pe_group_list_free(list) };
    let view = unsafe { pe_group(core, team_id) };
    let info = unsafe { &*pe_group_info(view) };
    let read: Vec<(i64, String, String)> = unsafe { std::slice::from_raw_parts(info.members, info.member_count) }
        .iter()
        .map(|m| (m.card, text(m.name), text(m.label)))
        .collect();
    assert_eq!(
        read,
        [
            (mary, "Mary Smith".into(), "Mary Smith <mary.smith@work.example>".into()),
            (0, "Dave".into(), "Dave <dave@example.com>".into())
        ]
    );
    assert_eq!(text(info.name), "Team");
    unsafe { pe_group_free(view) };

    // completion: the book first, a group by its name with its members
    let found = completions(core, "te");
    assert_eq!(
        found,
        [(
            "Team".to_string(),
            "Mary Smith <mary.smith@work.example>, Dave <dave@example.com>".to_string(),
            true
        )]
    );
    let found = completions(core, "mary");
    assert!(found.iter().all(|f| !f.2) && found.len() == 2, "{found:?}");

    // Select Recipients and Write To add to a field, each address once
    let field = c("dave@example.com");
    let added = c("Mary Smith <mary.smith@work.example>, Dave <dave@example.com>");
    assert_eq!(
        taken(unsafe { pe_address_field_add(field.as_ptr(), added.as_ptr()) }),
        "dave@example.com, Mary Smith <mary.smith@work.example>"
    );

    // a vCard file of two contacts, one already in the book
    let vcf = dir.path().join("two.vcf");
    std::fs::write(
        &vcf,
        "BEGIN:VCARD\r\nVERSION:3.0\r\nFN:Mary Smith\r\nEMAIL:mary@example.com\r\nEND:VCARD\r\n\
         BEGIN:VCARD\r\nVERSION:3.0\r\nFN:John Doe\r\nEMAIL:john@example.org\r\nBDAY:1990-01-02\r\nEND:VCARD\r\n",
    )
    .unwrap();
    let vcf = c(vcf.to_str().unwrap());
    let (mut added, mut skipped) = (0u64, 0u64);
    assert!(unsafe { pe_book_import(core, &vcf.as_ptr(), 1, &mut added, &mut skipped, &mut error) });
    assert_eq!((added, skipped), (1, 1));
    // as the windows say it
    pe_i18n::set_language("en");
    assert_eq!(
        pe_i18n::tr_args(
            pe_i18n::Text::UiBookImported,
            &[("added", added.into()), ("skipped", skipped.into())]
        ),
        "Added 1 contact, skipped 1 already in the Address Book."
    );
    let missing = c(dir.path().join("missing.vcf").to_str().unwrap());
    assert!(!unsafe { pe_book_import(core, &missing.as_ptr(), 1, null_mut(), null_mut(), &mut error) });
    assert!(!taken(error).is_empty());
    error = null_mut();

    // what a vCard brought that the form does not show stays when the form saves the card
    let john = card_rows(core, "john")[0].0;
    let view = unsafe { pe_card(core, john) };
    let mut info = unsafe { std::ptr::read(pe_card_info(view)) };
    let changed = c("Johnny");
    info.nickname = changed.as_ptr();
    assert_eq!(unsafe { pe_card_save(core, &info, null_mut()) }, john);
    unsafe { pe_card_free(view) };

    // written out: everyone, or the ones chosen
    let out = dir.path().join("out.vcf");
    let out_path = c(out.to_str().unwrap());
    let mut written = 0u64;
    assert!(unsafe { pe_book_export(core, null(), 0, out_path.as_ptr(), &mut written, &mut error) });
    assert_eq!(written, 2);
    let file = std::fs::read_to_string(&out).unwrap();
    assert!(
        file.contains("FN:John Doe") && file.contains("NICKNAME:Johnny") && file.contains("BDAY:1990-01-02"),
        "{file}"
    );
    assert!(file.contains("FN:Mary Smith"), "{file}");
    assert!(unsafe { pe_book_export(core, &john, 1, out_path.as_ptr(), &mut written, null_mut()) });
    assert_eq!(written, 1);

    // deleted: out of the groups too; the group goes with its own Delete
    assert!(unsafe { pe_book_delete(core, 0, [mary, john].as_ptr(), 2, null(), 0) });
    assert!(card_rows(core, "").is_empty());
    let view = unsafe { pe_group(core, team_id) };
    assert_eq!(unsafe { &*pe_group_info(view) }.member_count, 1);
    unsafe { pe_group_free(view) };
    assert!(unsafe { pe_group_delete(core, team_id) });
    let list = unsafe { pe_groups(core, null()) };
    assert_eq!(unsafe { pe_group_list_count(list) }, 0);
    unsafe { pe_group_list_free(list) };

    unsafe { pe_core_close(core) };
}

#[test]
fn null_and_bad_arguments_of_the_book() {
    unsafe {
        assert!(pe_cards(null(), null()).is_null());
        assert_eq!(pe_card_list_count(null()), 0);
        assert!(pe_card_list_get(null(), 0).is_null());
        pe_card_list_free(null_mut());
        assert!(pe_card(null(), 1).is_null());
        assert!(pe_card_info(null()).is_null());
        pe_card_free(null_mut());
        let mut error: *mut c_char = null_mut();
        assert_eq!(pe_card_save(null(), null(), &mut error), 0);
        pe_string_free(error);
        assert!(!pe_book_delete(null(), 0, null(), 0, null(), 0));
        assert!(pe_groups(null(), null()).is_null());
        assert!(pe_group_people(null(), 1, null()).is_null());
        assert_eq!(pe_group_list_count(null()), 0);
        assert!(pe_group_list_get(null(), 0).is_null());
        pe_group_list_free(null_mut());
        assert!(pe_group(null(), 1).is_null());
        assert!(pe_group_info(null()).is_null());
        pe_group_free(null_mut());
        assert_eq!(pe_group_save(null(), null(), null_mut()), 0);
        assert!(!pe_group_delete(null(), 1));
        let mut added = true;
        let mut status: *mut c_char = null_mut();
        assert_eq!(pe_book_add_sender(null(), 1, 1, &mut added, &mut status), 0);
        assert!(!added);
        assert_eq!(CStr::from_ptr(status).to_str().unwrap(), "");
        pe_string_free(status);
        assert!(!pe_book_import(null(), null(), 0, null_mut(), null_mut(), null_mut()));
        assert_eq!(pe_book_members_add(null(), 0, null(), 3, null_mut()), 0);
        let name = pe_book_display_name(null(), null());
        assert_eq!(CStr::from_ptr(name).to_str().unwrap(), "");
        pe_string_free(name);
        assert!(!pe_book_export(null(), null(), 0, null(), null_mut(), null_mut()));
        let field = pe_address_field_add(null(), null());
        assert_eq!(CStr::from_ptr(field).to_str().unwrap(), "");
        pe_string_free(field);
    }
}

#[test]
fn an_address_is_checked_as_one_mailbox() {
    // SAFETY: NUL-terminated strings, or NULL
    unsafe {
        assert!(pe_address_is_mailbox(c("mary@example.com").as_ptr()));
        assert!(!pe_address_is_mailbox(
            c("boss@corp.example>, attacker@evil.example").as_ptr()
        ));
        assert!(!pe_address_is_mailbox(c("not an address").as_ptr()));
        assert!(!pe_address_is_mailbox(null()));
    }
}

/// The rows of a card list, (id, name, address, phone, company, label), freed
fn rows_of(list: *mut PeCardList) -> Vec<(i64, String, String, String, String, String)> {
    assert!(!list.is_null());
    let rows = (0..unsafe { pe_card_list_count(list) })
        .map(|i| {
            let row = unsafe { &*pe_card_list_get(list, i) };
            (
                row.id,
                text(row.name),
                text(row.address),
                text(row.phone),
                text(row.company),
                text(row.label),
            )
        })
        .collect();
    unsafe { pe_card_list_free(list) };
    rows
}

fn group_names(core: *const PeCore, filter: &str) -> Vec<String> {
    let filter = c(filter);
    let list = unsafe { pe_groups(core, filter.as_ptr()) };
    let names = (0..unsafe { pe_group_list_count(list) })
        .map(|i| text(unsafe { &*pe_group_list_get(list, i) }.name))
        .collect();
    unsafe { pe_group_list_free(list) };
    names
}

/// A contact of only an address, or of nothing
fn save(core: *const PeCore, first: &str, address: Option<&str>, error: &mut *mut c_char) -> i64 {
    let first = c(first);
    let address = address.map(c);
    let addresses: Vec<*const c_char> = address.iter().map(|a| a.as_ptr()).collect();
    let card = PeCard {
        id: 0,
        name: null(),
        first: first.as_ptr(),
        last: null(),
        nickname: null(),
        company: null(),
        notes: null(),
        addresses: addresses.as_ptr(),
        address_count: addresses.len(),
        phones: null(),
        phone_count: 0,
    };
    unsafe { pe_card_save(core, &card, error) }
}

#[test]
fn the_book_decides_what_the_windows_show() {
    pe_i18n::set_language("en");
    let dir = TempDir::new("ffi-book-rules");
    let path = c(dir.path().join("store.db").to_str().unwrap());
    let core = unsafe { pe_core_open_with(path.as_ptr(), PE_OPEN_MEMORY_PASSWORDS, null(), None, null_mut()) };
    assert!(!core.is_null());

    // the display name follows first and last
    let (first, last) = (c(" Mary "), c("Smith"));
    assert_eq!(
        taken(unsafe { pe_book_display_name(first.as_ptr(), last.as_ptr()) }),
        "Mary Smith"
    );
    assert_eq!(taken(unsafe { pe_book_display_name(null(), last.as_ptr()) }), "Smith");

    // a contact of only an address is known by it; one of nothing is refused, in words
    let mut error: *mut c_char = null_mut();
    let ann = save(core, "", Some("ann@example.com"), &mut error);
    assert!(ann > 0 && error.is_null());
    assert_eq!(
        rows_of(unsafe { pe_cards(core, null()) }),
        [(
            ann,
            "ann@example.com".to_string(),
            "ann@example.com".to_string(),
            String::new(),
            String::new(),
            "ann@example.com".to_string()
        )]
    );
    assert_eq!(save(core, "", None, &mut error), 0);
    assert_eq!(taken(error), "The contact has no name and no e-mail address.");
    error = null_mut();
    // a name without an address is a contact
    let bob = save(core, "Bob", None, &mut error);
    assert!(bob > 0 && error.is_null());

    // a group with a card, the card's address typed again, and an address typed twice: each once
    let (team, typed, again, card_again) = (
        c("Sales Team"),
        c("dave@example.org"),
        c("DAVE@example.org"),
        c("Ann@Example.com"),
    );
    let member = |card: i64, address: *const c_char| PeMember {
        card,
        name: null(),
        address,
        label: null(),
    };
    let members = [
        member(ann, null()),
        member(0, card_again.as_ptr()),
        member(0, typed.as_ptr()),
        member(0, again.as_ptr()),
        member(bob, null()),
        member(bob, null()),
    ];
    let group = PeGroup {
        id: 0,
        name: team.as_ptr(),
        members: members.as_ptr(),
        member_count: members.len(),
    };
    let team_id = unsafe { pe_group_save(core, &group, &mut error) };
    assert!(team_id > 0 && error.is_null());
    let (family, empty) = (
        c("Family"),
        PeGroup {
            id: 0,
            name: null(),
            members: null(),
            member_count: 0,
        },
    );
    let family_id = unsafe {
        pe_group_save(
            core,
            &PeGroup {
                name: family.as_ptr(),
                ..empty
            },
            null_mut(),
        )
    };
    assert!(family_id > 0);

    // groups found as people are: a word of the name
    assert_eq!(group_names(core, ""), ["Family", "Sales Team"]);
    assert_eq!(group_names(core, "team"), ["Sales Team"]);
    assert!(group_names(core, "x").is_empty());

    // a group's people as rows: the cards as they are, the typed address with id 0
    let people = rows_of(unsafe { pe_group_people(core, team_id, null()) });
    assert_eq!(
        people
            .iter()
            .map(|r| (r.0, r.1.as_str(), r.5.as_str()))
            .collect::<Vec<_>>(),
        [
            (ann, "ann@example.com", "ann@example.com"),
            (0, "dave@example.org", "dave@example.org"),
            (bob, "Bob", "")
        ]
    );
    let dav = c("dav");
    assert_eq!(
        rows_of(unsafe { pe_group_people(core, team_id, dav.as_ptr()) }).len(),
        1
    );
    assert!(unsafe { pe_group_people(core, 999_999, null()) }.is_null());

    // Group Properties adds those not in the list yet, a card's address counting as it
    let list = [member(ann, c("ann@example.com").into_raw())];
    let dave = c("dave@example.org");
    let added = [
        member(ann, null()),
        member(0, card_again.as_ptr()),
        member(0, dave.as_ptr()),
        member(0, again.as_ptr()),
        member(bob, null()),
    ];
    let mut keep = [true; 5];
    assert_eq!(
        unsafe {
            pe_book_members_add(
                list.as_ptr(),
                list.len(),
                added.as_ptr(),
                added.len(),
                keep.as_mut_ptr(),
            )
        },
        2
    );
    assert_eq!(keep, [false, false, true, false, true]);
    drop(unsafe { CString::from_raw(list[0].address as *mut c_char) });

    // Delete in a group: the card out of the book, the typed address out of the group
    let addresses = [again.as_ptr()];
    assert!(unsafe { pe_book_delete(core, team_id, &bob, 1, addresses.as_ptr(), 1) });
    let people = rows_of(unsafe { pe_group_people(core, team_id, null()) });
    assert_eq!(people.iter().map(|r| r.0).collect::<Vec<_>>(), [ann]);
    assert!(rows_of(unsafe { pe_cards(core, null()) }).iter().all(|r| r.0 != bob));

    // several files read in at once; the one that can not be read is named, the others read all the same
    let one = dir.path().join("one.vcf");
    std::fs::write(
        &one,
        "BEGIN:VCARD\r\nVERSION:3.0\r\nFN:Zoe\r\nEMAIL:zoe@example.com\r\nEND:VCARD\r\n",
    )
    .unwrap();
    let two = dir.path().join("two.csv");
    std::fs::write(
        &two,
        "Name,E-mail Address\nYann,yann@example.com\nAnn,ann@example.com\n",
    )
    .unwrap();
    let paths = [
        c(one.to_str().unwrap()),
        c(dir.path().join("gone.vcf").to_str().unwrap()),
        c(two.to_str().unwrap()),
    ];
    let pointers: Vec<*const c_char> = paths.iter().map(|p| p.as_ptr()).collect();
    let (mut added, mut skipped) = (0u64, 0u64);
    assert!(!unsafe {
        pe_book_import(
            core,
            pointers.as_ptr(),
            pointers.len(),
            &mut added,
            &mut skipped,
            &mut error,
        )
    });
    assert_eq!((added, skipped), (2, 1));
    let said = taken(error);
    assert!(said.starts_with("gone.vcf: ") && !said.contains('\n'), "{said}");

    unsafe { pe_core_close(core) };
}
