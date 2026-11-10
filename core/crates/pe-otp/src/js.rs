//! JavaScript's number parsing and rounding, and string lengths in UTF-16 code units, as the
//! features of otp-detect are computed with them.

/// `parseFloat`: the longest decimal literal at the start, after JavaScript whitespace. NaN when
/// there is none. `Infinity` is not read, as nothing here can produce it in its case.
pub fn parse_float(s: &str) -> f64 {
    let s = s.trim_start_matches(pe_jsre::is_space).as_bytes();
    let mut at = 0;
    if matches!(s.first(), Some(b'+' | b'-')) {
        at += 1;
    }
    let digits = |from: usize| s[from.min(s.len())..].iter().take_while(|b| b.is_ascii_digit()).count();
    let whole = digits(at);
    at += whole;
    let mut fraction = 0;
    if s.get(at) == Some(&b'.') {
        fraction = digits(at + 1);
        if whole > 0 || fraction > 0 {
            at += 1 + fraction;
        }
    }
    if whole == 0 && fraction == 0 {
        return f64::NAN;
    }
    if matches!(s.get(at), Some(b'e' | b'E')) {
        let sign = usize::from(matches!(s.get(at + 1), Some(b'+' | b'-')));
        let exponent = digits(at + 1 + sign);
        if exponent > 0 {
            at += 1 + sign + exponent;
        }
    }
    let literal = std::str::from_utf8(&s[..at]).unwrap_or("");
    let literal = literal.strip_prefix('+').unwrap_or(literal);
    // A trailing dot ("5.") and a missing whole part (".5") both parse in Rust too
    literal.parse().unwrap_or(f64::NAN)
}

/// `parseInt(s, 10)`
pub fn parse_int(s: &str) -> f64 {
    let s = s.trim_start_matches(pe_jsre::is_space);
    let (negative, rest) = match s.as_bytes().first() {
        Some(b'-') => (true, &s[1..]),
        Some(b'+') => (false, &s[1..]),
        _ => (false, s),
    };
    let digits = rest.bytes().take_while(u8::is_ascii_digit).count();
    if digits == 0 {
        return f64::NAN;
    }
    let value: f64 = rest[..digits].parse().unwrap_or(f64::NAN);
    if negative { -value } else { value }
}

/// `Math.round`: halves go up, towards positive infinity.
pub fn round(x: f64) -> f64 {
    let floor = x.floor();
    if x - floor >= 0.5 { floor + 1.0 } else { floor }
}

/// `Math.max(0, ...values)`: NaN if any value is.
pub fn max0(values: impl IntoIterator<Item = f64>) -> f64 {
    let mut max = 0.0f64;
    for value in values {
        if value.is_nan() {
            return f64::NAN;
        }
        if value > max {
            max = value;
        }
    }
    max
}

fn high_word(x: f64) -> i32 {
    (x.to_bits() >> 32) as i32
}

fn with_high_word(x: f64, high: i32) -> f64 {
    f64::from_bits((u64::from(high as u32) << 32) | (x.to_bits() & 0xffff_ffff))
}

/// `Math.log1p` as V8 computes it, with fdlibm's algorithm (FreeBSD s_log1p.c, V8's
/// base/ieee754.cc), which is not always correctly rounded: the platform's `ln_1p` can differ in
/// the last bit, and a feature must be the same number the model was trained on. Clang contracts
/// a multiplication and an addition in one expression into a fused multiply-add on arm64, where
/// otp-detect is trained, so those are `mul_add` here.
// The constants as fdlibm writes them, to compare with its source
#[allow(clippy::excessive_precision)]
pub fn log1p(x: f64) -> f64 {
    const LN2_HI: f64 = 6.93147180369123816490e-01;
    const LN2_LO: f64 = 1.90821492927058770002e-10;
    const TWO54: f64 = 1.80143985094819840000e+16;
    const LP1: f64 = 6.666666666666735130e-01;
    const LP2: f64 = 3.999999999940941908e-01;
    const LP3: f64 = 2.857142874366239149e-01;
    const LP4: f64 = 2.222219843214978396e-01;
    const LP5: f64 = 1.818357216161805012e-01;
    const LP6: f64 = 1.531383769920937332e-01;
    const LP7: f64 = 1.479819860511658591e-01;

    let hx = high_word(x);
    let ax = hx & 0x7fff_ffff;
    let mut k = 1;
    let mut f = 0.0;
    let mut hu = 0;
    let mut c = 0.0;
    if hx < 0x3FDA_827A {
        // 1+x < sqrt(2)+
        if ax >= 0x3ff0_0000 {
            // x <= -1.0
            return if x == -1.0 { f64::NEG_INFINITY } else { f64::NAN };
        }
        if ax < 0x3e20_0000 {
            // |x| < 2**-29
            if TWO54 + x > 0.0 && ax < 0x3c90_0000 {
                return x;
            }
            return (-(x * x)).mul_add(0.5, x);
        }
        if hx > 0 || hx <= 0xbfd2_bec4_u32 as i32 {
            // sqrt(2)/2- <= 1+x < sqrt(2)+
            k = 0;
            f = x;
            hu = 1;
        }
    }
    if hx >= 0x7ff0_0000 {
        return x + x;
    }
    if k != 0 {
        let mut u;
        if hx < 0x4340_0000 {
            u = 1.0 + x;
            hu = high_word(u);
            k = (hu >> 20) - 1023;
            // correction term
            c = if k > 0 { 1.0 - (u - x) } else { x - (u - 1.0) };
            c /= u;
        } else {
            u = x;
            hu = high_word(u);
            k = (hu >> 20) - 1023;
            c = 0.0;
        }
        hu &= 0x000f_ffff;
        if hu < 0x6a09e {
            // u ~< sqrt(2)
            u = with_high_word(u, hu | 0x3ff0_0000);
        } else {
            k += 1;
            u = with_high_word(u, hu | 0x3fe0_0000);
            hu = (0x0010_0000 - hu) >> 2;
        }
        f = u - 1.0;
    }
    let hfsq = 0.5 * f * f;
    let kf = f64::from(k);
    if hu == 0 {
        // |f| < 2**-20
        if f == 0.0 {
            if k == 0 {
                return 0.0;
            }
            c = kf.mul_add(LN2_LO, c);
            return kf.mul_add(LN2_HI, c);
        }
        let r = hfsq * (-0.666_666_666_666_666_6f64).mul_add(f, 1.0);
        if k == 0 {
            return f - r;
        }
        return kf.mul_add(LN2_HI, -((r - kf.mul_add(LN2_LO, c)) - f));
    }
    let s = f / (2.0 + f);
    let z = s * s;
    let r = z * z.mul_add(
        z.mul_add(z.mul_add(z.mul_add(z.mul_add(z.mul_add(LP7, LP6), LP5), LP4), LP3), LP2),
        LP1,
    );
    if k == 0 {
        return f - (-s).mul_add(hfsq + r, hfsq);
    }
    kf.mul_add(LN2_HI, -((hfsq - s.mul_add(hfsq + r, kf.mul_add(LN2_LO, c))) - f))
}

/// Byte offsets of a text as UTF-16 offsets, the unit every position in otp-detect is counted in.
pub struct Units {
    /// The UTF-16 offset of every byte offset, None for ASCII text where the two are the same.
    map: Option<Vec<u32>>,
}

impl Units {
    pub fn new(text: &str) -> Units {
        if text.is_ascii() {
            return Units { map: None };
        }
        let mut map = Vec::with_capacity(text.len() + 1);
        let mut units = 0u32;
        for c in text.chars() {
            for _ in 0..c.len_utf8() {
                map.push(units);
            }
            units += c.len_utf16() as u32;
        }
        map.push(units);
        Units { map: Some(map) }
    }

    /// The UTF-16 offset of a byte offset on a character boundary.
    pub fn at(&self, byte: usize) -> usize {
        match &self.map {
            None => byte,
            Some(map) => map[byte] as usize,
        }
    }
}

/// `s.slice(0, max)` in UTF-16 code units. JavaScript can cut a surrogate pair in two and keep its
/// lone first half; U+FFFD stands in for it, as it is one code unit that is no letter, digit or
/// space either.
pub fn slice_utf16(s: &str, max: usize) -> std::borrow::Cow<'_, str> {
    let cut = pe_jsre::truncate_utf16(s, max);
    if cut.len() < s.len() && pe_jsre::utf16_len(cut) < max {
        return format!("{cut}\u{FFFD}").into();
    }
    cut.into()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_like_javascript() {
        assert_eq!(parse_float("1.5px"), 1.5);
        assert_eq!(parse_float(" -.5"), -0.5);
        assert_eq!(parse_float("5."), 5.0);
        assert_eq!(parse_float("0e5x"), 0.0);
        assert_eq!(parse_float("1e"), 1.0);
        assert!(parse_float(".").is_nan());
        assert!(parse_float("-").is_nan());
        assert!(parse_float("infinity").is_nan());
        assert_eq!(parse_int("600px"), 600.0);
        assert_eq!(parse_int("+700"), 700.0);
        assert_eq!(parse_int("-3.9"), -3.0);
        assert!(parse_int("bold").is_nan());
        assert_eq!(round(2.5), 3.0);
        assert_eq!(round(-2.5), -2.0);
        assert_eq!(round(0.49999999999999994), 0.0);
    }

    #[test]
    fn slices_in_utf16_units() {
        assert_eq!(slice_utf16("ab😀c", 3), "ab\u{FFFD}");
        assert_eq!(slice_utf16("ab😀c", 4), "ab😀");
        assert_eq!(slice_utf16("abc", 5), "abc");
        let units = Units::new("a😀b");
        assert_eq!(units.at(5), 3);
    }

    #[test]
    fn log1p_is_v8s() {
        // Math.log1p of node 24 on arm64; the first five integers where it is not the platform's
        // ln_1p are among them. It matched this port for every integer up to 600000.
        for (x, expected) in [
            (0_f64, 0.0),
            (1.0, std::f64::consts::LN_2),
            (13.0, 2.639057329615259),
            (175.0, 5.170483995038151),
            (2992.0, 8.0040315078527),
            (4497.0, 8.411388132519262),
            (5855.0, 8.675222055641147),
            (43451.0, 10.67941215955364),
            (524288.0, 13.169798337985775),
            (1e-10, 9.999999999500001e-11),
            (0.5, 0.4054651081081644),
            (-0.25, -0.2876820724517809),
            (1e300, 690.7755278982137),
        ] {
            assert_eq!(log1p(x), expected, "{x}");
        }
        assert_eq!(log1p(-1.0), f64::NEG_INFINITY);
        assert!(log1p(-2.0).is_nan());
    }
}
