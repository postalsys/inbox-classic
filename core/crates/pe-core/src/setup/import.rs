//! Reading a setup file for the import window, and importing the parts and accounts the user chose: an account here
//! already is skipped, contacts merge as Import Address Book merges them, settings are replaced, rules are added
//! unless the same rule is here, and keys follow the key book's rules.

use std::collections::HashSet;
use std::io::Read;
use std::path::Path;

use pe_i18n::{Text, tr, tr_args};
use pe_store::{AccountId, Group, Member, Rule, Store};

use super::file::{AccountRef, FileApp, FileRule, SignInRef, parse};
use super::{MAX_FILE, Parts, SetupError, SetupFile, count_text};
use crate::keys::{Book, KeySource, Learned};
use crate::secrets::Key;
use crate::sign_in_apps::{SignInWith, with_provider};
use crate::{Core, Error, Result};

/// What an import takes of a setup file
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ImportChoice {
    /// The parts, of those the file holds
    pub parts: Parts,
    /// The accounts, by their place in the file ([`super::SetupAccount::index`])
    pub accounts: Vec<usize>,
}

/// What a line of an import's summary tells
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImportLineKind {
    Added,
    Skipped,
    /// Something to know or to do: an account that asks for its password, a key that waits for a decision
    Note,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImportLine {
    pub kind: ImportLineKind,
    pub text: String,
}

/// What an import did, a line each, and the accounts it added (syncing)
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ImportSummary {
    pub lines: Vec<ImportLine>,
    pub accounts: Vec<AccountId>,
}

impl ImportSummary {
    fn line(&mut self, kind: ImportLineKind, text: String) {
        self.lines.push(ImportLine { kind, text });
    }

    /// A line of a count, when it is not 0
    fn count(&mut self, kind: ImportLineKind, text: Text, count: usize) {
        if count > 0 {
            self.line(kind, count_text(text, count));
        }
    }
}

/// The account here that `reference` names (the same address and IMAP server)
fn account_here(accounts: &[pe_store::Account], reference: &AccountRef) -> Option<AccountId> {
    accounts
        .iter()
        .find(|account| reference.is(&account.settings))
        .map(|account| account.id)
}

/// The sign-in app here with this issuer and client id
fn app_here(store: &Store, issuer: &str, client_id: &str) -> Result<Option<pe_store::SignInAppId>> {
    Ok(store
        .sign_in_apps()?
        .into_iter()
        .find(|stored| stored.app.issuer == issuer && stored.app.client_id == client_id)
        .map(|stored| stored.id))
}

impl Core {
    /// Reads the setup file at `path`, opened with `passphrase` when it is sealed with one, and checks everything in
    /// it: what it holds, for the import window, which marks the accounts set up here already. Nothing changes.
    pub fn read_setup(&self, path: &Path, passphrase: Option<&str>) -> std::result::Result<SetupFile, SetupError> {
        let unreadable = |error: std::io::Error| {
            SetupError::Invalid(tr_args(Text::SetupErrorRead, &[("error", (&error.to_string()).into())]))
        };
        let file = std::fs::File::open(path).map_err(unreadable)?;
        if file.metadata().map_err(unreadable)?.len() > MAX_FILE as u64 {
            return Err(SetupError::invalid(Text::SetupErrorTooLarge));
        }
        let mut bytes = Vec::new();
        file.take(MAX_FILE as u64 + 1)
            .read_to_end(&mut bytes)
            .map_err(unreadable)?;
        let mut setup = parse(&bytes, passphrase)?;
        self.mark_setup(&mut setup)
            .map_err(|error| SetupError::Invalid(error.to_string()))?;
        Ok(setup)
    }

    /// Marks the accounts of `setup` set up here already, and says what an import does with each
    fn mark_setup(&self, setup: &mut SetupFile) -> Result<()> {
        let store = self.store();
        let accounts = store.accounts()?;
        for (row, account) in setup.accounts.iter_mut().zip(&setup.data.accounts) {
            if row.problem.is_some() {
                continue;
            }
            let reference = AccountRef {
                email: account.settings.email.clone(),
                imap_host: account.settings.imap_host.clone(),
            };
            row.here = account_here(&accounts, &reference).is_some();
            if let SignInRef::App { issuer, client_id } = &account.sign_in
                && !setup.data.apps.iter().any(|app| same_app(app, issuer, client_id))
                && app_here(&store, issuer, client_id)?.is_none()
            {
                row.problem = Some(tr_args(Text::SetupAccountNoApp, &[("app", (&row.sign_in).into())]));
                continue;
            }
            let oauth = account.sign_in != SignInRef::Password;
            row.note = tr(match (row.here, row.has_secret, oauth) {
                (true, _, _) => Text::SetupAccountHere,
                (false, true, false) => Text::SetupAccountSecretPassword,
                (false, true, true) => Text::SetupAccountSecretToken,
                (false, false, false) => Text::SetupAccountAsksPassword,
                (false, false, true) => Text::SetupAccountSignsInAgain,
            });
        }
        Ok(())
    }

    /// Imports the parts and accounts of `setup` that `choice` names. Accounts added start syncing; one without its
    /// password asks for it as an account whose password is missing does.
    pub fn import_setup(&self, setup: &SetupFile, choice: &ImportChoice) -> Result<ImportSummary> {
        let parts = Parts(choice.parts.known().0 & setup.parts.0);
        if parts.is_empty() {
            return Err(Error::Invalid(tr(Text::SetupErrorNoParts)));
        }
        let mut summary = ImportSummary::default();
        // the sign-in apps first: the accounts may sign in with them
        if parts.has(Parts::SIGN_IN_APPS) {
            self.import_apps(setup, &mut summary)?;
        }
        if parts.has(Parts::ACCOUNTS) {
            self.import_accounts(setup, &choice.accounts, &mut summary)?;
        }
        if parts.has(Parts::SETTINGS) {
            self.import_settings(setup)?;
            summary.line(ImportLineKind::Added, tr(Text::SetupImportedSettings));
        }
        if parts.has(Parts::PREFERENCES) && !setup.prefs.is_empty() {
            summary.line(ImportLineKind::Added, tr(Text::SetupImportedPreferences));
        }
        if parts.has(Parts::CONTACTS) {
            self.import_contacts(setup, &mut summary)?;
        }
        // after the accounts: an own key is used for the own addresses it holds
        if parts.has(Parts::KEYS) {
            self.import_keys(setup, &mut summary)?;
        }
        if parts.has(Parts::RULES) {
            self.import_rules(setup, &mut summary)?;
        }
        if parts.has(Parts::TRUSTED_SENDERS) {
            let store = self.store();
            let before: HashSet<String> = store.trusted_senders()?.into_iter().map(|s| s.value).collect();
            let mut added = 0;
            for (value, domain) in &setup.data.trusted {
                if !before.contains(value) && store.trust_sender(value, *domain).is_ok() {
                    added += 1;
                }
            }
            summary.count(ImportLineKind::Added, Text::SetupAddedTrustedSenders, added);
        }
        if summary.lines.is_empty() {
            summary.line(ImportLineKind::Note, tr(Text::SetupNothing));
        }
        Ok(summary)
    }

    fn import_apps(&self, setup: &SetupFile, summary: &mut ImportSummary) -> Result<()> {
        let store = self.store();
        for (kind, on) in &setup.data.builtin {
            store.set_builtin_sign_in_enabled(kind.as_str(), *on)?;
        }
        let (mut added, mut skipped) = (0, 0);
        for FileApp { app, secret } in &setup.data.apps {
            if app_here(&store, &app.issuer, &app.client_id)?.is_some() {
                skipped += 1;
                continue;
            }
            let app = pe_store::SignInApp {
                has_secret: secret.is_some(),
                ..app.clone()
            };
            let id = store.add_sign_in_app(&app)?;
            // an app removed before may have had this id: its secret goes
            self.secrets.remove(Key::App(id));
            if let Some(secret) = secret
                && let Err(why) = self.secrets.set(Key::App(id), secret)
            {
                summary.line(ImportLineKind::Note, why);
            }
            added += 1;
        }
        summary.count(ImportLineKind::Added, Text::SetupAddedSignInApps, added);
        summary.count(ImportLineKind::Skipped, Text::SetupSkippedSignInApps, skipped);
        Ok(())
    }

    fn import_accounts(&self, setup: &SetupFile, chosen: &[usize], summary: &mut ImportSummary) -> Result<()> {
        let mut added = Vec::new();
        let mut notes = Vec::new();
        for (row, account) in setup.accounts.iter().zip(&setup.data.accounts) {
            if !chosen.contains(&row.index) {
                continue;
            }
            let address = (&row.email).into();
            if let Some(problem) = &row.problem {
                summary.line(
                    ImportLineKind::Skipped,
                    tr_args(
                        Text::SetupSkippedInvalid,
                        &[("address", address), ("reason", problem.into())],
                    ),
                );
                continue;
            }
            let reference = AccountRef {
                email: account.settings.email.clone(),
                imap_host: account.settings.imap_host.clone(),
            };
            if account_here(&self.store().accounts()?, &reference).is_some() {
                summary.line(
                    ImportLineKind::Skipped,
                    tr_args(Text::SetupSkippedHere, &[("address", address)]),
                );
                continue;
            }
            let with = match &account.sign_in {
                SignInRef::Password => None,
                SignInRef::Builtin(kind) => Some(SignInWith::Builtin(*kind)),
                SignInRef::App { issuer, client_id } => match app_here(&self.store(), issuer, client_id)? {
                    Some(id) => Some(SignInWith::App(id)),
                    None => {
                        summary.line(
                            ImportLineKind::Skipped,
                            tr_args(
                                Text::SetupSkippedNoApp,
                                &[("address", address), ("app", (&row.sign_in).into())],
                            ),
                        );
                        continue;
                    }
                },
            };
            let settings = match with {
                None => account.settings.clone(),
                // an access token goes to the provider's own servers only
                Some(with) => {
                    let auth = pe_store::Auth::OAuth2(with.auth_name());
                    with_provider(&account.settings, &self.sign_in_provider(with)?, &auth)
                }
            };
            let id = {
                let store = self.store();
                let id = store.add_account(&settings)?;
                let name = match account.account_name.as_str() {
                    "" => crate::default_account_name(&settings.email),
                    name => name.to_string(),
                };
                store.set_account_name(id, &name)?;
                store.set_signature(id, &account.signature)?;
                store.set_account_addresses(id, &account.addresses)?;
                id
            };
            // an account removed before may have had this id: its password goes, whatever happens to this one
            self.secrets.remove(id);
            match &account.secret {
                Some(secret) => self.keep_password(id, secret),
                None => notes.push(tr_args(
                    if with.is_some() {
                        Text::SetupSignsInAgain
                    } else {
                        Text::SetupAsksPassword
                    },
                    &[("address", (&settings.email).into())],
                )),
            }
            added.push(id);
        }
        summary.count(ImportLineKind::Added, Text::SetupAddedAccounts, added.len());
        for note in notes {
            summary.line(ImportLineKind::Note, note);
        }
        for &id in &added {
            self.sync(id)?;
        }
        summary.accounts = added;
        Ok(())
    }

    fn import_settings(&self, setup: &SetupFile) -> Result<()> {
        let Some(settings) = &setup.data.settings else {
            return Ok(());
        };
        if let Some(on) = settings.dark_messages {
            self.set_dark_messages(on)?;
        }
        if let Some(size) = settings.text_size {
            self.set_text_size(size)?;
        }
        if let Some(ahead) = settings.download_ahead.as_deref().and_then(pe_store::Ahead::of_key) {
            self.set_download_ahead(ahead)?;
        }
        if let Some(limit) = settings.download_limit_mb {
            self.set_download_limit_mb(limit)?;
        }
        if let Some(on) = settings.always_load_pictures {
            self.set_always_load_pictures(on)?;
        }
        if let Some(on) = settings.pgp_keyserver {
            self.set_pgp_keyserver(on)?;
        }
        if let Some(delay) = settings.send_delay {
            self.set_send_delay(delay)?;
        }
        Ok(())
    }

    fn import_contacts(&self, setup: &SetupFile, summary: &mut ImportSummary) -> Result<()> {
        let (added, skipped) = self.store().import_cards(&setup.data.cards)?;
        summary.count(ImportLineKind::Added, Text::SetupAddedContacts, added as usize);
        summary.count(ImportLineKind::Skipped, Text::SetupSkippedContacts, skipped as usize);
        let mut groups = 0;
        for group in &setup.data.groups {
            let (existing, members) = {
                let store = self.store();
                let existing = store
                    .groups("")?
                    .into_iter()
                    .find(|known| known.name.trim().eq_ignore_ascii_case(&group.name))
                    .map(|known| store.group(known.id))
                    .transpose()?
                    .flatten();
                // a member with a card here is kept by the card, as Group Properties keeps one
                let mut members = Vec::new();
                for (name, address) in &group.members {
                    members.push(match store.card_by_address(address)? {
                        Some(card) => Member {
                            card: Some(card.id),
                            name: card.name,
                            address: address.clone(),
                        },
                        None => Member {
                            card: None,
                            name: name.clone(),
                            address: address.clone(),
                        },
                    });
                }
                (existing, members)
            };
            let saved = match existing {
                Some(existing) => {
                    let merged = crate::book::add_members(&existing.members, &members);
                    if merged.len() == existing.members.len() {
                        continue;
                    }
                    Group {
                        members: merged,
                        ..existing
                    }
                }
                None => Group {
                    id: 0,
                    name: group.name.clone(),
                    members,
                },
            };
            self.save_group(&saved)?;
            groups += 1;
        }
        summary.count(ImportLineKind::Added, Text::SetupAddedGroups, groups);
        Ok(())
    }

    fn import_keys(&self, setup: &SetupFile, summary: &mut ImportSummary) -> Result<()> {
        let store = self.store();
        let book = Book::new(&store, &self.secrets, &self.pgp_certs)?;
        let now = crate::worker::unix_now();
        let (mut contacts, mut own) = (0, 0);
        let mut waiting: Vec<String> = Vec::new();
        for (cert, verified) in &setup.data.contact_keys {
            let fingerprint = cert.fingerprint();
            let known = store.pgp_key(&fingerprint)?.is_some();
            for (address, learned) in book.learn(cert, KeySource::File)? {
                if learned == Learned::Pending && !waiting.contains(&address) {
                    waiting.push(address);
                }
            }
            for address in verified {
                if cert.has_address(address, now) {
                    store.set_pgp_verified(&fingerprint, address, true)?;
                }
            }
            contacts += usize::from(!known);
        }
        for (key, identities) in &setup.data.own_keys {
            let fingerprint = key.fingerprint();
            let known = store
                .pgp_key(&fingerprint)?
                .is_some_and(|stored| stored.secret.is_some());
            if let Err(error) = book.keep_secret(key, KeySource::File, false) {
                summary.line(ImportLineKind::Note, error.to_string());
                break;
            }
            let own_here = book.own_addresses()?.clone();
            for (address, autocrypt) in identities {
                // only an address of an account here, and one that has no key of its own yet
                if own_here.contains(address)
                    && key.cert().has_address(address, now)
                    && store.pgp_identity(address)?.is_none()
                {
                    store.set_pgp_identity(&pe_store::PgpIdentity {
                        address: address.clone(),
                        fingerprint: fingerprint.clone(),
                        autocrypt: *autocrypt,
                    })?;
                }
            }
            own += usize::from(!known);
        }
        summary.count(ImportLineKind::Added, Text::SetupAddedOwnKeys, own);
        summary.count(ImportLineKind::Added, Text::SetupAddedContactKeys, contacts);
        if !waiting.is_empty() {
            summary.line(
                ImportLineKind::Note,
                tr_args(Text::PgpImportedPending, &[("addresses", (&waiting.join(", ")).into())]),
            );
        }
        Ok(())
    }

    fn import_rules(&self, setup: &SetupFile, summary: &mut ImportSummary) -> Result<()> {
        let store = self.store();
        let accounts = store.accounts()?;
        let (mut added, mut same, mut elsewhere, mut waiting) = (0, 0, 0, 0);
        for FileRule { rule, account, move_to } in &setup.data.rules {
            let account = match account {
                Some(reference) => match account_here(&accounts, reference) {
                    Some(id) => Some(id),
                    None => {
                        elsewhere += 1;
                        continue;
                    }
                },
                None => None,
            };
            // the folder by its path, or the account and path to wait for until its account syncs
            let (folder, pending) = match move_to {
                Some(target) => match account_here(&accounts, &target.account) {
                    None => {
                        elsewhere += 1;
                        continue;
                    }
                    Some(owner) => match store.find_folder(owner, &target.path)? {
                        Some(folder) => (Some(folder.id), None),
                        None => (None, Some((owner, target.path.clone()))),
                    },
                },
                None => (None, None),
            };
            let rule = Rule {
                account,
                move_to: folder,
                ..rule.clone()
            };
            if is_here(&store, &rule, pending.as_ref())? {
                same += 1;
                continue;
            }
            let id = store.save_rule(&rule)?;
            if let Some((owner, path)) = &pending {
                store.set_rule_pending_target(id, *owner, path)?;
                waiting += 1;
            }
            added += 1;
        }
        summary.count(ImportLineKind::Added, Text::SetupAddedRules, added);
        summary.count(ImportLineKind::Skipped, Text::SetupSkippedRules, same);
        summary.count(ImportLineKind::Skipped, Text::SetupSkippedRulesAccount, elsewhere);
        summary.count(ImportLineKind::Note, Text::SetupRulesWaiting, waiting);
        Ok(())
    }
}

/// Whether the same rule is here: the same query for the same Inbox, doing the same
fn is_here(store: &Store, rule: &Rule, pending: Option<&(AccountId, String)>) -> Result<bool> {
    for known in store.rules()? {
        let same = known.query == rule.query
            && known.account == rule.account
            && known.move_to == rule.move_to
            && (
                known.mark_read,
                known.flag,
                known.archive,
                known.junk,
                known.remove,
                known.quiet,
            ) == (
                rule.mark_read,
                rule.flag,
                rule.archive,
                rule.junk,
                rule.remove,
                rule.quiet,
            );
        if same && store.rule_pending_target(known.id)?.as_ref() == pending {
            return Ok(true);
        }
    }
    Ok(false)
}

fn same_app(app: &FileApp, issuer: &str, client_id: &str) -> bool {
    app.app.issuer == issuer && app.app.client_id == client_id
}
