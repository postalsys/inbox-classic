//! The message list's selection: the rows selected as ranges of row numbers, as the Windows app's virtual list keeps
//! them, never an object a row. GTK's own GtkMultiSelection reads and keeps every selected row's object, so Select All
//! of a folder of 200,000 messages read 200,000 rows on the window thread and every reload of the list walked them
//! again; here Select All is one range.

use std::cell::RefCell;

use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gio, glib};

use crate::messages::{MessageModel, MessageRow};

/// Row numbers as ranges, start included and end not, ascending, apart and never empty
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Ranges(Vec<(u32, u32)>);

impl Ranges {
    /// The ranges as they are
    pub fn spans(&self) -> &[(u32, u32)] {
        &self.0
    }

    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }

    /// How many rows
    pub fn size(&self) -> u64 {
        self.0.iter().map(|(start, end)| u64::from(end - start)).sum()
    }

    pub fn first(&self) -> Option<u32> {
        self.0.first().map(|(start, _)| *start)
    }

    pub fn last(&self) -> Option<u32> {
        self.0.last().map(|(_, end)| end - 1)
    }

    pub fn contains(&self, row: u32) -> bool {
        // the last range starting at or before the row is the only one that can hold it
        let before = self.0.partition_point(|(start, _)| *start <= row);
        before > 0 && row < self.0[before - 1].1
    }

    /// The rows `start` to `end` added
    pub fn add(&mut self, start: u32, end: u32) {
        if start >= end {
            return;
        }
        // those touching or overlapping it merged with it
        let from = self.0.partition_point(|(_, e)| *e < start);
        let to = self.0.partition_point(|(s, _)| *s <= end);
        let (mut start, mut end) = (start, end);
        if from < to {
            start = start.min(self.0[from].0);
            end = end.max(self.0[to - 1].1);
        }
        self.0.splice(from..to, [(start, end)]);
    }

    /// The rows `start` to `end` taken out
    pub fn remove(&mut self, start: u32, end: u32) {
        if start >= end {
            return;
        }
        let from = self.0.partition_point(|(_, e)| *e <= start);
        let to = self.0.partition_point(|(s, _)| *s < end);
        if from >= to {
            return;
        }
        let mut kept = Vec::with_capacity(2);
        let (first, last) = (self.0[from], self.0[to - 1]);
        if first.0 < start {
            kept.push((first.0, start));
        }
        if last.1 > end {
            kept.push((end, last.1));
        }
        self.0.splice(from..to, kept);
    }

    /// The rows of the list after `removed` rows at `position` gave way to `added` others: those removed are no
    /// longer selected, those after them move; rows changed in place (as many added as removed) stay selected
    pub fn splice(&mut self, position: u32, removed: u32, added: u32) {
        if removed == added {
            return;
        }
        self.remove(position, position.saturating_add(removed));
        // what is left at or past the removed rows is past them now, so it moves by the rows added less those removed
        let shift = |row: u32| (row - removed).saturating_add(added);
        let mut moved = Vec::with_capacity(self.0.len() + 1);
        for &(start, end) in &self.0 {
            if end <= position {
                moved.push((start, end));
                continue;
            }
            // a range the new rows fall into is split around them
            if start < position {
                moved.push((start, position));
            }
            moved.push((shift(start.max(position)), shift(end)));
        }
        self.0.clear();
        for (start, end) in moved {
            self.add(start, end);
        }
    }

    /// `n` rows from `position` selected; with `unselect_rest` only they (a click, Shift+click, Select All), else
    /// with those selected (Ctrl+click, Ctrl+Shift+click)
    pub fn select(&mut self, position: u32, n: u32, unselect_rest: bool) {
        if unselect_rest {
            self.0.clear();
        }
        self.add(position, position.saturating_add(n));
    }

    /// `n` rows from `position` no longer selected
    pub fn unselect(&mut self, position: u32, n: u32) {
        self.remove(position, position.saturating_add(n));
    }

    /// The rows of `mask` selected as `selected` has them, the others as they were (a rubber band, a selection set
    /// whole)
    pub fn set(&mut self, selected: &Ranges, mask: &Ranges) {
        for &(start, end) in mask.spans() {
            self.remove(start, end);
        }
        for &(start, end) in mask.spans() {
            for &(s, e) in selected.within(start, end).spans() {
                self.add(s, e);
            }
        }
    }

    /// Those within the rows `start` to `end`
    pub fn within(&self, start: u32, end: u32) -> Ranges {
        let mut found = Ranges::default();
        let from = self.0.partition_point(|(_, e)| *e <= start);
        for &(s, e) in &self.0[from..] {
            if s >= end {
                break;
            }
            found.0.push((s.max(start), e.min(end)));
        }
        found
    }

    /// The span of the rows selected in one and not in the other (position, how many); None when they are the same
    pub fn changed_span(&self, other: &Ranges) -> Option<(u32, u32)> {
        let mut edges: Vec<u32> = self.0.iter().chain(&other.0).flat_map(|&(s, e)| [s, e]).collect();
        edges.sort_unstable();
        edges.dedup();
        let differs = edges
            .windows(2)
            .filter(|pair| self.contains(pair[0]) != other.contains(pair[0]));
        let (mut first, mut last) = (None, 0);
        for pair in differs {
            first.get_or_insert(pair[0]);
            last = pair[1];
        }
        first.map(|first| (first, last - first))
    }

    /// The rows of a GTK bitset as ranges: at once for one run of rows (Select All, a range), else row by row
    pub fn of_bitset(set: &gtk::Bitset) -> Ranges {
        let mut ranges = Ranges::default();
        if set.is_empty() {
            return ranges;
        }
        let (min, max) = (set.minimum(), set.maximum());
        if set.size() == u64::from(max - min) + 1 {
            ranges.add(min, max.saturating_add(1));
            return ranges;
        }
        let Some((mut iter, first)) = gtk::BitsetIter::init_first(set) else {
            return ranges;
        };
        let mut at = Some(first);
        while let Some(row) = at {
            match ranges.0.last_mut() {
                Some((_, end)) if *end == row => *end += 1,
                _ => ranges.0.push((row, row + 1)),
            }
            at = iter.next();
        }
        ranges
    }

    /// As a GTK bitset
    fn bitset(&self) -> gtk::Bitset {
        let set = gtk::Bitset::new_empty();
        for &(start, end) in &self.0 {
            set.add_range(start, end - start);
        }
        set
    }
}

mod imp {
    use super::*;

    #[derive(Default)]
    pub struct MessageSelection {
        pub model: RefCell<Option<MessageModel>>,
        pub selected: RefCell<Ranges>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for MessageSelection {
        const NAME: &'static str = "IcMessageSelection";
        type Type = super::MessageSelection;
        type Interfaces = (gio::ListModel, gtk::SelectionModel);
    }

    impl ObjectImpl for MessageSelection {}

    impl MessageSelection {
        fn hold(&self, position: u32) {
            if let Some(model) = self.model.borrow().as_ref() {
                model.hold(position);
            }
        }
    }

    impl ListModelImpl for MessageSelection {
        fn item_type(&self) -> glib::Type {
            MessageRow::static_type()
        }

        fn n_items(&self) -> u32 {
            self.model.borrow().as_ref().map_or(0, |m| m.n_items())
        }

        fn item(&self, position: u32) -> Option<glib::Object> {
            self.model.borrow().as_ref()?.item(position)
        }
    }

    impl SelectionModelImpl for MessageSelection {
        fn selection_in_range(&self, position: u32, n_items: u32) -> gtk::Bitset {
            self.selected
                .borrow()
                .within(position, position.saturating_add(n_items))
                .bitset()
        }

        fn is_selected(&self, position: u32) -> bool {
            self.selected.borrow().contains(position)
        }

        fn select_all(&self) -> bool {
            let rows = self.n_items();
            self.obj().change(|ranges| ranges.select(0, rows, true));
            true
        }

        fn unselect_all(&self) -> bool {
            self.obj().change(|ranges| ranges.unselect(0, u32::MAX));
            true
        }

        /// A click (GTK keeps the row clicked, its anchor, out of sight too)
        fn select_item(&self, position: u32, unselect_rest: bool) -> bool {
            self.hold(position);
            self.obj().change(|ranges| ranges.select(position, 1, unselect_rest));
            true
        }

        fn unselect_item(&self, position: u32) -> bool {
            self.hold(position);
            self.obj().change(|ranges| ranges.unselect(position, 1));
            true
        }

        /// Shift+click from the anchor (one end) to the row clicked (the other)
        fn select_range(&self, position: u32, n_items: u32, unselect_rest: bool) -> bool {
            self.hold(position);
            self.hold(position.saturating_add(n_items.saturating_sub(1)));
            self.obj()
                .change(|ranges| ranges.select(position, n_items, unselect_rest));
            true
        }

        fn unselect_range(&self, position: u32, n_items: u32) -> bool {
            self.obj().change(|ranges| ranges.unselect(position, n_items));
            true
        }

        fn set_selection(&self, selected: &gtk::Bitset, mask: &gtk::Bitset) -> bool {
            let (selected, mask) = (Ranges::of_bitset(selected), Ranges::of_bitset(mask));
            self.obj().change(|ranges| ranges.set(&selected, &mask));
            true
        }
    }
}

glib::wrapper! {
    pub struct MessageSelection(ObjectSubclass<imp::MessageSelection>)
        @implements gio::ListModel, gtk::SelectionModel;
}

impl MessageSelection {
    /// The selection of `model`'s rows: its changes passed on, the selection following them
    pub fn new(model: &MessageModel) -> MessageSelection {
        let selection: MessageSelection = glib::Object::new();
        *selection.imp().model.borrow_mut() = Some(model.clone());
        let weak = selection.downgrade();
        model.connect_items_changed(move |_, position, removed, added| {
            let Some(selection) = weak.upgrade() else { return };
            selection.imp().selected.borrow_mut().splice(position, removed, added);
            selection.items_changed(position, removed, added);
        });
        selection
    }

    /// The rows selected, borrowed: let go before the selection changes
    pub fn ranges(&self) -> std::cell::Ref<'_, Ranges> {
        self.imp().selected.borrow()
    }

    /// Only the rows `ranges` selected
    pub fn set_ranges(&self, ranges: Ranges) {
        self.change(|selected| *selected = ranges);
    }

    /// The selection changed by `f`, the rows whose state changed told
    fn change(&self, f: impl FnOnce(&mut Ranges)) {
        let before = self.ranges().clone();
        let rows = self.n_items();
        let after = {
            let mut selected = self.imp().selected.borrow_mut();
            f(&mut selected);
            // never past the end of the list
            selected.remove(rows, u32::MAX);
            selected.clone()
        };
        if let Some((position, n)) = before.changed_span(&after) {
            self.selection_changed(position, n);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ranges(spans: &[(u32, u32)]) -> Ranges {
        let mut r = Ranges::default();
        for &(s, e) in spans {
            r.add(s, e);
        }
        r
    }

    #[test]
    fn ranges_merge_split_and_find_rows() {
        let mut r = ranges(&[(10, 20), (30, 40)]);
        r.add(20, 25);
        assert_eq!(r.spans(), [(10, 25), (30, 40)], "touching ranges join");
        r.add(24, 31);
        assert_eq!(r.spans(), [(10, 40)], "one bridging two joins them");
        r.remove(15, 18);
        assert_eq!(r.spans(), [(10, 15), (18, 40)]);
        r.remove(0, 12);
        assert_eq!(r.spans(), [(12, 15), (18, 40)]);
        assert!(r.contains(12) && r.contains(39) && !r.contains(15) && !r.contains(40) && !r.contains(0));
        assert_eq!(r.size(), 25);
        assert_eq!((r.first(), r.last()), (Some(12), Some(39)));
        r.remove(0, u32::MAX);
        assert!(r.is_empty());
        assert_eq!((r.first(), r.last()), (None, None));
    }

    /// Select All of a huge list is one range, not a row each
    #[test]
    fn select_all_of_a_huge_list_is_one_range() {
        let mut r = Ranges::default();
        r.add(0, 200_000);
        assert_eq!(r.spans().len(), 1);
        assert_eq!(r.size(), 200_000);
        r.remove(5, 6);
        assert_eq!(r.spans(), [(0, 5), (6, 200_000)]);
    }

    /// The selection follows the list's changes: rows added above move it down, rows removed leave it, rows
    /// changed in place (a page drawn, the same list read again) keep it
    #[test]
    fn ranges_follow_the_list() {
        let mut r = ranges(&[(5, 8), (20, 22)]);
        r.splice(0, 0, 3);
        assert_eq!(r.spans(), [(8, 11), (23, 25)], "three new rows at the top");
        r.splice(9, 2, 0);
        assert_eq!(r.spans(), [(8, 9), (21, 23)], "two removed from the first range");
        r.splice(0, 100, 100);
        assert_eq!(r.spans(), [(8, 9), (21, 23)], "changed in place");
        r.splice(0, 30, 0);
        assert!(r.is_empty(), "every row removed (another list)");
        let mut r = ranges(&[(0, 10)]);
        r.splice(10, 0, 5);
        assert_eq!(r.spans(), [(0, 10)], "rows added at the end leave it");
        r.splice(4, 0, 2);
        assert_eq!(r.spans(), [(0, 4), (6, 12)], "rows added inside it are not selected");
        r.splice(3, 4, 0);
        assert_eq!(r.spans(), [(0, 8)], "the rows around those removed join");
    }

    #[test]
    fn the_rows_that_changed_are_told() {
        let a = ranges(&[(10, 20)]);
        assert_eq!(a.changed_span(&a.clone()), None);
        assert_eq!(a.changed_span(&ranges(&[(10, 25)])), Some((20, 5)));
        assert_eq!(a.changed_span(&ranges(&[(3, 4), (10, 20)])), Some((3, 1)));
        assert_eq!(a.changed_span(&ranges(&[(12, 14)])), Some((10, 10)));
        assert_eq!(a.changed_span(&Ranges::default()), Some((10, 10)));
        assert_eq!(ranges(&[(0, 5)]).changed_span(&ranges(&[(100, 105)])), Some((0, 105)));
    }

    /// The calls a list view makes for a click, Shift+click, Ctrl+click and Ctrl+Shift+click (gtklistbase.c), a
    /// rubber band, and the keys' Select All and Unselect All give the rows they did with GtkMultiSelection
    #[test]
    fn clicks_and_keys_select_as_before() {
        let rows = 1_000;
        let mut r = Ranges::default();
        // a click on row 5, Shift+click on row 10
        r.select(5, 1, true);
        r.select(5, 6, true);
        assert_eq!(r.spans(), [(5, 11)]);
        // Ctrl+click on 20 adds it, Ctrl+click on 7 takes it away
        r.select(20, 1, false);
        r.unselect(7, 1);
        assert_eq!(r.spans(), [(5, 7), (8, 11), (20, 21)]);
        // Ctrl+Shift+click from 20 to 25 adds them; from an anchor not selected, takes them away
        r.select(20, 6, false);
        assert_eq!(r.spans(), [(5, 7), (8, 11), (20, 26)]);
        r.unselect(9, 13);
        assert_eq!(r.spans(), [(5, 7), (8, 9), (22, 26)]);
        assert_eq!(r.size(), 7);
        // a rubber band over rows 100 to 104: only they, as GTK sets them with the whole list as the mask
        r.set(&ranges(&[(100, 105)]), &ranges(&[(0, rows)]));
        assert_eq!(r.spans(), [(100, 105)]);
        // one with the rows around it kept: only its own rows set
        r.set(&ranges(&[(102, 103)]), &ranges(&[(101, 104)]));
        assert_eq!(r.spans(), [(100, 101), (102, 103), (104, 105)]);
        // a click alone selects only its row
        r.select(500, 1, true);
        assert_eq!(r.spans(), [(500, 501)]);
        r.select(0, rows, true);
        assert_eq!(r.spans(), [(0, 1_000)]);
        r.unselect(0, u32::MAX);
        assert!(r.is_empty());
        // never past the end of the list, which MessageSelection's change takes away
        r.select(990, 50, true);
        r.remove(rows, u32::MAX);
        assert_eq!(r.spans(), [(990, 1_000)]);
    }

    #[test]
    fn within_clips_to_the_rows_asked() {
        let r = ranges(&[(0, 10), (20, 30), (40, 50)]);
        assert_eq!(r.within(5, 25).spans(), [(5, 10), (20, 25)]);
        assert!(r.within(10, 20).is_empty());
        assert_eq!(r.within(0, u32::MAX), r);
    }
}
