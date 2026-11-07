//! The web views, locked down the way the Windows app locks WebView2 down: the core's documents are served from the
//! app's own scheme (`inboxclassic://preview/<n>`, `inboxclassic://compose/<n>`, `inboxclassic://help/`) out of
//! memory, every other load is blocked by the content rules the core gives (only the pictures of a message the user
//! allowed get through), nothing navigates away from the document, links open in the browser, no window opens, no
//! dev tools, an ephemeral network session (nothing on disk). JavaScript is off but in the editor, whose page runs
//! only its own script (allowed by a nonce in its CSP).

use std::cell::{Cell, RefCell};
use std::collections::HashMap;
use std::rc::Rc;

use gtk::prelude::*;
use gtk::{gio, glib};
use webkit::prelude::*;

/// One web context, network session and pair of content rules for all the app's web views
pub struct Web {
    context: webkit::WebContext,
    session: webkit::NetworkSession,
    /// The documents the scheme serves, by their URI
    documents: RefCell<HashMap<String, Rc<str>>>,
    next: Cell<u64>,
    /// The rules that block every load, and those that let a message's pictures through; None until compiled
    filters: RefCell<Option<(webkit::UserContentFilter, webkit::UserContentFilter)>>,
    /// Loads waiting for the rules: no document is shown without them
    waiting: RefCell<Vec<Box<dyn FnOnce()>>>,
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
        });
        let served = Rc::downgrade(&web);
        context.register_uri_scheme(pe_html::DOCUMENT_SCHEME, move |request| {
            let document = served
                .upgrade()
                .and_then(|web| web.document(&request.uri().unwrap_or_default()));
            match document {
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

    fn document(&self, uri: &str) -> Option<Rc<str>> {
        let uri = uri.split('#').next().unwrap_or(uri);
        self.documents.borrow().get(uri).cloned()
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

    /// A new URI under `kind` serving `document`, and the one it replaces given up
    fn serve(&self, kind: &str, document: &str, replaces: Option<&str>) -> String {
        let n = self.next.get() + 1;
        self.next.set(n);
        let uri = format!("{}://{kind}/{n}", pe_html::DOCUMENT_SCHEME);
        let mut documents = self.documents.borrow_mut();
        if let Some(old) = replaces {
            documents.remove(old);
        }
        documents.insert(uri.clone(), Rc::from(document));
        uri
    }

    fn forget(&self, uri: &str) {
        self.documents.borrow_mut().remove(uri);
    }
}

/// The settings of every web view: `javascript` only for the editor
fn settings(javascript: bool) -> webkit::Settings {
    let settings = webkit::Settings::new();
    settings.set_enable_javascript(javascript);
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
    /// What "Show the message that bounced" on a bounce's card does; nothing without it
    bounced: Bounced,
}

/// The handler of the link of a bounce's card, shared by the view and its policy decisions
type Bounced = Rc<RefCell<Option<Rc<dyn Fn()>>>>;

impl DocumentView {
    /// `kind` names the documents (`preview`, `help`, `compose`); `javascript` for the editor only
    pub fn new(kind: &'static str, javascript: bool) -> DocumentView {
        let web = web();
        let manager = webkit::UserContentManager::new();
        let view = webkit::WebView::builder()
            .web_context(&web.context)
            .network_session(&web.session)
            .settings(&settings(javascript))
            .user_content_manager(&manager)
            .build();
        view.set_vexpand(true);
        view.set_hexpand(true);
        let current: Rc<RefCell<String>> = Rc::default();
        let own = current.clone();
        let bounced: Bounced = Rc::default();
        let link = bounced.clone();
        view.connect_decide_policy(move |view, decision, kind| decide(view, decision, kind, &own.borrow(), &link));
        // no window opens from a document
        view.connect_create(|_, _| None);
        // the page's own menu without what makes no sense here (reload, back, inspect)
        view.connect_context_menu(|_, menu, _| {
            keep_useful(menu);
            false
        });
        DocumentView {
            view,
            manager,
            kind,
            current,
            bounced,
        }
    }

    /// `show` runs when "Show the message that bounced" on a bounce's card is clicked; the link itself says nothing,
    /// the owner knows the message from the view it shows
    pub fn on_bounced_message(&self, show: impl Fn() + 'static) {
        *self.bounced.borrow_mut() = Some(Rc::new(show));
    }

    pub fn manager(&self) -> &webkit::UserContentManager {
        &self.manager
    }

    /// Shows `document`, with the message's pictures from the internet only when `remote_images`
    pub fn show(&self, document: &str, remote_images: bool) {
        let web = web();
        let previous = self.current.borrow().clone();
        let uri = web.serve(self.kind, document, (!previous.is_empty()).then_some(previous.as_str()));
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

    /// The document dropped (the view is going away)
    pub fn release(&self) {
        web().forget(&self.current.borrow());
    }
}

/// What a document may do: show itself (and its own anchors), nothing else; a link the user follows opens in the
/// browser, but the link of a bounce's card, which goes to `bounced`
fn decide(
    view: &webkit::WebView,
    decision: &webkit::PolicyDecision,
    kind: webkit::PolicyDecisionType,
    own: &str,
    bounced: &Bounced,
) -> bool {
    use webkit::PolicyDecisionType as Kind;
    match kind {
        Kind::NavigationAction | Kind::NewWindowAction => {
            let uri = decision
                .downcast_ref::<webkit::NavigationPolicyDecision>()
                .and_then(|navigation| navigation.navigation_action())
                .and_then(|action| action.request())
                .and_then(|request| request.uri())
                .map(|uri| uri.to_string())
                .unwrap_or_default();
            let same = uri.split('#').next() == Some(own);
            if kind == Kind::NavigationAction && same {
                decision.use_();
            } else {
                decision.ignore();
                if pe_html::is_bounced_message_link(&uri) {
                    // taken out first: the handler may show another document in this view
                    let show = bounced.borrow().clone();
                    if let Some(show) = show {
                        // after this signal, as the view may be asked to load meanwhile
                        glib::idle_add_local_once(move || show());
                    }
                } else if !same {
                    crate::ui::open_externally(&uri, crate::ui::window_of(view).as_ref());
                }
            }
            true
        }
        _ => false,
    }
}

/// The items of a page's context menu that do something here: copying, selecting, the editing ones and the spelling
/// guesses of the editor
fn keep_useful(menu: &webkit::ContextMenu) {
    use webkit::ContextMenuAction as Action;
    let items = menu.items();
    for item in items {
        let keep = matches!(
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
        pe_core::reader_page(pe_core::ReaderState::NoMessage)
    } else {
        "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"color-scheme\" content=\"light\">\
         <style>html{background:#fff}</style></head><body></body></html>"
            .into()
    }
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
