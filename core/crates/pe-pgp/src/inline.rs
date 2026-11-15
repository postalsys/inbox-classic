//! Armored OpenPGP blocks written into the text of a message ("inline PGP"), as some clients still send.
//!
//! Only found here; whether a block is opened, and how, is the core's decision. Inline signatures are never checked
//! (RFC 9787 section 6.2.3): what they cover can not be bound to what the message shows.

/// What an armored block holds.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Kind {
    /// An OpenPGP message, encrypted or signed: `BEGIN PGP MESSAGE`.
    Message,
    /// Text with a cleartext signature: `BEGIN PGP SIGNED MESSAGE` up to the end of its signature.
    Signed,
    PublicKey,
    PrivateKey,
    Signature,
}

/// One block: its kind and where it is in the text, from the start of its BEGIN line to the end of its END line.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Block {
    pub kind: Kind,
    pub start: usize,
    pub end: usize,
}

/// At most this many blocks are found in one text.
const MAX_BLOCKS: usize = 16;

fn kind_of(line: &str) -> Option<(Kind, &'static str)> {
    let line = line.trim_end();
    Some(match line {
        "-----BEGIN PGP MESSAGE-----" => (Kind::Message, "-----END PGP MESSAGE-----"),
        "-----BEGIN PGP SIGNED MESSAGE-----" => (Kind::Signed, "-----END PGP SIGNATURE-----"),
        "-----BEGIN PGP PUBLIC KEY BLOCK-----" => (Kind::PublicKey, "-----END PGP PUBLIC KEY BLOCK-----"),
        "-----BEGIN PGP PRIVATE KEY BLOCK-----" => (Kind::PrivateKey, "-----END PGP PRIVATE KEY BLOCK-----"),
        "-----BEGIN PGP SIGNATURE-----" => (Kind::Signature, "-----END PGP SIGNATURE-----"),
        _ => return None,
    })
}

/// What armored OpenPGP data holds, from its first BEGIN line (pasted or dropped text: a key or a message).
pub fn armored_kind(bytes: &[u8]) -> Option<Kind> {
    let text = String::from_utf8_lossy(bytes.get(..bytes.len().min(4096))?);
    text.lines().find_map(|line| kind_of(line).map(|(kind, _)| kind))
}

/// The lines of `text` with their byte offsets (start, end including the line break).
fn lines(text: &str) -> impl Iterator<Item = (usize, usize, &str)> {
    let mut at = 0;
    text.split_inclusive('\n').map(move |line| {
        let start = at;
        at += line.len();
        (start, at, line.trim_end_matches(['\r', '\n']))
    })
}

/// The armored blocks in `text`, in order. A block whose END line is missing is not one.
pub fn blocks(text: &str) -> Vec<Block> {
    let mut out = Vec::new();
    let mut open: Option<(Kind, &str, usize)> = None;
    for (start, end, line) in lines(text) {
        match open {
            None => {
                if let Some((kind, closing)) = kind_of(line) {
                    open = Some((kind, closing, start));
                }
            }
            Some((kind, closing, begin)) => {
                if line.trim_end() == closing {
                    out.push(Block {
                        kind,
                        start: begin,
                        end,
                    });
                    open = None;
                    if out.len() >= MAX_BLOCKS {
                        break;
                    }
                }
            }
        }
    }
    out
}

/// The text a cleartext signed block signs, as rPGP reads it: dash escaping taken off, trailing spaces trimmed (RFC
/// 9580 section 7.1), with `\n` line ends for showing. `None` if the block is not one.
pub fn cleartext(block: &str) -> Option<String> {
    let (message, _) = pgp::composed::CleartextSignedMessage::from_string(block).ok()?;
    Some(message.signed_text().replace("\r\n", "\n"))
}

#[cfg(test)]
mod tests {
    use super::*;

    const SIGNED: &str = "Hi\r\n-----BEGIN PGP SIGNED MESSAGE-----\r\nHash: SHA256\r\n\r\nHello\r\n- -- dashes\r\n\
                          -----BEGIN PGP SIGNATURE-----\r\n\r\niQ==\r\n-----END PGP SIGNATURE-----\r\nBye\r\n";

    #[test]
    fn finds_blocks() {
        let found = blocks(SIGNED);
        assert_eq!(found.len(), 1);
        assert_eq!(found[0].kind, Kind::Signed);
        assert!(SIGNED[found[0].start..found[0].end].starts_with("-----BEGIN PGP SIGNED"));
        assert!(SIGNED[found[0].end..].starts_with("Bye"));
    }

    #[test]
    fn cleartext_is_unescaped() {
        let found = blocks(SIGNED)[0];
        assert_eq!(
            cleartext(&SIGNED[found.start..found.end]).as_deref(),
            Some("Hello\n-- dashes")
        );
    }

    #[test]
    fn armor_kinds() {
        assert_eq!(
            armored_kind(b"-----BEGIN PGP PUBLIC KEY BLOCK-----\n"),
            Some(Kind::PublicKey)
        );
        assert_eq!(
            armored_kind(b"junk\n-----BEGIN PGP MESSAGE-----\n"),
            Some(Kind::Message)
        );
        assert_eq!(armored_kind(b"hello"), None);
    }

    #[test]
    fn unterminated_block_is_none() {
        assert!(blocks("-----BEGIN PGP MESSAGE-----\nabc\n").is_empty());
        assert!(blocks("text -----BEGIN PGP MESSAGE-----\nabc\n-----END PGP MESSAGE-----\n").is_empty());
    }

    #[test]
    fn several_blocks() {
        let text = "-----BEGIN PGP MESSAGE-----\na\n-----END PGP MESSAGE-----\nmiddle\n\
                    -----BEGIN PGP PUBLIC KEY BLOCK-----\nb\n-----END PGP PUBLIC KEY BLOCK-----";
        let found = blocks(text);
        assert_eq!(
            found.iter().map(|b| b.kind).collect::<Vec<_>>(),
            [Kind::Message, Kind::PublicKey]
        );
        assert_eq!(found[1].end, text.len());
    }
}
