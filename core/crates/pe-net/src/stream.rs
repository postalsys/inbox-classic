//! A connection to a mail server: plain TCP, or TLS from the start or after STARTTLS.

use std::io;
use std::net::SocketAddr;
use std::time::Duration;

use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio_rustls::client::TlsStream;

use crate::tls::{self, TlsFailure, Trust};

/// How the connection is protected
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Security {
    /// TLS from the start (IMAPS 993, SMTPS 465)
    Tls,
    /// STARTTLS, required: a server that does not offer it is refused
    StartTls,
    /// No encryption, for test servers and servers on the same machine only
    Plain,
}

/// A connection that could not be made or broke
#[derive(Debug)]
pub enum Error {
    Io(io::Error),
    Timeout,
    Tls(TlsFailure),
}

impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Error::Io(error) => write!(f, "connection error: {error}"),
            Error::Timeout => f.write_str("the server did not answer in time"),
            Error::Tls(failure) => write!(f, "TLS error: {}", failure.message),
        }
    }
}

impl std::error::Error for Error {}

impl From<io::Error> for Error {
    fn from(error: io::Error) -> Self {
        Error::Io(error)
    }
}

impl From<TlsFailure> for Error {
    fn from(failure: TlsFailure) -> Self {
        Error::Tls(failure)
    }
}

pub enum Stream {
    Plain(TcpStream),
    Tls(Box<TlsStream<TcpStream>>),
    /// After a failed upgrade or close
    Closed,
}

/// How long one address has to itself before the next one is tried as well (RFC 8305 "Happy Eyeballs")
const NEXT_ADDRESS_AFTER: Duration = Duration::from_millis(250);

/// TCP keepalive: the first probe after this long without traffic, then one every [`KEEPALIVE_INTERVAL`]. Keeps NAT
/// and routers from forgetting a quiet connection, and makes one they forgot fail instead of waiting for ever.
const KEEPALIVE_IDLE: Duration = Duration::from_secs(60);
const KEEPALIVE_INTERVAL: Duration = Duration::from_secs(15);
/// Probes unanswered before the connection is given up, where the system lets it be set
const KEEPALIVE_PROBES: u32 = 4;

/// Turns TCP keepalive on for a connection
fn keep_alive(socket: &TcpStream) -> io::Result<()> {
    let keepalive = socket2::TcpKeepalive::new()
        .with_time(KEEPALIVE_IDLE)
        .with_interval(KEEPALIVE_INTERVAL);
    // Windows sends 10 probes, and does not let the count be set
    #[cfg(any(target_os = "linux", target_os = "macos"))]
    let keepalive = keepalive.with_retries(KEEPALIVE_PROBES);
    socket2::SockRef::from(socket).set_tcp_keepalive(&keepalive)
}

/// The addresses in the order to try them: IPv6 and IPv4 by turns, starting with the family the resolver put first, so
/// a family that does not work on this network costs one short head start, not the whole timeout
fn interleaved(addresses: Vec<SocketAddr>) -> Vec<SocketAddr> {
    let first_v6 = addresses.first().is_some_and(SocketAddr::is_ipv6);
    let (mut first, mut second): (Vec<SocketAddr>, Vec<SocketAddr>) =
        addresses.into_iter().partition(|a| a.is_ipv6() == first_v6);
    first.reverse();
    second.reverse();
    let mut ordered = Vec::with_capacity(first.len() + second.len());
    while !first.is_empty() || !second.is_empty() {
        ordered.extend(first.pop());
        ordered.extend(second.pop());
    }
    ordered
}

/// A TCP connection to the first address of `host` that answers: each next one is tried when the one before failed
/// or did not answer within [`NEXT_ADDRESS_AFTER`], the others are dropped once one connects
async fn connect_any(host: &str, port: u16) -> io::Result<TcpStream> {
    let addresses = interleaved(tokio::net::lookup_host((host, port)).await?.collect());
    let mut pending = addresses.into_iter().peekable();
    let mut attempts = tokio::task::JoinSet::new();
    let mut last_error = None;
    loop {
        if let Some(address) = pending.next() {
            attempts.spawn(TcpStream::connect(address));
        }
        if attempts.is_empty() {
            return Err(
                last_error.unwrap_or_else(|| io::Error::new(io::ErrorKind::NotFound, "no address for the host"))
            );
        }
        let more = pending.peek().is_some();
        tokio::select! {
            Some(done) = attempts.join_next() => match done {
                Ok(Ok(socket)) => return Ok(socket),
                // a refused or unreachable address: the next one starts now
                Ok(Err(error)) => last_error = Some(error),
                Err(error) => last_error = Some(io::Error::other(error.to_string())),
            },
            _ = tokio::time::sleep(NEXT_ADDRESS_AFTER), if more => {}
        }
    }
}

impl Stream {
    /// Connects to `host:port`, with TLS for [`Security::Tls`]
    pub async fn connect(
        host: &str,
        port: u16,
        security: Security,
        trust: &Trust,
        timeout: Duration,
    ) -> Result<Stream, Error> {
        let connect = async {
            let socket = connect_any(host, port).await?;
            socket.set_nodelay(true)?;
            keep_alive(&socket)?;
            match security {
                Security::Tls => Ok(Stream::Tls(Box::new(tls::handshake(socket, host, trust).await?))),
                Security::StartTls | Security::Plain => Ok(Stream::Plain(socket)),
            }
        };
        tokio::time::timeout(timeout, connect)
            .await
            .map_err(|_| Error::Timeout)?
    }

    /// Runs the TLS handshake on a plain connection, after the server agreed to STARTTLS
    pub async fn upgrade(&mut self, host: &str, trust: &Trust) -> Result<(), Error> {
        let Stream::Plain(socket) = std::mem::replace(self, Stream::Closed) else {
            return Err(Error::Io(io::Error::new(
                io::ErrorKind::NotConnected,
                "the connection is not a plain one",
            )));
        };
        *self = Stream::Tls(Box::new(tls::handshake(socket, host, trust).await?));
        Ok(())
    }

    pub fn is_tls(&self) -> bool {
        matches!(self, Stream::Tls(_))
    }

    /// Reads what is there, 0 at the end of the connection. Cancel safe.
    pub async fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        match self {
            Stream::Plain(socket) => socket.read(buf).await,
            Stream::Tls(tls) => tls.read(buf).await,
            Stream::Closed => Ok(0),
        }
    }

    pub async fn write_all(&mut self, data: &[u8]) -> io::Result<()> {
        match self {
            Stream::Plain(socket) => {
                socket.write_all(data).await?;
                socket.flush().await
            }
            Stream::Tls(tls) => {
                tls.write_all(data).await?;
                tls.flush().await
            }
            Stream::Closed => Err(io::Error::new(io::ErrorKind::NotConnected, "connection closed")),
        }
    }

    pub async fn shutdown(&mut self) {
        let _ = match self {
            Stream::Plain(socket) => socket.shutdown().await,
            Stream::Tls(tls) => tls.shutdown().await,
            Stream::Closed => Ok(()),
        };
        *self = Stream::Closed;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn connections_are_kept_alive() {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let port = listener.local_addr().unwrap().port();
        let socket = connect_any("127.0.0.1", port).await.unwrap();
        keep_alive(&socket).unwrap();
        let sock = socket2::SockRef::from(&socket);
        assert!(sock.keepalive().unwrap());
        #[cfg(any(target_os = "linux", target_os = "macos"))]
        {
            assert_eq!(sock.tcp_keepalive_time().unwrap(), KEEPALIVE_IDLE);
            assert_eq!(sock.tcp_keepalive_interval().unwrap(), KEEPALIVE_INTERVAL);
        }
    }

    #[test]
    fn addresses_take_turns_by_family() {
        let a = |s: &str| s.parse::<SocketAddr>().unwrap();
        let ordered = interleaved(vec![
            a("[::1]:1"),
            a("[::2]:1"),
            a("[::3]:1"),
            a("10.0.0.1:1"),
            a("10.0.0.2:1"),
        ]);
        assert_eq!(
            ordered,
            [
                a("[::1]:1"),
                a("10.0.0.1:1"),
                a("[::2]:1"),
                a("10.0.0.2:1"),
                a("[::3]:1")
            ]
        );
        assert_eq!(
            interleaved(vec![a("10.0.0.1:1"), a("[::1]:1")]),
            [a("10.0.0.1:1"), a("[::1]:1")]
        );
        assert!(interleaved(Vec::new()).is_empty());
    }

    /// `localhost` is ::1 and 127.0.0.1: with a server on 127.0.0.1 only, the refused ::1 does not stop the connection
    #[tokio::test]
    async fn the_next_address_when_one_does_not_answer() {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let port = listener.local_addr().unwrap().port();
        let connected = connect_any("localhost", port).await.unwrap();
        assert!(connected.peer_addr().unwrap().is_ipv4());
        // nothing listening anywhere: the last error
        drop(listener);
        assert!(connect_any("127.0.0.1", port).await.is_err());
    }
}
