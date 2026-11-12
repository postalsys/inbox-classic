//! The help for the Windows and Mac apps' viewers: the contents, a topic's page, a search, and the topic of a window
//! (pe-html help.rs), in the language in use

use std::ffi::c_char;
use std::ptr::null_mut;

use crate::core::{Rows, arg, handed, take_back};
use crate::{guard, into_c_string};

/// A topic of the contents or of a search
#[repr(C)]
pub struct PeHelpRow {
    /// The section's title in the contents (the same for each of its topics); empty in a search
    pub section: *const c_char,
    /// The topic's id, for `pe_help_topic`
    pub topic: *const c_char,
    pub title: *const c_char,
    /// One sentence of what the topic is about
    pub summary: *const c_char,
}

/// The list of `pe_help_contents` and `pe_help_search`
pub struct PeHelpList(Rows<PeHelpRow>);

/// `platform` (`windows`, `mac` or `linux`), the platform this was built for when NULL or unknown
///
/// # Safety
/// `platform` must be NULL or a NUL-terminated string.
unsafe fn platform(platform: *const c_char) -> pe_html::Platform {
    // SAFETY: as the caller guarantees
    unsafe { arg(platform) }
        .and_then(pe_html::Platform::from_name)
        .unwrap_or_else(pe_html::Platform::current)
}

fn list(rows: &[(String, pe_html::HelpTopic)]) -> *mut PeHelpList {
    handed(PeHelpList(Rows::new(rows, |(section, topic), strings| PeHelpRow {
        section: strings.add(section),
        topic: strings.add(&topic.id),
        title: strings.add(&topic.title),
        summary: strings.add(&topic.summary),
    })))
}

/// The contents: every topic in order, with its section's title. Free with `pe_help_list_free`.
///
/// # Safety
/// `platform` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_help_contents(platform_name: *const c_char) -> *mut PeHelpList {
    // SAFETY: as the caller guarantees
    let platform = unsafe { platform(platform_name) };
    guard(|| {
        let rows: Vec<(String, pe_html::HelpTopic)> = pe_html::help_contents(platform, pe_i18n::language())
            .into_iter()
            .flat_map(|section| {
                section
                    .topics
                    .into_iter()
                    .map(move |topic| (section.title.clone(), topic))
            })
            .collect();
        list(&rows)
    })
    .unwrap_or(null_mut())
}

/// The topics that have every word of `query`, the best first. Free with `pe_help_list_free`.
///
/// # Safety
/// `platform` and `query` must be NULL or NUL-terminated strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_help_search(platform_name: *const c_char, query: *const c_char) -> *mut PeHelpList {
    // SAFETY: as the caller guarantees
    let (platform, query) = unsafe { (platform(platform_name), arg(query).unwrap_or_default().to_string()) };
    guard(|| {
        let rows: Vec<(String, pe_html::HelpTopic)> = pe_html::help_search(&query, platform, pe_i18n::language())
            .into_iter()
            .map(|topic| (String::new(), topic))
            .collect();
        list(&rows)
    })
    .unwrap_or(null_mut())
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_help_list_count(list: *const PeHelpList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// The row at `index`, NULL past the end; it lives as long as the list
///
/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_help_list_get(list: *const PeHelpList, index: usize) -> *const PeHelpRow {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_help_list_free(list: *mut PeHelpList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// The page of the topic `topic` for the help viewer, its links to other topics `topic:<id>` (see
/// `pe_help_link_topic`); NULL for no such topic. Free with `pe_string_free`.
///
/// # Safety
/// `platform` and `topic` must be NULL or NUL-terminated strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_help_topic(platform_name: *const c_char, topic: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let (platform, topic) = unsafe { (platform(platform_name), arg(topic).unwrap_or_default().to_string()) };
    guard(|| pe_html::help_topic(&topic, platform, pe_i18n::language()).map_or(null_mut(), into_c_string))
        .unwrap_or(null_mut())
}

/// The topic a window's help opens (`main`, `account-form`, `account-properties`, `options`, `sign-in-apps`,
/// `agents`, `address-book`, `compose`). Free with `pe_string_free`.
///
/// # Safety
/// `window` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_help_context(window: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let window = unsafe { arg(window) }.unwrap_or_default().to_string();
    guard(|| into_c_string(pe_html::help_context(&window).to_string())).unwrap_or(null_mut())
}

/// The topic a link of a help page opens (`topic:find-messages`), NULL for a link that is no topic (one to open in
/// the browser). Free with `pe_string_free`.
///
/// # Safety
/// `url` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_help_link_topic(url: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let url = unsafe { arg(url) }.unwrap_or_default().to_string();
    guard(|| pe_html::help_link_topic(&url).map_or(null_mut(), |topic| into_c_string(topic.to_string())))
        .unwrap_or(null_mut())
}
