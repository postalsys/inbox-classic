//! Hostile messages: mutated versions of the conformance messages must parse or fail with a
//! limit error, never panic, and stay within the limits. Deterministic (a fixed seed); core/fuzz
//! has the open-ended cargo-fuzz target.

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use pe_mime::parser::{Limits, parse_with};

struct Rng(u64);

impl Rng {
    fn next(&mut self) -> u64 {
        self.0 ^= self.0 >> 12;
        self.0 ^= self.0 << 25;
        self.0 ^= self.0 >> 27;
        self.0.wrapping_mul(0x2545_f491_4f6c_dd1d)
    }

    fn below(&mut self, n: usize) -> usize {
        (self.next() % n.max(1) as u64) as usize
    }
}

const INTERESTING: &[&[u8]] = &[
    b"\r\n",
    b"\n",
    b"--",
    b"=?UTF-8?B?",
    b"?=",
    b"=",
    b";",
    b"\"",
    b"(",
    b")",
    b"<",
    b">",
    b":",
    b",",
    b"Content-Type: multipart/mixed; boundary=x\r\n\r\n--x\r\n",
    b"Content-Type: message/rfc822\r\n\r\n",
    b"Content-Transfer-Encoding: base64\r\n",
    b"Content-Transfer-Encoding: quoted-printable\r\n",
    b"\xff\xfe",
    b"\x00",
    b"charset=utf-16",
    b"&#x",
    b"<a href=",
    b"filename*0*=utf-8''%",
];

fn mutate(rng: &mut Rng, input: &[u8]) -> Vec<u8> {
    let mut out = input.to_vec();
    for _ in 0..=rng.below(6) {
        let at = rng.below(out.len() + 1);
        match rng.below(5) {
            0 => {
                let piece = INTERESTING[rng.below(INTERESTING.len())];
                out.splice(at..at, piece.iter().copied());
            }
            1 if !out.is_empty() => {
                let end = (at + rng.below(32)).min(out.len());
                out.drain(at.min(end)..end);
            }
            2 => out.truncate(at),
            3 => {
                let piece = out[at..(at + rng.below(256)).min(out.len())].to_vec();
                out.splice(at..at, piece);
            }
            _ => out.insert(at, rng.next() as u8),
        }
    }
    out
}

#[test]
fn mutated_messages_do_not_panic() {
    let cases: serde_json::Value = serde_json::from_str(include_str!("fixtures/message-cases.json")).unwrap();
    let inputs: Vec<Vec<u8>> = cases["messages"]
        .as_array()
        .unwrap()
        .iter()
        .map(|c| STANDARD.decode(c["raw"].as_str().unwrap()).unwrap())
        .collect();
    let limits = Limits {
        max_nesting_depth: 16,
        max_headers_size: 64 * 1024,
        max_part_count: 128,
        max_rfc822_nesting_depth: 3,
        max_forwarded_addresses: 128,
    };
    let mut rng = Rng(0x5eed_1234_abcd_ef01);
    for round in 0..3_000 {
        let input = mutate(&mut rng, &inputs[round % inputs.len()]);
        if let Err(error) = parse_with(&input, limits) {
            assert!(error.code.starts_with("EMAX"), "{error}");
        }
    }
}

#[test]
fn limits_hold() {
    let limits = Limits::default();
    // a part per line, past the part count
    let mut wide = b"Content-Type: multipart/mixed; boundary=b\r\n\r\n".to_vec();
    for _ in 0..=limits.max_part_count {
        wide.extend_from_slice(b"--b\r\n\r\nx\r\n");
    }
    assert_eq!(parse_with(&wide, limits).unwrap_err().code, "EMAXPARTCOUNT");
    // headers past the size limit
    let mut long = Vec::new();
    for i in 0..40_000 {
        long.extend(format!("X-Header-{i}: value\r\n").bytes());
    }
    assert_eq!(parse_with(&long, limits).unwrap_err().code, "EMAXHEADERSIZE");
}

/// Inputs the fuzzer (core/fuzz) found to crash the parser, kept so they stay fixed
#[test]
fn fuzzer_findings() {
    let findings: [&[u8]; 1] = [
        // a Date zone of '+' and four bytes cutting a character in two
        &[
            100, 97, 116, 101, 58, 1, 32, 32, 58, 32, 32, 32, 32, 57, 32, 32, 1, 32, 32, 32, 32, 32, 32, 32, 32, 43, 0,
            212, 0, 32, 32, 0, 32, 32, 32, 32, 58, 221,
        ],
    ];
    for input in findings {
        let _ = pe_mime::parser::parse(input);
    }
}
