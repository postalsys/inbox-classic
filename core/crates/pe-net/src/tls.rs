//! TLS for IMAP and SMTP: rustls with the ring provider. Certificates are checked against the
//! operating system's trust store ([`Trust::Platform`]), or against certificates the user accepted
//! for a server with a self-signed one ([`Trust::Pinned`]). There is no "accept anything" mode.
//! The certificate a server presented is kept, so a failed handshake can show it to the user, who
//! can then pin it.

use std::fmt;
use std::sync::{Arc, Mutex, OnceLock};

use rustls::client::danger::{HandshakeSignatureValid, ServerCertVerified, ServerCertVerifier};
use rustls::client::{ClientSessionMemoryCache, Resumption};
use rustls::crypto::{CryptoProvider, verify_tls12_signature, verify_tls13_signature};
use rustls::pki_types::{CertificateDer, ServerName, UnixTime};
use rustls::{CertificateError, ClientConfig, DigitallySignedStruct, SignatureScheme};
use tokio::net::TcpStream;
use tokio_rustls::TlsConnector;
use tokio_rustls::client::TlsStream;

/// Which server certificates are accepted
#[derive(Clone, PartialEq, Eq, Default)]
pub enum Trust {
    /// Certificates the operating system trusts, for the host name connected to
    #[default]
    Platform,
    /// Exactly these certificates (DER), whatever their issuer or host name: a self-signed
    /// certificate the user accepted
    Pinned(Vec<Vec<u8>>),
}

impl fmt::Debug for Trust {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Trust::Platform => f.write_str("Platform"),
            Trust::Pinned(certs) => write!(f, "Pinned({} certificates)", certs.len()),
        }
    }
}

/// Why a handshake failed, for what the user is offered
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TlsFailureKind {
    /// Not trusted by the system (self-signed, unknown CA, refused by its policy): the user can
    /// pin it
    Untrusted,
    /// Issued for another host name
    WrongHost,
    /// Expired or not valid yet
    Expired,
    Other,
}

/// A failed handshake, with the certificate the server presented if it got that far
#[derive(Debug)]
pub struct TlsFailure {
    pub kind: TlsFailureKind,
    pub message: String,
    pub certificate: Option<Vec<u8>>,
}

/// The certificate a server presented during one handshake
type SeenCertificate = Arc<Mutex<Option<Vec<u8>>>>;

/// Built once: the platform verifier loads the system roots, and the session cache lets later
/// connections resume
fn provider() -> &'static Arc<CryptoProvider> {
    static PROVIDER: OnceLock<Arc<CryptoProvider>> = OnceLock::new();
    PROVIDER.get_or_init(|| Arc::new(rustls::crypto::ring::default_provider()))
}

fn platform_verifier() -> Result<Arc<dyn ServerCertVerifier>, rustls::Error> {
    static VERIFIER: OnceLock<Arc<dyn ServerCertVerifier>> = OnceLock::new();
    if let Some(verifier) = VERIFIER.get() {
        return Ok(verifier.clone());
    }
    let verifier: Arc<dyn ServerCertVerifier> = Arc::new(rustls_platform_verifier::Verifier::new(provider().clone())?);
    Ok(VERIFIER.get_or_init(|| verifier).clone())
}

fn resumption() -> Resumption {
    static CACHE: OnceLock<Arc<ClientSessionMemoryCache>> = OnceLock::new();
    Resumption::store(
        CACHE
            .get_or_init(|| Arc::new(ClientSessionMemoryCache::new(256)))
            .clone(),
    )
}

/// Checks the certificate with `inner` and keeps a copy of it
#[derive(Debug)]
struct Recording {
    inner: Arc<dyn ServerCertVerifier>,
    seen: SeenCertificate,
}

impl ServerCertVerifier for Recording {
    fn verify_server_cert(
        &self,
        end_entity: &CertificateDer<'_>,
        intermediates: &[CertificateDer<'_>],
        server_name: &ServerName<'_>,
        ocsp_response: &[u8],
        now: UnixTime,
    ) -> Result<ServerCertVerified, rustls::Error> {
        if let Ok(mut seen) = self.seen.lock() {
            *seen = Some(end_entity.to_vec());
        }
        self.inner
            .verify_server_cert(end_entity, intermediates, server_name, ocsp_response, now)
    }

    fn verify_tls12_signature(
        &self,
        message: &[u8],
        cert: &CertificateDer<'_>,
        dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        self.inner.verify_tls12_signature(message, cert, dss)
    }

    fn verify_tls13_signature(
        &self,
        message: &[u8],
        cert: &CertificateDer<'_>,
        dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        self.inner.verify_tls13_signature(message, cert, dss)
    }

    fn supported_verify_schemes(&self) -> Vec<SignatureScheme> {
        self.inner.supported_verify_schemes()
    }
}

/// Accepts exactly the pinned certificates. The handshake signatures are still checked, so the
/// server has to hold the key of the pinned certificate.
#[derive(Debug)]
struct Pinned {
    certificates: Vec<Vec<u8>>,
}

impl ServerCertVerifier for Pinned {
    fn verify_server_cert(
        &self,
        end_entity: &CertificateDer<'_>,
        _intermediates: &[CertificateDer<'_>],
        _server_name: &ServerName<'_>,
        _ocsp_response: &[u8],
        _now: UnixTime,
    ) -> Result<ServerCertVerified, rustls::Error> {
        if self
            .certificates
            .iter()
            .any(|pinned| pinned.as_slice() == end_entity.as_ref())
        {
            Ok(ServerCertVerified::assertion())
        } else {
            Err(rustls::Error::InvalidCertificate(CertificateError::UnknownIssuer))
        }
    }

    fn verify_tls12_signature(
        &self,
        message: &[u8],
        cert: &CertificateDer<'_>,
        dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        verify_tls12_signature(message, cert, dss, &provider().signature_verification_algorithms)
    }

    fn verify_tls13_signature(
        &self,
        message: &[u8],
        cert: &CertificateDer<'_>,
        dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        verify_tls13_signature(message, cert, dss, &provider().signature_verification_algorithms)
    }

    fn supported_verify_schemes(&self) -> Vec<SignatureScheme> {
        provider().signature_verification_algorithms.supported_schemes()
    }
}

fn config(trust: &Trust, seen: SeenCertificate) -> Result<ClientConfig, rustls::Error> {
    let inner: Arc<dyn ServerCertVerifier> = match trust {
        Trust::Platform => platform_verifier()?,
        Trust::Pinned(certificates) => Arc::new(Pinned {
            certificates: certificates.clone(),
        }),
    };
    let mut config = ClientConfig::builder_with_provider(provider().clone())
        .with_safe_default_protocol_versions()?
        .dangerous()
        .with_custom_certificate_verifier(Arc::new(Recording { inner, seen }))
        .with_no_client_auth();
    // a resumed session skips the verifier, so only sessions the platform trusted are resumed:
    // a pinned certificate is checked again on every connection, and stops working once unpinned
    config.resumption = match trust {
        Trust::Platform => resumption(),
        Trust::Pinned(_) => Resumption::disabled(),
    };
    Ok(config)
}

fn kind_of(error: &rustls::Error) -> TlsFailureKind {
    use CertificateError::*;
    match error {
        rustls::Error::InvalidCertificate(certificate) => match certificate {
            NotValidForName | NotValidForNameContext { .. } => TlsFailureKind::WrongHost,
            Expired | ExpiredContext { .. } | NotValidYet | NotValidYetContext { .. } => TlsFailureKind::Expired,
            // a revoked or broken certificate is not one to accept
            Revoked | BadEncoding => TlsFailureKind::Other,
            // anything else the trust store refused (unknown issuer, self-signed, a policy of the
            // platform such as macOS refusing long lived certificates): the user may pin it
            _ => TlsFailureKind::Untrusted,
        },
        _ => TlsFailureKind::Other,
    }
}

/// Runs the TLS handshake on a connected socket
pub async fn handshake(socket: TcpStream, host: &str, trust: &Trust) -> Result<TlsStream<TcpStream>, TlsFailure> {
    let seen = SeenCertificate::default();
    let failure = |kind: TlsFailureKind, message: String| TlsFailure {
        kind,
        message,
        certificate: seen.lock().ok().and_then(|mut s| s.take()),
    };
    let config = config(trust, seen.clone()).map_err(|e| failure(kind_of(&e), e.to_string()))?;
    let name = ServerName::try_from(host.to_string()).map_err(|e| failure(TlsFailureKind::Other, e.to_string()))?;
    TlsConnector::from(Arc::new(config))
        .connect(name, socket)
        .await
        .map_err(|error| {
            let kind = error
                .get_ref()
                .and_then(|inner| inner.downcast_ref::<rustls::Error>())
                .map_or(TlsFailureKind::Other, kind_of);
            failure(kind, error.to_string())
        })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn classifies_certificate_errors() {
        let kind = |e| kind_of(&rustls::Error::InvalidCertificate(e));
        assert_eq!(kind(CertificateError::UnknownIssuer), TlsFailureKind::Untrusted);
        assert_eq!(kind(CertificateError::NotValidForName), TlsFailureKind::WrongHost);
        assert_eq!(kind(CertificateError::Expired), TlsFailureKind::Expired);
        assert_eq!(kind(CertificateError::Revoked), TlsFailureKind::Other);
        assert_eq!(
            kind(CertificateError::ApplicationVerificationFailure),
            TlsFailureKind::Untrusted
        );
        assert_eq!(kind_of(&rustls::Error::HandshakeNotComplete), TlsFailureKind::Other);
    }
}
