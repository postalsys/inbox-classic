//! Step 8b of the UI test, its second part: the files the core does not draw (tiles), Show in Message in the strip's
//! menu, and the printout with the pictures in it. `tiles.eml` (a HEIC picture, a photo and a PDF file with a
//! password) and `photo-and-pdf.eml` of `scripts/ui-e2e/previews/`, put in the Inbox by the first part.

use super::attach::{close_menu, menu_item_sensitive};
use super::previews::{all_come, close, opened, previews_shown, reading_page, run_script, switch};
use super::steps::{document_text, open_by_subject};
use super::*;

pub(super) const TILES: &str = "The boat trip, and the booking";
pub(super) const TILES_ID: &str = "<previews-4@example.com>";

/// Each tile of the page shown: its type, name, size and reason, and its height, a line each
const TILE_TEXTS: &str = "(function(){var s=document.querySelector('section[class^=\"pe-att-\"]');if(!s)return '';\
    return Array.prototype.slice.call(s.querySelectorAll('a.t')).map(function(a){\
    return a.textContent+'|'+Math.round(a.getBoundingClientRect().height)}).join('\\n')})()";

/// How far down the page shown is scrolled, in CSS pixels; None when it could not be read
async fn scrolled(view: &webkit::WebView) -> Option<i64> {
    run_script(view, "Math.round(window.scrollY)").await.parse().ok()
}

/// The tiles of the HEIC picture and the protected PDF file, the photo between them drawn; Tab and Enter on a tile
/// opens its file
pub(super) async fn tiles(d: &Driver, inbox: i64) {
    let main = shell().main();
    let view = main.reader.preview.view.clone();
    open_by_subject(inbox, TILES).await;
    let come = all_come(&view, 1, 20).await;
    let tiles = run_script(&view, TILE_TEXTS).await;
    let lines: Vec<&str> = tiles.lines().collect();
    let heights: Vec<&str> = lines.iter().filter_map(|l| l.rsplit('|').next()).collect();
    d.check(
        come.is_some_and(|l| l.pictures == 1 && l.come == 1)
            && lines.len() == 2
            && lines[0].contains("HEIC")
            && lines[0].contains("boat.heic")
            && lines[0].contains("HEIC pictures are not shown yet")
            && lines[1].contains("booking-4471.pdf")
            && lines[1].contains("Protected by a password")
            && heights.len() == 2
            && heights[0] == heights[1],
        &format!(
            "the photo shows, the HEIC picture and the protected PDF file are tiles of one size that say why \
             ({tiles:?})"
        ),
    );
    // the HEIC picture's tile at the top, the photo under it; then the protected PDF file's at the end
    run_script(
        &view,
        "document.querySelector('section[class^=\"pe-att-\"] a.t').scrollIntoView()",
    )
    .await;
    d.shot(main.window(), "read-32-previews-tiles").await;
    run_script(&view, "window.scrollTo(0, document.body.scrollHeight)").await;
    d.shot(main.window(), "read-32a-previews-tiles-end").await;
    // the protected PDF file's tile focused as Tab leaves it, and Enter: what a link does on Enter is its click
    let focused = run_script(
        &view,
        "(function(){var a=document.querySelectorAll('section[class^=\"pe-att-\"] a.t')[1];if(!a)return 'no';\
         a.focus();if(document.activeElement!==a||a.tabIndex<0)return 'no';a.click();return 'yes'})()",
    )
    .await;
    let files = opened(10).await;
    d.check(
        focused == "yes" && files.len() == 1 && files[0].file_name().is_some_and(|n| n == "booking-4471.pdf"),
        &format!("Tab and Enter on a tile open its file ({files:?})"),
    );
    // the HEIC picture's Show in Message is greyed: nothing here draws it
    let strip = &main.reader.strip;
    let item = menu_of(strip, 0).await;
    d.check(
        item.as_ref()
            .is_some_and(|(_, ticked, enabled, sensitive)| !ticked && !enabled && *sensitive == Some(false)),
        &format!("on the HEIC picture Show in Message is greyed ({item:?})"),
    );
    d.shot(main.window(), "read-32b-previews-tiles-menu").await;
    close_menu(strip).await;
}

/// The strip's menu of file `index` opened, as the menu key opens it: its words, whether Show in Message is ticked
/// and can be chosen, and whether its item is drawn so
async fn menu_of(strip: &crate::attachments::Strip, index: i32) -> Option<(Vec<String>, bool, bool, Option<bool>)> {
    let child = strip.flow.child_at_index(index)?;
    strip.flow.select_child(&child);
    child.grab_focus();
    strip.popup_menu(&child, None);
    let menu = wait_for(5, || strip.open_menu()).await?;
    pause(300).await;
    let (ticked, enabled) = strip.show_in_message_item()?;
    let sensitive = menu_item_sensitive(&menu, "Show in Message");
    Some((menu_labels(Some(&menu)), ticked, enabled, sensitive))
}

/// Show in Message of the menu open chosen, as a click on it does, and the menu closed
async fn choose_show_in_message(strip: &crate::attachments::Strip) -> bool {
    let Some(menu) = strip.open_menu() else {
        return false;
    };
    let chosen = WidgetExt::activate_action(&menu, "strip.show-in-message", None).is_ok();
    close_menu(strip).await;
    chosen
}

/// Waits until the page shows `previews` pictures of which `invoice` are the invoice's; its scroll then
async fn shows(view: &webkit::WebView, previews: usize, invoice: usize) -> Option<Option<i64>> {
    for _ in 0..80 {
        let come = previews == 0 || all_come(view, previews, 1).await.is_some_and(|l| l.come == previews);
        if previews_shown(view, 1).await == (previews, invoice) && come {
            return Some(scrolled(view).await);
        }
        pause(100).await;
    }
    None
}

/// Show in Message on the invoice of `photo-and-pdf.eml`: ticked; chosen, the invoice is taken out and the text stays
/// where it was scrolled to; chosen again, it is back. With the previews off it draws the invoice alone
pub(super) async fn show_in_message(d: &Driver, inbox: i64, photo: &str) {
    let main = shell().main();
    let view = main.reader.preview.view.clone();
    let strip = &main.reader.strip;
    open_by_subject(inbox, photo).await;
    all_come(&view, 4, 20).await;
    // down into the text, short of where the page without the invoice ends
    run_script(&view, "window.scrollTo(0, 60)").await;
    let before = scrolled(&view).await;
    let item = menu_of(strip, 1).await;
    let labels = item.as_ref().map(|i| i.0.clone()).unwrap_or_default();
    d.check(
        labels == ["Open", "Save As\u{2026}", "Save All\u{2026}", "Show in Message"]
            && item.as_ref().is_some_and(|(_, ticked, enabled, _)| *ticked && *enabled),
        &format!("the invoice's menu has Show in Message after Save All, ticked ({item:?})"),
    );
    d.shot(main.window(), "read-32c-previews-show-in-message").await;
    let chosen = choose_show_in_message(strip).await;
    let after = shows(&view, 1, 0).await;
    d.check(
        chosen && before.is_some_and(|y| y > 0) && after == Some(before),
        &format!("choosing it takes the invoice out, the text where it was ({before:?} then {after:?})"),
    );
    let strip_files = strip.shown();
    d.check(
        strip_files.len() == 2,
        &format!("the strip still lists both files ({strip_files:?})"),
    );
    let item = menu_of(strip, 1).await;
    d.check(
        item.as_ref().is_some_and(|(_, ticked, enabled, _)| !ticked && *enabled),
        &format!("then Show in Message is not ticked ({item:?})"),
    );
    let chosen = choose_show_in_message(strip).await;
    let back = shows(&view, 4, 3).await;
    d.check(
        chosen && back == Some(before),
        &format!("chosen again, the invoice is back, the text where it was ({back:?})"),
    );

    // the previews off: Show in Message draws the invoice alone
    let Some(dialog) = reading_page().await else {
        d.check(false, "Preferences opens");
        return;
    };
    let Some(show) = switch(&dialog, Setting::ShowPreviews) else {
        d.check(false, "Preferences has the switch of the previews");
        close(dialog).await;
        return;
    };
    show.set_active(false);
    close(dialog).await;
    // another message first: what was chosen is for the message while it is shown
    open_by_subject(inbox, TILES).await;
    open_by_subject(inbox, photo).await;
    let none = shows(&view, 0, 0).await;
    let item = menu_of(strip, 1).await;
    let chosen =
        item.as_ref().is_some_and(|(_, ticked, enabled, _)| !ticked && *enabled) && choose_show_in_message(strip).await;
    let alone = shows(&view, 3, 3).await;
    d.check(
        none.is_some() && chosen && alone.is_some(),
        &format!("with the previews off Show in Message draws the invoice alone ({item:?}, {alone:?})"),
    );
    d.shot(main.window(), "read-32d-previews-shown-alone").await;
    if let Some(dialog) = reading_page().await {
        if let Some(show) = switch(&dialog, Setting::ShowPreviews) {
            show.set_active(true);
        }
        close(dialog).await;
    }
    d.check(shell().core.show_previews(), "the previews on again");
}

/// Print of `photo-and-pdf.eml`: the print dialog over the printout the core made, with the photo in it and a line
/// naming the invoice, which is not printed; the printout as the print view draws it in a window of its own (its
/// picture drawn: a `data:` address the print view loads)
pub(super) async fn printing(d: &Driver, inbox: i64, photo: &str) {
    open_by_subject(inbox, photo).await;
    let main_window = shell().main().window().clone().upcast::<gtk::Window>();
    command(Command::Print);
    let dialog = wait_for(40, || {
        windows()
            .into_iter()
            .find(|w| w != &main_window && w.is::<gtk::PrintUnixDialog>())
    })
    .await;
    let printed = crate::reader::printing().unwrap_or_default();
    let text = document_text(&printed);
    d.check(
        dialog.is_some()
            && text.contains("the lodge's invoice")
            && printed.contains("<img src=\"data:image/jpeg;base64,")
            && text.contains("invoice-2026-118.pdf (3 pages, ")
            && text.contains("is not printed. Open it to print it.")
            && !printed.contains("/pv/"),
        "Print of a message with previews opens the print dialog over the core's printout: the photo in it, a line \
         naming the invoice",
    );
    if let Some(dialog) = dialog {
        pause(1000).await;
        let closed = dialog.downgrade();
        dialog.close();
        drop(dialog);
        wait_until(10, || closed.upgrade().is_none_or(|w| !w.is_visible())).await;
    }
    wait_until(10, || crate::reader::printing().is_none()).await;
    d.check(
        main_window.cursor().is_none(),
        "the window is no longer busy once the dialog is there",
    );
    print_view(d, &printed).await;
}

/// The printout in a print view of its own, in a window: its photo drawn (blue sky in the picture of it)
async fn print_view(d: &Driver, printed: &str) {
    let view = crate::webview::DocumentView::new("print", false);
    let window = gtk::Window::builder()
        .title("Print")
        .default_width(760)
        .default_height(1100)
        .child(&view.view)
        .build();
    window.present();
    view.show(printed, false);
    wait_until(10, || !view.view.is_loading()).await;
    pause(800).await;
    let blue = match view
        .view
        .snapshot_future(webkit::SnapshotRegion::FullDocument, webkit::SnapshotOptions::NONE)
        .await
    {
        Ok(texture) => {
            let mut downloader = gdk::TextureDownloader::new(&texture);
            downloader.set_format(gdk::MemoryFormat::R8g8b8a8);
            let (bytes, _) = downloader.download_bytes();
            bytes
                .as_chunks::<4>()
                .0
                .iter()
                .filter(|p| u16::from(p[2]) > u16::from(p[0]) + 40 && p[2] > 110)
                .count()
        }
        Err(_) => 0,
    };
    d.check(
        blue > 5000,
        &format!("the print view draws the photo ({blue} pixels of its sky)"),
    );
    d.shot(&window, "read-33-previews-print").await;
    window.close();
    view.release();
}
