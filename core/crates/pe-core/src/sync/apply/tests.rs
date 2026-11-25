//! Items carried from one store to another as the engine carries them: added there through the setup import, then
//! changed in place to fields edited on the first, then removed. Passwords live in memory only.

use std::collections::BTreeMap;

use pe_store::{AccountSettings, Auth, Card, Group, Member, Rule, Security, SignInApp};
use pe_testkit::TempDir;
use serde_json::{Value, json};

use crate::secrets::Key;
use crate::sync::items::{Choice, Item, TRUSTED};
use crate::{Core, Options, PasswordStore};

fn opened(dir: &TempDir) -> Core {
    let options = Options {
        passwords: PasswordStore::Memory,
        ..Default::default()
    };
    Core::open_with(dir.path().join("store.db"), options, |_| {}).unwrap()
}

/// An OpenID Connect issuer on this computer that answers every request with its discovery document; its issuer
fn issuer_here() -> String {
    use std::io::{Read, Write};
    let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
    let issuer = format!("http://127.0.0.1:{}", listener.local_addr().unwrap().port());
    let body = json!({
        "issuer": issuer,
        "authorization_endpoint": format!("{issuer}/authorize"),
        "token_endpoint": format!("{issuer}/token"),
        "code_challenge_methods_supported": ["S256"],
    })
    .to_string();
    std::thread::spawn(move || {
        for mut stream in listener.incoming().flatten() {
            let mut request = Vec::new();
            let mut buffer = [0u8; 1024];
            while !request.windows(4).any(|w| w == b"\r\n\r\n") {
                match stream.read(&mut buffer) {
                    Ok(0) | Err(_) => break,
                    Ok(n) => request.extend_from_slice(&buffer[..n]),
                }
            }
            let response = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                body.len()
            );
            let _ = stream.write_all(response.as_bytes());
        }
    });
    issuer
}

/// Something of every kind: an account with its password, a sign-in app with its secret, settings, two cards (one
/// with a picture), a group, an own key, a contact's verified key, two rules and a trusted sender
fn fill(core: &Core) {
    let ann = core
        .add_account(
            &AccountSettings {
                name: "Ann Example".into(),
                email: "ann@example.com".into(),
                username: "ann@example.com".into(),
                imap_host: "127.0.0.1".into(),
                imap_port: 9,
                imap_security: Security::Tls,
                smtp_host: "127.0.0.1".into(),
                smtp_port: 9,
                smtp_security: Security::StartTls,
                auth: Auth::Password,
            },
            "ann-pw",
        )
        .unwrap();
    core.set_account_name(ann, "Work").unwrap();
    core.set_signature(ann, "<p>Ann</p>").unwrap();
    core.set_account_addresses_text(ann, "Ann Two <ann2@example.com>")
        .unwrap();
    core.set_account_verifiers_text(ann, "mx.mail.example").unwrap();
    let issuer = issuer_here();
    let app = core
        .store()
        .add_sign_in_app(&SignInApp {
            name: "Acme".into(),
            issuer: issuer.clone(),
            client_id: "acme-client".into(),
            has_secret: true,
            scopes: "openid email".into(),
            authorize_url: format!("{issuer}/authorize"),
            token_url: format!("{issuer}/token"),
            response_issuer: None,
            imap_host: "imap.acme.example".into(),
            imap_port: 993,
            imap_security: Security::Tls,
            smtp_host: "smtp.acme.example".into(),
            smtp_port: 465,
            smtp_security: Security::Tls,
            enabled: true,
        })
        .unwrap();
    core.secrets.set(Key::App(app), "client-secret").unwrap();
    core.set_text_size(1).unwrap();
    core.set_send_delay(10).unwrap();

    let dave = core
        .save_card(&Card {
            name: "Dave Example".into(),
            addresses: vec!["dave@example.net".into()],
            phones: vec![("cell".into(), "+1 555 0100".into())],
            ..Default::default()
        })
        .unwrap();
    let png = crate::card_pictures::normalize(&crate::card_pictures::tests::png(8, 8)).unwrap();
    core.set_card_picture_png(dave, &png).unwrap();
    core.save_card(&Card {
        name: "Eve".into(),
        addresses: vec!["eve@example.org".into()],
        ..Default::default()
    })
    .unwrap();
    core.save_group(&Group {
        id: 0,
        name: "Friends".into(),
        members: vec![
            Member {
                card: Some(dave),
                ..Default::default()
            },
            Member {
                card: None,
                name: "Frank".into(),
                address: "frank@example.org".into(),
            },
        ],
    })
    .unwrap();

    core.pgp_generate(ann).unwrap();
    let now = crate::worker::unix_now();
    let dave_key = pe_pgp::generate("Dave", &["dave@example.net".into()], now).unwrap();
    let imported = core
        .pgp_import(dave_key.cert().armored().as_bytes(), None, crate::keys::KeySource::File)
        .unwrap();
    core.pgp_set_key_verified(&imported.keys[0], true).unwrap();

    for (name, query) in [("News", "list:news.example"), ("Shop", "from:shop.example")] {
        core.save_rule(&Rule {
            enabled: true,
            name: name.into(),
            query: query.into(),
            mark_read: true,
            ..Default::default()
        })
        .unwrap();
    }
    core.trust_sender("shop.example", true).unwrap();
}

fn snapshot(core: &Core) -> Vec<Item> {
    core.sync_snapshot(&Choice::default(), &[]).unwrap()
}

/// The item of `kind` here whose label is `label` (any for an empty one)
fn find(core: &Core, kind: &str, label: &str) -> Option<Item> {
    snapshot(core)
        .into_iter()
        .find(|item| item.kind == kind && (label.is_empty() || item.label == label))
}

fn item(core: &Core, kind: &str, label: &str) -> Item {
    find(core, kind, label).unwrap_or_else(|| panic!("no {kind} {label}"))
}

/// The two stores, `b` holding every item of `a` added as the engine adds them, in the engine's order
fn carried() -> (TempDir, TempDir, Core, Core) {
    let (dir_a, dir_b) = (TempDir::new("apply-a"), TempDir::new("apply-b"));
    let (a, b) = (opened(&dir_a), opened(&dir_b));
    fill(&a);
    let items = snapshot(&a);
    for kind in crate::sync::items::KINDS.iter().chain([&TRUSTED]) {
        for item in items.iter().filter(|item| item.kind == *kind) {
            if item.kind == "secret" || item.kind == "app-secret" {
                assert!(b.sync_update(item.kind, &item.natural, &item.fields).unwrap());
            } else {
                b.sync_add(item.kind, &item.fields).unwrap();
            }
        }
    }
    (dir_a, dir_b, a, b)
}

/// `item` changed by `change` and applied to `b`, whose item is then the changed one
fn changes(b: &Core, item: &Item, change: impl FnOnce(&mut BTreeMap<String, Value>)) {
    let mut fields = item.fields.clone();
    change(&mut fields);
    assert_ne!(fields, item.fields, "{} changed", item.kind);
    assert!(b.sync_update(item.kind, &item.natural, &fields).unwrap());
    let after = snapshot(b)
        .into_iter()
        .find(|here| here.kind == item.kind && here.natural == item.natural)
        .unwrap_or_else(|| panic!("{} {} after the change", item.kind, item.natural));
    assert_eq!(after.fields, fields, "{} {}", item.kind, item.natural);
}

fn removed(b: &Core, item: &Item) {
    b.sync_remove(item.kind, &item.natural).unwrap();
    let left = snapshot(b)
        .into_iter()
        .any(|here| here.kind == item.kind && here.natural == item.natural);
    assert!(!left, "{} {} removed", item.kind, item.natural);
    // removing what is not here is nothing
    b.sync_remove(item.kind, &item.natural).unwrap();
}

#[test]
fn every_kind_is_added_changed_and_removed_in_place() {
    let (_da, _db, a, b) = carried();
    for item in snapshot(&a) {
        let here = find(&b, item.kind, &item.label).unwrap_or_else(|| panic!("{} {} added", item.kind, item.label));
        assert_eq!(here.fields, item.fields, "{} {}", item.kind, item.label);
    }

    changes(&b, &item(&a, "setting", ""), |fields| {
        fields.insert("text_size".into(), json!(3));
        fields.insert("send_delay".into(), json!(30));
        fields.insert("always_load_pictures".into(), json!(true));
    });
    changes(&b, &item(&a, "builtin", ""), |fields| {
        fields.insert("google".into(), json!(true));
    });
    let app = item(&a, "app", "Acme");
    changes(&b, &app, |fields| {
        fields.insert("name".into(), json!("Acme Mail"));
        fields.insert("scopes".into(), json!("openid email profile"));
        fields.insert("enabled".into(), json!(false));
        fields.insert(
            "imap".into(),
            json!({"host": "mail.acme.example", "port": 994, "security": "tls"}),
        );
    });
    let app_secret = item(&a, "app-secret", "Acme");
    changes(&b, &app_secret, |fields| {
        fields.insert("value".into(), json!("client-secret-2"));
    });

    let account = item(&a, "account", "Work");
    changes(&b, &account, |fields| {
        fields.insert("name".into(), json!("Ann B. Example"));
        fields.insert("account_name".into(), json!("Home"));
        fields.insert("username".into(), json!("ann"));
        fields.insert(
            "signature".into(),
            json!(pe_html::signature_html("<p>Ann <b>B</b></p>")),
        );
        fields.insert("verifiers".into(), json!("mx.other.example"));
        fields.insert(
            "smtp".into(),
            json!({"host": "smtp.example.com", "port": 587, "security": "starttls"}),
        );
        fields.remove("address:ann2@example.com");
        fields.insert(
            "address:ann3@example.com".into(),
            json!({"email": "ann3@example.com", "name": "Ann Three"}),
        );
    });
    changes(&b, &item(&a, "secret", "Work"), |fields| {
        fields.insert("value".into(), json!("ann-pw-2"));
    });

    let contact = item(&a, "key", "");
    let own = item(&a, "own-key", "");
    changes(&b, &contact, |fields| {
        fields.remove("verified:dave@example.net");
    });
    changes(&b, &own, |fields| {
        let identity = fields.get_mut("identity:ann@example.com").unwrap();
        identity["autocrypt"] = json!(false);
        fields.remove("identity:ann2@example.com");
    });

    let dave = item(&a, "card", "Dave Example");
    changes(&b, &dave, |fields| {
        fields.insert("company".into(), json!("Example Ltd"));
        fields.insert("address:dave@home.example".into(), json!("dave@home.example"));
        fields.remove("picture");
    });
    let group = item(&a, "group", "Friends");
    changes(&b, &group, |fields| {
        fields.remove("member:frank@example.org");
        fields.insert(
            "member:eve@example.org".into(),
            json!({"email": "eve@example.org", "name": "Eve"}),
        );
    });
    let rule = item(&a, "rule", "News");
    changes(&b, &rule, |fields| {
        fields.insert("name".into(), json!("Newsletters"));
        fields.insert("enabled".into(), json!(false));
        fields.insert("position".into(), json!(1));
    });
    assert_eq!(
        item(&b, "rule", "Shop").fields["position"],
        json!(0),
        "the other rule moved up"
    );
    let trusted = item(&a, TRUSTED, "shop.example");
    assert!(b.sync_update(TRUSTED, &trusted.natural, &trusted.fields).unwrap());

    // the account's settings, its password and the app's secret as the store and the password store have them
    let ann = b.accounts().unwrap().pop().unwrap();
    assert_eq!((ann.settings.smtp_port, ann.settings.username.as_str()), (587, "ann"));
    assert_eq!(b.secrets.get(ann.id).as_deref(), Some("ann-pw-2"));
    let stored = b.store().sign_in_apps().unwrap().pop().unwrap();
    assert_eq!(b.secrets.get(Key::App(stored.id)).as_deref(), Some("client-secret-2"));
    let dave_here = b
        .store()
        .cards("")
        .unwrap()
        .into_iter()
        .find(|card| card.name == "Dave Example")
        .unwrap();
    assert_eq!(b.store().card_picture(dave_here.id).unwrap(), None);

    // the secrets go with their account and app; an app an account signs in with stays
    for removing in [
        &trusted,
        &rule,
        &group,
        &dave,
        &contact,
        &own,
        &app_secret,
        &app,
        &account,
    ] {
        removed(&b, removing);
    }
    assert!(b.accounts().unwrap().is_empty());
    assert_eq!(b.secrets.get(ann.id), None);
    assert_eq!(b.secrets.get(Key::App(stored.id)), None);
}

#[test]
fn what_is_not_here_is_for_adding() {
    let dir = TempDir::new("apply-none");
    let core = opened(&dir);
    let fields = BTreeMap::from([("value".to_string(), json!("x"))]);
    for kind in [
        "account",
        "secret",
        "app",
        "app-secret",
        "key",
        "own-key",
        "card",
        "group",
        "rule",
        TRUSTED,
    ] {
        assert!(!core.sync_update(kind, "nothing", &fields).unwrap(), "{kind}");
        core.sync_remove(kind, "nothing").unwrap();
    }
    assert!(core.sync_update("pref", "preferences", &fields).unwrap());
    assert!(core.sync_update("setting", "settings", &fields).unwrap());
}

#[test]
fn values_that_do_not_pass_leave_the_item_as_it_is() {
    let (_da, _db, a, b) = carried();
    let refused = |item: &Item, change: &dyn Fn(&mut BTreeMap<String, Value>)| {
        let mut fields = item.fields.clone();
        change(&mut fields);
        assert!(b.sync_update(item.kind, &item.natural, &fields).unwrap());
        let after = snapshot(&b)
            .into_iter()
            .find(|here| here.kind == item.kind && here.natural == item.natural)
            .unwrap();
        assert_eq!(after.fields, item.fields, "{} {}", item.kind, item.label);
    };
    refused(&item(&a, "setting", ""), &|fields| {
        fields.insert("text_size".into(), json!(99));
        fields.insert("send_delay".into(), json!(7));
    });
    refused(&item(&a, "account", "Work"), &|fields| {
        fields.insert(
            "smtp".into(),
            json!({"host": "smtp example", "port": 25, "security": "tls"}),
        );
    });
    // an account's address and server are which account it is
    let account = item(&a, "account", "Work");
    let mut moved = account.fields.clone();
    moved.insert("email".into(), json!("mallory@example.com"));
    assert!(b.sync_update("account", &account.natural, &moved).unwrap());
    assert_eq!(b.accounts().unwrap()[0].settings.email, "ann@example.com");
    refused(&item(&a, "app", "Acme"), &|fields| {
        fields.insert(
            "smtp".into(),
            json!({"host": "smtp.acme.example", "port": 25, "security": "plain"}),
        );
    });
    refused(&item(&a, "card", "Dave Example"), &|fields| {
        fields.insert("picture".into(), json!("bm90IGEgcGljdHVyZQ=="));
    });
    refused(&item(&a, "rule", "News"), &|fields| {
        fields.insert("name".into(), json!(["not", "text"]));
    });
    // a secret too long for one
    let secret = item(&a, "secret", "Work");
    let mut long = secret.fields.clone();
    long.insert("value".into(), json!("x".repeat(65 * 1024)));
    assert!(b.sync_update("secret", &secret.natural, &long).unwrap());
    assert_eq!(b.secrets.get(b.accounts().unwrap()[0].id).as_deref(), Some("ann-pw"));
}
