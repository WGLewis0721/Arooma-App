#!/usr/bin/env python3
"""Package already-downloaded Autumn Archive *proofs* into a transient TestFlight checkout.

Never run as part of public App Store packaging. This script does not set artRightsCleared
or override approved images; it merely enables *internal* visual QA on a user's iPhone.
"""
from pathlib import Path
import json, shutil
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
print("Prepared 30 on-device, offline collectible proof assets for internal TestFlight only")
