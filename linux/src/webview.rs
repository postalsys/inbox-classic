//! The web views, locked down the way the Windows app locks WebView2 down: the core's documents are served from the
//! app's own scheme (`inboxclassic://preview/<n>/`, `inboxclassic://compose/<n>/`) out of memory, and the parts of a
//! signed or encrypted message beside its page (`inboxclassic://preview/<n>/part-N`, each in a frame of the page),
//! and the previews of its attachments (`inboxclassic://preview/pv/<token>-<file>-<page>`), answered once the core
//! has drawn them ([`preview_answered`]), never by waiting in the scheme's handler.
//! Every other load is blocked by the content rules the core gives (only the pictures of a message the user allowed
//! get through), nothing navigates away from the document, links open in the browser, no window opens, no
//! dev tools, an ephemeral network session (nothing on disk). Page scripts are off but in the editor, whose page runs
//! only its own script (allowed by a nonce in its CSP); the reading pane runs the app's own script (the core's, which
//! sizes the frames of a signed or encrypted message's parts) with the page's scripts still off.

use std::cell::{Cell, RefCell};
use std::collections::HashMap;
use std::rc::Rc;

use gtk::prelude::*;
use gtk::{gdk, gio, glib};
use webkit::prelude::*;

/// One web context, network session and pair of content rules for all the app's web views
pub struct Web {
    context: webkit::WebContext,
    session: webkit::NetworkSession,
    /// The documents the scheme serves, by their URI, each with the documents of its parts (`part-N` beside it)
    documents: RefCell<HashMap<String, Served>>,
    next: Cell<u64>,
    /// The rules that block every load, and those that let a message's pictures through; None until compiled
    filters: RefCell<Option<(webkit::UserContentFilter, webkit::UserContentFilter)>>,
    /// Loads waiting for the rules: no document is shown without them
    waiting: RefCell<Vec<Box<dyn FnOnce()>>>,
    /// The previews asked for and not answered yet, by the core's ask
    pending: RefCell<HashMap<u64, webkit::URISchemeRequest>>,
}

/// A page and the documents of its frames, and the token of its previews (ended with the page)
struct Served {
    page: Rc<str>,
    parts: Rc<[String]>,
    previews: Option<String>,
}

impl Served {
    /// The page no longer shown: the core stops answering its previews, and answers those still asked for with none
    /// (which finishes their requests)
    fn end(self) {
        if let Some(token) = &self.previews {
            crate::app::shell().core.previews_end(token);
        }
    }
}

thread_local! {
    static WEB: Rc<Web> = Web::new();
}

pub fn web() -> Rc<Web> {
    WEB.with(Rc::clone)
}

impl Web {
    fn new() -> Rc<Web> {
        let context = webkit::WebContext::new();
        let web = Rc::new(Web {
            context: context.clone(),
            session: webkit::NetworkSession::new_ephemeral(),
            documents: RefCell::default(),
            next: Cell::new(0),
            filters: RefCell::new(None),
            waiting: RefCell::default(),
            pending: RefCell::default(),
        });
        let served = Rc::downgrade(&web);
        context.register_uri_scheme(pe_html::DOCUMENT_SCHEME, move |request| {
            let Some(web) = served.upgrade() else { return };
            let uri = request.uri().unwrap_or_default();
            // a preview of a page shown: kept until the core has drawn it (an address of no page shown is not found)
            if let Some(ask) = crate::app::shell().core.preview_ask(&uri) {
                web.pending.borrow_mut().insert(ask, request.clone());
                return;
            }
            match web.document(&uri) {
                Some(document) => {
                    let bytes = glib::Bytes::from_owned(document.as_bytes().to_vec());
                    let length = bytes.len() as i64;
                    let stream = gio::MemoryInputStream::from_bytes(&bytes);
                    request.finish(&stream, length, Some("text/html"));
                }
                None => {
                    let mut error = glib::Error::new(gio::IOErrorEnum::NotFound, "no such document");
                    request.finish_error(&mut error);
                }
            }
        });
        web.compile_rules();
        web
    }

    /// The page at `uri`, or the document of one of its parts; None for any other address, or a part not shown
    fn document(&self, uri: &str) -> Option<Rc<str>> {
        let uri = uri.split(['#', '?']).next().unwrap_or(uri);
        let documents = self.documents.borrow();
        if let Some(served) = documents.get(uri) {
            return Some(served.page.clone());
        }
        let index = pe_html::part_document(uri)?;
        let page = &uri[..=uri.rfind('/')?];
        let part = documents.get(page)?.parts.get(index)?;
        (!part.is_empty()).then(|| Rc::from(part.as_str()))
    }

    /// The content rules of the core compiled once (WebKit keeps them in a store on disk, in the cache folder)
    fn compile_rules(self: &Rc<Web>) {
        let dir = glib::user_cache_dir().join("inbox-classic").join("content-rules");
        let _ = std::fs::create_dir_all(&dir);
        let store = webkit::UserContentFilterStore::new(&dir.to_string_lossy());
        let blocked = glib::Bytes::from_owned(pe_html::webkit_content_rules(false).into_bytes());
        let pictures = glib::Bytes::from_owned(pe_html::webkit_content_rules(true).into_bytes());
        let web = Rc::downgrade(self);
        let second = store.clone();
        store.save("blocked", &blocked, gio::Cancellable::NONE, move |first| {
            second.save("pictures", &pictures, gio::Cancellable::NONE, move |allowing| {
                let Some(web) = web.upgrade() else { return };
                match (first, allowing) {
                    (Ok(blocked), Ok(allowing)) => {
                        *web.filters.borrow_mut() = Some((blocked, allowing));
                        let waiting = std::mem::take(&mut *web.waiting.borrow_mut());
                        for load in waiting {
                            load();
                        }
                    }
                    (Err(error), _) | (_, Err(error)) => {
                        // without the rules nothing is shown: a document's loads would not be blocked
                        eprintln!("the content rules could not be compiled: {error}");
                    }
                }
            });
        });
    }

    /// Runs `load` once the rules are there
    fn when_ready(&self, load: impl FnOnce() + 'static) {
        if self.filters.borrow().is_some() {
            load();
        } else {
            self.waiting.borrow_mut().push(Box::new(load));
        }
    }

    /// A new URI under `kind` serving `document` and its `parts` beside it, its previews under the token `previews`,
    /// and the one it replaces given up. It ends in `/`, so the page's frames (`part-N`) ask for addresses under it
    fn serve(
        &self,
        kind: &str,
        document: &str,
        parts: &[String],
        previews: Option<&str>,
        replaces: Option<&str>,
    ) -> String {
        let n = self.next.get() + 1;
        self.next.set(n);
        let uri = format!("{}://{kind}/{n}/", pe_html::DOCUMENT_SCHEME);
        let served = Served {
            page: Rc::from(document),
            parts: Rc::from(parts),
            previews: previews.map(str::to_string),
        };
        let old = {
            let mut documents = self.documents.borrow_mut();
            documents.insert(uri.clone(), served);
            replaces.and_then(|old| documents.remove(old))
        };
        if let Some(old) = old {
            old.end();
        }
        uri
    }

    fn forget(&self, uri: &str) {
        let old = self.documents.borrow_mut().remove(uri);
        if let Some(old) = old {
            old.end();
        }
    }
}

/// The core drew (or gave up) the preview of `ask`: the web view that asked for it answered with the picture, or
/// "not found" (a page no longer shown). On the window thread, as every event of the core
pub fn preview_answered(ask: u64) {
    let Some(request) = web().pending.borrow_mut().remove(&ask) else {
        return;
    };
    match crate::app::shell().core.preview_answer(ask) {
        Some(picture) => {
            let bytes = glib::Bytes::from(&picture.bytes[..]);
            let length = bytes.len() as i64;
            let stream = gio::MemoryInputStream::from_bytes(&bytes);
            request.finish(&stream, length, Some(picture.mime.as_str()));
        }
        None => {
            let mut error = glib::Error::new(gio::IOErrorEnum::NotFound, "no such preview");
            request.finish_error(&mut error);
        }
    }
}

/// The settings of every web view: `javascript` (the page's own scripts) only for the editor; `app_scripts` lets the
/// app run its own script in the page (`enable-javascript`) while the page's scripts, its `<script>` elements, event
/// attributes and `javascript:` links, stay off (`enable-javascript-markup`)
fn settings(javascript: bool, app_scripts: bool) -> webkit::Settings {
    let settings = webkit::Settings::new();
    settings.set_enable_javascript(javascript || app_scripts);
    settings.set_enable_javascript_markup(javascript);
    settings.set_enable_developer_extras(false);
    settings.set_enable_html5_local_storage(false);
    settings.set_enable_html5_database(false);
    settings.set_enable_webgl(false);
    settings.set_enable_webaudio(false);
    settings.set_enable_webrtc(false);
    settings.set_enable_media_stream(false);
    settings.set_enable_mediasource(false);
    settings.set_enable_encrypted_media(false);
    settings.set_enable_page_cache(false);
    settings.set_enable_dns_prefetching(false);
    settings.set_enable_fullscreen(false);
    settings.set_enable_back_forward_navigation_gestures(false);
    settings.set_javascript_can_open_windows_automatically(false);
    settings.set_javascript_can_access_clipboard(false);
    settings.set_allow_file_access_from_file_urls(false);
    settings.set_allow_universal_access_from_file_urls(false);
    settings.set_allow_top_navigation_to_data_urls(false);
    settings.set_allow_modal_dialogs(false);
    settings
}

/// A web view that shows one of the core's documents at a time
#[derive(Clone)]
pub struct DocumentView {
    pub view: webkit::WebView,
    manager: webkit::UserContentManager,
    kind: &'static str,
    /// The URI of the document shown, the only one it may navigate to
    current: Rc<RefCell<String>>,
    /// The links clicked in the document that its owner follows itself, shared with the view's policy decisions
    links: Links,
    /// Whether the document shown has frames to size ([`DocumentView::measure_frames`]), and the timer that sizes them
    measuring: Rc<Cell<bool>>,
    measure_timer: Rc<RefCell<Option<glib::SourceId>>>,
    /// Counts the documents asked for: a document shown in place ([`DocumentView::show_in_place`]) waits for the
    /// scroll of the one before and is dropped when another was asked for meanwhile
    asked: Rc<Cell<u64>>,
    /// The app's script that scrolls the document being loaded to where the one before was, until it has loaded
    scroll_back: Rc<RefCell<Option<(String, webkit::UserScript)>>>,
}

/// Asked of a link clicked in a document before the browser opens it: true when the owner took it (the bounce card's)
type Links = Rc<RefCell<Option<Rc<dyn Fn(&str) -> bool>>>>;

thread_local! {
    /// The web views that show or write a message, for View > Text Size (the help and printing keep their size)
    static MESSAGE_VIEWS: RefCell<Vec<glib::WeakRef<webkit::WebView>>> = const { RefCell::new(Vec::new()) };
}

/// `change` done to every web view that shows or writes a message and is still open; the closed ones leave the list
fn each_message_view(change: impl Fn(&webkit::WebView)) {
    MESSAGE_VIEWS.with(|views| {
        views
            .borrow_mut()
            .retain(|view| view.upgrade().map(|view| change(&view)).is_some());
    });
}

/// View > Text Size: every web view that shows or writes a message at `zoom` (the core's, 1.0 for Medium)
pub fn set_text_zoom(zoom: f64) {
    each_message_view(|view| view.set_zoom_level(zoom));
}

/// The background of pe-html's documents in a dark window (its `DOCUMENT_DARK`)
const DARK_BACKGROUND: &str = "#1e1f22";

/// What a web view that shows or writes a message paints before its document does: the documents' dark background
/// while the window is dark and messages may be dark (Preferences), white otherwise, so nothing flashes white
pub fn background() -> gdk::RGBA {
    let dark = pe_html::dark() && adw::StyleManager::default().is_dark();
    gdk::RGBA::parse(if dark { DARK_BACKGROUND } else { "#ffffff" }).unwrap_or(gdk::RGBA::WHITE)
}

/// Every web view that shows or writes a message given the [`background`] of now
pub fn update_backgrounds() {
    let color = background();
    each_message_view(|view| view.set_background_color(&color));
}

/// The web views follow the style of the windows: their background changes with it. The documents change by
/// themselves: WebKit's `prefers-color-scheme` follows the style libadwaita gives the windows (and printing is light,
/// the dark styles being for the screen only)
pub fn follow_style() {
    adw::StyleManager::default().connect_dark_notify(|_| update_backgrounds());
}

impl DocumentView {
    /// `kind` names the documents (`preview`, `help`, `compose`); `javascript` for the editor only
    pub fn new(kind: &'static str, javascript: bool) -> DocumentView {
        let web = web();
        let manager = webkit::UserContentManager::new();
        let view = webkit::WebView::builder()
            .web_context(&web.context)
            .network_session(&web.session)
            .settings(&settings(javascript, kind == "preview"))
            .user_content_manager(&manager)
            .build();
        view.set_vexpand(true);
        view.set_hexpand(true);
        if kind == "preview" || kind == "compose" {
            view.set_zoom_level(crate::app::shell().core.text_zoom());
            view.set_background_color(&background());
            MESSAGE_VIEWS.with(|views| views.borrow_mut().push(view.downgrade()));
        }
        let current: Rc<RefCell<String>> = Rc::default();
        let own = current.clone();
        let links: Links = Rc::default();
        let asked = links.clone();
        view.connect_decide_policy(move |view, decision, kind| decide(view, decision, kind, &own.borrow(), &asked));
        // no window opens from a document
        view.connect_create(|_, _| None);
        // the page's own menu without what makes no sense here (reload, back, inspect)
        view.connect_context_menu(|_, menu, hit| {
            keep_useful(menu, hit);
            false
        });
        let measuring: Rc<Cell<bool>> = Rc::default();
        let measure = measuring.clone();
        let scroll_back: Rc<RefCell<Option<(String, webkit::UserScript)>>> = Rc::default();
        let scrolled = scroll_back.clone();
        let scripts = manager.clone();
        view.connect_load_changed(move |view, event| {
            if event != webkit::LoadEvent::Finished {
                return;
            }
            if measure.get() {
                size_frames(view);
            }
            // the document is where the one before was: the script is not for the next one (a document before it that
            // stopped loading finishes too)
            let done = scrolled
                .borrow()
                .as_ref()
                .is_some_and(|(uri, _)| view.uri().is_some_and(|shown| shown == *uri));
            if done && let Some((_, script)) = scrolled.borrow_mut().take() {
                scripts.remove_script(&script);
            }
        });
        DocumentView {
            view,
            manager,
            kind,
            current,
            links,
            measuring,
            measure_timer: Rc::default(),
            asked: Rc::default(),
            scroll_back,
        }
    }

    /// The frames of the document shown (a signed or encrypted message's parts) sized to their documents with the
    /// core's script: once the page has loaded, then every 400 ms (pictures loading, "..." unfolded, the width or the
    /// text size changed) until another document is shown or the view goes; `on` false stops it
    pub fn measure_frames(&self, on: bool) {
        if let Some(timer) = self.measure_timer.borrow_mut().take() {
            timer.remove();
        }
        self.measuring.set(on);
        if !on {
            return;
        }
        if !self.view.is_loading() {
            size_frames(&self.view);
        }
        let view = self.view.downgrade();
        let measuring = self.measuring.clone();
        let timer = glib::timeout_add_local(std::time::Duration::from_millis(400), move || match view.upgrade() {
            Some(view) if measuring.get() => {
                size_frames(&view);
                glib::ControlFlow::Continue
            }
            _ => glib::ControlFlow::Break,
        });
        self.measure_timer.replace(Some(timer));
    }

    /// `links` is asked of a link clicked in the document before the browser opens it: true when it took the link
    /// itself, which the browser then does not open
    pub fn set_links(&self, links: impl Fn(&str) -> bool + 'static) {
        *self.links.borrow_mut() = Some(Rc::new(links));
    }

    pub fn manager(&self) -> &webkit::UserContentManager {
        &self.manager
    }

    /// Shows `document`, with the message's pictures from the internet only when `remote_images`
    pub fn show(&self, document: &str, remote_images: bool) {
        self.show_parts(document, &[], None, remote_images);
    }

    /// Shows `document` whose frames show `parts` (a signed or encrypted message's) and whose previews are under the
    /// token `previews` (the view's), with the message's pictures from the internet only when `remote_images`
    pub fn show_parts(&self, document: &str, parts: &[String], previews: Option<&str>, remote_images: bool) {
        self.ask();
        self.load(document, parts, previews, remote_images, 0.0);
    }

    /// Another document asked for: the one waiting for its scroll dropped, the frames of the one before no longer
    /// measured (the owner turns it on for the new one right after)
    fn ask(&self) -> u64 {
        let asked = self.asked.get() + 1;
        self.asked.set(asked);
        self.measure_frames(false);
        asked
    }

    /// Shows `document` (the same message's again: Show in Message, its whole source after its text, its pictures
    /// allowed) scrolled to where the one shown was, so its text does not move: the core's script reads how far down
    /// it is, and the new one is scrolled there as it loads, before it is drawn
    pub fn show_in_place(&self, document: &str, parts: &[String], previews: Option<&str>, remote_images: bool) {
        let asked = self.ask();
        let (document, parts, previews) = (document.to_string(), parts.to_vec(), previews.map(str::to_string));
        let this = self.clone();
        self.view.evaluate_javascript(
            pe_html::SCROLL_SCRIPT,
            None,
            None,
            gio::Cancellable::NONE,
            move |value| {
                // another document was asked for meanwhile
                if this.asked.get() != asked {
                    return;
                }
                let y = value.ok().and_then(|v| v.to_str().parse::<f64>().ok()).unwrap_or(0.0);
                this.load(&document, &parts, previews.as_deref(), remote_images, y);
            },
        );
    }

    /// The document served and loaded once the rules are there, scrolled down `y` CSS pixels as it loads
    fn load(&self, document: &str, parts: &[String], previews: Option<&str>, remote_images: bool, y: f64) {
        let web = web();
        let previous = self.current.borrow().clone();
        let uri = web.serve(
            self.kind,
            document,
            parts,
            previews,
            (!previous.is_empty()).then_some(previous.as_str()),
        );
        *self.current.borrow_mut() = uri.clone();
        let this = self.clone();
        web.when_ready(move || {
            // a later document took this one's place meanwhile
            if *this.current.borrow() != uri {
                return;
            }
            let rules = self::web();
            if let Some((blocked, allowing)) = &*rules.filters.borrow() {
                this.manager.remove_all_filters();
                this.manager.add_filter(if remote_images { allowing } else { blocked });
            }
            if let Some((_, script)) = this.scroll_back.borrow_mut().take() {
                this.manager.remove_script(&script);
            }
            if y > 0.0 {
                // when the document is parsed, before it is drawn; its pictures' sizes are in its markup
                let script = webkit::UserScript::new(
                    &pe_html::scroll_to_script(y),
                    webkit::UserContentInjectedFrames::TopFrame,
                    webkit::UserScriptInjectionTime::End,
                    &[],
                    &[],
                );
                this.manager.add_script(&script);
                this.scroll_back.replace(Some((uri.clone(), script)));
            }
            this.view.load_uri(&uri);
        });
    }

    /// What the e2e driver checks: the document shown
    #[cfg(feature = "e2e")]
    pub fn shown(&self) -> String {
        web()
            .document(&self.current.borrow())
            .map(|d| d.to_string())
            .unwrap_or_default()
    }

    /// What the e2e driver checks: the document shown and the documents of its parts
    #[cfg(feature = "e2e")]
    pub fn shown_with_parts(&self) -> String {
        let current = self.current.borrow();
        let documents = web()
            .documents
            .borrow()
            .get(current.as_str())
            .map(|s| (s.page.clone(), s.parts.clone()));
        documents
            .map(|(page, parts)| format!("{page}{}", parts.join("")))
            .unwrap_or_default()
    }

    /// The document dropped (the view is going away)
    pub fn release(&self) {
        self.measure_frames(false);
        web().forget(&self.current.borrow());
    }
}

/// The core's script that makes each frame of the page as tall as its document, run as the app's (the page's own
/// scripts stay off)
fn size_frames(view: &webkit::WebView) {
    view.evaluate_javascript(pe_html::MEASURE_SCRIPT, None, None, gio::Cancellable::NONE, |_| {});
}

/// What a document may do: show itself (and its own anchors), nothing else; a link the user follows opens in the
/// browser, unless `links` takes it
fn decide(
    view: &webkit::WebView,
    decision: &webkit::PolicyDecision,
    kind: webkit::PolicyDecisionType,
    own: &str,
    links: &Links,
) -> bool {
    use webkit::PolicyDecisionType as Kind;
    match kind {
        Kind::NavigationAction | Kind::NewWindowAction => {
            let action = decision
                .downcast_ref::<webkit::NavigationPolicyDecision>()
                .and_then(|navigation| navigation.navigation_action());
            let uri = action
                .as_ref()
                .and_then(|action| action.request())
                .and_then(|request| request.uri())
                .map(|uri| uri.to_string())
                .unwrap_or_default();
            let same = uri.split('#').next() == Some(own);
            // a frame of the page loading its part's document beside it, never a link the user followed
            let frame = !own.is_empty()
                && uri.starts_with(own)
                && pe_html::part_document(&uri).is_some()
                && action
                    .as_ref()
                    .is_some_and(|action| action.navigation_type() == webkit::NavigationType::Other);
            if kind == Kind::NavigationAction && (same || frame) {
                decision.use_();
            } else {
                decision.ignore();
                // taken out first: the owner may show another document in this view
                let links = links.borrow().clone();
                let taken = links.is_some_and(|links| links(&uri));
                if !taken && !same {
                    crate::ui::open_externally(&uri, crate::ui::window_of(view).as_ref());
                }
            }
            true
        }
        _ => false,
    }
}

/// The items of a page's context menu that do something here: copying, selecting, the editing ones and the spelling
/// guesses of the editor. On an attachment's preview not its link (the app's own, opening the file) and only Copy
/// Image of the picture (saving or opening it would give the app's copy, not the file)
fn keep_useful(menu: &webkit::ContextMenu, hit: &webkit::HitTestResult) {
    use webkit::ContextMenuAction as Action;
    let preview = hit.link_uri().is_some_and(|uri| pe_html::is_preview_link(&uri));
    let items = menu.items();
    for item in items {
        let keep = !(preview && item.stock_action() == Action::CopyLinkToClipboard)
            && matches!(
                item.stock_action(),
                Action::Copy
                    | Action::CopyLinkToClipboard
                    | Action::CopyImageToClipboard
                    | Action::Cut
                    | Action::Paste
                    | Action::PasteAsPlainText
                    | Action::Delete
                    | Action::SelectAll
                    | Action::SpellingGuess
                    | Action::IgnoreSpelling
                    | Action::LearnSpelling
                    | Action::NoGuessesFound
                    | Action::Custom
            );
        if !keep {
            menu.remove(&item);
        }
    }
}

/// `value` as a JavaScript string literal: everything but plain letters, digits and spaces escaped (as UTF-16 code
/// units), so no value can end the string
pub fn js_string(value: &str) -> String {
    let mut out = String::with_capacity(value.len() + 2);
    out.push('\'');
    for unit in value.encode_utf16() {
        match char::from_u32(u32::from(unit)) {
            Some(c) if c.is_ascii_alphanumeric() || c == ' ' => out.push(c),
            _ => out.push_str(&format!("\\u{unit:04x}")),
        }
    }
    out.push('\'');
    out
}

/// The page of a reading pane with no message: the core's, saying so, or an empty one while a message is coming
pub fn no_message(say_so: bool) -> String {
    if say_so {
        return pe_core::reader_page(pe_core::ReaderState::NoMessage);
    }
    // dark in a dark window too, as the documents are, while messages may be dark
    let (scheme, dark) = if pe_html::dark() {
        (
            "light dark",
            format!("@media screen and (prefers-color-scheme:dark){{html{{background:{DARK_BACKGROUND}}}}}"),
        )
    } else {
        ("light", String::new())
    };
    format!(
        "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"color-scheme\" content=\"{scheme}\">\
         <style>html{{background:#fff}}{dark}</style></head><body></body></html>"
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn values_can_not_end_their_string() {
        assert_eq!(js_string("bold"), "'bold'");
        assert_eq!(js_string("a'b"), "'a\\u0027b'");
        assert_eq!(js_string("</script>"), "'\\u003c\\u002fscript\\u003e'");
        assert_eq!(js_string("\u{1F600}"), "'\\ud83d\\ude00'");
    }
}
