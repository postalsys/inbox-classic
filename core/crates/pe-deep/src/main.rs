//! The deep test's conductor (docs/deep-test-plan.md): makes the world, starts its servers, drives a target (the core
//! without a window, or an app through its driver) through the journeys and the walk with the checks after every
//! step, and writes the report. `scripts/deep-test.sh` runs it for each platform.
//!
//! ```text
//! pe-deep run [--profile small|standard|overnight] [--seed N] [--steps N] [--until N] [--journeys D2,D4|all|none]
//!             [--out DIR] [--worlds DIR] [--shrink] [--corpus DIR] [--target NAME --driver PROGRAM ARGS...]
//!
//! `--corpus DIR` fills the world with real messages from a folder of `.eml` files, for runs on this computer only:
//! the world made from them stays under build/ (never committed), and CI never names one.
//! pe-deep world [--profile P] [--worlds DIR]       the world's storage files written, its digest printed
//! ```

use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

use pe_deep::core_target::CoreTarget;
use pe_deep::driver::DriverTarget;
use pe_deep::model::Target;
use pe_deep::run::{Run, Stop};
use pe_deep::servers::Servers;
use pe_deep::world::{Profile, World};
use pe_deep::{journeys, report, walk};

/// The world is the same from run to run (its storage made once and kept); the walk's seed changes
const WORLD_SEED: u64 = 1;

struct Options {
    profile: Profile,
    seed: Option<u64>,
    steps: Option<u64>,
    until: Option<u64>,
    journeys: Vec<String>,
    walk: bool,
    out: PathBuf,
    worlds: PathBuf,
    shrink: bool,
    target: String,
    driver: Vec<String>,
    /// A folder of real `.eml` files the world's mail comes from: this computer's runs only, never CI's
    corpus: Option<PathBuf>,
}

fn usage(why: &str) -> ! {
    eprintln!("{why}\nsee the top of core/crates/pe-deep/src/main.rs");
    std::process::exit(2)
}

fn parse(args: &[String]) -> Options {
    let mut o = Options {
        profile: Profile::Standard,
        seed: None,
        steps: None,
        until: None,
        journeys: Vec::new(),
        walk: true,
        out: PathBuf::from("build/deep/core"),
        worlds: PathBuf::from("build/deep"),
        shrink: false,
        target: "core".into(),
        driver: Vec::new(),
        corpus: None,
    };
    let mut at = 0;
    let value = |at: &mut usize| -> String {
        *at += 1;
        args.get(*at)
            .cloned()
            .unwrap_or_else(|| usage("an option without its value"))
    };
    let number = |text: String| {
        text.parse::<u64>()
            .unwrap_or_else(|_| usage(&format!("not a number: {text}")))
    };
    while at < args.len() {
        match args[at].as_str() {
            "--profile" => {
                o.profile =
                    Profile::parse(&value(&mut at)).unwrap_or_else(|| usage("profile: small, standard, overnight"))
            }
            "--seed" => o.seed = Some(number(value(&mut at))),
            "--steps" => o.steps = Some(number(value(&mut at))),
            "--until" => o.until = Some(number(value(&mut at))),
            "--journeys" => {
                let list = value(&mut at);
                match list.as_str() {
                    "all" => o.journeys.clear(),
                    "none" => o.journeys = vec!["none".into()],
                    _ => o.journeys = list.split(',').map(str::to_string).collect(),
                }
            }
            "--no-walk" => o.walk = false,
            "--out" => o.out = PathBuf::from(value(&mut at)),
            "--worlds" => o.worlds = PathBuf::from(value(&mut at)),
            "--shrink" => o.shrink = true,
            "--target" => o.target = value(&mut at),
            "--corpus" => o.corpus = Some(PathBuf::from(value(&mut at))),
            "--driver" => {
                o.driver = args[at + 1..].to_vec();
                break;
            }
            other => usage(&format!("unknown option {other}")),
        }
        at += 1;
    }
    if o.target != "core" && o.driver.is_empty() {
        usage("a target other than core needs --driver");
    }
    o
}

/// The seeds that once failed, run again before a new one (seeds.txt next to this crate)
fn kept_seeds() -> Vec<u64> {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("seeds.txt");
    std::fs::read_to_string(path)
        .unwrap_or_default()
        .lines()
        .filter_map(|l| l.split('#').next()?.trim().parse().ok())
        .collect()
}

fn commit() -> String {
    std::process::Command::new("git")
        .args(["rev-parse", "HEAD"])
        .output()
        .ok()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default()
}

/// The outcome of one run
struct Outcome {
    passed: bool,
    /// The step of the first failure
    first_failure: Option<u64>,
}

/// One run from a fresh start: servers from the world's storage, a new target, the journeys and the walk
fn run_once(o: &Options, world: &World, storages: &[PathBuf], seed: u64, until: Option<u64>, out: PathBuf) -> Outcome {
    let _ = std::fs::remove_dir_all(&out);
    std::fs::create_dir_all(&out).unwrap_or_else(|e| usage(&format!("can not make {}: {e}", out.display())));
    let Some(servers) = Servers::start(world, storages) else {
        usage("ImapKit could not start: run npm ci in core/e2e");
    };
    let mut target: Box<dyn Target> = if o.target == "core" {
        Box::new(CoreTarget::new(out.join("app")))
    } else {
        Box::new(DriverTarget::new(&o.target, o.driver.clone(), out.join("app")))
    };
    println!(
        "== {}: starting with {} messages in {} accounts",
        o.target,
        world.total(),
        world.accounts.len()
    );
    let mut stopped = None;
    if let Err(why) = target.start(&servers.accounts) {
        stopped = Some(format!("the target did not start: {why}"));
    }
    let mut run = Run::new(target.as_mut(), &servers, world, out.clone());
    run.until = until;
    if stopped.is_none() {
        let steps = o.steps.unwrap_or(world.profile.steps());
        let mut outcome = Ok(());
        if o.journeys != ["none"] {
            outcome = journeys::run_all(&mut run, &o.journeys);
        }
        if outcome.is_ok() && o.walk {
            outcome = walk::walk(&mut run, seed, steps);
            // the seeds that failed before, a shorter walk each, on the same servers
            for kept in kept_seeds().into_iter().filter(|k| *k != seed) {
                if outcome.is_err() {
                    break;
                }
                println!("== the walk of seed {kept}, which once failed");
                outcome = walk::walk(&mut run, kept, (steps / 4).max(50));
            }
        }
        stopped = match outcome {
            Ok(()) | Err(Stop::Until) => None,
            Err(Stop::Broken(why)) => Some(why),
        };
    }
    let health = pe_deep::health::judge(&run.samples);
    let passed = run.failed.is_empty() && stopped.is_none() && health.is_empty();
    let first_failure = run
        .failed
        .first()
        .map(|f| f.step)
        .or(stopped.is_some().then(|| run.step_number()));
    let _ = report::write(&run, passed, stopped.as_deref(), &health, &out.join("report.html"));
    let result = report::result_json(&run, passed, stopped.as_deref(), &commit());
    let _ = std::fs::write(
        out.join("result.json"),
        serde_json::to_string_pretty(&result).unwrap_or_default(),
    );
    println!(
        "== {}: {} after {} steps, {} failures{}; the report is {}",
        o.target,
        if passed { "passed" } else { "FAILED" },
        run.step_number(),
        run.failed.len(),
        stopped.map(|s| format!(", stopped: {s}")).unwrap_or_default(),
        out.join("report.html").display()
    );
    Outcome { passed, first_failure }
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let (command, rest) = args.split_first().unwrap_or_else(|| usage("pe-deep run | world"));
    let o = parse(rest);
    let corpus = o.corpus.as_ref().map(|dir| {
        pe_deep::world::Corpus::open(dir).unwrap_or_else(|e| usage(&format!("the corpus {}: {e}", dir.display())))
    });
    let world = World::generate_from(WORLD_SEED, o.profile, corpus);
    let dir = world.dir(&o.worlds);
    let storages = world
        .write(&dir)
        .unwrap_or_else(|e| usage(&format!("can not write the world to {}: {e}", dir.display())));
    println!(
        "== world {} of {} messages in {}",
        world.digest(),
        world.total(),
        dir.display()
    );
    if command == "world" {
        return;
    }
    if command != "run" {
        usage("pe-deep run | world");
    }
    let seed = o.seed.unwrap_or_else(|| {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map_or(1, |d| d.as_secs() % 1_000_000)
    });
    println!("== the walk's seed is {seed}");
    let outcome = run_once(&o, &world, &storages, seed, o.until, o.out.clone());
    if outcome.passed {
        return;
    }
    // the smallest run that still fails: shorter prefixes of the same seed, a few at most
    if o.shrink
        && let Some(mut failing) = outcome.first_failure
    {
        let mut shortest = failing;
        for attempt in 0..4 {
            let until = failing / 2;
            if until < 5 {
                break;
            }
            println!("== shrinking: the first {until} steps of seed {seed}");
            let tried = run_once(
                &o,
                &world,
                &storages,
                seed,
                Some(until),
                o.out.join(format!("shrink-{attempt}")),
            );
            match tried.first_failure {
                Some(step) if !tried.passed => {
                    shortest = step;
                    failing = step;
                }
                _ => break,
            }
        }
        println!("== the shortest run found that fails: seed {seed} --until {shortest}");
    }
    if o.seed.is_none() {
        println!("== a new seed failed: add {seed} to core/crates/pe-deep/seeds.txt");
    }
    std::process::exit(1);
}
