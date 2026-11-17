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
    /// Header fields added to the top: the sender's `Autocrypt`
    pub headers: Vec<String>,
    /// Header fields added inside the encryption: the other recipients' keys (`Autocrypt-Gossip`)
    pub gossip: Vec<String>,
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

/// The addresses of a list as typed, as the compose window lists them
fn addresses(list: &str) -> Vec<String> {
    crate::compose_keys::mailboxes_in(list)
        .into_iter()
        .map(|(address, _)| address)
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
        // what still quotes or carries encrypted mail goes only encrypted; once that is removed, it may go without
        let encrypted_content = crate::compose_keys::encrypted_content(outgoing);
        if let Some(reason) = encrypted_content.clone().filter(|_| !outgoing.encrypt && !draft) {
            return Err(crate::Error::Compose(reason));
        }
        let from = crate::compose_keys::sending_address(self, account, outgoing)?;
        let no_key = || crate::Error::Compose(ComposeError::NoOwnKey(from.clone()));
        // the sender's key in the Autocrypt header, unless its switch is off; not in a draft
        let autocrypt = match draft {
            true => None,
            false => self.autocrypt_header(&from)?,
        };
        // a draft quoting encrypted mail is saved encrypted to the sender's key, whatever Encrypt says: what was
        // encrypted never reaches the server in the clear
        let encrypt = outgoing.encrypt || (draft && encrypted_content.is_some());
        if !(encrypt || (outgoing.sign && !draft)) {
            return Ok(autocrypt.map(|header| {
                std::sync::Arc::new(OutgoingKeys {
                    signer: None,
                    recipients: Vec::new(),
                    hidden: Vec::new(),
                    headers: vec![header],
                    gossip: Vec::new(),
                })
            }));
        }
        let headers: Vec<String> = autocrypt.into_iter().collect();
        self.book(|book| {
            // a draft is encrypted to the sender's own certificate: nothing unwrapped for it
            if draft {
                let own = book.identity_cert(&from)?.ok_or_else(no_key)?;
                return Ok(Some(OutgoingKeys {
                    signer: None,
                    recipients: vec![own],
                    hidden: Vec::new(),
                    headers: Vec::new(),
                    gossip: Vec::new(),
                }));
            }
            let own = book.identity_key(&from)?.ok_or_else(no_key)?;
            if !outgoing.encrypt {
                return Ok(Some(OutgoingKeys {
                    signer: Some(own),
                    recipients: Vec::new(),
                    hidden: Vec::new(),
                    headers,
                    gossip: Vec::new(),
                }));
            }
            let now = unix_now();
            let mut missing = Vec::new();
            let mut visible: Vec<(String, Cert)> = Vec::new();
            let mut usable = |address: String| -> Result<Option<Cert>> {
                // the user's other own addresses are encrypted to by their own key
                let cert = match book.cert_for(&address)? {
                    Some(cert) => Some(cert),
                    None => book.identity_cert(&address)?,
                };
                match cert.filter(|cert| cert.can_encrypt(now).is_ok()) {
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
                if let Some(cert) = usable(address.clone())? {
                    visible.push((address, cert.clone()));
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
            // each visible recipient gets the others' keys, to answer all of them encrypted (never the Bcc's)
            let gossip = if visible.len() > 1 {
                visible
                    .iter()
                    .filter_map(|(address, cert)| crate::autocrypt::gossip_header(address, cert, now))
                    .collect()
            } else {
                Vec::new()
            };
            Ok(Some(OutgoingKeys {
                signer: Some(own),
                recipients,
                hidden,
                headers,
                gossip,
            }))
        })
        .map(|keys| keys.map(std::sync::Arc::new))
    }

    /// The `Autocrypt` header of an own address, when it has a key and its switch is on
    fn autocrypt_header(&self, address: &str) -> Result<Option<String>> {
        let Some(identity) = self
            .store()
            .pgp_identity(address)?
            .filter(|identity| identity.autocrypt)
        else {
            return Ok(None);
        };
        let key = self.pgp_cert(&identity.fingerprint)?;
        Ok(key.and_then(|cert| crate::autocrypt::header(address, &cert, unix_now())))
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
    for header in &keys.headers {
        top.extend_from_slice(header.as_bytes());
    }
    let wrapped = if !keys.recipients.is_empty() {
        // the gossip goes with the content, inside the encryption
        let mut inner: Vec<u8> = keys
            .gossip
            .iter()
            .flat_map(|header| header.as_bytes().to_vec())
            .collect();
        inner.extend_from_slice(&content);
        let content = inner;
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
    } else if let Some(signer) = keys.signer.as_ref() {
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
    } else {
        // neither signed nor encrypted: the content as it was, under the top headers with the new ones
        content
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
