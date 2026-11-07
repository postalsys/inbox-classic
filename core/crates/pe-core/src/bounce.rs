//! The card of a bounce in the reading pane: what pe-bounce found in a notice that a message was not delivered (or
//! not yet), in the user's language. pe-html draws it.

use pe_bounce::{Bounce, BounceKind, Label, Recipient};
use pe_html::{BounceCard, CardDetail, CardPicture, CardReason};
use pe_i18n::{Text, tr, tr_args};

/// The picture of a reason: six cover the 16
pub(crate) fn picture(label: Label) -> CardPicture {
    match label {
        Label::UserUnknown | Label::InvalidAddress | Label::MailboxDisabled => CardPicture::Address,
        Label::MailboxFull => CardPicture::Mailbox,
        Label::IpBlacklisted | Label::DomainBlacklisted | Label::PolicyBlocked | Label::GeoBlocked => {
            CardPicture::Block
        }
        Label::SpamBlocked | Label::VirusDetected => CardPicture::Spam,
        Label::RelayDenied | Label::AuthFailure | Label::ServerError | Label::Unknown => CardPicture::Server,
        Label::RateLimited | Label::Greylisting => CardPicture::Clock,
    }
}

/// The words of a reason: what it is, why, and what to do about it
pub(crate) fn words(label: Label) -> [Text; 3] {
    match label {
        Label::UserUnknown => [
            Text::BounceUserUnknown,
            Text::BounceUserUnknownWhy,
            Text::BounceUserUnknownDo,
        ],
        Label::InvalidAddress => [
            Text::BounceInvalidAddress,
            Text::BounceInvalidAddressWhy,
            Text::BounceInvalidAddressDo,
        ],
        Label::MailboxDisabled => [
            Text::BounceMailboxDisabled,
            Text::BounceMailboxDisabledWhy,
            Text::BounceMailboxDisabledDo,
        ],
        Label::MailboxFull => [
            Text::BounceMailboxFull,
            Text::BounceMailboxFullWhy,
            Text::BounceMailboxFullDo,
        ],
        Label::SpamBlocked => [
            Text::BounceSpamBlocked,
            Text::BounceSpamBlockedWhy,
            Text::BounceSpamBlockedDo,
        ],
        Label::VirusDetected => [
            Text::BounceVirusDetected,
            Text::BounceVirusDetectedWhy,
            Text::BounceVirusDetectedDo,
        ],
        Label::IpBlacklisted => [
            Text::BounceIpBlocklisted,
            Text::BounceIpBlocklistedWhy,
            Text::BounceIpBlocklistedDo,
        ],
        Label::DomainBlacklisted => [
            Text::BounceDomainBlocklisted,
            Text::BounceDomainBlocklistedWhy,
            Text::BounceDomainBlocklistedDo,
        ],
        Label::PolicyBlocked => [
            Text::BouncePolicyBlocked,
            Text::BouncePolicyBlockedWhy,
            Text::BouncePolicyBlockedDo,
        ],
        Label::GeoBlocked => [
            Text::BounceGeoBlocked,
            Text::BounceGeoBlockedWhy,
            Text::BounceGeoBlockedDo,
        ],
        Label::RelayDenied => [
            Text::BounceRelayDenied,
            Text::BounceRelayDeniedWhy,
            Text::BounceRelayDeniedDo,
        ],
        Label::AuthFailure => [
            Text::BounceAuthFailure,
            Text::BounceAuthFailureWhy,
            Text::BounceAuthFailureDo,
        ],
        Label::RateLimited => [
            Text::BounceRateLimited,
            Text::BounceRateLimitedWhy,
            Text::BounceRateLimitedDo,
        ],
        Label::Greylisting => [
            Text::BounceGreylisting,
            Text::BounceGreylistingWhy,
            Text::BounceGreylistingDo,
        ],
        Label::ServerError => [
            Text::BounceServerError,
            Text::BounceServerErrorWhy,
            Text::BounceServerErrorDo,
        ],
        Label::Unknown => [Text::BounceUnknown, Text::BounceUnknownWhy, Text::BounceUnknownDo],
    }
}

/// How long the receiving server asked to wait, in minutes up to an hour and a half, in hours after
fn retry_note(seconds: u32) -> String {
    let minutes = seconds.div_ceil(60).max(1);
    if minutes < 90 {
        tr_args(Text::BounceRetryMinutes, &[("count", i64::from(minutes).into())])
    } else {
        let hours = (minutes + 30) / 60;
        tr_args(Text::BounceRetryHours, &[("count", i64::from(hours).into())])
    }
}

/// A recipient's address as the card shows it
fn address(recipient: &Recipient) -> String {
    recipient.address.clone().unwrap_or_else(|| tr(Text::BounceSomeone))
}

/// What to do about a recipient the message is still on its way to, in place of the reason's own advice (which is for
/// a failure); None for greylisting, whose own advice is that already. Among failures it also says that this one is
/// still being tried, which a delay's card says above its reasons.
fn delayed_advice(label: Label, kind: BounceKind, card: BounceKind) -> Option<Text> {
    match (kind, card) {
        (BounceKind::Failed, _) => None,
        _ if label == Label::Greylisting => None,
        (BounceKind::Delayed, BounceKind::Delayed) => Some(Text::BounceDelayedDo),
        (BounceKind::Delayed, BounceKind::Failed) => Some(Text::BounceDelayedRowDo),
    }
}

/// The reasons of the card: recipients with the same reason (and both failed, or both delayed) together, in the
/// order the notice names them
fn reasons(bounce: &Bounce) -> Vec<CardReason> {
    let mut groups: Vec<(Label, BounceKind, Vec<&Recipient>)> = Vec::new();
    for recipient in &bounce.recipients {
        match groups
            .iter_mut()
            .find(|(label, kind, _)| *label == recipient.label && *kind == recipient.kind)
        {
            Some((_, _, members)) => members.push(recipient),
            None => groups.push((recipient.label, recipient.kind, vec![recipient])),
        }
    }
    groups
        .into_iter()
        .map(|(label, kind, members)| {
            let [title, why, advice] = words(label);
            let mut notes = Vec::new();
            if let Some(seconds) = members.iter().filter_map(|r| r.retry_after).max() {
                notes.push(retry_note(seconds));
            }
            let mut lists: Vec<&str> = Vec::new();
            for list in members
                .iter()
                .filter_map(|r| r.blocklist.as_ref())
                .flat_map(|b| b.lists())
            {
                if !lists.contains(&list.name) {
                    lists.push(list.name);
                }
            }
            // a list's family named beside one of its lists: the list says more (Spamhaus beside Spamhaus ZEN)
            let named = lists.clone();
            lists.retain(|list| {
                !named
                    .iter()
                    .any(|other| other.len() > list.len() && other.starts_with(&format!("{list} ")))
            });
            if !lists.is_empty() {
                notes.push(tr_args(Text::BounceBlocklist, &[("lists", (&lists.join(", ")).into())]));
            }
            CardReason {
                picture: Some(picture(label)),
                // a reason the notice gives without naming anyone stands on its own
                addresses: members
                    .iter()
                    .filter(|r| r.address.is_some())
                    .map(|r| address(r))
                    .collect(),
                title: tr(title),
                why: tr(why),
                advice: tr(delayed_advice(label, kind, bounce.kind).unwrap_or(advice)),
                delayed: kind == BounceKind::Delayed,
                notes,
            }
        })
        .collect()
}

/// What the notice says of each recipient, for Details
fn details(bounce: &Bounce) -> Vec<CardDetail> {
    bounce
        .recipients
        .iter()
        .map(|recipient| {
            let mut lines = Vec::new();
            if let Some(server) = &recipient.remote_mta {
                lines.push(tr_args(Text::BounceServer, &[("server", server.into())]));
            }
            if let Some(status) = &recipient.status {
                lines.push(tr_args(Text::BounceStatus, &[("status", status.into())]));
            }
            CardDetail {
                address: address(recipient),
                lines,
                words: recipient.diagnostic.clone().unwrap_or_default(),
            }
        })
        .collect()
}

/// The card of `bounce`; `linked` when the message it returns is in the store, for the card to link to
pub(crate) fn card(bounce: &Bounce, linked: bool) -> BounceCard {
    let delayed = bounce.kind == BounceKind::Delayed;
    let mut lines = Vec::new();
    if delayed {
        lines.push(tr(Text::BounceDelayedNote));
    }
    if let Some(subject) = bounce.original.as_ref().and_then(|o| o.subject.as_deref()) {
        lines.push(format!("{}: {subject}", tr(Text::HeaderSubject)));
    }
    BounceCard {
        delayed,
        heading: tr(if delayed {
            Text::BounceDelayed
        } else {
            Text::BounceFailed
        }),
        lines,
        link: linked.then(|| tr(Text::BounceShowMessage)),
        advice_label: tr(Text::BounceWhatToDo),
        reasons: reasons(bounce),
        details_label: tr(Text::BounceDetails),
        details: details(bounce),
        details_note: bounce
            .reporting_mta
            .as_ref()
            .map(|server| tr_args(Text::BounceReportedBy, &[("server", server.into())]))
            .unwrap_or_default(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_label_has_a_picture_and_its_own_words() {
        let mut seen = std::collections::HashSet::new();
        for label in Label::ALL {
            let _ = picture(label);
            for text in words(label) {
                assert!(seen.insert(text), "{label:?} shares {text:?}");
                assert!(!tr(text).is_empty());
            }
        }
        assert_eq!(seen.len(), 48);
        // six pictures in all
        let pictures: std::collections::HashSet<_> = Label::ALL.iter().map(|l| format!("{:?}", picture(*l))).collect();
        assert_eq!(pictures.len(), 6);
    }

    #[test]
    fn a_delay_is_not_told_to_send_again() {
        use BounceKind::{Delayed, Failed};
        assert_eq!(delayed_advice(Label::ServerError, Failed, Failed), None);
        assert_eq!(
            delayed_advice(Label::ServerError, Delayed, Delayed),
            Some(Text::BounceDelayedDo)
        );
        assert_eq!(
            delayed_advice(Label::MailboxFull, Delayed, Failed),
            Some(Text::BounceDelayedRowDo)
        );
        assert_eq!(delayed_advice(Label::Greylisting, Delayed, Failed), None);
        assert_eq!(delayed_advice(Label::Greylisting, Delayed, Delayed), None);
    }

    #[test]
    fn waits_in_minutes_then_hours() {
        assert_eq!(
            retry_note(30),
            "The receiving server asked to wait a minute before the next try."
        );
        assert_eq!(
            retry_note(300),
            "The receiving server asked to wait 5 minutes before the next try."
        );
        assert_eq!(
            retry_note(7200),
            "The receiving server asked to wait 2 hours before the next try."
        );
    }
}
