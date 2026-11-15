//! Signing and encrypting what is sent (PGP/MIME, RFC 3156): a message built as any other ([`pe_smtp::build`]), its
//! content (the part under the top headers) then signed, or signed and encrypted, and put back under the same top
//! headers. Ordinary mail is built exactly as before; this only wraps.
//!
//! - **Sign**: `multipart/signed` over the content's exact bytes, quoted-printable where relays would change it
//!   (`pe_smtp::Message::signed`).
//! - **Encrypt**: the content signed and encrypted in one OpenPGP message (RFC 3156 section 6.2), to every To and Cc
//!   recipient and the sender's own key (so the Sent copy opens), Bcc recipients not named in it.
//! - **A draft** with Encrypt on: encrypted to the sender's own key only, not signed (RFC 9787 section 9.5).

use pe_pgp::{Cert, SecretKey};
use pe_store::normal_address;

use crate::compose::{ComposeError, Outgoing};
use crate::worker::unix_now;
use crate::{AccountId, Core, Result};

/// The keys a message is protected with, found when it was sent (the private key unwrapped for this one message)
pub(crate) struct OutgoingKeys {
    /// Signs it; None for a draft
    pub signer: Option<SecretKey>,
    /// Encrypted to these (To, Cc and the sender's own); empty when it is only signed
    pub recipients: Vec<Cert>,
    /// Encrypted to these without naming them (Bcc)
    pub hidden: Vec<Cert>,
}

impl std::fmt::Debug for OutgoingKeys {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "OutgoingKeys({} recipients)",
            self.recipients.len() + self.hidden.len()
        )
    }
}

/// The addresses of a list as typed
fn addresses(list: &str) -> Vec<String> {
    pe_mime::parser::parse_addresses(list)
        .iter()
        .flat_map(|address| {
            address
                .mailboxes()
                .iter()
                .map(|m| normal_address(&m.address))
                .collect::<Vec<_>>()
        })
        .collect()
}

impl Core {
    /// The keys `outgoing` is signed and encrypted with from `account`, None when it is neither; for a `draft`, the
    /// sender's own key to encrypt to. Refused when a key is missing: the sender's, or (Encrypt) a recipient's.
    pub(crate) fn outgoing_keys(
        &self,
        account: AccountId,
        outgoing: &Outgoing,
        draft: bool,
    ) -> Result<Option<std::sync::Arc<OutgoingKeys>>> {
        if outgoing.quote_encrypted && !outgoing.encrypt && !draft {
            return Err(crate::Error::Compose(ComposeError::EncryptedQuote));
        }
        // a draft quoting encrypted mail is saved encrypted to the sender's key, whatever Encrypt says: what was
        // encrypted never reaches the server in the clear
        let encrypt = outgoing.encrypt || (draft && outgoing.quote_encrypted);
        if !(encrypt || (outgoing.sign && !draft)) {
            return Ok(None);
        }
        let from = match outgoing.from.as_deref() {
            Some(other) => normal_address(other),
            None => normal_address(&self.store().account(account)?.settings.email),
        };
        let no_key = || crate::Error::Compose(ComposeError::NoOwnKey(from.clone()));
        self.book(|book| {
            // a draft is encrypted to the sender's own certificate: nothing unwrapped for it
            if draft {
                let own = book.identity_cert(&from)?.ok_or_else(no_key)?;
                return Ok(Some(OutgoingKeys {
                    signer: None,
                    recipients: vec![own],
                    hidden: Vec::new(),
                }));
            }
            let own = book.identity_key(&from)?.ok_or_else(no_key)?;
            if !outgoing.encrypt {
                return Ok(Some(OutgoingKeys {
                    signer: Some(own),
                    recipients: Vec::new(),
                    hidden: Vec::new(),
                }));
            }
            let now = unix_now();
            let mut missing = Vec::new();
            let mut usable = |address: String| -> Result<Option<Cert>> {
                match book.cert_for(&address)?.filter(|cert| cert.can_encrypt(now).is_ok()) {
                    Some(cert) => Ok(Some(cert)),
                    None if address == from => Ok(None),
                    None => {
                        if !missing.contains(&address) {
                            missing.push(address);
                        }
                        Ok(None)
                    }
                }
            };
            let mut recipients = vec![own.cert().clone()];
            for address in addresses(&outgoing.to).into_iter().chain(addresses(&outgoing.cc)) {
                if let Some(cert) = usable(address)? {
                    recipients.push(cert);
                }
            }
            let mut hidden = Vec::new();
            for address in addresses(&outgoing.bcc) {
                if let Some(cert) = usable(address)? {
                    hidden.push(cert);
                }
            }
            if !missing.is_empty() {
                return Err(crate::Error::Compose(ComposeError::MissingKeys(missing)));
            }
            Ok(Some(OutgoingKeys {
                signer: Some(own),
                recipients,
                hidden,
            }))
        })
        .map(|keys| keys.map(std::sync::Arc::new))
    }
}

/// A boundary that is in none of `parts`
fn boundary(parts: &[&[u8]]) -> String {
    let mut random = [0u8; 12];
    let _ = ring::rand::SecureRandom::fill(&ring::rand::SystemRandom::new(), &mut random);
    let mut boundary = format!("----pe-{}", pe_pgp::hex(&random).to_lowercase());
    while parts
        .iter()
        .any(|part| part.windows(boundary.len()).any(|w| w == boundary.as_bytes()))
    {
        boundary.push('x');
    }
    boundary
}

/// `built` signed, or encrypted (and signed when `keys` has a signer) when `keys` has recipients: the keys decide,
/// so a draft that must go encrypted is, whatever Encrypt says
pub(crate) fn protect(
    built: pe_smtp::Built,
    keys: &OutgoingKeys,
    now: i64,
) -> std::result::Result<pe_smtp::Built, ComposeError> {
    let failed = |error: pe_pgp::Error| ComposeError::Protect(error.to_string());
    let raw = &built.raw;
    let outline = pe_mime::outline::outline(raw);
    // never sent unprotected when it was to be protected
    let Some(root) = outline.root() else {
        return Err(failed(pe_pgp::Error::Malformed("no message to protect".into())));
    };
    // the top headers stay; the content's own (its type and encoding) go with the content
    let mut top = Vec::new();
    let mut content = Vec::new();
    for field in crate::protect::header_lines(&raw[..root.body]) {
        let name = field.split(|&b| b == b':').next().unwrap_or_default();
        match String::from_utf8_lossy(name).trim().to_ascii_lowercase().as_str() {
            "content-type" | "content-transfer-encoding" => content.extend_from_slice(field),
            "mime-version" => {}
            _ => top.extend_from_slice(field),
        }
    }
    content.extend_from_slice(b"\r\n");
    content.extend_from_slice(&raw[root.body..]);
    let wrapped = if !keys.recipients.is_empty() {
        let recipients: Vec<&Cert> = keys.recipients.iter().collect();
        let hidden: Vec<&Cert> = keys.hidden.iter().collect();
        let armored = pe_pgp::encrypt(content, &recipients, &hidden, keys.signer.as_ref(), now).map_err(failed)?;
        let b = boundary(&[armored.as_bytes()]);
        format!(
            "Content-Type: multipart/encrypted;\r\n protocol=\"application/pgp-encrypted\";\r\n boundary=\"{b}\"\r\n\r\n\
             This is an OpenPGP/MIME encrypted message (RFC 4880 and 3156)\r\n\
             --{b}\r\nContent-Type: application/pgp-encrypted\r\nContent-Description: PGP/MIME version identification\r\n\r\n\
             Version: 1\r\n\r\n--{b}\r\nContent-Type: application/octet-stream; name=\"encrypted.asc\"\r\n\
             Content-Description: OpenPGP encrypted message\r\nContent-Disposition: inline; filename=\"encrypted.asc\"\r\n\r\n\
             {armored}\r\n--{b}--\r\n"
        )
        .into_bytes()
    } else {
        let Some(signer) = keys.signer.as_ref() else {
            return Ok(built);
        };
        let signed = pe_pgp::sign_detached(&content, signer, now).map_err(failed)?;
        let b = boundary(&[&content]);
        let mut out = format!(
            "Content-Type: multipart/signed; micalg=\"{}\";\r\n protocol=\"application/pgp-signature\";\r\n \
             boundary=\"{b}\"\r\n\r\nThis is an OpenPGP/MIME signed message (RFC 4880 and 3156)\r\n--{b}\r\n",
            signed.micalg
        )
        .into_bytes();
        out.extend_from_slice(&content);
        out.extend_from_slice(
            format!(
                "\r\n--{b}\r\nContent-Type: application/pgp-signature; name=\"signature.asc\"\r\n\
                 Content-Description: OpenPGP digital signature\r\nContent-Disposition: attachment; \
                 filename=\"signature.asc\"\r\n\r\n{}\r\n--{b}--\r\n",
                signed.signature.trim_end()
            )
            .as_bytes(),
        );
        out
    };
    let mut raw = top;
    raw.extend_from_slice(b"MIME-Version: 1.0\r\n");
    raw.extend_from_slice(&wrapped);
    Ok(pe_smtp::Built { raw, ..built })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn boundaries_are_not_in_the_content() {
        let b = boundary(&[b"hello"]);
        assert!(b.starts_with("----pe-"));
    }
}
