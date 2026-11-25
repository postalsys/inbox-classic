# OpenPGP in Inbox Classic: plan

The plan for encrypted and signed mail (OpenPGP, RFC 9580 and RFC 4880, PGP/MIME of RFC 3156), written on 15 November 2026 at 0.18.0. Eleven pull requests, each landing on Windows, the Mac and Linux at once, merged to master one after the other, released together at the end. `docs/pgp-overview.html` is the same plan as a page.

Everything happens inside the app. No `gpg`, no agent, no system keyring of keys: the Rust core parses, checks, decrypts and signs, and the three apps show what it decided.

## Scope

| #   | Part                                                                        | PRs  | Size |
| --- | --------------------------------------------------------------------------- | ---- | ---- |
| 1   | The OpenPGP engine (`pe-pgp`) with its policy, and the cross-checks in CI   | 1    | L    |
| 2   | Keys: the key store, the master key, My Keys, keys in the Address Book      | 2, 3 | L    |
| 3   | Reading: decryption, signature checks, frames for each part, the bar        | 4, 5 | L    |
| 4   | Writing: Sign and Encrypt, drafts, the Sent copy, Undo Send                 | 6, 7 | L    |
| 5   | Finding keys: Web Key Directory and keys.openpgp.org, publishing one's own  | 8    | M    |
| 6   | Autocrypt: keys travelling in the mail itself                               | 9    | M    |
| 7   | Search, the list, notifications and agents with encrypted mail              | 10   | M    |
| 8   | Hardening: the whole feature reviewed, fuzzed and run against other clients | 11   | M    |

Not in this round: S/MIME, smartcards and hardware keys, post-quantum keys (RFC 9980; rPGP has it behind a feature, later), the Autocrypt Setup Message, decrypting loose `.pgp` files attached to ordinary mail, producing protected headers (see the decisions).

## Decisions taken

From the request:

- **Nothing outside the app.** No system utilities.
- **Keys belong to people**: the Address Book shows and manages the keys of a contact's addresses.
- **Keys are found by themselves** on keys.openpgp.org (and, before it, in the domain's own Web Key Directory).
- **No typing of passphrases all day.**
- **Each part of a message has its own result**, and the message is drawn so that a checked part and an unchecked one can not be confused.

Confirmed on 15 November 2026:

- **Private keys: a master key in the keychain.** A random 32 byte master key is kept in the system's store (Keychain, Credential Manager, Secret Service) beside the mail passwords. Each private key is kept in the local store wrapped under it. The passphrase of an imported key is asked once, at import, and is not kept. No prompts after that.
- **Encrypt and Sign are manual.** Both are off for a new message and nothing is remembered per person. One exception that is a safety rule, not a convenience: a reply to an encrypted message starts with Encrypt on.
- **Keys are looked up only when Encrypt is turned on** (for the recipients that have no key yet), or with Find Key on a contact. Web Key Directory first, then keys.openpgp.org; a switch in Options turns keys.openpgp.org off.
- **Colored frames in the message, a document for each part.** Each part is drawn in a frame with its result, and the bar over the message sums them up. A message's own CSS could cover or restyle a label that shares its document, so labels and mail never share one: see "A document for each part" below.
- **If a part's height can not be measured with page scripts off** on one of the three web views, the fallback on all three is one part at a time, chosen from a native strip of the parts with their verdicts.
- **A message protected as a whole looks the same**: the bar and one label over its one part.
- **Only protected mail is drawn this way.** A message without a signed or encrypted layer is drawn exactly as today.
- **Two levels of trust.** A key that was found is usable and its signatures show in blue ("Signed by a@example.org"). A key whose fingerprint the user compared and marked Verified shows in green. A different key turning up for an address is never taken silently.
- **Autocrypt, read and sent.** Never `prefer-encrypt=mutual`, as encryption is manual.
- **Decrypted text is indexed**, so search and the list's snippets work; "Search in encrypted messages" in Options, on by default. The message itself stays encrypted on disk.
- **Protected headers are read, not written.** An incoming message's inner Subject and addresses (RFC 9788, and the older `protected-headers="v1"`) are shown when their layer is valid. Outgoing mail keeps its Subject as written.

## Defaults chosen (say if you want otherwise)

- **The library is rPGP** (`pgp` 0.21.1 or newer, MIT or Apache-2.0, pure Rust, used by Delta Chat, audited in 2019 and 2024). Sequoia is LGPL and its pure Rust backend is marked as not for general use, so it does not fit a statically linked MIT app. rPGP has no policy layer and had eleven advisories since December 2024, so: the policy is ours (`pe-pgp/src/policy.rs`), its release notes are followed, every advisory gets a regression test here, and Sequoia checks our output in CI.
- **A new key is Ed25519 with a Curve25519 encryption subkey, version 4**, no expiry: what Autocrypt requires and every client reads. Version 6 keys and AEAD (SEIPDv2) are read and used when a recipient's key announces them.
- **Encrypt always signs** (RFC 9787: no encrypted but unsigned mail), signed inside the encryption, and always encrypts to the sender's own key too, so the Sent copy can be read.
- **No message goes out half encrypted.** If a recipient has no usable key, Send stops with the list of who, Find Key, and Send Without Encryption (which is refused for a reply that quotes encrypted mail until the quote is removed).
- **Bcc recipients are hidden**: their key ids are left out of the encrypted message (anonymous recipients); if that proves unreliable with rPGP they get a copy encrypted separately.
- **Inline PGP** (armored blocks in the text): decrypted into a frame of its own; its signatures are not checked (RFC 9787 6.2.3: inline signatures can not be bound to what is shown). The frame says "Signature not checked".
- **A failed signature is not an alarm.** Its frame is amber and says in plain words what is wrong ("The signature does not match this text"); it never looks more dangerous than unsigned mail, which most mail is (RFC 9787 6.4).
- **Pictures from the internet in a decrypted part load only on a click.** The "Download Pictures" bar stays, but the sender's trust and "always download" never apply to a decrypted part, the choice is for that message that one time and is not remembered, and once they are loaded the part no longer says "Encrypted": its label and the bar say "Pictures were loaded from the internet" (RFC 9787 9.9: fetch and stop calling it protected). A signature's verdict is not changed by it.
- **Agents (MCP) see no decrypted mail**: not the text, not the snippet, not through search. They can not sign, encrypt, decrypt or touch keys.
- **A backup is offered right after a key is made or imported**: "Save a Backup…" writes the private key protected by a passphrase of the user's choice (the only place a passphrase is typed). The private key never leaves the app unprotected: in a backup or a setup file it is under a passphrase, in the settings sync vault under the vault key (`docs/sync-plan.md`), and only when the user leaves Your private keys on in What to sync.
- **Publishing to keys.openpgp.org is a button**, never automatic: My Keys > Publish uploads the public key and asks the server to send its confirmation mail, which arrives in the user's own inbox.

## The design

### Crates

- **`pe-pgp`** (new, `#![forbid(unsafe_code)]`, no network, no files): pure functions over bytes on top of rPGP.
    - `cert`: parse (armored or binary, size and packet limits), merge, minimize for export, user ids and their addresses, fingerprint, `valid_at(time)`.
    - `policy`: what is acceptable and since when. MD5 never; SHA-1 for data signatures made before February 2013 and for key bindings made before February 2023 (Sequoia's cutoffs); RSA under 2048 bits, DSA and ElGamal refused; signatures from the future refused; validity is judged at the signature's creation time; a hard revocation counts backwards in time; a subkey must be bound, with the back signature for signing subkeys; key flags are enforced. One table, one test for each row.
    - `verify`: a detached signature over exact bytes (only document signature types), giving who signed, when, and why not.
    - `decrypt`: integrity is mandatory (SEIPDv1 with its MDC checked before a byte is released, SEIPDv2; the old unprotected packet is refused); limits on decompressed size, nesting and packet counts.
    - `sign`, `encrypt` (sign then encrypt in one message), `generate`, `protect` and `unprotect` a private key with a passphrase (for import and backup).
    - `autocrypt`: the header parsed and built.
    - `examples/sop.rs`: the Stateless OpenPGP command line (draft-dkg-openpgp-stateless-cli) on these functions, for the cross-checks.
- **`pe-mime`** gets `outline(raw) -> Outline`: the tree of parts with the byte ranges of each part's headers and body in the source, nothing decoded. A signature is checked over the exact bytes of a part, which the flattening parser does not keep. Pure, fuzzed, and tested by cutting the source with its own ranges.
- **`pe-keys`** (new): Web Key Directory and the keys.openpgp.org API over `pe_net::http` (https only, no redirects, 1 MB limit). Its results go through `pe-pgp` before anything is kept.
- **`pe-store`**: migrations for the keys (below) and the marks on messages.
- **`pe-core`**: `keys.rs` (the key book, the master key, wrapping), `protect.rs` (reading: layers, sections, verdicts), `protect_out.rs` (writing), the Autocrypt bookkeeping, and the words in `text.rs`.
- **`pe-html`**: `secure.rs`: the outer page with the labels, and each part's own document.
- **`pe-smtp`**: builds the content entity apart from the top headers and wraps it (`multipart/signed`, `multipart/encrypted`). Ordinary mail is built exactly as before; the nodemailer conformance tests say so.

### Keys

- Tables: `pgp_keys` (fingerprint, the public certificate, the wrapped private key or NULL, created, expires, revoked, where it came from, when), `pgp_key_addresses` (key, address, verified), `pgp_peers` (address, the key in use, a newer key waiting for the user's decision, Autocrypt's timestamps), `pgp_identities` (own address, its key, send the Autocrypt header), `pgp_lookups` (address, source, when, found or not).
- **The master key**: 32 random bytes, base64, in the system's store as `<profile>/pgp` through the existing `Secrets` (well under Credential Manager's 2560 byte limit, which a private key itself would not fit). Private keys are wrapped with ChaCha20-Poly1305 (`ring`, already linked), a random nonce, and the fingerprint and profile as associated data, so a wrapped key can not be moved to another row or store.
- A private key is unwrapped for one operation and wiped after it (`zeroize`); nothing decrypted stays in memory between messages.
- **No system store, no private keys**: where the store is unavailable (a Linux session without Secret Service) the app says so and keeps public keys only. Tests use `PasswordStore::Memory`.
- **A lost master key** (a reset keychain) leaves the wrapped keys unreadable: the app says which keys need their backup imported again. This is why the backup is offered at once.
- **Import**: a file, the clipboard, a key attached to a message (`application/pgp-keys`, shown as a card with Import), a vCard's `KEY`. An imported private key is unlocked with its passphrase once and stored wrapped.
- **My Keys** (Tools > Encryption Keys, and Account Properties > Security): one key per own address, aliases included. New Key, Import, Save a Backup, Export Public Key, Publish, Remove (asks, and says what will no longer be readable).
- **The Address Book**: a contact's window lists the keys of its addresses with the fingerprint in groups of four, where the key came from, Verified or not, and Find Key, Import, Verify (shows both fingerprints to compare), Export, Remove. The list of contacts shows a small key for people who have one. vCard import and export carry `KEY`.
- **A changed key**: when another key appears for an address that has one (from any source), the old one stays in use and the contact and the compose window say "A new key was found for a@example.org on 3 December" with Use the New Key and Keep. A Verified key is never replaced without that.

### Reading

1. `outline` finds the cryptographic layers. The **envelope** is the layers that start at the top of the message (RFC 9787); a layer anywhere else is a part of its own.
2. The message is cut into **sections** in their order: each protected subtree is one, the unprotected runs between them are others. Each section is decrypted or checked by itself, parsed by itself and sanitized by itself, so an unclosed tag or quote in one can not swallow the next (EFAIL's direct exfiltration), and `cid:` pictures resolve only inside their own section.
3. Each section gets a **verdict**:

| Verdict                  | Frame | Words                                                          |
| ------------------------ | ----- | -------------------------------------------------------------- |
| Verified                 | green | Signed by Alice, key verified                                  |
| Signed                   | blue  | Signed by alice@example.org (key not verified)                 |
| Signed by another person | amber | Signed by bob@example.net, who is not the sender               |
| Key not known            | grey  | Signed, but the key is not known. Find Key                     |
| Does not match           | amber | The signature does not match this text (or: why it is refused) |
| Not signed               | grey  | Not signed                                                     |

Encryption adds a lock and "Encrypted" to the label; a part that can not be decrypted says for which keys it was encrypted; a part whose integrity is not protected is not shown at all.

4. A signature counts for the sender only if the signing key has a user id with the address of the one `From` (two `From` addresses, or a `Sender` that differs, never give green).
5. The **bar** over the message is native (the header pane on Windows with Outlook Express's ribbon and lock pictures; the same place on the Mac and Linux). It gives the whole message's state by RFC 9787's rules, from the envelope only, and counts the parts: "Encrypted. Signed by Alice (verified)", or "3 parts: 1 signed by Alice, 1 not signed, 1 with a signature that does not match". Details opens a window with every layer, key, algorithm and time.
6. Attachments of a decrypted section are listed and saved as today; the list says which section each is from when there is more than one.
7. Reply and Forward quote only what was shown, section by section; a part that was hidden or not decrypted is never decrypted for a reply ("Re: What's up Johnny"), and quoting a decrypted part turns Encrypt on.

### A document for each part

The sanitizer keeps a message's own styles (mail needs them to look right), so a label drawn in the same document as mail is only as safe as our CSS against the sender's. Instead:

- **The outer page** is made by the core and holds only the labels and one `iframe` for each part. No markup from mail is ever in it, so nothing a sender writes can cover, move or restyle a label.
- **Each part is its own document**, served by the core under its own address (the scheme handler the apps have), in an `iframe` with `sandbox` (no scripts, no forms, no navigation of the page around it), its own CSP and its own picture rule. A document can not draw outside its `iframe`; that is the browser's rule, not ours.
- **Label words come from the core's own data**: the address that was checked against From, and the person's name from the Address Book if they are in it. Never the free text name of the key, so a key named "Alice (key verified)" gains nothing.
- **The labels link to Details** (`inboxclassic:part-N`), a link only the outer page can hold.
- **Heights**: an `iframe` does not grow with its content, so the app measures each part and sets its height, with a script the app itself runs in the outer page while page scripts stay off (WebView2's `ExecuteScript`, WKWebView's `evaluateJavaScript`, WebKitGTK with `enable-javascript-markup` off). Measured again when pictures load, "..." is unfolded, the text size or the window's width changes. The script is one string from the core.
- **The spike comes first** (the first step of PR 4): a page of three parts in each of the three web views, with page scripts off, measured and resized. If it fails on any of them, all three get the fallback: a native strip of the parts with their verdicts, and the web view showing the chosen part.
- A message with more than 20 parts shows the first 20 and a line that opens the rest.
- **What changes for the user**: Select All, Copy and Find work inside one part at a time. Print gets one document from the core, the labels as plain words.
- **A corpus of imitations** (a perfect copy of the green label painted in an unsigned part, styles that try to reach the outer page, content with fixed position and negative margins) is in the tests, with screenshots in the UI tests that are looked at in review.

What remains: a sender can paint a look-alike label inside their own part, where it sits under the real label of that part; and in a message with no layer at all, where there is no bar. The help says that the bar is the place to look.

### Writing

- The compose window gets **Sign** and **Encrypt** (toolbar and Message menu, the Outlook Express pictures on Windows), both off; Encrypt turns Sign on and needs a key for the From address (it offers to make one).
- With Encrypt on, each recipient gets a small lock or a warning; the missing keys are looked up then (PR 8).
- `worker::build` is the one place where a message becomes bytes; with Sign or Encrypt it goes through `protect_out`: the content entity from `pe-smtp` (7 bit clean, CRLF, no trailing spaces, `From ` lines encoded, so no relay changes signed bytes), signed (`multipart/signed`, `micalg` from the hash used) or signed and encrypted (`multipart/encrypted`).
- **The Sent copy** is the same bytes, readable through the sender's own key. **Drafts** of a message with Encrypt on are saved to the server encrypted to the own key only and not signed (RFC 9787 9.5). The recovery copy in the local store stays as it is today.
- **Undo Send and reopening a draft** go through the reading path, then `reopen`, so an encrypted Outbox entry opens again as it was written.
- **Attach My Public Key** in the Insert menu.
- Sign and Encrypt are fields of `Outgoing` checked in the core: the key must belong to the From address; an agent's message can set neither.

### Finding keys (`pe-keys`)

- Order: the local keys, then **Web Key Directory** (the advanced address `openpgpkey.<domain>`, the direct one only when that name does not exist, asked through the DNS over HTTPS the autoconfig already uses), then **keys.openpgp.org** (`/vks/v1/by-email/`).
- A key is taken only if it has a user id with exactly the address asked for; other user ids are dropped; it goes through the policy; it is stored as found, not verified, with its source.
- A miss is remembered for a day and a 429 or 503 backs off; the server allows one lookup a minute per address.
- "Key not known" on a signature offers Find Key, which asks keys.openpgp.org by fingerprint (that discloses no address).
- **Publish**: upload, then `request-verify` for the key's addresses; the status (published, waiting for confirmation) shows in My Keys.

### Autocrypt

- **Read** whenever a message's source is parsed (opened, or downloaded ahead): one `From`, the header's `addr` equal to it, not in Junk, not a bounce or other report. Ordered by the message's date as the specification says, so the order of reading does not matter. `Autocrypt-Gossip` is read inside a valid encrypted envelope only, for addresses in To and Cc only.
- **Sent** from an address that has a key, unless Account Properties > Security says not to; `Autocrypt-Gossip` inside encrypted mail to several people.
- Keys learned this way are "found" keys and follow the changed key rule above.

### Search, the list, notifications, agents

- `messages` gets a mark for encrypted and signed (from BODYSTRUCTURE at sync), shown as a small lock or ribbon in the list; `is:encrypted` and `is:signed` in search and rules.
- After a message is decrypted (opened, or in the background worker when its source is cached) its text is indexed and its snippet and inner Subject replace the placeholders. The switch off removes them again.
- Text that came from decryption is marked in the store, and the agents' list, search and `get_message` leave it out: an agent sees "Encrypted message".
- A notification of new encrypted mail shows the sender and "Encrypted message".

## The pull requests

Each PR follows "How every PR is done" below. Screenshot names are the UI tests' new steps.

### PR 1: `feat(core): the OpenPGP engine` (L, no UI)

- `pe-pgp` as above, with `policy.rs` and the `sop` example. `core/Cargo.lock`, `THIRD-PARTY-NOTICES` and the Windows link libraries (`--print native-static-libs`) follow the new dependencies. A note on the size of the exe before and after.
- Tests:
    - RFC 9580's appendix vectors and rPGP's sample keys.
    - **Fixtures made by other implementations** (`tests/fixtures/generate.sh`, committed output as the other ports do): keys, signatures and encrypted messages from GnuPG, Sequoia and OpenPGP.js, in the variants that matter (RSA 2048 to 4096, Ed25519, NIST curves, v4 and v6, SEIPDv1 and v2, compressed, with and without armor). `tests/conformance.rs` reads all of them and checks that the others' tools read ours.
    - The policy table, row by row, with keys made for it: expired at signing, revoked before and after, soft and hard revocation, SHA-1 before and after the cutoff, a signing subkey without its back signature, an encryption-only key used to sign, a signature from the future.
    - Integrity: no MDC, a stripped MDC, flipped bits, the unprotected packet, truncation; nothing of the plaintext is returned in any of them.
    - One regression test for each rPGP advisory of 2024 to 2026 (signature types that are not document signatures, the unchecked integrity case, decompression bombs, deep nesting, the secret key parser).
- Fuzz targets `pgp_cert`, `pgp_message`, `autocrypt_header`.
- CI: a job builds the `sop` example and runs encrypt, decrypt, sign and verify in both directions against `sqop` (Sequoia, a codebase that shares nothing with rPGP). A scheduled workflow, not a gate, runs the OpenPGP interoperability test suite against it and keeps the report.
- This PR also commits this plan and its overview.

### PR 2: `feat(core): the key store` (M, no UI)

- The migrations, `keys.rs` (book, master key, wrap and unwrap, import, export, backup, the changed key rule), `Key::Pgp` in `secrets.rs`, vCard `KEY`.
- C API: the key list handle and its rows, generate, import (with the passphrase), export, backup, remove, verify, the keys of an address. The header is committed. As the API changes without the apps, the PR is labelled `shells: partial` and says PR 3 is what is left.
- Tests: migration; a wrapped key does not open with another master key, another profile or on another row; the store never holds a private key in the clear (the test reads the database file for the key's bytes); import of protected and unprotected keys, wrong passphrase, a public key where a private one is expected; no system store gives public keys only; the changed key rule; vCard round trips. `PE_KEYRING_TESTS=1` runs the master key against the real stores on the three systems.

### PR 3: `feat: encryption keys` (L)

- `commands.toml`: `encryption_keys` (Tools). The My Keys window, the Security page of Account Properties, the keys in a contact's window and the key mark in the Address Book list, the Verify window, New Key (a few seconds, with the backup offered after), the card for a key attached to a message.
- Help: new topics `encryption-keys` and `verify-a-key` in every language; F1 for the new windows.
- UI tests: `keys-1-my-keys`, `keys-2-new-key`, `keys-3-backup`, `keys-4-import` (with a passphrase), `keys-5-contact`, `keys-6-verify`, `keys-7-attached-key`, `keys-8-no-keychain` (Linux).

### PR 4: `feat(core): reading protected mail` (L)

- **The spike** of "A document for each part", before anything else; its result is written into this plan.
- `pe-mime` `outline`; `pe-core` `protect.rs` (layers, sections, verdicts, the From rule, protected headers read); `pe-html` `secure.rs` (the outer page and the parts' documents); `view.rs` builds them from sections and the apps' document servers hand out each part by its address; reply and forward quote sections; the picture rule for decrypted parts (only on a click, never remembered, the label changed after); `MessageView` carries the summary and the parts for the bar.
- Tests:
    - `outline`: its ranges cut the source back into the same bytes, for every message of the pe-mime fixtures; fuzz target `mime_outline`.
    - **A corpus of mail** (`pe-core/tests/pgp_mail/`, each `.eml` with the expected sections and verdicts in a table), written for this project after the published attack classes rather than copied (the Johnny repository has no license):
        - ordinary: signed, encrypted, both, from Thunderbird, GnuPG clients, Proton, Delta Chat, K-9, Apple Mail with GPG Suite;
        - several parts signed apart, some valid, some not; a mailing list footer after a signed part;
        - EFAIL: a decrypted part between two HTML parts with an open `<img src="`; changed ciphertext; no MDC;
        - "Johnny, you are fired": a signed part hidden in `multipart/alternative` or `related`, shown through `cid:`; a signed part of someone else's old mail wrapped in new text; display name and address tricks, two From headers, Sender; HTML that paints a frame;
        - "Re: What's up Johnny": a hidden encrypted part (the reply must not hold its text), text hidden by CSS;
        - inline PGP, nested layers to the limit and beyond, a signature over a part with bare LF, trailing spaces and 8 bit text.
    - `pe-html`: the outer page holds no byte that came from a message but the escaped, capped label words (tested with hostile key names, addresses and subjects); no input makes the sanitizer emit an `iframe` or an `inboxclassic:` link; each part's document carries its own CSP.
    - Fuzz target `pgp_unwrap` (a message, a fixed key book).
    - Timing: opening an encrypted 100 KB message costs under 30 ms more than a plain one.

### PR 5: `feat: the security bar` (L)

- C API: the summary, the parts (`PeMessagePart` rows), `PE_READER_LINK_PART`, the Details data. Apps: the bar in the three readers and the message windows, serving each part's document, measuring the parts, Details, Find Key from a frame, the list of attachments by section.
- Help: `encrypted-and-signed-mail` ("what the colors mean", "look at the bar").
- UI tests (messages put into ImapKit over its API): `secure-1-verified`, `secure-2-signed-unverified`, `secure-3-encrypted`, `secure-4-mixed-parts` (three frames, three verdicts, the bar's count), `secure-5-bad-signature`, `secure-6-wrong-signer`, `secure-7-no-key`, `secure-8-fake-frame` (the painted label stays under the real one, and styles aimed at the labels change nothing), `secure-12-resized` (a part grows when its pictures load and when "..." is unfolded, nothing is cut off, no inner scroll bars), `secure-9-details`, `secure-10-inline`, `secure-11-pictures-in-decrypted` (nothing is requested before the click, also from a trusted sender with "always download" on; after it the label has changed; opened again, nothing is requested), in dark mode too on the Mac and Linux.

### PR 6: `feat(core): signing and encrypting what is sent` (M, no UI)

- `pe-smtp`: the content entity and the two wrappers. `Outgoing.sign`, `Outgoing.encrypt`; `protect_out.rs`; `compose::check` findings (no own key, recipients without a key, an encrypted quote in clear mail); drafts, the Sent copy, `reopen`, hidden Bcc.
- The e2e harness (`core/e2e`) gets OpenPGP.js as the other side: it makes signed and encrypted mail for the tests to receive, and decrypts and checks what the core sends, over two new REST calls of the harness.
- Tests: nodemailer conformance unchanged for ordinary mail; signed bytes survive a relay that rewraps (the canonical form test); `e2e_core` against ImapKit: signed mail verifies in OpenPGP.js; encrypted mail on the server holds none of the words of the text or the attachment names; the Sent copy and the draft decrypt with the own key and the draft is not signed; a Bcc recipient can decrypt and is not named in the packets; Undo Send gives the message back; a recipient without a key stops the send; the reply rule.

### PR 7: `feat: Sign and Encrypt in the compose window` (M)

- `commands.toml`: `compose_sign`, `compose_encrypt`, `attach_my_key`. `PeOutgoing` gets the two flags. The toggles, the recipients' locks, the "who has no key" window, the reply warning.
- UI tests: `write-30-sign`, `write-31-encrypt`, `write-32-missing-key`, `write-33-reply-encrypted`, `write-34-quote-in-clear`, `write-35-attach-key`; the sent messages checked through the harness.

### PR 8: `feat: finding and publishing keys` (M)

- `pe-keys`; `Core::find_keys` on the worker with an event; the Options switch; Find Key in the contact, the compose window and the frame; Publish in My Keys.
- Tests: a loopback server playing keys.openpgp.org and a Web Key Directory: found, 404, 429 with backoff, 503, a body over the limit, a redirect (refused), a key without the address asked for (refused), a key with extra user ids (dropped), an expired key; the advanced then direct order with a fake DNS; the cache and the day of remembering a miss; upload and request-verify. `PE_NETWORK_TESTS=1`: one lookup by fingerprint on the real keys.openpgp.org and one real Web Key Directory. UI tests against the loopback server: `keys-9-find`, `keys-10-not-found`, `keys-11-publish`, `write-36-found-on-encrypt`.

### PR 9: `feat: Autocrypt` (M)

- Reading and sending as above, gossip, the Account Properties switch, the changed key notice in the contact and the compose window.
- Tests: Autocrypt's own example headers; the rules (two From, `addr` mismatch, Junk, reports, an older message read later); `e2e_core`: a header from OpenPGP.js is learned, ours is read by it, gossip only inside encryption; UI tests `keys-12-learned`, `keys-13-changed-key`, `account-13-security`.

### PR 10: `feat: encrypted mail in search, the list and for agents` (M)

- The marks, `is:encrypted`, `is:signed`, the background decryption for the index, the Options switch and its clean up, the notification words, the wall for agents.
- Tests: store and query tests; `e2e_core`: an encrypted message is found by a word of its text after the background pass, not after the switch is off; `pe-mcp` e2e: list, search and get never return decrypted words, and no tool signs or encrypts. UI tests: `main-12-lock-in-list`, `search-9-encrypted`, `options-4-encryption`.

### PR 11: `chore: OpenPGP hardening` (M)

- The whole feature at once, not one diff: `/security-review` over `master` against the tag 0.18.0, and the `security-audit` skill's review of `pe-pgp`, `protect.rs`, `keys.rs` and `secure.rs` with the threat list below as its checklist.
- Each fuzz target run for an hour, its corpus committed; the interoperability suite's report read and its failures either fixed or listed with the reason.
- The help complete in every language; `docs/shells.md`; CLAUDE.md gets the crates and the rules of this plan that later work must keep.
- `/simplify` over the feature's code as a whole.

## How every PR is done

1. On master, `git pull`, then a branch (`feat/<name>`) in a git worktree of its own.
2. The core and its tests first: unit tests, the corpus, migration tests, `e2e_core` against ImapKit for anything that talks IMAP or SMTP.
3. `core/commands.toml` or the C API; rebuild `pe-ffi` and commit the header and the generated command tables.
4. The three apps.
5. Translations: English, then drafts in German, Estonian, Spanish and French by `core/locales/GLOSSARY.md` (which first gets the terms: key, fingerprint, signed, encrypted, verified), each marked `# review: new`; `pe-i18n` tests and the pseudo-language run.
6. Help in every language (translations marked for review), `docs/shells.md`.
7. **UI end-to-end**: the step in `scripts/ui-e2e/SCENARIO.md` and in the three runners, the entry in `scripts/feature-map.mjs`; run the three, look at the screenshots, `feature-map.mjs --check` for each platform.
8. **UX review until nothing is left**, from the screenshots of all three platforms, as in the last round; for this feature also: can every state be told from every other at a glance, in light and dark, and without color (the words and the pictures carry it too).
9. **/simplify** over the changed code, with the maintainability check.
10. **/security-review** of the branch; fix what it finds, then go on in the same turn.
11. `cargo fmt --all`, `cargo clippy --workspace --all-targets -- -D warnings`, `cargo test --workspace`, prettier, `scripts/check-shells.sh`.
12. Commits: `feat(core)`, `feat(windows)`, `feat(mac)`, `feat(linux)`, `feat(i18n)`, `docs(help)`, `test(e2e)`, then `fix(ux)`, `refactor` and `fix` as the reviews need.
13. Push, open the PR, `gh run watch`. Fix real failures; rerun flaky jobs at most 3 times.
14. Merge with a merge commit once CI is green and the last review round found nothing.

PRs 1, 2, 4 and 6 are core only; 1 and the `outline` of 4 can be built side by side.

## How it is tested, in one place

| Layer                | What                                                                                                        | Where                                 |
| -------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| Vectors              | RFC 9580 appendix, rPGP's samples, Autocrypt's examples                                                     | `pe-pgp/tests`                        |
| Other clients' data  | Committed fixtures from GnuPG, Sequoia and OpenPGP.js, regenerated by a script                              | `pe-pgp/tests/conformance.rs`         |
| Live cross-check     | Our `sop` against `sqop`, both directions, on every PR; the interoperability suite on a schedule            | CI                                    |
| Policy               | One test a row of the policy table                                                                          | `pe-pgp/tests/policy.rs`              |
| Known attacks        | The mail corpus with expected verdicts; advisory regressions                                                | `pe-core/tests/pgp_mail`              |
| Fuzzing              | `pgp_cert`, `pgp_message`, `autocrypt_header`, `mime_outline`, `pgp_unwrap`                                 | `core/fuzz`                           |
| Keys at rest         | Wrapping, the file never holding a private key, the real system stores                                      | `pe-core`, `PE_KEYRING_TESTS=1`       |
| Network              | Loopback keys.openpgp.org and Web Key Directory; one live lookup                                            | `pe-keys/tests`, `PE_NETWORK_TESTS=1` |
| End to end, the core | ImapKit with OpenPGP.js as the other person: send, receive, drafts, Sent, Bcc, Undo Send, search, agents    | `pe-core/tests/e2e_core.rs`, `pe-mcp` |
| End to end, the apps | The steps `keys-*`, `secure-*`, `write-30` to `36`, on the three platforms, light and dark, pseudo-language | the UI tests, `feature-map.mjs`       |

## Threats and what answers them

| Threat                                                             | Answer                                                                                                                                          |
| ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Changed ciphertext, plaintext sent out through HTML (EFAIL)        | Integrity before any plaintext; sections sanitized apart; pictures in decrypted parts only on a click, then no longer called encrypted; the CSP |
| A valid signature wrapped in someone else's message                | Only the envelope gives the message's state; every other layer is a framed part; the From rule                                                  |
| A painted "verified" frame                                         | Labels and mail never share a document; label words from the core only; the bar's count; the imitation tests                                    |
| A hidden encrypted part leaked by a reply                          | Replies quote what was shown; nothing is decrypted for a reply; an encrypted quote forces Encrypt                                               |
| A wrong key planted on a server or in a header                     | Two levels of trust; exact address match; no silent key change; Web Key Directory before the key server                                         |
| A stolen store file                                                | Private keys wrapped under the master key in the system's store; bound to their row and profile                                                 |
| Malformed packets: crashes, bombs, endless loops                   | Limits in `pe-pgp`, the fuzz targets, `catch_unwind` at the C API, rPGP followed release by release                                             |
| Weak or old cryptography accepted                                  | The policy table, judged at signing time                                                                                                        |
| Addresses disclosed by lookups                                     | Only on Encrypt or Find Key; the domain's own directory first; a cache; a switch                                                                |
| An agent reading or signing as the user                            | No decrypted text, snippet or search result for agents; no tool reaches keys, Sign or Encrypt                                                   |
| Mail half encrypted; drafts and Sent copies in the clear on a host | Send stops on a missing key; drafts and the Sent copy are encrypted to the own key                                                              |

## At the end

- Every PR merged; the release-please PR collects them as the next minor version and is left for you. Before it: `node scripts/i18n-review.mjs --html build/i18n-review.html` and your review of the translations.
- `build/windows-ux-pending.md` empty, or its open items listed with the reason.
- The homepage gets a screenshot of an encrypted message and a paragraph (`postalsys/inboxclassic.com`).
- The work starts when you say go.

## As built: where the result differs from the plan

- **PR 1, the engine**:
    - SHA-1 follows Sequoia's two cutoffs (data signatures until February 2013, key bindings until February 2023) rather than "never for key bindings": keys from before 2019 were bound with SHA-1 and are still in use. DSA and ElGamal keys are refused.
    - The other implementations' fixtures come from GnuPG, Sequoia (through `sqop`) and OpenPGP.js, eight kinds of key including v6 and RSA 4096; GopenPGP was left out (no package; the three cover the formats).
    - rPGP is built without bzip2: no client this app talks to uses it, and every decompressor is one more parser of hostile data.
    - Signatures in encrypted mail name the visible recipients (Intended Recipient Fingerprint, RFC 9580), and a signature that names recipients but not the one who decrypted it is "not for you": signed content can not be passed on as if written to someone else. A message with hidden recipients names none (naming them would show them), which is one more reason for PR 6 to give each Bcc recipient a copy of their own.
    - The live cross-check (`scripts/pgp-interop.sh`, CI's `pgp-interop` job) runs against GnuPG too, not only Sequoia. The scheduled run of the OpenPGP interoperability test suite moves to PR 11.
- **PR 4, reading**:
    - Parts are joined into one document only when they come from the same layer and have the same verdict (the parts under one envelope, a run of unprotected parts). Two parts encrypted apart are always two documents, even with equal verdicts: anyone can encrypt a part to the user, and one drawn in the same document as a captured ciphertext could carry its plaintext away.
    - A `multipart/encrypted` whose content is OpenPGP data that is not encrypted is shown as broken, not as encrypted; a `multipart/signed` inside an encryption is judged for the user's key that opened it, so a signed message written to someone else and put in a new envelope reads "not for you".
    - Labels name a signer by the Address Book's name of the address that was checked, else by that address; never by the key's own user id text.
- **PR 11, hardening**:
    - The OpenPGP interoperability test suite (Sequoia's, `scripts/pgp-interop-suite.sh`, weekly in `.github/workflows/pgp-interop-suite.yml`, its report kept as an artifact) runs `pe-pgp`'s `sop` beside `sqop`. Its first run found six things, fixed with a test each: a message compressed more than once came out as the compressed bytes past the first layer, with no limit on the depth (now four layers, then refused); a key whose ECDH parameters name IDEA, 3DES, CAST5 or Blowfish for the key wrap was encrypted to; a signature or binding with a critical notation counted (RFC 9580 says a critical notation not understood makes it invalid, and none is understood here); a signing subkey's back signature counted after it expired; a false back signature put before the real one hid it; and a key not marked for encryption (a signing subkey, a certifying primary key) decrypted what was encrypted to it.
    - What the suite still scores as failures, on purpose or out of scope: post-quantum keys and persistent symmetric keys (not in this round); the 2k to 3k RSA rows, where the suite wants a warning that neither implementation gives; decrypting with one's own RSA key under 2048 bits (the weakness is the sender's to avoid, refusing helps no one); subkeys of unknown algorithms or curves in opaque encodings, which make rPGP refuse the whole certificate; secret keys whose primary is a public key or a GnuPG stub (offline primary keys, like smartcards, are not in this round); a revocation that expires (the key stays revoked); a v6 issuer fingerprint in a v4 signature (Sequoia refuses it too); text mode signatures over a bare CR (mail is signed in binary mode over CRLF text); choosing AES-256 where the recipient lists AES-128 first; and a bundle with one unusable certificate, which `sop` refuses as the app refuses to send when one recipient has no usable key. The suite's tests of SOP options the example does not have (passwords, inline and cleartext signatures, `--no-armor`, several user ids or signers at once) are not run for it.
    - The audit of the whole feature against the threat list found five gaps, each fixed with a test: a stored key that is not the one in use for an address (one waiting for the user's decision, one kept away with Keep) signed for its sender in blue, so only the key in use now does; a Subject protected inside an encryption went into the clear Subject of a reply or forward, which now takes the Subject the message travelled under; background decryption had no panic boundary, so a message that made a parser panic stopped the background work of its account on every pass; a password store that could not be read (locked, refused) read as having no master key, and the next new key wrote a new one over it, locking every private key; and a Sender other than the From was not part of the From rule.
    - Not changed: once pictures load in a decrypted part, its label adds "Pictures were loaded from the internet" after the words of its protection rather than dropping "Encrypted", which still says how it came. The `/simplify` pass did not cache unwrapped private keys between opens, which the rule of unwrapping a key for one operation forbids.
