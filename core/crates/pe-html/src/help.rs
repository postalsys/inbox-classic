//! The user help: one topic a file (`help/<language>/<id>.html`, the markup of `help/FORMAT.md`), ordered into
//! sections by `help/topics.toml`. Here a topic becomes what each platform shows: its keys from `core/commands.toml`
//! as the platform writes them, its controls named by the catalogs of the language, the parts of other platforms left
//! out, the links to other topics with their titles. The apps' help viewers ask for the contents, a topic's page and
//! a search; `help_export` writes the pages for the Mac's Help Book, for Yelp and for the website.

use crate::editor::text as escape;
use crate::platform::{Platform, REVIEW_END, REVIEW_START, filter_platform};
use base64::Engine as _;

include!(concat!(env!("OUT_DIR"), "/help.rs"));

/// A link to a topic in a page of the app's help viewers: `topic:find-messages`, which the viewer opens itself
pub const HELP_TOPIC_SCHEME: &str = "topic:";

/// A topic as the contents and a search list it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HelpTopic {
    pub id: String,
    pub title: String,
    pub summary: String,
}

/// A section of the contents with its topics
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HelpSection {
    pub id: String,
    pub title: String,
    pub topics: Vec<HelpTopic>,
}

/// Where a page goes: the app's viewer (links `topic:`, pictures inline), or files (links `<id>.html`, pictures in
/// `pictures/`) for the Mac's Help Book, Yelp or the website, which also get the contents
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HelpTarget {
    Viewer,
    HelpBook,
    Yelp,
    Web,
}

/// The topic a window's help opens (`account-form`, `options`, `agents`; see help/topics.toml), the main window's for
/// one it does not know
pub fn help_context(window: &str) -> &'static str {
    CONTEXT
        .iter()
        .find(|(name, _)| *name == window)
        .or_else(|| CONTEXT.iter().find(|(name, _)| *name == "main"))
        .map_or("main-window", |(_, topic)| topic)
}

/// The topic `id` from a link of a help page (`topic:find-messages`), None for any other link
pub fn help_link_topic(url: &str) -> Option<&str> {
    url.strip_prefix(HELP_TOPIC_SCHEME)
        .filter(|id| source("en", id).is_some())
}

/// The contents: the sections in order with their topics' titles and summaries
pub fn help_contents(platform: Platform, language: &str) -> Vec<HelpSection> {
    SECTIONS
        .iter()
        .map(|(id, topics)| HelpSection {
            id: id.to_string(),
            title: words(language, &format!("help-section-{id}")),
            topics: topics
                .iter()
                .filter_map(|topic| entry(topic, platform, language))
                .collect(),
        })
        .collect()
}

/// The page of the topic `id` for the app's help viewer, None for no such topic
pub fn help_topic(id: &str, platform: Platform, language: &str) -> Option<String> {
    let body = topic_body(id, platform, language, HelpTarget::Viewer)?;
    Some(page(
        &body,
        &title_of(&body),
        platform,
        language,
        HelpTarget::Viewer,
        "",
        id,
    ))
}

/// The topics whose text has every word of `query`, the best first: a word in the title counts most, then in the
/// summary, then in the text
pub fn help_search(query: &str, platform: Platform, language: &str) -> Vec<HelpTopic> {
    let words: Vec<String> = query.split_whitespace().map(str::to_lowercase).collect();
    if words.is_empty() {
        return Vec::new();
    }
    let mut found: Vec<(usize, HelpTopic)> = index(platform, language)
        .iter()
        .filter_map(|indexed| {
            let topic = &indexed.topic;
            let (title, summary) = (topic.title.to_lowercase(), topic.summary.to_lowercase());
            let mut score = 0;
            for word in &words {
                if !indexed.text.contains(word.as_str()) {
                    return None;
                }
                score += 5 * usize::from(title.contains(word.as_str()))
                    + 3 * usize::from(summary.contains(word.as_str()))
                    + indexed.text.matches(word.as_str()).count().min(5);
            }
            Some((score, topic.clone()))
        })
        .collect();
    found.sort_by_key(|(score, _)| std::cmp::Reverse(*score));
    found.into_iter().map(|(_, topic)| topic).collect()
}

/// Every page of the help for `target` (not the viewer): `index.html` with the contents, a page a topic, and the
/// pictures they show, each with its path
pub fn help_export(platform: Platform, language: &str, target: HelpTarget) -> Vec<(String, Vec<u8>)> {
    let contents = help_contents(platform, language);
    let index = contents_html(&contents, target);
    let title = words(language, "help-title");
    let mut files = vec![(
        "index.html".to_string(),
        page(
            &format!("<h1>{}</h1>\n{index}", escape(&title)),
            &title,
            platform,
            language,
            target,
            "",
            "index",
        )
        .into_bytes(),
    )];
    let mut pictures = Vec::new();
    for id in all_topics() {
        let Some(body) = topic_body(id, platform, language, target) else {
            continue;
        };
        pictures.extend(
            PICTURES
                .iter()
                .filter(|(p, name, _)| *p == platform.name() && body.contains(&format!("pictures/{name}.png"))),
        );
        let page = page(&body, &title_of(&body), platform, language, target, &index, id);
        files.push((format!("{id}.html"), page.into_bytes()));
    }
    pictures.dedup_by_key(|(_, name, _)| *name);
    for (_, name, bytes) in pictures {
        files.push((format!("pictures/{name}.png"), bytes.to_vec()));
    }
    files
}

fn all_topics() -> impl Iterator<Item = &'static str> {
    SECTIONS.iter().flat_map(|(_, topics)| topics.iter().copied())
}

/// The source of a topic in `language`, the English one for a topic not translated yet
fn source(language: &str, id: &str) -> Option<&'static str> {
    let find = |language: &str| {
        TOPICS
            .iter()
            .find(|(l, i, _)| *l == language && *i == id)
            .map(|(_, _, html)| *html)
    };
    find(language).or_else(|| find("en"))
}

/// A message of the catalog as the help names it: without its access key's `&` and a menu item's "...", escaped
fn words(language: &str, id: &str) -> String {
    let text = pe_i18n::message_in(language, id).unwrap_or_else(|| id.to_string());
    let text = text.replace("&&", "\u{0}").replace('&', "").replace('\u{0}', "&");
    // GTK's labels mark their access key with _
    let text = if id.starts_with("gtk-") {
        text.replace('_', "")
    } else {
        text
    };
    escape(
        text.trim_end_matches("...")
            .trim_end_matches('\u{2026}')
            .trim_end_matches(':')
            .trim_end(),
    )
}

/// A topic as the contents and the search read it: its title and summary, and its words in lower case
struct Indexed {
    topic: HelpTopic,
    text: String,
}

/// Every topic of `platform` in `language` read once: the contents and each search (Linux's on every key typed) look
/// them up here rather than making each page again
fn index(platform: Platform, language: &str) -> std::sync::Arc<Vec<Indexed>> {
    type Indexes = Vec<((Platform, String), std::sync::Arc<Vec<Indexed>>)>;
    static INDEXES: std::sync::OnceLock<std::sync::Mutex<Indexes>> = std::sync::OnceLock::new();
    let mut indexes = INDEXES
        .get_or_init(Default::default)
        .lock()
        .unwrap_or_else(|e| e.into_inner());
    if let Some((_, made)) = indexes.iter().find(|(key, _)| key.0 == platform && key.1 == language) {
        return made.clone();
    }
    // the website's form of a page: its pictures named, not encoded, which adds nothing to read
    let made: Vec<Indexed> = all_topics()
        .filter_map(|id| {
            let body = topic_body(id, platform, language, HelpTarget::Web)?;
            let topic = HelpTopic {
                id: id.to_string(),
                title: title_of(&body),
                summary: between(&body, "<p class=\"summary\">", "</p>")
                    .map(plain_text)
                    .unwrap_or_default(),
            };
            Some(Indexed {
                topic,
                text: plain_text(&body).to_lowercase(),
            })
        })
        .collect();
    let made = std::sync::Arc::new(made);
    indexes.push(((platform, language.to_string()), made.clone()));
    made
}

/// A topic's title and summary for the contents
fn entry(id: &str, platform: Platform, language: &str) -> Option<HelpTopic> {
    index(platform, language)
        .iter()
        .find(|indexed| indexed.topic.id == id)
        .map(|indexed| indexed.topic.clone())
}

fn title_of(body: &str) -> String {
    between(body, "<h1>", "</h1>").map(plain_text).unwrap_or_default()
}

fn between<'a>(text: &'a str, start: &str, end: &str) -> Option<&'a str> {
    let from = text.find(start)? + start.len();
    Some(&text[from..from + text[from..].find(end)?])
}

/// The text of some markup: its tags out, its entities read, its spaces one
fn plain_text(html: &str) -> String {
    let mut text = String::with_capacity(html.len());
    let mut in_tag = false;
    for c in html.chars() {
        match c {
            '<' => in_tag = true,
            '>' => {
                in_tag = false;
                text.push(' ');
            }
            _ if !in_tag => text.push(c),
            _ => {}
        }
    }
    let text = text
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&amp;", "&");
    text.split_whitespace().collect::<Vec<_>>().join(" ")
}

/// The topic `id` as the platform shows it: its parts, keys, words, links and pictures filled in
fn topic_body(id: &str, platform: Platform, language: &str, target: HelpTarget) -> Option<String> {
    let html = filter_platform(source(language, id)?, platform)
        .replace(REVIEW_START, "")
        .replace(REVIEW_END, "");
    let html = fill(&html, "<kbd data-command=\"", "\"></kbd>", |command| {
        command_key(command, platform, language)
    });
    let html = fill(&html, "<b data-text=\"", "\"></b>", |message| {
        format!("<b>{}</b>", words(language, message))
    });
    let html = fill(&html, "<div data-generate=\"", "\"></div>", |what| match what {
        "shortcuts" => shortcuts_table(platform, language),
        _ => String::new(),
    });
    let html = fill(&html, "<a href=\"topic:", "\"></a>", |topic| {
        let title = source(language, topic)
            .and_then(|html| between(html, "<h1>", "</h1>"))
            .map(plain_text);
        format!(
            "<a href=\"topic:{topic}\">{}</a>",
            escape(&title.unwrap_or_else(|| topic.to_string()))
        )
    });
    let html = fill(&html, "<img src=\"picture:", ">", |rest| {
        picture(rest, platform, target)
    });
    let html = fill(&html, "href=\"topic:", "\"", |topic| {
        format!("href=\"{}\"", topic_link(topic, target))
    });
    Some(old_keys(&html, platform, language))
}

/// Where a link to the topic `id` goes: the viewer opens `topic:` itself, the exported pages are files
fn topic_link(id: &str, target: HelpTarget) -> String {
    match target {
        HelpTarget::Viewer => format!("{HELP_TOPIC_SCHEME}{id}"),
        _ => format!("{id}.html"),
    }
}

/// `html` with each `start...end` made by `make` from what is between them
fn fill(html: &str, start: &str, end: &str, make: impl Fn(&str) -> String) -> String {
    let mut out = String::with_capacity(html.len());
    let mut rest = html;
    while let Some(at) = rest.find(start) {
        out.push_str(&rest[..at]);
        let inner = &rest[at + start.len()..];
        let Some(close) = inner.find(end) else {
            out.push_str(&rest[at..]);
            return out;
        };
        out.push_str(&make(&inner[..close]));
        rest = &inner[close + end.len()..];
    }
    out.push_str(rest);
    out
}

/// A screenshot of the UI tests: `rest` is what follows `<img src="picture:` to the end of the tag
fn picture(rest: &str, platform: Platform, target: HelpTarget) -> String {
    let name = rest.split('"').next().unwrap_or_default();
    let attributes = rest[name.len()..].trim_start_matches('"');
    let Some((_, _, bytes)) = PICTURES.iter().find(|(p, n, _)| *p == platform.name() && *n == name) else {
        return String::new();
    };
    let source = match target {
        HelpTarget::Viewer => {
            format!(
                "data:image/png;base64,{}",
                base64::engine::general_purpose::STANDARD.encode(bytes)
            )
        }
        _ => format!("pictures/{name}.png"),
    };
    format!(
        "<img class=\"picture\" src=\"{source}\"{}>",
        attributes.trim_end_matches('/')
    )
}

/// The key of the command `id` as the platform writes it (Ctrl+Shift+F, Strg in German; ⇧⌘F on the Mac), empty for
/// a command without one there
fn command_key(id: &str, platform: Platform, language: &str) -> String {
    let Some((_, _, key, mac, linux)) = COMMANDS.iter().find(|(command, ..)| *command == id) else {
        return String::new();
    };
    let spec = match platform {
        Platform::Windows => key,
        Platform::Mac => mac,
        Platform::Linux => linux,
    };
    key_text(spec, platform, language)
}

fn key_text(spec: &str, platform: Platform, language: &str) -> String {
    if spec.is_empty() {
        return String::new();
    }
    let parts: Vec<&str> = spec.split('+').collect();
    let (key, modifiers) = parts.split_last().unwrap_or((&"", &[]));
    if platform == Platform::Mac {
        let has = |name: &str| modifiers.contains(&name);
        // ⇧/ is ?, as the Mac's menus write it
        let shifted_slash = has("Shift") && *key == "/";
        let mut text = String::new();
        if has("Alt") {
            text.push('\u{2325}');
        }
        if has("Shift") && !shifted_slash {
            text.push('\u{21E7}');
        }
        if has("Mod") {
            text.push('\u{2318}');
        }
        text.push_str(match *key {
            "Delete" => "\u{232B}",
            "Enter" => "\u{21A9}",
            "/" if shifted_slash => "?",
            other => other,
        });
        return format!("<kbd>{}</kbd>", escape(&text));
    }
    let name = |part: &str| match part {
        "Mod" => words(language, "key-ctrl"),
        "Alt" => words(language, "key-alt"),
        "Shift" => words(language, "key-shift"),
        "Delete" => words(language, "key-del"),
        "Enter" => words(language, "key-enter"),
        other => escape(other),
    };
    parts
        .iter()
        .map(|part| format!("<kbd>{}</kbd>", name(part)))
        .collect::<Vec<_>>()
        .join("+")
}

/// Keys written by hand (`<kbd>Ctrl</kbd>`) as the keyboard of the language or the Mac names them
fn old_keys(html: &str, platform: Platform, language: &str) -> String {
    if platform == Platform::Mac {
        return html
            .replace("<kbd>Ctrl</kbd>", "<kbd>\u{2318}</kbd>")
            .replace("<kbd>Alt</kbd>", "<kbd>\u{2325}</kbd>")
            .replace("<kbd>Shift</kbd>", "<kbd>\u{21E7}</kbd>")
            .replace("<kbd>Delete</kbd>", "<kbd>\u{232B}</kbd>")
            .replace("<kbd>Enter</kbd>", "<kbd>\u{21A9}</kbd>")
            .replace("<kbd>Return</kbd>", "<kbd>\u{21A9}</kbd>");
    }
    let key = |id: &str| format!("<kbd>{}</kbd>", words(language, id));
    html.replace("<kbd>Ctrl</kbd>", &key("key-ctrl"))
        .replace("<kbd>Alt</kbd>", &key("key-alt"))
        .replace("<kbd>Shift</kbd>", &key("key-shift"))
        .replace("<kbd>Delete</kbd>", &key("key-del"))
        .replace("<kbd>Enter</kbd>", &key("key-enter"))
}

/// Key names a translation must not write itself: the topics name keys in English (`<kbd>Shift</kbd>`), which the
/// page then writes for the keyboard of the language and the platform
#[cfg(test)]
const LOCAL_KEYS: &[&str] = &[
    "Strg", "Umschalt", "Entf", "Eingabe", "Mayús", "Supr", "Intro", "Entrar", "Maj", "Suppr", "Entrée",
];

/// The catalog message a platform's menu names the command `id` by: the Mac's and Linux's own words for Quit,
/// Settings and Preferences, `cmd-<id>` for the rest
fn command_label(id: &str, platform: Platform) -> String {
    match (platform, id) {
        (Platform::Mac, "exit") => "mac-quit".into(),
        (Platform::Mac, "options") => "mac-settings".into(),
        (Platform::Mac, "help") => "ui-help-title".into(),
        (Platform::Linux, "exit") => "gtk-quit".into(),
        (Platform::Linux, "options") => "gtk-preferences".into(),
        _ => format!("cmd-{}", id.replace('_', "-")),
    }
}

/// Every command with a key on the platform, by menu, as a table
fn shortcuts_table(platform: Platform, language: &str) -> String {
    let mut html = String::new();
    for menu in ["app", "file", "edit", "view", "message", "tools", "help"] {
        let rows: Vec<String> = COMMANDS
            .iter()
            .filter(|(id, m, ..)| menu_of(id, m, platform) == menu)
            .filter_map(|(id, ..)| {
                let key = command_key(id, platform, language);
                let label = words(language, &command_label(id, platform));
                (!key.is_empty()).then(|| format!("<tr><td>{label}</td><td>{key}</td></tr>"))
            })
            .collect();
        if rows.is_empty() {
            continue;
        }
        // the Mac's app menu has the app's name
        let title = match menu {
            "app" => "Inbox Classic".to_string(),
            _ => words(language, &format!("menu-{menu}")),
        };
        html.push_str(&format!(
            "<h2>{title}</h2>\n<table>\n<tr><th>{}</th><th>{}</th></tr>\n{}\n</table>\n",
            words(language, "help-column-command"),
            words(language, "help-column-keys"),
            rows.join("\n")
        ));
    }
    html
}

/// The menu a command is in on a platform: on the Mac Quit and Settings are in the app's menu
fn menu_of<'a>(id: &str, menu: &'a str, platform: Platform) -> &'a str {
    match (platform, id) {
        (Platform::Mac, "exit" | "options") => "app",
        _ => menu,
    }
}

/// The contents as a list of sections and links, for the exported pages
fn contents_html(contents: &[HelpSection], target: HelpTarget) -> String {
    let mut html = String::from("<nav class=\"contents\">\n");
    for section in contents {
        html.push_str(&format!("<h2>{}</h2>\n<ul>\n", section.title));
        for topic in &section.topics {
            html.push_str(&format!(
                "<li><a href=\"{}\">{}</a></li>\n",
                topic_link(&topic.id, target),
                escape(&topic.title)
            ));
        }
        html.push_str("</ul>\n");
    }
    html.push_str("</nav>\n");
    html
}

/// A whole page: the topic in the platform's style, for the target; the exported topics with a way back to the
/// contents (and on the website, the contents beside them)
fn page(
    body: &str,
    title: &str,
    platform: Platform,
    language: &str,
    target: HelpTarget,
    contents: &str,
    anchor: &str,
) -> String {
    let csp = match target {
        HelpTarget::Viewer => "default-src 'none'; style-src 'unsafe-inline'; img-src data:",
        _ => "default-src 'none'; style-src 'unsafe-inline'; img-src 'self'",
    };
    let help = words(language, "help-title");
    let (head, around) = match target {
        HelpTarget::Viewer => (String::new(), (String::new(), String::new())),
        HelpTarget::HelpBook => (
            {
                // the book's title on its first page only; each topic's summary for Help Viewer's search results
                let title = match anchor {
                    "index" => format!("<meta name=\"AppleTitle\" content=\"{help}\">\n"),
                    _ => String::new(),
                };
                let summary = between(body, "<p class=\"summary\">", "</p>")
                    .map(plain_text)
                    .unwrap_or_default();
                format!(
                    "{title}<meta name=\"description\" content=\"{}\">\n",
                    escape(&summary).replace('"', "&quot;")
                )
            },
            (home_link(&help, anchor), String::new()),
        ),
        HelpTarget::Yelp => (String::new(), (home_link(&help, anchor), String::new())),
        HelpTarget::Web => (
            String::new(),
            (
                match anchor {
                    "index" => format!("{}<div class=\"web\"><main>\n", web_bar(platform, language, anchor)),
                    _ => format!(
                        "{}<div class=\"web\"><nav class=\"side\">{}</nav><main>\n",
                        web_bar(platform, language, anchor),
                        contents.replace(
                            &format!("href=\"{anchor}.html\""),
                            &format!("href=\"{anchor}.html\" aria-current=\"page\"")
                        )
                    ),
                },
                "</main></div>\n".to_string(),
            ),
        ),
    };
    // the Help Book's anchor of the page, which the app opens with openHelpAnchor
    let anchor = match target {
        HelpTarget::HelpBook if !anchor.is_empty() => format!("<a name=\"{anchor}\"></a>\n"),
        _ => String::new(),
    };
    format!(
        "<!doctype html>\n<html lang=\"{language}\">\n<head>\n<meta charset=\"utf-8\">\n\
         <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n\
         <meta http-equiv=\"Content-Security-Policy\" content=\"{csp}\">\n{head}<title>{}</title>\n<style>{}</style>\n\
         </head>\n<body class=\"{}\">\n{}{anchor}{body}{}</body>\n</html>\n",
        escape(title),
        style(platform) + if target == HelpTarget::Web { WEB_STYLE } else { "" },
        platform.name(),
        around.0,
        around.1
    )
}

/// The link back to the contents at the top of a page of the Help Book or Yelp, none on the contents themselves
fn home_link(help: &str, page: &str) -> String {
    match page {
        "index" => String::new(),
        _ => format!("<p class=\"home\"><a href=\"index.html\">{help}</a></p>\n"),
    }
}

/// The bar over a page of the website's help (help/<language>/<platform>/<page>.html): the homepage, and the same page
/// for the other platforms and in the other languages
fn web_bar(platform: Platform, language: &str, page: &str) -> String {
    let file = format!("{page}.html");
    let platforms = [
        (Platform::Windows, "Windows"),
        (Platform::Mac, "Mac"),
        (Platform::Linux, "Linux"),
    ]
    .iter()
    .map(|(other, name)| match *other == platform {
        true => format!("<b>{name}</b>"),
        false => format!("<a href=\"../{}/{file}\">{name}</a>", other.name()),
    })
    .collect::<Vec<_>>()
    .join(" ");
    let languages = pe_i18n::LANGUAGES
        .iter()
        .map(|(code, name)| match *code == language {
            true => format!("<b>{name}</b>"),
            false => format!(
                "<a href=\"../../{code}/{}/{file}\" hreflang=\"{code}\">{name}</a>",
                platform.name()
            ),
        })
        .collect::<Vec<_>>()
        .join(" ");
    format!(
        "<header class=\"bar\"><a class=\"brand\" href=\"/\">Inbox Classic</a>\
         <span class=\"platforms\">{platforms}</span><span class=\"languages\">{languages}</span></header>\n"
    )
}

/// The website's help in the homepage's look: its colors and type, the page centered, the contents beside the topic
/// as the reader scrolls (inboxclassic.com/help)
const WEB_STYLE: &str = "body.windows,body.mac,body.linux{font:16px/1.6 system-ui,-apple-system,'Segoe UI',sans-serif;\
     margin:0;background:#f7f7fb;color:#1f2330}header.bar{max-width:1180px;margin:0 auto;padding:14px 24px;\
     border-bottom:1px solid #e3e3ee}header.bar .brand{color:#3d4aa8;font-size:1.1em}header.bar a{color:#3d4aa8}\
     .web{max-width:1180px;margin:0 auto;padding:24px}.web main{background:#fff;border-radius:12px;padding:28px 36px;\
     box-shadow:0 1px 3px rgba(20,20,60,.08)}.web .side{position:sticky;top:16px;align-self:flex-start;\
     max-height:calc(100vh - 32px);overflow:auto}.web .side a{color:#30395e;text-decoration:none}\
     .web .side a:hover,.web main a{color:#3d4aa8}h1,h2{color:#1f2330}h2{border-bottom:none}\
     aside.note,aside.warning{background:#f1f2fb;border:1px solid #e0e2f5;border-radius:10px}\
     @media(prefers-color-scheme:dark){body.windows,body.mac,body.linux{background:#14151c;color:#e6e7ef}\
     .web main{background:#1d1f29;box-shadow:none}header.bar{border-color:#2c2f3d}.web .side a{color:#c5c9e6}\
     h1,h2{color:#e6e7ef}aside.note,aside.warning{background:#232637;border-color:#30344a}\
     header.bar a,header.bar .brand,.web main a,.web .side a:hover{color:#9aa6ff}}";

/// The page's style: Tahoma and the classic colors on Windows, the system's font and colors (light and dark) on the
/// Mac and Linux; a line of about 75 characters on all
fn style(platform: Platform) -> String {
    let platform_style = match platform {
        Platform::Windows => {
            "body{font:10pt Tahoma,Arial,sans-serif;color:#000;background:#fff}\
             h1,h2{color:#036}h2{border-bottom:1px solid #9ab}a{color:#03c}\
             aside.note,aside.warning{background:#ffffe1;border:1px solid #c9c9a0}kbd{background:#f4f4f4;border-color:#999}"
        }
        Platform::Mac => {
            ":root{color-scheme:light dark}\
             body{font:13px -apple-system,BlinkMacSystemFont,sans-serif;color:CanvasText;background:Canvas}\
             a{color:LinkText}aside.note,aside.warning{background:color-mix(in srgb,CanvasText 6%,Canvas);border-radius:8px}\
             kbd{font-family:-apple-system,sans-serif}"
        }
        Platform::Linux => {
            ":root{color-scheme:light dark}\
             body{font:11pt system-ui,'Adwaita Sans',Cantarell,sans-serif;color:CanvasText;background:Canvas}\
             a{color:#1c71d8}@media(prefers-color-scheme:dark){a{color:#78aeed}}\
             aside.note,aside.warning{background:color-mix(in srgb,CanvasText 6%,Canvas);border-radius:12px}"
        }
    };
    format!(
        "body{{margin:16px 24px;line-height:1.5}}body>:not(.web),main{{max-width:42em}}h1{{font-size:1.6em;margin:0 0 4px}}\
         h2{{font-size:1.2em;margin:1.4em 0 .4em}}p.summary{{font-size:1.05em;opacity:.8;margin-top:0}}\
         ol,ul{{padding-left:1.6em}}li{{margin:.3em 0}}table{{border-collapse:collapse;margin:.6em 0}}\
         th,td{{text-align:left;padding:4px 12px 4px 0;border-bottom:1px solid color-mix(in srgb,currentColor 18%,transparent);vertical-align:top}}\
         kbd{{font-size:.9em;border:1px solid color-mix(in srgb,currentColor 35%,transparent);border-bottom-width:2px;\
         border-radius:4px;padding:0 4px;white-space:nowrap}}aside{{padding:8px 12px;margin:.8em 0}}.side a[aria-current]{{font-weight:700;text-decoration:none}}\
         aside.warning{{border-left:4px solid #c60}}img.picture{{max-width:100%;height:auto;margin:.6em 0;\
         border:1px solid color-mix(in srgb,currentColor 18%,transparent)}}nav.related{{margin-top:1.6em;padding-top:.6em;\
         border-top:1px solid color-mix(in srgb,currentColor 18%,transparent)}}nav.related a{{margin-right:1.2em}}\
         p.home{{margin:0 0 1em;font-size:.9em}}header.bar{{display:flex;flex-wrap:wrap;gap:8px 24px;align-items:baseline;\
         max-width:none;padding:0 0 12px;margin:0 0 20px;border-bottom:1px solid color-mix(in srgb,currentColor 18%,transparent)}}\
         header.bar .brand{{font-weight:700;text-decoration:none;margin-right:auto}}header.bar a,header.bar b{{margin-right:10px}}.web{{display:flex;gap:32px}}.web .side{{flex:0 0 240px;font-size:.92em}}.web .side ul{{padding-left:1.1em}}\
         .web main{{flex:1;min-width:0}}@media(max-width:700px){{.web{{display:block}}.web .side{{display:none}}}}\
         {platform_style}"
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keys_as_each_platform_writes_them() {
        assert_eq!(
            key_text("Mod+Shift+F", Platform::Windows, "en"),
            "<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F</kbd>"
        );
        assert_eq!(key_text("Mod+Q", Platform::Linux, "de"), "<kbd>Strg</kbd>+<kbd>Q</kbd>");
        assert_eq!(
            key_text("Mod+Alt+Shift+A", Platform::Mac, "en"),
            "<kbd>\u{2325}\u{21E7}\u{2318}A</kbd>"
        );
        assert_eq!(key_text("Mod+Shift+/", Platform::Mac, "en"), "<kbd>\u{2318}?</kbd>");
        assert_eq!(
            key_text("Mod+Delete", Platform::Mac, "en"),
            "<kbd>\u{2318}\u{232B}</kbd>"
        );
        assert_eq!(key_text("", Platform::Windows, "en"), "");
    }

    /// Mark as Read is Ctrl+Q on Windows and Linux but Shift-Command-U on the Mac, where Command-Q quits: the old
    /// help, which wrote Ctrl+Q by hand, told Mac users to quit
    #[test]
    fn a_command_has_its_platforms_key() {
        assert_eq!(
            command_key("mark_read", Platform::Windows, "en"),
            "<kbd>Ctrl</kbd>+<kbd>Q</kbd>"
        );
        assert_eq!(
            command_key("mark_read", Platform::Mac, "en"),
            "<kbd>\u{21E7}\u{2318}U</kbd>"
        );
        assert_eq!(command_key("no_such_command", Platform::Mac, "en"), "");
    }

    #[test]
    fn controls_are_named_as_the_app_names_them() {
        assert_eq!(words("en", "cmd-new-account"), "New Account");
        assert_eq!(words("de", "cmd-mark-read"), "Als gelesen markieren");
        assert_eq!(words("en", "help-title"), "Inbox Classic Help");
    }

    #[test]
    fn filling_and_plain_text() {
        let html = fill(
            "a <x data=\"1\"></x> b <x data=\"2\"></x>",
            "<x data=\"",
            "\"></x>",
            |v| format!("[{v}]"),
        );
        assert_eq!(html, "a [1] b [2]");
        assert_eq!(
            plain_text("<p>One &amp; <b>two</b></p>\n<p>three</p>"),
            "One & two three"
        );
        assert_eq!(topic_link("find-messages", HelpTarget::Viewer), "topic:find-messages");
        assert_eq!(topic_link("find-messages", HelpTarget::Web), "find-messages.html");
    }

    /// Every topic of every language: in topics.toml, with a title and a summary, its keys, words and links found
    #[test]
    fn every_topic_resolves() {
        let listed: Vec<&str> = all_topics().collect();
        for (language, id, html) in TOPICS {
            assert!(listed.contains(id), "{language}/{id}.html is not in topics.toml");
            let start = html.trim_start().trim_start_matches(REVIEW_START).trim_start();
            assert!(start.starts_with("<h1>"), "{language}/{id}: starts with its <h1>");
            assert!(html.contains("<p class=\"summary\">"), "{language}/{id}: has a summary");
            for command in between_all(html, "data-command=\"", "\"") {
                assert!(
                    COMMANDS.iter().any(|(c, ..)| *c == command),
                    "{language}/{id}: no command {command}"
                );
            }
            for message in between_all(html, "data-text=\"", "\"") {
                assert!(
                    pe_i18n::message_in("en", message).is_some(),
                    "{language}/{id}: no message {message}"
                );
            }
            for link in between_all(html, "href=\"topic:", "\"") {
                assert!(listed.contains(&link), "{language}/{id}: no topic {link}");
            }
            assert!(
                !html.contains('\u{2014}') && !html.contains('\u{2013}'),
                "{language}/{id}: a dash"
            );
            for name in LOCAL_KEYS {
                assert!(
                    !html.contains(&format!("<kbd>{name}</kbd>")),
                    "{language}/{id}: <kbd>{name}</kbd>, write it in English"
                );
            }
        }
        for id in &listed {
            assert!(source("en", id).is_some(), "en/{id}.html is missing");
            for platform in [Platform::Windows, Platform::Mac, Platform::Linux] {
                let page = help_topic(id, platform, "en").unwrap();
                assert!(
                    !page.contains("data-text") && !page.contains("data-command"),
                    "{id}: left unfilled"
                );
            }
        }
    }

    fn between_all<'a>(text: &'a str, start: &str, end: &str) -> Vec<&'a str> {
        text.split(start)
            .skip(1)
            .filter_map(|rest| rest.split(end).next())
            .collect()
    }

    #[test]
    fn the_shortcuts_table_has_every_command_with_a_key() {
        let table = shortcuts_table(Platform::Mac, "en");
        assert!(
            table.contains("<td>Mark as Read</td><td><kbd>\u{21E7}\u{2318}U</kbd></td>"),
            "{table}"
        );
        assert!(!table.contains("<td></td>"));
    }
}
