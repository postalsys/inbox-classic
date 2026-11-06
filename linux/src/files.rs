//! Messages as `.eml` files: dragged out of the list onto a file manager (or another program that takes files), saved
//! several at a time, forwarded as attachments; and `.eml` files dropped onto a folder. The core makes the files and
//! downloads what is not here yet; that blocks, so it runs on a thread of its own and the window waits for it.

use std::cell::RefCell;
use std::path::{Path, PathBuf};
use std::pin::Pin;
use std::time::Duration;

use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gdk, gio, glib};
use pe_core::MessageRef;

use crate::app::shell;

/// How long a drag, a Save As or a forward waits for the messages not downloaded yet
pub const WAIT: Duration = Duration::from_secs(120);

/// The messages of a drag inside the app (onto a folder of the tree): a type of its own, so no other program is
/// offered them as text
#[derive(Clone, Debug, PartialEq, Eq, glib::Boxed)]
#[boxed_type(name = "InboxClassicMessages")]
pub struct DraggedMessages(pub Vec<MessageRef>);

/// Where dragged messages are written for the program they are dropped on to copy: under $XDG_RUNTIME_DIR, the
/// user's own and gone at logout, else the cache
pub fn drag_dir() -> PathBuf {
    glib::user_runtime_dir().join("inbox-classic").join("drag")
}

/// Empties [`drag_dir`]: at start (what a crash left) and at the end
pub fn clear_drag_dir() {
    let _ = std::fs::remove_dir_all(drag_dir());
}

/// A new folder of [`drag_dir`] for one drag, so two drags of messages with one subject do not meet
fn new_drag_dir() -> std::io::Result<PathBuf> {
    let nanos = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_or(0, |d| d.as_nanos());
    let dir = drag_dir().join(nanos.to_string());
    std::fs::create_dir_all(&dir)?;
    Ok(dir)
}

/// Runs `work` with the core on a thread of its own, the status bar saying while messages of `refs` are downloaded
/// for it (and "Done" once they are)
pub async fn with_downloads<T: Send + 'static>(
    refs: &[MessageRef],
    work: impl FnOnce(&pe_core::Core) -> Result<T, String> + Send + 'static,
) -> Result<T, String> {
    let core = shell().core.clone();
    let downloading = !core.all_downloaded(refs).unwrap_or(true);
    if downloading {
        shell().main().set_status(&pe_core::downloading_text(refs.len() as u64));
    }
    let done = gio::spawn_blocking(move || work(&core))
        .await
        .unwrap_or_else(|_| Err("the messages could not be had".into()));
    if downloading {
        shell().main().set_status("Done");
    }
    done
}

/// Saves messages into `dir` (never over a file there): the files written, or why not
pub async fn save(refs: Vec<MessageRef>, dir: PathBuf) -> Result<Vec<PathBuf>, String> {
    let wanted = refs.clone();
    with_downloads(&wanted, move |core| {
        core.save_messages(&refs, &dir, WAIT).map_err(|e| e.to_string())
    })
    .await
}

/// The files of `refs` for a drag: written once, into a folder of their own, when a program asks for them
async fn drag_files(provider: &MessageFiles) -> Result<Vec<PathBuf>, String> {
    if let Some(written) = provider.imp().written.borrow().clone() {
        return Ok(written);
    }
    let refs = provider.imp().refs.borrow().clone();
    let dir = new_drag_dir().map_err(|e| e.to_string())?;
    let written = save(refs, dir).await?;
    *provider.imp().written.borrow_mut() = Some(written.clone());
    Ok(written)
}

mod imp {
    use super::*;

    #[derive(Default)]
    pub struct MessageFiles {
        pub refs: RefCell<Vec<MessageRef>>,
        /// The files once written: a program that asks again gets the same ones
        pub written: RefCell<Option<Vec<PathBuf>>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for MessageFiles {
        const NAME: &'static str = "InboxClassicMessageFiles";
        type Type = super::MessageFiles;
        type ParentType = gdk::ContentProvider;
    }

    impl ObjectImpl for MessageFiles {}

    impl ContentProviderImpl for MessageFiles {
        fn formats(&self) -> gdk::ContentFormats {
            gdk::ContentFormats::new(&["text/uri-list"])
        }

        fn write_mime_type_future(
            &self,
            mime_type: &str,
            stream: &gio::OutputStream,
            io_priority: glib::Priority,
        ) -> Pin<Box<dyn std::future::Future<Output = Result<(), glib::Error>> + 'static>> {
            let provider = self.obj().clone();
            let stream = stream.clone();
            let wanted = mime_type == "text/uri-list";
            Box::pin(async move {
                if !wanted {
                    return Err(glib::Error::new(
                        gio::IOErrorEnum::NotSupported,
                        "only files are offered",
                    ));
                }
                let paths = drag_files(&provider)
                    .await
                    .map_err(|why| glib::Error::new(gio::IOErrorEnum::Failed, &why))?;
                stream
                    .write_all_future(uri_list(&paths).into_bytes(), io_priority)
                    .await
                    .map_err(|(_, error)| error)?;
                Ok(())
            })
        }
    }
}

glib::wrapper! {
    /// The messages of a drag as files, for programs outside the app: written only when one asks for them
    pub struct MessageFiles(ObjectSubclass<imp::MessageFiles>) @extends gdk::ContentProvider;
}

impl MessageFiles {
    pub fn new(refs: Vec<MessageRef>) -> MessageFiles {
        let provider: MessageFiles = glib::Object::new();
        *provider.imp().refs.borrow_mut() = refs;
        provider
    }

    /// The files, written when they are not yet: what a file manager gets (the test asks for them so)
    pub async fn files(&self) -> Result<Vec<PathBuf>, String> {
        drag_files(self).await
    }
}

/// `text/uri-list`: a `file://` URI a line, CR LF after each (RFC 2483)
pub fn uri_list(paths: &[PathBuf]) -> String {
    paths
        .iter()
        .map(|path| format!("{}\r\n", gio::File::for_path(path).uri()))
        .collect()
}

/// What a drag of `refs` from the list offers: the messages themselves for the folder tree, files for other programs
pub fn drag_content(refs: Vec<MessageRef>) -> gdk::ContentProvider {
    let inside = gdk::ContentProvider::for_value(&DraggedMessages(refs.clone()).to_value());
    gdk::ContentProvider::new_union(&[inside, MessageFiles::new(refs).upcast()])
}

/// Whether dropped files can be put in a folder as messages: every one an `.eml`
pub fn all_messages(files: &[PathBuf]) -> bool {
    !files.is_empty()
        && files
            .iter()
            .all(|f| f.extension().is_some_and(|e| e.eq_ignore_ascii_case("eml")))
}

/// The local paths of a dropped file list
pub fn paths_of(list: &gdk::FileList) -> Vec<PathBuf> {
    list.files().iter().filter_map(|f| f.path()).collect()
}

/// The name a folder of the file system goes by in the status bar: its own name, the whole path for the root
pub fn place_name(dir: &Path) -> String {
    dir.file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_else(|| dir.display().to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_eml_files_are_messages() {
        assert!(all_messages(&[
            PathBuf::from("/tmp/a.eml"),
            PathBuf::from("/tmp/B.EML")
        ]));
        assert!(!all_messages(&[
            PathBuf::from("/tmp/a.eml"),
            PathBuf::from("/tmp/b.txt")
        ]));
        assert!(!all_messages(&[]));
    }

    #[test]
    fn uri_lists_end_lines_with_crlf() {
        let list = uri_list(&[PathBuf::from("/tmp/a b.eml")]);
        assert_eq!(list, "file:///tmp/a%20b.eml\r\n");
    }

    #[test]
    fn places_by_their_names() {
        assert_eq!(place_name(Path::new("/home/ann/Desktop")), "Desktop");
    }
}
