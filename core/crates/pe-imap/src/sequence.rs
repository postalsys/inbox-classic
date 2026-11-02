//! Sets of message numbers, `1:5,7,10:*`, and which numbers a command means: UIDs or sequence
//! numbers. Parsed once, so a set that reaches the wire is always valid and one that comes from
//! the server (COPYUID, VANISHED, ESEARCH) can be expanded and searched.

use std::fmt;

use crate::compiler::is_valid_sequence_set;
use crate::error::CompileError;

/// The most numbers a set may expand to
pub const EXPANDED_RANGE_LIMIT: u64 = 0x100_0000;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SequenceSet(String);

impl SequenceSet {
    /// A set in IMAP syntax, `1:5,7` or `1:*`
    pub fn parse(set: &str) -> Result<Self, CompileError> {
        if set != "$" && is_valid_sequence_set(set) {
            Ok(SequenceSet(set.to_string()))
        } else {
            Err(CompileError::new("InvalidSequenceSet", "Invalid sequence set value"))
        }
    }

    /// Every message, `1:*`
    pub fn all() -> Self {
        SequenceSet("1:*".into())
    }

    /// The numbers as ranges, `[1, 2, 3, 7]` gives `1:3,7`. None for an empty list.
    pub fn from_numbers(numbers: &[u64]) -> Option<Self> {
        let mut sorted = numbers.to_vec();
        sorted.sort_unstable();
        sorted.dedup();
        let mut ranges: Vec<(u64, u64)> = Vec::new();
        for n in sorted {
            match ranges.last_mut() {
                Some((_, end)) if *end + 1 == n => *end = n,
                _ => ranges.push((n, n)),
            }
        }
        let text: Vec<String> = ranges
            .iter()
            .map(|(a, b)| if a == b { a.to_string() } else { format!("{a}:{b}") })
            .collect();
        (!text.is_empty()).then(|| SequenceSet(text.join(",")))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }

    /// The ranges, `*` as `largest`
    fn ranges(&self, largest: u64) -> impl Iterator<Item = (u64, u64)> + '_ {
        let number = move |part: &str| {
            if part == "*" {
                largest
            } else {
                part.parse().unwrap_or(0)
            }
        };
        self.0.split(',').map(move |range| {
            let (first, last) = range.split_once(':').unwrap_or((range, range));
            let (first, last) = (number(first), number(last));
            (first.min(last), first.max(last))
        })
    }

    /// Whether `n` is in the set, `*` standing for `largest`
    pub fn contains(&self, n: u64, largest: u64) -> bool {
        self.ranges(largest).any(|(low, high)| (low..=high).contains(&n))
    }

    /// The numbers, `*` standing for `largest`. None past [`EXPANDED_RANGE_LIMIT`].
    pub fn expand(&self, largest: u64) -> Option<Vec<u64>> {
        let mut out = Vec::new();
        for (low, high) in self.ranges(largest) {
            if out.len() as u64 + (high - low) >= EXPANDED_RANGE_LIMIT {
                return None;
            }
            out.extend(low..=high);
        }
        Some(out)
    }
}

impl fmt::Display for SequenceSet {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

/// The messages a command acts on
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Messages {
    Uids(SequenceSet),
    Seqs(SequenceSet),
}

impl Messages {
    /// One message by UID
    pub fn uid(uid: u64) -> Self {
        Messages::Uids(SequenceSet(uid.to_string()))
    }

    pub fn set(&self) -> &SequenceSet {
        match self {
            Messages::Uids(set) | Messages::Seqs(set) => set,
        }
    }

    pub fn is_uid(&self) -> bool {
        matches!(self, Messages::Uids(_))
    }

    /// `FETCH` or `UID FETCH`
    pub(crate) fn command(&self, name: &str) -> String {
        if self.is_uid() {
            format!("UID {name}")
        } else {
            name.to_string()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_and_packs() {
        assert!(SequenceSet::parse("1:5,7,10:*").is_ok());
        for bad in ["", "1:", "a", "1 2", "$"] {
            assert!(SequenceSet::parse(bad).is_err(), "{bad}");
        }
        assert_eq!(
            SequenceSet::from_numbers(&[7, 1, 2, 3, 3, 9]).unwrap().as_str(),
            "1:3,7,9"
        );
        assert_eq!(SequenceSet::from_numbers(&[]), None);
    }

    #[test]
    fn contains_and_expands() {
        let set = SequenceSet::parse("1:3,7,10:*").unwrap();
        assert!(set.contains(2, 12) && set.contains(11, 12) && !set.contains(5, 12) && !set.contains(13, 12));
        assert_eq!(set.expand(11), Some(vec![1, 2, 3, 7, 10, 11]));
        assert_eq!(SequenceSet::parse("5:3").unwrap().expand(0), Some(vec![3, 4, 5]));
        assert_eq!(SequenceSet::parse("1:99999999999").unwrap().expand(0), None);
        assert_eq!(Messages::uid(5).command("FETCH"), "UID FETCH");
    }
}
