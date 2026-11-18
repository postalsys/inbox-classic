//! What the tests of previews share

use std::sync::mpsc::Receiver;
use std::time::{Duration, Instant};

use pe_core::{Core, Event, MessageView};

/// The view `build` makes as a window shows it once its files are all described: while it has "Preparing…" tiles
/// (files not described in time, as on a busy runner), built again when the core says they are
/// ([`Event::PreviewsPrepared`]), as the windows do, the view before it then ended
pub fn settled(core: &Core, events: &Receiver<Event>, build: impl Fn() -> MessageView) -> MessageView {
    let mut view = build();
    while view.preparing {
        let token = view.preview_token.clone().expect("a view with previews has a token");
        let until = Instant::now() + Duration::from_secs(120);
        loop {
            match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
                Ok(Event::PreviewsPrepared { token: of }) if of == token => break,
                Ok(_) => {}
                Err(error) => panic!("the files of view {token} not prepared: {error}"),
            }
        }
        let again = build();
        core.previews_end(&token);
        view = again;
    }
    view
}
