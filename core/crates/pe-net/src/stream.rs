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

#[derive(Debug)]
pub enum ConnectError {
    Io(io::Error),
    Timeout,
    Tls(TlsFailure),
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
    ) -> Result<Stream, ConnectError> {
        let connect = async {
            let socket = TcpStream::connect((host, port)).await.map_err(ConnectError::Io)?;
            socket.set_nodelay(true).map_err(ConnectError::Io)?;
            match security {
                Security::Tls => tls::handshake(socket, host, trust)
                    .await
                    .map(|tls| Stream::Tls(Box::new(tls)))
                    .map_err(ConnectError::Tls),
                Security::StartTls | Security::Plain => Ok(Stream::Plain(socket)),
            }
        };
        tokio::time::timeout(timeout, connect)
            .await
            .map_err(|_| ConnectError::Timeout)?
    }

    /// Runs the TLS handshake on a plain connection, after the server agreed to STARTTLS
    pub async fn upgrade(&mut self, host: &str, trust: &Trust) -> Result<(), TlsFailure> {
        let Stream::Plain(socket) = std::mem::replace(self, Stream::Closed) else {
            return Err(TlsFailure {
                message: "the connection is not a plain one".into(),
                certificate: None,
            });
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
