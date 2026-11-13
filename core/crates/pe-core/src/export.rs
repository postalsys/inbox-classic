//! Messages as `.eml` files: dragged out of the list onto the desktop or a file window, saved several at a time, or
//! attached to one new message to forward them. Their sources come from the store, and those not downloaded yet from
//! their servers, on a connection of their account's own for the occasion (the reader keeps only the message the
//! user opened last).

use std::collections::{BTreeMap, HashMap};
use std::path::{Path, PathBuf};
use std::time::Duration;

use pe_store::{AccountId, MessageRef};

use pe_i18n::{Text, tr, tr_args};

use crate::worker::{Role, Worker};
use crate::{Core, Draft, Error, Result};

/// A message as a file: its name, and its source or why it could not be had
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Exported {
    pub name: String,
    pub source: std::result::Result<Vec<u8>, String>,
}

/// The file name of a message with `subject`: the subject made safe, `.eml` after it, `message.eml` without one
pub(crate) fn eml_name(subject: &str) -> String {
    // the subject made safe first, the extension after: a subject of only `???` is not left without one
    let stem = pe_mime::parser::safe_filename(Some(&subject.replace(['/', '\\'], "-")), "message/rfc822");
    let mut stem = if stem.starts_with("attachment.") {
        "message".to_string()
    } else {
        stem
    };
    // a file name is at most 255 UTF-16 units on Windows and the Mac, 255 bytes on Linux: room left for ".eml" and
    // " (99)", so the extension is never cut off where the name is made to fit
    while stem.encode_utf16().count() > MAX_STEM || stem.len() > MAX_STEM {
        stem.pop();
    }
    format!("{}.eml", stem.trim_end_matches(['.', ' ']))
}

/// The longest stem of a file name, in UTF-16 units and in bytes
const MAX_STEM: usize = 240;

/// `names` made different from each other (case aside, as the file systems of Windows and the Mac compare them):
/// `Lunch.eml`, `Lunch (2).eml`
fn unique(names: Vec<String>) -> Vec<String> {
    let mut taken: HashMap<String, u32> = HashMap::new();
    let mut out = Vec::with_capacity(names.len());
    for name in names {
        let (stem, extension) = name.rsplit_once('.').map_or((name.as_str(), ""), |(s, e)| (s, e));
        let mut candidate = name.clone();
        let mut n = 1;
        while taken.contains_key(&candidate.to_lowercase()) {
            n += 1;
            candidate = format!("{stem} ({n}).{extension}");
        }
        taken.insert(candidate.to_lowercase(), n);
        out.push(candidate);
    }
    out
}

impl Core {
    /// The file names `refs` get as `.eml` files, in their order and different from each other, without their sources
    /// (a drag names its files before they are written)
    pub fn export_names(&self, refs: &[MessageRef]) -> Result<Vec<String>> {
        let store = self.store();
        let mut names = Vec::with_capacity(refs.len());
        for r in refs {
            let subject = store
                .message(r.folder, r.uid)?
                .map(|m| m.info.subject)
                .unwrap_or_default();
            names.push(eml_name(&subject));
        }
        Ok(unique(names))
    }

    /// Whether every one of `refs` is downloaded, so their files can be written at once
    pub fn all_downloaded(&self, refs: &[MessageRef]) -> Result<bool> {
        let store = self.store();
        for r in refs {
            if !store.has_source(r.folder, r.uid)? {
                return Ok(false);
            }
        }
        Ok(true)
    }

    /// What the status bar says while the messages of `refs` that are not here yet come: "Downloading 2 messages...";
    /// None when all are here
    pub fn downloading_text(&self, refs: &[MessageRef]) -> Result<Option<String>> {
        let store = self.store();
        let mut missing = 0;
        for r in refs {
            missing += u64::from(!store.has_source(r.folder, r.uid)?);
        }
        Ok((missing > 0).then(|| crate::text::downloading_text(missing)))
    }

    /// The messages `refs` as files, downloading those that are not here yet (kept for reading too), waiting at most
    /// `timeout` for them. Blocks: call it from a thread of its own, never from a window's or the core's.
    pub fn export_messages(&self, refs: &[MessageRef], timeout: Duration) -> Result<Vec<Exported>> {
        let names = self.export_names(refs)?;
        let mut missing: BTreeMap<AccountId, Vec<MessageRef>> = BTreeMap::new();
        {
            let store = self.store();
            for r in refs {
                if !store.has_source(r.folder, r.uid)? {
                    let account = store.folder(r.folder)?.account_id;
                    missing.entry(account).or_default().push(*r);
                }
            }
        }
        let mut problems: HashMap<MessageRef, String> = HashMap::new();
        if !missing.is_empty() {
            let (sender, receiver) = std::sync::mpsc::channel();
            let accounts = missing.len();
            for (account, wanted) in missing {
                let mut worker = Worker::new(account, Role::Reader, self.worker_context());
                let sender = sender.clone();
                self.runtime()?.spawn(async move {
                    let _ = sender.send(worker.fetch_sources(&wanted).await);
                });
            }
            let deadline = std::time::Instant::now() + timeout;
            for _ in 0..accounts {
                let left = deadline.saturating_duration_since(std::time::Instant::now());
                match receiver.recv_timeout(left) {
                    Ok(failed) => problems.extend(failed),
                    Err(_) => break,
                }
            }
        }
        let store = self.store();
        let mut exported = Vec::with_capacity(refs.len());
        for (r, name) in refs.iter().zip(names) {
            let source = match store.source(r.folder, r.uid)? {
                Some(source) => Ok(source),
                None => Err(problems.remove(r).unwrap_or_else(|| tr(Text::ExportNotInTime))),
            };
            exported.push(Exported { name, source });
        }
        Ok(exported)
    }

    /// Writes the messages `refs` into `dir` as `.eml` files, never over a file there (`Lunch (2).eml` then), marked
    /// as from the internet where the system has such a mark. Returns the files written; refused with the reasons of
    /// those that could not be. Blocks as [`Core::export_messages`] does.
    pub fn save_messages(&self, refs: &[MessageRef], dir: &Path, timeout: Duration) -> Result<Vec<PathBuf>> {
        let exported = self.export_messages(refs, timeout)?;
        let mut written = Vec::new();
        let mut problems = Vec::new();
        for file in exported {
            match file.source {
                Ok(source) => match crate::view::write_new(dir, &file.name, &source) {
                    Ok(path) => written.push(path),
                    Err(error) => problems.push(format!("{}: {error}", file.name)),
                },
                Err(problem) => problems.push(format!("{}: {problem}", file.name)),
            }
        }
        if !problems.is_empty() {
            let total = crate::text::messages(refs.len() as u64);
            let listed = problems.join("; ");
            return Err(Error::Unavailable(tr_args(
                Text::ExportNotSaved,
                &[
                    ("failed", problems.len().into()),
                    ("messages", (&total).into()),
                    ("problems", (&listed).into()),
                ],
            )));
        }
        Ok(written)
    }

    /// The messages `refs` written as `.eml` files into a new folder of the user's own (as drafts' attachments are),
    /// for a drag onto the desktop or a file window that wants files that are there; their paths. Blocks as
    /// [`Core::export_messages`] does.
    pub fn drag_files(&self, refs: &[MessageRef], timeout: Duration) -> Result<Vec<PathBuf>> {
        let dir = crate::private_dir("drag").map_err(|e| Error::Unavailable(e.to_string()))?;
        self.save_messages(refs, &dir, timeout)
    }

    /// A new message forwarding `refs` as attached `.eml` files (the window writes it from the account of the first):
    /// its subject that one's with "Fw: ". Downloads what is not here yet, as [`Core::export_messages`] does, and blocks as it does.
    pub fn forward_as_attachments(&self, refs: &[MessageRef], timeout: Duration) -> Result<Draft> {
        let first = refs.first().ok_or(Error::NotFound)?;
        let subject = self
            .store()
            .message(first.folder, first.uid)?
            .map(|m| m.info.subject)
            .unwrap_or_default();
        let exported = self.export_messages(refs, timeout)?;
        let mut files = Vec::with_capacity(exported.len());
        for file in exported {
            let source = file
                .source
                .map_err(|problem| Error::Unavailable(format!("{}: {problem}", file.name)))?;
            files.push((file.name, source));
        }
        let attachments =
            crate::write_out(&format!("forward-{}-{}", first.folder, first.uid), files).map_err(|error| {
                Error::Unavailable(tr_args(
                    Text::ExportNotAttached,
                    &[("error", (&error.to_string()).into())],
                ))
            })?;
        Ok(Draft {
            subject: crate::compose::prefixed("Fw: ", &subject),
            attachments,
            ..Draft::default()
        })
    }
}

/// Writes `content` into `dir` as `name`, or as `name (2).eml` and so on when that is taken, never over a file there,
/// marked as from the internet where the system has such a mark (Windows; the Mac app sets its own); its path. For a
/// file a drag promised into a folder the system chose.
pub fn write_file(dir: &Path, name: &str, content: &[u8]) -> Result<PathBuf> {
    let name = pe_mime::parser::safe_filename(Some(name), "message/rfc822");
    crate::view::write_new(dir, &name, content).map_err(|e| Error::Unavailable(format!("{name}: {e}")))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn names_from_subjects() {
        assert_eq!(eml_name("Lunch on Friday"), "Lunch on Friday.eml");
        assert_eq!(eml_name("a/b\\c"), "a-b-c.eml");
        assert_eq!(eml_name(""), "message.eml");
        assert_eq!(eml_name("???"), "message.eml");
    }

    #[test]
    fn long_names_keep_their_extension() {
        let emoji = "\u{1F600}".repeat(150);
        let name = eml_name(&format!("{emoji}x.hta"));
        assert!(name.ends_with(".eml"), "{name}");
        assert!(name.encode_utf16().count() <= 250 && name.len() <= 250);
        let latin = eml_name(&"a".repeat(400));
        assert!(latin.len() <= MAX_STEM + 4 && latin.ends_with(".eml"));
    }

    #[test]
    fn names_kept_apart() {
        let names = unique(vec![
            "Lunch.eml".into(),
            "lunch.eml".into(),
            "Other.eml".into(),
            "Lunch.eml".into(),
        ]);
        assert_eq!(names, ["Lunch.eml", "lunch (2).eml", "Other.eml", "Lunch (3).eml"]);
    }
}
