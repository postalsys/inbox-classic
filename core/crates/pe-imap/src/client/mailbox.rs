//! Mailboxes: LIST with special-use folders and subscriptions, SELECT and EXAMINE, STATUS,
//! NAMESPACE, and creating, renaming, deleting and subscribing. A port of imapflow's list.ts,
//! select.ts and status.ts.

use std::collections::HashSet;

use super::{Client, Completion, Error};
use crate::compiler::Arg;
use crate::special_use::{self, FLAGS, Source};
use crate::types::{Response, Token};

/// The personal namespace: what mailbox names start with, and the hierarchy delimiter
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Namespace {
    pub prefix: String,
    pub delimiter: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ListedMailbox {
    /// The full name, decoded
    pub path: String,
    /// The last part of the path
    pub name: String,
    pub delimiter: Option<String>,
    /// LIST attributes, `\HasChildren`, `\Noselect`, ...
    pub flags: Vec<String>,
    pub subscribed: bool,
    /// `\Inbox`, `\Sent`, `\Drafts`, `\Trash`, `\Junk`, `\Archive`, `\All` or `\Flagged`
    pub special_use: Option<&'static str>,
    pub special_use_source: Option<Source>,
}

impl ListedMailbox {
    pub fn has_flag(&self, flag: &str) -> bool {
        self.flags.iter().any(|f| f.eq_ignore_ascii_case(flag))
    }

    /// Whether the mailbox can be selected (`\Noselect` and `\NonExistent` can not)
    pub fn is_selectable(&self) -> bool {
        !self.has_flag("\\Noselect") && !self.has_flag("\\NonExistent")
    }

    fn depth(&self) -> usize {
        match &self.delimiter {
            Some(d) if !d.is_empty() => self.path.matches(d.as_str()).count(),
            _ => 0,
        }
    }
}

/// The selected mailbox, as SELECT or EXAMINE reported it and as it changed since
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Selected {
    pub path: String,
    pub exists: u32,
    pub uid_validity: Option<u64>,
    pub uid_next: Option<u64>,
    pub flags: Vec<String>,
    pub permanent_flags: Vec<String>,
    pub highest_modseq: Option<u64>,
    pub read_only: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct MailboxStatus {
    pub messages: Option<u64>,
    pub unseen: Option<u64>,
    pub uid_next: Option<u64>,
    pub uid_validity: Option<u64>,
    pub highest_modseq: Option<u64>,
}

fn texts(tokens: &[Token]) -> Vec<String> {
    tokens.iter().filter_map(Token::text).collect()
}

impl Client {
    pub(super) async fn fetch_namespace(&mut self) -> Result<Option<Namespace>, Error> {
        let completion = match self.run("NAMESPACE", Vec::new()).await {
            Ok(completion) => completion,
            Err(Error::Refused { .. }) => return Ok(None),
            Err(error) => return Err(error),
        };
        // * NAMESPACE (("" "/")) NIL NIL: the first personal namespace
        let personal = completion
            .untagged
            .iter()
            .find(|r| r.command.eq_ignore_ascii_case("NAMESPACE"))
            .and_then(|r| r.attributes.first())
            .and_then(Token::as_list)
            .and_then(|list| list.first())
            .and_then(Token::as_list);
        Ok(personal.map(|entry| Namespace {
            prefix: entry.first().and_then(Token::text).unwrap_or_default(),
            delimiter: entry.get(1).and_then(Token::text),
        }))
    }

    /// Every mailbox, special-use folders first in Outlook Express order, then by name
    pub async fn list(&mut self) -> Result<Vec<ListedMailbox>, Error> {
        let extended = self.has_capability("LIST-EXTENDED");
        let special = self.has_capability("SPECIAL-USE") || self.has_capability("IMAP4REV2");
        let mut options = Vec::new();
        if extended {
            options.push(Arg::atom("SUBSCRIBED"));
        }
        if special {
            options.push(Arg::atom("SPECIAL-USE"));
        }

        let mut subscriptions_known = false;
        let mut mailboxes = match options.is_empty() {
            false => match self.run_list(true, options).await {
                Ok(listed) => {
                    subscriptions_known = extended;
                    listed
                }
                // a server that refuses RETURN options gets a plain LIST
                Err(Error::Refused { status, .. }) if status == "BAD" => self.run_list(true, Vec::new()).await?,
                Err(error) => return Err(error),
            },
            true => self.run_list(true, Vec::new()).await?,
        };

        if !subscriptions_known {
            subscriptions_known = self.mark_subscribed(&mut mailboxes).await?;
        }
        if !subscriptions_known || !mailboxes.iter().any(|m| m.subscribed) {
            // without subscription information every mailbox counts as subscribed
            mailboxes
                .iter_mut()
                .filter(|m| !m.has_flag("\\NonExistent"))
                .for_each(|m| m.subscribed = true);
        }
        assign_special_use(&mut mailboxes, special);
        sort(&mut mailboxes);
        Ok(mailboxes)
    }

    async fn run_list(&mut self, list: bool, options: Vec<Arg>) -> Result<Vec<ListedMailbox>, Error> {
        let mut args = vec![Arg::string(""), Arg::string("*")];
        if !options.is_empty() {
            args.push(Arg::atom("RETURN"));
            args.push(Arg::List(options));
        }
        let name = if list { "LIST" } else { "LSUB" };
        let completion = self.run(name, args).await?;
        Ok(completion
            .untagged
            .iter()
            .filter(|r| r.command.eq_ignore_ascii_case(name))
            .filter_map(|r| self.listed(r))
            .collect())
    }

    /// `* LIST (\HasNoChildren \Sent) "/" "Sent Items"`
    fn listed(&self, response: &Response) -> Option<ListedMailbox> {
        let flags = texts(response.attributes.first()?.as_list()?);
        let delimiter = response
            .attributes
            .get(1)
            .and_then(Token::text)
            .filter(|d| !d.is_empty());
        let raw = response.attributes.get(2)?.text()?;
        let mut path = self.decode_path(&raw);
        // some servers start names with the delimiter
        if let Some(d) = &delimiter
            && path.len() > d.len()
            && path.starts_with(d.as_str())
        {
            path = path[d.len()..].to_string();
        }
        let name = match &delimiter {
            Some(d) => path.rsplit(d.as_str()).next().unwrap_or(&path).to_string(),
            None => path.clone(),
        };
        Some(ListedMailbox {
            subscribed: flags.iter().any(|f| f.eq_ignore_ascii_case("\\Subscribed")),
            path,
            name,
            delimiter,
            flags,
            special_use: None,
            special_use_source: None,
        })
    }

    /// Marks the mailboxes LSUB lists, returns whether that worked
    async fn mark_subscribed(&mut self, mailboxes: &mut [ListedMailbox]) -> Result<bool, Error> {
        match self.run_list(false, Vec::new()).await {
            Ok(subscribed) => {
                let paths: HashSet<&str> = subscribed.iter().map(|m| m.path.as_str()).collect();
                for mailbox in mailboxes.iter_mut() {
                    mailbox.subscribed |= paths.contains(mailbox.path.as_str());
                }
                Ok(true)
            }
            Err(Error::Refused { .. }) => Ok(false),
            Err(error) => Err(error),
        }
    }

    /// Opens a mailbox for reading and writing
    pub async fn select(&mut self, path: &str) -> Result<Selected, Error> {
        self.open("SELECT", path).await
    }

    /// Opens a mailbox read-only
    pub async fn examine(&mut self, path: &str) -> Result<Selected, Error> {
        self.open("EXAMINE", path).await
    }

    async fn open(&mut self, command: &str, path: &str) -> Result<Selected, Error> {
        // the previous mailbox is closed as soon as the command is sent
        self.selected = None;
        let completion = self.run(command, vec![self.encode_path(path)]).await?;
        let mut selected = Selected {
            path: self.decode_path(path),
            read_only: command == "EXAMINE",
            ..Default::default()
        };
        for response in &completion.untagged {
            read_select_response(&mut selected, response);
        }
        match completion.tagged.code().map(|(code, _)| code).as_deref() {
            Some("READ-ONLY") => selected.read_only = true,
            Some("READ-WRITE") => selected.read_only = false,
            _ => {}
        }
        self.selected = Some(selected.clone());
        Ok(selected)
    }

    /// Closes the selected mailbox without expunging (UNSELECT), or with CLOSE where UNSELECT is
    /// not available, which does expunge
    pub async fn unselect(&mut self) -> Result<(), Error> {
        if self.selected.is_none() {
            return Ok(());
        }
        let command = if self.has_capability("UNSELECT") {
            "UNSELECT"
        } else {
            "CLOSE"
        };
        self.run(command, Vec::new()).await?;
        self.selected = None;
        Ok(())
    }

    /// Message counts of a mailbox without selecting it
    pub async fn status(&mut self, path: &str) -> Result<MailboxStatus, Error> {
        let mut items = vec![
            Arg::atom("MESSAGES"),
            Arg::atom("UNSEEN"),
            Arg::atom("UIDNEXT"),
            Arg::atom("UIDVALIDITY"),
        ];
        if self.has_capability("CONDSTORE") {
            items.push(Arg::atom("HIGHESTMODSEQ"));
        }
        let completion = self
            .run("STATUS", vec![self.encode_path(path), Arg::List(items)])
            .await?;
        let mut status = MailboxStatus::default();
        let list = completion
            .untagged
            .iter()
            .filter(|r| r.command.eq_ignore_ascii_case("STATUS"))
            .find_map(|r| r.attributes.get(1).and_then(Token::as_list));
        for pair in list.unwrap_or_default().chunks_exact(2) {
            let value = pair[1].number();
            match pair[0].text().unwrap_or_default().to_ascii_uppercase().as_str() {
                "MESSAGES" => status.messages = value,
                "UNSEEN" => status.unseen = value,
                "UIDNEXT" => status.uid_next = value,
                "UIDVALIDITY" => status.uid_validity = value,
                "HIGHESTMODSEQ" => status.highest_modseq = value,
                _ => {}
            }
        }
        Ok(status)
    }

    /// Creates a mailbox, returns false when it existed already
    pub async fn create(&mut self, path: &str) -> Result<bool, Error> {
        match self.run("CREATE", vec![self.encode_path(path)]).await {
            Ok(_) => Ok(true),
            Err(Error::Refused { code: Some(code), .. }) if code == "ALREADYEXISTS" => Ok(false),
            Err(error) => Err(error),
        }
    }

    pub async fn delete(&mut self, path: &str) -> Result<(), Error> {
        if self.selected.as_ref().is_some_and(|s| s.path == path) {
            self.unselect().await?;
        }
        self.simple("DELETE", vec![self.encode_path(path)]).await
    }

    pub async fn rename(&mut self, path: &str, new_path: &str) -> Result<(), Error> {
        self.simple("RENAME", vec![self.encode_path(path), self.encode_path(new_path)])
            .await
    }

    pub async fn subscribe(&mut self, path: &str) -> Result<(), Error> {
        self.simple("SUBSCRIBE", vec![self.encode_path(path)]).await
    }

    pub async fn unsubscribe(&mut self, path: &str) -> Result<(), Error> {
        self.simple("UNSUBSCRIBE", vec![self.encode_path(path)]).await
    }

    async fn simple(&mut self, command: &str, args: Vec<Arg>) -> Result<(), Error> {
        self.run(command, args).await.map(|_: Completion| ())
    }
}

fn read_select_response(selected: &mut Selected, response: &Response) {
    let command = response.command.to_ascii_uppercase();
    if command == "FLAGS" {
        selected.flags = response
            .attributes
            .first()
            .and_then(Token::as_list)
            .map(texts)
            .unwrap_or_default();
        return;
    }
    if let Ok(count) = command.parse::<u32>() {
        if response.attributes.first().is_some_and(|t| t.is_atom("EXISTS")) {
            selected.exists = count;
        }
        return;
    }
    let Some((code, args)) = response.code() else { return };
    let number = args.first().and_then(Token::number);
    match code.as_str() {
        "UIDVALIDITY" => selected.uid_validity = number,
        "UIDNEXT" => selected.uid_next = number,
        "HIGHESTMODSEQ" => selected.highest_modseq = number,
        "PERMANENTFLAGS" => {
            selected.permanent_flags = args.first().and_then(Token::as_list).map(texts).unwrap_or_default();
        }
        _ => {}
    }
}

/// One mailbox per special-use flag: the best source wins, then the shallower path, then the
/// name. INBOX is always the inbox.
fn assign_special_use(mailboxes: &mut [ListedMailbox], has_extension: bool) {
    let mut candidates = Vec::new();
    for (index, mailbox) in mailboxes.iter().enumerate() {
        if mailbox.path == "INBOX" {
            candidates.push((Source::Extension, 0, mailbox.path.clone(), "\\Inbox", index));
            continue;
        }
        if let Some((flag, source)) = special_use::detect(has_extension, &mailbox.flags, &mailbox.name) {
            // a name match for a mailbox that does not exist could take the place of a real one
            if source != Source::Extension && mailbox.has_flag("\\NonExistent") {
                continue;
            }
            candidates.push((source, mailbox.depth(), mailbox.path.clone(), flag, index));
        }
    }
    candidates.sort();
    let mut assigned = HashSet::new();
    for (source, _, _, flag, index) in candidates {
        if mailboxes[index].special_use.is_some() || !assigned.insert(flag) {
            continue;
        }
        mailboxes[index].special_use = Some(flag);
        mailboxes[index].special_use_source = Some(source);
    }
}

fn sort(mailboxes: &mut [ListedMailbox]) {
    let order = |m: &ListedMailbox| m.special_use.and_then(|flag| FLAGS.iter().position(|f| *f == flag));
    mailboxes.sort_by(|a, b| match (order(a), order(b)) {
        (Some(x), Some(y)) => x.cmp(&y),
        (Some(_), None) => std::cmp::Ordering::Less,
        (None, Some(_)) => std::cmp::Ordering::Greater,
        (None, None) => a
            .path
            .to_lowercase()
            .cmp(&b.path.to_lowercase())
            .then_with(|| a.path.cmp(&b.path)),
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    fn mailbox(path: &str, flags: &[&str]) -> ListedMailbox {
        ListedMailbox {
            path: path.into(),
            name: path.rsplit('/').next().unwrap().into(),
            delimiter: Some("/".into()),
            flags: flags.iter().map(|f| f.to_string()).collect(),
            subscribed: true,
            special_use: None,
            special_use_source: None,
        }
    }

    #[test]
    fn special_use_prefers_flags_and_shallow_paths() {
        let mut list = vec![
            mailbox("Work/Sent", &[]),
            mailbox("Sent Items", &[]),
            mailbox("Sent", &["\\Sent"]),
            mailbox("INBOX", &[]),
            mailbox("Trash", &["\\NonExistent"]),
            mailbox("Projects", &[]),
            mailbox("Deleted Items", &[]),
        ];
        assign_special_use(&mut list, true);
        sort(&mut list);
        let summary: Vec<(&str, Option<&str>)> = list.iter().map(|m| (m.path.as_str(), m.special_use)).collect();
        assert_eq!(
            summary,
            vec![
                ("INBOX", Some("\\Inbox")),
                ("Sent", Some("\\Sent")),
                ("Deleted Items", Some("\\Trash")),
                ("Projects", None),
                ("Sent Items", None),
                ("Trash", None),
                ("Work/Sent", None),
            ]
        );
    }
}
