//! What the windows of each platform take from here alike: the help, filtered for the platform it is shown on, and
//! the content rules the WebKit web views (the Mac's WKWebView, Linux's WebKitGTK) block every load with, as WebView2's
//! request filter does on Windows.

/// The user help, one source for every platform: `<!--os:mac-->` (or `os:windows,linux`, any list) starts a part only
/// those platforms show and `<!--/os-->` ends it
const HELP: &str = include_str!("help.html");

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

    fn name(self) -> &'static str {
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

/// The help page for `platform`: the parts of other platforms left out, and on the Mac the keys named as its keyboard
/// names them (Ctrl is Command there, Alt is Option)
pub fn help_page(platform: Platform) -> String {
    let filtered = filter_platform(HELP, platform);
    match platform {
        Platform::Mac => filtered
            .replace("<kbd>Ctrl</kbd>", "<kbd>\u{2318}</kbd>")
            .replace("<kbd>Alt</kbd>", "<kbd>\u{2325}</kbd>")
            .replace("<kbd>Shift</kbd>", "<kbd>\u{21E7}</kbd>")
            .replace("<kbd>Del</kbd>", "<kbd>\u{232B}</kbd>")
            .replace("<kbd>Delete</kbd>", "<kbd>\u{232B}</kbd>"),
        _ => filtered,
    }
}

const PART_START: &str = "<!--os:";
const PART_END: &str = "<!--/os-->";

/// `html` without the parts marked for other platforms. Parts do not nest; one that is not closed runs to the end.
fn filter_platform(html: &str, platform: Platform) -> String {
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
    fn the_help_of_each_platform() {
        for platform in [Platform::Windows, Platform::Mac, Platform::Linux] {
            let page = help_page(platform);
            assert!(page.contains("<title>Inbox Classic Help</title>"));
            assert!(
                !page.contains(PART_START) && !page.contains(PART_END),
                "no markers left"
            );
        }
        let mac = help_page(Platform::Mac);
        assert!(!mac.contains("<kbd>Ctrl</kbd>") && mac.contains("<kbd>\u{2318}</kbd>"));
        assert!(!mac.contains("Credential Manager") && !mac.contains("Explorer"));
        let linux = help_page(Platform::Linux);
        assert!(linux.contains("<kbd>Ctrl</kbd>"));
        assert!(!linux.contains("Credential Manager") && !linux.contains("%LOCALAPPDATA%"));
        let windows = help_page(Platform::Windows);
        assert!(windows.contains("Credential Manager") && windows.contains("%LOCALAPPDATA%"));
        assert!(!windows.contains("keychain") && !windows.contains("~/Library"));
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
