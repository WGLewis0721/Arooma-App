# Arooma V2 — Final Collectible Edition
## Production design and implementation specification for GPT-6 Sol · Extra High

**Status:** Approved direction, implementation handoff. **Repository:** `WGLewis0721/Arooma-App`. **Base:** current `main` after PR #10, at `049edf5` on 2026-10-30, unless a newer `main` has been merged. **Target:** the existing deployable Arooma PWA, not a new app, splash-only concept, Figma-only proposal, or unapproved SwiftUI rewrite.

> **The brief:** Keep the Arooma functions that work. Turn a serviceable demo with illustration substitutes into the most polished luxury fragrance-card collection experience practical on iPhone Safari and an installed iOS web app. Make the real, previously approved card artwork the centerpiece. The user already spent hours directing and approving the images: **reuse those exact files; do not redraw, reinterpret, replace, regenerate or invent them.** The result should feel as intentional, responsive and quiet as an excellent first-party iOS app, with the elegant material character of a serious fragrance house.

### 0. Hard delivery rules

1. **No new low-resolution SVG mock cards.** Original pixel-for-pixel artwork masters are in `assets/collectibles/masters/`. They are the source of visual truth. The current `assets/collectibles/cards/*.svg` are temporary V2 stand-ins, not acceptable release art. Do not ship them as though the approved photographic cards are loaded.
2. **Do not rebuild.** Preserve one-file `index.html` architecture, local-first collections, existing Cover Flow/Stack/Fan, search, shelves, wear log, rotation, backups, photo support and data compatibility. Improve in place.
3. **Deliver, don't narrate.** Implement the app, commit a focused branch, open a PR to `main`, provide an iPhone-viewable Pages preview where supported, and merge only when the small acceptance gate is green. Use screenshots from the actual implementation, not unrelated concept renders. Do not build a second prototype while leaving the main app unchanged.
4. **Production restraint:** good taste is fewer controls, more direct manipulation, better typography, excellent gesture physics and fidelity. No sparkly hover loops, artificial neon, heavy glass over artwork, decorative UI for its own sake, or background auto-animations.
5. **Image rights are not established by repo storage or a fair-use disclaimer.** Follow `docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md` before public marketing / App Store distribution. These stored artwork sources are for the owner's design handoff; record provenance and any distribution limitation. Do not pull brand stock photography or assume any brand endorses Arooma.
6. **Limit unnecessary testing.** Do one targeted visual/interaction pass and one final CI run, not a test-driven redesign campaign or 40 commits to make a broad fixture happy. Fix critical failures; do not disable safety checks or rewrite unrelated smoke expectations to conceal defects.

### 1. Actual starting point and what must survive

The current V2 release already has a working light/dark palette system, a calligraphy welcome, one-tap Demo/Mine switching, the separate demo and owner collections, a card face/back rotation, and a passing 218-check merged-commit smoke suite (PR #10). The problem is **art-direction fidelity and visual refinement**: the cards are tiny synthetic SVG bottle drawings instead of the commissioned photo-composite masters. Other polish shortcomings include narrow phone typography, motion that feels like translated DOM instead of a coherent object, excess peripheral chrome, and image treatment that doesn't respect the collectible edges.

Keep `arooma.cabinet`, `arooma.demo`, `arooma.prefs`, `arooma.v2.theme` and `arooma.v2.appearance` semantics; do not silently clear or migrate owner's personal data. Maintain the original schema and backup compatibility; a new optional `artKey` already exists for copied curated entries. Preserve `sw.js` offline support; version/invalidate cached assets correctly so Safari does not show old illustrations after deployment. `npm run check` covers design docs; `npm test` covers browser behavior. See `docs/design/brand/BRAND_BOARD.md`, `docs/design/specs/2026-10-30-v2-collectible-gallery-implementation.md`, and `docs/design/brand/COLLECTIBLE_CARD_ART_DIRECTION.md`.

### 2. Original card artwork: non-negotiable asset map

These are **actual original source PNG files committed to this repository**, not reconstruction instructions or image-search links.

| Demo card key | Exact source asset (complete two-up diptych) | Authority | Pixel dimensions |
| --- | --- | --- | --- |
| `dior` / `c0` | `assets/collectibles/masters/approved/dior-sauvage-elixir-original-diptych.png` | **Locked Archive Foil V3**; grapefruit and readable TOP notes on the front; no Ultra Rare | 1470 × 1070 |
| `hawas` / `c1` | `assets/collectibles/masters/approved/rasasi-hawas-for-him-original-diptych.png` | Corrected user-reviewed Hawas; violet bottle and silver ornamental cap; 2015 EDP | 1470 × 1070 |
| `myslf` / `c2` | `assets/collectibles/masters/approved/ysl-myslf-edp-original-diptych.png` | Existing YSL MYSLF original card pair, black monogrammed sprayer; 2023 EDP | 1536 × 1024 |
| `prodigy` / `c3` | `assets/collectibles/masters/historical/mind-games-prodigy-v2-original-diptych.png` | **Historical only**, old V2 art includes “ULTRA RARE”; preserve, but do not falsely label this V3-compliant | 1470 × 1070 |

Additional original historic work is stored at:
- `assets/collectibles/masters/historical/prada-luna-rossa-ocean-front-original.png`
- `assets/collectibles/masters/historical/prada-luna-rossa-ocean-back-original.png`

The historical assets exist to preserve work already performed. Do not automatically put them into the polished V3 collection or modify approved V3 content without user approval. For the fourth demo slot, either present Prodigy clearly as an **archival card** or keep its existing fixture behind a legacy-demo mode until its final art is approved; **never recreate a fake photographic Prodigy V3 card**.

**Verifiable original SHA-256 values:**

```text
Dior original:    eb4fef3eaa37d8ffc270354d90a1e5614cb944b33b90521c2abb3cc19bfbeb7c
Hawas original:   77073abcba76f1173efe62daa6259cd0e34db0374d5ec186f8e65094607c1bdd
YSL original:     ebdc1a32ba4a667f2fbe306c6acbea4be694b346f56c99b20cd91c9a12fff7ec
Prodigy original: f6187eb0778226b6c8ac55af1eec59d7b54f3944fadf0874ef5a79ec56465418
```

**Important resolution reality:** the source diptychs are ~1470×1070 / 1536×1024. Each separate face is only approximately 735×1070 or 768×1024, depending on the original. Do not claim native 1180×1720 or 4K originals; do not blur them by forcing oversized raster scaling. A sharp, true-resolution render on a phone is preferable to fake upscale or over-sharpening. If the approved originals cannot support a specific zoom view at full density, leave that detail for a separate authorized asset improvement, not an AI substitution.

#### Lossless / derivative workflow

1. Keep each `*-original-diptych.png` **byte-for-byte untouched** (checksums above). Each diptych contains a front on the left and back on the right. Treat these source files as protected masters.
2. Split into two faces at the source's midpoint, then visually crop **only outer matte/gutter** as necessary. Start with `[0, 0, width/2, height]` and `[width/2, 0, width, height]`. The exact card bounds may be inset; optical inspection on the real files is required. Do not cut off corner foil, footers, grapefruit props, cap, brand title or metadata.
3. Do not stretch to force 59:86. Keep entire card edges, use transparent/padded matte outside the object or a fitted composition. The **card object** remains 59:86, and the bezel clipping layer—not the source photo—creates rounded-corner masks.
4. Write derived images to `assets/collectibles/production/{dior,hawas,myslf,prodigy}/` with lowercase `front.webp`, `back.webp` (or PNG where lossless is needed), and a small manifest linking back to the exact master SHA. Prefer 85–95 quality WebP when no visible foil/lettering deterioration; choose original PNG if compression harms sharp type. Generate only meaningful density variants; lazy-load offscreen cards, eagerly load selected and nearest neighbors.
5. No mid-card JPEG seam, browser-resized double-panel diptych, foil border fabricated on top, painted-over watermark, invented logos, or altered word shapes. Any shader is a **separate overlay** outside raster text: light can skim card edges, but must never obscure notes.
6. Derive a small static contact sheet from actual output files for visual acceptance. It is evidence, not a redesign. Use matching house/name/concentration/notes from the verified catalog instead of trusting any AI-generated typesetting as factual source.
7. Register production assets in a single lookup table rather than hardcoding per-card URLs in every layout. Keep a graceful illustration fallback for missing/blocked files; fallback art is not the target finish. If any existing `artKey` points to production art, its saved image survives reload, demo→own, Share, and offline Home Screen mode.

### 3. Visual north star and art hierarchy

**Apple-grade iOS tactility × a fragrance house's meticulous visual system.** The collectible art is the jewelry; the surrounding app is the fitted velvet tray. The screenshot test is simple: a random screenshot of Cover Flow looks like a designed product, not an ad, a CSS demo or a trading-card game.

*Shell / navigation*: restrained deep navy/plum atmosphere or warm bone/cream paper. Shallow luminous gradient, not a black void. Liquid Glass is reserved for bars and controls and must never wash over the artwork. No heavy bevel around every panel, no faux masonry texture behind every card, no unrelated neon. The current four themes are **brand-wide shell materials**; per-fragrance card art does not get recolored by a theme.

*The card*: no rewriting, no substituting typesetting from SVG placeholders. Fine iridescent engraved border remains built into the original approved image. Natural photographic light, restrained floor reflection, subtle thickness at tilt only. Photo shadows and accents come from the source composition, not artificial generic glows. The front's top-note list must be legible in a near-full-screen inspection view. The back uses the approved tight editorial serif, bronze labels, three stacked horizontal photographic note strips, and three bottom metadata columns.

*Spacing and control hierarchy*: 8-point base system with 4-point optical adjustments. Clear safe areas under status bar / home indicator. 44×44 minimum functional touch target even where visual button is smaller. Primary action stands out once per screen; avoid two simultaneously prominent filled controls. No visible row of obscure action icons on a face. Text must not collide with header, cards, notches or Dynamic Island.

#### 60:30:10 theme palette — keep the four approved names

| Name | Dominant 60% | Secondary 30% | Metal/accent 10% | Display type direction |
| --- | --- | --- | --- | --- |
| **Obsidian Gold** | `#161B24` | `#312B33` | `#B88B47` | Cormorant Garamond / Iowan Old Style |
| **Ivory Oud** | `#F3EBDD` | `#D8C4AA` | `#9F6A36` | Bodoni Moda / Didot |
| **Violet Ink** | `#1B1A28` | `#5D5266` | `#C9B6D9` | EB Garamond / Iowan Old Style |
| **Emerald Resin** | `#18211F` | `#4B5A55` | `#D1B68B` | Fraunces / Palatino |

These are **design ratios**, not mandatory pixel percentages; 60 = field/background, 30 = supporting surfaces, 10 = primary accent. In dark mode blend **midnight navy, blackened plum and aubergine**, not `#000`. In light mode blend **bone white `#F4EEE4`, cream `#EDE3D6`, warm beige `#DCCDBA`**, not sterile `#FFF`. Both appearances are available for each theme. Colors change with a quiet interpolation and do not repaint cards or rearrange controls.

**Typography system:** SF Pro/system for navigation, input, badges, tab labels, errors and metadata. One carefully chosen editorial high-contrast serif per theme for large headings and primary perfume names. Use actual legally available typefaces and license records if bundling; do not add proprietary font binaries from another product. Arooma wordmark is a **custom vector calligraphic mark**, not a random decorative script font across the UI. Test large and small sizes on iPhone; avoid tiny all-caps captions that vanish at normal viewing distance. Avoid switching font families during a motion transition.

### 4. Interaction specification by surface

#### First run and returning use

- **Retire cabinet-door animation entirely.** First-ever open: the brand name **Arooma** writes once in fountain-pen calligraphy using a correctly constructed vector stroke reveal (ideally actual glyph path drawing). Use the uploaded handwriting references as **movement/style**, not copyrighted copied lettering. Start/end gracefully; a single restrained taper and flourish, optional subtle drying-ink material shift. The work is done by tasteful movement, not particle effects.
- Background follows the selected system appearance: midnight-navy/plum in dark; bone/cream/beige in light. The mode and four-color swatches appear without layout jump. Two clear entries: **Explore Demo** and **My Collection**. Do not trap the user in a replay; returning users land directly in their last chosen collection, with theme and selection intact.
- Intro animation should not block taps; render the finished mark when Reduce Motion is enabled. Avoid forced waiting on a splash. An optional rewatch lives under Appearance/About.

#### Cover Flow — signature surface

- Selected card centered and slightly forward; neighbors visible with controlled rotation and true depth. Their movement is anchored to the user's finger, not delayed until release. One selected card at a time; maintain correct z-order so card controls aren't hidden by transformed siblings.
- Drag release: velocity-aware, precisely snaps one card into place using one tuned low-bounce spring family. Keep center-of-gravity believable; no choppy simultaneous perspective changes, no disappearing/recreating DOM cards, no style jump when title text updates.
- Cards should feel dense yet responsive: slight lift under touch, contact shadow refines, foil edge catches a controlled specular streak. No continuous animated shimmer while idle. Do not apply perspective changes to typesetting beyond those inherent in the card's rigid plane.
- Tap selected: expands into immersive **Card Inspector** with matched spatial origin, not a new generic full-screen page. Inspect means artwork nearly edge-to-edge (with safe-area/legibility), accurate front↔back flip, readable notes. Reveal Arooma ownership controls outside the card, not over the scent map. Tap again/back/swipe down to dismiss. Provide visible Flip and Close actions in addition to gestures.

#### Flip, inspection and foil behavior

- Flip around vertical axis using a single transform of the card as a rigid object; swap faces only when the reverse becomes visible. Both sides remain physically connected. Preserve pointer hit targets outside transformed 3D DOM when needed (see PR #10; do **not** regress the fixed Edit details hit test).
- Light/faux foil should respond to *card angle or explicit touch*, never wander autonomously. Highlight limited to a narrow, separately composited rim and a quiet glass glint; respect Reduced Motion and avoid washing over engraved text. DeviceOrientation permission is optional and should never be requested just to browse cards.
- No source image blurring during animation: transform raster in compositor; do not re-encode the image on every animation frame. Use CSS GPU-friendly transforms and opacity judiciously, without forcing `will-change` across every offscreen item. Target smooth interaction on an actual iPhone; don't invent a measured 60 fps claim.

#### Stack, Fan, collection, search

- **Stack:** top card peels/settles, neighbors share one motion language. Tapping top opens or flips the focused card; flicking changes selection; preserve orientation and z-order.
- **Fan:** cards hinge around a common pivot, selected card rises without occluding title/notes; no jerky changes between modes.
- **All Shelves / collection:** shift from immersive card to a calm, visually legible card grid. The same card identity and selection persist. Tap thumbnail to focus; no unnecessary intermediate modal.
- **Search:** visible within one step. Search exact maker, product, concentration, alternate spelling with tolerant matching. Result can focus card or **Add to Collection** in ≤3 taps. Don't silently equate EDT and EDP variants.
- **Owner records:** collectible back = scent story/map, not a settings form. **My Bottle** = wears, fill estimate, personal notes, authenticity observations, edit, move and delete. Make those direct and context-aware. Demo→Mine is one explicit tap and must not overwrite already-owned data. Avoid extra confirmation dialogs for safe reversible actions; preserve Undo for meaningful destructive ones.

#### One consistent action budget

| Intent | Action budget from an open collection | Desired interaction |
| --- | --- | --- |
| Browse next fragrance | **1 gesture** | Swipe/flick/snap with no button |
| Inspect the focused art | **1 tap** | Matched-source expansion |
| Flip to scent map | **1 tap** | Clear front/back control or tap |
| Save a curated demo fragrance | **1 tap** | Add to Mine; keep original art |
| Record wearing a saved bottle | **1 tap** | Wear Today + gentle acknowledgement/Undo |
| Find existing bottle | **1 tap** to search | Fast, focused search |
| Add new owned fragrance | **≤3 taps** for known catalog entry | Search → Select → Add; manual form available for custom records |
| Switch modes/theme | **≤2 taps** | No reset of card selection or data |

### 5. Motion and feedback grammar

All timing figures are initial tuning ranges, not fixed animation-duration tests:

| Event | Start behavior | Target settling character |
| --- | --- | --- |
| Touch down | Immediate, subtle lift (~1–2% scale max) | Never delays the drag |
| Scroll and snap | Tracks finger, then kinetic projected landing | ~250–400 ms velocity-aware spring with little overshoot |
| Expand card | One continuous object into inspector | ~350–500 ms smooth matched transition |
| Flip card | Single perspective rotation | ~450–600 ms with stable sharp text at rest |
| Change Stack/Fan/Cover Flow | Same objects rearrange | ~400–650 ms, no opacity-reset cheat |
| Ink wordmark | Draws once on first run | ~1.2–1.8 s; skip/reduce as needed |
| Theme swap | Surfaces interpolate | ~200–350 ms; card photo unchanged |

Use one spring/damping vocabulary across all layouts. Haptics only on selection snap or meaningful completed events where supported; a web app cannot claim native Core Haptics or Liquid Glass APIs. Record an honest parity gap for any requested SwiftUI-native functionality. On Reduce Motion, flatten parallax/perspective travel, show clear discrete state transitions, and retain tappable alternatives.

### 6. Engineering plan (make changes in this order)

**A. Lock and inspect source assets**

- Verify all master PNG files exist in the branch and match SHA-256 hashes. Compare against the owner-approved Dior/Hawas/YSL designs; acknowledge Prodigy and Prada as historical. Don't burn time generating new designs. Build a simple deterministic crop/export script with an idempotent manifest; do not hand-paint the pictures.
- Derive front/back images, inspect all four borders, copy and cap silhouette at phone scale. For different input aspect ratios, store explicit per-card bounds. Keep original source PNGs as immutable assets. Make a short asset QA proof contact sheet from actual saved images.

**B. Integrate real assets before polishing anything else**

- Replace `CARDS` demo image lookups to use `production/*/front` and `back`. Keep the saved `artKey` mapping stable across demo, owned, export/import, and reload. Preserve short textual notes outside imagery for VoiceOver/search. Preserve historical demo fixture behavior for non-curated bottles. Remove the eight synthetic front/back SVG stand-ins from the **runtime path** after the real art works; they may stay archived until a cleanup commit if references are documented.
- Update `sw.js` only for cache version and production art, with an offline fallback that does not block boot; test fresh and cached visits. Correct image memory usage by lazy-loading distant cards (the UI still needs instant nearest-neighbor flipping).

**C. Refine presentation without rewriting the data model**

- Create a small set of shared motion/material/type tokens, then align header, gallery, inspector, collection, sheet, empty states and controls. Fix the intro wordmark path, center card sizing, responsive title layout and light/dark. Improve card focus, perspective and snap in existing geometry functions. Use a single shared card renderer/view model across layouts.
- Preserve ownership actions and ergonomic one-tap choices. Do not introduce multi-screen onboarding, forced account, feature wall, ad system, monetization, or external data dependencies.

**D. Release**

- Deliver one coherent PR against `main` with clear actual-art screenshots at **393×852** in dark and light, and one video/screen recording of a finger-led Cover Flow → Inspector → Flip → Mine flow if practical. Include the asset-manifest hashes and the brief rights/provenance note. Merge after the compact QA gate, not after an endless refactor.

### 7. Lean acceptance gate (do not overtest)

**Test strategy:** The previous `main` passed **218/218** browser smoke cases; this work is concentrated on *image integration, presentation and gesture correctness*. Retain existing protections, but don't run them on every intermediate tweak or create hundreds more tests. Execute the following small manual/automated matrix first, then a **single final required CI run** on the combined PR/head commit. Fix critical red checks; avoid manipulating tests to manufacture green. Do not disable repository protections.

1. **Visual fidelity:** three approved original source images match checksums; each front/back face is derived without cropping logos/foil/bottle/notes; no shipping placeholder SVGs for the three V3 cards; nearest phone-scale screenshot is clearly photorealistic and text is readable.
2. **Three core actions:** Cover Flow swipe and settle, focused card inspect+flip and close, one-tap demo Add to Mine followed by preserved artwork after reload. Include a single edit/history check because PR #10 fixed the back-face click hit-testing.
3. **No data regression:** old owner collections load, wear log still one tap, export→restore round-trip works, demo remains separate and duplicate add does not multiply records. Don't clear real local storage for test setup.
4. **Three widths, two appearance modes:** 375, 393 and 430 CSS px. One dark and one light screenshot, no clipped wordmark/header/card, no horizontal overflow, hit targets readable and ≥44 px. Reduce Motion shows legible non-animated states.
5. **Offline/PWA:** after one load, selected artwork and saved collection survive an offline launch. The cache updates after deployment; no old SVG remains permanently pinned by the service worker.
6. **Publish:** PR merged only with required checks green; Pages reports success; verify the served version shows the original art (not just the spec or a local screenshot). If a hard block remains, give the exact error and leave a small fix PR, not an unfounded “shipped” claim.

Do not use a superficial 218/218 count as a proxy for aesthetics. Screenshots and direct touch behavior are first-class release proof. Do not pretend a desktop Chromium headless run establishes physical iPhone touch quality; say what is device-tested and what is not.

### 8. Definition of *final*

- A person opens Arooma on iPhone and sees a considered, complete luxury product, not a web component gallery.
- The **three locked V3 artworks are unmistakably the original images**: real bottles, photographic top-note scenes, foil and refined typesetting. The original full diptychs and their checksums remain in the repo. Prodigy/Prada are preserved honestly as historical sources, not falsely promoted as locked V3.
- Cards feel responsive, grounded, elegant and coherent across Cover Flow, Stack, Fan and Inspector. Highlights respond to interaction, and the content remains sharp.
- First run welcomes with real calligraphic writing and a fast entry; returning use has no intro friction.
- A user can find a bottle, collect it, inspect its notes, wear it, and export/restore their archive without hunting through submenus. Nothing destructive happens to prior saved bottles.
- Four 60:30:10 themes look intentional in both soft dark and warm light. UI sans, editorial serif and one calligraphic brand mark never compete.
- The finished PR includes **actual screenshots**, a concise verification report, and a known-limits note about PWA-native differences and third-party artwork rights.

**Out of scope for this pass:** native SwiftUI rewrite, Apple App Store submission, ad SDK/IAP, cloud accounts, automated web scraping, image re-generation, a new database, speculative fragrance AI, or changing approved photographic art. The objective is one coherent Arooma V2 final polish, not an adjacent project.