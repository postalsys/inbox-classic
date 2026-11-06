//! Messages as `.eml` files: dragged out of the list onto a file manager (or another program that takes files), saved
//! several at a time, forwarded as attachments; and `.eml` files dropped onto a folder. The core makes the files and
//! downloads what is not here yet; that blocks, so it runs on a thread of its own and the window waits for it.

use std::cell::RefCell;
use std::path::PathBuf;
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

/// Runs `work` on `refs` with the core on a thread of its own, the status bar saying while messages of them are
/// downloaded for it (and "Done" once they are)
pub async fn with_downloads<T: Send + 'static>(
    refs: Vec<MessageRef>,
    work: impl FnOnce(&pe_core::Core, &[MessageRef]) -> pe_core::Result<T> + Send + 'static,
) -> Result<T, String> {
    let core = shell().core.clone();
    let downloading = core.downloading_text(&refs).ok().flatten();
    if let Some(text) = &downloading {
        shell().main().set_status(text);
    }
    let done = match gio::spawn_blocking(move || work(&core, &refs)).await {
        Ok(done) => done.map_err(|e| e.to_string()),
        // the core caught it; what it said is its panic's
        Err(panic) => Err(panic
            .downcast_ref::<&str>()
            .map(|s| (*s).to_string())
            .or_else(|| panic.downcast_ref::<String>().cloned())
            .unwrap_or_default()),
    };
    if downloading.is_some() {
        shell().main().set_status("Done");
    }
    done
}

/// Where the files of a drag are while a program waits for them, so a second request gets the same ones
#[derive(Default)]
enum DragFiles {
    #[default]
    NotAsked,
    /// Being written: those who asked meanwhile, told when they are
    Writing(Vec<async_channel::Sender<Result<Vec<PathBuf>, String>>>),
    Written(Result<Vec<PathBuf>, String>),
}

/// The files of a drag: written once, into the core's folder for them, when a program first asks for them; whoever
/// asks while they are written gets the same ones
async fn drag_files(provider: &MessageFiles) -> Result<Vec<PathBuf>, String> {
    let waiting = {
        let mut state = provider.imp().files.borrow_mut();
        match &mut *state {
            DragFiles::Written(written) => return written.clone(),
            DragFiles::Writing(waiters) => {
                let (send, receive) = async_channel::bounded(1);
                waiters.push(send);
                Some(receive)
            }
            DragFiles::NotAsked => {
                *state = DragFiles::Writing(Vec::new());
                None
            }
        }
    };
    if let Some(receive) = waiting {
        return receive.recv().await.unwrap_or_else(|e| Err(e.to_string()));
    }
    let refs = provider.imp().refs.borrow().clone();
    let written = with_downloads(refs, |core, refs| core.drag_files(refs, WAIT)).await;
    let state = std::mem::replace(
        &mut *provider.imp().files.borrow_mut(),
        DragFiles::Written(written.clone()),
    );
    if let DragFiles::Writing(waiters) = state {
        for waiter in waiters {
            let _ = waiter.try_send(written.clone());
        }
    }
    written
}

mod imp {
    use super::*;

    #[derive(Default)]
    pub struct MessageFiles {
        pub refs: RefCell<Vec<MessageRef>>,
        pub(super) files: RefCell<DragFiles>,
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

/// Whether dropped files can go into a folder: one of them at least is a message file; the core reports the others
pub fn takes(files: &[PathBuf]) -> bool {
    files.iter().any(|f| pe_core::is_message_file(f))
}

/// The local paths of a dropped file list
pub fn paths_of(list: &gdk::FileList) -> Vec<PathBuf> {
    list.files().iter().filter_map(|f| f.path()).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_drop_with_a_message_file_is_taken() {
        assert!(takes(&[PathBuf::from("/tmp/a.eml"), PathBuf::from("/tmp/b.txt")]));
        assert!(!takes(&[PathBuf::from("/tmp/b.txt")]));
        assert!(!takes(&[]));
    }

    #[test]
    fn uri_lists_end_lines_with_crlf() {
        let list = uri_list(&[PathBuf::from("/tmp/a b.eml")]);
        assert_eq!(list, "file:///tmp/a%20b.eml\r\n");
    }
}
