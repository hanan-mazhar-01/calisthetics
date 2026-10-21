#!/usr/bin/env python3
"""Makes every app icon and splash image from assets/branding/app_icon_source.png.

  python3 tool/make_app_icons.py

* iOS: the whole AppIcon set (square, no transparency: Apple rounds it) and the
  launch image (the icon with rounded corners).
* Android: the old-style launcher icons (rounded), the adaptive icon pieces
  (foreground + a rose gradient behind it) and the splash icons.
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SRC = Image.open(ROOT / "assets/branding/app_icon_source.png").convert("RGB")
RES = ROOT / "android/app/src/main/res"
IOS = ROOT / "ios/Runner/Assets.xcassets"
R = Image.LANCZOS


def square(px):
    return SRC.resize((px, px), R)


def rounded(px, radius=0.2237):
    """The icon with rounded corners and transparent outside (supersampled)."""
    s = 4
    big = SRC.resize((px * s, px * s), R).convert("RGBA")
    mask = Image.new("L", (px * s, px * s), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, px * s - 1, px * s - 1), radius=int(px * s * radius), fill=255)
    big.putalpha(mask)
    return big.resize((px, px), R)


def centred(px, content):
    """The icon at [content] of a transparent px x px canvas."""
    inner = int(px * content)
    canvas = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    canvas.paste(square(inner).convert("RGBA"), ((px - inner) // 2, (px - inner) // 2))
    return canvas


# ---- iOS app icon set -------------------------------------------------------
icons = IOS / "AppIcon.appiconset"
for e in json.loads((icons / "Contents.json").read_text())["images"]:
    w = float(e["size"].split("x")[0])
    px = round(w * int(e["scale"].rstrip("x")))
    square(px).save(icons / e["filename"], "PNG")
    print("ios", e["filename"], px)

# ---- iOS launch image (the rounded icon, 120 pt) ------------------------------
for name, px in (("LaunchImage.png", 120), ("LaunchImage@2x.png", 240), ("LaunchImage@3x.png", 360)):
    rounded(px).save(IOS / "LaunchImage.imageset" / name, "PNG")

# ---- Android old-style icons (48 dp) -----------------------------------------
for d, px in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)):
    rounded(px, 0.18).save(RES / f"mipmap-{d}/ic_launcher.png", "PNG")

# ---- Android adaptive icon: 108 dp canvas, the picture at 80 % ----------------
for d, px in (("mdpi", 108), ("hdpi", 162), ("xhdpi", 216), ("xxhdpi", 324), ("xxxhdpi", 432)):
    centred(px, 0.80).save(RES / f"mipmap-{d}/ic_launcher_foreground.png", "PNG")

# ---- Android splash icons: 120 dp (before Android 12), 288 dp canvas (12+) ------
for d, px in (("mdpi", 120), ("hdpi", 180), ("xhdpi", 240), ("xxhdpi", 360), ("xxxhdpi", 480)):
    out = RES / f"drawable-{d}"
    out.mkdir(exist_ok=True)
    rounded(px).save(out / "splash_icon.png", "PNG")
for d, scale in (("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2), ("xxhdpi", 3), ("xxxhdpi", 4)):
    px = int(288 * scale)
    canvas = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    icon = rounded(int(130 * scale))   # inside Android 12's 192 dp circle
    canvas.paste(icon, ((px - icon.width) // 2, (px - icon.height) // 2), icon)
    canvas.save(RES / f"drawable-{d}/splash_icon_v31.png", "PNG")
print("done")
