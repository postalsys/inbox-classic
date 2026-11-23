//! Finding correspondents' keys (pe-keys) and publishing the user's own. Only when the user asks: Encrypt turned on
//! for recipients without a key, Find Key on a contact or on a signature by an unknown key, Publish in My Keys. The
//! domain's Web Key Directory is asked first; keys.openpgp.org, unless Options turns it off. A miss is not asked again
//! for a day. What is found is learned as any key is (keys.rs): a different key for an address that has one waits.
//!
//! The network part runs in the background, and what it found is learned there too, on a store connection of its
//! own, before [`Event::KeysFound`] tells the windows: a lookup whose window closed loses nothing. The window that
//! asked takes the words ([`Core::pgp_find_result`]).

use pe_i18n::{Text, tr, tr_args};

use crate::keys::{Book, CertCache, KeySource, Learned};
use crate::secrets::Secrets;
use crate::worker::unix_now;
use crate::{Core, Event, Result};

/// A miss is asked again after this long
const MISS_KEPT: i64 = 24 * 60 * 60;
/// An address is asked again after this long when the user asks (Find Key): keys.openpgp.org allows one lookup a
/// minute for an address
const ASKED_KEPT: i64 = 60;

/// What a lookup is for
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) enum Wanted {
    /// The keys of these addresses
    Addresses(Vec<String>),
    /// The key with this fingerprint or key id
    Handle(String),
}

/// What a lookup came to, for the window: per address what became of it, and the words to say
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FindOutcome {
    /// Each address asked for, and whether a key is used for it now
    pub addresses: Vec<(String, bool)>,
    /// What to tell the user
    pub text: String,
    /// How many addresses got a key, used or waiting for the user's decision ([`Event::KeysFound`]'s `learned`)
    pub learned: usize,
}

/// What publishing came to
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PublishOutcome {
    pub ok: bool,
    pub text: String,
}

impl Core {
    /// Where keys are looked up: keys.openpgp.org and every domain's own directory, or the servers of the tests
    fn key_servers(&self) -> pe_keys::Servers {
        let servers = self.pgp_servers.lock().unwrap_or_else(|e| e.into_inner());
        servers.clone().unwrap_or_default()
    }

    /// The UI tests' key server (`--key-server`): keys.openpgp.org and every domain's directory played by one server
    /// on this computer. Refused for anything but a loopback address, so no one can send the lookups elsewhere.
    pub fn use_test_key_server(&self, base: &str) -> bool {
        let loopback = ["http://127.0.0.1:", "http://[::1]:", "http://localhost:"];
        let base = base.trim_end_matches('/');
        let Some(port) = loopback.iter().find_map(|prefix| base.strip_prefix(prefix)) else {
            return false;
        };
        if port.is_empty() || !port.bytes().all(|b| b.is_ascii_digit()) {
            return false;
        }
        *self.pgp_servers.lock().unwrap_or_else(|e| e.into_inner()) = Some(pe_keys::Servers {
            keyserver: base.to_string(),
            wkd_base: Some(base.to_string()),
        });
        true
    }

    /// Looks up the keys of `addresses` that have none (and were not looked up in vain in the last day), in the
    /// background: [`Event::KeysFound`] follows with the request this returns; None when there is nothing to ask
    pub fn pgp_find(&self, addresses: &[String]) -> Result<Option<u64>> {
        self.find_addresses(addresses, MISS_KEPT, false)
    }

    /// [`Core::pgp_find`] as the user asks it again (Find Key): a miss is asked again after a minute, and an address
    /// whose key can no longer encrypt (expired, revoked) is asked too, for a newer key
    pub(crate) fn pgp_find_again(&self, addresses: &[String]) -> Result<Option<u64>> {
        self.find_addresses(addresses, ASKED_KEPT, true)
    }

    /// Whether `address` was looked up in the last minute: Find Key waits for that
    pub(crate) fn asked_lately(&self, address: &str, now: i64) -> Result<bool> {
        Ok(self
            .store()
            .pgp_lookup(address)?
            .is_some_and(|(at, _)| now - at < ASKED_KEPT))
    }

    /// Whether the user may ask for the key of `address` again (Find Key): not while it is looked up, nor within a
    /// minute of the last time
    pub(crate) fn may_ask_again(&self, address: &str, now: i64) -> Result<bool> {
        Ok(!self.looking_for(address) && !self.asked_lately(address, now)?)
    }

    /// Whether the key of `address` is being looked up now
    pub(crate) fn looking_for(&self, address: &str) -> bool {
        let mut looking = self.pgp_looking.lock().unwrap_or_else(|e| e.into_inner());
        // a lookup that ended is no longer waited for, whether its result was taken or not
        looking.retain(|_, request| self.pgp_lookups.is_running(*request));
        looking.contains_key(address)
    }

    fn find_addresses(&self, addresses: &[String], miss_kept: i64, unusable_too: bool) -> Result<Option<u64>> {
        let wanted = self.wanted(addresses, miss_kept, unusable_too)?;
        if wanted.is_empty() {
            return Ok(None);
        }
        let use_keyserver = self.store().pgp_keyserver()?;
        let request = self.start_lookup(Wanted::Addresses(wanted.clone()), use_keyserver)?;
        let mut looking = self.pgp_looking.lock().unwrap_or_else(|e| e.into_inner());
        looking.extend(wanted.into_iter().map(|address| (address, request)));
        Ok(Some(request))
    }

    /// The addresses of `addresses` a lookup asks for: not the user's own, without a key (or, `unusable_too`, with one
    /// that can no longer encrypt), not missed in the last `miss_kept` seconds
    fn wanted(&self, addresses: &[String], miss_kept: i64, unusable_too: bool) -> Result<Vec<String>> {
        let now = unix_now();
        let store = self.store();
        // the user's own addresses are never asked about: their keys are their own
        let mut own = std::collections::HashSet::new();
        for account in store.accounts()? {
            own.extend(
                crate::own_addresses(&store, account.id)?
                    .iter()
                    .map(|a| pe_store::normal_address(a)),
            );
        }
        let mut wanted = Vec::new();
        for address in addresses {
            let address = pe_store::normal_address(address);
            if address.is_empty() || wanted.contains(&address) || own.contains(&address) {
                continue;
            }
            let key = store.pgp_peer(&address)?.and_then(|peer| peer.fingerprint);
            let has_key = match key {
                // asked again for a newer key when the one there can no longer encrypt
                Some(fingerprint) if unusable_too => store
                    .pgp_key(&fingerprint)?
                    .and_then(|key| self.pgp_certs.get(&key))
                    .is_some_and(|cert| cert.can_encrypt(now).is_ok()),
                Some(_) => true,
                None => false,
            };
            let missed = store
                .pgp_lookup(&address)?
                .is_some_and(|(at, found)| !found && now - at < miss_kept);
            if !has_key && !missed {
                wanted.push(address);
            }
        }
        Ok(wanted)
    }

    /// Looks up the key with `handle` on keys.openpgp.org: for a signature by a key not known here (Find Key beside its
    /// label). `handle` is the link clicked (`inboxclassic:find-key?<handle>`, [`pe_html::find_key_link`]) or the bare
    /// fingerprint or key id; anything but 16, 40 or 64 hex digits is refused ([`pe_html::key_handle`]). Asking by
    /// fingerprint tells the server no address. [`Event::KeysFound`] follows; the view built again then checks the
    /// signature with the key found. Refused while the user turned the key server off.
    pub fn pgp_find_handle(&self, handle: &str) -> Result<u64> {
        let handle = pe_html::find_key_link(handle)
            .or_else(|| pe_html::key_handle(handle))
            .ok_or_else(|| crate::Error::Invalid(tr(Text::PgpFoundNoKey)))?;
        if !self.store().pgp_keyserver()? {
            return Err(crate::Error::Unavailable(keyserver_off()));
        }
        self.start_lookup(Wanted::Handle(handle), true)
    }

    /// Find Key in a contact's window: the keys of the card's addresses that have none or one that can no longer
    /// encrypt, from each domain's Web Key Directory, then keys.openpgp.org (unless Settings turns it off), as the
    /// compose window's Find Key asks: an address asked in the last minute, or being looked up, is not asked again.
    /// What is found is learned as any key is (a different key for an address that has one waits for the user's
    /// decision). [`Event::KeysFound`] follows with the request; None when there is nothing to ask
    /// ([`Core::contact_can_find_keys`]).
    pub fn contact_find_keys(&self, card: pe_store::CardId) -> Result<Option<u64>> {
        let wanted = self.contact_wanted(card)?;
        self.pgp_find_again(&wanted)
    }

    /// Whether a contact's Find Key has anything to ask now ([`Core::contact_find_keys`]): its window enables the
    /// button by it. False for a card not saved yet.
    pub fn contact_can_find_keys(&self, card: pe_store::CardId) -> bool {
        self.contact_wanted(card).is_ok_and(|wanted| !wanted.is_empty())
    }

    /// The addresses of a card that Find Key asks for
    fn contact_wanted(&self, card: pe_store::CardId) -> Result<Vec<String>> {
        let Some(card) = self.store().card(card)? else {
            return Err(crate::Error::NotFound);
        };
        let now = unix_now();
        let mut addresses = Vec::new();
        for address in &card.addresses {
            let address = pe_store::normal_address(address);
            if self.may_ask_again(&address, now)? {
                addresses.push(address);
            }
        }
        self.wanted(&addresses, ASKED_KEPT, true)
    }

    fn start_lookup(&self, wanted: Wanted, use_keyserver: bool) -> Result<u64> {
        let request = self.next_request.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        let servers = self.key_servers();
        let now = unix_now();
        let learner = Learner {
            path: self.path.clone(),
            secrets: self.secrets.clone(),
            certs: self.pgp_certs.clone(),
        };
        let work = async move {
            let found = match wanted {
                // the addresses at once (each still asks its domain's directory before the key server), in order
                Wanted::Addresses(addresses) => {
                    let mut lookups = tokio::task::JoinSet::new();
                    for (index, address) in addresses.into_iter().enumerate() {
                        let servers = servers.clone();
                        lookups.spawn(async move {
                            let result = pe_keys::find(&address, &servers, use_keyserver, now).await;
                            (index, address, result)
                        });
                    }
                    let mut found = lookups.join_all().await;
                    found.sort_by_key(|(index, _, _)| *index);
                    found
                        .into_iter()
                        .map(|(_, address, result)| (address, result))
                        .collect()
                }
                Wanted::Handle(handle) => vec![(String::new(), pe_keys::by_fingerprint(&handle, &servers).await)],
            };
            // learned here, before the windows hear of it: one whose window closed meanwhile loses nothing
            tokio::task::spawn_blocking(move || learner.learn(found))
                .await
                .unwrap_or_else(|error| FindOutcome {
                    addresses: Vec::new(),
                    text: tr_args(Text::PgpFindUnavailable, &[("error", (&error.to_string()).into())]),
                    learned: 0,
                })
        };
        self.pgp_lookups.start_with(
            self.runtime()?,
            request,
            work,
            self.events.clone(),
            |request, outcome| Event::KeysFound {
                request,
                learned: outcome.learned,
            },
        );
        Ok(request)
    }

    /// The words of what a lookup found, for the window that asked (once): None for a lookup still running or an
    /// unknown request. The keys are in the key book already.
    pub fn pgp_find_result(&self, request: u64) -> Option<FindOutcome> {
        self.pgp_lookups.take(request)
    }

    /// Publishes an own key's public part on keys.openpgp.org, asking the server to send its confirmation mail to the
    /// key's addresses (it publishes an address once its owner clicks the link): [`Event::KeyPublished`] follows
    pub fn pgp_publish(&self, fingerprint: &str) -> Result<u64> {
        let key = self.pgp_key(fingerprint)?;
        // only the user's own key: a contact's is theirs to publish
        if !key.own {
            return Err(crate::Error::NotFound);
        }
        let armored = self.pgp_export(fingerprint)?;
        let addresses: Vec<String> = key.addresses.into_iter().map(|(address, _)| address).collect();
        let request = self.next_request.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        let servers = self.key_servers();
        let work = async move {
            let result = pe_keys::publish(&armored, &addresses, &servers).await;
            match result {
                Ok(published) => {
                    let pending: Vec<&str> = published
                        .addresses
                        .iter()
                        .filter(|(_, status)| status == "pending")
                        .map(|(address, _)| address.as_str())
                        .collect();
                    let done: Vec<&str> = published
                        .addresses
                        .iter()
                        .filter(|(_, status)| status == "published")
                        .map(|(address, _)| address.as_str())
                        .collect();
                    let mut text = Vec::new();
                    if !pending.is_empty() {
                        text.push(tr_args(
                            Text::PgpPublishPending,
                            &[("addresses", (&pending.join(", ")).into())],
                        ));
                    }
                    if !done.is_empty() {
                        text.push(tr_args(
                            Text::PgpPublishDone,
                            &[("addresses", (&done.join(", ")).into())],
                        ));
                    }
                    PublishOutcome {
                        ok: true,
                        text: text.join(" "),
                    }
                }
                Err(why) => PublishOutcome {
                    ok: false,
                    text: tr_args(Text::PgpPublishFailed, &[("error", (&why).into())]),
                },
            }
        };
        self.pgp_publishes
            .start(self.runtime()?, request, work, self.events.clone(), |request| {
                Event::KeyPublished { request }
            });
        Ok(request)
    }

    pub fn pgp_publish_result(&self, request: u64) -> Option<PublishOutcome> {
        self.pgp_publishes.take(request)
    }

    /// Settings > Reading > Encryption: "Look up keys on keys.openpgp.org", on out of the box
    pub fn pgp_keyserver(&self) -> Result<bool> {
        Ok(self.store().pgp_keyserver()?)
    }

    pub fn set_pgp_keyserver(&self, on: bool) -> Result<()> {
        Ok(self.store().set_pgp_keyserver(on)?)
    }
}
/// Why a key is not looked up on keys.openpgp.org, naming where the switch is as the window names it on this platform
pub(crate) fn keyserver_off() -> String {
    let settings = pe_html::settings_words("reading", pe_html::Platform::current(), pe_i18n::language());
    pe_i18n::tr_args(pe_i18n::Text::PgpKeyserverOff, &[("settings", (&settings).into())])
}

/// What learns a lookup's keys off the window thread: the store's file, the password store and the certificates read
struct Learner {
    path: std::path::PathBuf,
    secrets: Secrets,
    certs: std::sync::Arc<CertCache>,
}

impl Learner {
    /// What was found, learned on a store connection of its own as any key is (a different key for an address that
    /// has one waits), each address's lookup remembered; what it came to
    fn learn(self, found: Vec<(String, pe_keys::Found)>) -> FindOutcome {
        match pe_store::Store::open(&self.path) {
            Ok(store) => learn_found(&store, &self.secrets, &self.certs, found, unix_now()),
            Err(error) => FindOutcome {
                addresses: Vec::new(),
                text: tr_args(Text::PgpFindUnavailable, &[("error", (&error.to_string()).into())]),
                learned: 0,
            },
        }
    }
}

fn learn_found(
    store: &pe_store::Store,
    secrets: &Secrets,
    certs: &CertCache,
    found: Vec<(String, pe_keys::Found)>,
    now: i64,
) -> FindOutcome {
    let book = Book::new(store, secrets, certs).ok();
    let mut addresses = Vec::new();
    let mut used = Vec::new();
    let mut waiting = Vec::new();
    let mut unavailable = None;
    let mut learned_any = false;
    for (address, found) in found {
        let mut has_key = false;
        match found {
            pe_keys::Found::Key(bytes, source) => {
                let source = match source {
                    pe_keys::Source::Wkd => KeySource::Wkd,
                    pe_keys::Source::Keyserver => KeySource::Keyserver,
                };
                let certs = pe_pgp::read_certs(&bytes).unwrap_or_default();
                for cert in &certs {
                    let learned = book
                        .as_ref()
                        .and_then(|book| book.learn(cert, source).ok())
                        .unwrap_or_default();
                    learned_any = true;
                    for (held, what) in learned {
                        match what {
                            Learned::Used | Learned::Same => used.push(held.clone()),
                            Learned::Pending => waiting.push(held.clone()),
                            Learned::Own => {}
                        }
                        if held == address {
                            has_key = matches!(what, Learned::Used | Learned::Same);
                        }
                    }
                }
                if !address.is_empty() {
                    let _ = store.set_pgp_lookup(&address, now, true);
                }
            }
            pe_keys::Found::NotFound => {
                if !address.is_empty() {
                    let _ = store.set_pgp_lookup(&address, now, false);
                }
            }
            pe_keys::Found::Unavailable(why) => unavailable = Some(why),
        }
        if !address.is_empty() {
            addresses.push((address, has_key));
        }
    }
    let missing: Vec<&str> = addresses
        .iter()
        .filter(|(_, has)| !has)
        .map(|(address, _)| address.as_str())
        .collect();
    let mut text = Vec::new();
    if !used.is_empty() {
        text.push(tr_args(Text::PgpFoundKeys, &[("addresses", (&used.join(", ")).into())]));
    }
    if !waiting.is_empty() {
        text.push(tr_args(
            Text::PgpImportedPending,
            &[("addresses", (&waiting.join(", ")).into())],
        ));
    }
    if let Some(why) = unavailable {
        text.push(tr_args(Text::PgpFindUnavailable, &[("error", (&why).into())]));
    } else if !missing.is_empty() {
        text.push(tr_args(
            Text::PgpFoundNone,
            &[("addresses", (&missing.join(", ")).into())],
        ));
    } else if !learned_any && addresses.is_empty() {
        text.push(tr(Text::PgpFoundNoKey));
    }
    FindOutcome {
        text: text.join(" "),
        learned: used.len() + waiting.len(),
        addresses,
    }
}
