//! What a lookup reads from the network, behind a trait so tests answer in its place

use std::pin::Pin;
use std::task::Poll;
use std::time::Duration;

use pe_net::http::{HttpError, Method, Request, Response};

use crate::dns::{self, MxRecord, SrvRecord};

/// The largest document read: a configuration file or an autodiscover response is a few kilobytes, and the host
/// that serves it is named by the address, so its size is not ours to trust
pub const MAX_BODY: usize = 256 * 1024;

/// A request a lookup makes
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HttpRequest {
    pub method: Method,
    pub url: String,
    pub headers: Vec<(String, String)>,
    pub body: Vec<u8>,
}

impl HttpRequest {
    pub fn get(url: impl Into<String>) -> HttpRequest {
        HttpRequest {
            method: Method::Get,
            url: url.into(),
            headers: Vec::new(),
            body: Vec::new(),
        }
    }

    /// The value of the header field `name`, compared without case
    pub fn header(&self, name: &str) -> Option<&str> {
        self.headers
            .iter()
            .find(|(n, _)| n.eq_ignore_ascii_case(name))
            .map(|(_, v)| v.as_str())
    }
}

/// The network as a lookup sees it: HTTP requests that are not redirected, and MX and SRV records. The records
/// come over DNS-over-HTTPS through [`Io::http`] unless an implementation answers them itself.
pub trait Io: Sync {
    fn http(&self, request: HttpRequest) -> impl Future<Output = Result<Response, HttpError>> + Send;

    /// The MX records of `domain`, lowest priority first
    fn mx(&self, domain: &str) -> impl Future<Output = Vec<MxRecord>> + Send {
        async move { dns::doh_mx(self, domain).await }
    }

    /// The SRV records of `name`, lowest priority first
    fn srv(&self, name: &str) -> impl Future<Output = Vec<SrvRecord>> + Send {
        async move { dns::doh_srv(self, name).await }
    }
}

/// The real network, through pe-net: HTTPS with the platform's certificates; plain HTTP only for a URL that says
/// so, and never with credentials (pe-net refuses an `Authorization` header there)
#[derive(Debug, Clone, Copy)]
pub struct NetIo {
    /// The time one request may take
    pub timeout: Duration,
}

impl Io for NetIo {
    fn http(&self, request: HttpRequest) -> impl Future<Output = Result<Response, HttpError>> + Send {
        let timeout = self.timeout;
        async move {
            let headers: Vec<(&str, &str)> = request.headers.iter().map(|(n, v)| (n.as_str(), v.as_str())).collect();
            pe_net::http::send(Request {
                method: request.method,
                url: &request.url,
                headers: &headers,
                body: &request.body,
                timeout,
                max_response: MAX_BODY,
                plain_http: request.url.starts_with("http://"),
            })
            .await
        }
    }
}

pub(crate) type BoxFuture<'a, T> = Pin<Box<dyn Future<Output = T> + Send + 'a>>;

/// The first of `futures` to end with Some, the others dropped (which cancels their requests); None when all end
/// with None. When several are ready at once, the earlier one in the list wins.
pub(crate) async fn first_some<T>(mut futures: Vec<BoxFuture<'_, Option<T>>>) -> Option<T> {
    std::future::poll_fn(move |cx| {
        let mut i = 0;
        while i < futures.len() {
            match futures[i].as_mut().poll(cx) {
                Poll::Ready(Some(value)) => return Poll::Ready(Some(value)),
                Poll::Ready(None) => {
                    drop(futures.remove(i));
                }
                Poll::Pending => i += 1,
            }
        }
        if futures.is_empty() {
            Poll::Ready(None)
        } else {
            Poll::Pending
        }
    })
    .await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn the_first_answer_wins() {
        let slow: BoxFuture<Option<u8>> = Box::pin(async {
            tokio::time::sleep(Duration::from_secs(60)).await;
            Some(1)
        });
        let empty: BoxFuture<Option<u8>> = Box::pin(async { None });
        let soon: BoxFuture<Option<u8>> = Box::pin(async {
            tokio::task::yield_now().await;
            Some(3)
        });
        assert_eq!(first_some(vec![slow, empty, soon]).await, Some(3));
        // ready at once: the earlier one
        let a: BoxFuture<Option<u8>> = Box::pin(async { Some(1) });
        let b: BoxFuture<Option<u8>> = Box::pin(async { Some(2) });
        assert_eq!(first_some(vec![a, b]).await, Some(1));
        let none: Vec<BoxFuture<Option<u8>>> = vec![Box::pin(async { None }), Box::pin(async { None })];
        assert_eq!(first_some(none).await, None);
        assert_eq!(first_some::<u8>(vec![]).await, None);
    }
}
