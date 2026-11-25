//! Hybrid logical clock stamps: every change made on any computer gets one, and every computer puts the same changes
//! in the same order by them, whatever its own clock says. A stamp is the wall time in milliseconds, a counter for
//! changes in the same millisecond (or after a stamp from a computer whose clock runs ahead), and the device that made
//! it, written as text that sorts in that order.

use std::sync::Mutex;

/// A change's place in time, comparable across computers
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Stamp {
    pub millis: u64,
    pub counter: u32,
    pub device: String,
}

impl Stamp {
    /// As stored and sent: fixed-width numbers first, so text order is time order
    pub fn text(&self) -> String {
        format!("{:015}-{:06}-{}", self.millis, self.counter, self.device)
    }

    /// Read back from [`Stamp::text`]; None for anything else
    pub fn parse(text: &str) -> Option<Stamp> {
        let mut parts = text.splitn(3, '-');
        let millis = parts.next()?;
        let counter = parts.next()?;
        let device = parts.next()?;
        if millis.len() != 15 || counter.len() != 6 || device.is_empty() {
            return None;
        }
        Some(Stamp {
            millis: millis.parse().ok()?,
            counter: counter.parse().ok()?,
            device: device.to_string(),
        })
    }
}

/// This computer's clock: never goes back, and moves past every stamp it has seen
#[derive(Debug)]
pub struct Clock {
    device: String,
    last: Mutex<(u64, u32)>,
}

impl Clock {
    pub fn new(device: &str) -> Clock {
        Clock {
            device: device.to_string(),
            last: Mutex::new((0, 0)),
        }
    }

    /// The stamp of a change made now, at the wall time `now` in milliseconds
    pub fn tick(&self, now: u64) -> Stamp {
        let mut last = self.last.lock().unwrap_or_else(|e| e.into_inner());
        *last = if now > last.0 { (now, 0) } else { (last.0, last.1 + 1) };
        Stamp {
            millis: last.0,
            counter: last.1,
            device: self.device.clone(),
        }
    }

    /// A stamp from another computer seen: the next one made here comes after it
    pub fn witness(&self, seen: &Stamp) {
        let mut last = self.last.lock().unwrap_or_else(|e| e.into_inner());
        if (seen.millis, seen.counter) > *last {
            *last = (seen.millis, seen.counter);
        }
    }
}

/// The wall clock in milliseconds since the Unix epoch
pub fn now_millis() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_or(0, |d| d.as_millis() as u64)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn stamps_order_by_time_then_counter_then_device_and_survive_a_slow_clock() {
        let mac = Clock::new("mac");
        let a = mac.tick(1000);
        let b = mac.tick(1000);
        let c = mac.tick(900);
        assert!(a < b && b < c, "never back, even when the wall clock is");
        assert_eq!((c.millis, c.counter), (1000, 2));
        // a stamp from a computer whose clock runs ahead: the next one here comes after it
        let ahead = Stamp {
            millis: 5000,
            counter: 3,
            device: "pc".into(),
        };
        mac.witness(&ahead);
        let d = mac.tick(1001);
        assert!(d > ahead && d.millis == 5000 && d.counter == 4);
        // text keeps the order, and reads back
        let texts: Vec<String> = [&a, &b, &c, &d].iter().map(|s| s.text()).collect();
        let mut sorted = texts.clone();
        sorted.sort();
        assert_eq!(texts, sorted);
        assert_eq!(Stamp::parse(&d.text()), Some(d.clone()));
        assert_eq!(Stamp::parse("nonsense"), None);
        // a device id with dashes reads back whole
        let dashed = Stamp {
            millis: 1,
            counter: 0,
            device: "a-b-c".into(),
        };
        assert_eq!(Stamp::parse(&dashed.text()), Some(dashed));
    }
}
