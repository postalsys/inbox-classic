//! A run: a target driven through the journeys and the walk, the checks after every step, and what a report needs:
//! every step, every failure with the steps before it, the health samples.

use std::path::PathBuf;
use std::time::Instant;

use crate::checks::{self, Failure, Shape, Truth};
use crate::health::Sample;
use crate::model::{Act, Seen, Target};
use crate::servers::Servers;
use crate::world::World;

/// A step done
#[derive(Debug, Clone)]
pub struct Step {
    pub number: u64,
    /// The journey it belongs to, or `walk`
    pub part: String,
    pub what: String,
    /// Seconds since the run began
    pub at: f64,
}

/// A failure, with where it happened
#[derive(Debug, Clone)]
pub struct Failed {
    pub step: u64,
    pub part: String,
    pub failure: Failure,
    /// What the window showed then
    pub seen: Option<Seen>,
    pub screenshot: Option<PathBuf>,
}

/// A journey's outcome
#[derive(Debug, Clone)]
pub struct JourneyResult {
    pub id: &'static str,
    pub name: &'static str,
    pub failures: usize,
    /// What it could not do on this target, a sentence each
    pub skipped: Vec<String>,
    pub seconds: f64,
}

pub struct Run<'a> {
    pub target: &'a mut dyn Target,
    pub servers: &'a Servers,
    pub world: &'a World,
    pub out: PathBuf,
    pub shape: Shape,
    pub part: String,
    pub steps: Vec<Step>,
    pub failed: Vec<Failed>,
    pub samples: Vec<Sample>,
    pub journeys: Vec<JourneyResult>,
    /// Steps not done for good: the run stops at this step (a replay)
    pub until: Option<u64>,
    began: Instant,
    shots: u32,
    /// The folders of the messages shown in the last steps (checks.rs `always`)
    reading: Vec<(String, String)>,
    /// The servers' folders as the last settled check read them, for the checks before quiet
    counted: Option<std::collections::HashMap<String, Vec<crate::servers::Counted>>>,
    checks: u64,
}

/// Why a run stopped before its end
#[derive(Debug)]
pub enum Stop {
    /// `--until` reached
    Until,
    /// The target failed to do a step or to settle: the run can not go on
    Broken(String),
}

impl<'a> Run<'a> {
    pub fn new(target: &'a mut dyn Target, servers: &'a Servers, world: &'a World, out: PathBuf) -> Run<'a> {
        Run {
            target,
            servers,
            world,
            out,
            shape: Shape::default(),
            part: String::new(),
            steps: Vec::new(),
            failed: Vec::new(),
            samples: Vec::new(),
            journeys: Vec::new(),
            until: None,
            began: Instant::now(),
            shots: 0,
            reading: Vec::new(),
            counted: None,
            checks: 0,
        }
    }

    pub fn step_number(&self) -> u64 {
        self.steps.len() as u64
    }

    fn log(&mut self, what: String) -> Result<(), Stop> {
        let number = self.step_number() + 1;
        if self.until.is_some_and(|until| number > until) {
            return Err(Stop::Until);
        }
        println!("{number:>6} {:<10} {what}", self.part);
        self.steps.push(Step {
            number,
            part: self.part.clone(),
            what,
            at: self.began.elapsed().as_secs_f64(),
        });
        Ok(())
    }

    /// One act of the user's
    pub fn act(&mut self, act: Act) -> Result<(), Stop> {
        self.log(act.describe())?;
        if let Act::Sort(by, ascending) = act {
            self.shape = Shape { sort: by, ascending };
        }
        self.target
            .act(&act)
            .map_err(|e| Stop::Broken(format!("{}: {e}", act.describe())))
    }

    /// Something another client or the server did, `what` for the log
    pub fn server(&mut self, what: String, f: impl FnOnce(&Servers)) -> Result<(), Stop> {
        self.log(format!("server: {what}"))?;
        f(self.servers);
        Ok(())
    }

    /// Waits until nothing is under way, then runs the checks that always hold; what the window shows
    pub fn settled(&mut self) -> Result<Seen, Stop> {
        self.target.settle().map_err(Stop::Broken)?;
        self.check(true)
    }

    /// The checks that always hold, on what the window shows now; `settled` when nothing is under way
    pub fn check(&mut self, settled: bool) -> Result<Seen, Stop> {
        let seen = self.target.observe().map_err(Stop::Broken)?;
        if let Some(shown) = &seen.shown {
            let place = (shown.account.clone(), shown.path.clone());
            self.reading.retain(|p| *p != place);
            self.reading.push(place);
            if self.reading.len() > 3 {
                self.reading.remove(0);
            }
        }
        // the servers asked only once things are quiet; before, their folders as read last
        let mut truth = match (settled, self.counted.take()) {
            (false, Some(counted)) => Truth::cached(self.servers, counted),
            _ => Truth::read(self.servers),
        };
        self.counted = Some(truth.counted_now());
        for failure in checks::always(&seen, &mut truth, self.shape, settled, &self.reading) {
            self.fail(failure, Some(seen.clone()));
        }
        // health every tenth check: it is judged by thirds of the run
        self.checks += 1;
        if self.checks % 10 == 1
            && let Some(mut sample) = self.target.health()
        {
            sample.step = self.step_number();
            sample.sessions = self.servers.accounts.iter().map(|a| a.sessions() as u64).sum();
            self.samples.push(sample);
        }
        Ok(seen)
    }

    /// A check of a journey's own
    pub fn expect(&mut self, ok: bool, what: impl Into<String>) {
        let what = what.into();
        if ok {
            println!("       ok  {what}");
        } else {
            let seen = self.target.observe().ok();
            self.fail(
                Failure {
                    check: "journey",
                    detail: what,
                },
                seen,
            );
        }
    }

    fn fail(&mut self, failure: Failure, seen: Option<Seen>) {
        println!("  FAILED  {}: {}", failure.check, failure.detail);
        // a picture of the first failures of a run, not of every one
        let screenshot = (self.shots < 10).then(|| {
            self.shots += 1;
            let path = self.out.join(format!("failure-{}.png", self.step_number()));
            self.target.screenshot(&path);
            path
        });
        self.failed.push(Failed {
            step: self.step_number(),
            part: self.part.clone(),
            failure,
            seen,
            screenshot: screenshot.filter(|p| p.exists()),
        });
    }

    pub fn elapsed(&self) -> f64 {
        self.began.elapsed().as_secs_f64()
    }
}
