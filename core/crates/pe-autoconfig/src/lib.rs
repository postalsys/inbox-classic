//! The servers of an e-mail address, found the way EmailEngine finds them (lib/autodetect-imap-settings.js), which
//! includes the way Thunderbird does:
//!
//! 1. The mail exchange (MX) of the domain: a custom domain at Google, Microsoft 365, Zoho, AWS WorkMail and other
//!    known hosts has the servers of its host. A match wins.
//! 2. Otherwise these race, and the first that names a server wins: the SRV records of RFC 6186, the provider's own
//!    configuration file (`<domain>/.well-known` and `autoconfig.<domain>`), Thunderbird's ISPDB, and Microsoft
//!    Autodiscover.
//! 3. Otherwise the usual names `imap.<domain>` and `smtp.<domain>`.
//!
//! Each step has its own time budget ([`BUDGET`]). The settings carry an app password hint
//! ([`Settings::app_password`]) for providers that want one, by the domain or by its exchange.
//!
//! Only over HTTPS, so nobody on the network can hand out other servers, and never a server without encryption: a
//! server offered without TLS is taken as STARTTLS, which fails rather than sends anything in the clear. MX and
//! SRV records come over DNS-over-HTTPS ([`dns`]: Cloudflare, then Google), not over plain DNS, which anyone on a
//! café Wi-Fi can forge. The DoH provider learns only the domain looked up, as the ISPDB already does.
//!
//! Autodiscover is the one lookup that can use the password ([`Credentials`]): hosted Exchange answers only an
//! authenticated request. The password is sent only to an HTTPS origin that answered the anonymous request with a
//! `401` naming Basic: never first, never over plain HTTP, and never to an origin that a response body named. See
//! [`autodiscover`].
#![forbid(unsafe_code)]

mod app_password;
pub mod autodiscover;
mod config;
pub mod dns;
mod io;
mod mx;
mod resolve;
mod xml;

use std::time::Duration;

pub use app_password::{AppPassword, app_password};
pub use config::{Server, ServerSecurity, parse_config, parse_partial};
pub use dns::{MxRecord, SrvRecord};
pub use io::{HttpRequest, Io, MAX_BODY, NetIo};
pub use mx::{Delegate, delegate};
pub use pe_net::http::{HttpError, Method, Response};

/// Where the settings came from
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Source {
    /// The provider's own configuration file
    Provider,
    /// Thunderbird's database of providers
    Ispdb,
    /// `imap.<domain>` and `smtp.<domain>`: nothing was found, these are the usual names
    Guess,
    /// The mail exchange of the domain is a known provider's
    Mx,
    /// The SRV records of the domain (RFC 6186)
    Srv,
    /// Microsoft Autodiscover
    Autodiscover,
}

/// The servers of an address
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Settings {
    pub imap: Server,
    pub smtp: Server,
    /// The user name for logging in, the templates of the configuration filled in
    pub username: String,
    /// The provider takes OAuth 2.0 (Gmail, Outlook.com, Google Workspace and Microsoft 365 domains)
    pub oauth2: bool,
    pub source: Source,
    /// The provider wants an app password rather than the account password
    pub app_password: Option<AppPassword>,
}

/// What one lookup found: either server may be missing, the user name too
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Discovered {
    pub imap: Option<Server>,
    pub smtp: Option<Server>,
    pub username: Option<String>,
    pub oauth2: bool,
}

impl Discovered {
    /// It names a server; a lookup that names none has not answered
    pub fn names_host(&self) -> bool {
        self.imap.is_some() || self.smtp.is_some()
    }
}

/// The account's login, for Autodiscover on a server that answers only an authenticated request
#[derive(Clone, PartialEq, Eq)]
pub struct Credentials {
    /// The login; the address when None
    pub user: Option<String>,
    pub password: String,
}

impl std::fmt::Debug for Credentials {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Credentials")
            .field("user", &self.user)
            .field("password", &"<hidden>")
            .finish()
    }
}

/// How long each step may take: the MX lookup, then each of the racing lookups
pub const BUDGET: Duration = Duration::from_secs(5);

/// How long one request may take
const TIMEOUT: Duration = Duration::from_secs(5);

/// The domain of an address in its ASCII form (`bücher.de` is `xn--bcher-kva.de`), lowercased; None when it
/// has none or it is not a host name
pub fn domain_of(email: &str) -> Option<String> {
    let (_, domain) = email.trim().rsplit_once('@')?;
    let domain = dns::host_name(&idna::domain_to_ascii(domain.trim_end_matches('.')).ok()?)?;
    // a name without a dot is a local host, not a mail domain
    domain.contains('.').then_some(domain)
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
        app_password: None,
    }
}

/// The settings of what a lookup found, a missing server filled in from [`guess`]
fn settings(email: &str, domain: &str, source: Source, found: Discovered) -> Settings {
    let usual = guess(email, domain);
    Settings {
        imap: found.imap.unwrap_or(usual.imap),
        smtp: found.smtp.unwrap_or(usual.smtp),
        username: found.username.filter(|u| !u.is_empty()).unwrap_or(usual.username),
        oauth2: found.oauth2,
        source,
        app_password: None,
    }
}

/// Finds the servers of `email`; the guess when no configuration is found. None for an address without a domain.
/// `credentials` (the account's login) are used by Autodiscover only, and only for an HTTPS origin that asks for
/// them with a Basic challenge.
pub async fn discover(email: &str, credentials: Option<&Credentials>) -> Option<Settings> {
    discover_using(email, credentials, &NetIo { timeout: TIMEOUT }, BUDGET).await
}

/// [`discover`] over another network (tests answer in its place), with `budget` for each step
pub async fn discover_using<I: Io>(
    email: &str,
    credentials: Option<&Credentials>,
    io: &I,
    budget: Duration,
) -> Option<Settings> {
    let domain = domain_of(email)?;
    let email = email.trim();
    let (exchange, by_mx) = resolve::by_mx(io, email, &domain, budget).await;
    let found = match by_mx {
        Some(found) => Some((Source::Mx, found)),
        None => resolve::race(io, email, &domain, credentials, budget).await,
    };
    let mut settings = match found {
        Some((source, found)) => settings(email, &domain, source, found),
        None => guess(email, &domain),
    };
    settings.app_password = app_password(email, exchange.as_deref());
    Some(settings)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A `fetch(host, path)` of HTTPS GETs as the network: nothing else is fetched, and there are no DNS records
    struct FetchIo<F>(F);

    impl<F, Fut> Io for FetchIo<F>
    where
        F: Fn(String, String) -> Fut + Sync,
        Fut: Future<Output = Result<Response, HttpError>> + Send,
    {
        fn http(&self, request: HttpRequest) -> impl Future<Output = Result<Response, HttpError>> + Send {
            let url = pe_net::http::parse_url(&request.url).filter(|u| u.https && request.method == Method::Get);
            let fetch = url.map(|url| (self.0)(url.host, url.path));
            async move {
                match fetch {
                    Some(fetch) => fetch.await,
                    None => Err(HttpError::BadUrl),
                }
            }
        }

        async fn mx(&self, _: &str) -> Vec<MxRecord> {
            Vec::new()
        }

        async fn srv(&self, _: &str) -> Vec<SrvRecord> {
            Vec::new()
        }
    }

    /// [`discover`] with another way to fetch, for tests: `fetch(host, path)` gets the configuration files over
    /// HTTPS; there are no DNS records, and no Autodiscover
    async fn discover_with<F, Fut>(email: &str, fetch: F) -> Option<Settings>
    where
        F: Fn(String, String) -> Fut + Sync,
        Fut: Future<Output = Result<Response, HttpError>> + Send,
    {
        discover_using(email, None, &FetchIo(fetch), BUDGET).await
    }

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
        Ok(Response::new(200, body))
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

    // ---- EmailEngine autodetectImapSettings and resolver, over a stand-in network

    use std::collections::HashMap;
    use std::sync::Mutex;

    enum Reply {
        Body(u16, String),
        /// After this many milliseconds
        Later(u64, String),
        Challenge,
        Redirect(String),
        Stall,
    }

    type Handler = Box<dyn Fn(&HttpRequest) -> Reply + Send + Sync>;

    struct Net {
        mx: Vec<MxRecord>,
        srv: HashMap<String, Vec<SrvRecord>>,
        http: Handler,
        calls: Mutex<Vec<HttpRequest>>,
        srv_asked: Mutex<Vec<String>>,
        /// SRV lookups wait until this many have been asked
        srv_gate: usize,
    }

    impl Net {
        fn new(http: impl Fn(&HttpRequest) -> Reply + Send + Sync + 'static) -> Net {
            Net {
                mx: Vec::new(),
                srv: HashMap::new(),
                http: Box::new(http),
                calls: Mutex::new(Vec::new()),
                srv_asked: Mutex::new(Vec::new()),
                srv_gate: 0,
            }
        }

        fn nothing() -> Net {
            Net::new(|_| Reply::Body(404, String::new()))
        }

        fn with_mx(mut self, exchanges: &[(u16, &str)]) -> Net {
            self.mx = exchanges
                .iter()
                .map(|(priority, exchange)| MxRecord {
                    priority: *priority,
                    exchange: exchange.to_string(),
                })
                .collect();
            self
        }

        fn with_srv(mut self, name: &str, target: &str, port: u16) -> Net {
            self.srv.insert(
                name.to_string(),
                vec![SrvRecord {
                    priority: 1,
                    weight: 1,
                    port,
                    target: target.to_string(),
                }],
            );
            self
        }
    }

    impl Io for Net {
        fn http(&self, request: HttpRequest) -> impl Future<Output = Result<Response, HttpError>> + Send {
            self.calls.lock().unwrap().push(request.clone());
            let reply = (self.http)(&request);
            async move {
                match reply {
                    Reply::Body(status, body) => Ok(Response::new(status, body)),
                    Reply::Later(ms, body) => {
                        tokio::time::sleep(Duration::from_millis(ms)).await;
                        Ok(Response::new(200, body))
                    }
                    Reply::Challenge => Ok(Response {
                        headers: vec![("WWW-Authenticate".into(), "Basic realm=\"x\"".into())],
                        ..Response::new(401, "")
                    }),
                    Reply::Redirect(to) => Ok(Response {
                        headers: vec![("Location".into(), to)],
                        ..Response::new(302, "")
                    }),
                    Reply::Stall => std::future::pending().await,
                }
            }
        }

        async fn mx(&self, _: &str) -> Vec<MxRecord> {
            self.mx.clone()
        }

        async fn srv(&self, name: &str) -> Vec<SrvRecord> {
            self.srv_asked.lock().unwrap().push(name.to_string());
            for _ in 0..1000 {
                if self.srv_asked.lock().unwrap().len() >= self.srv_gate {
                    return self.srv.get(name).cloned().unwrap_or_default();
                }
                tokio::task::yield_now().await;
            }
            panic!("the SRV lookups were not made at once");
        }
    }

    const BUDGET_IN_TESTS: Duration = Duration::from_secs(2);

    async fn find(email: &str, net: &Net) -> Settings {
        discover_using(email, None, net, BUDGET_IN_TESTS).await.unwrap()
    }

    fn at(host: &str, port: u16, security: ServerSecurity) -> Server {
        Server {
            host: host.into(),
            port,
            security,
        }
    }

    fn autoconfig_doc(host: &str) -> String {
        format!(
            r#"<?xml version="1.0" encoding="UTF-8"?><clientConfig version="1.1"><emailProvider id="example.com"><incomingServer type="imap"><hostname>{host}</hostname><port>993</port><socketType>SSL</socketType></incomingServer></emailProvider></clientConfig>"#
        )
    }

    #[tokio::test]
    async fn known_exchanges() {
        let m365 = find(
            "user@customdomain.com",
            &Net::nothing().with_mx(&[(10, "contoso.mail.protection.outlook.com")]),
        )
        .await;
        assert_eq!(m365.source, Source::Mx);
        assert_eq!(m365.imap, at("outlook.office365.com", 993, ServerSecurity::Tls));
        assert_eq!(m365.smtp, at("smtp.office365.com", 587, ServerSecurity::StartTls));
        assert_eq!(m365.username, "user@customdomain.com");
        assert!(m365.oauth2);
        assert_eq!(m365.app_password.unwrap().provider, "Microsoft");

        let zoho = find("user@customdomain.com", &Net::nothing().with_mx(&[(10, "mx.zoho.eu")])).await;
        assert_eq!((zoho.source, zoho.imap.host.as_str()), (Source::Mx, "imappro.zoho.eu"));
        assert_eq!(zoho.app_password, None);

        // the lowest priority is the exchange
        let naver = find(
            "user@customdomain.com",
            &Net::nothing().with_mx(&[(50, "backup.example.com"), (10, "mx1.naver.com")]),
        )
        .await;
        assert_eq!(naver.imap.host, "imap.naver.com");
    }

    #[tokio::test]
    async fn google_by_the_srv_records_of_gmail() {
        let net = Net::nothing()
            .with_mx(&[(10, "gmail-smtp-in.l.google.com")])
            .with_srv("_imaps._tcp.gmail.com", "imap.gmail.com", 993)
            .with_srv("_submissions._tcp.gmail.com", "smtp.gmail.com", 465);
        let gmail = find("user@gmail.com", &net).await;
        assert_eq!(gmail.source, Source::Mx);
        assert_eq!(gmail.imap, at("imap.gmail.com", 993, ServerSecurity::Tls));
        assert_eq!(gmail.smtp, at("smtp.gmail.com", 465, ServerSecurity::Tls));
        assert!(gmail.oauth2);
        assert_eq!(gmail.app_password.unwrap().provider, "Gmail");

        // _imap without TLS is STARTTLS; _submission on 465 is implicit TLS
        let net = Net::nothing()
            .with_mx(&[(10, "alt.l.google.com")])
            .with_srv("_imap._tcp.gmail.com", "imap.legacy.gmail.com", 143)
            .with_srv("_submission._tcp.gmail.com", "smtp.legacy.gmail.com", 465);
        let legacy = find("user@gmail.com", &net).await;
        assert_eq!(legacy.imap, at("imap.legacy.gmail.com", 143, ServerSecurity::StartTls));
        assert_eq!(legacy.smtp, at("smtp.legacy.gmail.com", 465, ServerSecurity::Tls));
        let net = Net::nothing().with_mx(&[(10, "alt.l.google.com")]).with_srv(
            "_submission._tcp.gmail.com",
            "smtp.gmail.com",
            587,
        );
        assert_eq!(
            find("user@gmail.com", &net).await.smtp.security,
            ServerSecurity::StartTls
        );
    }

    #[tokio::test]
    async fn a_known_exchange_that_names_nothing_leaves_its_hint() {
        // Google's exchange, but no SRV records: the race decides, the hint of the exchange stays
        let net = Net::new(|request| {
            if request.url.starts_with("https://autoconfig.thunderbird.net/") {
                Reply::Body(200, autoconfig_doc("imap.mozilla.example.com"))
            } else {
                Reply::Body(404, String::new())
            }
        })
        .with_mx(&[(1, "aspmx.l.google.com")]);
        let found = find("user@workspace.example", &net).await;
        assert_eq!(
            (found.source, found.imap.host.as_str()),
            (Source::Ispdb, "imap.mozilla.example.com")
        );
        assert_eq!(found.app_password.unwrap().provider, "Gmail");
        // and the guess gets it too
        let guessed = find(
            "user@workspace.example",
            &Net::nothing().with_mx(&[(1, "aspmx.l.google.com")]),
        )
        .await;
        assert_eq!(
            (guessed.source, guessed.app_password.unwrap().provider),
            (Source::Guess, "Gmail")
        );
        let aol = find("user@aol.com", &Net::nothing()).await;
        assert_eq!(aol.app_password.unwrap().provider, "AOL");
    }

    #[tokio::test]
    async fn the_first_lookup_to_name_a_server_wins() {
        let net = Net::new(|request| {
            let url = request.url.as_str();
            if url.starts_with("https://example.com/") {
                // answers first, but names nothing: a loss, not a win
                Reply::Body(200, "<clientConfig version=\"1.1\"></clientConfig>".into())
            } else if url.starts_with("https://autoconfig.example.com/") {
                Reply::Later(20, autoconfig_doc("imap.autoconfig.example.com"))
            } else if url.starts_with("https://autoconfig.thunderbird.net/") {
                Reply::Later(200, autoconfig_doc("imap.mozilla.example.com"))
            } else {
                Reply::Body(404, String::new())
            }
        });
        let found = find("user@example.com", &net).await;
        assert_eq!(found.imap.host, "imap.autoconfig.example.com");
        assert_eq!(found.source, Source::Provider);
        // only the IMAP half was named: SMTP is the usual name
        assert_eq!(found.smtp, at("smtp.example.com", 465, ServerSecurity::Tls));

        // every lookup came back empty: the guess
        assert_eq!(
            find("user@example.com", &Net::nothing()).await,
            guess("user@example.com", "example.com")
        );
    }

    #[tokio::test]
    async fn a_lookup_that_outlives_its_budget_loses() {
        let net = Net::new(|request| {
            if request.url.starts_with("https://autoconfig.thunderbird.net/") {
                Reply::Body(200, autoconfig_doc("imap.mozilla.example.com"))
            } else {
                Reply::Stall
            }
        });
        let started = std::time::Instant::now();
        let found = discover_using("user@example.com", None, &net, Duration::from_millis(100))
            .await
            .unwrap();
        assert_eq!(found.imap.host, "imap.mozilla.example.com");
        // nothing answers at all: the guess within the budgets
        let stalled = Net::new(|_| Reply::Stall);
        let guessed = discover_using("user@example.com", None, &stalled, Duration::from_millis(100))
            .await
            .unwrap();
        assert_eq!(guessed.source, Source::Guess);
        assert!(started.elapsed() < Duration::from_secs(2));
    }

    #[tokio::test]
    async fn srv_records() {
        // IMAP without a submission record keeps its answer
        let net = Net::nothing().with_srv("_imaps._tcp.example.com", "imap.example.com", 993);
        let found = find("user@example.com", &net).await;
        assert_eq!(
            (found.source, found.imap.host.as_str()),
            (Source::Srv, "imap.example.com")
        );
        assert_eq!(found.smtp.host, "smtp.example.com");

        // no record at all names nothing
        assert_eq!(
            resolve::srv(&Net::nothing(), "example.com").await,
            Discovered::default()
        );

        // IMAP and SMTP are looked up at once: the first two lookups are both asked before either answers
        let mut net = Net::nothing()
            .with_srv("_imaps._tcp.example.com", "imap.example.com", 993)
            .with_srv("_submission._tcp.example.com", "smtp.example.com", 587);
        net.srv_gate = 2;
        let found = resolve::srv(&net, "example.com").await;
        let mut first_two = net.srv_asked.lock().unwrap()[..2].to_vec();
        first_two.sort();
        assert_eq!(first_two, ["_imaps._tcp.example.com", "_submissions._tcp.example.com"]);
        assert_eq!(found.imap, Some(at("imap.example.com", 993, ServerSecurity::Tls)));
        assert_eq!(found.smtp, Some(at("smtp.example.com", 587, ServerSecurity::StartTls)));
    }

    #[tokio::test]
    async fn autodiscover_in_the_race() {
        let pox = r#"<?xml version="1.0" encoding="utf-8"?><Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006"><Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a"><Account><AccountType>email</AccountType><Protocol><Type>IMAP</Type><Server>mail.example.com</Server><Port>993</Port><SSL>on</SSL><LoginName>EXAMPLE\user</LoginName></Protocol><Protocol><Type>SMTP</Type><Server>mail.example.com</Server><Port>587</Port><SSL>off</SSL></Protocol></Account></Response></Autodiscover>"#;
        let net = Net::new(move |request| {
            let authorized = request.header("authorization").is_some();
            match (request.method, request.url.as_str(), authorized) {
                (Method::Post, "https://autodiscover.example.com/autodiscover/autodiscover.xml", false) => {
                    Reply::Challenge
                }
                (Method::Post, "https://autodiscover.example.com/autodiscover/autodiscover.xml", true) => {
                    Reply::Body(200, pox.into())
                }
                _ => Reply::Body(404, String::new()),
            }
        });
        let credentials = Credentials {
            user: None,
            password: "pw".into(),
        };
        let found = discover_using("user@example.com", Some(&credentials), &net, BUDGET_IN_TESTS)
            .await
            .unwrap();
        assert_eq!(found.source, Source::Autodiscover);
        assert_eq!(found.imap, at("mail.example.com", 993, ServerSecurity::Tls));
        assert_eq!(found.smtp, at("mail.example.com", 587, ServerSecurity::StartTls));
        assert_eq!(found.username, "EXAMPLE\\user");
        // without the password the same domain is a guess
        let net = Net::new(|request| match request.method {
            Method::Post => Reply::Challenge,
            Method::Get => Reply::Body(404, String::new()),
        });
        assert_eq!(find("user@example.com", &net).await.source, Source::Guess);
    }

    /// Where the password went in a whole lookup where every POST asks for it and the plain-HTTP step redirects
    /// elsewhere
    #[tokio::test]
    async fn the_password_goes_only_where_it_was_asked_for() {
        let net = Net::new(|request| {
            let url = request.url.as_str();
            if url.starts_with("http://") {
                return Reply::Redirect("https://collector.example.net/autodiscover/autodiscover.xml".into());
            }
            match request.method {
                Method::Post if url.starts_with("https://autodiscover.example.com/") => Reply::Challenge,
                // the domain itself names another endpoint in its body
                Method::Post if url.starts_with("https://example.com/") => Reply::Body(
                    200,
                    r#"<Autodiscover><Response><Account><Action>redirectUrl</Action><RedirectUrl>https://collector.example.org/x</RedirectUrl></Account></Response></Autodiscover>"#.into(),
                ),
                Method::Post => Reply::Challenge,
                Method::Get => Reply::Body(404, String::new()),
            }
        });
        let credentials = Credentials {
            user: Some("login".into()),
            password: "pw".into(),
        };
        let found = discover_using("user@example.com", Some(&credentials), &net, BUDGET_IN_TESTS)
            .await
            .unwrap();
        assert_eq!(found.source, Source::Guess);
        let calls = net.calls.lock().unwrap();
        let mut challenged_before = std::collections::HashSet::new();
        for call in calls.iter() {
            let origin = pe_net::http::parse_url_with(&call.url, true).unwrap().origin();
            match call.header("authorization") {
                None if call.method == Method::Post => {
                    challenged_before.insert(origin);
                }
                None => {}
                Some(authorization) => {
                    assert_eq!(authorization, "Basic bG9naW46cHc=");
                    assert_eq!(origin, "https://autodiscover.example.com", "{}", call.url);
                    assert!(challenged_before.contains(&origin), "not before the anonymous request");
                }
            }
        }
        assert!(calls.iter().any(|c| c.header("authorization").is_some()));
        // nothing is asked over plain HTTP, where anyone on the network could answer
        assert!(calls.iter().all(|c| c.url.starts_with("https://")), "{calls:?}");
        assert!(
            calls
                .iter()
                .any(|c| c.url.starts_with("https://collector.example.org/"))
        );
        assert!(
            calls
                .iter()
                .all(|c| c.url.starts_with("https://") || c.header("authorization").is_none())
        );
    }

    #[test]
    fn the_lookups_can_run_on_another_thread() {
        fn send<T: Send>(_: T) {}
        send(discover("a@example.com", None));
        let credentials = Credentials {
            user: None,
            password: "x".into(),
        };
        send(discover("a@example.com", Some(&credentials)));
    }

    #[test]
    fn credentials_are_not_printed() {
        let credentials = Credentials {
            user: Some("me".into()),
            password: "hunter2".into(),
        };
        assert!(!format!("{credentials:?}").contains("hunter2"));
    }
}
