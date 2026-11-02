//! Names to save attachments under. The sender picks the filename, so it may hold a path, names
//! Windows reserves for devices, control characters, or direction overrides that make
//! `photo\u{202e}gpj.exe` look like `photo.exe.jpg`.

/// The longest name kept, in characters; the extension survives the cut
const MAX_CHARS: usize = 200;

const RESERVED: [&str; 4] = ["CON", "PRN", "AUX", "NUL"];

pub fn safe_filename(name: Option<&str>, mime_type: &str) -> String {
    let base = name.unwrap_or_default().rsplit(['/', '\\']).next().unwrap_or_default();
    let cleaned: String = base.chars().filter(|c| !is_unsafe(*c)).collect();
    let cleaned = cleaned.trim_matches(|c: char| c.is_whitespace() || c == '.');
    if cleaned.is_empty() {
        return format!("attachment.{}", extension_for(mime_type));
    }
    let shortened = shorten(cleaned);
    if is_reserved(&shortened) {
        format!("_{shortened}")
    } else {
        shortened
    }
}

/// The name without control and direction characters, for display
pub(crate) fn without_unsafe_marks(name: &str) -> String {
    name.chars()
        .filter(|c| !c.is_control() && !is_direction_mark(*c))
        .collect()
}

fn is_direction_mark(c: char) -> bool {
    // marks, embeddings, overrides and isolates
    matches!(c, '\u{061c}' | '\u{200e}' | '\u{200f}' | '\u{202a}'..='\u{202e}' | '\u{2066}'..='\u{2069}')
}

fn is_unsafe(c: char) -> bool {
    c.is_control() || matches!(c, '<' | '>' | ':' | '"' | '|' | '?' | '*') || is_direction_mark(c)
}

/// `CON`, `com1.txt`, `LPT¹.log`: Windows opens a device instead of a file for these, whatever
/// the extension
fn is_reserved(name: &str) -> bool {
    let stem = name
        .split('.')
        .next()
        .unwrap_or_default()
        .trim_end()
        .to_ascii_uppercase();
    if RESERVED.contains(&stem.as_str()) {
        return true;
    }
    let Some(rest) = stem.strip_prefix("COM").or_else(|| stem.strip_prefix("LPT")) else {
        return false;
    };
    let mut digits = rest.chars();
    matches!(
        (digits.next(), digits.next()),
        (Some('0'..='9' | '¹' | '²' | '³'), None)
    )
}

fn shorten(name: &str) -> String {
    if name.chars().count() <= MAX_CHARS {
        return name.to_string();
    }
    let extension = name
        .rsplit_once('.')
        .map(|(_, e)| e)
        .filter(|e| !e.is_empty() && e.chars().count() <= 16);
    match extension {
        Some(extension) => {
            let keep = MAX_CHARS - extension.chars().count() - 1;
            let stem: String = name.chars().take(keep).collect();
            format!("{}.{extension}", stem.trim_end())
        }
        None => {
            let cut: String = name.chars().take(MAX_CHARS).collect();
            cut.trim_end_matches(|c: char| c.is_whitespace() || c == '.')
                .to_string()
        }
    }
}

fn extension_for(mime_type: &str) -> &'static str {
    match mime_type {
        "text/plain" => "txt",
        "text/html" => "html",
        "text/calendar" | "application/ics" => "ics",
        "message/rfc822" => "eml",
        "message/delivery-status" | "message/feedback-report" => "txt",
        "image/png" => "png",
        "image/jpeg" => "jpg",
        "image/gif" => "gif",
        "application/pdf" => "pdf",
        _ => "bin",
    }
}

#[cfg(test)]
mod tests {
    use super::safe_filename;

    #[test]
    fn strips_paths_and_unsafe_characters() {
        assert_eq!(safe_filename(Some("../../etc/passwd"), "text/plain"), "passwd");
        assert_eq!(
            safe_filename(Some("C:\\Windows\\evil.dll"), "application/octet-stream"),
            "evil.dll"
        );
        assert_eq!(
            safe_filename(Some("photo\u{202e}gpj.exe"), "image/jpeg"),
            "photogpj.exe"
        );
        assert_eq!(safe_filename(Some("a\u{0}b\r\n:c?.txt"), "text/plain"), "abc.txt");
        assert_eq!(safe_filename(Some(" report.pdf. "), "application/pdf"), "report.pdf");
        assert_eq!(safe_filename(Some("Tšekk.pdf"), "application/pdf"), "Tšekk.pdf");
    }

    #[test]
    fn names_from_the_type() {
        assert_eq!(safe_filename(None, "message/rfc822"), "attachment.eml");
        assert_eq!(safe_filename(Some(".."), "image/png"), "attachment.png");
        assert_eq!(safe_filename(Some("dir/"), "application/x-foo"), "attachment.bin");
    }

    #[test]
    fn reserved_device_names() {
        assert_eq!(safe_filename(Some("CON"), "text/plain"), "_CON");
        assert_eq!(safe_filename(Some("nul.txt"), "text/plain"), "_nul.txt");
        assert_eq!(safe_filename(Some("com1.log"), "text/plain"), "_com1.log");
        assert_eq!(safe_filename(Some("LPT\u{b9}"), "text/plain"), "_LPT\u{b9}");
        assert_eq!(safe_filename(Some("console.txt"), "text/plain"), "console.txt");
        assert_eq!(safe_filename(Some("com10.txt"), "text/plain"), "com10.txt");
    }

    #[test]
    fn long_names_keep_the_extension() {
        let name = format!("{}.pdf", "a".repeat(500));
        let safe = safe_filename(Some(&name), "application/pdf");
        assert_eq!(safe.chars().count(), 200);
        assert!(safe.ends_with("a.pdf"));
        let name = format!("{} {}", "a".repeat(199), "b".repeat(50));
        assert_eq!(safe_filename(Some(&name), "text/plain"), "a".repeat(199));
    }
}
