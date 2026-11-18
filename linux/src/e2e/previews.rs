//! Step 8b of the UI test: pictures and PDF files after a message's text. The three messages of
//! `scripts/ui-e2e/previews/` and one with many pictures (made here) put in the Inbox over ImapKit's API: the previews
//! answered by the document server once the core drew them, read back with the app's own script (page scripts off);
//! a click on one opening the file as the strip does; the long PDF file's link; a message window; the two switches of
//! Preferences; PDF previews off as after a crash; the tiles, Show in Message and printing (`preview_tiles.rs`); the
//! dark look (a pixel of the photo's sky read back); a narrow window and the words in German for the review of the
//! look. The messages are taken away at the end.

use super::preview_tiles::{TILES, TILES_ID};
use super::steps::{document_text, folder_id, open_by_subject};
use super::*;
use crate::attachments::take_opened;

const PHOTO: &str = "Photos and the invoice";
const LONG: &str = "The kettle's manual";
const MANY: &str = "Pictures from the summer party";
const PHOTO_ID: &str = "<previews-1@example.com>";
const LONG_ID: &str = "<previews-2@example.com>";
const MANY_ID: &str = "<previews-many@ui-test.example>";
/// How many pictures the message with many has; the core shows 20 at most
const PICTURES: usize = 24;
const LONG_NAME: &str =
    "Das Feuerwerk um Mitternacht vom Steg aus gesehen, mit allen Gaesten des Sommerfests am See im Hintergrund.png";

fn fixture(name: &str) -> String {
    let path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../scripts/ui-e2e/previews")
        .join(name);
    std::fs::read_to_string(path).unwrap_or_default()
}

/// The bytes of the attachment `name` of a fixture, decoded from its base64
fn attachment_bytes(raw: &str, name: &str) -> Vec<u8> {
    let header = format!("filename=\"{name}\"");
    let Some(start) = raw.find(&header) else {
        return Vec::new();
    };
    let rest = &raw[start..];
    let body = rest
        .find("\n\n")
        .or_else(|| rest.find("\r\n\r\n"))
        .map(|at| &rest[at..]);
    let Some(body) = body else { return Vec::new() };
    let body = body.trim_start();
    let end = body.find("\n--").unwrap_or(body.len());
    base64::engine::general_purpose::STANDARD
        .decode(body[..end].replace(['\r', '\n'], ""))
        .unwrap_or_default()
}

/// A picture of the party, a PNG of `width` by `height` in a color of its own
fn party_png(index: usize, width: i32, height: i32) -> Vec<u8> {
    use gtk::cairo;
    let Ok(mut surface) = cairo::ImageSurface::create(cairo::Format::ARgb32, width, height) else {
        return Vec::new();
    };
    if let Ok(cr) = cairo::Context::new(&surface) {
        let hue = index as f64 / PICTURES as f64;
        cr.set_source_rgb(0.25 + 0.6 * hue, 0.45, 0.85 - 0.6 * hue);
        let _ = cr.paint();
        cr.set_source_rgb(1.0, 1.0, 1.0);
        cr.select_font_face("Sans", cairo::FontSlant::Normal, cairo::FontWeight::Bold);
        cr.set_font_size(f64::from(height) / 5.0);
        cr.move_to(f64::from(width) / 10.0, f64::from(height) / 2.0);
        let _ = cr.show_text(&format!("{}", index + 1));
    }
    surface.flush();
    let stride = surface.stride() as usize;
    let Ok(data) = surface.data() else { return Vec::new() };
    let bytes = glib::Bytes::from(&*data);
    let texture = gdk::MemoryTexture::new(width, height, gdk::MemoryFormat::B8g8r8a8Premultiplied, &bytes, stride);
    texture.save_to_png_bytes().to_vec()
}

/// The message with more pictures than the core shows, the first with a long name, some tall
fn many_raw() -> String {
    let mut parts = String::new();
    for index in 0..PICTURES {
        let (width, height) = if index % 5 == 2 { (300, 420) } else { (640, 400) };
        let name = if index == 0 {
            LONG_NAME.to_string()
        } else {
            format!("party-{:02}.png", index + 1)
        };
        parts.push_str(&format!(
            "--many\r\nContent-Type: image/png; name=\"{name}\"\r\nContent-Disposition: attachment; filename=\"{name}\"\r\n\
             Content-Transfer-Encoding: base64\r\n\r\n{}\r\n",
            base64::engine::general_purpose::STANDARD.encode(party_png(index, width, height))
        ));
    }
    format!(
        "From: Maria Example <maria@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: {MANY}\r\n\
         Message-ID: {MANY_ID}\r\nDate: {}\r\nMIME-Version: 1.0\r\nContent-Type: multipart/mixed; boundary=\"many\"\r\n\r\n\
         --many\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nAll the pictures from Saturday, one for each of you.\r\n\
         {parts}--many--\r\n",
        steps::date_now(-6),
    )
}

/// The value of the app's own `script` in `view` (the page's scripts stay off), empty when it could not run
pub(super) async fn run_script(view: &webkit::WebView, script: &str) -> String {
    match view.evaluate_javascript_future(script, None, None).await {
        Ok(value) => value.to_str().to_string(),
        Err(_) => String::new(),
    }
}

/// The previews' pictures: how many, how many have come (loaded, with a size), and the top of each caption
const LOADED: &str = "(function(){var s=document.querySelector('section[class^=\"pe-att-\"]');if(!s)return 'none';\
    var i=Array.prototype.slice.call(s.querySelectorAll('img'));\
    var c=Array.prototype.slice.call(s.querySelectorAll('figcaption')).map(function(f){\
    return Math.round(f.getBoundingClientRect().top+window.scrollY)}).join(',');\
    return i.length+'/'+i.filter(function(x){return x.complete&&x.naturalWidth>0}).length+'/'+c})()";

/// Pictures (all of them) and how many have come, with the captions' places
#[derive(Debug, Default, PartialEq)]
pub(super) struct Loaded {
    pub(super) pictures: usize,
    pub(super) come: usize,
    captions: String,
}

async fn loaded(view: &webkit::WebView) -> Option<Loaded> {
    let value = run_script(view, LOADED).await;
    let mut parts = value.splitn(3, '/');
    Some(Loaded {
        pictures: parts.next()?.parse().ok()?,
        come: parts.next()?.parse().ok()?,
        captions: parts.next()?.to_string(),
    })
}

/// Waits until the `count` previews of `view` have all come; what was seen last
pub(super) async fn all_come(view: &webkit::WebView, count: usize, seconds: u64) -> Option<Loaded> {
    let deadline = Instant::now() + Duration::from_secs(seconds);
    let mut last = None;
    while Instant::now() < deadline {
        let now = loaded(view).await;
        if now.as_ref().is_some_and(|l| l.pictures == count && l.come == count) {
            return now;
        }
        last = now;
        pause(250).await;
    }
    last
}

/// The addresses of the pictures in the page shown, as the page has them
async fn sources(view: &webkit::WebView) -> String {
    run_script(
        view,
        "Array.prototype.slice.call(document.images).map(function(i){return i.getAttribute('src')}).join(' ')",
    )
    .await
}

/// The link of a file's previews clicked in the page (`n`: the file's place among the previews; `more`: its "Open to
/// see all" link), as the user clicks it
async fn click_preview(view: &webkit::WebView, n: usize, more: bool) -> bool {
    let selector = if more { "a.m" } else { "figure > a:not(.m)" };
    let script = format!(
        "(function(){{var s=document.querySelector('section[class^=\"pe-att-\"]');if(!s)return 'no';\
         var a=s.querySelectorAll('{selector}')[{n}];if(!a)return 'no';a.click();return 'yes'}})()"
    );
    run_script(view, &script).await == "yes"
}

/// The opened files the hook recorded within `seconds`
pub(super) async fn opened(seconds: u64) -> Vec<PathBuf> {
    let mut found = Vec::new();
    wait_until(seconds, || {
        found.extend(take_opened());
        !found.is_empty()
    })
    .await;
    found
}

pub(super) async fn previews(d: &Driver) {
    d.step("pictures and PDF files in the message");
    let main = shell().main();
    let Some(inbox) = wait_for(30, || folder_id("Inbox")).await else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    let photo_raw = fixture("photo-and-pdf.eml");
    let added = [
        photo_raw.clone(),
        fixture("long-pdf.eml"),
        many_raw(),
        fixture("tiles.eml"),
    ]
    .iter()
    .all(|raw| d.add_message(raw, &["\\Seen"]).is_ok());
    run_command(Command::Sync);
    select_folder("Inbox");
    let arrived = wait_until(30, || {
        let listed = listed_in_folder(inbox, 0, 500);
        [PHOTO, LONG, MANY, TILES]
            .iter()
            .all(|subject| listed.iter().any(|m| m.info.subject == *subject))
    })
    .await;
    d.check(
        added && arrived,
        "the messages with pictures and PDF files are in the Inbox",
    );
    take_opened();
    d.check(
        shell().core.show_previews() && shell().core.pdf_previews().unwrap_or(false),
        "previews of pictures and PDF files are on out of the box",
    );

    let view = main.reader.preview.view.clone();
    open_by_subject(inbox, PHOTO).await;
    // as soon as the page is there, before its pictures have all come: where the captions are
    let mut first = None;
    for _ in 0..100 {
        first = loaded(&view).await;
        if first.is_some() {
            break;
        }
        pause(50).await;
    }
    let come = all_come(&view, 4, 20).await;
    d.check(
        come.as_ref().is_some_and(|l| l.pictures == 4 && l.come == 4),
        &format!("the photo and the invoice's three pages show after the text ({come:?})"),
    );
    let first = first.unwrap_or_default();
    d.check(
        first.captions.is_empty() || come.as_ref().is_some_and(|l| l.captions == first.captions),
        &format!(
            "the captions stay where they were while the pictures come ({} of {} had come first: {} then {})",
            first.come,
            first.pictures,
            first.captions,
            come.as_ref().map(|l| l.captions.as_str()).unwrap_or_default()
        ),
    );
    let text = document_text(&main.reader.preview.shown());
    d.check(
        text.contains("lake.jpg") && text.contains("invoice-2026-118.pdf") && text.contains("3 pages, "),
        "each file's name and size are above it, the invoice's with its 3 pages",
    );
    let strip = main.reader.strip.shown();
    d.check(
        strip.len() == 2 && strip[0].name == "lake.jpg" && strip[1].name == "invoice-2026-118.pdf",
        &format!("the strip still lists both files ({strip:?})"),
    );
    let alt = run_script(
        &view,
        "Array.prototype.slice.call(document.querySelectorAll('img.p')).map(function(i){return i.alt}).join('|')",
    )
    .await;
    d.check(
        alt.starts_with("invoice-2026-118.pdf, page 1 of 3"),
        &format!("a screen reader hears each page's file and number ({alt})"),
    );
    d.shot(main.window(), "read-30-previews").await;

    // the photo clicked: the file handed over is byte for byte what was sent
    let clicked = click_preview(&view, 0, false).await;
    let files = opened(10).await;
    d.check(
        clicked
            && files.len() == 1
            && files[0].file_name().is_some_and(|n| n == "lake.jpg")
            && std::fs::read(&files[0]).is_ok_and(|bytes| bytes == attachment_bytes(&photo_raw, "lake.jpg")),
        &format!("clicking the photo opens it, byte for byte what was sent ({files:?})"),
    );
    keyboard(d, &view).await;

    long_pdf(d, inbox).await;
    in_window(d, inbox).await;
    switches(d, inbox).await;
    pdf_off(d, inbox).await;
    preview_tiles::tiles(d, inbox).await;
    preview_tiles::show_in_message(d, inbox, PHOTO).await;
    preview_tiles::printing(d, inbox, PHOTO).await;
    many(d, inbox).await;
    dark(d, inbox).await;
    german(d, inbox).await;
    remove_messages(d, inbox).await;
}

/// Tab reaches each file once (one link a file), and Enter on the invoice's opens it
async fn keyboard(d: &Driver, view: &webkit::WebView) {
    let stops = run_script(
        view,
        "(function(){var s=document.querySelector('section[class^=\"pe-att-\"]');if(!s)return '';\
         return Array.prototype.slice.call(s.querySelectorAll('a')).filter(function(a){return a.tabIndex>=0})\
         .map(function(a){return a.querySelectorAll('img').length}).join(',')})()",
    )
    .await;
    d.check(
        stops == "1,3",
        &format!("Tab stops once at each file, the invoice's pages in one stop ({stops})"),
    );
    // the invoice's link focused as Tab leaves it, and Enter: what a link does on Enter is its click
    let focused = run_script(
        view,
        "(function(){var a=document.querySelectorAll('section[class^=\"pe-att-\"] figure > a')[1];a.focus();\
         if(document.activeElement!==a)return 'no';a.click();return 'yes'})()",
    )
    .await;
    let files = opened(10).await;
    d.check(
        focused == "yes" && files.len() == 1 && files[0].file_name().is_some_and(|n| n == "invoice-2026-118.pdf"),
        &format!("Enter on the invoice's previews opens the invoice ({files:?})"),
    );
}

/// The manual: its first five pages, then the link that opens it
async fn long_pdf(d: &Driver, inbox: i64) {
    let main = shell().main();
    let view = main.reader.preview.view.clone();
    open_by_subject(inbox, LONG).await;
    let come = all_come(&view, 5, 20).await;
    let text = document_text(&main.reader.preview.shown());
    d.check(
        come.as_ref().is_some_and(|l| l.pictures == 5 && l.come == 5) && text.contains("Open to see all 12 pages"),
        &format!("the manual shows its first five pages and \"Open to see all 12 pages\" ({come:?})"),
    );
    run_script(&view, "window.scrollTo(0, document.body.scrollHeight)").await;
    d.shot(main.window(), "read-30c-previews-long").await;
    let clicked = click_preview(&view, 0, true).await;
    let files = opened(10).await;
    d.check(
        clicked && files.len() == 1 && files[0].file_name().is_some_and(|n| n == "kettle-manual.pdf"),
        &format!("the link opens the manual ({files:?})"),
    );
}

/// The message in a window of its own: the previews there too
async fn in_window(d: &Driver, inbox: i64) {
    let main = shell().main();
    open_by_subject(inbox, PHOTO).await;
    let row = main
        .list
        .shown_messages(500)
        .iter()
        .position(|m| m.folder_id == inbox && m.info.subject == PHOTO);
    let Some(row) = row.and_then(|at| u32::try_from(at).ok()) else {
        d.check(false, "the message with the photo is listed");
        return;
    };
    main.list.view.emit_by_name::<()>("activate", &[&row]);
    let Some(window) = wait_for(10, || crate::message_window::windows().into_iter().next()).await else {
        d.check(false, "the message opens in a window of its own");
        return;
    };
    wait_until(15, || window.reader.has_view()).await;
    let come = all_come(&window.reader.preview.view, 4, 20).await;
    d.check(
        come.is_some_and(|l| l.pictures == 4 && l.come == 4),
        "a message window shows the previews too",
    );
    d.shot(&window.window, "read-30d-previews-window").await;
    let _ = WidgetExt::activate_action(&window.window, "window.close", None);
    wait_until(10, || crate::message_window::windows().is_empty()).await;
}

/// Preferences open on its Reading page
pub(super) async fn reading_page() -> Option<adw::Dialog> {
    command(Command::Options);
    let dialog = wait_dialog(10, "preferences-dialog").await?;
    preferences_page(&dialog, SettingsPage::Reading);
    pause(300).await;
    Some(dialog)
}

pub(super) fn switch(dialog: &adw::Dialog, setting: Setting) -> Option<adw::SwitchRow> {
    setting_row(dialog.upcast_ref(), setting).and_downcast::<adw::SwitchRow>()
}

pub(super) async fn close(dialog: adw::Dialog) {
    dialog.close();
    wait_gone(10, "preferences-dialog").await;
}

/// How many of the page's pictures are previews, and how many of them are of the file at `attachment`
pub(super) async fn previews_shown(view: &webkit::WebView, attachment: usize) -> (usize, usize) {
    let sources = sources(view).await;
    let previews: Vec<&str> = sources.split(' ').filter(|s| s.starts_with("/pv/")).collect();
    let of_file = previews
        .iter()
        .filter(|s| s.split('-').nth(1) == Some(&attachment.to_string()))
        .count();
    (previews.len(), of_file)
}

/// Whether the page says why PDF files are not shown
async fn notice(view: &webkit::WebView) -> String {
    run_script(
        view,
        "(function(){var w=document.querySelector('section[class^=\"pe-att-\"] .w');return w?w.textContent:''})()",
    )
    .await
}

/// The two switches of Preferences: both on; all previews off (the PDF switch insensitive, keeping its value) and on;
/// PDF files off (the photo still shown, nothing said) and on
async fn switches(d: &Driver, inbox: i64) {
    let main = shell().main();
    let view = main.reader.preview.view.clone();
    open_by_subject(inbox, PHOTO).await;
    let Some(dialog) = reading_page().await else {
        d.check(false, "Preferences opens");
        return;
    };
    let (Some(show), Some(pdfs)) = (
        switch(&dialog, Setting::ShowPreviews),
        switch(&dialog, Setting::PdfPreviews),
    ) else {
        d.check(false, "Preferences has the switches of the previews");
        close(dialog).await;
        return;
    };
    d.check(
        show.is_active()
            && pdfs.is_active()
            && pdfs.is_sensitive()
            && show.title() == "Show attachments in messages"
            && !show.subtitle().unwrap_or_default().is_empty()
            && pdfs.title() == "Show PDF files in messages",
        "Preferences' Reading page has \"Show attachments in messages\" with its note and \"Show PDF files in \
         messages\" under it, both on",
    );
    show.grab_focus();
    d.shot(&dialog, "read-30e-previews-settings").await;
    show.set_active(false);
    d.check(
        !shell().core.show_previews() && !pdfs.is_sensitive() && pdfs.is_active(),
        "off, the PDF switch can not be changed and keeps its value",
    );
    let mut gone = false;
    for _ in 0..60 {
        if main.reader.has_view() && previews_shown(&view, 1).await.0 == 0 {
            gone = true;
            break;
        }
        pause(250).await;
    }
    d.check(gone, "and the message shown has no previews");
    d.shot(&dialog, "read-30f-previews-settings-off").await;
    show.set_active(true);
    d.check(
        all_come(&view, 4, 20).await.is_some_and(|l| l.come == 4) && pdfs.is_sensitive(),
        "on again, the previews are back",
    );
    pdfs.set_active(false);
    let mut photo_only = false;
    for _ in 0..60 {
        if previews_shown(&view, 1).await == (1, 0) {
            photo_only = true;
            break;
        }
        pause(250).await;
    }
    d.check(
        photo_only && notice(&view).await.is_empty(),
        "\"Show PDF files in messages\" off: the photo shows, the invoice does not, and nothing says why",
    );
    pdfs.set_active(true);
    d.check(
        all_come(&view, 4, 20).await.is_some_and(|l| l.come == 4),
        "on again, the invoice's pages are back",
    );
    close(dialog).await;
}

/// PDF previews off as after a PDF file ended the app: the switch of Preferences open goes off, the message says why
/// and names the switch; turned on again, the notice is gone and the pages are back
async fn pdf_off(d: &Driver, inbox: i64) {
    let main = shell().main();
    let view = main.reader.preview.view.clone();
    let Some(dialog) = reading_page().await else {
        d.check(false, "Preferences opens");
        return;
    };
    let _ = shell().core.pdf_previews_crashed_for_tests();
    let off = match switch(&dialog, Setting::PdfPreviews) {
        Some(row) => wait_until(10, || !row.is_active()).await,
        None => false,
    };
    d.check(
        off,
        "a PDF file that ended the app turns the PDF switch of the Preferences open off",
    );
    close(dialog).await;
    open_by_subject(inbox, LONG).await;
    open_by_subject(inbox, PHOTO).await;
    let mut said = String::new();
    for _ in 0..40 {
        said = notice(&view).await;
        if !said.is_empty() && previews_shown(&view, 1).await == (1, 0) {
            break;
        }
        pause(250).await;
    }
    d.check(
        said.contains("Show PDF files in messages") && previews_shown(&view, 1).await == (1, 0),
        &format!("the message shows the photo and why PDF files are not shown, naming the switch ({said})"),
    );
    all_come(&view, 1, 10).await;
    d.shot(main.window(), "read-31-previews-pdf-off").await;
    let Some(dialog) = reading_page().await else {
        d.check(false, "Preferences opens again");
        return;
    };
    match switch(&dialog, Setting::PdfPreviews) {
        Some(row) => {
            d.check(!row.is_active(), "Preferences shows PDF files off");
            row.set_active(true);
        }
        None => d.check(false, "Preferences has the PDF switch"),
    }
    close(dialog).await;
    open_by_subject(inbox, LONG).await;
    open_by_subject(inbox, PHOTO).await;
    let back = all_come(&view, 4, 20).await.is_some_and(|l| l.come == 4);
    d.check(
        back && notice(&view).await.is_empty(),
        "turned on, the notice is gone and the pages are back",
    );
}

/// More pictures than the core shows: the first 20, every one come (none broken), the rest only in the strip; in a
/// narrow window nothing wider than the pane
async fn many(d: &Driver, inbox: i64) {
    let main = shell().main();
    let view = main.reader.preview.view.clone();
    open_by_subject(inbox, MANY).await;
    let come = all_come(&view, 20, 30).await;
    d.check(
        come.as_ref().is_some_and(|l| l.pictures == 20 && l.come == 20) && main.reader.strip.shown().len() == PICTURES,
        &format!("of {PICTURES} pictures the first 20 show, every one come, all in the strip ({come:?})"),
    );
    d.shot(main.window(), "read-30g-previews-many").await;
    run_script(&view, "window.scrollTo(0, 2400)").await;
    d.shot(main.window(), "read-30h-previews-many-scrolled").await;
    // a narrow window of its own: everything as wide as the pane at most, the long name wrapped
    let row = main
        .list
        .shown_messages(500)
        .iter()
        .position(|m| m.folder_id == inbox && m.info.subject == MANY);
    let Some(row) = row.and_then(|at| u32::try_from(at).ok()) else {
        return;
    };
    main.list.view.emit_by_name::<()>("activate", &[&row]);
    let Some(window) = wait_for(10, || crate::message_window::windows().into_iter().next()).await else {
        d.check(false, "the message with many pictures opens in a window of its own");
        return;
    };
    window.window.set_default_size(420, 760);
    wait_until(10, || window.window.width() <= 460 && window.reader.has_view()).await;
    let narrow = &window.reader.preview.view;
    all_come(narrow, 20, 30).await;
    let widths = run_script(
        narrow,
        "document.documentElement.scrollWidth+'/'+document.documentElement.clientWidth",
    )
    .await;
    let fits = widths
        .split_once('/')
        .and_then(|(a, b)| Some(a.parse::<i64>().ok()? <= b.parse::<i64>().ok()?));
    d.check(
        fits == Some(true),
        &format!("in a narrow window nothing is wider than the pane, the long name wraps ({widths})"),
    );
    d.shot(&window.window, "read-30i-previews-narrow").await;
    let _ = WidgetExt::activate_action(&window.window, "window.close", None);
    wait_until(10, || crate::message_window::windows().is_empty()).await;
}

/// The color of the pixel of `view` at (`x`, `y`) of its page, as red, green and blue
async fn pixel(view: &webkit::WebView, x: f64, y: f64) -> Option<(u8, u8, u8)> {
    let texture = view
        .snapshot_future(webkit::SnapshotRegion::Visible, webkit::SnapshotOptions::NONE)
        .await
        .ok()?;
    let scale = f64::from(texture.width()) / f64::from(view.width().max(1));
    let (px, py) = ((x * scale) as usize, (y * scale) as usize);
    let mut downloader = gdk::TextureDownloader::new(&texture);
    downloader.set_format(gdk::MemoryFormat::R8g8b8a8);
    let (bytes, stride) = downloader.download_bytes();
    let at = py * stride + px * 4;
    let rgb = bytes.get(at..at + 3)?;
    Some((rgb[0], rgb[1], rgb[2]))
}

/// Where in the visible page a point of the `n`th picture of the previews is (`fx`, `fy` of its width and height),
/// scrolled to the middle of the view first
async fn point_of(view: &webkit::WebView, n: usize, fx: f64, fy: f64) -> Option<(f64, f64)> {
    let script = format!(
        "(function(){{var i=document.querySelectorAll('section[class^=\"pe-att-\"] img')[{n}];if(!i)return '';\
         var r=i.getBoundingClientRect();window.scrollBy(0,r.top+r.height*{fy}-window.innerHeight/2);\
         r=i.getBoundingClientRect();return (r.left+r.width*{fx})+'/'+(r.top+r.height*{fy})}})()"
    );
    let value = run_script(view, &script).await;
    let (x, y) = value.split_once('/')?;
    Some((x.parse().ok()?, y.parse().ok()?))
}

/// The dark look: the photo as it is (its sky still blue), the PDF pages on white, the captions light
async fn dark(d: &Driver, inbox: i64) {
    let main = shell().main();
    let view = main.reader.preview.view.clone();
    let styles = adw::StyleManager::default();
    styles.set_color_scheme(adw::ColorScheme::ForceDark);
    wait_until(10, || styles.is_dark()).await;
    open_by_subject(inbox, LONG).await;
    open_by_subject(inbox, PHOTO).await;
    all_come(&view, 4, 20).await;
    pause(500).await;
    let sky = match point_of(&view, 0, 0.3, 0.04).await {
        Some((x, y)) => {
            pause(400).await;
            pixel(&view, x, y).await
        }
        None => None,
    };
    d.check(
        sky.is_some_and(|(r, _, b)| u16::from(b) > u16::from(r) + 40),
        &format!("in dark mode the photo is as it is, its sky blue ({sky:?})"),
    );
    let paper = match point_of(&view, 1, 0.02, 0.5).await {
        Some((x, y)) => {
            pause(400).await;
            pixel(&view, x, y).await
        }
        None => None,
    };
    d.check(
        paper.is_some_and(|(r, g, b)| r > 240 && g > 240 && b > 240),
        &format!("and a PDF page on white ({paper:?})"),
    );
    let colors = run_script(
        &view,
        "(function(){var s=document.querySelector('section[class^=\"pe-att-\"]');return getComputedStyle(s.querySelector('.n')).color\
         +'|'+getComputedStyle(s).backgroundColor})()",
    )
    .await;
    d.check(
        colors.starts_with("rgb(227, 227, 230)|rgb(30, 31, 34)"),
        &format!("the names light on the document's dark ({colors})"),
    );
    run_script(&view, "window.scrollTo(0, 0)").await;
    d.shot(main.window(), "read-30j-previews-dark").await;
    open_by_subject(inbox, LONG).await;
    all_come(&view, 5, 20).await;
    run_script(&view, "window.scrollTo(0, document.body.scrollHeight)").await;
    d.shot(main.window(), "read-30k-previews-long-dark").await;
    open_by_subject(inbox, MANY).await;
    all_come(&view, 20, 30).await;
    d.shot(main.window(), "read-30l-previews-many-dark").await;
    open_by_subject(inbox, TILES).await;
    all_come(&view, 1, 20).await;
    d.shot(main.window(), "read-32e-previews-tiles-dark").await;
    if let Some(dialog) = reading_page().await {
        d.shot(&dialog, "read-30m-previews-settings-dark").await;
        close(dialog).await;
    }
    styles.set_color_scheme(adw::ColorScheme::Default);
    wait_until(5, || !styles.is_dark()).await;
}

/// The words in German, for the review of the look: the captions, the notice and Preferences' rows
async fn german(d: &Driver, inbox: i64) {
    steps::in_language("de").await;
    let main = shell().main();
    let view = main.reader.preview.view.clone();
    select_folder(&pe_core::i18n::tr(pe_core::i18n::Text::FolderInbox));
    open_by_subject(inbox, PHOTO).await;
    all_come(&view, 4, 20).await;
    let text = document_text(&main.reader.preview.shown());
    d.check(
        text.contains("3 Seiten"),
        &format!("in German the invoice says its pages in German ({})", text.len()),
    );
    d.shot(main.window(), "read-30n-previews-de").await;
    open_by_subject(inbox, MANY).await;
    all_come(&view, 20, 30).await;
    d.shot(main.window(), "read-30o-previews-many-de").await;
    if let Some(dialog) = reading_page().await {
        d.shot(&dialog, "read-30p-previews-settings-de").await;
        close(dialog).await;
    }
    steps::in_language("en").await;
}

/// The messages of the step taken away from the server and the list
async fn remove_messages(d: &Driver, inbox: i64) {
    for message in d.messages("INBOX") {
        let raw = raw_text(&message);
        if [PHOTO_ID, LONG_ID, MANY_ID, TILES_ID].iter().any(|id| raw.contains(id))
            && let Some(uid) = message["uid"].as_u64()
        {
            let _ = http(
                d.ports.rest,
                "DELETE",
                &format!("/v1/mailboxes/INBOX/messages/{uid}"),
                None,
            );
        }
    }
    run_command(Command::Sync);
    let gone = wait_until(30, || {
        let listed = listed_in_folder(inbox, 0, 500);
        ![PHOTO, LONG, MANY, TILES]
            .iter()
            .any(|subject| listed.iter().any(|m| m.info.subject == *subject))
    })
    .await;
    d.check(gone, "the messages with previews are taken away");
}
