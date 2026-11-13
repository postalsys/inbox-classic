"""Rebuild the Gemini envelope concept as clean, grid-based SVGs for Inbox Classic."""

import math
import os
import sys

import uharfbuzz as hb
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

OUT = sys.argv[1]
FONT = sys.argv[2]

BLUE = "#4C5CC5"
CORAL = "#F8485E"
INK = "#3F3A8F"
WHITE = "#FFFFFF"


def f(v):
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return "0" if s == "-0" else s


# Envelope in local units: frame box 128 x 84, frame stroke 8, lines 7.
FW, FH, FS, LS, GAP = 128.0, 84.0, 8.0, 7.0, 6.0


def envelope(cid, white=WHITE, coral=CORAL, mono=None, detail=True):
    """Frame box at (0,0) size FW x FH. Returns SVG elements."""
    ix, iy, iw, ih = FS, FS, FW - 2 * FS, FH - 2 * FS
    cx = ix + iw / 2
    vy = iy + 0.72 * ih  # coral vertex
    dx, dy = iw / 2, vy - iy
    th = math.atan2(dy, dx)
    voff = (LS + GAP) / math.cos(th)
    wy = vy - voff  # white chevron vertex
    ext = 20.0  # extend arms past the clip
    ux, uy = math.cos(th), math.sin(th)

    def arm_pts(vx, vyy):
        return (vx - ux * (dx + ext) * 2, vyy - uy * (dx + ext) * 2), (vx, vyy), (vx + ux * (dx + ext) * 2, vyy - uy * (dx + ext) * 2)

    # bottom diagonals at 45 degrees from the bottom corners to the coral arm
    def meet(sx, sy, ddx, ddy):
        # line from (sx,sy) direction (ddx,ddy) with coral left/right arm
        # coral left arm: through (cx,vy) direction (-ux,-uy); right arm (ux,-uy)
        ax, ay = (-ux, -uy) if ddx > 0 else (ux, -uy)
        # solve s*(ddx,ddy) - t*(ax,ay) = (cx - sx, vy - sy)
        det = ddx * (-ay) - (-ax) * ddy
        s = ((cx - sx) * (-ay) - (-ax) * (vy - sy)) / det
        return sx + ddx * s, sy + ddy * s

    k = 1 / math.sqrt(2)
    bl0 = (ix - 10 * k, iy + ih + 10 * k)
    bl1 = meet(ix, iy + ih, k, -k)
    br0 = (ix + iw + 10 * k, iy + ih + 10 * k)
    br1 = meet(ix + iw, iy + ih, -k, -k)

    w = mono or white
    c = mono or coral
    o = []
    r = FS * 0.75
    frame = (
        f'<path fill="{w}" fill-rule="evenodd" d="M{f(r)} 0H{f(FW - r)}A{f(r)} {f(r)} 0 0 1 {f(FW)} {f(r)}V{f(FH - r)}'
        f"A{f(r)} {f(r)} 0 0 1 {f(FW - r)} {f(FH)}H{f(r)}A{f(r)} {f(r)} 0 0 1 0 {f(FH - r)}V{f(r)}A{f(r)} {f(r)} 0 0 1 {f(r)} 0Z"
        f'M{f(ix)} {f(iy)}V{f(iy + ih)}H{f(ix + iw)}V{f(iy)}Z"/>'
    )
    m = FS / 2  # clip into the frame, which is drawn on top, so no seam shows
    o.append(f'<clipPath id="{cid}"><rect x="{f(ix - m)}" y="{f(iy - m)}" width="{f(iw + 2 * m)}" height="{f(ih + 2 * m)}"/></clipPath>')
    o.append(f'<g clip-path="url(#{cid})" fill="none" stroke-width="{f(LS)}">')
    if detail:
        a, b, e = arm_pts(cx, wy)
        o.append(f'<path stroke="{w}" stroke-linejoin="miter" d="M{f(a[0])} {f(a[1])}L{f(b[0])} {f(b[1])}L{f(e[0])} {f(e[1])}"/>')
        o.append(f'<path stroke="{w}" d="M{f(bl0[0])} {f(bl0[1])}L{f(bl1[0])} {f(bl1[1])}M{f(br0[0])} {f(br0[1])}L{f(br1[0])} {f(br1[1])}"/>')
    a, b, e = arm_pts(cx, vy)
    o.append(f'<path stroke="{c}" stroke-linejoin="round" d="M{f(a[0])} {f(a[1])}L{f(b[0])} {f(b[1])}L{f(e[0])} {f(e[1])}"/>')
    o.append("</g>")
    o.append(frame)
    return "".join(o)


def svg(w, h, body, title):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {f(w)} {f(h)}" width="{f(w)}" height="{f(h)}">'
        f"<title>{title}</title>{body}</svg>\n"
    )


def rrect(x, y, w, h, r, fill):
    return f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(r)}" fill="{fill}"/>'


def placed(x, y, scale, inner):
    return f'<g transform="translate({f(x)} {f(y)}) scale({f(scale)})">{inner}</g>'


def write(name, text):
    p = os.path.join(OUT, name)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w") as fh:
        fh.write(text)


# 1. The mark: blue plate 144 x 100 with the envelope inset 8.
MW, MH, MP = 144.0, 100.0, 8.0
mark_body = rrect(0, 0, MW, MH, 8, BLUE) + placed(MP, MP, 1, envelope("m"))
write("svg/mark.svg", svg(MW, MH, mark_body, "Inbox Classic"))

# 2. Mono mark (one color, no plate): for symbolic icons, stamps, embossing.
write("svg/mark-mono.svg", svg(FW, FH, envelope("mm", mono="#000000", detail=False), "Inbox Classic"))


# 3. Square app icon, full bleed (Windows, Linux, web): envelope 70% of the width.
def square_icon(size, plate_x, plate_w, radius, cid):
    ew = plate_w * 0.70
    sc = ew / FW
    eh = FH * sc
    body = rrect(plate_x, plate_x, plate_w, plate_w, radius, BLUE)
    body += placed(plate_x + (plate_w - ew) / 2, plate_x + (plate_w - eh) / 2, sc, envelope(cid))
    return svg(size, size, body, "Inbox Classic")


write("svg/app-icon.svg", square_icon(1024, 0, 1024, 1024 * 0.2, "a"))
# 4. macOS: Apple's grid, 824 plate on a 1024 canvas, radius about 185.
write("svg/app-icon-macos.svg", square_icon(1024, 100, 824, 185.4, "b"))

# 5. Favicon for 16 to 48 pixels: frame and coral V only, thicker strokes.
fav = rrect(0, 0, 32, 32, 6.5, BLUE)
fw, fh, fs = 24.0, 17.0, 2.75
fx, fy = 4.0, 7.5
fav += (
    f'<rect x="{f(fx + fs / 2)}" y="{f(fy + fs / 2)}" width="{f(fw - fs)}" height="{f(fh - fs)}" rx="1" fill="none" '
    f'stroke="{WHITE}" stroke-width="{f(fs)}"/>'
)
iy = fy + fs
fav += (
    f'<clipPath id="f"><rect x="{f(fx + fs)}" y="{f(iy)}" width="{f(fw - 2 * fs)}" height="{f(fh - 2 * fs)}"/></clipPath>'
    f'<path clip-path="url(#f)" fill="none" stroke="{CORAL}" stroke-width="{f(fs)}" stroke-linejoin="round" '
    f'd="M{f(fx)} {f(iy - 2.5)}L16 {f(iy + 7.2)}L{f(fx + fw)} {f(iy - 2.5)}"/>'
)
write("svg/favicon.svg", svg(32, 32, fav, "Inbox Classic"))


# 6. Wordmark in PT Sans Bold, outlined, kerned by HarfBuzz.
def wordmark(text, fill):
    data = open(FONT, "rb").read()
    face = hb.Face(data)
    font = hb.Font(face)
    buf = hb.Buffer()
    buf.add_str(text)
    buf.guess_segment_properties()
    hb.shape(font, buf, {"kern": True, "liga": True})
    tt = TTFont(FONT)
    gs = tt.getGlyphSet()
    order = tt.getGlyphOrder()
    pen = SVGPathPen(gs)
    x = 0
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        g = order[info.codepoint]
        gs[g].draw(TransformPen(pen, (1, 0, 0, -1, x + pos.x_offset, 0)))
        x += pos.x_advance
    upm = tt["head"].unitsPerEm
    cap = tt["OS/2"].sCapHeight or 700
    return pen.getCommands(), x, upm, cap


def lockup(textfill, name):
    d, adv, upm, cap = wordmark("Inbox Classic", textfill)
    H = MH
    capH = H * 0.37  # cap height relative to the mark
    s = capH / cap
    gap = H * 0.24
    tx = MW + gap
    ty = H / 2 + capH / 2  # baseline so caps center on the mark
    W = tx + adv * s
    body = rrect(0, 0, MW, MH, 8, BLUE) + placed(MP, MP, 1, envelope("l"))
    body += f'<path fill="{textfill}" transform="translate({f(tx)} {f(ty)}) scale({s:.5f})" d="{d}"/>'
    write(name, svg(math.ceil(W), H, body, "Inbox Classic"))


lockup(INK, "svg/logo-horizontal.svg")
lockup(WHITE, "svg/logo-horizontal-on-dark.svg")
