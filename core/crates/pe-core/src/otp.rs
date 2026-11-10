//! One-time codes (sign-in, verification, approval codes) for the card at the top of a message. The code comes from
//! the sender's `OTP-Token` header (draft-goto-otp-token, read by pe-mime), else from the body as pe-otp finds it. Mail
//! is no authenticated channel, so a code is offered only when the provider of the account says the domain it is for
//! signed the message (a `dkim=pass` in its own Authentication-Results, as one-click Unsubscribe asks): the header's
//! origin, or the From domain for a code found in the body. Neither is shown in Junk E-mail, Sent Items or Drafts.

use pe_i18n::{Text, tr, tr_args};
use pe_mime::parser::Message;

use crate::unsubscribe::passed_domains;

/// A code found in a message and the domain it is for
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Code {
    /// What Copy puts on the clipboard: the code as it is typed
    pub code: String,
    /// The code as the message prints it (`482 913`)
    pub printed: String,
    /// The host the code is for: the header's origin, or the sender's domain
    pub domain: String,
    /// The domain whose signature covers it: `domain` or a parent of it
    pub signer: String,
}

/// The code of `message`, when the provider says the domain it is for signed it; `trusted` names whose verdicts count
pub(crate) fn of(message: &Message, trusted: &[String]) -> Option<Code> {
    let signed = passed_domains(&message.headers, trusted);
    // a signature of example.com covers example.com and the hosts under it (accounts.example.com), never a sibling: a
    // guess at registrable domains would make two sites under a shared suffix (me.uk, github.io) one
    let signer = |host: &str| {
        signed
            .iter()
            .filter(|d| !d.is_empty() && (host == d.as_str() || host.ends_with(&format!(".{d}"))))
            .min_by_key(|d| d.len())
            .cloned()
    };
    if let Some(token) = &message.otp {
        let host = origin_host(&token.origin)?;
        let signer = signer(&host)?;
        return Some(Code {
            code: token.code.clone(),
            printed: token.code.clone(),
            domain: host,
            signer,
        });
    }
    let domain = sender_domain(message)?;
    let signer = signer(&domain)?;
    let found = pe_otp::detect_otp(&pe_otp::MessageInput {
        subject: message.subject.as_deref(),
        text: message.text.as_deref(),
        html: message.html.as_deref(),
    })?;
    Some(Code {
        code: found.code,
        printed: found.raw,
        domain,
        signer,
    })
}

/// The host of an origin `https://host[:port]` (pe-mime has checked its form), lowercased
fn origin_host(origin: &str) -> Option<String> {
    let rest = origin.split_once("://")?.1;
    let host = if let Some(literal) = rest.strip_prefix('[') {
        literal.split(']').next()?
    } else {
        rest.split(':').next()?
    };
    Some(host.to_ascii_lowercase())
}

/// The domain of the From address, lowercased
fn sender_domain(message: &Message) -> Option<String> {
    let address = &message.from.as_ref()?.mailboxes().first()?.address;
    let domain = address.rsplit_once('@')?.1.trim();
    (!domain.is_empty()).then(|| domain.to_ascii_lowercase())
}

/// The card of `code`, saying it is old when the message was sent more than an hour before `now` (seconds since the
/// Unix epoch, as `sent`)
pub(crate) fn card(code: &Code, sent: Option<i64>, now: i64) -> pe_html::OtpCard {
    pe_html::OtpCard {
        heading: tr_args(Text::OtpHeading, &[("domain", code.domain.as_str().into())]),
        code: code.printed.clone(),
        note: tr_args(Text::OtpNote, &[("domain", code.signer.as_str().into())]),
        copy: tr(Text::OtpCopy),
        old: sent.filter(|sent| now - sent > 3600).map(|_| tr(Text::OtpOld)),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use pe_mime::parser::parse;

    const TRUSTED: &[&str] = &["mail.test"];

    fn trusted() -> Vec<String> {
        TRUSTED.iter().map(|d| d.to_string()).collect()
    }

    /// A message from `from`, with the provider's verdict that `signed` passed DKIM (when given), and `extra` headers
    fn message(from: &str, signed: Option<&str>, extra: &str, body: &str) -> Message {
        let verdict = signed
            .map(|d| format!("Authentication-Results: mx.mail.test; dkim=pass header.d={d}; spf=pass\r\n"))
            .unwrap_or_default();
        let raw = format!(
            "{verdict}{extra}From: Service <{from}>\r\nTo: me@mail.test\r\nSubject: Your sign-in code\r\n\
             Content-Type: text/plain; charset=utf-8\r\n\r\n{body}\r\n"
        );
        parse(raw.as_bytes()).unwrap()
    }

    const BODY: &str = "Hello,\r\n\r\nYour verification code is 482913.\r\n\r\nIt expires in 10 minutes. If you did not \
                        ask for it, ignore this email.";

    #[test]
    fn a_code_in_the_body_of_signed_mail() {
        let code = of(
            &message("no-reply@accounts.example.com", Some("example.com"), "", BODY),
            &trusted(),
        )
        .unwrap();
        assert_eq!(code.code, "482913");
        assert_eq!(code.domain, "accounts.example.com");
    }

    #[test]
    fn no_code_without_the_providers_word() {
        // no verdict, a verdict for another domain, a verdict the sender wrote itself
        assert_eq!(of(&message("no-reply@example.com", None, "", BODY), &trusted()), None);
        assert_eq!(
            of(
                &message("no-reply@example.com", Some("evil.test"), "", BODY),
                &trusted()
            ),
            None
        );
        let forged = message(
            "no-reply@example.com",
            None,
            "Authentication-Results: mx.evil.test; dkim=pass header.d=example.com\r\n",
            BODY,
        );
        assert_eq!(of(&forged, &trusted()), None);
        // a site's signature covers no other site under the same suffix (me.uk is no domain of one owner)
        assert_eq!(
            of(
                &message("no-reply@acme.me.uk", Some("evil.me.uk"), "", BODY),
                &trusted()
            ),
            None
        );
        let origin = "OTP-Token: \"917355\"; origin=\"https://login.acme.me.uk\"\r\n";
        assert_eq!(
            of(&message("x@evil.me.uk", Some("evil.me.uk"), origin, BODY), &trusted()),
            None
        );
        // nor a parent's: a signature of accounts.example.com does not cover example.com
        assert_eq!(
            of(
                &message("a@example.com", Some("accounts.example.com"), "", BODY),
                &trusted()
            ),
            None
        );
    }

    #[test]
    fn the_header_wins_for_its_origin() {
        let header = "OTP-Token: \"917355\"; origin=\"https://login.example.com\"\r\n";
        let code = of(
            &message("no-reply@example.com", Some("example.com"), header, BODY),
            &trusted(),
        )
        .unwrap();
        assert_eq!(
            (code.code.as_str(), code.domain.as_str()),
            ("917355", "login.example.com")
        );
        // a header for a domain that did not sign: no code, not even the body's
        let other = "OTP-Token: \"917355\"; origin=\"https://bank.test\"\r\n";
        assert_eq!(
            of(
                &message("no-reply@example.com", Some("example.com"), other, BODY),
                &trusted()
            ),
            None
        );
    }

    #[test]
    fn look_alikes_give_no_code() {
        let order = "Thank you for your order 48291355. Your total is 129.00 EUR and it ships on 12/11/2026.";
        assert_eq!(
            of(&message("shop@example.com", Some("example.com"), "", order), &trusted()),
            None
        );
    }

    #[test]
    fn the_card_says_when_the_code_is_old() {
        let code = Code {
            code: "482913".into(),
            printed: "482 913".into(),
            domain: "accounts.example.com".into(),
            signer: "example.com".into(),
        };
        let fresh = card(&code, Some(1000), 1000 + 600);
        assert_eq!(fresh.code, "482 913");
        assert!(fresh.heading.contains("accounts.example.com"));
        assert!(fresh.note.contains("example.com") && !fresh.note.contains("accounts."));
        assert_eq!(fresh.old, None);
        assert!(card(&code, Some(1000), 1000 + 7200).old.is_some());
        assert_eq!(card(&code, None, 7200).old, None);
    }
}
