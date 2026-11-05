//! Inbox Classic on Linux: the main window with the folders on the left, the message list on the top right and the
//! reading pane below it, in GTK 4 and libadwaita. All mail data comes from the Rust core (`pe-core`), linked as a
//! crate; the windows show what it decoded and sanitized, and the web views show its documents as they are.
#![forbid(unsafe_code)]

mod accounts;
mod agents;
mod app;
mod complete;
mod compose;
#[cfg(feature = "e2e")]
mod e2e;
mod editor;
mod folders;
mod help;
mod mailbox;
mod messages;
mod notify;
mod outbox;
mod reader;
mod settings;
mod sign_in_apps;
mod tray;
mod ui;
mod webview;

#[rustfmt::skip]
#[path = "generated/commands.rs"]
mod commands;

use std::path::PathBuf;

use adw::prelude::*;
use gtk::{gio, glib};

/// The app id: the desktop file, the icon and the D-Bus name of the default mail store
pub const APP_ID: &str = "com.inboxclassic.InboxClassic";
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// The command line. Options for test runs: --store <file> uses another mail store, --memory-passwords keeps passwords
/// for this run only, --pin-certificate <file> trusts only that server certificate, --sign-in-page-file <file> writes
/// the page of a browser sign-in there for the test to open instead of the browser. A mailto: link (and what follows
/// it) is a new message to write; a file is a message to put into the selected folder.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct Arguments {
    pub store: Option<PathBuf>,
    pub certificate: Option<PathBuf>,
    pub memory_passwords: bool,
    pub sign_in_page_file: Option<PathBuf>,
    pub version: bool,
    pub mailto: Option<String>,
    pub files: Vec<PathBuf>,
    /// The UI end-to-end test, its screenshots and log to this folder (builds with the `e2e` feature only)
    pub e2e: Option<PathBuf>,
    /// --mcp: relay an AI agent's MCP connection to the app that is running (started when it is not), no window
    pub mcp: bool,
    /// --background: started for an agent (by --mcp), without its window
    pub background: bool,
}

impl Arguments {
    /// Reads the arguments after the program's name. A mailto: link is the rest of the command line, whatever it has
    /// in it: a link made up to look like more arguments stays part of the link
    pub fn parse<S: AsRef<str>>(args: &[S]) -> Arguments {
        let mut parsed = Arguments::default();
        let mut rest = args.iter().map(AsRef::as_ref);
        while let Some(arg) = rest.next() {
            if arg.len() >= 7 && arg[..7].eq_ignore_ascii_case("mailto:") {
                let tail: Vec<&str> = std::iter::once(arg).chain(rest.by_ref()).collect();
                parsed.mailto = Some(tail.join(" "));
                break;
            }
            match arg {
                "--store" => parsed.store = rest.next().map(PathBuf::from),
                "--pin-certificate" => parsed.certificate = rest.next().map(PathBuf::from),
                "--sign-in-page-file" => parsed.sign_in_page_file = rest.next().map(PathBuf::from),
                "--e2e" => parsed.e2e = rest.next().map(PathBuf::from),
                "--memory-passwords" => parsed.memory_passwords = true,
                "--version" => parsed.version = true,
                "--mcp" => parsed.mcp = true,
                "--background" => parsed.background = true,
                file if !file.starts_with("--") => parsed.files.push(file_path(file)),
                _ => {}
            }
        }
        parsed
    }
}

/// A file argument as a path: a file:// URI (as file managers hand them) or a path
fn file_path(arg: &str) -> PathBuf {
    if arg.starts_with("file://")
        && let Some(path) = gio::File::for_uri(arg).path()
    {
        return path;
    }
    PathBuf::from(arg)
}

/// The mail store: $XDG_DATA_HOME/inbox-classic/store.db
pub fn default_store() -> PathBuf {
    glib::user_data_dir().join("inbox-classic").join("store.db")
}

/// The D-Bus name the app runs under: its own for the default store, and one for each other store, so another start
/// for the same store hands over to the one running (as on Windows) and a test store runs beside the real one
fn application_id(store: Option<&PathBuf>) -> String {
    match store {
        None => APP_ID.to_string(),
        Some(path) => {
            let path = std::fs::canonicalize(path).unwrap_or_else(|_| path.clone());
            // FNV-1a, the same in every process of this build
            let hash = path
                .to_string_lossy()
                .bytes()
                .fold(0xcbf2_9ce4_8422_2325u64, |hash, byte| {
                    (hash ^ u64::from(byte)).wrapping_mul(0x0100_0000_01b3)
                });
            format!("{APP_ID}.Store{hash:016x}")
        }
    }
}

fn main() -> glib::ExitCode {
    let argv: Vec<String> = std::env::args().collect();
    let arguments = Arguments::parse(&argv[1..]);
    // the version to standard output, without a display: the release's boot test
    if arguments.version {
        println!("Inbox Classic {VERSION}");
        return glib::ExitCode::SUCCESS;
    }
    if arguments.mcp {
        return relay(&arguments);
    }
    if let Some(out) = arguments.e2e.clone() {
        #[cfg(feature = "e2e")]
        return e2e::run(out);
        #[cfg(not(feature = "e2e"))]
        {
            eprintln!(
                "this build has no UI test (--e2e {}): build it with --features e2e",
                out.display()
            );
            return glib::ExitCode::FAILURE;
        }
    }
    run(arguments, argv)
}

/// `--mcp`: the relay of an agent's MCP server, to the app that has this store open, started in the background when it
/// is not running; no display is opened
fn relay(arguments: &Arguments) -> glib::ExitCode {
    let store = arguments.store.clone().unwrap_or_else(default_store);
    match pe_mcp::relay_for_store(&store, arguments.store.as_deref(), &pe_mcp::launching_program()) {
        Ok(()) => glib::ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("{error}");
            glib::ExitCode::FAILURE
        }
    }
}

/// Runs the app: the first start for a store opens it, another one hands its command line to that one and ends
pub fn run(arguments: Arguments, argv: Vec<String>) -> glib::ExitCode {
    let application = adw::Application::builder()
        .application_id(application_id(arguments.store.as_ref()))
        .flags(gio::ApplicationFlags::HANDLES_COMMAND_LINE)
        .resource_base_path("/com/inboxclassic/InboxClassic")
        .build();
    application.connect_startup(|_| {
        gio::resources_register_include!("inbox-classic.gresource").expect("the app's resources");
        ui::load_style();
    });
    let first = std::cell::RefCell::new(Some(arguments));
    application.connect_command_line(move |application, command_line| {
        let args: Vec<String> = command_line
            .arguments()
            .iter()
            .skip(1)
            .map(|arg| arg.to_string_lossy().into_owned())
            .collect();
        match first.borrow_mut().take() {
            // the first start: its own arguments, as read before the display opened
            Some(arguments) => app::start(application, arguments),
            // another start for this store: what it was for, here; one in the background (for an agent) finds it running
            None => {
                let arguments = Arguments::parse(&args);
                if !arguments.background {
                    app::hand_over(arguments);
                }
            }
        }
        glib::ExitCode::SUCCESS
    });
    application.run_with_args(&argv)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn options_and_a_mailto_link() {
        let parsed = Arguments::parse(&[
            "--store",
            "/tmp/s.db",
            "--memory-passwords",
            "--pin-certificate",
            "c.pem",
        ]);
        assert_eq!(parsed.store, Some(PathBuf::from("/tmp/s.db")));
        assert_eq!(parsed.certificate, Some(PathBuf::from("c.pem")));
        assert!(parsed.memory_passwords && !parsed.version);
        // what follows the link is part of it, however it looks
        let parsed = Arguments::parse(&[
            "--memory-passwords",
            "mailto:ann@example.com?subject=Hi",
            "--store",
            "x",
        ]);
        assert_eq!(
            parsed.mailto.as_deref(),
            Some("mailto:ann@example.com?subject=Hi --store x")
        );
        assert_eq!(parsed.store, None);
        assert_eq!(
            Arguments::parse(&["MAILTO:bob@example.com"]).mailto.as_deref(),
            Some("MAILTO:bob@example.com")
        );
        assert!(Arguments::parse(&["--version"]).version);
        assert_eq!(
            Arguments::parse(&["/tmp/a.eml"]).files,
            vec![PathBuf::from("/tmp/a.eml")]
        );
        assert_eq!(
            Arguments::parse(&["file:///tmp/b%20c.eml"]).files,
            vec![PathBuf::from("/tmp/b c.eml")]
        );
    }

    #[test]
    fn each_store_has_a_name_of_its_own() {
        assert_eq!(application_id(None), APP_ID);
        let one = application_id(Some(&PathBuf::from("/tmp/one.db")));
        let two = application_id(Some(&PathBuf::from("/tmp/two.db")));
        assert!(one.starts_with("com.inboxclassic.InboxClassic.Store") && one != two);
        assert_eq!(one, application_id(Some(&PathBuf::from("/tmp/one.db"))));
        assert!(gio::Application::id_is_valid(&one));
    }
}
