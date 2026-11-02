//! Encoded words of header values (RFC 2047), `=?UTF-8?Q?=C3=B5?=`. Decoded leniently, the way
//! libmime does: anywhere in the value, with the space between adjacent words dropped, and the
//! bytes of adjacent words in the same charset joined before decoding, as senders split a
//! multi-byte character across two words.

use base64::Engine;
use base64::engine::general_purpose::STANDARD_NO_PAD;

use encoding_rs::Encoding;

use crate::charset;

struct Word<'a> {
    /// Where the word ends in the value
    end: usize,
    charset: &'a str,
    base64: bool,
    text: &'a str,
}

/// Adjacent words in one charset. Base64 text is joined before it is decoded: a sender can split
/// a word in the middle of a 4 character group.
struct Run<'a> {
    charset: &'a str,
    /// Resolved once for the whole run
    encoding: Option<&'static Encoding>,
    bytes: Vec<u8>,
    base64: String,
}

impl<'a> Run<'a> {
    fn new(word: &Word<'a>) -> Self {
        let mut run = Run {
            charset: word.charset,
            encoding: charset::encoding_for(word.charset),
            bytes: Vec::new(),
            base64: String::new(),
        };
        run.push(word);
        run
    }

    /// Whether `charset` is the charset of this run
    fn takes(&self, charset: &str) -> bool {
        match (self.encoding, charset::encoding_for(charset)) {
            (Some(a), Some(b)) => a == b,
            _ => self.charset.eq_ignore_ascii_case(charset),
        }
    }

    fn push(&mut self, word: &Word) {
        if word.base64 {
            self.base64.push_str(word.text);
        } else {
            self.bytes.extend(decode_b(&std::mem::take(&mut self.base64)));
            self.bytes.extend(decode_q(word.text));
        }
    }

    fn finish(mut self) -> String {
        self.bytes.extend(decode_b(&self.base64));
        match self.encoding {
            Some(encoding) => encoding.decode_without_bom_handling(&self.bytes).0.into_owned(),
            None => String::from_utf8_lossy(&self.bytes).into_owned(),
        }
    }
}

/// The encoded word that starts at `start` (at "=?"), if it is one
fn word_at(value: &str, start: usize) -> Option<Word<'_>> {
    let rest = value.get(start + 2..)?;
    let charset_end = rest.find('?')?;
    let charset = &rest[..charset_end];
    if charset.is_empty()
        || !charset
            .bytes()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, b'_' | b'-' | b'*'))
    {
        return None;
    }
    let rest = &rest[charset_end + 1..];
    let encoding = rest.as_bytes().first()?.to_ascii_uppercase();
    if !matches!(encoding, b'Q' | b'B') || rest.as_bytes().get(1) != Some(&b'?') {
        return None;
    }
    let text_end = rest[2..].find('?')?;
    if rest.as_bytes().get(2 + text_end + 1) != Some(&b'=') {
        return None;
    }
    // `rest` is the end of `value`, the word ends with the "?=" after its text
    let end = value.len() - rest[2 + text_end + 2..].len();
    let text = &rest[2..2 + text_end];
    Some(Word {
        end,
        charset,
        base64: encoding == b'B',
        text,
    })
}

/// The byte of a `=XX` or `%XX` escape that starts at `at`
pub(crate) fn hex_escape(bytes: &[u8], at: usize, marker: u8) -> Option<u8> {
    let digit = |i: usize| bytes.get(i).and_then(|c| (*c as char).to_digit(16));
    if bytes.get(at) != Some(&marker) {
        return None;
    }
    Some((digit(at + 1)? * 16 + digit(at + 2)?) as u8)
}

/// Q encoding: `_` is a space, `=XX` a byte. A broken escape stays as it is.
fn decode_q(text: &str) -> Vec<u8> {
    let text = text.as_bytes();
    let mut out = Vec::with_capacity(text.len());
    let mut i = 0;
    while i < text.len() {
        if let Some(byte) = hex_escape(text, i, b'=') {
            out.push(byte);
            i += 3;
            continue;
        }
        out.push(if matches!(text[i], b'_' | b' ' | b'\t') {
            b' '
        } else {
            text[i]
        });
        i += 1;
    }
    out
}

/// B encoding: base64 where padding ends a group (joined words can carry padding inside), stray
/// characters ignored
fn decode_b(text: &str) -> Vec<u8> {
    let mut out = Vec::new();
    for piece in text.split('=') {
        let clean: String = piece
            .chars()
            .filter(|c| c.is_ascii_alphanumeric() || *c == '+' || *c == '/')
            .collect();
        // a trailing single character can not hold a byte
        let usable = clean.len() - usize::from(clean.len() % 4 == 1);
        out.extend(STANDARD_NO_PAD.decode(&clean[..usable]).unwrap_or_default());
    }
    out
}

/// Decodes the encoded words in a header value
pub fn decode_words(value: &str) -> String {
    let mut out = String::with_capacity(value.len());
    let mut pos = 0;
    // the run of adjacent words in one charset being collected
    let mut pending: Option<Run> = None;
    let mut search = 0;
    while let Some(found) = value[search..].find("=?") {
        let start = search + found;
        let Some(word) = word_at(value, start) else {
            search = start + 2;
            continue;
        };
        let between = &value[pos..start];
        let adjacent = pending.is_some() && between.chars().all(char::is_whitespace);
        match pending.as_mut() {
            Some(run) if adjacent && run.takes(word.charset) => run.push(&word),
            _ => {
                flush(&mut out, pending.take());
                if !adjacent {
                    out.push_str(between);
                }
                pending = Some(Run::new(&word));
            }
        }
        pos = word.end;
        search = word.end;
    }
    flush(&mut out, pending);
    out.push_str(&value[pos..]);
    out
}

fn flush(out: &mut String, pending: Option<Run>) {
    if let Some(run) = pending {
        out.push_str(&run.finish());
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn decodes_q_and_b_words() {
        assert_eq!(decode_words("=?UTF-8?Q?J=C3=B5ul_ja_uus_aasta?="), "Jõul ja uus aasta");
        assert_eq!(decode_words("=?utf-8?b?SsO1dWw=?="), "Jõul");
        assert_eq!(decode_words("=?ISO-8859-1?Q?=F5?= and =?iso-8859-1?q?=e4?="), "õ and ä");
        assert_eq!(decode_words("plain text"), "plain text");
    }

    #[test]
    fn joins_adjacent_words() {
        // the space between adjacent words is dropped
        assert_eq!(decode_words("=?UTF-8?Q?a?= =?UTF-8?Q?b?="), "ab");
        // a multi-byte character split across two words
        assert_eq!(decode_words("=?UTF-8?B?w6E=?= =?UTF-8?B?w6k=?="), "áé");
        assert_eq!(decode_words("=?UTF-8?Q?=C3?= =?UTF-8?Q?=B5?="), "õ");
        assert_eq!(decode_words("=?UTF-8?B?w?= =?UTF-8?B?7U=?="), "õ");
        // different charsets are decoded on their own, still without the space
        assert_eq!(decode_words("=?UTF-8?Q?=C3=B5?= =?ISO-8859-1?Q?=E4?="), "õä");
        // text between words stays
        assert_eq!(decode_words("=?UTF-8?Q?a?= x =?UTF-8?Q?b?="), "a x b");
    }

    #[test]
    fn leaves_broken_words_alone() {
        assert_eq!(decode_words("=?UTF-8?X?abc?="), "=?UTF-8?X?abc?=");
        assert_eq!(decode_words("=?UTF-8?Q?abc"), "=?UTF-8?Q?abc");
        assert_eq!(decode_words("=??Q?a?="), "=??Q?a?=");
        assert_eq!(decode_words("a =? b"), "a =? b");
        assert_eq!(decode_words("=?UTF-8?Q?a=ZZ?="), "a=ZZ");
        assert_eq!(decode_words("=?utf-8*en?Q?x?="), "x");
        assert_eq!(decode_words("=?UTF-8?B?!!!?="), "");
    }
}
