# Animated Scent World collectible — required production procedure

> Summary: Mandatory 10-stage research-to-live-video workflow for bottle-contained Scent Worlds, including independent environmental motion, offline SwiftUI looping, separated holographic foil, quality gates and release checks.

**Design map:** [Arooma design brain](../README.md).

**Status: required for any Arooma card described as "animated Scent World".** This procedure is specific to the *living miniature environment inside a recognizable fragrance bottle* card type. It does not apply to ordinary still-image cards. The approved reference implementation is Creed Aventus (PRs #46 and #47). Louis Vuitton Imagination PR #48 was a **static-only** delivery and does not satisfy this procedure.

## Definition of done

A finished Scent World is a **real, independently moving 6–10 second miniature cinematic environment, contained inside the fragrance bottle, on a fixed premium collectible card**, with an independent motion-responsive holographic foil treatment, accurate fragrance identity and a usable reverse. The card plays offline, muted, and continuously on the focused front face on iPhone; it pauses when flipped, off-center, inactive or Reduce Motion is enabled. A static image with a SwiftUI shader, particle overlay, fake wobble, lens distortion or moving foil is NOT an animated Scent World.

## Required sequence — do not skip or reorder

1. **Research the fragrance.** Record official house/product reference, year, concentration, bottle silhouette/cap/color and supported top/heart/base notes. Distinguish official notes from interpretations. Link sources in the asset manifest or research notes. Never invent a note or manufacture an affiliation with the house.
2. **Design the card.** Begin with Arooma's approved 59:86 visual grammar: restrained premium border, legible permanent title/house/type, stable frame registration and defined front/reverse. Establish separate layers for card frame, bottle, world clip, and native holographic foil. The card is NOT a full-screen fantasy landscape.
3. **Make/verify the bottle.** Use a lawful product reference and validate silhouette, proportions, cap, glass/liquid tint and typography against evidence. Aim for high recognition without misrepresenting the artwork as official advertising; preserve negative space and a neutral studio surround. Brand logos identify the recorded fragrance, not Arooma's publisher or sponsor.
4. **World building.** Translate scent notes into a coherent *miniature* scene inside the glass, with foreground/midground/background and physically plausible motion opportunities. The scenery may NEVER spill into a distracting external background. Make a finished still keyframe with a fixed camera/composition before animating. Keep glass edges, neck, cap, labels, and card typography fixed.
5. **Animate, render and verify actual video.** Feed the approved keyframe to Higgsfield image-to-video (Aventus used Seedance 2.0 for 8 s). Animate multiple independently identifiable scene regions: e.g. waves moving and reflecting, clouds drifting, foliage shifting, steam rising, a sunbeam tracking across architecture. Require at least THREE distinct genuinely moving environmental regions visible on sampled frames; reject motion restricted to a corner, a global transform, camera zoom, simple looped displacement, overlays or flicker. Keep product text/cap/frame anchored. Render muted H.264 MP4, preferably 8 s, 24 fps, approximately 720×1050 or higher at 59:86 crop, with stable first/last-frame loop and no jumps. If credits, model access or reference media are unavailable, mark the asset BLOCKED and do not substitute static motion while claiming completion.
6. **Build the moving card.** Composite the *video* into the approved card shell, maintaining exact frame alignment; permanent title and foil frame remain stable while the interior environment moves. Do not bake all motion away into a poster. Maintain the matching informational reverse (notes, no bogus rarity or performance claims).
7. **Holographic foil.** Preserve Arooma's multi-hue, tilt-reactive foil/edge finish above the card. **Never put AVPlayerLayer through the Metal colorEffect/LiveFoil shader.** Keep the video as a separate untouched layer; apply the shader to a separate SwiftUI vector-gradient/glint overlay. This fixes the iPhone yellow-prohibition-frame regression from Aventus.
8. **Export and provenance.** Export the exact finished silent MP4, a poster extracted from that MP4 (not a different illustration), reverse art, a machine-readable manifest with source and SHA-256 and model/prompt/verification metadata. Prefer checked-in offline media in ios/AroomaNative/Resources; any ingest action MUST verify hash and commit completed binaries before merge. A URL-only development fallback does not qualify as offline delivery.
9. **Integrate into native card collection.** Add catalog entry; register MP4/poster in Xcode project's resource build phase; route the focused front face to the shared AVQueuePlayer/AVPlayerLooper view, leave reverse and still-preview/export paths intact. Play only while front/focused/active and not Reduce Motion; pause/unmount elsewhere. Do not disrupt Cover Flow, Stack, Fan, flips, haptics, gestures, local-first storage or existing foil. Prefer extracting a reusable `LiveScentWorldCard` component rather than making fragrance-specific players.
10. **Validate and deliver.** Inspect frames across beginning/middle/end and quantify at least 3 moving regions. `ffprobe` codec/duration/fps/dimensions, SHA-256, first/last seam, static frame/label alignment and actual decoded scene motion. CI must compile Debug and Release, check required media in .app, and verify all manifest paths. Verify front, reverse, focus gating, Reduce Motion, background/offline, playback, foil and performance on an iPhone. Never call a still image plus holographic shimmer "animated"; never claim TestFlight/device validation until it happened. Only then merge the completed asset PR to main.

## Acceptance checklist for an asset PR

- [ ] Research and bottle identity documented, including independent-app/non-endorsement context.
- [ ] Card 59:86; world stays inside the bottle; exterior remains subdued.
- [ ] Final MP4 exists; scene movement independently visible in >=3 spatial regions, not mere warping.
- [ ] Bottle, frame, text anchored; clean loop, poster matches moving video.
- [ ] Holo foil stays visually responsive and is independent from AVPlayerLayer.
- [ ] Reverse has fragrance-specific accurate note information.
- [ ] MP4/poster/reverse are bundled offline; checksums and manifest match.
- [ ] Simulator Debug/Release and bundle-content checks passed.
- [ ] Physical-device review honestly marked verified or pending. **Do not claim full ship-ready before device playback inspection.**

## Imagination: target world and correction

Official profile emphasizes **Calabrian bergamot/citrus, Tunisian neroli, Nigerian ginger, Ceylon cinnamon, Chinese black tea, Ambrox/amber, Sicilian cedar**. Visual direction: soft Mediterranean dawn, bright citrus grove and flowering neroli in the bottle's foreground; a miniature tea pavilion and rising black-tea steam in the middle; calm luminous sea and pale limestone architecture in the distance. A physically separate bottle and card border remain still. Animate sea ripples/reflections, drifting mist/clouds, leaves, and tea steam with slow, deliberate timing. Keep the entire outside background dark, unobtrusive and still. Preserve the Imagination bottle's blue-green glass, black disk cap and simple silhouette. **The stills merged in PR #48 are only keyframe/reverse candidates, not proof of motion**.

Official reference: https://us.louisvuitton.com/eng-us/stories/imagination and https://en.louisvuitton.com/eng-nl/products/imagination-nvprod7340011v/LP0476

## Existing implementation references

- `assets/collectibles/scent-worlds/manifest.json` — cataloged assets and checksums
- `ios/AroomaNative/Artwork.swift` — Aventus looping player and poster and reverse
- `ios/AroomaNative/AtelierPrimitives.swift` — card selection and Metal/AVPlayer-layer separation
- `ios/AroomaNative/AtelierGallery.swift` — focused card state
- `ios/AroomaNative.xcodeproj/project.pbxproj` — bundle resources
- `.github/workflows/native-ios.yml` — simulator and offline-bundle verification
- `docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md` — legal/provenance rules

**Failure rule:** a still is a STILL; an unrendered prompt is a PROMPT; an accepted generation job is PENDING; a real finished and verified MP4 integrated with playback is an ANIMATED SCENT WORLD. Never conflate these stages.
