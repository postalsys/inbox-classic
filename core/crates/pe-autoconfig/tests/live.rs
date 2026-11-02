//! The lookups against the real ISPDB and providers. They need the internet, so they run only with
//! PE_NETWORK_TESTS=1 (the Linux CI job sets it). The addresses are made up: only their domains matter.

use pe_autoconfig::{ServerSecurity, Source, discover};

fn enabled() -> bool {
    std::env::var_os("PE_NETWORK_TESTS").is_some_and(|v| v == "1")
}

#[tokio::test]
async fn finds_the_servers_of_well_known_providers() {
    if !enabled() {
        return;
    }
    let gmail = discover("postalexpress.test@gmail.com").await.unwrap();
    assert_ne!(gmail.source, Source::Guess, "{gmail:?}");
    assert_eq!(gmail.imap.host, "imap.gmail.com");
    assert_eq!(gmail.imap.security, ServerSecurity::Tls);
    assert_eq!(gmail.smtp.host, "smtp.gmail.com");
    assert!(gmail.oauth2);

    let fastmail = discover("postalexpress.test@fastmail.com").await.unwrap();
    assert_ne!(fastmail.source, Source::Guess, "{fastmail:?}");
    assert!(fastmail.imap.host.ends_with("fastmail.com"), "{fastmail:?}");
}

#[tokio::test]
async fn guesses_for_a_domain_nobody_knows() {
    if !enabled() {
        return;
    }
    // .invalid never resolves (RFC 2606)
    let unknown = discover("someone@postalexpress.invalid").await.unwrap();
    assert_eq!(unknown.source, Source::Guess);
    assert_eq!(unknown.imap.host, "imap.postalexpress.invalid");
}
