//! A vault in an S3-compatible bucket: Amazon S3, Cloudflare R2, MinIO and the like. Every request is signed with
//! AWS Signature Version 4, its body's SHA-256 included (R2 refuses an unsigned payload on PUT), and goes over HTTPS
//! through pe-net (plain HTTP only to 127.0.0.1, for test servers). The vault's files are objects under the place's
//! prefix; the lock is written with `If-None-Match: *`, which S3, R2 and MinIO honour atomically. Listings are
//! parsed here with limits on their size, and the secret key never appears in an error or in debug output.

use std::fmt::Write as _;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use pe_net::http::{self, HttpError, Method, Request, Response, percent_encode};
use quick_xml::Reader;
use quick_xml::events::Event;
use ring::{digest, hmac};

use super::backend::{MAX_FILE, Place, PlaceError, PlaceResult};

/// The largest listing page read: a thousand keys of a few hundred bytes each
const MAX_LISTING: usize = 8 * 1024 * 1024;
/// The answer to a PUT or a DELETE, or an error document
const MAX_ANSWER: usize = 64 * 1024;
/// Room for the head of a response around a file read whole
const HEAD_ROOM: usize = 64 * 1024;
/// Pages of one listing: a million names, more than a vault ever has
const MAX_PAGES: usize = 1000;
/// Deeper than a listing or an error document goes
const MAX_DEPTH: usize = 8;
/// The text of one element: an S3 key is at most 1024 bytes
const MAX_TEXT: usize = 4096;
/// The events of one document: a page of a thousand keys with their details is about twenty thousand
const MAX_EVENTS: usize = 200_000;
/// The time a request without a body may take
const TIMEOUT: Duration = Duration::from_secs(60);
/// The slowest upload waited for, in bytes a second, on top of [`TIMEOUT`]
const SLOWEST_UPLOAD: u64 = 64 * 1024;

/// A bucket (and a folder in it) that holds a vault
#[derive(Clone)]
pub struct S3 {
    /// `https://s3.eu-central-1.amazonaws.com`, `https://<account>.r2.cloudflarestorage.com`, a MinIO server
    pub endpoint: String,
    /// `us-east-1`, `auto` for R2; empty is `us-east-1`
    pub region: String,
    pub bucket: String,
    /// A folder in the bucket, `/`-separated; empty for the bucket's root
    pub prefix: String,
    pub access_key: String,
    pub secret_key: String,
    /// `endpoint/bucket/key` rather than `bucket.endpoint/key`
    pub path_style: bool,
}

impl std::fmt::Debug for S3 {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("S3")
            .field("endpoint", &self.endpoint)
            .field("region", &self.region)
            .field("bucket", &self.bucket)
            .field("prefix", &self.prefix)
            .field("access_key", &self.access_key)
            .field("secret_key", &"(hidden)")
            .field("path_style", &self.path_style)
            .finish()
    }
}

/// The parts of a vault name, or of the place's prefix: only plain parts, never `.`, `..` or a backslash
fn parts(path: &str) -> PlaceResult<Vec<&str>> {
    let mut out = Vec::new();
    for part in path.split('/').filter(|p| !p.is_empty()) {
        if part == "." || part == ".." || part.contains(['\\', ':']) || part.chars().any(char::is_control) {
            return Err(PlaceError::Failed(format!("not a name of the vault: {path}")));
        }
        out.push(part);
    }
    Ok(out)
}

/// A request to the bucket, before it is signed
struct Call<'a> {
    method: Method,
    /// The object's key, None for the bucket itself (a listing)
    key: Option<&'a str>,
    /// Names and values not yet encoded
    query: Vec<(&'a str, String)>,
    /// Header fields besides the ones signing adds, names in lowercase
    headers: Vec<(&'static str, &'a str)>,
    body: &'a [u8],
    max_response: usize,
}

impl Call<'_> {
    fn new(method: Method, key: Option<&str>) -> Call<'_> {
        Call {
            method,
            key,
            query: Vec::new(),
            headers: Vec::new(),
            body: &[],
            max_response: MAX_ANSWER,
        }
    }
}

impl S3 {
    /// The vault's folder in the bucket as a key prefix: `a/b/`, or empty
    fn root(&self) -> PlaceResult<String> {
        Ok(parts(&self.prefix)?.iter().map(|p| format!("{p}/")).collect())
    }

    /// The key of a vault name
    fn key(&self, path: &str) -> PlaceResult<String> {
        let parts = parts(path)?;
        if parts.is_empty() {
            return Err(PlaceError::Failed(format!("not a name of the vault: {path}")));
        }
        Ok(format!("{}{}", self.root()?, parts.join("/")))
    }

    fn region(&self) -> &str {
        if self.region.trim().is_empty() {
            "us-east-1"
        } else {
            self.region.trim()
        }
    }

    /// What is wrong with the settings, before anything is sent
    fn check(&self) -> PlaceResult<http::Url> {
        let bad = |why: &str| Err(PlaceError::Failed(why.to_string()));
        let Some(url) = http::parse_url(self.endpoint.trim()) else {
            return bad("The S3 endpoint is not an https:// address");
        };
        if !url.https && url.host != "127.0.0.1" {
            return bad("The S3 endpoint is not an https:// address");
        }
        if !url.path.trim_end_matches('/').is_empty() {
            return bad("The S3 endpoint is a server's address without a path");
        }
        let bucket_ok = |b: u8| b.is_ascii_lowercase() || b.is_ascii_digit() || b"-._".contains(&b);
        if self.bucket.is_empty() || self.bucket.len() > 255 || !self.bucket.bytes().all(bucket_ok) {
            return bad("The bucket's name is not one S3 allows");
        }
        if !self.path_style && self.bucket.contains(['.', '_']) {
            return bad("This bucket's name can only be reached with path-style addressing");
        }
        let region_ok = |b: u8| b.is_ascii_alphanumeric() || b == b'-';
        if self.region().len() > 64 || !self.region().bytes().all(region_ok) {
            return bad("The region is not one S3 has");
        }
        let key_ok = |k: &str| !k.is_empty() && k.len() <= 256 && k.bytes().all(|b| b.is_ascii_graphic() && b != b',');
        if !key_ok(&self.access_key) || self.access_key.contains('/') || !key_ok(&self.secret_key) {
            return bad("The access key or the secret key is not one S3 gives");
        }
        Ok(url)
    }

    /// The URL of a call and its canonical path and query, encoded as signed
    fn address(&self, base: &http::Url, call: &Call) -> (String, String, Vec<(String, String)>) {
        let mut path = String::new();
        if self.path_style {
            path.push('/');
            path.push_str(&percent_encode(&self.bucket));
        }
        if let Some(key) = call.key {
            for part in key.split('/') {
                path.push('/');
                path.push_str(&percent_encode(part));
            }
        }
        if path.is_empty() {
            path.push('/');
        }
        let mut query: Vec<(String, String)> = call
            .query
            .iter()
            .map(|(name, value)| (percent_encode(name), percent_encode(value)))
            .collect();
        query.sort();
        let scheme = if base.https { "https" } else { "http" };
        let host = if self.path_style {
            base.authority()
        } else {
            format!("{}.{}", self.bucket, base.authority())
        };
        let mut url = format!("{scheme}://{host}{path}");
        if !query.is_empty() {
            let pairs: Vec<String> = query.iter().map(|(n, v)| format!("{n}={v}")).collect();
            url.push('?');
            url.push_str(&pairs.join("&"));
        }
        (url, path, query)
    }

    /// Sends a call signed, on a runtime of its own
    fn send(&self, call: Call) -> PlaceResult<Response> {
        let base = self.check()?;
        let (url, path, query) = self.address(&base, &call);
        let host = http::parse_url(&url)
            .map(|u| u.authority())
            .ok_or_else(|| PlaceError::Failed("The S3 endpoint is not an https:// address".into()))?;
        let payload = hex(digest::digest(&digest::SHA256, call.body).as_ref());
        let date = amz_date(SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |d| d.as_secs()));
        let mut signed: Vec<(String, String)> = vec![
            ("host".into(), host),
            ("x-amz-content-sha256".into(), payload.clone()),
            ("x-amz-date".into(), date.clone()),
        ];
        signed.extend(call.headers.iter().map(|(n, v)| (n.to_string(), v.to_string())));
        let signer = Signer {
            access_key: &self.access_key,
            secret_key: &self.secret_key,
            region: self.region(),
        };
        let authorization = signer.authorization(call.method.name(), &path, &query, &signed, &payload, &date);
        let mut headers: Vec<(&str, &str)> = signed
            .iter()
            .filter(|(name, _)| name != "host")
            .map(|(n, v)| (n.as_str(), v.as_str()))
            .collect();
        headers.push(("authorization", &authorization));
        if call.method == Method::Put {
            headers.push(("content-type", "application/octet-stream"));
        }
        let request = Request {
            method: call.method,
            url: &url,
            headers: &headers,
            body: call.body,
            timeout: TIMEOUT + Duration::from_secs(call.body.len() as u64 / SLOWEST_UPLOAD),
            max_response: call.max_response,
            plain_http: false,
        };
        match block(http::send(request))? {
            Ok(response) => Ok(response),
            Err(HttpError::Net(e)) => Err(PlaceError::Missing(format!(
                "The S3 endpoint could not be reached: {e}"
            ))),
            Err(HttpError::TooLarge) => Err(PlaceError::Failed("S3 answered with more than expected".into())),
            Err(e) => Err(PlaceError::Failed(format!("S3: {e}"))),
        }
    }

    /// The names (`folders` false) or the folders directly under a vault folder, every page of the listing
    fn listing(&self, prefix: &str, folders: bool) -> PlaceResult<Vec<String>> {
        let mut under = self.root()?;
        for part in parts(prefix)? {
            under.push_str(part);
            under.push('/');
        }
        let mut names = Vec::new();
        let mut token: Option<String> = None;
        for _ in 0..MAX_PAGES {
            let mut call = Call::new(Method::Get, None);
            call.query = vec![
                ("list-type", "2".into()),
                ("delimiter", "/".into()),
                ("prefix", under.clone()),
            ];
            if let Some(token) = &token {
                call.query.push(("continuation-token", token.clone()));
            }
            call.max_response = MAX_LISTING;
            let response = self.send(call)?;
            if response.status != 200 {
                return Err(self.refusal(&response));
            }
            let page = parse_listing(&response.body)
                .ok_or_else(|| PlaceError::Failed("S3 answered a listing that could not be read".into()))?;
            let found = if folders { page.folders } else { page.keys };
            for full in found {
                let Some(name) = full.strip_prefix(&under) else {
                    continue;
                };
                let name = name.strip_suffix('/').unwrap_or(name);
                if !name.is_empty() && !name.contains('/') {
                    names.push(name.to_string());
                }
            }
            match page.next {
                Some(next) if page.truncated && !next.is_empty() && token.as_ref() != Some(&next) => token = Some(next),
                _ => {
                    names.sort();
                    names.dedup();
                    return Ok(names);
                }
            }
        }
        Err(PlaceError::Failed("S3 answered a listing without end".into()))
    }

    /// An answer that is not a success, in words; the bucket missing is [`PlaceError::Missing`], credentials
    /// refused [`PlaceError::Refused`]
    fn refusal(&self, response: &Response) -> PlaceError {
        let (code, message) = parse_error(&response.body).unwrap_or_default();
        let mut words = format!("S3 answered {}", response.status);
        if !code.is_empty() {
            let _ = write!(words, " {code}");
        }
        if !message.is_empty() {
            let _ = write!(words, ": {message}");
        }
        match (response.status, code.as_str()) {
            (404, _) | (_, "NoSuchBucket") => {
                PlaceError::Missing(format!("The bucket {} was not found ({words})", self.bucket))
            }
            (401 | 403, _) | (_, "SignatureDoesNotMatch" | "InvalidAccessKeyId" | "AccessDenied") => {
                PlaceError::Refused(words)
            }
            _ => PlaceError::Failed(words),
        }
    }

    /// Whether a 404 is about the bucket rather than the object
    fn no_bucket(response: &Response) -> bool {
        parse_error(&response.body).is_some_and(|(code, _)| code == "NoSuchBucket")
    }
}

impl Place for S3 {
    fn list(&self, prefix: &str) -> PlaceResult<Vec<String>> {
        self.listing(prefix, false)
    }

    fn folders(&self, prefix: &str) -> PlaceResult<Vec<String>> {
        self.listing(prefix, true)
    }

    fn read(&self, path: &str) -> PlaceResult<Option<Vec<u8>>> {
        let key = self.key(path)?;
        let mut call = Call::new(Method::Get, Some(&key));
        call.max_response = MAX_FILE + HEAD_ROOM;
        let response = self.send(call)?;
        match response.status {
            200 if response.body.len() > MAX_FILE => Err(PlaceError::Failed(format!("{path} is too large"))),
            200 => Ok(Some(response.body)),
            404 if !S3::no_bucket(&response) => Ok(None),
            _ => Err(self.refusal(&response)),
        }
    }

    fn write(&self, path: &str, bytes: &[u8]) -> PlaceResult<()> {
        let key = self.key(path)?;
        let mut call = Call::new(Method::Put, Some(&key));
        call.body = bytes;
        let response = self.send(call)?;
        match response.status {
            200 | 201 | 204 => Ok(()),
            _ => Err(self.refusal(&response)),
        }
    }

    fn create(&self, path: &str, bytes: &[u8]) -> PlaceResult<bool> {
        let key = self.key(path)?;
        let mut call = Call::new(Method::Put, Some(&key));
        call.body = bytes;
        call.headers.push(("if-none-match", "*"));
        let response = self.send(call)?;
        match response.status {
            200 | 201 | 204 => Ok(true),
            // there already; or another write of it under way (S3's ConditionalRequestConflict), which wins or not
            412 => Ok(false),
            409 if parse_error(&response.body).is_some_and(|(code, _)| code == "ConditionalRequestConflict") => {
                Ok(false)
            }
            _ => Err(self.refusal(&response)),
        }
    }

    fn delete(&self, path: &str) -> PlaceResult<()> {
        let key = self.key(path)?;
        let response = self.send(Call::new(Method::Delete, Some(&key)))?;
        match response.status {
            200 | 202 | 204 => Ok(()),
            404 if !S3::no_bucket(&response) => Ok(()),
            _ => Err(self.refusal(&response)),
        }
    }
}

/// Runs a request to its end from code that is not async: on a runtime of its own, in a thread of its own when
/// called from inside another runtime (whose thread may not block on one)
fn block<T: Send>(work: impl Future<Output = T> + Send) -> PlaceResult<T> {
    let run = move || {
        tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .map(|runtime| runtime.block_on(work))
            .map_err(|e| PlaceError::Failed(e.to_string()))
    };
    if tokio::runtime::Handle::try_current().is_err() {
        return run();
    }
    std::thread::scope(|scope| {
        scope
            .spawn(run)
            .join()
            .unwrap_or_else(|_| Err(PlaceError::Failed("the request to S3 stopped".into())))
    })
}

/// Signature Version 4 of a request to S3
pub(crate) struct Signer<'a> {
    pub access_key: &'a str,
    pub secret_key: &'a str,
    pub region: &'a str,
}

impl Signer<'_> {
    /// The `Authorization` value of a request: `path` and `query` encoded as sent (the query sorted), `headers`
    /// every field signed with its name in lowercase, `payload` the hex SHA-256 of the body, `date` as in
    /// `x-amz-date`
    pub(crate) fn authorization(
        &self,
        method: &str,
        path: &str,
        query: &[(String, String)],
        headers: &[(String, String)],
        payload: &str,
        date: &str,
    ) -> String {
        let mut headers: Vec<(String, String)> = headers
            .iter()
            .map(|(name, value)| {
                let value = value.split_whitespace().collect::<Vec<_>>().join(" ");
                (name.to_ascii_lowercase(), value)
            })
            .collect();
        headers.sort();
        let signed_names: Vec<&str> = headers.iter().map(|(n, _)| n.as_str()).collect();
        let signed_names = signed_names.join(";");
        let mut query: Vec<&(String, String)> = query.iter().collect();
        query.sort();
        let query: Vec<String> = query.iter().map(|(n, v)| format!("{n}={v}")).collect();
        let canonical_headers: String = headers.iter().map(|(n, v)| format!("{n}:{v}\n")).collect();
        let canonical = format!(
            "{method}\n{path}\n{}\n{canonical_headers}\n{signed_names}\n{payload}",
            query.join("&")
        );
        let day = &date[..date.len().min(8)];
        let scope = format!("{day}/{}/s3/aws4_request", self.region);
        let to_sign = format!(
            "AWS4-HMAC-SHA256\n{date}\n{scope}\n{}",
            hex(digest::digest(&digest::SHA256, canonical.as_bytes()).as_ref())
        );
        let key = format!("AWS4{}", self.secret_key);
        let key = hmac_sha256(key.as_bytes(), day.as_bytes());
        let key = hmac_sha256(&key, self.region.as_bytes());
        let key = hmac_sha256(&key, b"s3");
        let key = hmac_sha256(&key, b"aws4_request");
        let signature = hex(&hmac_sha256(&key, to_sign.as_bytes()));
        format!(
            "AWS4-HMAC-SHA256 Credential={}/{scope}, SignedHeaders={signed_names}, Signature={signature}",
            self.access_key
        )
    }
}

fn hmac_sha256(key: &[u8], data: &[u8]) -> Vec<u8> {
    hmac::sign(&hmac::Key::new(hmac::HMAC_SHA256, key), data)
        .as_ref()
        .to_vec()
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().fold(String::with_capacity(bytes.len() * 2), |mut out, b| {
        let _ = write!(out, "{b:02x}");
        out
    })
}

/// `20130524T000000Z` of seconds since 1970
fn amz_date(seconds: u64) -> String {
    let days = (seconds / 86_400) as i64;
    let time = seconds % 86_400;
    // days to a date in the proleptic Gregorian calendar (Howard Hinnant's civil_from_days)
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let day = doy - (153 * mp + 2) / 5 + 1;
    let month = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = yoe + era * 400 + i64::from(month <= 2);
    format!(
        "{year:04}{month:02}{day:02}T{:02}{:02}{:02}Z",
        time / 3600,
        time / 60 % 60,
        time % 60
    )
}

/// What a ListObjectsV2 page says
#[derive(Debug, Default, PartialEq, Eq)]
struct Page {
    /// `Contents/Key`
    keys: Vec<String>,
    /// `CommonPrefixes/Prefix`
    folders: Vec<String>,
    truncated: bool,
    next: Option<String>,
}

fn parse_listing(body: &[u8]) -> Option<Page> {
    let mut page = Page::default();
    let mut root = false;
    walk(body, |path, text| match path {
        [r] if r == "ListBucketResult" => root = true,
        [_, c, k] if c == "Contents" && k == "Key" => page.keys.push(text.to_string()),
        [_, c, p] if c == "CommonPrefixes" && p == "Prefix" => page.folders.push(text.to_string()),
        [_, t] if t == "IsTruncated" => page.truncated = text == "true",
        [_, n] if n == "NextContinuationToken" => page.next = Some(text.to_string()),
        _ => {}
    })?;
    root.then_some(page)
}

/// The `Code` and `Message` of an S3 error document, the message cut short and without control characters
fn parse_error(body: &[u8]) -> Option<(String, String)> {
    let mut code = String::new();
    let mut message = String::new();
    walk(body, |path, text| match path {
        [e, c] if e == "Error" && c == "Code" => code = text.to_string(),
        [e, m] if e == "Error" && m == "Message" => message = text.to_string(),
        _ => {}
    })?;
    let clean = |text: String| -> String { text.chars().filter(|c| !c.is_control()).take(200).collect() };
    let code = clean(code);
    let code = if code.bytes().all(|b| b.is_ascii_alphanumeric()) {
        code
    } else {
        String::new()
    };
    (!code.is_empty()).then(|| (code, clean(message)))
}

/// Walks an XML document, handing each element's path (local names) and trimmed text to `visit` when it ends; None
/// when it is not well-formed or larger than any S3 answer
fn walk(body: &[u8], mut visit: impl FnMut(&[String], &str)) -> Option<()> {
    let xml = std::str::from_utf8(body).ok()?.trim_start_matches('\u{feff}');
    let mut reader = Reader::from_str(xml);
    let mut path: Vec<String> = Vec::new();
    let mut text = String::new();
    for _ in 0..MAX_EVENTS {
        match reader.read_event().ok()? {
            Event::Start(tag) => {
                if path.len() >= MAX_DEPTH {
                    return None;
                }
                path.push(tag.local_name().into_inner().to_string());
                text.clear();
            }
            Event::Empty(tag) => {
                if path.len() >= MAX_DEPTH {
                    return None;
                }
                path.push(tag.local_name().into_inner().to_string());
                visit(&path, "");
                path.pop();
                text.clear();
            }
            Event::Text(part) => text.push_str(&part),
            Event::CData(part) => text.push_str(&part),
            Event::GeneralRef(reference) => {
                if reference.is_char_ref() {
                    text.extend(reference.resolve_char_ref().ok().flatten());
                } else {
                    // an entity a document declares is not one S3 writes
                    text.push_str(quick_xml::escape::resolve_predefined_entity(&reference)?);
                }
            }
            Event::End(_) => {
                let value = std::mem::take(&mut text);
                visit(&path, value.trim());
                path.pop()?;
            }
            Event::Eof => return path.is_empty().then_some(()),
            _ => {}
        }
        if text.len() > MAX_TEXT {
            return None;
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::BTreeMap;
    use std::io::{Read, Write};
    use std::net::TcpListener;
    use std::sync::{Arc, Mutex};

    #[test]
    fn signs_aws_get_object_example() {
        // "Example: GET Object" of the S3 documentation on Signature Version 4 in the Authorization header
        let signer = Signer {
            access_key: "AKIAIOSFODNN7EXAMPLE",
            secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            region: "us-east-1",
        };
        let empty = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
        let headers = [
            ("host", "examplebucket.s3.amazonaws.com"),
            ("range", "bytes=0-9"),
            ("x-amz-content-sha256", empty),
            ("x-amz-date", "20130524T000000Z"),
        ]
        .map(|(n, v)| (n.to_string(), v.to_string()));
        assert_eq!(hex(digest::digest(&digest::SHA256, b"").as_ref()), empty);
        assert_eq!(
            signer.authorization("GET", "/test.txt", &[], &headers, empty, "20130524T000000Z"),
            "AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request, \
             SignedHeaders=host;range;x-amz-content-sha256;x-amz-date, \
             Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41"
        );
    }

    #[test]
    fn dates() {
        assert_eq!(amz_date(1_369_353_600), "20130524T000000Z");
        assert_eq!(amz_date(0), "19700101T000000Z");
        assert_eq!(amz_date(951_825_599), "20000229T115959Z");
        assert_eq!(amz_date(1_798_761_599), "20261231T235959Z");
    }

    fn place(endpoint: &str) -> S3 {
        S3 {
            endpoint: endpoint.into(),
            region: "us-east-1".into(),
            bucket: "vault-bucket".into(),
            prefix: "Inbox Classic/vault".into(),
            access_key: "AKIDTEST".into(),
            secret_key: "secret/key+1".into(),
            path_style: true,
        }
    }

    #[test]
    fn addresses_encode_each_part() {
        let s3 = place("https://s3.eu-central-1.amazonaws.com");
        let base = s3.check().unwrap();
        let key = s3.key("devices/a b+c/ü").unwrap();
        assert_eq!(key, "Inbox Classic/vault/devices/a b+c/ü");
        let (url, path, _) = s3.address(&base, &Call::new(Method::Get, Some(&key)));
        assert_eq!(path, "/vault-bucket/Inbox%20Classic/vault/devices/a%20b%2Bc/%C3%BC");
        assert_eq!(url, format!("https://s3.eu-central-1.amazonaws.com{path}"));
        let mut list = Call::new(Method::Get, None);
        list.query = vec![
            ("prefix", "a b/".into()),
            ("list-type", "2".into()),
            ("delimiter", "/".into()),
        ];
        let (url, path, query) = s3.address(&base, &list);
        assert_eq!(path, "/vault-bucket");
        assert_eq!(query[0], ("delimiter".to_string(), "%2F".to_string()));
        assert_eq!(
            url,
            "https://s3.eu-central-1.amazonaws.com/vault-bucket?delimiter=%2F&list-type=2&prefix=a%20b%2F"
        );
        // the bucket in the host name
        let hosted = S3 {
            path_style: false,
            ..place("https://s3.amazonaws.com/")
        };
        let (url, _, _) = hosted.address(&hosted.check().unwrap(), &Call::new(Method::Get, Some("x/y")));
        assert_eq!(url, "https://vault-bucket.s3.amazonaws.com/x/y");
    }

    #[test]
    fn settings_are_checked_before_anything_is_sent() {
        for endpoint in [
            "http://s3.example.com",
            "http://localhost:9000",
            "ftp://x",
            "https://s3.example.com/path",
        ] {
            assert!(place(endpoint).check().is_err(), "{endpoint}");
        }
        assert!(place("http://127.0.0.1:9000").check().is_ok());
        for bucket in ["", "Upper", "a/b", "a b"] {
            let s3 = S3 {
                bucket: bucket.into(),
                ..place("https://s3.example.com")
            };
            assert!(s3.check().is_err(), "{bucket}");
        }
        let s3 = S3 {
            secret_key: "with\nbreak".into(),
            ..place("https://s3.example.com")
        };
        assert!(s3.check().is_err());
        let s3 = place("https://s3.example.com");
        for bad in ["../x", "devices/../../x", "a\\b", "c:x", "", "/", "a/./b", "a\u{0}b"] {
            assert!(s3.key(bad).is_err(), "{bad:?}");
        }
        // the secret stays out of debug output
        let shown = format!("{s3:?}");
        assert!(shown.contains("AKIDTEST") && !shown.contains("secret/key"), "{shown}");
    }

    #[test]
    fn listings() {
        let page = parse_listing(
            br#"<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>vault-bucket</Name><Prefix>v/devices/</Prefix><KeyCount>3</KeyCount><MaxKeys>2</MaxKeys>
  <Delimiter>/</Delimiter><IsTruncated>true</IsTruncated>
  <Contents><Key>v/devices/head</Key><LastModified>2026-11-25T10:00:00.000Z</LastModified>
    <ETag>&quot;abc&quot;</ETag><Size>3</Size><StorageClass>STANDARD</StorageClass></Contents>
  <Contents><Key>v/devices/a&amp;b</Key><Size>1</Size></Contents>
  <CommonPrefixes><Prefix>v/devices/7f3c/</Prefix></CommonPrefixes>
  <CommonPrefixes><Prefix>v/devices/9a1b/</Prefix></CommonPrefixes>
  <NextContinuationToken>1ueGcxLPRx1Tr/XYExHnhbYLgveDs2J/wm36Hy4vbOwM=</NextContinuationToken>
</ListBucketResult>"#,
        )
        .unwrap();
        assert_eq!(
            page,
            Page {
                keys: vec!["v/devices/head".into(), "v/devices/a&b".into()],
                folders: vec!["v/devices/7f3c/".into(), "v/devices/9a1b/".into()],
                truncated: true,
                next: Some("1ueGcxLPRx1Tr/XYExHnhbYLgveDs2J/wm36Hy4vbOwM=".into()),
            }
        );
        let last = parse_listing(b"<ListBucketResult><IsTruncated>false</IsTruncated></ListBucketResult>").unwrap();
        assert_eq!(last, Page::default());
        // not a listing, not a document, too large
        assert_eq!(parse_listing(b"<Error><Code>AccessDenied</Code></Error>"), None);
        assert_eq!(parse_listing(b"<ListBucketResult><Contents>"), None);
        assert_eq!(parse_listing(b"<ListBucketResult>&custom;</ListBucketResult>"), None);
        let deep = format!("<ListBucketResult>{}", "<a>".repeat(MAX_DEPTH));
        assert_eq!(parse_listing(deep.as_bytes()), None);
        let long = format!(
            "<ListBucketResult><Contents><Key>{}</Key></Contents></ListBucketResult>",
            "k".repeat(MAX_TEXT + 1)
        );
        assert_eq!(parse_listing(long.as_bytes()), None);
        let many = format!("<ListBucketResult>{}</ListBucketResult>", "<a/>".repeat(MAX_EVENTS));
        assert_eq!(parse_listing(many.as_bytes()), None);
    }

    #[test]
    fn errors() {
        let (code, message) =
            parse_error(b"<?xml version=\"1.0\"?><Error><Code>NoSuchBucket</Code><Message>The specified bucket\n does not exist</Message><BucketName>x</BucketName></Error>").unwrap();
        assert_eq!(
            (code.as_str(), message.as_str()),
            ("NoSuchBucket", "The specified bucket does not exist")
        );
        assert_eq!(parse_error(b"<Error><Code>no such</Code></Error>"), None);
        assert_eq!(parse_error(b"<html>nope</html>"), None);
        let s3 = place("https://s3.example.com");
        let answer = |status: u16, body: &str| s3.refusal(&Response::new(status, body));
        assert!(matches!(answer(404, ""), PlaceError::Missing(_)));
        assert!(matches!(
            answer(403, "<Error><Code>AccessDenied</Code></Error>"),
            PlaceError::Refused(_)
        ));
        assert!(matches!(
            answer(400, "<Error><Code>InvalidAccessKeyId</Code></Error>"),
            PlaceError::Refused(_)
        ));
        let PlaceError::Failed(words) = answer(
            500,
            "<Error><Code>InternalError</Code><Message>Try again</Message></Error>",
        ) else {
            panic!("a server error is a failure");
        };
        assert_eq!(words, "S3 answered 500 InternalError: Try again");
    }

    /// A small S3 on 127.0.0.1: one bucket, signatures checked with its own secret, objects kept in memory,
    /// listings of two entries a page, `If-None-Match: *` honoured
    struct FakeS3 {
        endpoint: String,
        objects: Arc<Mutex<BTreeMap<String, Vec<u8>>>>,
    }

    struct Asked {
        method: String,
        path: String,
        query: Vec<(String, String)>,
        headers: Vec<(String, String)>,
        body: Vec<u8>,
    }

    impl Asked {
        fn header(&self, name: &str) -> Option<&str> {
            self.headers.iter().find(|(n, _)| n == name).map(|(_, v)| v.as_str())
        }

        fn param(&self, name: &str) -> Option<String> {
            self.query
                .iter()
                .find(|(n, _)| n == name)
                .map(|(_, v)| http::form_decode(v))
        }
    }

    fn read_request(stream: &mut std::net::TcpStream) -> Option<Asked> {
        let mut raw = Vec::new();
        let mut chunk = [0u8; 8192];
        let head_end = loop {
            if let Some(at) = raw.windows(4).position(|w| w == b"\r\n\r\n") {
                break at;
            }
            let read = stream.read(&mut chunk).ok()?;
            if read == 0 {
                return None;
            }
            raw.extend_from_slice(&chunk[..read]);
        };
        let head = String::from_utf8(raw[..head_end].to_vec()).ok()?;
        let mut lines = head.split("\r\n");
        let mut first = lines.next()?.split(' ');
        let method = first.next()?.to_string();
        let target = first.next()?;
        let (path, query) = target.split_once('?').unwrap_or((target, ""));
        let query = query
            .split('&')
            .filter(|p| !p.is_empty())
            .map(|p| {
                let (n, v) = p.split_once('=').unwrap_or((p, ""));
                (n.to_string(), v.to_string())
            })
            .collect();
        let headers: Vec<(String, String)> = lines
            .filter_map(|l| l.split_once(':'))
            .map(|(n, v)| (n.trim().to_ascii_lowercase(), v.trim().to_string()))
            .collect();
        let length: usize = headers
            .iter()
            .find(|(n, _)| n == "content-length")
            .map_or(0, |(_, v)| v.parse().unwrap_or(0));
        let mut body = raw[head_end + 4..].to_vec();
        while body.len() < length {
            let read = stream.read(&mut chunk).ok()?;
            if read == 0 {
                return None;
            }
            body.extend_from_slice(&chunk[..read]);
        }
        Some(Asked {
            method,
            path: path.to_string(),
            query,
            headers,
            body,
        })
    }

    /// Whether the request carries a signature of what was sent, made with `secret`
    fn signed_by(asked: &Asked, secret: &str) -> bool {
        let Some(authorization) = asked.header("authorization") else {
            return false;
        };
        let Some(names) = authorization
            .split("SignedHeaders=")
            .nth(1)
            .and_then(|s| s.split(',').next())
        else {
            return false;
        };
        let headers: Vec<(String, String)> = names
            .split(';')
            .map(|n| (n.to_string(), asked.header(n).unwrap_or_default().to_string()))
            .collect();
        let payload = asked.header("x-amz-content-sha256").unwrap_or_default();
        if payload != hex(digest::digest(&digest::SHA256, &asked.body).as_ref()) {
            return false;
        }
        let signer = Signer {
            access_key: "AKIDTEST",
            secret_key: secret,
            region: "us-east-1",
        };
        let date = asked.header("x-amz-date").unwrap_or_default();
        signer.authorization(&asked.method, &asked.path, &asked.query, &headers, payload, date) == authorization
    }

    fn answer(stream: &mut std::net::TcpStream, status: u16, body: &[u8]) {
        let head = format!(
            "HTTP/1.1 {status} X\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
            body.len()
        );
        let _ = stream.write_all(head.as_bytes());
        let _ = stream.write_all(body);
    }

    fn error(code: &str) -> Vec<u8> {
        format!("<?xml version=\"1.0\"?><Error><Code>{code}</Code><Message>{code}</Message></Error>").into_bytes()
    }

    fn escape(text: &str) -> String {
        text.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;")
    }

    fn listing(objects: &BTreeMap<String, Vec<u8>>, asked: &Asked) -> Vec<u8> {
        let prefix = asked.param("prefix").unwrap_or_default();
        let delimiter = asked.param("delimiter").unwrap_or_default();
        let start: usize = asked.param("continuation-token").map_or(0, |t| t.parse().unwrap());
        let mut entries: Vec<(String, bool)> = Vec::new();
        for key in objects.keys().filter(|k| k.starts_with(&prefix)) {
            let rest = &key[prefix.len()..];
            match rest.find(delimiter.as_str()).filter(|_| !delimiter.is_empty()) {
                Some(at) => entries.push((format!("{prefix}{}", &rest[..at + delimiter.len()]), true)),
                None => entries.push((key.clone(), false)),
            }
        }
        entries.dedup();
        let page: Vec<&(String, bool)> = entries.iter().skip(start).take(2).collect();
        let more = start + 2 < entries.len();
        let mut xml =
            String::from("<?xml version=\"1.0\"?><ListBucketResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">");
        let _ = write!(xml, "<IsTruncated>{more}</IsTruncated>");
        for (name, folder) in page {
            if *folder {
                let _ = write!(
                    xml,
                    "<CommonPrefixes><Prefix>{}</Prefix></CommonPrefixes>",
                    escape(name)
                );
            } else {
                let _ = write!(xml, "<Contents><Key>{}</Key><Size>1</Size></Contents>", escape(name));
            }
        }
        if more {
            let _ = write!(xml, "<NextContinuationToken>{}</NextContinuationToken>", start + 2);
        }
        xml.push_str("</ListBucketResult>");
        xml.into_bytes()
    }

    fn serve(stream: &mut std::net::TcpStream, objects: &Mutex<BTreeMap<String, Vec<u8>>>) {
        let Some(asked) = read_request(stream) else { return };
        if !signed_by(&asked, "secret/key+1") {
            return answer(stream, 403, &error("SignatureDoesNotMatch"));
        }
        let Some(rest) = asked.path.strip_prefix("/vault-bucket") else {
            return answer(stream, 404, &error("NoSuchBucket"));
        };
        let key: Vec<String> = rest.split('/').skip(1).map(http::form_decode).collect();
        let key = key.join("/");
        let mut objects = objects.lock().unwrap();
        match (asked.method.as_str(), key.is_empty()) {
            ("GET", true) if asked.param("list-type").as_deref() == Some("2") => {
                let body = listing(&objects, &asked);
                answer(stream, 200, &body)
            }
            ("GET", false) => match objects.get(&key) {
                Some(bytes) => answer(stream, 200, bytes),
                None => answer(stream, 404, &error("NoSuchKey")),
            },
            ("PUT", false) => {
                if asked.header("if-none-match") == Some("*") && objects.contains_key(&key) {
                    return answer(stream, 412, &error("PreconditionFailed"));
                }
                objects.insert(key, asked.body);
                answer(stream, 200, b"")
            }
            ("DELETE", false) => {
                objects.remove(&key);
                answer(stream, 204, b"")
            }
            _ => answer(stream, 400, &error("InvalidRequest")),
        }
    }

    fn fake_s3() -> FakeS3 {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let endpoint = format!("http://{}", listener.local_addr().unwrap());
        let objects = Arc::new(Mutex::new(BTreeMap::new()));
        let kept = objects.clone();
        std::thread::spawn(move || {
            for stream in listener.incoming() {
                let Ok(mut stream) = stream else { continue };
                serve(&mut stream, &kept);
            }
        });
        FakeS3 { endpoint, objects }
    }

    /// Every operation of a place, as the folder's test does them, on a place that starts empty
    fn exercise(place: &S3) {
        assert!(place.list("devices/a").unwrap().is_empty(), "nothing yet, no error");
        assert!(place.folders("devices").unwrap().is_empty());
        place.write("devices/a/000001", b"one").unwrap();
        place.write("devices/a/000002", b"two").unwrap();
        place.write("devices/a/000003", b"three").unwrap();
        place.write("devices/a/sub/x", b"x").unwrap();
        place.write("devices/a/a b+c&d", b"odd").unwrap();
        place.write("devices/b/head", b"b").unwrap();
        place.write("devices/c d/head", b"c").unwrap();
        assert_eq!(
            place.list("devices/a").unwrap(),
            ["000001", "000002", "000003", "a b+c&d"],
            "every page, without the folder in it"
        );
        assert_eq!(place.folders("devices").unwrap(), ["a", "b", "c d"]);
        assert_eq!(place.folders("devices/a").unwrap(), ["sub"]);
        assert!(place.list("devices").unwrap().is_empty());
        assert_eq!(place.read("devices/a/000002").unwrap().as_deref(), Some(&b"two"[..]));
        assert_eq!(place.read("devices/a/a b+c&d").unwrap().as_deref(), Some(&b"odd"[..]));
        assert_eq!(place.read("devices/a/000009").unwrap(), None);
        place.write("devices/a/000002", b"again").unwrap();
        assert_eq!(place.read("devices/a/000002").unwrap().as_deref(), Some(&b"again"[..]));
        // created only once
        assert!(place.create("lock.json", b"mine").unwrap());
        assert!(!place.create("lock.json", b"theirs").unwrap());
        assert_eq!(place.read("lock.json").unwrap().as_deref(), Some(&b"mine"[..]));
        place.delete("lock.json").unwrap();
        place.delete("lock.json").unwrap();
        assert!(place.create("lock.json", b"theirs").unwrap());
        // never outside the vault
        for bad in ["../x", "devices/../../x", "a\\b", "c:x"] {
            assert!(place.write(bad, b"x").is_err(), "{bad}");
        }
        for path in [
            "lock.json",
            "devices/a/000001",
            "devices/a/000002",
            "devices/a/000003",
            "devices/a/sub/x",
            "devices/a/a b+c&d",
            "devices/b/head",
            "devices/c d/head",
        ] {
            place.delete(path).unwrap();
        }
        assert!(place.folders("").unwrap().is_empty());
    }

    #[test]
    fn every_operation_on_a_bucket() {
        let fake = fake_s3();
        let place = place(&fake.endpoint);
        place.write("devices/a/000001", b"one").unwrap();
        // kept under the prefix, by its name
        assert_eq!(
            fake.objects.lock().unwrap().keys().collect::<Vec<_>>(),
            ["Inbox Classic/vault/devices/a/000001"]
        );
        place.delete("devices/a/000001").unwrap();
        exercise(&place);
        // a bucket at the root too
        exercise(&S3 {
            prefix: String::new(),
            ..place.clone()
        });
    }

    #[test]
    fn refusals_are_told_apart() {
        let fake = fake_s3();
        let wrong_secret = S3 {
            secret_key: "not-it".into(),
            ..place(&fake.endpoint)
        };
        assert!(matches!(wrong_secret.read("x"), Err(PlaceError::Refused(_))));
        assert!(matches!(wrong_secret.list(""), Err(PlaceError::Refused(_))));
        let no_bucket = S3 {
            bucket: "other".into(),
            ..place(&fake.endpoint)
        };
        assert!(matches!(no_bucket.read("x"), Err(PlaceError::Missing(_))));
        assert!(matches!(no_bucket.delete("x"), Err(PlaceError::Missing(_))));
        assert!(matches!(no_bucket.list(""), Err(PlaceError::Missing(_))));
        // nothing listening
        let gone = place("http://127.0.0.1:9");
        assert!(matches!(gone.read("x"), Err(PlaceError::Missing(_))));
        let Err(error) = wrong_secret.write("x", b"x") else {
            panic!("refused")
        };
        assert!(!error.to_string().contains("not-it"), "{error}");
    }

    #[tokio::test(flavor = "multi_thread")]
    async fn works_from_inside_a_runtime() {
        let fake = fake_s3();
        let place = place(&fake.endpoint);
        place.write("a", b"1").unwrap();
        assert_eq!(place.list("").unwrap(), ["a"]);
    }

    /// Against a real server: `PE_S3_TEST_ENDPOINT`, `PE_S3_TEST_REGION`, `PE_S3_TEST_BUCKET`,
    /// `PE_S3_TEST_ACCESS_KEY` and `PE_S3_TEST_SECRET_KEY` (a MinIO at `http://127.0.0.1:9000` will do); the test
    /// works under a prefix of its own and takes away what it wrote
    #[test]
    #[ignore]
    fn a_real_bucket() {
        let var = |name: &str| std::env::var(name).unwrap_or_default();
        let endpoint = var("PE_S3_TEST_ENDPOINT");
        if endpoint.is_empty() {
            eprintln!("PE_S3_TEST_ENDPOINT is not set");
            return;
        }
        let place = S3 {
            endpoint,
            region: var("PE_S3_TEST_REGION"),
            bucket: var("PE_S3_TEST_BUCKET"),
            prefix: format!(
                "pe-s3-test-{}",
                amz_date(SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs())
            ),
            access_key: var("PE_S3_TEST_ACCESS_KEY"),
            secret_key: var("PE_S3_TEST_SECRET_KEY"),
            path_style: true,
        };
        exercise(&place);
    }
}
