//! Whose word counts in a message's headers: the Authentication-Results (RFC 8601) of the account's own provider. A
//! sender can write such a header too; a provider removes incoming ones that carry its own name (the authserv-id),
//! so the one whose authserv-id is a domain of the provider's (its IMAP server's, the account address's, or a known
//! sibling of them) is the provider's verdict. With none such, nothing passed.

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
/// is a `trusted` domain
pub(crate) fn verdict<'a>(all: &'a [Header], trusted: &[String]) -> Option<Vec<&'a str>> {
    headers(all, "authentication-results").find_map(|value| {
        let mut parts = value.split(';');
        let id = parts.next()?.split_whitespace().next()?;
        trusted
            .iter()
            .any(|domain| registrable(id) == *domain)
            .then(|| parts.map(str::trim).filter(|r| !r.is_empty()).collect())
    })
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
}
