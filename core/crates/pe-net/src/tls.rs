//! TLS for IMAP and SMTP: rustls with the ring provider. Certificates are checked against the
//! operating system's trust store ([`Trust::Platform`]), or against certificates the user accepted
//! for a server with a self-signed one ([`Trust::Pinned`]). There is no "accept anything" mode.
//! The certificate a server presented is kept, so a failed handshake can show it to the user, who
//! can then pin it.

use std::fmt;
use std::sync::{Arc, Mutex};

use rustls::client::danger::{HandshakeSignatureValid, ServerCertVerified, ServerCertVerifier};
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

/// A failed handshake, with the certificate the server presented if it got that far
#[derive(Debug)]
pub struct TlsFailure {
    pub message: String,
    pub certificate: Option<Vec<u8>>,
}

fn provider() -> Arc<CryptoProvider> {
    Arc::new(rustls::crypto::ring::default_provider())
}

/// Checks the certificate with `inner` and keeps a copy of it
#[derive(Debug)]
struct Recording {
    inner: Arc<dyn ServerCertVerifier>,
    seen: Arc<Mutex<Option<Vec<u8>>>>,
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
    provider: Arc<CryptoProvider>,
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
        verify_tls12_signature(message, cert, dss, &self.provider.signature_verification_algorithms)
    }

    fn verify_tls13_signature(
        &self,
        message: &[u8],
        cert: &CertificateDer<'_>,
        dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        verify_tls13_signature(message, cert, dss, &self.provider.signature_verification_algorithms)
    }

    fn supported_verify_schemes(&self) -> Vec<SignatureScheme> {
        self.provider.signature_verification_algorithms.supported_schemes()
    }
}

fn config(trust: &Trust, seen: Arc<Mutex<Option<Vec<u8>>>>) -> Result<ClientConfig, rustls::Error> {
    let provider = provider();
    let inner: Arc<dyn ServerCertVerifier> = match trust {
        Trust::Platform => Arc::new(rustls_platform_verifier::Verifier::new(provider.clone())?),
        Trust::Pinned(certificates) => Arc::new(Pinned {
            certificates: certificates.clone(),
            provider: provider.clone(),
        }),
    };
    Ok(ClientConfig::builder_with_provider(provider)
        .with_safe_default_protocol_versions()?
        .dangerous()
        .with_custom_certificate_verifier(Arc::new(Recording { inner, seen }))
        .with_no_client_auth())
}

/// Runs the TLS handshake on a connected socket
pub async fn handshake(socket: TcpStream, host: &str, trust: &Trust) -> Result<TlsStream<TcpStream>, TlsFailure> {
    let seen = Arc::new(Mutex::new(None));
    let failure = |message: String, seen: &Arc<Mutex<Option<Vec<u8>>>>| TlsFailure {
        message,
        certificate: seen.lock().ok().and_then(|mut s| s.take()),
    };
    let config = config(trust, seen.clone()).map_err(|e| failure(e.to_string(), &seen))?;
    let name = ServerName::try_from(host.to_string()).map_err(|e| failure(e.to_string(), &seen))?;
    TlsConnector::from(Arc::new(config))
        .connect(name, socket)
        .await
        .map_err(|e| failure(e.to_string(), &seen))
}
