# Louis Vuitton Imagination — Scent World animation handoff

Follows [ANIMATED_SCENT_WORLD_PIPELINE.md](../../../docs/design/brand/ANIMATED_SCENT_WORLD_PIPELINE.md). Start from the hash-pinned `candidates/imagination-v2-keyframe.png`, NOT the old PR #48 static front. This is a keyframe **candidate** pending visual owner review, never a substitute for motion.

## Higgsfield 8-second image-to-video

Use Seedance 2.0 image-to-video, portrait; reference the finished 880x1168 still. Target 8 seconds, 720p or higher, muted. Do not regenerate scenery outside the bottle.

> A seamless eight-second macro cinematographic shot of a miniature Mediterranean scent world INSIDE the transparent blue-green Louis Vuitton Imagination bottle of the reference frame. Completely locked-off front-facing camera. Black circular perfume cap and glass contour, IMAGINATION typography, outside-bottle almost-black studio backdrop, Arooma collectible card frame and title remain pixel-locked and still; no camera zoom, bottle rotation, scene cut, morphing, typography changes, confetti or decorative overlays. INSIDE the tiny bottle, visible independent richly textured real-world motion: bright turquoise sea waves physically advance and retreat and the liquid reflections move across the limestone, citrus and neroli leaves sway in a gentle coastal breeze at several depths, fine volumetric black-tea steam curls upwards from a miniature tea pavilion, high clouds drift slowly above a distant coast and sunbeams gently change between clouds. Rich cinema-grade layered parallax ONLY in the contained diorama and no movement on card or studio background. Clearly visible motion at beginning, middle and end, coherent physical continuity, leisurely premium pacing. Last frame naturally returns to near-first-frame state for a graceful loop. Preserve exact bottle recognizability and readable lettering, foil is applied separately in native renderer, not in generated motion.

**Quality test:** independently moving sea, foliage, tea steam and atmosphere (>=3 regions); stable edges/text/cap; no fake global displacement or swirl; no motion confined to the bottom right corner. Never declare success from tool job submission alone. Compare sampled frames at 0, 2, 4, 6, and ~8 seconds, inspect seam, probe codec/fps, hash the actual MP4.

## Assembly

- Use the rendered video as the card's animated front. Card shell, typography and border remain fixed.
- Use existing native `FoilLayer` only on an independent non-video overlay, following Aventus PR #47. **No AVPlayerLayer inside a Metal colorEffect**.
- Extract poster from exact final video (do not use a different still), include original reverse, and bundle video and poster into Xcode resources and Scent World manifest.
- Register `imagination` in the same focused-front AVPlayerLooper routing as Aventus, with offscreen/flip/background/Reduce Motion gating. Keep the reverse note-map available.
- Verify physical-device playback, SwiftUI frame and memory behavior, offline, CI Debug+Release. Merge only after passing real-motion and binary checks.

**Production blocker when this branch was created (2026-11-02):** Higgsfield showed 3.29 credits available; 8 seconds at Seedance 2.0/720p was quoted at 36 credits. This is not a finished video, and the branch must stay unmerged while video rendering remains unavailable.
