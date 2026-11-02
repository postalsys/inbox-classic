//! The resolvers and their order, as in EmailEngine (`resolver` in lib/autodetect-imap-settings.js): the mail
//! exchange first; when it is not a known one, SRV records, the provider's file at two places, the ISPDB and
//! Autodiscover race, each with its own time budget, and the first that names a server wins.

use std::time::Duration;

use crate::autodiscover;
use crate::config::parse_partial;
use crate::io::{BoxFuture, HttpRequest, Io, first_some};
use crate::mx::{Delegate, delegate};
use crate::{Credentials, Discovered, Server, ServerSecurity, Source, lookup_urls, provider_url};

/// The servers of the SRV records of `domain` (RFC 6186): `_imaps`, else `_imap`; `_submissions`, else
/// `_submission`. IMAP and SMTP are looked up at once. A record without TLS is STARTTLS (there is no server without
/// encryption), and `_submission` on port 465 is implicit TLS, as some providers publish it.
pub(crate) async fn srv<I: Io>(io: &I, domain: &str) -> Discovered {
    let lookup = |prefix: &str| {
        let name = format!("{prefix}._tcp.{domain}");
        async move { io.srv(&name).await.into_iter().next() }
    };
    let server = |record: crate::dns::SrvRecord, security| Server {
        host: record.target,
        port: record.port,
        security,
    };
    let imap = async {
        if let Some(record) = lookup("_imaps").await {
            return Some(server(record, ServerSecurity::Tls));
        }
        let record = lookup("_imap").await?;
        Some(server(record, ServerSecurity::StartTls))
    };
    let smtp = async {
        if let Some(record) = lookup("_submissions").await {
            return Some(server(record, ServerSecurity::Tls));
        }
        let record = lookup("_submission").await?;
        let security = if record.port == 465 {
            ServerSecurity::Tls
        } else {
            ServerSecurity::StartTls
        };
        Some(server(record, security))
    };
    let (imap, smtp) = tokio::join!(imap, smtp);
    Discovered {
        imap,
        smtp,
        username: None,
        oauth2: false,
    }
}

/// A configuration file at `url`; `%EMAILDOMAIN%` as a host name is `domain`
async fn config_file<I: Io>(io: &I, url: String, email: &str, domain: &str) -> Option<Discovered> {
    let response = io.http(HttpRequest::get(url)).await.ok()?;
    if response.status != 200 {
        return None;
    }
    parse_partial(std::str::from_utf8(&response.body).ok()?, email, domain)
}

/// What a known exchange says, for `email`
async fn from_exchange<I: Io>(io: &I, email: &str, exchange: &str) -> Option<Discovered> {
    match delegate(exchange)? {
        Delegate::Servers(found) => Some(found),
        Delegate::Srv { domain, oauth2 } => Some(Discovered {
            oauth2,
            ..srv(io, domain).await
        }),
        Delegate::Autoconfig(domain) => config_file(io, provider_url(email, domain), email, domain).await,
    }
}

/// The lowest exchange of `domain`, and the servers it says, within `budget`
pub(crate) async fn by_mx<I: Io>(
    io: &I,
    email: &str,
    domain: &str,
    budget: Duration,
) -> (Option<String>, Option<Discovered>) {
    let started = tokio::time::Instant::now();
    let Ok(records) = tokio::time::timeout(budget, io.mx(domain)).await else {
        return (None, None);
    };
    let Some(exchange) = records.into_iter().min_by_key(|r| r.priority).map(|r| r.exchange) else {
        return (None, None);
    };
    let left = budget.saturating_sub(started.elapsed());
    let found = tokio::time::timeout(left, from_exchange(io, email, &exchange))
        .await
        .ok()
        .flatten()
        .filter(Discovered::names_host);
    (Some(exchange), found)
}

/// A resolver that has `budget` to name a server
fn timed<'a>(
    source: Source,
    budget: Duration,
    lookup: impl Future<Output = Option<Discovered>> + Send + 'a,
) -> BoxFuture<'a, Option<(Source, Discovered)>> {
    Box::pin(async move {
        let found = tokio::time::timeout(budget, lookup).await.ok().flatten()?;
        found.names_host().then_some((source, found))
    })
}

/// SRV, the file at `/.well-known`, the file at `autoconfig.<domain>`, the ISPDB and Autodiscover at once; the first
/// that names a server, the earlier in this order on a tie
pub(crate) async fn race<I: Io>(
    io: &I,
    email: &str,
    domain: &str,
    credentials: Option<&Credentials>,
    budget: Duration,
) -> Option<(Source, Discovered)> {
    let mut lookups = vec![timed(Source::Srv, budget, async { Some(srv(io, domain).await) })];
    lookups.extend(
        lookup_urls(email, domain).map(|(source, url)| timed(source, budget, config_file(io, url, email, domain))),
    );
    lookups.push(timed(
        Source::Autodiscover,
        budget,
        autodiscover::resolve(io, email, domain, credentials),
    ));
    first_some(lookups).await
}
