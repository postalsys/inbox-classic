"""Writes the test files of pe-preview (tests/files.rs): ordinary PDF files from ReportLab and pikepdf (qpdf), and
files built to hang, blow up or crash a renderer, from the spike of docs/attachment-preview-plan.md. All of them are
made here, none is a real person's file.

    python3 -m venv venv && venv/bin/pip install reportlab pikepdf
    venv/bin/python -I generate.py .

HEIC and AVIF come from macOS `sips`; elsewhere they are left as they are."""
import os
import shutil
import struct
import subprocess
import sys
import zlib

import pikepdf
from reportlab.lib.pagesizes import A4, letter
from reportlab.pdfgen import canvas

out = sys.argv[1]


def p(name):
    return os.path.join(out, name)


def write(name, data):
    with open(p(name), "wb") as f:
        f.write(data)


# --- ordinary files ---

c = canvas.Canvas(p("invoice.pdf"), pagesize=A4)
c.setTitle("Invoice 2026-116")
c.setFont("Helvetica-Bold", 22)
c.drawString(60, 780, "INVOICE 2026-116")
c.setFont("Helvetica", 11)
for i, line in enumerate(["Acme Widgets Ltd", "12 Example Street", "Tallinn, Estonia", "", "Bill to: Jane Doe"]):
    c.drawString(60, 740 - i * 16, line)
c.line(60, 640, 535, 640)
for i, (item, qty, price) in enumerate([("Widget, blue", 4, "48.00"), ("Widget, red", 1, "30.00"), ("Shipping", 1, "5.90")]):
    c.drawString(60, 620 - i * 18, item)
    c.drawRightString(400, 620 - i * 18, str(qty))
    c.drawRightString(535, 620 - i * 18, price + " EUR")
c.setFont("Times-Bold", 13)
c.drawRightString(535, 540, "Total 83.90 EUR")
c.showPage()
c.save()

c = canvas.Canvas(p("letter-two-pages.pdf"), pagesize=letter)
for page in range(2):
    c.setFont("Times-Roman", 12)
    for i in range(40):
        c.drawString(72, 720 - i * 16, f"Page {page + 1}, line {i + 1}: the quick brown fox jumps over the lazy dog.")
    c.showPage()
c.save()

c = canvas.Canvas(p("receipt-roll.pdf"), pagesize=(226, 2400))
c.setFont("Courier", 9)
for i in range(140):
    c.drawString(10, 2380 - i * 17, f"{i + 1:3d} ITEM {'#' * (i % 10)}  {i * 1.1:6.2f}")
c.showPage()
c.save()

c = canvas.Canvas(p("manual-40-pages.pdf"), pagesize=A4)
c.setTitle("Manual")
for page in range(40):
    c.setFont("Helvetica", 14)
    c.drawString(72, 760, f"Chapter {page // 20 + 1}, page {page + 1}")
    c.showPage()
c.save()

with pikepdf.open(p("invoice.pdf")) as pdf:
    pdf.save(p("encrypted-empty-password.pdf"), encryption=pikepdf.Encryption(owner="owner-secret", user="", R=6))
with pikepdf.open(p("invoice.pdf")) as pdf:
    pdf.save(p("encrypted-rc4-empty-password.pdf"), encryption=pikepdf.Encryption(owner="o", user="", R=3, aes=False, metadata=False))
with pikepdf.open(p("invoice.pdf")) as pdf:
    pdf.save(p("encrypted-password.pdf"), encryption=pikepdf.Encryption(owner="owner", user="open-me", R=6))
with open(p("invoice.pdf"), "rb") as f:
    data = f.read()
write("truncated.pdf", data[: len(data) * 2 // 3])

if shutil.which("sips"):
    # a 64 by 48 picture as HEIC and AVIF: no preview, a tile
    png = p("small.png")
    raw = b"".join(b"\0" + b"".join(bytes([x * 4 % 256, y * 5 % 256, 128]) for x in range(64)) for y in range(48))
    ihdr = struct.pack(">IIBBBBB", 64, 48, 8, 2, 0, 0, 0)

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)

    write("small.png", b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))
    for fmt in ("heic", "avif"):
        subprocess.run(["sips", "-s", "format", fmt, png, "--out", p("photo." + fmt)], check=True, capture_output=True)
    os.remove(png)


# --- hostile files ---

def pdf(objects, root=1):
    """A PDF with a correct xref table from a list of object bodies, numbered from 1"""
    body = b"%PDF-1.7\n%\xe2\xe3\xcf\xd3\n"
    offsets = []
    for i, obj in enumerate(objects, start=1):
        offsets.append(len(body))
        body += b"%d 0 obj\n" % i + obj + b"\nendobj\n"
    xref = len(body)
    body += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objects) + 1)
    for off in offsets:
        body += b"%010d 00000 n \n" % off
    body += b"trailer\n<< /Size %d /Root %d 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (len(objects) + 1, root, xref)
    return body


def stream(data, extra=b"", compress=True):
    if compress:
        data = zlib.compress(data, 9)
        extra += b" /Filter /FlateDecode"
    return b"<< /Length %d%s >>\nstream\n" % (len(data), extra) + data + b"\nendstream"


def page(content, mediabox=b"[0 0 595 842]", resources=b"<< >>"):
    return [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox " + mediabox + b" /Resources " + resources + b" /Contents 4 0 R >>",
        content,
    ]


def zeros(size, fill=b"\0"):
    c = zlib.compressobj(9)
    chunk = fill * (1 << 24)
    parts = []
    while size > 0:
        n = min(len(chunk), size)
        parts.append(c.compress(chunk[:n]))
        size -= n
    return b"".join(parts) + c.flush()


# a content stream that inflates to 256 MB of spaces
data = zeros(256 << 20, b" ")
write("flate-bomb.pdf", pdf(page(b"<< /Length %d /Filter /FlateDecode >>\nstream\n" % len(data) + data + b"\nendstream")))

# a content stream flate2 refuses but hayro's lenient decoder reads: a first code that refers to before the start
# (skipped), an empty stored block, then raw deflate of 256 MB of spaces
def bad_reference_prefix():
    bits = []

    def put(value, count, msb_first):
        for i in range(count):
            bits.append((value >> (count - 1 - i if msb_first else i)) & 1)

    put(0, 1, False)
    put(1, 2, False)
    put(1, 7, True)
    put(0, 5, True)
    put(0, 7, True)
    put(0, 1, False)
    put(0, 2, False)
    out = bytearray()
    for i in range(0, len(bits), 8):
        out.append(sum(bit << j for j, bit in enumerate(bits[i : i + 8])))
    return bytes(out) + b"\0\0\xff\xff"


raw = zlib.compressobj(9, zlib.DEFLATED, -15)
spaces = b" " * (1 << 24)
data = bad_reference_prefix() + b"".join(raw.compress(spaces) for _ in range(16)) + raw.flush()
write("lenient-flate-bomb.pdf", pdf(page(b"<< /Length %d /Filter /FlateDecode >>\nstream\n" % len(data) + data + b"\nendstream")))

# an inline picture of 20,000 by 20,000 gray whose Flate data inflates to 400 MB
inline = zeros(20000 * 20000)
assert b"EI" not in inline
content = b"q 100 0 0 100 0 0 cm BI /W 20000 /H 20000 /CS /G /BPC 8 /F /Fl ID " + inline + b" EI Q"
write("inline-image-bomb.pdf", pdf(page(stream(content))))


# pictures whose codec says a size far larger than their dictionary does
def picture_page(name, image_dict, data):
    objs = page(stream(b"q 595 0 0 842 0 0 cm /Im1 Do Q"), resources=b"<< /XObject << /Im1 5 0 R >> >>")
    objs.append(b"<< /Type /XObject /Subtype /Image " + image_dict + b" /Length %d >>\nstream\n" % len(data) + data + b"\nendstream")
    write(name, pdf(objs))


# CCITT: Columns 60,000 by the Height of 20,000 (the decoder sizes its rows by Columns)
picture_page("ccitt-columns.pdf", b"/Width 10 /Height 20000 /BitsPerComponent 1 /ColorSpace /DeviceGray /Filter /CCITTFaxDecode /DecodeParms << /K -1 /Columns 60000 >>", b"\0" * 64)
# JPEG 2000: the codestream's SIZ says 60,000 by 60,000
siz = b"\xff\x4f\xff\x51\x00\x29\x00\x00" + b"".join(struct.pack(">I", v) for v in (60000, 60000, 0, 0, 60000, 60000, 0, 0)) + struct.pack(">H", 3) + b"\x07\x01\x01" * 3
picture_page("jpx-siz.pdf", b"/Width 10 /Height 10 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /JPXDecode", siz + b"\xff\xd9")
# JBIG2: the page information says 65,000 by 65,000
info = b"\0\0\0\0\x30\x00\x01\0\0\0\x13" + struct.pack(">II", 65000, 65000) + b"\0" * 11
picture_page("jbig2-page.pdf", b"/Width 10 /Height 10 /ColorSpace /DeviceGray /BitsPerComponent 1 /Filter /JBIG2Decode", info)

# a picture XObject that says 60,000 by 60,000 pixels of RGB, its data a short Flate stream
img = zeros(1 << 16)
objs = page(stream(b"q 595 0 0 842 0 0 cm /Im1 Do Q"), resources=b"<< /XObject << /Im1 5 0 R >> >>")
objs.append(
    b"<< /Type /XObject /Subtype /Image /Width 60000 /Height 60000 /ColorSpace /DeviceRGB /BitsPerComponent 8 "
    b"/Filter /FlateDecode /Length %d >>\nstream\n" % len(img) + img + b"\nendstream"
)
write("image-60000.pdf", pdf(objs))

# 12 MB of path: hayro would keep it all (about 50 bytes a byte)
write("path-bomb.pdf", pdf(page(stream(b"0 0 m " + b"100 100 l 0 0 l " * 750_000 + b"S"))))

# arrays nested 200,000 deep in the content stream
write("deep-content.pdf", pdf(page(stream(b"[" * 200000 + b"]" * 200000 + b" pop"))))

# a form XObject that draws itself
objs = page(stream(b"/F1 Do"), resources=b"<< /XObject << /F1 5 0 R >> >>")
objs.append(stream(b"/F1 Do", b" /Type /XObject /Subtype /Form /BBox [0 0 100 100] /Resources << /XObject << /F1 5 0 R >> >>", compress=False))
write("xobject-self.pdf", pdf(objs))

# forms that each draw the next twice: 2^40 draws without a cycle (hayro hangs on it, growing)
objs = page(stream(b"/F0 Do"), resources=b"<< /XObject << /F0 5 0 R >> >>")
for i in range(40):
    if i == 39:
        body, res = b"0 0 m 1 1 l S", b"<< >>"
    else:
        body, res = b"/Fn Do /Fn Do", b"<< /XObject << /Fn %d 0 R >> >>" % (6 + i)
    objs.append(stream(body, b" /Type /XObject /Subtype /Form /BBox [0 0 100 100] /Resources " + res, compress=False))
write("xobject-laughs.pdf", pdf(objs))

# a page tree whose node is its own kid
objs = [
    b"<< /Type /Catalog /Pages 2 0 R >>",
    b"<< /Type /Pages /Kids [2 0 R 3 0 R] /Count 2 >>",
    b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R >>",
    stream(b"0 0 m 100 100 l S"),
]
write("page-tree-cycle.pdf", pdf(objs))

write("mediabox-huge.pdf", pdf(page(stream(b"0 0 m 1 1 l S"), mediabox=b"[0 0 1e30 1e30]")))
write("mediabox-thread.pdf", pdf(page(stream(b"0 0 m 1 10000 l S"), mediabox=b"[0 0 1 14400]")))

# JavaScript on open, a launch action and a link: the picture shows none of them
objs = [
    b"<< /Type /Catalog /Pages 2 0 R /OpenAction 5 0 R /AA << /WC 6 0 R >> >>",
    b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
    b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 "
    b"/BaseFont /Helvetica >> >> >> /Contents 4 0 R /Annots [7 0 R] >>",
    stream(b"BT /F1 24 Tf 72 720 Td (Scripts and actions) Tj ET"),
    b"<< /S /JavaScript /JS (app.alert\\('hello'\\);) >>",
    b"<< /S /Launch /F (cmd.exe) /Win << /F (cmd.exe) /P (/c calc) >> >>",
    b"<< /Type /Annot /Subtype /Link /Rect [72 700 300 740] /A << /S /URI /URI (https://example.com/track) >> >>",
]
write("scripts-and-actions.pdf", pdf(objs))
write("header-only.pdf", b"%PDF-1.7\n")


def png(width, height, color_type, idat, depth=8):
    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", width, height, depth, color_type, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")


write("png-100000.png", png(100000, 100000, 2, zlib.compress(b"\0" * 1000)))
write("png-16bit-16384.png", png(16384, 16384, 6, zlib.compress(b"\0" * 1000), depth=16))
write("jpeg-65000.jpg", b"\xff\xd8\xff\xc0" + struct.pack(">HBHHB", 17, 8, 65000, 65000, 3) + b"\x01\x11\x00\x02\x11\x00\x03\x11\x00\xff\xd9")
write("bmp-50000.bmp", b"BM" + struct.pack("<IHHI", 54, 0, 0, 54) + struct.pack("<IiiHHIIiiII", 40, 50000, 50000, 1, 32, 0, 0, 2835, 2835, 0, 0))
entries = [(256, 4, 1, 100000), (257, 4, 1, 100000), (258, 3, 1, 8), (259, 3, 1, 1), (262, 3, 1, 1), (273, 4, 1, 8), (277, 3, 1, 1), (278, 4, 1, 100000), (279, 4, 1, 100)]
ifd = struct.pack("<H", len(entries)) + b"".join(struct.pack("<HHII", *e) for e in entries) + b"\0\0\0\0"
write("tiff-100000.tif", b"II*\0" + struct.pack("<I", 108) + b"\0" * 100 + ifd)
print("ok")
