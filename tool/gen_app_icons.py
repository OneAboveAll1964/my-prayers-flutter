#!/usr/bin/env python3
"""Generate iOS + Android launcher icons from the branding source images.

Sources (branding/icon/src):
  icon_color.png  - fully composed icon: solid green bg (#2E7C4F) + light logo
  foreground.png  - logo + decorative stars on transparent (adaptive foreground)
  icon_dark.png   - black bg + white logo (iOS dark appearance)

Run from the project root:  python3 tool/gen_app_icons.py
"""
import os
from PIL import Image, ImageOps, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "branding", "icon", "src")

COLOR = Image.open(os.path.join(SRC, "icon_color.png")).convert("RGB")
FG = Image.open(os.path.join(SRC, "foreground.png")).convert("RGBA")
DARK = Image.open(os.path.join(SRC, "icon_dark.png")).convert("RGB")

BG_RGB = (46, 124, 79)  # #2E7C4F sampled from icon_color.png


def resized(img, size):
    return img.resize((size, size), Image.LANCZOS)


# ---------------------------------------------------------------- iOS ----------
IOS = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")

ios_light = {
    "Icon-App-20x20@1x.png": 20, "Icon-App-20x20@2x.png": 40, "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29, "Icon-App-29x29@2x.png": 58, "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40, "Icon-App-40x40@2x.png": 80, "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120, "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76, "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}
for fn, sz in ios_light.items():
    resized(COLOR, sz).save(os.path.join(IOS, fn))

# Dark appearance: opaque black bg + white logo, as designed.
resized(DARK, 1024).save(os.path.join(IOS, "Icon-App-Dark-1024@1x.png"))

# Tinted appearance: grayscale (luminance) logo on transparent; iOS applies the tint.
gray = ImageOps.grayscale(FG.convert("RGB"))
tinted = Image.merge("RGBA", (gray, gray, gray, FG.getchannel("A")))
resized(tinted, 1024).save(os.path.join(IOS, "Icon-App-Tinted-1024@1x.png"))

# ------------------------------------------------------------ Android ----------
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")

# Adaptive foreground source (transparent, full 108dp artboard).
resized(FG, 1024).save(os.path.join(RES, "drawable", "ic_launcher_foreground_src.png"))


def circle_alpha(img):
    s = img.size[0]
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, s - 1, s - 1), fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


legacy = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
for d, sz in legacy.items():
    sq = resized(COLOR, sz)
    sq.save(os.path.join(RES, f"mipmap-{d}", "ic_launcher.png"))
    circle_alpha(sq).save(os.path.join(RES, f"mipmap-{d}", "ic_launcher_round.png"))

# ------------------------------------------------------------ previews ---------
# Emulate the Android adaptive render: 108dp canvas, only the central 72dp
# viewport is shown, masked to a launcher shape. Scale x4 -> 432.
OUT = "/tmp/icon_preview"
os.makedirs(OUT, exist_ok=True)
CAN = 432
VIEW = int(CAN * 72 / 108)  # 288
off = (CAN - VIEW) // 2


def compose(inset_pct):
    canvas = Image.new("RGBA", (CAN, CAN), BG_RGB + (255,))
    content = CAN - 2 * int(CAN * inset_pct)
    fg = resized(FG, content)
    canvas.alpha_composite(fg, ((CAN - content) // 2, (CAN - content) // 2))
    return canvas.crop((off, off, off + VIEW, off + VIEW))


def mask_circle(img):
    m = Image.new("L", img.size, 0)
    ImageDraw.Draw(m).ellipse((0, 0, img.size[0] - 1, img.size[1] - 1), fill=255)
    img.putalpha(m)
    return img


def mask_squircle(img):
    m = Image.new("L", img.size, 0)
    r = int(img.size[0] * 0.24)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, img.size[0] - 1, img.size[1] - 1), radius=r, fill=255)
    img.putalpha(m)
    return img


for pct, tag in [(0.0, "inset00"), (0.08, "inset08")]:
    base = compose(pct)
    mask_circle(base.copy()).save(os.path.join(OUT, f"adaptive_{tag}_circle.png"))
    mask_squircle(base.copy()).save(os.path.join(OUT, f"adaptive_{tag}_squircle.png"))

# iOS light + tinted previews
resized(COLOR, 256).save(os.path.join(OUT, "ios_light_256.png"))
prev_t = Image.new("RGBA", (256, 256), (90, 110, 200, 255))
prev_t.alpha_composite(resized(tinted, 256))
prev_t.save(os.path.join(OUT, "ios_tinted_on_blue_256.png"))

print("done; previews in", OUT)
