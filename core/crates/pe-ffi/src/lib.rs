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
