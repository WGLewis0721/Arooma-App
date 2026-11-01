# Autumn Archive | Production prompt and per-fragrance brief

> Part of the [Arooma design map](../../../../docs/design/README.md). Applies to **new 59:86 card fronts** only. The owner-approved MYSLF card and locked [Archive Foil v3 direction](../../../../docs/design/brand/COLLECTIBLE_CARD_ART_DIRECTION.md) are quality references. Commercial rights review is mandatory.

## Required inputs

Read the selected item in [catalog.json](catalog.json):
- **Exact house, product name and variant:** verify against primary source, not model memory.
- **Product reference image(s):** brand-supplied or independently photographed, with rights/provenance recorded, showing the exact bottle/cap/label. The reference can be used for private evaluation without implying redistribution clearance.
- **Verified note facts:** where unclear, omit note labels rather than fabricate them.
- **Unique scene brief:** each item's sceneBrief is a proposed artistic theme, not automatically a factual note claim.

## Master prompt template

Create **one complete, polished Arooma collectible fragrance card front**, straight-on 59:86 portrait, with all four corners visible and ample print-safe edges. Match the aesthetic quality and restraint of the owner-approved YSL MYSLF art: visually accurate single bottle centered as the principal hero, intricately detailed cinematic fragrance environment, photographic ingredient and material textures, carefully designed editorial title hierarchy, restrained metallic etched border with violet/cyan/copper iridescent accents, and elegant Arooma attribution. Do not create an app UI, mockup, poster sheet, frame-only design, or an unapproved official endorsement.

**Exact product:** [HOUSE] [NAME] [VERIFIED_VARIANT]. Use the attached permitted photographic reference to faithfully represent the real container's silhouette, cap, label placement, glass/body color, and all visibly legible marks. Do not redesign, idealize, invent hidden packaging, change the flanker, produce more than one product, or add a cap not shown in the reference. Preserve exact product identity above all stylistic flourishes.

**Art direction:** [ONE_PRODUCT_SCENE_BRIEF]. Employ an atmospheric luxury still life with visually grounded materials that support the verified fragrance character and do not distract from the bottle. Each scene must have an original composition, not a template duplicated across brands.

**Typography:** Accurate, independently verified house, fragrance name and concentration at the top. Include up to 3-4 **verified** top-note labels only if supplied. No speculative notes, false maker claims, fabricated awards, rarity, potency tier, rarity odds, pricing, combat/game UI, or lengthy borrowed campaign text.

**Card finish:** razor-sharp studio hero, precise physical shadows and reflections, beautifully legible text, narrow etched holographic outer border, balanced negative space, luxury serif typography and quiet "AROOMA • FRAGRANCE COLLECTION" footer. The frame is decorative, never a clipping crop. The image must still look like a premium collectible when displayed at 250pt width on an iPhone.

**Negative constraints:** no hand, person, bathroom or bedroom background; no AI-mutated logo or spelling, inaccurate brand lettering, bottle redesign, invented cap, duplicate bottle, generic stock scent splash, low-contrast captions, oversized plastic rainbow trim or faux official seal.

## Output and review

- Generate 2-4 candidates per product as a production budget allowance. Compare bottle fidelity, legibility, artistry and composition. Reject misses rather than treating every generation as a deliverable.
- Keep the lossless master at the path from catalog.json. Generate a separately optimized, color-managed app copy at its frontAppAsset path only after review.
- The release manifest must be updated to status=approved **only after** product fact verification, legal asset review and an accepted artwork proof. The existing sample approved-design assets do not establish commercial licenses.
- Do not imply an image has actually been generated, reviewed or distributed until the file exists and the build is verified. Run the release gate: `node scripts/check-fall-archive.mjs --release`.
- Existing foil is primarily an interactive native material. Static decorative foil in the generated art should remain understated to avoid double holo overlay.
