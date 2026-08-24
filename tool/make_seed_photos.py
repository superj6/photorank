"""Generate a fake camera roll with EXIF dates: gradients, shapes, labels,
a few bursts (shots seconds apart) and same-day groups."""
import colorsys, math, random, sys
from datetime import datetime, timedelta
import piexif
from PIL import Image, ImageDraw, ImageFont

out = sys.argv[1]
rng = random.Random(7)
now = datetime(2026, 8, 24, 12, 0, 0)

def palette(i):
    h = (i * 0.137) % 1.0
    a = tuple(int(c * 255) for c in colorsys.hsv_to_rgb(h, 0.65, 0.95))
    b = tuple(int(c * 255) for c in colorsys.hsv_to_rgb((h + 0.4) % 1, 0.7, 0.55))
    return a, b

def render(i, label, portrait, jitter):
    w, h = (1080, 1440) if portrait else (1440, 1080)
    a, b = palette(i)
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(0, h, 4):
        t = y / h
        col = tuple(int(a[k] * (1 - t) + b[k] * t) for k in range(3))
        for yy in range(y, min(y + 4, h)):
            for x in range(w):
                px[x, yy] = col
    d = ImageDraw.Draw(img)
    r = rng.Random if False else None
    cx, cy = w // 2 + jitter * 40, h // 2 - jitter * 30
    rad = min(w, h) // 4
    d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(255, 255, 255, 40))
    d.rectangle([80, h - 260, w - 80, h - 120], fill=(0, 0, 0))
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 96)
    except OSError:
        font = ImageFont.load_default()
    d.text((110, h - 240), label, fill=(255, 255, 255), font=font)
    return img

def save(img, path, when):
    # Android's MediaProvider drops DateTimeOriginal unless OffsetTimeOriginal
    # is present (or the date is within a day of the file mtime).
    stamp = when.strftime("%Y:%m:%d %H:%M:%S")
    exif = piexif.dump({
        "0th": {piexif.ImageIFD.DateTime: stamp},
        "Exif": {
            piexif.ExifIFD.DateTimeOriginal: stamp,
            piexif.ExifIFD.DateTimeDigitized: stamp,
            piexif.ExifIFD.OffsetTimeOriginal: "+00:00",
        },
    })
    img.save(path, "JPEG", quality=82, exif=exif)

n = 0
def emit(when, label, portrait=True, jitter=0):
    global n
    n += 1
    save(render(n, label, portrait, jitter), f"{out}/IMG_{n:04d}.jpg", when)

# 1) scattered singles across 12 months
for i in range(45):
    when = now - timedelta(days=rng.randint(1, 360), hours=rng.randint(0, 12), minutes=rng.randint(0, 59))
    emit(when, f"#{i+1} {when:%b %d}", portrait=rng.random() < 0.7)

# 2) five bursts of 3–6 shots, 2–4 s apart
for bnum in range(5):
    base = now - timedelta(days=rng.randint(2, 300), hours=rng.randint(0, 10))
    size = rng.choice([3, 4, 5, 6])
    t = base
    for k in range(size):
        emit(t, f"burst {bnum+1}.{k+1}", portrait=True, jitter=k)
        t += timedelta(seconds=rng.randint(2, 4))

# 3) three "trip days" with 6–8 shots spread over the day
for trip in range(3):
    day = now - timedelta(days=rng.randint(20, 330))
    day = day.replace(hour=9, minute=0)
    for k in range(rng.randint(6, 8)):
        emit(day + timedelta(minutes=rng.randint(0, 540)), f"trip {trip+1} · {day:%b %d}", portrait=rng.random() < 0.5)

print(n, "photos written to", out)
