# Archive Foil v3 | Production handbook for designers + AI agents

> Part of the Arooma design brain. Start at [../README.md](../README.md). Visual authority: [COLLECTIBLE_CARD_ART_DIRECTION.md](COLLECTIBLE_CARD_ART_DIRECTION.md). This handbook makes the owner's approved Dior Sauvage Elixir diptych with top-note names on front and no rarity badges **repeatable**; it does not implement an in-app feature.

> Summary: Treat AI as the art department for set generation, object cleanup, relighting and ingredient still lifes. Treat the designer as art director, retoucher, typographer, colorist and final print operator. Lock a product manifest, compose against fixed SVG artboards, isolate a controllable foil layer, retouch bottle markings and verify small-type, source and rights before export.


**Locked 2026-10-30 v3 overrides:** do not put “ULTRA RARE” or an equivalent rarity badge on either face. The front must contain **a source-verified visual top-note ingredient and the 3-4 source-verified top-note names** under the title. Back note-map tiles are **horizontal photo strips with text immediately to their right**, not three columns. Preserve the approved back spacing, serif italics, copper labels, and 3-field metadata row. **Never source note lists or dates from a rendered AI image.**

## 1. Job ticket (complete before prompting)

One fragrance per ticket. Copy this manifest and fill only verified fields:

```yaml
job_id: example-house-product-concentration-v01
house: "EXACT HOUSE"
fragrance: "EXACT FRAGRANCE"
concentration: "EXACT EDT / EDP / Extrait etc."
positioning: "Masc / Fem / Unisex, with source"
released: "YYYY, with source"
bottle_reference: "owner photo file + view/crop + usage permission"
brand_photo_reference: "official URL, visual reference only"
verified_top: ["..."]
verified_heart: ["..."]
verified_base: ["..."]
description: "20-30 factual editorial words, reviewed by human"
facts_source_urls: ["exact official product URL"]
facts_checked_on: "YYYY-MM-DD"
photo_rights_status: "owner supplied / licensed / unverified"
designer: "name"
reviewer: "name"
```

**Rules:** do not copy notes from the last generated card. Do not mix Eau de Toilette, Eau de Parfum, Le Parfum or Extrait versions. If a top/heart/base taxonomy is unavailable, describe the published note *set* and do not fabricate pyramid placement. The approved Dior layout reference is **visual-only**: its sample note text is not a primary source.

## 2. Working package and layer contract

Use the editable templates:
- [Front SVG](../../../assets/collectibles/templates/archive-foil-v3-front.svg)
- [Back SVG](../../../assets/collectibles/templates/archive-foil-v3-back.svg)

Files for every fragrance:
```text
arooma/<house>/<fragrance-concentration>/
  00_sources/         owner bottle, official URLs, signed rights/credits
  01_manifest/        verified-copy.yaml, revision notes
  02_generations/     raw prompts, seeds/model/date, generated photographic plates
  03_composites/      layered PSD/AFPHOTO/AI/FIG + linked images
  04_proofs/          thumb-360px, flat front/back, foil-only, side-by-side
  05_exports/         front-1180x1720.png, back-1180x1720.png, optional print package
```

Required editable layers, separately named: `BG_SET`, `REAR_PROPS`, `PRODUCT_HERO`, `FOREGROUND_PROPS`, `CONTACT_SHADOWS`, `INNER_ETCHED_LINE`, `FOIL_MASK`, `DISPLAY_TYPE`, `INFO_TYPE`, `PRINT_FINISH`, `GUIDES_NONEXPORT`. **Do not bake labels or typography into a single AI image.**

## 3. Image-generation tasks by component

**Generate plates, not finished cards**. One task per composite component allows rework without destroying good detail.

**A. Product cutout / cleanup (identity first):**
```text
Retouch this supplied photograph of the exact [HOUSE + FRAGRANCE + CONCENTRATION].
Preserve bottle geometry, seams, cap, nozzle, embossing, lettering, ornament,
glass opacity, and authentic color. Remove hands, dust, incidental scratches,
and background. Product-photography relight with one soft key and natural
reflections. No restyling, invented label, duplicate bottle, fantasy light,
new cap, or change to silhouette. Return clean centered product on neutral or
transparent background. Do not add card border or text.
```

**B. Environment plate:**
```text
Create an art-directable luxury tabletop set for [BRAND MOOD + PALETTE].
Use authentic material details: [TWO grounded materials / ingredients],
negative-space area behind main product and title, one coherent directional
studio key, believable wet/dry reflections and natural perspective. Produce
an empty set with no bottle, brand marks, typography, trading-card border,
magic effects, particle haze or floating objects. Portrait crop.
```

**C. Ingredient/prop plates:**
```text
Create a restrained photoreal editorial still-life of [VERIFIED INGREDIENT],
one object family only. Side-lit macro material with natural texture,
controlled contrast, coherent key direction with the master set.
No words, no labels, no extra ingredients and no fantasy illustration.
Output photo plate suitable for a rectangular note tile.
```

**D. Alternate foreground:** one small rose stem, glass tube, vanilla pod, or branch as warranted by note facts. Keep props behind the bottle shoulder or on table; do not obscure house marks.

**E. Border/foil is NOT image generated:** use the separated vector strokes of the SVG template or equivalent editable vectors. Hand-apply selective iridescent foil texture, two contained glints max. Never use AI rainbow as a substitute for a foil mask.

## 4. Human compositing sequence

1. **Research check:** product photo and published note set; sign the manifest. No art starts before this.
2. **Artboard setup:** exact 1180×1720 px, 59:86, two independent faces, 12-column guide and 5% safety. Place both in an aligned comparison document.
3. **Set lighting:** background plate with dark print base; establish directional key and 15-25% quiet region.
4. **Bottle extraction:** remove original photo surroundings; inspect curves, cap, label and tassel/crest at 100% and 200% zoom; preserve real product proportions.
5. **Grounding:** realistic support plane, occlusion, cast shadows and reflected color. Product must not look like it floats; no incompatible shadow directions.
6. **Props:** one botanical/wood structure and at most one accent prop in front; integrate perspective and color temperature.
7. **Inner frame and foil:** use selective etched vectors. The outer edge is sacrosanct; masked subject overlap can interrupt **only** the inner frame. Keep foil at border and micro-corners, not a lens flare across copy.
8. **Typography:** set house/name/concentration/notes/metadata/footer in the editor from manifest. Use **actual text objects** and permitted fonts. Rebuild any words generated into the image; even a recognizable bottle label must be audited.
9. **Back face:** same trim, photographic tonal range, type family, foil rhythm. Back is **not a bland spreadsheet**: three large **horizontal** editorial image strips + their adjacent stage notes + concise facts.
10. **Physical finish:** minuscule print grain, edge-foil reflection, calibrated contrast. Add final grain to art, not to primary text. No global oversharpen or overglow.
11. **Review:** overlay front/back in registration; flip horizontally for design balance review; verify both at natural size, 360px width, and 100% zoom.
12. **Export and handoff:** pack source, manifest, sources/rights, generation metadata, PNGs, review proof and any print-specific files.

## 5. Front and back copy budget

**Front:** Brand house, fragrance, concentration at upper-right, **3-4 verified top-note names** in small uppercase under the name, a recognizable top-note ingredient scene, and the small Arooma maker line. Concentration is the only strength indicator. **Do not add ULTRA RARE, performance numbers, fake statistics or price.**

**Back:**
- Header title and **exact official concentration at upper right**, no extra rarity tiers.
- Description: one short paragraph **18-32 words**, no subjective claims dressed as independent performance facts.
- Note map: **three horizontal full-width rows** (TOP, HEART, BASE); each row shows a wide ingredient photo on the left and stage heading + a concise verified note list **on the right**. The front's note list must match the TOP row. If source doesn't assign stages, use a non-pyramidal “KEY NOTES” label instead.
- Metadata: `RELEASED`, `POSITIONING`, `CONCENTRATION` in three equal columns. Use source-labeled marketing positioning. Avoid repeat information where space is needed.
- Keep three generous note photographs and the bottom metadata; **no compulsory additional bottom photo strip**, which was removed in the approved Dior layout.
- Arooma microlabel in lower safe area.
- Community ratings only if separately commissioned with published source, retrieval date and units. They are not a default card element.

## 6. Production profiles

| Profile | Export | Use |
| --- | --- | --- |
| Master review | two separate 1180×1720 PNG, 8-bit sRGB, full corner and outer border | iPhone/proof |
| Artwork retouch | layered lossless working file, linked source images, text/vector layers preserved | future changes |
| Social/preview | one side-by-side preview, charcoal gutter, no Safari/UI screenshot chrome | approval |
| Print handoff | vendor-specific PDF/TIFF or separations with embedded/licensed fonts, 300 ppi at physical size, negotiated bleed/safe/spot-foil | **only after printer confirms requirements** |

**Foil spot plate (print):** a separate vector mask explicitly named `FOIL_MASK`. Do not simulate the actual print process by simply creating a multicolored border in the composite. Printer may require specific spot color names, trapping and tolerances; confirm before release. No automatic RGB-to-CMYK conversion claimed.

## 7. Creative and technical rejection gates

**Hard fail without discussion:**
- Bottle silhouette, cap, hardware, tassel or logo inaccurate; wrong edition/concentration.
- Any false note/date or “official” ULTRA RARE claim.
- AI-written small type without deterministic proofing; letter artifacts or hallucinated brand logos.
- Card corners/trim cropped; front/back widths or perspective don't match.
- Material physically impossible: product floats, shadows go in opposed directions, foil lights every pixel, no contact reflection.
- Generic flat ad/catalog treatment, or ornate overproduced fantasy treatment.
- No editable source, no product manifest, unclear source rights for public publication.

**Visual scoring (1 to 5)**; require **≥4 in each** for a finished concept:
1. **Fidelity:** exact bottle looks manufactured, not invented.
2. **Art direction:** strongest detail around bottle, intentional diagonal light and grounded props.
3. **Collectibility:** border/foil feels printed, frame overlaps controlled, concentration carries strength without any invented rarity tag.
4. **Typography:** hierarchy is deliberate, text legible at phone width, no typographic errors.
5. **Pairing:** back looks like same object, visually rich editorial imagery, not a different template.

Use the owner's approved Dior Sauvage Elixir diptych with top-note names on front and no rarity badges as the visual calibration image, not its note text. A human art director gives the final yes/no.

## 8. First-pass brief for another agent

```text
Read docs/design/brand/COLLECTIBLE_CARD_ART_DIRECTION.md and
docs/design/brand/COLLECTIBLE_CARD_PRODUCTION.md.
The approved 2026-10-30 DIOR SAUVAGE ELIXIR final diptych is the visual master.
Work as an experienced luxury packaging/editorial designer using AI for
photographic plates only. Do not ask image AI to typeset a complete card.
Before producing pixels: verify the exact brand, concentration, bottle and
official notes; output a copy manifest and 2-sentence art direction.
Use the front/back **v3** SVG templates, preserve foil/text as editable layers,
compose a matching pair, then run the five scoring gates. Never reintroduce
the rejected flat catalog look or maximal fantasy card.
Deliver separate front/back 1180x1720 PNGs, a diptych proof, a layered source,
and a rights/copy checklist.
```

**Caveat:** documentation is not evidence that a generated card is print-ready, that image source rights are cleared, or that a particular AI tool reproduces geometry exactly. Human retouch and verification remain required.
