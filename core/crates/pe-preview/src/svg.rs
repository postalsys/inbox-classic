//! An SVG picture in a message's text (`cid:` or `data:`, never an attached file) to a raster preview: drawn with
//! resvg, which reads nothing outside the file (no other files, no network, no fonts: text is not drawn), and encoded
//! again as the core's own PNG, so a web view never parses the sender's SVG as a document.
//!
//! Before resvg sees it, the file's size and its `use` references are checked: a `use` copies what it names, so a
//! few nested ones (`a` drawing `b` ten times, `b` drawing `c` ten times...) would make a tree of billions of elements
//! from a few kilobytes.

use std::collections::HashMap;

use resvg::usvg::roxmltree;

use crate::limits::{MAX_SVG, MAX_SVG_ELEMENTS};
use crate::{Description, Kind, Picture, Refusal};

/// Whether `bytes` are an SVG document by their start: optional byte order mark and white space, then the XML
/// declaration, a comment, a doctype or the `svg` element itself, and an `svg` element early on
pub fn is_svg(bytes: &[u8]) -> bool {
    let bytes = bytes.strip_prefix(b"\xef\xbb\xbf").unwrap_or(bytes);
    let start = bytes
        .iter()
        .position(|b| !b.is_ascii_whitespace())
        .unwrap_or(bytes.len());
    let head = &bytes[start..bytes.len().min(start + 4096)];
    let opens = |prefix: &[u8]| {
        head.get(..prefix.len())
            .is_some_and(|start| start.eq_ignore_ascii_case(prefix))
    };
    let known = opens(b"<svg") || opens(b"<?xml") || opens(b"<!--") || opens(b"<!doctype svg");
    known && head.windows(4).any(|window| window.eq_ignore_ascii_case(b"<svg"))
}

/// The size of the preview of an SVG picture: its own size, scaled to [`crate::limits::MAX_SIDE`]
pub fn describe(bytes: &[u8]) -> Result<Description, Refusal> {
    let tree = parse(bytes)?;
    let (width, height) = size_of(&tree)?;
    Ok(Description {
        kind: Kind::Picture,
        pages: 1,
        title: None,
        sizes: vec![Some((width, height))],
    })
}

/// The preview of an SVG picture: drawn at its size (at most [`crate::limits::MAX_SIDE`] a side) on nothing, a PNG
pub fn render(bytes: &[u8]) -> Result<Picture, Refusal> {
    let tree = parse(bytes)?;
    let (width, height) = size_of(&tree)?;
    let mut pixmap = resvg::tiny_skia::Pixmap::new(width, height).ok_or(Refusal::TooLarge)?;
    let bounds = tree.size();
    let transform =
        resvg::tiny_skia::Transform::from_scale(width as f32 / bounds.width(), height as f32 / bounds.height());
    check_extent(&tree, transform)?;
    resvg::render(&tree, transform, &mut pixmap.as_mut());
    let mut pixels = Vec::with_capacity(pixmap.data().len());
    for pixel in pixmap.pixels() {
        let color = pixel.demultiply();
        pixels.extend_from_slice(&[color.red(), color.green(), color.blue(), color.alpha()]);
    }
    let image = image::RgbaImage::from_raw(width, height, pixels).ok_or(Refusal::Unreadable)?;
    crate::encode::encode(image::DynamicImage::ImageRgba8(image), false, None)
}

/// The tree resvg draws, from a file whose size and `use` copies are within the limits; nothing is loaded from
/// outside it
fn parse(bytes: &[u8]) -> Result<resvg::usvg::Tree, Refusal> {
    if bytes.len() > MAX_SVG {
        return Err(Refusal::TooLarge);
    }
    // a compressed SVG (svgz) would be inflated by usvg without a limit
    if bytes.starts_with(&[0x1f, 0x8b]) || !is_svg(bytes) {
        return Err(Refusal::Unsupported);
    }
    let text = std::str::from_utf8(bytes).map_err(|_| Refusal::Unreadable)?;
    // no DTD: no entities, external or internal
    let xml = roxmltree::ParsingOptions {
        allow_dtd: false,
        nodes_limit: MAX_SVG_ELEMENTS as u32 * 4,
        ..Default::default()
    };
    let document = roxmltree::Document::parse_with_options(text, xml).map_err(|_| Refusal::Unreadable)?;
    check_copies(&document)?;
    let options = resvg::usvg::Options {
        resources_dir: None,
        image_href_resolver: resvg::usvg::ImageHrefResolver {
            resolve_data: Box::new(|_, _, _| None),
            resolve_string: Box::new(|_, _| None),
        },
        ..Default::default()
    };
    let tree = resvg::usvg::Tree::from_xmltree(&document, &options).map_err(|_| Refusal::Unreadable)?;
    check_filters(&tree)?;
    Ok(tree)
}

/// The largest blur or morphology radius drawn, in the SVG's own units: resvg's box blur overflows its sums on a
/// standard deviation of tens of thousands (found by fuzzing), and nothing is blurred usefully past the picture
const MAX_FILTER_RADIUS: f32 = 1000.0;

/// The radii of a filter's blurs, shadows and morphologies
fn radii(filter: &resvg::usvg::filter::Filter) -> Vec<f32> {
    use resvg::usvg::filter::Kind;
    filter
        .primitives()
        .iter()
        .flat_map(|primitive| match primitive.kind() {
            Kind::GaussianBlur(blur) => vec![blur.std_dev_x().get(), blur.std_dev_y().get()],
            Kind::DropShadow(shadow) => vec![shadow.std_dev_x().get(), shadow.std_dev_y().get()],
            Kind::Morphology(morphology) => vec![morphology.radius_x().get(), morphology.radius_y().get()],
            _ => Vec::new(),
        })
        .collect()
}

/// Refuses a picture whose filters blur or spread further than [`MAX_FILTER_RADIUS`], or than the picture is wide
/// once its groups' transforms are applied
fn check_filters(tree: &resvg::usvg::Tree) -> Result<(), Refusal> {
    let fits = |radius: f32| radius.is_finite() && radius <= MAX_FILTER_RADIUS;
    if !tree.filters().iter().flat_map(|filter| radii(filter)).all(fits) {
        return Err(Refusal::TooLarge);
    }
    fn walk(group: &resvg::usvg::Group) -> bool {
        let (sx, sy) = group.abs_transform().get_scale();
        let scale = sx.abs().max(sy.abs());
        let fits = |radius: f32| (radius * scale).is_finite() && radius * scale <= 2.0 * crate::limits::MAX_SIDE as f32;
        group.filters().iter().flat_map(|filter| radii(filter)).all(fits)
            && group.children().iter().all(|node| match node {
                resvg::usvg::Node::Group(group) => walk(group),
                _ => true,
            })
    }
    walk(tree.root()).then_some(()).ok_or(Refusal::TooLarge)
}

/// How far from the preview, in its pixels, anything of the picture may reach: tiny-skia keeps edges in 16.16 fixed
/// point, and a path out at millions of pixels breaks its scanning (found by fuzzing), while nothing that far is seen
const MAX_EXTENT: f32 = 8.0 * crate::limits::MAX_SIDE as f32;

/// Refuses a picture any of whose shapes, their strokes included, reach further than [`MAX_EXTENT`] from the preview
/// once drawn with `transform`. Whatever else draws a sender's SVG with resvg (brand logos) checks it too.
pub fn check_extent(tree: &resvg::usvg::Tree, transform: resvg::tiny_skia::Transform) -> Result<(), Refusal> {
    let reach = tree.root().abs_stroke_bounding_box();
    let (left, top) = (reach.left() * transform.sx, reach.top() * transform.sy);
    let (right, bottom) = (reach.right() * transform.sx, reach.bottom() * transform.sy);
    let near = |n: f32| n.is_finite() && n.abs() <= MAX_EXTENT;
    [left, top, right, bottom]
        .into_iter()
        .all(near)
        .then_some(())
        .ok_or(Refusal::TooLarge)
}

/// The preview's size: the picture's own, scaled to fit, at least a pixel a side
fn size_of(tree: &resvg::usvg::Tree) -> Result<(u32, u32), Refusal> {
    let size = tree.size();
    let (width, height) = (size.width(), size.height());
    if !(width.is_finite() && height.is_finite() && width > 0.0 && height > 0.0) {
        return Err(Refusal::Unreadable);
    }
    let longest = width.max(height);
    let scale = (crate::limits::MAX_SIDE as f32 / longest).min(1.0);
    let side = |n: f32| ((n * scale).round() as u32).clamp(1, crate::limits::MAX_SIDE);
    Ok((side(width), side(height)))
}

/// Refuses a file whose elements, each `use` counted as the copy of what it names, are more than
/// [`MAX_SVG_ELEMENTS`]; or whose `use` references go deeper than resvg is asked to follow
fn check_copies(document: &roxmltree::Document) -> Result<(), Refusal> {
    let ids: HashMap<&str, roxmltree::Node> = document
        .descendants()
        .filter_map(|node| Some((node.attribute("id")?, node)))
        .collect();
    let mut counted = HashMap::new();
    let total = elements(document.root_element(), &ids, &mut counted, 0)?;
    if total > MAX_SVG_ELEMENTS {
        return Err(Refusal::TooLarge);
    }
    Ok(())
}

/// How deep `use` references and elements may nest before the file is refused
const MAX_DEPTH: usize = 256;

/// The elements `node` stands for: itself, its children's, and for a `use` what it names (once per element, counted
/// with what it names); a reference back to itself counts as refused
fn elements<'a>(
    node: roxmltree::Node<'a, 'a>,
    ids: &HashMap<&str, roxmltree::Node<'a, 'a>>,
    counted: &mut HashMap<roxmltree::NodeId, Option<u64>>,
    depth: usize,
) -> Result<u64, Refusal> {
    if depth > MAX_DEPTH {
        return Err(Refusal::TooLarge);
    }
    match counted.get(&node.id()) {
        Some(Some(count)) => return Ok(*count),
        // under way: a reference to itself
        Some(None) => return Err(Refusal::Unreadable),
        None => {}
    }
    counted.insert(node.id(), None);
    let mut count: u64 = 1;
    for child in node.children().filter(|child| child.is_element()) {
        count = count.saturating_add(elements(child, ids, counted, depth + 1)?);
        if count > MAX_SVG_ELEMENTS {
            return Err(Refusal::TooLarge);
        }
    }
    if node.tag_name().name() == "use" {
        let link = node
            .attribute(("http://www.w3.org/1999/xlink", "href"))
            .or_else(|| node.attribute("href"));
        if let Some(target) = link
            .and_then(|link| link.trim().strip_prefix('#'))
            .and_then(|id| ids.get(id))
        {
            count = count.saturating_add(elements(*target, ids, counted, depth + 1)?);
        }
    }
    if count > MAX_SVG_ELEMENTS {
        return Err(Refusal::TooLarge);
    }
    counted.insert(node.id(), Some(count));
    Ok(count)
}

#[cfg(test)]
mod tests {
    use super::*;

    const CIRCLE: &[u8] = b"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"40\" height=\"20\">\
        <rect width=\"40\" height=\"20\" fill=\"#c00\"/></svg>";

    #[test]
    fn an_svg_is_told_by_its_start() {
        assert!(is_svg(CIRCLE));
        assert!(is_svg(b"\xef\xbb\xbf  <?xml version=\"1.0\"?><svg/>"));
        assert!(is_svg(b"<!-- made by hand --><SVG></SVG>"));
        assert!(!is_svg(b"<html><svg></svg></html>"));
        assert!(!is_svg(b"\x89PNG\r\n"));
        assert!(!is_svg(b"<?xml version=\"1.0\"?><feed/>"));
    }

    #[test]
    fn an_svg_is_drawn_as_a_png_of_its_size() {
        let description = describe(CIRCLE).unwrap();
        assert_eq!(description.sizes, [Some((40, 20))]);
        let picture = render(CIRCLE).unwrap();
        assert_eq!((picture.width, picture.height), (40, 20));
        assert!(picture.bytes.starts_with(b"\x89PNG"));
        let decoded = image::load_from_memory(&picture.bytes).unwrap().to_rgba8();
        assert_eq!(decoded.get_pixel(5, 5).0, [0xcc, 0, 0, 255]);
    }

    #[test]
    fn a_large_svg_is_scaled_and_a_broken_one_refused() {
        let wide = b"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100000\" height=\"50000\"/>";
        assert_eq!(describe(wide).unwrap().sizes, [Some((2048, 1024))]);
        assert_eq!(describe(b"<svg width=\"0\"").unwrap_err(), Refusal::Unreadable);
        assert_eq!(describe(&[0x1f, 0x8b, 8, 0]).unwrap_err(), Refusal::Unsupported);
        let big = format!("<svg>{}</svg>", " ".repeat(MAX_SVG));
        assert_eq!(describe(big.as_bytes()).unwrap_err(), Refusal::TooLarge);
    }

    /// `use` copies that multiply (ten of ten of ten...) are refused before resvg makes the copies; one that names
    /// itself too
    #[test]
    fn copies_that_multiply_are_refused() {
        let mut svg = String::from(
            "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"10\" \
             height=\"10\"><defs><rect id=\"l0\" width=\"1\" height=\"1\"/>",
        );
        for level in 1..12 {
            svg.push_str(&format!("<g id=\"l{level}\">"));
            for _ in 0..10 {
                svg.push_str(&format!("<use xlink:href=\"#l{}\"/>", level - 1));
            }
            svg.push_str("</g>");
        }
        svg.push_str("</defs><use href=\"#l11\"/></svg>");
        let started = std::time::Instant::now();
        assert_eq!(describe(svg.as_bytes()).unwrap_err(), Refusal::TooLarge);
        assert!(started.elapsed() < std::time::Duration::from_secs(1));

        let looped = b"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"10\" height=\"10\">\
            <g id=\"a\"><use href=\"#a\"/></g></svg>";
        assert!(describe(looped).is_err());

        // a blur so wide its sums overflow (found by fuzzing): refused; an ordinary one drawn
        let blur = |deviation: &str| {
            format!(
                "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"30\" height=\"10\"><filter id=\"f\">\
                 <feGaussianBlur stdDeviation=\"{deviation}\"/></filter><circle cx=\"5\" cy=\"5\" r=\"2\" \
                 filter=\"url(#f)\"/></svg>"
            )
        };
        assert_eq!(
            render(blur("20000000000000000000").as_bytes()).unwrap_err(),
            Refusal::TooLarge
        );
        assert_eq!(render(blur("2").as_bytes()).unwrap().width, 30);
        let scaled = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"30\" height=\"10\"><filter id=\"f\">\
            <feGaussianBlur stdDeviation=\"900\"/></filter><g transform=\"scale(1000)\"><circle r=\"2\" \
            filter=\"url(#f)\"/></g></svg>";
        assert_eq!(render(scaled.as_bytes()).unwrap_err(), Refusal::TooLarge);

        // a few copies are an ordinary picture
        let icons = b"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"30\" height=\"10\"><defs>\
            <circle id=\"d\" cx=\"5\" cy=\"5\" r=\"4\"/></defs><use href=\"#d\"/><use href=\"#d\" x=\"10\"/>\
            <use href=\"#d\" x=\"20\"/></svg>";
        assert_eq!(render(icons).unwrap().width, 30);
    }

    /// Nothing outside the file is read: a picture it names is not drawn, a script is not run (there is nothing to
    /// run it), an external entity is refused
    #[test]
    fn nothing_outside_the_file_is_read() {
        let svg = b"<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" \
            width=\"10\" height=\"10\"><image width=\"10\" height=\"10\" xlink:href=\"file:///etc/passwd\"/>\
            <image width=\"10\" height=\"10\" href=\"https://example.com/x.png\"/><script>alert(1)</script></svg>";
        let picture = render(svg).unwrap();
        let decoded = image::load_from_memory(&picture.bytes).unwrap().to_rgba8();
        assert!(decoded.pixels().all(|pixel| pixel.0[3] == 0));
        let entity = b"<?xml version=\"1.0\"?><!DOCTYPE svg [<!ENTITY x SYSTEM \"file:///etc/passwd\">]>\
            <svg xmlns=\"http://www.w3.org/2000/svg\" width=\"10\" height=\"10\"><text>&x;</text></svg>";
        assert!(describe(entity).is_err());
    }

    #[test]
    fn a_shape_out_at_millions_of_pixels_is_refused_before_it_is_drawn() {
        // found by fuzzing: a path out at -6.7e15 broke tiny-skia's scanning
        let far = b"<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"1 6 30 11\">\
            <path d=\"M0 0L30 10Q15 0 6-6666666666666660 1010Q15 0 0 10z\" stroke=\"green\"/></svg>";
        assert_eq!(render(far).err(), Some(Refusal::TooLarge));
        let found = include_bytes!("../../../fuzz/corpus/preview_svg/crash-db2a1c38e904cd30309b60c285393183ed5547f7");
        assert!(render(found).is_err());
        // a shape that goes some way past the picture's edge is drawn
        let past = b"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"40\" height=\"20\">\
            <path d=\"M-500 -500L540 520\" stroke=\"green\" stroke-width=\"4\"/></svg>";
        assert!(render(past).is_ok());
    }
}
