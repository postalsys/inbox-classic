//! Whether a message's pictures on the internet load without the user's click: the setting that loads every
//! message's, or a sender the user trusts (an address, or a whole domain, pe-store `trusted.rs`) when the account's
//! provider confirms the message comes from that domain, so a forged From asks as before. Never in Junk E-mail.

use pe_mime::parser::{Message, ParsedAddress};
use pe_store::TrustedSender;

use crate::authres::{passes, registrable, tag, verdict};

/// What decides the pictures of a message of a folder
#[derive(Default)]
pub(crate) struct Rules<'a> {
    /// Options' "Download pictures in all messages"
    pub always: bool,
    /// The folder is Junk E-mail: nothing loads by itself there
    pub junk: bool,
    pub senders: &'a [TrustedSender],
}

/// The message's sender as the bar names them: the From address in lower case, its domain, and whether the provider
/// confirmed that domain
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Sender {
    pub address: String,
    pub domain: String,
    pub verified: bool,
}

/// The sender of `message`, None for a From that is no single address
pub(crate) fn sender(message: &Message, trusted: &[String]) -> Option<Sender> {
    let Some(ParsedAddress::Mailbox(from)) = &message.from else {
        return None;
    };
    let address = from.address.trim().to_lowercase();
    let (_, domain) = address
        .rsplit_once('@')
        .filter(|(user, domain)| !user.is_empty() && domain.contains('.'))?;
    let domain = domain.to_string();
    let verified = from_verified(&message.headers, trusted, &domain);
    Some(Sender {
        address,
        domain,
        verified,
    })
}

/// Whether the provider's Authentication-Results (from a `trusted` authserv-id) confirm `domain` sent the message:
/// DMARC passed for it as the From domain, or DKIM passed for a signature of it or of its organization (relaxed
/// alignment, as DMARC counts it)
pub(crate) fn from_verified(headers: &[pe_mime::parser::Header], trusted: &[String], domain: &str) -> bool {
    let Some(results) = verdict(headers, trusted) else {
        return false;
    };
    results.iter().any(|result| {
        let dmarc =
            passes(result, "dmarc") && tag(result, "header.from").is_some_and(|d| d.eq_ignore_ascii_case(domain));
        let dkim = passes(result, "dkim")
            && tag(result, "header.d").is_some_and(|d| registrable(&d.to_ascii_lowercase()) == registrable(domain));
        dmarc || dkim
    })
}

/// Whether the pictures load without asking
pub(crate) fn load(rules: &Rules, sender: Option<&Sender>) -> bool {
    if rules.junk {
        return false;
    }
    rules.always || sender.is_some_and(|sender| sender.verified && trusts(rules.senders, sender))
}

/// Whether the list trusts the sender, by their address or their whole domain (not a parent domain's)
pub(crate) fn trusts(senders: &[TrustedSender], sender: &Sender) -> bool {
    senders.iter().any(|trusted| match trusted.domain {
        true => trusted.value == sender.domain,
        false => trusted.value == sender.address,
    })
}

/// What the pictures bar offers for `sender`: Always from the address and from everyone at the domain when the
/// provider confirmed them, otherwise the line that says why it cannot
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct BarWords {
    pub always_sender: String,
    pub always_domain: String,
    pub unconfirmed: String,
}

pub fn bar_words(sender: &Sender) -> BarWords {
    use pe_i18n::{Text, tr_args};
    if !sender.verified {
        return BarWords {
            unconfirmed: tr_args(
                Text::UiPicturesUnconfirmed,
                &[("domain", sender.domain.as_str().into())],
            ),
            ..Default::default()
        };
    }
    BarWords {
        always_sender: tr_args(
            Text::UiPicturesAlwaysSender,
            &[("sender", sender.address.as_str().into())],
        ),
        always_domain: tr_args(
            Text::UiPicturesAlwaysDomain,
            &[("domain", sender.domain.as_str().into())],
        ),
        unconfirmed: String::new(),
    }
}

/// How the Trusted Senders list names an entry: the address, or "Everyone at shop.com"
pub fn trusted_label(sender: &TrustedSender) -> String {
    match sender.domain {
        true => pe_i18n::tr_args(
            pe_i18n::Text::UiTrustedEveryoneAt,
            &[("domain", sender.value.as_str().into())],
        ),
        false => sender.value.clone(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn message(from: &str, results: &str) -> Message {
        let source = format!(
            "From: {from}\r\nAuthentication-Results: mx.provider.example; {results}\r\nSubject: hi\r\n\r\nbody"
        );
        pe_mime::parser::parse(source.as_bytes()).unwrap()
    }

    fn rules(senders: &[TrustedSender], always: bool, junk: bool) -> Rules<'_> {
        Rules { always, junk, senders }
    }

    fn trusted(value: &str, domain: bool) -> TrustedSender {
        TrustedSender {
            id: 1,
            value: value.into(),
            domain,
        }
    }

    #[test]
    fn a_trusted_sender_loads_only_when_confirmed() {
        let providers = vec!["provider.example".to_string()];
        let dkim = message(
            "Shop <News@Shop.com>",
            "dkim=pass header.d=mail.shop.com; dmarc=pass header.from=shop.com",
        );
        let sender = sender(&dkim, &providers).unwrap();
        assert_eq!(
            (sender.address.as_str(), sender.domain.as_str(), sender.verified),
            ("news@shop.com", "shop.com", true)
        );

        let forged = message(
            "Shop <news@shop.com>",
            "dkim=fail header.d=shop.com; dmarc=fail header.from=shop.com",
        );
        let forged = super::sender(&forged, &providers).unwrap();
        assert!(!forged.verified);
        let other_provider = message("news@shop.com", "dkim=pass header.d=shop.com");
        assert!(
            !super::sender(&other_provider, &["someone.else".to_string()])
                .unwrap()
                .verified,
            "a verdict of a provider not the account's"
        );
        let other_signer = message("news@shop.com", "dkim=pass header.d=bulk-mailer.net");
        assert!(
            !super::sender(&other_signer, &providers).unwrap().verified,
            "signed by another domain"
        );

        let by_address = [trusted("news@shop.com", false)];
        let by_domain = [trusted("shop.com", true)];
        assert!(load(&rules(&by_address, false, false), Some(&sender)));
        assert!(load(&rules(&by_domain, false, false), Some(&sender)));
        assert!(
            !load(&rules(&by_domain, false, false), Some(&forged)),
            "a forged From asks"
        );
        assert!(!load(
            &rules(&[trusted("ann@shop.com", false)], false, false),
            Some(&sender)
        ));
        assert!(!load(
            &rules(&[trusted("mail.shop.com", true)], false, false),
            Some(&sender)
        ));
        assert!(load(&rules(&[], true, false), None), "always");
        assert!(
            !load(&rules(&by_domain, true, true), Some(&sender)),
            "never in Junk E-mail"
        );
        assert!(super::sender(&message("undisclosed-recipients:;", "dkim=pass"), &providers).is_none());
    }
}
