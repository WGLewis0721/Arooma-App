#!/usr/bin/env python3
"""Build original botanical glyph image sets for the owner's Season Compass UI.

Strict 5x4 atlas, 20 cells, deterministic mapping; do not use remote images
at app runtime. CI checks in the resulting imagesets with the app source.
"""
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import Request, urlopen
from PIL import Image, ImageOps
import io
import json

source = Path("assets/insights/season-compass/atlas-source.json")
data = json.loads(source.read_text())
expected = [
    "apple", "lavender", "lime", "violet", "jasmine",
    "geranium", "vanilla", "sandalwood", "patchouli", "bergamot",
    "cardamom", "orange-blossom", "tobacco", "cedar", "cinnamon",
    "iris", "rose", "lemon", "pink-pepper", "honey",
]
if data.get("layout") != "5x4" or data.get("cells") != expected:
    raise SystemExit("Ingredient icon atlas grid and mapping differ from source contract")
url = data["url"]
p = urlparse(url)
if p.scheme != "https" or p.hostname != "d8j0ntlcm91z4.cloudfront.net":
    raise SystemExit("Icon atlas must come from the specified generated-art origin")
with urlopen(Request(url, headers={"User-Agent": "Arooma-Assets/1.0"}), timeout=60) as response:
    raw = response.read(25_000_001)
if len(raw) >= 25_000_000:
    raise SystemExit("Atlas exceeds 25MB limit")
image = ImageOps.exif_transpose(Image.open(io.BytesIO(raw))).convert("RGB")
w, h = image.size
if w < 1000 or h < 700:
    raise SystemExit(f"Atlas too small: {w}x{h}")
out = Path("ios/AroomaNative/Assets.xcassets")
out.mkdir(parents=True, exist_ok=True)
for n, name in enumerate(expected):
    col, row = n % 5, n // 5
    box = (round(w*col/5), round(h*row/4), round(w*(col+1)/5), round(h*(row+1)/4))
    cell = image.crop(box)
    # Retain a generous safe area: no false cutouts, invented transparency or
    # uncontrolled cropping of ingredients that reach close to cell edges.
    corner = cell.getpixel((3, 3))
    icon = ImageOps.pad(cell, (176,176), method=Image.Resampling.LANCZOS,
                        color=corner, centering=(0.5,0.5))
    folder = out / ("insight-" + name + ".imageset")
    folder.mkdir(parents=True, exist_ok=True)
    icon.save(folder/"ingredient.png", optimize=True)
    (folder/"Contents.json").write_text(json.dumps({
        "images":[{"filename":"ingredient.png","idiom":"universal"}],
        "info":{"author":"xcode","version":1}
    },indent=2)+"\n")
assert len(list(out.glob("insight-*.imageset")))==20
print("Staged 20/20 original illustrated botanical ingredients in Xcode's native asset catalog")
