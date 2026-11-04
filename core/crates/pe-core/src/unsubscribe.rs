//! Unsubscribing from a mailing list: the `List-Unsubscribe` header (RFC 2369) offers a page, a message to send or,
//! with `List-Unsubscribe-Post` (RFC 8058), a one-click POST. The POST is offered only for a message whose DKIM
//! signature covers both headers, as RFC 8058 asks: the receiving server's verdict, the topmost
//! Authentication-Results header (a sender can add one of its own, but only below the servers'), says `dkim=pass` for
//! a domain whose DKIM-Signature lists them. Every address is read here, from the message, never from the window.

use pe_mime::parser::Header;

/// How a message lets its reader leave its list
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Unsubscribe {
    /// A POST of `List-Unsubscribe=One-Click` to this https address does it
    OneClick { url: String },
    /// A message to this `mailto:` link, written for the user to send
    Mail { link: String },
    /// A page on the web, opened in the browser
    Web { url: String },
}

impl Unsubscribe {
    /// The host it goes to, or the address the message goes to, for the window to say
    pub fn target(&self) -> String {
        match self {
            Unsubscribe::OneClick { url } | Unsubscribe::Web { url } => {
                pe_net::http::parse_url(url).map(|u| u.host).unwrap_or_default()
            }
            Unsubscribe::Mail { link } => crate::mailto::draft(link).map(|draft| draft.to).unwrap_or_default(),
        }
    }
}

fn header<'a>(headers: &'a [Header], key: &'a str) -> impl Iterator<Item = &'a str> {
    headers
        .iter()
        .filter(move |h| h.key.eq_ignore_ascii_case(key))
        .map(|h| h.value.as_str())
}

/// The addresses of `List-Unsubscribe`: what is in angle brackets
fn addresses(value: &str) -> Vec<&str> {
    value
        .split('<')
        .skip(1)
        .filter_map(|part| part.split_once('>').map(|(address, _)| address.trim()))
        .collect()
}

/// The value of a tag of a DKIM-Signature or a property of Authentication-Results (`d=`, `header.d=`)
fn tag<'a>(value: &'a str, name: &str) -> Option<&'a str> {
    value
        .split([';', ' ', '\t', '\r', '\n'])
        .filter_map(|part| part.split_once('='))
        .find(|(key, _)| key.trim().eq_ignore_ascii_case(name))
        .map(|(_, value)| value.trim().trim_matches('"'))
}

/// The domains the receiving server says signed the message: `dkim=pass` results of the topmost
/// Authentication-Results
fn passed_domains(headers: &[Header]) -> Vec<String> {
    let Some(results) = header(headers, "authentication-results").next() else {
        return Vec::new();
    };
    // after the server's id, one result per `;`
    results
        .split(';')
        .skip(1)
        .filter(|result| {
            result
                .split_whitespace()
                .next()
                .is_some_and(|method| method.eq_ignore_ascii_case("dkim=pass"))
        })
        .filter_map(|result| {
            tag(result, "header.d").map(str::to_string).or_else(|| {
                tag(result, "header.i")
                    .and_then(|i| i.rsplit('@').next())
                    .map(str::to_string)
            })
        })
        .map(|domain| domain.to_ascii_lowercase())
        .collect()
}

/// Whether a signature of a domain that passed covers both List-Unsubscribe headers
fn signed(headers: &[Header]) -> bool {
    let passed = passed_domains(headers);
    header(headers, "dkim-signature").any(|signature| {
        let compact: String = signature.chars().filter(|c| !c.is_whitespace()).collect();
        let domain = tag(&compact, "d").unwrap_or_default().to_ascii_lowercase();
        let covered: Vec<String> = tag(&compact, "h")
            .unwrap_or_default()
            .split(':')
            .map(|h| h.to_ascii_lowercase())
            .collect();
        passed.contains(&domain)
            && covered.iter().any(|h| h == "list-unsubscribe")
            && covered.iter().any(|h| h == "list-unsubscribe-post")
    })
}

/// How the message lets its reader leave its list, the one-click way first, then a message, then a page; None when
/// it does not say
pub fn of(headers: &[Header]) -> Option<Unsubscribe> {
    let list = header(headers, "list-unsubscribe").next()?;
    let addresses = addresses(list);
    // what this client goes to: https, or http to the loopback address (test servers)
    let web = addresses
        .iter()
        .find(|a| pe_net::http::parse_url(a).is_some())
        .map(|a| a.to_string());
    let mail = addresses
        .iter()
        .find(|a| crate::mailto::draft(a).is_some())
        .map(|a| a.to_string());
    let one_click = header(headers, "list-unsubscribe-post")
        .next()
        .is_some_and(|post| post.trim().eq_ignore_ascii_case("List-Unsubscribe=One-Click"));
    match (web, mail) {
        (Some(url), _) if one_click && signed(headers) => Some(Unsubscribe::OneClick { url }),
        (_, Some(link)) => Some(Unsubscribe::Mail { link }),
        (Some(url), None) => Some(Unsubscribe::Web { url }),
        (None, None) => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn headers(text: &str) -> Vec<Header> {
        let source = format!("{text}\r\nSubject: x\r\n\r\nbody\r\n");
        pe_mime::parser::parse(source.as_bytes()).unwrap().headers
    }

    const SIGNED: &str = "Authentication-Results: mx.example.net; spf=pass smtp.mailfrom=list.example.com; dkim=pass header.d=list.example.com header.s=s1\r\n\
        DKIM-Signature: v=1; a=rsa-sha256; d=list.example.com; s=s1;\r\n h=from:subject:list-unsubscribe:list-unsubscribe-post; bh=x; b=y\r\n\
        List-Unsubscribe: <mailto:leave@list.example.com?subject=unsubscribe>, <https://list.example.com/u/123>\r\n\
        List-Unsubscribe-Post: List-Unsubscribe=One-Click";

    #[test]
    fn one_click_only_when_signed() {
        assert_eq!(
            of(&headers(SIGNED)),
            Some(Unsubscribe::OneClick {
                url: "https://list.example.com/u/123".into()
            })
        );
        // the signature does not cover List-Unsubscribe-Post: the message to send instead
        let partly = SIGNED.replace("list-unsubscribe:list-unsubscribe-post", "list-unsubscribe");
        assert!(matches!(of(&headers(&partly)), Some(Unsubscribe::Mail { .. })));
        // the server says the signature failed, or another domain signed
        assert!(matches!(
            of(&headers(&SIGNED.replace("dkim=pass", "dkim=fail"))),
            Some(Unsubscribe::Mail { .. })
        ));
        assert!(matches!(
            of(&headers(
                &SIGNED.replace("header.d=list.example.com", "header.d=other.example")
            )),
            Some(Unsubscribe::Mail { .. })
        ));
        // a verdict of the sender's own, below the server's, counts for nothing
        let forged = format!(
            "Authentication-Results: mx.example.net; dkim=none\r\n{}",
            SIGNED.replace(
                "Authentication-Results: mx.example.net",
                "Authentication-Results: forged.example"
            )
        );
        assert!(matches!(of(&headers(&forged)), Some(Unsubscribe::Mail { .. })));
        // without List-Unsubscribe-Post, no POST
        let no_post = SIGNED.replace("List-Unsubscribe-Post: List-Unsubscribe=One-Click", "X-Other: 1");
        assert!(matches!(of(&headers(&no_post)), Some(Unsubscribe::Mail { .. })));
    }

    #[test]
    fn a_page_or_a_message_otherwise() {
        let page = headers("List-Unsubscribe: <https://news.example.com/leave>");
        assert_eq!(
            of(&page),
            Some(Unsubscribe::Web {
                url: "https://news.example.com/leave".into()
            })
        );
        assert_eq!(of(&page).unwrap().target(), "news.example.com");
        let mail = of(&headers("List-Unsubscribe: <mailto:off@news.example.com?subject=stop>")).unwrap();
        assert_eq!(mail.target(), "off@news.example.com");
        // plain http to the internet, javascript: and the like are not gone to
        assert_eq!(
            of(&headers(
                "List-Unsubscribe: <http://news.example.com/leave>, <javascript:alert(1)>"
            )),
            None
        );
        assert_eq!(of(&headers("X-Other: 1")), None);
    }
}
