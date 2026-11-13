//! A large message's text before the rest (docs/open-speed-plan.md, phase 5): its structure, its header, the text
//! and HTML parts and the pictures shown inside them, fetched by part, and put together as a message the parser reads
//! as it reads the whole one. The parts not fetched (the attachments) are in it with their own MIME headers and no
//! content, so the view names them as it would; their sizes come from the structure. What this makes is shown, never
//! stored: the whole source follows.

use pe_imap::client::FetchQuery;
use pe_imap::{BodyStructure, Client};
use pe_store::{FolderId, Store};

use crate::{Result, fetch_one, select_folder};

/// The most the parts shown first may take together
const SHOWN_FIRST_LIMIT: u64 = 2 * 1024 * 1024;

/// A large message's text, before the rest of it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TextFirst {
    /// A message with the header, the text and the pictures shown inside it, and its attachments without content
    pub source: Vec<u8>,
    /// About how large each attachment is, decoded, in the order the view lists them (the rules of
    /// [`BodyStructure::attachments`] are those of the parser)
    pub sizes: Vec<u64>,
}

fn is_multipart(part: &BodyStructure) -> bool {
    part.content_type.starts_with("multipart/")
}

/// The leaves of the structure in the message's order: an attached message counts as one
fn leaves<'a>(part: &'a BodyStructure, found: &mut Vec<&'a BodyStructure>) {
    if is_multipart(part) {
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

/// The text of a large message first: every part but its attachments (the text, the pictures shown in it), the
/// attachments with their headers alone. None when that is not small enough (the whole message comes as it is).
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
    let Some(first) = fetch_one(client, uid, &query).await? else {
        return Ok(None);
    };
    let (Some(structure), Some(header)) = (first.body_structure, first.headers) else {
        return Ok(None);
    };
    let attachments = structure.attachments();
    let mut all = Vec::new();
    leaves(&structure, &mut all);
    let wanted: Vec<&BodyStructure> = all
        .into_iter()
        .filter(|part| !attachments.iter().any(|attached| std::ptr::eq(*attached, *part)))
        .collect();
    let total: u64 = wanted.iter().map(|part| part.size.unwrap_or(0)).sum();
    if wanted.is_empty() || total > SHOWN_FIRST_LIMIT {
        return Ok(None);
    }
    // every part's own header, and the content of those shown
    let mut sections = Vec::new();
    if is_multipart(&structure) {
        for child in &structure.children {
            collect_sections(child, &mut sections);
        }
    }
    sections.extend(wanted.iter().map(|part| part.section()));
    let query = FetchQuery {
        parts: sections,
        ..Default::default()
    };
    let Some(mut parts) = fetch_one(client, uid, &query).await? else {
        return Ok(None);
    };
    let mut source = header;
    if is_multipart(&structure) {
        put_children(&structure, &mut parts.parts, &mut source);
    } else if let Some(content) = parts.parts.remove(&structure.section()) {
        source.extend_from_slice(&content);
    }
    let sizes = attachments.iter().map(|part| decoded_size(part)).collect();
    Ok(Some(TextFirst { source, sizes }))
}

/// The sections of the MIME headers of a part and the parts under it
fn collect_sections(part: &BodyStructure, found: &mut Vec<String>) {
    found.push(format!("{}.MIME", part.section()));
    if is_multipart(part) {
        for child in &part.children {
            collect_sections(child, found);
        }
    }
}

/// A multipart's children between its boundaries, each with its own header, and its content when it was fetched
fn put_children(part: &BodyStructure, fetched: &mut std::collections::BTreeMap<String, Vec<u8>>, out: &mut Vec<u8>) {
    let boundary = part.parameters.get("boundary").cloned().unwrap_or_default();
    for child in &part.children {
        out.extend_from_slice(format!("\r\n--{boundary}\r\n").as_bytes());
        let section = child.section();
        if let Some(header) = fetched.remove(&format!("{section}.MIME")) {
            out.extend_from_slice(&header);
        }
        if is_multipart(child) {
            put_children(child, fetched, out);
        } else if let Some(content) = fetched.remove(&section) {
            out.extend_from_slice(&content);
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
    fn a_base64_attachment_is_about_three_quarters_of_its_size() {
        let mut attached = part("application/pdf", "3");
        attached.encoding = Some("base64".into());
        assert_eq!(decoded_size(&attached), 570);
        assert_eq!(decoded_size(&part("text/plain", "1")), 780);
    }
}
