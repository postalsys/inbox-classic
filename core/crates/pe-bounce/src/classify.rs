//! What a remote server's reply means: a port of bounce-classifier (`../bounce-classifier/src`).
//! The network's verdict ([`crate::model`]) with its rules on top: phrases that settle the
//! category, and the SMTP codes when the network is unsure; then the action to take, how long to
//! wait before trying again, and the blocklist that is named.

use std::sync::LazyLock;

use regex::Regex;

use crate::js::{self, regex};
use crate::model::{self, NUM_LABELS};

/// The categories of the network's output, in the order of model/labels.json: `label as usize` is
/// the index of its output
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Label {
    AuthFailure,
    DomainBlacklisted,
    GeoBlocked,
    Greylisting,
    InvalidAddress,
    IpBlacklisted,
    MailboxDisabled,
    MailboxFull,
    PolicyBlocked,
    RateLimited,
    RelayDenied,
    ServerError,
    SpamBlocked,
    Unknown,
    UserUnknown,
    VirusDetected,
}

impl Label {
    pub const ALL: [Label; NUM_LABELS] = [
        Label::AuthFailure,
        Label::DomainBlacklisted,
        Label::GeoBlocked,
        Label::Greylisting,
        Label::InvalidAddress,
        Label::IpBlacklisted,
        Label::MailboxDisabled,
        Label::MailboxFull,
        Label::PolicyBlocked,
        Label::RateLimited,
        Label::RelayDenied,
        Label::ServerError,
        Label::SpamBlocked,
        Label::Unknown,
        Label::UserUnknown,
        Label::VirusDetected,
    ];

    /// The name bounce-classifier uses, `user_unknown`
    pub fn name(self) -> &'static str {
        match self {
            Label::AuthFailure => "auth_failure",
            Label::DomainBlacklisted => "domain_blacklisted",
            Label::GeoBlocked => "geo_blocked",
            Label::Greylisting => "greylisting",
            Label::InvalidAddress => "invalid_address",
            Label::IpBlacklisted => "ip_blacklisted",
            Label::MailboxDisabled => "mailbox_disabled",
            Label::MailboxFull => "mailbox_full",
            Label::PolicyBlocked => "policy_blocked",
            Label::RateLimited => "rate_limited",
            Label::RelayDenied => "relay_denied",
            Label::ServerError => "server_error",
            Label::SpamBlocked => "spam_blocked",
            Label::Unknown => "unknown",
            Label::UserUnknown => "user_unknown",
            Label::VirusDetected => "virus_detected",
        }
    }

    pub fn from_name(name: &str) -> Option<Label> {
        Label::ALL.into_iter().find(|l| l.name() == name)
    }

    /// What to do about a bounce of this category
    pub fn action(self) -> Action {
        match self {
            Label::UserUnknown | Label::InvalidAddress | Label::MailboxDisabled => Action::Remove,
            Label::Greylisting | Label::RateLimited | Label::ServerError | Label::MailboxFull => Action::Retry,
            Label::IpBlacklisted | Label::GeoBlocked => Action::RetryDifferentIp,
            Label::DomainBlacklisted | Label::AuthFailure | Label::RelayDenied => Action::FixConfiguration,
            Label::SpamBlocked | Label::PolicyBlocked | Label::Unknown => Action::Review,
            Label::VirusDetected => Action::RemoveContent,
        }
    }

    /// Whether a blocklist named only in words is reported for this category; other categories
    /// (an unknown recipient, a full mailbox) are not caused by a listing
    fn is_block(self) -> bool {
        matches!(
            self,
            Label::IpBlacklisted | Label::DomainBlacklisted | Label::SpamBlocked | Label::PolicyBlocked
        )
    }
}

/// The recommended action, bounce-classifier's ACTION_MAP
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Action {
    /// A permanent failure: the address is no good
    Remove,
    /// A temporary failure: try again later
    Retry,
    /// The sending server's address is blocked
    RetryDifferentIp,
    /// The sender's setup needs fixing
    FixConfiguration,
    /// Someone has to look at it
    Review,
    /// The content was refused
    RemoveContent,
}

impl Action {
    pub fn name(self) -> &'static str {
        match self {
            Action::Remove => "remove",
            Action::Retry => "retry",
            Action::RetryDifferentIp => "retry_different_ip",
            Action::FixConfiguration => "fix_configuration",
            Action::Review => "review",
            Action::RemoveContent => "remove_content",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum BlocklistType {
    Ip,
    Domain,
    Uri,
}

impl BlocklistType {
    pub fn name(self) -> &'static str {
        match self {
            BlocklistType::Ip => "ip",
            BlocklistType::Domain => "domain",
            BlocklistType::Uri => "uri",
        }
    }
}

/// One blocklist named in a reply
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BlocklistInfo {
    /// `Spamhaus ZEN`, `Barracuda`
    pub name: &'static str,
    pub kind: BlocklistType,
    /// A DNSBL or lookup host was named, which is evidence on its own, rather than only the
    /// list's name next to words about listing
    pub host: bool,
}

/// The blocklists a reply names
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Blocklist {
    One(BlocklistInfo),
    Several { lists: Vec<BlocklistInfo>, host: bool },
}

impl Blocklist {
    pub fn lists(&self) -> &[BlocklistInfo] {
        match self {
            Blocklist::One(info) => std::slice::from_ref(info),
            Blocklist::Several { lists, .. } => lists,
        }
    }

    pub fn host(&self) -> bool {
        match self {
            Blocklist::One(info) => info.host,
            Blocklist::Several { host, .. } => *host,
        }
    }
}

/// bounce-classifier's ClassificationResult
#[derive(Debug, Clone, PartialEq)]
pub struct Classification {
    pub label: Label,
    /// The network's probability for `label`, also when a rule chose it
    pub confidence: f32,
    /// The network's own choice, when a rule chose another label
    pub model_label: Option<Label>,
    pub action: Action,
    /// The network's probability of each label, in the order of [`Label::ALL`]
    pub scores: [f32; NUM_LABELS],
    /// A phrase or an SMTP code chose the label
    pub used_fallback: bool,
    /// Seconds to wait before trying again, when the reply says
    pub retry_after: Option<u32>,
    pub blocklist: Option<Blocklist>,
}

/// The SMTP codes at the start of a reply
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SmtpCodes {
    /// `550`
    pub main: Option<String>,
    /// `5.1.1`
    pub extended: Option<String>,
}

/// The network's top score below which an SMTP code decides
pub const CODE_FALLBACK_THRESHOLD: f32 = 0.5;

/// The longest reply read, in UTF-16 code units
pub const MAX_MESSAGE_LENGTH: usize = 10_000;

/// RFC 3463 enhanced status codes
const SMTP_CODES: &[(&str, Label)] = &[
    ("5.1.1", Label::UserUnknown),
    ("5.1.2", Label::InvalidAddress),
    ("5.1.3", Label::InvalidAddress),
    ("5.1.6", Label::InvalidAddress),
    ("4.1.1", Label::UserUnknown),
    ("5.2.0", Label::UserUnknown),
    ("5.2.1", Label::MailboxDisabled),
    ("5.2.2", Label::MailboxFull),
    ("5.2.3", Label::RateLimited),
    ("4.2.0", Label::Greylisting),
    ("4.2.1", Label::RateLimited),
    ("4.2.2", Label::MailboxFull),
    ("5.3.0", Label::ServerError),
    ("5.3.1", Label::ServerError),
    ("5.3.2", Label::ServerError),
    ("4.3.0", Label::ServerError),
    ("4.3.1", Label::ServerError),
    ("4.3.2", Label::ServerError),
    ("5.4.1", Label::UserUnknown),
    ("5.4.4", Label::ServerError),
    ("4.4.1", Label::ServerError),
    ("4.4.2", Label::ServerError),
    ("5.5.0", Label::UserUnknown),
    ("5.5.1", Label::InvalidAddress),
    ("5.5.2", Label::InvalidAddress),
    ("5.6.1", Label::PolicyBlocked),
    ("5.6.2", Label::PolicyBlocked),
    ("5.7.0", Label::VirusDetected),
    ("5.7.1", Label::PolicyBlocked),
    ("5.7.2", Label::RelayDenied),
    ("5.7.8", Label::AuthFailure),
    ("5.7.9", Label::AuthFailure),
    ("5.7.23", Label::AuthFailure),
    ("5.7.25", Label::AuthFailure),
    ("5.7.26", Label::AuthFailure),
    ("4.7.0", Label::RateLimited),
    ("4.7.1", Label::RateLimited),
    ("4.7.3", Label::RateLimited),
    ("4.7.28", Label::RateLimited),
    ("4.7.32", Label::RateLimited),
    ("4.7.650", Label::RateLimited),
    ("4.7.651", Label::RateLimited),
    ("5.2.121", Label::RateLimited),
    ("5.2.122", Label::RateLimited),
];

/// Basic SMTP reply codes
const SMTP_MAIN_CODES: &[(&str, Label)] = &[
    ("421", Label::Greylisting),
    ("450", Label::Greylisting),
    ("451", Label::ServerError),
    ("452", Label::ServerError),
    ("500", Label::InvalidAddress),
    ("501", Label::InvalidAddress),
    ("502", Label::ServerError),
    ("503", Label::ServerError),
    ("504", Label::ServerError),
    ("550", Label::UserUnknown),
    ("551", Label::RelayDenied),
    ("552", Label::MailboxFull),
    ("553", Label::InvalidAddress),
    ("554", Label::PolicyBlocked),
    ("571", Label::SpamBlocked),
];

fn lookup(table: &[(&str, Label)], code: &str) -> Option<Label> {
    table.iter().find(|(c, _)| *c == code).map(|(_, l)| *l)
}

/// Phrases that settle the category, checked in order. `.{0,50}?` and the like keep a match short
const TEXT_FALLBACKS: &[(&str, Label)] = &[
    (r"doesn't have a .{0,50}? account", Label::UserUnknown),
    (r"user doesn't have .{0,50}? account", Label::UserUnknown),
    (r"not a valid recipient", Label::UserUnknown),
    (r"no such user", Label::UserUnknown),
    (r"user unknown", Label::UserUnknown),
    (r"mailbox not found", Label::UserUnknown),
    (r"recipient rejected", Label::UserUnknown),
    (r"sender is unauthenticated", Label::AuthFailure),
    (r"requires .{0,50}? authenticate", Label::AuthFailure),
    (r"illegal attachment", Label::VirusDetected),
    (r"virus .{0,20}?detected", Label::VirusDetected),
    (r"infected .{0,20}?attachment", Label::VirusDetected),
    (r"malware .{0,20}?detected", Label::VirusDetected),
    (r"out of storage space", Label::MailboxFull),
    (r"over ?quota", Label::MailboxFull),
    (r"quota exceeded", Label::MailboxFull),
    (r"mailbox.{0,20}?full", Label::MailboxFull),
    (r"user unknown in", Label::UserUnknown),
    (r"address rejected.{0,30}?user unknown", Label::UserUnknown),
    (r"too many .{0,30}?connections", Label::RateLimited),
    (r"too many .{0,30}?messages", Label::RateLimited),
    (r"too many .{0,30}?recipients", Label::RateLimited),
    (r"rate .{0,20}?limit", Label::RateLimited),
    (r"sending .{0,20}?limit", Label::RateLimited),
    (r"connection .{0,20}?limit", Label::RateLimited),
    (r"throttl", Label::RateLimited),
];

static TEXT_FALLBACK_PATTERNS: LazyLock<Vec<(Regex, Label)>> = LazyLock::new(|| {
    TEXT_FALLBACKS
        .iter()
        .map(|(pattern, label)| (regex(pattern, "i"), *label))
        .collect()
});

/// Patterns whose first group is a number and second a unit, checked in order
const RETRY_PATTERNS: &[&str] = &[
    r"try\s+again\s+in\s+(\d+)\s*(second|minute|hour|min|sec|hr)s?",
    r"retry\s+in\s+(\d+)\s*(second|minute|hour|min|sec|hr)s?",
    r"wait\s+(\d+)\s*(second|minute|hour|min|sec|hr)s?",
    r"greylisted?\s+(?:for\s+)?(\d+)\s*(second|minute|hour|min|sec|hr)s?",
    r"delayed?\s+(?:for\s+)?(\d+)\s*(second|minute|hour|min|sec|hr)s?",
    r"come\s+back\s+in\s+(\d+)\s*(second|minute|hour|min|sec|hr)s?",
    r"after\s+(\d+)\s*(second|minute|hour|min|sec|hr)s?",
    r"\b(\d+)\s*(second|minute|hour)s?\b",
    r"too\s+many.{0,50}?(\d+)\s*(second|minute|hour|min|sec|hr)s?",
    r"greylist.{0,50}?(\d+)\s*(second|minute|hour|min|sec|hr)s?",
];

static RETRY_REGEXES: LazyLock<Vec<Regex>> = LazyLock::new(|| RETRY_PATTERNS.iter().map(|p| regex(p, "i")).collect());

static MAIN_CODE: LazyLock<Regex> = LazyLock::new(|| regex(r"^(\d{3})[\s-]", ""));
// bounce-classifier's pattern also rejects a code inside an IPv4 address with a lookbehind
// (?<!\d\.) and a lookahead (?!\.\d), which Rust's engine does not have; extract_smtp_codes checks
// them by hand
static EXTENDED_CODE: LazyLock<Regex> = LazyLock::new(|| regex(r"\b([245])\.(\d{1,3})\.(\d{1,3})\b", ""));

/// Listing wording a vendor's name has to be near
const BLOCKLIST_WORDING: &str = r"\b(?:block(?:ed|ing|list(?:ed)?)?|blacklist(?:ed)?|listed|rbl|dnsbl|reputation)\b";

fn near_wording(term: &str, wording: &str) -> String {
    format!(r"\b{term}\b.{{0,60}}{wording}|{wording}.{{0,60}}\b{term}\b")
}

struct BlocklistPattern {
    pattern: Regex,
    name: &'static str,
    kind: BlocklistType,
    host: bool,
}

fn entry(pattern: &str, name: &'static str, kind: BlocklistType, host: bool) -> BlocklistPattern {
    BlocklistPattern {
        pattern: regex(pattern, "i"),
        name,
        kind,
        host,
    }
}

/// A security vendor counts as a blocklist when its DNSBL or lookup host is named, or its name
/// sits next to listing wording; vendors are named in ordinary rejections too
fn vendor(vendor: &str, name: &'static str, hostnames: Option<&str>) -> Vec<BlocklistPattern> {
    let mut entries = Vec::new();
    if let Some(hostnames) = hostnames {
        entries.push(entry(hostnames, name, BlocklistType::Ip, true));
    }
    entries.push(entry(
        &near_wording(vendor, BLOCKLIST_WORDING),
        name,
        BlocklistType::Ip,
        false,
    ));
    entries
}

/// Names that match almost any "blocked" message and would crowd out a specific list
const GENERIC_BLOCKLIST_NAMES: [&str; 3] = ["RBL", "DNSBL", "Blocklist"];

static BLOCKLIST_PATTERNS: LazyLock<Vec<BlocklistPattern>> = LazyLock::new(|| {
    use BlocklistType::{Domain, Ip, Uri};
    let mut patterns = vec![
        entry(r"spamhaus\.org", "Spamhaus", Ip, true),
        entry(r"\bsbl\b", "Spamhaus SBL", Ip, false),
        entry(r"\bxbl\b", "Spamhaus XBL", Ip, false),
        entry(r"\bpbl\b", "Spamhaus PBL", Ip, false),
        entry(r"\bdbl\.spamhaus", "Spamhaus DBL", Domain, true),
        entry(r"\bzen\.spamhaus", "Spamhaus ZEN", Ip, true),
    ];
    patterns.extend(vendor("barracuda", "Barracuda", Some(r"barracudacentral\.org")));
    patterns.extend([
        entry(r"sorbs\.net", "SORBS", Ip, true),
        entry(r"dnsbl\.sorbs", "SORBS", Ip, true),
        entry(r"spamcop\.net", "SpamCop", Ip, true),
        entry(r"uribl\.com", "URIBL", Uri, true),
        entry(r"multi\.uribl", "URIBL", Uri, true),
    ]);
    patterns.extend(vendor("cloudmark", "Cloudmark", Some(r"csi\.cloudmark\.com")));
    patterns.extend(vendor(
        "proofpoint",
        "Proofpoint",
        Some(r"(?:ipcheck|prs)\.proofpoint\.com"),
    ));
    patterns.extend(vendor("mimecast", "Mimecast", None));
    patterns.extend([
        entry(r"\bS3150\b", "Microsoft Blocklist", Ip, false),
        entry(r"invaluement", "Invaluement", Ip, false),
        entry(r"hostkarma", "Hostkarma", Ip, false),
    ]);
    patterns.extend(vendor(r"trend\s*micro", "Trend Micro", Some(r"ers\.trendmicro\.com")));
    patterns.extend([
        // A bare "RBL" turns up in unrelated text, so it needs a DNSBL host carrying the term or
        // listing wording nearby
        entry(r"\b(?:dns|spam)?rbl\.[a-z0-9-]*[a-z]", "RBL", Ip, true),
        entry(
            &near_wording("rbl", r"\b(?:block(?:ed|ing|list(?:ed)?)?|blacklist(?:ed)?|listed)\b"),
            "RBL",
            Ip,
            false,
        ),
        entry(r"\bdnsbl\b", "DNSBL", Ip, false),
        entry(r"blacklist", "Blocklist", Ip, false),
        entry(r"blocklist", "Blocklist", Ip, false),
    ]);
    patterns
});

/// The SMTP code at the start of a reply and the first enhanced status code in it
pub fn extract_smtp_codes(message: &str) -> SmtpCodes {
    let main = MAIN_CODE.captures(message).map(|c| c[1].to_string());
    let bytes = message.as_bytes();
    let extended = EXTENDED_CODE.captures_iter(message).find_map(|c| {
        let m = c.get(0)?;
        // Not the end of an IPv4 address (`192.168.1.1` has no `2.168.1`) nor its start
        // (`5.7.1.100` has no `5.7.1`)
        let after_ip_part = m.start() >= 2 && bytes[m.start() - 1] == b'.' && bytes[m.start() - 2].is_ascii_digit();
        let before_ip_part =
            bytes.get(m.end()) == Some(&b'.') && bytes.get(m.end() + 1).is_some_and(u8::is_ascii_digit);
        (!after_ip_part && !before_ip_part).then(|| format!("{}.{}.{}", &c[1], &c[2], &c[3]))
    });
    SmtpCodes { main, extended }
}

/// The category a phrase in the reply settles
pub fn text_fallback(message: &str) -> Option<Label> {
    TEXT_FALLBACK_PATTERNS
        .iter()
        .find(|(pattern, _)| pattern.is_match(message))
        .map(|(_, label)| *label)
}

/// The category of the reply's SMTP codes
fn smtp_code_fallback(message: &str) -> Option<Label> {
    let codes = extract_smtp_codes(message);
    codes
        .extended
        .as_deref()
        .and_then(|code| lookup(SMTP_CODES, code))
        .or_else(|| codes.main.as_deref().and_then(|code| lookup(SMTP_MAIN_CODES, code)))
}

/// The category of the reply's phrases, else its SMTP codes
pub fn code_fallback(message: &str) -> Option<Label> {
    text_fallback(message).or_else(|| smtp_code_fallback(message))
}

/// Seconds the reply asks to wait before trying again, from a second to a day
pub fn extract_retry_timing(message: &str) -> Option<u32> {
    for pattern in RETRY_REGEXES.iter() {
        let Some(c) = pattern.captures(message) else {
            continue;
        };
        // parseInt of a long run of digits is a huge number, out of range like any other
        let Ok(value) = c[1].parse::<u64>() else {
            continue;
        };
        let unit = c[2].to_lowercase();
        let seconds = if unit.starts_with("sec") {
            value
        } else if unit.starts_with("min") {
            value.saturating_mul(60)
        } else if unit.starts_with("hour") || unit == "hr" {
            value.saturating_mul(3600)
        } else {
            value
        };
        if (1..=86_400).contains(&seconds) {
            return u32::try_from(seconds).ok();
        }
    }
    None
}

/// The blocklists a reply names
pub fn identify_blocklist(message: &str) -> Option<Blocklist> {
    let mut found: Vec<BlocklistInfo> = Vec::new();
    for pattern in BLOCKLIST_PATTERNS.iter() {
        if !pattern.pattern.is_match(message) {
            continue;
        }
        match found.iter_mut().find(|b| b.name == pattern.name) {
            Some(existing) => existing.host |= pattern.host,
            None => found.push(BlocklistInfo {
                name: pattern.name,
                kind: pattern.kind,
                host: pattern.host,
            }),
        }
    }
    let first = found.first()?.clone();
    let mut specific: Vec<BlocklistInfo> = found
        .into_iter()
        .filter(|b| !GENERIC_BLOCKLIST_NAMES.contains(&b.name))
        .collect();
    Some(match specific.len() {
        0 => Blocklist::One(first),
        1 => Blocklist::One(specific.remove(0)),
        _ => {
            let host = specific.iter().any(|b| b.host);
            Blocklist::Several { lists: specific, host }
        }
    })
}

/// Classifies a remote server's reply, `550 5.1.1 <user@example.com>: User unknown`. Unlike the
/// original, an empty reply is not an error: it gets the network's verdict on nothing
pub fn classify(message: &str) -> Classification {
    let message = js::truncate_utf16(message, MAX_MESSAGE_LENGTH);
    let model = model::model();
    let scores = model.scores(message);
    let mut max_score = 0f32;
    let mut max_index = 0;
    for (i, score) in scores.iter().enumerate() {
        if *score > max_score {
            max_score = *score;
            max_index = i;
        }
    }
    let model_label = Label::ALL[max_index];
    let mut label = model_label;
    let mut used_fallback = false;
    if let Some(fallback) = text_fallback(message) {
        label = fallback;
        used_fallback = true;
    } else if (max_score < CODE_FALLBACK_THRESHOLD || label == Label::Unknown)
        && let Some(fallback) = smtp_code_fallback(message)
    {
        label = fallback;
        used_fallback = true;
    }
    let confidence = scores[label as usize];
    // A named DNSBL host is reported whatever the label, wording alone only for a block
    let blocklist = identify_blocklist(message).filter(|b| b.host() || label.is_block());
    Classification {
        label,
        confidence,
        model_label: (label != model_label).then_some(model_label),
        action: label.action(),
        scores,
        used_fallback,
        retry_after: extract_retry_timing(message),
        blocklist,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn labels_match_the_model() {
        // Model::load checks model/labels.json against Label::ALL
        model::model();
        for (i, label) in Label::ALL.into_iter().enumerate() {
            assert_eq!(label as usize, i);
            assert_eq!(Label::from_name(label.name()), Some(label));
        }
    }

    #[test]
    fn smtp_codes() {
        let codes = extract_smtp_codes("550-5.1.1 User unknown");
        assert_eq!(codes.main.as_deref(), Some("550"));
        assert_eq!(codes.extended.as_deref(), Some("5.1.1"));
        assert_eq!(extract_smtp_codes("550 IP 5.7.1.100 is blacklisted").extended, None);
        assert_eq!(extract_smtp_codes("Server at 5.2.2.50 rejected").extended, None);
        assert_eq!(extract_smtp_codes("192.168.1.1 rejected").extended, None);
        assert_eq!(
            extract_smtp_codes("v1.2 5.7.1 result").extended.as_deref(),
            Some("5.7.1")
        );
        assert_eq!(extract_smtp_codes("550 5.7.23 SPF").extended.as_deref(), Some("5.7.23"));
    }

    #[test]
    fn retry_timing() {
        assert_eq!(extract_retry_timing("Try again in 30 seconds"), Some(30));
        assert_eq!(extract_retry_timing("Retry in 2 hr"), Some(7200));
        assert_eq!(extract_retry_timing("Wait 10 min"), Some(600));
        assert_eq!(extract_retry_timing("Wait 100000 seconds"), None);
        assert_eq!(extract_retry_timing("Wait 99999999999999999999999 seconds"), None);
        assert_eq!(extract_retry_timing("User unknown"), None);
    }

    #[test]
    fn blocklists() {
        let several = identify_blocklist("Blocked by spamhaus.org and barracuda").unwrap();
        assert_eq!(several.lists().len(), 2);
        assert_eq!(identify_blocklist("550 marblehead.com rejected"), None);
        assert!(!identify_blocklist("Blocked by Mimecast").unwrap().host());
        assert_eq!(
            identify_blocklist("rejected, listed on rbl.example.org"),
            Some(Blocklist::One(BlocklistInfo {
                name: "RBL",
                kind: BlocklistType::Ip,
                host: true
            }))
        );
    }

    #[test]
    fn classifies() {
        let result = classify("550 5.1.1 User unknown");
        assert_eq!(result.label, Label::UserUnknown);
        assert_eq!(result.action, Action::Remove);
        let result = classify("550 Blocked by zen.spamhaus.org");
        assert!(result.blocklist.is_some());
        assert_eq!(classify("").label, classify(" ").label);
    }
}
