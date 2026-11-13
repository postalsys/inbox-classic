//! BIMI logos (draft-brand-indicators-for-message-identification): the brand's logo shown beside the sender of a
//! message whose domain passed DMARC and whose logo the receiving server checked. The client can not check DMARC
//! itself (it has no SPF data), so the verdict is the receiving server's: the topmost Authentication-Results header
//! (a sender can add one, but only below the servers') must say `bimi=pass` and `dmarc=pass`. The logo then comes
//! from the server's BIMI-Indicator header (the SVG itself, no request) or else from the https URL of BIMI-Location.
//! An SVG is checked (size, no scripts, nothing loaded from elsewhere) and turned into pixels here, so the window
//! gets a picture and never an SVG.

use base64::Engine;
use pe_mime::parser::Header;

use crate::authres::{self, passes, tag, verdict};

/// The most an SVG logo may be, as BIMI asks of them
pub const MAX_SVG: usize = 32 * 1024;

/// Where a message's logo is
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Logo {
    /// The SVG, from BIMI-Indicator
    Indicator(Vec<u8>),
    /// An https address to fetch the SVG from, from BIMI-Location
    Location(String),
}

/// The logo of a message, when the account's provider (whose verdicts `trusted` names) says the brand's domain
/// passed DMARC and its logo passed BIMI; None otherwise. A BIMI-Location is used only over https (http to the
/// loopback address only in a debug build, for the tests).
pub fn of(headers: &[Header], trusted: &[String]) -> Option<Logo> {
    let results = verdict(headers, trusted)?;
    if !results.iter().any(|r| passes(r, "bimi")) || !results.iter().any(|r| passes(r, "dmarc")) {
        return None;
    }
    if let Some(indicator) = authres::headers(headers, "bimi-indicator").next() {
        let compact: String = indicator.chars().filter(|c| !c.is_whitespace()).collect();
        let svg = base64::engine::general_purpose::STANDARD.decode(compact).ok()?;
        return (svg.len() <= MAX_SVG).then_some(Logo::Indicator(svg));
    }
    let location = authres::headers(headers, "bimi-location").next()?;
    let url = tag(location, "l")?.to_string();
    let parsed = pe_net::http::parse_url(&url)?;
    (parsed.https || cfg!(debug_assertions) || LOOPBACK.load(std::sync::atomic::Ordering::Relaxed))
        .then_some(Logo::Location(url))
}

/// Whether a BIMI-Location on the loopback address over plain http counts: only the apps' UI tests turn it on, so a
/// release build can show a logo the test serves from 127.0.0.1 (pe_net::http::parse_url takes plain http to the
/// loopback address only, never to another host)
static LOOPBACK: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);

/// The UI tests' switch for [`LOOPBACK`]; never called otherwise
pub fn allow_loopback_logos(on: bool) {
    LOOPBACK.store(on, std::sync::atomic::Ordering::Relaxed);
}

/// An SVG logo as `size` x `size` pixels, BGRA with the alpha multiplied in (as Windows draws them), the logo
/// centered in it; None for what is no logo BIMI allows: too large, compressed, scripted, or reaching for anything
/// outside itself
pub fn render(svg: &[u8], size: u32) -> Option<Vec<u8>> {
    if svg.len() > MAX_SVG || svg.starts_with(&[0x1f, 0x8b]) || !(16..=512).contains(&size) {
        return None;
    }
    let text = std::str::from_utf8(svg).ok()?.to_ascii_lowercase();
    // SVG Tiny PS has none of these; an SVG that has them is no BIMI logo
    if [
        "<script",
        "<foreignobject",
        "<image",
        "<iframe",
        "javascript:",
        "<!entity",
    ]
    .iter()
    .any(|bad| text.contains(bad))
    {
        return None;
    }
    // nothing is loaded from anywhere, files or the network: an href to elsewhere draws nothing
    let options = resvg::usvg::Options {
        resources_dir: None,
        image_href_resolver: resvg::usvg::ImageHrefResolver {
            resolve_data: Box::new(|_, _, _| None),
            resolve_string: Box::new(|_, _| None),
        },
        ..Default::default()
    };
    let tree = resvg::usvg::Tree::from_data(svg, &options).ok()?;
    let mut pixmap = resvg::tiny_skia::Pixmap::new(size, size)?;
    let bounds = tree.size();
    let scale = (size as f32 / bounds.width()).min(size as f32 / bounds.height());
    if !scale.is_finite() || scale <= 0.0 {
        return None;
    }
    let (dx, dy) = (
        (size as f32 - bounds.width() * scale) / 2.0,
        (size as f32 - bounds.height() * scale) / 2.0,
    );
    let transform = resvg::tiny_skia::Transform::from_scale(scale, scale).post_translate(dx, dy);
    resvg::render(&tree, transform, &mut pixmap.as_mut());
    // RGBA to BGRA, the alpha multiplied in already
    let mut pixels = pixmap.take();
    for pixel in pixels.as_chunks_mut::<4>().0 {
        pixel.swap(0, 2);
    }
    Some(pixels)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// As the account whose provider names its verdicts mx.example.net has it
    fn of(headers: &[Header]) -> Option<Logo> {
        super::of(headers, &["example.net".to_string()])
    }

    const SVG: &str = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.2\" baseProfile=\"tiny-ps\" viewBox=\"0 0 100 100\">\
        <title>Brand</title><circle cx=\"50\" cy=\"50\" r=\"50\" fill=\"#ff0000\"/></svg>";

    fn headers(text: &str) -> Vec<Header> {
        pe_mime::parser::parse(format!("{text}\r\nSubject: x\r\n\r\nbody\r\n").as_bytes())
            .unwrap()
            .headers
    }

    fn indicator() -> String {
        base64::engine::general_purpose::STANDARD.encode(SVG)
    }

    #[test]
    fn a_logo_only_when_the_server_passed_it() {
        let passed = format!(
            "Authentication-Results: mx.example.net; dmarc=pass header.from=brand.example; bimi=pass header.d=brand.example\r\nBIMI-Indicator: {}",
            indicator()
        );
        assert_eq!(of(&headers(&passed)), Some(Logo::Indicator(SVG.as_bytes().to_vec())));
        // DMARC failed, BIMI was not checked, or the verdict is the sender's own under the server's
        assert_eq!(of(&headers(&passed.replace("dmarc=pass", "dmarc=fail"))), None);
        assert_eq!(of(&headers(&passed.replace("bimi=pass", "bimi=none"))), None);
        let forged = format!("Authentication-Results: mx.example.net; dmarc=none\r\n{passed}");
        assert_eq!(of(&headers(&forged)), None);
        // a verdict of anyone but the provider counts for nothing
        assert_eq!(of(&headers(&passed.replace("mx.example.net", "forged.example"))), None);
        // the location instead: https only (or a test server on the loopback address)
        let location = "Authentication-Results: mx.example.net; dmarc=pass; bimi=pass\r\nBIMI-Location: v=BIMI1; l=https://brand.example/logo.svg";
        assert_eq!(
            of(&headers(location)),
            Some(Logo::Location("https://brand.example/logo.svg".into()))
        );
        assert_eq!(of(&headers(&location.replace("https:", "http:"))), None);
        assert_eq!(
            of(&headers(
                &location.replace("https://brand.example", "http://127.0.0.1:9")
            ))
            .is_some(),
            cfg!(debug_assertions)
        );
        assert_eq!(of(&headers("Subject-Line: none")), None);
    }

    #[test]
    fn draws_a_logo_and_refuses_what_is_none() {
        let pixels = render(SVG.as_bytes(), 32).unwrap();
        assert_eq!(pixels.len(), 32 * 32 * 4);
        // the middle is red (BGRA), the corner clear
        let middle = (16 * 32 + 16) * 4;
        assert_eq!(&pixels[middle..middle + 4], &[0, 0, 255, 255]);
        assert_eq!(&pixels[0..4], &[0, 0, 0, 0]);
        // scripts, things from elsewhere, compressed or oversized files, and what is no SVG
        let scripted = SVG.replace("<title>", "<script>alert(1)</script><title>");
        assert!(render(scripted.as_bytes(), 32).is_none());
        let elsewhere = SVG.replace(
            "<title>Brand</title>",
            "<image href=\"https://tracker.example/p.png\" width=\"10\" height=\"10\"/>",
        );
        assert!(render(elsewhere.as_bytes(), 32).is_none());
        assert!(render(&[0x1f, 0x8b, 0, 0], 32).is_none());
        assert!(render(&vec![b' '; MAX_SVG + 1], 32).is_none());
        assert!(render(b"not an svg", 32).is_none());
        assert!(render(SVG.as_bytes(), 4).is_none());
    }
}
