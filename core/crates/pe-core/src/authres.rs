//! Whose word counts in a message's headers: the Authentication-Results (RFC 8601) of the account's own provider. A
//! sender can write such a header too; a provider removes incoming ones that carry its own name (the authserv-id),
//! so the one whose authserv-id is a domain of the provider's (its IMAP server's, the account address's, or a known
//! sibling of them) is the provider's verdict. With none such, nothing passed.
//!
//! Some providers write their verdict in ARC-Authentication-Results (RFC 8617) instead: Microsoft's
//! Authentication-Results carry no authserv-id, its ARC set does (`i=1; mx.microsoft.com 1; dkim=pass ...`). That
//! counts only when no Authentication-Results of the provider's is there, and only the ARC set the provider added
//! itself. A sender can write a whole ARC set too, in the provider's name, at any instance (none is checked: no
//! signature is verified here), and a provider that can not add a set after it (the instances end at 50) adds none.
//! What a sender can not do is put a header above those the provider adds as it receives the message: its
//! Authentication-Results (Microsoft's, without an authserv-id) is there, and its ARC set, sealed last, above it. So
//! the set counts when it comes before the topmost Authentication-Results, is of the highest instance (1 to 50) and
//! the only one of it, carries the provider's authserv-id, and its ARC-Seal of that instance, before it too, is in a
//! domain of the provider's (`d=`).

use pe_mime::parser::Header;
use pe_store::AccountSettings;

/// Providers whose servers sign their verdicts with another domain than the one their users see
const SIBLINGS: &[(&str, &str)] = &[
    ("gmail.com", "google.com"),
    ("googlemail.com", "google.com"),
    ("outlook.com", "outlook.com"),
    ("hotmail.com", "outlook.com"),
    ("live.com", "outlook.com"),
    ("office365.com", "outlook.com"),
    // Microsoft writes its verdict as mx.microsoft.com (ARC-Authentication-Results) and seals as microsoft.com
    ("outlook.com", "microsoft.com"),
    ("hotmail.com", "microsoft.com"),
    ("live.com", "microsoft.com"),
    ("office365.com", "microsoft.com"),
    ("fastmail.com", "messagingengine.com"),
    ("me.com", "icloud.com"),
    ("mac.com", "icloud.com"),
];

/// The part of a host its owner registered: `mx.example.com` and `mail.example.co.uk` to `example.com` and
/// `example.co.uk`
pub(crate) fn registrable(host: &str) -> String {
    let host = host.trim().trim_end_matches('.').to_ascii_lowercase();
    let labels: Vec<&str> = host.split('.').filter(|l| !l.is_empty()).collect();
    let keep = match labels.as_slice() {
        [.., second, last]
            if last.len() == 2 && matches!(*second, "co" | "com" | "org" | "net" | "ac" | "gov" | "edu") =>
        {
            3
        }
        _ => 2,
    };
    labels[labels.len().saturating_sub(keep)..].join(".")
}

/// The domains whose verdicts an account's provider gives
pub(crate) fn trusted(settings: &AccountSettings) -> Vec<String> {
    let mut domains = vec![
        registrable(&settings.imap_host),
        registrable(settings.email.rsplit('@').next().unwrap_or_default()),
    ];
    let siblings: Vec<String> = SIBLINGS
        .iter()
        .filter(|(seen, _)| domains.iter().any(|d| d == seen))
        .map(|(_, signs)| signs.to_string())
        .collect();
    domains.extend(siblings);
    domains.retain(|d| d.contains('.'));
    domains.sort();
    domains.dedup();
    domains
}

/// The headers named `key`, in the order they come (the newest first)
pub(crate) fn headers<'a>(headers: &'a [Header], key: &'a str) -> impl Iterator<Item = &'a str> {
    headers
        .iter()
        .filter(move |h| h.key.eq_ignore_ascii_case(key))
        .map(|h| h.value.as_str())
}

/// The value of a tag (`d=`) or a property (`header.d=`) in a `;` or space separated list
pub(crate) fn tag<'a>(value: &'a str, name: &str) -> Option<&'a str> {
    value
        .split([';', ' ', '\t', '\r', '\n'])
        .filter_map(|part| part.split_once('='))
        .find(|(key, _)| key.trim().eq_ignore_ascii_case(name))
        .map(|(_, value)| value.trim().trim_matches('"'))
}

/// The provider's verdict: the results (after the authserv-id) of the first Authentication-Results whose authserv-id
/// is a `trusted` domain; with none such, those of the provider's own ARC set ([`arc_verdict`])
pub(crate) fn verdict<'a>(all: &'a [Header], trusted: &[String]) -> Option<Vec<&'a str>> {
    headers(all, "authentication-results")
        .find_map(|value| results_of(value, trusted))
        .or_else(|| arc_verdict(all, trusted))
}

/// The results of one Authentication-Results value when its authserv-id (its first word) is `trusted`
fn results_of<'a>(value: &'a str, trusted: &[String]) -> Option<Vec<&'a str>> {
    let mut parts = value.split(';');
    let id = parts.next()?.split_whitespace().next()?;
    is_trusted(id, trusted).then(|| parts.map(str::trim).filter(|r| !r.is_empty()).collect())
}

fn is_trusted(host: &str, trusted: &[String]) -> bool {
    let domain = registrable(host);
    trusted.contains(&domain)
}

/// The instance (`i=`) of an ARC header's value, its first tag: 1 to 50 (RFC 8617 4.2.1), None for any other
fn instance(value: &str) -> Option<u32> {
    let (first, _) = value.split_once(';')?;
    let (name, number) = first.split_once('=')?;
    let number: u32 = (name.trim().eq_ignore_ascii_case("i")).then(|| number.trim().parse().ok())??;
    (1..=50).contains(&number).then_some(number)
}

/// The headers named `key` with their places among all of them
fn placed<'a>(all: &'a [Header], key: &'a str) -> impl Iterator<Item = (usize, &'a str)> {
    all.iter()
        .enumerate()
        .filter(move |(_, h)| h.key.eq_ignore_ascii_case(key))
        .map(|(at, h)| (at, h.value.as_str()))
}

/// The provider's verdict in its ARC set (see the top of this file): the ARC-Authentication-Results of the highest
/// instance, above the topmost Authentication-Results, when its authserv-id is `trusted` and the ARC-Seal of that
/// instance above it too is sealed in a `trusted` domain's name; its results after the authserv-id
pub(crate) fn arc_verdict<'a>(all: &'a [Header], trusted: &[String]) -> Option<Vec<&'a str>> {
    // what the provider added as it received the message: above its Authentication-Results, which must be there
    let (received, _) = placed(all, "authentication-results").next()?;
    let (top, value) = placed(all, "arc-authentication-results")
        .filter_map(|(at, value)| Some((instance(value)?, at, value)))
        .max_by_key(|(i, ..)| *i)
        .filter(|(_, at, _)| *at < received)
        .map(|(i, _, value)| (i, value))?;
    // a second set of the same instance: not the provider's alone, so neither counts
    if headers(all, "arc-authentication-results")
        .filter(|v| instance(v) == Some(top))
        .count()
        > 1
    {
        return None;
    }
    let sealed = placed(all, "arc-seal")
        .filter(|(at, seal)| *at < received && instance(seal) == Some(top))
        .any(|(_, seal)| tag(seal, "d").is_some_and(|d| is_trusted(d, trusted)));
    if !sealed {
        return None;
    }
    // after `i=N;` the authserv-id, then the results as in Authentication-Results
    let (_, rest) = value.split_once(';')?;
    results_of(rest, trusted)
}

/// Whether a result of the verdict is `method=pass` (`dkim=pass header.d=...`)
pub(crate) fn passes(result: &str, method: &str) -> bool {
    result
        .split_whitespace()
        .next()
        .and_then(|r| r.split_once('='))
        .is_some_and(|(m, verdict)| m.eq_ignore_ascii_case(method) && verdict.eq_ignore_ascii_case("pass"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn trusts_the_providers_own_names() {
        assert_eq!(registrable("mx.example.com"), "example.com");
        assert_eq!(registrable("mail.example.co.uk"), "example.co.uk");
        let gmail = AccountSettings {
            name: "Ann".into(),
            email: "ann@gmail.com".into(),
            username: "ann@gmail.com".into(),
            imap_host: "imap.gmail.com".into(),
            imap_port: 993,
            imap_security: pe_store::Security::Tls,
            smtp_host: "smtp.gmail.com".into(),
            smtp_port: 465,
            smtp_security: pe_store::Security::Tls,
            auth: pe_store::Auth::Password,
        };
        assert_eq!(trusted(&gmail), ["gmail.com", "google.com"]);
        let parse = |text: &str| {
            pe_mime::parser::parse(format!("{text}\r\nSubject: x\r\n\r\nx\r\n").as_bytes())
                .unwrap()
                .headers
        };
        let headers = parse(
            "Authentication-Results: forged.example; dkim=pass header.d=bank.example\r\n\
             Authentication-Results: mx.google.com; dkim=fail; dmarc=pass",
        );
        // the sender's own above it counts for nothing: the provider's is the one
        let found = verdict(&headers, &trusted(&gmail)).unwrap();
        assert_eq!(found, ["dkim=fail", "dmarc=pass"]);
        assert!(passes(found[1], "dmarc") && !passes(found[0], "dkim"));
        // with none of the provider's, there is no verdict
        assert_eq!(
            verdict(
                &parse("Authentication-Results: forged.example; dmarc=pass"),
                &trusted(&gmail)
            ),
            None
        );
    }

    fn outlook() -> AccountSettings {
        AccountSettings {
            name: "Ann".into(),
            email: "ann@outlook.com".into(),
            username: "ann@outlook.com".into(),
            imap_host: "outlook.office365.com".into(),
            imap_port: 993,
            imap_security: pe_store::Security::Tls,
            smtp_host: "smtp-mail.outlook.com".into(),
            smtp_port: 587,
            smtp_security: pe_store::Security::StartTls,
            auth: pe_store::Auth::Password,
        }
    }

    fn parse(text: &str) -> Vec<Header> {
        pe_mime::parser::parse(format!("{text}\r\nSubject: x\r\n\r\nx\r\n").as_bytes())
            .unwrap()
            .headers
    }

    /// Microsoft's own verdict, as it delivers it: an Authentication-Results without an authserv-id, its ARC set of
    /// instance 1 above it
    const MICROSOFT: &str = "ARC-Seal: i=1; a=rsa-sha256; s=arcselector10001; d=microsoft.com; cv=none; b=x\r\n\
         ARC-Message-Signature: i=1; a=rsa-sha256; c=relaxed/relaxed; d=microsoft.com; s=arcselector10001; b=y\r\n\
         ARC-Authentication-Results: i=1; mx.microsoft.com 1; spf=pass smtp.mailfrom=bank.example; dmarc=pass\r\n \
         action=none header.from=bank.example; dkim=pass header.d=bank.example; arc=none\r\n\
         Authentication-Results: spf=pass (sender IP is 192.0.2.1) smtp.mailfrom=bank.example; dkim=pass\r\n \
         (signature was verified) header.d=bank.example;dmarc=pass action=none header.from=bank.example;";

    #[test]
    fn microsofts_verdict_is_read_from_its_arc_set() {
        let trusted = trusted(&outlook());
        assert!(trusted.contains(&"microsoft.com".to_string()), "{trusted:?}");
        let headers = parse(MICROSOFT);
        let found = verdict(&headers, &trusted).expect("the verdict of Microsoft's ARC set");
        assert!(
            found
                .iter()
                .any(|r| passes(r, "dmarc") && tag(r, "header.from") == Some("bank.example"))
        );
        assert!(
            found
                .iter()
                .any(|r| passes(r, "dkim") && tag(r, "header.d") == Some("bank.example"))
        );
        // the provider's Authentication-Results, when there is one, is the one that counts
        let both = parse(&format!(
            "Authentication-Results: mx.microsoft.com; dmarc=fail\r\n{MICROSOFT}"
        ));
        assert_eq!(verdict(&both, &trusted).unwrap(), ["dmarc=fail"]);
    }

    #[test]
    fn an_arc_set_the_sender_wrote_counts_for_nothing() {
        let trusted = trusted(&outlook());
        // below the provider's own set: the highest instance is the provider's, whose verdict is a failure
        let under = parse(
            "ARC-Seal: i=2; a=rsa-sha256; d=microsoft.com; cv=fail; b=x\r\n\
             ARC-Authentication-Results: i=2; mx.microsoft.com 1; dmarc=fail header.from=bank.example\r\n\
             Authentication-Results: dmarc=fail header.from=bank.example\r\n\
             ARC-Seal: i=1; a=rsa-sha256; d=microsoft.com; cv=none; b=x\r\n\
             ARC-Authentication-Results: i=1; mx.microsoft.com 1; dmarc=pass header.from=bank.example",
        );
        assert_eq!(
            verdict(&under, &trusted).unwrap(),
            ["dmarc=fail header.from=bank.example"]
        );
        // where the provider added no set: a seal in another name, or none, is no verdict
        let other_seal = parse(
            "ARC-Seal: i=1; a=rsa-sha256; d=forged.example; cv=none; b=x\r\n\
             ARC-Authentication-Results: i=1; mx.microsoft.com 1; dmarc=pass header.from=bank.example",
        );
        assert_eq!(verdict(&other_seal, &trusted), None);
        let unsealed =
            parse("ARC-Authentication-Results: i=1; mx.microsoft.com 1; dmarc=pass header.from=bank.example");
        assert_eq!(verdict(&unsealed, &trusted), None);
        // another provider's name in the set
        let elsewhere = parse(
            "ARC-Seal: i=1; a=rsa-sha256; d=forged.example; cv=none; b=x\r\n\
             ARC-Authentication-Results: i=1; mx.forged.example; dmarc=pass header.from=bank.example",
        );
        assert_eq!(verdict(&elsewhere, &trusted), None);
        // two sets of the same instance: neither is the provider's alone
        let twice = parse(&format!(
            "ARC-Authentication-Results: i=1; mx.microsoft.com 1; dmarc=pass header.from=evil.example\r\n{MICROSOFT}"
        ));
        assert_eq!(verdict(&twice, &trusted), None);
        // the sender's whole set at the last instance, where the provider can add none after it: below the provider's
        // Authentication-Results, so not the provider's
        let last = parse(
            "Authentication-Results: spf=fail smtp.mailfrom=bank.example; dmarc=fail header.from=bank.example\r\n\
             ARC-Seal: i=50; a=rsa-sha256; d=microsoft.com; cv=pass; b=x\r\n\
             ARC-Authentication-Results: i=50; mx.microsoft.com 1; dmarc=pass header.from=bank.example",
        );
        assert_eq!(verdict(&last, &trusted), None);
        // an instance past the last there can be is none
        let past = parse(
            "ARC-Seal: i=4294967295; a=rsa-sha256; d=microsoft.com; cv=pass; b=x\r\n\
             ARC-Authentication-Results: i=4294967295; mx.microsoft.com 1; dmarc=pass header.from=evil.example\r\n\
             Authentication-Results: dmarc=fail header.from=bank.example",
        );
        assert_eq!(verdict(&past, &trusted), None);
        // with no Authentication-Results of the provider's at all, no ARC set counts
        let alone = parse(
            "ARC-Seal: i=1; a=rsa-sha256; d=microsoft.com; cv=none; b=x\r\n\
             ARC-Authentication-Results: i=1; mx.microsoft.com 1; dmarc=pass header.from=bank.example",
        );
        assert_eq!(verdict(&alone, &trusted), None);
    }
}
