//! The UI end-to-end test, built into the binary with the `e2e` feature (never in a release): `inbox-classic --e2e
//! <dir>` starts ImapKit (core/e2e), puts mail there over its REST API, runs the real app on a store of its own with
//! --memory-passwords, --pin-certificate and --sign-in-page-file, and drives its real widgets from the window thread
//! the way a user would (text typed into the fields, buttons clicked, rows selected, the menu's commands run),
//! checking the results over the REST API. A picture of each step goes to <dir> under the names the Windows test
//! (scripts/ui-e2e.ps1) gives them, the log to <dir>/log.txt; the exit code is 1 when a check failed.

use std::cell::RefCell;
use std::io::{BufRead, BufReader, Read, Write};
use std::path::{Path, PathBuf};
use std::process::{Child, ChildStdin, Command as Process, Stdio};
use std::rc::Rc;
use std::time::{Duration, Instant};

use adw::prelude::*;
use base64::Engine;
use gtk::{gdk, gio, glib, graphene};
use serde_json::Value;
use webkit::prelude::*;

use crate::app::{run_command, shell};
use crate::commands::Command;
use crate::ui::FILE_ANSWERS;

/// The steps after organizing: lists, invitations, logos, dragging, junk, folders, links, completion, signatures
mod steps;

const SUBJECT: &str = "Photos from Saturday";
const NEWSLETTER: &str = "October newsletter";
const MINUTES: &str = "Minutes of the planning meeting";

thread_local! {
    static DRIVER: RefCell<Option<Rc<Driver>>> = const { RefCell::new(None) };
}

struct Ports {
    imap: u16,
    smtp: u16,
    rest: u16,
    cert: String,
    /// The second server, with a mailbox of its own, for the second account
    second_imap: u16,
    second_smtp: u16,
    second_rest: u16,
}

struct Driver {
    out: PathBuf,
    log: RefCell<std::fs::File>,
    failures: RefCell<Vec<String>>,
    finished: std::cell::Cell<bool>,
    ports: Ports,
    /// ImapKit runs while its stdin is open
    _harness: (Child, ChildStdin),
}

/// Runs the test: ImapKit, the mail, the app with the driver; the exit code says whether every check passed
pub fn run(out: PathBuf) -> glib::ExitCode {
    let _ = std::fs::create_dir_all(&out);
    let out = std::fs::canonicalize(&out).unwrap_or(out);
    for entry in std::fs::read_dir(&out).into_iter().flatten().flatten() {
        let path = entry.path();
        let name = path
            .file_name()
            .map(|n| n.to_string_lossy().into_owned())
            .unwrap_or_default();
        if name.ends_with(".png") || name.starts_with("store.db") || name == "log.txt" || name == "result.txt" {
            let _ = std::fs::remove_file(&path);
        }
    }
    let log = std::fs::File::create(out.join("log.txt")).expect("log.txt");
    let (harness, ports) = match start_harness() {
        Ok(started) => started,
        Err(error) => {
            eprintln!("ImapKit did not start: {error}");
            return glib::ExitCode::FAILURE;
        }
    };
    let driver = Rc::new(Driver {
        out: out.clone(),
        log: RefCell::new(log),
        failures: RefCell::default(),
        finished: std::cell::Cell::new(false),
        ports,
        _harness: harness,
    });
    driver.step("putting mail into ImapKit");
    if let Err(error) = seed(&driver) {
        driver.check(false, &format!("the test mail went into ImapKit ({error})"));
    }
    let arguments = crate::Arguments {
        store: Some(out.join("store.db")),
        certificate: Some(PathBuf::from(&driver.ports.cert)),
        memory_passwords: true,
        sign_in_page_file: Some(out.join("sign-in-page.txt")),
        ..Default::default()
    };
    let store = out.join("store.db").to_string_lossy().into_owned();
    let cert = driver.ports.cert.clone();
    let page = out.join("sign-in-page.txt").to_string_lossy().into_owned();
    let argv = vec![
        "inbox-classic".to_string(),
        "--store".into(),
        store,
        "--memory-passwords".into(),
        "--pin-certificate".into(),
        cert,
        "--sign-in-page-file".into(),
        page,
    ];
    DRIVER.with(|d| *d.borrow_mut() = Some(driver.clone()));
    // the driver starts once the app has
    glib::timeout_add_local_once(Duration::from_millis(500), || {
        let driver = DRIVER.with(|d| d.borrow().clone()).expect("the driver");
        glib::spawn_future_local(async move {
            let finished = std::panic::AssertUnwindSafe(scenario(driver.clone()));
            // a panic in a step is a failure of the test, not a hang
            let outcome = futures_catch(finished).await;
            if let Err(why) = outcome {
                driver.check(false, &format!("unexpected error: {why}"));
            }
            driver.finish();
        });
    });
    let _ = crate::run(arguments, argv);
    // the last step ends the app: what it checked last is that it did
    if let Some(driver) = DRIVER.with(|d| d.borrow().clone())
        && !driver.finished.get()
    {
        driver.check(true, "the app ended");
        driver.finish();
    }
    let failed = DRIVER.with(|d| d.borrow().as_ref().map_or(1, |d| d.failures.borrow().len()));
    if failed == 0 {
        glib::ExitCode::SUCCESS
    } else {
        glib::ExitCode::FAILURE
    }
}

/// The scenario's future, a panic in it turned into an error
async fn futures_catch(
    future: std::panic::AssertUnwindSafe<impl std::future::Future<Output = ()>>,
) -> Result<(), String> {
    let mut future = Box::pin(future.0);
    std::future::poll_fn(move |context| {
        match std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| future.as_mut().poll(context))) {
            Ok(std::task::Poll::Ready(())) => std::task::Poll::Ready(Ok(())),
            Ok(std::task::Poll::Pending) => std::task::Poll::Pending,
            Err(panic) => {
                let why = panic
                    .downcast_ref::<String>()
                    .cloned()
                    .or_else(|| panic.downcast_ref::<&str>().map(|s| s.to_string()))
                    .unwrap_or_else(|| "a panic".into());
                std::task::Poll::Ready(Err(why))
            }
        }
    })
    .await
}

// ---- ImapKit ----

fn harness_dir() -> PathBuf {
    std::env::var_os("INBOX_CLASSIC_E2E_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|| Path::new(env!("CARGO_MANIFEST_DIR")).join("../core/e2e"))
}

/// `node harness.mjs` with its OAuth provider and a user with an address for name to sign in as there
fn start_harness() -> Result<((Child, ChildStdin), Ports), String> {
    let mut child = Process::new("node")
        .arg("harness.mjs")
        .current_dir(harness_dir())
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .map_err(|e| e.to_string())?;
    let mut stdin = child.stdin.take().ok_or("no stdin")?;
    let config = r#"{"oauth":{},"users":{"testuser":{"password":"testpass"},"alice@example.com":{"password":"pw","displayName":"Alice Example"}},"second":{"users":{"testuser2":{"password":"testpass2"}}}}"#;
    writeln!(stdin, "{config}").map_err(|e| e.to_string())?;
    let stdout = child.stdout.take().ok_or("no stdout")?;
    let mut line = String::new();
    BufReader::new(stdout).read_line(&mut line).map_err(|e| e.to_string())?;
    let ports: Value = serde_json::from_str(&line).map_err(|e| format!("{e}: {line}"))?;
    let port = |name: &str| ports[name].as_u64().unwrap_or(0) as u16;
    let second = |name: &str| ports["second"][name].as_u64().unwrap_or(0) as u16;
    Ok((
        (child, stdin),
        Ports {
            imap: port("imap"),
            smtp: port("smtp"),
            rest: port("rest"),
            cert: ports["cert"].as_str().unwrap_or_default().to_string(),
            second_imap: second("imap"),
            second_smtp: second("smtp"),
            second_rest: second("rest"),
        },
    ))
}

/// A request to ImapKit's REST API: its body, decoded from chunks when it came in them
fn http(port: u16, method: &str, path: &str, body: Option<&str>) -> Result<String, String> {
    let mut stream = std::net::TcpStream::connect(("127.0.0.1", port)).map_err(|e| e.to_string())?;
    stream.set_read_timeout(Some(Duration::from_secs(20))).ok();
    let body = body.unwrap_or("");
    let request = format!(
        "{method} {path} HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\nContent-Type: application/json\r\n\
         Content-Length: {}\r\n\r\n{body}",
        body.len()
    );
    stream.write_all(request.as_bytes()).map_err(|e| e.to_string())?;
    let mut response = Vec::new();
    stream.read_to_end(&mut response).map_err(|e| e.to_string())?;
    let text = String::from_utf8_lossy(&response);
    let (head, rest) = text.split_once("\r\n\r\n").ok_or("no header")?;
    if !head.starts_with("HTTP/1.1 2") {
        return Err(head.lines().next().unwrap_or_default().to_string());
    }
    if !head.to_ascii_lowercase().contains("transfer-encoding: chunked") {
        return Ok(rest.to_string());
    }
    let mut decoded = String::new();
    let mut rest = rest;
    while let Some((size, after)) = rest.split_once("\r\n") {
        let size = usize::from_str_radix(size.trim(), 16).unwrap_or(0);
        if size == 0 || after.len() < size {
            break;
        }
        decoded.push_str(&after[..size]);
        rest = after[size..].trim_start_matches("\r\n");
    }
    Ok(decoded)
}

impl Driver {
    fn messages(&self, mailbox: &str) -> Vec<Value> {
        self.messages_at(self.ports.rest, mailbox)
    }

    /// The messages of a mailbox of the server whose REST API is at `rest`
    fn messages_at(&self, rest: u16, mailbox: &str) -> Vec<Value> {
        let path = format!("/v1/mailboxes/{}/messages?raw=true", mailbox.replace('/', "%2F"));
        http(rest, "GET", &path, None)
            .ok()
            .and_then(|body| serde_json::from_str::<Value>(&body).ok())
            .and_then(|v| v.as_array().cloned())
            .unwrap_or_default()
    }

    fn mailboxes(&self) -> Vec<String> {
        http(self.ports.rest, "GET", "/v1/mailboxes", None)
            .ok()
            .and_then(|body| serde_json::from_str::<Value>(&body).ok())
            .and_then(|v| v.as_array().cloned())
            .unwrap_or_default()
            .iter()
            .filter_map(|m| m["path"].as_str().map(str::to_string))
            .collect()
    }

    /// The first message of `mailbox` whose source has `needle`
    fn find(&self, mailbox: &str, needle: &str) -> Option<Value> {
        self.messages(mailbox)
            .into_iter()
            .find(|m| raw_text(m).contains(needle))
    }

    /// How many messages of the Inbox of the server whose REST API is at `rest` are unread
    fn unread_at(&self, rest: u16) -> usize {
        self.messages_at(rest, "INBOX")
            .iter()
            .filter(|m| !m["flags"].as_array().is_some_and(|f| f.iter().any(|f| f == "\\Seen")))
            .count()
    }

    fn flags(&self, mailbox: &str, needle: &str) -> Vec<String> {
        self.find(mailbox, needle)
            .and_then(|m| m["flags"].as_array().cloned())
            .unwrap_or_default()
            .iter()
            .filter_map(|f| f.as_str().map(str::to_string))
            .collect()
    }

    fn seen(&self, needle: &str) -> bool {
        self.flags("INBOX", needle).iter().any(|f| f == "\\Seen")
    }

    fn add_message(&self, raw: &str, flags: &[&str]) -> Result<(), String> {
        self.add_message_at(self.ports.rest, raw, flags)
    }

    /// A message into the Inbox of the server whose REST API is at `rest`
    fn add_message_at(&self, rest: u16, raw: &str, flags: &[&str]) -> Result<(), String> {
        let body = serde_json::json!({ "raw": raw, "flags": flags }).to_string();
        http(rest, "POST", "/v1/mailboxes/INBOX/messages", Some(&body)).map(|_| ())
    }
}

/// The source of a message the REST API gave, base64 encoded
fn raw_text(message: &Value) -> String {
    let raw = message["raw"].as_str().unwrap_or_default();
    base64::engine::general_purpose::STANDARD
        .decode(raw.replace(['\r', '\n'], ""))
        .map(|bytes| String::from_utf8_lossy(&bytes).into_owned())
        .unwrap_or_default()
}

/// A picture sent inside the message: the newsletter's banner, as a PNG
fn banner_png() -> Vec<u8> {
    use gtk::cairo;
    let (width, height) = (560, 110);
    let Ok(mut surface) = cairo::ImageSurface::create(cairo::Format::ARgb32, width, height) else {
        return Vec::new();
    };
    if let Ok(cr) = cairo::Context::new(&surface) {
        cr.set_source_rgb(31.0 / 255.0, 77.0 / 255.0, 58.0 / 255.0);
        let _ = cr.paint();
        cr.set_source_rgb(1.0, 1.0, 1.0);
        cr.select_font_face("Serif", cairo::FontSlant::Normal, cairo::FontWeight::Bold);
        cr.set_font_size(30.0);
        cr.move_to(24.0, 54.0);
        let _ = cr.show_text("Trail Notes");
        cr.set_source_rgb(214.0 / 255.0, 232.0 / 255.0, 220.0 / 255.0);
        cr.select_font_face("Serif", cairo::FontSlant::Normal, cairo::FontWeight::Normal);
        cr.set_font_size(15.0);
        cr.move_to(26.0, 82.0);
        let _ = cr.show_text("Walks, maps and weekend ideas  |  October");
    }
    surface.flush();
    let stride = surface.stride() as usize;
    let Ok(data) = surface.data() else { return Vec::new() };
    let bytes = glib::Bytes::from(&*data);
    let texture = gdk::MemoryTexture::new(width, height, gdk::MemoryFormat::B8g8r8a8Premultiplied, &bytes, stride);
    texture.save_to_png_bytes().to_vec()
}

/// The mail of the test, newest first in the list: the newsletter, Ann's message, the minutes, Carol's reply
fn seed(driver: &Driver) -> Result<(), String> {
    let png = base64::engine::general_purpose::STANDARD.encode(banner_png());
    let pdf = "%PDF-1.4\n% a small attachment from the Linux UI test\n";
    let pdf64 = base64::engine::general_purpose::STANDARD.encode(pdf);
    driver.add_message(
        &format!(
            "From: Bob Harris <bob@example.com>\r\nTo: testuser@inboxclassic.test, Dave <dave@example.com>\r\n\
             Cc: Carol <carol@example.com>\r\nSubject: {MINUTES}\r\nMessage-ID: <minutes@example.com>\r\n\
             Date: Wed, 1 Oct 2025 09:00:00 +0000\r\n\r\nWe agreed on the dates.\r\n"
        ),
        &["\\Seen"],
    )?;
    driver.add_message(
        "From: Carol <carol@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Re: Lunch on Friday\r\n\
         Message-ID: <lunch2@example.com>\r\nIn-Reply-To: <lunch1@example.com>\r\nDate: Mon, 29 Sep 2025 12:00:00 +0000\r\n\
         Content-Type: text/html; charset=utf-8\r\n\r\n\
         <div dir=\"ltr\">Friday is fine, see you at noon.</div><br><div class=\"gmail_quote\"><div dir=\"ltr\" \
         class=\"gmail_attr\">On Mon, Sep 29, 2025 at 9:00 AM Alex Morgan &lt;testuser@inboxclassic.test&gt; wrote:<br></div>\
         <blockquote class=\"gmail_quote\" style=\"margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);\
         padding-left:1ex\">Lunch on Friday? The usual place.</blockquote></div>\r\n",
        &["\\Seen"],
    )?;
    driver.add_message(
        &format!(
            "From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: {SUBJECT}\r\n\
             Message-ID: <ui-e2e@example.com>\r\nDate: Mon, 6 Oct 2025 10:00:00 +0000\r\n\r\nHi Alex,\r\n\
             the photos from Saturday are in the shared album. The one from the lake came out best.\r\n\r\nAnn\r\n"
        ),
        &[],
    )?;
    let html = "<div style=\"font-family:Georgia,serif;max-width:560px;color:#222\">\
        <p><img src=\"cid:banner@example.com\" width=\"560\" height=\"110\" alt=\"Trail Notes\"></p>\
        <h2 style=\"color:#1f4d3a;margin:18px 0 6px\">Five autumn walks worth the drive</h2>\
        <p>The larches are turning gold and the summer crowds have gone home. This month we picked five routes for short \
        October days, each under four hours, with a warm cafe at the end.</p>\
        <p><a href=\"https://example.com/news\">Read the full guide</a> <script>alert(\"never runs\")</script></p>\
        <p style=\"color:#666;font-size:14px\">Photo of the month, sent in by a reader:</p>\
        <p><img src=\"https://nodemailer.com/img/nm_logo_200x136.png\" width=\"200\" height=\"136\" alt=\"Photo of the month\"></p></div>";
    driver.add_message(
        &format!(
            "From: Trail Notes <news@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: {NEWSLETTER}\r\n\
             Message-ID: <news@example.com>\r\nDate: Wed, 8 Oct 2025 08:00:00 +0000\r\nMIME-Version: 1.0\r\n\
             Content-Type: multipart/mixed; boundary=\"mixed\"\r\n\r\n--mixed\r\n\
             Content-Type: multipart/related; boundary=\"related\"\r\n\r\n--related\r\n\
             Content-Type: text/html; charset=utf-8\r\n\r\n{html}\r\n--related\r\n\
             Content-Type: image/png\r\nContent-ID: <banner@example.com>\r\nContent-Transfer-Encoding: base64\r\n\r\n{png}\r\n\
             --related--\r\n--mixed\r\nContent-Type: application/pdf; name=\"report.pdf\"\r\n\
             Content-Disposition: attachment; filename=\"report.pdf\"\r\nContent-Transfer-Encoding: base64\r\n\r\n{pdf64}\r\n\
             --mixed--\r\n"
        ),
        &["\\Flagged"],
    )
}

// ---- the driver's means ----

impl Driver {
    fn write(&self, line: &str) {
        println!("{line}");
        let _ = writeln!(self.log.borrow_mut(), "{line}");
    }

    fn step(&self, text: &str) {
        self.write(&format!("== {text}"));
    }

    fn check(&self, ok: bool, what: &str) {
        if ok {
            self.write(&format!("   ok: {what}"));
        } else {
            self.write(&format!("   FAILED: {what}"));
            self.failures.borrow_mut().push(what.to_string());
        }
    }

    /// The result written once, and the app ended when it still runs
    fn finish(&self) {
        if self.finished.replace(true) {
            return;
        }
        let failures = self.failures.borrow();
        let result = if failures.is_empty() {
            "passed".to_string()
        } else {
            format!("failed: {}", failures.len())
        };
        self.write(&format!("== {result}"));
        for failure in failures.iter() {
            self.write(&format!("   {failure}"));
        }
        let _ = std::fs::write(self.out.join("result.txt"), &result);
        drop(failures);
        shell().application.quit();
    }

    /// A picture of `widget`'s window: the window as GTK draws it, the web views in it as WebKit draws them, and the
    /// popovers open on it
    async fn shot(&self, widget: &impl IsA<gtk::Widget>, name: &str) {
        pause(700).await;
        let Some(window) = widget.as_ref().root().and_downcast::<gtk::Window>() else {
            self.write(&format!("   no window for {name}"));
            return;
        };
        match capture(&window).await {
            Some(texture) => {
                if let Err(error) = texture.save_to_png(self.out.join(format!("{name}.png"))) {
                    self.write(&format!("   {name}.png not saved: {error}"));
                }
            }
            None => self.write(&format!("   no picture of {name}")),
        }
    }
}

async fn pause(ms: u64) {
    glib::timeout_future(Duration::from_millis(ms)).await;
}

/// Waits up to `seconds` for `condition` to give something, which it returns
async fn wait_for<T>(seconds: u64, mut condition: impl FnMut() -> Option<T>) -> Option<T> {
    let deadline = Instant::now() + Duration::from_secs(seconds);
    loop {
        if let Some(value) = condition() {
            return Some(value);
        }
        if Instant::now() > deadline {
            return None;
        }
        pause(250).await;
    }
}

async fn wait_until(seconds: u64, mut condition: impl FnMut() -> bool) -> bool {
    wait_for(seconds, || condition().then_some(())).await.is_some()
}

/// The window drawn into a texture: GTK's drawing of it, the web views as WebKit draws them (dimmed as the rest
/// when a dialog is over them), the dialogs over that with their own web views, and the open popovers
async fn capture(window: &gtk::Window) -> Option<gdk::Texture> {
    let (width, height) = (window.width(), window.height());
    if width <= 0 || height <= 0 {
        return None;
    }
    let snapshot = gtk::Snapshot::new();
    paint_window(window, &snapshot, width, height).await;
    let root = window.clone().upcast::<gtk::Widget>();
    let dialogs: Vec<adw::Dialog> = descendants::<adw::Dialog>(&root)
        .into_iter()
        .filter(|d| d.is_mapped())
        .collect();
    let in_dialog = |view: &webkit::WebView| view.ancestor(adw::Dialog::static_type()).is_some();
    let dim = gdk::RGBA::new(0.0, 0.0, 0.0, 0.12);
    for view in descendants::<webkit::WebView>(&root) {
        if !in_dialog(&view)
            && let Some(bounds) = draw_web_view(&snapshot, &view, window).await
            && !dialogs.is_empty()
        {
            snapshot.append_color(&dim, &bounds);
        }
    }
    for dialog in &dialogs {
        let Some(bounds) = dialog.compute_bounds(window) else {
            continue;
        };
        snapshot.save();
        snapshot.translate(&graphene::Point::new(bounds.x(), bounds.y()));
        gtk::WidgetPaintable::new(Some(dialog)).snapshot(&snapshot, bounds.width() as f64, bounds.height() as f64);
        snapshot.restore();
        for view in descendants::<webkit::WebView>(dialog.upcast_ref()) {
            draw_web_view(&snapshot, &view, window).await;
        }
    }
    for popover in descendants::<gtk::Popover>(&root) {
        if !popover.is_visible() {
            continue;
        }
        let (w, h) = (popover.width() as f32, popover.height() as f32);
        let Some(point) = popover_origin(&popover, window) else {
            continue;
        };
        snapshot.save();
        snapshot.translate(&point);
        gtk::WidgetPaintable::new(Some(&popover)).snapshot(&snapshot, w as f64, h as f64);
        snapshot.restore();
    }
    let node = snapshot.to_node()?;
    let renderer = window.renderer()?;
    Some(renderer.render_texture(node, Some(&graphene::Rect::new(0.0, 0.0, width as f32, height as f32))))
}

/// The window as it was painted: taken in its next paint, as the picture is gone once anything in it changes (the
/// spinner of a message being downloaded turns all the time)
async fn paint_window(window: &gtk::Window, snapshot: &gtk::Snapshot, width: i32, height: i32) {
    let paint = || gtk::WidgetPaintable::new(Some(window)).current_image();
    let Some(clock) = window.frame_clock() else {
        paint().snapshot(snapshot, width as f64, height as f64);
        return;
    };
    let taken: Rc<RefCell<Option<gdk::Paintable>>> = Rc::default();
    let into = taken.clone();
    let painted = window.clone();
    let handler = clock.connect_after_paint(move |_| {
        if into.borrow().is_none() {
            into.replace(Some(gtk::WidgetPaintable::new(Some(&painted)).current_image()));
        }
    });
    window.queue_draw();
    wait_until(2, || taken.borrow().is_some()).await;
    clock.disconnect(handler);
    let image = taken.take().unwrap_or_else(paint);
    image.snapshot(snapshot, width as f64, height as f64);
}

/// A web view as WebKit draws it, where it is in the window; its bounds, None when it is not shown
async fn draw_web_view(
    snapshot: &gtk::Snapshot,
    view: &webkit::WebView,
    window: &gtk::Window,
) -> Option<graphene::Rect> {
    if !view.is_drawable() {
        return None;
    }
    let bounds = view.compute_bounds(window)?;
    let texture = view
        .snapshot_future(webkit::SnapshotRegion::Visible, webkit::SnapshotOptions::NONE)
        .await
        .ok()?;
    snapshot.append_texture(&texture, &bounds);
    Some(bounds)
}

/// Where a popover is drawn over its window: under the middle of what it points at, inside the window
fn popover_origin(popover: &gtk::Popover, window: &gtk::Window) -> Option<graphene::Point> {
    let parent = popover.parent()?;
    let bounds = parent.compute_bounds(window)?;
    let (w, h) = (popover.width() as f32, popover.height() as f32);
    let (x, y) = match popover.pointing_to() {
        (true, rect) => (
            bounds.x() + rect.x() as f32,
            bounds.y() + rect.y() as f32 + rect.height() as f32,
        ),
        _ => (bounds.x() + bounds.width() / 2.0, bounds.y() + bounds.height()),
    };
    let left = (x - w / 2.0).clamp(0.0, (window.width() as f32 - w).max(0.0));
    let top = y.min((window.height() as f32 - h).max(0.0));
    Some(graphene::Point::new(left, top))
}

/// Every widget of type `T` under `root`, popovers' children included
fn descendants<T: IsA<gtk::Widget>>(root: &gtk::Widget) -> Vec<T> {
    let mut found = Vec::new();
    let mut stack = vec![root.clone()];
    while let Some(widget) = stack.pop() {
        if let Some(typed) = widget.downcast_ref::<T>() {
            found.push(typed.clone());
        }
        let mut child = widget.first_child();
        while let Some(c) = child {
            stack.push(c.clone());
            child = c.next_sibling();
        }
    }
    found
}

/// The windows of the app, the main window first
fn windows() -> Vec<gtk::Window> {
    gtk::Window::list_toplevels()
        .into_iter()
        .filter_map(|w| w.downcast::<gtk::Window>().ok())
        .filter(|w| w.is_visible())
        .collect()
}

/// The shown widget named `name` in any window
fn named(name: &str) -> Option<gtk::Widget> {
    windows().iter().find_map(|w| named_in(w.upcast_ref(), name))
}

fn named_in(root: &gtk::Widget, name: &str) -> Option<gtk::Widget> {
    descendants::<gtk::Widget>(root)
        .into_iter()
        .find(|w| w.widget_name() == name && w.is_mapped())
}

fn set_text(root: &gtk::Widget, name: &str, text: &str) -> bool {
    match named_in(root, name).and_then(|w| w.dynamic_cast::<gtk::Editable>().ok()) {
        Some(editable) => {
            editable.set_text(text);
            true
        }
        None => false,
    }
}

fn text_of(root: &gtk::Widget, name: &str) -> String {
    named_in(root, name)
        .and_then(|w| w.dynamic_cast::<gtk::Editable>().ok())
        .map(|e| e.text().to_string())
        .unwrap_or_default()
}

fn click(root: &gtk::Widget, name: &str) -> bool {
    match named_in(root, name).and_then(|w| w.downcast::<gtk::Button>().ok()) {
        Some(button) if button.is_sensitive() => {
            button.emit_clicked();
            true
        }
        _ => false,
    }
}

/// The labels of a menu's items, its sections' included
fn menu_labels(popover: Option<&gtk::PopoverMenu>) -> Vec<String> {
    fn walk(model: &gio::MenuModel, labels: &mut Vec<String>) {
        for index in 0..model.n_items() {
            if let Some(section) = model.item_link(index, gio::MENU_LINK_SECTION) {
                walk(&section, labels);
            } else if let Some(label) = model
                .item_attribute_value(index, gio::MENU_ATTRIBUTE_LABEL, None)
                .and_then(|v| v.get::<String>())
            {
                labels.push(label);
            }
        }
    }
    let mut labels = Vec::new();
    if let Some(model) = popover.and_then(|p| p.menu_model()) {
        walk(&model, &mut labels);
    }
    labels
}

/// The text of a label named `name` under `root`
fn label_of(root: &gtk::Widget, name: &str) -> String {
    named_in(root, name)
        .and_downcast::<gtk::Label>()
        .map(|l| l.text().to_string())
        .unwrap_or_default()
}

/// The message box open, when there is one
fn alert() -> Option<adw::AlertDialog> {
    windows()
        .iter()
        .flat_map(|w| descendants::<adw::AlertDialog>(w.upcast_ref()))
        .find(|d| d.is_mapped())
}

fn alert_text(dialog: &adw::AlertDialog) -> String {
    format!("{} {}", dialog.heading().unwrap_or_default(), dialog.body())
}

/// Answers the message box with the button that reads `label`
fn answer(dialog: &adw::AlertDialog, label: &str) -> bool {
    let button = descendants::<gtk::Button>(dialog.upcast_ref()).into_iter().find(|b| {
        b.label().as_deref() == Some(label)
            || b.child()
                .and_downcast::<gtk::Label>()
                .is_some_and(|l| l.text() == label)
    });
    match button {
        Some(button) => {
            button.emit_clicked();
            true
        }
        None => false,
    }
}

async fn wait_alert(seconds: u64) -> Option<adw::AlertDialog> {
    wait_for(seconds, alert).await
}

fn dialog_named(name: &str) -> Option<adw::Dialog> {
    named(name).and_then(|w| w.downcast::<adw::Dialog>().ok())
}

async fn wait_dialog(seconds: u64, name: &str) -> Option<adw::Dialog> {
    wait_for(seconds, || dialog_named(name)).await
}

async fn wait_gone(seconds: u64, name: &str) -> bool {
    wait_until(seconds, || named(name).is_none()).await
}

fn main_window() -> gtk::Widget {
    shell().main().window().clone().upcast()
}

fn rows() -> u32 {
    shell().main().list.rows()
}

/// Selects the folder of the first account named so in the tree (the display name: Inbox, Sent Items, Drafts)
fn select_folder(name: &str) -> bool {
    let core = &shell().core;
    let Some(account) = core.accounts().ok().and_then(|a| a.first().map(|a| a.id)) else {
        return false;
    };
    let folder = core
        .folders(account)
        .unwrap_or_default()
        .into_iter()
        .find(|f| pe_core::folder_name(&f.info) == name);
    folder.is_some_and(|f| shell().main().folders.select(f.id))
}

async fn select_row(index: u32) {
    shell().main().list.select(index);
    pause(1500).await;
}

/// The compose window open last
fn compose() -> Option<Rc<crate::compose::Compose>> {
    shell().composes.borrow().last().cloned()
}

async fn wait_compose(seconds: u64) -> Option<Rc<crate::compose::Compose>> {
    let found = wait_for(seconds, compose).await?;
    // its editor's page there
    wait_until(10, || found.editor.is_loaded()).await;
    pause(300).await;
    Some(found)
}

/// The account a compose window sends from, as its From list shows it
fn compose_from(compose: &crate::compose::Compose) -> String {
    named_in(compose.window.upcast_ref(), "compose-from")
        .and_downcast::<gtk::DropDown>()
        .and_then(|d| d.selected_item())
        .and_downcast::<gtk::StringObject>()
        .map(|s| s.string().to_string())
        .unwrap_or_default()
}

async fn close_compose(compose: &crate::compose::Compose) {
    compose.window.close();
    if let Some(dialog) = wait_alert(3).await {
        answer(&dialog, "No");
    }
    wait_until(10, || !compose.window.is_visible()).await;
}

/// Runs a command as the menu would, outside the driver's own turn (a command may open a dialog with its own loop)
fn command(command: Command) {
    glib::idle_add_local_once(move || run_command(command));
}

// ---- the scenario ----

async fn scenario(d: Rc<Driver>) {
    add_account(&d, "Alex Morgan", "testuser", "testpass", true, false).await;
    reading(&d).await;
    writing(&d).await;
    steps::not_downloaded(&d).await;
    outbox(&d).await;
    drafts(&d).await;
    send_receive(&d).await;
    finding(&d).await;
    files(&d).await;
    organizing(&d).await;
    steps::unsubscribing(&d).await;
    steps::invitation_and_logo(&d).await;
    steps::collapsed_account(&d).await;
    steps::agent(&d).await;
    steps::mark_all_read(&d).await;
    steps::dragging(&d).await;
    steps::several_messages(&d).await;
    steps::junk(&d).await;
    steps::folders(&d).await;
    steps::closing_a_message(&d).await;
    steps::mailto(&d).await;
    steps::completing(&d).await;
    steps::signature(&d).await;
    steps::gmail(&d).await;
    wrong_password(&d).await;
    steps::all_inboxes(&d).await;
    accounts(&d).await;
    sign_in_apps(&d).await;
    about_and_help(&d).await;
    printing(&d).await;
    steps::closing(&d).await;
}

/// Both steps of the account form: the name and address, then the servers with the password; on the `second` server
async fn add_account(d: &Driver, name: &str, user: &str, password: &str, shots: bool, second: bool) {
    let (imap, smtp) = if second {
        (d.ports.second_imap, d.ports.second_smtp)
    } else {
        (d.ports.imap, d.ports.smtp)
    };
    d.step(&format!("adding the account {name}"));
    let Some(first) = wait_dialog(20, "account-start").await else {
        d.check(false, &format!("the account form opens ({name})"));
        return;
    };
    d.check(true, &format!("the account form opens ({name})"));
    let first = first.upcast::<gtk::Widget>();
    if shots {
        let google = named_in(&first, "sign-in-google").is_some();
        let microsoft = named_in(&first, "sign-in-microsoft").is_some();
        d.check(
            google && microsoft,
            "it starts with the Google and Microsoft sign-in buttons",
        );
        d.check(
            named_in(&first, "form-3").is_none(),
            "and asks no password before the servers are known",
        );
    }
    set_text(&first, "start-name", name);
    set_text(&first, "start-email", &format!("{user}@inboxclassic.test"));
    if shots {
        d.shot(&first, "account-1-form").await;
    }
    click(&first, "dialog-ok");
    if shots && let Some(wait) = wait_dialog(5, "wait-dialog").await {
        d.shot(&wait, "account-2-lookup").await;
    }
    // the lookup finds nothing for this domain: the second form comes with the usual names to correct
    let Some(second) = wait_dialog(40, "account-servers").await else {
        d.check(false, "the server settings form follows the lookup");
        return;
    };
    let second = second.upcast::<gtk::Widget>();
    d.check(true, "the server settings form follows the lookup");
    d.check(
        text_of(&second, "form-4") == "imap.inboxclassic.test",
        "the lookup guessed the IMAP server",
    );
    d.check(
        text_of(&second, "form-0") == name,
        "the server form keeps the name typed first",
    );
    set_text(&second, "form-2", user);
    set_text(&second, "form-3", password);
    set_text(&second, "form-4", "127.0.0.1");
    set_text(&second, "form-5", &imap.to_string());
    if let Some(combo) = named_in(&second, "form-6").and_downcast::<adw::ComboRow>() {
        combo.set_selected(2);
    }
    set_text(&second, "form-7", "127.0.0.1");
    set_text(&second, "form-8", &smtp.to_string());
    // ImapKit's SMTP server takes a password only after STARTTLS
    if let Some(combo) = named_in(&second, "form-9").and_downcast::<adw::ComboRow>() {
        combo.set_selected(1);
    }
    if shots {
        d.shot(&second, "account-3-servers").await;
    }
    click(&second, "dialog-ok");
    let warning = wait_alert(10).await;
    d.check(warning.is_some(), "a connection without encryption is warned about");
    if let Some(warning) = warning {
        if shots {
            d.shot(&warning, "account-4-warning").await;
        }
        answer(&warning, "Yes");
    }
}

async fn reading(d: &Driver) {
    d.step("syncing");
    let main = main_window();
    let folders = wait_for(30, || {
        let n = shell().main().folders.rows();
        (n >= 7).then_some(n)
    })
    .await;
    d.check(
        folders.is_some(),
        &format!("the folders of the account are in the tree ({folders:?})"),
    );
    select_folder("Inbox");
    let count = wait_for(30, || (rows() >= 4).then(rows)).await;
    d.check(count == Some(4), &format!("the messages are in the list ({count:?})"));
    d.shot(&main, "main-1-inbox").await;

    d.step("reading an HTML message");
    select_row(0).await;
    d.check(
        wait_until(20, || d.seen(NEWSLETTER)).await,
        "showing the message marked it read on the server",
    );
    let reader = &shell().main().reader;
    d.check(
        wait_until(10, || reader.attachments.is_visible()).await,
        "the paper clip of the attachments is there",
    );
    d.check(
        reader.pictures_blocked(),
        "the information bar says pictures are blocked",
    );
    let title = shell().main().window().title().unwrap_or_default();
    d.check(
        title == "Inbox - Inbox Classic",
        &format!("the title names the folder ({title})"),
    );
    pause(1500).await;
    d.shot(&main, "read-1-html").await;

    d.step("message properties");
    command(Command::Properties);
    match wait_dialog(10, "properties-dialog").await {
        Some(dialog) => {
            let text = named_in(dialog.upcast_ref(), "properties-text")
                .and_downcast::<gtk::TextView>()
                .map(|v| {
                    let buffer = v.buffer();
                    buffer.text(&buffer.start_iter(), &buffer.end_iter(), false).to_string()
                })
                .unwrap_or_default();
            d.check(
                text.contains("Subject: October newsletter") && !text.contains("larches are turning"),
                "File > Properties opens the headers of the message, without the body",
            );
            d.shot(&dialog, "read-7-properties").await;
            dialog.close();
        }
        None => d.check(false, "File > Properties opens the headers of the message"),
    }

    d.step("the message list menu and the message source");
    let mailbox = shell().main();
    let list_view: gtk::Widget = mailbox.list.view.clone().upcast();
    mailbox.message_menu(&list_view, 60.0, 60.0);
    let labels = menu_labels(mailbox.message_popover.borrow().as_ref());
    d.check(
        [
            "Reply to Sender",
            "Mark as Unread",
            "Move to Folder\u{2026}",
            "View Source",
            "Properties",
        ]
        .iter()
        .all(|label| labels.iter().any(|l| l == label)),
        &format!(
            "the message list has a right-click menu with the message's actions ({})",
            labels.join(", ")
        ),
    );
    d.check(
        !labels.iter().any(|l| l == "Mark as Read"),
        "a read message offers Mark as Unread, not Mark as Read",
    );
    d.shot(&main_window(), "read-14-menu").await;
    if let Some(popover) = mailbox.message_popover.borrow().as_ref() {
        popover.popdown();
    }
    let _ = list_view.activate_action("message.viewsource", None);
    match wait_dialog(10, "source-dialog").await {
        Some(dialog) => {
            let text = named_in(dialog.upcast_ref(), "properties-text")
                .and_downcast::<gtk::TextView>()
                .map(|v| {
                    let buffer = v.buffer();
                    buffer.text(&buffer.start_iter(), &buffer.end_iter(), false).to_string()
                })
                .unwrap_or_default();
            d.check(true, "View Source opens the whole message");
            d.check(
                text.contains("Subject: October newsletter")
                    && text.contains("Content-Type: multipart")
                    && text.contains("larches are turning"),
                "with its header and every part, as the server has it",
            );
            d.check(
                dialog.title() == "Message Source: October newsletter",
                &format!("the window names the message ({})", dialog.title()),
            );
            d.shot(&dialog, "read-15-source").await;
            let eml = d.out.join("source-saved.eml");
            let _ = std::fs::remove_file(&eml);
            FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![eml.clone()]));
            if let Some(save) = named_in(dialog.upcast_ref(), "source-save").and_downcast::<gtk::Button>() {
                save.emit_clicked();
            }
            let saved = wait_until(10, || {
                std::fs::read_to_string(&eml).is_ok_and(|t| t.contains("larches are turning"))
            })
            .await;
            d.check(saved, "Save As in it saves the message as it came");
            d.check(dialog_named("source-dialog").is_some(), "and the source stays open");
            dialog.close();
            d.check(wait_gone(10, "source-dialog").await, "Close closes it");
        }
        None => d.check(false, "View Source opens the whole message"),
    }

    d.step("pictures from the internet");
    reader.download_pictures.emit_clicked();
    d.check(
        wait_until(10, || !reader.pictures_blocked()).await,
        "clicking the bar shows the pictures, and the bar goes away",
    );
    pause(3000).await;
    d.shot(&main, "read-2-pictures").await;

    d.step("saving the attachment");
    reader.attachments.popup();
    pause(500).await;
    d.check(
        reader.attachments.is_active(),
        "the paper clip offers the files to save",
    );
    d.shot(&main, "read-3-attachments").await;
    reader.attachments.popdown();
    let saved = d.out.join("report.pdf");
    let _ = std::fs::remove_file(&saved);
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![saved.clone()]));
    let _ = WidgetExt::activate_action(
        shell().main().window(),
        "reader.save-attachment",
        Some(&0u32.to_variant()),
    );
    let content = wait_for(10, || std::fs::read_to_string(&saved).ok())
        .await
        .unwrap_or_default();
    d.check(
        content.starts_with("%PDF-1.4"),
        "the attachment is saved as it was sent",
    );

    d.step("marking unread and read");
    run_command(Command::MarkUnread);
    d.check(
        wait_until(20, || !d.seen(NEWSLETTER)).await,
        "Mark Unread clears \\Seen on the server",
    );
    d.shot(&main, "read-5-unread").await;
    run_command(Command::MarkRead);
    d.check(wait_until(20, || d.seen(NEWSLETTER)).await, "Mark Read sets it again");

    d.step("a reply with the earlier message folded");
    select_row(3).await;
    pause(1000).await;
    d.shot(&main, "read-6-folded").await;
}

async fn writing(d: &Driver) {
    d.step("forwarding");
    select_row(0).await;
    run_command(Command::Forward);
    match wait_compose(10).await {
        Some(c) => {
            d.check(
                c.subject.text() == format!("Fw: {NEWSLETTER}"),
                "the subject is marked Fw:",
            );
            d.check(c.to.text().is_empty(), "the recipients are left to the user");
            d.shot(&c.window, "write-1-forward").await;
            close_compose(&c).await;
        }
        None => d.check(false, "Forward opens a compose window"),
    }

    d.step("replying to all");
    select_row(2).await;
    run_command(Command::ReplyAll);
    match wait_compose(10).await {
        Some(c) => {
            let to = c.to.text().to_string();
            d.check(
                to.contains("bob@example.com") && to.contains("dave@example.com"),
                &format!("it goes to the sender and the others ({to})"),
            );
            d.check(!to.contains("testuser@"), "but not to the account itself");
            d.check(c.cc.text().contains("carol@example.com"), "with the Cc kept");
            d.check(
                WidgetExt::is_visible(&c.cc),
                "the Cc row is open, as it has someone in it",
            );
            d.shot(&c.window, "write-2-reply-all").await;
            close_compose(&c).await;
        }
        None => d.check(false, "Reply All opens a compose window"),
    }

    d.step("replying");
    select_row(1).await;
    run_command(Command::Reply);
    let Some(c) = wait_compose(10).await else {
        d.check(false, "Reply opens a compose window");
        return;
    };
    d.check(c.to.text().contains("ann@example.com"), "the reply goes to the sender");
    c.editor.focus();
    pause(300).await;
    if let Some(bold) = named_in(c.window.upcast_ref(), "Bold").and_downcast::<gtk::Button>() {
        bold.emit_clicked();
    }
    let bold = wait_until(10, || {
        named_in(c.window.upcast_ref(), "Bold")
            .and_downcast::<gtk::ToggleButton>()
            .is_some_and(|t| t.is_active())
    })
    .await;
    d.check(bold, "B shows bold is on");
    c.editor.type_text("Thanks, Ann. The lake one is my favourite too.");
    pause(500).await;
    d.shot(&c.window, "write-3-reply").await;
    click(c.window.upcast_ref(), "compose-send");
    let reply = wait_for(30, || d.find("INBOX", &format!("Subject: Re: {SUBJECT}"))).await;
    d.check(reply.is_some(), "the reply arrived over SMTP");
    if let Some(reply) = reply {
        let text = raw_text(&reply);
        d.check(
            text.contains("In-Reply-To: <ui-e2e@example.com>"),
            "the reply refers to the message it answers",
        );
        d.check(text.contains("my favourite too"), "the reply has what was typed");
        d.check(
            text.contains("Content-Type: text/html") && text.contains("Content-Type: text/plain"),
            "it is HTML with a text part",
        );
        d.check(text.contains("<b>Thanks, Ann"), "what was typed in bold is bold");
        d.check(
            text.contains("Original Message") && text.contains("shared album"),
            "the folded quote is sent along",
        );
        d.check(text.matches("shared album").count() == 2, "the quote is sent once");
    }
    let sent = wait_for(30, || d.find("Sent", &format!("Subject: Re: {SUBJECT}"))).await;
    d.check(sent.is_some(), "a copy of the reply is in Sent");

    d.step("a new message");
    run_command(Command::NewMail);
    let Some(c) = wait_compose(10).await else {
        d.check(false, "Create Mail opens an empty compose window");
        return;
    };
    d.check(
        !WidgetExt::is_visible(&c.cc) && !WidgetExt::is_visible(&c.bcc) && !c.attached.is_visible(),
        "a new message shows no empty Cc, Bcc or Attach row",
    );
    d.check(
        c.cc_button.is_visible() && c.bcc_button.is_visible(),
        "the Cc and Bcc buttons are at the end of the To row",
    );
    d.shot(&c.window, "write-0-new-empty").await;
    c.cc_button.emit_clicked();
    d.check(
        wait_until(5, || WidgetExt::is_visible(&c.cc) && !c.cc_button.is_visible()).await,
        "Cc opens its row, and its button goes",
    );
    let from = compose_from(&c);
    d.check(
        from == "Alex Morgan <testuser@inboxclassic.test>",
        &format!("From names the account it goes from ({from})"),
    );
    c.to.set_text("dave at example.com");
    c.subject.set_text("Trail map for Sunday");
    c.editor
        .type_text("Hi Dave, here is the trail map for Sunday. See you at nine!");
    pause(500).await;
    click(c.window.upcast_ref(), "compose-send");
    let problem = wait_alert(10).await;
    d.check(problem.is_some(), "a mistyped address is pointed out before sending");
    if let Some(problem) = problem {
        d.shot(&problem, "write-4-bad-address").await;
        answer(&problem, "OK");
    }
    d.check(
        wait_until(5, || alert().is_none() && c.window.is_visible()).await,
        "and the message stays open to fix it",
    );
    c.to.set_text("Dave <dave@example.com>");
    let files = std::env::temp_dir().join("ic-ui-attach");
    let _ = std::fs::create_dir_all(&files);
    let _ = std::fs::write(files.join("trail-map.txt"), "the attachment that goes\n");
    let _ = std::fs::write(files.join("packing-list.txt"), "attached by mistake\n");
    for file in ["trail-map.txt", "packing-list.txt"] {
        FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![files.join(file)]));
        click(c.window.upcast_ref(), "compose-attach");
        pause(300).await;
    }
    d.check(
        wait_until(5, || c.file_labels().len() == 2).await,
        "Attach adds the files to the Attach row",
    );
    d.shot(&c.window, "write-5-new").await;
    if let Some(second) = c.attached.child_at_index(1) {
        c.attached.select_child(&second);
        // Delete in the Attach row, as the key does it
        c.remove_selected_file();
    }
    d.check(
        wait_until(5, || c.file_labels().len() == 1).await,
        "Delete in the Attach row takes one off",
    );
    click(c.window.upcast_ref(), "compose-send");
    let new = wait_for(30, || d.find("INBOX", "Subject: Trail map for Sunday")).await;
    d.check(new.is_some(), "the new message was sent");
    let raw = new.as_ref().map(raw_text).unwrap_or_default();
    d.check(raw.contains("here is the trail map for Sunday"), "with what was typed");
    d.check(
        raw.contains("trail-map.txt") && !raw.contains("packing-list"),
        "with only the file left attached",
    );
    d.check(
        raw.contains("Content-Type: text/plain") && !raw.contains("Content-Type: text/html"),
        "nothing formatted: it went as plain text",
    );
}

/// The outgoing server out of reach, as when offline: its port changed in Accounts > Properties to one nothing
/// listens on, and back
async fn set_smtp_port(d: &Driver, port: &str) {
    set_port(d, "form-8", port).await;
}

/// A server's port (`form-5` the incoming, `form-8` the outgoing) changed in Accounts > Properties
async fn set_port(d: &Driver, field: &str, port: &str) {
    command(Command::Accounts);
    let Some(accounts) = wait_dialog(10, "accounts-dialog").await else {
        d.check(false, "File > Accounts opens");
        return;
    };
    let accounts = accounts.upcast::<gtk::Widget>();
    click(&accounts, "accounts-properties");
    let Some(form) = wait_dialog(10, "account-properties").await else {
        d.check(false, "Properties opens");
        return;
    };
    set_text(form.upcast_ref(), field, port);
    click(form.upcast_ref(), "dialog-ok");
    // a question about a connection without encryption: Yes
    if let Some(question) = wait_alert(5).await {
        answer(&question, "Yes");
    }
    wait_gone(10, "account-properties").await;
    if let Some(dialog) = accounts.downcast_ref::<adw::Dialog>() {
        dialog.close();
    }
    wait_gone(10, "accounts-dialog").await;
}

async fn outbox(d: &Driver) {
    d.step("the Outbox: a send that can not go");
    set_smtp_port(d, "1").await;
    run_command(Command::NewMail);
    let Some(c) = wait_compose(10).await else {
        d.check(false, "Create Mail opens a compose window");
        return;
    };
    c.to.set_text("Erin <erin@example.com>");
    c.subject.set_text("Waited in the Outbox in the UI test");
    c.editor.type_text("This waited in the Outbox.");
    pause(400).await;
    click(c.window.upcast_ref(), "compose-send");
    d.check(
        wait_until(10, || !c.window.is_visible()).await,
        "Send closes the message",
    );
    let waits = wait_until(40, || shell().main().status_texts().1.contains("Outbox")).await;
    d.check(
        waits,
        &format!(
            "a send that can not go says it waits in the Outbox ({})",
            shell().main().status_texts().1
        ),
    );
    d.check(
        d.find("INBOX", "Subject: Waited in the Outbox in the UI test")
            .is_none(),
        "and it was not sent",
    );
    command(Command::Outbox);
    match wait_dialog(10, "outbox-dialog").await {
        Some(dialog) => {
            let rows = named_in(dialog.upcast_ref(), "outbox-list")
                .map(|l| descendants::<adw::ActionRow>(&l).len())
                .unwrap_or(0);
            d.check(rows == 1, "Tools > Outbox lists what waits");
            d.shot(&dialog, "write-7-outbox").await;
            dialog.close();
            wait_gone(10, "outbox-dialog").await;
        }
        None => d.check(false, "Tools > Outbox lists what waits"),
    }
    // the server back: the settings change syncs the account, and a sync sends the Outbox first
    set_smtp_port(d, &d.ports.smtp.to_string()).await;
    shell().sync_all();
    let gone = wait_for(40, || d.find("INBOX", "Subject: Waited in the Outbox in the UI test")).await;
    d.check(gone.is_some(), "once the server is back it goes by itself");
}

async fn drafts(d: &Driver) {
    d.step("Drafts");
    let main = main_window();
    run_command(Command::NewMail);
    let Some(c) = wait_compose(10).await else {
        d.check(false, "Create Mail opens a compose window");
        return;
    };
    c.to.set_text("Fay <fay@example.com>");
    c.subject.set_text("Draft from the UI test");
    c.editor.type_text("Half written.");
    pause(500).await;
    c.window.close();
    let ask = wait_alert(10).await;
    d.check(ask.is_some(), "closing a written message asks to save it");
    if let Some(ask) = ask {
        d.shot(&ask, "write-8-save-draft").await;
        answer(&ask, "Yes");
    }
    d.check(
        wait_until(10, || !c.window.is_visible()).await,
        "Yes saves it and closes the window",
    );
    let draft = wait_for(30, || d.find("Drafts", "Subject: Draft from the UI test")).await;
    d.check(draft.is_some(), "the draft is in Drafts on the server");
    let flags = d.flags("Drafts", "Subject: Draft from the UI test");
    d.check(flags.iter().any(|f| f == "\\Draft"), "marked as a draft");
    select_folder("Drafts");
    d.check(wait_until(30, || rows() >= 1).await, "Drafts lists it");
    select_row(0).await;
    // Enter on the draft opens it to go on writing
    shell().main().open_selected();
    let Some(c) = wait_compose(20).await else {
        d.check(false, "opening the draft opens a compose window");
        return;
    };
    d.check(c.subject.text() == "Draft from the UI test", "with its subject");
    d.check(c.to.text().contains("fay@example.com"), "and its recipient");
    c.editor.focus();
    c.editor.exec("selectAll", "");
    c.editor.run_script("window.getSelection().collapseToEnd()");
    c.editor.type_text(" Now finished.");
    pause(500).await;
    d.shot(&c.window, "write-9-draft-reopened").await;
    click(c.window.upcast_ref(), "compose-save");
    let replaced = wait_until(30, || {
        let all = d.messages("Drafts");
        all.len() == 1 && raw_text(&all[0]).contains("Now finished")
    })
    .await;
    d.check(replaced, "Save replaces the draft");
    let said = wait_until(30, || c.status.text().starts_with("Saved in Drafts at ")).await;
    d.check(
        said,
        &format!("the message window says when the draft is saved ({})", c.status.text()),
    );
    d.shot(&c.window, "write-10-draft-saved").await;
    click(c.window.upcast_ref(), "compose-send");
    let finished = wait_for(30, || d.find("INBOX", "Subject: Draft from the UI test")).await;
    d.check(finished.is_some(), "the finished draft is sent");
    let raw = finished.as_ref().map(raw_text).unwrap_or_default();
    d.check(
        raw.contains("Half written") && raw.contains("Now finished"),
        "with all that was written",
    );
    d.check(
        wait_until(30, || d.messages("Drafts").is_empty()).await,
        "and its draft is gone",
    );
    let outgoing = wait_until(30, || {
        let text = shell().main().status_texts().1;
        text.starts_with("Sent ") && text.contains("Draft from the UI test")
    })
    .await;
    d.check(
        outgoing,
        &format!(
            "the main window says what was sent ({})",
            shell().main().status_texts().1
        ),
    );
    d.shot(&main, "write-11-sent").await;
    select_folder("Inbox");
}

async fn send_receive(d: &Driver) {
    d.step("Send/Recv");
    let main = main_window();
    let now = glib::DateTime::now_utc()
        .and_then(|t| t.format("%a, %d %b %Y %H:%M:%S +0000"))
        .unwrap_or_default();
    let added = d.add_message(
        &format!(
            "From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: One more thing\r\n\
             Message-ID: <later@example.com>\r\nDate: {now}\r\n\r\nArrived later.\r\n"
        ),
        &[],
    );
    d.check(added.is_ok(), "new mail is put into ImapKit");
    run_command(Command::Sync);
    d.check(
        wait_until(30, || rows() >= 7).await,
        &format!("the new mail is in the list ({})", rows()),
    );
    d.shot(&main, "main-2-new-mail").await;
    select_folder("Sent Items");
    d.check(wait_until(20, || rows() >= 2).await, "Sent Items has what was sent");
    select_row(0).await;
    d.shot(&main, "main-3-sent-items").await;
    select_folder("Inbox");
}

async fn search(text: &str) {
    shell().main().find.set_text(text);
    pause(600).await;
}

async fn finding(d: &Driver) {
    d.step("finding");
    let main = main_window();
    let mailbox = shell().main();
    select_folder("Inbox");
    let all = wait_for(20, || (rows() >= 7).then(rows)).await.unwrap_or(0);
    d.check(
        !mailbox.list.columns.folder.is_visible(),
        "a folder has no Folder column",
    );
    search("lunch").await;
    d.check(
        wait_until(10, || rows() == 1).await,
        "typing in it narrows the list to what has it (the subject)",
    );
    d.check(
        mailbox.list.columns.folder.is_visible(),
        "it searches every folder: the list has a Folder column",
    );
    let summary = mailbox.search_summary().unwrap_or_default();
    d.check(
        summary.starts_with("1 result for \u{201C}lunch\u{201D} in all folders"),
        &format!("the search bar says what was found for what ({summary})"),
    );
    let title = mailbox.window().title().unwrap_or_default();
    d.check(
        title.starts_with("All folders"),
        &format!("the title says where ({title})"),
    );
    d.shot(&main, "find-1-results").await;
    search("ann@example.com").await;
    d.check(wait_until(10, || rows() >= 2).await, "the sender address is found too");
    search("nothing has this").await;
    d.check(wait_until(10, || rows() == 0).await, "and nothing when nothing has it");
    let summary = mailbox.search_summary().unwrap_or_default();
    d.check(
        summary.starts_with("No results for \u{201C}nothing has this\u{201D}"),
        &format!("the search bar says there are no results ({summary})"),
    );
    d.shot(&main, "find-3-no-results").await;
    search("").await;
    d.check(
        wait_until(10, || rows() == all && !mailbox.list.columns.folder.is_visible()).await,
        "clearing it shows the folder again, without the Folder column",
    );
    d.check(mailbox.search_summary().is_none(), "and without the search bar");
    run_command(Command::Sync);
    search("agreed dates").await;
    d.check(
        wait_until(40, || {
            // the text is read in the background: the search follows when it is in
            if rows() != 1 {
                shell().main().find.set_text("agreed  dates");
                shell().main().find.set_text("agreed dates");
            }
            rows() == 1
        })
        .await,
        "words of the text are found",
    );
    search("from:carol").await;
    d.check(wait_until(10, || rows() == 1).await, "Gmail operators work: from:");
    search("").await;
    search("photos in:inbox").await;
    let in_inbox = wait_for(10, || (rows() >= 1 && rows() < all).then(rows)).await;
    let summary = mailbox.search_summary().unwrap_or_default();
    d.check(
        summary.ends_with(" in Inbox") && mailbox.selected_name() == "Inbox",
        &format!("in:inbox: the title and the search bar say the Inbox ({summary})"),
    );
    search("photos").await;
    let everywhere = wait_for(10, || (rows() > in_inbox.unwrap_or(0)).then(rows)).await;
    d.check(in_inbox.is_some() && everywhere.is_some(), &format!("the messages of other folders are found too ({everywhere:?}), in:inbox narrows them to the Inbox ({in_inbox:?})"));
    select_row(0).await;
    d.shot(&main, "find-2-every-folder").await;
    search("is:unread").await;
    d.check(
        wait_until(10, || rows() >= 1 && rows() < all).await,
        "is:unread lists the unread messages",
    );
    search("photos").await;
    select_row(0).await;
    d.check(
        wait_until(10, || mailbox.reader.header_text().contains('@')).await,
        "a result is shown in the reading pane",
    );
    if let Some(clear) = named("search-clear").and_downcast::<gtk::Button>() {
        clear.emit_clicked();
    }
    d.check(
        wait_until(10, || {
            rows() == all && mailbox.find.text().is_empty() && mailbox.search_summary().is_none()
        })
        .await,
        "Clear search on the search bar ends the search",
    );
    search("photos").await;
    mailbox.find.emit_by_name::<()>("stop-search", &[]);
    d.check(
        wait_until(10, || rows() == all && !mailbox.list.columns.folder.is_visible()).await,
        "Esc ends the search: the folder again, without the Folder column",
    );
}

async fn files(d: &Driver) {
    d.step("saving and importing a message as a file");
    select_folder("Inbox");
    wait_until(10, || rows() >= 7).await;
    select_row(rows() - 1).await;
    let eml = d.out.join("saved-message.eml");
    let _ = std::fs::remove_file(&eml);
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![eml.clone()]));
    command(Command::SaveAs);
    let saved = wait_until(10, || {
        std::fs::read_to_string(&eml).is_ok_and(|t| t.contains("Subject: Re: Lunch on Friday"))
    })
    .await;
    d.check(saved, "Save As saves the message as it came");
    select_folder("Archive");
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![eml.clone()]));
    command(Command::Import);
    let imported = wait_for(20, || d.find("Archive", "Subject: Re: Lunch on Friday")).await;
    d.check(
        imported.is_some(),
        "Import Messages puts the message in the folder, on the server",
    );
    select_folder("Inbox");
}

async fn organizing(d: &Driver) {
    d.step("flagging, deleting and moving");
    let main = main_window();
    select_folder("Inbox");
    wait_until(10, || rows() >= 7).await;
    select_row(0).await;
    d.check(
        !shell().main().reader.pictures_blocked(),
        "a plain text message does not offer Download pictures",
    );
    run_command(Command::Flag);
    d.check(
        wait_until(20, || {
            d.flags("INBOX", "Subject: One more thing")
                .iter()
                .any(|f| f == "\\Flagged")
        })
        .await,
        "Flag Message flags it on the server",
    );
    d.shot(&main, "organize-1-flagged").await;
    let listed = rows();
    command(Command::Delete);
    d.check(
        wait_for(20, || d.find("Trash", "Subject: One more thing"))
            .await
            .is_some(),
        "Delete puts it in Deleted Items",
    );
    d.check(
        d.find("INBOX", "Subject: One more thing").is_none(),
        "and takes it out of the Inbox",
    );
    d.check(wait_until(10, || rows() == listed - 1).await, "the list has one less");
    let moving = shell()
        .main()
        .list
        .selected()
        .map(|(_, m)| m.info.subject)
        .unwrap_or_default();
    command(Command::Move);
    match wait_dialog(10, "move-dialog").await {
        Some(dialog) => {
            if let Some(combo) = named_in(dialog.upcast_ref(), "form-0").and_downcast::<adw::ComboRow>() {
                let model = combo.model().and_downcast::<gtk::StringList>();
                let archive = model.and_then(|m| (0..m.n_items()).find(|i| m.string(*i).as_deref() == Some("Archive")));
                if let Some(index) = archive {
                    combo.set_selected(index);
                }
            }
            d.shot(&dialog, "organize-2-move").await;
            click(dialog.upcast_ref(), "dialog-ok");
            let moved = wait_for(20, || d.find("Archive", &format!("Subject: {moving}"))).await;
            d.check(
                moved.is_some(),
                &format!("the selected message is in Archive ({moving})"),
            );
            d.check(wait_until(10, || rows() == listed - 2).await, "and out of the list");
        }
        None => d.check(false, "Move to Folder asks where"),
    }
    d.shot(&main, "organize-3-after").await;
    select_folder("Deleted Items");
    wait_until(10, || rows() >= 1).await;
    select_row(0).await;
    command(Command::Delete);
    let sure = wait_alert(10).await;
    d.check(sure.is_some(), "deleting for good asks first");
    if let Some(sure) = sure {
        d.shot(&sure, "organize-4-for-good").await;
        answer(&sure, "Yes");
    }
    d.check(
        wait_until(20, || d.find("Trash", "Subject: One more thing").is_none()).await,
        "and then it is gone from the server",
    );
    select_folder("Inbox");
}

async fn wrong_password(d: &Driver) {
    d.step("a wrong password");
    // the second account's mail, on a server of its own, newer than the first account's
    steps::seed_second(d);
    command(Command::NewAccount);
    add_account(d, "Work", "testuser2", "not-the-password", false, true).await;
    let logon = wait_dialog(30, "logon").await;
    d.check(logon.is_some(), "a refused password is asked for again");
    if let Some(logon) = logon {
        let status = shell().main().status_texts().0;
        d.check(
            status.to_lowercase().contains("authentication"),
            &format!("the status bar says why ({status})"),
        );
        d.shot(&logon, "trouble-1-password").await;
        // the right password, and the account syncs
        set_text(logon.upcast_ref(), "form-0", "testpass2");
        click(logon.upcast_ref(), "dialog-ok");
        let synced = wait_until(30, || {
            steps::second_inbox().is_some_and(|inbox| shell().core.folder(inbox).is_ok_and(|f| f.total >= 2))
        })
        .await;
        d.check(synced, "with the right password typed, the account syncs");
    }
}

async fn accounts(d: &Driver) {
    d.step("accounts");
    command(Command::Accounts);
    let Some(accounts) = wait_dialog(10, "accounts-dialog").await else {
        d.check(false, "File > Accounts lists the accounts");
        return;
    };
    let accounts = accounts.upcast::<gtk::Widget>();
    let listed = named_in(&accounts, "accounts-list")
        .map(|l| descendants::<adw::ActionRow>(&l).len())
        .unwrap_or(0);
    d.check(listed == 2, &format!("both accounts are listed ({listed})"));
    d.shot(&accounts, "accounts-1-list").await;
    click(&accounts, "accounts-properties");
    match wait_dialog(10, "account-properties").await {
        Some(form) => {
            d.check(
                text_of(form.upcast_ref(), "form-5") == d.ports.imap.to_string(),
                "Properties shows the settings, with the IMAP port as it was saved",
            );
            set_text(form.upcast_ref(), "form-0", "Alex Morgan Renamed");
            d.shot(&form, "accounts-2-properties").await;
            click(form.upcast_ref(), "dialog-ok");
            if let Some(question) = wait_alert(3).await {
                answer(&question, "Yes");
            }
            d.check(wait_gone(10, "account-properties").await, "OK closes Properties");
        }
        None => d.check(false, "Properties shows the settings"),
    }
    let renamed = shell()
        .core
        .accounts()
        .unwrap_or_default()
        .iter()
        .any(|a| a.settings.name == "Alex Morgan Renamed");
    d.check(renamed, "the new name is saved");
    // Remove the second, the one with the wrong password
    if let Some(list) = named_in(&accounts, "accounts-list").and_downcast::<gtk::ListBox>() {
        list.select_row(list.row_at_index(1).as_ref());
    }
    click(&accounts, "accounts-remove");
    let sure = wait_alert(10).await;
    d.check(sure.is_some(), "Remove asks first");
    if let Some(sure) = sure {
        answer(&sure, "Yes");
    }
    let one = wait_until(10, || shell().core.accounts().map(|a| a.len() == 1).unwrap_or(false)).await;
    d.check(one, "and removes it");
    if let Some(dialog) = accounts.downcast_ref::<adw::Dialog>() {
        dialog.close();
    }
    wait_gone(10, "accounts-dialog").await;
    d.check(
        wait_until(10, || {
            shell().main().folders.markup_of(crate::folders::ALL_INBOXES).is_none()
        })
        .await,
        "All Inboxes goes with the second account",
    );
    d.shot(&main_window(), "accounts-3-after").await;
}

async fn sign_in_apps(d: &Driver) {
    d.step("sign-in apps");
    command(Command::Accounts);
    let Some(accounts) = wait_dialog(10, "accounts-dialog").await else {
        d.check(false, "File > Accounts opens");
        return;
    };
    click(accounts.upcast_ref(), "accounts-sign-in-apps");
    let Some(apps) = wait_dialog(10, "sign-in-apps-dialog").await else {
        d.check(false, "File > Accounts > Sign-in Apps opens the sign-in apps");
        return;
    };
    let apps_widget = apps.clone().upcast::<gtk::Widget>();
    let rows = named_in(&apps_widget, "sign-in-apps-list")
        .map(|l| descendants::<adw::ActionRow>(&l).len())
        .unwrap_or(0);
    d.check(
        rows == 2,
        &format!("the built-in Microsoft and Google clients are listed ({rows})"),
    );
    let on = |i: usize| {
        named_in(&apps_widget, &format!("app-on-{i}"))
            .and_downcast::<gtk::Switch>()
            .is_some_and(|s| s.is_active())
    };
    d.check(on(0) && !on(1), "Microsoft is on and Google off out of the box");
    let edit = named_in(&apps_widget, "apps-edit").is_some_and(|b| b.is_sensitive());
    let remove = named_in(&apps_widget, "apps-remove").is_some_and(|b| b.is_sensitive());
    d.check(!edit && !remove, "a built-in client can not be edited or removed");
    let note = named_in(&apps_widget, "sign-in-apps-note")
        .and_downcast::<gtk::Label>()
        .map(|l| l.text().to_string())
        .unwrap_or_default();
    d.check(note.contains("built in"), "a built-in client says what it is");
    d.shot(&apps, "signin-1-apps").await;
    click(&apps_widget, "apps-add");
    match wait_dialog(10, "sign-in-app-editor").await {
        Some(editor) => {
            let editor_widget = editor.clone().upcast::<gtk::Widget>();
            let google = pe_oauth::Preset::all()
                .iter()
                .position(|p| p.name == "Google")
                .unwrap_or(0);
            click(&editor_widget, &format!("app-preset-{google}"));
            d.check(
                wait_until(5, || {
                    text_of(&editor_widget, "app-issuer") == "https://accounts.google.com"
                })
                .await,
                "Fill in for Google fills in its issuer",
            );
            d.check(
                text_of(&editor_widget, "app-imap-host") == "imap.gmail.com"
                    && text_of(&editor_widget, "app-redirect") == "http://127.0.0.1",
                "its servers, and the redirect URI to register",
            );
            d.shot(&editor, "signin-2-google-preset").await;
            editor.close();
            wait_gone(10, "sign-in-app-editor").await;
        }
        None => d.check(false, "Add opens the sign-in app editor"),
    }
    apps.close();
    wait_gone(10, "sign-in-apps-dialog").await;
    accounts.close();
    wait_gone(10, "accounts-dialog").await;
}

async fn about_and_help(d: &Driver) {
    d.step("about");
    command(Command::About);
    let about = wait_for(10, || {
        windows()
            .iter()
            .flat_map(|w| descendants::<adw::AboutDialog>(w.upcast_ref()))
            .find(|a| a.is_mapped())
    })
    .await;
    d.check(
        about.as_ref().is_some_and(|a| a.version() == crate::VERSION),
        "About shows the version",
    );
    if let Some(about) = about {
        d.shot(&about, "help-1-about").await;
        about.close();
    }
    d.step("help");
    command(Command::Help);
    let help = wait_for(10, || windows().into_iter().find(|w| w.widget_name() == "help-window")).await;
    d.check(help.is_some(), "F1 opens the help");
    if let Some(help) = help {
        pause(3000).await;
        d.shot(&help, "help-2-contents").await;
        help.close();
    }
}

async fn printing(d: &Driver) {
    d.step("printing");
    select_folder("Inbox");
    wait_until(10, || rows() >= 1).await;
    select_row(1).await;
    pause(1000).await;
    command(Command::Print);
    let main = shell().main().window().clone().upcast::<gtk::Window>();
    let dialog = wait_for(20, || {
        windows()
            .into_iter()
            .find(|w| w != &main && w.is::<gtk::PrintUnixDialog>())
    })
    .await;
    d.check(dialog.is_some(), "Print opens the print dialog over the app");
    if let Some(dialog) = dialog {
        pause(2000).await;
        d.shot(&dialog, "files-3-print").await;
        // closed: the same as Cancel
        dialog.close();
        d.check(
            wait_until(10, || !dialog.is_visible()).await,
            "and closing it prints nothing",
        );
    }
}
