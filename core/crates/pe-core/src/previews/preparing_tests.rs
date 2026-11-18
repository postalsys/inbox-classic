//! Files not described in time: "Preparing…" tiles, the window told once they are, and the view built again with
//! their previews; never told for a view that ended

use super::*;
use crate::list_load::tests::opened;
use std::sync::mpsc::Receiver;
use std::time::Instant;

/// pe-preview's engine behind a gate: nothing is read until the test opens it, as on a busy computer
#[derive(Default)]
struct Gate {
    open: Mutex<bool>,
    opened: Condvar,
}

impl Gate {
    fn open(&self) {
        *unpoisoned(&self.open) = true;
        self.opened.notify_all();
    }
}

impl pe_preview::Engine for Gate {
    fn run(
        &self,
        kind: pe_preview::Kind,
        file: &Arc<Vec<u8>>,
        pages: &[usize],
        budget: u64,
        emit: &mut dyn FnMut(pe_preview::Step) -> bool,
    ) {
        let mut open = unpoisoned(&self.open);
        while !*open {
            open = self.opened.wait(open).unwrap_or_else(|p| p.into_inner());
        }
        drop(open);
        pe_preview::Real.run(kind, file, pages, budget, emit);
    }
}

/// A core whose previews wait for the gate, with message 1 (a PNG, a PDF file and a text file) in its Inbox
fn gated(dir: &pe_testkit::TempDir) -> (Arc<Core>, FolderId, Receiver<Event>, Arc<Gate>) {
    let (core, inbox, events) = opened(dir, 1);
    let gate = Arc::new(Gate::default());
    assert!(core.previews.engine.set(gate.clone()).is_ok());
    core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
    (core, inbox, events, gate)
}

fn states(view: &crate::MessageView) -> Vec<ShowInMessage> {
    view.attachments.iter().map(|a| a.show_in_message).collect()
}

/// A view whose files were not described in time shows them as "Preparing…" (greyed in the strip, not counted as
/// files past the budget); once they are, the window is told once, and the view built again draws them
#[test]
fn files_not_described_in_time_are_preparing_until_they_are() {
    let dir = pe_testkit::TempDir::new("core-previews-preparing");
    let (core, inbox, events, gate) = gated(&dir);
    let view = core.message_view(inbox, 1, false).unwrap().unwrap();
    let token = view.preview_token.clone().unwrap();
    let preparing = tr(Text::PreviewTilePreparing);
    assert!(view.preparing);
    assert_eq!(view.document.matches(&preparing).count(), 2, "{}", view.document);
    assert!(!view.document.contains("/pv/"), "{}", view.document);
    assert!(!view.document.contains("more file"), "{}", view.document);
    assert_eq!(
        states(&view),
        [
            ShowInMessage::Unavailable,
            ShowInMessage::Unavailable,
            ShowInMessage::None
        ]
    );
    // a tile opens its file as the strip does, and has no picture to ask for
    let link = format!("inboxclassic:attachment-{token}-1");
    assert_eq!(core.preview_link(&link, &token), Some(1));
    assert_eq!(core.preview_ask(&format!("/pv/{token}-0-0")), None);

    gate.open();
    super::tests::prepared(&events, &token);
    // built again, then the view before it ended, as the windows do
    let again = core.message_view(inbox, 1, false).unwrap().unwrap();
    core.previews_end(&token);
    let new = again.preview_token.clone().unwrap();
    assert!(!again.preparing);
    assert!(!again.document.contains(&preparing), "{}", again.document);
    assert!(
        again
            .document
            .contains(&format!("src=\"/pv/{new}-0-0\" width=\"64\" height=\"32\"")),
        "{}",
        again.document
    );
    assert!(again.document.contains(&format!("/pv/{new}-1-0")), "{}", again.document);
    assert_eq!(
        states(&again),
        [ShowInMessage::On, ShowInMessage::On, ShowInMessage::None]
    );
    let ask = core.preview_ask(&format!("/pv/{new}-0-0")).unwrap();
    let until = Instant::now() + Duration::from_secs(60);
    loop {
        match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
            Ok(Event::PreviewAnswered { ask: answered }) if answered == ask => break,
            // once a view
            Ok(Event::PreviewsPrepared { token: of }) => panic!("told again for {of}"),
            Ok(_) => {}
            Err(error) => panic!("not answered: {error}"),
        }
    }
    assert_eq!(core.preview_answer(ask).unwrap().width, 64);
}

/// A view that ended before its files were described is not told of them
#[test]
fn a_view_that_ended_is_not_told() {
    let dir = pe_testkit::TempDir::new("core-previews-preparing-ended");
    let (core, inbox, events, gate) = gated(&dir);
    let view = core.message_view(inbox, 1, false).unwrap().unwrap();
    assert!(view.preparing);
    let token = view.preview_token.clone().unwrap();
    core.previews_end(&token);
    gate.open();
    // queued after the view's descriptions: once it is done, they are too
    let request = core.previews_start(inbox, 1, vec![0, 1]).unwrap();
    let until = Instant::now() + Duration::from_secs(60);
    let done = |a| core.preview_file(request, a).is_some_and(|file| file.done);
    while !(done(0) && done(1)) {
        match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
            Ok(Event::PreviewsPrepared { token: of }) => panic!("told of {of}, which ended"),
            Ok(_) => {}
            Err(error) => panic!("previews not done: {error}"),
        }
    }
    let told: Vec<Event> = events.try_iter().collect();
    assert!(
        !told.iter().any(|event| matches!(event, Event::PreviewsPrepared { .. })),
        "{told:?}"
    );
}

/// A message file's window is told the same way, and its view built again has the previews
#[test]
fn a_message_file_s_view_is_told_too() {
    let dir = pe_testkit::TempDir::new("core-previews-preparing-file");
    let (core, _inbox, events, gate) = gated(&dir);
    let path = dir.path().join("photos.eml");
    std::fs::write(&path, super::tests::message()).unwrap();
    let view = core.file_view(&path, false).unwrap();
    assert!(view.preparing);
    let token = view.preview_token.clone().unwrap();
    gate.open();
    super::tests::prepared(&events, &token);
    let again = core.file_view(&path, false).unwrap();
    core.previews_end(&token);
    let new = again.preview_token.clone().unwrap();
    assert!(!again.preparing);
    assert!(again.document.contains(&format!("/pv/{new}-1-0")), "{}", again.document);
}

/// A PNG picture of `width` by `height`, base64 as a message carries it
fn png_base64(width: u32, height: u32) -> String {
    use base64::Engine;
    let picture = image::RgbImage::from_pixel(width, height, image::Rgb([200, 30, 30]));
    let mut bytes = Vec::new();
    image::DynamicImage::ImageRgb8(picture)
        .write_to(&mut std::io::Cursor::new(&mut bytes), image::ImageFormat::Png)
        .unwrap();
    base64::engine::general_purpose::STANDARD.encode(bytes)
}

/// What a view had described late is taken by another view of the message only for the same bytes: a view with
/// another file at that place (the message read decrypted rather than as it is, or changed) reads its own
#[test]
fn a_late_description_is_taken_only_for_its_own_file() {
    let dir = pe_testkit::TempDir::new("core-previews-preparing-own");
    let (core, inbox, events, gate) = gated(&dir);
    let view = core.message_view(inbox, 1, false).unwrap().unwrap();
    assert!(view.preparing);
    let token = view.preview_token.clone().unwrap();
    gate.open();
    super::tests::prepared(&events, &token);
    // still shown, its late descriptions kept; the next view has another picture first
    let message = String::from_utf8(super::tests::message()).unwrap();
    let other = message.replace(&png_base64(64, 32), &png_base64(48, 24));
    assert_ne!(other, message);
    core.store().set_source(inbox, 1, other.as_bytes()).unwrap();
    let again = core.message_view(inbox, 1, false).unwrap().unwrap();
    let new = again.preview_token.clone().unwrap();
    assert!(
        again
            .document
            .contains(&format!("src=\"/pv/{new}-0-0\" width=\"48\" height=\"24\"")),
        "{}",
        again.document
    );
    core.previews_end(&token);
    core.previews_end(&new);
}
