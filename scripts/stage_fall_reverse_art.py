#!/usr/bin/env python3
"""Stage 30 generated triptychs as 90 standalone photographic note strips.

Input: assets/collectibles/seasons/fall-2026/reverse-art-candidates.json
Output: assets/collectibles/seasons/fall-2026/reverse-art/{slug}-{stage}.jpg

This is internal pre-release artwork. The source candidates remain unapproved;
publishing rights and image approvals are independent from the editor-written notes.
"""
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urlparse
from PIL import Image, ImageOps
import io
import json

base=Path("assets/collectibles/seasons/fall-2026")
entries=json.loads((base/"reverse-art-candidates.json").read_text())["candidates"]
if len(entries)!=30 or len({c["id"] for c in entries})!=30: raise SystemExit("Need 30 unique candidates")
valid={c["id"] for c in json.loads((base/"catalog.json").read_text())["cards"]}
if {c["id"] for c in entries}!=valid: raise SystemExit("Candidate IDs do not match catalog")
out=base/"reverse-art"
out.mkdir(parents=True,exist_ok=True)
for entry in entries:
    url=entry["url"]
    p=urlparse(url)
    if p.scheme!="https" or p.hostname!="d8j0ntlcm91z4.cloudfront.net":
        raise SystemExit("Unapproved source origin: "+entry["id"])
    with urlopen(Request(url,headers={"User-Agent":"Arooma-Art-Review/1.0"}),timeout=60) as response:
        raw=response.read(25_000_001)
    if len(raw)>25_000_000: raise SystemExit("Oversized source: "+entry["id"])
    image=ImageOps.exif_transpose(Image.open(io.BytesIO(raw))).convert("RGB")
    width,height=image.size
    if width<950 or height<600: raise SystemExit("Undersized triptych: "+entry["id"])
    for index,stage in enumerate(("top","heart","base")):
        y0=round(index*height/3)
        y1=round((index+1)*height/3)
        band=image.crop((0,y0,width,y1))
        target=ImageOps.fit(band,(1000,390),Image.Resampling.LANCZOS,centering=(0.5,0.5))
        target.save(out/(entry["id"]+"-"+stage+".jpg"),format="JPEG",quality=88,optimize=True)
assert len(list(out.glob("*.jpg")))==90, "90 files required"
print("Staged exactly 90 distinctive TOP/HEART/BASE ingredient photographs for 30 cards")
