//! Hostile input: mutated responses must never panic the framer or the parser, and every value the
//! compiler writes must come back unchanged when parsed, so no value can change the shape of a
//! command. Deterministic (a fixed seed), so a failure reproduces; core/fuzz has the open-ended
//! cargo-fuzz targets.

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use pe_imap::{Arg, Command, CompileOptions, FrameLimits, Framer, ParserOptions, Token, compile, parse_with};

/// xorshift64*, enough for test input
struct Rng(u64);

impl Rng {
    fn next(&mut self) -> u64 {
        self.0 ^= self.0 >> 12;
        self.0 ^= self.0 << 25;
        self.0 ^= self.0 >> 27;
        self.0.wrapping_mul(0x2545_f491_4f6c_dd1d)
    }

    fn below(&mut self, n: usize) -> usize {
        (self.next() % n as u64) as usize
    }
}

const INTERESTING: &[u8] = b"()[]{}<>\"\\*%~:,.+ \r\n\x00\x7f\xc3NIL0123456789";

fn mutate(rng: &mut Rng, input: &[u8]) -> Vec<u8> {
    let mut out = input.to_vec();
    for _ in 0..=rng.below(4) {
        let at = if out.is_empty() { 0 } else { rng.below(out.len() + 1) };
        match rng.below(6) {
            0 if !out.is_empty() => {
                let i = at.min(out.len() - 1);
                out[i] = INTERESTING[rng.below(INTERESTING.len())];
            }
            1 => out.insert(at, INTERESTING[rng.below(INTERESTING.len())]),
            2 if !out.is_empty() => {
                out.remove(at.min(out.len() - 1));
            }
            3 => out.truncate(at),
            4 => {
                let piece = out[at..].to_vec();
                out.extend_from_slice(&piece);
            }
            _ => out.insert(at, rng.next() as u8),
        }
    }
    out
}

fn inputs() -> Vec<Vec<u8>> {
    let cases: Vec<serde_json::Value> = serde_json::from_str(include_str!("fixtures/parser-cases.json")).unwrap();
    cases
        .iter()
        .map(|case| {
            let mut wire = case["input"].as_str().unwrap().as_bytes().to_vec();
            wire.extend_from_slice(b"\r\n");
            wire
        })
        .collect()
}

#[test]
fn mutated_responses_do_not_panic() {
    let limits = FrameLimits {
        max_line: 1 << 16,
        max_literal: 1 << 16,
        max_response: 1 << 17,
    };
    let options = ParserOptions { max_tokens: 10_000 };
    let mut rng = Rng(0x9e37_79b9_7f4a_7c15);
    let inputs = inputs();
    for round in 0..20_000 {
        let wire = mutate(&mut rng, &inputs[round % inputs.len()]);
        let mut framer = Framer::new(limits);
        // also split at a random point, as the network does
        let split = rng.below(wire.len() + 1);
        let mut responses = Vec::new();
        if framer.push(&wire[..split], &mut responses).is_ok() {
            let _ = framer.push(&wire[split..], &mut responses);
        }
        for response in responses {
            let _ = response.parse_with(&options);
        }
        // the parser on its own, with whatever literals are at hand
        let _ = parse_with(&wire, vec![b"x".to_vec(); rng.below(3)], &options);
    }
}

fn round_trip(value: &[u8], options: &CompileOptions) -> Token {
    let command = Command {
        tag: "A1".into(),
        name: "LOGIN".into(),
        args: vec![Arg::Str(value.to_vec())],
    };
    let wire: Vec<u8> = compile(&command, options).unwrap().concat();
    let mut responses = Vec::new();
    Framer::default().push(&wire, &mut responses).unwrap();
    assert_eq!(responses.len(), 1, "{wire:?}");
    let parsed = responses
        .remove(0)
        .parse()
        .unwrap_or_else(|error| panic!("{error} for {wire:?}"));
    assert_eq!(parsed.tag, "A1");
    assert_eq!(parsed.command, "LOGIN");
    assert_eq!(parsed.attributes.len(), 1, "{wire:?}");
    parsed.attributes[0].clone()
}

#[test]
fn compiled_strings_parse_back() {
    let mut rng = Rng(42);
    let utf8 = CompileOptions {
        utf8: true,
        ..Default::default()
    };
    for _ in 0..5_000 {
        let length = rng.below(40);
        let value: Vec<u8> = (0..length)
            .map(|_| match rng.below(3) {
                0 => INTERESTING[rng.below(INTERESTING.len())],
                1 => b'a' + rng.below(26) as u8,
                _ => rng.next() as u8,
            })
            .collect();
        for options in [&CompileOptions::default(), &utf8] {
            let bytes = match round_trip(&value, options) {
                Token::String(bytes) | Token::Literal(bytes) => bytes,
                other => panic!("{other:?} for {value:?}"),
            };
            assert_eq!(bytes, value);
        }
    }
    // a base64 SASL response is a plain quoted string
    let token = round_trip(STANDARD.encode(b"\0user\0pass").as_bytes(), &CompileOptions::default());
    assert!(matches!(token, Token::String(_)));
}
