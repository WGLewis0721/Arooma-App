#!/usr/bin/env python3
"""Package reviewed-file-layout (but unapproved-art) Autumn Archive *proofs* into a transient TestFlight checkout.

Never run as part of public App Store packaging. This script does not set artRightsCleared
or override approved images; it merely enables *internal* visual QA on a user's iPhone.
"""
from pathlib import Path
import json, shutil
src = Path("assets/collectibles/seasons/fall-2026/proofs")
if not src.exists():
    src = Path("_build/fall-candidates")
dst = Path("ios/AroomaNative/Assets.xcassets")
manifest = json.loads(Path("assets/collectibles/seasons/fall-2026/candidates.json").read_text())
cards = manifest["candidates"]
if len(cards) != 30 or len({c["id"] for c in cards}) != 30:
    raise SystemExit("Must stage exactly 30 unique proof images")
for card in cards:
    p = src / (card["id"] + ".jpg")
    if not p.exists() or p.stat().st_size < 20_000:
        raise SystemExit("Missing proof image: " + str(p))
for card in cards:
    aset = dst / ("fall2026-" + card["id"] + ".imageset")
    aset.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src/(card["id"]+".jpg"),aset/"front.jpg")
    (aset/"Contents.json").write_text(json.dumps({
        "images":[{"filename":"front.jpg","idiom":"universal"}],
        "info":{"author":"xcode","version":1}
    },indent=2)+"\n")
# Full reverse artistry follows the exact same internal/TestFlight-only asset gate.
# Three distinct photos per fragrance; never substitute cropped front-card art.
reverse = Path("assets/collectibles/seasons/fall-2026/reverse-art")
catalog = json.loads(Path("assets/collectibles/seasons/fall-2026/catalog.json").read_text())
assert len(catalog["cards"]) == 30
expected = [(c["id"], stage) for c in catalog["cards"] for stage in ("top", "heart", "base")]
for slug, stage in expected:
    picture = reverse/(slug+"-"+stage+".jpg")
    if not picture.exists() or picture.stat().st_size < 20_000:
        raise SystemExit("Missing reverse photograph: " + str(picture))
for slug, stage in expected:
    imageset = dst/("fallnotes-"+slug+"-"+stage+".imageset")
    imageset.mkdir(parents=True, exist_ok=True)
    shutil.copy2(reverse/(slug+"-"+stage+".jpg"), imageset/"photo.jpg")
    (imageset/"Contents.json").write_text(json.dumps({
        "images":[{"filename":"photo.jpg","idiom":"universal"}],
        "info":{"author":"xcode","version":1}
    },indent=2)+"\n")
print("Prepared 30 card fronts and 90 unique stage photographs for internal TestFlight only")

