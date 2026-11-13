//! The address book through C: its people (cards) and groups as lists of rows, one card or group with all its fields
//! for Properties, saving and deleting them, a message's sender added, and vCard and CSV files read in and written
//! out. The completion of address fields is `pe_contacts` (in `core.rs`).

use std::ffi::c_char;
use std::ptr::{null, null_mut};

use pe_core::book::BookRow;
use pe_store::{Card, Group, Member};

use crate::core::{PeCore, Rows, Strings, arg, handed, refused, take_back, with};
use crate::{guard, into_c_string};

/// What a phone number is
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PePhoneKind {
    Other = 0,
    Home = 1,
    Work = 2,
    Mobile = 3,
}

impl PePhoneKind {
    fn of(kind: &str) -> Self {
        match kind {
            "home" => PePhoneKind::Home,
            "work" => PePhoneKind::Work,
            "cell" => PePhoneKind::Mobile,
            _ => PePhoneKind::Other,
        }
    }

    fn name(self) -> &'static str {
        match self {
            PePhoneKind::Home => "home",
            PePhoneKind::Work => "work",
            PePhoneKind::Mobile => "cell",
            PePhoneKind::Other => "",
        }
    }
}

/// A person of the address book as its list shows them
#[repr(C)]
pub struct PeCardRow {
    /// The card; 0 for an address typed into a group (`pe_group_people`), which has no Properties and which Delete
    /// takes out of the group by its `address` (`pe_book_delete`)
    pub id: i64,
    /// The name shown (Name column): the name, or the address of someone without one
    pub name: *const c_char,
    /// The default address (E-mail column), empty for none
    pub address: *const c_char,
    /// The first phone number (Phone column), empty for none
    pub phone: *const c_char,
    pub company: *const c_char,
    /// As it goes in an address field (`Name <address>`, the name quoted where it needs it), empty without an address:
    /// what Write To and Select Recipients put in To, Cc or Bcc
    pub label: *const c_char,
}

/// The people of the address book; free with `pe_card_list_free`
pub struct PeCardList(Rows<PeCardRow>);

fn card_list(rows: &[BookRow]) -> *mut PeCardList {
    handed(PeCardList(Rows::new(rows, |row, strings| PeCardRow {
        id: row.card,
        name: strings.add(&row.name),
        address: strings.add(&row.address),
        phone: strings.add(&row.phone),
        company: strings.add(&row.company),
        label: strings.add(&row.label),
    })))
}

/// The filter argument of the book's lists: NULL, empty or not UTF-8 for everything
///
/// # Safety
/// `filter` must be NULL or a NUL-terminated string.
unsafe fn filter_of(filter: *const c_char) -> String {
    // SAFETY: as the caller guarantees
    unsafe { arg(filter) }.unwrap_or_default().to_string()
}

/// The people of the address book, by name; with `filter` (NULL or empty for everyone), those whose name (a word of
/// it), nickname, company or an address starts with it. NULL on failure.
///
/// # Safety
/// `core` must be a live handle, `filter` NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_cards(core: *const PeCore, filter: *const c_char) -> *mut PeCardList {
    // SAFETY: as the caller guarantees
    let filter = unsafe { filter_of(filter) };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| match core.card_rows(&filter) {
            Ok(rows) => card_list(&rows),
            Err(_) => null_mut(),
        })
    }
}

/// The people of group `id` in their order, as `pe_cards` lists the book's: a card's row as its card is now, an
/// address typed into the group with `id` 0; with `filter` (NULL or empty for all), those found by it as `pe_cards`
/// finds people. NULL when there is no such group or on failure. Free with `pe_card_list_free`.
///
/// # Safety
/// `core` must be a live handle, `filter` NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_group_people(core: *const PeCore, id: i64, filter: *const c_char) -> *mut PeCardList {
    // SAFETY: as the caller guarantees
    let filter = unsafe { filter_of(filter) };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| match core.group_people(id, &filter) {
            Ok(rows) => card_list(&rows),
            Err(_) => null_mut(),
        })
    }
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_card_list_count(list: *const PeCardList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// Row `index`, NULL past the end
///
/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_card_list_get(list: *const PeCardList, index: usize) -> *const PeCardRow {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_card_list_free(list: *mut PeCardList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// A phone number of a card
#[repr(C)]
pub struct PePhone {
    pub kind: PePhoneKind,
    pub number: *const c_char,
}

/// A person with every field Contact Properties edits. From `pe_card`, its strings and arrays belong to the handle;
/// to `pe_card_save`, to the caller.
#[repr(C)]
pub struct PeCard {
    /// 0 for a new one
    pub id: i64,
    /// The name shown and written to; empty when saved, it is made of `first` and `last`
    pub name: *const c_char,
    pub first: *const c_char,
    pub last: *const c_char,
    pub nickname: *const c_char,
    pub company: *const c_char,
    pub notes: *const c_char,
    /// The addresses, the default one first
    pub addresses: *const *const c_char,
    pub address_count: usize,
    pub phones: *const PePhone,
    pub phone_count: usize,
}

/// One card for its Properties: a handle whose `PeCard` comes from `pe_card_info`; free with `pe_card_free`
pub struct PeCardView {
    info: PeCard,
    _addresses: Vec<*const c_char>,
    _phones: Vec<PePhone>,
    _strings: Strings,
}

/// Card `id` with all its fields, NULL when there is none
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_card(core: *const PeCore, id: i64) -> *mut PeCardView {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| match core.card(id) {
            Ok(Some(card)) => handed(card_view(&card)),
            _ => null_mut(),
        })
    }
}

fn card_view(card: &Card) -> PeCardView {
    let mut strings = Strings::default();
    let addresses: Vec<*const c_char> = card.addresses.iter().map(|a| strings.add(a)).collect();
    let phones: Vec<PePhone> = card
        .phones
        .iter()
        .map(|(kind, number)| PePhone {
            kind: PePhoneKind::of(kind),
            number: strings.add(number),
        })
        .collect();
    let info = PeCard {
        id: card.id,
        name: strings.add(&card.name),
        first: strings.add(&card.first),
        last: strings.add(&card.last),
        nickname: strings.add(&card.nickname),
        company: strings.add(&card.company),
        notes: strings.add(&card.notes),
        // the Vec's buffer stays where it is when the Vec moves into the view
        addresses: if addresses.is_empty() {
            null()
        } else {
            addresses.as_ptr()
        },
        address_count: addresses.len(),
        phones: if phones.is_empty() { null() } else { phones.as_ptr() },
        phone_count: phones.len(),
    };
    PeCardView {
        info,
        _addresses: addresses,
        _phones: phones,
        _strings: strings,
    }
}

/// The card of a `pe_card` handle
///
/// # Safety
/// `view` must be NULL or a handle that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_card_info(view: *const PeCardView) -> *const PeCard {
    // SAFETY: as the caller guarantees
    unsafe { view.as_ref() }.map_or(null(), |view| &view.info)
}

/// # Safety
/// `view` must be NULL or a handle that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_card_free(view: *mut PeCardView) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(view) }
}

/// `count` items at `items`, each read by `read`; None when one can not be read. NULL is none.
///
/// # Safety
/// `items` must be NULL or point to `count` items.
unsafe fn items<T, U>(items: *const T, count: usize, read: impl FnMut(&T) -> Option<U>) -> Option<Vec<U>> {
    if items.is_null() || count == 0 {
        return Some(Vec::new());
    }
    // SAFETY: as the caller guarantees
    unsafe { std::slice::from_raw_parts(items, count) }
        .iter()
        .map(read)
        .collect()
}

/// A string field: NULL is empty, text that is not UTF-8 refuses the whole form
///
/// # Safety
/// `text` must be NULL or a NUL-terminated string.
unsafe fn field(text: *const c_char) -> Option<String> {
    if text.is_null() {
        return Some(String::new());
    }
    // SAFETY: as the caller guarantees
    unsafe { arg(text) }.map(str::to_string)
}

/// # Safety
/// `card` must be NULL or valid, as `pe_card_save` says.
unsafe fn card_of(card: *const PeCard) -> Option<Card> {
    // SAFETY: as the caller guarantees
    let c = unsafe { card.as_ref() }?;
    // SAFETY: as the caller guarantees, for every string and array below
    unsafe {
        Some(Card {
            id: c.id,
            name: field(c.name)?,
            first: field(c.first)?,
            last: field(c.last)?,
            nickname: field(c.nickname)?,
            company: field(c.company)?,
            notes: field(c.notes)?,
            addresses: items(c.addresses, c.address_count, |a| field(*a))?
                .into_iter()
                .map(|a| a.trim().to_string())
                .filter(|a| !a.is_empty())
                .collect(),
            phones: items(c.phones, c.phone_count, |p| {
                Some((p.kind.name().to_string(), field(p.number)?))
            })?,
            extra: String::new(),
            picture: None,
        })
    }
}

/// Saves a card: a new one when its `id` is 0, else in place of card `id` (what a vCard brought that the form does
/// not show is kept). An address that is not one mailbox alone is left out. With no name, first or last name the card
/// is known by its default address; one with no address either is refused. Its id, or 0 with the reason in `error`
/// (NULL or a pointer to a string to free with `pe_string_free`), in words for the user.
///
/// # Safety
/// `core` must be a live handle, `card` a valid card whose strings are NULL or NUL-terminated and whose arrays hold
/// `address_count` and `phone_count` items (or are NULL), `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_card_save(core: *const PeCore, card: *const PeCard, error: *mut *mut c_char) -> i64 {
    // SAFETY: as the caller guarantees
    let card = unsafe { card_of(card) };
    // SAFETY: as the caller guarantees
    let outcome = unsafe {
        with(core, Err(None), |core| {
            let Some(mut card) = card else {
                return Err(None);
            };
            if card.id != 0 {
                card.extra = match core.card(card.id) {
                    Ok(Some(old)) => old.extra,
                    Ok(None) => return Err(Some(pe_core::Error::NotFound)),
                    Err(e) => return Err(Some(e)),
                };
            }
            core.save_card(&card).map_err(Some)
        })
    };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the contact could not be saved") }.unwrap_or(0)
}

/// The display name that follows the first and last name as they are typed (Contact Properties): `Mary Smith`,
/// `Smith`, or empty; what a card saved without a display name gets. Free with `pe_string_free`; NULL on failure.
///
/// # Safety
/// `first` and `last` must be NULL or NUL-terminated strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_book_display_name(first: *const c_char, last: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let (first, last) = unsafe { (arg(first).unwrap_or_default(), arg(last).unwrap_or_default()) };
    guard(|| into_c_string(pe_core::book::display_name(first, last))).unwrap_or(null_mut())
}

/// Delete of the address book: `count` cards (`ids`) out of the book and the groups they are in, and `address_count`
/// addresses typed into `group` (the `address` of its rows with `id` 0) out of that group; `group` 0 for none.
/// False on failure.
///
/// # Safety
/// `core` must be a live handle, `ids` NULL or `count` ids, `addresses` NULL or `address_count` NUL-terminated
/// strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_book_delete(
    core: *const PeCore,
    group: i64,
    ids: *const i64,
    count: usize,
    addresses: *const *const c_char,
    address_count: usize,
) -> bool {
    // SAFETY: as the caller guarantees
    let Some(ids) = (unsafe { items(ids, count, |id| Some(*id)) }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    let Some(addresses) = (unsafe { items(addresses, address_count, |a| field(*a)) }) else {
        return false;
    };
    let group = (group != 0).then_some(group);
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, false, |core| {
            core.delete_from_book(group, &ids, &addresses).is_ok()
        })
    }
}

/// A group of the address book as its list shows it
#[repr(C)]
pub struct PeGroupRow {
    pub id: i64,
    pub name: *const c_char,
    pub member_count: usize,
    /// Its members as they go in an address field, separated by commas: what Write To and Select Recipients put in
    /// To, Cc or Bcc for the group
    pub label: *const c_char,
}

/// The groups; free with `pe_group_list_free`
pub struct PeGroupList(Rows<PeGroupRow>);

/// The groups of the address book, by name; with `filter` (NULL or empty for all), those whose name (a word of it)
/// starts with it, as `pe_cards` finds people. NULL on failure.
///
/// # Safety
/// `core` must be a live handle, `filter` NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_groups(core: *const PeCore, filter: *const c_char) -> *mut PeGroupList {
    // SAFETY: as the caller guarantees
    let filter = unsafe { filter_of(filter) };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(groups) = core.groups(&filter) else {
                return null_mut();
            };
            handed(PeGroupList(Rows::new(&groups, |group, strings| PeGroupRow {
                id: group.id,
                name: strings.add(&group.name),
                member_count: group.members.len(),
                label: strings.add(&pe_core::book::group_label(group)),
            })))
        })
    }
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_group_list_count(list: *const PeGroupList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// Row `index`, NULL past the end
///
/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_group_list_get(list: *const PeGroupList, index: usize) -> *const PeGroupRow {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_group_list_free(list: *mut PeGroupList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// Someone in a group: a card of the book, or an address typed in
#[repr(C)]
pub struct PeMember {
    /// The card, 0 for an address of no card. Saved, a card member follows its card (its name and default address)
    pub card: i64,
    pub name: *const c_char,
    pub address: *const c_char,
    /// As it goes in an address field (from `pe_group` only; not read by `pe_group_save`)
    pub label: *const c_char,
}

/// A group with its members. From `pe_group`, its strings and array belong to the handle; to `pe_group_save`, to the
/// caller.
#[repr(C)]
pub struct PeGroup {
    /// 0 for a new one
    pub id: i64,
    pub name: *const c_char,
    pub members: *const PeMember,
    pub member_count: usize,
}

/// One group for its Properties: a handle whose `PeGroup` comes from `pe_group_info`; free with `pe_group_free`
pub struct PeGroupView {
    info: PeGroup,
    _members: Vec<PeMember>,
    _strings: Strings,
}

/// Group `id` with its members, NULL when there is none
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_group(core: *const PeCore, id: i64) -> *mut PeGroupView {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(Some(group)) = core.group(id) else {
                return null_mut();
            };
            let mut strings = Strings::default();
            let members: Vec<PeMember> = group
                .members
                .iter()
                .map(|m| PeMember {
                    card: m.card.unwrap_or(0),
                    name: strings.add(&m.name),
                    address: strings.add(&m.address),
                    label: strings.add(&pe_core::book::member_label(m)),
                })
                .collect();
            let info = PeGroup {
                id: group.id,
                name: strings.add(&group.name),
                members: if members.is_empty() { null() } else { members.as_ptr() },
                member_count: members.len(),
            };
            handed(PeGroupView {
                info,
                _members: members,
                _strings: strings,
            })
        })
    }
}

/// The group of a `pe_group` handle
///
/// # Safety
/// `view` must be NULL or a handle that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_group_info(view: *const PeGroupView) -> *const PeGroup {
    // SAFETY: as the caller guarantees
    unsafe { view.as_ref() }.map_or(null(), |view| &view.info)
}

/// # Safety
/// `view` must be NULL or a handle that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_group_free(view: *mut PeGroupView) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(view) }
}

/// Saves a group: a new one when its `id` is 0, else in place of group `id`. A member of no card without an address
/// is left out, and a card or an address given twice (a card's default address typed again too) is kept once. Its id, or 0 with the reason in `error` (NULL or a pointer to a string to free with
/// `pe_string_free`).
///
/// # Safety
/// `core` must be a live handle, `group` a valid group whose strings are NULL or NUL-terminated and whose `members`
/// holds `member_count` of them (or is NULL), `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_group_save(core: *const PeCore, group: *const PeGroup, error: *mut *mut c_char) -> i64 {
    // SAFETY: as the caller guarantees
    let group = unsafe { group.as_ref() }.and_then(|g| {
        // SAFETY: as the caller guarantees
        unsafe {
            Some(Group {
                id: g.id,
                name: field(g.name)?,
                members: members_of(g.members, g.member_count)?,
            })
        }
    });
    // SAFETY: as the caller guarantees
    let outcome = unsafe {
        with(core, Err(None), |core| match group {
            Some(group) => core.save_group(&group).map_err(Some),
            None => Err(None),
        })
    };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the group could not be saved") }.unwrap_or(0)
}

/// `count` members at `members`; None when a string is not UTF-8
///
/// # Safety
/// `members` must be NULL or point to `count` members whose strings are NULL or NUL-terminated.
unsafe fn members_of(members: *const PeMember, count: usize) -> Option<Vec<Member>> {
    // SAFETY: as the caller guarantees
    unsafe {
        items(members, count, |m| {
            Some(Member {
                card: (m.card != 0).then_some(m.card),
                name: field(m.name)?,
                address: field(m.address)?.trim().to_string(),
            })
        })
    }
}

/// Which of `added_count` members (`added`) go into a group of `count` members (`members`), the way Group Properties
/// adds people: `keep[i]` (an array of `added_count`) true for those not in it yet, a card once and an address once
/// (whether of a card or typed, ignoring case; also against those before it in `added`). Give each member its
/// `address`, a card's its default one. How many to add; 0 with every `keep` false for an argument that can not be
/// read.
///
/// # Safety
/// `members` and `added` must be NULL or point to `count` and `added_count` members whose strings are NULL or
/// NUL-terminated, `keep` NULL or an array of `added_count`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_book_members_add(
    members: *const PeMember,
    count: usize,
    added: *const PeMember,
    added_count: usize,
    keep: *mut bool,
) -> usize {
    if keep.is_null() || added_count == 0 {
        return 0;
    }
    // SAFETY: as the caller guarantees
    let keep = unsafe { std::slice::from_raw_parts_mut(keep, added_count) };
    keep.fill(false);
    // SAFETY: as the caller guarantees
    let (Some(members), Some(added)) = (unsafe { members_of(members, count) }, unsafe {
        members_of(added, added_count)
    }) else {
        return 0;
    };
    guard(|| {
        let mut list = members;
        let mut kept = 0;
        for (index, member) in added.iter().enumerate() {
            let longer = pe_core::book::add_members(&list, std::slice::from_ref(member));
            if longer.len() > list.len() {
                keep[index] = true;
                kept += 1;
                list = longer;
            }
        }
        kept
    })
    .unwrap_or(0)
}

/// Deletes a group (not the people in it)
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_group_delete(core: *const PeCore, id: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.delete_group(id).is_ok()) }
}

/// Adds the sender of message `uid` of `folder` to the address book (Add Sender to Address Book): the id of the card
/// that has their address already, or of a new one with their name and address, `added` (when not NULL) true for a
/// new one. 0 when the message is not there or its sender has no address. `status` (when not NULL) gets what the
/// status bar says in every case (added, there already, no address to add, or why it failed); free it with
/// `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle, `added` and `status` NULL or valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_book_add_sender(
    core: *const PeCore,
    folder: i64,
    uid: u64,
    added: *mut bool,
    status: *mut *mut c_char,
) -> i64 {
    // SAFETY: as the caller guarantees
    let outcome = unsafe {
        with(core, None, |core| {
            Some(
                core.add_sender(folder, uid)
                    .unwrap_or_else(|error| pe_core::book::SenderAdded {
                        status: error.to_string(),
                        ..Default::default()
                    }),
            )
        })
    };
    let done = outcome.unwrap_or_default();
    if !added.is_null() {
        // SAFETY: as the caller guarantees
        unsafe { *added = done.added };
    }
    if !status.is_null() {
        // SAFETY: as the caller guarantees
        unsafe { *status = into_c_string(done.status) };
    }
    done.card
}

/// Reads the vCard (`.vcf`) and CSV files at `paths` (`count` of them, UTF-8) into the address book (File > Import >
/// Address Book): a card whose addresses are all in the book already is left out. `added` and `skipped` (when not
/// NULL) get the counts of every file read. True when every file was read; false when one could not be (or is too
/// big), the others read all the same, with `error` (NULL or a pointer to a string to free with `pe_string_free`)
/// naming each such file and why, a line each.
///
/// # Safety
/// `core` must be a live handle, `paths` NULL or `count` NUL-terminated strings, `added`, `skipped` and `error` NULL
/// or valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_book_import(
    core: *const PeCore,
    paths: *const *const c_char,
    count: usize,
    added: *mut u64,
    skipped: *mut u64,
    error: *mut *mut c_char,
) -> bool {
    // SAFETY: as the caller guarantees
    let paths: Option<Vec<std::path::PathBuf>> = unsafe {
        items(paths, count, |path| {
            arg(*path).filter(|p| !p.is_empty()).map(std::path::PathBuf::from)
        })
    };
    // SAFETY: as the caller guarantees
    let outcome = unsafe {
        with(core, Err(None), |core| match &paths {
            Some(paths) => Ok(core.import_cards(paths)),
            None => Err(None),
        })
    };
    // SAFETY: as the caller guarantees
    let Some(imported) = (unsafe { refused(error, outcome, "the file could not be read") }) else {
        return false;
    };
    for (to, value) in [(added, imported.added), (skipped, imported.skipped)] {
        if !to.is_null() {
            // SAFETY: as the caller guarantees
            unsafe { *to = value };
        }
    }
    if imported.failed.is_empty() {
        return true;
    }
    if !error.is_null() {
        // SAFETY: as the caller guarantees
        unsafe { *error = into_c_string(imported.failures()) };
    }
    false
}

/// Writes `count` cards (`ids`; every card when `count` is 0) to a vCard file at `path` (UTF-8), replacing one that
/// is there (File > Export > Address Book). `written` (when not NULL) gets how many. False with the reason in `error`
/// (NULL or a pointer to a string to free with `pe_string_free`) when the file can not be written.
///
/// # Safety
/// `core` must be a live handle, `ids` NULL or `count` ids, `path` a NUL-terminated string, `written` and `error`
/// NULL or valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_book_export(
    core: *const PeCore,
    ids: *const i64,
    count: usize,
    path: *const c_char,
    written: *mut u64,
    error: *mut *mut c_char,
) -> bool {
    // SAFETY: as the caller guarantees
    let ids = unsafe { items(ids, count, |id| Some(*id)) }.unwrap_or_default();
    // SAFETY: as the caller guarantees
    let path = unsafe { arg(path) }.map(std::path::PathBuf::from);
    // SAFETY: as the caller guarantees
    let outcome = unsafe {
        with(core, Err(None), |core| match &path {
            Some(path) => core.export_cards(&ids, path).map_err(Some),
            None => Err(None),
        })
    };
    // SAFETY: as the caller guarantees
    let Some(count) = (unsafe { refused(error, outcome, "the file could not be written") }) else {
        return false;
    };
    if !written.is_null() {
        // SAFETY: as the caller guarantees
        unsafe { *written = count };
    }
    true
}

/// The text of an address field (`field`, as typed so far) with `added` put at its end after a comma: the `label`s of
/// card, group and completion rows, separated by commas. An address already in the field, or given twice, goes in
/// once. What Select Recipients and Write To put in To, Cc or Bcc. Free with `pe_string_free`; NULL on failure.
///
/// # Safety
/// `field` and `added` must be NULL or NUL-terminated strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_address_field_add(field: *const c_char, added: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let (field, added) = unsafe { (arg(field).unwrap_or_default(), arg(added).unwrap_or_default()) };
    guard(|| into_c_string(pe_core::book::add_to_field(field, added))).unwrap_or(null_mut())
}

/// Whether `address` is one mailbox alone (`mary@example.com`): what Contact Properties checks a typed address with
/// before saving it, the way the core keeps only such addresses on a card. False for NULL.
///
/// # Safety
/// `address` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_address_is_mailbox(address: *const c_char) -> bool {
    // SAFETY: as the caller guarantees
    let Some(address) = (unsafe { arg(address) }) else {
        return false;
    };
    guard(|| pe_core::book::is_mailbox(address)).unwrap_or(false)
}

/// Bytes handed to C, `len` set to their length; free with `pe_bytes_free`
fn handed_bytes(bytes: Vec<u8>, len: &mut usize) -> *mut u8 {
    let bytes = bytes.into_boxed_slice();
    *len = bytes.len();
    Box::into_raw(bytes).cast()
}

/// The picture file at `path` (PNG or JPEG) as the core keeps a contact's picture: read and turned into the core's
/// own 256 pixel square PNG, `len` bytes, to show (`pe_png_bgra`) and to set once the user says OK
/// (`pe_card_set_picture_png`). Needs no core and touches no store: call it off the window thread. NULL with the
/// reason in `error` (NULL or a pointer to a string to free with `pe_string_free`), in words for the user: the file
/// is no PNG or JPEG picture, it is too large, or it can not be read. Free the bytes with `pe_bytes_free`.
///
/// # Safety
/// `path` must be a NUL-terminated string, `len` a valid pointer, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_card_picture_prepare(
    path: *const c_char,
    len: *mut usize,
    error: *mut *mut c_char,
) -> *mut u8 {
    // SAFETY: as the caller guarantees
    let Some(len) = (unsafe { len.as_mut() }) else {
        return null_mut();
    };
    *len = 0;
    // SAFETY: as the caller guarantees
    let path = unsafe { arg(path) }.map(std::path::PathBuf::from);
    let outcome = guard(|| match &path {
        Some(path) => pe_core::card_pictures::prepare(path),
        None => Err(pe_core::card_pictures::Refused::NotPicture),
    })
    .unwrap_or(Err(pe_core::card_pictures::Refused::NotPicture));
    match outcome {
        Ok(png) => handed_bytes(png, len),
        Err(refused) => {
            if !error.is_null() {
                // SAFETY: the caller gave a valid pointer
                unsafe { *error = into_c_string(pe_core::sentence(&refused.text())) };
            }
            null_mut()
        }
    }
}

/// Sets card `card`'s picture to `png` (`len` bytes), one `pe_card_picture_prepare` made; false for anything else
///
/// # Safety
/// `core` must be a live handle, `png` `len` readable bytes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_card_set_picture_png(core: *const PeCore, card: i64, png: *const u8, len: usize) -> bool {
    if png.is_null() {
        return false;
    }
    // SAFETY: as the caller guarantees
    let png = unsafe { std::slice::from_raw_parts(png, len) };
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.set_card_picture_png(card, png).is_ok()) }
}

/// A picture `pe_card_picture_prepare` made (`png`, `len` bytes) as `size` x `size` BGRA with the alpha multiplied in
/// (`size` 16 to 512), `out_len` bytes, for the window to show it before it is set; NULL for anything else. Needs no
/// core. Free with `pe_bytes_free`.
///
/// # Safety
/// `png` must be `len` readable bytes, `out_len` a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_png_bgra(png: *const u8, len: usize, size: u32, out_len: *mut usize) -> *mut u8 {
    // SAFETY: as the caller guarantees
    let Some(out_len) = (unsafe { out_len.as_mut() }) else {
        return null_mut();
    };
    *out_len = 0;
    if png.is_null() {
        return null_mut();
    }
    // SAFETY: as the caller guarantees
    let png = unsafe { std::slice::from_raw_parts(png, len) };
    match guard(|| pe_core::card_pictures::bgra(png, size)).flatten() {
        Some(pixels) => handed_bytes(pixels, out_len),
        None => null_mut(),
    }
}

/// Takes card `card`'s picture away
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_card_remove_picture(core: *const PeCore, card: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.remove_card_picture(card).is_ok()) }
}

/// Whether card `card` has a picture
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_card_has_picture(core: *const PeCore, card: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.card_has_picture(card)) }
}

/// Card `card`'s picture for its Properties: `size` x `size` BGRA with the alpha multiplied in (`size` 16 to 512),
/// `len` bytes; NULL when it has none. Free with `pe_bytes_free`.
///
/// # Safety
/// `core` must be a live handle, `len` a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_card_picture(core: *const PeCore, card: i64, size: u32, len: *mut usize) -> *mut u8 {
    // SAFETY: as the caller guarantees
    let Some(len) = (unsafe { len.as_mut() }) else {
        return null_mut();
    };
    *len = 0;
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| match core.card_picture(card, size) {
            Some(pixels) => handed_bytes(pixels, len),
            None => null_mut(),
        })
    }
}

/// One or two initials of a person, as the message list shows them (`pe_core::initials`): from `name`, else from
/// `address`; empty for neither. Either may be NULL. Free with `pe_string_free`.
///
/// # Safety
/// `name` and `address` must each be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_initials(name: *const c_char, address: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let text = |p: *const c_char| {
        if p.is_null() {
            String::new()
        } else {
            unsafe { std::ffi::CStr::from_ptr(p) }.to_string_lossy().into_owned()
        }
    };
    let (name, address) = (text(name), text(address));
    crate::guard(|| pe_core::initials(&name, &address)).map_or(std::ptr::null_mut(), crate::into_c_string)
}
