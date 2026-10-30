# Original Arooma collectible artwork — immutable handoff

The PNG files in this folder are **exact previous card-generation outputs** transferred into the repository as binary blobs. They are not the illustrated SVG stand-ins found in `assets/collectibles/cards/`. Keep these masters unmodified and derive any optimized runtime face imagery from them.

## Approved, locked card-design originals

| Fragrance | Repo path | Pixels (diptych) | Original SHA-256 |
| --- | --- | --- | --- |
| Dior Sauvage Elixir | `approved/dior-sauvage-elixir-original-diptych.png` | 1470 × 1070 | `eb4fef3eaa37d8ffc270354d90a1e5614cb944b33b90521c2abb3cc19bfbeb7c` |
| Rasasi Hawas For Him | `approved/rasasi-hawas-for-him-original-diptych.png` | 1470 × 1070 | `77073abcba76f1173efe62daa6259cd0e34db0374d5ec186f8e65094607c1bdd` |
| YSL MYSLF Eau de Parfum | `approved/ysl-myslf-edp-original-diptych.png` | 1536 × 1024 | `ebdc1a32ba4a667f2fbe306c6acbea4be694b346f56c99b20cd91c9a12fff7ec` |

## Historical compositions (retain, not V3-approved)

| Fragrance | Repo path | Original SHA-256 | Note |
| --- | --- | --- | --- |
| MIND GAMES Prodigy | `historical/mind-games-prodigy-v2-original-diptych.png` | `f6187eb0778226b6c8ac55af1eec59d7b54f3944fadf0874ef5a79ec56465418` | Old V2 artwork includes a rarity label; don't advertise as locked Archive Foil V3 |
| Prada Luna Rossa Ocean | `historical/prada-luna-rossa-ocean-front-original.png` | `ca63cb7feac38abf6c2dadec02c39efa0004ff421882e4a70ca6e91170677c39` | Earlier front design |
| Prada Luna Rossa Ocean | `historical/prada-luna-rossa-ocean-back-original.png` | `a2a2d16592d12f1dd8c6e7ba4d5f98764ffa8c6fdcc6e758252a83bcbb74ba24` | Earlier back design |

Both cards of each approved diptych are visible side-by-side in the original file. First split at x = 50%; inspect actual edge bounds and trim only outer matte. Do not crop card boundaries, smooth away the embossed border, recompose the bottle, or redraw typography. The generated individual face resolution is around 735×1070 / 768×1024 before trimming; **do not falsely claim 1180×1720 source pixels**.

The **three V3 approved faces** are the definitive replacement for the runtime SVG sketches. Historical references can remain in the repo but should be visibly distinguished until their V3 promotion is approved.

**Use**: [`../../../AROOMA_V2_FINAL_POLISH_SPEC.md`](../../../AROOMA_V2_FINAL_POLISH_SPEC.md) for exact implementation and QA instructions.

**Rights**: These original asset files are stored for the user's design handoff. Public publication, marketing and App Store usage require image-provenance review under [`../../../docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md`](../../../docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md). The presence of an image here is not proof of third-party licensing or endorsement.