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

#[tokio::test]
async fn mx_and_srv_over_dns_over_https() {
    use pe_autoconfig::{HttpRequest, Io, NetIo, dns};
    use std::time::Duration;

    if !enabled() {
        return;
    }
    let io = NetIo {
        timeout: Duration::from_secs(5),
    };
    // a Google Workspace domain: its exchange is Google's, so the servers are Gmail's
    let mx = io.mx("postalsys.com").await;
    assert!(mx[0].exchange.ends_with(".l.google.com"), "{mx:?}");
    let postalsys = pe_autoconfig::discover("postalexpress.test@postalsys.com")
        .await
        .unwrap();
    assert_eq!(postalsys.source, Source::Mx, "{postalsys:?}");
    assert_eq!(postalsys.imap.host, "imap.gmail.com");
    assert_eq!(postalsys.imap.security, ServerSecurity::Tls);
    assert_eq!(postalsys.smtp.host, "smtp.gmail.com");
    assert!(postalsys.oauth2);
    assert_eq!(postalsys.app_password.unwrap().provider, "Gmail");

    // RFC 6186 records
    let imaps = io.srv("_imaps._tcp.fastmail.com").await;
    assert_eq!(
        (imaps[0].target.as_str(), imaps[0].port),
        ("imap.fastmail.com", 993),
        "{imaps:?}"
    );
    let submissions = io.srv("_submissions._tcp.fastmail.com").await;
    assert_eq!(
        (submissions[0].target.as_str(), submissions[0].port),
        ("smtp.fastmail.com", 465),
        "{submissions:?}"
    );
    // fastmail.com publishes `0 0 0 .` for _submission: not offered
    assert!(io.srv("_submission._tcp.fastmail.com").await.is_empty());

    // the fallback provider answers in the same format
    let request = HttpRequest {
        headers: vec![("accept".into(), "application/dns-json".into())],
        ..HttpRequest::get(format!("{}?name=postalsys.com&type=MX", dns::DOH_FALLBACK))
    };
    let response = io.http(request).await.unwrap();
    let google = dns::parse_doh_mx(&response.body).unwrap();
    assert!(google[0].exchange.ends_with(".l.google.com"), "{google:?}");
}
