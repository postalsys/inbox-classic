//! Emoji reactions through C: the reactions to the message the reading pane shows, one chip a person, and what a
//! chip's menu does (Open Reaction Email, Show as Email). The badges of the list rows are `PeMessage::reactions`.

use std::ffi::c_char;
use std::ptr::null_mut;

use pe_core::reactions::ReactionChip;

use crate::core::{PeCore, Rows, handed, take_back, with};

/// One person's reactions to a message
#[repr(C)]
pub struct PeReaction {
    /// Their emoji, then their name: "👍❤️ Kate Kalda"
    pub text: *const c_char,
    /// When their last reaction came, in words
    pub when: *const c_char,
}

/// The reactions to a message; free with `pe_reactions_free`
pub struct PeReactions {
    rows: Rows<PeReaction>,
    chips: Vec<ReactionChip>,
}

/// The reactions to the message `folder`/`uid`, one a person, in the order they first reacted (none: an empty list)
///
/// # Safety
/// `core` must be live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_reactions(core: *const PeCore, folder: i64, uid: u64) -> *mut PeReactions {
    // SAFETY: as the caller guarantees
    let chips = unsafe {
        with(core, Vec::new(), |core| {
            core.reactions_of(folder, uid).unwrap_or_default()
        })
    };
    let rows = Rows::new(&chips, |chip, strings| PeReaction {
        text: strings.add(&chip.text),
        when: strings.add(&chip.when),
    });
    handed(PeReactions { rows, chips })
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_reactions_count(list: *const PeReactions) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|l| &l.rows))
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_reactions_get(list: *const PeReactions, index: usize) -> *const PeReaction {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|l| &l.rows), index)
}

/// # Safety
/// `list` must be NULL or a list not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_reactions_free(list: *mut PeReactions) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// Open Reaction Email: the newest email of the chip `index` written to a private file, its path (UTF-8, free with
/// `pe_string_free`) for the message window that opens files; NULL when it is not kept any longer
///
/// # Safety
/// `core` and `list` must be live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_reactions_email_file(
    core: *const PeCore,
    list: *const PeReactions,
    index: usize,
) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let Some(at) = (unsafe { list.as_ref() })
        .and_then(|l| l.chips.get(index))
        .and_then(|c| c.emails.last().copied())
    else {
        return null_mut();
    };
    // SAFETY: as the caller guarantees
    let path = unsafe { with(core, None, |core| core.reaction_email_file(at).ok().flatten()) };
    path.map_or(null_mut(), |path| {
        crate::into_c_string(path.to_string_lossy().into_owned())
    })
}

/// Show as Email: the emails of the chip `index` listed again for good, their reactions taken off the message
///
/// # Safety
/// `core` and `list` must be live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_reactions_show_as_email(core: *const PeCore, list: *const PeReactions, index: usize) {
    // SAFETY: as the caller guarantees
    let Some(chip) = (unsafe { list.as_ref() }).and_then(|l| l.chips.get(index)) else {
        return;
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, (), |core| {
            let _ = core.show_reactions_as_email(&chip.emails);
        })
    }
}
