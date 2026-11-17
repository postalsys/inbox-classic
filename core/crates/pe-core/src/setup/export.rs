//! Writing a setup file: the parts chosen, from the store and the system's password store, as the JSON of `file.rs`,
//! sealed with the passphrase when there is one.

use std::collections::{BTreeMap, HashMap};
use std::path::Path;

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use pe_i18n::{Text, tr, tr_args};
use pe_oauth::ProviderKind;
use pe_store::{AccountId, Card, Store};
use zeroize::Zeroizing;

use super::file::{
    AccountEntry, AccountRef, AddressEntry, AppEntry, AppsPart, ContactKeyEntry, ContactsPart, Document, FolderRef,
    GroupEntry, IdentityEntry, KeysPart, OwnKeyEntry, RuleEntry, Server, SettingsPart, SignInEntry, TrustedEntry,
    part_lines,
};
use super::{FORMAT, MAX_FILE, Parts, SetupCounts, VERSION, pref_value};
use crate::keys::Book;
use crate::secrets::Key;
use crate::sign_in_apps::SignInWith;
use crate::{Core, Error, Result};

impl Core {
    /// Writes a setup file at `path` with the `parts` chosen. With `passphrase` (8 characters or more, as a key
    /// backup's) the whole file is sealed with it and carries the secrets too: the accounts' passwords and refresh
    /// tokens, the sign-in apps' client secrets, the user's own private keys. `prefs` are the app's preferences by
    /// the names of [`super::PREFERENCES`], as text; others are left out. Returns each part written with what it
    /// holds, in words. A `path` without an extension gets [`super::EXTENSION`].
    pub fn export_setup(
        &self,
        path: &Path,
        parts: Parts,
        passphrase: Option<&str>,
        prefs: &[(String, String)],
    ) -> Result<Vec<(Parts, String)>> {
        let parts = parts.known();
        if parts.is_empty() {
            return Err(Error::Invalid(tr(Text::SetupErrorNoParts)));
        }
        let passphrase = passphrase.filter(|p| !p.is_empty());
        if let Some(why) = passphrase.and_then(|p| crate::keys::passphrase_problem(p, p)) {
            return Err(Error::Invalid(why));
        }
        let (document, counts) = self.setup_document(parts, passphrase.is_some(), prefs)?;
        let mut json = Zeroizing::new(serde_json::to_vec(&document).map_err(|e| Error::Invalid(e.to_string()))?);
        drop(document);
        if json.len() > MAX_FILE {
            return Err(Error::Invalid(tr(Text::SetupErrorTooLarge)));
        }
        let sealed = match passphrase {
            // moved into the sealing, not copied
            Some(passphrase) => Some(Zeroizing::new(
                pe_pgp::sealed::seal(std::mem::take(&mut *json), passphrase)
                    .map_err(|e| Error::Invalid(e.to_string()))?
                    .into_bytes(),
            )),
            None => None,
        };
        let bytes: &[u8] = sealed.as_deref().map_or(&json, |sealed| sealed);
        write_private(&super::with_extension(path), bytes).map_err(|error| {
            Error::Unavailable(tr_args(
                Text::SetupErrorWrite,
                &[("error", (&error.to_string()).into())],
            ))
        })?;
        Ok(part_lines(parts, &counts, false))
    }

    /// The document of `parts`, with the secrets when `secrets`, and how much each part holds
    fn setup_document(
        &self,
        parts: Parts,
        secrets: bool,
        prefs: &[(String, String)],
    ) -> Result<(Document, SetupCounts)> {
        let store = self.store();
        let mut counts = SetupCounts::default();
        let mut document = Document {
            format: FORMAT.into(),
            version: VERSION,
            app_version: crate::VERSION.into(),
            created: crate::worker::unix_now(),
            ..Document::default()
        };
        if parts.has(Parts::SETTINGS) {
            let settings = settings_part(&store)?;
            counts.settings = settings.count();
            document.settings = Some(settings);
        }
        if parts.has(Parts::PREFERENCES) {
            let kept: BTreeMap<String, String> = prefs
                .iter()
                .filter_map(|(name, value)| Some((name.clone(), pref_value(name, value)?)))
                .collect();
            counts.preferences = kept.len();
            document.preferences = Some(kept);
        }
        if parts.has(Parts::ACCOUNTS) {
            let accounts = self.account_entries(&store, secrets)?;
            counts.accounts = accounts.len();
            document.accounts = Some(accounts);
        }
        if parts.has(Parts::SIGN_IN_APPS) {
            let apps = self.apps_part(&store, secrets)?;
            counts.sign_in_apps = apps.apps.len();
            counts.builtin = 2;
            document.sign_in_apps = Some(apps);
        }
        if parts.has(Parts::CONTACTS) {
            let (contacts, people) = contacts_part(&store)?;
            counts.contacts = people;
            counts.groups = contacts.groups.len();
            document.contacts = Some(contacts);
        }
        if parts.has(Parts::KEYS) {
            let book = Book::new(&store, &self.secrets, &self.pgp_certs)?;
            let keys = keys_part(&store, &book, secrets)?;
            counts.own_keys = keys.own.len();
            counts.contact_keys = keys.contacts.len();
            document.keys = Some(keys);
        }
        if parts.has(Parts::RULES) {
            let rules = rule_entries(&store)?;
            counts.rules = rules.len();
            document.rules = Some(rules);
        }
        if parts.has(Parts::TRUSTED_SENDERS) {
            let trusted: Vec<TrustedEntry> = store
                .trusted_senders()?
                .into_iter()
                .map(|sender| TrustedEntry {
                    value: sender.value,
                    domain: sender.domain,
                })
                .collect();
            counts.trusted_senders = trusted.len();
            document.trusted_senders = Some(trusted);
        }
        Ok((document, counts))
    }

    fn account_entries(&self, store: &Store, secrets: bool) -> Result<Vec<AccountEntry>> {
        let mut entries = Vec::new();
        for account in store.accounts()? {
            let settings = &account.settings;
            let sign_in = match &settings.auth {
                pe_store::Auth::Password => SignInEntry::Password,
                pe_store::Auth::OAuth2(name) => match SignInWith::of_auth(name) {
                    Some(SignInWith::Builtin(ProviderKind::Google)) => SignInEntry::Google,
                    Some(SignInWith::Builtin(ProviderKind::Microsoft)) => SignInEntry::Microsoft,
                    Some(SignInWith::App(id)) => {
                        let app = store.sign_in_app(id)?.app;
                        SignInEntry::App {
                            issuer: app.issuer,
                            client_id: app.client_id,
                        }
                    }
                    // signs in with something that is not here: nothing another computer could sign in with
                    _ => continue,
                },
            };
            entries.push(AccountEntry {
                email: settings.email.clone(),
                name: settings.name.clone(),
                account_name: account.account_name.clone(),
                username: settings.username.clone(),
                imap: Server::of(&settings.imap_host, settings.imap_port, settings.imap_security),
                smtp: Server::of(&settings.smtp_host, settings.smtp_port, settings.smtp_security),
                sign_in,
                signature: store.signature(account.id)?,
                addresses: store
                    .account_addresses(account.id)?
                    .into_iter()
                    .map(|(email, name)| AddressEntry { email, name })
                    .collect(),
                secret: secrets.then(|| self.secrets.get(account.id)).flatten(),
            });
        }
        Ok(entries)
    }

    fn apps_part(&self, store: &Store, secrets: bool) -> Result<AppsPart> {
        let apps = store
            .sign_in_apps()?
            .into_iter()
            .map(|stored| {
                let app = stored.app;
                let secret = (secrets && app.has_secret)
                    .then(|| self.secrets.get(Key::App(stored.id)))
                    .flatten();
                AppEntry {
                    imap: Server::of(&app.imap_host, app.imap_port, app.imap_security),
                    smtp: Server::of(&app.smtp_host, app.smtp_port, app.smtp_security),
                    name: app.name,
                    issuer: app.issuer,
                    client_id: app.client_id,
                    scopes: app.scopes,
                    enabled: app.enabled,
                    secret,
                }
            })
            .collect();
        Ok(AppsPart {
            google: Some(store.builtin_sign_in_enabled(ProviderKind::Google.as_str())?),
            microsoft: Some(store.builtin_sign_in_enabled(ProviderKind::Microsoft.as_str())?),
            apps,
        })
    }
}

fn settings_part(store: &Store) -> Result<SettingsPart> {
    Ok(SettingsPart {
        dark_messages: Some(store.dark_messages()?),
        text_size: Some(store.text_size()?.unwrap_or(crate::TEXT_SIZE_MEDIUM)),
        download_ahead: Some(store.download_ahead()?.key().to_string()),
        download_limit_mb: Some(store.download_limit_mb()?),
        always_load_pictures: Some(store.always_load_pictures()?),
        pgp_keyserver: Some(store.pgp_keyserver()?),
        pgp_index_encrypted: Some(store.pgp_index_encrypted()?),
        send_delay: Some(store.send_delay()?),
    })
}

/// The address book as vCards with their pictures (their keys go in the keys part), and its groups; and how many
/// people
fn contacts_part(store: &Store) -> Result<(ContactsPart, usize)> {
    let cards = store
        .cards("")?
        .into_iter()
        .map(|card| {
            let picture = store.card_picture(card.id)?.map(|(png, _)| png);
            Ok(Card { picture, ..card })
        })
        .collect::<pe_store::Result<Vec<Card>>>()?;
    let mut groups = Vec::new();
    for group in store.groups("")? {
        groups.push(GroupEntry {
            name: group.name,
            members: group
                .members
                .into_iter()
                .filter(|member| !member.address.is_empty())
                .map(|member| AddressEntry {
                    email: member.address,
                    name: member.name,
                })
                .collect(),
        });
    }
    let contacts = ContactsPart {
        vcards: crate::vcard::write_vcards(&cards),
        groups,
    };
    Ok((contacts, cards.len()))
}

/// The contacts' keys in use for one of their addresses (a key no address uses is one the user did not take), and
/// with `secrets` the user's own private keys that open, with the addresses that use them
fn keys_part(store: &Store, book: &Book<'_>, secrets: bool) -> Result<KeysPart> {
    let identities = store.pgp_identities()?;
    let mut part = KeysPart::default();
    for key in store.pgp_keys()? {
        let held = store.pgp_key_addresses(Some(&key.fingerprint))?;
        if key.secret.is_some() {
            if !secrets {
                continue;
            }
            // a key whose master key is gone can not be carried: it can not be opened here either
            let Ok(secret) = book.own_key(&key.fingerprint) else {
                continue;
            };
            part.own.push(OwnKeyEntry {
                key: STANDARD.encode(&*secret.to_bytes()),
                identities: identities
                    .iter()
                    .filter(|identity| identity.fingerprint == key.fingerprint)
                    .map(|identity| IdentityEntry {
                        address: identity.address.clone(),
                        autocrypt: identity.autocrypt,
                    })
                    .collect(),
            });
            continue;
        }
        let mut in_use = false;
        for address in &held {
            in_use = store
                .pgp_peer(&address.address)?
                .and_then(|peer| peer.fingerprint)
                .is_some_and(|used| used == key.fingerprint);
            if in_use {
                break;
            }
        }
        if in_use {
            part.contacts.push(ContactKeyEntry {
                cert: STANDARD.encode(&key.cert),
                verified: held
                    .into_iter()
                    .filter(|address| address.verified)
                    .map(|address| address.address)
                    .collect(),
            });
        }
    }
    Ok(part)
}

fn rule_entries(store: &Store) -> Result<Vec<RuleEntry>> {
    let accounts: HashMap<AccountId, AccountRef> = store
        .accounts()?
        .iter()
        .map(|account| (account.id, AccountRef::of(&account.settings)))
        .collect();
    let named = |id: AccountId| accounts.get(&id).cloned().ok_or(Error::NotFound);
    let mut entries = Vec::new();
    for rule in store.rules()? {
        let account = rule.account.map(named).transpose()?;
        let move_to = match (rule.move_to, store.rule_pending_target(rule.id)?) {
            (Some(folder), _) => match store.folder(folder) {
                Ok(folder) => Some(FolderRef {
                    account: named(folder.account_id)?,
                    path: folder.info.path,
                }),
                Err(_) => None,
            },
            (None, Some((account, path))) => Some(FolderRef {
                account: named(account)?,
                path,
            }),
            (None, None) => None,
        };
        entries.push(RuleEntry {
            name: rule.name,
            enabled: rule.enabled,
            account,
            query: rule.query,
            move_to,
            mark_read: rule.mark_read,
            flag: rule.flag,
            archive: rule.archive,
            junk: rule.junk,
            remove: rule.remove,
            quiet: rule.quiet,
        });
    }
    Ok(entries)
}

/// Writes `bytes` at `path` readable by this user only (it may carry secrets, sealed), through a file beside it that
/// takes its place once complete
fn write_private(path: &Path, bytes: &[u8]) -> std::io::Result<()> {
    use std::io::Write;
    let name = path
        .file_name()
        .ok_or_else(|| std::io::Error::new(std::io::ErrorKind::InvalidInput, "no file name"))?;
    let partial = path.with_file_name(format!(".{}.{}.part", name.to_string_lossy(), std::process::id()));
    let mut options = std::fs::OpenOptions::new();
    options.write(true).create(true).truncate(true);
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        options.mode(0o600);
    }
    let written = (|| {
        let mut file = options.open(&partial)?;
        file.write_all(bytes)?;
        file.sync_all()?;
        drop(file);
        std::fs::rename(&partial, path)
    })();
    if written.is_err() {
        let _ = std::fs::remove_file(&partial);
    }
    written
}
