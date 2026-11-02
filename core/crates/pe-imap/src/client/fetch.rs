//! FETCH: what to ask for ([`FetchQuery`]) and what comes back ([`FetchedMessage`]). Bodies are
//! fetched with BODY.PEEK so reading does not mark a message as seen. A port of imapflow's
//! fetch.ts and of its formatMessageResponse.

use std::collections::BTreeMap;

use super::{Client, Completion, Error};
use crate::compiler::Arg;
use crate::message::{BodyStructure, Envelope, parse_body_structure, parse_envelope};
use crate::sequence::Messages;
use crate::types::{Response, Token};

/// The data items to fetch. The UID is always fetched.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct FetchQuery {
    pub flags: bool,
    pub envelope: bool,
    pub body_structure: bool,
    pub internal_date: bool,
    pub size: bool,
    /// MODSEQ, where CONDSTORE is available
    pub modseq: bool,
    /// The header: all of it for `Some(vec![])`, these fields otherwise
    pub headers: Option<Vec<String>>,
    /// Body parts by part number (`1`, `1.2`, `2.MIME`)
    pub parts: Vec<String>,
    /// The whole message
    pub source: bool,
    /// Only messages whose MODSEQ is higher (CONDSTORE)
    pub changed_since: Option<u64>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct FetchedMessage {
    pub seq: u32,
    pub uid: Option<u64>,
    pub flags: Option<Vec<String>>,
    pub envelope: Option<Envelope>,
    pub body_structure: Option<BodyStructure>,
    /// INTERNALDATE in seconds since the Unix epoch
    pub internal_date: Option<i64>,
    pub size: Option<u64>,
    pub modseq: Option<u64>,
    pub headers: Option<Vec<u8>>,
    pub parts: BTreeMap<String, Vec<u8>>,
    pub source: Option<Vec<u8>>,
}

impl FetchQuery {
    fn items(&self, condstore: bool) -> Vec<Arg> {
        let wanted = [
            (true, "UID"),
            (self.flags, "FLAGS"),
            (self.envelope, "ENVELOPE"),
            (self.body_structure, "BODYSTRUCTURE"),
            (self.internal_date, "INTERNALDATE"),
            (self.size, "RFC822.SIZE"),
            (self.modseq && condstore, "MODSEQ"),
        ];
        let mut items: Vec<Arg> = wanted
            .into_iter()
            .filter(|(on, _)| *on)
            .map(|(_, name)| Arg::atom(name))
            .collect();
        let peek = |section: Vec<Arg>| Arg::Section {
            name: "BODY.PEEK".into(),
            section,
            partial: None,
        };
        match &self.headers {
            Some(fields) if fields.is_empty() => items.push(peek(vec![Arg::atom("HEADER")])),
            Some(fields) => items.push(peek(vec![
                Arg::atom("HEADER.FIELDS"),
                Arg::List(fields.iter().map(|f| Arg::atom(f.to_ascii_uppercase())).collect()),
            ])),
            None => {}
        }
        items.extend(self.parts.iter().map(|part| peek(vec![Arg::atom(part.as_str())])));
        if self.source {
            items.push(peek(Vec::new()));
        }
        items
    }
}

impl Client {
    /// Fetches messages, in the order the server sent them
    pub async fn fetch(&mut self, messages: &Messages, query: &FetchQuery) -> Result<Vec<FetchedMessage>, Error> {
        let mut fetched: Vec<FetchedMessage> = Vec::new();
        self.fetch_each(messages, query, &mut |message| {
            // some servers split one message over several FETCH responses
            match fetched.last_mut() {
                Some(last) if last.seq == message.seq => merge(last, message),
                _ => fetched.push(message),
            }
        })
        .await?;
        Ok(fetched)
    }

    /// Fetches like [`Client::fetch`], handing each message to `each` as it arrives instead of
    /// collecting them, for large mailboxes. A FETCH for a message that was not asked for is a
    /// change by someone else and arrives as an event. A UID FETCH that the server cuts short
    /// with MESSAGELIMIT is repeated for the rest of the set.
    pub async fn fetch_each(
        &mut self,
        messages: &Messages,
        query: &FetchQuery,
        each: &mut dyn FnMut(FetchedMessage),
    ) -> Result<(), Error> {
        let mut next = Some(messages.clone());
        let mut ceiling = u64::MAX;
        while let Some(messages) = next.take() {
            let completion = self.fetch_once(&messages, query, each).await?;
            // each round has to go lower, so a server can not keep the client asking
            if let (Messages::Uids(set), Some(lowest)) = (&messages, completion.message_limit())
                && lowest < ceiling
            {
                ceiling = lowest;
                next = set.below(lowest).map(Messages::Uids);
            }
        }
        Ok(())
    }

    async fn fetch_once(
        &mut self,
        messages: &Messages,
        query: &FetchQuery,
        each: &mut dyn FnMut(FetchedMessage),
    ) -> Result<Completion, Error> {
        let exists = u64::from(self.require_selected()?.exists);
        let condstore = self.has_capability("CONDSTORE");
        let mut args = vec![
            Arg::Sequence(messages.set().to_string()),
            Arg::List(query.items(condstore)),
        ];
        if let (Some(modseq), true) = (query.changed_since, condstore) {
            args.push(Arg::List(vec![Arg::atom("CHANGEDSINCE"), Arg::Number(modseq)]));
        }
        let requested = |seq: u32, response: &Response| match messages {
            // without a UID in the answer the message can not be told apart, it is taken as asked for
            Messages::Uids(set) => item(response, "UID")
                .and_then(Token::number)
                .is_none_or(|uid| set.contains(uid, u64::MAX)),
            Messages::Seqs(set) => set.contains(u64::from(seq), exists),
        };
        let mut handler = |response: Response| match response.message_data() {
            Some((seq, kind)) if kind.is_atom("FETCH") && requested(seq, &response) => {
                each(parse_fetch(seq, response));
                Ok(None)
            }
            _ => Ok(Some(response)),
        };
        self.run_with(&messages.command("FETCH"), args, &mut handler, None)
            .await
    }
}

fn merge(into: &mut FetchedMessage, from: FetchedMessage) {
    into.uid = into.uid.or(from.uid);
    into.flags = from.flags.or(into.flags.take());
    into.envelope = from.envelope.or(into.envelope.take());
    into.body_structure = from.body_structure.or(into.body_structure.take());
    into.internal_date = into.internal_date.or(from.internal_date);
    into.size = into.size.or(from.size);
    into.modseq = from.modseq.or(into.modseq);
    into.headers = from.headers.or(into.headers.take());
    into.source = from.source.or(into.source.take());
    into.parts.extend(from.parts);
}

/// The data items of `* 12 FETCH (UID 98 FLAGS (\Seen) ...)` as key and value
fn items(response: Response) -> Vec<Token> {
    match response.attributes.into_iter().nth(1) {
        Some(Token::List(items)) => items,
        _ => Vec::new(),
    }
}

/// Reads a FETCH response, taking its data: a body is moved out, not copied
pub(crate) fn parse_fetch(seq: u32, response: Response) -> FetchedMessage {
    let mut message = FetchedMessage {
        seq,
        ..Default::default()
    };
    let mut items = items(response).into_iter();
    while let (Some(key), Some(value)) = (items.next(), items.next()) {
        let Token::Atom(key) = key else { continue };
        let name = key.value.as_slice();
        let is = |expected: &str| name.eq_ignore_ascii_case(expected.as_bytes());
        if is("UID") {
            message.uid = value.number();
        } else if is("FLAGS") {
            message.flags = value.as_list().map(|_| value.texts());
        } else if is("ENVELOPE") {
            message.envelope = value.as_list().map(parse_envelope);
        } else if is("BODYSTRUCTURE") || (is("BODY") && key.section.is_none()) {
            message.body_structure = value.as_list().map(parse_body_structure);
        } else if is("INTERNALDATE") {
            message.internal_date = value.text().and_then(|d| crate::date::parse_internal_date(&d));
        } else if is("RFC822.SIZE") {
            message.size = value.number();
        } else if is("MODSEQ") {
            message.modseq = value.as_list().and_then(|l| l.first()).and_then(Token::number);
        } else if (is("BODY") || is("BINARY"))
            && let Some(section) = &key.section
        {
            body_section(&mut message, section, value);
        }
    }
    message
}

/// The value of a data item of a FETCH response, without taking the response apart
fn item<'a>(response: &'a Response, name: &str) -> Option<&'a Token> {
    let items = response.attributes.get(1)?.as_list()?;
    items
        .as_chunks::<2>()
        .0
        .iter()
        .find(|[key, _]| key.is_atom(name))
        .map(|[_, value]| value)
}

/// UID, flags and MODSEQ of a FETCH that reports a flag change, None when it has no flags
pub(crate) fn flag_update(response: &Response) -> Option<(Option<u64>, Vec<String>, Option<u64>)> {
    let flags = item(response, "FLAGS")?.texts();
    let uid = item(response, "UID").and_then(Token::number);
    let modseq = item(response, "MODSEQ")
        .and_then(Token::as_list)
        .and_then(|l| l.first())
        .and_then(Token::number);
    Some((uid, flags, modseq))
}

fn body_section(message: &mut FetchedMessage, section: &[Token], value: Token) {
    let value = match value {
        Token::String(bytes) | Token::Literal(bytes) => bytes,
        Token::Atom(atom) => atom.value,
        _ => Vec::new(),
    };
    let Some(first) = section.first().and_then(Token::text) else {
        message.source = Some(value);
        return;
    };
    if first.eq_ignore_ascii_case("HEADER") || first.to_ascii_uppercase().starts_with("HEADER.FIELDS") {
        message.headers = Some(value);
    } else {
        message.parts.insert(first, value);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::compiler::{Command, CompileOptions, compile};

    #[test]
    fn query_items() {
        let query = FetchQuery {
            flags: true,
            envelope: true,
            modseq: true,
            headers: Some(vec!["Subject".into(), "references".into()]),
            parts: vec!["1.2".into()],
            source: true,
            ..Default::default()
        };
        let command = Command {
            tag: "A1".into(),
            name: "UID FETCH".into(),
            args: vec![Arg::Sequence("1:*".into()), Arg::List(query.items(true))],
        };
        let wire = compile(&command, &CompileOptions::default()).unwrap().concat();
        assert_eq!(
            String::from_utf8(wire).unwrap(),
            "A1 UID FETCH 1:* (UID FLAGS ENVELOPE MODSEQ BODY.PEEK[HEADER.FIELDS (SUBJECT REFERENCES)] BODY.PEEK[1.2] BODY.PEEK[])\r\n"
        );
        assert!(!query.items(false).iter().any(|a| *a == Arg::atom("MODSEQ")));
    }

    #[test]
    fn parses_fetch_items() {
        let response = crate::parse(
            b"* 12 FETCH (UID 98 FLAGS (\\Seen $Forwarded) INTERNALDATE \"17-Jul-1996 02:44:25 -0700\" RFC822.SIZE 4286 MODSEQ (12121231000) BODY[HEADER.FIELDS (SUBJECT)] {4}\r\n BODY[1] \"hi\" BODY[] NIL)",
            vec![b"S: x".to_vec()],
        )
        .unwrap();
        let message = parse_fetch(12, response);
        assert_eq!(message.uid, Some(98));
        assert_eq!(
            message.flags,
            Some(vec!["\\Seen".to_string(), "$Forwarded".to_string()])
        );
        assert_eq!(message.internal_date, Some(837_596_665));
        assert_eq!((message.size, message.modseq), (Some(4286), Some(12_121_231_000)));
        assert_eq!(message.headers.as_deref(), Some(&b"S: x"[..]));
        assert_eq!(message.parts["1"], b"hi");
        assert_eq!(message.source.as_deref(), Some(&b""[..]));
    }

    #[test]
    fn merges_split_responses() {
        let mut first = FetchedMessage {
            seq: 1,
            uid: Some(5),
            ..Default::default()
        };
        let second = FetchedMessage {
            seq: 1,
            flags: Some(vec![]),
            size: Some(3),
            ..Default::default()
        };
        merge(&mut first, second);
        assert_eq!((first.uid, first.size, first.flags.is_some()), (Some(5), Some(3), true));
    }
}
