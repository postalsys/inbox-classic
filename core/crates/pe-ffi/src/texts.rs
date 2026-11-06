//! The words of the windows through C: one of the catalog (`PeText`, core/include/texts.h) in the language in use,
//! with its placeables filled, and the language itself: which there are, which is in use, and which the system's
//! preferred languages come to.

use std::ffi::c_char;
use std::ptr::null_mut;

use pe_i18n::{Arg, Text};

use crate::core::{Rows, arg, handed, take_back};
use crate::{guard, into_c_string};

/// Word `text` (PE_TEXT_...) in the language in use, `&` marking a menu letter as the catalog has it. Free with
/// `pe_string_free`; NULL for a number that is no word.
#[unsafe(no_mangle)]
pub extern "C" fn pe_text(text: u32) -> *mut c_char {
    guard(|| Text::from_index(text).map_or(null_mut(), |t| into_c_string(pe_i18n::tr(t)))).unwrap_or(null_mut())
}

/// [`pe_text`] without the menu letter marks, as the Mac shows a word. Free with `pe_string_free`.
#[unsafe(no_mangle)]
pub extern "C" fn pe_text_plain(text: u32) -> *mut c_char {
    guard(|| {
        Text::from_index(text).map_or(null_mut(), |t| {
            into_c_string(pe_i18n::without_mnemonic(&pe_i18n::tr(t)))
        })
    })
    .unwrap_or(null_mut())
}

/// Word `text` with its placeables filled: `names[i]` is `values[i]`, a value that is a whole number passed as a number
/// (plurals choose by it). Free with `pe_string_free`.
///
/// # Safety
/// `names` and `values` must be NULL or `count` NUL-terminated strings each.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_text_args(
    text: u32,
    names: *const *const c_char,
    values: *const *const c_char,
    count: usize,
) -> *mut c_char {
    let Some(text) = Text::from_index(text) else {
        return null_mut();
    };
    let mut pairs: Vec<(String, String)> = Vec::new();
    if count > 0 && !names.is_null() && !values.is_null() {
        for i in 0..count {
            // SAFETY: the caller gave `count` strings in each
            let (name, value) = unsafe { (arg(*names.add(i)), arg(*values.add(i))) };
            if let (Some(name), Some(value)) = (name, value) {
                pairs.push((name.to_string(), value.to_string()));
            }
        }
    }
    guard(|| {
        let args: Vec<(&str, Arg)> = pairs
            .iter()
            .map(|(name, value)| {
                // a number only when it reads back the same: "007" or "+1" (a subject, a folder) stays as written
                let value = match value.parse::<i64>().ok().filter(|n| &n.to_string() == value) {
                    Some(number) => Arg::Num(number),
                    None => Arg::Str(value),
                };
                (name.as_str(), value)
            })
            .collect();
        into_c_string(pe_i18n::tr_args(text, &args))
    })
    .unwrap_or(null_mut())
}

/// A language there is a catalog of
#[repr(C)]
pub struct PeLanguage {
    /// `de`
    pub code: *const c_char,
    /// Its name in itself, `Deutsch`
    pub name: *const c_char,
}

/// The languages; free with `pe_language_list_free`
pub struct PeLanguageList(Rows<PeLanguage>);

/// The languages there is a catalog of, English first, as the language choice lists them
#[unsafe(no_mangle)]
pub extern "C" fn pe_languages() -> *mut PeLanguageList {
    guard(|| {
        handed(PeLanguageList(Rows::new(
            pe_i18n::LANGUAGES,
            |(code, name), strings| PeLanguage {
                code: strings.add(code),
                name: strings.add(name),
            },
        )))
    })
    .unwrap_or(null_mut())
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_language_list_count(list: *const PeLanguageList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|l| &l.0))
}

/// Language `index`, valid until the list is freed; NULL past the end
///
/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_language_list_get(list: *const PeLanguageList, index: usize) -> *const PeLanguage {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|l| &l.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet, freed once.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_language_list_free(list: *mut PeLanguageList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// Uses the catalog of `code` (`de`, `de-AT`; `qps` the test pseudo-language) from now on, English for one there is
/// none of. Call it at start, before the windows read any word. Returns the code used; free with `pe_string_free`.
///
/// # Safety
/// `code` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_set_language(code: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let code = unsafe { arg(code) }.unwrap_or_default().to_string();
    guard(|| into_c_string(pe_i18n::set_language(&code).to_string())).unwrap_or(null_mut())
}

/// The language for the system's preferred languages (`preferred`, most preferred first: `de-AT`, `en-US`): the
/// first there is a catalog of, `en` when none. Free with `pe_string_free`.
///
/// # Safety
/// `preferred` must be NULL or `count` NUL-terminated strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_resolve_language(preferred: *const *const c_char, count: usize) -> *mut c_char {
    let mut tags = Vec::new();
    if !preferred.is_null() {
        for i in 0..count {
            // SAFETY: the caller gave `count` strings
            if let Some(tag) = unsafe { arg(*preferred.add(i)) } {
                tags.push(tag.to_string());
            }
        }
    }
    guard(|| into_c_string(pe_i18n::resolve(&tags).to_string())).unwrap_or(null_mut())
}

/// The code of the language in use (`en` before one was set). Free with `pe_string_free`.
#[unsafe(no_mangle)]
pub extern "C" fn pe_language() -> *mut c_char {
    guard(|| into_c_string(pe_i18n::language().to_string())).unwrap_or(null_mut())
}

#[cfg(test)]
mod tests {
    use super::*;

    include!(concat!(env!("OUT_DIR"), "/text_ids.rs"));

    #[test]
    fn the_ids_of_c_and_swift_are_the_catalogs() {
        // the generated headers number the words as pe-i18n does
        let ids: Vec<&str> = Text::ALL.iter().map(|t| t.id()).collect();
        assert_eq!(ids, TEXT_IDS);
    }

    #[test]
    fn values_that_only_look_like_numbers_stay_as_written() {
        let text = Text::SavedTo as u32;
        let names = [c"count".as_ptr(), c"messages".as_ptr(), c"folder".as_ptr()];
        let values = [c"3".as_ptr(), c"3 messages".as_ptr(), c"007".as_ptr()];
        // SAFETY: three names and three values, NUL-terminated
        let said = unsafe { pe_text_args(text, names.as_ptr(), values.as_ptr(), 3) };
        // SAFETY: from pe_text_args
        let text = unsafe { std::ffi::CStr::from_ptr(said) }.to_string_lossy().into_owned();
        // SAFETY: from pe_text_args, freed once
        unsafe { crate::pe_string_free(said) };
        assert_eq!(text, "Saved 3 messages to 007");
    }
}
