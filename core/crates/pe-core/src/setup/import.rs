//! Reading a setup file for the import window, and importing the parts and accounts the user chose: an account here
//! already is skipped, contacts merge as Import Address Book merges them, settings are replaced, rules are added
//! unless the same rule is here, and keys follow the key book's rules. A sign-in app is saved with the endpoints its
//! issuer's discovery document gives now, as the sign-in apps window saves one: never with any a file names.

use std::collections::{HashMap, HashSet};
use std::io::Read;
use std::path::Path;

use pe_i18n::{Text, tr, tr_args};
use pe_oauth::Discovered;
use pe_store::{AccountId, CardId, FolderId, Group, Member, Rule, StoredSignInApp};

use super::file::{AccountRef, FileAccount, FileRule, SignInRef, parse};
use super::{MAX_FILE, Parts, SetupAccount, SetupError, SetupFile, count_text};
use crate::keys::{Book, KeySource, Learned};
use crate::secrets::Key;
use crate::sign_in_apps::{SignInWith, checked_app, same_client, with_provider};
use crate::{Core, Error, Event, Result};

/// What an import takes of a setup file
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ImportChoice {
    /// The parts, of those the file holds; [`Parts::ACCOUNTS`] follows from `accounts`
    pub parts: Parts,
    /// The accounts, by their place in the file ([`super::SetupAccount::index`]); none for no accounts
    pub accounts: Vec<usize>,
}

impl ImportChoice {
    /// The parts it takes: the accounts part when it names accounts, never when it names none
    fn parts(&self) -> Parts {
        let others = Parts(self.parts.known().0 & !Parts::ACCOUNTS.0);
        if self.accounts.is_empty() {
            others
        } else {
            others.with(Parts::ACCOUNTS)
        }
    }
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

/// What became of one account of a file
enum Outcome {
    /// Added, with what it asks for once it connects
    Added(AccountId, Option<String>),
    /// Not added, and why, in words
    Skipped(String),
}

/// The sign-in apps of a file whose issuer could not be read, by issuer and client id
type Unreachable = HashSet<(String, String)>;

/// A rule as an import compares it with those here: query, account, folder, actions, the folder it waits for
type RuleKey = (
    String,
    Option<AccountId>,
    Option<FolderId>,
    [bool; 6],
    Option<(AccountId, String)>,
);

fn rule_key(rule: &Rule, pending: Option<(AccountId, String)>) -> RuleKey {
    let actions = [
        rule.mark_read,
        rule.flag,
        rule.archive,
        rule.junk,
        rule.remove,
        rule.quiet,
    ];
    (rule.query.clone(), rule.account, rule.move_to, actions, pending)
}

/// The account here that `reference` names (the same address and IMAP server)
fn account_here(accounts: &[pe_store::Account], reference: &AccountRef) -> Option<AccountId> {
    accounts
        .iter()
        .find(|account| reference.is(&account.settings))
        .map(|account| account.id)
}

impl Core {
    /// Reads the setup file at `path`, opened with `passphrase` when it is sealed with one, and checks everything in
    /// it: what it holds, for the import window, which marks the accounts set up here already. Nothing changes. A
    /// sealed file read without a passphrase is told from its first bytes, before the rest is read.
    pub fn read_setup(&self, path: &Path, passphrase: Option<&str>) -> std::result::Result<SetupFile, SetupError> {
        let unreadable = |error: std::io::Error| {
            SetupError::Invalid(tr_args(Text::SetupErrorRead, &[("error", (&error.to_string()).into())]))
        };
        let mut file = std::fs::File::open(path).map_err(unreadable)?;
        if file.metadata().map_err(unreadable)?.len() > MAX_FILE as u64 {
            return Err(SetupError::invalid(Text::SetupErrorTooLarge));
        }
        let mut bytes = Vec::new();
        (&mut file).take(64).read_to_end(&mut bytes).map_err(unreadable)?;
        let head = bytes.strip_prefix("\u{feff}".as_bytes()).unwrap_or(&bytes);
        if pe_pgp::sealed::looks_sealed(head) && passphrase.is_none_or(str::is_empty) {
            return Err(SetupError::NeedsPassphrase);
        }
        file.take(MAX_FILE as u64 + 1)
            .read_to_end(&mut bytes)
            .map_err(unreadable)?;
        let mut setup = parse(&bytes, passphrase)?;
        self.mark_setup(&mut setup)
            .map_err(|error| SetupError::Invalid(error.to_string()))?;
        Ok(setup)
    }

    /// Marks the accounts of `setup` set up here already, those whose sign-in app is nowhere, and says what an
    /// import does with each
    fn mark_setup(&self, setup: &mut SetupFile) -> Result<()> {
        let store = self.store();
        let accounts = store.accounts()?;
        let apps = store.sign_in_apps()?;
        for (row, account) in setup.accounts.iter_mut().zip(&setup.data.accounts) {
            let Some(account) = account else {
                row.importable = false;
                continue;
            };
            row.here = account_here(&accounts, &AccountRef::of(&account.settings)).is_some();
            if let SignInRef::App { issuer, client_id } = &account.sign_in
                && !setup.data.apps.iter().any(|app| app.is(issuer, client_id))
                && !apps.iter().any(|stored| same_client(&stored.app, issuer, client_id))
            {
                row.problem = Some(tr_args(Text::SetupAccountNoApp, &[("app", (&row.sign_in).into())]));
            }
            row.importable = !row.here && row.problem.is_none();
            let oauth = account.sign_in != SignInRef::Password;
            row.note = match (row.here, &row.problem, row.has_secret, oauth) {
                (true, _, _, _) => tr(Text::SetupAccountHere),
                (false, Some(problem), _, _) => problem.clone(),
                (false, None, true, false) => tr(Text::SetupAccountSecretPassword),
                (false, None, true, true) => tr(Text::SetupAccountSecretToken),
                (false, None, false, false) => tr(Text::SetupAccountAsksPassword),
                (false, None, false, true) => tr(Text::SetupAccountSignsInAgain),
            };
        }
        Ok(())
    }

    /// Imports the parts and accounts of `setup` that `choice` names. Accounts added start syncing; one without its
    /// password asks for it as an account whose password is missing does. Posts [`Event::AccountsChanged`],
    /// [`Event::SettingsChanged`], [`Event::AddressBookChanged`] and [`Event::KeysChanged`] for what it changed.
    ///
    /// BLOCKS while the issuers of the sign-in apps it adds are read over the network (20 seconds at most each): call
    /// it from a thread of its own, never the window thread.
    pub fn import_setup(&self, setup: &SetupFile, choice: &ImportChoice) -> Result<ImportSummary> {
        let parts = Parts(choice.parts().0 & setup.parts.0);
        if parts.is_empty() {
            return Err(Error::Invalid(tr(Text::SetupErrorNoParts)));
        }
        let mut summary = ImportSummary::default();
        // the sign-in apps first: the accounts may sign in with them
        let unreachable = match parts.has(Parts::SIGN_IN_APPS) {
            true => self.import_apps(setup, &mut summary)?,
            false => Unreachable::new(),
        };
        if parts.has(Parts::ACCOUNTS) {
            self.import_accounts(setup, &choice.accounts, &unreachable, &mut summary)?;
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
            self.import_trusted(setup, &mut summary)?;
        }
        if summary.lines.is_empty() {
            summary.line(ImportLineKind::Note, tr(Text::SetupNothing));
        }
        let settings = Parts::SETTINGS
            .with(Parts::SIGN_IN_APPS)
            .with(Parts::RULES)
            .with(Parts::TRUSTED_SENDERS);
        for (changed, event) in [
            (!summary.accounts.is_empty(), Event::AccountsChanged),
            (parts.0 & settings.0 != 0, Event::SettingsChanged),
            (parts.has(Parts::CONTACTS), Event::AddressBookChanged),
            (parts.has(Parts::KEYS), Event::KeysChanged),
        ] {
            if changed {
                self.post(event)?;
            }
        }
        Ok(summary)
    }

    /// The discovery document of `issuer`, read now on the core's runtime; waits for it
    fn discover_now(&self, issuer: &str) -> std::result::Result<Discovered, String> {
        let (sender, found) = std::sync::mpsc::channel();
        let issuer = issuer.to_string();
        self.runtime().map_err(|error| error.to_string())?.spawn(async move {
            let _ = sender.send(pe_oauth::discover(&issuer).await);
        });
        found.recv().map_err(|error| error.to_string())?
    }

    /// Adds the sign-in apps of the file that are not here, each with the endpoints its issuer gives now; those whose
    /// issuer could not be read
    fn import_apps(&self, setup: &SetupFile, summary: &mut ImportSummary) -> Result<Unreachable> {
        let here = {
            let store = self.store();
            for (kind, on) in &setup.data.builtin {
                store.set_builtin_sign_in_enabled(kind.as_str(), *on)?;
            }
            store.sign_in_apps()?
        };
        let (mut added, mut skipped) = (0, 0);
        let mut unreachable = Unreachable::new();
        for app in &setup.data.apps {
            let (issuer, client_id) = (&app.form.issuer, &app.form.client_id);
            if here.iter().any(|stored| same_client(&stored.app, issuer, client_id)) {
                skipped += 1;
                continue;
            }
            let Ok(found) = self.discover_now(issuer) else {
                summary.line(
                    ImportLineKind::Skipped,
                    tr_args(Text::SetupSkippedUnreachable, &[("name", (&app.form.name).into())]),
                );
                unreachable.insert((issuer.clone(), client_id.clone()));
                continue;
            };
            let saved = checked_app(&app.form, found, app.secret.is_some(), app.enabled)?;
            let id = self.store().add_sign_in_app(&saved)?;
            // an app removed before may have had this id: its secret goes
            self.secrets.remove(Key::App(id));
            if let Some(secret) = &app.secret
                && let Err(why) = self.secrets.set(Key::App(id), secret)
            {
                summary.line(ImportLineKind::Note, why);
            }
            added += 1;
        }
        summary.count(ImportLineKind::Added, Text::SetupAddedSignInApps, added);
        summary.count(ImportLineKind::Skipped, Text::SetupSkippedSignInApps, skipped);
        Ok(unreachable)
    }

    fn import_accounts(
        &self,
        setup: &SetupFile,
        chosen: &[usize],
        unreachable: &Unreachable,
        summary: &mut ImportSummary,
    ) -> Result<()> {
        let (mut here, apps) = {
            let store = self.store();
            let here: Vec<AccountRef> = store
                .accounts()?
                .iter()
                .map(|account| AccountRef::of(&account.settings))
                .collect();
            (here, store.sign_in_apps()?)
        };
        let (mut added, mut notes) = (Vec::new(), Vec::new());
        for (row, account) in setup.accounts.iter().zip(&setup.data.accounts) {
            if !chosen.contains(&row.index) {
                continue;
            }
            match self.import_account(row, account.as_ref(), &here, &apps, unreachable)? {
                Outcome::Added(id, note) => {
                    added.push(id);
                    notes.extend(note);
                    here.extend(account.as_ref().map(|account| AccountRef::of(&account.settings)));
                }
                Outcome::Skipped(why) => summary.line(ImportLineKind::Skipped, why),
            }
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

    /// One account of a file added, or why not; `here`, the accounts here, `apps`, the sign-in apps here
    fn import_account(
        &self,
        row: &SetupAccount,
        account: Option<&FileAccount>,
        here: &[AccountRef],
        apps: &[StoredSignInApp],
        unreachable: &Unreachable,
    ) -> Result<Outcome> {
        let address = (&row.email).into();
        let account = match (account, &row.problem) {
            (Some(account), None) => account,
            (_, problem) => {
                let reason = problem.clone().unwrap_or_default();
                let words = tr_args(
                    Text::SetupSkippedInvalid,
                    &[("address", address), ("reason", (&reason).into())],
                );
                return Ok(Outcome::Skipped(words));
            }
        };
        if here.iter().any(|known| known.is(&account.settings)) {
            return Ok(Outcome::Skipped(tr_args(
                Text::SetupSkippedHere,
                &[("address", address)],
            )));
        }
        let with = match &account.sign_in {
            SignInRef::Password => None,
            SignInRef::Builtin(kind) => Some(SignInWith::Builtin(*kind)),
            SignInRef::App { issuer, client_id } => {
                if unreachable.contains(&(issuer.clone(), client_id.clone())) {
                    let words = tr_args(Text::SetupSkippedUnreachable, &[("name", address)]);
                    return Ok(Outcome::Skipped(words));
                }
                // loaded after this import added its sign-in apps
                match apps.iter().find(|stored| same_client(&stored.app, issuer, client_id)) {
                    Some(stored) => Some(SignInWith::App(stored.id)),
                    None => {
                        let words = tr_args(
                            Text::SetupSkippedNoApp,
                            &[("address", address), ("app", (&row.sign_in).into())],
                        );
                        return Ok(Outcome::Skipped(words));
                    }
                }
            }
        };
        let settings = match with {
            None => account.settings.clone(),
            // an access token goes to the provider's own servers only
            Some(with) => {
                let auth = pe_store::Auth::OAuth2(with.auth_name());
                with_provider(&account.settings, &self.sign_in_provider(with)?, &auth)
            }
        };
        let secret = account.secret.as_ref().map(|secret| secret.as_str());
        let id = self.add_account_with(&settings, &account.account_name, secret)?;
        {
            let store = self.store();
            store.set_signature(id, &account.signature)?;
            store.set_account_addresses(id, &account.addresses)?;
        }
        // as Properties saves them: the provider's own names keep following the provider table
        if let Some(names) = &account.verifiers {
            self.set_account_verifiers_text(id, names)?;
        }
        let note = secret.is_none().then(|| {
            let text = match with {
                Some(_) => Text::SetupSignsInAgain,
                None => Text::SetupAsksPassword,
            };
            tr_args(text, &[("address", (&settings.email).into())])
        });
        Ok(Outcome::Added(id, note))
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
        // turned off, what was decrypted here leaves the index
        if let Some(on) = settings.pgp_index_encrypted {
            self.set_pgp_index_encrypted(on)?;
        }
        if let Some(delay) = settings.send_delay {
            self.set_send_delay(delay)?;
        }
        if let Some(on) = settings.show_previews {
            self.set_show_previews(on)?;
        }
        if let Some(on) = settings.pdf_previews {
            self.set_pdf_previews(on)?;
        }
        Ok(())
    }

    fn import_contacts(&self, setup: &SetupFile, summary: &mut ImportSummary) -> Result<()> {
        let store = self.store();
        let (added, skipped) = store.import_cards(&setup.data.cards)?;
        summary.count(ImportLineKind::Added, Text::SetupAddedContacts, added as usize);
        summary.count(ImportLineKind::Skipped, Text::SetupSkippedContacts, skipped as usize);
        // every address of the book, once: (card, its name, its default address)
        let mut cards: HashMap<String, (CardId, String, String)> = HashMap::new();
        for card in store.cards("")? {
            let Some(default) = card.addresses.first() else {
                continue;
            };
            for address in &card.addresses {
                cards
                    .entry(address.to_lowercase())
                    .or_insert_with(|| (card.id, card.name.clone(), default.clone()));
            }
        }
        let mut groups: HashMap<String, Group> = store
            .groups("")?
            .into_iter()
            .map(|group| (group.name.trim().to_lowercase(), group))
            .collect();
        let mut saved = 0;
        for group in &setup.data.groups {
            let key = group.name.to_lowercase();
            let mut known = groups.remove(&key).unwrap_or_else(|| Group {
                id: 0,
                name: group.name.clone(),
                members: Vec::new(),
            });
            if group_members(&mut known.members, &group.members, &cards) || known.id == 0 {
                known.id = store.save_group(&known)?;
                saved += 1;
            }
            groups.insert(key, known);
        }
        summary.count(ImportLineKind::Added, Text::SetupAddedGroups, saved);
        Ok(())
    }

    fn import_keys(&self, setup: &SetupFile, summary: &mut ImportSummary) -> Result<()> {
        let store = self.store();
        let book = Book::new(&store, &self.secrets, &self.pgp_certs)?;
        let own = book.own_addresses()?;
        let now = crate::worker::unix_now();
        let (mut contacts, mut owned) = (0, 0);
        let mut waiting: Vec<String> = Vec::new();
        // the contacts' keys and their marks in one transaction
        store.pgp_transaction(|| {
            for (cert, verified) in &setup.data.contact_keys {
                let fingerprint = cert.fingerprint();
                let known = store.pgp_key(&fingerprint)?.is_some();
                for (address, learned) in book.learned(cert, KeySource::File, own)? {
                    match learned {
                        Learned::Pending if !waiting.contains(&address) => waiting.push(address),
                        // a mark of a sealed file only, and only for the key the address uses now
                        Learned::Used | Learned::Same if setup.encrypted && verified.contains(&address) => {
                            store.set_pgp_verified(&fingerprint, &address, true)?;
                        }
                        _ => {}
                    }
                }
                contacts += usize::from(!known);
            }
            Ok(())
        })?;
        for (key, identities) in &setup.data.own_keys {
            let fingerprint = key.fingerprint();
            let known = store
                .pgp_key(&fingerprint)?
                .is_some_and(|stored| stored.secret.is_some());
            if let Err(error) = book.keep_secret(key, KeySource::File, false) {
                summary.line(ImportLineKind::Note, error.to_string());
                break;
            }
            for (address, autocrypt) in identities {
                // only an address of an account here, and one that has no key of its own yet
                if own.contains(address)
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
            owned += usize::from(!known);
        }
        summary.count(ImportLineKind::Added, Text::SetupAddedOwnKeys, owned);
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
        let mut here = HashSet::new();
        for rule in store.rules()? {
            let pending = store.rule_pending_target(rule.id)?;
            here.insert(rule_key(&rule, pending));
        }
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
            if !here.insert(rule_key(&rule, pending.clone())) {
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

    fn import_trusted(&self, setup: &SetupFile, summary: &mut ImportSummary) -> Result<()> {
        let mut store = self.store();
        let before: HashSet<String> = store.trusted_senders()?.into_iter().map(|s| s.value).collect();
        let added = store.transaction(|store| {
            let mut added = 0;
            for (value, domain) in &setup.data.trusted {
                if !before.contains(value) {
                    store.trust_sender(value, *domain)?;
                    added += 1;
                }
            }
            Ok(added)
        })?;
        summary.count(ImportLineKind::Added, Text::SetupAddedTrustedSenders, added);
        Ok(())
    }
}

/// Adds to `members` those of a file's group (name, address) not in it yet: a card of the book by its card, an address
/// of no card by itself, each once. `cards` holds every address of the book. Whether any was added.
fn group_members(
    members: &mut Vec<Member>,
    added: &[(String, String)],
    cards: &HashMap<String, (CardId, String, String)>,
) -> bool {
    let mut cards_in: HashSet<CardId> = members.iter().filter_map(|member| member.card).collect();
    let mut addresses: HashSet<String> = members.iter().map(|member| member.address.to_lowercase()).collect();
    let before = members.len();
    for (name, address) in added {
        let member = match cards.get(&address.to_lowercase()) {
            Some((card, name, default)) => Member {
                card: Some(*card),
                name: name.clone(),
                address: default.clone(),
            },
            None => Member {
                card: None,
                name: name.clone(),
                address: address.clone(),
            },
        };
        let new_card = member.card.is_none_or(|card| cards_in.insert(card));
        if new_card && addresses.insert(member.address.to_lowercase()) {
            members.push(member);
        }
    }
    members.len() > before
}
