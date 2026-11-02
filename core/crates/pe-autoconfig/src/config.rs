//! Thunderbird's autoconfig XML (https://wiki.mozilla.org/Thunderbird:Autoconfiguration:ConfigFileFormat): the
//! first IMAP server and the first SMTP server with encryption, their user name template filled in

use crate::Discovered;

use quick_xml::Reader;
use quick_xml::events::Event;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ServerSecurity {
    /// TLS from the start
    Tls,
    StartTls,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Server {
    pub host: String,
    pub port: u16,
    pub security: ServerSecurity,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Found {
    pub imap: Server,
    pub smtp: Server,
    pub username: String,
    pub oauth2: bool,
}

#[derive(Default)]
struct Entry {
    kind: String,
    host: String,
    port: String,
    socket: String,
    username: String,
    oauth2: bool,
}

impl Entry {
    /// A server to use: a host name (`%EMAILDOMAIN%` is `domain`), a port, and encryption; a server without
    /// encryption is no option
    fn server(&self, domain: &str) -> Option<Server> {
        let host = if self.host == "%EMAILDOMAIN%" {
            domain
        } else {
            self.host.as_str()
        };
        let valid_host = !host.is_empty()
            && host.len() <= 253
            && host
                .bytes()
                .all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'.');
        let port: u16 = self.port.trim().parse().ok().filter(|p| *p > 0)?;
        let security = match self.socket.trim().to_ascii_uppercase().as_str() {
            "SSL" | "TLS" => ServerSecurity::Tls,
            "STARTTLS" => ServerSecurity::StartTls,
            _ => return None,
        };
        valid_host.then(|| Server {
            host: host.to_ascii_lowercase(),
            port,
            security,
        })
    }
}

/// `%EMAILADDRESS%`, `%EMAILLOCALPART%` and `%EMAILDOMAIN%` filled in
fn fill(template: &str, email: &str) -> String {
    let (local, domain) = email.rsplit_once('@').unwrap_or((email, ""));
    template
        .replace("%EMAILADDRESS%", email)
        .replace("%EMAILLOCALPART%", local)
        .replace("%EMAILDOMAIN%", domain)
}

/// The servers of a configuration file for `email`; None when it has no usable IMAP and SMTP server
pub fn parse_config(xml: &str, email: &str) -> Option<Found> {
    let email = email.trim();
    let domain = email.rsplit_once('@').map(|(_, d)| d).unwrap_or_default();
    let found = parse_partial(xml, email, &domain.to_ascii_lowercase())?;
    Some(Found {
        imap: found.imap?,
        smtp: found.smtp?,
        username: found.username.unwrap_or_else(|| email.to_string()),
        oauth2: found.oauth2,
    })
}

/// The servers of a configuration file for `email`, either of them missing when the file has none with encryption;
/// None when it is no configuration file or names no usable server at all. A host name `%EMAILDOMAIN%` is
/// `domain`.
pub fn parse_partial(xml: &str, email: &str, domain: &str) -> Option<Discovered> {
    let email = email.trim();
    let entries = parse_entries(xml)?;
    let pick = |kind: &str| {
        entries
            .iter()
            .filter(|e| e.kind == kind)
            .find_map(|e| Some((e, e.server(domain)?)))
    };
    let imap = pick("imap");
    let smtp = pick("smtp");
    // the user name and OAuth of the IMAP server, or of the SMTP server when there is no IMAP one
    let named = imap.as_ref().or(smtp.as_ref()).map(|(entry, _)| *entry)?;
    let username = (!named.username.is_empty()).then(|| fill(&named.username, email));
    Some(Discovered {
        imap: imap.map(|(_, server)| server),
        smtp: smtp.map(|(_, server)| server),
        username,
        oauth2: named.oauth2,
    })
}

/// The server entries of a configuration file
fn parse_entries(xml: &str) -> Option<Vec<Entry>> {
    let mut reader = Reader::from_str(xml);
    let mut entries: Vec<Entry> = Vec::new();
    let mut current: Option<Entry> = None;
    // the text of the element being read: quick-xml hands text, CDATA and references over separately
    let mut text = String::new();
    loop {
        match reader.read_event().ok()? {
            Event::Start(tag) => {
                let name = tag.local_name();
                if name.as_ref() == "incomingServer" || name.as_ref() == "outgoingServer" {
                    let kind = tag
                        .attributes()
                        .flatten()
                        .find(|a| a.key.as_ref() == "type")
                        .map(|a| a.value.to_ascii_lowercase())
                        .unwrap_or_default();
                    current = Some(Entry {
                        kind,
                        ..Default::default()
                    });
                }
                text.clear();
            }
            Event::Text(part) => text.push_str(&part),
            Event::CData(part) => text.push_str(&part),
            Event::GeneralRef(reference) => {
                if reference.is_char_ref() {
                    text.extend(reference.resolve_char_ref().ok().flatten());
                } else if let Some(resolved) = quick_xml::escape::resolve_predefined_entity(&reference) {
                    text.push_str(resolved);
                }
            }
            Event::End(tag) => {
                let name = tag.local_name();
                let value = std::mem::take(&mut text).trim().to_string();
                match (name.as_ref(), current.as_mut()) {
                    ("incomingServer" | "outgoingServer", Some(_)) => entries.extend(current.take()),
                    ("hostname", Some(entry)) => entry.host = value,
                    ("port", Some(entry)) => entry.port = value,
                    ("socketType", Some(entry)) => entry.socket = value,
                    ("username", Some(entry)) => entry.username = value,
                    ("authentication", Some(entry)) => entry.oauth2 |= value.eq_ignore_ascii_case("OAuth2"),
                    _ => {}
                }
            }
            Event::Eof => break,
            _ => {}
        }
        // a configuration file is short; a long one is not one
        if entries.len() > 64 || text.len() > 4096 {
            return None;
        }
    }
    Some(entries)
}

#[cfg(test)]
mod tests {
    use super::*;

    const GMAIL_LIKE: &str = r#"<?xml version="1.0"?>
<clientConfig version="1.1">
  <emailProvider id="example.com">
    <domain>example.com</domain>
    <incomingServer type="pop3">
      <hostname>pop.example.com</hostname><port>995</port><socketType>SSL</socketType>
    </incomingServer>
    <incomingServer type="imap">
      <hostname>plain.example.com</hostname><port>143</port><socketType>plain</socketType>
    </incomingServer>
    <incomingServer type="imap">
      <hostname>IMAP.example.com</hostname>
      <port>993</port>
      <socketType>SSL</socketType>
      <username>%EMAILADDRESS%</username>
      <authentication>OAuth2</authentication>
      <authentication>password-cleartext</authentication>
    </incomingServer>
    <outgoingServer type="smtp">
      <hostname>smtp.example.com</hostname>
      <port>587</port>
      <socketType>STARTTLS</socketType>
      <username>%EMAILLOCALPART%</username>
    </outgoingServer>
  </emailProvider>
</clientConfig>"#;

    #[test]
    fn picks_encrypted_imap_and_smtp() {
        let found = parse_config(GMAIL_LIKE, "me@example.com").unwrap();
        assert_eq!(
            found.imap,
            Server {
                host: "imap.example.com".into(),
                port: 993,
                security: ServerSecurity::Tls
            }
        );
        assert_eq!(found.smtp.port, 587);
        assert_eq!(found.smtp.security, ServerSecurity::StartTls);
        assert_eq!(found.username, "me@example.com");
        assert!(found.oauth2);
    }

    #[test]
    fn refuses_what_is_no_configuration() {
        assert_eq!(parse_config("<html>not found</html>", "a@b.c"), None);
        assert_eq!(parse_config("not xml at all <<<", "a@b.c"), None);
        // only servers without encryption
        let plain = r#"<clientConfig><emailProvider><incomingServer type="imap"><hostname>h.com</hostname><port>143</port><socketType>plain</socketType></incomingServer><outgoingServer type="smtp"><hostname>h.com</hostname><port>25</port><socketType>plain</socketType></outgoingServer></emailProvider></clientConfig>"#;
        assert_eq!(parse_config(plain, "a@b.c"), None);
        // a host name that is not one: the next IMAP server would be taken, the plain one is no option
        let odd = GMAIL_LIKE.replace("IMAP.example.com", "imap.example.com/../evil");
        assert_eq!(parse_config(&odd, "a@b.c"), None);
        // references and CDATA are part of the text
        let refs = GMAIL_LIKE.replace(
            "<username>%EMAILADDRESS%</username>",
            "<username>a&#64;b&amp;<![CDATA[c]]></username>",
        );
        assert_eq!(parse_config(&refs, "me@example.com").unwrap().username, "a@b&c");
        assert_eq!(fill("%EMAILLOCALPART%@%EMAILDOMAIN%", "u@d.ee"), "u@d.ee");
    }

    fn doc(incoming: &str, outgoing: &str) -> String {
        format!(
            r#"<?xml version="1.0" encoding="UTF-8"?>
<clientConfig version="1.1"><emailProvider id="example.com">{incoming}{outgoing}</emailProvider></clientConfig>"#
        )
    }

    // EmailEngine processAutoconfigFile
    #[test]
    fn substitutes_the_domain_in_host_and_user() {
        let text = doc(
            "<incomingServer type=\"imap\"><hostname>%EMAILDOMAIN%</hostname><port>143</port><socketType>STARTTLS</socketType><username>%EMAILDOMAIN%</username></incomingServer>",
            "",
        );
        let found = parse_partial(&text, "john@sub.example.com", "sub.example.com").unwrap();
        let imap = found.imap.unwrap();
        assert_eq!(
            (imap.host.as_str(), imap.security),
            ("sub.example.com", ServerSecurity::StartTls)
        );
        assert_eq!(found.username.as_deref(), Some("sub.example.com"));
        assert_eq!(found.smtp, None);
    }

    #[test]
    fn either_half_is_an_answer() {
        // no servers at all: nothing
        assert_eq!(parse_partial(&doc("", ""), "j@example.com", "example.com"), None);
        // an empty host name is no server, the SMTP half stands
        let text = doc(
            "<incomingServer type=\"imap\"><hostname></hostname><port>993</port><socketType>SSL</socketType></incomingServer>",
            "<outgoingServer type=\"smtp\"><hostname>smtp.example.com</hostname><port>587</port><socketType>STARTTLS</socketType></outgoingServer>",
        );
        let found = parse_partial(&text, "j@example.com", "example.com").unwrap();
        assert_eq!(found.imap, None);
        assert_eq!(found.smtp.unwrap().host, "smtp.example.com");
        // a missing port and socketType do not discard the document
        let text = doc(
            "<incomingServer type=\"imap\"><hostname>imap.example.com</hostname></incomingServer>",
            "<outgoingServer type=\"smtp\"><hostname>smtp.example.com</hostname><port>465</port><socketType>SSL</socketType></outgoingServer>",
        );
        let found = parse_partial(&text, "j@example.com", "example.com").unwrap();
        assert_eq!(found.imap, None);
        assert_eq!(found.smtp.unwrap().port, 465);
    }

    #[test]
    fn a_hostless_server_does_not_shadow_a_later_one() {
        let text = doc(
            "<incomingServer type=\"pop3\"><hostname>pop.example.com</hostname><port>995</port><socketType>SSL</socketType></incomingServer>\
             <incomingServer type=\"imap\"><hostname></hostname><port>143</port><socketType>plain</socketType></incomingServer>\
             <incomingServer type=\"imap\"><hostname>imap.example.com</hostname><port>993</port><socketType>SSL</socketType></incomingServer>",
            "<outgoingServer type=\"smtp\"><hostname></hostname><port>25</port><socketType>plain</socketType></outgoingServer>\
             <outgoingServer type=\"smtp\"><hostname>smtp.example.com</hostname><port>587</port><socketType>STARTTLS</socketType></outgoingServer>",
        );
        let found = parse_partial(&text, "j@example.com", "example.com").unwrap();
        assert_eq!(found.imap.unwrap().port, 993);
        assert_eq!(found.smtp.unwrap().host, "smtp.example.com");
        // no <username>: none to fill in
        assert_eq!(found.username, None);
    }

    #[test]
    fn decodes_entities_in_values() {
        let text = doc(
            "<incomingServer type=\"imap\"><hostname>imap.example.com</hostname><port>993</port><socketType>SSL</socketType><username>john&amp;doe@example.com</username></incomingServer>",
            "",
        );
        let found = parse_partial(&text, "john&doe@example.com", "example.com").unwrap();
        assert_eq!(found.username.as_deref(), Some("john&doe@example.com"));
        assert_eq!(
            parse_partial(
                "<html><body><p>Not found<br></body></html>",
                "j@example.com",
                "example.com"
            ),
            None
        );
    }
}
