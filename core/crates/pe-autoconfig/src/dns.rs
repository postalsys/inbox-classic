//! MX and SRV records over DNS-over-HTTPS (the JSON API of Cloudflare, Google's as the fallback), never over
//! plain DNS: an answer over UDP can be forged by anyone on the same network (a café Wi-Fi), and these records
//! decide which servers get the password. The DoH provider sees only the name looked up, which is the domain of the
//! address, as the ISPDB lookup already does.

use std::time::Duration;

use crate::io::{HttpRequest, Io};

/// The DoH JSON API asked first
pub const DOH_PRIMARY: &str = "https://cloudflare-dns.com/dns-query";
/// Asked when the first one does not answer
pub const DOH_FALLBACK: &str = "https://dns.google/resolve";
/// How long one DoH provider may take, so the fallback still fits in a resolver's budget
const DOH_TIMEOUT: Duration = Duration::from_millis(2000);
/// More records than any domain publishes for one name
const MAX_ANSWERS: usize = 64;

const TYPE_MX: u16 = 15;
const TYPE_SRV: u16 = 33;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MxRecord {
    pub priority: u16,
    /// Lowercase, without the trailing dot
    pub exchange: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SrvRecord {
    pub priority: u16,
    pub weight: u16,
    pub port: u16,
    /// Lowercase, without the trailing dot
    pub target: String,
}

/// A host name of a DNS answer or a server setting, lowercase and without a trailing dot; None for anything that is
/// not one (`.` included, the "no such service" target)
pub(crate) fn host_name(text: &str) -> Option<String> {
    let host = text.trim();
    let host = host.strip_suffix('.').unwrap_or(host).to_ascii_lowercase();
    let valid = !host.is_empty()
        && host.len() <= 253
        && host.split('.').all(|label| {
            !label.is_empty()
                && label.len() <= 63
                && label
                    .bytes()
                    .all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'_')
        });
    valid.then_some(host)
}

/// The `data` of the answers of type `rtype` in a DoH JSON response; None when it is not one. An answer with a
/// `Status` other than 0 (NOERROR) has no records.
pub fn parse_doh(json: &[u8], rtype: u16) -> Option<Vec<String>> {
    let value: serde_json::Value = serde_json::from_slice(json).ok()?;
    let status = value.get("Status")?.as_u64()?;
    if status != 0 {
        return Some(Vec::new());
    }
    let Some(answers) = value.get("Answer").and_then(|a| a.as_array()) else {
        return Some(Vec::new());
    };
    Some(
        answers
            .iter()
            .filter(|answer| answer.get("type").and_then(|t| t.as_u64()) == Some(rtype as u64))
            .filter_map(|answer| answer.get("data")?.as_str().map(str::to_string))
            .take(MAX_ANSWERS)
            .collect(),
    )
}

/// `10 mx.example.com.`
pub fn parse_mx_data(data: &str) -> Option<MxRecord> {
    let mut parts = data.split_whitespace();
    let priority = parts.next()?.parse().ok()?;
    let exchange = host_name(parts.next()?)?;
    parts.next().is_none().then_some(MxRecord { priority, exchange })
}

/// `0 1 993 imap.example.com.`; None for the target `.`, which says the service is not offered (RFC 2782)
pub fn parse_srv_data(data: &str) -> Option<SrvRecord> {
    let mut parts = data.split_whitespace();
    let priority = parts.next()?.parse().ok()?;
    let weight = parts.next()?.parse().ok()?;
    let port: u16 = parts.next()?.parse().ok()?;
    let target = host_name(parts.next()?)?;
    (port > 0 && parts.next().is_none()).then_some(SrvRecord {
        priority,
        weight,
        port,
        target,
    })
}

/// The MX records of a DoH response, lowest priority first
pub fn parse_doh_mx(json: &[u8]) -> Option<Vec<MxRecord>> {
    let mut records: Vec<MxRecord> = parse_doh(json, TYPE_MX)?
        .iter()
        .filter_map(|d| parse_mx_data(d))
        .collect();
    records.sort_by_key(|r| r.priority);
    Some(records)
}

/// The SRV records of a DoH response, lowest priority first
pub fn parse_doh_srv(json: &[u8]) -> Option<Vec<SrvRecord>> {
    let mut records: Vec<SrvRecord> = parse_doh(json, TYPE_SRV)?
        .iter()
        .filter_map(|d| parse_srv_data(d))
        .collect();
    records.sort_by_key(|r| r.priority);
    Some(records)
}

/// The DoH response for `name`, from the first provider that gives one
async fn query<I: Io + ?Sized>(io: &I, name: &str, rtype: &str) -> Option<Vec<u8>> {
    let name = host_name(name)?;
    for base in [DOH_PRIMARY, DOH_FALLBACK] {
        let request = HttpRequest {
            headers: vec![("accept".into(), "application/dns-json".into())],
            ..HttpRequest::get(format!("{base}?name={name}&type={rtype}"))
        };
        if let Ok(Ok(response)) = tokio::time::timeout(DOH_TIMEOUT, io.http(request)).await
            && response.status == 200
            && serde_json::from_slice::<serde_json::Value>(&response.body).is_ok_and(|v| v.get("Status").is_some())
        {
            return Some(response.body);
        }
    }
    None
}

/// The MX records of `domain` over DoH, lowest priority first; none when neither provider answers
pub async fn doh_mx<I: Io + ?Sized>(io: &I, domain: &str) -> Vec<MxRecord> {
    let body = query(io, domain, "MX").await;
    body.and_then(|b| parse_doh_mx(&b)).unwrap_or_default()
}

/// The SRV records of `name` over DoH, lowest priority first; none when neither provider answers
pub async fn doh_srv<I: Io + ?Sized>(io: &I, name: &str) -> Vec<SrvRecord> {
    let body = query(io, name, "SRV").await;
    body.and_then(|b| parse_doh_srv(&b)).unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use std::sync::Mutex;

    use super::*;
    use crate::{HttpError, Response};

    // what Cloudflare answered for postalsys.com
    const MX: &str = r#"{"Status":0,"TC":false,"RD":true,"RA":true,"AD":false,"CD":false,"Question":[{"name":"postalsys.com","type":15}],"Answer":[{"name":"postalsys.com","type":15,"TTL":300,"data":"10 alt3.aspmx.l.google.com."},{"name":"postalsys.com","type":5,"TTL":300,"data":"cname.example.com."},{"name":"postalsys.com","type":15,"TTL":300,"data":"1 ASPMX.L.google.com."},{"name":"postalsys.com","type":15,"TTL":300,"data":"5 alt1.aspmx.l.google.com."}]}"#;

    #[test]
    fn mx_answers() {
        let records = parse_doh_mx(MX.as_bytes()).unwrap();
        assert_eq!(
            records
                .iter()
                .map(|r| (r.priority, r.exchange.as_str()))
                .collect::<Vec<_>>(),
            [
                (1, "aspmx.l.google.com"),
                (5, "alt1.aspmx.l.google.com"),
                (10, "alt3.aspmx.l.google.com")
            ]
        );
        // NXDOMAIN and SERVFAIL have no records; no answer section either
        assert_eq!(
            parse_doh_mx(br#"{"Status":3,"Answer":[{"type":15,"data":"1 mx.example.com."}]}"#),
            Some(vec![])
        );
        assert_eq!(parse_doh_mx(br#"{"Status":2}"#), Some(vec![]));
        assert_eq!(parse_doh_mx(br#"{"Status":0}"#), Some(vec![]));
        // not a DoH response
        assert_eq!(parse_doh_mx(b"<html>"), None);
        assert_eq!(parse_doh_mx(br#"{"Answer":[]}"#), None);
        // a null MX (RFC 7505) and junk are no exchange
        assert_eq!(parse_mx_data("0 ."), None);
        assert_eq!(parse_mx_data("x mx.example.com."), None);
        assert_eq!(parse_mx_data("10 mx.example.com. extra"), None);
        assert_eq!(parse_mx_data("10 mx/evil"), None);
    }

    #[test]
    fn srv_answers() {
        let json = br#"{"Status":0,"Answer":[{"name":"_imaps._tcp.fastmail.com","type":33,"TTL":3600,"data":"0 1 993 imap.fastmail.com"}]}"#;
        assert_eq!(
            parse_doh_srv(json).unwrap(),
            [SrvRecord {
                priority: 0,
                weight: 1,
                port: 993,
                target: "imap.fastmail.com".into()
            }]
        );
        // what fastmail.com publishes for _submission: not offered (RFC 6186 section 3.4)
        let none =
            br#"{"Status":0,"Answer":[{"name":"_submission._tcp.fastmail.com","type":33,"TTL":3600,"data":"0 0 0 "}]}"#;
        assert_eq!(parse_doh_srv(none), Some(vec![]));
        assert_eq!(parse_srv_data("0 0 587 ."), None);
        assert_eq!(parse_srv_data("0 0 70000 a.example.com"), None);
        // sorted by priority
        let two = br#"{"Status":0,"Answer":[{"type":33,"data":"20 0 993 b.example.com."},{"type":33,"data":"10 0 993 a.example.com."}]}"#;
        assert_eq!(parse_doh_srv(two).unwrap()[0].target, "a.example.com");
    }

    #[test]
    fn host_names() {
        assert_eq!(host_name("Mail.Example.COM.").as_deref(), Some("mail.example.com"));
        assert_eq!(host_name("."), None);
        assert_eq!(host_name(""), None);
        assert_eq!(host_name("a..b"), None);
        assert_eq!(host_name("a b.com"), None);
        assert_eq!(host_name(&"a".repeat(64)), None);
    }

    /// DoH over a stand-in HTTP: answers by the host of the URL
    struct Doh {
        asked: Mutex<Vec<HttpRequest>>,
        cloudflare: Option<&'static str>,
        google: Option<&'static str>,
    }

    impl Io for Doh {
        async fn http(&self, request: HttpRequest) -> Result<Response, HttpError> {
            let answer = if request.url.starts_with(DOH_PRIMARY) {
                self.cloudflare
            } else {
                self.google
            };
            self.asked.lock().unwrap().push(request);
            answer.map(|a| Response::new(200, a)).ok_or(HttpError::Malformed)
        }
    }

    #[tokio::test]
    async fn falls_back_to_the_second_provider() {
        let doh = Doh {
            asked: Mutex::new(Vec::new()),
            cloudflare: None,
            google: Some(MX),
        };
        let records = doh_mx(&doh, "postalsys.com").await;
        assert_eq!(records[0].exchange, "aspmx.l.google.com");
        let asked = doh.asked.lock().unwrap().clone();
        assert_eq!(
            asked[0].url,
            "https://cloudflare-dns.com/dns-query?name=postalsys.com&type=MX"
        );
        assert_eq!(asked[0].header("Accept"), Some("application/dns-json"));
        assert_eq!(asked[1].url, "https://dns.google/resolve?name=postalsys.com&type=MX");

        // an answer from the first provider is enough, even one without records
        let doh = Doh {
            asked: Mutex::new(Vec::new()),
            cloudflare: Some(r#"{"Status":3}"#),
            google: Some(MX),
        };
        assert_eq!(doh_srv(&doh, "_imaps._tcp.example.com").await, vec![]);
        assert_eq!(doh.asked.lock().unwrap().len(), 1);

        // neither answers: no records, and a name that is not one is not asked about
        let doh = Doh {
            asked: Mutex::new(Vec::new()),
            cloudflare: Some("garbage"),
            google: None,
        };
        assert_eq!(doh_mx(&doh, "example.com").await, vec![]);
        assert_eq!(doh_mx(&doh, "exa mple.com&type=A").await, vec![]);
        assert_eq!(doh.asked.lock().unwrap().len(), 2);
    }
}
