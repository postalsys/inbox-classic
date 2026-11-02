//! The content type of an attachment from its file name, for the types people attach; anything else is
//! application/octet-stream, which every client offers to save

const TYPES: &[(&str, &str)] = &[
    ("7z", "application/x-7z-compressed"),
    ("avif", "image/avif"),
    ("bmp", "image/bmp"),
    ("csv", "text/csv"),
    ("doc", "application/msword"),
    (
        "docx",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ),
    ("eml", "message/rfc822"),
    ("gif", "image/gif"),
    ("gz", "application/gzip"),
    ("heic", "image/heic"),
    ("htm", "text/html"),
    ("html", "text/html"),
    ("ics", "text/calendar"),
    ("jpeg", "image/jpeg"),
    ("jpg", "image/jpeg"),
    ("json", "application/json"),
    ("m4a", "audio/mp4"),
    ("md", "text/markdown"),
    ("mov", "video/quicktime"),
    ("mp3", "audio/mpeg"),
    ("mp4", "video/mp4"),
    ("odp", "application/vnd.oasis.opendocument.presentation"),
    ("ods", "application/vnd.oasis.opendocument.spreadsheet"),
    ("odt", "application/vnd.oasis.opendocument.text"),
    ("pdf", "application/pdf"),
    ("png", "image/png"),
    ("ppt", "application/vnd.ms-powerpoint"),
    (
        "pptx",
        "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    ),
    ("rar", "application/vnd.rar"),
    ("rtf", "application/rtf"),
    ("svg", "image/svg+xml"),
    ("tar", "application/x-tar"),
    ("tif", "image/tiff"),
    ("tiff", "image/tiff"),
    ("txt", "text/plain"),
    ("vcf", "text/vcard"),
    ("wav", "audio/wav"),
    ("webp", "image/webp"),
    ("xls", "application/vnd.ms-excel"),
    (
        "xlsx",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ),
    ("xml", "application/xml"),
    ("zip", "application/zip"),
];

pub fn mime_type(filename: &str) -> &'static str {
    let extension = filename
        .rsplit_once('.')
        .map(|(_, e)| e.to_ascii_lowercase())
        .unwrap_or_default();
    TYPES
        .binary_search_by(|(e, _)| (*e).cmp(extension.as_str()))
        .map_or("application/octet-stream", |i| TYPES[i].1)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn types() {
        assert!(TYPES.windows(2).all(|w| w[0].0 < w[1].0), "sorted for the search");
        assert_eq!(mime_type("Report.PDF"), "application/pdf");
        assert_eq!(mime_type("photo.jpg"), "image/jpeg");
        assert_eq!(mime_type("program.exe"), "application/octet-stream");
        assert_eq!(mime_type("noextension"), "application/octet-stream");
    }
}
