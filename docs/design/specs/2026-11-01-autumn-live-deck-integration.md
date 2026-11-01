# Native Autumn live deck integration (2026-11-01)

> Part of the [Arooma design map](../README.md). Implements the owner's request to put the 30 generated cards into the same live native deck as the original four, not a separate proof viewer, and then complete the back with sourced fragrance notes.

## Owner experience

- Open **Collection → Demo**: original four editions plus 30 Autumn Archive editions, 34 total.
- Or select **Cards → Autumn Archive · 30 live cards**: switch to the original Collection deck and focus the first new card.
- Switch between **Cover Flow, Stack and Fan** without losing selection. The same `DeckMotor`, `FlipMotor`, `AtelierCardSurface`, `LiveFoil`, haptics and tap/drag behavior apply to all 34.
- Tap one of the 30: the original `AtelierInspector` opens; horizontal drag flips a proper double-sided 3D card. The reverse uses three real **Top / Heart / Base** note strips populated from the product's sourced pyramid, with consistent typography and real fragrance notes. Each card's catalog record contains the provenance URL. The images retain their original style and motion behavior.
- Add an autumn fragrance as an actual owned bottle or wishlist entry through existing native actions, if desired; browsing never grants ownership or paid card entitlements.

## Existing data and visual assets

- Four original `Fragrance` IDs and their approved diptychs remain unchanged.
- 30 separate edition IDs use `fall2026-<slug>`. One Dior Sauvage Elixir edition intentionally coexists with the original Dior illustration. Distinct edition IDs prevent accidental ownership migration.
- `assets/collectibles/seasons/fall-2026/proofs/*.jpg` are retained as candidate sources but **not** copied directly to ordinary App Store builds. The existing `scripts/prepare_fall_testflight.py` packages only the 30 product image sets into `Assets.car` for private Debug and internal Codemagic/TestFlight builds. A bounded 96 MB image cache limits decoded artwork memory.
- Existing `SavedArchive` persisted fields do not change: bottles, photos, notes, saved layering and card purchases are preserved.
- The commercial availability and verified-rights gates remain unchanged; DEBUG and `AROOMA_INTERNAL_PREVIEW` can display proofs as **interactive local demo cards**, not approved commercial sales. Unapproved seasonal sharing is unavailable. All 30 metadata identities remain resolvable for already-saved owned/wishlisted records even when artwork is unavailable.

## Acceptance checks

1. Stage private image sets and build native iOS Debug; verify the **30 image names inside compiled `Assets.car`** and the catalog JSON in the app bundle.
2. Launch, select Demo and verify 34 cards, with all 30 readable and no “Artwork unavailable” placeholder.
3. Test each layout, 3D flip, swipe interruption, phone-tilt lighting, Reduce Motion, and accessibility actions.
4. From Cards, use the new Autumn Archive shortcut and confirm it lands on the first new card in the original deck.
5. Add an autumn edition to the user's owned collection and verify original images, wear histories and saved cards were unaffected.
6. Compile the internal Release configuration with all 30 photographs. Signed TestFlight upload is still the owner's manual `arooma-testflight` workflow.

## Distribution limitation

The proof artworks are not yet commercially cleared. The normal App Store release path does **not** package or unlock the unapproved image assets. This is an internal iPhone demonstration; product details and distribution rights need final review before public launch. Editing a bundled JPG still requires a new app build; it is not a remote hot-update.

## 2026-11-01 follow-up: actual fragrance notes

- All 30 `catalog.json` entries now contain `notePyramid.top`, `notePyramid.heart`, `notePyramid.base`, `sourceURL` and `sourceType` (maker/retailer or an editorial fragrance database). These notes are research-backed note descriptions, not a chemical analysis, and manufacturers or databases may publish different note pyramids.
- `Fall2026Collection.fragrances` now passes notes to native catalog search, inspector and layering; no extra server, private account or migration is needed.
- `Fall2026Reverse` shows real TOP NOTES / HEART NOTES / BASE NOTES in the existing three-strip treatment, while leaving the front images, foil, tilt, physics and card IDs unchanged.
- `node scripts/check-fall-archive.mjs` verifies exactly 30 complete pyramids with provenance links; this separate factual metadata does **not** mark any of the unapproved brand-art/rights flags as accepted for public sale.
- In the owner’s internal build, confirm long notes wrap gracefully on the smallest supported iPhone and use VoiceOver to read every stage. The master front image and 3D flip remain unchanged.

## 2026-11-01: owner-locked full reverse restored

**Correction to an incomplete earlier implementation:** Three text-only note strips and three identical crops of the front photograph were insufficient. [The Archive Foil v3 art standard](../brand/COLLECTIBLE_CARD_ART_DIRECTION.md) mandates a complete mirrored visual reverse. The owner supplied the MYSLF reverse again to restate this standard.

Every one of the 30 Fall editions now has its own editorial story, release year, marketing classification, concentration and three complete sourced note lists. All three note rows use **different photographic ingredient art**, generated as independent images, never cropped from the product front. The original front card's etched holographic perimeter is reused via a border mask so front and reverse match exactly. The 3:2 source triptych of each fragrance is cut into three 1000 x 390 botanical panels and provided only in the signed internal build's compiled asset catalog as `fallnotes-<id>-top`, `fallnotes-<id>-heart`, `fallnotes-<id>-base`.

The production build `prepare_fall_testflight.py` fails if any of the 90 photo assets is missing. Native CI inspects `Assets.car` and verifies all 90 by name in addition to the 30 card fronts. Public commercial bundles do not include the unapproved artwork, as before.

**Acceptance on a physical iPhone:** all four edges of the holographic border; full house and variant; original 18–34 word italic description; Top/Heart/Base photo strips with visually distinct ingredients and correctly typeset actual notes; no clipped notes; release year, masculine/unisex classification, concentration and Arooma footer. Inspect the shortest and longest fragrance names and 6-note bases. Flip/motion/ownership behavior remains unchanged. The source note pyramids and source URLs remain intact, and edited descriptions do not imply maker endorsement.
