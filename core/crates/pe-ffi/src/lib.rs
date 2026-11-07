//! The C API that the C++ app links (`pe_ffi.lib`, header `core/include/inbox_classic.h`).
//!
//! Rules for every export:
//! - Coarse calls on opaque handles; the C++ side never sees Rust types or does parsing of its own.
//! - Strings go both ways as UTF-8. Strings returned to C++ are allocated here and given back with `pe_string_free`.
//! - No panic crosses into C++: each export runs inside `guard`, a panic becomes an error result (NULL here). A crash
//!   on a malformed message would come back on every start, so aborting is not an option.

mod agents;
mod core;
mod selection;
mod texts;
#[cfg(windows)]
mod windows;

pub use agents::*;
pub use core::*;
pub use selection::*;
pub use texts::*;

use std::ffi::{CString, c_char};
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::ptr::null_mut;

/// Runs `f`, turning a panic into `None`.
fn guard<T>(f: impl FnOnce() -> T) -> Option<T> {
    catch_unwind(AssertUnwindSafe(f)).ok()
}

/// A C string of `text`. A NUL inside would cut it short, so it is replaced.
fn c_string(text: String) -> CString {
    let text = if text.contains('\0') {
        text.replace('\0', "\u{FFFD}")
    } else {
        text
    };
    CString::new(text).unwrap_or_default()
}

/// Hands a string to C++, to be freed with `pe_string_free`
fn into_c_string(text: String) -> *mut c_char {
    c_string(text).into_raw()
}

/// The version of the core, a static string that is not freed.
#[unsafe(no_mangle)]
pub extern "C" fn pe_version() -> *const c_char {
    concat!(env!("CARGO_PKG_VERSION"), "\0").as_ptr().cast()
}

/// Sanitizes `len` bytes of message HTML (UTF-8, invalid sequences are replaced) and returns a complete document
/// for the preview, or NULL on failure. Free the result with `pe_string_free`.
///
/// # Safety
/// `html` must point to `len` readable bytes; it may be NULL when `len` is 0.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_html_render(html: *const u8, len: usize, allow_remote_images: bool) -> *mut c_char {
    let bytes: &[u8] = match (html.is_null(), len) {
        (_, 0) => &[],
        (true, _) => return null_mut(),
        // SAFETY: the caller guarantees `len` readable bytes at `html`
        (false, _) => unsafe { std::slice::from_raw_parts(html, len) },
    };
    guard(|| {
        let options = pe_html::RenderOptions { allow_remote_images };
        into_c_string(pe_html::render_document(&String::from_utf8_lossy(bytes), &options))
    })
    .unwrap_or(null_mut())
}

/// The user help for `platform` (`windows`, `mac` or `linux`; NULL is the platform this was built for): one page
/// for every platform, with the parts of the others left out. Free with `pe_string_free`.
///
/// # Safety
/// `platform` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_help_page(platform: *const c_char) -> *mut c_char {
    let platform = if platform.is_null() {
        pe_html::Platform::current()
    } else {
        // SAFETY: as the caller guarantees
        let name = unsafe { std::ffi::CStr::from_ptr(platform) }.to_string_lossy();
        pe_html::Platform::from_name(&name).unwrap_or_else(pe_html::Platform::current)
    };
    guard(|| into_c_string(pe_html::help_page(platform))).unwrap_or(null_mut())
}

/// The WebKit content rules (WKContentRuleList JSON) of a web view that shows the core's documents: every load
/// blocked but the app's own `inboxclassic:` documents, `cid:` and `data:`, and with `allow_remote_images` the
/// message's pictures from the internet. Free with `pe_string_free`.
#[unsafe(no_mangle)]
pub extern "C" fn pe_webkit_content_rules(allow_remote_images: bool) -> *mut c_char {
    guard(|| into_c_string(pe_html::webkit_content_rules(allow_remote_images))).unwrap_or(null_mut())
}

/// What the reading pane shows instead of a message (`pe_reader_page`)
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeReaderState {
    /// No message is selected
    NoMessage = 0,
    /// The message selected is being downloaded (after `pe_message_open`, before `MessageReady`)
    Downloading = 1,
    /// It could not be downloaded (`MessageFailed`): `failure` and `reason` are the event's
    Failed = 2,
}

/// The page of the reading pane for `state`, the same words on every platform: a document to show as the messages
/// are shown. `failure` and `reason` (NULL for none) are those of `MessageFailed`, for `Failed`. Free with
/// `pe_string_free`.
///
/// # Safety
/// `reason` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_reader_page(
    state: PeReaderState,
    failure: core::PeFailureKind,
    reason: *const c_char,
) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let reason = (!reason.is_null()).then(|| unsafe { std::ffi::CStr::from_ptr(reason) }.to_string_lossy());
    guard(|| {
        let state = match state {
            PeReaderState::NoMessage => pe_core::ReaderState::NoMessage,
            PeReaderState::Downloading => pe_core::ReaderState::Downloading,
            PeReaderState::Failed => pe_core::ReaderState::Failed {
                kind: failure.into(),
                reason: reason.as_deref().unwrap_or_default(),
            },
        };
        into_c_string(pe_core::reader_page(state))
    })
    .unwrap_or(null_mut())
}

/// What the windows say beside Try Again over a message that could not be downloaded. Free with `pe_string_free`.
#[unsafe(no_mangle)]
pub extern "C" fn pe_retry_note() -> *mut c_char {
    guard(|| into_c_string(pe_core::retry_note())).unwrap_or(null_mut())
}

/// A size as the windows show it (`512 bytes`, `13 KB`, `2.4 MB`). Free with `pe_string_free`.
#[unsafe(no_mangle)]
pub extern "C" fn pe_format_size(bytes: u64) -> *mut c_char {
    guard(|| into_c_string(pe_core::format_size(bytes))).unwrap_or(null_mut())
}

/// The page of the Print window for a message document of the core (`PeMessageInfo.document`): the same document
/// with the core's own script that says "done" once the print preview is closed. NULL for a document
/// that is not one of the core's. Free with `pe_string_free`.
///
/// # Safety
/// `document` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_print_page(document: *const c_char) -> *mut c_char {
    if document.is_null() {
        return null_mut();
    }
    // SAFETY: as the caller guarantees
    let document = unsafe { std::ffi::CStr::from_ptr(document) }.to_string_lossy();
    guard(|| pe_html::print_page(&document).map_or(null_mut(), into_c_string)).unwrap_or(null_mut())
}

/// The page of the compose window's editor, with the quoted message `quote` (from the draft, or NULL for a new
/// message) folded behind "..." when `folded`, and `body` (the draft's, or NULL) as what is written so far. NULL on
/// failure. Free with `pe_string_free`.
///
/// # Safety
/// `quote` and `body` must be NULL or NUL-terminated strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_editor_document(quote: *const c_char, folded: bool, body: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let text = |p: *const c_char| (!p.is_null()).then(|| unsafe { std::ffi::CStr::from_ptr(p) }.to_string_lossy());
    let (quote, body) = (text(quote), text(body));
    guard(|| {
        into_c_string(pe_html::editor_document(
            quote.as_deref(),
            folded,
            body.as_deref().unwrap_or_default(),
        ))
    })
    .unwrap_or(null_mut())
}

/// The picture file at `path` (UTF-8) as a `data:` URI for the editor's Insert Picture, NULL when it can not be
/// read or is not a PNG, JPEG or GIF picture (by its content, not its name). Free with `pe_string_free`.
///
/// # Safety
/// `path` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_picture_uri(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return null_mut();
    }
    // SAFETY: as the caller guarantees
    let Ok(path) = unsafe { std::ffi::CStr::from_ptr(path) }.to_str() else {
        return null_mut();
    };
    guard(|| {
        // a file dropped on the text may be anything: its size and first bytes are looked at before it is read
        use std::io::Read;
        let mut file = std::fs::File::open(path).ok()?;
        if file.metadata().ok()?.len() > pe_html::PICTURE_FILE_LIMIT as u64 {
            return None;
        }
        let mut head = Vec::with_capacity(pe_html::PICTURE_HEAD);
        (&mut file)
            .take(pe_html::PICTURE_HEAD as u64)
            .read_to_end(&mut head)
            .ok()?;
        pe_html::picture_type(&head)?;
        let data = std::fs::read(path).ok()?;
        pe_html::picture_uri(&data).map(into_c_string)
    })
    .flatten()
    .unwrap_or(null_mut())
}

/// Frees a string returned by this library. NULL is ignored.
///
/// # Safety
/// `text` must be NULL or a string from this library that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_string_free(text: *mut c_char) {
    if !text.is_null() {
        // SAFETY: the caller guarantees it came from `into_c_string` and is freed once
        drop(unsafe { CString::from_raw(text) });
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CStr;

    #[test]
    fn editor_pages_and_pictures() {
        let quote = CString::new("<p>old</p>").unwrap();
        let page = unsafe { pe_editor_document(quote.as_ptr(), true, std::ptr::null()) };
        let text = unsafe { CStr::from_ptr(page) }.to_str().unwrap().to_string();
        unsafe { pe_string_free(page) };
        assert!(
            text.contains("contenteditable") && text.contains("data-folded=\"1\""),
            "{text}"
        );
        let page = unsafe { pe_editor_document(std::ptr::null(), false, std::ptr::null()) };
        assert!(!unsafe { CStr::from_ptr(page) }.to_str().unwrap().contains("<iframe"));
        unsafe { pe_string_free(page) };

        let dir = std::env::temp_dir().join(format!("pe-picture-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let gif = dir.join("x.txt");
        std::fs::write(&gif, b"GIF89a").unwrap();
        let path = CString::new(gif.to_str().unwrap()).unwrap();
        let uri = unsafe { pe_picture_uri(path.as_ptr()) };
        assert_eq!(
            unsafe { CStr::from_ptr(uri) }.to_str().unwrap(),
            "data:image/gif;base64,R0lGODlh"
        );
        unsafe { pe_string_free(uri) };
        // a file larger than a picture may be is refused by its size, before it is read
        let big = dir.join("big.png");
        let file = std::fs::File::create(&big).unwrap();
        file.set_len(pe_html::PICTURE_FILE_LIMIT as u64 + 1).unwrap();
        drop(file);
        let mut data = std::fs::read(&big).unwrap();
        data[..8].copy_from_slice(b"\x89PNG\r\n\x1a\n");
        std::fs::write(&big, data).unwrap();
        let path = CString::new(big.to_str().unwrap()).unwrap();
        assert!(unsafe { pe_picture_uri(path.as_ptr()) }.is_null());
        std::fs::write(&gif, b"<svg>").unwrap();
        assert!(unsafe { pe_picture_uri(path.as_ptr()) }.is_null());
        let missing = CString::new(dir.join("missing").to_str().unwrap()).unwrap();
        assert!(unsafe { pe_picture_uri(missing.as_ptr()) }.is_null());
        assert!(unsafe { pe_picture_uri(std::ptr::null()) }.is_null());
        std::fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn tells_the_cards_link_from_the_messages() {
        use crate::core::{PeReaderLink, pe_reader_link};
        let link = |uri: &str| unsafe { pe_reader_link(CString::new(uri).unwrap().as_ptr()) };
        assert_eq!(link(pe_html::BOUNCED_MESSAGE_LINK), PeReaderLink::BouncedMessage);
        assert_eq!(link("https://example.com/"), PeReaderLink::Other);
        assert_eq!(link("mailto:a@example.com"), PeReaderLink::Other);
        assert_eq!(unsafe { pe_reader_link(std::ptr::null()) }, PeReaderLink::Other);
    }

    #[test]
    fn version_matches_the_crate() {
        let version = unsafe { CStr::from_ptr(pe_version()) };
        assert_eq!(version.to_str().unwrap(), env!("CARGO_PKG_VERSION"));
    }

    #[test]
    fn renders_and_frees() {
        let html = b"<p>hi</p><script>x</script>";
        let out = unsafe { pe_html_render(html.as_ptr(), html.len(), false) };
        assert!(!out.is_null());
        let text = unsafe { CStr::from_ptr(out) }.to_str().unwrap().to_owned();
        unsafe { pe_string_free(out) };
        assert!(text.contains("<p>hi</p>"));
        assert!(!text.contains("<script"));
    }

    #[test]
    fn nul_does_not_cut_strings() {
        let out = into_c_string("a\0b".to_owned());
        assert_eq!(unsafe { CStr::from_ptr(out) }.to_str().unwrap(), "a\u{FFFD}b");
        unsafe { pe_string_free(out) };
    }

    #[test]
    fn null_input() {
        assert!(unsafe { pe_html_render(std::ptr::null(), 5, false) }.is_null());
        let out = unsafe { pe_html_render(std::ptr::null(), 0, false) };
        assert!(!out.is_null());
        unsafe { pe_string_free(out) };
        unsafe { pe_string_free(null_mut()) };
        // a print page only from a document of the core's
        assert!(unsafe { pe_print_page(std::ptr::null()) }.is_null());
        let foreign = CString::new("<html>not ours</html>").unwrap();
        assert!(unsafe { pe_print_page(foreign.as_ptr()) }.is_null());
    }
}
