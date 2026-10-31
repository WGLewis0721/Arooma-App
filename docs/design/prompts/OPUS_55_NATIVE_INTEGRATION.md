# Claude Opus 5.5 — Arooma native premium interaction + supplied signature integration

> Part of the [Arooma design brain](../README.md). Earlier native interaction and signature handoff.
> Summary: Integrate the approved animated calligraphy assets and polish SwiftUI card physics and tilt-reactive holographic material; the separate Wishlist/discovery prompt governs newer capture and search requirements.

## Role and goal

Act as Arooma's principal native iOS motion engineer and luxury digital product designer. Deliver a coherent, responsive, production-quality native SwiftUI fragrance collection experience worthy of a $25/year subscription. Implement substantive changes in real source; do not deliver another cosmetic mockup or stop after planning.

## Repository and source of truth

Repository: https://github.com/WGLewis0721/Arooma-App

Read these files **before editing**:
- `docs/design/specs/2026-10-31-native-premium-motion-interaction-system.md`
- `assets/brand/AROOMA_SIGNATURE.md`
- `docs/design/brand/BRAND_BOARD.md`
- `ios/AroomaNative/WelcomeAndInspector.swift`, `DeckMotor.swift`, `DeckPhysics.swift`, `MaterialLight.swift`, `HoloFoil.metal`, and the galleries.

Review the recent merged native motion and Codemagic fixes. Retain tested working architecture, stored fragrance collections, personal photos, renamed shelves, wear history and layered combinations.

## Non-negotiable: integrate the already-created logo, do not make another one

The **definitive original Arooma signature** and two finished Higgsfield writing-animation clips are already committed:
- Vector logo: `assets/brand/arooma-signature.svg`
- Pixel-perfect transparent ink: `ios/AroomaNative/Assets.xcassets/AroomaSignature.imageset/arooma-signature.png`
- Light intro: `ios/AroomaNative/Resources/AroomaIntroInkLight.mp4`
- Dark intro: `ios/AroomaNative/Resources/AroomaIntroInkDark.mp4`
- Provenance/usage/acceptance: `assets/brand/AROOMA_SIGNATURE.md`

**Do not redesign, refont, regenerate, trace anew or reanimate the wordmark from scratch.** The current Snell Roundhand `Text("Arooma")`, left-to-right rectangle wipe, and generic underline in `WelcomeScreen` must be replaced by integrating these committed assets. Add the MP4 files to the Xcode target bundle, implement one-shot, silent, theme-aware seamless playback that finishes on the canonical static logo, and preserve optical center, letter geometry, scale, and every flourish. Playback has to feel like ink arriving through a real pen stroke, not a clipped text reveal. If generated video deviates from the master lettering, mask/constrain its pixels to the provided alpha silhouette or transition imperceptibly to the final PNG; don't alter the brand identity to fit the video.

Respect light/dark appearance, transparent static fallback, Reduce Motion, VoiceOver, scene restoration, interrupted playback, Low Power Mode, and first-launch-only behavior. Returning owners must bypass the intro; expose optional replay in the existing consolidated options menu. Do not introduce splash-screen blockers or new onboarding friction.

## Card physics and genuine holographic material

Continue the existing physical deck engine and all three layouts. Eliminate miscentering, card skipping, discontinuous overlap, unresponsive gestures, and disjoint inspection transitions. Maintain one continuous finger-driven position/velocity model with realistic inertial releases, interruptible springs, dimensionally coherent perspective, edge thickness, depth and contact shadows; inspector gestures and layout morphs must share the same spatial logic.

Upgrade the existing Metal foil renderer and Core Motion connection to visibly change **angle-dependent iridescence, diffractive holographic foil, directional specular highlights, and subtle parallax** from phone tilt, card pose and touch. A completely stationary card must change its reflections when the owner tilts only the physical iPhone. Light must travel coherently across the card and metallic areas, never appear as an independent looping rainbow wash. Leave original bottle photos and card lettering sharp. Idle glints remain rare, low-energy and subordinate to immediate touch or tilt.

## Product interactions

Bring Apple-quality polish, motion, restraint and useful system capabilities to onboarding, glass/material hierarchy, inspector, Quick Add, shelf overview with pinch zoom, shelf renaming, the combined theme/view switcher in the options menu, navigation, and the intuitive Wear Log for layering two or three fragrances. Quick Add must let someone capture a bottle photo or a name in 10–15 seconds; preserve that quick capture even before full metadata is available. Make essential tasks achievable with minimal steps, clean touch targets, haptics and motion accessibility.

## Performance, verification, delivery

Profile the existing foil shader and the signature video on an actual iPhone where available; no claim of verified 60/120 FPS based on a simulator alone. Minimize GPU overdraw, memory and decoding work, pause sensors when invisible, and support thermal and low-power degradation. Run automated native tests and build CI; exercise left/right reversal, rapid flicks, layout switches, flip interruption, tilt-only shimmer, layered wear saving, intro skip/replay, appearance switch and returning-user resume. Clearly label anything not measured on device.

Make a reviewable PR with native source implementation, tests, real before/after motion evidence and a short acceptance checklist. **The logo and motion files are complete inputs, not prompts to generate replacements.** The deliverable is an integrated product, not another spec or an alternate concept.
