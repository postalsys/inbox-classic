//! Microsoft Autodiscover, ported from EmailEngine (lib/autodetect-imap-settings.js): the legacy POX endpoint
//! (`/autodiscover/autodiscover.xml`) and the SOAP `GetUserSettings` one (`/autodiscover/autodiscover.svc`), at
//! `autodiscover.<domain>` (or the host of its `_autodiscover._tcp` SRV record) and at the domain itself, over HTTPS
//! only. Microsoft's step of a plain-HTTP GET of `autodiscover.<domain>`, whose redirect names another endpoint, is
//! left out on purpose: anyone on the network can forge a plain-HTTP answer, and the servers the named endpoint
//! returned would then be theirs, password or not.
//!
//! The password goes only to an HTTPS origin that answered the anonymous request with a `401` whose challenge
//! names Basic: never with the first request and never over plain HTTP. The anonymous request follows HTTPS
//! redirects (all within reach of whoever holds a certificate the system trusts), so that origin can be the end of
//! such a redirect; the requests with the password follow none. An origin that a response body names is asked
//! anonymously only.

use base64::Engine;
use pe_net::http::{Method, Response, Url, parse_url};

use crate::dns::host_name;
use crate::io::{BoxFuture, HttpRequest, Io, first_some};
use crate::xml::{Node, walk};
use crate::{Credentials, Discovered, Server, ServerSecurity};

const POX_PATH: &str = "/autodiscover/autodiscover.xml";
const SOAP_PATH: &str = "/autodiscover/autodiscover.svc";
/// Exchange answers `application/xml` with 415 before it reads the body
const CONTENT_TYPE: &str = "text/xml; charset=utf-8";
/// How many times a response body may name another endpoint instead of answering
pub const MAX_REDIRECTS: u8 = 2;
/// How many HTTP redirects (3xx) one anonymous request follows
const MAX_HOPS: usize = 3;
/// Accounts, protocols and settings read from one response; Exchange repeats a connection once per server, so
/// dozens are normal
const MAX_ENTRIES: usize = 256;

/// The five XML metacharacters escaped, as EmailEngine's `escapeXml`
pub fn escape_xml(text: &str) -> String {
    quick_xml::escape::escape(text).into_owned()
}

/// The legacy (POX) request. The order of the children matters: Exchange answers ErrorCode 600 when
/// `AcceptableResponseSchema` comes before `EMailAddress`.
pub fn build_pox_request(email: &str) -> String {
    format!(
        r#"<?xml version="1.0" encoding="utf-8"?>
<Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/requestschema/2006">
  <Request>
    <EMailAddress>{}</EMailAddress>
    <AcceptableResponseSchema>http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a</AcceptableResponseSchema>
  </Request>
</Autodiscover>"#,
        escape_xml(email)
    )
}

/// The SOAP `GetUserSettings` request for the external IMAP and SMTP endpoints. Exchange fills these from other
/// configuration than POX, which often names nothing but Outlook on the web.
pub fn build_soap_request(email: &str) -> String {
    format!(
        r#"<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:a="http://schemas.microsoft.com/exchange/2010/Autodiscover" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsa="http://www.w3.org/2005/08/addressing">
  <soap:Header>
    <a:RequestedServerVersion>Exchange2013</a:RequestedServerVersion>
    <wsa:Action>http://schemas.microsoft.com/exchange/2010/Autodiscover/Autodiscover/GetUserSettings</wsa:Action>
  </soap:Header>
  <soap:Body>
    <a:GetUserSettingsRequestMessage>
      <a:Request>
        <a:Users><a:User><a:Mailbox>{}</a:Mailbox></a:User></a:Users>
        <a:RequestedSettings>
          <a:Setting>ExternalImap4Connections</a:Setting>
          <a:Setting>ExternalSmtpConnections</a:Setting>
        </a:RequestedSettings>
      </a:Request>
    </a:GetUserSettingsRequestMessage>
  </soap:Body>
</soap:Envelope>"#,
        escape_xml(email)
    )
}

/// A POX response: the servers it names, and the endpoint it names instead of answering
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Pox {
    pub found: Discovered,
    /// `<Action>redirectUrl</Action>` with its `<RedirectUrl>`. A `redirectAddr` names another address and is not
    /// followed.
    pub redirect_url: Option<String>,
}

/// The first value of each child of a `<Protocol>`
#[derive(Default)]
struct Protocol {
    kind: Option<String>,
    server: Option<String>,
    login: Option<String>,
    port: Option<String>,
    ssl: Option<String>,
}

#[derive(Default)]
struct Account {
    types: Vec<String>,
    action: Option<String>,
    redirect_url: Option<String>,
    protocols: Vec<Protocol>,
}

fn first(slot: &mut Option<String>, value: &str) {
    if slot.is_none() {
        *slot = Some(value.to_string());
    }
}

/// A port of a server setting: a number above 0
fn port_of(value: Option<&str>) -> Option<u16> {
    value?.trim().parse().ok().filter(|p| *p > 0)
}

/// The usual port of a protocol and its encryption
fn default_port(imap: bool, security: ServerSecurity) -> u16 {
    match (imap, security) {
        (true, ServerSecurity::Tls) => 993,
        (true, ServerSecurity::StartTls) => 143,
        (false, ServerSecurity::Tls) => 465,
        (false, ServerSecurity::StartTls) => 587,
    }
}

impl Protocol {
    /// A server of a `<Protocol>` with a `<Server>`. `<SSL>off</SSL>` is STARTTLS: there is no server without
    /// encryption. Without `<SSL>`, the port tells.
    fn server(&self, imap: bool) -> Option<Server> {
        let host = host_name(self.server.as_deref()?)?;
        let port = port_of(self.port.as_deref());
        let security = match self.ssl.as_deref().map(str::trim) {
            Some(ssl) if ssl.eq_ignore_ascii_case("on") => ServerSecurity::Tls,
            Some(ssl) if ssl.eq_ignore_ascii_case("off") => ServerSecurity::StartTls,
            _ if matches!(port, Some(25 | 143 | 587)) => ServerSecurity::StartTls,
            _ => ServerSecurity::Tls,
        };
        Some(Server {
            host,
            port: port.unwrap_or(default_port(imap, security)),
            security,
        })
    }
}

/// Reads a POX response: the first IMAP and SMTP `<Protocol>` that names a server, of an account of type `email`.
/// None when it is not well-formed; an empty body names nothing.
pub fn parse_pox(xml: &str) -> Option<Pox> {
    let mut accounts: Vec<Account> = Vec::new();
    walk(xml, |node| match node {
        Node::Open(path) => {
            let path: Vec<&str> = path.iter().map(String::as_str).collect();
            match path[..] {
                ["autodiscover", "response", "account"] if accounts.len() < MAX_ENTRIES => {
                    accounts.push(Account::default())
                }
                ["autodiscover", "response", "account", "protocol"] => {
                    if let Some(account) = accounts.last_mut()
                        && account.protocols.len() < MAX_ENTRIES
                    {
                        account.protocols.push(Protocol::default());
                    }
                }
                _ => {}
            }
        }
        Node::Close(path, value) => {
            let path: Vec<&str> = path.iter().map(String::as_str).collect();
            let Some(account) = accounts.last_mut() else { return };
            match path[..] {
                ["autodiscover", "response", "account", field] => match field {
                    "accounttype" if account.types.len() < MAX_ENTRIES => account.types.push(value.to_string()),
                    "action" => first(&mut account.action, value),
                    "redirecturl" => first(&mut account.redirect_url, value),
                    _ => {}
                },
                ["autodiscover", "response", "account", "protocol", field] => {
                    let Some(protocol) = account.protocols.last_mut() else {
                        return;
                    };
                    match field {
                        "type" => first(&mut protocol.kind, value),
                        "server" => first(&mut protocol.server, value),
                        "loginname" => first(&mut protocol.login, value),
                        "port" => first(&mut protocol.port, value),
                        "ssl" => first(&mut protocol.ssl, value),
                        _ => {}
                    }
                }
                _ => {}
            }
        }
    })?;

    let protocols = || {
        accounts
            .iter()
            .filter(|a| a.types.iter().any(|t| t.eq_ignore_ascii_case("email")))
            .flat_map(|a| a.protocols.iter())
    };
    let pick = |kind: &str, imap: bool| {
        protocols()
            .filter(|p| p.kind.as_deref().is_some_and(|k| k.eq_ignore_ascii_case(kind)))
            .find_map(|p| Some((p.server(imap)?, p.login.clone().filter(|l| !l.is_empty()))))
    };
    let imap = pick("imap", true);
    let smtp = pick("smtp", false);
    let username = imap
        .as_ref()
        .and_then(|(_, login)| login.clone())
        .or_else(|| smtp.as_ref().and_then(|(_, login)| login.clone()));
    // the action is what makes it a redirect: a stray RedirectUrl is not one
    let redirect_url = accounts.iter().find_map(|a| {
        let action = a.action.as_deref()?.trim();
        let url = a.redirect_url.as_deref()?.trim();
        (action.eq_ignore_ascii_case("redirectUrl") && !url.is_empty()).then(|| url.to_string())
    });
    Some(Pox {
        found: Discovered {
            imap: imap.map(|(server, _)| server),
            smtp: smtp.map(|(server, _)| server),
            username,
            oauth2: false,
        },
        redirect_url,
    })
}

/// A `<ProtocolConnection>` of a SOAP response
#[derive(Default)]
struct Connection {
    hostname: Option<String>,
    port: Option<String>,
    encryption: Option<String>,
}

#[derive(Default)]
struct UserSetting {
    name: Option<String>,
    connections: Vec<Connection>,
}

/// One connection out of a collection: the first with implicit TLS (`SSL`), else the first usable one, which is
/// STARTTLS (`TLS`, and `None` too: there is no server without encryption)
fn pick_connection(connections: &[Connection]) -> Option<Server> {
    let usable = |c: &Connection| Some((host_name(c.hostname.as_deref()?)?, port_of(c.port.as_deref())?));
    let implicit = |c: &Connection| {
        c.encryption
            .as_deref()
            .is_some_and(|e| e.trim().eq_ignore_ascii_case("ssl"))
    };
    let tls = connections.iter().find(|c| implicit(c) && usable(c).is_some());
    let picked = tls.or_else(|| connections.iter().find(|c| usable(c).is_some()))?;
    let (host, port) = usable(picked)?;
    Some(Server {
        host,
        port,
        security: if implicit(picked) {
            ServerSecurity::Tls
        } else {
            ServerSecurity::StartTls
        },
    })
}

/// Reads a SOAP `GetUserSettings` response: `ExternalImap4Connections` and `ExternalSmtpConnections`. None when it
/// is not well-formed.
pub fn parse_soap(xml: &str) -> Option<Discovered> {
    const SETTING: [&str; 8] = [
        "envelope",
        "body",
        "getusersettingsresponsemessage",
        "response",
        "userresponses",
        "userresponse",
        "usersettings",
        "usersetting",
    ];
    let mut settings: Vec<UserSetting> = Vec::new();
    walk(xml, |node| match node {
        Node::Open(path) => {
            if path.len() == 8 && path.iter().zip(SETTING).all(|(a, b)| a == b) && settings.len() < MAX_ENTRIES {
                settings.push(UserSetting::default());
            }
            let in_setting = path.len() == 10 && path.iter().zip(SETTING).all(|(a, b)| a == b);
            if in_setting
                && path[8] == "protocolconnections"
                && path[9] == "protocolconnection"
                && let Some(setting) = settings.last_mut()
                && setting.connections.len() < MAX_ENTRIES
            {
                setting.connections.push(Connection::default());
            }
        }
        Node::Close(path, value) => {
            if path.len() < 9 || !path.iter().zip(SETTING).all(|(a, b)| a == b) {
                return;
            }
            let Some(setting) = settings.last_mut() else { return };
            let rest: Vec<&str> = path[8..].iter().map(String::as_str).collect();
            match rest[..] {
                ["name"] => first(&mut setting.name, value),
                ["protocolconnections", "protocolconnection", field] => {
                    let Some(connection) = setting.connections.last_mut() else {
                        return;
                    };
                    match field {
                        "hostname" => first(&mut connection.hostname, value),
                        "port" => first(&mut connection.port, value),
                        "encryptionmethod" => first(&mut connection.encryption, value),
                        _ => {}
                    }
                }
                _ => {}
            }
        }
    })?;
    let connections = |name: &str| {
        settings
            .iter()
            .find(|s| s.name.as_deref().is_some_and(|n| n.eq_ignore_ascii_case(name)))
            .and_then(|s| pick_connection(&s.connections))
    };
    Some(Discovered {
        imap: connections("externalimap4connections"),
        smtp: connections("externalsmtpconnections"),
        username: None,
        oauth2: false,
    })
}

/// An HTTPS URL
fn https_url(url: &str) -> Option<Url> {
    parse_url(url).filter(|u| u.https)
}

/// The URL a `Location` names, relative to `base`
fn location(base: &Url, value: &str) -> Option<String> {
    let value = value.trim();
    let lower = value.to_ascii_lowercase();
    if lower.starts_with("https://") || lower.starts_with("http://") {
        Some(value.to_string())
    } else if value.starts_with('/') && !value.starts_with("//") {
        Some(format!("{}{value}", base.origin()))
    } else {
        None
    }
}

fn is_redirect(status: u16) -> bool {
    matches!(status, 301 | 302 | 303 | 307 | 308)
}

fn is_success(status: u16) -> bool {
    (200..300).contains(&status)
}

/// A challenge that names Basic, in any of the `WWW-Authenticate` fields
fn offers_basic(response: &Response) -> bool {
    response.header_values("www-authenticate").any(|value| {
        value
            .split(|c: char| !(c.is_ascii_alphanumeric() || c == '_'))
            .any(|word| word.eq_ignore_ascii_case("basic"))
    })
}

fn post(url: &str, body: &str, authorization: Option<&str>) -> HttpRequest {
    let mut headers = vec![("Content-Type".to_string(), CONTENT_TYPE.to_string())];
    if let Some(authorization) = authorization {
        headers.push(("Authorization".to_string(), authorization.to_string()));
    }
    HttpRequest {
        method: Method::Post,
        url: url.to_string(),
        headers,
        body: body.as_bytes().to_vec(),
    }
}

/// The anonymous POX request to `origin`, following HTTP redirects to HTTPS only: the response, and the origin that
/// gave it
async fn post_anonymous<I: Io>(io: &I, origin: &str, body: &str) -> Option<(Response, String)> {
    let mut url = https_url(&format!("{origin}{POX_PATH}"))?;
    for _ in 0..=MAX_HOPS {
        let target = format!("{}{}", url.origin(), url.path);
        let response = io.http(post(&target, body, None)).await.ok()?;
        if !is_redirect(response.status) {
            return Some((response, url.origin()));
        }
        url = https_url(&location(&url, response.header("location")?)?)?;
    }
    None
}

fn text(body: &[u8]) -> Option<&str> {
    std::str::from_utf8(body).ok()
}

/// Autodiscover against one origin (`https://host[:port]`): anonymously first, then, when the origin that answered
/// challenges with Basic and there is a password, POX and SOAP with the password at once, the first that names a
/// server winning (POX on a tie, as only it names the login). None unless a server is named.
pub(crate) fn run<'a, I: Io>(
    io: &'a I,
    origin: String,
    email: &'a str,
    credentials: Option<&'a Credentials>,
    redirects_left: u8,
) -> BoxFuture<'a, Option<Discovered>> {
    Box::pin(async move {
        let pox_body = build_pox_request(email);
        let (response, origin) = post_anonymous(io, &origin, &pox_body).await?;
        if is_success(response.status) {
            let pox = parse_pox(text(&response.body)?)?;
            if pox.found.names_host() {
                return Some(pox.found);
            }
            // another endpoint for the same mailbox, named by a server that asked for nothing: anonymously
            let next = pox.redirect_url.as_deref().and_then(https_url)?;
            if redirects_left == 0 {
                return None;
            }
            return run(io, next.origin(), email, None, redirects_left - 1).await;
        }
        let credentials = credentials.filter(|c| !c.password.is_empty())?;
        if response.status != 401 || !offers_basic(&response) {
            return None;
        }
        let user = credentials.user.as_deref().filter(|u| !u.is_empty()).unwrap_or(email);
        let token = base64::engine::general_purpose::STANDARD.encode(format!("{user}:{}", credentials.password));
        let authorization = format!("Basic {token}");
        let pox_url = format!("{origin}{POX_PATH}");
        let soap_url = format!("{origin}{SOAP_PATH}");
        let soap_body = build_soap_request(email);
        // both requests are made before either is awaited
        let pox_request = io.http(post(&pox_url, &pox_body, Some(&authorization)));
        let soap_request = io.http(post(&soap_url, &soap_body, Some(&authorization)));
        let pox = async {
            let response = pox_request.await.ok()?;
            let found = is_success(response.status).then(|| parse_pox(text(&response.body)?))??;
            found.found.names_host().then_some(found.found)
        };
        let soap = async {
            let response = soap_request.await.ok()?;
            let found = is_success(response.status).then(|| parse_soap(text(&response.body)?))??;
            found.names_host().then_some(found)
        };
        first_some(vec![Box::pin(pox), Box::pin(soap)]).await
    })
}

/// Autodiscover for `email`: the subdomain (or the host of the `_autodiscover._tcp` SRV record) and the domain, at
/// once; the first that names a server wins
pub(crate) async fn resolve<I: Io>(
    io: &I,
    email: &str,
    domain: &str,
    credentials: Option<&Credentials>,
) -> Option<Discovered> {
    // the domain itself needs no DNS answer, so it does not wait for the SRV lookup of the subdomain's host
    let subdomain: BoxFuture<'_, Option<Discovered>> = Box::pin(async move {
        let srv = io.srv(&format!("_autodiscover._tcp.{domain}")).await;
        let origin = match srv.first() {
            Some(record) if record.port == 443 => format!("https://{}", record.target),
            Some(record) => format!("https://{}:{}", record.target, record.port),
            None => format!("https://autodiscover.{domain}"),
        };
        // the SRV record may name the domain itself, which is asked anyway
        if origin == format!("https://{domain}") {
            return None;
        }
        run(io, origin, email, credentials, MAX_REDIRECTS).await
    });
    let root = run(io, format!("https://{domain}"), email, credentials, MAX_REDIRECTS);
    first_some(vec![subdomain, root]).await
}

#[cfg(test)]
mod tests {
    use std::sync::Mutex;

    use super::*;
    use crate::dns::SrvRecord;
    use crate::{HttpError, Response};

    // ---- EmailEngine escapeXml, buildAutodiscoverRequest, buildAutodiscoverSoapRequest

    #[test]
    fn escapes() {
        assert_eq!(escape_xml("<>&'\""), "&lt;&gt;&amp;&apos;&quot;");
        assert_eq!(escape_xml("user.name+tag@example.com"), "user.name+tag@example.com");
        let escaped = escape_xml("a@b.com</EMailAddress><injected>x");
        assert!(!escaped.contains('<') && !escaped.contains('>'));
        assert!(escaped.contains("&lt;injected&gt;"));
        assert_eq!(escape_xml("&lt;"), "&amp;lt;");
    }

    #[test]
    fn requests() {
        let pox = build_pox_request("user@example.com");
        assert!(pox.find("<EMailAddress>").unwrap() < pox.find("<AcceptableResponseSchema>").unwrap());
        assert!(build_pox_request("a<b>@example.com").contains("<EMailAddress>a&lt;b&gt;@example.com</EMailAddress>"));
        let soap = build_soap_request("user@example.com");
        assert!(soap.contains("<a:Setting>ExternalImap4Connections</a:Setting>"));
        assert!(soap.contains("<a:Setting>ExternalSmtpConnections</a:Setting>"));
        assert!(soap.contains("<a:Mailbox>user@example.com</a:Mailbox>"));
        assert!(build_soap_request("a&b@example.com").contains("<a:Mailbox>a&amp;b@example.com</a:Mailbox>"));
        // both are well-formed and carry the address
        assert!(walk(&pox, |_| {}).is_some() && walk(&soap, |_| {}).is_some());
    }

    // ---- EmailEngine processAutodiscoverResponse

    fn pox(accounts: &str) -> String {
        format!(
            r#"<?xml version="1.0" encoding="utf-8"?>
<Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
  <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
    {accounts}
  </Response>
</Autodiscover>"#
        )
    }

    const EMAIL_ACCOUNT: &str = "<Account>
      <AccountType>email</AccountType>
      <Action>settings</Action>
      <Protocol>
        <Type>IMAP</Type>
        <Server>imap.example.com</Server>
        <Port>993</Port>
        <LoginName>john@example.com</LoginName>
        <SSL>on</SSL>
      </Protocol>
      <Protocol>
        <Type>SMTP</Type>
        <Server>smtp.example.com</Server>
        <Port>587</Port>
        <LoginName>john@example.com</LoginName>
        <SSL>off</SSL>
      </Protocol>
    </Account>";

    fn server(host: &str, port: u16, security: ServerSecurity) -> Option<Server> {
        Some(Server {
            host: host.into(),
            port,
            security,
        })
    }

    #[test]
    fn pox_responses() {
        let found = parse_pox(&pox(EMAIL_ACCOUNT)).unwrap().found;
        assert_eq!(found.imap, server("imap.example.com", 993, ServerSecurity::Tls));
        // SSL off is STARTTLS here: never a server without encryption
        assert_eq!(found.smtp, server("smtp.example.com", 587, ServerSecurity::StartTls));
        assert_eq!(found.username.as_deref(), Some("john@example.com"));

        // accounts that are not of type email
        let notes = parse_pox(&pox(&EMAIL_ACCOUNT.replacen("email", "notes", 1))).unwrap();
        assert!(!notes.found.names_host());
        // an empty body names nothing; a malformed one is no response
        assert!(!parse_pox("").unwrap().found.names_host());
        assert_eq!(parse_pox("<Autodiscover><Response>"), None);
    }

    #[test]
    fn pox_hostless_blocks() {
        // a hostless block of the same type does not discard the one that names a host
        let found = parse_pox(&pox("<Account>
              <AccountType>email</AccountType>
              <Protocol><Type>IMAP</Type><Server>imap.example.com</Server><Port>993</Port><SSL>on</SSL></Protocol>
              <Protocol><Type>IMAP</Type></Protocol>
              <Protocol><Type>SMTP</Type><Server>smtp.example.com</Server><Port>587</Port><SSL>off</SSL></Protocol>
              <Protocol><Type>SMTP</Type><Port>25</Port></Protocol>
            </Account>"))
        .unwrap()
        .found;
        assert_eq!(found.imap.unwrap().host, "imap.example.com");
        assert_eq!(found.smtp.unwrap().host, "smtp.example.com");
        // a block with no Server names nothing, so it is not an entry
        let none = parse_pox(&pox(
            "<Account><AccountType>email</AccountType><Protocol><Type>IMAP</Type><Port>993</Port><SSL>on</SSL></Protocol></Account>",
        ))
        .unwrap();
        assert_eq!(none.found, Discovered::default());
        // a hostless block comes first: the next one stands, and without SSL the port tells the encryption
        let later = parse_pox(&pox("<Account><AccountType>email</AccountType>\
            <Protocol><Type>IMAP</Type><Server></Server></Protocol>\
            <Protocol><Type>imap</Type><Server>Mail.Example.com</Server><Port>143</Port></Protocol>\
            <Protocol><Type>SMTP</Type><Server>mail.example.com</Server></Protocol></Account>"))
        .unwrap()
        .found;
        assert_eq!(later.imap, server("mail.example.com", 143, ServerSecurity::StartTls));
        assert_eq!(later.smtp, server("mail.example.com", 465, ServerSecurity::Tls));
        assert_eq!(later.username, None);
    }

    // ---- EmailEngine poxRedirectUrl

    #[test]
    fn pox_redirects() {
        let redirecting = pox(
            "<Account><Action>redirectUrl</Action><RedirectUrl>https://real.example.net/autodiscover/autodiscover.xml</RedirectUrl></Account>",
        );
        assert_eq!(
            parse_pox(&redirecting).unwrap().redirect_url.as_deref(),
            Some("https://real.example.net/autodiscover/autodiscover.xml")
        );
        // a stray RedirectUrl without the action is not a redirect
        let stray = pox("<Account><RedirectUrl>https://real.example.net/x</RedirectUrl></Account>");
        assert_eq!(parse_pox(&stray).unwrap().redirect_url, None);
        // a RedirectAddr names another address
        let addr =
            pox("<Account><Action>redirectAddr</Action><RedirectAddr>other@example.net</RedirectAddr></Account>");
        assert_eq!(parse_pox(&addr).unwrap().redirect_url, None);
        assert_eq!(parse_pox(&pox(EMAIL_ACCOUNT)).unwrap().redirect_url, None);
        assert_eq!(parse_pox("not xml at all").unwrap().redirect_url, None);
    }

    // ---- EmailEngine processAutodiscoverSoapResponse

    fn soap(settings: &str) -> String {
        format!(
            r#"<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>
    <GetUserSettingsResponseMessage xmlns="http://schemas.microsoft.com/exchange/2010/Autodiscover">
      <Response>
        <ErrorCode>NoError</ErrorCode>
        <UserResponses>
          <UserResponse>
            <ErrorCode>NoError</ErrorCode>
            <UserSettings>{settings}</UserSettings>
          </UserResponse>
        </UserResponses>
      </Response>
    </GetUserSettingsResponseMessage>
  </s:Body>
</s:Envelope>"#
        )
    }

    fn connections(name: &str, list: &[(&str, u16, &str)]) -> String {
        let entries: String = list
            .iter()
            .map(|(host, port, encryption)| {
                format!(
                    "<ProtocolConnection><Hostname>{host}</Hostname><Port>{port}</Port><EncryptionMethod>{encryption}</EncryptionMethod></ProtocolConnection>"
                )
            })
            .collect();
        format!(
            r#"<UserSetting i:type="ProtocolConnectionCollectionSetting" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><Name>{name}</Name><ProtocolConnections>{entries}</ProtocolConnections></UserSetting>"#
        )
    }

    /// What hosted Exchange answers: IMAP on both ports, SMTP on submission only, every entry repeated
    fn ovh_style() -> String {
        connections(
            "ExternalImap4Connections",
            &[
                ("pro2.mail.ovh.net", 143, "TLS"),
                ("pro2.mail.ovh.net", 993, "SSL"),
                ("pro2.mail.ovh.net", 143, "TLS"),
                ("pro2.mail.ovh.net", 993, "SSL"),
            ],
        ) + &connections(
            "ExternalSmtpConnections",
            &[("pro2.mail.ovh.net", 587, "TLS"), ("pro2.mail.ovh.net", 587, "TLS")],
        )
    }

    #[test]
    fn soap_responses() {
        let found = parse_soap(&soap(&ovh_style())).unwrap();
        // implicit TLS wins over the STARTTLS entry listed before it
        assert_eq!(found.imap, server("pro2.mail.ovh.net", 993, ServerSecurity::Tls));
        assert_eq!(found.smtp, server("pro2.mail.ovh.net", 587, ServerSecurity::StartTls));

        let starttls = parse_soap(&soap(&connections(
            "ExternalImap4Connections",
            &[("mail.example.com", 143, "TLS")],
        )));
        assert_eq!(
            starttls.as_ref().unwrap().imap,
            server("mail.example.com", 143, ServerSecurity::StartTls)
        );
        assert_eq!(starttls.unwrap().smtp, None);

        let smtp_only = parse_soap(&soap(&connections(
            "ExternalSmtpConnections",
            &[("mail.example.com", 587, "TLS")],
        )));
        assert_eq!(smtp_only.as_ref().unwrap().imap, None);
        assert_eq!(
            smtp_only.unwrap().smtp,
            server("mail.example.com", 587, ServerSecurity::StartTls)
        );

        // no usable host or port
        let unusable = connections(
            "ExternalImap4Connections",
            &[("", 993, "SSL"), ("mail.example.com", 0, "SSL")],
        );
        assert_eq!(parse_soap(&soap(&unusable)).unwrap().imap, None);
        // None is STARTTLS too: never a server without encryption
        let plain = connections("ExternalImap4Connections", &[("mail.example.com", 143, "None")]);
        assert_eq!(
            parse_soap(&soap(&plain)).unwrap().imap.unwrap().security,
            ServerSecurity::StartTls
        );

        assert_eq!(parse_soap(&soap("")), Some(Discovered::default()));
        assert_eq!(
            parse_soap(r#"<?xml version="1.0"?><nothing/>"#),
            Some(Discovered::default())
        );
        assert_eq!(parse_soap("<s:Envelope><s:Body>"), None);
    }

    // ---- EmailEngine runAutodiscovery: a stand-in network that records every request

    enum Reply {
        Status(u16),
        Body(u16, String),
        /// A 401 with this challenge
        Challenge(&'static str),
        /// A redirect to this URL
        Redirect(u16, String),
        /// The connection fails
        Fail,
        /// Never answers
        Stall,
    }

    type Handler = Box<dyn Fn(&str, usize) -> Reply + Send + Sync>;

    struct Stub {
        calls: Mutex<Vec<HttpRequest>>,
        handler: Handler,
        srv: Vec<SrvRecord>,
    }

    /// `post https://host/path` or `get http://...`
    fn key(request: &HttpRequest) -> String {
        let method = if request.method == Method::Post { "post" } else { "get" };
        format!("{method} {}", request.url)
    }

    impl Stub {
        fn new(handler: impl Fn(&str, usize) -> Reply + Send + Sync + 'static) -> Stub {
            Stub {
                calls: Mutex::new(Vec::new()),
                handler: Box::new(handler),
                srv: Vec::new(),
            }
        }

        fn calls(&self) -> Vec<HttpRequest> {
            self.calls.lock().unwrap().clone()
        }

        fn keys(&self) -> Vec<String> {
            self.calls().iter().map(key).collect()
        }
    }

    impl Io for Stub {
        fn http(&self, request: HttpRequest) -> impl Future<Output = Result<Response, HttpError>> + Send {
            let number = {
                let mut calls = self.calls.lock().unwrap();
                calls.push(request.clone());
                calls.len()
            };
            let reply = (self.handler)(&key(&request), number);
            async move {
                match reply {
                    Reply::Status(status) => Ok(Response::new(status, "")),
                    Reply::Body(status, body) => Ok(Response::new(status, body)),
                    Reply::Challenge(challenge) => Ok(Response {
                        headers: vec![("WWW-Authenticate".into(), challenge.into())],
                        ..Response::new(401, "")
                    }),
                    Reply::Redirect(status, to) => Ok(Response {
                        headers: vec![("Location".into(), to)],
                        ..Response::new(status, "")
                    }),
                    Reply::Fail => Err(HttpError::Malformed),
                    Reply::Stall => std::future::pending().await,
                }
            }
        }

        async fn mx(&self, _: &str) -> Vec<crate::dns::MxRecord> {
            Vec::new()
        }

        async fn srv(&self, _: &str) -> Vec<SrvRecord> {
            self.srv.clone()
        }
    }

    const BASIC: &str = "Basic realm=\"test\", Negotiate, NTLM";
    const ORIGIN: &str = "https://autodiscover.example.com";
    const POX_URL: &str = "post https://autodiscover.example.com/autodiscover/autodiscover.xml";
    const SOAP_URL: &str = "post https://autodiscover.example.com/autodiscover/autodiscover.svc";
    const EMAIL: &str = "user@example.com";

    fn credentials() -> Credentials {
        Credentials {
            user: Some("user@example.com".into()),
            password: "secret".into(),
        }
    }

    fn pox_with_imap() -> String {
        pox("<Account><AccountType>email</AccountType>\
            <Protocol><Type>IMAP</Type><Server>imap.example.com</Server><Port>993</Port><SSL>on</SSL><LoginName>real-login</LoginName></Protocol>\
            <Protocol><Type>SMTP</Type><Server>smtp.example.com</Server><Port>587</Port><SSL>off</SSL></Protocol></Account>")
    }

    /// What hosted Exchange answers an authenticated POX request with: webmail only
    fn pox_web_only() -> String {
        pox("<Account><AccountType>email</AccountType><Protocol><Type>WEB</Type></Protocol></Account>")
    }

    fn authorization(request: &HttpRequest) -> Option<&str> {
        request.header("authorization")
    }

    async fn run_with(stub: &Stub, credentials: Option<&Credentials>) -> Option<Discovered> {
        run(stub, ORIGIN.to_string(), EMAIL, credentials, MAX_REDIRECTS).await
    }

    #[tokio::test]
    async fn announces_text_xml_and_keeps_an_anonymous_answer_anonymous() {
        let stub = Stub::new(|key, _| match key {
            POX_URL => Reply::Body(200, pox_with_imap()),
            _ => Reply::Status(404),
        });
        let creds = credentials();
        let found = run_with(&stub, Some(&creds)).await.unwrap();
        assert_eq!(found.imap, server("imap.example.com", 993, ServerSecurity::Tls));
        assert_eq!(found.username.as_deref(), Some("real-login"));
        let calls = stub.calls();
        assert_eq!(calls.len(), 1, "one request is enough when it is answered");
        assert_eq!(calls[0].header("content-type"), Some("text/xml; charset=utf-8"));
        assert_eq!(authorization(&calls[0]), None, "no password before it is asked for");
        assert_eq!(calls[0].body, build_pox_request(EMAIL).into_bytes());
    }

    #[tokio::test]
    async fn asks_anonymously_first_then_with_the_password() {
        let stub = Stub::new(|key, n| match key {
            POX_URL if n == 1 => Reply::Challenge(BASIC),
            POX_URL => Reply::Body(200, pox_with_imap()),
            _ => Reply::Challenge(BASIC),
        });
        let creds = credentials();
        let found = run_with(&stub, Some(&creds)).await.unwrap();
        assert_eq!(found.smtp, server("smtp.example.com", 587, ServerSecurity::StartTls));
        let calls = stub.calls();
        assert_eq!(authorization(&calls[0]), None);
        // base64 of user@example.com:secret
        let sent = calls.iter().find_map(authorization).unwrap();
        assert_eq!(sent, "Basic dXNlckBleGFtcGxlLmNvbTpzZWNyZXQ=");
        // and only to the origin that challenged, over HTTPS
        assert!(
            calls
                .iter()
                .filter(|c| authorization(c).is_some())
                .all(|c| c.url.starts_with(ORIGIN))
        );
    }

    #[tokio::test]
    async fn an_anonymous_answer_without_a_server_ends_the_lookup() {
        let no_server = pox(
            "<Account><AccountType>email</AccountType><Protocol><Type>IMAP</Type><Port>993</Port><SSL>on</SSL></Protocol></Account>",
        );
        for body in [no_server, pox_web_only()] {
            let stub = Stub::new(move |key, _| match key {
                POX_URL => Reply::Body(200, body.clone()),
                _ => Reply::Challenge(BASIC),
            });
            let creds = credentials();
            assert_eq!(run_with(&stub, Some(&creds)).await, None);
            assert_eq!(stub.calls().len(), 1, "a 200 is not a request for credentials");
        }
    }

    #[tokio::test]
    async fn no_password_without_a_basic_challenge() {
        // a challenge that does not offer Basic, a 404 from a parking host, a 500
        for first in [
            Reply::Challenge("Negotiate, NTLM"),
            Reply::Status(404),
            Reply::Status(500),
        ] {
            let first = Mutex::new(Some(first));
            let stub = Stub::new(move |key, _| match key {
                POX_URL => first.lock().unwrap().take().unwrap_or(Reply::Status(500)),
                _ => Reply::Body(200, soap(&ovh_style())),
            });
            let creds = credentials();
            assert_eq!(run_with(&stub, Some(&creds)).await, None);
            assert_eq!(stub.calls().len(), 1);
        }
        // "basic" inside another word is not Basic
        let stub = Stub::new(|key, _| match key {
            POX_URL => Reply::Challenge("Negotiate realm=\"notbasic\""),
            _ => Reply::Body(200, soap(&ovh_style())),
        });
        assert_eq!(run_with(&stub, Some(&credentials())).await, None);
        assert_eq!(stub.calls().len(), 1);
    }

    #[tokio::test]
    async fn gives_up_without_credentials() {
        let stub = Stub::new(|key, _| match key {
            POX_URL => Reply::Challenge(BASIC),
            _ => Reply::Body(200, soap(&ovh_style())),
        });
        assert_eq!(run_with(&stub, None).await, None);
        assert_eq!(
            stub.calls().len(),
            1,
            "nothing is asked that cannot be answered without a password"
        );
        let empty = Credentials {
            user: None,
            password: String::new(),
        };
        assert_eq!(run_with(&stub, Some(&empty)).await, None);
        assert_eq!(stub.calls().len(), 2);
    }

    #[tokio::test]
    async fn soap_when_pox_names_no_imap() {
        let stub = Stub::new(|key, n| match key {
            POX_URL if n == 1 => Reply::Challenge(BASIC),
            POX_URL => Reply::Body(200, pox_web_only()),
            SOAP_URL => Reply::Body(200, soap(&ovh_style())),
            _ => Reply::Status(404),
        });
        let found = run_with(&stub, Some(&credentials())).await.unwrap();
        assert_eq!(found.imap, server("pro2.mail.ovh.net", 993, ServerSecurity::Tls));
        assert_eq!(found.smtp, server("pro2.mail.ovh.net", 587, ServerSecurity::StartTls));
        let calls = stub.calls();
        let soap_call = calls.iter().find(|c| key(c) == SOAP_URL).unwrap();
        assert!(authorization(soap_call).is_some());
        assert_eq!(soap_call.body, build_soap_request(EMAIL).into_bytes());
    }

    #[tokio::test]
    async fn pox_wins_a_tie_because_it_names_the_login() {
        let stub = Stub::new(|key, n| match key {
            POX_URL if n == 1 => Reply::Challenge(BASIC),
            POX_URL => Reply::Body(200, pox_with_imap()),
            _ => Reply::Body(200, soap(&ovh_style())),
        });
        let found = run_with(&stub, Some(&credentials())).await.unwrap();
        assert_eq!(found.username.as_deref(), Some("real-login"));
        assert_eq!(
            stub.keys().iter().filter(|k| *k == SOAP_URL).count(),
            1,
            "both asked at once"
        );
    }

    #[tokio::test]
    async fn does_not_wait_for_a_stalled_endpoint() {
        let stub = Stub::new(|key, n| match key {
            POX_URL if n == 1 => Reply::Challenge(BASIC),
            POX_URL => Reply::Body(200, pox_with_imap()),
            _ => Reply::Stall,
        });
        let found = run_with(&stub, Some(&credentials())).await.unwrap();
        assert_eq!(found.username.as_deref(), Some("real-login"));
        assert!(
            stub.keys().contains(&SOAP_URL.to_string()),
            "SOAP was asked and had not answered"
        );

        let stub = Stub::new(|key, n| match key {
            POX_URL if n == 1 => Reply::Challenge(BASIC),
            POX_URL => Reply::Stall,
            _ => Reply::Body(200, soap(&ovh_style())),
        });
        let found = run_with(&stub, Some(&credentials())).await.unwrap();
        assert_eq!(found.imap, server("pro2.mail.ovh.net", 993, ServerSecurity::Tls));
    }

    #[tokio::test]
    async fn the_password_goes_to_the_host_that_challenged() {
        // the anonymous request is redirected over HTTPS, and the host it ends at challenges
        let stub = Stub::new(|key, _| match key {
            POX_URL => Reply::Redirect(302, "https://mail.example.net/autodiscover/autodiscover.xml".into()),
            "post https://mail.example.net/autodiscover/autodiscover.xml" => Reply::Challenge(BASIC),
            "post https://mail.example.net/autodiscover/autodiscover.svc" => Reply::Body(200, soap(&ovh_style())),
            _ => Reply::Status(404),
        });
        let found = run_with(&stub, Some(&credentials())).await.unwrap();
        assert_eq!(found.imap, server("pro2.mail.ovh.net", 993, ServerSecurity::Tls));
        for call in stub.calls().iter().filter(|c| authorization(c).is_some()) {
            assert!(call.url.starts_with("https://mail.example.net/"), "{}", call.url);
        }
        assert!(authorization(&stub.calls()[0]).is_none() && authorization(&stub.calls()[1]).is_none());
    }

    #[tokio::test]
    async fn no_password_after_a_redirect_to_plain_http() {
        let stub = Stub::new(|key, _| match key {
            POX_URL => Reply::Redirect(
                307,
                "http://downgraded.example.net/autodiscover/autodiscover.xml".into(),
            ),
            _ => Reply::Challenge(BASIC),
        });
        assert_eq!(run_with(&stub, Some(&credentials())).await, None);
        assert_eq!(stub.calls().len(), 1, "the redirect to http is not followed at all");
    }

    #[tokio::test]
    async fn the_password_does_not_follow_a_redirect() {
        // the credentialed answer redirects elsewhere: not followed, with or without the password
        let stub = Stub::new(|key, n| match key {
            POX_URL if n == 1 => Reply::Challenge(BASIC),
            POX_URL | SOAP_URL => Reply::Redirect(
                302,
                "https://collector.example.org/autodiscover/autodiscover.xml".into(),
            ),
            _ => Reply::Body(200, pox_with_imap()),
        });
        assert_eq!(run_with(&stub, Some(&credentials())).await, None);
        assert!(stub.calls().iter().all(|c| c.url.starts_with(ORIGIN)));
    }

    #[tokio::test]
    async fn refused_credentials_and_failures() {
        let stub = Stub::new(|_, _| Reply::Challenge(BASIC));
        assert_eq!(run_with(&stub, Some(&credentials())).await, None);
        assert_eq!(stub.calls().len(), 3);

        // one endpoint failing outright does not lose the other's answer
        let stub = Stub::new(|key, n| match key {
            POX_URL if n == 1 => Reply::Challenge(BASIC),
            POX_URL => Reply::Fail,
            _ => Reply::Body(200, soap(&ovh_style())),
        });
        assert!(run_with(&stub, Some(&credentials())).await.unwrap().names_host());
    }

    #[tokio::test]
    async fn the_address_is_the_login_by_default() {
        let stub = Stub::new(|key, n| match key {
            POX_URL if n == 1 => Reply::Challenge(BASIC),
            POX_URL => Reply::Body(200, pox_with_imap()),
            _ => Reply::Challenge(BASIC),
        });
        let creds = Credentials {
            user: None,
            password: "secret".into(),
        };
        run_with(&stub, Some(&creds)).await.unwrap();
        assert_eq!(
            stub.calls().iter().find_map(authorization),
            Some("Basic dXNlckBleGFtcGxlLmNvbTpzZWNyZXQ=")
        );
    }

    // ---- EmailEngine "autodiscovery reaches the endpoints the sequence names"

    const HTTP_GET: &str = "get http://autodiscover.example.com/autodiscover/autodiscover.xml";

    #[tokio::test]
    async fn nothing_is_asked_over_plain_http() {
        // a plain-HTTP answer could come from anyone on the network: that step of Microsoft's is not taken
        let stub = Stub::new(|key, _| match key {
            HTTP_GET => Reply::Redirect(302, "https://autodiscover.attacker.example/x".into()),
            _ => Reply::Status(404),
        });
        assert_eq!(resolve(&stub, EMAIL, "example.com", Some(&credentials())).await, None);
        assert!(
            stub.calls().iter().all(|c| c.url.starts_with("https://")),
            "{:?}",
            stub.keys()
        );
        assert!(!stub.keys().iter().any(|k| k.contains("attacker")));
        assert!(stub.calls().iter().all(|c| authorization(c).is_none()));
    }

    #[tokio::test]
    async fn the_root_domain_and_the_srv_host() {
        let stub = Stub::new(|key, _| match key {
            "post https://example.com/autodiscover/autodiscover.xml" => Reply::Body(200, pox_with_imap()),
            _ => Reply::Status(404),
        });
        assert!(resolve(&stub, EMAIL, "example.com", None).await.unwrap().names_host());

        let mut stub = Stub::new(|key, _| match key {
            "post https://ad.provider.example:8443/autodiscover/autodiscover.xml" => Reply::Body(200, pox_with_imap()),
            _ => Reply::Status(404),
        });
        stub.srv = vec![SrvRecord {
            priority: 0,
            weight: 0,
            port: 8443,
            target: "ad.provider.example".into(),
        }];
        assert!(resolve(&stub, EMAIL, "example.com", None).await.unwrap().names_host());
        assert!(
            !stub.keys().contains(&POX_URL.to_string()),
            "the SRV host replaces the subdomain"
        );
    }

    #[tokio::test]
    async fn in_response_redirects() {
        let redirecting = pox(
            "<Account><Action>redirectUrl</Action><RedirectUrl>https://real.example.net/autodiscover/autodiscover.xml</RedirectUrl></Account>",
        );
        // followed to the endpoint it names
        let body = redirecting.clone();
        let stub = Stub::new(move |key, _| match key {
            POX_URL => Reply::Body(200, body.clone()),
            "post https://real.example.net/autodiscover/autodiscover.xml" => Reply::Body(200, pox_with_imap()),
            _ => Reply::Status(404),
        });
        assert!(run_with(&stub, None).await.unwrap().names_host());
        assert_eq!(
            stub.keys(),
            [POX_URL, "post https://real.example.net/autodiscover/autodiscover.xml"]
        );

        // anonymously, never with the password, even when the endpoint it names challenges
        let stub = Stub::new(move |key, _| match key {
            POX_URL => Reply::Body(200, redirecting.clone()),
            _ => Reply::Challenge(BASIC),
        });
        assert_eq!(run_with(&stub, Some(&credentials())).await, None);
        assert!(
            stub.keys()
                .iter()
                .any(|k| k.starts_with("post https://real.example.net"))
        );
        assert!(stub.calls().iter().all(|c| authorization(c).is_none()));

        // a loop is bounded
        let to = |host: &str| {
            pox(&format!(
                "<Account><Action>redirectUrl</Action><RedirectUrl>https://{host}/autodiscover/autodiscover.xml</RedirectUrl></Account>"
            ))
        };
        let stub = Stub::new(move |key, _| {
            if key.contains("//a.example.com") {
                Reply::Body(200, to("b.example.com"))
            } else {
                Reply::Body(200, to("a.example.com"))
            }
        });
        assert_eq!(
            run(&stub, "https://a.example.com".into(), EMAIL, None, MAX_REDIRECTS).await,
            None
        );
        assert_eq!(stub.calls().len(), MAX_REDIRECTS as usize + 1);

        // a redirect to plain http is not followed
        let stub = Stub::new(move |_, _| {
            Reply::Body(
                200,
                pox("<Account><Action>redirectUrl</Action><RedirectUrl>http://x.example.net/a</RedirectUrl></Account>"),
            )
        });
        assert_eq!(run_with(&stub, None).await, None);
        assert_eq!(stub.calls().len(), 1);
    }

    #[tokio::test]
    async fn an_answer_naming_no_server_is_a_loss_everywhere() {
        let stub = Stub::new(|key, _| match key {
            k if k.ends_with("/autodiscover/autodiscover.xml") && k.starts_with("post") => {
                Reply::Body(200, pox_web_only())
            }
            _ => Reply::Status(404),
        });
        assert_eq!(resolve(&stub, EMAIL, "example.com", None).await, None);
        // no credential is ever attached to the http GET, or sent anywhere here
        let stub = Stub::new(|key, _| match key {
            HTTP_GET => Reply::Redirect(
                302,
                "https://autodiscover.1and1.info/Autodiscover/Autodiscover.xml".into(),
            ),
            _ => Reply::Status(404),
        });
        assert_eq!(resolve(&stub, EMAIL, "example.com", Some(&credentials())).await, None);
        assert!(stub.calls().iter().all(|c| authorization(c).is_none()));
    }
}
