//! The printout of a message with previews (docs/attachment-preview-plan.md, decision 5): its pictures print, put in
//! the print document as `data:` addresses of the core's own encodes (the print windows serve nothing but the page);
//! a PDF file, or a file shown as a tile, is not printed and a line names it. The pictures of its text (`cid:`,
//! `data:`, decision 8) print where the text shows them, the core's encodes too. The pictures are drawn first, if the
//! reading pane has not had them drawn already, off the window thread; [`Event::PrintReady`] says when the document
//! is there.

use std::collections::HashMap;
use std::sync::Arc;
use std::sync::atomic::Ordering;
use std::time::{Duration, Instant};

use pe_i18n::{Text, tr_args};

use super::{Files, PreviewDocument, PreviewFile, lock, lock_shown, unpoisoned};
use crate::connections::Connection;
use crate::{Core, Event};

/// The longest a printout waits for its pictures: one not drawn by then is named in a line
const PRINT_WAIT: Duration = Duration::from_secs(30);

/// What a printout is made of, taken from the view while it is shown
struct Printout {
    parts: pe_html::PrintParts,
    /// The files shown, each with the part whose document shows it (None for a message's one document)
    files: Vec<(Option<usize>, pe_html::PreviewFile)>,
    /// The numbers of the pictures of the message's text; none for a message with signed or encrypted parts, whose
    /// parts print as their words
    inline: Vec<usize>,
    /// The request drawing the pictures; None when the document has none
    request: Option<u64>,
}

/// Printouts kept for a window to take: one nobody takes (its window closed or showed another message first) gives
/// way to newer ones, so none is kept until the app quits
const PRINTOUTS_KEPT: usize = 8;

/// Keeps a printout of the view `token` for its window, dropping the oldest past [`PRINTOUTS_KEPT`] (requests only
/// grow); one whose view ended is dropped then
fn keep_printout(prints: &mut HashMap<u64, (String, String)>, request: u64, token: String, document: String) {
    prints.insert(request, (token, document));
    while prints.len() > PRINTOUTS_KEPT {
        let Some(oldest) = prints.keys().min().copied() else {
            break;
        };
        prints.remove(&oldest);
    }
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
            let inline: Vec<usize> = view
                .documents
                .iter()
                .filter(|document| document.part.is_none())
                .flat_map(|document| document.inline.iter().map(|inline| inline.picture.number))
                .collect();
            let pictures = view.files().any(is_printed_picture) || !inline.is_empty();
            Printout {
                parts,
                files: view.documents.iter().flat_map(printed_files).collect(),
                inline,
                request: if pictures { self.shown_request(view) } else { None },
            }
        };
        let print = self.next_request.fetch_add(1, Ordering::Relaxed);
        let token = token.to_string();
        let work = self.in_background(Connection::Reads, move |core| {
            let document = printed(&core.previews.files, &printout);
            keep_printout(&mut unpoisoned(&core.previews.prints), print, token, document);
            let _ = core.post(Event::PrintReady { request: print });
        });
        self.runtime().ok()?.spawn(work);
        Some(print)
    }

    /// The document of a printout [`Core::print_start`] made, once, after its [`Event::PrintReady`]
    pub fn print_result(&self, request: u64) -> Option<String> {
        unpoisoned(&self.previews.prints)
            .remove(&request)
            .map(|(_, document)| document)
    }
}

/// A document's files as the printout names them: a part's under its part's name ("Part 2: photo.jpg"), as every
/// part's text is printed in one document
fn printed_files(document: &PreviewDocument) -> Vec<(Option<usize>, pe_html::PreviewFile)> {
    let mut files = document.files.clone();
    if let Some(part) = document.part {
        let name = tr_args(Text::HeaderPart, &[("number", (part + 1).into())]);
        for file in &mut files {
            file.name = format!("{name}: {}", file.name);
        }
    }
    files.into_iter().map(|file| (document.part, file)).collect()
}

/// A file the printout shows as a picture: a picture drawn in the document (not a PDF file's page, not a tile)
fn is_printed_picture(file: &pe_html::PreviewFile) -> bool {
    !file.paper && file.tile.is_none() && !file.pages.is_empty()
}

/// The document to print: the message, then each picture drawn and a line for every other file shown; in a message
/// with signed or encrypted parts each part's after that part's text
fn printed(files: &Files, printout: &Printout) -> String {
    let drawn = match printout.request {
        Some(request) => {
            let wanted: Vec<usize> = printout
                .files
                .iter()
                .map(|(_, file)| file)
                .filter(|file| is_printed_picture(file))
                .map(|file| file.attachment)
                .chain(printout.inline.iter().copied())
                .collect();
            wait_drawn(files, request, &wanted, Instant::now() + PRINT_WAIT)
        }
        None => HashMap::new(),
    };
    let lines: Vec<String> = printout
        .files
        .iter()
        .map(|(_, file)| {
            tr_args(
                Text::PreviewNotPrinted,
                &[("name", (&file.name).into()), ("details", (&file.details).into())],
            )
        })
        .collect();
    let first_page = |number: usize| drawn.get(&number).and_then(|drawn| drawn.pages.get(&0)?.as_ref().ok());
    let inline = printout.inline.iter().filter_map(|&number| {
        let picture = first_page(number)?;
        let item = pe_html::PrintItem::Inline {
            number,
            mime: picture.mime.as_str(),
            bytes: &picture.bytes,
        };
        Some((None, item))
    });
    let items: Vec<(Option<usize>, pe_html::PrintItem)> = printout
        .files
        .iter()
        .zip(&lines)
        .map(|((part, file), line)| {
            // only the printed pictures were waited for
            let picture = first_page(file.attachment);
            let item = match picture {
                Some(picture) => pe_html::PrintItem::Picture {
                    name: &file.name,
                    mime: picture.mime.as_str(),
                    bytes: &picture.bytes,
                },
                None => pe_html::PrintItem::Line(line),
            };
            (*part, item)
        })
        .chain(inline)
        .collect();
    pe_html::print_document_with(&printout.parts, &items)
}

/// What `request` drew of the files `wanted` (attachments, pictures of the text) by `until`: each file once it is
/// done, or as far as it came
fn wait_drawn(files: &Files, request: u64, wanted: &[usize], until: Instant) -> HashMap<usize, PreviewFile> {
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

#[cfg(test)]
mod keep_tests {
    use super::*;

    #[test]
    fn printouts_nobody_takes_give_way_to_newer_ones() {
        let mut prints = HashMap::new();
        for request in 1..=(PRINTOUTS_KEPT as u64 + 3) {
            keep_printout(&mut prints, request, "t".into(), format!("doc {request}"));
        }
        assert_eq!(prints.len(), PRINTOUTS_KEPT);
        assert!(!prints.contains_key(&3) && prints.contains_key(&4));
        assert!(prints.contains_key(&(PRINTOUTS_KEPT as u64 + 3)));
    }
}
