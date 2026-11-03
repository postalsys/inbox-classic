//! OpenID Connect Discovery 1.0: where an issuer's sign-in page and token endpoint are, read from its
//! `/.well-known/openid-configuration` document when a sign-in app is saved.

use std::time::Duration;

use pe_net::http;
use serde_json::Value;

const DISCOVERY_TIMEOUT: Duration = Duration::from_secs(20);

/// What an issuer's discovery document says about signing in
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Discovered {
    pub authorize_url: String,
    pub token_url: String,
    /// The `iss` the issuer puts in its redirects (RFC 9207), when it says it does
    pub response_issuer: Option<String>,
}

/// The issuer as entered, checked and without a trailing slash: `https://`, or `http://` to 127.0.0.1 or
/// localhost (a provider on this computer, as a test server), with no query or fragment
pub fn issuer(entered: &str) -> Result<String, String> {
    let issuer = entered.trim().trim_end_matches('/');
    if issuer.contains(['?', '#']) || http::parse_url(issuer).is_none() {
        return Err(format!(
            "the issuer has to be an https:// address without a query, not \"{issuer}\""
        ));
    }
    Ok(issuer.to_string())
}

/// Reads the discovery document of `issuer` (checked with [`issuer`])
pub async fn discover(issuer: &str) -> Result<Discovered, String> {
    let url = format!("{issuer}/.well-known/openid-configuration");
    let response = http::get(&url, DISCOVERY_TIMEOUT)
        .await
        .map_err(|error| format!("{url}: {error}"))?;
    if response.status != 200 {
        return Err(format!(
            "{url} answered with HTTP {}: is the issuer right?",
            response.status
        ));
    }
    parse_discovery(issuer, &response.body)
}

/// The discovery document `body` of `issuer`, checked: it is for this issuer, its endpoints are https (or on this
/// computer, as the issuer may be), and it does not rule out PKCE with S256
pub fn parse_discovery(issuer: &str, body: &[u8]) -> Result<Discovered, String> {
    let document: Value = serde_json::from_slice(body).map_err(|_| "the discovery document is not JSON".to_string())?;
    let text = |key: &str| document.get(key).and_then(Value::as_str).map(str::trim);
    let named = text("issuer").unwrap_or_default();
    if !same_issuer(issuer, named) {
        return Err(format!("the discovery document is for another issuer, \"{named}\""));
    }
    let endpoint = |key: &str| {
        text(key)
            .filter(|url| http::parse_url(url).is_some() && !url.contains('#'))
            .filter(|url| url.starts_with("https://") || !issuer.starts_with("https://"))
            .map(str::to_string)
            .ok_or_else(|| format!("the discovery document has no usable {key}"))
    };
    let authorize_url = endpoint("authorization_endpoint")?;
    let token_url = endpoint("token_endpoint")?;
    let listed = |key: &str, value: &str| {
        document
            .get(key)
            .and_then(Value::as_array)
            .map(|values| values.iter().any(|v| v.as_str() == Some(value)))
    };
    // Microsoft lists no methods but takes S256; an issuer that lists them without it does not
    if listed("code_challenge_methods_supported", "S256") == Some(false) {
        return Err("the issuer does not support PKCE with S256, which Inbox Classic needs".into());
    }
    if listed("response_types_supported", "code") == Some(false) {
        return Err("the issuer does not support the authorization code flow".into());
    }
    let sends_issuer = document
        .get("authorization_response_iss_parameter_supported")
        .and_then(Value::as_bool)
        == Some(true);
    Ok(Discovered {
        authorize_url,
        token_url,
        response_issuer: sends_issuer.then(|| named.to_string()),
    })
}

/// The tenant of a Microsoft Entra issuer, `https://login.microsoftonline.com/<tenant>/v2.0`
fn microsoft_tenant(issuer: &str) -> Option<&str> {
    issuer
        .strip_prefix("https://login.microsoftonline.com/")
        .and_then(|rest| rest.strip_suffix("/v2.0"))
        .filter(|tenant| !tenant.is_empty() && !tenant.contains('/'))
}

/// Whether the discovery document's issuer is the one entered. Microsoft's multi-tenant authorities (`common`,
/// `organizations`, `consumers`) name a tenant in its place: `https://login.microsoftonline.com/{tenantid}/v2.0`,
/// or the tenant of personal accounts.
fn same_issuer(entered: &str, named: &str) -> bool {
    let named = named.trim_end_matches('/');
    if named == entered {
        return true;
    }
    matches!(
        (microsoft_tenant(entered), microsoft_tenant(named)),
        (Some("common" | "organizations" | "consumers"), Some(_))
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn issuers() {
        assert_eq!(
            issuer(" https://accounts.google.com/ ").unwrap(),
            "https://accounts.google.com"
        );
        assert_eq!(issuer("http://127.0.0.1:8085").unwrap(), "http://127.0.0.1:8085");
        for refused in [
            "http://login.example.com",
            "ftp://x",
            "accounts.google.com",
            "https://x.example/?a=b",
            "https://x.example/#f",
            "",
        ] {
            assert!(issuer(refused).is_err(), "{refused}");
        }
    }

    #[test]
    fn google_document() {
        let found = parse_discovery(
            "https://accounts.google.com",
            br#"{"issuer":"https://accounts.google.com","authorization_endpoint":"https://accounts.google.com/o/oauth2/v2/auth","token_endpoint":"https://oauth2.googleapis.com/token","code_challenge_methods_supported":["plain","S256"],"response_types_supported":["code","token"]}"#,
        )
        .unwrap();
        assert_eq!(
            found,
            Discovered {
                authorize_url: "https://accounts.google.com/o/oauth2/v2/auth".into(),
                token_url: "https://oauth2.googleapis.com/token".into(),
                response_issuer: None,
            }
        );
    }

    #[test]
    fn microsoft_tenant_templates() {
        let document = |issuer: &str| {
            format!(
                r#"{{"issuer":"{issuer}","authorization_endpoint":"https://login.microsoftonline.com/common/oauth2/v2.0/authorize","token_endpoint":"https://login.microsoftonline.com/common/oauth2/v2.0/token"}}"#
            )
        };
        let common = "https://login.microsoftonline.com/common/v2.0";
        for named in [
            "https://login.microsoftonline.com/{tenantid}/v2.0",
            "https://login.microsoftonline.com/9188040d-6c67-4c5b-b112-36a304b66dad/v2.0",
        ] {
            assert!(parse_discovery(common, document(named).as_bytes()).is_ok(), "{named}");
        }
        // a tenant of its own has to match exactly
        let tenant = "https://login.microsoftonline.com/contoso.example/v2.0";
        assert!(parse_discovery(tenant, document(tenant).as_bytes()).is_ok());
        assert!(
            parse_discovery(
                tenant,
                document("https://login.microsoftonline.com/other/v2.0").as_bytes()
            )
            .is_err()
        );
        assert!(parse_discovery(common, document("https://evil.example/{tenantid}/v2.0").as_bytes()).is_err());
    }

    #[test]
    fn refused_documents() {
        let issuer = "https://login.example.com";
        let with = |extra: &str| {
            format!(
                r#"{{"issuer":"https://login.example.com","authorization_endpoint":"https://login.example.com/authorize","token_endpoint":"https://login.example.com/token"{extra}}}"#
            )
        };
        assert!(parse_discovery(issuer, with("").as_bytes()).is_ok());
        let refusals = [
            (r#","code_challenge_methods_supported":["plain"]"#, "PKCE"),
            (r#","response_types_supported":["token"]"#, "authorization code"),
        ];
        for (extra, reason) in refusals {
            let error = parse_discovery(issuer, with(extra).as_bytes()).unwrap_err();
            assert!(error.contains(reason), "{error}");
        }
        // endpoints that are not https from an https issuer
        let plain = r#"{"issuer":"https://login.example.com","authorization_endpoint":"http://127.0.0.1/authorize","token_endpoint":"https://login.example.com/token"}"#;
        assert!(
            parse_discovery(issuer, plain.as_bytes())
                .unwrap_err()
                .contains("authorization_endpoint")
        );
        let missing =
            r#"{"issuer":"https://login.example.com","authorization_endpoint":"https://login.example.com/a"}"#;
        assert!(
            parse_discovery(issuer, missing.as_bytes())
                .unwrap_err()
                .contains("token_endpoint")
        );
        assert!(parse_discovery(issuer, b"<html>").is_err());
        let other = with("").replace(
            "\"issuer\":\"https://login.example.com\"",
            "\"issuer\":\"https://other.example\"",
        );
        assert!(
            parse_discovery(issuer, other.as_bytes())
                .unwrap_err()
                .contains("another issuer")
        );
    }

    #[test]
    fn test_server_on_this_computer() {
        // ImapKit's provider: plain http on the loopback address, and iss in its redirects
        let issuer = "http://127.0.0.1:8085";
        let found = parse_discovery(
            issuer,
            br#"{"issuer":"http://127.0.0.1:8085","authorization_endpoint":"http://127.0.0.1:8085/authorize","token_endpoint":"http://127.0.0.1:8085/token","code_challenge_methods_supported":["S256"],"authorization_response_iss_parameter_supported":true}"#,
        )
        .unwrap();
        assert_eq!(found.response_issuer.as_deref(), Some(issuer));
        assert_eq!(found.token_url, "http://127.0.0.1:8085/token");
    }
}
