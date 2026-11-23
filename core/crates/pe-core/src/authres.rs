//! Whose word counts in a message's headers: the verdict of the account's own provider (Authentication-Results, RFC
//! 8601). Anyone can write such a header into a message; what a sender can not do is write above the server that
//! receives it, which puts its verdict on top of everything the sender wrote. So only the newest verdict counts: the
//! topmost Authentication-Results, which must carry a name the account trusts ([`Verifiers`]: the provider table
//! below, or the account's own "Trust sender checks from"). When it names anyone else, the message has no verdict;
//! nothing further down is looked at, as a sender's own can follow the provider's directly (Gmail's is the last header
//! Gmail writes). Some providers (iCloud, Fastmail, Proton) write one header a check, with other fields between them,
//! and remove those senders write: their block goes on through those and ends at the next Received or
//! DKIM-Signature, or at a verdict in another name. A check the block gives twice is taken from its newest header.
//!
//! Zoho places its Authentication-Results after the last Received line, among the headers the sender wrote, so its
//! verdict is read from the ARC set (RFC 8617) it puts at the very top: the ARC-Authentication-Results of the highest
//! instance, the only one of it, above every Received and Authentication-Results, sealed (ARC-Seal `d=`) in a Zoho
//! domain. Its signature is not checked: its place is what makes it Zoho's, as for the block above.
//!
//! Microsoft renames the verdicts senders write (Authentication-Results-Original) and names its own
//! `mx.microsoft.com`; its older mail has a verdict with no name at all, which counts on Microsoft's accounts only.
//!
//! Domains are compared by their organizational domain on the Public Suffix List, as DMARC's relaxed alignment and
//! mailauth (`getAlignment`) do: `header.from=shop.com` confirms mail from `news.shop.com`, `evil.me.uk` vouches
//! for nobody at `shop.me.uk`.

use pe_mime::parser::Header;
use pe_store::{AccountId, AccountSettings, Store};

/// A domain in lower case, without a trailing dot or the angle brackets and user of an address (`<a@shop.com>`)
fn domain_of(value: &str) -> String {
    let value = value.trim().trim_start_matches('<').trim_end_matches('>');
    let host = value.rsplit('@').next().unwrap_or_default();
    host.trim().trim_end_matches('.').to_ascii_lowercase()
}

/// The organizational domain of `domain`: the part its owner registered under a public suffix (`mail.shop.co.uk` to
/// `shop.co.uk`); a public suffix or a name without one stays as it is
pub(crate) fn organizational(domain: &str) -> String {
    let domain = domain_of(domain);
    match psl::domain_str(&domain) {
        Some(org) => org.to_string(),
        None => domain,
    }
}

/// Whether two domains are aligned: the same organizational domain (DMARC's relaxed alignment)
pub(crate) fn aligned(a: &str, b: &str) -> bool {
    let (a, b) = (domain_of(a), domain_of(b));
    a.contains('.') && b.contains('.') && organizational(&a) == organizational(&b)
}

/// Whether `host` is `name` or a host under it (`mx.example.com` under `example.com`)
pub(crate) fn under(host: &str, name: &str) -> bool {
    !name.is_empty()
        && host
            .strip_suffix(name)
            .is_some_and(|rest| rest.is_empty() || rest.ends_with('.'))
}

/// How a provider's verdict is found
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
enum Rule {
    #[default]
    /// The top block, in one of its names
    Named,
    /// The top block, in its names or none (Microsoft's older mail)
    Nameless,
    /// The top block of one header a check (iCloud, Fastmail, Proton), which removes those senders write
    PerCheck,
    /// Its own ARC set on top, sealed in one of these domains (Zoho)
    Arc(&'static [&'static str]),
}

/// A provider: the domains its accounts' IMAP servers or addresses are under, the names its verdicts carry (a name
/// covers the hosts under it; `*` is any name, for a provider that names its servers by number and removes the
/// verdicts senders write), and where its verdict is
struct Provider {
    hosts: &'static [&'static str],
    names: &'static [&'static str],
    rule: Rule,
}

const fn named(hosts: &'static [&'static str], names: &'static [&'static str]) -> Provider {
    Provider {
        hosts,
        names,
        rule: Rule::Named,
    }
}

const fn per_check(hosts: &'static [&'static str], names: &'static [&'static str]) -> Provider {
    Provider {
        hosts,
        names,
        rule: Rule::PerCheck,
    }
}

const fn zoho(hosts: &'static [&'static str], seals: &'static [&'static str]) -> Provider {
    Provider {
        hosts,
        names: hosts,
        rule: Rule::Arc(seals),
    }
}

/// The providers whose verdicts carry other names than their accounts' domains. Seen in their mail on 23 November
/// 2026, but for Zoho's regions other than the EU, which follow Zoho's documentation, and AOL, Yandex and Lark.
const PROVIDERS: &[Provider] = &[
    named(&["gmail.com", "googlemail.com"], &["mx.google.com"]),
    Provider {
        hosts: &["outlook.com", "hotmail.com", "live.com", "msn.com", "office365.com"],
        names: &["microsoft.com"],
        rule: Rule::Nameless,
    },
    per_check(&["icloud.com", "me.com", "mac.com"], &["icloud.com"]),
    named(
        &["yahoo.com", "ymail.com", "rocketmail.com", "aol.com"],
        &["yahoo.com", "aol.com"],
    ),
    per_check(
        &["fastmail.com", "fastmail.fm", "messagingengine.com"],
        &["messagingengine.com"],
    ),
    per_check(
        &["proton.me", "protonmail.com", "protonmail.ch", "pm.me"],
        &["protonmail.ch"],
    ),
    named(&["gmx.net", "gmx.com", "gmx.de", "web.de"], &["gmx.net", "web.de"]),
    named(&["zone.eu", "zone.ee"], &["zonemx.eu"]),
    named(&["163.com", "126.com", "yeah.net"], &["*"]),
    named(&["larksuite.com"], &["lms"]),
    named(
        &["yandex.ru", "yandex.com", "ya.ru"],
        &["yandex.ru", "yandex.net", "yandex.com"],
    ),
    zoho(
        &["zoho.com", "zohomail.com"],
        &["zoho.com", "zohomail.com", "zohomail360.com"],
    ),
    zoho(
        &["zoho.eu", "zohomail.eu"],
        &["zoho.eu", "zohomail.eu", "zohomail360.eu"],
    ),
    zoho(
        &["zoho.in", "zohomail.in"],
        &["zoho.in", "zohomail.in", "zohomail360.in"],
    ),
    zoho(
        &["zoho.com.au", "zohomail.com.au"],
        &["zoho.com.au", "zohomail.com.au", "zohomail360.com.au"],
    ),
    zoho(
        &["zoho.jp", "zohomail.jp"],
        &["zoho.jp", "zohomail.jp", "zohomail360.jp"],
    ),
    zoho(&["zohocloud.ca"], &["zohocloud.ca"]),
    zoho(&["zoho.sa"], &["zoho.sa"]),
    zoho(&["zoho.uk"], &["zoho.uk"]),
    zoho(&["zoho.com.cn"], &["zoho.com.cn"]),
];

/// The organizational domains of an account's IMAP server and address, the server first; an address in place of a
/// name (Proton's Bridge on 127.0.0.1) gives none
fn account_domains(settings: &AccountSettings) -> Vec<String> {
    let host = settings.imap_host.trim();
    let mut domains = Vec::new();
    if host.parse::<std::net::IpAddr>().is_err() {
        domains.push(organizational(host));
    }
    domains.push(organizational(settings.email.rsplit('@').next().unwrap_or_default()));
    domains.retain(|d| d.contains('.'));
    domains.dedup();
    domains
}

fn provider(domains: &[String]) -> Option<&'static Provider> {
    domains
        .iter()
        .find_map(|domain| PROVIDERS.iter().find(|p| p.hosts.contains(&domain.as_str())))
}

/// Whose verdicts an account believes: the names their authserv-id may carry, and the provider's way of placing them
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Verifiers {
    names: Vec<String>,
    /// Where the provider puts its verdict
    rule: Rule,
}

impl Verifiers {
    /// An account's, from the provider table or its domains, its own names (`custom`, as the user wrote them) in
    /// place of those when it has some
    pub fn of(settings: &AccountSettings, custom: Option<&str>) -> Verifiers {
        let domains = account_domains(settings);
        let found = provider(&domains);
        let names = custom
            .map(parse_names)
            .filter(|names| !names.is_empty())
            .unwrap_or_else(|| defaults_of(found, domains));
        Verifiers {
            names,
            rule: found.map(|p| p.rule).unwrap_or_default(),
        }
    }

    /// Verifiers by name only
    #[cfg(test)]
    pub(crate) fn named(names: &[&str]) -> Verifiers {
        Verifiers {
            names: names.iter().map(|n| n.to_string()).collect(),
            ..Default::default()
        }
    }

    /// The verifiers of an account at `email` whose IMAP server is `imap_host`
    #[cfg(test)]
    pub(crate) fn of_host(email: &str, imap_host: &str) -> Verifiers {
        Verifiers::of(&tests::account(email, imap_host), None)
    }

    /// The names, as the account's field shows them
    pub fn text(&self) -> String {
        self.names.join(", ")
    }

    /// Whether a verdict of the authserv-id `id` (None: a verdict without one) is the provider's
    fn trusts(&self, id: Option<&str>) -> bool {
        let Some(id) = id else {
            return self.rule == Rule::Nameless;
        };
        let id = id.to_ascii_lowercase();
        self.names.iter().any(|name| name == "*" || under(&id, name))
    }
}

/// No one's verdicts: what a borrowed [`Verifiers`] defaults to
pub static NONE: Verifiers = Verifiers {
    names: Vec::new(),
    rule: Rule::Named,
};

impl Default for &Verifiers {
    fn default() -> Self {
        &NONE
    }
}

/// The names an account trusts unless it says otherwise: its provider's, else the organizational domains of its
/// IMAP server and its address
pub fn defaults(settings: &AccountSettings) -> Vec<String> {
    let domains = account_domains(settings);
    defaults_of(provider(&domains), domains)
}

fn defaults_of(found: Option<&Provider>, domains: Vec<String>) -> Vec<String> {
    match found {
        Some(found) => found.names.iter().map(|n| n.to_string()).collect(),
        None => domains,
    }
}

/// The names in what the user wrote: separated by commas, semicolons or white space, in lower case, without a
/// trailing dot; what is no host name (or `*`) is left out
pub fn parse_names(text: &str) -> Vec<String> {
    let mut names: Vec<String> = Vec::new();
    for word in text.split([',', ';', ' ', '\t', '\r', '\n']) {
        let name = match word.trim() {
            "*" => Some("*".to_string()),
            word => pe_autoconfig::dns::host_name(word),
        };
        if let Some(name) = name.filter(|name| !names.contains(name)) {
            names.push(name);
        }
    }
    names
}

/// The verifiers of `account` in `store`
pub(crate) fn verifiers(store: &Store, account: AccountId) -> pe_store::Result<Verifiers> {
    let custom = store.verifiers(account)?;
    Ok(Verifiers::of(&store.account(account)?.settings, custom.as_deref()))
}

/// The headers named `key`, in the order they come (the newest first)
pub(crate) fn headers<'a>(headers: &'a [Header], key: &'a str) -> impl Iterator<Item = &'a str> {
    headers
        .iter()
        .filter(move |h| h.key.eq_ignore_ascii_case(key))
        .map(|h| h.value.as_str())
}

/// The value of a tag (`d=`) in a tag list (DKIM-Signature, BIMI-Location, ARC-Seal)
pub(crate) fn tag<'a>(value: &'a str, name: &str) -> Option<&'a str> {
    value
        .split([';', ' ', '\t', '\r', '\n'])
        .filter_map(|part| part.split_once('='))
        .find(|(key, _)| key.trim().eq_ignore_ascii_case(name))
        .map(|(_, value)| value.trim().trim_matches('"'))
}

/// One result of a verdict: `dkim=pass header.d=shop.com`
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Outcome {
    pub method: String,
    pub result: String,
    /// `header.d`, `policy.authority` and the like, the keys in lower case
    props: Vec<(String, String)>,
}

impl Outcome {
    pub fn prop(&self, key: &str) -> Option<&str> {
        self.props
            .iter()
            .find(|(k, _)| k.eq_ignore_ascii_case(key))
            .map(|(_, v)| v.as_str())
    }

    /// The domain a property names (`header.from=shop.com`, `header.i=@shop.com`), None for none or an empty one
    pub fn domain(&self, key: &str) -> Option<String> {
        self.prop(key).map(domain_of).filter(|d| !d.is_empty())
    }

    pub fn passed(&self, method: &str) -> bool {
        self.method.eq_ignore_ascii_case(method) && self.result.eq_ignore_ascii_case("pass")
    }
}

/// The parts of an Authentication-Results value: split at `;` outside comments (which nest) and quoted strings, each
/// comment turned into a space, as mailauth's `arParser` reads them
fn parts(value: &str) -> Vec<String> {
    let mut parts = vec![String::new()];
    let (mut depth, mut quoted) = (0usize, false);
    let mut chars = value.chars();
    while let Some(c) = chars.next() {
        let part = parts.last_mut().expect("one part at least");
        match c {
            '\\' if quoted || depth > 0 => {
                let next = chars.next();
                if depth == 0 {
                    part.push('\\');
                    part.extend(next);
                }
            }
            '"' if depth == 0 => {
                quoted = !quoted;
                part.push(c);
            }
            _ if quoted => part.push(c),
            '(' => {
                if depth == 0 {
                    part.push(' ');
                }
                depth += 1;
            }
            ')' if depth > 0 => depth -= 1,
            _ if depth > 0 => {}
            ';' => parts.push(String::new()),
            _ => part.push(c),
        }
    }
    parts
}

/// The words of a part: split at white space outside quoted strings, the quotes taken off and quoted pairs read
fn words(part: &str) -> Vec<String> {
    let mut words = Vec::new();
    let (mut word, mut quoted, mut started) = (String::new(), false, false);
    let mut chars = part.chars();
    while let Some(c) = chars.next() {
        match c {
            '"' => {
                quoted = !quoted;
                started = true;
            }
            '\\' if quoted => word.extend(chars.next()),
            c if c.is_whitespace() && !quoted => {
                if started {
                    words.push(std::mem::take(&mut word));
                    started = false;
                }
            }
            c => {
                word.push(c);
                started = true;
            }
        }
    }
    if started {
        words.push(word);
    }
    words
}

/// One part as a result: `method=result` and its properties; None for what is none (`none`, an empty part)
fn outcome(part: &str) -> Option<Outcome> {
    let words = words(part);
    let (first, rest) = words.split_first()?;
    let (method, result) = first.split_once('=')?;
    // `dkim/1=pass`: the version is no part of the method
    let method = method.split('/').next().unwrap_or_default().trim().to_ascii_lowercase();
    if method.is_empty() {
        return None;
    }
    let props = rest
        .iter()
        .filter_map(|word| word.split_once('='))
        .filter(|(key, _)| key.contains('.'))
        .map(|(key, value)| (key.to_ascii_lowercase(), value.to_string()))
        .collect();
    Some(Outcome {
        method,
        result: result.trim().to_ascii_lowercase(),
        props,
    })
}

/// An Authentication-Results value as its authserv-id (None when it names none, as Microsoft's older ones) and its
/// results
pub(crate) fn parse(value: &str) -> (Option<String>, Vec<Outcome>) {
    let parts = parts(value);
    let first = parts.first().map(|p| p.trim()).unwrap_or_default();
    let (id, results) = if first.contains('=') {
        (None, &parts[..])
    } else {
        let id = first.split_whitespace().next().map(str::to_ascii_lowercase);
        (id, &parts[1.min(parts.len())..])
    };
    (id, results.iter().filter_map(|p| outcome(p)).collect())
}

fn is(header: &Header, key: &str) -> bool {
    header.key.eq_ignore_ascii_case(key)
}

/// The provider's verdict on a message
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Verdict {
    pub results: Vec<Outcome>,
    /// The place of the first header after the provider's: what is above it, the provider wrote
    end: usize,
}

impl Verdict {
    /// The verdict of the provider `verifiers` describe, None when the message has none of its
    pub fn of(all: &[Header], verifiers: &Verifiers) -> Option<Verdict> {
        match verifiers.rule {
            Rule::Arc(seals) => arc_set(all, verifiers, seals),
            Rule::Named | Rule::Nameless | Rule::PerCheck => top_block(all, verifiers),
        }
    }

    /// The results that passed for `method`
    pub fn passed<'a>(&'a self, method: &'a str) -> impl Iterator<Item = &'a Outcome> {
        self.results.iter().filter(move |r| r.passed(method))
    }

    /// The domains of the DKIM signatures that passed: `header.d`, else the domain of `header.i` (Gmail, Yahoo and
    /// GMX give only that)
    pub fn signers(&self) -> Vec<String> {
        self.passed("dkim")
            .filter_map(|r| r.domain("header.d").or_else(|| r.domain("header.i")))
            .collect()
    }

    fn dmarc_aligned(&self, from_domain: &str) -> bool {
        self.passed("dmarc")
            .any(|r| r.domain("header.from").is_some_and(|d| aligned(&d, from_domain)))
    }

    /// Whether the provider confirms `from_domain` sent the message: DMARC passed for it, or DKIM for a signature
    /// aligned with it
    pub fn confirms(&self, from_domain: &str) -> bool {
        self.dmarc_aligned(from_domain) || self.signers().iter().any(|d| aligned(d, from_domain))
    }

    /// Whether the provider passed the brand's logo of `from_domain`: BIMI passed for it, DMARC passed aligned with
    /// it, and the mark is certified where the provider says (`policy.authority`)
    pub fn logo(&self, from_domain: &str) -> bool {
        let bimi = self.passed("bimi").any(|r| {
            r.domain("header.d").is_none_or(|d| aligned(&d, from_domain))
                && r.prop("policy.authority")
                    .is_none_or(|a| a.eq_ignore_ascii_case("pass"))
        });
        bimi && self.dmarc_aligned(from_domain)
    }

    /// The headers named `key` that the provider wrote: those above the end of its verdict
    pub fn provider_headers<'a>(&self, all: &'a [Header], key: &'a str) -> impl Iterator<Item = &'a str> {
        headers(&all[..self.end.min(all.len())], key)
    }
}

/// The provider's verdict on top: the first Authentication-Results from the top, when it is in a trusted name, up to
/// the next Received, DKIM-Signature or verdict in another name (its end: what the provider wrote, as its BIMI
/// headers, is above it). Only that header's results, as a sender's own can follow it directly (Gmail's is the last
/// header Gmail writes) and would add checks the provider left out; but for a provider of one header a check, also
/// those of the trusted ones after it, a check given twice taken from the newest.
fn top_block(all: &[Header], verifiers: &Verifiers) -> Option<Verdict> {
    let start = all.iter().position(|h| is(h, "authentication-results"))?;
    let (id, mut results) = parse(&all[start].value);
    if !verifiers.trusts(id.as_deref()) {
        return None;
    }
    let mut end = all.len();
    for (at, header) in all.iter().enumerate().skip(start + 1) {
        if is(header, "received") || is(header, "dkim-signature") {
            end = at;
            break;
        }
        if !is(header, "authentication-results") {
            continue;
        }
        let (id, found) = parse(&header.value);
        if !verifiers.trusts(id.as_deref()) {
            end = at;
            break;
        }
        if verifiers.rule == Rule::PerCheck {
            let seen: Vec<String> = results.iter().map(|r| r.method.clone()).collect();
            results.extend(found.into_iter().filter(|r| !seen.contains(&r.method)));
        }
    }
    Some(Verdict { results, end })
}

/// The instance (`i=`) of an ARC header's value, its first tag: 1 to 50 (RFC 8617 4.2.1), None for any other
fn instance(value: &str) -> Option<u32> {
    let (first, _) = value.split_once(';')?;
    let (name, number) = first.split_once('=')?;
    let number: u32 = (name.trim().eq_ignore_ascii_case("i")).then(|| number.trim().parse().ok())??;
    (1..=50).contains(&number).then_some(number)
}

/// The provider's own ARC set (Zoho's): of the highest instance and the only one of it, above every Received and
/// Authentication-Results, sealed in a domain of the provider's and in a trusted name
fn arc_set(all: &[Header], verifiers: &Verifiers, seals: &[&str]) -> Option<Verdict> {
    let limit = all
        .iter()
        .position(|h| is(h, "received") || is(h, "authentication-results"))
        .unwrap_or(all.len());
    let sets: Vec<(usize, u32, &str)> = all
        .iter()
        .enumerate()
        .filter(|(_, h)| is(h, "arc-authentication-results"))
        .filter_map(|(at, h)| Some((at, instance(&h.value)?, h.value.as_str())))
        .collect();
    let top = sets.iter().map(|(_, i, _)| *i).max()?;
    let [(at, _, value)] = sets.iter().filter(|(_, i, _)| *i == top).collect::<Vec<_>>()[..] else {
        return None;
    };
    let sealed = all[..limit]
        .iter()
        .filter(|h| is(h, "arc-seal") && instance(&h.value) == Some(top))
        .any(|h| tag(&h.value, "d").is_some_and(|d| seals.iter().any(|seal| under(&domain_of(d), seal))));
    if *at >= limit || !sealed {
        return None;
    }
    let (_, rest) = value.split_once(';')?;
    let (id, results) = parse(rest);
    verifiers
        .trusts(id.as_deref())
        .then_some(Verdict { results, end: limit })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn parse_headers(text: &str) -> Vec<Header> {
        pe_mime::parser::parse(format!("{text}\r\nSubject: x\r\n\r\nx\r\n").as_bytes())
            .unwrap()
            .headers
    }

    pub(crate) fn account(email: &str, imap_host: &str) -> AccountSettings {
        AccountSettings {
            name: "Ann".into(),
            email: email.into(),
            username: email.into(),
            imap_host: imap_host.into(),
            imap_port: 993,
            imap_security: pe_store::Security::Tls,
            smtp_host: String::new(),
            smtp_port: 465,
            smtp_security: pe_store::Security::Tls,
            auth: pe_store::Auth::Password,
        }
    }

    fn verdict(text: &str, verifiers: &Verifiers) -> Option<Verdict> {
        Verdict::of(&parse_headers(text), verifiers)
    }

    #[test]
    fn organizational_domains_come_from_the_public_suffix_list() {
        assert_eq!(organizational("mx.example.com"), "example.com");
        assert_eq!(organizational("mail.example.co.uk"), "example.co.uk");
        assert_eq!(organizational("<News@Con.Shop.COM>"), "shop.com");
        assert!(aligned("con.shop.com", "shop.com"));
        assert!(aligned("news.shop.com", "mail.shop.com"));
        // a public suffix between them: two owners
        assert!(!aligned("evil.me.uk", "shop.me.uk"));
        assert!(!aligned("shop.github.io", "evil.github.io"));
        assert!(!aligned("lms", "lms"), "a name without a dot aligns with nothing");
        // a top-level domain not on the list (the tests' .test) keeps its last two labels
        assert_eq!(organizational("mx.inboxclassic.test"), "inboxclassic.test");
    }

    #[test]
    fn the_parser_reads_comments_quotes_and_what_providers_write() {
        // OpenDKIM: a semicolon inside a comment
        let (id, found) =
            parse("uvn-79-113.tll01.zonevs.eu; dkim=pass (2048-bit key; unprotected) header.d=shop.com header.s=s1");
        assert_eq!(id.as_deref(), Some("uvn-79-113.tll01.zonevs.eu"));
        assert_eq!(found.len(), 1);
        assert_eq!(found[0].domain("header.d").as_deref(), Some("shop.com"));
        // Yahoo and Zoho: a comment right after the result
        let (_, found) = parse("mta.yahoo.com; dmarc=pass(p=REJECT) header.from=shop.com arc_overridden_status=NOT;");
        assert!(found[0].passed("dmarc"));
        assert_eq!(found[0].prop("header.from"), Some("shop.com"));
        // Microsoft: a version after the name, no space after a semicolon
        let (id, found) = parse(
            "mx.microsoft.com 1; spf=pass (sender IP is 192.0.2.1) smtp.mailfrom=shop.com; dkim=pass (signature was \
             verified) header.d=shop.com;dmarc=pass action=none header.from=shop.com;compauth=pass reason=100",
        );
        assert_eq!(id.as_deref(), Some("mx.microsoft.com"));
        let methods: Vec<&str> = found.iter().map(|r| r.method.as_str()).collect();
        assert_eq!(methods, ["spf", "dkim", "dmarc", "compauth"]);
        // a nameless verdict, quoted values, an address in angle brackets, nested comments and `none`
        let (id, found) = parse(
            "spf=pass smtp.mailfrom=shop.com; bimi=skipped reason=\"missing; evidence\" header.d=\"shop.com\"; \
             dmarc=pass (a (nested; one)) header.from=<ann@Shop.com>; none",
        );
        assert_eq!(id, None);
        assert_eq!(found.len(), 3);
        assert_eq!(found[1].domain("header.d").as_deref(), Some("shop.com"));
        assert_eq!(found[2].domain("header.from").as_deref(), Some("shop.com"));
        assert_eq!(parse("example.org 1; none"), (Some("example.org".into()), vec![]));
    }

    /// Gmail: one header on top, DKIM's domain only as header.i, header.from the organizational domain (sonos.eml)
    #[test]
    fn gmail_confirms_a_sender_under_its_organizational_domain() {
        let gmail = Verifiers::of(&account("ann@gmail.com", "imap.gmail.com"), None);
        assert_eq!(gmail.text(), "mx.google.com");
        let found = verdict(
            "ARC-Authentication-Results: i=1; mx.google.com; dkim=pass header.i=@con.shop.com\r\n\
             Authentication-Results: mx.google.com; dkim=pass header.i=@con.shop.com header.s=s1 header.b=x; \
             spf=pass (google.com: domain of b@con.shop.com) smtp.mailfrom=\"b@con.shop.com\"; \
             dmarc=pass (p=REJECT sp=REJECT dis=NONE) header.from=shop.com\r\n\
             Received: from mail.shop.com by mx.google.com",
            &gmail,
        )
        .unwrap();
        assert!(found.confirms("con.shop.com"));
        assert_eq!(found.signers(), ["con.shop.com"]);
        assert!(!found.confirms("other.com"));
    }

    #[test]
    fn only_the_newest_block_counts() {
        let verifiers = Verifiers::named(&["mx.provider.example"]);
        // a verdict in another name on top: none, though the provider's name is further down
        assert_eq!(
            verdict(
                "Authentication-Results: forged.example; dmarc=pass header.from=bank.example\r\n\
                 Authentication-Results: mx.provider.example; dmarc=fail header.from=bank.example",
                &verifiers
            ),
            None
        );
        // Stalwart keeps a forged verdict in its own name below the trace lines: outside the block
        let found = verdict(
            "Received: from mail.example by mx.provider.example\r\n\
             Authentication-Results: mx.provider.example; dkim=pass header.d=shop.com\r\n\
             Received-SPF: pass\r\n\
             X-Spam-Status: No\r\n\
             Received: by mail.example\r\n\
             DKIM-Signature: v=1; d=shop.com; s=s1; b=x\r\n\
             Authentication-Results: mx.provider.example; dkim=pass header.d=bank.example; dmarc=pass header.from=bank.example",
            &verifiers,
        )
        .unwrap();
        assert!(found.confirms("shop.com"));
        assert!(!found.confirms("bank.example"));
        // a sender's own right under the provider's, as under Gmail's (the last header Gmail writes): it adds no check
        // the provider left out, and its logo headers are not the provider's
        let gmail = Verifiers::of_host("ann@gmail.com", "imap.gmail.com");
        let added = verdict(
            "Received: from mta.paypa1-alerts.com by mx.google.com\r\n\
             Received-SPF: pass\r\n\
             Authentication-Results: mx.google.com; spf=pass smtp.mailfrom=paypa1-alerts.com; \
             dmarc=pass header.from=paypa1-alerts.com\r\n\
             Authentication-Results: mx.google.com; dkim=pass header.d=bank.example; \
             bimi=pass header.d=paypa1-alerts.com policy.authority=pass\r\n\
             BIMI-Location: v=BIMI1; l=https://paypa1-alerts.com/paypal.svg\r\n\
             From: PayPal <service@paypa1-alerts.com>",
            &gmail,
        )
        .unwrap();
        assert!(!added.confirms("bank.example"));
        assert!(!added.logo("paypa1-alerts.com"));
        // no verdict at all
        assert_eq!(verdict("X-Other: 1", &verifiers), None);
    }

    /// iCloud: one header a check, below its own Received lines, other fields between them
    #[test]
    fn icloud_writes_one_header_a_check() {
        let icloud = Verifiers::of(&account("ann@icloud.com", "imap.mail.me.com"), None);
        let found = verdict(
            "Received: from p00-icloudmta by p196-mailgateway\r\n\
             Received: from mail.shop.com by p00-icloudmta-smtpin\r\n\
             X-ICL-Score: 2.3\r\n\
             Authentication-Results: bimi.icloud.com; bimi=skipped reason=\"missing evidence\"\r\n\
             X-ARC-Info: policy=fail; arc=none\r\n\
             Authentication-Results: arc.icloud.com; arc=none\r\n\
             Authentication-Results: dmarc.icloud.com; dmarc=pass header.from=shop.com\r\n\
             X-DMARC-Policy: v=DMARC1; p=reject;\r\n\
             Authentication-Results: dkim-verifier.icloud.com; dkim=pass header.d=shop.com header.i=@shop.com\r\n\
             Received-SPF: pass (spf.icloud.com: domain of a@shop.com)\r\n\
             Authentication-Results: spf.icloud.com; spf=pass smtp.mailfrom=a@shop.com\r\n\
             Received: by mail.shop.com\r\n\
             Authentication-Results: dmarc.icloud.com; dmarc=pass header.from=bank.example",
            &icloud,
        )
        .unwrap();
        assert_eq!(found.results.len(), 5);
        assert!(found.confirms("shop.com"));
        assert!(!found.confirms("bank.example"));
    }

    /// Microsoft: its own name on top, the sender's renamed; its older mail names no one, which counts there only
    #[test]
    fn microsoft_names_itself_or_no_one() {
        let outlook = Verifiers::of(&account("ann@outlook.com", "outlook.office365.com"), None);
        let named = "Received: from x by y.prod.outlook.com\r\n\
             Authentication-Results: mx.microsoft.com 1; dkim=pass header.d=shop.com;dmarc=pass action=none header.from=shop.com\r\n\
             Received: from mail.shop.com by y.mail.protection.outlook.com\r\n\
             Authentication-Results-Original: mx.microsoft.com 1; dmarc=pass header.from=bank.example";
        let found = verdict(named, &outlook).unwrap();
        assert!(found.confirms("shop.com") && !found.confirms("bank.example"));
        let nameless = "Authentication-Results: spf=pass (sender IP is 192.0.2.1) smtp.mailfrom=shop.com; dkim=pass \
             header.d=shop.com;dmarc=pass action=none header.from=shop.com;";
        assert!(verdict(nameless, &outlook).unwrap().confirms("shop.com"));
        let elsewhere = Verifiers::named(&["mx.provider.example"]);
        assert_eq!(
            verdict(nameless, &elsewhere),
            None,
            "nameless counts on Microsoft's accounts only"
        );
    }

    /// Zoho: the verdict of its ARC set on top; its Authentication-Results among the sender's headers is not read
    #[test]
    fn zoho_is_read_from_its_own_arc_set() {
        let zoho = Verifiers::of(&account("ann@shop.example", "imap.zoho.eu"), None);
        assert_eq!(zoho.text(), "zoho.eu, zohomail.eu");
        let set = "ARC-Seal: i=1; a=rsa-sha256; t=1; cv=none; d=zohomail.eu; s=zohoarc; b=x\r\n\
             ARC-Message-Signature: i=1; a=rsa-sha256; d=zohomail.eu; s=zohoarc; b=y\r\n\
             ARC-Authentication-Results: i=1; mx.zohomail.eu; dkim=pass; spf=pass smtp.mailfrom=a@shop.com; \
             dmarc=pass header.from=<a@shop.com> (p=reject dis=none)\r\n";
        let trace = "Received: from mail.shop.com by mx.zoho.eu\r\n\
             Received: by mail.shop.com\r\n\
             Authentication-Results: mx.zohomail.eu; dkim=pass; dmarc=pass(p=reject dis=none) header.from=shop.com\r\n\
             DKIM-Signature: v=1; d=shop.com; s=s1; b=x\r\n\
             Authentication-Results: mx.zohomail.eu; dkim=pass header.d=bank.example; dmarc=pass header.from=bank.example";
        let found = verdict(&format!("{set}{trace}"), &zoho).unwrap();
        assert!(found.confirms("shop.com") && !found.confirms("bank.example"));
        // without its set, or with the set below the trace lines, or sealed in another name: no verdict
        assert_eq!(verdict(trace, &zoho), None);
        assert_eq!(verdict(&format!("{trace}\r\n{}", set.trim_end()), &zoho), None);
        assert_eq!(
            verdict(
                &set.replace("d=zohomail.eu; s=zohoarc; b=x", "d=forged.example; b=x"),
                &zoho
            ),
            None
        );
        // a second set of the same instance: neither is Zoho's alone
        let twice = format!(
            "ARC-Authentication-Results: i=1; mx.zohomail.eu; dmarc=pass header.from=bank.example\r\n{set}{trace}"
        );
        assert_eq!(verdict(&twice, &zoho), None);
        // a higher instance than Zoho's, which a sender wrote below: not on top, so none
        let higher = format!(
            "{set}{trace}\r\nARC-Seal: i=2; d=zohomail.eu; cv=pass; b=x\r\n\
             ARC-Authentication-Results: i=2; mx.zohomail.eu; dmarc=pass header.from=bank.example"
        );
        assert_eq!(verdict(&higher, &zoho), None);
    }

    #[test]
    fn netease_and_others_by_their_table_entries() {
        let netease = Verifiers::of(&account("ann@163.com", "imap.163.com"), None);
        assert_eq!(netease.text(), "*");
        let found = verdict(
            "Authentication-Results: gzga-mx-mtada-g6-7; spf=pass smtp.mail=a@shop.com; dkim=pass header.i=@shop.com",
            &netease,
        )
        .unwrap();
        assert!(found.confirms("shop.com"));
        let fastmail = Verifiers::of(&account("ann@fastmail.com", "imap.fastmail.com"), None);
        assert!(fastmail.trusts(Some("phl-mx-02.messagingengine.com")));
        let proton = Verifiers::of(&account("ann@proton.me", "127.0.0.1"), None);
        assert!(proton.trusts(Some("mail.protonmail.ch")));
        let lark = Verifiers::of(&account("ann@shop.example", "imap.larksuite.com"), None);
        assert!(lark.trusts(Some("lms")) && !lark.trusts(Some("lms.forged.example")));
        // no entry: the organizational domains of the server and the address, as before
        let own = Verifiers::of(&account("ann@shop.example", "mail.host.example"), None);
        assert_eq!(own.text(), "host.example, shop.example");
        assert!(own.trusts(Some("mx.host.example")) && !own.trusts(Some("host.example.evil.com")));
        // the account's own names in place of those; nothing usable keeps the defaults
        let custom = Verifiers::of(
            &account("ann@shop.example", "mail.host.example"),
            Some("uvn-79-113.tll01.zonevs.eu, Mx.Mail.OVH.net.;bad/name"),
        );
        assert_eq!(custom.text(), "uvn-79-113.tll01.zonevs.eu, mx.mail.ovh.net");
        assert_eq!(
            Verifiers::of(&account("ann@shop.example", "mail.host.example"), Some(" , ")),
            own
        );
    }

    #[test]
    fn a_logo_needs_bimi_aligned_dmarc_and_a_certified_mark_where_said() {
        let verifiers = Verifiers::named(&["mx.provider.example"]);
        let logo = |results: &str| {
            verdict(
                &format!("Authentication-Results: mx.provider.example; {results}"),
                &verifiers,
            )
            .unwrap()
            .logo("news.shop.com")
        };
        assert!(logo(
            "bimi=pass header.d=shop.com header.selector=default; dmarc=pass header.from=shop.com"
        ));
        assert!(logo(
            "bimi=pass header.d=shop.com policy.authority=pass; dmarc=pass header.from=shop.com"
        ));
        assert!(!logo(
            "bimi=pass header.d=shop.com policy.authority=none; dmarc=pass header.from=shop.com"
        ));
        assert!(!logo("bimi=pass header.d=other.com; dmarc=pass header.from=shop.com"));
        assert!(!logo("bimi=pass header.d=shop.com; dmarc=pass header.from=other.com"));
        assert!(!logo("bimi=pass header.d=shop.com; dkim=pass header.d=shop.com"));
    }
}
