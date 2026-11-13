//! How long opening messages takes, and where the time goes: one record for each message opened, the last
//! [`KEPT`] in memory. An open slower than [`SLOW`] is written to the standard error (times, sizes and the server's
//! host only, never what is in the message).

use std::collections::VecDeque;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use pe_store::FolderId;

/// How many opens are kept
pub const KEPT: usize = 200;
/// An open slower than this is written to the standard error
pub const SLOW: Duration = Duration::from_secs(1);

/// Which connection brought the message
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Served {
    /// It was in the store: no connection used
    Store,
    /// The account's reader
    Reader,
    /// The main worker, when the reader could not connect
    Main,
}

/// The state of the connection that brought it
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Link {
    /// None was needed
    None,
    /// One already open
    Reused,
    /// Made for this open
    New,
    /// The one open failed, and a new one was made
    Retried,
}

/// One message opened. The times are from when the window asked for it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OpenTiming {
    pub folder: FolderId,
    pub uid: u64,
    /// The size of the source, 0 when it could not be had
    pub size: u64,
    pub served: Served,
    pub link: Link,
    /// The server's host, empty when it was in the store
    pub host: String,
    /// When the reader took the request
    pub started: Duration,
    /// Connected and signed in
    pub connected: Option<Duration>,
    /// The folder selected
    pub selected: Option<Duration>,
    /// The first line of the server's answer to the FETCH
    pub first_byte: Option<Duration>,
    /// The whole message here
    pub last_byte: Option<Duration>,
    /// The window told ([`crate::Event::MessageReady`])
    pub ready: Option<Duration>,
    /// The view built, when the window asked for one
    pub view_built: Option<Duration>,
    /// Whether it failed
    pub failed: bool,
}

impl OpenTiming {
    /// The time until the window was told, or until it failed
    pub fn total(&self) -> Option<Duration> {
        self.ready.or(self.last_byte).or(self.first_byte)
    }

    /// One line for the standard error
    fn line(&self) -> String {
        let ms = |d: Option<Duration>| d.map_or_else(|| "-".to_string(), |d| d.as_millis().to_string());
        format!(
            "open {}:{} {} bytes served={:?} link={:?} host={} started={} connected={} selected={} first_byte={} \
             last_byte={} ready={} failed={}",
            self.folder,
            self.uid,
            self.size,
            self.served,
            self.link,
            self.host,
            self.started.as_millis(),
            ms(self.connected),
            ms(self.selected),
            ms(self.first_byte),
            ms(self.last_byte),
            ms(self.ready),
            self.failed
        )
    }
}

/// The records, shared by the core and its readers
#[derive(Clone, Default)]
pub(crate) struct Timings(Arc<Mutex<VecDeque<(Instant, OpenTiming)>>>);

impl Timings {
    fn lock(&self) -> std::sync::MutexGuard<'_, VecDeque<(Instant, OpenTiming)>> {
        self.0.lock().unwrap_or_else(|p| p.into_inner())
    }

    /// The record of an open that is over
    pub(crate) fn add(&self, clock: &Clock) {
        let (asked, timing) = (clock.asked, clock.timing.clone());
        if timing.failed || timing.total().is_some_and(|total| total > SLOW) {
            eprintln!("{}", timing.line());
        }
        let mut kept = self.lock();
        if kept.len() == KEPT {
            kept.pop_front();
        }
        kept.push_back((asked, timing));
    }

    /// The view of the message opened last as `folder`/`uid` is built, at `at`
    pub(crate) fn view_built(&self, folder: FolderId, uid: u64, at: Instant) {
        let mut kept = self.lock();
        if let Some((asked, timing)) = kept
            .iter_mut()
            .rev()
            .find(|(_, t)| t.folder == folder && t.uid == uid && t.view_built.is_none())
        {
            timing.view_built = Some(at.saturating_duration_since(*asked));
        }
    }

    pub(crate) fn all(&self) -> Vec<OpenTiming> {
        self.lock().iter().map(|(_, timing)| timing.clone()).collect()
    }
}

/// The record of one open while it is under way
pub(crate) struct Clock {
    asked: Instant,
    pub(crate) timing: OpenTiming,
}

impl Clock {
    pub(crate) fn start(folder: FolderId, uid: u64, asked: Instant) -> Clock {
        Clock {
            asked,
            timing: OpenTiming {
                folder,
                uid,
                size: 0,
                served: Served::Store,
                link: Link::None,
                host: String::new(),
                started: asked.elapsed(),
                connected: None,
                selected: None,
                first_byte: None,
                last_byte: None,
                ready: None,
                view_built: None,
                failed: false,
            },
        }
    }

    /// The time since the window asked
    pub(crate) fn now(&self) -> Duration {
        self.asked.elapsed()
    }

    /// The time since the window asked, until `at`
    pub(crate) fn at(&self, at: Instant) -> Duration {
        at.saturating_duration_since(self.asked)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn clock(uid: u64, ready: u64, asked: Instant) -> Clock {
        let mut clock = Clock::start(1, uid, asked);
        clock.timing.ready = Some(Duration::from_millis(ready));
        clock
    }

    #[test]
    fn keeps_the_last_opens() {
        let timings = Timings::default();
        for uid in 0..(KEPT as u64 + 5) {
            timings.add(&clock(uid, 1, Instant::now()));
        }
        let all = timings.all();
        assert_eq!(all.len(), KEPT);
        assert_eq!(all[0].uid, 5);
    }

    #[test]
    fn the_view_is_timed_on_the_last_open_of_the_message() {
        let timings = Timings::default();
        let asked = Instant::now();
        timings.add(&clock(7, 1, asked));
        timings.add(&clock(7, 2, asked));
        timings.view_built(1, 7, asked + Duration::from_millis(40));
        let all = timings.all();
        assert_eq!(all[0].view_built, None);
        assert_eq!(all[1].view_built, Some(Duration::from_millis(40)));
    }

    #[test]
    fn the_line_has_no_content() {
        let mut t = clock(3, 1500, Instant::now()).timing;
        t.host = "imap.example.com".into();
        let line = t.line();
        assert!(line.starts_with("open 1:3 0 bytes served=Store"), "{line}");
        assert!(line.contains("ready=1500"), "{line}");
    }
}
