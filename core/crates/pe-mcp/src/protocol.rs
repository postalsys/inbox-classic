//! JSON-RPC 2.0 as MCP's stdio transport has it: one message per line, UTF-8, no batches.

use serde_json::{Value, json};
use tokio::io::{AsyncBufRead, AsyncBufReadExt, AsyncWrite, AsyncWriteExt};

/// The longest line read: a request is small, and a line without an end must not take the memory
pub(crate) const MAX_LINE: usize = 4 * 1024 * 1024;

pub(crate) const PARSE_ERROR: i64 = -32700;
pub(crate) const INVALID_REQUEST: i64 = -32600;
pub(crate) const METHOD_NOT_FOUND: i64 = -32601;
pub(crate) const INVALID_PARAMS: i64 = -32602;
/// The user turned the program away, agents are off, or the user has not answered yet
pub(crate) const NOT_ALLOWED: i64 = -32001;

/// The next line, without its end; None at the end of the stream or for a line longer than [`MAX_LINE`]
pub(crate) async fn read_line(reader: &mut (impl AsyncBufRead + Unpin)) -> Option<String> {
    let mut line = Vec::new();
    loop {
        let available = reader.fill_buf().await.ok()?;
        if available.is_empty() {
            return (!line.is_empty()).then(|| String::from_utf8_lossy(&line).into_owned());
        }
        match available.iter().position(|&b| b == b'\n') {
            Some(end) => {
                line.extend_from_slice(&available[..end]);
                reader.consume(end + 1);
                if line.last() == Some(&b'\r') {
                    line.pop();
                }
                return Some(String::from_utf8_lossy(&line).into_owned());
            }
            None => {
                let taken = available.len();
                line.extend_from_slice(available);
                reader.consume(taken);
            }
        }
        if line.len() > MAX_LINE {
            return None;
        }
    }
}

pub(crate) async fn write_message(writer: &mut (impl AsyncWrite + Unpin), message: &Value) -> std::io::Result<()> {
    let mut line = message.to_string();
    line.push('\n');
    writer.write_all(line.as_bytes()).await?;
    writer.flush().await
}

pub(crate) fn result(id: &Value, result: Value) -> Value {
    json!({ "jsonrpc": "2.0", "id": id, "result": result })
}

pub(crate) fn error(id: &Value, code: i64, message: &str) -> Value {
    json!({ "jsonrpc": "2.0", "id": id, "error": { "code": code, "message": message } })
}

/// A message read from a line
pub(crate) enum Incoming {
    Request {
        id: Value,
        method: String,
        params: Value,
    },
    Notification,
    /// Not JSON-RPC: the answer to send
    Invalid(Value),
}

pub(crate) fn parse(line: &str) -> Incoming {
    let Ok(message) = serde_json::from_str::<Value>(line) else {
        return Incoming::Invalid(error(&Value::Null, PARSE_ERROR, "not JSON"));
    };
    let id = message.get("id").cloned();
    let Some(method) = message.get("method").and_then(Value::as_str) else {
        // a response (MCP servers do not ask clients anything here) or something else
        return match id {
            Some(_) if message.get("result").is_some() || message.get("error").is_some() => Incoming::Notification,
            _ => Incoming::Invalid(error(&id.unwrap_or(Value::Null), INVALID_REQUEST, "not a request")),
        };
    };
    match id {
        Some(id) if id.is_string() || id.is_number() => Incoming::Request {
            id,
            method: method.to_string(),
            params: message.get("params").cloned().unwrap_or(Value::Null),
        },
        Some(id) => Incoming::Invalid(error(&id, INVALID_REQUEST, "an id is a string or a number")),
        None => Incoming::Notification,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn lines_are_read_whole_and_capped() {
        let mut input: &[u8] = b"{\"a\":1}\r\n{\"b\":2}\nlast";
        assert_eq!(read_line(&mut input).await.as_deref(), Some("{\"a\":1}"));
        assert_eq!(read_line(&mut input).await.as_deref(), Some("{\"b\":2}"));
        assert_eq!(read_line(&mut input).await.as_deref(), Some("last"));
        assert_eq!(read_line(&mut input).await, None);
        let long = vec![b'x'; MAX_LINE + 10];
        let mut input: &[u8] = &long;
        assert_eq!(read_line(&mut input).await, None);
    }

    #[test]
    fn requests_and_the_rest() {
        assert!(matches!(
            parse(r#"{"jsonrpc":"2.0","id":1,"method":"ping"}"#),
            Incoming::Request { method, .. } if method == "ping"
        ));
        assert!(matches!(
            parse(r#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#),
            Incoming::Notification
        ));
        assert!(matches!(parse("{"), Incoming::Invalid(e) if e["error"]["code"] == PARSE_ERROR));
        assert!(matches!(parse(r#"{"id":{},"method":"x"}"#), Incoming::Invalid(_)));
        assert!(matches!(parse(r#"[1]"#), Incoming::Invalid(_)));
    }
}
