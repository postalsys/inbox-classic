//! Message rules through C: the list of them, one saved, deleted or moved, how many messages a query matches now,
//! why a query can not be a rule's, and a rule run over the messages already in the Inbox.

use std::ffi::c_char;
use std::ptr::null_mut;

use pe_store::Rule;

use crate::core::{PeCore, Rows, arg, handed, refused, take_back, with};
use crate::into_c_string;

/// A message rule: a search query and what to do with the new mail of an Inbox that matches it
#[repr(C)]
pub struct PeRule {
    /// 0 for a new rule
    pub id: i64,
    pub enabled: bool,
    pub name: *const c_char,
    /// The account whose Inbox it is for, 0 for every account's
    pub account: i64,
    /// What the new mail has to match, in the search box's words
    pub query: *const c_char,
    /// The folder it moves the messages to, 0 for none
    pub move_to: i64,
    pub mark_read: bool,
    pub flag: bool,
    pub archive: bool,
    pub junk: bool,
    /// Into Deleted Items
    pub remove: bool,
    /// Not announced as new mail
    pub quiet: bool,
}

/// The rules; free with `pe_rules_free`
pub struct PeRules(Rows<PeRule>);

/// The message rules, in their order; NULL on failure
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_rules(core: *const PeCore) -> *mut PeRules {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(rules) = core.rules() else {
                return null_mut();
            };
            handed(PeRules(Rows::new(&rules, |r, strings| PeRule {
                id: r.id,
                enabled: r.enabled,
                name: strings.add(&r.name),
                account: r.account.unwrap_or(0),
                query: strings.add(&r.query),
                move_to: r.move_to.unwrap_or(0),
                mark_read: r.mark_read,
                flag: r.flag,
                archive: r.archive,
                junk: r.junk,
                remove: r.remove,
                quiet: r.quiet,
            })))
        })
    }
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_rules_count(list: *const PeRules) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// Rule `index`, NULL past the end
///
/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_rules_get(list: *const PeRules, index: usize) -> *const PeRule {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_rules_free(list: *mut PeRules) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// Saves a rule (a new one, id 0, last); its id, or 0 with the reason in `error` (free it with `pe_string_free`) for
/// a query that can not be a rule's or a rule that does nothing
///
/// # Safety
/// `core` must be a live handle, `rule` a valid rule, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_rule_save(core: *const PeCore, rule: *const PeRule, error: *mut *mut c_char) -> i64 {
    // SAFETY: as the caller guarantees
    let Some(r) = (unsafe { rule.as_ref() }) else {
        return 0;
    };
    // SAFETY: the strings of a valid rule
    let (name, query) = unsafe { (arg(r.name).unwrap_or_default(), arg(r.query).unwrap_or_default()) };
    let rule = Rule {
        id: r.id,
        enabled: r.enabled,
        name: name.to_string(),
        account: (r.account != 0).then_some(r.account),
        query: query.to_string(),
        move_to: (r.move_to != 0).then_some(r.move_to),
        mark_read: r.mark_read,
        flag: r.flag,
        archive: r.archive,
        junk: r.junk,
        remove: r.remove,
        quiet: r.quiet,
    };
    // SAFETY: as the caller guarantees
    let result = unsafe { with(core, Err(None), |core| core.save_rule(&rule).map_err(Some)) };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, result, "the rule could not be saved") }.unwrap_or(0)
}

/// Deletes a rule
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_rule_delete(core: *const PeCore, id: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.delete_rule(id).is_ok()) }
}

/// Moves a rule one place up (earlier) or down; false when it was first or last already
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_rule_move(core: *const PeCore, id: i64, up: bool) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.move_rule(id, up).unwrap_or(false)) }
}

/// How many messages in the Inbox of `account` (0: of every account) `query` matches now, for the rule editor
///
/// # Safety
/// `core` must be a live handle, `query` a valid string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_rule_matches(core: *const PeCore, query: *const c_char, account: i64) -> u64 {
    // SAFETY: as the caller guarantees
    let Some(query) = (unsafe { arg(query) }) else {
        return 0;
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, 0, |core| {
            core.rule_matches(query, (account != 0).then_some(account)).unwrap_or(0)
        })
    }
}

/// Why `query` can not be a rule's (it names a folder or a date), NULL when it can; free with `pe_string_free`
///
/// # Safety
/// `core` must be a live handle, `query` a valid string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_rule_query_problem(core: *const PeCore, query: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let Some(query) = (unsafe { arg(query) }) else {
        return null_mut();
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.rule_query_problem(query).map_or(null_mut(), into_c_string)
        })
    }
}

/// The words for the search box that show what `query` matches in the Inboxes (the rule editor's Show); free with
/// `pe_string_free`
///
/// # Safety
/// `core` must be a live handle, `query` a valid string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_rule_search_text(core: *const PeCore, query: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let Some(query) = (unsafe { arg(query) }) else {
        return null_mut();
    };
    // SAFETY: as the caller guarantees
    unsafe { with(core, null_mut(), |core| into_c_string(core.rule_search_text(query))) }
}

/// Runs a rule over the messages already in the Inbox (of its account or every account's), in the background:
/// `RulesApplied` says how many it sorted
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_rule_apply_now(core: *const PeCore, id: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.apply_rule_now(id).is_ok()) }
}

/// The query a rule made from a message starts with: `from:` its sender, or `list:` its mailing list; empty when
/// there is no message. Free with `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_rule_query_of_message(core: *const PeCore, folder: i64, uid: u64) -> *mut c_char {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            into_c_string(core.rule_query_of_message(folder, uid).unwrap_or_default())
        })
    }
}
