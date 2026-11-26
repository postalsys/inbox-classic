//! Show in Message, the printout with pictures and the scroll scripts through the C API, as the apps call them: a
//! message file's view (no account needed), events at a C callback on worker threads

use std::ffi::{CStr, CString, c_char, c_void};
use std::ptr::{null, null_mut};
use std::sync::Mutex;
use std::sync::mpsc::{Receiver, Sender, channel};
use std::time::Duration;

use pe_ffi::*;
use pe_testkit::TempDir;

/// An event as the test reads it: its kind, `uid` and `detail`
type Told = (PeEventKind, u64, Option<String>);

unsafe extern "C" fn on_event(context: *mut c_void, event: *const PeEvent) {
    // SAFETY: the context is the Mutex<Sender> of the test, the event lives for the call
    let (sender, event) = unsafe { (&*(context as *const Mutex<Sender<Told>>), &*event) };
    let detail = (!event.detail.is_null()).then(|| text(event.detail));
    let _ = sender.lock().unwrap().send((event.kind, event.uid, detail));
}

fn text(pointer: *const c_char) -> String {
    assert!(!pointer.is_null());
    unsafe { CStr::from_ptr(pointer) }.to_str().unwrap().to_owned()
}

/// Takes a string the core handed over, and frees it
fn taken(pointer: *mut c_char) -> String {
    let out = text(pointer);
    unsafe { pe_string_free(pointer) };
    out
}

/// The next event of `kind` that `matches` its `uid` and `detail`
fn wait_for(events: &Receiver<Told>, kind: PeEventKind, matches: impl Fn(u64, Option<&str>) -> bool) {
    loop {
        let (told, uid, detail) = events
            .recv_timeout(Duration::from_secs(120))
            .expect("an event within 120 seconds");
        if told == kind && matches(uid, detail.as_deref()) {
            return;
        }
    }
}

fn wait(events: &Receiver<Told>, kind: PeEventKind, uid: u64) {
    wait_for(events, kind, |told, _| told == uid);
}

/// The view of the message file, its token and each attachment's Show in Message, as the window shows it once its
/// files are all described: while some are "Preparing..." (not described in time, as on a busy runner), built again
/// when `PE_EVENT_KIND_PREVIEWS_PREPARED` names its token, as the apps do, the view before it then ended
fn view(
    core: *const PeCore,
    file: &CString,
    events: &Receiver<Told>,
) -> (*mut PeMessageView, String, Vec<PeShowInMessage>) {
    let view = unsafe { pe_file_view(core, file.as_ptr(), false, null_mut()) };
    assert!(!view.is_null());
    let info = unsafe { &*pe_message_view_info(view) };
    let states = (0..info.attachment_count)
        .map(|index| unsafe { (*pe_message_view_attachment(view, index)).show_in_message })
        .collect();
    let token = text(info.preview_token);
    if !text(info.document).contains("Preparing…") {
        return (view, token, states);
    }
    wait_for(events, PeEventKind::PreviewsPrepared, |_, detail| {
        detail == Some(token.as_str())
    });
    let again = self::view(core, file, events);
    let c_token = CString::new(token).unwrap();
    unsafe { pe_previews_end(core, c_token.as_ptr()) };
    unsafe { pe_message_view_free(view) };
    again
}

#[test]
fn show_in_message_and_the_printout_through_the_c_api() {
    let dir = TempDir::new("ffi-previews");
    let path = CString::new(dir.path().join("store.db").to_str().unwrap()).unwrap();
    let (sender, events) = channel();
    let context = Box::into_raw(Box::new(Mutex::new(sender)));
    let core = unsafe {
        pe_core_open_with(
            path.as_ptr(),
            PE_OPEN_MEMORY_PASSWORDS,
            null(),
            Some(on_event),
            context.cast(),
        )
    };
    assert!(!core.is_null());
    let eml = dir.path().join("photo-and-pdf.eml");
    std::fs::write(
        &eml,
        include_bytes!("../../../../scripts/ui-e2e/previews/photo-and-pdf.eml"),
    )
    .unwrap();
    let file = CString::new(eml.to_str().unwrap()).unwrap();

    // both drawn: their items checked
    let (shown, token, states) = view(core, &file, &events);
    assert_eq!(states, [PeShowInMessage::On, PeShowInMessage::On]);
    let c_token = CString::new(token.clone()).unwrap();

    // Show in Message takes the PDF file out: the view built again has it unchecked
    assert!(unsafe { pe_preview_show(core, c_token.as_ptr(), 1, false) });
    assert!(!unsafe { pe_preview_show(core, c_token.as_ptr(), 1, false) });
    let (again, new_token, states) = view(core, &file, &events);
    unsafe { pe_previews_end(core, c_token.as_ptr()) };
    unsafe { pe_message_view_free(shown) };
    assert_eq!(states, [PeShowInMessage::On, PeShowInMessage::Off]);
    let document = text(unsafe { (*pe_message_view_info(again)).document });
    assert!(!document.contains(&format!("/pv/{new_token}-1-")), "{document}");
    // and draws it again
    let c_new = CString::new(new_token.clone()).unwrap();
    assert!(unsafe { pe_preview_show(core, c_new.as_ptr(), 1, true) });
    assert!(!unsafe { pe_preview_show(core, null(), 1, true) });
    // the printout (made after the views were built, so nothing is drawing while their sizes are read): the photo
    // as data
    let print = unsafe { pe_print_start(core, c_new.as_ptr()) };
    assert_ne!(print, 0);
    wait(&events, PeEventKind::PrintReady, print);
    let printed = taken(unsafe { pe_print_result(core, print) });
    assert!(printed.contains("src=\"data:image/jpeg;base64,"));
    // the view's PDF file was taken out of the message: not in the printout either
    assert!(!printed.contains("invoice-2026-118.pdf"));
    assert!(unsafe { pe_print_result(core, print) }.is_null());
    let page = taken(unsafe { pe_print_page(CString::new(printed).unwrap().as_ptr()) });
    assert!(page.contains("data:image/jpeg;base64,"));

    unsafe { pe_previews_end(core, c_new.as_ptr()) };
    unsafe { pe_message_view_free(again) };

    // a token of no view: no printout, no choice
    let unknown = CString::new("0123456789abcdef0123456789abcdef").unwrap();
    assert_eq!(unsafe { pe_print_start(core, unknown.as_ptr()) }, 0);
    assert_eq!(unsafe { pe_print_start(core, c"".as_ptr()) }, 0);

    unsafe { pe_core_close(core) };
    drop(unsafe { Box::from_raw(context) });
}
