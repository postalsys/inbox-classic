//! The built-in Google client against Google itself, with PE_NETWORK_TESTS=1 (the Linux CI job sets it): a made-up
//! refresh token is refused as a grant (`invalid_grant`), which Google only says after it accepted the client ID and
//! its Desktop App secret (a wrong pair is `invalid_client`)

use pe_oauth::{OAuthError, Provider, ProviderKind, refresh};

fn enabled() -> bool {
    std::env::var_os("PE_NETWORK_TESTS").is_some_and(|v| v == "1")
}

#[tokio::test]
async fn google_accepts_the_built_in_client() {
    if !enabled() {
        return;
    }
    let google = Provider::builtin(ProviderKind::Google).expect("the Google client is built in");
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
