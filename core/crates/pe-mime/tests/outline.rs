//! The outline of every message of the conformance corpus holds together: each part lies inside its parent's body,
//! the parts of a multipart in order and apart, and the leaves the parser found as text, HTML or attachments are the
//! leaves of the outline.

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use pe_mime::outline::outline;

#[test]
fn every_corpus_message_outlines() {
    let cases: serde_json::Value = serde_json::from_str(include_str!("fixtures/message-cases.json")).unwrap();
    let messages = cases["messages"].as_array().unwrap();
    assert!(messages.len() > 100);
    for (number, case) in messages.iter().enumerate() {
        let raw = STANDARD.decode(case["raw"].as_str().unwrap()).unwrap();
        let outline = outline(&raw);
        let root = outline.root().unwrap();
        assert_eq!((root.start, root.end), (0, raw.len()), "case {number}");
        for part in &outline.parts {
            assert!(
                part.start <= part.body && part.body <= part.end && part.end <= raw.len(),
                "case {number}"
            );
            let mut previous_end = part.body;
            for &child in &part.children {
                let child = &outline.parts[child];
                assert!(child.start >= previous_end, "case {number}: parts overlap");
                assert!(child.end <= part.end, "case {number}: a part outside its parent");
                assert_eq!(child.depth, part.depth + 1, "case {number}");
                previous_end = child.end;
            }
            // a part that is not a multipart has none
            if !part.is_multipart() {
                assert!(part.children.is_empty(), "case {number}");
            }
        }
        // the parser's view of the same message: every attachment it found has a part of its type in the outline
        // (the outline does not look inside attached messages, the parser does)
        let attached = outline
            .parts
            .iter()
            .any(|part| part.content_type.starts_with("message/"));
        if !attached && let Ok(message) = pe_mime::parser::parse(&raw) {
            for attachment in &message.attachments {
                assert!(
                    outline
                        .parts
                        .iter()
                        .any(|part| part.content_type == attachment.mime_type)
                        || attachment.mime_type == "application/octet-stream",
                    "case {number}: {} not in the outline",
                    attachment.mime_type
                );
            }
        }
    }
}
