//! What sync carries, as items of fields. The snapshot is the setup file's document ([`crate::setup`]), split into one
//! item for each account, card, group, key, rule, trusted sender, sign-in app, the settings and the app preferences;
//! each field of an item changes on its own, so two computers editing different fields of one item both keep theirs.
//! A set (a card's addresses, a group's members, an account's other addresses, a key's verified addresses and an own
//! key's addresses) is a field for each of its elements (`address:ann@example.org`), so additions on two computers
//! both stay and a removal takes away only what it removed.
//!
//! Each item has a natural key that says it is the same thing on two computers (an account's address and IMAP
//! server, a key's fingerprint, a card's first address), so the same thing added on two computers becomes one item.
//!
//! Applying an item that is new here goes through the setup import, which checks it as it checks a file; an item that
//! is here is changed in place (an account keeps its downloaded mail, a card its place in groups).

use std::collections::BTreeMap;

use base64::Engine;
use serde_json::{Map, Value, json};

use crate::setup::file::{AccountEntry, AppEntry, Document, GroupEntry, RuleEntry, TrustedEntry};
use crate::setup::{ImportChoice, Parts};
use crate::{Core, Result};

/// The kinds of item, and the order they are applied in (an account before the rules that name it)
pub const KINDS: [&str; 12] = [
    "setting",
    "pref",
    "builtin",
    "app",
    "app-secret",
    "account",
    "secret",
    "key",
    "own-key",
    "card",
    "group",
    "rule",
];

/// The kind of trusted senders, applied after the rest
pub const TRUSTED: &str = "trusted";

/// One synced thing as it is here now
#[derive(Debug, Clone, PartialEq)]
pub struct Item {
    pub kind: &'static str,
    /// What says it is the same thing on every computer (see the module's words)
    pub natural: String,
    /// What it is called in the Sync window's history ("Work", "Ann Lee")
    pub label: String,
    pub fields: BTreeMap<String, Value>,
}

/// What a computer syncs, as the Sync settings choose it: each kind of data and each kind of secret
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(default)]
pub struct Choice {
    pub accounts: bool,
    pub passwords: bool,
    pub sign_ins: bool,
    pub sign_in_apps: bool,
    pub app_secrets: bool,
    pub contacts: bool,
    pub keys: bool,
    pub private_keys: bool,
    pub rules: bool,
    pub trusted: bool,
    pub settings: bool,
    pub preferences: bool,
}

impl Default for Choice {
    /// Everything, as sync is set up
    fn default() -> Choice {
        Choice {
            accounts: true,
            passwords: true,
            sign_ins: true,
            sign_in_apps: true,
            app_secrets: true,
            contacts: true,
            keys: true,
            private_keys: true,
            rules: true,
            trusted: true,
            settings: true,
            preferences: true,
        }
    }
}

impl Choice {
    fn parts(&self) -> Parts {
        let mut parts = Parts::NONE;
        for (on, part) in [
            (self.settings, Parts::SETTINGS),
            (self.preferences, Parts::PREFERENCES),
            (self.accounts, Parts::ACCOUNTS),
            (self.sign_in_apps, Parts::SIGN_IN_APPS),
            (self.contacts, Parts::CONTACTS),
            (self.keys, Parts::KEYS),
            (self.rules, Parts::RULES),
            (self.trusted, Parts::TRUSTED_SENDERS),
        ] {
            if on {
                parts = parts.with(part);
            }
        }
        parts
    }

    /// Whether items of `kind` are synced
    pub fn takes(&self, kind: &str) -> bool {
        match kind {
            "setting" => self.settings,
            "pref" => self.preferences,
            "builtin" | "app" => self.sign_in_apps,
            "app-secret" => self.sign_in_apps && self.app_secrets,
            "account" => self.accounts,
            "secret" => self.accounts && (self.passwords || self.sign_ins),
            "key" => self.keys,
            "own-key" => self.keys && self.private_keys,
            "card" | "group" => self.contacts,
            "rule" => self.rules,
            TRUSTED => self.trusted,
            _ => false,
        }
    }
}

/// The app preferences that stay on each computer
const LOCAL_PREFS: [&str; 1] = ["language"];

/// The field name of a set's elements: `addresses` gives `address:...`, `members` `member:...`
fn singular(set: &str) -> &str {
    set.strip_suffix("es")
        .filter(|s| s.ends_with("ss"))
        .or_else(|| set.strip_suffix('s'))
        .unwrap_or(set)
}

/// An object's fields, `set` names an array of it to turn into a field for each element keyed by `key` of it
fn fields_of(value: &Value, sets: &[(&str, &str)], left_out: &[&str]) -> BTreeMap<String, Value> {
    let mut fields = BTreeMap::new();
    let Some(object) = value.as_object() else {
        return fields;
    };
    for (name, value) in object {
        if left_out.contains(&name.as_str()) {
            continue;
        }
        match sets.iter().find(|(set, _)| set == name) {
            Some((set, key)) => {
                for element in value.as_array().into_iter().flatten() {
                    let id = match key.is_empty() {
                        true => element.as_str().map(str::to_string),
                        false => element.get(*key).and_then(Value::as_str).map(str::to_string),
                    };
                    if let Some(id) = id {
                        let prefix = singular(set);
                        fields.insert(format!("{prefix}:{}", id.to_lowercase()), element.clone());
                    }
                }
            }
            None => {
                fields.insert(name.clone(), value.clone());
            }
        }
    }
    fields
}

/// An object back from its fields: each set's elements gathered into its array again, in a stable order
fn object_of(fields: &BTreeMap<String, Value>, sets: &[&str]) -> Value {
    let mut object = Map::new();
    for set in sets {
        object.insert(set.to_string(), Value::Array(Vec::new()));
    }
    for (name, value) in fields {
        let set = sets
            .iter()
            .find(|set| name.strip_prefix(&format!("{}:", singular(set))).is_some());
        match set {
            Some(set) => {
                if let Some(Value::Array(list)) = object.get_mut(*set) {
                    list.push(value.clone());
                }
            }
            None => {
                object.insert(name.clone(), value.clone());
            }
        }
    }
    Value::Object(object)
}

/// A fingerprint of a certificate or a private key, as hex
fn fingerprint_of(base64: &str, secret: bool) -> Option<String> {
    let bytes = base64::engine::general_purpose::STANDARD.decode(base64).ok()?;
    let fingerprint = if secret {
        pe_pgp::SecretKey::from_bytes(&bytes).ok()?.fingerprint()
    } else {
        pe_pgp::read_certs(&bytes).ok()?.into_iter().next()?.fingerprint()
    };
    Some(fingerprint.to_string())
}

impl Core {
    /// Everything synced as it is here now, as `choice` takes it; `prefs` the app's preferences by name
    pub(crate) fn sync_snapshot(&self, choice: &Choice, prefs: &[(String, String)]) -> Result<Vec<Item>> {
        let secrets = choice.passwords || choice.sign_ins || choice.app_secrets || choice.private_keys;
        let (document, _) = self.setup_document(choice.parts(), secrets, prefs)?;
        let mut items = Vec::new();
        if let Some(settings) = &document.settings {
            items.push(Item {
                kind: "setting",
                natural: "settings".into(),
                label: String::new(),
                fields: fields_of(&json!(settings), &[], &[]),
            });
        }
        if let Some(prefs) = &document.preferences {
            let fields = prefs
                .iter()
                .filter(|(name, _)| !LOCAL_PREFS.contains(&name.as_str()))
                .map(|(name, value)| (name.clone(), json!(value)))
                .collect();
            items.push(Item {
                kind: "pref",
                natural: "preferences".into(),
                label: String::new(),
                fields,
            });
        }
        if let Some(apps) = &document.sign_in_apps {
            let mut fields = BTreeMap::new();
            for (name, on) in [("google", apps.google), ("microsoft", apps.microsoft)] {
                if let Some(on) = on {
                    fields.insert(name.to_string(), json!(on));
                }
            }
            items.push(Item {
                kind: "builtin",
                natural: "builtin".into(),
                label: String::new(),
                fields,
            });
            for app in &apps.apps {
                let natural = app_natural(&app.issuer, &app.client_id);
                items.push(Item {
                    kind: "app",
                    natural: natural.clone(),
                    label: app.name.clone(),
                    fields: fields_of(&json!(app), &[], &["secret"]),
                });
                if let Some(secret) = app.secret.as_ref().filter(|_| choice.app_secrets) {
                    items.push(Item {
                        kind: "app-secret",
                        natural,
                        label: app.name.clone(),
                        fields: BTreeMap::from([("value".to_string(), json!(secret))]),
                    });
                }
            }
        }
        for (position, account) in document.accounts.iter().flatten().enumerate() {
            let natural = account_natural(&account.email, &account.imap.host);
            let label = if account.account_name.is_empty() {
                account.email.clone()
            } else {
                account.account_name.clone()
            };
            let mut fields = fields_of(&json!(account), &[("addresses", "email")], &["secret"]);
            fields.insert("position".into(), json!(position));
            items.push(Item {
                kind: "account",
                natural: natural.clone(),
                label: label.clone(),
                fields,
            });
            let password = matches!(account.sign_in, crate::setup::file::SignInEntry::Password);
            let allowed = if password { choice.passwords } else { choice.sign_ins };
            if let Some(secret) = account.secret.as_ref().filter(|_| allowed) {
                items.push(Item {
                    kind: "secret",
                    natural,
                    label,
                    fields: BTreeMap::from([("value".to_string(), json!(secret))]),
                });
            }
        }
        if let Some(keys) = &document.keys {
            for key in &keys.contacts {
                let Some(fingerprint) = fingerprint_of(&key.cert, false) else {
                    continue;
                };
                let mut fields = BTreeMap::from([("cert".to_string(), json!(key.cert))]);
                for address in &key.verified {
                    fields.insert(format!("verified:{}", address.to_lowercase()), json!(address));
                }
                items.push(Item {
                    kind: "key",
                    natural: fingerprint.clone(),
                    label: fingerprint,
                    fields,
                });
            }
            for key in keys.own.iter().filter(|_| choice.private_keys) {
                let Some(fingerprint) = fingerprint_of(&key.key, true) else {
                    continue;
                };
                let mut fields = BTreeMap::from([("key".to_string(), json!(key.key))]);
                for identity in &key.identities {
                    fields.insert(format!("identity:{}", identity.address.to_lowercase()), json!(identity));
                }
                items.push(Item {
                    kind: "own-key",
                    natural: fingerprint.clone(),
                    label: fingerprint,
                    fields,
                });
            }
        }
        if let Some(contacts) = &document.contacts {
            for card in crate::vcard::read_vcards(&contacts.vcards) {
                let natural = card_natural(&card);
                let mut fields = BTreeMap::new();
                for (name, value) in [
                    ("name", &card.name),
                    ("first", &card.first),
                    ("last", &card.last),
                    ("nickname", &card.nickname),
                    ("company", &card.company),
                    ("notes", &card.notes),
                    ("extra", &card.extra),
                ] {
                    fields.insert(name.to_string(), json!(value));
                }
                fields.insert("phones".into(), json!(card.phones));
                // the first address is the default one: it is its own field, the others a set
                for (at, address) in card.addresses.iter().enumerate() {
                    let name = if at == 0 {
                        "default".to_string()
                    } else {
                        format!("address:{}", address.to_lowercase())
                    };
                    fields.insert(name, json!(address));
                }
                if let Some(picture) = &card.picture {
                    fields.insert(
                        "picture".into(),
                        json!(base64::engine::general_purpose::STANDARD.encode(picture)),
                    );
                }
                items.push(Item {
                    kind: "card",
                    natural,
                    label: card.name.clone(),
                    fields,
                });
            }
            for group in &contacts.groups {
                items.push(Item {
                    kind: "group",
                    natural: name_natural(&group.name),
                    label: group.name.clone(),
                    fields: fields_of(&json!(group), &[("members", "email")], &[]),
                });
            }
        }
        for (position, rule) in document.rules.iter().flatten().enumerate() {
            let mut fields = fields_of(&json!(rule), &[], &[]);
            let natural = rule_natural(rule);
            fields.insert("position".into(), json!(position));
            items.push(Item {
                kind: "rule",
                natural,
                label: rule.name.clone(),
                fields,
            });
        }
        for trusted in document.trusted_senders.iter().flatten() {
            items.push(Item {
                kind: TRUSTED,
                natural: name_natural(&trusted.value),
                label: trusted.value.clone(),
                fields: BTreeMap::from([
                    ("value".to_string(), json!(trusted.value)),
                    ("domain".to_string(), json!(trusted.domain)),
                ]),
            });
        }
        Ok(items)
    }

    /// An item new here added from its fields, through the setup import (which checks it as it checks a file).
    /// The app preferences are not the core's: the window takes them (`SyncNews::prefs`).
    pub(crate) fn sync_add(&self, kind: &str, fields: &BTreeMap<String, Value>) -> Result<()> {
        let Some((document, choice)) = document_of(kind, fields) else {
            return Ok(());
        };
        let file = match crate::setup::file::checked(document, true) {
            Ok(file) => file,
            Err(_) => return Ok(()),
        };
        let accounts = (0..file.accounts.len()).collect();
        self.import_setup(
            &file,
            &ImportChoice {
                parts: choice,
                accounts,
            },
        )?;
        Ok(())
    }
}

/// A setup document holding only the item of `kind` made of `fields`, and the part it is in; None for a kind the
/// setup file does not carry or fields that do not make one
pub(crate) fn document_of(kind: &str, fields: &BTreeMap<String, Value>) -> Option<(Document, Parts)> {
    let mut document = Document {
        format: crate::setup::FORMAT.into(),
        version: crate::setup::VERSION,
        ..Document::default()
    };
    let choice = match kind {
        "setting" => {
            document.settings = serde_json::from_value(object_of(fields, &[])).ok();
            Parts::SETTINGS
        }
        "builtin" => {
            document.sign_in_apps = Some(crate::setup::file::AppsPart {
                google: fields.get("google").and_then(Value::as_bool),
                microsoft: fields.get("microsoft").and_then(Value::as_bool),
                apps: Vec::new(),
            });
            Parts::SIGN_IN_APPS
        }
        "app" => {
            let Ok(app) = serde_json::from_value::<AppEntry>(object_of(fields, &[])) else {
                return None;
            };
            document.sign_in_apps = Some(crate::setup::file::AppsPart {
                apps: vec![app],
                ..Default::default()
            });
            Parts::SIGN_IN_APPS
        }
        "account" => {
            let Ok(account) = serde_json::from_value::<AccountEntry>(object_of(fields, &["addresses"])) else {
                return None;
            };
            document.accounts = Some(vec![account]);
            Parts::ACCOUNTS
        }
        "key" => {
            let cert = fields
                .get("cert")
                .and_then(Value::as_str)
                .unwrap_or_default()
                .to_string();
            let verified = set_values(fields, "verified");
            document.keys = Some(crate::setup::file::KeysPart {
                contacts: vec![crate::setup::file::ContactKeyEntry { cert, verified }],
                own: Vec::new(),
            });
            Parts::KEYS
        }
        "own-key" => {
            let key = fields
                .get("key")
                .and_then(Value::as_str)
                .unwrap_or_default()
                .to_string();
            let identities = fields
                .iter()
                .filter(|(name, _)| name.starts_with("identity:"))
                .filter_map(|(_, value)| serde_json::from_value(value.clone()).ok())
                .collect();
            document.keys = Some(crate::setup::file::KeysPart {
                contacts: Vec::new(),
                own: vec![crate::setup::file::OwnKeyEntry { key, identities }],
            });
            Parts::KEYS
        }
        "card" => {
            let card = card_of(fields, 0);
            document.contacts = Some(crate::setup::file::ContactsPart {
                vcards: crate::vcard::write_vcards(&[card]),
                groups: Vec::new(),
            });
            Parts::CONTACTS
        }
        "group" => {
            let Ok(group) = serde_json::from_value::<GroupEntry>(object_of(fields, &["members"])) else {
                return None;
            };
            document.contacts = Some(crate::setup::file::ContactsPart {
                vcards: String::new(),
                groups: vec![group],
            });
            Parts::CONTACTS
        }
        "rule" => {
            let Ok(rule) = serde_json::from_value::<RuleEntry>(object_of(fields, &[])) else {
                return None;
            };
            document.rules = Some(vec![rule]);
            Parts::RULES
        }
        TRUSTED => {
            // the value is the item's natural key, carried in its own field
            let value = fields
                .get("value")
                .and_then(Value::as_str)
                .unwrap_or_default()
                .to_string();
            let domain = fields.get("domain").and_then(Value::as_bool).unwrap_or(false);
            document.trusted_senders = Some(vec![TrustedEntry { value, domain }]);
            Parts::TRUSTED_SENDERS
        }
        _ => return None,
    };
    Some((document, choice))
}

/// An account's natural key: its address and IMAP server
/// A sign-in app's natural key: its issuer and client id
pub(crate) fn app_natural(issuer: &str, client_id: &str) -> String {
    format!("{issuer}|{client_id}")
}

/// A group's or a trusted sender's natural key: its name or address in lower case
pub(crate) fn name_natural(name: &str) -> String {
    name.to_lowercase()
}

pub(crate) fn account_natural(email: &str, imap_host: &str) -> String {
    format!("{}|{}", email.to_lowercase(), imap_host.to_lowercase())
}

/// A card's natural key: its default address, or its name when it has none
pub(crate) fn card_natural(card: &pe_store::Card) -> String {
    card.addresses
        .first()
        .map_or_else(|| format!("name:{}", card.name.to_lowercase()), |a| a.to_lowercase())
}

/// A rule's natural key: the same rule made on two computers is one, by what it does, not its name or place
pub(crate) fn rule_natural(rule: &RuleEntry) -> String {
    json!([
        rule.account,
        rule.query,
        rule.move_to,
        rule.mark_read,
        rule.flag,
        rule.archive,
        rule.junk,
        rule.remove,
        rule.quiet
    ])
    .to_string()
}

/// The values of a set's fields (`verified:...`)
fn set_values(fields: &BTreeMap<String, Value>, set: &str) -> Vec<String> {
    fields
        .iter()
        .filter(|(name, _)| name.starts_with(&format!("{set}:")))
        .filter_map(|(_, value)| value.as_str().map(str::to_string))
        .collect()
}

/// A card from its fields, with the id `id` (0 for a new one)
pub(crate) fn card_of(fields: &BTreeMap<String, Value>, id: pe_store::CardId) -> pe_store::Card {
    let text = |name: &str| fields.get(name).and_then(Value::as_str).unwrap_or_default().to_string();
    let mut addresses: Vec<String> = fields
        .get("default")
        .and_then(Value::as_str)
        .map(str::to_string)
        .into_iter()
        .collect();
    addresses.extend(set_values(fields, "address"));
    pe_store::Card {
        id,
        name: text("name"),
        first: text("first"),
        last: text("last"),
        nickname: text("nickname"),
        company: text("company"),
        notes: text("notes"),
        addresses,
        phones: fields
            .get("phones")
            .and_then(|p| serde_json::from_value(p.clone()).ok())
            .unwrap_or_default(),
        extra: text("extra"),
        picture: fields
            .get("picture")
            .and_then(Value::as_str)
            .and_then(|p| base64::engine::general_purpose::STANDARD.decode(p).ok()),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sets_become_a_field_each_and_come_back() {
        let group = json!({"name": "Family", "members": [{"name": "Ann", "email": "Ann@x.org"}, {"name": "Bo", "email": "bo@x.org"}]});
        let fields = fields_of(&group, &[("members", "email")], &[]);
        assert_eq!(
            fields.keys().collect::<Vec<_>>(),
            ["member:ann@x.org", "member:bo@x.org", "name"]
        );
        let back = object_of(&fields, &["members"]);
        assert_eq!(back["name"], "Family");
        assert_eq!(back["members"].as_array().unwrap().len(), 2);
        // a field left out
        let account = json!({"email": "a@x.org", "secret": "hunter2"});
        assert!(!fields_of(&account, &[], &["secret"]).contains_key("secret"));
    }

    #[test]
    fn a_card_from_its_fields_keeps_its_default_address_first() {
        let fields = BTreeMap::from([
            ("name".to_string(), json!("Ann Lee")),
            ("default".to_string(), json!("ann@work.org")),
            ("address:ann@home.org".to_string(), json!("ann@home.org")),
            ("phones".to_string(), json!([["cell", "+372 555"]])),
        ]);
        let card = card_of(&fields, 4);
        assert_eq!((card.id, card.name.as_str()), (4, "Ann Lee"));
        assert_eq!(card.addresses, ["ann@work.org", "ann@home.org"]);
        assert_eq!(card.phones, [("cell".to_string(), "+372 555".to_string())]);
    }

    #[test]
    fn the_choice_takes_kinds_as_the_settings_say() {
        let mut choice = Choice::default();
        assert!(KINDS.iter().all(|kind| choice.takes(kind)) && choice.takes(TRUSTED));
        choice.private_keys = false;
        choice.passwords = false;
        choice.sign_ins = false;
        assert!(!choice.takes("own-key") && !choice.takes("secret") && choice.takes("key"));
    }
}
