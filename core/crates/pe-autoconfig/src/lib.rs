//! The servers of an e-mail address, found the way Thunderbird finds them: the provider's own configuration file
//! (`autoconfig.<domain>`, then `<domain>/.well-known`), then Thunderbird's ISPDB, then the usual names
//! `imap.<domain>` and `smtp.<domain>`. Only over HTTPS, so nobody on the network can hand out other servers, and
//! never a server without encryption.
#![forbid(unsafe_code)]

mod config;
mod http;

use std::time::Duration;

pub use config::{Server, ServerSecurity, parse_config};
pub use http::{HttpError, Response, parse_response};

/// Where the settings came from
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Source {
    /// The provider's own configuration file
    Provider,
    /// Thunderbird's database of providers
    Ispdb,
    /// `imap.<domain>` and `smtp.<domain>`: nothing was found, these are the usual names
    Guess,
}

/// The servers of an address
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Settings {
    pub imap: Server,
    pub smtp: Server,
    /// The user name for logging in, the templates of the configuration filled in
    pub username: String,
    /// The provider takes OAuth 2.0 (Gmail, Outlook.com)
    pub oauth2: bool,
    pub source: Source,
}

/// How long each lookup may take
const TIMEOUT: Duration = Duration::from_secs(8);

/// The domain of an address in its ASCII form (`bücher.de` is `xn--bcher-kva.de`), lowercased; None when it
/// has none or it is not a host name
pub fn domain_of(email: &str) -> Option<String> {
    let (_, domain) = email.trim().rsplit_once('@')?;
    let domain = idna::domain_to_ascii(domain.trim_end_matches('.')).ok()?;
    let valid = !domain.is_empty()
        && domain.len() <= 253
        && domain.contains('.')
        && domain.split('.').all(|label| {
            !label.is_empty()
                && label.len() <= 63
                && label.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-')
                && !label.starts_with('-')
                && !label.ends_with('-')
        });
    valid.then_some(domain)
}

/// The places to ask, in order: the provider's file at two places, then the ISPDB
pub fn lookup_urls(email: &str, domain: &str) -> Vec<(Source, String, String)> {
    let address: String = email
        .bytes()
        .map(|b| match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' | b'@' => (b as char).to_string(),
            _ => format!("%{b:02X}"),
        })
        .collect();
    vec![
        (
            Source::Provider,
            format!("autoconfig.{domain}"),
            format!("/mail/config-v1.1.xml?emailaddress={address}"),
        ),
        (
            Source::Provider,
            domain.to_string(),
            "/.well-known/autoconfig/mail/config-v1.1.xml".to_string(),
        ),
        (
            Source::Ispdb,
            "autoconfig.thunderbird.net".to_string(),
            format!("/v1.1/{domain}"),
        ),
    ]
}

/// The usual names, for when nothing was found
pub fn guess(email: &str, domain: &str) -> Settings {
    Settings {
        imap: Server {
            host: format!("imap.{domain}"),
            port: 993,
            security: ServerSecurity::Tls,
        },
        smtp: Server {
            host: format!("smtp.{domain}"),
            port: 465,
            security: ServerSecurity::Tls,
        },
        username: email.trim().to_string(),
        oauth2: false,
        source: Source::Guess,
    }
}

/// Finds the servers of `email`; the guess when no configuration is found. None for an address without a
/// domain.
pub async fn discover(email: &str) -> Option<Settings> {
    discover_with(
        email,
        |host, path| async move { http::get(&host, &path, TIMEOUT).await },
    )
    .await
}

/// [`discover`] with another way to fetch, for tests
pub async fn discover_with<F, Fut>(email: &str, fetch: F) -> Option<Settings>
where
    F: Fn(String, String) -> Fut,
    Fut: Future<Output = Result<Response, HttpError>>,
{
    let domain = domain_of(email)?;
    let [first, second, third]: [(Source, String, String); 3] = lookup_urls(email, &domain).try_into().ok()?;
    // all at once: a host that does not answer does not hold up the others
    let (a, b, c) = tokio::join!(
        fetch(first.1, first.2),
        fetch(second.1, second.2),
        fetch(third.1, third.2)
    );
    // the first one that has a configuration, in the order of the sources
    for (source, response) in [(first.0, a), (second.0, b), (third.0, c)] {
        let Ok(response) = response else { continue };
        if response.status != 200 {
            continue;
        }
        let Ok(text) = String::from_utf8(response.body) else {
            continue;
        };
        if let Some(found) = parse_config(&text, email) {
            return Some(Settings {
                imap: found.imap,
                smtp: found.smtp,
                username: found.username,
                oauth2: found.oauth2,
                source,
            });
        }
    }
    Some(guess(email, &domain))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn domains() {
        assert_eq!(domain_of("a@Example.COM").as_deref(), Some("example.com"));
        assert_eq!(domain_of("a@b@example.org.").as_deref(), Some("example.org"));
        assert_eq!(domain_of("a@localhost"), None);
        assert_eq!(domain_of("a@exa mple.com"), None);
        assert_eq!(domain_of("a@-x.com"), None);
        assert_eq!(domain_of("no address"), None);
        assert_eq!(domain_of("a@evil.com/path?x"), None);
        assert_eq!(domain_of("a@Bücher.de").as_deref(), Some("xn--bcher-kva.de"));
    }

    #[test]
    fn urls_are_encoded() {
        let urls = lookup_urls("a+b c@example.com", "example.com");
        assert_eq!(urls[0].1, "autoconfig.example.com");
        assert_eq!(urls[0].2, "/mail/config-v1.1.xml?emailaddress=a%2Bb%20c@example.com");
        assert_eq!(urls[2].2, "/v1.1/example.com");
    }

    fn response(body: &str) -> Result<Response, HttpError> {
        Ok(Response {
            status: 200,
            body: body.as_bytes().to_vec(),
        })
    }

    #[tokio::test]
    async fn the_first_that_answers() {
        let ispdb = r#"<clientConfig><emailProvider id="x"><incomingServer type="imap"><hostname>imap.x.com</hostname><port>993</port><socketType>SSL</socketType><username>%EMAILLOCALPART%</username></incomingServer><outgoingServer type="smtp"><hostname>smtp.x.com</hostname><port>587</port><socketType>STARTTLS</socketType></outgoingServer></emailProvider></clientConfig>"#;
        let found = discover_with("me@x.com", |host, _| async move {
            if host == "autoconfig.thunderbird.net" {
                response(ispdb)
            } else {
                Err(HttpError::Malformed)
            }
        })
        .await
        .unwrap();
        assert_eq!(found.source, Source::Ispdb);
        assert_eq!(found.imap.host, "imap.x.com");
        assert_eq!(found.smtp.security, ServerSecurity::StartTls);
        assert_eq!(found.username, "me");

        // nothing anywhere: the usual names
        let guessed = discover_with("me@y.org", |_, _| async { Err(HttpError::Malformed) })
            .await
            .unwrap();
        assert_eq!(guessed, guess("me@y.org", "y.org"));
        assert_eq!(guessed.imap.host, "imap.y.org");
        assert!(
            discover_with("nodomain", |_, _| async { Err(HttpError::Malformed) })
                .await
                .is_none()
        );
    }
}
