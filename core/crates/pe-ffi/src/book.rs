//! The address book through C: its people (cards) and groups as lists of rows, one card or group with all its fields
//! for Properties, saving and deleting them, a message's sender added, and vCard and CSV files read in and written
//! out. The completion of address fields is `pe_contacts` (in `core.rs`).

use std::ffi::c_char;
use std::ptr::{null, null_mut};

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
    pub id: i64,
    /// The name shown (Name column)
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

/// The people of the address book, by name; with `filter` (NULL or empty for everyone), those whose name (a word of
/// it), nickname, company or an address starts with it. NULL on failure.
///
/// # Safety
/// `core` must be a live handle, `filter` NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_cards(core: *const PeCore, filter: *const c_char) -> *mut PeCardList {
    // SAFETY: as the caller guarantees
    let filter = unsafe { arg(filter) }.unwrap_or_default().to_string();
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(cards) = core.cards(&filter) else {
                return null_mut();
            };
            handed(PeCardList(Rows::new(&cards, |card, strings| {
                let address = card.addresses.first().map_or("", String::as_str);
                let label = if address.is_empty() {
                    String::new()
                } else {
                    pe_core::address_label(&card.name, address)
                };
                PeCardRow {
                    id: card.id,
                    name: strings.add(&card.name),
                    address: strings.add(address),
                    phone: strings.add(card.phones.first().map_or("", |(_, number)| number.as_str())),
                    company: strings.add(&card.company),
                    label: strings.add(&label),
                }
            })))
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
        })
    }
}

/// Saves a card: a new one when its `id` is 0, else in place of card `id` (what a vCard brought that the form does
/// not show is kept). An address that is not one mailbox alone is left out. Its id, or 0 with the reason in `error`
/// (NULL or a pointer to a string to free with `pe_string_free`).
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

/// Deletes `count` cards (out of the groups they are in too)
///
/// # Safety
/// `core` must be a live handle, `ids` NULL or `count` ids.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_cards_delete(core: *const PeCore, ids: *const i64, count: usize) -> bool {
    // SAFETY: as the caller guarantees
    let Some(ids) = (unsafe { items(ids, count, |id| Some(*id)) }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.delete_cards(&ids).is_ok()) }
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

/// The members of a group with an address, as they go in an address field
fn members_label(members: &[Member]) -> String {
    members
        .iter()
        .filter(|m| m.address.contains('@'))
        .map(|m| pe_core::address_label(&m.name, &m.address))
        .collect::<Vec<_>>()
        .join(", ")
}

/// The groups of the address book, by name; NULL on failure
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_groups(core: *const PeCore) -> *mut PeGroupList {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(groups) = core.groups() else {
                return null_mut();
            };
            handed(PeGroupList(Rows::new(&groups, |group, strings| PeGroupRow {
                id: group.id,
                name: strings.add(&group.name),
                member_count: group.members.len(),
                label: strings.add(&members_label(&group.members)),
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
                    label: strings.add(&pe_core::address_label(&m.name, &m.address)),
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
/// is left out. Its id, or 0 with the reason in `error` (NULL or a pointer to a string to free with
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
                members: items(g.members, g.member_count, |m| {
                    Some(Member {
                        card: (m.card != 0).then_some(m.card),
                        name: field(m.name)?,
                        address: field(m.address)?.trim().to_string(),
                    })
                })?,
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
/// new one. 0 when the message is not there or its sender has no address.
///
/// # Safety
/// `core` must be a live handle, `added` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_book_add_sender(core: *const PeCore, folder: i64, uid: u64, added: *mut bool) -> i64 {
    // SAFETY: as the caller guarantees
    let (id, new) = unsafe {
        with(core, (0, false), |core| {
            core.add_sender(folder, uid).unwrap_or((0, false))
        })
    };
    if !added.is_null() {
        // SAFETY: as the caller guarantees
        unsafe { *added = new };
    }
    id
}

/// Reads the vCard (`.vcf`) or CSV file at `path` (UTF-8) into the address book (File > Import > Address Book): a
/// card whose addresses are all in the book already is left out. `added` and `skipped` (when not NULL) get the
/// counts. False with the reason in `error` (NULL or a pointer to a string to free with `pe_string_free`) for a file
/// that can not be read or is too big.
///
/// # Safety
/// `core` must be a live handle, `path` a NUL-terminated string, `added`, `skipped` and `error` NULL or valid
/// pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_book_import(
    core: *const PeCore,
    path: *const c_char,
    added: *mut u64,
    skipped: *mut u64,
    error: *mut *mut c_char,
) -> bool {
    // SAFETY: as the caller guarantees
    let path = unsafe { arg(path) }.map(std::path::PathBuf::from);
    // SAFETY: as the caller guarantees
    let outcome = unsafe {
        with(core, Err(None), |core| match &path {
            Some(path) => core.import_cards(path).map_err(Some),
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
    true
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
