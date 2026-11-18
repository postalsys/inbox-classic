//! Show in Message, tiles, the line of files past the budget, the tiles of a message still downloading, and the
//! printout (docs/attachment-preview-plan.md, PR 3)

use super::*;
use crate::list_load::tests::opened;
use base64::Engine;
use pe_preview::limits::MAX_PREVIEWS;
use std::sync::mpsc::Receiver;
use std::time::Instant;

const PNG_RED: [u8; 3] = [200, 30, 30];

fn png(width: u32, height: u32) -> Vec<u8> {
    let picture = image::RgbImage::from_pixel(width, height, image::Rgb(PNG_RED));
    let mut bytes = Vec::new();
    image::DynamicImage::ImageRgb8(picture)
        .write_to(&mut std::io::Cursor::new(&mut bytes), image::ImageFormat::Png)
        .unwrap();
    bytes
}

fn file(name: &str) -> Vec<u8> {
    let path = format!("{}/../pe-preview/tests/files/{name}", env!("CARGO_MANIFEST_DIR"));
    std::fs::read(&path).unwrap_or_else(|e| panic!("{path}: {e}"))
}

/// A message with these files attached (name, type, content)
fn message(files: &[(&str, &str, &[u8])]) -> Vec<u8> {
    let mut out = "From: Ann <ann@example.com>\r\nTo: a@example.com\r\nSubject: Files\r\nMIME-Version: 1.0\r\n\
                   Content-Type: multipart/mixed; boundary=b\r\n\r\n--b\r\nContent-Type: text/plain\r\n\r\n\
                   The text.\r\n"
        .to_string();
    for (name, mime, content) in files {
        out.push_str(&format!(
            "--b\r\nContent-Type: {mime}; name={name}\r\nContent-Disposition: attachment; filename={name}\r\n\
             Content-Transfer-Encoding: base64\r\n\r\n{}\r\n",
            base64::engine::general_purpose::STANDARD.encode(content)
        ));
    }
    out.push_str("--b--\r\n");
    out.into_bytes()
}

/// Message 1 as a window shows it once its files are all described
fn shown(core: &Core, events: &Receiver<Event>, inbox: FolderId) -> crate::MessageView {
    super::tests::settled(core, events, || core.message_view(inbox, 1, false).unwrap().unwrap())
}

fn states(view: &crate::MessageView) -> Vec<ShowInMessage> {
    view.attachments.iter().map(|a| a.show_in_message).collect()
}

/// The next event that `matches` says is the one, within 20 seconds
fn wait_for<T>(events: &Receiver<Event>, mut matches: impl FnMut(&Event) -> Option<T>) -> T {
    let until = Instant::now() + Duration::from_secs(20);
    loop {
        match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
            Ok(event) => {
                if let Some(found) = matches(&event) {
                    return found;
                }
            }
            Err(error) => panic!("no such event: {error}"),
        }
    }
}

/// The answer to `ask` once its event came
fn answered(core: &Core, events: &Receiver<Event>, ask: u64) -> Option<Arc<Picture>> {
    wait_for(events, |event| {
        matches!(event, Event::PreviewAnswered { ask: a } if *a == ask).then_some(())
    });
    core.preview_answer(ask)
}

/// Show in Message draws a file the setting leaves out (here every file, the setting off), and takes a drawn one out,
/// while the message is shown; never kept once no window shows it
#[test]
fn show_in_message_lasts_while_the_message_is_shown() {
    let dir = pe_testkit::TempDir::new("core-previews-show");
    let (core, inbox, events) = opened(&dir, 1);
    core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
    core.set_show_previews(false).unwrap();
    // PDF files off too: a PDF file asked for is drawn all the same
    core.set_pdf_previews(false).unwrap();
    let first = shown(&core, &events, inbox);
    let token = first.preview_token.clone().unwrap();
    assert_eq!(
        states(&first),
        [ShowInMessage::Off, ShowInMessage::Off, ShowInMessage::None]
    );
    // the text file has no such command, nor does an unknown view
    assert!(!core.preview_show(&token, 2, true));
    assert!(!core.preview_show("0123456789abcdef0123456789abcdef", 0, true));
    // already out: taking it out changes nothing
    assert!(!core.preview_show(&token, 0, false));

    assert!(core.preview_show(&token, 1, true));
    // the window builds the view again, then ends the one it showed
    let second = shown(&core, &events, inbox);
    core.previews_end(&token);
    let token = second.preview_token.clone().unwrap();
    assert!(
        second.document.contains(&format!("/pv/{token}-1-0")),
        "{}",
        second.document
    );
    assert!(!second.document.contains(&format!("/pv/{token}-0-0")));
    assert_eq!(
        states(&second),
        [ShowInMessage::Off, ShowInMessage::On, ShowInMessage::None]
    );
    // its page is drawn although PDF files are off
    let ask = core.preview_ask(&format!("/pv/{token}-1-0")).unwrap();
    assert_eq!(answered(&core, &events, ask).unwrap().width, 1240);

    // taken out again
    assert!(!core.preview_show(&token, 1, true));
    assert!(core.preview_show(&token, 1, false));
    let third = shown(&core, &events, inbox);
    core.previews_end(&token);
    let token = third.preview_token.clone().unwrap();
    assert!(!third.document.contains("/pv/"), "{}", third.document);
    assert_eq!(states(&third)[1], ShowInMessage::Off);

    // shown, then the message is left: shown again later, it is as the setting says
    assert!(core.preview_show(&token, 0, true));
    core.previews_end(&token);
    let later = shown(&core, &events, inbox);
    assert!(!later.document.contains("/pv/"), "{}", later.document);
}

/// With the setting on, Show in Message takes a file out, and a message's choices are its own
#[test]
fn a_file_taken_out_leaves_the_message() {
    let dir = pe_testkit::TempDir::new("core-previews-hide");
    let (core, inbox, events) = opened(&dir, 2);
    core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
    core.store().set_source(inbox, 2, &super::tests::message()).unwrap();
    let view = shown(&core, &events, inbox);
    let token = view.preview_token.clone().unwrap();
    assert_eq!(states(&view)[..2], [ShowInMessage::On, ShowInMessage::On]);
    assert!(core.preview_show(&token, 0, false));
    let again = shown(&core, &events, inbox);
    let new = again.preview_token.clone().unwrap();
    assert!(
        !again.document.contains(&format!("/pv/{new}-0-0")),
        "{}",
        again.document
    );
    assert!(again.document.contains(&format!("/pv/{new}-1-0")));
    // its link opens nothing anymore (the strip still has it)
    assert_eq!(
        core.preview_link(&format!("inboxclassic:attachment-{new}-0"), &new),
        None
    );
    // the other message is as the setting says
    let other = super::tests::settled(&core, &events, || core.message_view(inbox, 2, false).unwrap().unwrap());
    let other_token = other.preview_token.clone().unwrap();
    assert!(other.document.contains(&format!("/pv/{other_token}-0-0")));
}

/// A file that is not drawn is a tile that says why, opens as the strip does, and its Show in Message is greyed
#[test]
fn files_that_are_not_drawn_are_tiles() {
    let dir = pe_testkit::TempDir::new("core-previews-tiles");
    let (core, inbox, events) = opened(&dir, 1);
    let heic = file("photo.heic");
    let locked = file("encrypted-password.pdf");
    let source = message(&[
        ("photo.heic", "image/heic", &heic),
        ("locked.pdf", "application/pdf", &locked),
        // a picture by its name that is not one
        ("fake.png", "image/png", b"this is text, not a picture"),
        ("red.png", "image/png", &png(8, 8)),
    ]);
    core.store().set_source(inbox, 1, &source).unwrap();
    let view = shown(&core, &events, inbox);
    let token = view.preview_token.clone().unwrap();
    let document = &view.document;
    for words in [
        "HEIC pictures are not shown yet",
        "Protected by a password",
        "Can not be shown",
    ] {
        assert!(document.contains(words), "{words}: {document}");
    }
    assert!(document.contains(">HEIC</span>"), "{document}");
    assert_eq!(document.matches("<a class=\"t\"").count(), 3, "{document}");
    assert_eq!(document.matches("<img").count(), 1, "{document}");
    assert_eq!(
        states(&view),
        [
            ShowInMessage::Unavailable,
            ShowInMessage::Unavailable,
            ShowInMessage::Unavailable,
            ShowInMessage::On
        ]
    );
    // each tile opens its file; none has a picture to ask for, and Show in Message does nothing for it
    for attachment in 0..3 {
        let link = format!("inboxclassic:attachment-{token}-{attachment}");
        assert_eq!(core.preview_link(&link, &token), Some(attachment));
        assert_eq!(core.preview_ask(&format!("/pv/{token}-{attachment}-0")), None);
        assert!(!core.preview_show(&token, attachment, true));
    }
    // the text above, the tiles after it
    assert!(document.find("The text.").unwrap() < document.find("<section").unwrap());
}

/// Past the message's budget the files are left out, one line says how many, and Show in Message draws one of them
#[test]
fn files_past_the_budget_are_counted_and_can_be_shown() {
    let dir = pe_testkit::TempDir::new("core-previews-budget");
    let (core, inbox, events) = opened(&dir, 1);
    let picture = png(8, 8);
    let names: Vec<String> = (0..MAX_PREVIEWS + 3).map(|n| format!("p{n}.png")).collect();
    let files: Vec<(&str, &str, &[u8])> = names
        .iter()
        .map(|name| (name.as_str(), "image/png", picture.as_slice()))
        .collect();
    core.store().set_source(inbox, 1, &message(&files)).unwrap();
    let view = shown(&core, &events, inbox);
    let token = view.preview_token.clone().unwrap();
    assert_eq!(view.document.matches("<img").count(), MAX_PREVIEWS);
    assert!(
        view.document.contains("3 more files are in the list above"),
        "{}",
        view.document
    );
    let last = MAX_PREVIEWS + 2;
    assert_eq!(states(&view)[last], ShowInMessage::Off);
    assert_eq!(states(&view)[0], ShowInMessage::On);

    assert!(core.preview_show(&token, last, true));
    let again = shown(&core, &events, inbox);
    core.previews_end(&token);
    let token = again.preview_token.clone().unwrap();
    assert_eq!(again.document.matches("<img").count(), MAX_PREVIEWS + 1);
    assert!(
        again.document.contains("2 more files are in the list above"),
        "{}",
        again.document
    );
    assert_eq!(states(&again)[last], ShowInMessage::On);
    // drawn on a budget of its own
    let ask = core.preview_ask(&format!("/pv/{token}-{last}-0")).unwrap();
    assert_eq!(answered(&core, &events, ask).unwrap().width, 8);
}

/// A large message's text first: its pictures and PDF files are tiles that say they are on their way, with the sizes
/// its structure gives; once the whole message is here its view has the previews, after the same text
#[test]
fn a_message_still_downloading_has_tiles_until_it_is_here() {
    let dir = pe_testkit::TempDir::new("core-previews-downloading");
    let (core, inbox, events) = opened(&dir, 1);
    let whole = super::tests::message();
    // the text first: the files without their content
    let first = message(&[
        ("red.png", "image/png", b""),
        ("invoice.pdf", "application/pdf", b""),
        ("notes.txt", "text/plain", b""),
    ]);
    core.partials.insert(
        inbox,
        1,
        pe_sync::TextFirst {
            source: first,
            sizes: vec![2_400_000, 3_100_000, 12],
        },
    );
    let view = shown(&core, &events, inbox);
    let token = view.preview_token.clone().unwrap();
    let document = &view.document;
    assert_eq!(document.matches("Downloading…").count(), 2, "{document}");
    assert!(!document.contains("/pv/"), "{document}");
    assert!(document.contains(&crate::format_size(2_400_000)), "{document}");
    assert_eq!(
        states(&view),
        [
            ShowInMessage::Unavailable,
            ShowInMessage::Unavailable,
            ShowInMessage::None
        ]
    );
    assert!(!core.preview_show(&token, 0, true));
    assert!(document.find("The text.").unwrap() < document.find("<section").unwrap());

    // here: the same text, then the previews
    core.store().set_source(inbox, 1, &whole).unwrap();
    let view = shown(&core, &events, inbox);
    let token = view.preview_token.clone().unwrap();
    assert!(view.document.contains(&format!("/pv/{token}-0-0")), "{}", view.document);
    assert!(!view.document.contains("Downloading…"));
    assert_eq!(states(&view)[..2], [ShowInMessage::On, ShowInMessage::On]);
    assert!(view.document.find("See them.").unwrap() < view.document.find("<section").unwrap());
}

/// The printout has the pictures as `data:` addresses and a line for the PDF file; a view with no previews has none
/// to make
#[test]
fn the_printout_has_the_pictures_and_names_the_pdf_file() {
    let dir = pe_testkit::TempDir::new("core-previews-print");
    let (core, inbox, events) = opened(&dir, 1);
    core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
    let view = shown(&core, &events, inbox);
    let token = view.preview_token.clone().unwrap();
    // the pictures are drawn for the printout even when the reading pane never asked for them
    let request = core.print_start(&token).unwrap();
    wait_for(&events, |event| {
        matches!(event, Event::PrintReady { request: r } if *r == request).then_some(())
    });
    let printed = core.print_result(request).unwrap();
    // taken once
    assert_eq!(core.print_result(request), None);
    assert!(printed.contains("See them."), "{printed}");
    assert!(printed.contains("src=\"data:image/png;base64,iVBORw0KGgo"), "{printed}");
    assert!(
        printed.contains("invoice.pdf (1 page, ") && printed.contains("is not printed. Open it to print it."),
        "{printed}"
    );
    assert!(!printed.contains("/pv/") && !printed.contains(&token), "{printed}");
    assert!(printed.contains("img-src data:;"), "{printed}");
    assert!(pe_html::print_page(&printed).is_some());

    // no previews: nothing to start, the view's own document is printed
    assert_eq!(core.print_start("0123456789abcdef0123456789abcdef"), None);
    core.set_show_previews(false).unwrap();
    let plain = shown(&core, &events, inbox);
    assert_eq!(core.print_start(&plain.preview_token.unwrap()), None);
}
