# Native Autumn live deck integration (2026-11-01)

> Part of the [Arooma design map](../README.md). Implements the owner's request to put the 30 generated cards into the same live native deck as the original four, not a separate proof viewer.

## Owner experience

- Open **Collection → Demo**: original four editions plus 30 Autumn Archive editions, 34 total.
- Or select **Cards → Autumn Archive · 30 live cards**: switch to the original Collection deck and focus the first new card.
- Switch between **Cover Flow, Stack and Fan** without losing selection. The same `DeckMotor`, `FlipMotor`, `AtelierCardSurface`, `LiveFoil`, haptics and tap/drag behavior apply to all 34.
- Tap one of the 30: the original `AtelierInspector` opens; horizontal drag flips a proper double-sided 3D card. The reverse uses three original editorial art-direction strips. It **does not** fabricate top/heart/base fragrance metadata.
- Add an autumn fragrance as an actual owned bottle or wishlist entry through existing native actions, if desired; browsing never grants ownership or paid card entitlements.

## Existing data and visual assets

- Four original `Fragrance` IDs and their approved diptychs remain unchanged.
- 30 separate edition IDs use `fall2026-<slug>`. One Dior Sauvage Elixir edition intentionally coexists with the original Dior illustration. Distinct edition IDs prevent accidental ownership migration.
- `assets/collectibles/seasons/fall-2026/proofs/*.jpg` (30 JPG files) is copied through an Xcode folder reference to `Arooma.app/proofs`. A bounded 96 MB image cache prevents a 34-card archive retaining every decoded asset indefinitely.
- Existing `SavedArchive` persisted fields do not change: bottles, photos, notes, saved layering and card purchases are preserved.
- The commercial availability and verified-rights gates remain unchanged; DEBUG and `AROOMA_INTERNAL_PREVIEW` can display proofs as **interactive local demo cards**, not approved commercial sales.

## Acceptance checks

1. Build native iOS Debug; verify **all 30 JPEGs and catalog JSON are actually embedded** in `Arooma.app`.
2. Launch, select Demo and verify 34 cards, with all 30 readable and no “Artwork unavailable” placeholder.
3. Test each layout, 3D flip, swipe interruption, phone-tilt lighting, Reduce Motion, and accessibility actions.
4. From Cards, use the new Autumn Archive shortcut and confirm it lands on the first new card in the original deck.
5. Add an autumn edition to the user's owned collection and verify original images, wear histories and saved cards were unaffected.
6. Compile the internal Release configuration with all 30 photographs. Signed TestFlight upload is still the owner's manual `arooma-testflight` workflow.

## Distribution limitation

The proof artworks are not yet commercially cleared. The normal App Store release path does **not** unlock the unapproved edition catalog. This is an internal iPhone demonstration; product details and distribution rights need final review before public launch. Editing a bundled JPG still requires a new app build; it is not a remote hot-update.
