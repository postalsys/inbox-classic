//! The bounce-classifier network, built into the crate and read once: an embedding of 5000 words
//! in 64 dimensions averaged over all 100 positions, a dense layer of 64 with ReLU and one of 16
//! with softmax (see bounce-classifier's docs/inference.md). The arithmetic follows its JavaScript
//! step for step, single precision where it keeps Float32Arrays and double where it adds up plain
//! numbers, so the scores match it to the last bits.

use std::collections::HashMap;
use std::sync::OnceLock;

use crate::Label;
use crate::js;

const MAX_LENGTH: usize = 100;
const EMBEDDING_DIM: usize = 64;
const HIDDEN_DIM: usize = 64;
pub const NUM_LABELS: usize = 16;

const VOCAB: &str = include_str!("../model/vocab.json");
const LABELS: &str = include_str!("../model/labels.json");
const CONFIG: &str = include_str!("../model/config.json");
const WEIGHTS: &[u8] = include_bytes!("../model/group1-shard1of1.bin");

pub struct Model {
    vocab: HashMap<String, u32>,
    dense1_kernel: Vec<f32>,
    dense1_bias: Vec<f32>,
    dense2_kernel: Vec<f32>,
    dense2_bias: Vec<f32>,
    embedding: Vec<f32>,
}

/// The model's metadata, from config.json
#[derive(Debug, Clone, PartialEq)]
pub struct ModelInfo {
    pub model_hash: Option<String>,
    pub trained_at: Option<String>,
    pub training_samples: Option<u64>,
    pub validation_accuracy: Option<f64>,
}

pub fn model() -> &'static Model {
    static MODEL: OnceLock<Model> = OnceLock::new();
    MODEL.get_or_init(Model::load)
}

pub fn info() -> ModelInfo {
    let config: serde_json::Value = serde_json::from_str(CONFIG).expect("model/config.json");
    ModelInfo {
        model_hash: config["model_hash"].as_str().map(str::to_string),
        trained_at: config["trained_at"].as_str().map(str::to_string),
        training_samples: config["training_samples"].as_u64(),
        validation_accuracy: config["validation_accuracy"].as_f64(),
    }
}

impl Model {
    fn load() -> Model {
        let words: Vec<String> = serde_json::from_str(VOCAB).expect("model/vocab.json");
        let mut vocab = HashMap::with_capacity(words.len());
        for (index, word) in words.into_iter().enumerate() {
            // A later duplicate wins, as Map.set does
            vocab.insert(word, index as u32);
        }
        // The outputs are read as Label::ALL; a model with other labels, or in another order, needs
        // the enum changed first
        let labels: serde_json::Value = serde_json::from_str(LABELS).expect("model/labels.json");
        for (i, label) in Label::ALL.iter().enumerate() {
            assert_eq!(
                labels["id_to_label"][i.to_string()].as_str(),
                Some(label.name()),
                "model/labels.json does not match Label::ALL"
            );
        }
        let data: Vec<f32> = WEIGHTS
            .as_chunks::<4>()
            .0
            .iter()
            .map(|b| f32::from_le_bytes(*b))
            .collect();
        let mut rest = data.as_slice();
        let mut take = |n: usize| {
            let (head, tail) = rest.split_at(n);
            rest = tail;
            head.to_vec()
        };
        let dense1_kernel = take(EMBEDDING_DIM * HIDDEN_DIM);
        let dense1_bias = take(HIDDEN_DIM);
        let dense2_kernel = take(HIDDEN_DIM * NUM_LABELS);
        let dense2_bias = take(NUM_LABELS);
        let embedding = rest.to_vec();
        assert_eq!(embedding.len() % EMBEDDING_DIM, 0, "embedding size");
        assert!(
            embedding.len() / EMBEDDING_DIM >= vocab.len(),
            "an embedding for every word"
        );
        Model {
            vocab,
            dense1_kernel,
            dense1_bias,
            dense2_kernel,
            dense2_bias,
            embedding,
        }
    }

    /// Lowercase, everything but ASCII letters, digits, `_` and whitespace made a space, whitespace
    /// collapsed, then the first 100 words looked up (1 for a word the vocabulary has not got, 0
    /// for the padding)
    fn tokenize(&self, text: &str) -> [u32; MAX_LENGTH] {
        let lower = text.to_lowercase();
        let cleaned: String = lower
            .chars()
            .map(|c| {
                if c.is_ascii_alphanumeric() || c == '_' || js::is_space(c) {
                    c
                } else {
                    ' '
                }
            })
            .collect();
        let processed = js::collapse(&cleaned);
        let mut tokens = [0; MAX_LENGTH];
        for (token, word) in tokens.iter_mut().zip(processed.split(' ')) {
            *token = self.vocab.get(word).copied().unwrap_or(1);
        }
        tokens
    }

    /// The probability of each label, in the order of [`Label::ALL`]
    pub fn scores(&self, text: &str) -> [f32; NUM_LABELS] {
        let tokens = self.tokenize(text);
        let mut pooled = [0f32; EMBEDDING_DIM];
        for token in tokens {
            let offset = token as usize * EMBEDDING_DIM;
            for (p, e) in pooled.iter_mut().zip(&self.embedding[offset..offset + EMBEDDING_DIM]) {
                *p += e;
            }
        }
        for p in &mut pooled {
            *p /= MAX_LENGTH as f32;
        }
        let mut hidden = [0f32; HIDDEN_DIM];
        for (i, h) in hidden.iter_mut().enumerate() {
            let mut sum = self.dense1_bias[i] as f64;
            for (j, p) in pooled.iter().enumerate() {
                sum += *p as f64 * self.dense1_kernel[j * HIDDEN_DIM + i] as f64;
            }
            *h = sum.max(0.0) as f32;
        }
        let mut output = [0f32; NUM_LABELS];
        for (i, o) in output.iter_mut().enumerate() {
            let mut sum = self.dense2_bias[i] as f64;
            for (j, h) in hidden.iter().enumerate() {
                sum += *h as f64 * self.dense2_kernel[j * NUM_LABELS + i] as f64;
            }
            *o = sum as f32;
        }
        softmax(&output)
    }
}

fn softmax(values: &[f32; NUM_LABELS]) -> [f32; NUM_LABELS] {
    let max = values
        .iter()
        .fold(f32::NEG_INFINITY, |m, v| if *v > m { *v } else { m });
    let mut out = [0f32; NUM_LABELS];
    let mut sum = 0f64;
    for (o, v) in out.iter_mut().zip(values) {
        let e = (*v as f64 - max as f64).exp();
        *o = e as f32;
        sum += e;
    }
    for o in &mut out {
        *o = (*o as f64 / sum) as f32;
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tokenizes_like_javascript() {
        let model = model();
        // non-ASCII letters split words, and an empty text is one empty word, the padding token
        assert_eq!(model.tokenize("")[0], 0);
        let a = model.tokenize("550 user unknown");
        let b = model.tokenize("  550\u{A0}USER--unknown!! ");
        assert_eq!(a, b);
        assert_ne!(a[0], 1);
        assert_eq!(model.tokenize("bénutzer")[0], model.tokenize("b nutzer")[0]);
    }

    #[test]
    fn scores_add_up_to_one() {
        let sum: f32 = model().scores("550 5.1.1 User unknown").iter().sum();
        assert!((sum - 1.0).abs() < 1e-4);
    }

    #[test]
    fn reads_the_metadata() {
        assert!(info().model_hash.is_some());
    }
}
