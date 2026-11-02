//! Providers known by the mail exchange of a domain: a custom domain hosted at Google, Microsoft 365, Zoho and
//! others has the servers of its host. Ported from EmailEngine (`resolveUsingMX` in
//! lib/autodetect-imap-settings.js), in the same order.

use crate::ServerSecurity::{StartTls, Tls};
use crate::{Discovered, Server, ServerSecurity};

/// What an exchange says about the servers
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Delegate {
    /// These servers
    Servers(Discovered),
    /// The SRV records of this domain
    Srv { domain: &'static str, oauth2: bool },
    /// The provider's autoconfig file of this domain
    Autoconfig(&'static str),
}

/// `suffix` at the end of `exchange`, at a word boundary (a regex `\bsuffix$`)
pub(crate) fn ends_with_word(exchange: &str, suffix: &str) -> bool {
    exchange
        .strip_suffix(suffix)
        .is_some_and(|rest| !rest.ends_with(|c: char| c.is_ascii_alphanumeric() || c == '_'))
}

/// `prefix`, digits or none, then `suffix`, the whole name (a regex `^prefix\d*suffix$`)
fn numbered(exchange: &str, prefix: &str, suffix: &str) -> bool {
    exchange
        .strip_prefix(prefix)
        .and_then(|rest| rest.strip_suffix(suffix))
        .is_some_and(|digits| digits.bytes().all(|b| b.is_ascii_digit()))
}

/// The region of an AWS WorkMail exchange, `inbound-smtp.<region>.amazonaws.com`
fn aws_region(exchange: &str) -> Option<&str> {
    let labels: Vec<&str> = exchange.split('.').collect();
    let at = labels.iter().position(|label| *label == "inbound-smtp")?;
    let region = *labels.get(at + 1)?;
    let valid = !region.is_empty() && region.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-');
    (valid && labels[at + 2..] == ["amazonaws", "com"]).then_some(region)
}

fn fixed(imap: (&str, u16, ServerSecurity), smtp: (&str, u16, ServerSecurity), oauth2: bool) -> Delegate {
    let server = |(host, port, security): (&str, u16, ServerSecurity)| Server {
        host: host.to_string(),
        port,
        security,
    };
    Delegate::Servers(Discovered {
        imap: Some(server(imap)),
        smtp: Some(server(smtp)),
        username: None,
        oauth2,
    })
}

/// What the exchange (lowercase, no trailing dot) of a domain says about its servers; None for one not known
pub fn delegate(exchange: &str) -> Option<Delegate> {
    let ex = exchange;
    if ends_with_word(ex, "l.google.com") {
        return Some(Delegate::Srv {
            domain: "gmail.com",
            oauth2: true,
        });
    }
    if ends_with_word(ex, "mx.yandex.net") {
        return Some(Delegate::Autoconfig("yandex.ru"));
    }
    if numbered(ex, "mx", ".zone.eu") {
        return Some(fixed(("mail.zone.ee", 993, Tls), ("smtp.zone.ee", 465, Tls), false));
    }
    if ends_with_word(ex, "larksuite.com") {
        return Some(fixed(
            ("imap.larksuite.com", 993, Tls),
            ("smtp.larksuite.com", 465, Tls),
            false,
        ));
    }
    if ends_with_word(ex, "zonemx.eu") {
        return Some(Delegate::Autoconfig("zone.ee"));
    }
    if let Some(region) = aws_region(ex) {
        let imap = format!("imap.mail.{region}.awsapps.com");
        let smtp = format!("smtp.mail.{region}.awsapps.com");
        return Some(fixed((&imap, 993, Tls), (&smtp, 465, Tls), false));
    }
    if numbered(ex, "mx", ".zoho.eu") {
        return Some(fixed(
            ("imappro.zoho.eu", 993, Tls),
            ("smtppro.zoho.eu", 465, Tls),
            false,
        ));
    }
    if numbered(ex, "mx", ".zoho.com") {
        return Some(fixed(
            ("imappro.zoho.com", 993, Tls),
            ("smtppro.zoho.com", 465, Tls),
            false,
        ));
    }
    if ends_with_word(ex, "protection.outlook.com") {
        // Microsoft 365: its autodiscover does not hand out IMAP settings, these are fixed
        return Some(fixed(
            ("outlook.office365.com", 993, Tls),
            ("smtp.office365.com", 587, StartTls),
            true,
        ));
    }
    if ex == "mx.dka.mailcore.net" {
        return Some(fixed(
            ("imap.dka.mailcore.net", 993, Tls),
            ("smtp.dka.mailcore.net", 587, StartTls),
            false,
        ));
    }
    if ex == "ekiri.ee" {
        return Some(fixed(
            ("turvaline.ekiri.ee", 993, Tls),
            ("turvaline.ekiri.ee", 465, Tls),
            false,
        ));
    }
    if numbered(ex, "mx", ".sg.aliyun.com") {
        return Some(fixed(
            ("imap.sg.aliyun.com", 993, Tls),
            ("smtp.sg.aliyun.com", 465, Tls),
            false,
        ));
    }
    if ex
        .strip_suffix(".prodigy.net")
        .is_some_and(|rest| rest.trim_end_matches(|c: char| c.is_ascii_digit()).ends_with("mx-vip"))
    {
        return Some(fixed(
            ("imap.mail.att.net", 993, Tls),
            ("smtp.mail.att.net", 465, Tls),
            false,
        ));
    }
    if numbered(ex, "mx", ".naver.com") {
        return Some(fixed(
            ("imap.naver.com", 993, Tls),
            ("smtp.naver.com", 587, StartTls),
            false,
        ));
    }
    if numbered(ex, "mxbiz", ".qq.com") {
        return Some(fixed(
            ("imap.exmail.qq.com", 993, Tls),
            ("smtp.exmail.qq.com", 465, Tls),
            false,
        ));
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    type Entry = (String, u16, ServerSecurity);

    fn servers(exchange: &str) -> Option<(Entry, Entry)> {
        match delegate(exchange)? {
            Delegate::Servers(found) => {
                let (imap, smtp) = (found.imap?, found.smtp?);
                Some((
                    (imap.host, imap.port, imap.security),
                    (smtp.host, smtp.port, smtp.security),
                ))
            }
            _ => None,
        }
    }

    // EmailEngine "maps the ... MX exchange to a fixed config"
    #[test]
    fn fixed_providers() {
        let table = [
            (
                "contoso.mail.protection.outlook.com",
                ("outlook.office365.com", 993, Tls),
                ("smtp.office365.com", 587, StartTls),
            ),
            (
                "mx.zoho.eu",
                ("imappro.zoho.eu", 993, Tls),
                ("smtppro.zoho.eu", 465, Tls),
            ),
            (
                "mx2.zoho.com",
                ("imappro.zoho.com", 993, Tls),
                ("smtppro.zoho.com", 465, Tls),
            ),
            ("mx1.zone.eu", ("mail.zone.ee", 993, Tls), ("smtp.zone.ee", 465, Tls)),
            (
                "inbound-smtp.eu-west-1.amazonaws.com",
                ("imap.mail.eu-west-1.awsapps.com", 993, Tls),
                ("smtp.mail.eu-west-1.awsapps.com", 465, Tls),
            ),
            (
                "mailfwd.larksuite.com",
                ("imap.larksuite.com", 993, Tls),
                ("smtp.larksuite.com", 465, Tls),
            ),
            (
                "mx1.naver.com",
                ("imap.naver.com", 993, Tls),
                ("smtp.naver.com", 587, StartTls),
            ),
            (
                "mxbiz1.qq.com",
                ("imap.exmail.qq.com", 993, Tls),
                ("smtp.exmail.qq.com", 465, Tls),
            ),
            (
                "mx1.sg.aliyun.com",
                ("imap.sg.aliyun.com", 993, Tls),
                ("smtp.sg.aliyun.com", 465, Tls),
            ),
            (
                "mx-vip1.prodigy.net",
                ("imap.mail.att.net", 993, Tls),
                ("smtp.mail.att.net", 465, Tls),
            ),
            (
                "mx.dka.mailcore.net",
                ("imap.dka.mailcore.net", 993, Tls),
                ("smtp.dka.mailcore.net", 587, StartTls),
            ),
            (
                "ekiri.ee",
                ("turvaline.ekiri.ee", 993, Tls),
                ("turvaline.ekiri.ee", 465, Tls),
            ),
        ];
        for (exchange, imap, smtp) in table {
            let (found_imap, found_smtp) = servers(exchange).unwrap_or_else(|| panic!("{exchange}"));
            assert_eq!(found_imap, (imap.0.to_string(), imap.1, imap.2), "{exchange}");
            assert_eq!(found_smtp, (smtp.0.to_string(), smtp.1, smtp.2), "{exchange}");
        }
        // OAuth 2.0 for Microsoft 365, not for the others
        let Some(Delegate::Servers(m365)) = delegate("contoso.mail.protection.outlook.com") else {
            panic!()
        };
        assert!(m365.oauth2);
        let Some(Delegate::Servers(zoho)) = delegate("mx.zoho.eu") else {
            panic!()
        };
        assert!(!zoho.oauth2);
    }

    #[test]
    fn delegated_lookups() {
        for google in [
            "gmail-smtp-in.l.google.com",
            "aspmx.l.google.com",
            "alt1.aspmx.l.google.com",
            "l.google.com",
        ] {
            assert_eq!(
                delegate(google),
                Some(Delegate::Srv {
                    domain: "gmail.com",
                    oauth2: true
                }),
                "{google}"
            );
        }
        assert_eq!(delegate("mx.yandex.net"), Some(Delegate::Autoconfig("yandex.ru")));
        assert_eq!(delegate("mx.zonemx.eu"), Some(Delegate::Autoconfig("zone.ee")));
    }

    #[test]
    fn near_misses_are_no_match() {
        for other in [
            "evil-l.google.com.example.com",
            "xl.google.com",
            "mx.example.com",
            "mxa.zoho.com",
            "mx1.zoho.com.evil.net",
            "mxbiz.qq.com.cn",
            "inbound-smtp.eu-west-1.amazonaws.com.evil.net",
            "inbound-smtp..amazonaws.com",
            "notprotection.outlook.com",
            "mx-vipx.prodigy.net",
            "sub.ekiri.ee",
        ] {
            assert_eq!(delegate(other), None, "{other}");
        }
        assert!(delegate("mx-vip.prodigy.net").is_some());
        assert!(delegate("mx.zone.eu").is_some());
    }
}
