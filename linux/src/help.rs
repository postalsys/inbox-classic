//! The help window: the core's help page for Linux (pe_html::help_page, core/crates/pe-html/src/help.html), shown in
//! a web view like a message (scripts off, links opened in the browser). One window; F1 again brings it to the front.

use std::cell::RefCell;

use adw::prelude::*;

use crate::app::shell;
use crate::webview::DocumentView;

thread_local! {
    static HELP: RefCell<Option<adw::ApplicationWindow>> = const { RefCell::new(None) };
}

pub fn open() {
    if let Some(window) = HELP.with(|help| help.borrow().clone()) {
        window.present();
        return;
    }
    let view = DocumentView::new("help", false);
    view.show(&pe_html::help_page(pe_html::Platform::Linux), false);
    let toolbar = adw::ToolbarView::new();
    toolbar.add_top_bar(&adw::HeaderBar::new());
    toolbar.set_content(Some(&view.view));
    // not owned by the main window: the help stays usable while a dialog of the main window is open
    let window = adw::ApplicationWindow::builder()
        .application(&shell().application)
        .title(t!(UiHelpTitle))
        .default_width(820)
        .default_height(700)
        .content(&toolbar)
        .build();
    window.set_widget_name("help-window");
    window.connect_close_request(move |_| {
        view.release();
        HELP.with(|help| help.borrow_mut().take());
        glib::Propagation::Proceed
    });
    HELP.with(|help| *help.borrow_mut() = Some(window.clone()));
    window.present();
}

pub fn close() {
    if let Some(window) = HELP.with(|help| help.borrow().clone()) {
        window.close();
    }
}

use gtk::glib;
