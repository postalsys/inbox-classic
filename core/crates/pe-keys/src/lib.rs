//! Finding a correspondent's OpenPGP key, and publishing the user's own:
//!
//! - **Web Key Directory** (draft-koch-openpgp-webkey-service): the key the address's own mail domain publishes, at
//!   `openpgpkey.<domain>` (the advanced method), or at the domain itself when that name does not exist (the direct
//!   method). Only the recipient's own provider learns of the lookup, so it is asked first.
//! - **keys.openpgp.org** (its VKS API): by address, by fingerprint or key id; publishing is an upload and a request
//!   for the server to send its confirmation mail.
//!
//! What comes back is a key only when `pe-pgp` reads it and it holds exactly the address asked for (or the
//! fingerprint): its other user ids are dropped, and a key the policy refuses is not one. HTTPS only (`pe_net::http`,
//! no redirects, 1 MB at most); nothing here stores anything.
#![forbid(unsafe_code)]

use std::time::Duration;

use pe_net::http::{self, Method, Request};

/// keys.openpgp.org
pub const KEYSERVER: &str = "https://keys.openpgp.org";

const TIMEOUT: Duration = Duration::from_secs(10);

/// Where keys are looked up; the tests point it at a server of their own
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Servers {
    /// The key server's base address, `https://keys.openpgp.org`
    pub keyserver: String,
    /// The Web Key Directory of every domain at this base instead (`http://127.0.0.1:port`): the advanced method is
    /// asked at `<base>/advanced/...`, the direct at `<base>/direct/...`
    pub wkd_base: Option<String>,
}

impl Default for Servers {
    fn default() -> Self {
        Servers {
            keyserver: KEYSERVER.into(),
            wkd_base: None,
        }
    }
}

/// Where a key was found
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Source {
    Wkd,
    Keyserver,
}

/// What a lookup came to
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Found {
    /// A key, binary, trimmed to the address asked for
    Key(Vec<u8>, Source),
    /// No key there (or none that holds the address)
    NotFound,
    /// The server could not be asked now (no connection, too many requests, down for maintenance): try later
    Unavailable(String),
}

/// z-base-32 (RFC 6189), the alphabet of the Web Key Directory's hashes
pub fn zbase32(bytes: &[u8]) -> String {
    const ALPHABET: &[u8; 32] = b"ybndrfg8ejkmcpqxot1uwisza345h769";
    let mut out = String::new();
    let mut buffer = 0u32;
    let mut bits = 0;
    for &byte in bytes {
        buffer = (buffer << 8) | u32::from(byte);
        bits += 8;
        while bits >= 5 {
            bits -= 5;
            out.push(ALPHABET[((buffer >> bits) & 31) as usize] as char);
        }
    }
    if bits > 0 {
        out.push(ALPHABET[((buffer << (5 - bits)) & 31) as usize] as char);
    }
    out
}

/// The Web Key Directory's name for a local part: z-base-32 of the SHA-1 of it in lower case
pub fn wkd_hash(local: &str) -> String {
    let digest = ring::digest::digest(
        &ring::digest::SHA1_FOR_LEGACY_USE_ONLY,
        local.to_ascii_lowercase().as_bytes(),
    );
    zbase32(digest.as_ref())
}

/// A value in a URL: everything but letters, digits and `-._~` percent-encoded
fn encoded(value: &str) -> String {
    let mut out = String::new();
    for byte in value.bytes() {
        if byte.is_ascii_alphanumeric() || b"-._~".contains(&byte) {
            out.push(byte as char);
        } else {
            out.push_str(&format!("%{byte:02X}"));
        }
    }
    out
}

/// The two addresses of the Web Key Directory for `address`: advanced, then direct
pub fn wkd_urls(address: &str, servers: &Servers) -> Option<(String, String)> {
    let (local, domain) = address.trim().rsplit_once('@')?;
    let domain = domain.to_ascii_lowercase();
    if local.is_empty() || domain.is_empty() || domain.contains(['/', '?', '#', ':', '@']) {
        return None;
    }
    let hash = wkd_hash(local);
    let local = encoded(local);
    Some(match &servers.wkd_base {
        Some(base) => (
            format!("{base}/advanced/.well-known/openpgpkey/{domain}/hu/{hash}?l={local}"),
            format!("{base}/direct/.well-known/openpgpkey/hu/{hash}?l={local}"),
        ),
        None => (
            format!("https://openpgpkey.{domain}/.well-known/openpgpkey/{domain}/hu/{hash}?l={local}"),
            format!("https://{domain}/.well-known/openpgpkey/hu/{hash}?l={local}"),
        ),
    })
}

/// A key in `bytes` that holds `address`, trimmed to it
fn trimmed(bytes: &[u8], address: &str, now: i64) -> Option<Vec<u8>> {
    pe_pgp::read_certs(bytes)
        .ok()?
        .into_iter()
        .find_map(|cert| cert.minimal(address, now))
        .map(|cert| cert.to_bytes())
}

async fn get(url: &str) -> Result<http::Response, http::HttpError> {
    let mut request = Request::get(url, TIMEOUT);
    request.plain_http = url.starts_with("http://127.0.0.1") || url.starts_with("http://localhost");
    http::send(request).await
}

/// What an answer of a lookup is: a key (checked by `accept`), none, or try later
fn answer(
    response: Result<http::Response, http::HttpError>,
    accept: impl Fn(&[u8]) -> Option<Vec<u8>>,
    source: Source,
) -> Found {
    match response {
        Ok(response) if response.status == 200 => match accept(&response.body) {
            Some(key) => Found::Key(key, source),
            None => Found::NotFound,
        },
        Ok(response) if matches!(response.status, 429 | 500..=599) => {
            Found::Unavailable(format!("HTTP {}", response.status))
        }
        Ok(_) => Found::NotFound,
        Err(error) => Found::Unavailable(error.to_string()),
    }
}

/// The key `address`'s domain publishes in its Web Key Directory: the advanced method, and the direct one only when
/// the advanced host can not be reached at all (the draft: when `openpgpkey.<domain>` does not exist)
pub async fn wkd(address: &str, servers: &Servers, now: i64) -> Found {
    let Some((advanced, direct)) = wkd_urls(address, servers) else {
        return Found::NotFound;
    };
    let accept = |body: &[u8]| trimmed(body, address, now);
    match get(&advanced).await {
        Err(http::HttpError::Net(_)) => answer(get(&direct).await, accept, Source::Wkd),
        response => answer(response, accept, Source::Wkd),
    }
}

/// The key keys.openpgp.org has for `address` (it publishes an address only once its owner confirmed it)
pub async fn by_email(address: &str, servers: &Servers, now: i64) -> Found {
    let url = format!("{}/vks/v1/by-email/{}", servers.keyserver, encoded(address.trim()));
    answer(get(&url).await, |body| trimmed(body, address, now), Source::Keyserver)
}

/// The key keys.openpgp.org has with this fingerprint or key id (upper case hex), for a signature by a key not
/// known here: asking by fingerprint tells the server no address
pub async fn by_fingerprint(handle: &str, servers: &Servers) -> Found {
    let handle: String = handle
        .chars()
        .filter(char::is_ascii_hexdigit)
        .collect::<String>()
        .to_ascii_uppercase();
    let kind = match handle.len() {
        16 => "by-keyid",
        40 | 64 => "by-fingerprint",
        _ => return Found::NotFound,
    };
    let url = format!("{}/vks/v1/{kind}/{handle}", servers.keyserver);
    let accept = |body: &[u8]| {
        let cert = pe_pgp::read_certs(body)
            .ok()?
            .into_iter()
            .find(|cert| cert.handles().contains(&handle))?;
        Some(cert.to_bytes())
    };
    answer(get(&url).await, accept, Source::Keyserver)
}

/// The key of `address`: the Web Key Directory first, then (when `use_keyserver`) keys.openpgp.org
pub async fn find(address: &str, servers: &Servers, use_keyserver: bool, now: i64) -> Found {
    let wkd = wkd(address, servers, now).await;
    match wkd {
        Found::Key(..) => wkd,
        _ if use_keyserver => match by_email(address, servers, now).await {
            Found::NotFound if matches!(wkd, Found::Unavailable(_)) => wkd,
            other => other,
        },
        _ => wkd,
    }
}

/// What keys.openpgp.org says of each address of a key: `published`, `pending` (a confirmation mail was sent),
/// `unpublished`, `revoked`
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Published {
    pub token: String,
    pub addresses: Vec<(String, String)>,
}

fn published(body: &[u8]) -> Option<Published> {
    let value: serde_json::Value = serde_json::from_slice(body).ok()?;
    let token = value["token"].as_str()?.to_string();
    let mut addresses: Vec<(String, String)> = value["status"]
        .as_object()?
        .iter()
        .filter_map(|(address, status)| Some((address.clone(), status.as_str()?.to_string())))
        .collect();
    addresses.sort();
    Some(Published { token, addresses })
}

async fn post_json(url: &str, body: &serde_json::Value) -> Result<Published, String> {
    let body = body.to_string();
    let mut request = Request::get(url, TIMEOUT);
    request.method = Method::Post;
    request.headers = &[("Content-Type", "application/json"), ("Accept", "application/json")];
    request.body = body.as_bytes();
    request.plain_http = url.starts_with("http://127.0.0.1");
    let response = http::send(request).await.map_err(|error| error.to_string())?;
    if response.status != 200 {
        let value: serde_json::Value = serde_json::from_slice(&response.body).unwrap_or_default();
        let said = value["error"]
            .as_str()
            .map(str::to_string)
            .unwrap_or_else(|| format!("HTTP {}", response.status));
        return Err(said.chars().filter(|c| !c.is_control()).take(200).collect());
    }
    published(&response.body).ok_or_else(|| "not an answer of a key server".to_string())
}

/// Publishes a public key on keys.openpgp.org and asks it to send its confirmation mail to `addresses` (the server
/// publishes an address only once its owner clicks the link in that mail)
pub async fn publish(armored: &str, addresses: &[String], servers: &Servers) -> Result<Published, String> {
    let uploaded = post_json(
        &format!("{}/vks/v1/upload", servers.keyserver),
        &serde_json::json!({ "keytext": armored }),
    )
    .await?;
    let ask: Vec<&String> = addresses
        .iter()
        .filter(|address| {
            uploaded
                .addresses
                .iter()
                .any(|(a, status)| a == *address && status == "unpublished")
        })
        .collect();
    if ask.is_empty() {
        return Ok(uploaded);
    }
    post_json(
        &format!("{}/vks/v1/request-verify", servers.keyserver),
        &serde_json::json!({ "token": uploaded.token, "addresses": ask }),
    )
    .await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_hash_of_the_draft() {
        // draft-koch-openpgp-webkey-service: "Joe.Doe" -> "iy9q119eutrkn8s1mk4r39qejnbu3n5q"
        assert_eq!(wkd_hash("Joe.Doe"), "iy9q119eutrkn8s1mk4r39qejnbu3n5q");
    }

    #[test]
    fn wkd_addresses() {
        let (advanced, direct) = wkd_urls("Joe.Doe@Example.ORG", &Servers::default()).unwrap();
        assert_eq!(
            advanced,
            "https://openpgpkey.example.org/.well-known/openpgpkey/example.org/hu/iy9q119eutrkn8s1mk4r39qejnbu3n5q?l=Joe.Doe"
        );
        assert_eq!(
            direct,
            "https://example.org/.well-known/openpgpkey/hu/iy9q119eutrkn8s1mk4r39qejnbu3n5q?l=Joe.Doe"
        );
        assert!(wkd_urls("a@b/c", &Servers::default()).is_none());
        assert!(wkd_urls("no-at", &Servers::default()).is_none());
        let (advanced, _) = wkd_urls("a+b@example.org", &Servers::default()).unwrap();
        assert!(advanced.ends_with("?l=a%2Bb"));
    }

    #[test]
    fn publish_answers() {
        let body = br#"{"key_fpr":"AB","token":"t0k","status":{"b@x.org":"unpublished","a@x.org":"published"}}"#;
        assert_eq!(
            published(body),
            Some(Published {
                token: "t0k".into(),
                addresses: vec![
                    ("a@x.org".into(), "published".into()),
                    ("b@x.org".into(), "unpublished".into())
                ]
            })
        );
        assert_eq!(published(b"<html>"), None);
    }
}
