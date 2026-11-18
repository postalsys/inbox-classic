//! The UI tests' message with a picture in each of two parts, one of them encrypted (`secure-previews.eml` in
//! `scripts/ui-e2e/pgp/`), made once and committed with the committed `me.asc`, so the other fixtures and keys stay as
//! they are: `cargo run -p pe-pgp --example ui_fixture_previews -- ../scripts/ui-e2e/pgp`.
//!
//! The first part is not protected and carries `harbour.png`; the second is encrypted to the test account's key and
//! carries `floor-plan.png`. Each part's previews show in its own document under a token of its own: the plain part,
//! which anyone on the way could have added, can not show or ask for the encrypted part's picture. The pictures are
//! drawn here (no one's real file) and written as PNG without compression, so nothing but std is needed.

use std::path::Path;

use pe_pgp::{encrypt, read_secret_keys};

/// 1 November 2026, 10:00 UTC, as the other fixtures
const AT: i64 = 1_793_527_200;
const ME: &str = "testuser@inboxclassic.test";

fn crc32(bytes: &[u8]) -> u32 {
    let mut crc = 0xffff_ffffu32;
    for &byte in bytes {
        crc ^= u32::from(byte);
        for _ in 0..8 {
            crc = if crc & 1 == 1 {
                (crc >> 1) ^ 0xedb8_8320
            } else {
                crc >> 1
            };
        }
    }
    !crc
}

fn adler32(bytes: &[u8]) -> u32 {
    let (mut a, mut b) = (1u32, 0u32);
    for &byte in bytes {
        a = (a + u32::from(byte)) % 65_521;
        b = (b + a) % 65_521;
    }
    (b << 16) | a
}

fn chunk(out: &mut Vec<u8>, kind: &[u8], data: &[u8]) {
    out.extend_from_slice(&(data.len() as u32).to_be_bytes());
    let mut body = kind.to_vec();
    body.extend_from_slice(data);
    out.extend_from_slice(&body);
    out.extend_from_slice(&crc32(&body).to_be_bytes());
}

/// An RGB picture as PNG, its deflate stream of stored blocks
fn png(width: u32, height: u32, pixel: impl Fn(u32, u32) -> [u8; 3]) -> Vec<u8> {
    let mut raw = Vec::new();
    for y in 0..height {
        raw.push(0);
        for x in 0..width {
            raw.extend_from_slice(&pixel(x, y));
        }
    }
    let mut zlib = vec![0x78, 0x01];
    let blocks: Vec<&[u8]> = raw.chunks(65_535).collect();
    for (index, block) in blocks.iter().enumerate() {
        zlib.push(u8::from(index + 1 == blocks.len()));
        let length = block.len() as u16;
        zlib.extend_from_slice(&length.to_le_bytes());
        zlib.extend_from_slice(&(!length).to_le_bytes());
        zlib.extend_from_slice(block);
    }
    zlib.extend_from_slice(&adler32(&raw).to_be_bytes());
    let mut header = width.to_be_bytes().to_vec();
    header.extend_from_slice(&height.to_be_bytes());
    header.extend_from_slice(&[8, 2, 0, 0, 0]);
    let mut out = b"\x89PNG\r\n\x1a\n".to_vec();
    chunk(&mut out, b"IHDR", &header);
    chunk(&mut out, b"IDAT", &zlib);
    chunk(&mut out, b"IEND", &[]);
    out
}

/// A harbour at noon: sky, a white pier, water
fn harbour(x: u32, y: u32) -> [u8; 3] {
    match y {
        0..90 => [(120 + y / 2) as u8, (170 + y / 3) as u8, 230],
        90..104 if (40..200).contains(&x) => [245, 245, 240],
        _ => [20, (90 + (x + y) % 24) as u8, (140 + y / 8) as u8],
    }
}

/// A floor plan: lines on paper, one room shaded
fn floor_plan(x: u32, y: u32) -> [u8; 3] {
    let wall = x % 60 < 3 || y % 50 < 3 || x > 236 || y > 146;
    match (wall, (60..120).contains(&x) && (50..100).contains(&y)) {
        (true, _) => [60, 60, 70],
        (false, true) => [214, 228, 247],
        _ => [250, 246, 236],
    }
}

fn base64(bytes: &[u8]) -> String {
    const ALPHABET: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let mut out = String::new();
    for (index, three) in bytes.chunks(3).enumerate() {
        if index > 0 && index % 19 == 0 {
            out.push_str("\r\n");
        }
        let n = three
            .iter()
            .enumerate()
            .fold(0u32, |n, (i, &b)| n | u32::from(b) << (16 - 8 * i));
        for i in 0..4 {
            let shown = i <= three.len();
            out.push(if shown {
                ALPHABET[(n >> (18 - 6 * i) & 63) as usize] as char
            } else {
                '='
            });
        }
    }
    out
}

fn picture(name: &str, bytes: &[u8]) -> String {
    format!(
        "Content-Type: image/png; name=\"{name}\"\r\nContent-Disposition: attachment; filename=\"{name}\"\r\n\
         Content-Transfer-Encoding: base64\r\n\r\n{}",
        base64(bytes)
    )
}

fn mixed(boundary: &str, parts: &[String]) -> String {
    let mut out = format!("Content-Type: multipart/mixed; boundary=\"{boundary}\"\r\n\r\n");
    for part in parts {
        out.push_str(&format!("--{boundary}\r\n{part}\r\n"));
    }
    out.push_str(&format!("--{boundary}--\r\n"));
    out
}

fn main() {
    let dir = std::env::args().nth(1).expect("the directory of me.asc");
    let dir = Path::new(&dir);
    let read = |name: &str| std::fs::read(dir.join(name)).expect(name);
    let passphrase = String::from_utf8(read("me.passphrase")).expect("a passphrase");
    let me = read_secret_keys(&read("me.asc"), passphrase.trim())
        .expect("me.asc")
        .remove(0);
    let text = |words: &str| format!("Content-Type: text/plain; charset=utf-8\r\n\r\n{words}");
    let plain = mixed(
        "p",
        &[
            text("The harbour, as promised."),
            picture("harbour.png", &png(240, 150, harbour)),
        ],
    );
    let inner = mixed(
        "i",
        &[
            text("The floor plan, for your eyes only."),
            picture("floor-plan.png", &png(240, 150, floor_plan)),
        ],
    );
    let armored = encrypt(inner.into_bytes(), &[me.cert()], &[], None, AT).expect("encrypted");
    let sealed = format!(
        "Content-Type: multipart/encrypted; protocol=\"application/pgp-encrypted\"; boundary=\"e\"\r\n\r\n\
         --e\r\nContent-Type: application/pgp-encrypted\r\n\r\nVersion: 1\r\n--e\r\n\
         Content-Type: application/octet-stream\r\n\r\n{armored}\r\n--e--\r\n"
    );
    let body = mixed("mix", &[plain, sealed]);
    let (content_type, rest) = body.split_once("\r\n\r\n").expect("a body");
    let message = format!(
        "From: Alice Example <alice@example.org>\r\nTo: Alex Morgan <{ME}>\r\nSubject: Two pictures, one sealed\r\n\
         Date: Sun, 01 Nov 2026 10:00:00 +0000\r\nMessage-ID: <previews@ui-test.example>\r\nMIME-Version: 1.0\r\n\
         {content_type}\r\n\r\n{rest}"
    );
    std::fs::write(dir.join("secure-previews.eml"), message).expect("written");
}
