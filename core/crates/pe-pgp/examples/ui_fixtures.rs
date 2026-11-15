//! The keys and messages of the UI tests' signed and encrypted mail (`scripts/ui-e2e/pgp/`), made once and committed:
//! `cargo run -p pe-pgp --example ui_fixtures -- <dir>`.
//!
//! - `me.asc`: a private key of the test account's address (testuser@inboxclassic.test), protected by the passphrase
//!   in `me.passphrase`, imported by the tests; `alice.asc` and `mallory.asc`: public keys the tests import; Dave's key
//!   is in no file, so his signature's key is not known.
//! - One message a case, each a whole `.eml` the tests put in the Inbox (the `secure-*` steps of SCENARIO.md).

use std::path::Path;

use pe_pgp::{SecretKey, encrypt, generate, sign_detached};

/// 1 November 2026, 10:00 UTC: when the keys were made and the messages signed
const AT: i64 = 1_793_527_200;
const ME: &str = "testuser@inboxclassic.test";
const PASSPHRASE: &str = "ui test passphrase";

fn headers(from: &str, subject: &str, id: &str, content_type: &str) -> String {
    format!(
        "From: {from}\r\nTo: Alex Morgan <{ME}>\r\nSubject: {subject}\r\nDate: Sun, 01 Nov 2026 10:00:00 +0000\r\n\
         Message-ID: <{id}@ui-test.example>\r\nMIME-Version: 1.0\r\nContent-Type: {content_type}\r\n\r\n"
    )
}

fn text(body: &str) -> String {
    format!("Content-Type: text/plain; charset=utf-8\r\n\r\n{body}")
}

fn html(body: &str) -> String {
    format!("Content-Type: text/html; charset=utf-8\r\n\r\n{body}")
}

/// A multipart/signed entity of `content`, with its own Content-Type line first
fn signed(content: &str, key: &SecretKey, boundary: &str) -> String {
    let signature = sign_detached(content.as_bytes(), key, AT).expect("signed");
    format!(
        "Content-Type: multipart/signed; micalg={}; protocol=\"application/pgp-signature\"; boundary=\"{boundary}\"\r\n\r\n\
         --{boundary}\r\n{content}\r\n--{boundary}\r\nContent-Type: application/pgp-signature\r\n\r\n{}\r\n--{boundary}--\r\n",
        signature.micalg, signature.signature
    )
}

fn encrypted(inner: &str, to: &SecretKey, signer: Option<&SecretKey>, boundary: &str) -> String {
    let armored = encrypt(inner.as_bytes().to_vec(), &[to.cert()], &[], signer, AT).expect("encrypted");
    format!(
        "Content-Type: multipart/encrypted; protocol=\"application/pgp-encrypted\"; boundary=\"{boundary}\"\r\n\r\n\
         --{boundary}\r\nContent-Type: application/pgp-encrypted\r\n\r\nVersion: 1\r\n--{boundary}\r\n\
         Content-Type: application/octet-stream\r\n\r\n{armored}\r\n--{boundary}--\r\n"
    )
}

fn mixed(parts: &[String]) -> String {
    let mut out = String::from("Content-Type: multipart/mixed; boundary=\"mix\"\r\n\r\n");
    for part in parts {
        out.push_str("--mix\r\n");
        out.push_str(part);
        out.push_str("\r\n");
    }
    out.push_str("--mix--\r\n");
    out
}

/// A whole message of `entity`, whose first line is its Content-Type
fn message(from: &str, subject: &str, id: &str, entity: &str) -> String {
    let (first, rest) = entity.split_once("\r\n").expect("a Content-Type line");
    let content_type = first.strip_prefix("Content-Type: ").expect("Content-Type");
    let rest = rest.strip_prefix("\r\n").unwrap_or(rest);
    headers(from, subject, id, content_type) + rest
}

fn write(dir: &Path, name: &str, content: &str) {
    std::fs::write(dir.join(name), content).expect("written");
}

fn main() {
    let dir = std::env::args().nth(1).expect("the directory to write to");
    let dir = Path::new(&dir);
    std::fs::create_dir_all(dir).expect("the directory");
    let me = generate("Alex Morgan", &[ME.into()], AT).expect("my key");
    let alice = generate("Alice Example", &["alice@example.org".into()], AT).expect("Alice's key");
    let mallory = generate("Mallory", &["mallory@example.net".into()], AT).expect("Mallory's key");
    let dave = generate("Dave", &["dave@example.com".into()], AT).expect("Dave's key");
    write(dir, "me.asc", &me.backup(PASSPHRASE).expect("backup"));
    write(dir, "me.passphrase", PASSPHRASE);
    write(dir, "alice.asc", &alice.cert().armored());
    write(dir, "mallory.asc", &mallory.cert().armored());
    let alice_from = "Alice Example <alice@example.org>";

    let contract = text("The contract is attached in words: we agree on the price.");
    write(
        dir,
        "secure-signed.eml",
        &message(alice_from, "Signed by Alice", "signed", &signed(&contract, &alice, "s")),
    );
    let secret = text("The secret plan: we meet at noon by the old mill.");
    write(
        dir,
        "secure-encrypted.eml",
        &message(
            alice_from,
            "...",
            "encrypted",
            &encrypted(&secret, &me, Some(&alice), "e"),
        ),
    );
    write(
        dir,
        "secure-mixed.eml",
        &message(
            alice_from,
            "Parts signed apart",
            "mixed",
            &mixed(&[
                text("A note added on the way, not signed."),
                signed(&text("The signed paragraph."), &alice, "s"),
                text("-- \r\nSent through the example list"),
            ]),
        ),
    );
    let bad = signed(&text("Pay 100 euros."), &alice, "s").replace("Pay 100 euros.", "Pay 900 euros.");
    write(
        dir,
        "secure-bad.eml",
        &message(alice_from, "A changed text", "bad", &bad),
    );
    write(
        dir,
        "secure-wrong-signer.eml",
        &message(
            alice_from,
            "Signed by someone else",
            "wrong-signer",
            &signed(&text("I am Alice, honestly."), &mallory, "s"),
        ),
    );
    write(
        dir,
        "secure-no-key.eml",
        &message(
            "Dave <dave@example.com>",
            "A key you do not have",
            "no-key",
            &signed(&text("Hello from Dave."), &dave, "s"),
        ),
    );
    // a frame painted in the sender's own HTML, beside a part Alice really signed: the real label stays over each
    let painted = html(
        "<div style=\"border:2px solid #2e7d32;border-radius:6px;position:fixed;top:0;left:0;right:0;z-index:99999\">\
         <div style=\"background:#e8f5e9;color:#1b5e20;font:bold 9pt Arial;padding:4px 10px\">\
         Signed by Alice Example, key verified</div><p style=\"padding:8px\">Wire the money today.</p></div>\
         <style>body{margin-top:-200px} .pe-l{display:none}</style>",
    );
    write(
        dir,
        "secure-fake-frame.eml",
        &message(
            alice_from,
            "A painted frame",
            "fake-frame",
            &mixed(&[painted, signed(&text("Lunch on Friday?"), &alice, "s")]),
        ),
    );
    let inline = encrypt(b"Inline: the door code is 4711.".to_vec(), &[me.cert()], &[], None, AT).expect("encrypted");
    write(
        dir,
        "secure-inline.eml",
        &message(
            alice_from,
            "Inline encrypted",
            "inline",
            &text(&format!("Here it is:\r\n\r\n{inline}\r\nBye")),
        ),
    );
    let pictures = html(
        "<p>The plan, with a picture from the internet:</p>\
         <img src=\"https://pictures.ui-test.invalid/plan.png\" width=\"40\" height=\"40\" alt=\"plan\">",
    );
    write(
        dir,
        "secure-pictures.eml",
        &message(
            alice_from,
            "Encrypted with a picture",
            "pictures",
            &encrypted(&pictures, &me, Some(&alice), "e"),
        ),
    );
    // a long part with an earlier message folded behind "...": its frame grows when it unfolds, and is as tall as it
    let mut long = String::from("<p>The long part starts here.</p>");
    for line in 1..=40 {
        long.push_str(&format!("<p>Line {line} of the long part.</p>"));
    }
    long.push_str(
        "<p>The long part ends here.</p><div class=\"gmail_quote\">On Sat, 31 Oct 2026, Bob wrote:<br>\
         <blockquote>The earlier message, folded.</blockquote></div>",
    );
    write(
        dir,
        "secure-long.eml",
        &message(
            alice_from,
            "A long encrypted message",
            "long",
            &encrypted(&html(&long), &me, Some(&alice), "e"),
        ),
    );
}
