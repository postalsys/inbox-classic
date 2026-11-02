//! A connection to a mail server: plain TCP, or TLS from the start or after STARTTLS.

use std::io;
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
            let socket = TcpStream::connect((host, port)).await?;
            socket.set_nodelay(true)?;
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
