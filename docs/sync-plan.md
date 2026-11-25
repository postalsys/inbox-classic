# Settings sync

Accounts, keys, the Address Book, rules, sign-in apps and settings kept the same on every computer through a place the user owns: a folder a sync client copies (Dropbox, OneDrive, iCloud Drive, Google Drive, Nextcloud, Syncthing) or an S3-compatible bucket (AWS, Cloudflare R2, Backblaze B2, MinIO). There is no service of ours in between. The user's decisions of 2026-11-25 are below; later work keeps them.

## Decisions

- Both places in the first version; WebDAV later.
- Everything syncs by default, secrets included: passwords, Google and Microsoft sign-ins, sign-in app secrets and the user's own OpenPGP private keys. Each kind of data and each kind of secret can be left out when sync is set up, and later in its settings.
- Each computer writes only its own change files. A soft lock guards only the rewrites that touch what others wrote: folding the changes into the snapshot, removing a computer, a new vault key.
- Clashing edits: the later edit of a field wins on every computer; the losing value is kept in the sync history, which restores it with one click. Sets (a card's addresses, a group's members) merge element by element. The same thing added on two computers is one.
- What other computers changed applies by itself; removing an account says so in a notice. Restore points let the user go back.
- App preferences sync, the language not (each computer has its own).
- A Google or Microsoft sign-in refreshed on one computer is written back, so the others never hold a token the provider has replaced.

## The vault

`core/crates/pe-core/src/sync/vault.rs` has the layout. Every file but `vault.json` and `lock` is sealed with the vault key (ChaCha20-Poly1305, bound to the vault, the computer that wrote it and its name, `crypt.rs`), so the place's owner and anyone who can read it see only how many changes there are and when. The vault key lives in each computer's system password store; in the vault it is only sealed with the sync passphrase, which is typed once on each computer that joins. A lost passphrase is no loss while one computer is still set up: it can seal the key again under a new one.

The rule of `docs/pgp-plan.md` that private keys never leave the app unprotected holds: in the vault they are under the vault key, as in a setup file they are under its passphrase.

## The engine

`engine.rs` does one sync: read the batches the others wrote since last time (or the snapshot, for a computer that joins after a fold), find what changed here by comparing each field's hash with what was last synced (`pe-store` `sync_fields`), settle each field by its stamp (`stamp.rs`, a hybrid logical clock, so a computer whose clock is wrong can not win forever), apply what the others won (`apply.rs` changes an item in place, so an account keeps its mail and a card its groups; a new item goes through the setup import, which checks it as it checks a file), and write what changed here as the next batch. Past 50 batches a computer folds every batch into the snapshot under the lock.

Items and their natural keys are in `items.rs`. A field is a value of the setup file's document, so sync carries what Export carries and checks what comes in the same way.

## Known limits

- A card's natural key is its first address; changing it is a removal and an addition on the other computers.
- The history of lost edits is kept on the computer that settled the clash.
- A folder's lock is advisory: two computers that take it within the time the sync client needs to copy it read it back after `SETTLE_MILLIS`, and the one whose token the file does not hold gives way; a fold that runs twice is harmless, as folding is idempotent.

## The windows

The same on the three platforms, each in its own way (Linux is the reference; screenshots `sync-1-off` to `sync-6-history` of the UI tests):

- **The settings' Sync page** (`core/settings.toml`, page `sync`). Off: the page's note and Set Up Sync only, as the one action of the page (Linux: a suggested button row). On: Synced through (the place, as what computer) and Status (`pe_settings_sync_state`, words from the core), Sync Now (off while a sync runs), Computers, History, Turn Off Sync (asks first; red), then What to sync: a switch for each kind of data and secret, a secret's switch off while its data's is (`depends_on`). Each change of a switch counts at once (Windows: on Apply, as the other settings). The page follows `SettingsSyncChanged`.
- **Set Up Sync** (a dialog over the settings, or over Add Mail Account on the first run): first where to keep it, A folder (Choose… opens the system's folder chooser; the path under it) or S3-compatible storage (Endpoint, Region, Bucket, Folder in the bucket, Access key ID, Secret access key); Next is off until the place is complete and looks at it (`pe_settings_sync_probe_start`, then `pe_settings_sync_probe` on `SettingsSyncChanged`), a problem said in red under the fields. Then either Start Sync (an empty place: the passphrase twice with the key backups' rule, `pe_pgp_passphrase_problem`) or Join Sync (a vault: the passphrase once, and that what is here and there come together), the name of this computer (the system's), and What to sync folded into one row that says Everything or Some things left out. Turn On Sync turns it on (`pe_settings_sync_turn_on`, its problem in red under the fields) and closes the dialog; the status bar says Sync is on.
- **Computers** and **History**: a list each (Linux: pages of the settings dialog; the Mac and Windows: sheets or small dialogs), Computers read by the core (`pe_settings_sync_computers_start`), each but this one with Remove (asks first); History with Restore on each row, and its note.
- **The first run**: under the fields of Add Mail Account, “Already use Inbox Classic on another computer?” with Join Its Sync… and Import from a File…; Join Its Sync opens Set Up Sync and closes Add Mail Account once the first sync brought an account.
- **Events**: `SettingsSyncReady` is answered at once with `pe_settings_sync_continue` and the app preferences (as for an export); `SettingsSyncChanged` refreshes the page and takes `pe_settings_sync_news`: its preferences applied as an import applies them, its notice in the status bar.
