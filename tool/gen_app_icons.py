#!/usr/bin/env python3
"""Generate iOS + Android launcher icons from the branding source images.

Sources (branding/icon/src):
  icon_color.png      - fully composed icon: solid green bg (#2E7C4F) + light logo
  foreground.png      - light logo + decorative stars on transparent (adaptive fg)
  foreground_only.png - green logo on transparent (iOS dark appearance)

Run from the project root:  python3 tool/gen_app_icons.py
"""
import json
import os
from PIL import Image, ImageChops, ImageDraw, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "branding", "icon", "src")

COLOR = Image.open(os.path.join(SRC, "icon_color.png")).convert("RGB")
FG = Image.open(os.path.join(SRC, "foreground.png")).convert("RGBA")
DARK = Image.open(os.path.join(SRC, "foreground_only.png")).convert("RGBA")

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

# Dark appearance: transparent green logo; iOS composites it over its own
# dark system background.
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

# ------------------------------------------------------ splash (Android) -------
# Circular badge (green disc + white logo + stars) sized to 80% of the canvas
# with transparent padding, so it sits inside the launcher icon mask and renders
# as a clean circle rather than being reshaped into the device's squircle.
DISC = 922  # ~0.80 * 1152
splash = Image.new("RGBA", (1152, 1152), (0, 0, 0, 0))
splash.alpha_composite(circle_alpha(resized(COLOR, DISC)), ((1152 - DISC) // 2, (1152 - DISC) // 2))
nodpi = os.path.join(RES, "drawable-nodpi")
os.makedirs(nodpi, exist_ok=True)
splash.save(os.path.join(nodpi, "splash_icon.png"))

# ---------------------------------------------------------- launch (iOS) -------
# LaunchScreen.storyboard references a 120pt "LaunchImage"; provide a matching
# circular badge so the iOS splash shows the same icon as Android.
LAUNCH = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "LaunchImage.imageset")
os.makedirs(LAUNCH, exist_ok=True)
for scale, name in [(1, "LaunchImage.png"), (2, "LaunchImage@2x.png"), (3, "LaunchImage@3x.png")]:
    circle_alpha(resized(COLOR, 120 * scale)).save(os.path.join(LAUNCH, name))
with open(os.path.join(LAUNCH, "Contents.json"), "w") as f:
    json.dump({
        "images": [
            {"idiom": "universal", "filename": "LaunchImage.png", "scale": "1x"},
            {"idiom": "universal", "filename": "LaunchImage@2x.png", "scale": "2x"},
            {"idiom": "universal", "filename": "LaunchImage@3x.png", "scale": "3x"},
        ],
        "info": {"version": 1, "author": "xcode"},
    }, f, indent=2)

# Flutter SplashOverlay (shown briefly on iOS after the native launch screen)
# uses the same circular badge so the handoff is seamless.
circle_alpha(resized(COLOR, 512)).save(
    os.path.join(ROOT, "assets", "widget", "launch_icon.png"))

# ----------------------------------------------- notification icon (Android) ---
# Small status-bar icon: white logo silhouette only (no stars), padded. Android
# uses only the alpha channel and tints it, so RGB is irrelevant.
_nr, _ng, _nb, _na = FG.split()
_nmask = ImageChops.darker(ImageChops.darker(_nr, _ng), _nb).point(
    lambda v: 255 if v > 200 else 0)
_nlogo = Image.merge("RGBA", (_nr, _ng, _nb, ImageChops.multiply(_na, _nmask)))
_nlogo = _nlogo.crop(_nlogo.getbbox())
_nscale = int(192 * 0.76) / max(_nlogo.size)
_nlogo = _nlogo.resize(
    (round(_nlogo.size[0] * _nscale), round(_nlogo.size[1] * _nscale)), Image.LANCZOS)
notif = Image.new("RGBA", (192, 192), (0, 0, 0, 0))
notif.alpha_composite(_nlogo, ((192 - _nlogo.size[0]) // 2, (192 - _nlogo.size[1]) // 2))
notif.save(os.path.join(RES, "drawable-nodpi", "ic_notify.png"))

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

prev_d = Image.new("RGBA", (256, 256), (28, 28, 30, 255))
prev_d.alpha_composite(resized(DARK, 256))
prev_d.convert("RGB").save(os.path.join(OUT, "ios_dark_on_systembg_256.png"))

# splash badge on each splash background
for bg, tag in [((251, 251, 250), "light"), ((14, 16, 19), "dark")]:
    p = Image.new("RGBA", (1152, 1152), bg + (255,))
    p.alpha_composite(splash)
    p.convert("RGB").resize((360, 360), Image.LANCZOS).save(os.path.join(OUT, f"splash_on_{tag}.png"))

print("done; previews in", OUT)
