"""Builds labelled before/after contact sheets from capture.sh output.
   python3 ios/Tests/compose_before_after.py <before-dir> <after-dir> <out-dir>"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

before, after, out = map(Path, sys.argv[1:4])
out.mkdir(parents=True, exist_ok=True)
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 44)
except Exception:
    font = ImageFont.load_default()
sheets = []
for a in sorted(after.glob("after-*.png")):
    key = a.name[len("after-"):]
    b = before / f"before-{key}"
    ai = Image.open(a).convert("RGB")
    bi = Image.open(b).convert("RGB") if b.exists() else Image.new("RGB", ai.size, (40, 40, 40))
    w, h = ai.size
    sheet = Image.new("RGB", (w * 2 + 60, h + 110), (18, 18, 22))
    sheet.paste(bi.resize((w, h)), (20, 90)); sheet.paste(ai, (w + 40, 90))
    d = ImageDraw.Draw(sheet)
    d.text((20, 24), "BEFORE (main)" if b.exists() else "BEFORE: not captured (no launch hook on main)", fill=(200, 200, 200), font=font)
    d.text((w + 40, 24), "AFTER (this branch)", fill=(230, 200, 140), font=font)
    target = out / f"compare-{key}"
    sheet.save(target); sheets.append(target)
    print("wrote", target)
if sheets:
    thumbs = [Image.open(s) for s in sheets]
    tw = 900; th = int(thumbs[0].height * tw / thumbs[0].width)
    grid = Image.new("RGB", (tw, th * len(thumbs)), (18, 18, 22))
    for i, t in enumerate(thumbs):
        grid.paste(t.resize((tw, th)), (0, i * th))
    grid.save(out / "before-after-overview.jpg", quality=86)
