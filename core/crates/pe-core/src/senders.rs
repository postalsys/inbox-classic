//! The picture of each message's sender in the message list, decided by the core from what the account's provider
//! says of the message (docs/column-layout-plan.md, sender pictures). The provider's Authentication-Results and
//! BIMI-Location come with the summary (pe-sync), wait in the store, and are read here by the background worker with
//! the rules of the reading pane: [`bimi::of`] for a brand's logo (the provider's own verdict says `bimi=pass` and
//! `dmarc=pass`), [`pictures::from_verified`] for a sender whose domain is confirmed (a contact's picture, step 5).
//! Only bits and the logo's address are kept. The list shows the logo, else the initials of the sender
//! ([`crate::text::initials`]); a message in a Junk folder shows no picture (the store leaves its logo out).

use crate::{authres, bimi, pictures};

/// The From domain is confirmed: DMARC passed for it, or DKIM for a signature of it
pub const VERIFIED: u8 = 1;
/// The provider passed the brand's logo (BIMI) and DMARC
pub const LOGO: u8 = 2;
/// The provider gave no verdict of its own (no Authentication-Results of a trusted authserv-id at the top)
pub const NO_VERDICT: u8 = 4;

/// What a message's verdicts say of its sender
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Judged {
    pub bits: u8,
    /// The https address of the brand's logo, when [`LOGO`]
    pub logo_url: Option<String>,
}

/// Reads the verdict fields `headers` (as the server gave them) of a message from `from_address`, for an account whose
/// provider's authserv-ids are `trusted`
pub(crate) fn judge(headers: &str, from_address: &str, trusted: &[String]) -> Judged {
    let mut block = headers.to_string();
    block.push_str("\r\n");
    let parsed = pe_mime::parser::parse(block.as_bytes())
        .map(|m| m.headers)
        .unwrap_or_default();
    let mut bits = 0;
    if authres::verdict(&parsed, trusted).is_none() {
        bits |= NO_VERDICT;
    }
    if pictures::sender_of(from_address, &parsed, trusted).is_some_and(|sender| sender.verified) {
        bits |= VERIFIED;
    }
    // the logo's address only: the logo itself (BIMI-Indicator) is not fetched with the summary
    let logo_url = match bimi::of(&parsed, trusted) {
        Some(bimi::Logo::Location(url)) => Some(url),
        _ => None,
    };
    if logo_url.is_some() {
        bits |= LOGO;
    }
    Judged { bits, logo_url }
}

/// The kinds of picture a row of the list has
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PictureKind {
    /// None: the apps draw the sender's initials
    None,
    /// A brand's logo
    Logo,
    /// A contact's picture (the Address Book, step 5)
    Contact,
}

/// The key of a picture the apps keep pixels by and ask [`crate::Core::picture_start`] for: its kind in the high bits,
/// the row of its table under them; 0 for none
pub fn picture_key(kind: PictureKind, id: i64) -> u64 {
    let kind = match kind {
        PictureKind::None => return 0,
        PictureKind::Logo => 1u64,
        PictureKind::Contact => 2,
    };
    (kind << 48) | (id as u64 & ((1 << 48) - 1))
}

/// The kind and row of a picture key; None for 0 or one no key gives
pub fn picture_of(key: u64) -> Option<(PictureKind, i64)> {
    let id = (key & ((1 << 48) - 1)) as i64;
    match key >> 48 {
        1 => Some((PictureKind::Logo, id)),
        2 => Some((PictureKind::Contact, id)),
        _ => None,
    }
}

/// The picture of a row of the list: its kind and key
pub fn picture(message: &pe_store::Message) -> (PictureKind, u64) {
    match message.logo {
        Some(logo) => (PictureKind::Logo, picture_key(PictureKind::Logo, logo)),
        None => (PictureKind::None, 0),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn trusted() -> Vec<String> {
        vec!["example.com".into()]
    }

    const LOCATION: &str = "BIMI-Location: v=BIMI1; l=https://shop.example/logo.svg\r\n";

    #[test]
    fn a_logo_the_provider_passed() {
        let headers = format!(
            "Authentication-Results: mx.example.com; dkim=pass header.d=shop.example; dmarc=pass \
             header.from=shop.example; bimi=pass header.d=shop.example\r\n{LOCATION}"
        );
        let judged = judge(&headers, "news@shop.example", &trusted());
        assert_eq!(judged.bits, VERIFIED | LOGO);
        assert_eq!(judged.logo_url.as_deref(), Some("https://shop.example/logo.svg"));
    }

    #[test]
    fn a_forged_sender_gets_nothing() {
        let headers = format!(
            "Authentication-Results: mx.example.com; dkim=fail header.d=shop.example; dmarc=fail \
             header.from=shop.example; bimi=fail\r\n{LOCATION}"
        );
        assert_eq!(
            judge(&headers, "news@shop.example", &trusted()),
            Judged {
                bits: 0,
                logo_url: None
            }
        );
    }

    #[test]
    fn the_senders_own_results_do_not_count() {
        // the provider's on top says fail; the sender's own, below it, says pass
        let headers = format!(
            "Authentication-Results: mx.example.com; dmarc=fail header.from=shop.example\r\n\
             Authentication-Results: mx.example.com; dmarc=pass header.from=shop.example; bimi=pass\r\n{LOCATION}"
        );
        assert_eq!(judge(&headers, "news@shop.example", &trusted()).bits, 0);
        // one of an authserv-id the provider is not
        let headers = format!(
            "Authentication-Results: evil.example; dmarc=pass header.from=shop.example; bimi=pass\r\n{LOCATION}"
        );
        assert_eq!(judge(&headers, "news@shop.example", &trusted()).bits, NO_VERDICT);
    }

    #[test]
    fn a_provider_without_verdicts() {
        assert_eq!(judge("", "ann@example.com", &trusted()).bits, NO_VERDICT);
        assert_eq!(judge(LOCATION, "news@shop.example", &trusted()).bits, NO_VERDICT);
    }

    #[test]
    fn a_confirmed_sender_without_a_logo() {
        let headers = "Authentication-Results: mx.example.com; dkim=pass header.d=example.org\r\n";
        assert_eq!(judge(headers, "bo@mail.example.org", &trusted()).bits, VERIFIED);
        assert_eq!(judge(headers, "bo@other.example", &trusted()).bits, 0);
    }

    #[test]
    fn an_oversized_verdict_on_top_gives_none() {
        // the provider's results on top, too large to keep; a forged pass below them
        let provider = format!(
            "Authentication-Results: mx.example.com; dmarc=fail header.from=shop.example; {}\r\n",
            "x".repeat(5000)
        );
        let header = format!(
            "{provider}Authentication-Results: mx.example.com; dmarc=pass header.from=shop.example; bimi=pass\r\n\
             {LOCATION}\r\n"
        );
        let kept = pe_sync::auth_fields(header.as_bytes());
        let judged = judge(&kept, "news@shop.example", &trusted());
        assert_eq!(judged.bits, NO_VERDICT);
        assert_eq!(judged.logo_url, None);
    }

    #[test]
    fn keys_round_trip() {
        assert_eq!(picture_key(PictureKind::None, 5), 0);
        assert_eq!(picture_of(0), None);
        let key = picture_key(PictureKind::Logo, 42);
        assert_eq!(picture_of(key), Some((PictureKind::Logo, 42)));
        let key = picture_key(PictureKind::Contact, 7);
        assert_eq!(picture_of(key), Some((PictureKind::Contact, 7)));
        assert_ne!(picture_key(PictureKind::Logo, 7), key);
    }
}
