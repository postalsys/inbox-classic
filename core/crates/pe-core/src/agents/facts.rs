//! What an agent is told of a message beyond its text, as the reading pane shows it: the bounce explained (pe-bounce),
//! the calendar invitation with the user's own answer, whether the account's provider confirmed the sender
//! (Authentication-Results, as the pictures and the sender's card go by), and the signature of a signed message. All
//! of it from the message as it came; an encrypted message has none of it but the sender's check ([`super::agent_message`]).

use pe_mime::parser::{self, Message};

use crate::calendar::{Invitation, Method};
use crate::protect::{KeyRing, Signature};

/// What the core needs to know of a message's place to tell an agent about it
#[derive(Default)]
pub struct Context<'a> {
    /// The domains whose Authentication-Results the account's provider gives
    pub trusted: &'a [String],
    /// The user's own addresses, to find their answer to an invitation
    pub own: &'a [String],
    /// The keys to check a signature with; None for a message that has no signature
    pub ring: Option<&'a KeyRing>,
    /// The user's answers to invitations that were sent, by the event's UID: their status from then on
    pub replies: &'a [(String, String)],
}

/// A recipient a bounce says the message did not reach (or not yet)
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct BouncedRecipient {
    /// Empty when the notice does not say
    pub address: String,
    /// Not yet delivered and still being tried, rather than failed for good
    pub delayed: bool,
    /// The enhanced status code, `5.1.1`
    pub status: String,
    /// What the server's words mean, bounce-classifier's name: `user_unknown`, `mailbox_full`...
    pub category: String,
    /// What to do about it, bounce-classifier's name: `remove`, `retry`...
    pub action: String,
    /// The remote server's own words
    pub server_words: String,
    /// The server that refused it
    pub server: String,
}

/// A bounce, as an agent is told it
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct AgentBounce {
    /// Every recipient only delayed: the message is still on its way
    pub delayed: bool,
    pub recipients: Vec<BouncedRecipient>,
    /// The returned message's subject and Message-ID, as the notice quotes them
    pub original_subject: String,
    pub original_message_id: String,
}

/// A calendar invitation, as an agent is told it
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct AgentInvitation {
    /// `request`, `update`, `cancel` or `reply`
    pub method: &'static str,
    pub summary: String,
    /// Seconds since the Unix epoch; for a `floating` time, the wall time as if it were UTC
    pub start: Option<i64>,
    pub end: Option<i64>,
    pub all_day: bool,
    /// The times are as written, in no zone
    pub floating: bool,
    pub location: String,
    pub organizer: String,
    pub attendees: usize,
    /// How it repeats, in words; empty for once
    pub repeats: String,
    /// The user's own answer as the invitation has it (`needs-action`, `accepted`, `declined`, `tentative`); empty
    /// when it does not name them
    pub your_status: String,
}

/// The signature of a message signed (and not encrypted), as an agent is told it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AgentSignature {
    /// `verified` (the sender's key, which the user verified), `signed` (the sender's key, not verified), `other_person`
    /// (a good signature by someone else), `unknown_key`, `bad` or `not_checked`
    pub state: &'static str,
    /// Who signed it, when known
    pub signer: String,
    /// The whole message is signed, not only a part of it
    pub whole: bool,
}

/// The facts of a message an agent is told besides its text
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Facts {
    pub bounce: Option<AgentBounce>,
    pub invitation: Option<AgentInvitation>,
    /// Whether the provider confirmed the sender's domain (DMARC, or DKIM of its domain); None when it gave no
    /// verdict of its own
    pub sender_verified: Option<bool>,
    pub signature: Option<AgentSignature>,
}

/// Whether the provider confirmed the sender of `message`: None without a verdict of its own
pub(crate) fn sender_verified(message: &Message, trusted: &[String]) -> Option<bool> {
    crate::authres::verdict(&message.headers, trusted)?;
    Some(crate::pictures::sender(message, trusted).is_some_and(|sender| sender.verified))
}

/// The bounce `source` is, None for any other message
fn bounce(message: &Message, source: &[u8]) -> Option<AgentBounce> {
    if !pe_bounce::detect::may_be_bounce(message) {
        return None;
    }
    let bounce = pe_bounce::analyze(source)?;
    let recipients = bounce
        .recipients
        .iter()
        .map(|r| BouncedRecipient {
            address: r.address.clone().unwrap_or_default(),
            delayed: r.kind == pe_bounce::BounceKind::Delayed,
            status: r.status.clone().unwrap_or_default(),
            category: r.label.name().into(),
            action: r.action.name().into(),
            server_words: r.diagnostic.clone().unwrap_or_default(),
            server: r.remote_mta.clone().unwrap_or_default(),
        })
        .collect();
    let original = bounce.original.as_ref();
    Some(AgentBounce {
        delayed: bounce.kind == pe_bounce::BounceKind::Delayed,
        recipients,
        original_subject: original.and_then(|o| o.subject.clone()).unwrap_or_default(),
        original_message_id: original.and_then(|o| o.message_id.clone()).unwrap_or_default(),
    })
}

fn method_name(method: Method) -> &'static str {
    match method {
        Method::Request => "request",
        Method::Update => "update",
        Method::Cancel => "cancel",
        Method::Reply => "reply",
    }
}

/// The invitation of `message`'s calendar part, with the answer of the attendee who is the user (`own`): the last one
/// they sent (`replies`), or the one the invitation names
fn invitation(message: &Message, own: &[String], replies: &[(String, String)]) -> Option<AgentInvitation> {
    let part = crate::view::calendar_part(&message.attachments)?;
    let calendar = String::from_utf8_lossy(&part.content);
    let Invitation {
        method,
        summary,
        start,
        end,
        all_day,
        floating,
        location,
        organizer,
        attendees,
        repeats,
    } = crate::calendar::invitation(&calendar, part.method.as_deref())?;
    Some(AgentInvitation {
        method: method_name(method),
        summary,
        start,
        end,
        all_day,
        floating,
        location,
        organizer,
        attendees,
        repeats,
        your_status: crate::calendar_reply::event_uid(&calendar)
            .and_then(|uid| replies.iter().find(|(event, _)| *event == uid))
            .map(|(_, status)| status.clone())
            .or_else(|| crate::calendar::attendee_status(&calendar, own))
            .unwrap_or_default(),
    })
}

/// What a signature is, in the words an agent is told
fn signature_state(signature: &Signature) -> Option<(&'static str, String)> {
    Some(match signature {
        Signature::None => return None,
        Signature::Verified { signer, .. } => ("verified", signer.clone()),
        Signature::Signed { signer, .. } => ("signed", signer.clone()),
        Signature::OtherPerson { signer, .. } => ("other_person", signer.clone()),
        Signature::UnknownKey { .. } => ("unknown_key", String::new()),
        Signature::Bad { .. } => ("bad", String::new()),
        Signature::NotChecked => ("not_checked", String::new()),
    })
}

/// The signature of `source` as the reading pane checks it: the whole message's, or the first signed part's
fn signature(source: &[u8], ring: &KeyRing) -> Option<AgentSignature> {
    let from = crate::from_addresses(source);
    let protected = crate::protect::read(source, ring, &from, crate::worker::unix_now())?;
    let whole = protected.envelope.as_ref();
    let verdict = whole.or_else(|| protected.sections.iter().find_map(|s| s.verdict.as_ref()))?;
    let (state, signer) = signature_state(&verdict.signature)?;
    Some(AgentSignature {
        state,
        signer,
        whole: whole.is_some(),
    })
}

/// The facts of a message that is not encrypted, `message` parsed from `source`
pub(crate) fn of(message: &Message, source: &[u8], context: &Context) -> Facts {
    Facts {
        bounce: bounce(message, source),
        invitation: invitation(message, context.own, context.replies),
        sender_verified: sender_verified(message, context.trusted),
        signature: context.ring.and_then(|ring| signature(source, ring)),
    }
}

/// The facts of an encrypted message: only whether the provider confirmed its sender, from its outer header
pub(crate) fn of_envelope(message: &parser::Message, context: &Context) -> Facts {
    Facts {
        sender_verified: sender_verified(message, context.trusted),
        ..Default::default()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn parsed(source: &[u8]) -> Message {
        parser::parse(source).unwrap()
    }

    #[test]
    fn the_sender_is_confirmed_by_the_providers_verdict_only() {
        let trusted = ["example.com".to_string()];
        let confirmed = b"Authentication-Results: mx.example.com; dmarc=pass header.from=shop.example\r\n\
            From: Shop <news@shop.example>\r\nSubject: x\r\n\r\nx\r\n";
        assert_eq!(sender_verified(&parsed(confirmed), &trusted), Some(true));
        let failed = b"Authentication-Results: mx.example.com; dmarc=fail header.from=shop.example\r\n\
            From: Shop <news@shop.example>\r\nSubject: x\r\n\r\nx\r\n";
        assert_eq!(sender_verified(&parsed(failed), &trusted), Some(false));
        // a verdict of someone else's server says nothing
        let foreign = b"Authentication-Results: mx.evil.example; dmarc=pass header.from=shop.example\r\n\
            From: Shop <news@shop.example>\r\nSubject: x\r\n\r\nx\r\n";
        assert_eq!(sender_verified(&parsed(foreign), &trusted), None);
    }

    #[test]
    fn an_invitation_says_the_users_answer() {
        let source = b"From: carol@example.com\r\nSubject: Plan\r\nContent-Type: multipart/mixed; boundary=c\r\n\r\n\
            --c\r\nContent-Type: text/plain\r\n\r\nSee you.\r\n\
            --c\r\nContent-Type: text/calendar; method=REQUEST\r\n\r\n\
            BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nSUMMARY:Plan\r\nDTSTART:20261120T090000Z\r\n\
            ATTENDEE;CN=Bob:mailto:bob@example.com\r\nATTENDEE;PARTSTAT=ACCEPTED;CN=Me:MAILTO:Me@Example.com\r\n\
            END:VEVENT\r\nEND:VCALENDAR\r\n--c--\r\n";
        let own = ["me@example.com".to_string()];
        let facts = of(
            &parsed(source),
            source,
            &Context {
                own: &own,
                ..Default::default()
            },
        );
        let invitation = facts.invitation.unwrap();
        assert_eq!((invitation.method, invitation.summary.as_str()), ("request", "Plan"));
        assert_eq!(invitation.your_status, "accepted");
        assert_eq!(invitation.attendees, 2);
        // not among the attendees: nothing said
        let facts = of(&parsed(source), source, &Context::default());
        assert_eq!(facts.invitation.unwrap().your_status, "");
        assert!(facts.bounce.is_none() && facts.signature.is_none());
    }

    #[test]
    fn a_bounce_is_explained() {
        let source = b"From: MAILER-DAEMON@example.com\r\nTo: me@example.com\r\nSubject: Undelivered Mail\r\n\
            Content-Type: multipart/report; report-type=delivery-status; boundary=r\r\n\r\n\
            --r\r\nContent-Type: text/plain\r\n\r\nYour message could not be delivered.\r\n\
            --r\r\nContent-Type: message/delivery-status\r\n\r\nReporting-MTA: dns; mx.example.com\r\n\r\n\
            Final-Recipient: rfc822; gone@example.org\r\nAction: failed\r\nStatus: 5.1.1\r\n\
            Diagnostic-Code: smtp; 550 5.1.1 The email account that you tried to reach does not exist\r\n\
            --r\r\nContent-Type: message/rfc822\r\n\r\nFrom: me@example.com\r\nTo: gone@example.org\r\n\
            Subject: Hello\r\nMessage-ID: <hello@example.com>\r\n\r\nHi\r\n--r--\r\n";
        let bounce = of(&parsed(source), source, &Context::default()).bounce.unwrap();
        assert!(!bounce.delayed);
        let recipient = &bounce.recipients[0];
        assert_eq!(recipient.address, "gone@example.org");
        assert_eq!(
            (recipient.status.as_str(), recipient.category.as_str()),
            ("5.1.1", "user_unknown")
        );
        assert!(recipient.server_words.contains("does not exist"), "{recipient:?}");
        assert_eq!(bounce.original_subject, "Hello");
    }

    #[test]
    fn a_signature_is_told_as_the_reading_pane_checks_it() {
        let source = b"From: Ann <ann@example.com>\r\nTo: me@example.com\r\nSubject: Signed\r\n\
            Content-Type: multipart/signed; micalg=pgp-sha256; protocol=\"application/pgp-signature\"; boundary=s\r\n\r\n\
            --s\r\nContent-Type: text/plain\r\n\r\nThe plan.\r\n\
            --s\r\nContent-Type: application/pgp-signature\r\n\r\n\
            -----BEGIN PGP SIGNATURE-----\r\n\r\nAAAA\r\n-----END PGP SIGNATURE-----\r\n--s--\r\n";
        let ring = KeyRing::default();
        let facts = of(
            &parsed(source),
            source,
            &Context {
                ring: Some(&ring),
                ..Default::default()
            },
        );
        let signature = facts.signature.unwrap();
        assert!(signature.whole);
        // a signature that can not be checked here is never told as good
        assert!(matches!(signature.state, "bad" | "unknown_key"), "{signature:?}");
        // a message that is not signed has none
        let plain = b"From: a@example.com\r\nSubject: x\r\n\r\nx\r\n";
        assert!(
            of(
                &parsed(plain),
                plain,
                &Context {
                    ring: Some(&ring),
                    ..Default::default()
                }
            )
            .signature
            .is_none()
        );
    }
}
