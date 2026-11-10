//! Evaluates the gradient boosted trees exported by otp-detect's training/train.py, a port of its
//! src/model.ts. The trees are in model/model.rs, generated from otp-detect's src/model-data.ts by
//! scripts/update-otp-model.sh.

use crate::features::FEATURE_NAMES;

/// One tree in flat arrays. Internal node i compares feature[i] with threshold[i]: values less
/// than or equal go left. A child index >= 0 is another internal node, a negative index c is the
/// leaf !c (that is -c - 1) in `leaves`.
#[derive(Debug)]
pub struct Tree {
    pub feature: &'static [usize],
    pub threshold: &'static [f64],
    pub left: &'static [i32],
    pub right: &'static [i32],
    pub leaves: &'static [f64],
}

#[derive(Debug)]
pub struct Model {
    pub version: &'static str,
    pub feature_names: &'static [&'static str],
    pub trees: &'static [Tree],
    /// Default decision threshold on the probability, picked on held-out data
    pub threshold: f64,
}

/// The model built in, from otp-detect (model/SOURCE says which version)
pub const MODEL: Model = include!("../model/model.rs");

// A model trained on another feature list than this version computes does not build
const _: () = assert!(
    MODEL.has_feature_names(),
    "the model was trained on a different feature list than this version computes"
);

const fn same(a: &str, b: &str) -> bool {
    let (a, b) = (a.as_bytes(), b.as_bytes());
    if a.len() != b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if a[i] != b[i] {
            return false;
        }
        i += 1;
    }
    true
}

impl Model {
    /// Whether the model was trained on the feature list this version computes, FEATURE_NAMES
    pub const fn has_feature_names(&self) -> bool {
        if self.feature_names.len() != FEATURE_NAMES.len() {
            return false;
        }
        let mut i = 0;
        while i < FEATURE_NAMES.len() {
            if !same(self.feature_names[i], FEATURE_NAMES[i]) {
                return false;
            }
            i += 1;
        }
        true
    }

    /// Probability that the candidate with these features is the one-time code
    pub fn predict(&self, row: &[f64]) -> f64 {
        let sum: f64 = self.trees.iter().fold(0.0, |sum, tree| sum + tree.eval(row));
        1.0 / (1.0 + (-sum).exp())
    }
}

impl Tree {
    fn eval(&self, row: &[f64]) -> f64 {
        if self.feature.is_empty() {
            return self.leaves.first().copied().unwrap_or(0.0);
        }
        let mut node = 0;
        loop {
            // NaN compares false and goes right, as in JavaScript
            let value = row.get(self.feature[node]).copied().unwrap_or(f64::NAN);
            let next = if value <= self.threshold[node] {
                self.left[node]
            } else {
                self.right[node]
            };
            if next < 0 {
                return self.leaves[(-next - 1) as usize];
            }
            node = next as usize;
        }
    }
}
