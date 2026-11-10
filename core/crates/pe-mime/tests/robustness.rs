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

/// GHSA-q8wm-54mj-r36p: lines that share a long prefix with every boundary of a deeply nested message
/// cost about what plain lines of the same size do, as each line is looked up once
#[test]
fn near_miss_boundaries_cost_like_plain_lines() {
    let prefix = "x".repeat(60);
    let mut head = String::new();
    for i in 0..250 {
        head.push_str(&format!(
            "Content-Type: multipart/mixed; boundary=\"{prefix}{i:03}\"\r\n\r\n--{prefix}{i:03}\r\n"
        ));
    }
    let message = |line: &str| {
        let mut raw = head.clone().into_bytes();
        for _ in 0..40_000 {
            raw.extend(line.as_bytes());
        }
        raw
    };
    let near = message(&format!("--{prefix}99z\r\n"));
    let plain = message(&format!("{}\r\n", "y".repeat(prefix.len() + 5)));
    assert_eq!(near.len(), plain.len());
    let time = |raw: &[u8]| {
        let started = std::time::Instant::now();
        parse_with(raw, Limits::default()).unwrap();
        started.elapsed()
    };
    // warm up, then the better of three runs of each
    time(&plain);
    let best = |raw: &[u8]| (0..3).map(|_| time(raw)).min().unwrap();
    let (near, plain) = (best(&near), best(&plain));
    assert!(
        near < plain * 4 + std::time::Duration::from_millis(50),
        "near misses {near:?}, plain {plain:?}"
    );
}
