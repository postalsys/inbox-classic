//! An item that is here changed to the fields the engine merged, or removed. Each is found by its natural key computed
//! from the store as [`super::items`] computes it, and changed in place: an account keeps its downloaded mail, a card
//! its place in groups, a rule its place in the list.
//!
//! The fields come from a place others could write to, so they are read as a setup file is: made into the item's setup
//! document and checked by [`crate::setup::file::checked`], and what does not pass is left as it is here rather than
//! failing the sync. Nothing is written for a value that is the same here already.

use std::collections::{BTreeMap, HashMap};

use base64::Engine;
use pe_store::{Account, AccountId, Card, CardId, Group, Member, PgpIdentity, Rule};
use serde_json::Value;

use super::items::{self, TRUSTED, app_natural, name_natural};
use crate::keys::{Book, KeySource};
use crate::secrets::Key;
use crate::setup::Parts;
use crate::setup::file::{self, SettingsPart, SetupFile};
use crate::setup::import::{book_addresses, member_of};
use crate::{Core, Error, Result};

/// The item of `kind` made of `fields`, checked as a setup file's item is; None when it does not pass
fn checked(kind: &str, fields: &BTreeMap<String, Value>) -> Option<SetupFile> {
    let (document, _) = items::document_of(kind, fields)?;
    file::checked(document, true).ok()
}

/// A secret's `value` field, checked as a sealed setup file's secret is
fn secret_of(fields: &BTreeMap<String, Value>) -> Option<zeroize::Zeroizing<String>> {
    let value = fields.get("value").and_then(Value::as_str).map(str::to_string);
    file::secret(&value, true)
}

/// A `position` field as an index
fn position_of(fields: &BTreeMap<String, Value>) -> Option<usize> {
    fields
        .get("position")
        .and_then(Value::as_u64)
        .and_then(|at| usize::try_from(at).ok())
}

/// `wanted` when it is set and not what is here
fn changed<T: PartialEq>(wanted: Option<T>, here: &Option<T>) -> Option<T> {
    wanted.filter(|value| here.as_ref() != Some(value))
}

/// Whether two members are the same: the same card, or the same address of no card
fn same_member(a: &Member, b: &Member) -> bool {
    match (a.card, b.card) {
        (Some(a), Some(b)) => a == b,
        (None, None) => a.address.eq_ignore_ascii_case(&b.address),
        _ => false,
    }
}

/// The members of a group made of a file's group members (name, address), each once: a card of the book by its card,
/// an address of no card by itself. The members here that stay keep their place, the new ones come after them.
fn group_members(
    here: &[Member],
    wanted: &[(String, String)],
    cards: &HashMap<String, (CardId, String, String)>,
) -> Vec<Member> {
    let mut resolved: Vec<Member> = Vec::new();
    for (name, address) in wanted {
        let member = member_of(name, address, cards);
        if !resolved.iter().any(|known| same_member(known, &member)) {
            resolved.push(member);
        }
    }
    let mut members: Vec<Member> = here
        .iter()
        .filter(|member| resolved.iter().any(|w| same_member(member, w)))
        .cloned()
        .collect();
    for member in resolved {
        if !members.iter().any(|kept| same_member(kept, &member)) {
            members.push(member);
        }
    }
    members
}

/// What an account's other addresses are, to compare: (address in lower case, name), sorted
fn address_set(addresses: &[(String, String)]) -> Vec<(String, String)> {
    let mut set: Vec<(String, String)> = addresses
        .iter()
        .map(|(email, name)| (email.to_lowercase(), name.clone()))
        .collect();
    set.sort();
    set
}

impl Core {
    /// The item of `kind` whose natural key is `natural` here changed to `fields` (all its fields); Ok(false) when no
    /// such item is here (the engine then calls [`Core::sync_add`]). Fields that do not pass the setup file's checks
    /// leave the item as it is.
    pub(crate) fn sync_update(&self, kind: &str, natural: &str, fields: &BTreeMap<String, Value>) -> Result<bool> {
        match kind {
            // the window applies the preferences
            "pref" => Ok(true),
            "setting" => self.update_settings(fields).map(|()| true),
            "builtin" => self.update_builtin(fields).map(|()| true),
            "app" => self.update_app(natural, fields),
            "app-secret" => self.update_app_secret(natural, fields),
            "account" => self.update_account_item(natural, fields),
            "secret" => self.update_secret(natural, fields),
            "key" => self.update_contact_key(natural, fields),
            "own-key" => self.update_own_key(natural, fields),
            "card" => self.update_card(natural, fields),
            "group" => self.update_group(natural, fields),
            "rule" => self.update_rule(natural, fields),
            TRUSTED => self.update_trusted(natural, fields),
            // a kind this version does not know: nothing to add either
            _ => Ok(true),
        }
    }

    /// The item of `kind` whose natural key is `natural` removed here; nothing when it is not here. The settings, the
    /// preferences and the built-in switches are never removed, nor an account's secret (it goes with its account).
    pub(crate) fn sync_remove(&self, kind: &str, natural: &str) -> Result<()> {
        match kind {
            "app" => {
                let Some(id) = self.app_here(natural)?.map(|stored| stored.id) else {
                    return Ok(());
                };
                match self.remove_sign_in_app(id) {
                    // accounts here still sign in with it: it stays for them
                    Err(Error::InUse(_)) => Ok(()),
                    other => other,
                }
            }
            "app-secret" => {
                let Some(stored) = self.app_here(natural)? else {
                    return Ok(());
                };
                self.secrets.remove(Key::App(stored.id));
                if stored.app.has_secret {
                    let app = pe_store::SignInApp {
                        has_secret: false,
                        ..stored.app
                    };
                    self.store().update_sign_in_app(stored.id, &app)?;
                }
                Ok(())
            }
            "account" => match self.account_here(natural)? {
                Some((account, _)) => self.remove_account(account.id),
                None => Ok(()),
            },
            "key" | "own-key" => {
                let own = kind == "own-key";
                let here = self.store().pgp_key(natural)?;
                match here {
                    Some(key) if key.secret.is_some() == own => self.pgp_remove(natural),
                    _ => Ok(()),
                }
            }
            "card" => match self.card_here(natural)? {
                Some(card) => self.delete_cards(&[card.id]),
                None => Ok(()),
            },
            "group" => match self.group_here(natural)? {
                Some(group) => self.delete_group(group.id),
                None => Ok(()),
            },
            "rule" => match self.rule_here(natural)? {
                Some((rule, _)) => self.delete_rule(rule.id),
                None => Ok(()),
            },
            TRUSTED => {
                let here = self.trusted_senders()?;
                match here.iter().find(|sender| name_natural(&sender.value) == natural) {
                    Some(sender) => self.untrust_sender(sender.id),
                    None => Ok(()),
                }
            }
            _ => Ok(()),
        }
    }

    // ---- finding what is here by its natural key ----

    /// The account here and its place in the accounts' order
    fn account_here(&self, natural: &str) -> Result<Option<(Account, usize)>> {
        let accounts = self.store().accounts()?;
        Ok(accounts
            .into_iter()
            .enumerate()
            .find(|(_, account)| {
                items::account_natural(&account.settings.email, &account.settings.imap_host) == natural
            })
            .map(|(at, account)| (account, at)))
    }

    fn app_here(&self, natural: &str) -> Result<Option<pe_store::StoredSignInApp>> {
        let apps = self.store().sign_in_apps()?;
        Ok(apps
            .into_iter()
            .find(|stored| app_natural(&stored.app.issuer, &stored.app.client_id) == natural))
    }

    fn card_here(&self, natural: &str) -> Result<Option<Card>> {
        let cards = self.store().cards("")?;
        Ok(cards.into_iter().find(|card| items::card_natural(card) == natural))
    }

    fn group_here(&self, natural: &str) -> Result<Option<Group>> {
        let groups = self.store().groups("")?;
        Ok(groups.into_iter().find(|group| name_natural(&group.name) == natural))
    }

    /// The rule here and its place in the rules' order
    fn rule_here(&self, natural: &str) -> Result<Option<(Rule, usize)>> {
        let (document, _) = self.setup_document(Parts::RULES, false, &[])?;
        let rules = self.store().rules()?;
        Ok(document
            .rules
            .unwrap_or_default()
            .iter()
            .zip(rules)
            .enumerate()
            .find(|(_, (entry, _))| items::rule_natural(entry) == natural)
            .map(|(at, (_, rule))| (rule, at)))
    }

    // ---- each kind ----

    /// The settings whose value changed, applied as an import applies them
    fn update_settings(&self, fields: &BTreeMap<String, Value>) -> Result<()> {
        let Some(mut file) = checked("setting", fields) else {
            return Ok(());
        };
        let Some(wanted) = file.data.settings.take() else {
            return Ok(());
        };
        let (document, _) = self.setup_document(Parts::SETTINGS, false, &[])?;
        let here = document.settings.unwrap_or_default();
        file.data.settings = Some(SettingsPart {
            dark_messages: changed(wanted.dark_messages, &here.dark_messages),
            text_size: changed(wanted.text_size, &here.text_size),
            download_ahead: changed(wanted.download_ahead, &here.download_ahead),
            download_limit_mb: changed(wanted.download_limit_mb, &here.download_limit_mb),
            always_load_pictures: changed(wanted.always_load_pictures, &here.always_load_pictures),
            pgp_keyserver: changed(wanted.pgp_keyserver, &here.pgp_keyserver),
            pgp_index_encrypted: changed(wanted.pgp_index_encrypted, &here.pgp_index_encrypted),
            send_delay: changed(wanted.send_delay, &here.send_delay),
            show_previews: changed(wanted.show_previews, &here.show_previews),
            pdf_previews: changed(wanted.pdf_previews, &here.pdf_previews),
        });
        self.import_settings(&file)
    }

    /// Whether the built-in sign-in apps are offered for new accounts
    fn update_builtin(&self, fields: &BTreeMap<String, Value>) -> Result<()> {
        let Some(file) = checked("builtin", fields) else {
            return Ok(());
        };
        let store = self.store();
        for (kind, on) in &file.data.builtin {
            if store.builtin_sign_in_enabled(kind.as_str())? != *on {
                store.set_builtin_sign_in_enabled(kind.as_str(), *on)?;
            }
        }
        Ok(())
    }

    /// A sign-in app's name, scopes, servers and switch; its endpoints stay those its issuer gave here
    fn update_app(&self, natural: &str, fields: &BTreeMap<String, Value>) -> Result<bool> {
        let Some(stored) = self.app_here(natural)? else {
            return Ok(false);
        };
        let Some(app) = checked("app", fields).and_then(|mut file| file.data.apps.pop()) else {
            return Ok(true);
        };
        if !app.is(&stored.app.issuer, &stored.app.client_id) {
            return Ok(true);
        }
        let found = pe_oauth::Discovered {
            authorize_url: stored.app.authorize_url.clone(),
            token_url: stored.app.token_url.clone(),
            response_issuer: stored.app.response_issuer.clone(),
        };
        let Ok(wanted) = crate::sign_in_apps::checked_app(&app.form, found, stored.app.has_secret, app.enabled) else {
            return Ok(true);
        };
        if wanted == stored.app {
            return Ok(true);
        }
        self.store().update_sign_in_app(stored.id, &wanted)?;
        let servers = |app: &pe_store::SignInApp| {
            (
                app.imap_host.clone(),
                app.imap_port,
                app.imap_security,
                app.smtp_host.clone(),
                app.smtp_port,
                app.smtp_security,
            )
        };
        // the accounts that sign in with it move to its servers, as when it is saved in its window
        if servers(&wanted) != servers(&stored.app) {
            self.move_accounts_to(stored.id, &wanted)?;
        }
        Ok(true)
    }

    /// A sign-in app's client secret
    fn update_app_secret(&self, natural: &str, fields: &BTreeMap<String, Value>) -> Result<bool> {
        let Some(stored) = self.app_here(natural)? else {
            return Ok(false);
        };
        let Some(secret) = secret_of(fields) else {
            return Ok(true);
        };
        if self.secrets.get(Key::App(stored.id)).as_deref() != Some(secret.as_str()) {
            self.secrets
                .set(Key::App(stored.id), &secret)
                .map_err(Error::Unavailable)?;
        }
        if !stored.app.has_secret {
            let app = pe_store::SignInApp {
                has_secret: true,
                ..stored.app
            };
            self.store().update_sign_in_app(stored.id, &app)?;
        }
        Ok(true)
    }

    /// An account's names, signature, other addresses, servers, user name, verifiers and place; never which account it
    /// is (its address and IMAP server) nor how it signs in
    fn update_account_item(&self, natural: &str, fields: &BTreeMap<String, Value>) -> Result<bool> {
        let Some((account, at)) = self.account_here(natural)? else {
            return Ok(false);
        };
        let id = account.id;
        if let Some(wanted) = checked("account", fields).and_then(|mut file| file.data.accounts.pop().flatten()) {
            let here = &account.settings;
            let mut settings = pe_store::AccountSettings {
                email: here.email.clone(),
                imap_host: here.imap_host.clone(),
                auth: here.auth.clone(),
                ..wanted.settings.clone()
            };
            // an account that signs in with a provider is at the provider's servers
            if here.auth != pe_store::Auth::Password {
                settings = pe_store::AccountSettings {
                    name: settings.name,
                    username: settings.username,
                    ..here.clone()
                };
            }
            if settings != *here {
                self.update_account(id, &settings)?;
            }
            let account_name = match wanted.account_name.as_str() {
                "" => crate::default_account_name(&here.email),
                name => name.to_string(),
            };
            if account_name != account.account_name {
                self.set_account_name(id, &account_name)?;
            }
            self.update_account_extras(id, &wanted)?;
        }
        if let Some(position) = position_of(fields)
            && position != at
        {
            self.move_account(id, position)?;
        }
        Ok(true)
    }

    /// An account's signature, other addresses and verifiers
    fn update_account_extras(&self, id: AccountId, wanted: &file::FileAccount) -> Result<()> {
        let (signature, addresses) = {
            let store = self.store();
            (store.signature(id)?, store.account_addresses(id)?)
        };
        if signature != wanted.signature {
            self.set_signature(id, &wanted.signature)?;
        }
        if address_set(&addresses) != address_set(&wanted.addresses) {
            self.store().set_account_addresses(id, &wanted.addresses)?;
        }
        // none is the provider's own; unchanged writes nothing
        self.set_account_verifiers_text(id, wanted.verifiers.as_deref().unwrap_or(""))
    }

    /// An account's password or refresh token, kept as signing in keeps it; its connections are made again with it
    fn update_secret(&self, natural: &str, fields: &BTreeMap<String, Value>) -> Result<bool> {
        let Some((account, _)) = self.account_here(natural)? else {
            return Ok(false);
        };
        let Some(secret) = secret_of(fields) else {
            return Ok(true);
        };
        if self.secrets.get(account.id).as_deref() != Some(secret.as_str()) {
            self.keep_password(account.id, &secret);
            self.stop_worker(account.id);
        }
        Ok(true)
    }

    /// A contact's key: what the certificate brings merged in, and the addresses marked as compared exactly those of
    /// the item, a mark set only for an address that uses this key (as an import sets it)
    fn update_contact_key(&self, natural: &str, fields: &BTreeMap<String, Value>) -> Result<bool> {
        let store = self.store();
        match store.pgp_key(natural)? {
            None => return Ok(false),
            // the user's own key: an own-key item's
            Some(stored) if stored.secret.is_some() => return Ok(true),
            Some(_) => {}
        }
        let Some((cert, verified)) = checked("key", fields).and_then(|mut file| file.data.contact_keys.pop()) else {
            return Ok(true);
        };
        if cert.fingerprint() != natural {
            return Ok(true);
        }
        let book = Book::new(&store, &self.secrets, &self.pgp_certs)?;
        let own = book.own_addresses()?;
        let here = book.cert(natural)?;
        // learned again only when it brings something: learning a key an address does not use makes it wait again
        let new = match &here {
            Some(here) => here
                .merge(&cert)
                .is_some_and(|merged| merged.to_bytes() != here.to_bytes()),
            None => true,
        };
        store.pgp_transaction(|| {
            if new {
                book.learned(&cert, KeySource::File, own)?;
            }
            for held in store.pgp_key_addresses(Some(natural))? {
                let marked = verified.contains(&held.address);
                let in_use = store
                    .pgp_peer(&held.address)?
                    .and_then(|peer| peer.fingerprint)
                    .is_some_and(|used| used == natural);
                if (marked && in_use && !held.verified) || (!marked && held.verified) {
                    store.set_pgp_verified(natural, &held.address, marked)?;
                }
            }
            Ok(())
        })?;
        Ok(true)
    }

    /// One of the user's own keys: the private key merged in when it differs, and the own addresses that use it (with
    /// Autocrypt or not) exactly those of the item, each an address of an account here that the key holds
    fn update_own_key(&self, natural: &str, fields: &BTreeMap<String, Value>) -> Result<bool> {
        let store = self.store();
        if !store.pgp_key(natural)?.is_some_and(|stored| stored.secret.is_some()) {
            return Ok(false);
        }
        let Some((key, identities)) = checked("own-key", fields).and_then(|mut file| file.data.own_keys.pop()) else {
            return Ok(true);
        };
        if key.fingerprint() != natural {
            return Ok(true);
        }
        let book = Book::new(&store, &self.secrets, &self.pgp_certs)?;
        let same = book
            .own_key(natural)
            .is_ok_and(|here| *here.to_bytes() == *key.to_bytes());
        if !same {
            book.keep_secret(&key, KeySource::File, false)?;
        }
        let own = book.own_addresses()?;
        let now = crate::worker::unix_now();
        store.pgp_transaction(|| {
            for (address, autocrypt) in &identities {
                if !own.contains(address) || !key.cert().has_address(address, now) {
                    continue;
                }
                let here = store.pgp_identity(address)?;
                if here.is_none_or(|here| here.fingerprint != natural || here.autocrypt != *autocrypt) {
                    store.set_pgp_identity(&PgpIdentity {
                        address: address.clone(),
                        fingerprint: natural.to_string(),
                        autocrypt: *autocrypt,
                    })?;
                }
            }
            for identity in store.pgp_identities()? {
                if identity.fingerprint == natural
                    && !identities.iter().any(|(address, _)| *address == identity.address)
                {
                    store.remove_pgp_identity(&identity.address)?;
                }
            }
            Ok(())
        })?;
        Ok(true)
    }

    /// A card's fields, addresses and picture (none in the fields takes the picture here away)
    fn update_card(&self, natural: &str, fields: &BTreeMap<String, Value>) -> Result<bool> {
        let Some(here) = self.card_here(natural)? else {
            return Ok(false);
        };
        // read as a file's card is: through its vCard, the picture made the core's own
        let Some(mut file) = checked("card", fields) else {
            return Ok(true);
        };
        let Some(wanted) = file.data.cards.pop() else {
            return Ok(true);
        };
        let card = Card {
            id: here.id,
            picture: None,
            ..wanted.clone()
        };
        if card
            != (Card {
                picture: None,
                ..here.clone()
            })
        {
            match self.save_card(&card) {
                // a card without a name or an address is not one: this one stays as it is
                Err(Error::Invalid(_)) => return Ok(true),
                other => other?,
            };
        }
        let picture_here = self.store().card_picture(here.id)?.map(|(png, _)| png);
        let picture_given = fields
            .get("picture")
            .and_then(Value::as_str)
            .and_then(|p| base64::engine::general_purpose::STANDARD.decode(p).ok());
        if picture_given != picture_here {
            match wanted.picture {
                Some(png) if Some(&png) != picture_here.as_ref() => self.set_card_picture_png(here.id, &png)?,
                None if picture_given.is_none() => self.remove_card_picture(here.id)?,
                // the same once made the core's own, or a picture that is not one: this one stays
                _ => {}
            }
        }
        Ok(true)
    }

    /// A group's name and members: exactly the item's, each address of a card here as that card
    fn update_group(&self, natural: &str, fields: &BTreeMap<String, Value>) -> Result<bool> {
        let Some(here) = self.group_here(natural)? else {
            return Ok(false);
        };
        let Some(wanted) = checked("group", fields).and_then(|mut file| file.data.groups.pop()) else {
            return Ok(true);
        };
        let cards = book_addresses(&self.store())?;
        // only its case can change: another name is another group
        let name = match wanted.name.to_lowercase() == natural {
            true => wanted.name,
            false => here.name.clone(),
        };
        let members = group_members(&here.members, &wanted.members, &cards);
        let same = here.members.len() == members.len()
            && members.iter().all(|m| here.members.iter().any(|h| same_member(h, m)));
        if name != here.name || !same {
            self.save_group(&Group {
                id: here.id,
                name,
                members,
            })?;
        }
        Ok(true)
    }

    /// A rule's name, switch and place; what it does is its natural key
    fn update_rule(&self, natural: &str, fields: &BTreeMap<String, Value>) -> Result<bool> {
        let Some((here, at)) = self.rule_here(natural)? else {
            return Ok(false);
        };
        if let Some(wanted) = checked("rule", fields).and_then(|mut file| file.data.rules.pop())
            && (wanted.rule.name != here.name || wanted.rule.enabled != here.enabled)
        {
            let rule = Rule {
                name: wanted.rule.name,
                enabled: wanted.rule.enabled,
                ..here.clone()
            };
            self.store().save_rule(&rule)?;
        }
        if let Some(position) = position_of(fields) {
            let mut at = at;
            while at != position {
                let up = position < at;
                if !self.move_rule(here.id, up)? {
                    break;
                }
                at = if up { at - 1 } else { at + 1 };
            }
        }
        Ok(true)
    }

    /// A trusted sender: whether it is a whole domain
    fn update_trusted(&self, natural: &str, fields: &BTreeMap<String, Value>) -> Result<bool> {
        let here = self.trusted_senders()?;
        let Some(sender) = here.iter().find(|sender| sender.value.to_lowercase() == natural) else {
            return Ok(false);
        };
        let Some((value, domain)) = checked(TRUSTED, fields).and_then(|mut file| file.data.trusted.pop()) else {
            return Ok(true);
        };
        if value == natural && domain != sender.domain {
            self.untrust_sender(sender.id)?;
            self.trust_sender(&value, domain)?;
        }
        Ok(true)
    }
}

#[cfg(test)]
mod tests;
