# Arooma V2 | Collectible gallery, luxury themes, motion and low-friction core actions

> Part of the [Arooma design brain](../README.md). Read [brand/BRAND_BOARD.md](../brand/BRAND_BOARD.md) for the implemented V2 look, [brand/COLLECTIBLE_CARD_ART_DIRECTION.md](../brand/COLLECTIBLE_CARD_ART_DIRECTION.md) for the archived art-direction baseline, and [brand/THIRD_PARTY_CONTENT_POLICY.md](../brand/THIRD_PARTY_CONTENT_POLICY.md) for media rights.

> Summary: This PR builds a V2 **web-app demonstration** on top of the existing local-first Arooma app: four 60:30:10 luxury theme palettes, a synchronized light/dark appearance, direct collection/demo entry with animated "Arooma" calligraphy, a persistent in-app switcher, and four illustrated Archive Foil fragrance pairs. The original Cover Flow, Stack, Fan, personal collection, wear logging, backup, and restore remain functional. This is **not** native SwiftUI or an App Store submission.

**Status:** Implemented in PR #8, pending automated and physical-iPhone verification.
**Date:** 2026-10-30
**Owner direction:** Build V2 and merge into main; populate with existing concepts; eliminate unnecessary steps for the primary workflows.

## Problem and experience

The older cabinet was pleasant but static and visually disconnected from the premium editorial fragrance cards. Users want to touch the objects, compare compositions, record a wear in one tap, use their own collection without deleting a demo, and change the appearance without losing context.

**Primary journey:** Arooma script entry -> tap "Explore demo cards" -> swipe Cover Flow -> tap focused card to see fragrance-map reverse -> tap Details for own-record actions -> tap Wear Today, Test, All Shelves, Add, or switch to My Collection from the persistent header.

## Exact palette tokens, 60:30:10

Distribution is by visual area and emphasis: 60% dominant shell, 30% secondary supporting surface/vignette, 10% highlight/metal/UI accent. The individual cards keep their own brand-linked scene and foil coloring; the shell is not allowed to recolor bottle imagery.

| Theme | Dominant 60 | Secondary 30 | Accent 10 | Display family candidates |
| --- | --- | --- | --- | --- |
| Obsidian Gold | `#161B24` navy | `#312B33` graphite plum | `#B88B47` bronze | Iowan Old Style / Cormorant Garamond |
| Ivory Oud | `#F3EBDD` bone | `#D8C4AA` sand | `#9F6A36` bronze | Didot / Bodoni Moda |
| Violet Ink | `#1B1A28` iris | `#5D5266` muted violet | `#C9B6D9` silver lavender | Iowan Old Style / EB Garamond |
| Emerald Resin | `#18211F` emerald charcoal | `#4B5A55` moss slate | `#D1B68B` champagne metal | Palatino / Fraunces |

**Mode override:** any of the four hues can switch between **dark** with ink/navy/plum gradients (not `#000000`) and **light** with warm bone/cream/beige gradients (not `#FFFFFF`). Current build uses offline-safe locally available system font fallbacks; named downloadable families are **suggested pairing references**, not bundled font files. Standard utility remains Apple system/SF Pro. Only the wordmark uses Snell Roundhand/Apple Chancery-style calligraphy. All actionable text remains legible sans serif.

## Surfaces and actions

### Welcome / return

- The former cabinet door animation is **removed from active use**. A short calligraphic "Arooma" write-on followed by one underline flourish is the first-run entry experience.
- Four palette swatches, Light/Dark controls, direct Explore Demo and Open My Collection actions. No required signup, extra confirmation or permissions.
- Returning users with a saved mode **skip the intro** and land directly back in the selected shelf, for speed. The menu's wordmark action replays the visual when desired.
- Reduced Motion shows the completed wordmark without staged drawing.
- All changes to theme and appearance persist separately from ownership/backup data.

### Shelf and collector cards

- Preserve the current Cover Flow/Stack/Fan geometry, touch velocity and selection across modes; no new deck route or loading screen.
- The selected collectible displays the original Arooma v3 content hierarchy: product name, visual top-note props, top-note names, clear official concentration; reverse contains description and three horizontal TOP/HEART/BASE strips.
- Image face and reverse are static **illustrated SVG interpretations** produced for this PWA from previously approved card concepts, **not the original ChatGPT full-resolution photorealistic PNG diptychs**. Swap them with cleared rasters at same filenames when provided/imported. No unlicensed manufacturer marketing photo was scraped or committed.
- Original fictional seven-bottle demo remains, with four recognizable curated fragrances added: Dior Sauvage Elixir, Rasasi Hawas for Him, YSL MYSLF EDP, and Mind Games Prodigy. The official maker's concentration and listed note information are used; exact note stage order verified against published brand sources.
- The collectible **flips to the scent map**, and curated demo entries have a one-tap **Add to my collection** action that preserves their illustrated card art under an optional `artKey` in the existing schema v3; the existing Details button opens the personal ownership menu (wear history, edit, rotate, move, authenticity observations and delete) in the same interaction framework. The owner record is never deleted.

### Core functions, friction budget

| Task | Target from cabinet | Implementation |
| --- | --- | --- |
| Browse | Direct drag/keyboard or tap adjacent card | Existing finger-tracked Cover Flow |
| Check notes | One focused-card tap | Same card flips to scent map |
| Add curated fragrance to my collection | One tap on a demo collectible | The primary action copies its fragrance facts and Arooma illustration to own storage, then switches to the owned card; duplicates are opened instead of added |
| Wear today | One tap on any owned or classic bottle | Existing Wear today CTA / Undo |
| Start scent test | One tap | Existing Test CTA and in-app check-ins |
| Find a fragrance | One tap | All Shelves/Search button |
| Add bottle | One tap | Header + opens existing add form |
| Switch demo ↔ own | One tap | Header Demo/My Collection, preserves separate stores |
| Change theme | One tap to appearance sheet, then swatch | Four deterministic palettes and Light/Dark |
| Ownership/history/edit | Tap Details, then appropriate destination | Existing menu; no extra global screen |
| Backup/restore | Menu → Backup and restore | Previous local-first explicit flow unchanged |

Demo/card upgrades are limited to `arooma.demo` and an `arooma.v2.curatedInstalled` marker; `arooma.cabinet`, older migrations, `arooma.v1` fallback, photos and backup schema v3 remain unchanged. A curated card removed by the user does not reappear automatically. Demo reset is explicit.

## Platform and interaction guardrails

- Current app remains a static PWA, not SwiftUI; native haptics, Apple Liquid Glass and App Intents are not represented as built. Safari haptics remain best effort.
- Motion follows the existing finger-driven transforms; a short 3D flip and foil surface are integrated with the content. No autoplay carousel or continuous motion added.
- Reduced Motion suppresses intro script animation and transitions.
- Every card has an accessible label, source SVG has `role=img` and alt text; all controls have accessible names. Cards can be browsed with arrow keys.
- PWA service-worker shell now precaches the eight curated card faces for an offline launch.
- Content includes an independent-app disclaimer. Real fragrance house marks and vector renderings need separate rights review for App Store distribution; no publication approval is inferred from Yugipedia.

## QA

1. Fresh first paint shows calligraphy entry, not doors. Entry into demo or own collection is a single decision with no extra dialog.
2. All four swatches and Light/Dark work, changing control/scene palettes while keeping card art intact.
3. All four curated fronts and backs load via local SVG assets, even from the installed offline cache.
4. Cover Flow, Stack and Fan preserve selection; tap focused collectible flips; other samples continue to display ownership records.
5. Independent own/demo local stores, storage migration and data backup roundtrips remain intact.
6. Wear today, undo, test timer, search, shelves, add/edit/delete, rotations, and share image still work.
7. 375, 390, 430 px viewport; landscape prompt; reduced motion; test iOS Safari/Home Screen.
8. CI `npm run check` and `npm test` must pass **before merge**. Keep Playwright screenshots as artifacts.
9. Validate actual device visual quality, soft keyboard behavior, gestures, foil readability and frame consistency after deployment.

## Open/owed

- Replace illustrated stand-ins with the exact final Arooma photographic collectible PNGs only after an approved import/provenance procedure, and test on an actual iPhone. Present asset integration must not be misrepresented.
- Aroooma is a personal archive, not an official brand property; brand affiliation and photo rights policies remain active.
- Native SwiftUI move, true haptics, lighting on physical device, actual 60fps measurements, font licenses and App Store review are separate projects.
- This implementation does not enable ads, IAP, network catalog search, third-party analytics or account login.

## Rollback

Revert PR #8, leaving own collection storage untouched. Before reinstalling a web build, export a JSON backup to protect local-only owner data.
