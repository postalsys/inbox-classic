//! A large message's text before the rest (docs/open-speed-plan.md, phase 5): its structure, its header, the text
//! and HTML parts and the pictures shown inside them, fetched by part, and put together as a message the parser reads
//! as it reads the whole one. The parts not fetched (the attachments) are in it with their own MIME headers and no
//! content, so the view names them as it would; their sizes come from the structure. What this makes is shown, never
//! stored: the whole source follows.

use pe_imap::client::FetchQuery;
use pe_imap::{BodyStructure, Client, Messages};
use pe_store::{FolderId, Store};

use crate::{Result, select_folder};

/// The most the parts shown first may take together
pub const SHOWN_FIRST_LIMIT: u64 = 2 * 1024 * 1024;

/// A large message's text, before the rest of it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TextFirst {
    /// A message with the header, the text and the pictures shown inside it, and the other parts without content
    pub source: Vec<u8>,
    /// About how large each part without content is, decoded, in the order of the message
    pub sizes: Vec<u64>,
}

/// Whether a part is shown in the message's text: a text or HTML part, or a picture it shows by its Content-ID, and not
/// one the sender attached
fn shown(part: &BodyStructure) -> bool {
    let attached = part
        .disposition
        .as_deref()
        .is_some_and(|d| d.eq_ignore_ascii_case("attachment"));
    let text = matches!(part.content_type.as_str(), "text/plain" | "text/html");
    let picture = part.content_type.starts_with("image/") && part.id.is_some();
    !attached && (text || picture)
}

/// The leaves of the structure in the message's order: an attached message counts as one
fn leaves<'a>(part: &'a BodyStructure, found: &mut Vec<&'a BodyStructure>) {
    if part.content_type.starts_with("multipart/") {
        for child in &part.children {
            leaves(child, found);
        }
    } else {
        found.push(part);
    }
}

/// The size of a part as it is decoded, from its size on the server
fn decoded_size(part: &BodyStructure) -> u64 {
    let size = part.size.unwrap_or(0);
    match part.encoding.as_deref() {
        // 57 bytes to a line of 76 characters and its line break
        Some("base64") => size * 57 / 78,
        _ => size,
    }
}

/// The text of a large message first: None when its structure has nothing to show first that is small enough (the
/// whole message comes as it is)
pub async fn fetch_text_first(
    client: &mut Client,
    store: &mut Store,
    folder: FolderId,
    uid: u64,
) -> Result<Option<TextFirst>> {
    select_folder(client, store, folder).await?;
    let query = FetchQuery {
        body_structure: true,
        headers: Some(Vec::new()),
        ..Default::default()
    };
    let Some(first) = client
        .fetch(&Messages::uid(uid), &query)
        .await?
        .into_iter()
        .find(|m| m.uid == Some(uid))
    else {
        return Ok(None);
    };
    let (Some(structure), Some(header)) = (first.body_structure, first.headers) else {
        return Ok(None);
    };
    let mut all = Vec::new();
    leaves(&structure, &mut all);
    let wanted: Vec<&BodyStructure> = all.iter().copied().filter(|part| shown(part)).collect();
    let total: u64 = wanted.iter().map(|part| part.size.unwrap_or(0)).sum();
    if wanted.is_empty() || total > SHOWN_FIRST_LIMIT {
        return Ok(None);
    }
    // every part's own header, and the content of those shown
    let multipart = structure.content_type.starts_with("multipart/");
    let mut sections = Vec::new();
    collect_sections(&structure, true, &mut sections);
    sections.extend(wanted.iter().map(|part| part.section()));
    let query = FetchQuery {
        parts: sections,
        ..Default::default()
    };
    let Some(parts) = client
        .fetch(&Messages::uid(uid), &query)
        .await?
        .into_iter()
        .find(|m| m.uid == Some(uid))
    else {
        return Ok(None);
    };
    let mut source = header;
    if multipart {
        put_children(&structure, &parts.parts, &mut source);
    } else if let Some(content) = parts.parts.get(&structure.section()) {
        source.extend_from_slice(content);
    }
    let sizes = all
        .iter()
        .filter(|part| !shown(part))
        .map(|part| decoded_size(part))
        .collect();
    Ok(Some(TextFirst { source, sizes }))
}

/// The sections of the MIME headers of every part under the root
fn collect_sections(part: &BodyStructure, root: bool, found: &mut Vec<String>) {
    if !root {
        found.push(format!("{}.MIME", part.section()));
    }
    if part.content_type.starts_with("multipart/") {
        for child in &part.children {
            collect_sections(child, false, found);
        }
    }
}

/// A multipart's children between its boundaries, each with its own header, and its content when it was fetched
fn put_children(part: &BodyStructure, fetched: &std::collections::BTreeMap<String, Vec<u8>>, out: &mut Vec<u8>) {
    let boundary = part.parameters.get("boundary").cloned().unwrap_or_default();
    for child in &part.children {
        out.extend_from_slice(format!("\r\n--{boundary}\r\n").as_bytes());
        let section = child.section();
        if let Some(header) = fetched.get(&format!("{section}.MIME")) {
            out.extend_from_slice(header);
        }
        if child.content_type.starts_with("multipart/") {
            put_children(child, fetched, out);
        } else if let Some(content) = fetched.get(&section) {
            out.extend_from_slice(content);
        }
    }
    out.extend_from_slice(format!("\r\n--{boundary}--\r\n").as_bytes());
}

#[cfg(test)]
mod tests {
    use super::*;

    fn part(content_type: &str, section: &str) -> BodyStructure {
        BodyStructure {
            part: Some(section.into()),
            content_type: content_type.into(),
            size: Some(780),
            ..Default::default()
        }
    }

    #[test]
    fn the_text_and_its_pictures_are_shown_first() {
        let mut picture = part("image/png", "2");
        picture.id = Some("<logo>".into());
        let mut attached = part("application/pdf", "3");
        attached.disposition = Some("attachment".into());
        attached.encoding = Some("base64".into());
        assert!(shown(&part("text/html", "1")));
        assert!(shown(&picture));
        assert!(!shown(&attached));
        // a picture without a Content-ID is not in the text
        assert!(!shown(&part("image/png", "4")));
        assert_eq!(decoded_size(&attached), 570);
    }
}
