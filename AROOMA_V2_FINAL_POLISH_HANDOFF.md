# AROOMA V2 → FINAL: SOL EXTRA PRODUCTION HANDOFF
**Owner-directed execution brief • 2026-10-30 • Read this FIRST from repo root**

> **For GPT-6 Sol at Extra thinking effort.** Finish the current Arooma app with the **exact owner-approved photographic collectible cards** already committed in this repository and with the polish, motion, restraint and internal consistency of a flagship iOS product. **This is a final integration and art-direction pass, not a redesign, a mockup, a new app or a rewrite.** Do the work in code on a focused branch, provide a usable iPhone preview, and merge when the concise release gate passes. The user does NOT want an essay, more low-resolution SVG recreations, gratuitous testing or an unshippable plan.

**Repository:** `WGLewis0721/Arooma-App`  
**Current demo:** https://wglewis0721.github.io/Arooma-App/  
**Current production form:** installable iPhone-oriented **single-file web app** (`index.html`, service worker `sw.js`), **NOT native SwiftUI**. Make the shipped web demo exceptional. Do not market ordinary CSS as Apple Liquid Glass, Taptic Engine or native SwiftUI.  
**Primary authority:** the three real, exact source PNG diptychs in [`assets/collectibles/masters/approved/`](assets/collectibles/masters/README.md). The handwritten card art has been APPROVED by the owner; the V2 low-detail illustration substitutes are NOT approved for final use.  
**Other required references:** [Archive Foil v3](docs/design/brand/COLLECTIBLE_CARD_ART_DIRECTION.md), [production guidance](docs/design/brand/COLLECTIBLE_CARD_PRODUCTION.md), [V2 current-state spec](docs/design/specs/2026-10-30-v2-collectible-gallery-implementation.md), [brand board](docs/design/brand/BRAND_BOARD.md), [third-party rights policy](docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md). The user-approved image wins over instructions in any stale V1 or V2 passage.

## 0 — Non-negotiable success statement

On an iPhone, opening Arooma should feel like entering a discreet couture fragrance archive. It should respond the instant a finger touches a card, snap with satisfying physical precision, show photographic artwork as sharp as its source permits, and present clear actions without clutter. The premium feeling comes from **motion continuity, correct optical layout, accurate material appearance, restraint, readability and zero friction** — not layers of shadows, additional controls, excess bounce or marketing-speak.

Do **not** ship a pixel-perfect functional shell populated with rudimentary placeholder cards again. **The actual previously approved artwork must be visibly used for the card front AND reverse in the app** before calling this final.

## 1 — First task: treat the committed exact artwork as the product

| Demo ID | Fragrance | Mandatory source file | Status |
| --- | --- | --- | --- |
| `c0` / `dior` | Dior Sauvage Elixir | `assets/collectibles/masters/approved/dior-sauvage-elixir-original-diptych.png` | **APPROVED** |
| `c1` / `hawas` | Rasasi Hawas For Him | `assets/collectibles/masters/approved/rasasi-hawas-for-him-original-diptych.png` | **APPROVED** |
| `c2` / `myslf` | Yves Saint Laurent MYSLF EDP | `assets/collectibles/masters/approved/ysl-myslf-edp-original-diptych.png` | **APPROVED** |
| `c3` / `prodigy` | MIND GAMES Prodigy | `assets/collectibles/masters/historical/mind-games-prodigy-original-diptych.png` | **HISTORICAL ONLY**; old `ULTRA RARE` label and layout violate v3 |
| Historical | Prada Luna Rossa Ocean | `assets/collectibles/masters/historical/prada-luna-rossa-ocean-{front,back}-original.png` | **HISTORICAL ONLY**; not a locked v3 pair |

**Absolute constraint:** Do not ask an image model to remake the three approved cards, do not hand-draw bottle approximations, do not substitute the existing `assets/collectibles/cards/{dior,hawas,myslf}-*.svg`, do not re-render copy in a new font, and do not use the history assets as if approved final v3. Do not silently reduce raster detail, flatten the colors or recolor the artwork with the UI theme.

The exact source diptychs are in the repository as byte-identical originals, source resolution approximately 1470×1070 (Dior/Hawas) or 1536×1024 (YSL); **do not invent a 4K original or claim 1180×1720 original faces**. Each diptych contains front on the LEFT and reverse on the RIGHT, with small external dark matte/gutter. Preserve the original file forever. **Produce two lossless crop-only derived face assets per approved fragrance**, ideally `assets/collectibles/cards/photographic/{dior,hawas,myslf}-{front,back}.png`; remove only the outer matte, never any foil edge or card lettering. Visually inspect each crop once at 100% and at actual iPhone display size; all four corners must be intact. Maintain aspect ratio 59:86. Use a high-quality compressed derivative for delivery **only if** a side-by-side visual comparison demonstrates no perceptible degradation. Never change source data.

After creating six face assets, switch card rendering in `buildSlot` to these exact files. Do not make a new content route, rebuild the canvas or disturb `CARDS` IDs, selected-card state, the active theme, demo/own separation, or the `artKey` persistence on imported personal copies. The screen must use the photographic front and the photographic reverse, including after refresh, after flipping, after returning from personal details, and offline after installation.

**Status honesty:** Only three locked v3 photography pairs exist in the repo at handoff. Prodigy and Prada are preserved for provenance but **require owner approval before appearing as finished v3 cards**. Keep the older seven fictional sample bottles useful; if Prodigy remains in the demo, clearly distinguish it as a historical concept, not one of the three finished approved cards. Never promise four finished photographic v3 cards when only three are approved.

## 2 — Preserve what is working; repair what feels cheap

Current code has real working behavior. **Do not rebuild or overwrite it:**
- Cover Flow, Stack and Fan use a single selection and common card DOM; preserve swipe physics and current active item across mode switches.
- One-tap `Demo ↔ Mine` switch, one-tap `Add to Mine`, `Wear today`, `Test`, `Search/All Shelves`, `Add Bottle`, `Details`, shelf organization, editable ownership history, safe undo, offline service-worker support and backup/restore stay in place.
- Keep separate local databases for demo and owner, existing `artKey` behavior for imported collector art, no account requirement, no destructive migration, no unnecessary prompts.
- Keep the *functional* V2 fix that puts the reverse-side `Edit details` control outside the hit-test plane of the rotated card. Do not regress the 218-check passing post-merge baseline.
- Preserve first-time Arooma wordmark entry and skip it for returning users; remove residual hinged-cabinet visual leftovers instead of layering new intro effects over them.

**Remove friction:** a collectible can be viewed, flipped and added without visiting an unrelated screen. On owned cards, one tap records a wear; ensure demo cards never misleadingly allow wear tracking when their primary action is Add to Mine. Every action should be discoverable without a tutorial, require at most **three purposeful taps** from the main screen, and never play a mandatory cinematic interstitial between two normal actions.

## 3 — New visual and motion finish: "Luxury in Motion"

### Art direction and hierarchy
- The collectible card is the hero. A selected card should occupy a confident fraction of the available gallery height while preserving its complete border, shadow and foil. Avoid tiny cards floating in enormous negative space and avoid flattening important typography.
- The surrounding shell is a quiet museum set: soft navy/charcoal plum or bone/cream backgrounds, atmospheric but not smoky gradients, low-contrast supporting elements, gentle edge illumination.
- **Inside the card:** photo and existing printed typesetting remain exactly as approved. **Outside the card:** use restrained native-like typographic hierarchy and one coherent materials system.
- Native-feeling *structural* glass for navigation/sheets/segmented controls, not frosted glass laid over photographic card art. Emboss/deboss and foil should read as light interacting with materials, not ornamental UI wallpaper.
- The visual shell must work in portrait at iPhone widths **375, 390, 402 and 430 CSS px**, safe areas and installed PWA viewport; no horizontal scroll or overlap with Dynamic Island/home indicator.

### Motion grammar (one consistent system)
Use finger-driven transforms and velocity-aware springs; retune, don't replace the existing physics. Proposed timings are a starting feel, not hard-coded prescriptions:
1. **Touch down** is immediate: selected card gains a small lift (roughly 1–2% scale where space permits), tight shadow and controllable pressed state; **do not delay tap feedback**.
2. **Cover Flow** follows the finger, neighbors rotate/shift with consistent depth and opacity, and release settles to exactly one card with restrained momentum. No jitter, teleport or fractional unsettled state. Maintain the same card selection across re-renders.
3. **Flip** is one continuous 3D rotation (roughly 400–600ms), both faces stay in one spatial object, a thin edge is visible at midpoint, back is never mirrored, no other card steals hit testing, and tapping the card again returns to front. Keep the separate Details control accessible.
4. **Stack** peels the top card with coherent depth ordering and soft spring return; **Fan** opens like carefully handled physical cards around one anchor, selected card floats slightly forward. Both must keep the tactile behavior, not turn into separate click-heavy screens.
5. **Gallery ↔ all shelves** has spatial continuity (cards rearrange or zoom from the source); preserve selection and remove disruptive full-screen cuts.
6. **Foil highlights** are GPU-friendly overlays restricted to the thin outer foil/metal region, mapped from actual card tilt / drag velocity, with low amplitude and no shimmer across readable type or bottle label. When idle: static. Device orientation input is optional, permission-gated and never required; pointer-only lighting must be excellent.
7. **Confirmations**: one light discrete response for settlement and successful actions where supported by web platform. Never simulate native haptics by pretending iOS Safari can reliably vibrate.
8. **Reduce Motion**: no parallax, no camera tilt, and simplified transitions that preserve orientation and interaction. Respect native `prefers-reduced-motion` and users with lower-powered devices.

**Performance aim:** prioritize input latency and visual stability; target fluid **60fps** on recent iPhones, but only claim measured performance if it has been measured. Use transform/opacity, avoid layout-triggering per-frame DOM measurements, eager-load selected and immediate-neighbor card faces, lazy-load others, preload the selected reverse, pre-cache six exact assets with cache-version bump, decode before revealing new selections, and guard against a blank/replaced card during face swaps. Make animation constants shared, not ten unrelated CSS easings.

### Palette / typography: keep the approved V2 framework, improve execution

Theme | 60% dominant | 30% secondary | 10% metal accent | Editorial display | Controls
--- | --- | --- | --- | --- | ---
Obsidian Gold | `#161B24` | `#312B33` | `#B88B47` | Cormorant Garamond / Iowan Old Style | SF Pro
Ivory Oud | `#F3EBDD` | `#D8C4AA` | `#9F6A36` | Bodoni Moda / Didot | SF Pro
Violet Ink | `#1B1A28` | `#5D5266` | `#C9B6D9` | EB Garamond / Iowan Old Style | SF Pro
Emerald Resin | `#18211F` | `#4B5A55` | `#D1B68B` | Fraunces / Palatino | SF Pro

- Do not change the per-fragrance printed artwork with the global theme switch.
- **Dark** = soft navy/blackened plum/deep purple blend; not pure black. **Light** = bone white/soft cream/beige; not stark white. Test all four theme identities in both appearances for text contrast, semantic accent and visual hierarchy.
- Editorial fonts must be authentic, licensed and load predictably offline **if bundled**. Never ship unlicensed font files. Use native serif fallbacks if rights/weight not available; typography consistency beats a spectacular font that flashes or fails.
- Keep utility copy in SF/system, semantically distinct sizes/weights, correct optical padding, and minimally three font roles: display serif, SF utility, custom Arooma calligraphy wordmark. Do not change typography inside accepted PNGs.
- Buttons are 44pt-ish usable touch targets with calm labels and obvious state; avoid duplicate Add, Edit, Share or navigation buttons on top of the card face.

### Fountain-pen wordmark
- The introductory and optional outro use the word **Arooma** in modern fountain-pen/copperplate-inspired calligraphy informed by the user's attached lettering references: graceful pressure contrast, connected strokes, refined swashes and one restrained underline.
- A simple left-to-right text wipe is **not** authentic pen motion. Ideally use a custom outlined vector path with stroke-reveal in logical pen-writing order (or a segmented write-on mask closely following glyph strokes); preserve the final sharp wordmark for users with reduced motion. Do not use a stock cursive font if it looks unlike ink calligraphy.
- Show theme and light/dark controls on first entry with a single `Explore demo` / `My collection` decision. Return users should land directly on the card they last viewed. An optional wordmark replay from Settings is okay, but **do not force intro on every opening**.
- Entrance and exit should take only as long as needed to make the product feel premium; no multi-second wait to reach a bottle, no marketing loading screen.

## 4 — Concrete implementation sequence (make changes, do not endlessly re-plan)

1. **Audit current render path**, `CARDS`, `buildSlot`, `flip`, `render`, selection, `artKey`, face CSS, service-worker precache, theme state and current repo design notes. Do not refactor code that isn't involved.
2. **Extract the six exact face assets** from the three committed approved diptychs using pixel-preserving crop; commit both source originals (already present) and derived faces with a small face manifest showing original file hash, crop bounding box, output dimensions, face variant and source approval. **No regeneration or artistic reinterpretation**. Note if a matte remnant requires precision trimming.
3. Replace the SVG references only for the **three approved collectible IDs**. Keep older art sources in a clear legacy/historical location, not referenced as finished cards. Update image alt labels and loading hints; make the reverse always the exact actual approved back image. Populate owned copies consistently.
4. **Polish the selected card and fluid layouts** with a single transform grammar, crisp focus scale, border-aware foil lighting, proper pressed state, flip hit testing, material-correct shadow and natural transition to details. Prefer tweaking existing CSS/JS over a new animation library.
5. Refine the four theme tokens, calligraphic entry, header spacing, sheets, gallery spacing, buttons, typography, empty states and accessory UI **to support the card**. Eliminate gratuitous controls, low-contrast text, jarring colors, awkward vertical gaps and any fake luxury flourish.
6. Confirm direct user flows: first launch → select demo → swipe → flip → Add to Mine → Wear Today → return to demo; then search/selection, all shelves, backup. The user should not need an onboarding tutorial.
7. Update docs only where behavior changed. Add a short `CHANGELOG.md` entry and make one iPhone preview available after build; optional before/after screenshot is useful **if it proves fidelity**.
8. Merge a focused PR to `main` after the release gate in §5; do not create chains of draft PRs or do broad unrelated refactors. If CI reveals an actual bug, fix that bug specifically. Do not disable protection or bypass meaningful failures.

## 5 — Small but real release gate (no performative testing)

**Quality over check count.** Do not add a hundred screenshot assertions or rerun a giant browser suite after every one-line tweak. Run a targeted local smoke pass after the work settles, and **one** normal repo CI run at merge readiness. Existing CI may run its established suite automatically; do not waste days on redundant custom suites.

**Only six must-pass acceptance scenarios:**

1. **Exact image fidelity**: side-by-side comparison of each of the **three** approved front/back source PNG cards versus final rendered card at actual iPhone scale. Same photographic detail, foil edge, labels and colors. No SVG replacement, no missing back, no chopped corner. Asset hashes/source crop records exist.
2. **Interaction**: select → drag Cover Flow → flip front/back → Edit details on owned back → return; no intercepted taps or choppy settle. Check Stack and Fan selection continuity briefly.
3. **Ownership**: Demo → one-tap Add to Mine → photo/card preserved in own collection → Wear Today → refresh; demo/own data remain separate and no duplicate created.
4. **Adaptive UI**: iPhone narrow/wide in dark and light; all four themes preserve readable labels, stable navigation, safe-area clearance and no horizontal overflow. A representative screenshot of each appearance/theme suffices.
5. **Access and resilience**: reduced motion, keyboard/tab/VoiceOver names, image decoding fallback and offline revisit with exact card faces. No endless loading state.
6. **Build/deploy**: no errors in browser console on key flows; one final GitHub Pages workflow is green; confirm live URL serves the **new photographic card assets** with a bumped service worker version.

No mandatory pixel-diff CI of every screen, no 200-plus new tests, no false claims of device haptics or native fps. Do not break a passing gate just to simplify the test count. On failure, reproduce and repair the specific regression, rerun the narrow scenario, then a final full workflow once.

## 6 — Definition of finished: what to deliver

Deliver code and an iPhone-viewable preview, **not just a spec**:
- Original approved 3 × two-sided photographic masters **already in repo**; derived 6 × front/back card assets committed with provenance and properly rendered by the app.
- Three premium layouts (Cover Flow, Stack, Fan) using exact face assets, with tactile movement, polished flip and clear owning/wearing/searching actions.
- Four coherent theme choices and intentional light/dark mode; welcome wordmark looks drawn by pen, not a generic fade/wipe.
- Local-first collection intact, no required account, no loss of any existing user's data, no feature regression, and an installed-home-screen offline experience.
- Concise release note and PR link + merged commit + live preview link + test results. Explicitly list any deferred historically unapproved card (Prodigy/Prada) and any factual or rights-review blocker.

**Non-goals:** no SwiftUI app rewrite, no new user accounts, social network, ads, IAP, marketplace, cloud backend, loyalty game, bulk AI card generator, or fake manufacturer licensing. Do not reinvent our card designs.

**Last directive:** if the exact source art is present, **use it**. The user has already paid for the art direction in time and approvals; this task is to turn those approved images into an exceptionally polished, delightfully tactile Arooma experience. Think like an iOS motion designer, Apple-platform engineer, luxury editorial typographer, photographic art director and unusually picky product designer working together.
