//! What the windows of each platform take from here alike: the parts of a help topic for the platform it is shown
//! on (help.rs), and the content rules the WebKit web views (the Mac's WKWebView, Linux's WebKitGTK) block every load with, as WebView2's
//! request filter does on Windows.

/// A platform the windows run on
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Platform {
    Windows,
    Mac,
    Linux,
}

impl Platform {
    /// `windows`, `mac` or `linux`
    pub fn from_name(name: &str) -> Option<Platform> {
        match name {
            "windows" => Some(Platform::Windows),
            "mac" => Some(Platform::Mac),
            "linux" => Some(Platform::Linux),
            _ => None,
        }
    }

    pub(crate) fn name(self) -> &'static str {
        match self {
            Platform::Windows => "windows",
            Platform::Mac => "mac",
            Platform::Linux => "linux",
        }
    }

    /// The platform this was built for (Windows for anything that is neither the Mac nor Linux)
    pub fn current() -> Platform {
        if cfg!(target_os = "macos") {
            Platform::Mac
        } else if cfg!(target_os = "linux") {
            Platform::Linux
        } else {
            Platform::Windows
        }
    }
}

/// The marks around a translated passage that waits for a native review (`scripts/i18n-review.mjs` lists them); the
/// page shows the passage without them
pub(crate) const REVIEW_START: &str = "<!--review-->";
pub(crate) const REVIEW_END: &str = "<!--/review-->";

const PART_START: &str = "<!--os:";
const PART_END: &str = "<!--/os-->";

/// `html` without the parts marked for other platforms. Parts do not nest; one that is not closed runs to the end.
pub(crate) fn filter_platform(html: &str, platform: Platform) -> String {
    let mut out = String::with_capacity(html.len());
    let mut rest = html;
    while let Some(at) = rest.find(PART_START) {
        out.push_str(&rest[..at]);
        let after = &rest[at + PART_START.len()..];
        let Some(close) = after.find("-->") else {
            rest = "";
            break;
        };
        let shown = after[..close].split(',').any(|name| name.trim() == platform.name());
        let inner = &after[close + 3..];
        let (part, next) = match inner.find(PART_END) {
            Some(end) => (&inner[..end], &inner[end + PART_END.len()..]),
            None => (inner, ""),
        };
        if shown {
            out.push_str(part);
        }
        rest = next;
    }
    out.push_str(rest);
    out
}

/// The scheme the WebKit web views load the app's own documents from (`inboxclassic://preview/1`): WebKit can not
/// answer https requests itself as WebView2 does, so the documents come from a scheme of the app's
pub const DOCUMENT_SCHEME: &str = "inboxclassic";

/// The WebKit content rules of a web view (the JSON of WKContentRuleList and WebKitUserContentFilter): every load is
/// blocked but the app's own documents, the `cid:` parts of the message and `data:`, and with `allow_remote_images`
/// the pictures of the message from the internet (images only, nothing else from there). A second wall behind the
/// documents' own CSP.
pub fn webkit_content_rules(allow_remote_images: bool) -> String {
    let mut rules = vec![
        r#"{"trigger":{"url-filter":".*"},"action":{"type":"block"}}"#.to_string(),
        format!(r#"{{"trigger":{{"url-filter":"^{DOCUMENT_SCHEME}:"}},"action":{{"type":"ignore-previous-rules"}}}}"#),
        r#"{"trigger":{"url-filter":"^cid:"},"action":{"type":"ignore-previous-rules"}}"#.to_string(),
        r#"{"trigger":{"url-filter":"^data:"},"action":{"type":"ignore-previous-rules"}}"#.to_string(),
    ];
    if allow_remote_images {
        rules.push(
            r#"{"trigger":{"url-filter":"^https?://","resource-type":["image"]},"action":{"type":"ignore-previous-rules"}}"#
                .to_string(),
        );
    }
    format!("[{}]", rules.join(","))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parts_of_other_platforms_are_left_out() {
        let html = "a<!--os:windows-->W<!--/os-->b<!--os:mac,linux-->ML<!--/os-->c<!--os:linux-->L<!--/os-->d";
        assert_eq!(filter_platform(html, Platform::Windows), "aWbcd");
        assert_eq!(filter_platform(html, Platform::Mac), "abMLcd");
        assert_eq!(filter_platform(html, Platform::Linux), "abMLcLd");
        // one left open runs to the end
        assert_eq!(filter_platform("a<!--os:mac-->M", Platform::Windows), "a");
        assert_eq!(filter_platform("a<!--os:mac-->M", Platform::Mac), "aM");
    }

    #[test]
    fn review_marks_are_left_out() {
        for platform in [Platform::Windows, Platform::Mac, Platform::Linux] {
            for language in ["en", "de", "et", "es", "fr"] {
                let page = crate::help_topic("find-messages", platform, language).unwrap();
                assert!(
                    !page.contains("<!--review") && !page.contains("<!--/review"),
                    "{language}"
                );
            }
        }
    }

    #[test]
    fn the_help_of_each_platform() {
        let page = |platform| crate::help_topic("data-storage", platform, "en").unwrap();
        for platform in [Platform::Windows, Platform::Mac, Platform::Linux] {
            assert!(
                !page(platform).contains(PART_START) && !page(platform).contains(PART_END),
                "no markers left"
            );
        }
        let (windows, mac, linux) = (page(Platform::Windows), page(Platform::Mac), page(Platform::Linux));
        assert!(windows.contains("Credential Manager") && !windows.contains("~/Library"));
        assert!(!mac.contains("Credential Manager") && mac.contains("~/Library"));
        assert!(!linux.contains("Credential Manager") && !linux.contains("%LOCALAPPDATA%"));
    }

    #[test]
    fn content_rules_block_everything_but_our_own() {
        let blocked: Vec<serde_json::Value> = serde_json::from_str(&webkit_content_rules(false)).unwrap();
        assert_eq!(blocked[0]["action"]["type"], "block");
        assert_eq!(blocked[0]["trigger"]["url-filter"], ".*");
        let allowed: Vec<&str> = blocked[1..]
            .iter()
            .map(|rule| {
                assert_eq!(rule["action"]["type"], "ignore-previous-rules");
                rule["trigger"]["url-filter"].as_str().unwrap()
            })
            .collect();
        assert_eq!(allowed, ["^inboxclassic:", "^cid:", "^data:"]);
        let with_pictures: Vec<serde_json::Value> = serde_json::from_str(&webkit_content_rules(true)).unwrap();
        let last = with_pictures.last().unwrap();
        assert_eq!(last["trigger"]["url-filter"], "^https?://");
        assert_eq!(last["trigger"]["resource-type"], serde_json::json!(["image"]));
    }
}

/// A page of the reading pane that is not a message: no message selected, the message downloading, or why it could not
/// be. `title` and `detail` are text (escaped here); with `busy` a spinner turns above them, drawn and moved by CSS
/// alone, as the pane runs no script. The same light page as the messages, under the same CSP.
pub fn status_page(title: &str, detail: &str, busy: bool) -> String {
    let spinner = if busy {
        "<div class=\"spin\" aria-hidden=\"true\"></div>"
    } else {
        ""
    };
    let detail = if detail.is_empty() {
        String::new()
    } else {
        format!("<p class=\"detail\">{}</p>", crate::editor::text(detail))
    };
    let (scheme, dark) = if crate::dark::dark() {
        ("light dark", crate::dark::PAGE_DARK)
    } else {
        ("light", "")
    };
    format!(
        "<!doctype html><html><head><meta charset=\"utf-8\">\
         <meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; style-src 'unsafe-inline'\">\
         <meta name=\"color-scheme\" content=\"{scheme}\"><style>\
         html{{background:#fff}}body{{margin:0;padding:48px 24px;text-align:center;font:13px system-ui,-apple-system,'Segoe UI',sans-serif;color:#333}}\
         .title{{font-size:14px;font-weight:600;margin:0 0 6px}}.detail{{margin:0 auto;max-width:420px;line-height:1.45;color:#666}}\
         .spin{{width:22px;height:22px;margin:0 auto 14px;border:2px solid #d8d8d8;border-top-color:#777;border-radius:50%;\
         animation:spin .9s linear infinite}}@keyframes spin{{to{{transform:rotate(360deg)}}}}\
         @media (prefers-reduced-motion:reduce){{.spin{{animation-duration:3s}}}}{dark}\
         </style></head><body role=\"status\">{spinner}<p class=\"title\">{}</p>{detail}</body></html>",
        crate::editor::text(title)
    )
}

#[cfg(test)]
mod status_tests {
    use super::*;

    #[test]
    fn a_status_page_is_text_only() {
        let page = status_page("Downloading <b>", "it & more", true);
        assert!(page.contains("Downloading &lt;b&gt;") && page.contains("it &amp; more"));
        assert!(page.contains("class=\"spin\"") && !page.contains("<script"));
        assert!(page.contains("default-src 'none'"));
        let quiet = status_page("There is no message selected.", "", false);
        assert!(!quiet.contains("class=\"spin\"") && !quiet.contains("class=\"detail\""));
    }
}
