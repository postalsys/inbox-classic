//! Every limit of the previews in one place (docs/attachment-preview-plan.md, "Decided"), each tested

use std::time::Duration;

/// The largest picture or PDF file that gets a preview
pub const MAX_FILE: usize = 50 * 1024 * 1024;

/// The longest side of a preview, a picture's or a page's, in pixels
pub const MAX_SIDE: u32 = 2048;

/// The pages of a PDF file drawn; the rest are in the file
pub const MAX_PAGES: usize = 5;

/// The width a PDF page is drawn at (A4 at 150 dpi), unless that makes its longest side over [`MAX_SIDE`]
pub const PAGE_WIDTH: u32 = 1240;

/// A page taller than this many times its width shows its top part only: a receipt roll still shows, a 1 by 10,000
/// point page is not drawn as a thread of pixels
pub const MAX_PAGE_RATIO: f64 = 4.0;

/// The widest or tallest picture read, in pixels: checked from its header, before it is decoded
pub const MAX_PICTURE_SIDE: u32 = 16_384;

/// The most pixels a picture may have: a 50 MP photo is read, a 30,000 by 30,000 bomb is not
pub const MAX_PICTURE_PIXELS: u64 = 100_000_000;

/// The most memory a picture's decoder may take ([`image::Limits::max_alloc`]): 100 MP of RGBA and a little more
pub const MAX_PICTURE_ALLOC: u64 = 448 * 1024 * 1024;

/// The previews in one message, pictures and PDF pages counted together, in the order of its files: a file past it
/// has none
pub const MAX_PREVIEWS: usize = 20;

/// How long the reading pane waits for the sizes of a message's files before it shows the message: the files not
/// described by then have no previews in it (an ordinary file is described in a few milliseconds; the wait is for a
/// hostile one, or a render thread busy with the page of a message shown before)
pub const DESCRIBE_WAIT: Duration = Duration::from_millis(250);

/// The pixels of all the previews of one message together: about 20 pictures of 2048 by 1536
pub const MESSAGE_PIXELS: u64 = 64 * 1024 * 1024;

/// The longest a PDF page (opening the file counts as its first page) may take before its render is abandoned
pub const PAGE_TIME: Duration = Duration::from_secs(2);

/// The longest a picture may take before its render is abandoned
pub const PICTURE_TIME: Duration = Duration::from_secs(5);

/// The previews kept in memory, encoded, least recently used out
pub const CACHE_BYTES: usize = 96 * 1024 * 1024;

/// The largest ICC profile carried over to a preview
pub const MAX_ICC: usize = 1024 * 1024;

/// The longest title of a PDF file kept, in characters
pub const MAX_TITLE: usize = 200;

/// The render threads abandoned in a session before previews stop altogether: each may keep a core busy until the
/// app quits
pub const MAX_ABANDONED: usize = 2;

/// The stack of the render thread: deep nesting in a PDF recurses, and a stack overflow ends the process
pub const RENDER_STACK: usize = 32 * 1024 * 1024;

/// An opaque preview's PNG larger than this is a scan or a photo, written as a JPEG when that is less than half the
/// size: a text page's PNG is 10 to 500 KB, a scanned page's 2 to 3 MB, a photo's in TIFF or BMP 1 to 3 MB
pub const PAGE_PNG: usize = 768 * 1024;

/// The JPEG quality of photos
pub const JPEG_QUALITY: u8 = 85;

/// The files remembered as not renderable (they ended the app or hung), newest kept
pub const MAX_REFUSED_KEPT: usize = 512;
