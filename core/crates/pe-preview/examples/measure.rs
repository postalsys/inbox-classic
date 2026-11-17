//! Draws the previews of files as the app does and says how long each took: the spike of
//! docs/attachment-preview-plan.md ("As built"). One line a file, tab separated: name, kind, pages, then each preview's
//! milliseconds, size and bytes, or why there is none. With an output folder, the previews are written there.
//!
//!     cargo run --release -p pe-preview --example measure -- [--out DIR] FILE...

use std::sync::Arc;
use std::time::Instant;

use pe_preview::limits::MAX_PAGES;
use pe_preview::{Kind, Picture, pdf, picture};

fn main() {
    let mut args = std::env::args().skip(1).peekable();
    let out = if args.peek().map(String::as_str) == Some("--out") {
        args.next();
        args.next().map(std::path::PathBuf::from)
    } else {
        None
    };
    for path in args {
        let name = std::path::Path::new(&path)
            .file_name()
            .unwrap()
            .to_string_lossy()
            .into_owned();
        let bytes = match std::fs::read(&path) {
            Ok(bytes) => Arc::new(bytes),
            Err(e) => {
                println!("{name}\t-\t-\tunreadable: {e}");
                continue;
            }
        };
        let mut line = vec![name.clone()];
        let write = |index: usize, picture: &Picture| {
            if let Some(out) = &out {
                let ext = if picture.mime == pe_preview::Mime::Png {
                    "png"
                } else {
                    "jpg"
                };
                let _ = std::fs::write(out.join(format!("{name}.{index}.{ext}")), &picture.bytes);
            }
        };
        match pe_preview::kind_of(&bytes) {
            None => line.push("unsupported".into()),
            Some(Kind::Picture) => {
                line.push("picture".into());
                let started = Instant::now();
                let described = picture::describe(&bytes);
                line.push(format!("describe {:.1} ms", ms(started)));
                let started = Instant::now();
                match described.and_then(|_| picture::render(&bytes)) {
                    Ok(picture) => {
                        line.push(format!(
                            "{:.1} ms {}x{} {:?} {} B",
                            ms(started),
                            picture.width,
                            picture.height,
                            picture.mime,
                            picture.bytes.len()
                        ));
                        write(0, &picture);
                    }
                    Err(refusal) => line.push(format!("{refusal:?} after {:.1} ms", ms(started))),
                }
            }
            Some(Kind::Pdf) => {
                line.push("pdf".into());
                let started = Instant::now();
                match pdf::Document::open(bytes.clone()) {
                    Err(refusal) => line.push(format!("{refusal:?} after {:.1} ms", ms(started))),
                    Ok(document) => {
                        let description = document.describe();
                        line.push(format!(
                            "open {:.1} ms, {} pages, title {:?}",
                            ms(started),
                            description.pages,
                            description.title.unwrap_or_default()
                        ));
                        let pages = document.pages();
                        for index in 0..description.pages.min(MAX_PAGES) {
                            let started = Instant::now();
                            match pages.render(index) {
                                Ok(picture) => {
                                    line.push(format!(
                                        "p{} {:.1} ms {}x{} {} B",
                                        index + 1,
                                        ms(started),
                                        picture.width,
                                        picture.height,
                                        picture.bytes.len()
                                    ));
                                    write(index, &picture);
                                }
                                Err(refusal) => {
                                    line.push(format!("p{} {refusal:?} after {:.1} ms", index + 1, ms(started)))
                                }
                            }
                        }
                    }
                }
            }
        }
        println!("{}", line.join("\t"));
    }
}

fn ms(since: Instant) -> f64 {
    since.elapsed().as_secs_f64() * 1000.0
}
