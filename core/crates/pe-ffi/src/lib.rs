//! The C API that the C++ app links (`pe_ffi.lib`, header `core/include/postal_express.h`).
//!
//! Rules for every export:
//! - Coarse calls on opaque handles; the C++ side never sees Rust types or does parsing of its own.
//! - Strings go both ways as UTF-8. Strings returned to C++ are allocated here and given back with `pe_string_free`.
//! - No panic crosses into C++: each export runs inside `guard`, a panic becomes an error result (NULL here). A crash
//!   on a malformed message would come back on every start, so aborting is not an option.

mod core;

pub use core::*;

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

/// The page of the compose window's editor, with the quoted message `quote` (from the draft, or NULL for a new
/// message) folded behind "..." when `folded`. NULL on failure. Free with `pe_string_free`.
///
/// # Safety
/// `quote` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_editor_document(quote: *const c_char, folded: bool) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let quote = if quote.is_null() {
        None
    } else {
        Some(unsafe { std::ffi::CStr::from_ptr(quote) }.to_string_lossy())
    };
    guard(|| into_c_string(pe_html::editor_document(quote.as_deref(), folded))).unwrap_or(null_mut())
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
        let page = unsafe { pe_editor_document(quote.as_ptr(), true) };
        let text = unsafe { CStr::from_ptr(page) }.to_str().unwrap().to_string();
        unsafe { pe_string_free(page) };
        assert!(
            text.contains("contenteditable") && text.contains("data-folded=\"1\""),
            "{text}"
        );
        let page = unsafe { pe_editor_document(std::ptr::null(), false) };
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
        std::fs::write(&gif, b"<svg>").unwrap();
        assert!(unsafe { pe_picture_uri(path.as_ptr()) }.is_null());
        let missing = CString::new(dir.join("missing").to_str().unwrap()).unwrap();
        assert!(unsafe { pe_picture_uri(missing.as_ptr()) }.is_null());
        assert!(unsafe { pe_picture_uri(std::ptr::null()) }.is_null());
        std::fs::remove_dir_all(&dir).unwrap();
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
    }
}
