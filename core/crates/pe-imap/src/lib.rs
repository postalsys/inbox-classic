//! IMAP client, a port of imapflow (../imapflow/src). Parsing of server responses is a pure function over bytes,
//! the connection layer (TLS, STARTTLS, COMPRESS, IDLE) sits on top of it.
#![forbid(unsafe_code)]
