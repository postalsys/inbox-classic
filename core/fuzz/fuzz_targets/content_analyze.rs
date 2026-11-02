//! A message body from a sender through reply and quote detection: the bytes are split into a
//! plain text and an HTML body and analysed with a parent message as history, so every stage
//! (both segmenters, the classifier and history matching) sees hostile input
#![no_main]

use libfuzzer_sys::fuzz_target;
use pe_content::{AnalyzeOptions, HistoryContent, MessageContent, analyze};

fuzz_target!(|data: &[u8]| {
    let input = String::from_utf8_lossy(data);
    let (text, html) = input.split_at(input.char_indices().nth(input.chars().count() / 2).map_or(0, |(at, _)| at));
    let content = MessageContent {
        text: Some(text),
        html: Some(html),
        subject: Some("Re: fuzz"),
        from: Some("Fuzz Tester <fuzz@example.com>"),
        ..Default::default()
    };
    let options = AnalyzeOptions {
        history: vec![HistoryContent {
            text: Some(html),
            html: Some(text),
        }],
        ..Default::default()
    };
    let result = analyze(&content, &options).expect("default options are valid");
    for segment in result.segments.iter().chain(&result.hidden_segments) {
        assert!(segment.source.start <= segment.source.end);
    }
    // The HTML alone, so the HTML segmenter drives the output too.
    let html_only = MessageContent {
        html: Some(&input),
        ..Default::default()
    };
    let _ = analyze(&html_only, &AnalyzeOptions::default());
});
