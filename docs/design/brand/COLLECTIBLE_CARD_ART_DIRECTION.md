# Collectible card art direction: Arooma Archive Foil

> Part of the Arooma design brain. Start at [../README.md](../README.md). This governs **optional, standalone generated collectible artwork**, not the default in-app cabinet cards. See [../specs/2026-10-30-collectible-card-art-direction.md](../specs/2026-10-30-collectible-card-art-direction.md) for scope and release decisions.

> Summary: An owner-directed, separate visual language synthesizes Prada's restrained product photography with the **composition principles**, not the IP, of modern Yu-Gi-Oh overframe cards. Use one product hero, a thin foil perimeter, calm atmospheric setting and a compact information strip. The bottle must stay accurate; commercial source photography does not transfer product-note facts between concentrations.

**Status:** Art-direction standard for collectible *concept images* only. Owner selected the third, quietest iteration on 2026-10-30. Does not authorize a new production feature, third-party brand assets in the public demo, or a global dark/gold redesign.

## 1. Source of truth and precedence

1. **Product identity:** Owner-supplied photograph of the exact owned bottle, when available. It overrides generic fragrance imagery for cap, sprayer, body, label, plaque, finish and proportions. Ask for another view if an essential detail is obscured. Never fabricate a cap.
2. **Specificity:** Brand-owned product page for the exact concentration and product code; official campaign imagery for its photographic vocabulary. Treat marketing stills as visual reference, not interchangeable note charts.
3. **Composition:** The owner's last approved quiet card iteration is the visual baseline: close bottle, ocean twilight, simple title, narrow iridescent edge, flat information hierarchy, companion reverse card. Earlier gold-heavy, highly illustrated versions are **rejected**.
4. **Card grammar:** Modern fantasy-trading-card overframe image is a *reference for composition only*: full-bleed internal illustration, foreground break across an inner border, ordered title, tiny metadata panel, optically plausible reflective finish. Do **not** copy the Yu-Gi-Oh logo, character, card template, attribute icon, level stars, rules, statistics, fonts, card number or proprietary marks.
5. **Arooma main UI:** [BRAND_BOARD.md](BRAND_BOARD.md) sections 1-3 still govern the normal cabinet. Archive Foil is an opt-in generated collectible artwork surface only. Never restyle shelf cards, share images, app icon or system UI with these dark/foil materials.

**Official Prada source ledger** (check live source for each new generation):
- [Luna Rossa Ocean EDP, Prada US](https://www.prada.com/us/en/p/product/2A1157_2HEB_F0Z99_P_ML100): grapefruit essence (top), incense (heart), vanilla bean accord (base); AmberXtreme is described as an intensity/diffusion molecule, **not an official fourth pyramid tier**.
- [Luna Rossa Ocean Le Parfum, Prada US](https://www.prada.com/us/en/p/luna-rossa-ocean-le-parfum-50ml/2A1158_2HEF_F0Z99_P_ML050): lemon essence, saffron accord, oakwood. Different fragrance and gradient bottle; do not apply to EDP.
- [Prada Luna Rossa Ocean campaign](https://www.prada.com/ch/en/pradasphere/fragrances/prada-luna-rossa/prada-luna-rossa-ocean.html): distinguishes EDT, EDP and Le Parfum. EDT is described with citrus, lavender/sage and suede/orris facets. Its captions do not define EDP.

**Evidence from four owner-shared Prada.com screenshots, 2026-10-30** (images supplied in chat, not redistributed in this public repo):
- **EDP hero:** dark navy cylindrical sprayer and broad rectangular body, continuous vertical red PRADA plaque, clean cyan-to-midnight blue background, crisp water sheets behind/around the bottle, simple left-aligned white sans heading. No fantasy particles or ornamental gold.
- **Le Parfum hero:** similar bottle family but ruby-to-navy gradient body and red-tinted highlights. This is a *different concentration*. Ocean behind is defocused, splashes stay near the base.
- **EDP ingredient photograph:** tactile weathered wood, red filaments, real citrus wedge, wet inky fluid; a few vivid natural objects anchored in shadow, asymmetrical crop.
- **Other ingredient photograph:** pink grapefruit flesh, dark vanilla pods, pale orchid, textured translucent resin, suspended water; near-macro product still life. The following page text concerns EDT, so do not treat this image as proof of EDP note taxonomy.
- **Common Prada grammar:** large areas of darkness, one sharply lit subject, editorial cropping, selective water sheen, realistic material response, disciplined negative space; no sparkle confetti, starbursts, nebulae, castles, mountains or magic lightning.

## 2. Visual system

| Element | Required treatment | Reject |
| --- | --- | --- |
| Hero | Single authentic bottle as the visual anchor; centered or slightly low; body and red plaque legible | Multiple bottles, bottle smaller than decorations, fake cap/branding |
| Color | Deep navy, near-black blue, controlled cool cyan, red only where product or fluid ribbons justify it | Uniform rainbow gradient, gold wallpaper, purple/pink fantasy haze |
| Light | One broad soft key upper-left; narrow controlled rim, cool reflected water light; deep but not crushed shadows | Every edge glowing; simultaneous contradictory light directions |
| Background | Photographic ocean at blue hour, soft horizon/sea spray and subtle water reflections; maximum one major splash gesture | Volcano/tornado, foam everywhere, fantasy moons or giant alien waves |
| Finish | 1 hairline metallic inner frame, narrow physical foil outer edge with blue-violet diffraction on **select facets** | Double/triple filigree frames, gold corners, glitter, ornamental badges |
| Text | Prada-like editorial hierarchy: prominent brand/title, restrained tracking, clear white or near-white text; foil accent on title sparingly | Glowing chunky game font, gold on every label, paragraphs squeezed into art |
| Surface | Dark printed cardstock with physically plausible edge glints and modest thickness | Plastic gloss covering every pixel, glass-panel UI treatment |
| Rarity | Small **ULTRA RARE** line; always identified as *fictional Arooma tier* outside the image metadata | Claiming Prada certifies or awards the tier |

**Frame budget:** Outer foil border approximately 1-1.5% of card width; optional inner rule 0.2-0.4%. Foil reflections should touch under 10% of visible card area. No more than two small specular points; highlights should shift with imagined metallic facets, never become a uniform rainbow veil.

**Typographic hierarchy:** Use one editorial serif *if it suits the brand identity* for the title or Prada wordmark treatment, and one neutral sans family for all metadata. Keep at most two type families, three weights and four sizes. Do not imitate copyrighted proprietary card type or invent a replacement Prada logotype; preserve legible PRADA from the photographed label. In generated proofs, overlay accurate textual layers as graphics rather than trusting generative typography for tiny text.

## 3. Fixed canvas and composition

**Standalone deliverables:** A true, flat, straight-on **front** and **back** as separate portrait images, each 59:86 aspect ratio (suggested working canvas 1180 x 1720 px, 2x export when possible), all four rounded corners visible, charcoal gutter outside 2-3%, no phone/eBay/mockup chrome, no oblique perspective.

**Front zones, normalized from upper edge:**

| Y range | Content | Requirement |
| --- | --- | --- |
| 0-12% | Brand/title and discreet EDP medallion | Top safe inset 4%; title in 1-2 lines; EDP at upper-right, no fake stars |
| 12-78% | Single product photo over atmospheric ocean | Bottle dominates, occupies roughly 65-78% card width and 48-58% full card height; sprayer/shoulders can cross *inner* frame; continuous red plaque; brightest contrast behind silhouette, **not** text |
| 78-95% | Opaque printed information strip | “EAU DE PARFUM”; secondary row “MASCULINE · 2023 · ULTRA RARE”; quiet rules and breathing space; no 3D chrome panel |
| 95-100% | Footer | “AROOMA • FRAGRANCE COLLECTION”; foil edge remains visible |

**Back zones:**

| Y range | Content | Requirement |
| --- | --- | --- |
| 0-14% | Title and concentration | Small emblem or micro-rule only; no large bottle repeated |
| 14-26% | Metadata | Type/positioning and verified release year; keep field labels concise |
| 26-62% | Fragrance map | TOP / HEART / BASE, each with ONE photographic crop or tiny icon, equal scale; no decorative ingredient sculpture |
| 62-76% | Short description | Two calm lines, 22-30 words max; text on solid dark field |
| 76-90% | Optional community data | At most 3 metrics; source name, date and rating scale required; omit if not independently verified |
| 90-100% | Fictional tier and footer | Small “ULTRA RARE” treatment and Arooma footer; ample negative space |

**Schematic:**

```text
FRONT 59:86                       BACK 59:86
┌───────────────────┐             ┌───────────────────┐
│ PRADA ...      EDP│             │ PRADA LUNA ROSSA  │
│ ───────────────── │             │ OCEAN / EDP       │
│                   │             │ TYPE  •  RELEASE  │
│    quiet ocean    │             │ ───────────────── │
│      [BOTTLE]     │             │ TOP     GRAPEFRUIT│
│   foreground      │             │ HEART      INCENSE│
│   crosses inner   │             │ BASE  VANILLA BEAN│
│   hairline only   │             │                   │
│                   │             │ SHORT DESCRIPTION │
│ ───────────────── │             │ ───────────────── │
│ EAU DE PARFUM     │             │ VERIFIED METRICS? │
│ MASCULINE · 2023  │             │ ULTRA RARE        │
│ ULTRA RARE        │             │ AROOMA ...        │
│ AROOMA ...        │             └───────────────────┘
└───────────────────┘
```

**Negative space:** Keep 20-30% of the *art region* quiet, especially near title and bottle shoulders. Waves/droplets may cross the internal illustration rule but must never cover the plaque or leave the outer card boundary. Leave 4% horizontal safe insets for text; 6% from trim for essential imagery. No cropped corner or stray exterior ribbon.

**Back note-map rules:** Start with exact brand-published top/heart/base hierarchy. For this EDP: grapefruit essence / incense / vanilla bean accord. Incense may be visually accompanied by charred wood, but do not label wood a separate official heart note. AmberXtreme belongs in a sourced explanatory note, not mislabeled as a base note. Source names must be spell-checked.

## 4. Repeatable generation workflow

1. **Identity gate:** Capture exact house, fragrance, concentration, official product URL, bottle photo, variant-specific brand palette. If conflicting screenshots exist, label each and lock the requested concentration.
2. **Copy gate:** Prepare a structured copy manifest *before* any image. Mark each field either brand sourced, community source with retrieval date, user supplied, or fictional Arooma metadata. Unknown = omit.
3. **Layout gate:** Select front/back map above. Build an empty flat wireframe with title, art box, information strip and footer. Never prompt “more epic”; ask for one deliberate compositional change.
4. **Image gate:** Generate the cleaned bottle and restrained environment. Preserve reference silhouette, sprayer and plaque. Create only one visible bottle, no invented labels.
5. **Material gate:** Add fine border, sparse diffraction and physical cardstock finish. Treat foil as material response, not a colorful lighting effect.
6. **Typography gate:** Inspect at iPhone-card size. If a word, number or brand mark is misspelled, replace by deterministic text overlay or regenerate. Do not ship guessed text.
7. **Pairing gate:** Front/back must share trim dimensions, border weight, corner radius, palette, cap-height scale and footer position. Back may be quieter than front, never busier.
8. **Human review:** Compare against the actual bottle and official reference. Reject any visible variant mix, impossible reflections, crowded panels or invented statistics.

**Prompt scaffold for image tools** (fill bracketed values; do not send template brackets literally):

```text
Create [FRONT or BACK] of one Arooma Archive Foil fragrance collectible, 59:86,
straight-on with four corners visible, charcoal margin, matte midnight-navy cardstock.
Match the supplied photo of [EXACT BOTTLE + CONCENTRATION] in silhouette,
sprayer, label, vertical plaque and body color. No imaginary cap.
Art direction: Prada editorial product photography at blue hour, restrained
water reflection and negative space; Yu-Gi-Oh-like *overframe composition only*:
the product may overlap a thin internal rule, never the outside edge.
Minimal cool blue-violet holographic foil along the 1% trim; no glitter or
rainbow wash. Quiet commercial typography with [VERIFIED MANIFEST TEXT].
Use the front/back zones in COLLECTIBLE_CARD_ART_DIRECTION.md.
Prioritize bottle accuracy and small-screen text legibility over ornament.
No game logo, characters, rules, stars, ATK/DEF, fantasy scenery, app chrome,
invented sizes, invented notes, unsourced ratings or extra copy.
```

**Negative-prompt shorthand:** baroque, ornate gold frame, filigree, galaxy, fantasy mountain, lightning, visual clutter, heavy particle spray, neon halo, rainbow overlay, duplicate bottle, deformed spray nozzle, unreadable plaque, fake cap, tiny illegible copy, excessive labels, ATK/DEF, stars, screenshot UI.

## 5. Release checklist and rejection thresholds

- [ ] Correct **concentration** and variant, matched to real bottle photo and official source.
- [ ] No mixing EDP navy bottle with Le Parfum ruby gradient, EDT ingredient copy or campaign still notes.
- [ ] Bottle ≥ primary visual prominence; red PRADA plaque crisp and unobstructed; spray assembly correct.
- [ ] One principal splash or movement, one coherent light source; negative space survives.
- [ ] Text hierarchy stays readable at roughly **360 px image width**; no more than 2 type families.
- [ ] Thin foil perimeter, zero broad-area rainbow overlay, no ornate corners; rarity feels scarce, not loud.
- [ ] Front and back are separate 59:86 images, matching edges, not a two-up collage or angled mockup.
- [ ] Front metadata includes concentration, stated marketing classification and fictional rarity only when supplied.
- [ ] Back TOP/HEART/BASE notes verified from the exact official product; AmberXtreme not mislabeled as an official base note.
- [ ] Release year cross-checked before printing; community scores cite source, date, scale and are not portrayed as Prada stats.
- [ ] Neither brand/logo from Yu-Gi-Oh nor its monster/game conventions carried into output.
- [ ] No copied vendor campaign photograph redistributed as Arooma-owned art. Check rights and permissions before shipping real-brand imagery.
- [ ] Product image still supports Arooma's neutral cabinet; this collectible treatment is **opt-in**, not applied to the main shelf.
- [ ] Failure on any of the above = regenerate/recompose, not “good enough.”
- [ ] **iPhone QA owed:** view at 375, 390, 430 CSS px, at reduced brightness and with text zoom; confirm no cropping and readable small metadata.

## 6. Boundaries and next decisions

This document describes *visual concept assets* from the owner, **not product implementation**. Real-brand bottle illustration, custom navy/foil materials and collectible-specific serif/sans type are bounded exceptions to [RULES_CARD.md](../RULES_CARD.md), Look and Boundaries. The existing fictional-house demo, original Warm Archive shelf/card treatment, share export and no-network rule remain untouched. Do not source new trademarked images or claim license. If collectible cards become an in-app user feature, first specify opt-in entry point, attribution, asset provenance/rights, local storage, accessible text equivalents, file sizes and integration with the existing ownership record. See [../DECISIONS.md](../DECISIONS.md).

The owner's approved direction is **restrained**. If a future output looks like a fantasy poster instead of a Prada editorial collectible, it fails this standard.
