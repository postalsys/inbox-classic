//! The encodings of outgoing mail, ported from nodemailer's qp, base64 and mime-funcs: quoted-printable and base64
//! bodies with their line wrapping, encoded words for header text, header folding and RFC 2231 parameters. The
//! output is what nodemailer writes, checked against it in tests/conformance.rs. Where nodemailer counts JavaScript
//! string length (UTF-16 units) the port does the same.

use base64::Engine;
use base64::engine::general_purpose::STANDARD;

/// The longest line of a quoted-printable or base64 body, and the folding width of headers
pub const LINE_LENGTH: usize = 76;

/// The limit of encoded words in headers
pub const WORD_LENGTH: usize = 52;

fn utf16_len(text: &str) -> usize {
    text.encode_utf16().count()
}

// ---- quoted-printable ----

/// Bytes written as they are (RFC 2045 6.7): TAB, LF, CR, and printable ASCII but '='
fn qp_literal(byte: u8) -> bool {
    matches!(byte, 0x09 | 0x0a | 0x0d | 0x20..=0x3c | 0x3e..=0x7e)
}

/// Quoted-printable without line wrapping; whitespace that ends a line is encoded
pub fn qp_encode(bytes: &[u8]) -> String {
    let mut out = String::with_capacity(bytes.len() * 3);
    for (i, &byte) in bytes.iter().enumerate() {
        let next = bytes.get(i + 1);
        let ends_line = matches!(next, None | Some(b'\n') | Some(b'\r'));
        if qp_literal(byte) && !(matches!(byte, b' ' | b'\t') && ends_line) {
            out.push(byte as char);
        } else {
            out.push_str(&format!("={byte:02X}"));
        }
    }
    out
}

fn is_hex(byte: u8) -> bool {
    byte.is_ascii_hexdigit()
}

/// Whether `line` ends with `=`, `=X` or `=XX` (hex), and the length of that tail
fn escape_tail(line: &[u8], max_digits: usize) -> Option<usize> {
    let at = line.iter().rposition(|c| *c == b'=')?;
    let digits = line.len() - at - 1;
    (digits <= max_digits && line[at + 1..].iter().all(|c| is_hex(*c))).then_some(digits + 1)
}

/// `=XX` at the end of `line`, its byte value
fn ends_with_escape(line: &[u8]) -> Option<u8> {
    let n = line.len();
    (n >= 3 && line[n - 3] == b'=' && is_hex(line[n - 2]) && is_hex(line[n - 1]))
        .then(|| u8::from_str_radix(std::str::from_utf8(&line[n - 2..]).unwrap_or("00"), 16).unwrap_or(0))
}

/// Whether `line` is one to four `=XX` escapes and nothing else
fn only_escapes(line: &[u8]) -> bool {
    line.len().is_multiple_of(3)
        && (3..=12).contains(&line.len())
        && line.chunks(3).all(|c| c[0] == b'=' && is_hex(c[1]) && is_hex(c[2]))
}

/// Takes the last `margin` bytes of `line`
fn tail(line: &[u8], margin: usize) -> &[u8] {
    &line[line.len().saturating_sub(margin)..]
}

/// Adds soft line breaks to quoted-printable text, at most `line_length` characters a line, breaking at white
/// space or punctuation when it can and never inside an escape or a UTF-8 sequence
pub fn qp_wrap(text: &str, line_length: usize) -> String {
    let line_length = line_length.max(4);
    let input = text.as_bytes();
    if input.len() <= line_length {
        return text.to_string();
    }
    let len = input.len();
    let margin = line_length / 3;
    let mut result: Vec<u8> = Vec::with_capacity(len + len / line_length * 3);
    let mut pos = 0;
    while pos < len {
        let mut line = &input[pos..(pos + line_length).min(len)];
        if let Some(at) = line.windows(2).position(|w| w == b"\r\n") {
            line = &line[..at + 2];
            result.extend_from_slice(line);
            pos += line.len();
            continue;
        }
        if line.last() == Some(&b'\n') {
            result.extend_from_slice(line);
            pos += line.len();
            continue;
        }
        let end = tail(line, margin);
        if let Some(at) = end.iter().rposition(|c| *c == b'\n') {
            // up to the line break
            line = &line[..line.len() - (end.len() - at - 1)];
            result.extend_from_slice(line);
            pos += line.len();
            continue;
        }
        let breakable = |c: &u8| matches!(c, b' ' | b'\t' | b'.' | b',' | b'!' | b'?');
        if line.len() > line_length - margin
            && let Some(at) = end.iter().rposition(breakable)
        {
            // after the last space or punctuation
            line = &line[..line.len() - (end.len() - at - 1)];
        } else if escape_tail(line, 2).is_some() {
            // an escape cut in two moves to the next line
            if let Some(cut) = escape_tail(line, 1) {
                line = &line[..line.len() - cut];
            }
            // and so does a UTF-8 sequence cut in two
            while line.len() > 3 && line.len() < len - pos && !only_escapes(line) {
                let Some(code) = ends_with_escape(line) else { break };
                if code < 128 {
                    break;
                }
                line = &line[..line.len() - 3];
                if code >= 0xc0 {
                    break;
                }
            }
        }
        if line.is_empty() {
            // only an incomplete escape at the very end of the input empties a line
            line = &input[pos..(pos + line_length).min(len)];
        }
        if pos + line.len() < len && line.last() != Some(&b'\n') {
            if line.len() == line_length && ends_with_escape(line).is_some() {
                line = &line[..line.len() - 3];
            } else if line.len() == line_length {
                line = &line[..line.len() - 1];
            }
            pos += line.len();
            result.extend_from_slice(line);
            result.extend_from_slice(b"=\r\n");
        } else {
            pos += line.len();
            result.extend_from_slice(line);
        }
    }
    String::from_utf8(result).unwrap_or_default()
}

// ---- base64 ----

pub fn base64_encode(bytes: &[u8]) -> String {
    STANDARD.encode(bytes)
}

/// Base64 of `bytes` in lines of 76 characters, written to `out`: the same as `base64_wrap(base64_encode(bytes))`
/// without the two copies of it
pub fn base64_lines_into(bytes: &[u8], out: &mut Vec<u8>) {
    // 57 bytes are 76 characters
    for (i, chunk) in bytes.chunks(57).enumerate() {
        if i > 0 {
            out.extend_from_slice(b"\r\n");
        }
        out.extend_from_slice(STANDARD.encode(chunk).as_bytes());
    }
}

/// Base64 in lines of `line_length` characters
pub fn base64_wrap(text: &str, line_length: usize) -> String {
    let line_length = line_length.max(1);
    if text.len() <= line_length {
        return text.to_string();
    }
    let lines: Vec<&str> = text
        .as_bytes()
        .chunks(line_length)
        .map(|chunk| std::str::from_utf8(chunk).unwrap_or(""))
        .collect();
    lines.join("\r\n").trim().to_string()
}

// ---- encoded words ----

/// `Q` when a value is mostly Latin letters, `B` otherwise; counted in UTF-16 units as nodemailer does
pub fn text_encoding(value: &str) -> char {
    let (mut non_latin, mut latin) = (0usize, 0usize);
    for unit in value.encode_utf16() {
        match unit {
            0x00..=0x08 | 0x0b | 0x0c | 0x0e..=0x1f | 0x80.. => non_latin += 1,
            0x41..=0x5a | 0x61..=0x7a => latin += 1,
            _ => {}
        }
    }
    if non_latin < latin { 'Q' } else { 'B' }
}

/// Splits quoted-printable text of an encoded word into parts of at most `max` characters without cutting an
/// escape or a UTF-8 sequence
pub fn split_encoded(text: &str, max: usize) -> Vec<String> {
    let max = max.max(12);
    let mut rest = text.as_bytes();
    let mut parts = Vec::new();
    while !rest.is_empty() {
        let mut line = &rest[..max.min(rest.len())];
        if let Some(cut) = escape_tail(line, 1) {
            line = &line[..line.len() - cut];
        }
        let fallback = if line.is_empty() {
            &rest[..max.min(rest.len())]
        } else {
            line
        };
        loop {
            if line.is_empty() {
                break;
            }
            let after = &rest[line.len()..];
            let continuation = after.len() >= 3
                && after[0] == b'='
                && is_hex(after[1])
                && is_hex(after[2])
                && matches!(
                    u8::from_str_radix(std::str::from_utf8(&after[1..3]).unwrap_or("00"), 16),
                    Ok(0x80..=0xc1)
                );
            if !continuation {
                break;
            }
            // the next byte continues a UTF-8 sequence: step back one escape
            line = &line[..line.len().saturating_sub(3)];
        }
        if line.is_empty() {
            line = fallback;
        }
        parts.push(String::from_utf8_lossy(line).into_owned());
        rest = &rest[line.len()..];
    }
    parts
}

/// An RFC 2047 encoded word of `data` in UTF-8, `Q` or `B`, split into several when `max_length` is set and the
/// word would be longer
pub fn encode_word(data: &str, encoding: char, max_length: usize) -> String {
    let mut max = max_length;
    if max > 12 {
        // =?UTF-8?Q? and ?=
        max -= 12;
    }
    let encoded = if encoding == 'Q' {
        let mut word = String::new();
        for c in qp_encode(data.as_bytes()).chars() {
            match c {
                ' ' => word.push('_'),
                'a'..='z' | 'A'..='Z' | '0'..='9' | '!' | '*' | '+' | '-' | '/' | '=' => word.push(c),
                _ => word.push_str(&format!("={:02X}", c as u32)),
            }
        }
        if max > 0 && word.len() > max {
            split_encoded(&word, max).join("?= =?UTF-8?Q?")
        } else {
            word
        }
    } else {
        let max = if max > 0 { (max - max % 4) / 4 * 3 } else { 0 }.max(if max > 0 { 3 } else { 0 });
        if max > 0 && base64_encode(data.as_bytes()).len() > max {
            // whole characters in each word (RFC 2047 6.3)
            let mut parts = Vec::new();
            let mut part = String::new();
            for (i, c) in data.chars().enumerate() {
                if part.len() + c.len_utf8() <= max || i == 0 {
                    part.push(c);
                } else {
                    parts.push(base64_encode(part.as_bytes()));
                    part = c.to_string();
                }
            }
            if !part.is_empty() {
                parts.push(base64_encode(part.as_bytes()));
            }
            parts.join("?= =?UTF-8?B?")
        } else {
            base64_encode(data.as_bytes())
        }
    };
    let close = if encoded.ends_with("?=") { "" } else { "?=" };
    format!("=?UTF-8?{encoding}?{encoded}{close}")
}

/// `value` with what needs encoding (non-ASCII, a quote, a look-alike of an encoded word that is not a valid one) as
/// encoded words: all of it with `encode_all`, otherwise from the word that holds the first such character to the
/// word that holds the last. A valid encoded word is passed through as it is.
pub fn encode_words(value: &str, encoding: char, max_length: usize, encode_all: bool) -> String {
    let chars: Vec<char> = value.chars().collect();
    let special = |c: &char| *c == '"' || !c.is_ascii();
    let mut range = (chars.iter().position(special), chars.iter().rposition(special));
    if value.contains("=?") {
        range = mark_invalid_encoded_words(&chars, range);
    }
    let (Some(first), Some(last)) = range else {
        return value.to_string();
    };
    if encode_all {
        return encode_word(value, encoding, max_length);
    }
    let mut start = first;
    while start > 0 && !is_js_space(chars[start - 1]) {
        start -= 1;
    }
    let mut end = last + 1;
    while end < chars.len() && !is_js_space(chars[end]) {
        end += 1;
    }
    let part = |range: std::ops::Range<usize>| chars[range].iter().collect::<String>();
    format!(
        "{}{}{}",
        part(0..start),
        encode_word(&part(start..end), encoding, max_length),
        part(end..chars.len())
    )
}

/// The white space of JavaScript's `\s`
fn is_js_space(c: char) -> bool {
    matches!(c as u32, 0x09..=0x0d | 0x20 | 0xa0 | 0x1680 | 0x2000..=0x200a | 0x2028 | 0x2029 | 0x202f | 0x205f | 0x3000 | 0xfeff)
}

/// An encoded word as RFC 2047 section 2 spells it: a charset token (with an optional RFC 2231 language), B or Q,
/// and encoded text without '?' or white space
fn is_valid_encoded_word(word: &[char]) -> bool {
    let text: String = word.iter().collect();
    let Some(inner) = text.strip_prefix("=?").and_then(|t| t.strip_suffix("?=")) else {
        return false;
    };
    let mut parts = inner.split('?');
    let (Some(charset), Some(encoding), Some(encoded), None) = (parts.next(), parts.next(), parts.next(), parts.next())
    else {
        return false;
    };
    !charset.is_empty()
        && !charset
            .chars()
            .any(|c| is_js_space(c) || "()<>@,;:\"/[]?.=".contains(c))
        && matches!(encoding, "B" | "b" | "Q" | "q")
        && !encoded.is_empty()
        && !encoded.chars().any(is_js_space)
}

/// The end of what a lenient decoder reads as an encoded word at `pos` (libmime and Python decode
/// '=?utf-8?Q?a b?=' across the space too): `=?[^?]*?[BbQq]?[^?]*?=`. Every part stops at the next '?', so this
/// never backtracks.
fn lenient_encoded_word(chars: &[char], pos: usize) -> Option<usize> {
    let to_question = |from: usize| (from..chars.len()).find(|&i| chars[i] == '?');
    if chars.get(pos..pos + 2)? != ['=', '?'] {
        return None;
    }
    let first = to_question(pos + 2)?;
    if !matches!(chars.get(first + 1)?, 'B' | 'b' | 'Q' | 'q') || chars.get(first + 2)? != &'?' {
        return None;
    }
    let last = to_question(first + 3)?;
    (chars.get(last + 1)? == &'=').then_some(last + 2)
}

/// `range` (the first and the last char that needs encoding) widened to the words of every look-alike of an
/// encoded word that is not one valid encoded word on its own (nodemailer 7a7b942). RFC 2047 section 7 requires a
/// word that begins with '=?' and ends with '?=' to be a valid encoded word, and decoders also decode a look-alike
/// that spans white space, so '=?utf-8?X?x?=' and 'see =?utf-8?Q?a b?= here' read differently on every receiver.
/// The bounds of the word around each '=?' are found once per word, so this stays linear.
fn mark_invalid_encoded_words(chars: &[char], range: (Option<usize>, Option<usize>)) -> (Option<usize>, Option<usize>) {
    let (mut first, mut last) = range;
    let len = chars.len();
    let (mut word_start, mut word_end) = (0, 0);
    let mut have_word = false;
    let mut word_at = |pos: usize, word_start: &mut usize, word_end: &mut usize| {
        if have_word && pos < *word_end {
            return;
        }
        have_word = true;
        *word_start = pos;
        while *word_start > 0 && !is_js_space(chars[*word_start - 1]) {
            *word_start -= 1;
        }
        *word_end = pos;
        while *word_end < len && !is_js_space(chars[*word_end]) {
            *word_end += 1;
        }
    };
    let find = |from: usize| (from..len.saturating_sub(1)).find(|&i| chars[i] == '=' && chars[i + 1] == '?');
    let mut pos = find(0);
    while let Some(at) = pos {
        word_at(at, &mut word_start, &mut word_end);
        let start = word_start;
        let matched = lenient_encoded_word(chars, at);
        let end = matched.unwrap_or(word_end);
        if matched.is_some() && end > word_end {
            // the look-alike runs across white space, on to the word it ends in
            word_at(end - 1, &mut word_start, &mut word_end);
        }
        // the word is measured only where it starts at this '=?', once per word, so this stays linear
        let word = &chars[start..word_end];
        let looks_like = matched.is_some() || (start == at && word.len() >= 4 && word.ends_with(&['?', '=']));
        let valid = || {
            start == at
                && word_end == end
                && word.len() <= 75
                && word.iter().map(|c| c.len_utf16()).sum::<usize>() <= 75
                && is_valid_encoded_word(word)
        };
        if looks_like && !valid() {
            first = Some(first.map_or(start, |f| f.min(start)));
            last = Some(last.map_or(word_end - 1, |l| l.max(word_end - 1)));
        }
        pos = find(matched.map_or(at + 2, |_| end));
    }
    (first, last)
}

/// A control character that can not stand in a header: all but TAB, CR and LF, and DEL
pub fn is_header_control(c: char) -> bool {
    matches!(c, '\x00'..='\x08' | '\x0b' | '\x0c' | '\x0e'..='\x1f' | '\x7f')
}

fn has_header_controls(value: &str) -> bool {
    value.chars().any(is_header_control)
}

/// Unstructured header text (Subject): as it is when it is plain ASCII, encoded words otherwise
pub fn encode_header_text(value: &str) -> String {
    let encoding = text_encoding(value);
    if has_header_controls(value) {
        encode_word(value, encoding, WORD_LENGTH)
    } else {
        encode_words(value, encoding, WORD_LENGTH, true)
    }
}

/// The display name of an address: bare when it is letters, digits and spaces, quoted when it is other ASCII,
/// encoded words otherwise
pub fn encode_address_name(name: &str) -> String {
    if name.chars().all(|c| c.is_ascii_alphanumeric() || c == '_' || c == ' ') {
        name.to_string()
    } else if name.chars().all(|c| matches!(c, '\x20'..='\x7e')) {
        quote_string(name)
    } else {
        encode_word(name, text_encoding(name), WORD_LENGTH)
    }
}

/// A quoted-string, quotes and backslashes escaped
pub fn quote_string(value: &str) -> String {
    let mut out = String::with_capacity(value.len() + 2);
    out.push('"');
    for c in value.chars() {
        if c == '"' || c == '\\' {
            out.push('\\');
        }
        out.push(c);
    }
    out.push('"');
    out
}

// ---- header folding ----

/// Folds a header line at white space so lines stay within `line_length` characters where they can
pub fn fold_lines(text: &str, line_length: usize, after_space: bool) -> String {
    let chars: Vec<char> = text.chars().collect();
    let len = chars.len();
    let mut result = String::with_capacity(text.len() + text.len() / line_length * 3);
    let mut pos = 0;
    while pos < len {
        let mut line: &[char] = &chars[pos..(pos + line_length).min(len)];
        if line.len() < line_length {
            result.extend(line);
            break;
        }
        if let Some(at) = line.iter().position(|c| *c == '\n' || *c == '\r') {
            // up to and with the line break that is there
            let end = if line[at] == '\r' && line.get(at + 1) == Some(&'\n') {
                at + 2
            } else {
                at + 1
            };
            line = &line[..end];
            result.extend(line);
            pos += line.len();
            continue;
        }
        if let Some((start, run)) = last_space_run(line)
            && line.len() - start - if after_space { run } else { 0 } < line.len()
        {
            let cut = line.len() - start - if after_space { run } else { 0 };
            line = &line[..line.len() - cut];
        } else {
            // no space to break at in the line: up to the next one
            let after = &chars[pos + line.len()..];
            let word = after.iter().take_while(|c| !c.is_whitespace()).count();
            if word > 0 {
                let spaces = after[word..].iter().take_while(|c| c.is_whitespace()).count();
                let take = word + if after_space { spaces } else { 0 };
                line = &chars[pos..pos + line.len() + take];
            }
        }
        result.extend(line);
        pos += line.len();
        if pos < len {
            result.push_str("\r\n");
        }
    }
    result
}

/// The start and length of the last run of white space in `line`
fn last_space_run(line: &[char]) -> Option<(usize, usize)> {
    let end = line.iter().rposition(|c| c.is_whitespace())? + 1;
    let start = line[..end]
        .iter()
        .rposition(|c| !c.is_whitespace())
        .map_or(0, |at| at + 1);
    Some((start, end - start))
}

// ---- parameters ----

/// Printable 7-bit text; for a parameter value also without TAB, CR, LF, DEL and quotes
pub fn is_plain_text(value: &str, is_param: bool) -> bool {
    !value.chars().any(|c| {
        if is_param {
            matches!(c, '\x00'..='\x1f' | '\x7f' | '"') || !c.is_ascii()
        } else {
            (is_header_control(c) && c != '\x7f') || !c.is_ascii()
        }
    })
}

/// A parameter value that goes out as it is: plain and not looking like an encoded word
fn is_plain_param_value(value: &str) -> bool {
    is_plain_text(value, true) && !value.contains("=?")
}

/// Percent encoding of everything but letters, digits and `-_.!~`, as UTF-8
pub fn safe_encode_uri_component(text: &str) -> String {
    let mut out = String::with_capacity(text.len() * 3);
    for byte in text.bytes() {
        if byte.is_ascii_alphanumeric() || matches!(byte, b'-' | b'_' | b'.' | b'!' | b'~') {
            out.push(byte as char);
        } else {
            out.push_str(&format!("%{byte:02X}"));
        }
    }
    out
}

/// A parameter as RFC 2231 continuations of at most `max_length` characters: `(key, value)` pairs, the keys
/// `name*0*`, `name*1` ... A short plain value stays one `(key, value)`.
pub fn build_header_param(key: &str, data: &str, max_length: usize) -> Vec<(String, String)> {
    let mut list: Vec<(String, bool)> = Vec::new();
    if is_plain_param_value(data) {
        let chars: Vec<char> = data.chars().collect();
        if chars.len() <= max_length {
            return vec![(key.to_string(), data.to_string())];
        }
        for chunk in chars.chunks(max_length) {
            list.push((chunk.iter().collect(), false));
        }
        // a last part shorter than the others is a part as well
    } else {
        let chars: Vec<String> = data.chars().map(String::from).collect();
        let mut line = String::from("utf-8''");
        let mut encoded = true;
        let mut start: isize = 0;
        let mut i: isize = 0;
        while (i as usize) < chars.len() {
            let original = &chars[i as usize];
            let mut chr = if encoded || original != " " {
                safe_encode_uri_component(original)
            } else {
                original.clone()
            };
            if !encoded && chr != *original {
                // the line so far was plain: it starts over encoded, if the char still fits
                if safe_encode_uri_component(&line).len() + chr.len() >= max_length {
                    list.push((std::mem::take(&mut line), encoded));
                    encoded = true;
                } else {
                    encoded = true;
                    i = start + 1;
                    line.clear();
                    continue;
                }
            }
            if line.len() + chr.len() >= max_length {
                list.push((std::mem::take(&mut line), encoded));
                chr = if original == " " {
                    " ".to_string()
                } else {
                    safe_encode_uri_component(original)
                };
                line = chr.clone();
                if chr == *original {
                    encoded = false;
                    start = i - 1;
                } else {
                    encoded = true;
                }
            } else {
                line.push_str(&chr);
            }
            i += 1;
        }
        if !line.is_empty() {
            list.push((line, encoded));
        }
    }
    list.into_iter()
        .enumerate()
        .map(|(i, (line, encoded))| (format!("{key}*{i}{}", if encoded { "*" } else { "" }), line))
        .collect()
}

/// A JSON string of `value`, the quoting nodemailer uses for parameter values
fn json_quote(value: &str) -> String {
    let mut out = String::from("\"");
    for c in value.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

fn has_tspecials(value: &str, apostrophe: bool) -> bool {
    value.chars().any(|c| {
        c.is_whitespace()
            || matches!(
                c,
                '"' | '\\' | ';' | ':' | '/' | '=' | '(' | ')' | ',' | '<' | '>' | '@' | '[' | ']' | '?'
            )
            || (apostrophe && c == '\'')
    })
}

/// A JSON-quoted value when it needs quoting, as nodemailer writes a `name=` of Content-Type
pub(crate) fn quote_param_if_needed(value: &str, encoded_from: &str) -> String {
    if value != encoded_from || has_tspecials(value, true) || value.starts_with('-') {
        json_quote(value)
    } else {
        value.to_string()
    }
}

/// `value; key=value; ...` with the parameters encoded as they need to be
pub fn build_header_value(value: &str, params: &[(&str, &str)]) -> String {
    let mut parts = Vec::new();
    for (key, param) in params {
        let key: String = key.chars().filter(|c| !c.is_control()).collect();
        if !is_plain_param_value(param) || utf16_len(param) >= 75 {
            for (name, encoded) in build_header_param(&key, param, 50) {
                let bare =
                    !(has_tspecials(&encoded, false) || encoded.starts_with(['-', '\'']) || encoded.ends_with('\''));
                if bare || name.ends_with('*') {
                    parts.push(format!("{name}={encoded}"));
                } else {
                    parts.push(format!("{name}={}", json_quote(&encoded)));
                }
            }
        } else if param.is_empty() || has_tspecials(param, true) || param.starts_with('-') {
            parts.push(format!("{key}={}", json_quote(param)));
        } else {
            parts.push(format!("{key}={param}"));
        }
    }
    let value: String = value.chars().filter(|c| !c.is_control()).collect();
    if parts.is_empty() {
        value
    } else {
        format!("{value}; {}", parts.join("; "))
    }
}

/// Whether a line of `text` is longer than `line_length` UTF-16 units; anything over 128 kB counts as long
pub fn has_longer_lines(text: &str, line_length: usize) -> bool {
    text.len() > 128 * 1024
        || text
            .split(['\n', '\r', '\u{2028}', '\u{2029}'])
            .any(|line| utf16_len(line) > line_length)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn quoted_printable() {
        assert_eq!(qp_encode("a = b \r\nc\t".as_bytes()), "a =3D b=20\r\nc=09");
        assert_eq!(qp_encode("ü".as_bytes()), "=C3=BC");
        let long = qp_encode("x".repeat(100).as_bytes());
        assert_eq!(qp_wrap(&long, 76), format!("{}=\r\n{}", "x".repeat(75), "x".repeat(25)));
    }

    #[test]
    fn words() {
        assert_eq!(encode_word("tere õhtust", 'Q', 0), "=?UTF-8?Q?tere_=C3=B5htust?=");
        assert_eq!(encode_word("日本", 'B', 0), "=?UTF-8?B?5pel5pys?=");
        assert_eq!(encode_words("plain", 'Q', 52, true), "plain");
        // a look-alike of an encoded word that is not a valid one is encoded, a valid one passes (the full cases are
        // in the conformance fixtures)
        assert!(encode_header_text("Re: =?utf-8?X?fake?=").starts_with("=?UTF-8?Q?"));
        assert_eq!(encode_header_text("=?UTF-8?B?ZmFrZQ==?="), "=?UTF-8?B?ZmFrZQ==?=");
        let partial = encode_words("see =?utf-8?X?fake?= here", 'Q', 52, false);
        assert!(
            partial.starts_with("see =?UTF-8?Q?") && partial.ends_with("?= here"),
            "{partial}"
        );
        for value in [
            "=? ".repeat(200_000),
            "=?".repeat(400_000),
            format!("{}=?", "a".repeat(400_000)),
            format!("=?x?Q?{}?=", "a".repeat(400_000)),
        ] {
            let started = std::time::Instant::now();
            encode_words(&value, 'Q', 52, true);
            let elapsed = started.elapsed();
            assert!(elapsed.as_secs() < 5, "{} chars took {elapsed:?}", value.len());
        }
        assert_eq!(text_encoding("abc ü"), 'Q');
        assert_eq!(text_encoding("ü"), 'B');
    }

    #[test]
    fn parameters() {
        assert_eq!(
            build_header_value("attachment", &[("filename", "a.pdf")]),
            "attachment; filename=a.pdf"
        );
        assert_eq!(
            build_header_value("attachment", &[("filename", "a b.pdf")]),
            "attachment; filename=\"a b.pdf\""
        );
        assert_eq!(
            build_header_value("attachment", &[("filename", "õ.txt")]),
            "attachment; filename*0*=utf-8''%C3%B5.txt"
        );
        assert_eq!(safe_encode_uri_component("a b*'()"), "a%20b%2A%27%28%29");
    }

    #[test]
    fn base64_into_a_buffer() {
        for len in [0, 1, 56, 57, 58, 114, 1000] {
            let bytes: Vec<u8> = (0..len).map(|i| i as u8).collect();
            let mut out = Vec::new();
            base64_lines_into(&bytes, &mut out);
            assert_eq!(
                String::from_utf8(out).unwrap(),
                base64_wrap(&base64_encode(&bytes), LINE_LENGTH)
            );
        }
    }

    #[test]
    fn folding() {
        assert_eq!(fold_lines("short", 76, false), "short");
        let folded = fold_lines(&format!("Subject: {}", "word ".repeat(30)), 76, false);
        assert!(folded.split("\r\n").all(|line| line.len() <= 76), "{folded}");
    }
}
