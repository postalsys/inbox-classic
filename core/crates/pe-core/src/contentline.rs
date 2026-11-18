//! The content lines of iCalendar (RFC 5545 3.1) and vCard (RFC 6350 3.3) files, which share their grammar: folded
//! lines unfolded, each split into its name, its parameters and its value, and TEXT values unescaped

/// A content line: its name (uppercase, without a group prefix), its parameters (names uppercase; a parameter of no
/// value, as vCard 2.1 writes `PREF`, with an empty one) and its value
pub(crate) type Line = (String, Vec<(String, String)>, String);

/// The lines of a file with the folded ones unfolded (a line that starts with a space or tab goes on the one before),
/// without empty ones
pub(crate) fn unfold(text: &str) -> Vec<String> {
    let mut unfolded: Vec<String> = Vec::new();
    for line in text.split('\n').map(|l| l.trim_end_matches('\r')) {
        match (line.strip_prefix([' ', '\t']), unfolded.last_mut()) {
            (Some(rest), Some(last)) => last.push_str(rest),
            _ if !line.is_empty() => unfolded.push(line.to_string()),
            _ => {}
        }
    }
    unfolded
}

/// A content line taken apart; None for one without a value
pub(crate) fn split(line: &str) -> Option<Line> {
    // the value starts at the first colon outside a quoted parameter
    let mut quoted = false;
    let colon = line.char_indices().find(|&(_, c)| {
        if c == '"' {
            quoted = !quoted;
        }
        c == ':' && !quoted
    })?;
    let (head, value) = (&line[..colon.0], &line[colon.0 + 1..]);
    let mut parts = head.split(';');
    let name = parts.next()?.trim().rsplit('.').next()?.to_ascii_uppercase();
    let params = parts
        .map(|p| match p.split_once('=') {
            Some((k, v)) => (k.trim().to_ascii_uppercase(), v.trim().trim_matches('"').to_string()),
            None => (p.trim().to_ascii_uppercase(), String::new()),
        })
        .collect();
    Some((name, params, value.to_string()))
}

/// The lines of a file, unfolded and taken apart
pub(crate) fn lines(text: &str) -> Vec<Line> {
    unfold(text).iter().filter_map(|line| split(line)).collect()
}

/// A TEXT value with its escapes taken out (`\n`, `\,`, `\;`, `\\`)
pub(crate) fn unescape(value: &str) -> String {
    let mut out = String::with_capacity(value.len());
    let mut chars = value.chars();
    while let Some(c) = chars.next() {
        if c == '\\' {
            match chars.next() {
                Some('n' | 'N') => out.push('\n'),
                Some(other) => out.push(other),
                None => {}
            }
        } else {
            out.push(c);
        }
    }
    out
}

/// The address of a `mailto:` value (an organizer, an attendee), trimmed; the value itself when it is no `mailto:`
pub(crate) fn mailto_address(value: &str) -> &str {
    let value = value.trim();
    value
        .get(..7)
        .filter(|p| p.eq_ignore_ascii_case("mailto:"))
        .map_or(value, |_| &value[7..])
        .trim()
}

/// A TEXT value escaped for a content line (`\\`, `\,`, `\;`, `\n`)
pub(crate) fn escape(value: &str) -> String {
    let mut out = String::with_capacity(value.len());
    for c in value.chars() {
        match c {
            '\\' => out.push_str("\\\\"),
            ',' => out.push_str("\\,"),
            ';' => out.push_str("\\;"),
            '\n' => out.push_str("\\n"),
            '\r' => {}
            other => out.push(other),
        }
    }
    out
}

/// A content line, folded at 75 bytes as the standards have it (a fold never inside a character), with its CRLF
pub(crate) fn folded(line: &str) -> String {
    let mut out = String::new();
    let mut width = 0;
    for c in line.chars() {
        if width + c.len_utf8() > 75 {
            out.push_str("\r\n ");
            width = 1;
        }
        out.push(c);
        width += c.len_utf8();
    }
    out.push_str("\r\n");
    out
}

/// Whether the parameters say `kind`: as a TYPE (`TYPE=WORK,PREF`, `type=pref`) or on its own (`PREF`)
pub(crate) fn has_type(params: &[(String, String)], kind: &str) -> bool {
    params.iter().any(|(key, value)| {
        key.eq_ignore_ascii_case(kind)
            || (key == "TYPE" && value.split(',').any(|v| v.trim().eq_ignore_ascii_case(kind)))
    })
}
