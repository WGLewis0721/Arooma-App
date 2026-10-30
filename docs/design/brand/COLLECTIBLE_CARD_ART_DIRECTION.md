# Arooma Archive Foil v2 | Master art-direction specification

> Part of the Arooma design brain. Start at [../README.md](../README.md). This governs optional, standalone collectible **artwork**, not the existing Warm Archive cabinet UI. Production methods are in [COLLECTIBLE_CARD_PRODUCTION.md](COLLECTIBLE_CARD_PRODUCTION.md).

> Summary: **Approved visual master (2026-10-30): the two-sided MIND GAMES PRODIGY dark photographic diptych with etched iridescent border, white sculptural hero bottle, diagonal studio light, layered glass/plant props, precise silver typography and a three-column note map above a wide photographic footer.** Supersedes the earlier Prada-minimal reference and both the busy fantasy and plain catalog explorations. This is an art-directed collectible, not a generic prompt style.

**Version:** 2.0 | **Status:** owner-approved *visual direction*; actual product copy and image rights separately checked. **Reference:** the owner's explicitly approved final Prodigy front/back image in the 2026-10-30 ChatGPT conversation. A low-resolution schematic is available in [../../assets/collectibles/templates/](../../assets/collectibles/templates/). The approved raster itself is not embedded in this public repository; keep that reference attached to every image-production task.

## 1. North star and rejection boundary

**Make a fragrance feel like a physical collector's edition:** premium perfume campaign photography framed as a rare foil trading card. The viewer sees, in order: authentic bottle, fragrance identity, carefully staged atmosphere, collectible finish. The reverse rewards inspection with three verified note groupings, brief editorial writing, metadata and a continuation photograph.

**Keep:** grounded still-life set, strong chiaroscuro/diagonal key light, 1-3 tactile glass/botanical props, shallow depth, clean recognizable bottle anatomy, confident typesetting, rich dark shadows, broken-line etched border with localized cyan/purple/rose-gold diffraction, physical print surface.

**Reject both ends:** (A) a plain photo in a rectangle with routine retail UI; (B) ornamental fantasy poster, gold filigree, magical particles, over-rendered CGI bottle, flowers erupting from the nozzle, impossible liquids, glitter everywhere, neon glows, illegible microtype. The owner's latest approved **Prodigy diptych**, not any preceding concept, is the aesthetic reference.

Modern Yu-Gi-Oh cards are cited only for *visual grammar*: a hero with forward depth, an inner frame visually interrupted by art, a compact text zone, foil-as-material, and card-like handling. Do not copy franchise logos, rules, attributes, level stars, ATK/DEF, layout pixels, character art or typefaces.

## 2. Master reference: observed composition

Measurements below are design targets inferred from the **approved 1470×1070 diptych** (each displayed card approximately 700×1010), normalized into independent portrait artboards. They are **not** a production mechanical drawing or evidence of exact physical foil thickness.

| Feature | FRONT | BACK |
| --- | --- | --- |
| Master proportion | 59:86 | 59:86 |
| Main title stack | Upper 5-23%; large house, name, concentration in three rows | Upper 5-19%; house, name, concentration with rarity at upper right |
| Main subject/content | From ~23 to 88% height: still life fills edge-to-edge **inside border** | Description ~20-33%; note map ~34-63%; metadata ~64-74%; continuous photographic bottom band ~75-96% |
| Product scale | Bottle ~42-58% card width, ~53-65% height; photographic environment fills the rest | No second hero bottle; 3 equal representative image tiles with note text |
| Footer | Last ~12%: dark opaque rarity band + Arooma microlabel | Rarity can sit top right; bottom photograph and a contained footer |
| Direction | Diagonal upper-right-to-lower-left soft shaft of light; counterweight botanical/glass objects | Structured editorial grid; thumbnail still lifes + wide atmospheric image |
| Surface | Printed dark midnight charcoal; textured cool foil edge with warm metallic pin highlights | Identical trim, grain, ink and optical corner details |

**Approved signature gestures:** a recognizable white bottle in an asymmetric laboratory still life; tube/botanical glass on the left, reagent/flower element on the right, wet reflective table; sharply controlled highlights and subdued backgrounds. Border corners show tiny etched geometric detail, not baroque scrolls. On the reverse, an **ultra-rare header tag**, three horizontally arranged ingredient images, two to three description lines, a row of three facts, and a full-width secondary art strip. The images are part of the composition, not nine miniature ingredient tiles.

**Important:** The generated Prodigy reference is **visual evidence only**. Some of its note labels are not source-verified. Never carry its fragrance notes or concentration into another fragrance record without checking the exact maker's product page.

## 3. Measured artboard system

- **Each face:** 1180 × 1720 px working artboard, portrait 59:86, with artwork and trim fully contained. A pair means **two separate files**; diptych is an optional review image.
- **Review gutter:** 2-3% outside card only in review previews, never inside print art.
- **Rounded corner:** visually equivalent to 2.5-3.5% of card width. No corner cuts through a logo or text.
- **Decorative foil perimeter:** optical width ~2-3% of card width, with a 1-2 px (at 1180px canvas) calm interior rule. Iridescence lives principally along perimeter and selected intersections, never across the entire photograph.
- **Safe zones:** text ≥5% card width from outer trim, key product detail ≥4% from frame; 2 mm added print bleed beyond trim only in a separate commercial-print derivative.
- **Grids:** 12-column underlying guide; 5% left/right margins; 2% minimum gutters. Front is visually **asymmetric** despite centered bottle. Back body spans ~90% width. Three note columns equal, with 2% gaps.
- **Negative space:** at least 15-25% of imagery should carry low detail so titles and bottle silhouette stay legible; no empty-but-sterile catalog appearance.
- **Overframe:** hero bottle/props may conceal a *segment of the inner etched line* but not the outer trim, footers or text; avoid fake huge 3D protrusions.

## 4. Image-making and art direction

**Photographic character**: premium studio set build. One large soft key from upper side, a smaller colder/hotter kicker tuned to the product, contact shadows, believable specular physics, real material grain. Keep bottle labels sharp, especially embossed crests, cap seams, tassels or red plaques. Supporting notes act as material **props** and suggest the smell rather than literal illustrated explosions.

**Depth layers** (distinct Photoshop/Figma/other editor layers):
1. `SET_BG`: atmospheric set and light/shadow (not UI gradient).
2. `SET_PROPS_BACK`: plant, flower, glass or mineral forms behind the product.
3. `BOTTLE_MASTER`: real photographed or accurately composited product, clean edges, exact geometry, original label and cap.
4. `SET_PROPS_FORE`: at most 1-2 grounded accents, with occlusion and cast shadow.
5. `INNER_FRAME`: thin etched line under/behind selective subject overlap.
6. `FOIL_MASK`: isolated textured border and microglints.
7. `TYPE_LOCKED`: **deterministically typeset**, separate from AI raster.
8. `PRINT_GRAIN`: subtle paper/coating texture on top, away from small letters.

**Do not use AI to invent an entire finished card** as the only production source. Generate/retouch photographic assets, then compose with a repeatable grid, non-generative typography and a controlled foil mask. Every deliverable has a clean, editable layered source and export.

### House-specific art direction without style drift

| House/fragrance | Stage and palette | Product-specific invariants |
| --- | --- | --- |
| MIND GAMES Prodigy | Black/steel-blue experimental atelier, cool hard glass, one disciplined diagonal shaft, soft white and muted rose/green botanical cues | White chess-piece/crown-like cap, correct stepped white vessel, center label, clear lower portion; **do not** turn cap into a generic cylinder |
| Parfums de Marly Delina | Dusty blush, antique silver, rose/lychee, romantic but shadowed stone studio; charcoal ink and restrained rose/pearl foil | Pale sculpted bottle, spherical silver crested cap, distinct knotted pink tassel; keep full silhouette readable |
| Parfums de Marly Althaïr | Tobacco/cognac/vanilla-brown, warm directional amber key, black vanilla pods and mineral texture; quiet copper foil | Cognac matte bottle with correct raised horses/crest, tapered polished silver cap; no fabricated label or spray top |
| Prada Luna Rossa Ocean EDP | Deep navy marine set, cold cyan water reflections, a **single** coherent splash, precise crimson only at bottle plaque | Navy/black bottle, vertical red PRADA plaque, exposed black spray assembly and red detail; do not swap Le Parfum gradient |

**Brand adaptation is mandatory:** palette, backdrop and props may change, but typographic hierarchy, 59:86 trim, border construction, note-map logic and finish remain Arooma-consistent. Arooma is a curator, not a replacement brand.

## 5. Print finish and type system

**Foil:** use a continuous narrow border foundation with small **intermittent cyan, violet, pale gold and copper holographic interference**; one or two localized edge glints. Crisp inset metallic rule and fine hand-tooled corner angles. Holography must look like reflective material under one light source, not a rainbow gradient or neon outline. Don't make 100% of edge the same luminous saturation.

**Type:** use a *licensed* luxury display serif for house/name (e.g. a legal high-contrast serif with small caps), and a neutral UI sans for secondary labels (e.g. permitted SF/system equivalent or licensed grotesk). Maximum two families, three weights, no novelty script. Preserve intentional accents (e.g. ALTHAÏR) and exact brand spelling. House/name can be spread letterspaced in uppercase, but no hand-invented house logo.

**Type targets at 1180px export:** house approximately 62-98px (adapt to name length), fragrance line 44-72px, concentration 19-31px, paragraph 27-33px, note labels 21-25px, metadata values 30-37px, footers 17-20px. These are **optical starting points**, not a license to shrink beyond legibility. Test at 360px card width and shorten text instead of compressing.

**Panel rules:** physical ink/opaque dark band, hairlines and modest metallic numerals; no floating glass panels. Front and back share the same baseline for trim, masthead style, footer tracking, corner ornament and foil frequency.

**Arooma copy:** `ULTRA RARE` is an **invented Arooma collectible tier**. It is not a fragrance industry's award and never appears as a maker-certified claim. `AROOMA • FRAGRANCE COLLECTION` is the constant maker mark. Gender/style labels are marketing positioning, not a rule for who can wear a scent.

## 6. Product data, accuracy and ownership

Lock a **copy manifest** for every fragrance *before* image generation: exact house, name, concentration, year, marketing positioning, verified top/heart/base groupings, short description, source URLs/as-of dates, bottle reference and author. Absence of trustworthy data means omit; never fill from an AI guess, another concentration, or a previous generated card. Any numeric longevity/sillage must have independent source + timestamp and should normally stay off this tier.

For **real brands**, original user photos are preferred for private concept work. Third-party campaign stills are useful references, not cleared reusable source assets. Do not commit unlicensed photography, logos or user/private photos into this public repo. Copyright/trademark usage and distribution rights need review before shipping brand likenesses. Do not put real brands into the existing fictional-bottle demo without a separately approved implementation spec.

## 7. Production, export and QA

**Production workflow and gates:** [COLLECTIBLE_CARD_PRODUCTION.md](COLLECTIBLE_CARD_PRODUCTION.md) (source manifest, AI-only components, retouching, human layout, export profiles, prompts and fail conditions). Editable, branded-free skeletons: [front](../../assets/collectibles/templates/archive-foil-front.svg) and [back](../../assets/collectibles/templates/archive-foil-back.svg).

**Automatic reject:** (1) wrong bottle geometry or brand inscription; (2) wrong concentration or unverified notes; (3) imaginary perfume branding; (4) foil/reflections appear generated across entire image; (5) legibility fails at 360 px; (6) front/back optical mismatch; (7) border crops or text goes outside safety; (8) copied anime/card logos or game statistics; (9) project exported only as flat AI image with uneditable text; (10) claim of brand endorsement.

**Creative signoff:** the owner-approved Prodigy reference is the target. A production designer signs off individually on bottle fidelity, scene plausibility, balanced lighting, typography, foil separation, factual copy, copyright provenance and thumbnail test. No automatic acceptance based solely on a positive AI critique.

## 8. Scope boundary

This is **standalone collectible concept art**. The regular Arooma Warm Archive shelf, card UI, share image, tokens, demo bottles and local-first behavior remain governed by [BRAND_BOARD.md](BRAND_BOARD.md) and [../RULES_CARD.md](../RULES_CARD.md). Only an explicit new feature request may embed cards in the application. No code, app tokens, shipping flow or public brand assets change under this document.

**Version note:** v1 (earlier minimalist Prada-only direction) is superseded by the owner's explicitly accepted Prodigy diptych; preserve older history in [../specs/2026-10-30-collectible-card-art-direction.md](../specs/2026-10-30-collectible-card-art-direction.md).
