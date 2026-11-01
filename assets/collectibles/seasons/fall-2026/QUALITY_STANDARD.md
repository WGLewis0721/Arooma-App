# Autumn Archive | Quantified MYSLF reference acceptance standard

> Part of [Arooma's design map](../../../../docs/design/README.md). Owner's MYSLF collectible image shared in conversation is the **quality reference**. Do not copy/upload that conversation image into a public Git repository unless the owner explicitly authorizes it.

## Baseline measurements of the supplied reference

| Property | Measured value | Notes |
| --- | --- | --- |
| Source file | 736 × 1073 pixels, 337 KB approximate | JPEG from owner's conversation; SHA-256 `5b491b9ace639a340bfdeaa056f7838e53b54482dd331dc30c509d47d051e3cc` |
| Artwork aspect | 736 / 1073 = 0.685927 | Within 0.00012 of the requested 59/86 ratio |
| Foreground card bounds | x=0..735, y≈46..1026 | Top/bottom **white margin ≈46 px each** in the reference. Not part of artwork to replicate. |
| Image dark fraction | 57.3% of interior content pixels have linear-weighted 8-bit luminance below 50 | Measured inside x0..735 and y65..1009. Lighting guidance only, not a universal filter. |
| Title/house region | x≈11..73%, y≈9..22% | Visually estimated bounding zone, not machine OCR geometry |
| Concentration region | x≈76..94%, y≈9..20% | Upper-right distinct from title |
| Product hero region | x≈39..65%, y≈23..81% | Approximate MYSLF bottle location; allow shape/size differences for new bottles |
| Supporting materials | mostly x≈8..38% and 66..91%, y≈40..80% | Materials support the hero instead of hiding it |
| Footer region | x≈10..90%, y≈83..92% | Arooma attribution centered in lower zone |
| Material signature | narrow etched, iridescent, fully closed outer edge; matte-black imagery; directional specular highlights | Qualitative behavior, not identifiable by one pixel statistic |

**Important:** the supplied image has a white outside margin and a rounded card inside it. Ship a deliberate 59:86 asset that renders neatly in the native gallery; do not mechanically reproduce the white screenshot padding. The source's 57.3% darkness is a *reference*, not a mandate to darken every bottle or obscure key label detail.

**Reference custody:** The numeric measurements and image hash are in this document; the actual MYSLF photo has **not** been uploaded to the public GitHub repository. For reproducible side-by-side review, the owner must place the exact source file in an access-controlled approved asset location and verify its hash. The hash alone cannot reconstruct the image.

## Hard rejection gates (100% must pass)

1. **Identity:** correct named fragrance, variant and concentration; unique bottle/cap/label shape compared side-by-side against a reference approved for the production workflow. No invented cap, missing lettering, generic replacement packaging, second bottle, hands or extra fingers.
2. **Text:** 100% of house/title/concentration text matches approved source fields; any displayed note verified. No fabricated note, brand claim, rarity or official affiliation.
3. **Canvas:** app artwork at least **1180 × 1720** pixels, aspect width/height within **0.005** of 59/86, with complete visible outer border. These size/ratio thresholds are Arooma release choices, not measurements of the 736×1073 source.
4. **Delivery:** 30 unique image IDs, unique content files, exactly one reviewed master per product; manifest approval flags are all true; 30 optimizations are included in Xcode image sets and load offline.
5. **Rights:** every candidate has documented art/photo provenance, and any redistributed commercial product imagery and brand treatment has completed the application's third-party content review.
6. **No blocking defects:** title and product must be readable in full-size inspection; no overlapping title, clipped artwork, AI distortions or obvious spelling/label corruption.

## Scored quality rubric (100 points)

Score against the MYSLF visual standard and the exact product's approved packaging reference **at the same display size**.

| Dimension | Weight | Pass threshold | What reviewer checks |
| --- | ---: | ---: | --- |
| Product fidelity | 30 | ≥27 | Real bottle/cap silhouette, label placement, material/color, no invented features |
| MYSLF-like composition | 20 | ≥17 | Title/concentration hierarchy, bottle hero, grounded supporting scene, balanced vertical layout |
| Premium visual finish | 20 | ≥17 | Convincing physical light, controlled shadows, detail, highlights and image cleanliness |
| Typography and legibility | 15 | ≥13 | Brand/name/variant and note labels accurate, beautifully typeset, legible in full inspector |
| Fragrance-specific scene | 10 | ≥8 | Distinctive artistic treatment from verified or explicitly imaginative creative brief, not generic repetition |
| Border/material restraint | 5 | ≥4 | Narrow continuous premium iridescent frame, no gaudy opaque rainbow or double-foil |

**Per-image pass: total ≥90/100, every individual minimum met, and all six hard rejection gates passed.** An image at 94 points with a wrong bottle is a rejection, not a pass.

## Review procedure

1. Automatically validate dimensions, ratio, file signatures, manifest completeness and duplicates.
2. Two reviewers independently see (a) the submitted card, (b) the owner's MYSLF card, (c) the exact product reference and verified metadata. Record the weighted six-part score.
3. Both reviewers must score ≥90 total and meet each category's minimum. Any disagreement on product identity triggers rejection/correction, not averaging.
4. At **236 pt wide** in the actual app, the main bottle must be recognizable and title legible; at full-inspector size, concentration and verified notes must be readable. Inspect at realistic phone brightness and light/dark settings.
5. If either reviewer scores a candidate below threshold, correct/regenerate and rerun *every hard gate*. No grade inflation from repeated retries.
6. Track acceptance percentage, number of generation attempts per accepted asset, number of bottle errors, and time spent correcting art. The default allowed rejection rate is not capped; quality wins.

## Batch release definition of done

- **30/30** unique products have an approved final front, associated verified product facts, documented rights review and successful Xcode image-set packaging.
- **30/30** cards score at least 90/100 with no hard-gate failure; **0** incorrect container variants, invented label claims or missing artwork.
- **30/30** render fully offline in the native gallery; 30/30 open and can be shared; no physical-ownership or digital-purchase side effects.
- The iOS compile passes; the owner inspects a real device; the signed build is uploaded and confirmed in internal TestFlight.

## Limits of image-to-image scores

**SSIM, pixel difference, color histograms and embedding similarity are supplemental.** A new fragrance should not be pixel-identical to MYSLF. Raw pixel matching would punish legitimately different color palettes, bottle shapes and ingredient scenes. Product fidelity still needs explicit comparison with the correct real-world container, and perceptual quality requires a calibrated human review. Do not invent a universal "95% similar" computer-vision score until a labeled set of accepted/rejected cards establishes its predictive value.

## Full reverse visual acceptance (2026-11-01)

The owner restated the MYSLF reverse as a **visual content** requirement. Every one of the 30 cards must include: (1) exact house/name/concentration masthead, (2) original 18–34 word editorial fragrance description, (3) FRAGRANCE MAP header, (4) three photographic Top/Heart/Base strips **with different stage-specific images**, (5) release year, marketed gender classification and concentration in a 3-column footer, (6) Arooma attribution, and (7) the same edge-to-edge etched foil border treatment as the front. The card must not use repeated crops of the front as fake ingredient photographs.

Artwork for stages is in `reverse-art/<id>-<stage>.jpg`, 1000x390 per strip. There must be **90/90 unique files and 30/30 complete editorial records**. Only the private TestFlight and DEBUG builds package the generated art; no public-rights flag is changed. The actual note text stays as independent sourced SwiftUI typography and does not rely on AI image text rendering.
