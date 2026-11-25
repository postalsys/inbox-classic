//! What a vault's files hold, sealed: each file encrypted and authenticated with the vault key (ChaCha20-Poly1305),
//! bound to the vault, the device that wrote it and its name, so a file can be neither read, changed, moved to another
//! name nor taken into another vault without it showing. The vault key itself is kept in the system's password store
//! on each computer, and in the vault only sealed with the sync passphrase ([`pe_pgp::sealed`]).

use ring::aead::{Aad, CHACHA20_POLY1305, LessSafeKey, Nonce, UnboundKey};
use ring::rand::{SecureRandom, SystemRandom};
use zeroize::Zeroizing;

/// The first byte of a sealed file: the format, so a later one can be told apart
const VERSION: u8 = 1;

/// A vault key, 32 random bytes
pub type VaultKey = Zeroizing<[u8; 32]>;

/// A new vault key
pub fn new_key() -> Option<VaultKey> {
    let mut key = Zeroizing::new([0u8; 32]);
    SystemRandom::new().fill(key.as_mut()).ok()?;
    Some(key)
}

/// A random id: 16 bytes as hex (a vault's, a device's, an item's)
pub fn new_id() -> Option<String> {
    let mut bytes = [0u8; 16];
    SystemRandom::new().fill(&mut bytes).ok()?;
    Some(bytes.iter().map(|b| format!("{b:02x}")).collect())
}

fn aad(vault: &str, device: &str, name: &str) -> Vec<u8> {
    format!("inboxclassic sync 1\0{vault}\0{device}\0{name}").into_bytes()
}

fn aead(key: &VaultKey) -> Option<LessSafeKey> {
    Some(LessSafeKey::new(
        UnboundKey::new(&CHACHA20_POLY1305, key.as_ref()).ok()?,
    ))
}

/// `plain` sealed as the file `name` of `device` in `vault`
pub fn seal(key: &VaultKey, vault: &str, device: &str, name: &str, plain: &[u8]) -> Option<Vec<u8>> {
    let mut nonce = [0u8; 12];
    SystemRandom::new().fill(&mut nonce).ok()?;
    let mut sealed = plain.to_vec();
    aead(key)?
        .seal_in_place_append_tag(
            Nonce::assume_unique_for_key(nonce),
            Aad::from(aad(vault, device, name)),
            &mut sealed,
        )
        .ok()?;
    let mut out = Vec::with_capacity(1 + 12 + sealed.len());
    out.push(VERSION);
    out.extend_from_slice(&nonce);
    out.extend_from_slice(&sealed);
    Some(out)
}

/// A file opened, None when it is not the sealed file `name` of `device` in `vault` (changed, moved, another vault's,
/// another key's)
pub fn open(key: &VaultKey, vault: &str, device: &str, name: &str, sealed: &[u8]) -> Option<Zeroizing<Vec<u8>>> {
    let (version, rest) = sealed.split_first()?;
    if *version != VERSION || rest.len() < 12 + 16 {
        return None;
    }
    let (nonce, body) = rest.split_at(12);
    let mut body = Zeroizing::new(body.to_vec());
    let plain_len = aead(key)?
        .open_in_place(
            Nonce::try_assume_unique_for_key(nonce).ok()?,
            Aad::from(aad(vault, device, name)),
            body.as_mut_slice(),
        )
        .ok()?
        .len();
    body.truncate(plain_len);
    Some(body)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_file_opens_only_where_it_was_sealed() {
        let key = new_key().unwrap();
        let sealed = seal(&key, "v", "mac", "000001", b"changes").unwrap();
        assert_eq!(
            open(&key, "v", "mac", "000001", &sealed).unwrap().as_slice(),
            b"changes"
        );
        // another name, device, vault or key: refused
        assert!(open(&key, "v", "mac", "000002", &sealed).is_none());
        assert!(open(&key, "v", "pc", "000001", &sealed).is_none());
        assert!(open(&key, "w", "mac", "000001", &sealed).is_none());
        assert!(open(&new_key().unwrap(), "v", "mac", "000001", &sealed).is_none());
        // a byte changed: refused
        let mut changed = sealed.clone();
        *changed.last_mut().unwrap() ^= 1;
        assert!(open(&key, "v", "mac", "000001", &changed).is_none());
        assert!(open(&key, "v", "mac", "000001", &[1, 2, 3]).is_none());
        assert_eq!(new_id().unwrap().len(), 32);
    }
}
