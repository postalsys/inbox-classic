//! Emoji reactions to a message, sent as an email: Gmail's (a `text/vnd.google.email-reaction+json` part with the
//! emoji), Outlook's (no machine-readable part: the reaction's picture from Outlook's CDN opening the HTML, its name in
//! brackets opening the text) and RFC 9078's (a part with `Content-Disposition: reaction` holding the emoji). A message
//! counts as a reaction only when it has one of those shapes, replies to one message (`In-Reply-To`), and the provider
//! says the From domain signed it, as for sign-in codes (otp.rs); the store then checks that the message it replies to
//! is here and that the sender is in it (`Core::reaction_target`). Anything short of that stays an ordinary email.

use pe_mime::parser::Message;
use pe_store::{FolderId, MessageRef};
use serde::Deserialize;

use crate::{Core, Event, Result};

/// A reaction a message carries: the emoji and the Message-ID of the message it is for
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Reaction {
    pub emoji: String,
    /// The Message-ID of the reacted message, with its brackets
    pub target: String,
    /// The reacting person's address, lower case
    pub from: String,
    /// Their name as the message gives it, empty when none
    pub name: String,
}

/// Outlook's reactions by the name of their picture
const OUTLOOK: [(&str, &str); 6] = [
    ("like", "👍"),
    ("heart", "❤️"),
    ("celebrate", "🎉"),
    ("laugh", "😆"),
    ("surprised", "😮"),
    ("sad", "😢"),
];

/// Where Outlook's reaction pictures are
const OUTLOOK_PICTURES: &str = "https://outlook-1.cdn.office.net/assets/reaction/";

/// The longest emoji sequence taken (a family with skin tones is about 11 code points)
const MAX_EMOJI_CHARS: usize = 16;

#[derive(Deserialize)]
struct GmailPart {
    emoji: String,
    version: u32,
}

/// The reaction the message `raw` (parsed: `message`) carries, by its shape alone (the caller checks the signature
/// and the thread)
pub fn shape(raw: &[u8], message: &Message) -> Option<Reaction> {
    let target = pe_mime::parser::message_ids(message.in_reply_to.as_deref()?);
    let [target] = target.as_slice() else { return None };
    let emoji = gmail(message).or_else(|| rfc9078(raw)).or_else(|| outlook(message))?;
    let from = message.from.as_ref()?.mailboxes().first()?.clone();
    Some(Reaction {
        emoji,
        target: target.clone(),
        from: from.address.to_lowercase(),
        name: from.name.trim().to_string(),
    })
}

/// The emoji of Gmail's reaction part
fn gmail(message: &Message) -> Option<String> {
    let part = message
        .attachments
        .iter()
        .find(|a| a.mime_type.eq_ignore_ascii_case("text/vnd.google.email-reaction+json"))?;
    if part.content.len() > 1024 {
        return None;
    }
    let read: GmailPart = serde_json::from_slice(&part.content).ok()?;
    (read.version == 1).then(|| emoji(&read.emoji)).flatten()
}

/// The emoji of an RFC 9078 reaction part (a disposition the parser reads as text: it is found in the outline and
/// read alone)
fn rfc9078(raw: &[u8]) -> Option<String> {
    let outline = pe_mime::outline::outline(raw);
    let at = outline
        .parts
        .iter()
        .position(|p| p.disposition.eq_ignore_ascii_case("reaction") && p.content_type == "text/plain")?;
    let part = outline.bytes(raw, at);
    if part.len() > 1024 {
        return None;
    }
    let read = pe_mime::parser::parse(part).ok()?;
    emoji(read.text.as_deref()?.trim())
}

/// The emoji of Outlook's reaction: its picture's name, opening both the HTML and the text
fn outlook(message: &Message) -> Option<String> {
    let html = message.html.as_deref()?;
    let text = message.text.as_deref()?.trim_start();
    let at = html.find(OUTLOOK_PICTURES)?;
    // the banner comes first: its own picture is the first of the message
    if html[..at].matches("<img").count() != 1 || at > 4096 {
        return None;
    }
    let rest = &html[at + OUTLOOK_PICTURES.len()..];
    let name = rest.split(".png").next()?;
    let (_, emoji) = OUTLOOK.iter().find(|(n, _)| *n == name)?;
    text.starts_with(&format!("[{name}]")).then(|| emoji.to_string())
}

/// `text` when it is one emoji (a sequence with joiners, variation selectors and skin tones): no letters, digits,
/// spaces or controls, and at least one pictograph
fn emoji(text: &str) -> Option<String> {
    let chars: Vec<char> = text.chars().collect();
    if chars.is_empty() || chars.len() > MAX_EMOJI_CHARS {
        return None;
    }
    let joining = |c: char| {
        matches!(
            c,
            '\u{200d}' | '\u{fe0f}' | '\u{fe0e}' | '\u{20e3}' | '\u{1f3fb}'..='\u{1f3ff}'
        )
    };
    let pictograph = |c: char| {
        matches!(c,
            '\u{2190}'..='\u{2bff}' | '\u{3030}' | '\u{303d}' | '\u{3297}' | '\u{3299}' |
            '\u{1f000}'..='\u{1faff}' | '\u{e0020}'..='\u{e007f}' | '\u{00a9}' | '\u{00ae}')
    };
    let regional = |c: char| matches!(c, '\u{1f1e6}'..='\u{1f1ff}');
    let fits = chars.iter().all(|c| joining(*c) || pictograph(*c) || regional(*c));
    (fits && chars.iter().any(|c| pictograph(*c) || regional(*c))).then(|| text.to_string())
}

/// The reaction of `message` when its shape is one and the provider says the sender's domain signed it; `trusted`
/// names whose verdicts count (the account's provider)
pub(crate) fn of(raw: &[u8], message: &Message, trusted: &crate::authres::Verifiers) -> Option<Reaction> {
    let reaction = shape(raw, message)?;
    let domain = reaction.from.rsplit_once('@')?.1.to_string();
    let signed = crate::unsubscribe::passed_domains(&message.headers, trusted);
    signed
        .iter()
        .any(|d| crate::authres::under(&domain, d))
        .then_some(reaction)
}

/// One person's reactions to a message, as the reading pane's Reactions line shows them: "👍❤️ Kate Kalda"
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ReactionChip {
    /// Their emoji, then their name (their address when they gave none)
    pub text: String,
    /// When their last reaction came, in words, for the chip's menu
    pub when: String,
    /// The emails their reactions came in, newest last: Open Reaction Email opens the newest, Show as Email lists
    /// them all again
    pub emails: Vec<MessageRef>,
}

impl ReactionChip {
    /// The email of their newest reaction, the one Open Reaction Email opens
    pub fn newest(&self) -> Option<MessageRef> {
        self.emails.last().copied()
    }
}

/// A row's reactions as its badge shows them: up to three emoji, most used first, then how many reactions there are
/// when more than one ("👍❤️ 3"); empty for none
pub fn badge(reactions: &[(String, u32)]) -> String {
    let shown: String = reactions.iter().take(3).map(|(emoji, _)| emoji.as_str()).collect();
    let total: u32 = reactions.iter().map(|(_, count)| count).sum();
    match total {
        0 => String::new(),
        1 => shown,
        _ => format!("{shown} {total}"),
    }
}

impl Core {
    /// The reactions to the message `folder`/`uid`, one chip a person, in the order they first reacted
    pub fn reactions_of(&self, folder: FolderId, uid: u64) -> Result<Vec<ReactionChip>> {
        let store = self.store();
        if !store.any_reactions()? {
            return Ok(Vec::new());
        }
        let Some(id) = store.message(folder, uid)?.and_then(|m| m.info.message_id) else {
            return Ok(Vec::new());
        };
        let account = store.folder(folder)?.account_id;
        /// One person's reactions as they are gathered
        struct Person {
            address: String,
            who: String,
            emoji: Vec<String>,
            last: i64,
            emails: Vec<MessageRef>,
        }
        let mut people: Vec<Person> = Vec::new();
        for row in store.reactions_to(account, &id)? {
            let at = MessageRef {
                folder: row.folder,
                uid: row.uid,
            };
            let person = match people.iter().position(|p| p.address == row.address) {
                Some(index) => &mut people[index],
                None => {
                    people.push(Person {
                        who: crate::book::shown_name(&row.name, &row.address).to_string(),
                        address: row.address.clone(),
                        emoji: Vec::new(),
                        last: row.at,
                        emails: Vec::new(),
                    });
                    people.last_mut().expect("just pushed")
                }
            };
            if !person.emoji.contains(&row.emoji) {
                person.emoji.push(row.emoji);
            }
            person.last = row.at;
            person.emails.push(at);
        }
        Ok(people
            .into_iter()
            .map(|p| ReactionChip {
                text: format!("{} {}", p.emoji.concat(), p.who),
                when: crate::calendar::local_date_time(p.last),
                emails: p.emails,
            })
            .collect())
    }

    /// Open Reaction Email: the hidden email `at` written to a private file, for the message window that opens files;
    /// None when it is not kept (any longer)
    pub fn reaction_email_file(&self, at: MessageRef) -> Result<Option<std::path::PathBuf>> {
        let Some(source) = self.store().hidden_source(at.folder, at.uid)? else {
            return Ok(None);
        };
        let dir = crate::private_dir("reactions").map_err(|e| crate::Error::Invalid(e.to_string()))?;
        let path = dir.join(format!("reaction-{}-{}.eml", at.folder, at.uid));
        std::fs::write(&path, source).map_err(|e| crate::Error::Invalid(e.to_string()))?;
        Ok(Some(path))
    }

    /// Show as Email: the reaction emails `emails` listed again for good, their reactions taken off the message
    pub fn show_reactions_as_email(&self, emails: &[MessageRef]) -> Result<()> {
        let mut by_folder: std::collections::BTreeMap<FolderId, Vec<u64>> = std::collections::BTreeMap::new();
        {
            let store = self.store();
            for at in emails {
                if store.unhide(at.folder, at.uid)? {
                    by_folder.entry(at.folder).or_default().push(at.uid);
                }
            }
        }
        for (folder, uids) in by_folder {
            let account = self.store().folder(folder)?.account_id;
            self.send_command(account, crate::worker::Command::FetchUids { folder, uids })?;
            self.post(Event::FolderChanged { account, folder })?;
        }
        self.post(Event::ListsChanged)?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const GMAIL: &str = "Authentication-Results: mx.google.com;\r\n dkim=pass header.i=@studio.example header.s=google;\r\n dmarc=pass header.from=studio.example\r\n\
        From: Kate Kalda <kate@studio.example>\r\nTo: Ann <ann@gmail.com>\r\nSubject: Re: Furniture\r\n\
        Message-ID: <reaction-1@mail.gmail.com>\r\nIn-Reply-To: <original-1@mail.gmail.com>\r\n\
        References: <earlier@mail.gmail.com> <original-1@mail.gmail.com>\r\nMIME-Version: 1.0\r\n\
        Content-Type: multipart/alternative; boundary=\"b\"\r\n\r\n\
        --b\r\nContent-Type: text/plain; charset=\"UTF-8\"\r\nContent-Transfer-Encoding: quoted-printable\r\n\r\n\
        =F0=9F=91=8D\r\n\r\nKate Kalda reageeris Gmaili kaudu\r\n\r\n> Tere!\r\n\
        --b\r\nContent-Type: text/vnd.google.email-reaction+json; charset=\"UTF-8\"\r\nContent-Transfer-Encoding: quoted-printable\r\n\r\n\
        {\r\n  \"emoji\": \"=F0=9F=91=8D\",\r\n  \"version\": 1\r\n}\r\n\
        --b\r\nContent-Type: text/html; charset=\"UTF-8\"\r\n\r\n<div>&#128077;</div><p>Kate Kalda reageeris</p>\r\n--b--\r\n";

    const OUTLOOK_MAIL: &str = "Authentication-Results: mx.example.net;\r\n dkim=pass header.d=company.example header.s=selector1\r\n\
        From: Ann Lee <ann@company.example>\r\nTo: Bo <bo@mail.example>\r\nSubject: RE: test\r\n\
        Message-ID: <reaction-2@eurprd07.prod.outlook.com>\r\nIn-Reply-To: <original-2@mail.example>\r\n\
        References: <original-2@mail.example>\r\nMIME-Version: 1.0\r\n\
        Content-Type: multipart/alternative; boundary=\"o\"\r\n\r\n\
        --o\r\nContent-Type: text/plain; charset=\"iso-8859-1\"\r\n\r\n[like]  Ann Lee reacted to your message:\r\n______\r\nFrom: Bo\r\n\
        --o\r\nContent-Type: text/html; charset=\"iso-8859-1\"\r\n\r\n<html><body><table><tr><td>\
        <img alt=\"like\" src=\"https://outlook-1.cdn.office.net/assets/reaction/like.png\" style=\"height:25px\"></td>\
        <td><span>Ann Lee</span> reacted to your message:</td></tr></table><hr><p>test</p></body></html>\r\n--o--\r\n";

    const RFC9078: &str = "From: Dave <dave@chat.example>\r\nTo: ann@example.org\r\nSubject: Re: hi\r\n\
        In-Reply-To: <original-3@example.org>\r\nMIME-Version: 1.0\r\n\
        Content-Type: multipart/mixed; boundary=\"r\"\r\n\r\n\
        --r\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nDave reacted\r\n\
        --r\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Disposition: reaction\r\n\r\n\u{1F389}\r\n--r--\r\n";

    fn parsed(raw: &str) -> Message {
        pe_mime::parser::parse(raw.as_bytes()).unwrap()
    }

    fn read(raw: &str) -> Option<Reaction> {
        shape(raw.as_bytes(), &parsed(raw))
    }

    fn signed(raw: &str, names: &[&str]) -> Option<Reaction> {
        of(raw.as_bytes(), &parsed(raw), &trusted(names))
    }

    fn trusted(names: &[&str]) -> crate::authres::Verifiers {
        crate::authres::Verifiers::named(names)
    }

    #[test]
    fn gmail_outlook_and_rfc_9078_reactions_are_read() {
        let gmail = read(GMAIL).unwrap();
        assert_eq!(
            (
                gmail.emoji.as_str(),
                gmail.target.as_str(),
                gmail.from.as_str(),
                gmail.name.as_str()
            ),
            ("👍", "<original-1@mail.gmail.com>", "kate@studio.example", "Kate Kalda")
        );
        let outlook = read(OUTLOOK_MAIL).unwrap();
        assert_eq!(
            (outlook.emoji.as_str(), outlook.target.as_str()),
            ("👍", "<original-2@mail.example>")
        );
        assert_eq!(read(RFC9078).unwrap().emoji, "🎉");
    }

    #[test]
    fn gmail_s_reaction_part_is_no_file() {
        assert_eq!(crate::view::listed(&parsed(GMAIL).attachments).count(), 0);
    }

    #[test]
    fn only_a_signed_sender_counts() {
        assert!(signed(GMAIL, &["mx.google.com"]).is_some());
        assert!(signed(OUTLOOK_MAIL, &["mx.example.net"]).is_some());
        // another provider's verdict, or none: not a reaction
        assert!(signed(GMAIL, &["mx.example.net"]).is_none());
        assert!(signed(RFC9078, &["mx.google.com"]).is_none());
    }

    #[test]
    fn what_only_resembles_a_reaction_stays_an_email() {
        // not a reply
        assert!(read(&GMAIL.replace("In-Reply-To: <original-1@mail.gmail.com>\r\n", "")).is_none());
        // a reply to two messages
        let two = GMAIL.replace("In-Reply-To: <original-1@mail.gmail.com>", "In-Reply-To: <a@x> <b@y>");
        assert!(read(&two).is_none());
        // Gmail's part with words in place of an emoji, or another version
        assert!(read(&GMAIL.replace("=F0=9F=91=8D\",", "click here\",")).is_none());
        assert!(read(&GMAIL.replace("\"version\": 1", "\"version\": 2")).is_none());
        // Outlook's banner after other pictures, or another picture name, or the text not opening with it
        let late = OUTLOOK_MAIL.replace("<table>", "<img src=\"https://tracker.example/x.png\"><table>");
        assert!(read(&late).is_none());
        assert!(read(&OUTLOOK_MAIL.replace("reaction/like.png", "reaction/evil.png")).is_none());
        assert!(read(&OUTLOOK_MAIL.replace("[like]", "Re:")).is_none());
        // an ordinary reply
        let plain = "From: a@x.example\r\nIn-Reply-To: <o@x>\r\nSubject: Re: x\r\n\r\nThanks!\r\n";
        assert!(read(plain).is_none());
    }

    #[test]
    fn the_badge_shows_three_emoji_and_the_count() {
        let r = |list: &[(&str, u32)]| badge(&list.iter().map(|(e, n)| (e.to_string(), *n)).collect::<Vec<_>>());
        assert_eq!(r(&[]), "");
        assert_eq!(r(&[("👍", 1)]), "👍");
        assert_eq!(r(&[("👍", 2), ("❤️", 1)]), "👍❤️ 3");
        assert_eq!(r(&[("🎉", 3), ("👍", 2), ("❤️", 1), ("😮", 1)]), "🎉👍❤️ 7");
    }

    #[test]
    fn an_emoji_is_one_emoji() {
        for good in ["👍", "❤️", "👍🏽", "👨‍👩‍👧", "🇪🇪", "🎉"] {
            assert_eq!(emoji(good).as_deref(), Some(good), "{good}");
        }
        for bad in ["", "ok", "👍 ok", "1️⃣2", "a👍", "<b>👍</b>", &"👍".repeat(20)] {
            assert!(emoji(bad).is_none(), "{bad}");
        }
    }
}
