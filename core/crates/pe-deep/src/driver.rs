//! An app as a target, through its driver: the app's UI test started in its deep mode, reading one request a line on
//! its standard input and answering with a line that starts with `DEEP ` and a JSON object on its standard output
//! (its other lines are its log, passed on). The requests:
//!
//! - `{"start": {"accounts": [{"name", "email", "imap", "smtp", "username", "password"}]}}`: the accounts added (as
//!   the test adds them: the core's call on the Mac and Linux, the form on Windows) and their first sync done;
//! - `{"act": ...}` (model.rs `Act`), done as the user's hand does it;
//! - `{"settle": seconds}`: answered once nothing is under way;
//! - `{"observe": true}`: answered with `{"seen": ...}` (model.rs `Seen`);
//! - `{"health": true}`: `{"memory_kib", "open_files", "store_bytes"}`, when it can tell;
//! - `{"screenshot": path}`, `{"quit": true}`.
//!
//! Every answer has `"ok"`; `false` with `"error"` when it could not, `"error": "unsupported"` for an act it can not
//! do. The app is started by the conductor with `--store`, `--memory-passwords` and `--pin-certificate` (ImapKit's
//! certificate), as the UI tests start it, and the driver's own option.

use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};
use std::process::{Child, ChildStdin, Command, Stdio};
use std::sync::mpsc::{Receiver, RecvTimeoutError, channel};
use std::time::Duration;

use serde_json::{Value, json};

use crate::model::{Act, Seen, Target, UNSUPPORTED};
use crate::servers::AccountServer;

pub struct DriverTarget {
    name: String,
    command: Vec<String>,
    dir: PathBuf,
    child: Option<Child>,
    stdin: Option<ChildStdin>,
    answers: Option<Receiver<Value>>,
    patience: Duration,
}

impl DriverTarget {
    /// `command`: the driver's program and its arguments (the conductor adds the store, the passwords and the
    /// certificate)
    pub fn new(name: &str, command: Vec<String>, dir: PathBuf) -> DriverTarget {
        DriverTarget {
            name: name.into(),
            command,
            dir,
            child: None,
            stdin: None,
            answers: None,
            patience: pe_testkit::patience() * 10,
        }
    }

    fn ask(&mut self, request: Value, wait: Duration) -> Result<Value, String> {
        let stdin = self.stdin.as_mut().ok_or("the driver is not running")?;
        writeln!(stdin, "{request}").map_err(|e| format!("the driver does not take requests: {e}"))?;
        stdin.flush().map_err(|e| e.to_string())?;
        let answers = self.answers.as_ref().ok_or("the driver is not running")?;
        let answer = match answers.recv_timeout(wait) {
            Ok(answer) => answer,
            Err(RecvTimeoutError::Timeout) => return Err(format!("no answer to {request} within {wait:?}")),
            Err(RecvTimeoutError::Disconnected) => return Err("the driver ended".into()),
        };
        if answer["ok"].as_bool() == Some(true) {
            Ok(answer)
        } else {
            Err(answer["error"].as_str().unwrap_or("the driver could not").to_string())
        }
    }

    fn launch(&mut self, accounts: &[AccountServer]) -> Result<(), String> {
        std::fs::create_dir_all(&self.dir).map_err(|e| e.to_string())?;
        let first = accounts.first().ok_or("no account")?;
        let pem = self.dir.join("imapkit.pem");
        write_pem(&first.kit.cert, &pem)?;
        let (program, args) = self.command.split_first().ok_or("no driver command")?;
        let mut child = Command::new(program)
            .args(args)
            .arg("--store")
            .arg(self.dir.join("store.db"))
            .arg("--memory-passwords")
            .arg("--pin-certificate")
            .arg(&pem)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::inherit())
            .spawn()
            .map_err(|e| format!("can not start {program}: {e}"))?;
        let stdout = child.stdout.take().ok_or("no stdout")?;
        let (sender, answers) = channel();
        let name = self.name.clone();
        std::thread::spawn(move || {
            for line in BufReader::new(stdout).lines().map_while(Result::ok) {
                match line.strip_prefix("DEEP ") {
                    Some(json) => {
                        let answer =
                            serde_json::from_str(json).unwrap_or_else(|_| json!({ "ok": false, "error": json }));
                        if sender.send(answer).is_err() {
                            break;
                        }
                    }
                    None => println!("       [{name}] {line}"),
                }
            }
        });
        self.stdin = child.stdin.take();
        self.child = Some(child);
        self.answers = Some(answers);
        Ok(())
    }
}

/// ImapKit's certificate in PEM, for the app's `--pin-certificate`
fn write_pem(cert: &[u8], path: &Path) -> Result<(), String> {
    use base64::Engine as _;
    let body = base64::engine::general_purpose::STANDARD.encode(cert);
    let lines: Vec<&str> = body
        .as_bytes()
        .chunks(64)
        .map(|c| std::str::from_utf8(c).unwrap_or_default())
        .collect();
    let pem = format!(
        "-----BEGIN CERTIFICATE-----\n{}\n-----END CERTIFICATE-----\n",
        lines.join("\n")
    );
    std::fs::write(path, pem).map_err(|e| e.to_string())
}

impl Target for DriverTarget {
    fn name(&self) -> &str {
        &self.name
    }

    fn start(&mut self, accounts: &[AccountServer]) -> Result<(), String> {
        self.launch(accounts)?;
        let list: Vec<Value> = accounts
            .iter()
            .map(|a| {
                json!({
                    "name": a.name, "email": a.email, "imap": a.kit.imap, "smtp": a.kit.smtp,
                    "username": pe_testkit::USER, "password": pe_testkit::PASSWORD,
                })
            })
            .collect();
        let patience = self.patience * 2;
        self.ask(json!({ "start": { "accounts": list } }), patience).map(|_| ())
    }

    fn act(&mut self, act: &Act) -> Result<(), String> {
        let patience = self.patience;
        match self.ask(act.to_json(), patience) {
            Err(e) if e == UNSUPPORTED => Err(UNSUPPORTED.into()),
            other => other.map(|_| ()),
        }
    }

    fn settle(&mut self) -> Result<(), String> {
        let seconds = self.patience.as_secs();
        self.ask(json!({ "settle": seconds }), self.patience + Duration::from_secs(30))
            .map(|_| ())
    }

    fn observe(&mut self) -> Result<Seen, String> {
        let patience = self.patience;
        let answer = self.ask(json!({ "observe": true }), patience)?;
        Seen::from_json(&answer["seen"]).ok_or_else(|| format!("the driver's answer is not what is seen: {answer}"))
    }

    fn health(&mut self) -> Option<crate::health::Sample> {
        let answer = self.ask(json!({ "health": true }), Duration::from_secs(30)).ok()?;
        let memory_kib = match self.child.as_ref() {
            Some(child) if answer["memory_kib"].as_u64().is_none() => crate::health::memory_kib(child.id()),
            _ => answer["memory_kib"].as_u64().unwrap_or(0),
        };
        Some(crate::health::Sample {
            memory_kib,
            open_files: answer["open_files"].as_u64().unwrap_or(0),
            store_bytes: crate::health::store_bytes(&self.dir.join("store.db")),
            ..Default::default()
        })
    }

    fn screenshot(&mut self, path: &Path) {
        let _ = self.ask(json!({ "screenshot": path }), Duration::from_secs(60));
    }
}

impl Drop for DriverTarget {
    fn drop(&mut self) {
        if self.stdin.is_some() {
            let _ = self.ask(json!({ "quit": true }), Duration::from_secs(20));
        }
        drop(self.stdin.take());
        if let Some(mut child) = self.child.take() {
            let _ = child.wait();
        }
    }
}
