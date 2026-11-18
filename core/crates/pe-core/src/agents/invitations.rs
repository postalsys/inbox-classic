//! An agent's answer to a calendar invitation (decision 8 of the MCP plan): accept, accept tentatively or decline,
//! only through the Send question. The core writes the answer from the invitation as it came (the calendar file
//! `METHOD:REPLY`, to its organizer, from the address it invited); the agent adds at most a line of text. The user's
//! status of the event changes once the message left the Outbox, never before.

use pe_i18n::{Arg, Text, tr_args};
use pe_mime::parser::{self, text_to_html};
use pe_store::FolderId;

use super::{AgentHost, Asked, Asking, Made, now};
use crate::calendar::Method;
use crate::calendar_reply::Response;
use crate::{Core, Draft, Error, Outgoing, Result};

/// The answer to an invitation a Send question carries
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct InvitationAnswer {
    /// The event's UID
    pub uid: String,
    pub response: Response,
    /// What the question says of it: what it answers, when the event is, and when the user's answer changes
    pub line: String,
}

/// What an agent asks to answer
#[derive(Debug, Clone)]
pub struct InvitationReply {
    pub folder: FolderId,
    pub uid: u64,
    pub response: Response,
    /// A line of the agent's own above the answer's words; empty for none
    pub comment: String,
    /// The agent's request, for the log
    pub call_id: Option<String>,
}

/// Refused: the message is no invitation to answer
fn not_an_invitation(why: &str) -> Error {
    Error::Unavailable(format!("{why} Nothing was asked of the user."))
}

/// An invitation as the core answers it: its calendar part, what it says, and the message it came in
struct Invited {
    calendar: String,
    event: crate::calendar::Invitation,
    message_id: Option<String>,
    references: Vec<String>,
}

/// The invitation of a message's `source`, one that can be answered
fn invited(source: &[u8]) -> Result<Invited> {
    // an agent never reads what is encrypted, and never answers it
    if crate::protect::has_encrypted(source) {
        return Err(Error::Unavailable(pe_i18n::tr(Text::AgentEncrypted)));
    }
    let message = parser::parse(source).map_err(|_| not_an_invitation("The message can not be read."))?;
    let part = crate::view::calendar_part(&message.attachments)
        .ok_or_else(|| not_an_invitation("The message carries no calendar invitation."))?;
    let calendar = String::from_utf8_lossy(&part.content).into_owned();
    let event = crate::calendar::invitation(&calendar, part.method.as_deref())
        .ok_or_else(|| not_an_invitation("The message's calendar file has no event."))?;
    if !matches!(event.method, Method::Request | Method::Update) {
        return Err(not_an_invitation(
            "The message is a cancellation or an answer, not an invitation: there is nothing to accept or decline.",
        ));
    }
    let mut references: Vec<String> = message
        .references
        .as_deref()
        .unwrap_or_default()
        .split_whitespace()
        .map(str::to_string)
        .collect();
    references.extend(message.message_id.clone());
    Ok(Invited {
        calendar,
        event,
        message_id: message.message_id,
        references,
    })
}

/// The values of the answer's words: what it answers and the event's name, with `extra`
fn reply_args<'a>(response: Response, summary: &'a str, extra: &[(&'a str, Arg<'a>)]) -> Vec<(&'a str, Arg<'a>)> {
    let mut all = vec![("response", response.name().into()), ("summary", summary.into())];
    all.extend_from_slice(extra);
    all
}

/// The message that answers `invited` with `answer`, from the user called `name` (the account's first address in
/// `own`), with the agent's `comment` above the answer's words; and that text
fn reply_message(
    invited: &Invited,
    answer: &crate::calendar_reply::Reply,
    reply: &InvitationReply,
    name: &str,
    own: &[String],
) -> (Outgoing, String) {
    let summary = invited.event.summary.as_str();
    let words = tr_args(
        Text::InvitationReplyText,
        &reply_args(reply.response, summary, &[("name", name.into())]),
    );
    let text = match reply.comment.trim() {
        "" => words,
        comment => format!("{comment}\n\n{words}"),
    };
    let outgoing = Outgoing {
        to: answer.organizer.clone(),
        subject: tr_args(Text::InvitationReplySubject, &reply_args(reply.response, summary, &[])),
        html: Some(text_to_html(&text)),
        in_reply_to: invited.message_id.clone(),
        references: invited.references.clone(),
        // from the address it invited, when that is another address of the account
        from: own
            .first()
            .is_some_and(|first| !answer.attendee.eq_ignore_ascii_case(first))
            .then(|| answer.attendee.clone()),
        calendar: Some(pe_smtp::IcalEvent {
            method: "REPLY".into(),
            content: answer.ics.clone(),
        }),
        ..Default::default()
    };
    (outgoing, text)
}

impl Core {
    /// Asks the user whether to send an agent's answer to the invitation of message `reply.uid` of `reply.folder`,
    /// through the Send question. Refused for a message that is encrypted, not downloaded, or no invitation (a
    /// cancellation, an answer), one that does not invite the account, and when the agent may not send now.
    pub fn agent_ask_invitation_reply(
        &self,
        host: &AgentHost,
        reply: &InvitationReply,
        key: Option<&str>,
    ) -> Result<Asked> {
        let (account, source, own, name) = {
            let store = self.store();
            let account = store.folder(reply.folder)?.account_id;
            let source = store
                .source(reply.folder, reply.uid)?
                .ok_or_else(|| Error::Unavailable(pe_i18n::tr(Text::AgentOriginalNotDownloaded)))?;
            let settings = store.account(account)?.settings;
            let name = crate::account_label(&settings.name, &settings.email);
            (account, source, crate::own_addresses(&store, account)?, name)
        };
        let invited = invited(&source)?;
        let answer = crate::calendar_reply::reply(&invited.calendar, &own, reply.response, now()).ok_or_else(|| {
            not_an_invitation(
                "The invitation does not name this account's address as an attendee, or names no organizer.",
            )
        })?;
        let (outgoing, text) = reply_message(&invited, &answer, reply, &name, &own);
        let when = crate::calendar::when(&invited.event);
        let line = tr_args(
            Text::AgentInvitationReply,
            &reply_args(reply.response, &invited.event.summary, &[("when", (&when).into())]),
        );
        let asking = Asking {
            account,
            made: Made {
                outgoing,
                draft: Draft::default(),
                answered: None,
                signature: String::new(),
            },
            text,
            call_id: reply.call_id.clone(),
            invitation: Some(InvitationAnswer {
                uid: answer.uid,
                response: reply.response,
                line,
            }),
        };
        self.ask_to_send(host, asking, key)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_invitations_are_answered() {
        let invitation = |method: &str| {
            format!(
                "From: Ann <ann@example.com>\r\nTo: me@example.com\r\nSubject: Plans\r\nMessage-ID: <i1@example.com>\r\n\
                 References: <r0@example.com>\r\n\
                 Content-Type: text/calendar; method={method}; charset=utf-8\r\n\r\n\
                 BEGIN:VCALENDAR\r\nMETHOD:{method}\r\nBEGIN:VEVENT\r\nUID:1@example.com\r\nSUMMARY:Plans\r\n\
                 DTSTART:20260715T120000Z\r\nORGANIZER:mailto:ann@example.com\r\nATTENDEE:mailto:me@example.com\r\n\
                 END:VEVENT\r\nEND:VCALENDAR\r\n"
            )
        };
        let found = invited(invitation("REQUEST").as_bytes()).unwrap();
        assert_eq!(found.event.summary, "Plans");
        assert_eq!(found.message_id.as_deref(), Some("<i1@example.com>"));
        assert_eq!(found.references, ["<r0@example.com>", "<i1@example.com>"]);
        for method in ["CANCEL", "REPLY"] {
            let refused = invited(invitation(method).as_bytes()).err().unwrap().to_string();
            assert!(refused.contains("not an invitation"), "{refused}");
        }
        let plain = b"From: a@example.com\r\nSubject: x\r\n\r\nNo event here\r\n";
        assert!(
            invited(plain)
                .err()
                .unwrap()
                .to_string()
                .contains("no calendar invitation")
        );
    }
}
