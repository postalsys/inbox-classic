//! Attachments opened from a message (the strip under its header): what kind of file each is, for its icon, and
//! whether it may be opened at all. A file that can run code (a program, a script, an installer, a shortcut, a disk
//! image, an Office file with macros) is never opened from a message; it can be saved. Any other is written into a
//! private folder of the user's (cleaned at start and after a day), marked as from the internet, and the app opens it
//! with the system's program for it.

use std::path::{Path, PathBuf};

use pe_i18n::{Text, tr};
use pe_store::FolderId;

use crate::{Core, Error, Result};

/// What kind of file an attachment is: its icon, and whether it may be opened
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FileKind {
    Image,
    Pdf,
    Document,
    Spreadsheet,
    Presentation,
    Archive,
    Audio,
    Video,
    Calendar,
    Contact,
    Key,
    Text,
    Mail,
    /// It can run code: never opened from a message
    Program,
    Other,
}

impl FileKind {
    /// The word of its icon
    pub fn word(self) -> &'static str {
        match self {
            FileKind::Image => "image",
            FileKind::Pdf => "pdf",
            FileKind::Document => "document",
            FileKind::Spreadsheet => "spreadsheet",
            FileKind::Presentation => "presentation",
            FileKind::Archive => "archive",
            FileKind::Audio => "audio",
            FileKind::Video => "video",
            FileKind::Calendar => "calendar",
            FileKind::Contact => "contact",
            FileKind::Key => "key",
            FileKind::Text => "text",
            FileKind::Mail => "mail",
            FileKind::Program => "program",
            FileKind::Other => "other",
        }
    }

    pub fn can_open(self) -> bool {
        self != FileKind::Program
    }
}

/// The extensions of files that can run code, on any of the three systems: Windows' programs, scripts, installers,
/// shortcuts and the files the shell runs; the Mac's apps, installers, scripts and disk images; Linux's; Java's; Office
/// documents with macros. Lowercase, without the dot.
const PROGRAMS: &[&str] = &[
    // Windows: programs and installers
    "exe",
    "com",
    "scr",
    "pif",
    "cpl",
    "msi",
    "msp",
    "mst",
    "msc",
    "msix",
    "msixbundle",
    "appx",
    "appxbundle",
    "appinstaller",
    "application",
    "gadget",
    "dll",
    "ocx",
    "sys",
    "drv",
    // Windows: scripts and what the shell runs
    "bat",
    "cmd",
    "ps1",
    "ps1xml",
    "ps2",
    "ps2xml",
    "psc1",
    "psc2",
    "psd1",
    "psm1",
    "vb",
    "vbe",
    "vbs",
    "js",
    "jse",
    "ws",
    "wsc",
    "wsf",
    "wsh",
    "hta",
    "sct",
    "reg",
    "inf",
    "scf",
    "lnk",
    "url",
    "website",
    "library-ms",
    "searchconnector-ms",
    "settingcontent-ms",
    "xbap",
    "chm",
    "hlp",
    "mde",
    "mdb",
    "accde",
    "ade",
    "adp",
    "mda",
    "mdz",
    "jnlp",
    "jar",
    "class",
    "py",
    "pyw",
    "pyc",
    "pl",
    "rb",
    "php",
    "cab",
    "diagcab",
    "xll",
    "xnk",
    "iqy",
    "slk",
    "appref-ms",
    "mof",
    "osd",
    "vsto",
    "vhd",
    "vhdx",
    // the Mac
    "app",
    "pkg",
    "mpkg",
    "dmg",
    "command",
    "tool",
    "terminal",
    "workflow",
    "action",
    "scpt",
    "scptd",
    "applescript",
    "osax",
    "kext",
    "prefpane",
    "webloc",
    "inetloc",
    "fileloc",
    "dylib",
    "bundle",
    "plugin",
    // Linux and Unix
    "sh",
    "bash",
    "zsh",
    "csh",
    "ksh",
    "fish",
    "run",
    "bin",
    "out",
    "elf",
    "so",
    "desktop",
    "appimage",
    "deb",
    "rpm",
    "snap",
    "flatpak",
    "flatpakref",
    // disk images that open as drives with programs on them
    "iso",
    "img",
    "udf",
    // Office documents and templates with macros
    "docm",
    "dotm",
    "xlsm",
    "xltm",
    "xlam",
    "xlsb",
    "pptm",
    "potm",
    "ppam",
    "ppsm",
    "sldm",
];

/// The extension of a file name, lowercase: the last one, so "invoice.pdf.exe" is an exe
fn extension(name: &str) -> String {
    let name = name.trim_end_matches(['.', ' ']);
    match name.rfind('.') {
        Some(dot) if dot + 1 < name.len() => name[dot + 1..].to_ascii_lowercase(),
        _ => String::new(),
    }
}

/// What kind of file `name` of type `mime_type` is. Its name decides first (the system opens a file by its name);
/// the type only where the name says nothing
pub fn file_kind(name: &str, mime_type: &str) -> FileKind {
    let extension = extension(name);
    if PROGRAMS.contains(&extension.as_str()) {
        return FileKind::Program;
    }
    let by_name = match extension.as_str() {
        "jpg" | "jpeg" | "png" | "gif" | "webp" | "heic" | "heif" | "bmp" | "tif" | "tiff" | "avif" | "ico" => {
            Some(FileKind::Image)
        }
        "pdf" => Some(FileKind::Pdf),
        "doc" | "docx" | "dotx" | "odt" | "rtf" | "pages" => Some(FileKind::Document),
        "xls" | "xlsx" | "xltx" | "ods" | "csv" | "numbers" => Some(FileKind::Spreadsheet),
        "ppt" | "pptx" | "potx" | "ppsx" | "odp" | "key" => Some(FileKind::Presentation),
        "zip" | "7z" | "rar" | "gz" | "tgz" | "bz2" | "xz" | "tar" | "zst" => Some(FileKind::Archive),
        "mp3" | "m4a" | "wav" | "aac" | "flac" | "ogg" | "opus" => Some(FileKind::Audio),
        "mp4" | "mov" | "m4v" | "avi" | "mkv" | "webm" => Some(FileKind::Video),
        "ics" | "ical" | "ifb" => Some(FileKind::Calendar),
        "vcf" | "vcard" => Some(FileKind::Contact),
        "asc" | "gpg" | "pgp" | "sig" | "pem" | "cer" | "crt" => Some(FileKind::Key),
        "txt" | "md" | "log" | "json" | "xml" => Some(FileKind::Text),
        "eml" | "msg" | "mbox" => Some(FileKind::Mail),
        // pages: opened in a browser they run their scripts (a way in that mail is known for), and "svg" can carry
        // script too
        "html" | "htm" | "xhtml" | "shtml" | "mht" | "mhtml" | "svg" => Some(FileKind::Program),
        _ => None,
    };
    if let Some(kind) = by_name {
        return kind;
    }
    let mime = mime_type.to_ascii_lowercase();
    let (top, sub) = mime.split_once('/').unwrap_or((mime.as_str(), ""));
    match (top, sub) {
        // with no name to go by, a program's type is enough to refuse it
        (_, sub)
            if sub.contains("x-msdownload")
                || sub.contains("x-executable")
                || sub.contains("x-sh")
                || sub.contains("javascript")
                || sub.contains("x-msi")
                || sub.contains("java-archive") =>
        {
            FileKind::Program
        }
        ("image", _) => FileKind::Image,
        ("audio", _) => FileKind::Audio,
        ("video", _) => FileKind::Video,
        ("text", "calendar") => FileKind::Calendar,
        ("text", "vcard") | ("text", "x-vcard") => FileKind::Contact,
        ("text", _) => FileKind::Text,
        ("message", _) => FileKind::Mail,
        ("application", "pdf") => FileKind::Pdf,
        ("application", "pgp-keys") | ("application", "pgp-signature") => FileKind::Key,
        _ => FileKind::Other,
    }
}

/// What opening an attachment gave: the file to open, and the note to show first (once: an encrypted message's file
/// is stored decrypted while it is open)
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Opened {
    pub path: PathBuf,
    pub note: Option<String>,
}

impl Core {
    /// Writes attachment `index` of a message where it can be opened, for the app to open with the system's program:
    /// refused for a file that can run code (it can be saved), None when the message or the attachment is not here
    pub fn open_attachment(&self, folder: FolderId, uid: u64, index: usize) -> Result<Option<Opened>> {
        let Some(source) = self.store().source(folder, uid)? else {
            return Ok(None);
        };
        self.open_from(source, index)
    }

    /// [`Core::open_attachment`] of a message file a window shows (`file_view`)
    pub fn file_open_attachment(&self, path: &Path, index: usize) -> Result<Option<Opened>> {
        let (source, _) = crate::read_message_file(path)?;
        self.open_from(source, index)
    }

    fn open_from(&self, source: Vec<u8>, index: usize) -> Result<Option<Opened>> {
        let encrypted = crate::protect::has_encrypted(&source);
        let shown = self.shown(&self.store(), source);
        let Some((name, mime_type, content)) = crate::view::attachment_with_type(&shown, index) else {
            return Ok(None);
        };
        if !file_kind(&name, &mime_type).can_open() {
            return Err(Error::Unavailable(tr(Text::AttachmentRunsPrograms)));
        }
        let dir = crate::private_dir("open").map_err(|error| Error::Unavailable(error.to_string()))?;
        let path =
            crate::view::write_new(&dir, &name, &content).map_err(|error| Error::Unavailable(error.to_string()))?;
        let note = if encrypted && !self.store().decrypted_open_noted()? {
            self.store().set_decrypted_open_noted()?;
            Some(tr(Text::AttachmentDecryptedNote))
        } else {
            None
        };
        Ok(Some(Opened { path, note }))
    }

    /// A folder of the user's own for files the system opens (a calendar invitation): private, and cleaned at start
    /// once a day old
    pub fn private_folder(&self, name: &str) -> Result<PathBuf> {
        crate::private_dir(name).map_err(|error| Error::Unavailable(error.to_string()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_file_is_known_by_its_last_extension_first() {
        assert_eq!(file_kind("Contract.pdf", "application/octet-stream"), FileKind::Pdf);
        assert_eq!(file_kind("invoice.pdf.exe", "application/pdf"), FileKind::Program);
        assert_eq!(file_kind("photo.JPG", ""), FileKind::Image);
        assert_eq!(file_kind("report.docm", ""), FileKind::Program);
        assert_eq!(file_kind("report.docx", ""), FileKind::Document);
        assert_eq!(file_kind("setup.exe ", ""), FileKind::Program, "trailing space");
        assert_eq!(file_kind("run.sh.", ""), FileKind::Program, "trailing dot");
        assert_eq!(
            file_kind("drawing.svg", "image/svg+xml"),
            FileKind::Program,
            "a page with script"
        );
        assert_eq!(file_kind("noname", "image/png"), FileKind::Image);
        assert_eq!(file_kind("noname", "application/x-msdownload"), FileKind::Program);
        assert_eq!(file_kind("noname", "application/octet-stream"), FileKind::Other);
        assert_eq!(file_kind("invite.ics", "text/calendar"), FileKind::Calendar);
        assert_eq!(file_kind("Mac App.app", ""), FileKind::Program);
        assert_eq!(file_kind("disk.dmg", ""), FileKind::Program);
        assert_eq!(
            file_kind("page.html", "text/html"),
            FileKind::Program,
            "a page runs its scripts"
        );
    }

    #[test]
    fn every_program_extension_is_refused() {
        for extension in PROGRAMS {
            let kind = file_kind(&format!("file.{extension}"), "application/octet-stream");
            assert_eq!(kind, FileKind::Program, "{extension}");
            assert!(!kind.can_open());
        }
    }
}
