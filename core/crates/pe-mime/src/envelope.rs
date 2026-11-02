//! Who a message is from and to, and what it is about: the fields IMAP's ENVELOPE carries and a
//! parsed message has, shared by the IMAP client, the message parser and the composer.

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Address {
    pub name: String,
    /// Empty for the name of an RFC 5322 group
    pub address: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Envelope {
    /// The Date header as sent, see [`Envelope::timestamp`]
    pub date: Option<String>,
    pub subject: Option<String>,
    pub from: Vec<Address>,
    pub sender: Vec<Address>,
    pub reply_to: Vec<Address>,
    pub to: Vec<Address>,
    pub cc: Vec<Address>,
    pub bcc: Vec<Address>,
    pub in_reply_to: Option<String>,
    pub message_id: Option<String>,
}

impl Envelope {
    /// The Date header in seconds since the Unix epoch
    pub fn timestamp(&self) -> Option<i64> {
        self.date.as_deref().and_then(crate::date::parse_date)
    }
}
