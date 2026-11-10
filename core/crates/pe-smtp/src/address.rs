//! Addresses of outgoing mail, as nodemailer's mime-node writes them: domains in IDNA form (or UTF-8 when the local
//! part needs SMTPUTF8 anyway), local parts that are not a dot-atom quoted, and display names encoded.

use pe_mime::Address;
use pe_mime::parser::ParsedAddress;

use crate::encoding::{encode_address_name, quote_string};

/// RFC 5321 atext plus the non-ASCII characters SMTPUTF8 (RFC 6531) allows
fn is_atext(c: char) -> bool {
    c.is_ascii_alphanumeric() || "!#$%&'*+-/=?^_`{|}~".contains(c) || !c.is_ascii()
}

fn is_dot_atom(text: &str) -> bool {
    !text.is_empty()
        && text
            .split('.')
            .all(|part| !part.is_empty() && part.chars().all(is_atext))
}

fn is_quoted_string(text: &str) -> bool {
    let Some(inner) = text.strip_prefix('"').and_then(|t| t.strip_suffix('"')) else {
        return false;
    };
    if text.len() < 2 {
        return false;
    }
    let mut chars = inner.chars();
    while let Some(c) = chars.next() {
        match c {
            '\\' if chars.next().is_none() => return false,
            '\\' => {}
            '"' => return false,
            _ => {}
        }
    }
    true
}

/// An address that can stand in a header without angle brackets
fn is_plain_address(address: &str) -> bool {
    let special = |c: char| c.is_whitespace() || "\"(),:;<>@[\\]".contains(c);
    match address.split_once('@') {
        Some((user, domain)) => {
            !user.is_empty() && !domain.is_empty() && !user.contains(special) && !domain.contains(special)
        }
        None => false,
    }
}

/// The domain in IDNA form, or as Unicode when the address needs SMTPUTF8; lowercased as written when it is no
/// domain. The mapper gets the domain as supplied, as UTS-46 does its own case mapping and `to_lowercase` differs
/// from it for some characters (nodemailer 093e4dd, GHSA-2g53-87p2-4qq8).
fn normalize_domain(domain: &str, unicode: bool) -> String {
    let lower = domain.to_lowercase();
    match idna::domain_to_ascii(domain) {
        Ok(ascii) if !ascii.is_empty() => {
            if unicode {
                let (decoded, result) = idna::domain_to_unicode(&ascii);
                if result.is_ok() { decoded } else { ascii }
            } else {
                ascii
            }
        }
        _ => lower,
    }
}

/// An address cleaned for a header and the envelope: control characters and angle brackets out, the domain
/// normalized, a local part that is no dot-atom quoted
pub fn normalize_address(address: &str) -> String {
    let mut cleaned = String::with_capacity(address.len());
    let mut in_run = false;
    for c in address.chars() {
        if c.is_ascii_control() || c == '<' || c == '>' {
            if !in_run {
                cleaned.push(' ');
            }
            in_run = true;
        } else {
            cleaned.push(c);
            in_run = false;
        }
    }
    let address = cleaned.trim();
    if address.is_empty() {
        return String::new();
    }
    // a domain literal can hold an '@' of its own: the split is at the '@' before it
    let literal = address
        .strip_suffix(']')
        .and_then(|_| address.rfind("@["))
        .filter(|at| !address[at + 2..address.len() - 1].contains(['[', ']', '\\']));
    let Some(at) = literal.or_else(|| address.rfind('@')) else {
        return normalize_local_part(address);
    };
    let (user, domain) = (&address[..at], &address[at + 1..]);
    let unicode = !user.is_ascii();
    let domain = if domain.starts_with('[') {
        domain.to_string()
    } else {
        normalize_domain(domain, unicode)
    };
    format!("{}@{domain}", normalize_local_part(user))
}

fn normalize_local_part(user: &str) -> String {
    if is_dot_atom(user) || is_quoted_string(user) {
        user.to_string()
    } else {
        quote_string(user)
    }
}

/// One address for a header: `Name <address>`, the address alone when there is no name
pub fn format_mailbox(address: &Address) -> String {
    let normalized = normalize_address(&address.address);
    if address.name.is_empty() {
        if is_plain_address(&normalized) {
            normalized
        } else {
            format!("<{normalized}>")
        }
    } else {
        format!("{} <{normalized}>", encode_address_name(&address.name))
    }
}

/// An address list for a header, groups as `Name:member, member;`
pub fn format_addresses(list: &[ParsedAddress]) -> String {
    let items: Vec<String> = list
        .iter()
        .filter_map(|address| match address {
            ParsedAddress::Mailbox(mailbox) if mailbox.address.trim().is_empty() => None,
            ParsedAddress::Mailbox(mailbox) => Some(format_mailbox(mailbox)),
            ParsedAddress::Group { name, members } => {
                let members: Vec<String> = members
                    .iter()
                    .filter(|m| !m.address.trim().is_empty())
                    .map(format_mailbox)
                    .collect();
                Some(format!("{}:{};", encode_address_name(name), members.join(", ")))
            }
        })
        .collect();
    items.join(", ")
}

/// The addresses the envelope takes from header lists: each once, in order, groups opened up
pub fn envelope_addresses<'a>(lists: impl IntoIterator<Item = &'a [ParsedAddress]>) -> Vec<String> {
    let mut seen = std::collections::HashSet::new();
    let mut out = Vec::new();
    for list in lists {
        for address in list.iter().flat_map(ParsedAddress::mailboxes) {
            let normalized = normalize_address(&address.address);
            if !normalized.is_empty() && seen.insert(normalized.clone()) {
                out.push(normalized);
            }
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn mailbox(name: &str, address: &str) -> Address {
        Address {
            name: name.into(),
            address: address.into(),
        }
    }

    #[test]
    fn addresses() {
        assert_eq!(normalize_address("Info@Jõgeva.EE"), "Info@xn--jgeva-dua.ee");
        assert_eq!(normalize_address("üser@Jõgeva.ee"), "üser@jõgeva.ee");
        assert_eq!(normalize_address("a b@example.com"), "\"a b\"@example.com");
        assert_eq!(normalize_address("x@[1.2.3.4]"), "x@[1.2.3.4]");
        assert_eq!(normalize_address("<a@b.c>\r\n"), "a@b.c");
        assert_eq!(format_mailbox(&mailbox("", "a b@example.com")), "<\"a b\"@example.com>");
        assert_eq!(format_mailbox(&mailbox("A, B", "a@b.c")), "\"A, B\" <a@b.c>");
    }

    #[test]
    fn envelope_is_unique() {
        let to = vec![
            ParsedAddress::Mailbox(mailbox("", "a@b.c")),
            ParsedAddress::Mailbox(mailbox("", "A@b.c")),
        ];
        let cc = vec![ParsedAddress::Group {
            name: "G".into(),
            members: vec![mailbox("", "a@b.c"), mailbox("", "d@e.f")],
        }];
        assert_eq!(
            envelope_addresses([to.as_slice(), cc.as_slice()]),
            ["a@b.c", "A@b.c", "d@e.f"]
        );
    }
}
