//! Step 4 of the UI test, continued: the pictures in a message's text drawn by the core. The newsletter's banner
//! (`cid:banner@example.com`, linked) is served at a preview address, no picture of the document is the sender's own
//! bytes, the printout has the core's copy of it, and its right-click menu keeps Copy Link.

use super::previews::run_script;
use super::*;

/// The banner's address as the document writes it, whether it has loaded, its width, its whole address and its
/// link's, then every picture's address that is the sender's own (`data:` or `cid:`), a line each
const BANNER: &str = "(function(){var b=document.querySelector('img[alt=\"Trail Notes\"]');if(!b)return 'none';\
    var own=Array.prototype.slice.call(document.querySelectorAll('img')).map(function(i){\
    return i.getAttribute('src')||''}).filter(function(s){return /^(data|cid):/i.test(s)});\
    var a=b.closest('a');return [b.getAttribute('src'),b.complete&&b.naturalWidth>0,b.naturalWidth,b.src,\
    a?a.href:''].concat(own).join('\\n')})()";

/// Each picture of the printout: how it is decoded, whether it is in the printout itself (data:, the core's copy; a
/// picture from the internet is blocked here), whether it has loaded (with a size), and its alt text, a line each
const PRINTED_PICTURES: &str = "Array.prototype.slice.call(document.images).map(function(x){\
    return [x.decoding,/^data:/.test(x.src),x.complete&&x.naturalWidth>0,x.alt].join(' ')}).join('\\n')";

/// What [`BANNER`] says of `view`, once the banner has loaded (10 seconds at most)
pub(super) async fn banner(view: &webkit::WebView) -> Vec<String> {
    let mut banner = Vec::new();
    for _ in 0..40 {
        banner = run_script(view, BANNER).await.lines().map(str::to_string).collect();
        if banner.get(1).is_some_and(|loaded| loaded == "true") {
            break;
        }
        pause(250).await;
    }
    banner
}

pub(super) async fn pictures_in_text(d: &Driver) {
    let view = shell().main().reader.preview.view.clone();
    let banner = banner(&view).await;
    let src = banner.first().cloned().unwrap_or_default();
    d.check(
        src.starts_with("/pv/")
            && banner.get(1).is_some_and(|l| l == "true")
            && banner.get(2).is_some_and(|w| w == "560"),
        &format!(
            "the banner sent inside the message is drawn by the core: a preview address, loaded, 560 wide ({banner:?})"
        ),
    );
    d.check(
        banner.len() == 5,
        &format!(
            "no picture of the document has a data: or cid: address ({:?})",
            banner.get(5..)
        ),
    );
    let (image, link) = (
        banner.get(3).cloned().unwrap_or_default(),
        banner.get(4).cloned().unwrap_or_default(),
    );
    d.check(
        link == "https://example.com/trail-notes",
        &format!("the banner keeps its link ({link})"),
    );
    context_menu(d, &view, &image, &link);
    print(d).await;
}

/// The app's handler of the web view's right-click menu given what a right-click on the linked banner gives it:
/// Copy Link and Copy Image stay, opening and saving go
fn context_menu(d: &Driver, view: &webkit::WebView, image: &str, link: &str) {
    use webkit::ContextMenuAction as Action;
    let context = webkit::HitTestResultContext::LINK | webkit::HitTestResultContext::IMAGE;
    let hit = glib::Object::builder::<webkit::HitTestResult>()
        .property("context", context.bits())
        .property("link-uri", link)
        .property("image-uri", image)
        .build();
    let menu = webkit::ContextMenu::new();
    for action in [
        Action::OpenLink,
        Action::OpenLinkInNewWindow,
        Action::DownloadLinkToDisk,
        Action::CopyLinkToClipboard,
        Action::OpenImageInNewWindow,
        Action::DownloadImageToDisk,
        Action::CopyImageToClipboard,
        Action::CopyImageUrlToClipboard,
    ] {
        menu.append(&webkit::ContextMenuItem::from_stock_action(action));
    }
    view.emit_by_name::<bool>("context-menu", &[&menu, &hit]);
    let left: Vec<Action> = menu.items().iter().map(|item| item.stock_action()).collect();
    d.check(
        left == [Action::CopyLinkToClipboard, Action::CopyImageToClipboard],
        &format!("right-clicking the linked banner offers Copy Link and Copy Image ({left:?})"),
    );
}

/// Print of the newsletter: the print dialog over the core's printout, the banner in it as the core's PNG
async fn print(d: &Driver) {
    let main = shell().main().window().clone().upcast::<gtk::Window>();
    command(Command::Print);
    let dialog = wait_for(40, || {
        windows()
            .into_iter()
            .find(|w| w != &main && w.is::<gtk::PrintUnixDialog>())
    })
    .await;
    let printed = crate::reader::printing().unwrap_or_default();
    d.check(
        dialog.is_some()
            && printed.contains("<img src=\"data:image/png;base64,")
            && printed.contains("alt=\"Trail Notes\"")
            && !printed.contains("/pv/")
            && !printed.contains("cid:"),
        "Print of the newsletter puts the banner into the printout as the core's PNG",
    );
    // what goes on paper: the print view's pictures loaded, and drawn as they are painted (a picture still being
    // decoded on WebKit's threads would print as an empty box)
    let pictures: Vec<String> = match crate::reader::printing_view() {
        Some(view) => run_script(&view, PRINTED_PICTURES)
            .await
            .lines()
            .map(str::to_string)
            .collect(),
        None => Vec::new(),
    };
    d.check(
        pictures.iter().any(|p| p == "sync true true Trail Notes")
            && pictures
                .iter()
                .all(|p| p.starts_with("sync ") && !p.starts_with("sync true false")),
        &format!("the pictures of the printout have loaded and are drawn as the page is printed ({pictures:?})"),
    );
    if let Some(dialog) = dialog {
        let closed = dialog.downgrade();
        dialog.close();
        drop(dialog);
        wait_until(10, || closed.upgrade().is_none_or(|w| !w.is_visible())).await;
    }
    wait_until(10, || crate::reader::printing().is_none()).await;
    wait_until(10, || main.cursor().is_none()).await;
}
