//! Which of a message's files the reading pane shows after its text, and how (docs/attachment-preview-plan.md): drawn,
//! as a tile that says why not, counted in the line of files left out, or not at all; and what the strip's Show in
//! Message says of each.

use std::collections::BTreeSet;
use std::sync::Arc;
use std::time::{Duration, Instant};

use pe_i18n::{Text, tr, tr_args};
use pe_preview::limits::{MAX_FILE, MAX_PREVIEWS};

use super::preparing::{Described, Late};
use super::{DESCRIBE, PREVIEW_PAGES, Preparing, PreviewDescription, PreviewRefusal};
use crate::Core;
use crate::opening::FileKind;
use crate::view;

/// What the strip's Show in Message says of a file
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum ShowInMessage {
    /// Not a picture or PDF file: no such command for it
    #[default]
    None,
    /// Drawn in the message: checked, and choosing it takes the file out of the message
    On,
    /// Not drawn, and it can be (left out by the setting, past the message's budget, or taken out): unchecked, and
    /// choosing it draws the file in the message
    Off,
    /// A tile that can not be drawn (a HEIC picture, a PDF file with a password, a file too large, one still
    /// downloading or being prepared): the command is greyed
    Unavailable,
}

/// What the user chose with Show in Message for a message while it is shown, never kept: the files drawn although
/// the setting or the budget leaves them out, and those taken out
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub(crate) struct Choices {
    pub shown: BTreeSet<usize>,
    pub hidden: BTreeSet<usize>,
}

/// How the view shows a message's pictures and PDF files after its text ([`Core::preview_plan`])
pub(crate) struct PreviewPlan<'a> {
    /// The core whose render thread reads the files' descriptions
    pub core: &'a Core,
    /// Where the message is, as a crash marker names it (`PreviewSource::about`): a decrypted part's file is named by
    /// it, never by its bytes ([`pe_preview::key_of_place`])
    pub about: String,
    /// Options' "Show attachments in messages": files drawn without the user asking
    pub auto: bool,
    /// PDF files are drawn
    pub pdfs: bool,
    /// What the section says when PDF files are not drawn because one ended the app ([`Core::previews_notice`])
    pub notice: Option<String>,
    /// The user's Show in Message choices for this message
    pub choices: Choices,
    /// A large message's text shown first: its files are not here yet; their sizes, in the strip's order
    pub downloading: Option<Vec<u64>>,
    /// What came of the files an earlier view of the message did not have described in time
    pub late: Late,
    /// The files of this view not described in time, shown as "Preparing…" until they are
    pub preparing: Arc<Preparing>,
}

impl PreviewPlan<'_> {
    /// Gives `view` (built with this plan) its files not described in time, for the window to be told of them
    pub(crate) fn preparing_of(&self, view: &mut crate::MessageView) {
        view.preparing = self.preparing.has_missed();
        view.preview_preparing = Some(self.preparing.clone());
    }
}

/// What the view takes of the plan: the section for pe-html, and Show in Message for each listed attachment
pub(crate) struct Planned {
    pub section: pe_html::PreviewSection,
    pub states: Vec<ShowInMessage>,
}

/// What comes of one file
enum Fate {
    /// Not a picture or PDF file, or one the user took out or the setting leaves out
    Left(ShowInMessage),
    /// Past the message's budget (or its time to read the files' sizes): counted in the line after the files
    More,
    /// Shown: drawn or as a tile
    Shown(pe_html::PreviewFile, ShowInMessage),
}

/// What the documents of one view share as the plan goes through them, one after another: the time left to read
/// their files' sizes and the pictures left
pub(crate) struct Budget {
    until: Instant,
    left: usize,
}

impl Budget {
    /// A view's: at most [`DESCRIBE`] for the sizes of all its files, [`MAX_PREVIEWS`] pictures
    pub(crate) fn new() -> Budget {
        Budget {
            until: Instant::now() + DESCRIBE,
            left: MAX_PREVIEWS,
        }
    }
}

/// Where one document's files are among the message's attachments
#[derive(Debug, Clone, Copy)]
pub(crate) struct Among {
    /// The place of its first file in the strip (the files of the parts before it come first)
    pub first: usize,
    /// Its files' descriptions may be kept in the cache: false for a message something of which was decrypted
    pub keep: bool,
}

/// The files of a document the view goes through, with the budget of the whole view
struct Walk<'a, 'p> {
    plan: &'a PreviewPlan<'p>,
    budget: &'a mut Budget,
    among: Among,
    /// A PDF file was left out because PDF files are off
    pdf_off: bool,
}

/// The previews of a message's listed attachments, in the order of the strip: each picture, and the first pages of
/// each PDF file, with the sizes read before the document is shown (at most [`DESCRIBE`] for them all: a file not
/// described by then is a "Preparing…" tile until it is), at most [`MAX_PREVIEWS`] pictures in all unless the user
/// asked for more; a tile for a file that is not drawn, and a line for those past the budget
pub(crate) fn section(message: &pe_mime::parser::Message, plan: &PreviewPlan) -> Planned {
    let among = Among { first: 0, keep: true };
    part_section(message, plan, &mut Budget::new(), among)
}

/// [`section`] of one part of a message with signed or encrypted parts, `part` that part's message: its files
/// numbered by their place in the strip (`among`), under a token of the part's own; `budget` the view's, shared by
/// its parts in their order
pub(crate) fn part_section(
    part: &pe_mime::parser::Message,
    plan: &PreviewPlan,
    budget: &mut Budget,
    among: Among,
) -> Planned {
    let mut walk = Walk {
        plan,
        budget,
        among,
        pdf_off: false,
    };
    let mut files = Vec::new();
    let mut states = Vec::new();
    let mut more = 0;
    for (index, attachment) in view::listed(&part.attachments).enumerate() {
        let state = match walk.fate(among.first + index, attachment) {
            Fate::Left(state) => state,
            Fate::More => {
                more += 1;
                ShowInMessage::Off
            }
            Fate::Shown(file, state) => {
                files.push(file);
                state
            }
        };
        states.push(state);
    }
    let more_files = (more > 0).then(|| tr_args(Text::PreviewMoreFiles, &[("count", more.into())]));
    Planned {
        section: pe_html::PreviewSection {
            token: pe_html::preview_token(),
            files,
            notice: plan.notice.clone().filter(|_| walk.pdf_off),
            more_files,
        },
        states,
    }
}

impl Walk<'_, '_> {
    fn fate(&mut self, index: usize, attachment: &pe_mime::parser::Attachment) -> Fate {
        let Some(kind) = kind_of(attachment) else {
            return Fate::Left(ShowInMessage::None);
        };
        if let Some(sizes) = &self.plan.downloading {
            let size = sizes.get(index).copied().unwrap_or(0);
            let tile = tile(index, attachment, kind, size, tr(Text::PreviewTileDownloading));
            return Fate::Shown(tile, ShowInMessage::Unavailable);
        }
        let size = attachment.content.len() as u64;
        if let Some(reason) = never_drawn(attachment, kind) {
            let tile = tile(index, attachment, kind, size, reason);
            return Fate::Shown(tile, ShowInMessage::Unavailable);
        }
        let choices = &self.plan.choices;
        let asked = choices.shown.contains(&index);
        if choices.hidden.contains(&index) || !(asked || self.plan.auto) {
            return Fate::Left(ShowInMessage::Off);
        }
        if kind == FileKind::Pdf && !self.plan.pdfs && !asked {
            self.pdf_off = true;
            let tile = tile(index, attachment, kind, size, tile_words(&PreviewRefusal::Disabled));
            return Fate::Shown(tile, ShowInMessage::Off);
        }
        // a file asked for has a wait and a budget of its own
        let wait = match asked {
            true => DESCRIBE,
            false => self.budget.until.saturating_duration_since(Instant::now()),
        };
        if !asked && self.budget.left == 0 {
            return Fate::More;
        }
        self.drawn(index, attachment, kind, asked, wait)
    }

    /// A file to draw: its pictures as its description sizes them, or a tile that says why it has none
    fn drawn(
        &mut self,
        index: usize,
        attachment: &pe_mime::parser::Attachment,
        kind: FileKind,
        asked: bool,
        wait: Duration,
    ) -> Fate {
        let size = attachment.content.len() as u64;
        let Some(description) = self.describe(index, attachment, asked, wait) else {
            // read on in the background: the window is told when it is, and builds the view again
            let tile = tile(index, attachment, kind, size, tr(Text::PreviewTilePreparing));
            return Fate::Shown(tile, ShowInMessage::Unavailable);
        };
        let pdf = kind == FileKind::Pdf;
        let left = if asked { MAX_PREVIEWS } else { self.budget.left };
        match description.map(|d| preview_file(index, attachment, pdf, &d, left)) {
            Ok(Some(file)) => {
                if !asked {
                    self.budget.left -= file.pages.len();
                }
                Fate::Shown(file, ShowInMessage::On)
            }
            Ok(None) => Fate::Shown(
                tile(index, attachment, kind, size, tile_words(&PreviewRefusal::Unreadable)),
                ShowInMessage::Unavailable,
            ),
            Err(reason) => {
                // one not read in time may be read the next time it is asked for
                let state = match reason {
                    PreviewRefusal::TimedOut => ShowInMessage::Off,
                    _ => ShowInMessage::Unavailable,
                };
                Fate::Shown(tile(index, attachment, kind, size, tile_words(&reason)), state)
            }
        }
    }

    /// What came of attachment `index` after an earlier view's wait, when it was read from these very bytes (another
    /// view of the message, decrypted or not, may have other files at that place); read again when it was refused by
    /// a setting that may have changed since
    fn late(&self, index: usize, attachment: &pe_mime::parser::Attachment) -> Option<Described> {
        let late = &self.plan.late;
        // the key only for a file described late at that place
        late.keys().find(|(at, _)| *at == index)?;
        let late = late.get(&(index, pe_preview::key_of(&attachment.content)))?;
        match late {
            Err(PreviewRefusal::Disabled | PreviewRefusal::Off) => None,
            late => Some(late.clone()),
        }
    }

    /// The description of a file: what came of it after an earlier view's wait, or read now, waiting at most `wait`;
    /// None when it did not come in time
    fn describe(
        &mut self,
        index: usize,
        attachment: &pe_mime::parser::Attachment,
        asked: bool,
        wait: Duration,
    ) -> Option<Described> {
        if let Some(late) = self.late(index, attachment) {
            return Some(late);
        }
        let file = Arc::new(attachment.content.clone());
        let about = format!("{}, attachment {index}", self.plan.about);
        let (pdfs, keep) = (self.plan.pdfs, self.among.keep);
        let preparing = &self.plan.preparing;
        let later = preparing.expect(index, file.clone());
        let described = self
            .plan
            .core
            .preview_describe(pdfs, file, about, wait, asked, keep, later);
        match described.is_some() {
            true => preparing.answered(),
            false => preparing.missed(),
        }
        described
    }
}

/// A picture or a PDF file by its name and type (its content not here yet in a large message's text first): the
/// files Show in Message is for
fn kind_of(attachment: &pe_mime::parser::Attachment) -> Option<FileKind> {
    let kind = crate::opening::file_kind_of(&attachment.safe_filename(), &attachment.mime_type, &attachment.content);
    matches!(kind, FileKind::Image | FileKind::Pdf).then_some(kind)
}

/// Why a picture or PDF file can never be drawn, whatever the user asks: a format the core does not draw, a file
/// too large, content that is not what its name says
fn never_drawn(attachment: &pe_mime::parser::Attachment, kind: FileKind) -> Option<String> {
    let content = &attachment.content;
    if let Some(format) = pe_preview::not_drawn(content) {
        return Some(tr_args(Text::PreviewTileFormat, &[("format", format.name().into())]));
    }
    if content.len() > MAX_FILE {
        return Some(tile_words(&PreviewRefusal::TooLarge));
    }
    let matches = matches!(
        (kind, pe_preview::kind_of(content)),
        (FileKind::Image, Some(pe_preview::Kind::Picture)) | (FileKind::Pdf, Some(pe_preview::Kind::Pdf))
    );
    (!matches).then(|| tile_words(&PreviewRefusal::Unsupported))
}

/// What a tile says of a file that has no preview, in a few words
pub fn tile_words(reason: &PreviewRefusal) -> String {
    let text = match reason {
        PreviewRefusal::Password => Text::PreviewTilePassword,
        PreviewRefusal::TooLarge | PreviewRefusal::OverBudget => Text::PreviewTileTooLarge,
        PreviewRefusal::TimedOut => Text::PreviewTileTimedOut,
        PreviewRefusal::Crashed => Text::PreviewTileCrashed,
        PreviewRefusal::Off => Text::PreviewTileOff,
        PreviewRefusal::Disabled => Text::PreviewPdfOff,
        PreviewRefusal::Unsupported | PreviewRefusal::Unreadable => Text::PreviewTileUnreadable,
    };
    tr(text)
}

/// A file shown as a tile: its type, name and size, and `reason`
fn tile(
    index: usize,
    attachment: &pe_mime::parser::Attachment,
    kind: FileKind,
    size: u64,
    reason: String,
) -> pe_html::PreviewFile {
    pe_html::PreviewFile {
        attachment: index,
        content_id: attachment.content_id.clone(),
        name: attachment.display_filename(),
        details: crate::format_size(size),
        tile: Some(pe_html::PreviewTile {
            label: type_label(&attachment.safe_filename(), kind),
            reason,
        }),
        ..Default::default()
    }
}

/// The few letters on a tile's icon: the file's extension in capitals ("PDF", "HEIC"), or its kind's when it has
/// none
fn type_label(name: &str, kind: FileKind) -> String {
    let extension = name
        .rsplit_once('.')
        .map(|(_, extension)| extension)
        .unwrap_or_default();
    if !extension.is_empty() && extension.len() <= 4 && extension.bytes().all(|b| b.is_ascii_alphanumeric()) {
        return extension.to_ascii_uppercase();
    }
    match kind {
        FileKind::Pdf => "PDF".to_string(),
        _ => "IMG".to_string(),
    }
}

/// The previews of one file as its description has them, at most `left` pictures; None when it has none
fn preview_file(
    index: usize,
    attachment: &pe_mime::parser::Attachment,
    pdf: bool,
    description: &PreviewDescription,
    left: usize,
) -> Option<pe_html::PreviewFile> {
    let name = attachment.display_filename();
    let pages: Vec<pe_html::PreviewPage> = description
        .sizes
        .iter()
        .enumerate()
        .take(PREVIEW_PAGES)
        .filter_map(|(page, size)| size.map(|size| (page, size)))
        .take(left)
        .map(|(page, size)| preview_page(&name, pdf, description.pages, page, size))
        .collect();
    if pages.is_empty() {
        return None;
    }
    let size = crate::format_size(attachment.content.len() as u64);
    let details = if pdf {
        tr_args(
            Text::PreviewPdfDetails,
            &[("count", description.pages.into()), ("size", (&size).into())],
        )
    } else {
        size
    };
    let more = (pdf && description.pages > pages.len())
        .then(|| tr_args(Text::PreviewMorePages, &[("count", description.pages.into())]));
    Some(pe_html::PreviewFile {
        attachment: index,
        content_id: attachment.content_id.clone(),
        paper: pdf,
        pages,
        name,
        details,
        more,
        tile: None,
    })
}

/// A picture of a file: a picture at its size, a PDF page drawn for a display of two pixels a point of CSS, so
/// at half its pixels
fn preview_page(name: &str, pdf: bool, count: usize, page: usize, (width, height): (u32, u32)) -> pe_html::PreviewPage {
    if !pdf {
        return pe_html::PreviewPage {
            page,
            width,
            height,
            alt: name.to_string(),
        };
    }
    let alt = tr_args(
        Text::PreviewPageAlt,
        &[
            ("name", name.into()),
            ("page", (page + 1).into()),
            ("count", count.into()),
        ],
    );
    pe_html::PreviewPage {
        page,
        width: width.div_ceil(2),
        height: height.div_ceil(2),
        alt,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_tile_s_label_is_its_type() {
        assert_eq!(type_label("photo.heic", FileKind::Image), "HEIC");
        assert_eq!(type_label("Invoice.Pdf", FileKind::Pdf), "PDF");
        assert_eq!(type_label("scan", FileKind::Pdf), "PDF");
        assert_eq!(type_label("picture.jpeg-large", FileKind::Image), "IMG");
        assert_eq!(type_label("x.<b>", FileKind::Image), "IMG");
    }

    #[test]
    fn every_refusal_has_words() {
        for reason in [
            PreviewRefusal::Unsupported,
            PreviewRefusal::TooLarge,
            PreviewRefusal::OverBudget,
            PreviewRefusal::Password,
            PreviewRefusal::Unreadable,
            PreviewRefusal::TimedOut,
            PreviewRefusal::Crashed,
            PreviewRefusal::Off,
            PreviewRefusal::Disabled,
        ] {
            assert!(!tile_words(&reason).is_empty(), "{reason:?}");
        }
        assert_eq!(
            tile_words(&PreviewRefusal::Password),
            "Protected by a password: open it to enter the password"
        );
    }
}
