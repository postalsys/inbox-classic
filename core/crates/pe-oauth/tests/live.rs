//! The built-in clients against Google and Microsoft themselves, with PE_NETWORK_TESTS=1 (the Linux CI job sets it):
//! a made-up refresh token is refused as a grant (`invalid_grant`), which each says only for a client it knows (and,
//! for Google, with its Desktop App secret); an unknown client is `invalid_client` or `unauthorized_client`

use pe_oauth::{OAuthError, Provider, ProviderKind, refresh};

fn enabled() -> bool {
    std::env::var_os("PE_NETWORK_TESTS").is_some_and(|v| v == "1")
}

#[tokio::test]
async fn google_accepts_the_built_in_client() {
    if !enabled() {
        return;
    }
    let google = Provider::builtin(ProviderKind::Google);
    match refresh(&google, "made-up-refresh-token").await {
        Err(OAuthError::Refused(reason)) => {
            assert!(
                reason.contains("invalid_grant") && !reason.contains("invalid_client"),
                "{reason}"
            );
        }
        other => panic!("expected the grant refused, got {other:?}"),
    }
}

#[tokio::test]
async fn microsoft_accepts_the_built_in_client() {
    if !enabled() {
        return;
    }
    let microsoft = Provider::builtin(ProviderKind::Microsoft);
    match refresh(&microsoft, "made-up-refresh-token").await {
        Err(OAuthError::Refused(reason)) => {
            assert!(
                reason.contains("invalid_grant")
                    && !reason.contains("invalid_client")
                    && !reason.contains("unauthorized_client"),
                "{reason}"
            );
        }
        other => panic!("expected the grant refused, got {other:?}"),
    }
}
