"""Writes the messages of the UI test's previews step (scripts/ui-e2e/SCENARIO.md, "Pictures and PDF files in the
message" and "Tiles, Show in Message and printing"): a photo and a three-page invoice, a twelve-page manual, and a
photo with a HEIC picture and a booking PDF that wants a password (shown as tiles). Everything is drawn here, nothing
is anyone's real file, and the output is the same on every run.

    python3 -m venv venv && venv/bin/pip install reportlab pillow
    venv/bin/python -I generate.py .
"""
import base64
import io
import math
import os
import sys

from PIL import Image, ImageDraw
from reportlab import rl_config
from reportlab.lib.pagesizes import A4
from reportlab.lib.pdfencrypt import StandardEncryption
from reportlab.pdfgen import canvas

rl_config.invariant = 1
out = sys.argv[1]


def photo():
    """A lake under mountains at sunset, 1600 by 1000"""
    width, height = 1600, 1000
    image = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(image)
    horizon = 620
    for y in range(horizon):
        t = y / horizon
        draw.line([(0, y), (width, y)], fill=(int(40 + 215 * t), int(70 + 110 * t), int(150 - 40 * t)))
    draw.ellipse([1090, 170, 1230, 310], fill=(255, 214, 120))
    for shade, base, peaks in [
        ((88, 72, 110), 640, [(0, 430), (260, 300), (520, 420), (760, 260), (1020, 410), (1300, 290), (1600, 400)]),
        ((52, 46, 78), 650, [(0, 520), (200, 450), (430, 540), (700, 430), (980, 540), (1240, 460), (1600, 540)]),
    ]:
        draw.polygon([(0, base)] + peaks + [(width, base)], fill=shade)
    for y in range(horizon, height):
        t = (y - horizon) / (height - horizon)
        draw.line([(0, y), (width, y)], fill=(int(70 - 40 * t), int(90 - 50 * t), int(130 - 60 * t)))
    for i in range(40):
        y = horizon + 12 + i * 9
        x = 1160 + int(60 * math.sin(i))
        draw.line([(x - 90 + i, y), (x + 90 - i, y)], fill=(230, 180, 110), width=2)
    buffer = io.BytesIO()
    image.save(buffer, "JPEG", quality=82, optimize=True)
    return buffer.getvalue()


def pdf(title, pages, draw_page, password=None):
    buffer = io.BytesIO()
    # a password to open it: the reading pane shows a tile in its place
    encrypt = StandardEncryption(password, ownerPassword=password) if password else None
    c = canvas.Canvas(buffer, pagesize=A4, encrypt=encrypt)
    c.setTitle(title)
    c.setAuthor("Inbox Classic UI test")
    for page in range(pages):
        draw_page(c, page, pages)
        c.showPage()
    c.save()
    return buffer.getvalue()


def invoice_page(c, page, pages):
    w, h = A4
    c.setFillColorRGB(0.12, 0.33, 0.62)
    c.rect(0, h - 90, w, 90, fill=1, stroke=0)
    c.setFillColorRGB(1, 1, 1)
    c.setFont("Helvetica-Bold", 24)
    c.drawString(50, h - 58, ["INVOICE 2026-118", "TERMS AND CONDITIONS", "DELIVERY NOTE"][page])
    c.setFillColorRGB(0, 0, 0)
    c.setFont("Helvetica", 11)
    for i, line in enumerate(["Lakeside Lodge", "4 Shore Road", "Tartu, Estonia", "", "Bill to: Test User"]):
        c.drawString(50, h - 130 - i * 16, line)
    if page == 0:
        rows = [("Room, 3 nights", "3", "120.00", "360.00"), ("Breakfast", "6", "14.00", "84.00"),
                ("Boat hire", "1", "45.00", "45.00"), ("Sauna", "2", "20.00", "40.00")]
        y = h - 260
        c.setFont("Helvetica-Bold", 11)
        for x, text in [(50, "Item"), (330, "Qty"), (400, "Price"), (480, "Total")]:
            c.drawString(x, y, text)
        c.line(50, y - 6, w - 50, y - 6)
        c.setFont("Helvetica", 11)
        for row in rows:
            y -= 24
            for x, text in zip([50, 330, 400, 480], row):
                c.drawString(x, y, text)
        c.line(50, y - 10, w - 50, y - 10)
        c.setFont("Helvetica-Bold", 13)
        c.drawString(400, y - 32, "EUR 529.00")
    else:
        c.setFont("Helvetica", 10.5)
        for i in range(22):
            c.drawString(50, h - 260 - i * 18, f"{page + 1}.{i + 1}  The lodge keeps the room for you until noon on the day of departure.")
    c.setFont("Helvetica", 9)
    c.drawString(50, 40, f"Page {page + 1} of {pages}")


def booking_page(c, page, pages):
    w, h = A4
    c.setFont("Helvetica-Bold", 20)
    c.drawString(50, h - 70, "Booking 4471")
    c.setFont("Helvetica", 11)
    c.drawString(50, h - 110, "Lakeside Lodge, 3 nights from 12 November 2026.")


def heic():
    """The start of a HEIC picture: its file type box naming the brands, then an empty media box. Nothing draws it;
    the reading pane tells the format by this header and shows a tile"""
    ftyp = b"ftyp" + b"heic" + (0).to_bytes(4, "big") + b"mif1heic"
    box = len(ftyp) + 4
    return box.to_bytes(4, "big") + ftyp + (8 + 64).to_bytes(4, "big") + b"mdat" + bytes(64)


def manual_page(c, page, pages):
    w, h = A4
    c.setFont("Helvetica-Bold", 20)
    c.drawString(50, h - 70, "Kettle K-200 manual" if page == 0 else f"Chapter {page}")
    c.setFont("Helvetica", 10.5)
    for i in range(34):
        c.drawString(50, h - 110 - i * 18, f"Step {page + 1}.{i + 1}: fill the kettle to the line, close the lid and press the switch.")
    c.setFont("Helvetica", 9)
    c.drawString(50, 40, f"Page {page + 1} of {pages}")


def attachment(name, mime, data):
    encoded = base64.encodebytes(data).decode().replace("\n", "\r\n")
    return (
        f"--b\r\nContent-Type: {mime}; name=\"{name}\"\r\nContent-Disposition: attachment; filename=\"{name}\"\r\n"
        f"Content-Transfer-Encoding: base64\r\n\r\n{encoded}"
    )


def message(subject, message_id, text, files):
    head = (
        "From: Maria Example <maria@example.com>\r\nTo: Test User <testuser@inboxclassic.test>\r\n"
        f"Subject: {subject}\r\nDate: Mon, 16 Nov 2026 10:12:00 +0000\r\nMessage-ID: <{message_id}@example.com>\r\n"
        "MIME-Version: 1.0\r\nContent-Type: multipart/mixed; boundary=b\r\n\r\n"
    )
    body = f"--b\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n{text}\r\n"
    return (head + body + "".join(attachment(*f) for f in files) + "--b--\r\n").encode()


def write(name, data):
    with open(os.path.join(out, name), "wb") as f:
        f.write(data)


write("photo-and-pdf.eml", message(
    "Photos and the invoice",
    "previews-1",
    "Hi,\r\n\r\nhere is a photo from the lake, and the lodge's invoice.\r\n\r\nMaria",
    [("lake.jpg", "image/jpeg", photo()), ("invoice-2026-118.pdf", "application/pdf", pdf("Invoice 2026-118", 3, invoice_page))],
))
write("long-pdf.eml", message(
    "The kettle's manual",
    "previews-2",
    "The manual you asked for is attached.\r\n\r\nMaria",
    [("kettle-manual.pdf", "application/pdf", pdf("Kettle K-200 manual", 12, manual_page))],
))
write("tiles.eml", message(
    "The boat trip, and the booking",
    "previews-4",
    "Hi,\r\n\r\nthe boat trip from my phone, a photo from the shore, and the booking (the password is in my other "
    "message).\r\n\r\nMaria",
    [("boat.heic", "image/heic", heic()), ("shore.jpg", "image/jpeg", photo()),
     ("booking-4471.pdf", "application/pdf", pdf("Booking 4471", 1, booking_page, password="lodge"))],
))
