//! The boundaries of the open multipart parts, indexed by value: a port of postal-mime's
//! boundary-stack.ts. A line is looked up instead of being compared with every open boundary in turn.
//! With a scan, a line sharing a long prefix with every boundary of a deeply nested message cost the
//! nesting depth times that prefix to reject (GHSA-q8wm-54mj-r36p); a lookup costs the length of the
//! line, whatever the depth.

use std::collections::HashMap;

use super::strings::is_wsp;

#[derive(Default)]
pub(super) struct Boundaries {
    /// The nodes open with each boundary, with their push order: the outermost first
    by_value: HashMap<Vec<u8>, Vec<(u64, usize)>>,
    by_node: HashMap<usize, Vec<u8>>,
    /// How many open boundaries have each length, so that a line no boundary can match is turned
    /// away before it is hashed
    lengths: HashMap<usize, usize>,
    next: u64,
}

impl Boundaries {
    /// Registers the boundary of a multipart node, ASCII and not ending in whitespace
    pub fn push(&mut self, value: &[u8], node: usize) {
        self.by_value.entry(value.to_vec()).or_default().push((self.next, node));
        self.next += 1;
        self.by_node.insert(node, value.to_vec());
        *self.lengths.entry(value.len()).or_default() += 1;
    }

    /// Removes the boundary of a node, if it registered one
    pub fn remove(&mut self, node: usize) {
        let Some(value) = self.by_node.remove(&node) else {
            return;
        };
        if let Some(list) = self.by_value.get_mut(&value) {
            list.retain(|(_, n)| *n != node);
            if list.is_empty() {
                self.by_value.remove(&value);
            }
        }
        if let Some(count) = self.lengths.get_mut(&value.len()) {
            *count -= 1;
            if *count == 0 {
                self.lengths.remove(&value.len());
            }
        }
    }

    /// The node whose boundary `line` delimits (false) or terminates (true): `--`, the boundary,
    /// optionally `--`, then optional whitespace (RFC 2046 5.1.1). When the line matches more than
    /// one open boundary, the outermost wins, as it does in every other parser.
    pub fn matching(&self, line: &[u8]) -> Option<(usize, bool)> {
        if self.by_node.is_empty() || line.len() <= 2 || !line.starts_with(b"--") {
            return None;
        }
        // a boundary does not end in whitespace, so trailing whitespace is never part of it
        let mut end = line.len();
        while end > 2 && is_wsp(line[end - 1]) {
            end -= 1;
        }
        let delimiter = self.find(&line[2..end]);
        let terminator = (end >= 4 && line[2..end].ends_with(b"--"))
            .then(|| self.find(&line[2..end - 2]))
            .flatten();
        match (delimiter, terminator) {
            (delimiter, Some(terminator)) if delimiter.is_none_or(|d| terminator.0 < d.0) => Some((terminator.1, true)),
            (Some(delimiter), _) => Some((delimiter.1, false)),
            _ => None,
        }
    }

    /// The outermost open boundary equal to `value`
    fn find(&self, value: &[u8]) -> Option<(u64, usize)> {
        if !self.lengths.contains_key(&value.len()) {
            return None;
        }
        self.by_value.get(value).and_then(|list| list.first().copied())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn delimiters_and_terminators() {
        let mut open = Boundaries::default();
        open.push(b"outer", 1);
        open.push(b"inner", 2);
        assert_eq!(open.matching(b"--outer"), Some((1, false)));
        assert_eq!(open.matching(b"--inner-- \t"), Some((2, true)));
        assert_eq!(open.matching(b"--inner x"), None);
        assert_eq!(open.matching(b"--"), None);
        assert_eq!(open.matching(b"-inner"), None);
        open.remove(2);
        assert_eq!(open.matching(b"--inner"), None);
        assert_eq!(open.matching(b"--outer--"), Some((1, true)));
    }

    /// A nested multipart reusing an ancestor's boundary, or one its terminator matches: the
    /// ancestor's delimiter is how every other parser reads the line
    #[test]
    fn the_outermost_wins() {
        let mut open = Boundaries::default();
        open.push(b"b", 1);
        open.push(b"b", 2);
        assert_eq!(open.matching(b"--b"), Some((1, false)));
        let mut open = Boundaries::default();
        open.push(b"b", 1);
        open.push(b"b--", 2);
        assert_eq!(open.matching(b"--b--"), Some((1, true)));
        let mut open = Boundaries::default();
        open.push(b"b--", 1);
        open.push(b"b", 2);
        assert_eq!(open.matching(b"--b--"), Some((1, false)));
    }
}
