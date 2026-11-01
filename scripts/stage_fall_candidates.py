#!/usr/bin/env python3
"""Download (never approve) Higgsfield generation candidates for private QA artifacts.

Usage: python3 scripts/stage_fall_candidates.py
Input: assets/collectibles/seasons/fall-2026/candidates.json
Output: _build/fall-candidates/*, not committed to the repository.
"""
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import Request, urlopen
import json, io, hashlib
from PIL import Image, ImageOps, ImageDraw, ImageFont

BASE = Path("assets/collectibles/seasons/fall-2026")
OUT = Path("_build/fall-candidates")
OUT.mkdir(parents=True, exist_ok=True)
manifest = json.loads((BASE/"candidates.json").read_text())
records = manifest["candidates"]
ids = {x["id"] for x in records}
if len(records) != 30 or len(ids) != 30:
    raise SystemExit("Exactly 30 distinct image candidates required for review artifact")

thumbs = []
summary = []
for record in sorted(records, key=lambda x:x["rank"]):
    url = record["result_url"]
    parts = urlparse(url)
    if parts.scheme != "https" or parts.hostname != "d8j0ntlcm91z4.cloudfront.net":
        raise SystemExit("Unapproved image origin for " + record["id"])
    req = Request(url, headers={"User-Agent": "Arooma-QA/1.0"})
    with urlopen(req, timeout=45) as resp:
        data = resp.read(25_000_001)
    if len(data) > 25_000_000 or len(data) < 20_000:
        raise SystemExit("Invalid input byte length " + record["id"])
    try:
        source = Image.open(io.BytesIO(data))
        source.load()
        image = ImageOps.exif_transpose(source).convert("RGB")
    except Exception as exc:
        raise SystemExit("Could not decode " + record["id"]) from exc
    if image.width < 1000 or image.height < 1300:
        raise SystemExit("Not enough actual pixels " + record["id"])
    # Preserve complete etched frame by letterboxing minimally to the 59:86 delivery ratio.
    cw,ch = 1180,1720
    target=Image.new("RGB",(cw,ch),(18,17,24))
    shrunk=ImageOps.contain(image,(cw,ch), Image.Resampling.LANCZOS)
    x=(cw-shrunk.width)//2; y=(ch-shrunk.height)//2
    target.paste(shrunk,(x,y))
    dst=OUT/(record["id"]+".jpg")
    target.save(dst,"JPEG",quality=92,optimize=True,subsampling=0)
    thumbs.append((record, target.resize((236,344),Image.Resampling.LANCZOS)))
    summary.append({"id":record["id"],"rank":record["rank"],"source_dimensions":[image.width,image.height],
                    "output_dimensions":[cw,ch],"sha256":hashlib.sha256(dst.read_bytes()).hexdigest(),
                    "generation_job":record["job_id"],"review_status":"unreviewed"})

cols=5
cell_w=252;cell_h=392
sheet=Image.new("RGB",(cols*cell_w, 6*cell_h),(14,13,19))
draw=ImageDraw.Draw(sheet)
for idx,(record,thumbnail) in enumerate(thumbs):
    left=(idx%cols)*cell_w+8;top=(idx//cols)*cell_h+8
    sheet.paste(thumbnail,(left,top))
    draw.text((left,top+350),f'{record["rank"]:02}. {record["id"][:26]}',fill=(230,218,188))
sheet.save(OUT/"contact-sheet.jpg",quality=91,optimize=True)
(OUT/"review-metadata.json").write_text(json.dumps(summary,indent=2)+"\n")
print(f"Staged {len(records)} candidates and QA contact sheet. No release approval granted.")
