//! Bounces explained: whether a message reports that mail could not be delivered (or is delayed),
//! to whom, what the remote server said and what that means. [`detect`] is a port of EmailEngine's
//! bounce detection (`../emailengine/lib/bounce-detect.js`), [`classify`] of bounce-classifier
//! (`../bounce-classifier/src`) with its model built in; [`analyze`] puts the two together.
#![forbid(unsafe_code)]

pub mod classify;
pub mod detect;
pub mod headers;
mod heuristics;
mod js;
pub mod model;

pub use classify::{Action, Blocklist, BlocklistInfo, BlocklistType, Classification, Label, classify};
pub use detect::{Detection, detect};

/// What a bounce reports
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BounceKind {
    /// Delivery failed for good, for at least one recipient
    Failed,
    /// Delivery is late and still being tried
    Delayed,
}

/// A recipient the message did not reach
#[derive(Debug, Clone, PartialEq)]
pub struct Recipient {
    /// None when the notice gives the reason but not the address
    pub address: Option<String>,
    /// The report's action for this recipient, `failed` or `delayed`
    pub kind: BounceKind,
    /// The enhanced status code, `5.1.1`
    pub status: Option<String>,
    /// The remote server's own words
    pub diagnostic: Option<String>,
    /// The server that refused the message
    pub remote_mta: Option<String>,
    /// What the server's words (or the status code, without them) mean
    pub label: Label,
    pub action: Action,
    /// Seconds the server asks to wait before trying again
    pub retry_after: Option<u32>,
    pub blocklist: Option<Blocklist>,
}

/// The returned message, as far as the bounce quotes it
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Original {
    pub message_id: Option<String>,
    /// Encoded words decoded
    pub subject: Option<String>,
    /// As written
    pub date: Option<String>,
    /// Encoded words decoded
    pub to: Option<String>,
}

/// A delivery failure or delay notice
#[derive(Debug, Clone, PartialEq)]
pub struct Bounce {
    /// Failed when any recipient failed
    pub kind: BounceKind,
    pub recipients: Vec<Recipient>,
    /// The server that wrote the report
    pub reporting_mta: Option<String>,
    pub original: Option<Original>,
}

/// Reads a raw message; None when it is not a bounce or a delay notice
/// The most recipients a bounce lists
pub const MAX_RECIPIENTS: usize = 100;

pub fn analyze(raw: &[u8]) -> Option<Bounce> {
    let parsed = detect::parse(raw)?;
    from_detection(&detect::detect_parsed(&parsed))
}

/// The kind an action names
fn kind_of(action: Option<&str>) -> Option<BounceKind> {
    let action = action?.trim();
    if action.eq_ignore_ascii_case("failed") {
        Some(BounceKind::Failed)
    } else if action.eq_ignore_ascii_case("delayed") {
        Some(BounceKind::Delayed)
    } else {
        None
    }
}

fn non_empty(value: Option<&str>) -> Option<String> {
    value.map(str::trim).filter(|v| !v.is_empty()).map(str::to_string)
}

fn recipient(
    address: Option<&str>,
    kind: BounceKind,
    response: Option<&detect::Response>,
    remote_mta: Option<&str>,
) -> Recipient {
    let status = non_empty(response.and_then(|r| r.status.as_deref()));
    let diagnostic = non_empty(response.and_then(|r| r.message.as_deref()));
    let classification = diagnostic.as_deref().or(status.as_deref()).map(classify);
    Recipient {
        address: non_empty(address),
        kind,
        remote_mta: non_empty(remote_mta),
        label: classification.as_ref().map_or(Label::Unknown, |c| c.label),
        action: classification.as_ref().map_or(Action::Review, |c| c.action),
        retry_after: classification.as_ref().and_then(|c| c.retry_after),
        blocklist: classification.and_then(|c| c.blocklist),
        status,
        diagnostic,
    }
}

/// The bounce a detection describes
pub fn from_detection(detection: &Detection) -> Option<Bounce> {
    let mut recipients = Vec::new();
    // The recipient EmailEngine describes comes first, with what the heuristics added
    let first_kind = if detection.delay_notice {
        Some(BounceKind::Delayed)
    } else {
        kind_of(detection.action.as_deref())
    };
    if let Some(kind) = first_kind {
        recipients.push(recipient(
            detection.recipient.as_deref(),
            kind,
            detection.response.as_ref(),
            detection.remote_mta.as_deref(),
        ));
    }
    // Then the other recipients of the report, at most MAX_RECIPIENTS (each is classified; a report of thousands is
    // not one the window can show anyway)
    for report in &detection.reports {
        if recipients.len() >= MAX_RECIPIENTS {
            break;
        }
        let Some(kind) = kind_of(report.action.as_deref()) else {
            continue;
        };
        let address = non_empty(report.recipient.as_deref());
        if address.is_some() && recipients.iter().any(|r| r.address == address) {
            continue;
        }
        recipients.push(recipient(
            address.as_deref(),
            kind,
            report.response.as_ref(),
            report.remote_mta.as_deref(),
        ));
    }
    if recipients.is_empty() {
        return None;
    }
    let kind = if recipients.iter().any(|r| r.kind == BounceKind::Failed) {
        BounceKind::Failed
    } else {
        BounceKind::Delayed
    };
    Some(Bounce {
        kind,
        recipients,
        reporting_mta: non_empty(detection.reporting_mta.as_deref()),
        original: original(detection),
    })
}

/// The returned message a detection found, when it found anything of it
pub fn original(detection: &Detection) -> Option<Original> {
    let headers = detection.message_headers.as_ref();
    let field = |key: &str| {
        // The values are unfolded already, see headers::decode
        let value = headers?.first(key)?;
        non_empty(Some(&pe_mime::decode_words(value)))
    };
    let original = Original {
        message_id: non_empty(detection.message_id.as_deref()),
        subject: field("subject"),
        date: field("date"),
        to: field("to"),
    };
    (original != Original::default()).then_some(original)
}
