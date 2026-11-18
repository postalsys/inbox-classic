# Pictures and PDF files in the message: plan

A message with attached photos or a PDF shows them after its text, as Apple Mail does, so the user reads an invoice or
looks at the holiday photos without opening anything. Today the reading pane lists every file in the strip under the
header and shows nothing of them; the user double-clicks each one, and Inbox Classic writes it into the private folder
and hands it to the system's program for it.

The product owner's question was: "Image preview is probably easy, just append an IMG tag, but what about PDFs?" The
short answer of this plan: neither the picture nor the PDF is handed to the web view as it came. The core reads both in
Rust, draws a bounded preview of its own (a PNG or JPEG it encoded itself), and the web view only ever decodes those.
Pictures with the `image` crate, which the core already uses for contacts' pictures; PDF pages with hayro, a renderer
in pure Rust. Both fit the security model: what a remote party writes is parsed only in Rust.

## Goal

- Pictures (JPEG, PNG, GIF, WebP, BMP, TIFF) and PDF files attached to a message are shown after its text, each at the
  width of the reading pane or its own size, whichever is smaller, with its name under it.
- The text of the message paints first, as now; previews fill in as they are ready, without moving what is above them.
- Nothing about the threat model changes: no script in the reading pane, no network, no parser of the sender's bytes
  outside Rust, encrypted parts never mixed.
- The same on Windows, the Mac and Linux, decided by the core.
- The user can turn it off (everywhere, or for one file), as Apple Mail's View as Icon.

## What happens now

- **The view** (`pe-core/src/view.rs` `build_unless`) parses the source with pe-mime, renders the body with
  `pe_html::render_view_cards`, and lists the attachments (`listed`: not the pictures of an HTML body, `related`, nor a
  delivery report's parts) as `AttachmentView` rows: display and safe names, type, size, `FileKind` (`opening.rs`),
  tooltip and refusal. It runs on a worker thread and can be given up between steps (`dropped`).
- **`cid:` pictures** of an HTML body are embedded by `pe-html` as `data:` URIs of the bytes that came
  (`Embedder`, at most 64 MB per document). The web view decodes the sender's own bytes there today. Any part with a
  Content-ID can be embedded, listed or not.
- **The document's CSP**: `default-src 'none'; img-src data:` (plus `http: https:` after Download Pictures);
  `style-src 'unsafe-inline'; font-src data:`. Scripts are off in all three web views; WebView2's request filter on `*`
  and the WebKit content rules (`pe_html::webkit_content_rules`) block every load but the app's own documents, `cid:`
  and `data:`.
- **Serving**: the documents come out of memory. WebView2 at `https://preview.inboxclassic.invalid/N/` with a
  `WebResourceRequested` filter (`app/src/webview.cpp` `FilterRequests`), WKWebView from a `WKURLSchemeHandler`
  (`mac/.../WebViews.swift` `DocumentServer`), WebKitGTK from `register_uri_scheme` (`linux/src/webview.rs`). All
  three serve only `text/html`: the page and, for signed or encrypted mail, `part-N` beside it
  (`pe_html::part_document`).
- **Signed and encrypted mail** (`docs/pgp-plan.md`, "A document for each part"): an outer page of labels and a
  sandboxed `iframe` per part; each part is its own document from `render_view_cards`. Two parts encrypted apart are
  always two documents. The app measures the frames with its own script (`MEASURE_SCRIPT`), page scripts off.
- **Opening a file** (`opening.rs`): written into a private folder emptied after a day, marked as from the internet,
  opened with the system's program. Programs, scripts, pages, SVG and Office files with macros are never opened.
- **Downloading**: the reader connection downloads the whole source on open (or ahead, per Options); over 1 MB the text
  comes first (`worker/large.rs`, `TEXT_FIRST_OVER`) and the attachments' sizes come from the structure, their content
  later. A view built from the text first has attachments without content.
- **Pictures already in the core**: `image` 0.25 with `png` and `jpeg` only (`card_pictures.rs`: decode with
  `Limits`, re-encode as the core's own PNG, the windows get pixels); `resvg` 0.49 for BIMI logos.

## Findings

### Pictures

| Format     | WebView2 (Chromium) | WKWebView (macOS 13+) | WebKitGTK (Ubuntu 26.04) | Rust decoder (`image` 0.25)                          |
| ---------- | ------------------- | --------------------- | ------------------------ | ---------------------------------------------------- |
| JPEG       | yes                 | yes                   | yes                      | zune-jpeg, pure Rust                                 |
| PNG, APNG  | yes                 | yes                   | yes                      | png, pure Rust                                       |
| GIF        | yes, animated       | yes, animated         | yes, animated            | gif, pure Rust (frames too)                          |
| WebP       | yes                 | yes                   | yes                      | image-webp, pure Rust                                |
| BMP, ICO   | yes                 | yes                   | yes                      | pure Rust                                            |
| TIFF       | no                  | yes (ImageIO)         | no                       | tiff, pure Rust                                      |
| AVIF       | yes                 | yes                   | build dependent          | needs dav1d (C); no pure Rust decoder without unsafe |
| HEIC, HEIF | no                  | yes (ImageIO)         | no                       | none in Rust; libheif and libde265 are C/C++         |
| JPEG XL    | from Chrome 155     | yes (Safari 17+)      | on unless built without  | jxl-oxide, pure Rust (not in `image`)                |
| SVG        | yes, as a document  | yes, as a document    | yes, as a document       | resvg (already in the core)                          |

- **Handing the original to the web view** ("just an IMG tag") would mean three different sets of formats, and the
  sender's bytes reaching each system's native decoders: Chromium's (Skia, libwebp, libavif, dav1d) and Apple's
  ImageIO. Those are where the worst image bugs of recent years were: libwebp's CVE-2023-4863 and ImageIO's
  CVE-2023-41064 (BLASTPASS, exploited zero click through iMessage), ImageIO's CVE-2025-43300 (DNG, exploited in
  targeted attacks, 2025), and the FORCEDENTRY JBIG2 chain (CVE-2021-30860). A mail client
  that shows every picture attached to every message, opened or previewed by the arrow keys, is exactly the zero click
  surface those attacks used. The `cid:` path already has this exposure for pictures in HTML bodies; previews of
  attachments should not widen it, and a later PR can route `cid:` pictures through the same pipeline (see "Later").
- **Decoding in Rust and serving our own encode** gives one set of formats on all three, removes the native decoders
  from the path entirely (the web view decodes only a PNG or JPEG the core wrote), and bounds memory and size: a 50 MP
  photo (8,192 x 6,144, about 150 MB of RGB) is decoded once on a worker, scaled, and the web view gets a JPEG of
  2,048 pixels at the longest side (a few hundred KB). The cost is a few hundred milliseconds of one core per such
  photo, off the window thread, and the dependencies `image` already pulls.
- **EXIF orientation**: `image` 0.25 reads it (`ImageDecoder::orientation`) and applies it
  (`DynamicImage::apply_orientation`); phone photos come out upright. The re-encode writes no EXIF, so GPS, camera and
  time stay in the file, as they should for a preview (the original is untouched when opened or saved). The ICC profile
  is read and carried over to the JPEG (bounded at 1 MB), so a Display P3 iPhone photo keeps its colors.
- **Animated GIFs**: the `gif` decoder gives frames; re-encoding an animation is possible but costs memory per frame.
  First frame only in v1, with the GIF's name under it as for any picture; a decision below.
- **HEIC**: iPhones send HEIC when the sending app does not convert (Apple's Mail converts to JPEG by default; the
  Files share sheet and some other apps do not). libheif and libde265 are C/C++. Pure Rust HEVC decoders appeared in
  2026 (`heifer` 0.3, which matches ffmpeg on the conformance bitstreams; imazen's `heic`, AGPL) but are months old,
  and HEVC carries patent pool licensing. HEIC gets a tile in v1 on all three; a decision below.
- **AVIF** in `image` needs dav1d (C); a pure Rust path (`zenavif` on rav1d) is new. Tile in v1. **JPEG XL** could
  come later through jxl-oxide (pure Rust); tile in v1.
- **SVG** is a document that can carry scripts and external references; `opening.rs` already treats it as a program.
  No preview. (resvg could rasterize it safely, as it does BIMI logos, but an attached SVG is rare and is often a
  vector of attack rather than a photo.)

### PDF files

The research behind the table is listed under "Sources" at the end.

| Option                                                       | Parser of hostile bytes                            | Quality                                                       | Size added                        | Effort                                             | Parity                                            |
| ------------------------------------------------------------ | -------------------------------------------------- | ------------------------------------------------------------- | --------------------------------- | -------------------------------------------------- | ------------------------------------------------- |
| a. hayro (pure Rust) renders page pictures                   | Rust, in a killable helper process of the app      | Good on ordinary PDFs (invoices, letters, scans); see below   | About 1 to 2 MB (to be measured)  | M: a crate, the helper, budgets                    | Same pixels on all three                          |
| a'. PDFium (pdfium-render) or MuPDF                          | C++ / C, in process                                | Best (Chrome's, or MuPDF's)                                   | 5 to 25 MB of native library each | M, plus shipping and updating a native library     | Same on all three                                 |
| b. The system's renderer (Windows.Data.Pdf, PDFKit, Poppler) | Native, in process (or a sandboxed helper)         | Very good                                                     | None                              | L: three integrations, three helpers to sandbox    | Three engines, three results; Linux needs Poppler |
| c. The web view's PDF viewer                                 | Chromium's PDFium plus its viewer UI in JavaScript | Very good on Windows and the Mac; none or PDF.js on WebKitGTK | None                              | S on two, impossible on Linux without page scripts | No                                                |
| d. A tile only (name, size, pages, title)                    | Rust, metadata only                                | No picture                                                    | Small (hayro-syntax or lopdf)     | S                                                  | Same                                              |
| e. First page only, or all pages                             | As a, a' or b                                      | First page: a card; all: the document                         | None more                         | The same; all pages costs more time and memory     | Same as the renderer                              |

- **c is out**: WebView2's PDF viewer is a script application (Chromium's PDF extension) that needs its own frame,
  plugin and navigation, all of which the reading pane forbids; WKWebView's PDF display is PDFKit in a native view that
  takes over the whole web view, not an element of the message; WebKitGTK either has PDF.js (JavaScript, needing page
  scripts) or nothing. It breaks "only the editor runs a script" and has no Linux story.
- **b is against the model** unless every renderer runs in a sandboxed helper process: an AppContainer process on
  Windows, an XPC service with the App Sandbox on the Mac (the app is not sandboxed itself), bubblewrap or a seccomp
  child on Linux. Each is real work and differs per platform, and Poppler is a dependency the Linux packages and the
  Arch recipe would gain. It gives the best fidelity for the least code of our own, but three engines give three
  results and three sets of CVEs to follow: CoreGraphics' PDF parsing (CVE-2025-24230, ZDI-25-300 and ZDI-25-418),
  Windows.Data.Pdf (remote code execution in 2017 and 2018, CVE-2017-0293, CVE-2018-8350; users also report files it
  throws on), Poppler's Splash backend (CVE-2026-10118, a heap overflow, the same kind as CVE-2020-35702).
- **a' (PDFium, MuPDF)** gives the best quality but is the same C/C++ parser class the model keeps out of the process.
  MuPDF is AGPL or a commercial license. pdfium-render (0.9.5) binds a PDFium library we would ship per platform
  (bblanchon's builds) and update with Chrome's fixes (CVE-2025-1918, CVE-2026-18012 among the recent ones).
- **a, hayro** (github.com/LaurenzV/hayro, 0.9.0 of 2026-11-02, MIT or Apache-2.0, by a Typst maintainer; Typst 0.14
  and newer draw PDF images with it):
    - Crates: `hayro-syntax` (parsing, repairs broken xref tables), `hayro-interpret` (content to a `Device`), `hayro`
      (pixels through `vello_cpu`), and decoders of their own for JPEG 2000, JBIG2 and CCITT fax (scans); JPEG through
      zune-jpeg, Flate through flate2. All decoders are features. `embed-fonts` bundles free substitutes of the standard
      14 fonts (about 240 KB), so a PDF that names Helvetica without embedding it still draws, and no system font is read.
    - `hayro` and `hayro-interpret` are `forbid(unsafe_code)`; `hayro-syntax` has none of its own by default (its
      optional `unsafe` feature, for speed, stays off).
    - Tested against more than 1,000 files of the pdf.js and PDFBox corpora by visual regression; the author says most
      PDFs that Chrome or Firefox draw right should work. Not supported: some blend modes, knockout groups, color key
      masks, CMYK blending; annotations and forms are not drawn. Encrypted PDFs: the README says unsupported, the code
      has RC4 and AES from pdf.js for the empty user password (most "encrypted" invoices: printing allowed, no password
      to open). A file that wants a password gets a tile.
    - **Its README warns of timeouts and running out of memory on untrusted files, and it has no limits or cancel API.**
      In process, a hostile PDF could spin a thread forever or make an allocation fail, and a failed allocation aborts
      the whole Rust process: the app would close every time the message is shown. That is why the renderer runs in a
      helper process the core can kill (below), not on a thread of the app.
    - Still young (0.x, no published pass rate, "no effort on performance yet", no glyph cache): the spike measures it
      on real attachments before anything is built on it.
- **Other pure Rust renderers**: pdf-rs with `pdf_render` is far behind and quiet; lopdf (0.47) parses and edits only,
  which would do for the tile's metadata, but hayro-syntax does too; PDFluent's `pdf-render` is a commercial fork of
  hayro. hayro is the only real choice in pure Rust.
- **d is the fallback** for everything a does not show: a PDF with a password, one hayro refuses or that runs out of
  its budget, one too large. It needs only a metadata read, which hayro-syntax gives without rendering.
- **e**: Apple Mail shows every page inline, scrollable, and that is what makes it useful for invoices and short
  letters. Showing every page of a 200-page manual is not useful and is costly. The plan shows every page up to a limit
  and a line for the rest; the limit is a decision below.

### How other clients do it

- **Apple Mail**: pictures and PDFs "in place" after the text, at the pane's width; the attachment's context menu has
  View as Icon and View in Place, per attachment. Multi-page PDFs have shown inline in some versions and as icons in
  others. The global switch is a hidden default (`DisableInlineAttachmentViewing`), which reportedly works on some
  versions only; there is no visible option.
- **Thunderbird**: View, Display Attachments Inline (on by default) shows picture attachments under the body; text
  attachments with a hidden pref. PDFs are never inline: they open in a pdf.js tab.
- **Outlook**: classic Outlook previews one attachment at a time in the reading pane through previewer add-ins (which
  the Trust Center can turn off); new Outlook and Outlook on the web show thumbnails above the body and open PDFs in
  the browser.
- **Gmail on the web**: thumbnail cards under the message, a PDF's first page as its card.
- What carries over: the previews go **after** the text (the text is what was written to the user), at most the pane's
  width, never enlarged; a per file "as icon" switch; and the list of files stays where it is.

## The recommended design

### In one paragraph

A new crate `pe-preview` (no unsafe, like every crate but `pe-ffi`) turns an attachment's bytes into preview pictures:
`image` for pictures, hayro for PDF pages, each with hard limits. It runs in a **helper process**: the app's own
executable started again with one argument, fed the file on a pipe, under an operating system memory and time limit,
killed when it runs over. It answers raw pixels; the core checks their size and encodes the PNG or JPEG itself, into an
in-memory cache. The view (`view.rs`) decides which listed attachments get a preview and adds, after the body, a
section of our own markup with an `<img>` per picture or page whose address carries a random token of this view, with
its width and height already known so nothing moves when it arrives. The three apps' document servers answer those
addresses later (WebView2's deferral, WKURLSchemeTask and WebKitGTK's scheme request are all asynchronous), with the
bytes the core gives them, `image/png` or `image/jpeg` only. Pictures of a decrypted part stay in that part's document.

### Fallback order

1. **Rendered preview**: pictures through `image`, PDF pages through hayro.
2. **Tile**: the same place and size class, a file icon, the name, the size and, for a PDF, the page count and its
   title when the file has one ("Invoice 2026-114.pdf, 2 pages, 84 KB"). For HEIC, AVIF, JPEG XL, password protected
   PDFs, anything refused or over budget, and while the message's attachments are still downloading.
3. **Nothing**: files that are not pictures or PDFs stay in the strip only, as now.

The system's renderers (option b) are kept as a possible later step for the Mac's HEIC only if the product owner asks
for it, in a sandboxed XPC helper; not part of this plan.

### Core: `pe-preview` and its helper

- **The helper process.** `pe-preview` is built twice: as a library the core uses to talk to the helper and encode
  pictures, and as a small executable of its own, `inbox-classic-preview` (decision 9), that does all the reading of
  attachment bytes. The core starts it when the first preview is wanted and keeps it running, one at a time. A
  request is a length-prefixed frame on its stdin (the kind, the bytes, which page, the size wanted); the answer is a
  frame on its stdout: a description (dimensions, page count, page sizes, title) or raw RGBA pixels with their width and
  height. The core reads only that frame, with every number checked against what it asked for (width and height at
  most the size wanted, the length exactly width x height x 4), and encodes the PNG or JPEG itself. So the web view
  decodes nothing the helper made either.
    - **Memory**: the helper's own global allocator counts and refuses past 1 GB (a refused allocation ends the helper,
      not the app); on Windows the core also puts it in a Job object with a process memory limit, kill on close and no
      child processes; on Linux `setrlimit(RLIMIT_AS)`; on the Mac (where address space limits do not work) the counting
      allocator is the limit.
    - **Time**: 5 seconds a picture, 3 seconds a PDF page, 1 second a description. Past it, the core kills the helper,
      shows a tile, and starts a new helper for the next request. A file that ended the helper twice gets tiles for the
      rest of the session.
    - **No reach**: the helper gets no handles but its pipes, an empty environment, no files to open, no network. A later
      PR (5) adds each system's confinement on top: a restricted token or AppContainer on Windows, the App Sandbox
      entitlement with nothing granted on the Mac, seccomp and Landlock on Linux. Even without it the helper parses in
      Rust only; the process is first about keeping the app alive and responsive.
    - **Why not a thread**: hayro has no limits or cancel API and warns of running out of memory and time on hostile
      files; a thread can not be stopped, and a failed allocation aborts the whole process. The helper is also what keeps
      `image`'s non-strict `max_alloc` honest.
- **Kinds**: `Preview::Picture { width, height }`, `Preview::Pdf { pages, page_sizes, title }`, `Preview::Tile {
reason }`. While the view is built, the core sends the helper one description request with every candidate file of
  the message (dimensions from a picture's header; a PDF's page count, page sizes and title from its page tree with
  hayro-syntax) and waits at most 250 ms for it, in parallel with sanitizing the body. That gives the document the
  sizes to reserve the space. A file not described in time is a tile (an ordinary invoice's page tree reads in a few
  milliseconds; the wait is for hostile files only).
- **Which attachments**: listed ones (`view::listed`), whose `FileKind` is `Image` or `Pdf` and whose content sniffs as
  a format the helper reads (`image::guess_format` on the bytes, `%PDF-` in the first 1 KB): a `.jpg` that is a PNG is
  still previewed as the PNG it is; a `.pdf` that is HTML is never previewed (it is a `Program` by `file_kind_of`
  already). Not one whose Content-ID the body embeds by `cid:` (pe-html reports which IDs it embedded), so a picture is
  never shown twice. Not attachments of a message/rfc822 inside the message (a forwarded message is its own matter).
- **Pictures**: `image` with the features `png`, `jpeg`, `gif`, `webp`, `bmp`, `ico`, `tiff`. `Limits`: at most 16,384
  pixels a side and 100 megapixels (a 50 MP photo fits, a 30,000 x 30,000 bomb does not). Orientation applied, scaled
  to at most 2,048 pixels at the longest side, never enlarged. The core encodes JPEG at quality 85 for pictures without
  alpha, PNG with it; the ICC profile carried over when under 1 MB; no other metadata. First frame of an animation.
- **PDF pages**: hayro with `embed-fonts` and its decoders (JPEG 2000, JBIG2, CCITT for scans), without its `unsafe`
  feature. Each page 1,240 pixels wide (A4 at 150 dpi: sharp at the reading pane's width on a 2x display), its height
  by the page's aspect ratio, capped at 4 times the width (a receipt roll still shows, a 1-by-10,000 point page does not
  allocate gigabytes). PNG (text stays sharp). Drawn on white, which is what a PDF assumes. No links or actions: a
  picture has none.
- **Budgets** (constants in one place, each tested):
    - a picture or PDF file at most 50 MB (bigger: tile);
    - at most 20 previews per message (pictures and PDF pages counted together), in the order of the strip; the rest are
      tiles, then one line "N more files are in the list above";
    - PDF pages: the first 5 of each PDF, then a line "Pages 6 to 200 are in the file. Open"; a decision below;
    - one render at a time (one helper), so 20 pictures never take more than one core and never compete with the window
      thread or the workers; requests in document order, so the first picture comes first.
- **Cache**: in the core's memory, the encoded previews keyed by (owner, attachment index, page, size), 96 MB, least
  recently used out. Arrowing back to a message shows its previews at once. Nothing is written to disk (decision 6);
  for an encrypted part, never.
- **Encrypted and signed mail**: the preview of an attachment of a decrypted section is made from that section's bytes,
  kept only in the memory cache, and its address names the part (`part-2/pv-<token>-3-1`) with a token of that part:
  the server answers it only for that part's document, so an unprotected part can not show an encrypted part's
  preview. Dropped from the cache with the view when the user leaves the message, as the decrypted source is.
- **The `MessageView`** gains `previews: Vec<PreviewView>` (attachment index, part, kind, sizes, tile words) and the
  document gains the section; `Core::preview(view_token, address)` answers a request with `(mime, bytes)`, rendering if
  needed, on a thread of the core; the answer reaches the apps as an event (below).

### The document (`pe-html`)

- **Where**: after the body, before the end of the document, in a `<section class="pe-att-<nonce>">`, the class name
  random per document as the print header's is, its styles in a cascade layer the message can not name (`@layer`) with
  important rules, so a message's own CSS can not hide or restyle it. (It can still paint a look-alike next to it; the
  strip above the message, which the sender can not touch, stays the list of what is really attached.)
- **Each preview**: `<figure>` with `<a href="inboxclassic:attachment-<token>-N">` around an `<img src="pv-<token>-N-P"
width height alt="Invoice.pdf, page 1">`, then a `<figcaption>` with the name, size and, for a PDF, "Page 1 of 3".
  CSS: `max-width:100%; height:auto` (the attributes give the aspect ratio, so the space is reserved before the bytes
  come), a light border and a white background for PDF pages, a gap between pages.
- **The token** is 128 random bits per view. A sender who writes `<img src="pv-...">` or `<a href="inboxclassic:attachment-...">`
  into their HTML can not know it; the server answers only the addresses the core made for that document, and the
  link handler only the token of the message shown. The sanitizer already leaves relative URLs as they are, which is
  why the token, not the path, is the guard.
- **CSP**: `img-src` gains the page's own origin (`'self'`, or the explicit origin if a web view does not match custom
  schemes to `'self'`: the spike below finds out). Nothing else changes; `default-src 'none'` stays.
- **Dark mode**: the section stays light whatever the message's look: pictures are never inverted, PDF pages are on
  white, and the caption takes the document's colors.
- **Tiles**: the same figure with a file icon (an inline SVG of ours, in the document's `<style>`, not a picture
  file) and the words, linking to the attachment as a preview does.
- **Text first and not downloaded yet**: the section has the tiles of the files, with "Downloading..." in the
  caption, sized like what they will become when the structure gives the dimensions (it does not, for most messages:
  a tile then). When the whole source comes, the view is built again, as now, and the previews are in it.
- **Print**: the print page (`print_page`) is the same document; the print window's server answers the preview
  addresses from the same cache. Pictures print; PDF pages are left out with a line "Invoice.pdf, 3 pages, print it
  from its own program"; a decision below.

### The three apps

The same change in each: the document server answers a second kind of address, asynchronously.

- **Windows** (`app/src/webview.cpp`, `preview.cpp`): `FilterRequests` sees `pv-` addresses under the page, takes
  `args->GetDeferral()`, and asks the core for the bytes on a thread of the core (`pe_preview_bytes` with a callback,
  or an event `PreviewReady` posted to the window thread as other events are). On the window thread it builds a
  `CreateWebResourceResponse` with `Content-Type: image/png` or `image/jpeg` (from the core, one of two values) and
  completes the deferral. A navigation away completes outstanding deferrals with 404. The Print window's server does
  the same.
- **The Mac** (`WebViews.swift` `DocumentServer`): `start task` keeps the `WKURLSchemeTask` in a table, asks the core,
  and answers on the main run loop in the common modes (`onMain`); `stop task` removes it so an answer for a stopped
  task is dropped (WebKit raises on a late answer to a stopped task).
- **Linux** (`linux/src/webview.rs`): the `register_uri_scheme` handler keeps the `URISchemeRequest`, spawns the
  render with `pe-core` directly, and finishes it on the GTK main loop with a `MemoryInputStream` and the type.
- **The link**: `inboxclassic:attachment-<token>-N` is handled where the other `inboxclassic:` links are (the OTP's
  Copy, the event card): the app checks the token with the core and opens attachment N exactly as a double-click in
  the strip does, with the same refusal for programs (none are previewed, but the path is shared).
- **The strip**: its context menu gains a checked item **Show in Message** for a picture or PDF (Apple Mail's View in
  Place / View as Icon), which rebuilds the document without that file's preview, for this message while it is shown.
  The strip keeps listing every file; nothing moves out of it.
- **Context menu of the web view**: the web views' own "Save Image As" and "Open Image in New Window" are taken off for
  previews (they would save our re-encode, not the file); "Copy Image" stays. Each app already trims this menu.
- **Keyboard and screen readers**: each preview is a link, so Tab reaches it in the web view and Enter opens the
  file, as in the strip; `alt` and `figcaption` give its name and page. No new keys.
- **Frames**: a protected message's part documents grow when previews arrive; the apps already measure again when a
  part's pictures load.

### Settings

- **Options, Read page**: "Show pictures and PDF files in the message" (on). Off: the section is not added, the strip
  is as today. Stored with the other reading options in `pe-store`, exported in the setup file.
- **Per file**: Show in Message in the strip's menu, for the message while it is shown (not remembered).
- No setting for page counts, sizes or formats.

### Help

- `attachments.html` gains "See pictures and PDF files in the message": what is shown, that the preview is a copy
  made by Inbox Classic (so a file the app can not draw shows as a tile and still opens), Show in Message, the option,
  that a preview never runs anything in the file and never loads anything from the internet. In every language, marked
  for review. `read-messages.html` links to it.
- F1 is unchanged (the reading pane's topic).

### Performance

- **First paint**: the view adds markup and dimensions only. The helper's description of the files (picture headers,
  a PDF's page tree) runs while the body is sanitized and is waited for at most 250 ms, a wait only a hostile or
  enormous file reaches; nothing is decoded or drawn before the document is shown. The web view then asks for each
  `pv-` address, which the helper draws one at a time in document order, so the first picture arrives first and the
  text never waits for a picture.
- **The helper's start**: a small executable, started once per session when the first preview is wanted (tens of
  milliseconds), kept running while previews are asked for and ended after a few idle minutes.
- **Costs measured in PR 1's benchmark**, with the budget it must stay under on the CI runners: a 12 MP JPEG under
  250 ms, a 50 MP JPEG under 1 s, a one page invoice PDF under 150 ms, a scanned page (JBIG2 or JPEG at 300 dpi) under
  400 ms.
- **Memory**: one decode at a time, in the helper (at most 1 GB, then it ends, never the app); the biggest allowed
  picture is 100 MP (about 400 MB of RGBA at worst, for the moment it is scaled); the core's cache is 96 MB of encoded
  previews, and the app holds nothing else.
- **Moving on**: a preview for a message no longer shown is not rendered (the request is cancelled by the web view's
  navigation, and the core checks the view token before it starts).
- **Download ahead off**: nothing changes about when sources are downloaded; previews come with the source.

### Security review

| Threat                                                                  | What answers it                                                                                                                                                                                                                                                                                      |
| ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Memory safety bug in a decoder or PDF parser, reached with no click     | Only Rust parsers with no unsafe of their own (`image`'s decoders, hayro without its `unsafe` feature), and those only in the helper process, not in the app. The web view decodes only the core's own PNG and JPEG encodes of checked raw pixels. Fuzz targets for every entry point of the helper. |
| Decompression bomb (a PNG of 100,000 x 100,000, a Flate stream of GBs)  | Dimensions checked from the header before decoding, `image::Limits`, the page size cap, file size caps, and the helper's 1 GB allocator limit (plus the Job object on Windows, `RLIMIT_AS` on Linux): past it the helper ends, the app shows a tile.                                                 |
| Infinite loop or very slow file (deep PDF content, huge Type3 font)     | The helper is killed after 5, 3 or 1 seconds and started again; a file that ended it twice gets tiles for the session; the window thread never waits.                                                                                                                                                |
| A panic                                                                 | In the helper: it answers "refused" (caught per request) or ends; either way a tile. Nothing of it reaches the app's process.                                                                                                                                                                        |
| A helper that is taken over                                             | It can only answer frames on its pipe; the core checks every number of a frame against what it asked for and encodes the pixels itself. PR 5 confines it further (AppContainer or restricted token, App Sandbox, seccomp and Landlock): no files, no network, no other processes.                    |
| JavaScript, forms, launch actions in a PDF                              | hayro does not run scripts or actions; the output is a picture with no links.                                                                                                                                                                                                                        |
| External references in a PDF (remote fonts, GoToR, URI, linked streams) | hayro reads only the file's own bytes; no network or file access exists in `pe-preview`.                                                                                                                                                                                                             |
| Fonts                                                                   | Embedded fonts parsed in Rust (hayro-font, in the helper); no system font is read (`embed-fonts` covers the standard 14), so a PDF can not probe which fonts are installed and the result is the same on all three.                                                                                  |
| SVG with scripts or references                                          | Never previewed (a `Program` already).                                                                                                                                                                                                                                                               |
| A name that lies (`photo.jpg` that is HTML)                             | Content sniffed; a page is a `Program` by `file_kind_of`; only formats the decoders accept are previewed.                                                                                                                                                                                            |
| A sender referencing the previews from their HTML                       | Per view, per part 128-bit token in every address and link; the servers answer only what the core made for that document.                                                                                                                                                                            |
| Encrypted part shown in an unprotected part (EFAIL style mixing)        | Previews of a section only in its own document, the token per part; decrypted previews in memory only, never on disk, gone with the view.                                                                                                                                                            |
| A sender's CSS hiding or faking previews                                | Our styles in a layer the message can not name; the strip, outside the document, stays the truth; the help says so.                                                                                                                                                                                  |
| Tracking (a read receipt by loading a preview)                          | Nothing goes to the network; previews are local.                                                                                                                                                                                                                                                     |
| EXIF GPS leaking                                                        | The preview carries no EXIF; it never leaves the app anyway (Copy Image copies pixels).                                                                                                                                                                                                              |

### Tests

- **`pe-preview` unit tests**: each format to a bounded JPEG or PNG; orientation 1 to 8 (fixtures from the EXIF
  orientation test set); a 50 MP picture scaled; refused: over the side, pixel and file limits, a PNG bomb, a truncated
  JPEG (tile, no panic), a GIF with 10,000 frames (first frame only, fast); ICC carried; no EXIF in the output.
- **PDF fixtures** (`pe-preview/tests/pdf/`, written for this project or under a license that allows it): an invoice
  from a common generator, a scanned page (JBIG2, CCITT, JPEG), a CJK document with embedded fonts, a form, a
  PDF with JavaScript and a launch action (the picture has no trace of either), an encrypted one with an empty user
  password (rendered) and with a password (tile), a broken xref (repaired or tile), a 1-by-10,000 point page (capped),
  a 500-page file (5 pages, the line), a file that loops and one that allocates without end (the helper killed). Rendered pictures compared with references by a
  tolerance, so a hayro update shows its changes.
- **Fuzz targets** `preview_picture`, `preview_pdf` and `preview_frame` (the core's reading of the helper's answer)
  with the others; a short run in CI, longer on schedule.
- **The helper's limits**: a test helper mode that allocates without end, loops, panics and answers frames with wrong
  sizes; each gives a tile, the app's memory and responsiveness unchanged, and a new helper for the next file.
- **`pe-html`**: the section's markup, the token in every address, a body that writes `pv-` addresses gets no answer,
  the CSP, the layer rules beating a message's `img{display:none!important}`.
- **`pe-core` view tests**: which attachments get previews (`cid:` ones not, a forwarded message's not, programs not),
  the 20 preview limit, text first gives tiles, encrypted sections each with their own token and nothing crossing.
- **UI end-to-end** (`scripts/ui-e2e/SCENARIO.md`, the three tests, `feature-map.mjs`): a message with two photos and a
  two-page PDF, screenshot `attachments-preview`; Show in Message off for one, screenshot again; Enter on a preview opens
  the file (checked as the strip's open is). A protected message with an attachment in each of two parts shows each
  in its frame.
- **Benchmarks** of PR 1's costs, in `pe-preview/benches`, a CI step that fails over twice the budget.

## Decisions for the product owner

1. **On by default?** Options: on (Apple Mail), off (Outlook, Thunderbird's default is on for pictures). Recommendation:
   **on**, as the feature is the point; the Options checkbox turns it off.
2. **How many PDF pages.** Options: first page only (Gmail's thumbnails); all pages (Apple Mail); all up to a limit.
   Recommendation: **every page up to 5**, then a line with the rest's count that opens the file. Invoices, letters
   and tickets are one to three pages; a long document is better read in a PDF program.
3. **HEIC (and AVIF).** Options: tile on all three (parity, no native decoder); the Mac only through ImageIO in a
   sandboxed XPC helper; all three through libheif in a helper. Recommendation: **tile on all three in v1**; revisit
   when a pure Rust HEVC decoder exists or if users ask, then the Mac helper first.
4. **Animated GIFs.** Options: first frame (v1 cost: none); animated through our own re-encode as an animated WebP or
   GIF, bounded in frames and pixels. Recommendation: **first frame** in v1; animation later if asked.
5. **Print.** Options: print nothing of the previews; pictures only; pictures and PDF pages. Recommendation: **pictures
   print, PDF pages do not** (a line names the file), as a PDF is printed better from its own program.
6. **A disk cache** of previews. Options: memory only; a cache folder with a size cap, never for encrypted parts.
   Recommendation: **memory only** in v1: renders are fast, and a folder of every picture anyone sent is one more thing
   to secure and clean.
7. **Show in Message remembered?** Options: for the message while shown; remembered per message in the store;
   per sender. Recommendation: **while shown**, with the Options switch for those who want it off everywhere.
8. **Pictures in HTML bodies (`cid:`) through the same pipeline** (follow-up, not this plan's PRs). Options: leave as
   today; decode and re-encode them too, so no sender bytes reach a web view decoder at all. Recommendation: **a later
   PR** after this ships, using `pe-preview`; it changes how every newsletter looks (GIFs, sizes), so it needs its own
   check.
9. **The helper: a second executable or the app started again.** Options: a small `inbox-classic-preview` executable
   shipped beside the app (installed next to the exe, signed with it by `sign-win.sh`; in `Contents/MacOS` of the
   bundle, signed and notarized with it; in `/usr/lib/inbox-classic/` of the Linux and Arch packages); or the app's own
   executable with a `--preview-helper` argument, keeping "one signed exe". Recommendation: **the second executable**:
   it starts in milliseconds instead of loading the whole app, its allocator limit applies to it alone, and each
   system's confinement (PR 5) is simplest on a binary of its own. The packaging scripts (`build-installer.sh`,
   `mac-build.sh`, `mac-package.sh`, `linux-package.sh`, `arch-makepkg.sh`, `release.sh`'s `--version` checks) each
   gain it.

## The pull requests

Each PR follows the usual way of work (core and tests first, the three apps in the same PR when UI changes, help in
every language, UI tests and the feature map).

### PR 1: `feat(core): pe-preview, pictures and PDF pages drawn in Rust` (L, no UI)

- **The spike first**, written into this plan: hayro on 50 real attachments (invoices from five generators, scans,
  tickets, forms, CJK) compared with a reference render, its speed and the exe size before and after; and a page in
  each of the three web views whose `<img>` is answered a second later by the document server (WebView2's deferral,
  WKURLSchemeTask, WebKitGTK), with the CSP's `img-src` for the page's own origin. If the deferred answer fails on one
  of them, all three get the fallback: the document is served again with the previews as `data:` URIs of our encodes
  once they are ready, the scroll position kept by the app's own script.
- `pe-preview` (library and helper executable) with the frames, limits, kill and restart, the core's cache, fuzz
  targets, fixtures and benchmarks above. `image` gains `gif`, `webp`, `bmp`, `ico`, `tiff`; hayro added;
  `Cargo.lock` and `THIRD-PARTY-NOTICES` follow. The helper built and packaged on the three (decision 9), started with
  `--version` by the release checks. A note on the sizes.
- This PR also commits this plan.

### PR 2: `feat: pictures and PDF files in the message` (L)

- `view.rs` chooses the previews and gives `MessageView.previews`; `pe-html` the section, the token, the layer and the
  CSP; `pe_html` reports the embedded Content-IDs. C API: the preview rows of a view, `pe_preview_bytes` (asynchronous,
  through an event), the `attachment-` link check. Header committed.
- The three apps: the asynchronous document server answers, the link, the web view's context menu.
- A signed or encrypted message gets no previews yet (its files stay in the strip, as today) until PR 4.
- The Options switch on the Read page, in the store and the setup file.
- Help: the new section of `attachments.html` in every language (marked for review).
- UI tests and `feature-map.mjs`: `attachments-preview`.

### PR 3: `feat: Show in Message, tiles and print` (M)

- The strip's Show in Message on the three; tiles for what is not drawn (HEIC, password protected, over budget,
  downloading); the "N more pages" and "N more files" lines; print with pictures and the PDF line.
- Text first: tiles with "Downloading...", replaced when the source comes.
- UI tests: `attachments-preview-icon`, `attachments-preview-print`.

### PR 4: `feat: previews in signed and encrypted mail` (M)

- The per part token and server answer, decrypted previews kept only in memory, frames measured again.
- Tests: the corpus of protected mail gains an attachment in each of two parts, one encrypted; the preview of one never
  answers in the other's document; nothing written to disk (checked as the key store test checks the database file).
- UI test: `pgp-attachment-preview`.

### PR 5: `chore: the preview helper confined` (M)

- Windows: the helper under a restricted token at low integrity, or an AppContainer with no capabilities, in its Job
  object; the Mac: the App Sandbox entitlement with nothing granted (no files, no network); Linux: Landlock with no
  paths and a seccomp filter of the few system calls it makes (`landlock` and `seccompiler`, both Rust).
- Tests: the helper started in each confinement draws the fixtures as before, and a test mode that tries to open a
  file, connect and start a process is refused in each.
- The help's security topic (`links-scripts`) gains a line on how previews are made.

## Later

- `cid:` pictures of HTML bodies through `pe-preview` (decision 8).
- A forwarded message (`message/rfc822`) shown inline after the body, as Apple Mail does, in a document of its own.
- HEIC on the Mac through a sandboxed helper, if asked (decision 3).

## Sources

Checked in November 2026. Where a page did not settle a point, the plan says so or leaves it to the spike.

- hayro: https://github.com/LaurenzV/hayro, https://docs.rs/crate/hayro/latest,
  https://docs.rs/hayro-syntax/latest/hayro_syntax/, https://docs.rs/hayro-interpret/latest/hayro_interpret/
- Typst and hayro: https://alternativeto.net/news/2025/10/typst-0-14-brings-pdf-accessibility-by-default-and-native-pdf-images
- pdf-rs: https://github.com/pdf-rs/pdf; lopdf: https://docs.rs/crate/lopdf/latest; pdfium-render:
  https://docs.rs/crate/pdfium-render/latest
- PDFium CVEs: https://www.rapid7.com/db/vulnerabilities/cve-2025-1918/,
  https://www.rapid7.com/db/vulnerabilities/cve-2026-18012/; Poppler: https://nvd.nist.gov/vuln/detail/CVE-2026-10118
- Windows.Data.Pdf: https://learn.microsoft.com/en-us/uwp/api/windows.data.pdf.pdfpage.rendertostreamasync,
  https://learn.microsoft.com/en-us/windows/win32/api/windows.data.pdf.interop/nf-windows-data-pdf-interop-pdfcreaterenderer,
  https://www.rapid7.com/db/vulnerabilities/msft-cve-2017-0293/
- CoreGraphics PDF: https://support.apple.com/122373, https://zerodayinitiative.com/advisories/ZDI-25-300
- WebView2's PDF toolbar:
  https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2settings.hiddenpdftoolbaritems;
  WebKitGTK and PDF.js: https://bugs.webkit.org/show_bug.cgi?id=241117, https://bugs.webkit.org/show_bug.cgi?id=260019
- Formats: https://developer.chrome.com/blog/jpeg-xl-in-chrome, https://caniuse.com/heic, https://caniuse.com/jpegxl
- `image`: https://docs.rs/crate/image/latest, https://docs.rs/image/latest/image/struct.Limits.html; AVIF and HEIC in
  Rust: https://docs.rs/crate/zenavif/0.1.7/source/README.md, https://docs.rs/crate/heifer/0.3.26,
  https://docs.rs/crate/heic/0.2.0/source/README.md; resvg: https://docs.rs/crate/resvg/latest
- Other clients: https://discussions.apple.com/thread/255407506, https://bugzilla.mozilla.org/show_bug.cgi?id=1663427,
  https://support.mozilla.org/th/questions/1508076, https://mc.merill.net/message/MC1174855
- Decoder exploits: https://blog.isosceles.com/the-webp-0day/, https://projectzero.google/2025/03/blasting-past-webp.html,
  https://blog.quarkslab.com/patch-analysis-of-Apple-iOS-CVE-2025-43300.html

## Decided (2026-11-17)

1. **On by default**, with a setting to turn previews off and "Show in Message" per file in the attachment strip's menu.
2. **PDF pages**: up to 5, then a line that opens the file ("Open to see all 12 pages").
3. **HEIC and AVIF**: a tile on all three platforms in version 1; previews follow once a safe decoder is ready.
4. **Animated GIFs**: the first frame only.
5. **Printing**: pictures print; PDF pages do not, a line names the file instead.
6. **Cache**: memory only; never a disk cache, and never for encrypted parts.
7. **"Show in Message"** for a file shown as a tile applies while the message is shown, not remembered.
8. **Pictures in the text (`cid:`)** go through the same pipeline in a later PR of this plan, so no picture bytes from a sender reach a web view decoder.
9. **Rendering runs in the app, not in a helper process.** This replaces the helper of the design above and PR 5's per-platform confinement:
    - A render thread of its own (never the window thread, never the core's async threads), fed one file at a time.
    - Hard limits before rendering: file size (50 MB), page count read (5), page size and the pixel size of every page and picture (at most 2048 px on the long side, and a total pixel budget per message); the `image` crate's `Limits` (max allocation) for pictures.
    - A watchdog: a render over its time limit (2 s a page, 5 s a picture) is abandoned; the thread is replaced, the file shown as a tile, and PDFs are no longer rendered for the rest of the session (an abandoned render may keep one CPU core busy until the app quits; a thread can not be stopped from outside).
    - A crash marker: before a file is rendered, its message, part and a hash are written to a small file in the app's data folder, and removed when the render ends. On start, a marker left behind means that file crashed the app (out of memory ends the process; no thread can catch it): it is recorded as not renderable, shown as a tile from then on, and the marker is cleared. A hostile file can therefore end the app at most once.
    - The trade-off, accepted: a hostile PDF can end the app once, or keep a core busy until quit; a helper process would avoid both but adds a program to ship and confine.

The PRs become: (1) the preview crate in pe-core with the render thread, limits, watchdog and crash marker, opening with the hayro spike on about 50 real attachments and the deferred pictures in all three web views; (2) previews in the message on all three apps with the setting, help and UI tests; (3) "Show in Message", tiles, printing, placeholders while downloading; (4) previews in signed and encrypted mail; (5) the body's `cid:` pictures through the same pipeline.

## As built (PR 1, 2026-11-17)

### The hayro spike

hayro 0.9.0 (crates.io, 2026-11-02), MIT or Apache-2.0, as are all its crates; everything new in the tree is MIT,
Apache-2.0, BSD-3-Clause or Zlib (`THIRD-PARTY-NOTICES` picks them up from `cargo metadata` as before). It needs Rust
1.92: the workspace, `linux/Cargo.toml` and the README now say 1.92 (resolver 3 would otherwise pick older versions).

**Unsafe code.** The hayro crates themselves forbid unsafe code, but what they pull in does not, and the plan's
"without its `unsafe` feature" can not be had: `hayro-interpret` 0.9 turns on `hayro-syntax`'s `unsafe` feature
itself, which brings flate2 on zlib-rs, memchr, and the SIMD paths of zune-jpeg, hayro-jpeg2000 and hayro-jbig2
(fearless_simd). hayro also uses pic-scale with its NEON, SSE and AVX features on (about 1,350 unsafe blocks: the
resampling of a PDF's pictures, whose sizes the sender chooses) and vello_cpu uses fearless_simd. These are SIMD kernels
and inflate, not parsers of PDF syntax, and zlib-rs, memchr and zune-jpeg are widely fuzzed; pic-scale is the one to
watch. Turning them off needs a change in hayro (features to opt out), worth asking upstream; until then a
`[patch.crates-io]` of `hayro-interpret` and `hayro` would be the only way.

**Size.** A release binary (thin LTO, stripped, arm64) that reads PNG and JPEG with `image` is 0.74 MB; with
`pe-preview` (all the picture formats, hayro, the standard fonts and CMaps) 6.45 MB: **5.7 MB added**, of which the
CMaps are about 460 KB and the fonts about 260 KB. The plan guessed 1 to 2 MB.

**The corpus**, 114 files: 7 downloaded real attachments (two IRS forms, a CDC leaflet in Chinese, a book in Japanese,
a Taiwanese magazine with fonts not embedded, a JBIG2 scan, an XFA form), 40 from the pdf.js test corpus (papers,
books, scans in JBIG2, CCITT and JPEG 2000, CJK, AcroForms, encrypted, fuzzed, known bombs), invoices from three
generators (Chrome's Skia, macOS Quartz through cupsfilter, ReportLab) with encrypted copies made by qpdf (AES-256 and
RC4 with an empty user password, and one with a password), a receipt roll, a 500-page file, a 300 dpi scan; pictures
(the EXIF orientation set, a camera JPEG with GPS, 12 and 50 MP photos, CMYK with a profile, progressive, Display P3,
TIFF LZW and G4, WebP lossy and lossless with alpha, an animated GIF, ICO, BMP, 16-bit PNG, HEIC, AVIF, a truncated
JPEG) and 27 hostile files made for it (Flate bombs of 256 MB and 1 GB, an image XObject of 60,000 by 60,000, one that
inflates to 400 MB, 2 million path segments, nesting 200,000 deep, a form drawing itself, forms drawing each other 2^40
times, a page tree cycle, absurd MediaBoxes, 100,000 pages, 1,000,000 `q`, a tiny tiling pattern, a PostScript
function shading, JavaScript and a launch action, pictures whose headers say 100,000 pixels a side or 16-bit 16,384
square, a GIF of 10,000 frames).

**Method.** `cargo run --release -p pe-preview --example measure` (committed), one process a file under
`/usr/bin/time -l` for the peak resident memory and a 60 second limit, on an Apple M5 Pro. Pages are drawn as the app
draws them (1,240 pixels wide, at most 2,048 tall, the first five), pictures scaled to 2,048. Times are of one page
or picture, peak memory is of the whole process. Page 1 was compared with Poppler's `pdftoppm` at the same width.

| File                                                                                                                  | What it is                           | Result                                     | ms (page 1 / slowest) | Peak MB  |
| --------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ------------------------------------------ | --------------------- | -------- |
| irs_f1040.pdf                                                                                                         | IRS form, fillable                   | 2 pages drawn, PNG 463 KB                  | 21 / 21               | 28       |
| irs_fw9.pdf                                                                                                           | IRS form, 6 pages                    | 5 drawn, PNG 458 KB                        | 19 / 21               | 32       |
| wnv_chinese.pdf                                                                                                       | CDC leaflet, Chinese, fonts embedded | 3 drawn, matches Poppler                   | 22 / 22               | 29       |
| SFAA_Japanese.pdf                                                                                                     | book, Japanese, 220 pages            | 5 drawn (CropBox, as viewers show it)      | 12 / 12               | 27       |
| mao.pdf                                                                                                               | magazine, CJK fonts not embedded     | drawn, **the CJK text missing**            | 15 / 15               | 33       |
| perf_text_cjk_nonembedded.pdf                                                                                         | CJK fonts not embedded               | drawn, **only the Latin letters**          | 11 / 11               | 23       |
| xfa_annual_expense_report.pdf                                                                                         | XFA form                             | its "Please wait" page, as Poppler         | 8 / 8                 | 20       |
| JBIG2Globals.pdf                                                                                                      | JBIG2 scan                           | drawn, PNG 733 KB                          | 135 / 135             | 77       |
| perf_codecs_jbig2.pdf                                                                                                 | JBIG2                                | drawn                                      | 24 / 24               | 28       |
| perf_codecs_ccitt.pdf                                                                                                 | CCITT fax                            | drawn                                      | 17 / 17               | 28       |
| perf_codecs_jpx.pdf                                                                                                   | JPEG 2000                            | drawn, JPEG 191 KB                         | 188 / 188             | 119      |
| perf_codecs_jpeg_cmyk.pdf                                                                                             | CMYK JPEG                            | drawn, JPEG 178 KB                         | 149 / 149             | 56       |
| perf_images_scan_gray.pdf                                                                                             | gray scan                            | drawn                                      | 43 / 43               | 40       |
| scan_jpeg_300dpi.pdf                                                                                                  | A4 photo scan, 300 dpi               | drawn, JPEG 440 KB                         | 132 / 132             | 62       |
| 22060_A1_01_Plans.pdf                                                                                                 | architect's plan, A1                 | drawn, matches Poppler                     | 166 / 166             | 73       |
| tracemonkey.pdf                                                                                                       | paper, 14 pages                      | 5 drawn                                    | 19 / 24               | 35       |
| freeculture.pdf                                                                                                       | book, 352 pages                      | 5 drawn                                    | 28 / 28               | 54       |
| TAMReview.pdf                                                                                                         | paper, 23 pages                      | 5 drawn                                    | 15 / 17               | 30       |
| invoice_chrome.pdf                                                                                                    | invoice, Chrome (Skia)               | drawn, PNG 64 KB                           | 7 / 7                 | 20       |
| invoice_quartz_cups.pdf                                                                                               | invoice, macOS Quartz                | drawn, PNG 32 KB                           | 6 / 6                 | 19       |
| invoice_reportlab.pdf                                                                                                 | invoice, ReportLab                   | drawn, title read                          | 7 / 7                 | 21       |
| encrypted_empty_user_password.pdf                                                                                     | AES-256, no password to open         | drawn                                      | 7 / 7                 | 20       |
| encrypted_rc4_empty_user.pdf                                                                                          | RC4, no password to open             | drawn                                      | 7 / 7                 | 20       |
| encrypted_with_password.pdf                                                                                           | needs a password                     | tile: Password                             | 4 (open)              | 3        |
| issue6010_1.pdf, pr6531_1.pdf                                                                                         | pdf.js encrypted                     | tile: Password                             | 4 (open)              | 3        |
| secHandler.pdf, empty_protected.pdf                                                                                   | pdf.js encrypted, empty password     | drawn                                      | 5 / 5                 | 19       |
| acroform_calculation_order.pdf                                                                                        | AcroForm                             | drawn with its fields' appearances         | 4 / 4                 | 15       |
| receipt_roll.pdf                                                                                                      | 226 by 2,400 points                  | its top: 512 by 2,048                      | 7 / 7                 | 14       |
| manual_500_pages.pdf                                                                                                  | 500 pages                            | 5 drawn, count read in 0.5 ms              | 5 / 5                 | 22       |
| truncated_invoice_chrome.pdf                                                                                          | cut at two thirds                    | xref rebuilt, drawn                        | 6 / 6                 | 20       |
| poppler-742-0-fuzzed.pdf                                                                                              | fuzzed                               | tile: Unreadable                           | 0                     | 3        |
| issue19517.pdf                                                                                                        | pdf.js, a huge picture               | page refused: TooLarge (was 400 MB)        | 0                     | 9        |
| photo_50mp.jpg                                                                                                        | 8,192 by 6,144 JPEG                  | 2,048 by 1,536 JPEG 633 KB                 | 290                   | 178      |
| photo_12mp.jpg                                                                                                        | 4,032 by 3,024 JPEG                  | 2,048 by 1,536 JPEG 659 KB                 | 110                   | 149      |
| orient_portrait_5.jpg (and 1 to 8)                                                                                    | EXIF orientation                     | upright, 1,200 by 1,800                    | 21                    | 16       |
| gps_DSCN0010.jpg                                                                                                      | camera JPEG with GPS                 | JPEG, no EXIF                              | 5                     | 4        |
| jpeg_cmyk_icc.jpg                                                                                                     | CMYK with a CMYK profile             | RGB JPEG, profile dropped                  | 29                    | 12       |
| jpeg_p3.jpg                                                                                                           | Display P3                           | JPEG, P3 profile kept                      | 21                    | 10       |
| jpeg_progressive.jpg                                                                                                  | progressive                          | JPEG                                       | 28                    | 16       |
| jpeg_truncated.jpg                                                                                                    | 12 MP cut short                      | drawn as far as it goes                    | 68                    | 142      |
| tiff_lzw.tif                                                                                                          | photo as TIFF                        | JPEG 529 KB (the PNG was 3.1 MB)           | 122                   | 24       |
| tiff_scan_g4.tif                                                                                                      | fax G4                               | PNG 24 KB                                  | 4                     | 4        |
| webp_lossy.webp, webp_alpha.webp                                                                                      | WebP lossy, lossless with alpha      | JPEG, PNG                                  | 14, 5                 | 6        |
| gif_animated_rotating_earth.gif                                                                                       | 1 MB animation                       | first frame, PNG                           | 4                     | 5        |
| png_16bit_alpha.png, ico_256.ico                                                                                      | 16-bit with alpha, icon              | PNG                                        | 11, 3                 | 10       |
| photo.heic, photo.avif                                                                                                | HEIC, AVIF                           | tile (not read)                            | 0                     | 3        |
| hostile_flate_bomb_1g.pdf                                                                                             | 1 MB file, content inflates to 1 GB  | page refused: TooLarge (was 1,077 MB)      | 8                     | 4        |
| hostile_image_bomb_400m.pdf                                                                                           | picture inflating to 400 MB          | page refused: TooLarge (was 416 MB)        | 8                     | 4        |
| hostile_image_60000x60000.pdf                                                                                         | picture said 60,000 square           | page refused: TooLarge                     | 0                     | 3        |
| hostile_path_2m.pdf                                                                                                   | 2 million path segments              | page refused: TooLarge (was 1,073 MB)      | 21                    | 9        |
| hostile_xobject_laughs.pdf                                                                                            | forms drawing each other 2^40 times  | **hangs**, memory growing (871 MB at 60 s) | killed at 60 s        | 871      |
| hostile_deep_dict.pdf                                                                                                 | dictionaries 50,000 deep             | tile: Unreadable                           | 244 (open)            | 3        |
| hostile_deep_content.pdf, xobject_self, page_tree_cycle, q_stack, tiling_tiny, type4_shading, 100000_pages, js_launch | the rest of the hostile PDFs         | drawn, bounded by hayro's own checks       | 3 to 17               | 11 to 27 |
| hostile_png_100000x100000.png, png_16bit_huge, bmp_50000, tiff_100000                                                 | sizes in the header                  | tile: TooLarge, nothing decoded            | 0                     | 2        |
| hostile_png_96mp_rgba.png                                                                                             | 16,000 by 6,000 RGBA, inside limits  | drawn                                      | 96                    | 376      |

**What the spike shows.**

- Quality: documents with embedded fonts match Poppler (IRS forms, the CDC leaflet, the A1 plan, scans in JBIG2,
  CCITT and JPEG 2000, CMYK). hayro shows the CropBox where `pdftoppm` shows the MediaBox with crop marks. Two kinds of
  file come out wrong: **CJK text in fonts that are not embedded** (older Asian documents; hayro has no CJK fallback
  font, and the core reads no system font) shows only its Latin letters, and **XFA-only forms** show their "Please
  wait" page (as Poppler does). Neither can be told apart before drawing; a CJK fallback font would add 10 MB or more.
- Speed: every ordinary page or picture under 300 ms, most under 30 ms; the plan's budgets (12 MP under 250 ms, 50 MP
  under 1 s, an invoice under 150 ms, a scan under 400 ms) hold with room.
- Memory: ordinary files peak at 20 to 180 MB in a process of their own. **hayro inflates a stream whole and keeps a
  page's paths with no limit**: a 1 MB file took 1 GB, a 6 MB one 1 GB of paths, and a 50 MB attachment could ask for
  50 GB, which in the app's process is a crash. So PR 1 measures every stream a page reaches before drawing it
  (`pe-preview/src/streams.rs`, below); the bombs are now refused in under 25 ms with 3 to 9 MB.
- Hangs: one file of the corpus never finishes (`hostile_xobject_laughs.pdf`), and it does not only keep a core busy:
  it allocates as it goes (about 14 MB a second). An abandoned render of it would end the app after a few minutes,
  which the crash marker then records (once). This is the one case the decided design accepts but underestimated; a
  cooperative stop in hayro (a callback checked between operators) would close it, and is worth asking upstream for.
- Pictures: the header checks refuse every oversized picture before decoding. A text page's PNG is 10 to 500 KB; a
  scanned page's was 2 to 3 MB, so a page (or an opaque lossless picture) whose PNG is over 768 KB is written as a JPEG
  when that is less than half the size.
- After the review's fixes the spike set draws as before (the same pages, sizes and times); pdf.js's `bomb_giant.pdf`,
  which hayro had drawn by giving up on its picture, is now refused before drawing, as its picture says it is far over
  the limit.
- Fuzzing found one more: a 684 byte WebP whose EXIF chunk says 4 GB made image-webp 0.2.4 allocate 4 GB when the
  orientation was read. pe-preview now refuses a WebP whose chunks run past the end of the file
  (`picture::webp_chunks`; the file is `tests/files/webp-exif-4gb.webp`). The tiff crate prints a `dbg!` line to
  stderr on some hostile TIFFs (harmless, noisy).

### The design as built

`core/crates/pe-preview` (`forbid(unsafe_code)`), used by `pe-core/src/previews.rs`:

- `picture`: `format_of` (JPEG, PNG, GIF, WebP, BMP, ICO, TIFF by content), `describe` (the preview's size from the
  header, orientation applied) and `render`. `image::Limits`: 16,384 a side, 448 MB of allocation, and refused
  before decoding past 100 MP or 448 MB decoded. Scaled to 2,048 (averaged when far larger, a triangle filter when a
  little larger), never enlarged; orientation applied after scaling; JPEG quality 85 for JPEG and lossy WebP, PNG for
  anything see-through, and the larger-than-768 KB rule above; an ICC profile up to 1 MB carried over when its colour
  space matches the pixels written (a CMYK profile is not); no EXIF, no text chunks. First frame of an animation.
- `pdf`: `Document::open` (a password needed is `Refusal::Password`, no pages is `Unreadable`), `describe` (page count,
  Info title as text without control or bidi characters, at most 200 characters, the sizes of the first five pages),
  `pages().render(n)`: 1,240 pixels wide unless the long side would pass 2,048, a page taller than four widths shows
  its top, on white, annotations' appearances drawn, no system font.
- `streams`: before a page is drawn, every stream it reaches (its content, its resources' forms, pictures, fonts,
  patterns and shadings, its annotations' appearances; not the page tree, other pages or actions) is measured, and
  every inline picture (`BI ... ID ... EI`) in the content streams among them (the page's, forms', tiling patterns',
  Type 3 glyphs', appearances'). Flate is counted as hayro reads it: flate2 on zlib, then on raw deflate, and when
  both fail a counting port of hayro's lenient decoder (pdf.js's: it skips back-references to before the start and
  ignores stored lengths and the checksum), so a stream only the lenient decoder reads is not counted as nothing
  (`streams/inflate.rs`; a test compares the counts with what hayro inflates). LZW and RunLength run counting their
  output into a 64 KB buffer, ASCIIHex and ASCII85 are decoded (they shrink). A picture counts as its pixels in RGBA by
  the larger of its dictionary's size and its codec's: CCITT by its Columns (and Rows), JPEG 2000 by its codestream's
  SIZ marker (none: refused), JBIG2 by its page information segment (a striped page, or a region of unknown length
  before it, as 65,535 tall, the most hayro-jbig2 allows); DCT by its dictionary. A size that disagrees with the
  dictionary is not refused as such, as legitimate files differ (striped JBIG2, JPEG 2000 at a reduced resolution):
  the larger size is what is measured. A page is refused past 160 MB for one stream or picture, 8 MB of content, or
  384 MB for the pages of the file together.
- `limits`: every number in one place (file 50 MB, 2,048 px, 5 pages, 2 s a page, 5 s a picture, 64 MP of previews a
  message, 96 MB of cache, two abandoned threads at most, a 32 MB stack for the render thread).
- `Previewer` (service.rs): a dispatcher thread and a render thread, both the crate's own. Requests queue in order
  (`request`); `describe(file, wait)` goes ahead of the queue and returns within `wait` (for PR 2's view, which needs
  the sizes before the document). The dispatcher answers from the cache what it holds (by SHA-256 of the file, never
  for `keep: false`, which PR 4 uses for decrypted parts: the reading pane gives it for any part that was decrypted):
  the description, the pages drawn and the refusals that come of the file itself (password, unreadable, too large),
  and sends only the pages it does not hold to the render thread. It checks the message's pixel budget, and follows the render
  thread step by step: each page or picture has its own deadline. Past it the render is abandoned, a new thread takes
  the next file, the file is added to the refused list, after a PDF no PDF is drawn for the session, and after two
  abandoned threads nothing is. A panic is caught (the file is a tile, the next draws). `cancel(owner)` drops the
  owner's waiting files, stops its file under way after the current page and frees its budget.
- `marker`: `rendering-<sha256>` written in `previews/` beside the store before each file (with its kind and "folder,
  message, attachment"), removed when the render ends or unwinds. At start, markers left behind join `refused` (the
  newest 512 kept) and are deleted; a file in it is `Refusal::Crashed` from then on. As the key is the file's content,
  a sender could change one byte a message and end the app once a message: so a marker left behind also turns PDF
  previews off (the store's `previews.pdf`, with `previews.pdf_crashed` noting why), checked as the core opens.
  `Event::PdfPreviewsOff` says so, `Core::previews_notice()` gives the words for where previews are shown (why, and
  that "Show PDF files in messages" in the reading options turns them on again), `Core::set_pdf_previews(true)` turns
  them on and clears the note. Pictures stay on: their decoders have hard limits. A PDF file then is
  `Refusal::Disabled` (`previews::refusal_text`). The words are in English and drafted in every language, marked for
  review; the apps show them in PR 2.
- `pe-core`: `Core::previews_start(folder, uid, attachments) -> request` reads the source once on the reads connection
  (blocking pool), takes the listed attachments and hands them to the render thread (started by the first preview);
  `Event::PreviewReady { request, attachment }` follows each step; `Core::preview_file(request, attachment)` gives the
  description, the pages (`Arc<Picture>`: `image/png` or `image/jpeg` bytes and the size) and the refusal;
  `previews_cancel(request)`. The C API does not change in this PR; pe-ffi does not pass the event on yet.

Tests: unit tests of every limit, the page sizes, titles, encoders and profiles, the cache, the markers (left behind,
panic, the list's length), the codecs' sizes, the lenient count against hayro's own inflate; `tests/render_thread.rs`
with a fake engine that hangs, panics and counts (watchdog, PDFs off, two hangs stop all, a marker left behind, cancel,
the budget, the cache answering pages and lasting refusals with only missing pages drawn, the PDF setting,
`describe` in time); `tests/pictures.rs`
(orientation 1 to 8, GPS and EXIF gone, ICC kept, CMYK profile dropped, every format, 24 MP scaled, a 200 frame GIF,
truncated files); `tests/files.rs` over the committed files (`tests/files/generate.py` makes them; none is anyone's
real file), among them the review's five (`lenient-flate-bomb.pdf`, `inline-image-bomb.pdf`, `ccitt-columns.pdf`,
`jpx-siz.pdf`, `jbig2-page.pdf`, which took 290 MB, 425 MB, 1.2 GB and 4.8 GB before the meter knew them, and are now
refused), the real engine abandoning `xobject-laughs.pdf`; `pe-core` previews of a stored message, and a crash
marker turning PDF previews off until they are turned on. Fuzz targets
`preview_picture` and `preview_pdf`, ten minutes each (96,605 and 14,119 runs, after the WebP fix no failure, no
input over a second; again after the review's fixes, 159,700 and 14,831 runs, no failure), corpora minimized and
committed.

### The web views

A page like PR 2's (`<img src="pv-...">` relative and absolute, `width` and `height` set, `max-width:100%;height:auto`)
in each platform's reading pane configuration, its pictures answered a second later by the scheme handler:

|                                 | WebView2 (Windows 11)                                                  | WKWebView (macOS 26)                                                              | WebKitGTK 2.52 (Ubuntu 26.04)                                       |
| ------------------------------- | ---------------------------------------------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Deferred answer                 | `GetDeferral`, later `put_Response` and `Complete` from a timer: shows | the `WKURLSchemeTask` kept, answered from the main run loop (common modes): shows | the `URISchemeRequest` kept (a ref), `finish` from a timeout: shows |
| Space reserved                  | yes, 300 px before and after, the text below does not move             | yes                                                                               | yes                                                                 |
| CSP `img-src 'self'`            | loads (https origin)                                                   | loads (the custom scheme counts as self)                                          | loads                                                               |
| CSP naming the origin or scheme | loads                                                                  | loads                                                                             | loads                                                               |
| CSP `img-src data:` only        | blocked                                                                | blocked                                                                           | blocked                                                             |
| Navigation before the answer    | completing the deferral later returns S_OK, nothing happens            | `stop` is called; the answer must then be dropped (WebKit raises otherwise)       | no signal; finishing later is harmless                              |

So the plan's design stands on all three; the `data:` fallback is not needed, and `'self'` is enough in the CSP.
WKWebView also serves a repeated address from its memory cache without asking the handler again: the per view token
keeps addresses unique, as planned. The spike programs were throwaway (not committed).

### What should change in the plan

- "hayro without its `unsafe` feature" is not possible with hayro 0.9; see "Unsafe code" above. Ask upstream for
  features to turn off `unsafe`, pic-scale's SIMD and fearless_simd, and for a cooperative stop.
- The size is 5.7 MB, not 1 to 2 MB.
- The decided design missed that hayro allocates without bound: the stream meter is now part of it, and an abandoned
  render can also grow memory until the app ends (once per file, recorded by the crash marker).
- CJK text in fonts that are not embedded does not show. Options for later: a CJK fallback font (10 MB or more), or
  a tile for a PDF whose fonts are CJK and not embedded (the meter could tell, as it walks the fonts).
- Benchmarks as a CI step (the plan's `benches`) are left for PR 2; the `measure` example gives the numbers.

## As built (PR 3, the core, 2026-11-18)

- **What each file gets** (`pe-core/src/previews/plan.rs`): every listed picture or PDF file by its name and type is
  drawn, a tile, counted in the line of files past the budget, or left out (taken out with Show in Message, or the
  setting off). A tile is the core's own markup (`pe_html::PreviewTile`): the type on an icon drawn in CSS, the name,
  the size and the reason in words, one link that opens the file, the same size whatever it says. Tiles: HEIC, AVIF
  and JPEG XL by their content (`pe_preview::not_drawn`), a file over 50 MB, content that is not what its name says,
  a PDF file with a password, one refused, timed out or that ended the app once, PDF files while PDF previews are off,
  and every picture and PDF file of a large message whose text came first ("Downloading…", with the sizes of its
  structure). When the whole source comes the view is built again and the previews take the tiles' place after the
  same text.
- **The budget line**: past 20 pictures, "4 more files are in the list above" (the plan's words), plain text: the
  strip is above the message on all three, and Show in Message draws any of them.
- **Show in Message** (decisions 1 and 7): `Core::preview_show(token, attachment, show)` records the choice for the
  message (not the view: a window that builds the view again, or another window showing the same message, sees it)
  until no window shows it, never in the store. Each strip row has `show_in_message`: none (not a picture or PDF
  file), on (drawn: checked, choosing takes it out), off (choosing draws it, also with the setting off or PDF files
  off) or unavailable (a tile that can not be drawn: greyed). A file asked for has its own pixel budget and its own
  wait for its size, and is drawn while PDF files are off by the setting (`pe_preview::Request::asked`); a file that
  ended the app or hung stays a tile.
- **The rebuild keeps the scroll**: the apps read `pe_html::SCROLL_SCRIPT` before they show the new document and run
  `scroll_to_script(y)` once it loaded; the text is above the section and every picture's size is in the markup, so
  the same offset shows the same text.
- **Print** (decision 5): `Core::print_start(token)` draws the pictures if the reading pane has not (waiting at most 30
  seconds, off the window thread), then wraps the sanitized message again (`pe_html::PrintParts`, never cut out of a
  document) with the pictures as `data:` addresses of the core's own PNG and JPEG encodes, and a line for each PDF
  file and tile ("invoice.pdf (3 pages, 84 KB) is not printed. Open it to print it."). `Event::PrintReady` says it is
  there, `Core::print_result` gives it once. The print document's CSP is `img-src data:` as any document's; it has no
  preview path.
- **C API**: `PeAttachment.show_in_message` (`PeShowInMessage`), `pe_preview_show`, `pe_print_start`,
  `pe_print_result`, `PE_EVENT_KIND_PRINT_READY`, `pe_scroll_script`, `pe_scroll_to_script`.
- Help: the section of `attachments.html` in every language; ten translations had the section twice, the copy is
  gone.

## As built (PR 4, the core, 2026-11-18)

- **A token per part document.** A message with signed or encrypted parts (`view.rs` `protected_view`) gets the
  previews of each part's files after that part's text, in the part's own document (`part-N`), under a token of the
  part's own (`previews::PreviewDocument`). The files keep their place in the strip (the parts' listed attachments in
  order), and one budget (20 pictures, the wait for their sizes) is shared by the parts in their order
  (`plan::part_section`, `plan::Budget`). The view's `preview_token` then names the view only: no document carries it,
  so the apps' calls (`pe_preview_link`, `pe_preview_show`, `pe_print_start`, `pe_previews_end`) are unchanged.
  `preview_ask` answers an address only for a file its own document shows; `preview_link` takes a part's link only
  when its token is a document of the view the reader names and the file is that part's. The apps can not tell which
  frame asked; they do not need to: a part's document is the only place its token is written, the sanitized mail of
  another part has no script to read a sibling frame, and 128 random bits can not be guessed, so the token is the
  capability.
- **Read as the view read it.** A view of a protected message reads its files again as its parts showed them
  (`Read::Protected`: `protect::shown_decrypted`, nothing when that fails now, so a file is never taken from another
  listing than the one its document was made of); an ordinary view reads the source as it is (`Read::Raw`), never
  decrypting. S/MIME is shown as any message (the app reads no S/MIME), so its previews are any message's; the old
  `may_be_signed_or_encrypted` wall is gone.
- **Memory only for what was decrypted** (decision 6). When anything of the message was decrypted its files'
  descriptions and pages are never put in the cache (`Request::keep` false, now also for `describe_file`, whose PDF
  title is the file's words). The crash marker and the refused list name such a file by where it is
  (`pe_preview::key_of_place`: SHA-256 of "folder F, message U, attachment N", or a message file by a digest of its
  bytes as they are), never by a hash of its decrypted bytes (which would let anyone who reads the folder confirm a
  guess), and the marker leaves out its type. A file that hung or ended the app is still refused at the next start,
  by its place. When the view ends, its drawn files, the answers no web view took and the printouts no window took are
  dropped (`forget_shown`). Not done: the bytes are not zeroed when freed.
- **Printing.** Decrypted pictures print: the printout already carries the decrypted text, and the pictures are the
  same mail. The printout is made in memory (`pe_html::print_parts`, `print_document_with`) and handed to the window,
  whose print web view is served from memory (WebView2 from memory, WKWebView's scheme handler with a non-persistent
  store, WebKitGTK with an ephemeral session); only the system's print spooler, or a file the user prints to, writes
  it, as for the text. Each part's pictures come right after that part's text (`pe_html::print_parts` keeps each
  part's text apart, `print_document_with` takes each item with its part), each named with its part ("Part 2:
  floor-plan.png"); PDF pages are not printed, as for any message.
- **Frames.** Every picture's width, height and aspect ratio are in its markup, so a part's frame measures as tall as
  it will be before the picture comes; Windows and Linux measure every 400 ms from the moment the page is shown, the
  Mac only from `didFinish`, which waits for the frames' pictures (see the apps below).
- **Agents** read the source as it is (`agents.rs`), never a view: an encrypted message's files stay refused, and no
  tool of pe-mcp reaches a preview.
- Tests: `pe-core/tests/pgp_previews.rs` with `scripts/ui-e2e/pgp/secure-previews.eml` (a plain part with
  `harbour.png`, an encrypted part with `floor-plan.png`, made by `cargo run -p pe-pgp --example
ui_fixture_previews -- ../scripts/ui-e2e/pgp` with the committed key): each part's token answers only its own file
  (checked by the pixels answered), the links, the view's end, a message file, the printout, the agents, and nothing
  decrypted on disk (the store's folder, the private attachments folder and the temporary folder scanned for the
  decrypted file's and its preview's bytes and hashes, with a control that the scan finds a copy written on purpose).
  `pe-preview`: a decrypted file's marker and refused entry name its place, its description is not kept.
- **The apps** need: Windows, a preview link clicked in a part's frame (`FrameNavigationStarting`, now opened only
  externally) passed to the reader's link handler; the Mac, frames measured from the moment the page is shown, not
  from `didFinish`. Linux needs nothing. UI test: `pgp-attachment-preview`.
- **After the UI reviews** (same PR): a link clicked in a part opens: the part's document has `<base target="_top">`
  (`RenderOptions::in_frame`) and its frame's sandbox `allow-top-navigation-by-user-activation`, so a click navigates
  the top page, whose handler in every app cancels it and opens the link or the file; `frame-src` is `'self'` again
  (a frame navigation was refused before WebKit asked the app). Two readers of one message each get their view: only
  a reader's own `message_view_cancel` drops a view. Each strip row says its part (`PeAttachment.part`, from 1),
  `protection` (none, signed, encrypted: the apps draw a lock for encrypted) and `part_text` ("From part 2:
  Encrypted. Not signed", also the tooltip's last line). The bar counts "encrypted and signed", "encrypted", "verified",
  "signed", "need attention" and "without a confirmed signature".
