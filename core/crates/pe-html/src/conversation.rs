//! The page of a conversation in the reading pane: a line of the app's own words for each message (who, when, the
//! first words, the folder it is filed in), and each open message a document of its own in a frame under its line.
//!
//! Built as the page of a message with signed or encrypted parts is ([`crate::secure_page`]): the page holds no markup
//! of any message, so no message can style, cover or read another, or the lines, which are the core's. Each open
//! message's document is complete, sanitized and with its own policy, served at `part-N` beside the page (N its place
//! in the conversation) in a sandboxed frame the app sizes to it ([`crate::MEASURE_SCRIPT`]). A line is a link
//! ([`CONVERSATION_LINK`]): the app asks the core to open or fold that message, and shows the page again.

use crate::editor;
use crate::secure::{framed_head, part_frame};

/// The link of a message's line: `inboxclassic:conversation-N`, N its place in the conversation
pub const CONVERSATION_LINK: &str = "inboxclassic:conversation-";

/// The link that shows the earlier messages of a long conversation, whose lines are left out until it is clicked
pub const CONVERSATION_EARLIER_LINK: &str = "inboxclassic:conversation-earlier";

/// Which message's line a link is, if it is one
pub fn conversation_link(uri: &str) -> Option<usize> {
    uri.strip_prefix(CONVERSATION_LINK)?.parse().ok()
}

/// Whether a link is the one that shows a long conversation's earlier messages
pub fn is_conversation_earlier_link(uri: &str) -> bool {
    uri == CONVERSATION_EARLIER_LINK
}

/// One message of the conversation, in the core's words
pub struct ConversationLine<'a> {
    /// Who sent it ("Bob Harris"; the user's own name for their own)
    pub from: &'a str,
    /// When, as the list writes it
    pub when: &'a str,
    /// Folded: its first words; open: who it went to ("to Ann, Carol")
    pub words: &'a str,
    /// The folder it is filed in, when not the one the conversation was opened from; empty otherwise
    pub folder: &'a str,
    /// Words on its state, after the folder: "Draft", "Encrypted, opens by itself", "Downloading…"; empty for none
    pub note: &'a str,
    pub unread: bool,
    /// Its document is served at `part-N` and shown under its line
    pub open: bool,
    /// Reply, Forward and Print act on it: its frame has an edge
    pub focus: bool,
}

/// The page of `lines`, in their order, the place of each its N. `earlier`: the words of the link that shows the
/// lines left out before `lines[0]` (None when none are), and the place of the first line shown. `remote_images`:
/// some open message may load pictures from the internet (each document's own policy still decides for it).
pub fn conversation_page(
    lines: &[ConversationLine],
    first: usize,
    earlier: Option<&str>,
    remote_images: bool,
) -> String {
    let head = framed_head(remote_images);
    let mut body = String::new();
    if let Some(words) = earlier {
        body.push_str(&format!(
            "<a class=\"pe-e\" href=\"{CONVERSATION_EARLIER_LINK}\">{}</a>",
            editor::text(words)
        ));
    }
    for (offset, line) in lines.iter().enumerate() {
        let index = first + offset;
        let mut classes = String::from("pe-m");
        for (on, class) in [(line.open, " pe-o"), (line.focus, " pe-f"), (line.unread, " pe-u")] {
            if on {
                classes.push_str(class);
            }
        }
        let mut head = format!(
            "<span class=\"pe-n\">{}</span><span class=\"pe-t\">{}</span>",
            editor::text(line.from),
            editor::text(line.when)
        );
        for (words, class) in [(line.folder, "pe-g"), (line.note, "pe-g")] {
            if !words.is_empty() {
                head.push_str(&format!("<span class=\"{class}\">{}</span>", editor::text(words)));
            }
        }
        head.push_str(&format!("<span class=\"pe-w\">{}</span>", editor::text(line.words)));
        body.push_str(&format!(
            "<section class=\"{classes}\"><a class=\"pe-h\" href=\"{CONVERSATION_LINK}{index}\">{head}</a>"
        ));
        if line.open {
            body.push_str(&part_frame(index, line.from));
        }
        body.push_str("</section>");
    }
    format!(
        "{head}<style>\
         html{{background:Canvas}}body{{margin:6px 8px;font:10pt Arial,sans-serif;--l:#c8ccd2;--a:#1f5fae;--h:#f3f5f8}}\
         .pe-m{{border:1px solid var(--l);border-radius:5px;margin:0 0 6px;overflow:hidden}}\
         .pe-f{{border:2px solid var(--a)}}\
         .pe-h{{display:flex;flex-wrap:wrap;align-items:baseline;gap:2px 10px;padding:5px 10px;color:CanvasText;\
         text-decoration:none}}\
         .pe-o .pe-h{{background:var(--h);border-bottom:1px solid var(--l)}}\
         .pe-h:hover .pe-n{{text-decoration:underline}}\
         .pe-n{{font-weight:bold}}\
         .pe-u .pe-n::before{{content:'';display:inline-block;width:7px;height:7px;border-radius:50%;\
         background:var(--a);margin-right:5px;vertical-align:1px}}\
         .pe-t{{color:GrayText;font-size:9pt}}\
         .pe-g{{font-size:8pt;border:1px solid var(--l);border-radius:3px;padding:0 5px;color:GrayText}}\
         .pe-w{{flex:1 1 12em;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:GrayText}}\
         .pe-e{{display:block;margin:0 0 6px;padding:4px 10px;color:var(--a)}}\
         .pe-d{{display:block;width:100%;border:0;height:120px}}\
         @media (prefers-color-scheme:dark){{body{{--l:#4a4f57;--a:#7fb0f0;--h:#262a30}}}}\
         </style></head><body>{body}</body></html>"
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    fn line<'a>(from: &'a str, open: bool, focus: bool) -> ConversationLine<'a> {
        ConversationLine {
            from,
            when: "11:04",
            words: "The lake <b>it</b> is.",
            folder: "",
            note: "",
            unread: false,
            open,
            focus,
        }
    }

    #[test]
    fn lines_are_ours_and_open_messages_are_documents_of_their_own() {
        let lines = [
            line("Dave", false, false),
            ConversationLine {
                folder: "Sent Items",
                ..line("You", false, false)
            },
            ConversationLine {
                unread: true,
                ..line("Bob \"Harris\" <b@x>", true, true)
            },
        ];
        let page = conversation_page(&lines, 0, None, false);
        // the words escaped as text, nothing of any message in the page
        assert!(page.contains("The lake &lt;b&gt;it&lt;/b&gt; is."));
        assert!(page.contains("Bob \"Harris\" &lt;b@x&gt;"));
        assert!(page.contains("title=\"Bob &quot;Harris&quot; &lt;b@x&gt;\""));
        assert!(page.contains("Sent Items"));
        // one frame, for the open message, at its place; each line links to its own place
        assert_eq!(page.matches("<iframe").count(), 1);
        assert!(page.contains("src=\"part-2\""));
        for index in 0..3 {
            assert!(page.contains(&format!("href=\"inboxclassic:conversation-{index}\"")));
        }
        assert!(page.contains("class=\"pe-m pe-o pe-f pe-u\""));
        // never scripts, popups, forms or a navigation of the top page without the user's click
        for flag in ["allow-scripts", "allow-popups", "allow-forms", "allow-top-navigation\""] {
            assert!(!page.contains(flag), "{flag}");
        }
        assert!(page.contains("default-src 'none'; frame-src 'self'; img-src data:;"));
        assert!(!page.contains("<script"));
    }

    #[test]
    fn a_long_conversation_starts_with_its_later_lines() {
        let lines = [line("Carol", false, false), line("Bob", true, true)];
        let page = conversation_page(&lines, 30, Some("Show 30 earlier messages"), true);
        assert!(page.contains("href=\"inboxclassic:conversation-earlier\">Show 30 earlier messages</a>"));
        // the places count from the first line shown
        assert!(page.contains("href=\"inboxclassic:conversation-30\""));
        assert!(page.contains("src=\"part-31\""));
        assert!(page.contains("img-src data: http: https:;"));
    }

    #[test]
    fn links_are_read_back() {
        assert_eq!(conversation_link("inboxclassic:conversation-7"), Some(7));
        assert_eq!(conversation_link("inboxclassic:conversation-earlier"), None);
        assert_eq!(conversation_link("inboxclassic:conversation-"), None);
        assert_eq!(conversation_link("inboxclassic:part-7"), None);
        assert!(is_conversation_earlier_link(CONVERSATION_EARLIER_LINK));
        assert!(!is_conversation_earlier_link("inboxclassic:conversation-1"));
    }
}
