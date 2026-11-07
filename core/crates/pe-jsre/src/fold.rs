//! Case folding of the `i` flag without `u`, as ECMAScript defines it (Canonicalize, 22.2.2.7.3).
//!
//! A character is matched through its canonical form: its uppercase when that is one UTF-16 code
//! unit, unless that would take a character outside ASCII into ASCII. So `ä` matches `Ä` and `σ`
//! matches `ς`, but the Kelvin sign does not match `k`, `ſ` does not match `s` and `ß` does not
//! match `ẞ`, which Rust's `(?i)` (Unicode simple case folding) would all match. Characters
//! outside the Basic Multilingual Plane are two code units to JavaScript without `u`, and
//! surrogates have no case, so they only ever match themselves.

use std::collections::HashMap;
use std::sync::LazyLock;

/// Canonicalize(ch) for a pattern without the `u` and `v` flags.
pub fn canonicalize(c: char) -> char {
    if c as u32 > 0xFFFF {
        return c;
    }
    let mut upper = c.to_uppercase();
    let (Some(u), None) = (upper.next(), upper.next()) else {
        return c;
    };
    if u as u32 > 0xFFFF || (c as u32 >= 128 && (u as u32) < 128) {
        return c;
    }
    u
}

struct Table {
    /// Every character whose canonical form it shares with another character, sorted.
    members: Vec<char>,
    /// The characters of each canonical form that more than one character has.
    groups: HashMap<char, Vec<char>>,
}

static TABLE: LazyLock<Table> = LazyLock::new(|| {
    let mut groups: HashMap<char, Vec<char>> = HashMap::new();
    for c in (0..=0xFFFF).filter_map(char::from_u32) {
        groups.entry(canonicalize(c)).or_default().push(c);
    }
    groups.retain(|_, group| group.len() > 1);
    let mut members: Vec<char> = groups.values().flatten().copied().collect();
    members.sort_unstable();
    Table { members, groups }
});

/// The characters `c` matches under the `i` flag, itself included; `None` when only itself.
pub fn equivalents(c: char) -> Option<&'static [char]> {
    TABLE.groups.get(&canonicalize(c)).map(Vec::as_slice)
}

/// Add what the characters of `low..=high` match under the `i` flag to `out`.
pub(crate) fn range_equivalents(low: char, high: char, out: &mut Vec<char>) {
    let members = &TABLE.members;
    let start = members.partition_point(|&m| m < low);
    let end = members.partition_point(|&m| m <= high);
    for &m in &members[start..end] {
        if let Some(group) = equivalents(m) {
            out.extend(group.iter().filter(|&&e| e < low || e > high));
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn canonical_forms() {
        assert_eq!(canonicalize('a'), 'A');
        assert_eq!(canonicalize('ä'), 'Ä');
        assert_eq!(canonicalize('ς'), 'Σ');
        // Into ASCII from outside it: kept.
        assert_eq!(canonicalize('ſ'), 'ſ');
        assert_eq!(canonicalize('ı'), 'ı');
        // Several characters as uppercase: kept.
        assert_eq!(canonicalize('ß'), 'ß');
        // Outside the BMP: kept.
        assert_eq!(canonicalize('\u{10428}'), '\u{10428}');
    }

    #[test]
    fn groups() {
        assert_eq!(equivalents('k').map(<[char]>::to_vec), Some(vec!['K', 'k']));
        assert_eq!(equivalents('\u{212A}'), None);
        let mut sigma = equivalents('σ').unwrap().to_vec();
        sigma.sort_unstable();
        assert_eq!(sigma, vec!['Σ', 'ς', 'σ']);
        let mut out = Vec::new();
        range_equivalents('a', 'c', &mut out);
        out.sort_unstable();
        assert_eq!(out, vec!['A', 'B', 'C']);
    }
}
