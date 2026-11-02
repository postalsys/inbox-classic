//! Errors of the protocol layer. They carry a bounded copy of the offending input only, a server
//! decides how long a line is and the error may end up in a log or in a dialog.

use std::fmt;

/// How much of the offending input an error keeps
pub const ERROR_CONTEXT_LENGTH: usize = 1024;

/// A response that could not be parsed or framed
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ParseError {
    /// A stable code, the same as imapflow uses (`ParserError2`, `LiteralTooLarge`, ...)
    pub code: &'static str,
    pub message: String,
    /// Byte position in the line, when there is one
    pub position: Option<usize>,
    /// The tag of the line, when it was read before the failure, so the command it answers can
    /// still be settled
    pub tag: Option<String>,
    /// The start of the input
    pub context: String,
}

impl ParseError {
    pub(crate) fn new(code: &'static str, message: impl Into<String>, position: Option<usize>, input: &[u8]) -> Self {
        let end = input.len().min(ERROR_CONTEXT_LENGTH);
        ParseError {
            code,
            message: message.into(),
            position,
            tag: None,
            context: String::from_utf8_lossy(&input[..end]).into_owned(),
        }
    }
}

impl fmt::Display for ParseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{} ({})", self.message, self.code)
    }
}

impl std::error::Error for ParseError {}

/// A command that can not be written to the wire
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CompileError {
    pub code: &'static str,
    pub message: String,
}

impl CompileError {
    pub(crate) fn new(code: &'static str, message: impl Into<String>) -> Self {
        CompileError {
            code,
            message: message.into(),
        }
    }
}

impl fmt::Display for CompileError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{} ({})", self.message, self.code)
    }
}

impl std::error::Error for CompileError {}
