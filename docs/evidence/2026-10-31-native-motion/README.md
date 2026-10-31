# Evidence: native premium motion (2026-10-31)

> Part of the Arooma design brain. Start at [../../design/README.md](../../design/README.md). Implementation record: [spec section 12](../../design/specs/2026-10-31-native-premium-motion-interaction-system.md#12-implementation-record-2026-10-31-branch-featnative-physical-deck-motion).

Everything here was produced by the **Native iOS 26 SwiftUI Build** workflow on a GitHub `macos-26` runner (iPhone 17 Pro simulator, iOS 26). The "before" app is `main` at `baf7a44`; the "after" app is this branch. Both start from the same seeded archive (`ios/Tests/capture.sh`).

| File | What it shows |
| --- | --- |
| `compare-01-welcome.jpg` … `compare-05-mine-gallery.jpg` | Same state, before vs after: first run, Cover Flow, Stack, Fan, owner collection |
| `compare-06-shelves.jpg`, `compare-07-today.jpg`, `compare-08-inspector.jpg` | After only. These screens exist on `main`, but `main` has no launch hook the capture script can use to open them |
| `autoplay-deck-and-morph.gif` | Screen recording of the **real deck engine** driven by a scripted finger (`-AroomaAutoplay YES`): drag, flick, reversal mid-settle, slow release springing back, Cover Flow → Stack → Fan morphs |
| `autoplay-inspector-flip.gif` | Zoom into the inspector, a scrub through edge-on and back, a flick flip, and the zoom back to the deck |

The full-length MP4 and raw logs are in the workflow artifacts `Arooma-After` / `Arooma-Before-After`.

## Frame pacing: what was measured, and what it does not prove

The in-app probe (`-AroomaFramePacing YES`) times every CADisplayLink frame while the deck or flip is animating. On the **CI simulator** (virtualized GPU, no ProMotion), unrecorded autoplay, 3-second windows:

| Build | Material | fps per window | hitch time |
| --- | --- | --- | --- |
| commit `6ad8e0c` | Live foil on up to 3 cards | 10.2, 13.3, 21.9, 18.7, 25.1, 20.2, 25.1, 35.2 | 408–829 ms/s |
| commit `6ad8e0c` | Foil shader off (`-AroomaFoilOff YES`) | 24.6, 35.5, 27.0, 42.0, 39.2, 45.0 | 245–585 ms/s |
| commit `22c5b0c` (different runner) | Live foil confined to the centre card | 6.7, 9.6, 12.1, 13.1, 10.4, 18.1, 12.2, 13.8, 12.6 | 697–888 ms/s |
| commit `22c5b0c` (same runner) | Foil shader off | 13.6, 17.7, 23.5, 18.1, 29.6, 23.8, 15.8 | 503–771 ms/s |

Runner-to-runner variance is large (the foil-off rows differ by ~1.7× between two runners), so numbers from different runs cannot be compared. Within one runner, turning the foil shader off roughly doubles simulator frame rate both times.

These are **not iPhone numbers**. A simulator on a CI VM renders through a virtualized GPU and is far slower than A-series hardware, so it can only rank relative cost: the foil shader was the largest single cost. Following that, the shader was confined to the card at the centre and the per-card live blur shadow was replaced by a pre-rendered sprite. **Device frame pacing (spec acceptance criterion 8) still has to be measured on a real iPhone** with the same probe, and the result recorded here.
