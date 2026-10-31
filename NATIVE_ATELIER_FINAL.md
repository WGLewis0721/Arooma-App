# Arooma Native — Atelier Final Visual System (iOS 26)

**Status:** Implemented in `feature/native-atelier-luxury-redesign` as a SwiftUI-only redesign. This document supersedes conflicting PWA delivery constraints in `AROOMA_V2_FINAL_POLISH_SPEC.md` but preserves its visual, artwork, interaction and local-first requirements.

## North star
The collectible is jewelry; every other surface is its fitted velvet tray. Photographic faces and their original metallic edges are the only hero assets. Do not regenerate cards, recolor their art, apply Liquid Glass to imagery, or place glass panels behind cards.

## Functional / content separation
**Content:** An atmospheric color-field, photographed cards, editorial fragrance copy, seasonal shelves and ownership records. Content surfaces use standard opaque/translucent materials and contact shadows, never Glass.
**Functional:** TabView, compact float controls, layout switcher, inspect/close buttons and system sheets. Liquid Glass is applied only to these controls and respects Reduce Transparency.

## Display language
- Every theme has dark and light variants with different atmospheric undertones, not a flat black/white recolor. Obsidian: graphite/navy/plum. Ivory: sand/bronze/cream. Violet: ink/plum/lavender. Emerald: fir/moss/champagne.
- 60:30:10 refers to dominant field, supporting atmosphere and restrained metal accent. Accent is functional and never washes over card art.
- New York/system-serif for title words, SF Pro/system for all labels, status, forms and navigation. Calligraphy is brand-only.
- Full-photo trading cards use the original committed approved masters through `ApprovedArtwork`. Preserve every original card face and reverse; historical Prodigy stays identified as archival.

## Native interactions
- **Onboarding:** one clear choice to Demo or Mine; four themes; visible card previews; returning owners skip it.
- **Gallery:** selected card larger and forward; neighboring cards have carefully limited perspective; finger movement directly controls position; flick release snaps with spring; selected identity persists across three layouts.
- **Inspector:** immersive flip by tapping the card or one clear Flip action; front and back are the exact photographic faces, no rebuilt notes.
- **Shelves:** editorial seasonal bays with horizontal tactile cards, not a generic inventory table.
- **Search:** readable cards, house/note matching, no network requests or fake filters.
- **Ownership:** large card hero, local metrics, wear/undo, history, notes, rotations, and bottle editing in three taps or fewer from common entry points.
- **Themes:** four materially different atmospheric palettes, both light and dark, one coherent system.
- **Haptics:** selection settle, wear confirmation, completed actions only; no tapping/hover/flip haptics.
- Liquid wave simulation is deliberately absent from this native experience; preserve stored fill estimates.

## Data and releases
Retain `CollectionStore` model and existing `arooma-native-v1.json` encoding without migrations, deletions, or resetting onboarding. Keep the bundle ID `com.graymatter.arooma` so TestFlight updates install over the existing app. Use the existing `codemagic.yaml` workflow and App Store distribution profile; do not regenerate signing files.

## Minimal quality gate
1. One Xcode 26 iOS Simulator build from GitHub Actions.
2. Attempt to launch simulator and capture real onboarding/gallery screenshots; screenshot stage may be skipped if a runtime is unavailable, without falsifying success.
3. Run signed `arooma-testflight` in Codemagic after PR merge, using a new build number. Verify the upload in App Store Connect before reporting installation-ready.
4. Physical iPhone acceptance: one each of Cover Flow, Stack, Fan, flip, Demo→Mine, wear/undo, Search, four themes and persistent local data. No fabricated device-performance claim.

## Conflicts flagged
- Old instructions saying "no TestFlight needed" or "improve PWA in place" are obsolete: the owner is already using native TestFlight.
- Old liquid-physics requirements are suspended by current owner direction.
- Requirements safeguarding user data, originality of card assets, copyright review, accessibility and accurate release claims remain in force.
