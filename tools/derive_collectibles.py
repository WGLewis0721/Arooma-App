#!/usr/bin/env python3
"""Deterministically export the original collectible diptychs as individual faces.

The source pixels are split exactly at the midpoint. No resize, crop into the card,
colour correction, sharpening, or generated details are applied. The entire half is
kept, including the source matte, to protect every corner of the foil border.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/collectibles"
OUTPUT = BASE / "production"
SOURCES = {
    "dior": ("approved", "dior-sauvage-elixir-original-diptych.png", "eb4fef3eaa37d8ffc270354d90a1e5614cb944b33b90521c2abb3cc19bfbeb7c"),
    "hawas": ("approved", "rasasi-hawas-for-him-original-diptych.png", "77073abcba76f1173efe62daa6259cd0e34db0374d5ec186f8e65094607c1bdd"),
    "myslf": ("approved", "ysl-myslf-edp-original-diptych.png", "ebdc1a32ba4a667f2fbe306c6acbea4be694b346f56c99b20cd91c9a12fff7ec"),
    "prodigy": ("historical", "mind-games-prodigy-v2-original-diptych.png", "f6187eb0778226b6c8ac55af1eec59d7b54f3944fadf0874ef5a79ec56465418"),
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    manifest = {"derivation": "Exact left/right half pixel crop; WebP quality 95, method 6. No resampling or artwork changes.", "cards": {}}
    contact = Image.new("RGB", (4 * 420, 2 * 330), "#211e29")
    for column, (key, (status, filename, expected)) in enumerate(SOURCES.items()):
        source = BASE / "masters" / status / filename
        actual = digest(source)
        if actual != expected:
            raise ValueError(f"Protected source checksum changed: {source}: {actual}")
        with Image.open(source) as original:
            original.load()
            width, height = original.size
            if width % 2:
                raise ValueError(f"Odd diptych width: {source}")
            bounds = {"front": (0, 0, width // 2, height), "back": (width // 2, 0, width, height)}
            faces = {}
            folder = OUTPUT / key
            folder.mkdir(parents=True, exist_ok=True)
            for row, (face, box) in enumerate(bounds.items()):
                pixels = original.crop(box)
                target = folder / f"{face}.webp"
                pixels.save(target, format="WEBP", quality=95, method=6, exact=True)
                faces[face] = {"path": str(target.relative_to(ROOT)), "crop_px": box, "pixels": pixels.size, "sha256": digest(target)}
                thumb = ImageOps.contain(pixels.convert("RGB"), (400, 310), Image.Resampling.LANCZOS)
                contact.paste(thumb, (column * 420 + (420 - thumb.width) // 2, row * 330 + (330 - thumb.height) // 2))
        manifest["cards"][key] = {"status": status, "source": str(source.relative_to(ROOT)), "source_sha256": actual, "faces": faces}
    contact.save(OUTPUT / "contact-sheet.png", optimize=True)
    (OUTPUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
