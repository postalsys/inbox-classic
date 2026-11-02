//! SMTP client and MIME message building, a port of the parts of nodemailer (../nodemailer/src) a mail client needs:
//! smtp-connection, mime-node, mail-composer, mime-funcs, qp, base64, punycode (through the idna crate) and xoauth2.
//! Recipients typed by the user are parsed with pe-mime's address parser, a port of the same addressparser.
#![forbid(unsafe_code)]

pub mod address;
pub mod client;
pub mod encoding;
pub mod message;
pub mod mime_types;

pub use client::{Client, Config, Credentials, Error, ErrorKind, Response, SendReport};
pub use message::{Attachment, Built, Envelope, Message, build, build_with};
