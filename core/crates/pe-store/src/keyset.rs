//! A row's place in a list from what it is sorted by, never from its number: the rows before it counted on the order's
//! index, the rows next to it found by walking that index from it. A list's order is a key (the date, the sender...)
//! and what breaks ties (the UID and row id of a message, the id of a conversation); NULL keys sort first, as SQLite
//! has them, so the rows beyond a place are up to three ranges of the index (those with its key, those past it, those
//! without one), each read on its own.

use rusqlite::params_from_iter;
use rusqlite::types::Value;

use crate::{Anchor, MessageRef, Result, Sort, SortField, Store};

/// A list's order as SQL: what it sorts by (with its collation), what breaks ties, and the direction
pub(crate) struct Order {
    pub key: String,
    pub ties: &'static [&'static str],
    pub ascending: bool,
}

/// Where a row is in an [`Order`]: its key and its ties
#[derive(Debug, Clone)]
pub(crate) struct Cursor {
    pub key: Value,
    pub ties: Vec<Value>,
}

impl Order {
    /// The order of a list of messages, one row each, as [`Sort::order_by`] has it
    pub fn messages(sort: Sort) -> Order {
        Order {
            key: crate::messages::sort_key(sort.field),
            // the id last: the same UID in two folders has one order across folders too (an index ends with the
            // rowid, so the indexes still serve the order)
            ties: &["uid", "id"],
            ascending: sort.ascending,
        }
    }

    /// The order of a grouped list's conversations (the columns of `g`, see threads.rs), as `group_order` has it
    pub fn conversations(sort: Sort) -> Order {
        let key = match sort.field {
            SortField::Date => "newest",
            SortField::Received => "newest_received",
            SortField::Size => "k",
            _ => "k COLLATE NOCASE",
        };
        Order {
            key: key.to_string(),
            ties: &["t"],
            ascending: sort.ascending,
        }
    }

    /// What the rows are read in, walking away from a place: down the list (`after`) or up it
    pub fn walking(&self, after: bool) -> String {
        let direction = if after == self.ascending { "ASC" } else { "DESC" };
        let mut terms = vec![format!("{} {direction}", self.key)];
        terms.extend(self.ties.iter().map(|tie| format!("{tie} {direction}")));
        terms.join(", ")
    }

    /// The rows beyond `place` (below it in the list with `after`, above it otherwise) as conditions, in the order
    /// they are met walking from it, each one range of the order's index, with its values after those of `base`
    pub fn beyond(&self, place: &Cursor, after: bool, base: &[Value]) -> Vec<(String, Vec<Value>)> {
        let key = &self.key;
        // towards greater keys, or smaller ones
        let up = after == self.ascending;
        let than = if up { ">" } else { "<" };
        let mut values = base.to_vec();
        let mut add = |value: &Value| {
            values.push(value.clone());
            format!("?{}", values.len())
        };
        let at = add(&place.key);
        let ties: Vec<String> = place.ties.iter().map(&mut add).collect();
        let mut pieces = vec![(
            format!(
                "{key} IS {at} AND ({}) {than} ({})",
                self.ties.join(", "),
                ties.join(", ")
            ),
            values,
        )];
        let mut keyed = base.to_vec();
        keyed.push(place.key.clone());
        let at = format!("?{}", keyed.len());
        match (up, place.key == Value::Null) {
            (true, true) => pieces.push((format!("{key} IS NOT NULL"), base.to_vec())),
            (true, false) => pieces.push((format!("{key} > {at}"), keyed)),
            (false, true) => {}
            (false, false) => {
                pieces.push((format!("{key} < {at}"), keyed));
                pieces.push((format!("{key} IS NULL"), base.to_vec()));
            }
        }
        pieces
    }
}

/// How a page read from an [`Anchor`] walks the list ([`Store::walk`]): from which row (none: from the end, up),
/// which way, how many rows it skips and how many it reads
pub(crate) struct Walk {
    pub cursor: Option<Cursor>,
    pub after: bool,
    pub skip: u64,
    pub limit: u64,
}

impl Walk {
    /// To the nearest row beyond `cursor`: below it with `after`, above it otherwise
    pub fn next(cursor: Cursor, after: bool) -> Walk {
        Walk {
            cursor: Some(cursor),
            after,
            skip: 0,
            limit: 1,
        }
    }

    /// The walk to the page of `limit` rows at `offset` from `anchor`, `place` finding where an anchor's row is; None
    /// when that row is not in the list (the page is then counted from the top)
    pub fn from(
        anchor: Anchor,
        offset: u64,
        limit: u64,
        place: impl Fn(MessageRef) -> Result<Option<Cursor>>,
    ) -> Result<Option<Walk>> {
        let (at, after) = match anchor {
            Anchor::Above(at) => (at, true),
            Anchor::Below(at) => (at, false),
            Anchor::End(rows) => {
                let end = offset.saturating_add(limit).min(rows);
                return Ok(Some(Walk {
                    cursor: None,
                    after: false,
                    skip: rows - end,
                    limit: end.saturating_sub(offset),
                }));
            }
        };
        Ok(place(at)?.map(|cursor| Walk {
            cursor: Some(cursor),
            after,
            skip: 0,
            limit,
        }))
    }
}

/// The rows of a list as SQL to read them from: `FROM` and `WHERE` of its own (the messages a search finds, or `g`
/// of a grouped list with the `WITH` before it), with the values of both
pub(crate) struct Rows {
    pub with: String,
    pub from: String,
    pub condition: String,
    pub values: Vec<Value>,
}

impl Rows {
    /// How many of them `piece` holds for, as SQL
    fn count_sql(&self, piece: &str) -> String {
        format!(
            "{} SELECT COUNT(*) FROM {} WHERE {} AND {piece}",
            self.with, self.from, self.condition
        )
    }
}

impl Store {
    /// How many rows of `rows` are above `place` in `order`: each range counted on the index
    pub(crate) fn count_before(&self, rows: &Rows, order: &Order, place: &Cursor) -> Result<u64> {
        let mut count = 0;
        for (piece, values) in order.beyond(place, false, &rows.values) {
            count += self
                .db
                .prepare_cached(&rows.count_sql(&piece))?
                .query_row(params_from_iter(values), |row| row.get::<_, u64>(0))?;
        }
        Ok(count)
    }

    /// The rows of `rows` that `walk` reaches ([`Walk`]), read with `read` from the columns `columns`, in the list's
    /// order: a page read from a row next to it, never counted from the top
    pub(crate) fn walk<T>(
        &self,
        rows: &Rows,
        order: &Order,
        walk: &Walk,
        columns: &str,
        read: impl Fn(&rusqlite::Row) -> rusqlite::Result<T>,
    ) -> Result<Vec<T>> {
        let Walk {
            ref cursor,
            after,
            mut skip,
            limit,
        } = *walk;
        let pieces = match cursor {
            Some(cursor) => order.beyond(cursor, after, &rows.values),
            None => vec![("1".to_string(), rows.values.clone())],
        };
        let mut found = Vec::new();
        for (piece, mut values) in pieces {
            let wanted = limit.saturating_sub(found.len() as u64);
            if wanted == 0 {
                break;
            }
            let counted = values.clone();
            values.push(Value::Integer(wanted as i64));
            values.push(Value::Integer(skip as i64));
            let got: Vec<T> = self
                .db
                .prepare_cached(&format!(
                    "{} SELECT {columns} FROM {} WHERE {} AND {piece} ORDER BY {} LIMIT ?{} OFFSET ?{}",
                    rows.with,
                    rows.from,
                    rows.condition,
                    order.walking(after),
                    values.len() - 1,
                    values.len()
                ))?
                .query_map(params_from_iter(values), &read)?
                .collect::<Result<_>>()?;
            if got.is_empty() && skip > 0 {
                // all of this range skipped: the rest from the next
                let count: u64 = self
                    .db
                    .prepare_cached(&rows.count_sql(&piece))?
                    .query_row(params_from_iter(counted), |row| row.get(0))?;
                skip -= count.min(skip);
            } else {
                skip = 0;
            }
            found.extend(got);
        }
        if !after {
            found.reverse();
        }
        Ok(found)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Every key, a NULL one too, and ties: the pieces beyond each place are exactly the rows past it, in order
    #[test]
    fn the_pieces_beyond_a_place_are_the_rows_past_it() {
        let db = rusqlite::Connection::open_in_memory().unwrap();
        db.execute_batch(
            "CREATE TABLE r (k INTEGER, u INTEGER, i INTEGER); \
             INSERT INTO r VALUES (NULL, 1, 1), (NULL, 2, 2), (5, 1, 3), (5, 2, 4), (7, 1, 5), (9, 3, 6), (9, 3, 7);",
        )
        .unwrap();
        for ascending in [true, false] {
            let order = Order {
                key: "k".into(),
                ties: &["u", "i"],
                ascending,
            };
            let all: Vec<(Option<i64>, i64, i64)> = db
                .prepare(&format!("SELECT k, u, i FROM r ORDER BY {}", order.walking(true)))
                .unwrap()
                .query_map([], |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)))
                .unwrap()
                .map(Result::unwrap)
                .collect();
            for (at, &(k, u, i)) in all.iter().enumerate() {
                let place = Cursor {
                    key: k.map_or(Value::Null, Value::Integer),
                    ties: vec![Value::Integer(u), Value::Integer(i)],
                };
                for after in [true, false] {
                    let mut walked = Vec::new();
                    for (piece, values) in order.beyond(&place, after, &[]) {
                        let sql = format!("SELECT i FROM r WHERE {piece} ORDER BY {}", order.walking(after));
                        let ids: Vec<i64> = db
                            .prepare(&sql)
                            .unwrap()
                            .query_map(params_from_iter(&values), |row| row.get(0))
                            .unwrap()
                            .map(Result::unwrap)
                            .collect();
                        walked.extend(ids);
                    }
                    let expected: Vec<i64> = if after {
                        all[at + 1..].iter().map(|r| r.2).collect()
                    } else {
                        all[..at].iter().rev().map(|r| r.2).collect()
                    };
                    assert_eq!(walked, expected, "ascending {ascending}, row {at}, after {after}");
                }
            }
        }
    }
}
