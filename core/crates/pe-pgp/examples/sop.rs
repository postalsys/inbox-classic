//! The Stateless OpenPGP command line (draft-dkg-openpgp-stateless-cli) on pe-pgp, the subset needed to check
//! this implementation against others (`scripts/pgp-interop.sh`): version, generate-key, extract-cert, sign, verify,
//! encrypt, decrypt. Data comes on standard input and goes to standard output, keys and certificates are files.

use std::io::{Read, Write};
use std::process::ExitCode;

/// SOP's exit codes.
const NO_SIGNATURE: u8 = 3;
const UNSUPPORTED_OPTION: u8 = 37;
const MISSING_ARG: u8 = 19;
const CANNOT_DECRYPT: u8 = 29;
const BAD_DATA: u8 = 41;
const UNSUPPORTED_SUBCOMMAND: u8 = 69;

fn now() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

fn stdin() -> Vec<u8> {
    let mut data = Vec::new();
    std::io::stdin().read_to_end(&mut data).ok();
    data
}

fn out(bytes: &[u8]) {
    std::io::stdout().write_all(bytes).ok();
}

fn certs(files: &[String]) -> Result<Vec<pe_pgp::Cert>, u8> {
    let mut all = Vec::new();
    for file in files {
        let bytes = std::fs::read(file).map_err(|_| MISSING_ARG)?;
        all.extend(pe_pgp::read_certs(&bytes).map_err(|_| BAD_DATA)?);
    }
    Ok(all)
}

fn keys(files: &[String]) -> Result<Vec<pe_pgp::SecretKey>, u8> {
    let mut all = Vec::new();
    for file in files {
        let bytes = std::fs::read(file).map_err(|_| MISSING_ARG)?;
        all.extend(pe_pgp::read_secret_keys(&bytes, "").map_err(|_| BAD_DATA)?);
    }
    Ok(all)
}

/// A time as SOP writes it: `2026-11-15T10:00:00Z`.
fn iso(secs: i64) -> String {
    let days = secs.div_euclid(86_400);
    let rem = secs.rem_euclid(86_400);
    // civil from days, Howard Hinnant's algorithm
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let day = doy - (153 * mp + 2) / 5 + 1;
    let month = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = yoe + era * 400 + i64::from(month <= 2);
    format!(
        "{year:04}-{month:02}-{day:02}T{:02}:{:02}:{:02}Z",
        rem / 3600,
        rem % 3600 / 60,
        rem % 60
    )
}

fn verifications(checks: &[pe_pgp::SigCheck]) -> String {
    let mut lines = String::new();
    for check in checks.iter().filter(|check| check.is_good()) {
        let primary = check.cert.clone().unwrap_or_default();
        let signer = check.issuers.first().cloned().unwrap_or_else(|| primary.clone());
        let when = iso(check.created.unwrap_or(0));
        lines.push_str(&format!("{when} {signer} {primary} mode:binary\n"));
    }
    lines
}

fn run(args: &[String]) -> Result<(), u8> {
    let (command, rest) = args.split_first().ok_or(UNSUPPORTED_SUBCOMMAND)?;
    let mut options = Vec::new();
    let mut files = Vec::new();
    for arg in rest {
        if arg == "--" {
            continue;
        }
        if arg.starts_with("--") {
            options.push(arg.as_str())
        } else {
            files.push(arg.clone())
        }
    }
    let option = |name: &str| options.iter().find_map(|o| o.strip_prefix(name)).map(str::to_string);
    for o in &options {
        let known = [
            "--armor",
            "--as=binary",
            "--as=text",
            "--sign-with=",
            "--verify-with=",
            "--verifications-out=",
        ]
        .iter()
        .any(|k| o.starts_with(k));
        if !known {
            return Err(UNSUPPORTED_OPTION);
        }
    }
    match command.as_str() {
        "version" => out(b"pe-pgp-sop 0.1\n"),
        "generate-key" => {
            let (name, address) = match files.first().and_then(|uid| pe_pgp::address_of(uid)) {
                Some(address) => (files[0].split('<').next().unwrap_or("").trim().to_string(), address),
                None => return Err(BAD_DATA),
            };
            let key = pe_pgp::generate(&name, &[address], now()).map_err(|_| BAD_DATA)?;
            // SOP's keys are private keys without a passphrase, armored
            use pgp::composed::{Deserializable, SignedSecretKey};
            let bytes = key.to_bytes();
            let armored = SignedSecretKey::from_bytes(&bytes[..])
                .and_then(|key| key.to_armored_string(Default::default()))
                .map_err(|_| BAD_DATA)?;
            out(armored.as_bytes());
        }
        "extract-cert" => {
            let keys = pe_pgp::read_secret_keys(&stdin(), "").map_err(|_| BAD_DATA)?;
            for key in keys {
                out(key.cert().armored().as_bytes());
            }
        }
        "sign" => {
            let data = stdin();
            let keys = keys(&files)?;
            for key in keys {
                let signed = pe_pgp::sign_detached(&data, &key, now()).map_err(|_| BAD_DATA)?;
                out(signed.signature.as_bytes());
            }
        }
        "verify" => {
            let (signature, certs_files) = files.split_first().ok_or(MISSING_ARG)?;
            let signature = std::fs::read(signature).map_err(|_| MISSING_ARG)?;
            let certs = certs(certs_files)?;
            let checks = pe_pgp::verify_detached(&signature, &stdin(), &certs, now()).map_err(|_| BAD_DATA)?;
            let lines = verifications(&checks);
            if lines.is_empty() {
                return Err(NO_SIGNATURE);
            }
            out(lines.as_bytes());
        }
        "encrypt" => {
            let certs = certs(&files)?;
            let signer = match option("--sign-with=") {
                Some(file) => keys(&[file])?.into_iter().next(),
                None => None,
            };
            let refs: Vec<&pe_pgp::Cert> = certs.iter().collect();
            let message = pe_pgp::encrypt(stdin(), &refs, &[], signer.as_ref(), now()).map_err(|_| BAD_DATA)?;
            out(message.as_bytes());
        }
        "decrypt" => {
            let keys = keys(&files)?;
            let certs = match option("--verify-with=") {
                Some(file) => certs(&[file])?,
                None => Vec::new(),
            };
            let opened = pe_pgp::decrypt(&stdin(), &keys, &certs, now()).map_err(|_| CANNOT_DECRYPT)?;
            if let Some(file) = option("--verifications-out=") {
                std::fs::write(file, verifications(&opened.signatures)).map_err(|_| MISSING_ARG)?;
            }
            out(&opened.data);
        }
        _ => return Err(UNSUPPORTED_SUBCOMMAND),
    }
    Ok(())
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match run(&args) {
        Ok(()) => ExitCode::SUCCESS,
        Err(code) => ExitCode::from(code),
    }
}
