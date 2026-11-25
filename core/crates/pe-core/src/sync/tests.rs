//! Computers syncing through one folder, as they do through a sync client: each a core of its own with its passwords
//! in memory. What one adds, changes and removes reaches the others; clashing edits are settled the same on every
//! computer with the losing one kept; the same thing added on two is one; folding keeps everything.

use pe_store::{AccountSettings, Auth, Card, Security};
use pe_testkit::TempDir;

use super::backend::Folder;
use super::engine::{Me, Outcome, SETTLE_MILLIS};
use super::items::Choice;
use super::stamp::Clock;
use super::vault::{self, Vault};
use crate::{Core, Options, PasswordStore};

struct Computer {
    _dir: TempDir,
    core: Core,
    device: String,
    clock: Clock,
}

impl Computer {
    fn new(device: &str) -> Computer {
        let dir = TempDir::new("pe-sync");
        let options = Options {
            passwords: PasswordStore::Memory,
            ..Default::default()
        };
        let core = Core::open_with(dir.path().join("store.db"), options, |_| {}).unwrap();
        Computer {
            _dir: dir,
            core,
            device: device.into(),
            clock: Clock::new(device),
        }
    }

    fn sync(&self, vault: &Vault<'_>) -> Outcome {
        let me = Me {
            device: &self.device,
            name: &self.device,
            clock: &self.clock,
            choice: Choice::default(),
        };
        self.core.sync_once(vault, &me, &[]).unwrap()
    }

    fn card(&self, address: &str) -> Option<Card> {
        self.core
            .cards("")
            .unwrap()
            .into_iter()
            .find(|c| c.addresses.first().is_some_and(|a| a == address))
    }
}

fn settings(email: &str) -> AccountSettings {
    AccountSettings {
        name: "Ann Example".into(),
        email: email.into(),
        username: email.into(),
        imap_host: "127.0.0.1".into(),
        imap_port: 9,
        imap_security: Security::Tls,
        smtp_host: "127.0.0.1".into(),
        smtp_port: 9,
        smtp_security: Security::StartTls,
        auth: Auth::Password,
    }
}

fn card(name: &str, address: &str) -> Card {
    Card {
        name: name.into(),
        addresses: vec![address.into()],
        ..Default::default()
    }
}

fn vault(dir: &TempDir) -> (Folder, String, super::crypt::VaultKey) {
    SETTLE_MILLIS.set(0);
    let place = Folder::new(&dir.path().join("vault"));
    let (id, key) = vault::create_vault(&place, "correct horse").unwrap();
    (place, id, key)
}

#[test]
fn what_one_computer_does_reaches_the_other() {
    let dir = TempDir::new("pe-sync-vault");
    let (place, id, key) = vault(&dir);
    let vault = Vault { place: &place, id, key };
    let (mac, pc) = (Computer::new("mac"), Computer::new("pc"));

    // an account with its password, and a card
    let ann = mac.core.add_account(&settings("ann@example.com"), "ann-pw").unwrap();
    mac.core.set_signature(ann, "<p>Regards</p>").unwrap();
    mac.core.save_card(&card("Bo Lee", "bo@example.org")).unwrap();
    assert!(mac.sync(&vault).sent > 0);
    let got = pc.sync(&vault);
    assert!(got.applied > 0 && got.skipped == 0, "{got:?}");
    let accounts = pc.core.store().accounts().unwrap();
    assert_eq!(accounts.len(), 1);
    assert_eq!(accounts[0].settings.email, "ann@example.com");
    assert_eq!(
        pc.core
            .secrets
            .get(crate::secrets::Key::Account(accounts[0].id))
            .as_deref(),
        Some("ann-pw")
    );
    assert_eq!(pc.card("bo@example.org").unwrap().name, "Bo Lee");

    // nothing more to send either way
    assert_eq!(pc.sync(&vault).sent, 0, "applied changes are not sent back");
    assert_eq!(mac.sync(&vault).applied, 0);

    // a change on the second, back on the first
    let mut bo = pc.card("bo@example.org").unwrap();
    bo.company = "Lee and Sons".into();
    pc.core.save_card(&bo).unwrap();
    pc.sync(&vault);
    mac.sync(&vault);
    assert_eq!(mac.card("bo@example.org").unwrap().company, "Lee and Sons");

    // removed on one, removed on the other, with the notice for an account
    pc.core.remove_account(accounts[0].id).unwrap();
    pc.sync(&vault);
    let removed = mac.sync(&vault);
    assert_eq!(removed.removed_accounts.len(), 1, "{removed:?}");
    assert!(mac.core.store().accounts().unwrap().is_empty());
    // how things were is kept, and reads back with the account
    let points = mac.core.settings_sync_restore_points();
    assert_eq!(points.len(), 1);
    let before = mac.core.settings_sync_restore_point(&points[0].path).unwrap();
    assert!(before.encrypted && before.accounts.iter().any(|a| a.email == "ann@example.com"));
}

#[test]
fn clashing_edits_end_the_same_everywhere_and_the_loser_is_kept() {
    let dir = TempDir::new("pe-sync-vault");
    let (place, id, key) = vault(&dir);
    let vault = Vault { place: &place, id, key };
    let (mac, pc) = (Computer::new("mac"), Computer::new("pc"));
    mac.core.save_card(&card("Bo Lee", "bo@example.org")).unwrap();
    mac.sync(&vault);
    pc.sync(&vault);

    // both change the same field before either syncs; the one that syncs later wins on both
    let mut on_mac = mac.card("bo@example.org").unwrap();
    on_mac.notes = "from the mac".into();
    mac.core.save_card(&on_mac).unwrap();
    let mut on_pc = pc.card("bo@example.org").unwrap();
    on_pc.notes = "from the pc".into();
    // and different fields: both kept
    on_pc.nickname = "Bobby".into();
    pc.core.save_card(&on_pc).unwrap();
    mac.sync(&vault);
    let clash = pc.sync(&vault);
    assert_eq!(clash.lost, 1, "the mac's edit is kept in the pc's history");
    mac.sync(&vault);
    for computer in [&mac, &pc] {
        let bo = computer.card("bo@example.org").unwrap();
        assert_eq!(
            (bo.notes.as_str(), bo.nickname.as_str()),
            ("from the pc", "Bobby"),
            "{}",
            computer.device
        );
    }
    let kept = pc.core.store().lost_edits().unwrap();
    assert_eq!(kept[0].value, "\"from the mac\"");
}

#[test]
fn the_same_thing_added_on_two_computers_is_one() {
    let dir = TempDir::new("pe-sync-vault");
    let (place, id, key) = vault(&dir);
    let vault = Vault { place: &place, id, key };
    let (mac, pc) = (Computer::new("mac"), Computer::new("pc"));
    mac.core.save_card(&card("Bo Lee", "bo@example.org")).unwrap();
    pc.core.save_card(&card("Bo Lee", "bo@example.org")).unwrap();
    pc.core.save_card(&card("Cy Dee", "cy@example.org")).unwrap();
    for _ in 0..2 {
        mac.sync(&vault);
        pc.sync(&vault);
    }
    for computer in [&mac, &pc] {
        assert_eq!(computer.core.cards("").unwrap().len(), 2, "{}", computer.device);
    }
    let ids = |c: &Computer| c.core.store().sync_ids("card").unwrap();
    assert_eq!(ids(&mac), ids(&pc), "both name each card by the same id");
}

#[test]
fn folding_keeps_everything_for_a_computer_that_joins_later() {
    let dir = TempDir::new("pe-sync-vault");
    let (place, id, key) = vault(&dir);
    let vault = Vault { place: &place, id, key };
    let mac = Computer::new("mac");
    for at in 0..5 {
        mac.core
            .save_card(&card(&format!("Person {at}"), &format!("p{at}@example.org")))
            .unwrap();
        mac.sync(&vault);
    }
    let me = Me {
        device: "mac",
        name: "mac",
        clock: &mac.clock,
        choice: Choice::default(),
    };
    assert!(super::engine::fold(&vault, me.device, me.name).unwrap());
    assert_eq!(vault.batches("mac").unwrap().len(), 1, "only the newest batch stays");
    let late = Computer::new("laptop");
    late.sync(&vault);
    assert_eq!(late.core.cards("").unwrap().len(), 5);
    // and the mac goes on from its newest batch
    mac.core.save_card(&card("Person 5", "p5@example.org")).unwrap();
    mac.sync(&vault);
    late.sync(&vault);
    assert_eq!(late.core.cards("").unwrap().len(), 6);
}

#[test]
fn a_computer_taken_out_stops_and_what_it_wrote_stays() {
    let dir = TempDir::new("pe-sync-vault");
    let (place, id, key) = vault(&dir);
    let vault = Vault { place: &place, id, key };
    let (mac, lost) = (Computer::new("mac"), Computer::new("lost"));
    lost.core.save_card(&card("Bo Lee", "bo@example.org")).unwrap();
    lost.sync(&vault);
    mac.sync(&vault);
    assert!(super::engine::fold(&vault, "mac", "mac").unwrap());
    assert!(super::engine::remove_device(&vault, "mac", "mac", "lost").unwrap());
    assert_eq!(vault.devices().unwrap(), ["mac"]);
    let me = Me {
        device: "lost",
        name: "lost",
        clock: &lost.clock,
        choice: Choice::default(),
    };
    assert!(
        lost.core.sync_once(&vault, &me, &[]).is_err(),
        "it is told, and writes nothing"
    );
    assert_eq!(vault.devices().unwrap(), ["mac"]);
    // a computer that joins later still gets the card
    let late = Computer::new("late");
    late.sync(&vault);
    assert!(late.card("bo@example.org").is_some());
}

#[test]
fn a_clash_of_secrets_keeps_none_of_them_aside() {
    let dir = TempDir::new("pe-sync-vault");
    let (place, id, key) = vault(&dir);
    let vault = Vault { place: &place, id, key };
    let (mac, pc) = (Computer::new("mac"), Computer::new("pc"));
    let ann = mac.core.add_account(&settings("ann@example.com"), "first").unwrap();
    mac.sync(&vault);
    pc.sync(&vault);
    let on_pc = pc.core.store().accounts().unwrap()[0].id;
    // a new password on both before either syncs
    mac.core
        .secrets
        .set(crate::secrets::Key::Account(ann), "from-the-mac")
        .unwrap();
    pc.core
        .secrets
        .set(crate::secrets::Key::Account(on_pc), "from-the-pc")
        .unwrap();
    mac.sync(&vault);
    pc.sync(&vault);
    mac.sync(&vault);
    for computer in [&mac, &pc] {
        assert!(
            computer.core.store().lost_edits().unwrap().is_empty(),
            "{}",
            computer.device
        );
    }
    // and both end with the same one
    let secret = |c: &Computer, id| c.core.secrets.get(crate::secrets::Key::Account(id));
    assert_eq!(secret(&mac, ann), secret(&pc, on_pc));
}
