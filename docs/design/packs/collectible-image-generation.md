# Pack: generating collectible fragrance card images

> Part of the Arooma design brain. Start at [../README.md](../README.md). This pack is for **opt-in Archive Foil art assets only**, not ordinary cabinet cards. Governing details: [../brand/COLLECTIBLE_CARD_ART_DIRECTION.md](../brand/COLLECTIBLE_CARD_ART_DIRECTION.md).

**Use when:** a user requests holographic collectible images, front/back card compositions, or consistent GenAI fragrance-card art. For actual app screen/card work, use [shelf-change.md](shelf-change.md) and [../brand/BRAND_BOARD.md](../brand/BRAND_BOARD.md) instead. The normal Warm Archive rules still apply to the app.

## Quick brief
- **Reference order:** exact photographed bottle > same-concentration brand product page > owner-approved quiet card > modern overframe composition principles. Never use EDT or Le Parfum notes/photos to fill gaps on EDP.
- **Hierarchy:** product hero > fragrance name > concentration and tiny fictional Arooma tier > notes on back. One bottle, one atmospheric movement, 20-30% negative space.
- **Medium:** 59:86 portrait, flat, visible corners, 2-3% charcoal gutter, printed navy cardstock with thin silver/cool holographic perimeter, limited specular glints. Product is photorealistic; border never competes.
- **Type:** two faces max, strong editorial title, readable metadata. Tiny wording must be validated or rendered as deterministic text overlay.
- **Do not:** make a two-up collage when separate images are requested, create imaginary cap, paint uniform rainbow, add ornamental gold, fantasy landscapes, game elements or unsourced statistics.
- **Brand and ownership:** the user-approved real-brand exception applies only to concept collectible art. Do not put real-brand material into the public fictional demo or claim brand affiliation/rarity endorsement.

## Exact sections to read
- `brand/COLLECTIBLE_CARD_ART_DIRECTION.md#1. Source of truth and precedence` for references, original product fidelity, source mix-ups.
- `brand/COLLECTIBLE_CARD_ART_DIRECTION.md#2. Visual system` for color, lighting, card material and typography.
- `brand/COLLECTIBLE_CARD_ART_DIRECTION.md#3. Fixed canvas and composition` for precise front/back layout.
- `brand/COLLECTIBLE_CARD_ART_DIRECTION.md#4. Repeatable generation workflow` for preflight, prompt scaffold, negative prompts.
- `brand/COLLECTIBLE_CARD_ART_DIRECTION.md#5. Release checklist and rejection thresholds` for the pass/fail gate.
- `brand/COLLECTIBLE_CARD_ART_DIRECTION.md#6. Boundaries and next decisions` before adding anything to the app.

## Agent checklist
- [ ] State exact brand + version (EDT, EDP, Le Parfum are not equivalent).
- [ ] Lock product photo details, concentration-specific official note pyramid and marketing positioning.
- [ ] Keep the front bottle large and the back informational, matched in border and typography.
- [ ] Check copy for spelling, invented statistics and invented dimensions.
- [ ] Show one finished 59:86 image per requested side, not app chrome.
- [ ] Run every checkbox in section 5 and reject decorative creep.
- [ ] If proposing integration with the cabinet, open a separate spec; no changes to `index.html` under this asset task.
