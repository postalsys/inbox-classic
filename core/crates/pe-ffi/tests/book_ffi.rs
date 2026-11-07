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
    let list = unsafe { pe_groups(core) };
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
    assert!(unsafe { pe_book_import(core, vcf.as_ptr(), &mut added, &mut skipped, &mut error) });
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
    assert!(!unsafe { pe_book_import(core, missing.as_ptr(), null_mut(), null_mut(), &mut error) });
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
    assert!(unsafe { pe_cards_delete(core, [mary, john].as_ptr(), 2) });
    assert!(card_rows(core, "").is_empty());
    let view = unsafe { pe_group(core, team_id) };
    assert_eq!(unsafe { &*pe_group_info(view) }.member_count, 1);
    unsafe { pe_group_free(view) };
    assert!(unsafe { pe_group_delete(core, team_id) });
    let list = unsafe { pe_groups(core) };
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
        assert!(!pe_cards_delete(null(), null(), 0));
        assert!(pe_groups(null()).is_null());
        assert_eq!(pe_group_list_count(null()), 0);
        assert!(pe_group_list_get(null(), 0).is_null());
        pe_group_list_free(null_mut());
        assert!(pe_group(null(), 1).is_null());
        assert!(pe_group_info(null()).is_null());
        pe_group_free(null_mut());
        assert_eq!(pe_group_save(null(), null(), null_mut()), 0);
        assert!(!pe_group_delete(null(), 1));
        let mut added = true;
        assert_eq!(pe_book_add_sender(null(), 1, 1, &mut added), 0);
        assert!(!added);
        assert!(!pe_book_import(null(), null(), null_mut(), null_mut(), null_mut()));
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
