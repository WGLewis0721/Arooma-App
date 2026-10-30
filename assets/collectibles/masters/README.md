# Exact Archive Foil card masters — source registry

**These are the ORIGINAL PNG files from the design sessions**, committed byte-for-byte, not 3D renders, simplified SVGs, recreated vectors, regenerated text, fake upscale or new variations.

## Approved photographic card masters (production visual authority)

| Fragrance | Exact original asset in this directory | Source pixels | SHA-256 |
| --- | --- | --- | --- |
| Dior Sauvage Elixir | [`approved/dior-sauvage-elixir-original-diptych.png`](approved/dior-sauvage-elixir-original-diptych.png) | 1470×1070 | `eb4fef3eaa37d8ffc270354d90a1e5614cb944b33b90521c2abb3cc19bfbeb7c` |
| Rasasi Hawas For Him | [`approved/rasasi-hawas-for-him-original-diptych.png`](approved/rasasi-hawas-for-him-original-diptych.png) | 1470×1070 | `77073abcba76f1173efe62daa6259cd0e34db0374d5ec186f8e65094607c1bdd` |
| YSL MYSLF Eau de Parfum | [`approved/ysl-myslf-edp-original-diptych.png`](approved/ysl-myslf-edp-original-diptych.png) | 1536×1024 | `ebdc1a32ba4a667f2fbe306c6acbea4be694b346f56c99b20cd91c9a12fff7ec` |

**Master construction:** Each original is one two-card image (left = FRONT; right = BACK) with dark external matte and narrow card-to-card gutter. Extract the two card rectangles with pixel crops, conservatively trimming only surrounding *external matte* after visual inspection. Maintain all four outer foil edges; DO NOT crop the gilded card frame or cut off corner details, text or imagery. These generated originals are NOT native 1180×1720 per face, so do not misrepresent their resolution. The 1180×1720 in the design guide is a **target source artboard**, not the resolution of these accepted files. Preserve exact originals unmodified and produce derived face images under `assets/collectibles/cards/photographic/` with provenance metadata, or display pre-cropped sources using a reliable, precisely validated inset crop. Prefer actual face image files; do not run expensive live canvas crops every time a card flips.

**Canonical UI mapping:** `CARDS.c0 → dior-sauvage-elixir`, `CARDS.c1 → rasasi-hawas-for-him`, `CARDS.c2 → ysl-myslf-edp`. Existing `assets/collectibles/cards/{dior,hawas,myslf}-*.svg` are **V2 placeholder artwork only** and MUST NOT be used as the production card visuals.

## Historical artwork, available but NOT approved as Archive Foil v3

| Fragrance | Exact source | Status |
| --- | --- | --- |
| Mind Games Prodigy | [`historical/mind-games-prodigy-original-diptych.png`](historical/mind-games-prodigy-original-diptych.png) | Earlier design with `ULTRA RARE` motif and different note-panel hierarchy. **DO NOT present as approved v3.** |
| Prada Luna Rossa Ocean | [`historical/prada-luna-rossa-ocean-front-original.png`](historical/prada-luna-rossa-ocean-front-original.png) / [`historical/prada-luna-rossa-ocean-back-original.png`](historical/prada-luna-rossa-ocean-back-original.png) | Earlier component revisions; no confirmed final paired v3 approval. **Do not substitute for approved cards.** |

The current V2 demo includes an SVG `prodigy` card; that is a placeholder and has **no approved equivalent to swap in yet**. Sol may show it as a clearly distinguished historical concept or keep it off the featured photographic deck; **do not invent a finished v3 card or present the older rarity label as acceptable**. Ask the owner only if an actual new design approval is needed to ship Prodigy.

## Content fidelity versus factual validation

A visual approval is **not** approval of AI-generated fragrance facts or claims. Use real variant-specific manufacturer descriptions to verify concentration, notes, year, marketing category. Correct metadata in the app's accessible text layer; do **not** silently re-typeset or repaint an approved PNG. Flag any conflicting printed data in a short explicit issue list for owner review.

This repository is an **independent companion**, not an endorsed fragrance-house property. All public distribution and photo provenance obey [the third-party content policy](../../../docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md). Do not turn any public reference image into a blanket claim of licensing or fair use.

**Source-of-truth layout:** [Archive Foil v3 art direction](../../../docs/design/brand/COLLECTIBLE_CARD_ART_DIRECTION.md). **Execution:** [root-level Sol Extra handoff](../../../AROOMA_V2_FINAL_POLISH_HANDOFF.md).
