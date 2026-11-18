//! The printout of a message with previews (docs/attachment-preview-plan.md, decision 5): its pictures print, put in
//! the print document as `data:` addresses of the core's own encodes (the print windows serve nothing but the page);
//! a PDF file, or a file shown as a tile, is not printed and a line names it. The pictures are drawn first, if the
//! reading pane has not had them drawn already, off the window thread; [`Event::PrintReady`] says when the document
//! is there.

use std::collections::HashMap;
use std::sync::Arc;
use std::sync::atomic::Ordering;
use std::time::{Duration, Instant};

use pe_i18n::{Text, tr_args};

use super::{Files, PreviewFile, lock, lock_shown, unpoisoned};
use crate::connections::Connection;
use crate::{Core, Event};

/// The longest a printout waits for its pictures: one not drawn by then is named in a line
const PRINT_WAIT: Duration = Duration::from_secs(30);

/// What a printout is made of, taken from the view while it is shown
struct Printout {
    parts: pe_html::PrintParts,
    files: Vec<pe_html::PreviewFile>,
    /// The request drawing the pictures; None when the document has none
    request: Option<u64>,
}

impl Core {
    /// Starts the printout of the view `token`: [`Event::PrintReady`] follows with the request this returns, and
    /// [`Core::print_result`] gives the document to print. None for a view that shows no previews (or is not shown):
    /// its `print_document` is printed as it is
    pub fn print_start(self: &Arc<Self>, token: &str) -> Option<u64> {
        let printout = {
            let mut shown = lock_shown(&self.previews.shown);
            let view = shown.iter_mut().find(|shown| shown.token == token)?;
            let parts = view.print.clone()?;
            let pictures = view.files.iter().any(is_printed_picture);
            Printout {
                parts,
                files: view.files.clone(),
                request: if pictures { self.shown_request(view) } else { None },
            }
        };
        let print = self.next_request.fetch_add(1, Ordering::Relaxed);
        let work = self.in_background(Connection::Reads, move |core| {
            let document = printed(&core.previews.files, &printout);
            unpoisoned(&core.previews.prints).insert(print, document);
            let _ = core.post(Event::PrintReady { request: print });
        });
        self.runtime().ok()?.spawn(work);
        Some(print)
    }

    /// The document of a printout [`Core::print_start`] made, once, after its [`Event::PrintReady`]
    pub fn print_result(&self, request: u64) -> Option<String> {
        unpoisoned(&self.previews.prints).remove(&request)
    }
}

/// A file the printout shows as a picture: a picture drawn in the document (not a PDF file's page, not a tile)
fn is_printed_picture(file: &pe_html::PreviewFile) -> bool {
    !file.paper && file.tile.is_none() && !file.pages.is_empty()
}

/// The document to print: the message, then each picture drawn and a line for every other file shown
fn printed(files: &Files, printout: &Printout) -> String {
    let drawn = match printout.request {
        Some(request) => wait_drawn(files, request, &printout.files, Instant::now() + PRINT_WAIT),
        None => HashMap::new(),
    };
    let lines: Vec<String> = printout
        .files
        .iter()
        .map(|file| {
            tr_args(
                Text::PreviewNotPrinted,
                &[("name", (&file.name).into()), ("details", (&file.details).into())],
            )
        })
        .collect();
    let items: Vec<pe_html::PrintItem> = printout
        .files
        .iter()
        .zip(&lines)
        .map(|(file, line)| {
            // only the printed pictures were waited for
            let picture = drawn
                .get(&file.attachment)
                .and_then(|drawn| drawn.pages.get(&0)?.as_ref().ok());
            match picture {
                Some(picture) => pe_html::PrintItem::Picture {
                    name: &file.name,
                    mime: picture.mime.as_str(),
                    bytes: &picture.bytes,
                },
                None => pe_html::PrintItem::Line(line),
            }
        })
        .collect();
    pe_html::print_document_with(&printout.parts, &items)
}

/// The pictures of `shown` that `request` drew by `until`: each file once it is done, or as far as it came
fn wait_drawn(
    files: &Files,
    request: u64,
    shown: &[pe_html::PreviewFile],
    until: Instant,
) -> HashMap<usize, PreviewFile> {
    let wanted: Vec<usize> = shown
        .iter()
        .filter(|file| is_printed_picture(file))
        .map(|file| file.attachment)
        .collect();
    let mut map = lock(files);
    loop {
        let done = wanted.iter().all(|attachment| {
            map.get(&(request, *attachment))
                .is_none_or(|file| file.done || file.pages.contains_key(&0))
        });
        let left = until.saturating_duration_since(Instant::now());
        if done || left.is_zero() {
            return wanted
                .iter()
                .filter_map(|attachment| Some((*attachment, map.get(&(request, *attachment))?.clone())))
                .collect();
        }
        map = files
            .changed
            .wait_timeout(map, left)
            .map(|(map, _)| map)
            .unwrap_or_else(|p| p.into_inner().0);
    }
}
