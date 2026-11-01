# Arooma Native Card Studio — Offline Photo Filters

**Shipped implementation:** `ios/AroomaNative/StudioPhotoFilters.swift` and `Commercial.swift`.

## Owner experience
- Cards > + > Choose bottle photo > tap any filter thumbnail > Save to My Cards.
- Six built-in grades: Original, Royal Amber, Midnight, Ivory, Violet, Emerald.
- The thumbnails display the **user's actual photograph**, not generic product sample art.
- Color adjustments use Apple Core Image on-device. No Arooma backend, online image model, or image upload is required.
- Filters affect the photograph, not physical product geometry, label wording, or the card's collectible foil. The original photo must be preserved.
- The optional existing Vision subject-isolation control remains separate; it can mistakenly include the hand and cannot reconstruct occluded details.

## Data compatibility
- `CreatedCard.photoFilter` stores the selected preset as a Codable string.
- Cards and portable backups created before filters decode as `Original`.
- `CardCommerce.create()` saves **unfiltered selected-photo pixels** plus the filter ID. On reopen the same deterministic grade is applied to the saved photo. PNG sharing uses the same graded photo and disables motion for its static render.
- Existing physical collection records and StoreKit entitlement flags are unchanged. No paywall; existing free personal cards remain free.
- This preserves grading non-destructively relative to the selected photo, but the *optional Vision cutout* still replaces the source photo in the existing card record. The pre-cutout source cannot be reconstructed from that saved card. This limitation is not concealed.

## Acceptance
1. On an iPhone, select an image: see six **actual-photo** thumbnails and change the live card by tapping each.
2. Save Royal Amber, reopen under My Cards, share a PNG: same grade and no source-product reconstruction.
3. Choose Isolate bottle and Original photo; filters still apply on both, cutout retains transparency.
4. Load existing personal cards/backups created before this change: no decoding failure; grade defaults to Original.
5. View cards offline, with Reduce Motion enabled and across four light/dark theme palettes.
6. Confirm no change to brand art masters, physical collection data, purchases or permissions.

**Build verification:** GitHub Actions `Native iOS 26 SwiftUI Build` on a macOS runner. Physical iPhone performance and final visual QA remain separate from compilation.
