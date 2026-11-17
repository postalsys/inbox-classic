//! What draws a file on the render thread: [`Real`] (the `image` crate and hayro), or a fake in tests that hangs or
//! panics

use std::sync::Arc;

use crate::limits::MAX_PAGES;
use crate::{Description, Kind, Picture, Refusal, pdf, picture};

/// Draws a file, step by step
pub trait Engine: Send + Sync + 'static {
    /// Draws `file`, a `kind` file: its description first, then the pages `pages` (none: described only) while their
    /// pixels fit in `budget`, each step told to `emit`, which says whether to go on (false: the request was
    /// cancelled, stop). [`Step::Started`] comes before each part with a time limit
    fn run(&self, kind: Kind, file: &Arc<Vec<u8>>, pages: &[usize], budget: u64, emit: &mut dyn FnMut(Step) -> bool);
}

/// A step of a render
#[derive(Debug)]
pub enum Step {
    /// A part with a time limit starts: a page of a PDF (opening it counts as its first), or a whole picture
    Started(Kind),
    /// The file read: a refusal ends it
    Described(Result<Description, Refusal>),
    Page(usize, Result<Picture, Refusal>),
}

/// The engine of the app: pictures with the `image` crate, PDF files with hayro
pub struct Real;

impl Engine for Real {
    fn run(&self, kind: Kind, file: &Arc<Vec<u8>>, pages: &[usize], budget: u64, emit: &mut dyn FnMut(Step) -> bool) {
        if !emit(Step::Started(kind)) {
            return;
        }
        match kind {
            Kind::Picture => run_picture(file, pages, budget, emit),
            Kind::Pdf => run_pdf(file, pages, budget, emit),
        }
    }
}

fn run_picture(file: &[u8], pages: &[usize], budget: u64, emit: &mut dyn FnMut(Step) -> bool) {
    let description = picture::describe(file);
    let size = description.as_ref().ok().and_then(|d| d.sizes.first().copied());
    if !emit(Step::Described(description)) || !pages.contains(&0) {
        return;
    }
    let mut left = budget;
    if let Some(size) = size {
        let page = page_fits(size, &mut left).and_then(|()| picture::render(file));
        emit(Step::Page(0, page));
    }
}

fn run_pdf(file: &Arc<Vec<u8>>, pages: &[usize], budget: u64, emit: &mut dyn FnMut(Step) -> bool) {
    let document = match pdf::Document::open(file.clone()) {
        Ok(document) => document,
        Err(refusal) => {
            emit(Step::Described(Err(refusal)));
            return;
        }
    };
    let description = document.describe();
    let sizes = description.sizes.clone();
    if !emit(Step::Described(Ok(description))) {
        return;
    }
    let drawn = document.pages();
    let mut left = budget;
    for &index in pages.iter().filter(|&&index| index < MAX_PAGES) {
        let Some(&size) = sizes.get(index) else {
            continue;
        };
        let page = match page_fits(size, &mut left) {
            Ok(()) => {
                if !emit(Step::Started(Kind::Pdf)) {
                    return;
                }
                drawn.render(index)
            }
            Err(refusal) => Err(refusal),
        };
        if !emit(Step::Page(index, page)) {
            return;
        }
    }
}

/// Whether a preview of `size` (None: a page of no size) fits in what is `left` of the budget, which it then takes
fn page_fits(size: Option<(u32, u32)>, left: &mut u64) -> Result<(), Refusal> {
    let (width, height) = size.ok_or(Refusal::TooLarge)?;
    let pixels = u64::from(width) * u64::from(height);
    if pixels > *left {
        return Err(Refusal::OverBudget);
    }
    *left -= pixels;
    Ok(())
}
