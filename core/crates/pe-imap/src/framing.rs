//! Splits the bytes a server sends into responses: a line, with the data of every literal it
//! announces (`{123}\r\n`) taken out of it. A port of imapflow's `imap-stream.ts`. The line keeps
//! its literal markers, the parser takes the data of each marker from the list in order.
//!
//! The server decides how long lines and literals are, so the framer bounds them before it
//! buffers anything, and fails for good once a bound is crossed: after that the stream can not be
//! trusted to be in step with the protocol.

use crate::error::ParseError;

/// Largest literal by default, 1 GiB
pub const MAX_LITERAL_SIZE: u64 = 1024 * 1024 * 1024;
/// Longest line by default (a response without a literal, like a large SEARCH answer)
pub const MAX_LINE_SIZE: u64 = MAX_LITERAL_SIZE;
/// Largest response by default, all its lines and literals together. Above the literal bound,
/// so a literal of the largest size still fits with its marker line.
pub const MAX_RESPONSE_SIZE: u64 = 2 * MAX_LITERAL_SIZE;

/// The most a literal reserves before its data arrives: the size is the server's claim, the
/// data is what it actually sends
const LITERAL_RESERVE: u64 = 16 * 1024 * 1024;

#[derive(Debug, Clone, Copy)]
pub struct FrameLimits {
    pub max_line: u64,
    pub max_literal: u64,
    pub max_response: u64,
}

impl Default for FrameLimits {
    fn default() -> Self {
        FrameLimits {
            max_line: MAX_LINE_SIZE,
            max_literal: MAX_LITERAL_SIZE,
            max_response: MAX_RESPONSE_SIZE,
        }
    }
}

/// One complete response, ready for [`RawResponse::parse`]
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RawResponse {
    /// The line without its final line break, literal markers kept
    pub line: Vec<u8>,
    pub literals: Vec<Vec<u8>>,
}

#[derive(Debug, Default)]
pub struct Framer {
    limits: FrameLimits,
    /// The part of the current line read so far
    line: Vec<u8>,
    /// The lines of the current response read so far
    response: Vec<u8>,
    literals: Vec<Vec<u8>>,
    /// Bytes still to read of the current literal, while one is being read
    literal_waiting: Option<u64>,
    literal: Vec<u8>,
    /// Lines and declared literal sizes of the current response
    response_bytes: u64,
    failed: Option<ParseError>,
}

impl Framer {
    pub fn new(limits: FrameLimits) -> Self {
        Framer {
            limits,
            ..Default::default()
        }
    }

    /// Feeds bytes from the connection and appends the responses they complete to `out`. On an
    /// error the responses completed before it are in `out` too, and every later call fails.
    pub fn push(&mut self, mut chunk: &[u8], out: &mut Vec<RawResponse>) -> Result<(), ParseError> {
        if let Some(error) = &self.failed {
            return Err(error.clone());
        }
        while !chunk.is_empty() {
            let result = match self.literal_waiting {
                Some(waiting) => {
                    let take = waiting.min(chunk.len() as u64) as usize;
                    self.literal.extend_from_slice(&chunk[..take]);
                    chunk = &chunk[take..];
                    self.wait_for_literal(waiting - take as u64);
                    Ok(())
                }
                None => self.read_line(&mut chunk, out),
            };
            if let Err(error) = result {
                // nothing buffered is of use any more
                *self = Framer {
                    failed: Some(error.clone()),
                    ..Default::default()
                };
                return Err(error);
            }
        }
        Ok(())
    }

    fn wait_for_literal(&mut self, waiting: u64) {
        if waiting == 0 {
            self.literals.push(std::mem::take(&mut self.literal));
            self.literal_waiting = None;
        } else {
            self.literal_waiting = Some(waiting);
        }
    }

    fn read_line(&mut self, chunk: &mut &[u8], out: &mut Vec<RawResponse>) -> Result<(), ParseError> {
        let Some(newline) = chunk.iter().position(|c| *c == b'\n') else {
            // a part of a line, the rest comes with a later chunk
            let length = (self.line.len() + chunk.len()) as u64;
            self.check_line(length)?;
            self.check_response(length)?;
            self.line.extend_from_slice(chunk);
            *chunk = &[];
            return Ok(());
        };
        self.check_line((self.line.len() + newline + 1) as u64)?;
        self.line.extend_from_slice(&chunk[..=newline]);
        *chunk = &chunk[newline + 1..];

        let line = std::mem::take(&mut self.line);
        let literal = self.literal_marker(&line)?;
        let size = line.len() as u64 + literal.unwrap_or(0);
        self.check_response(size)?;
        self.response_bytes += size;
        if self.response.is_empty() {
            self.response = line;
        } else {
            self.response.extend_from_slice(&line);
        }
        if let Some(size) = literal {
            self.literal = Vec::with_capacity(size.min(LITERAL_RESERVE) as usize);
            self.wait_for_literal(size);
            return Ok(());
        }

        let mut line = std::mem::take(&mut self.response);
        let literals = std::mem::take(&mut self.literals);
        self.response_bytes = 0;
        if line.last() == Some(&b'\n') {
            line.pop();
            if line.last() == Some(&b'\r') {
                line.pop();
            }
        }
        if !line.is_empty() {
            out.push(RawResponse { line, literals });
        }
        Ok(())
    }

    /// The size of the literal a line announces at its end, `{123}\r\n`
    fn literal_marker(&self, line: &[u8]) -> Result<Option<u64>, ParseError> {
        let Some(body) = line.strip_suffix(b"\n") else {
            return Ok(None);
        };
        let body = body.strip_suffix(b"\r").unwrap_or(body);
        let Some(body) = body.strip_suffix(b"}") else {
            return Ok(None);
        };
        let digits = body.iter().rev().take_while(|c| c.is_ascii_digit()).count();
        // the marker can not start the line
        if digits == 0 || body.len() == digits || body[body.len() - digits - 1] != b'{' {
            return Ok(None);
        }
        let digits = &body[body.len() - digits..];
        let significant = &digits[digits.iter().take_while(|c| **c == b'0').count()..];
        if significant.len() > 19 {
            return Err(too_large(None, self.limits.max_literal, line));
        }
        // at most 19 digits always fit
        let size = significant.iter().fold(0u64, |n, c| n * 10 + u64::from(c - b'0'));
        if size > self.limits.max_literal {
            return Err(too_large(Some(size), self.limits.max_literal, line));
        }
        Ok(Some(size))
    }

    fn check_line(&self, length: u64) -> Result<(), ParseError> {
        if length <= self.limits.max_line {
            return Ok(());
        }
        Err(ParseError::new(
            "LineTooLarge",
            format!(
                "Line length {length} exceeds maximum allowed size of {} bytes",
                self.limits.max_line
            ),
            None,
            &self.line,
        ))
    }

    /// Whether `additional` more bytes still fit in the current response
    fn check_response(&self, additional: u64) -> Result<(), ParseError> {
        let total = self.response_bytes.saturating_add(additional);
        if total <= self.limits.max_response {
            return Ok(());
        }
        Err(ParseError::new(
            "ResponseTooLarge",
            format!(
                "Response size {total} exceeds maximum allowed size of {} bytes",
                self.limits.max_response
            ),
            None,
            &self.response,
        ))
    }
}

fn too_large(size: Option<u64>, max: u64, line: &[u8]) -> ParseError {
    let size = size.map_or_else(|| "with more than 19 digits".into(), |size| size.to_string());
    ParseError::new(
        "LiteralTooLarge",
        format!("Literal size {size} exceeds maximum allowed size of {max} bytes"),
        None,
        line,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    fn frame(input: &[u8]) -> Vec<RawResponse> {
        let mut out = Vec::new();
        Framer::default().push(input, &mut out).unwrap();
        out
    }

    fn raw(line: &str, literals: &[&str]) -> RawResponse {
        RawResponse {
            line: line.as_bytes().to_vec(),
            literals: literals.iter().map(|l| l.as_bytes().to_vec()).collect(),
        }
    }

    #[test]
    fn lines_and_literals() {
        let input = b"A CAPABILITY\r\nA LOGIN \"aaa\" \"bbb\"\r\nA APPEND INBOX {5}\r\n12345\r\nA LOGIN {5}\r\n12345 {11}\r\n12345678901 \"another\"\r\nA LOGOUT\r\n";
        assert_eq!(
            frame(input),
            vec![
                raw("A CAPABILITY", &[]),
                raw("A LOGIN \"aaa\" \"bbb\"", &[]),
                raw("A APPEND INBOX {5}\r\n", &["12345"]),
                raw("A LOGIN {5}\r\n {11}\r\n \"another\"", &["12345", "12345678901"]),
                raw("A LOGOUT", &[]),
            ]
        );
    }

    #[test]
    fn byte_by_byte_is_the_same() {
        let input = b"* 1 FETCH (BODY[] {3}\r\nabc FLAGS ({0}\r\n))\r\n\r\n* OK done\n";
        let mut framer = Framer::default();
        let mut out = Vec::new();
        for byte in input {
            framer.push(&[*byte], &mut out).unwrap();
        }
        assert_eq!(out, frame(input));
        assert_eq!(out[0], raw("* 1 FETCH (BODY[] {3}\r\n FLAGS ({0}\r\n))", &["abc", ""]));
        assert_eq!(out[1], raw("* OK done", &[]));
    }

    #[test]
    fn not_a_marker() {
        assert_eq!(frame(b"* X {abc}\r\n"), vec![raw("* X {abc}", &[])]);
        assert_eq!(frame(b"}\r\n"), vec![raw("}", &[])]);
        assert_eq!(frame(b"{}\r\n"), vec![raw("{}", &[])]);
        assert_eq!(
            frame(b"* X {007}\r\nabcdefg\r\n"),
            vec![raw("* X {007}\r\n", &["abcdefg"])]
        );
        assert_eq!(frame(b"* X {000}\r\n\r\n"), vec![raw("* X {000}\r\n", &[""])]);
    }

    #[test]
    fn limits() {
        let limits = FrameLimits {
            max_line: 10,
            max_literal: 5,
            max_response: 30,
        };
        let mut out = Vec::new();
        let mut framer = Framer::new(limits);
        // the response before the failure is kept
        let error = framer.push(b"A1 OK x\r\n0123456789AB", &mut out).unwrap_err();
        assert_eq!(error.code, "LineTooLarge");
        assert_eq!(out, vec![raw("A1 OK x", &[])]);
        // failed for good
        assert!(framer.push(b"x\r\n", &mut out).is_err());

        let fail = |input: &[u8]| Framer::new(limits).push(input, &mut Vec::new()).unwrap_err().code;
        assert_eq!(fail(b"* {6}\r\n"), "LiteralTooLarge");
        assert_eq!(fail(b"* {5}\r\n12345 {5}\r\n12345 {5}\r\n"), "ResponseTooLarge");
        let mut framer = Framer::default();
        assert_eq!(
            framer.push(b"* {99999999999999999999}\r\n", &mut out).unwrap_err().code,
            "LiteralTooLarge"
        );
    }
}
