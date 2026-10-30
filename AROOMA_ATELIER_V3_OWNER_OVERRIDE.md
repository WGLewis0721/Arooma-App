# Arooma — Atelier V3 Card-First Rebuild

**Owner-directed implementation override (2026-10-30).** This document is the active brief for `feature/v3-atelier-card-first-rebuild`. It supersedes incompatible *stylistic* restrictions in prior V2 design docs. It does not supersede data safety, content rights, security, or truthful release reporting.

## Goal and scope

Rework most user-facing surfaces rather than make tiny cosmetic changes. Change **the header, card gallery, physics and lighting, navigation, first-run presentation, inspector, shelf grid, search, ownership sheet, and all four visual themes** as one coherent system.

The original full-resolution, commissioned Dior, Hawas and MYSLF card art already exists at `assets/collectibles/production/`; use it, never redraw it. Historical Prodigy remains marked archival. Preserve the byte-identical masters and the existing user-owned data.

## Overridden instructions and why

| Prior rule | Owner's current decision | Actual action |
| --- | --- | --- |
| `AROOMA_V2_FINAL_POLISH_SPEC.md`: “Do not rebuild; preserve one-file index.html” | 90% of layouts/interaction surfaces must materially change | Preserve the **data engine and storage format**, but allow a separate themed CSS/JS presentation layer to make a substantial redesign maintainable |
| `BRAND_BOARD.md` and prior smoke tests: bottles must always animate liquid | Suspend or comment out liquid animation so cards get the rendering budget | Set `LQ` simulation `ON=false`; leave fill measurements, static paths, photo level records and source code intact for eventual opt-in |
| V2 has a cabinet/door-centric metaphor and small peripheral tools | Collectible art is the hero; restore iOS tactility | No door intro; new gallery, five-tab navigation, full inspection, richer shelf and search layouts, direct ownership record and four unified themes |
| V2 requires exhaustive legacy liquid-motion tests | Lean regression relevant to this release | Update only liquid-specific obsolete expectations; keep saved data, add/undo, backup, cards, iPhone layout and gesture smoke coverage |
| Old cards are simplified SVGs | Exact art masters must be used | Production WebP derived from approved originals is the runtime for c0–c2; never swap in newly drawn SVG interpretations |

**Rules that still apply:** local storage compatibility (`arooma.cabinet`, `arooma.demo`, `arooma.prefs`, theme prefs), explicit reversible destructive actions, privacy, legal image provenance and honest unofficial brand status, platform accessibility, existing safeguards around backups, and checking actual CI results before claiming deployment.

## Implementation

- `assets/atelier/atelier.css`: responsive visual system for every important surface. Four palette identities in both dark and light; sharp photography with precise rim treatment; full phone canvas without fake iOS status bar; Apple-like shallow glass only on controls. Decorative lighting never washes over text.
- `assets/atelier/atelier.js`: five clear tabs (Cards, Search, Shelves, My Bottle, Style), gallery identity area, source-faithful shelf thumbnails, tolerant combined search including owned and catalog fragrances, editorial ownership record with direct wear/history/edit/move/backup.
- `index.html`: exposes a read-only-ish interface and existing user actions to the Atelier layer; retains the engine and state semantics. Suspends the liquid animation loop without losing stored levels. The existing matched-origin Inspector, one-tap demo→Mine, Cover Flow/Stack/Fan, and reversible operations remain.
- `sw.js`: precache the new CSS/JS and keep the original approved card faces offline.

## Design system

- Theme 60:30:10 tokens keep Obsidian Gold `#161B24/#312B33/#B88B47`; Ivory Oud `#F3EBDD/#D8C4AA/#9F6A36`; Violet Ink `#1B1A28/#5D5266/#C9B6D9`; Emerald Resin `#18211F/#4B5A55/#D1B68B`.
- Dark: midnight navy/plum/aubergine, not black. Light: bone/cream/beige, not hospital white.
- One typography hierarchy: system/SF Pro for actions, theme-specific refined display serif for headings, vector calligraphy only for Arooma entry.
- The gallery's high-resolution photographic cards occupy the visual center. The surrounding shell is quiet. No auto-shimmer, particle blizzard or endlessly animated liquid.
- Navigation and screens follow one 8-point rhythm, a 44px functional touch target where possible, safe-area margins and legible iPhone text.

## Core action budget

1 gesture to browse; 1 tap to inspect; 1 tap to flip; 1 tap demo→Mine; 1 tap to record wearing; 1 tap to Search; 1 tap to My Bottle; theme within 2 taps. Returning users do not replay the intro.

## Focused verification

A targeted regression once after the changes: confirm original card production paths, first-open and returning view, two themes, Cover Flow→Inspector→Flip→Close, one-tap collect, one-tap wear and undo, shelf/search navigation, ownership edit and export/restore on test data, offline shell caching, responsive 375/393/430 width, no console errors. Keep repository checks truthful, but do not repeatedly execute large suites after trivial CSS edits. **Do not claim physical iPhone 60 fps or native haptics from Chromium tests.**

## Known platform boundaries

This is an iOS-first **PWA**, not native SwiftUI. Device haptics, Liquid Glass and OS-level launch animation cannot be promised. Public distribution of third-party fragrance artwork still needs its documented rights basis. A major visual rework does not authorize deleting owners' data or weakening protections.
