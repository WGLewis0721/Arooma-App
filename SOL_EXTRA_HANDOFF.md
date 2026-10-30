# GPT-6 Sol · Extra High — Arooma final-polish assignment

**Start here:** [AROOMA_V2_FINAL_POLISH_SPEC.md](AROOMA_V2_FINAL_POLISH_SPEC.md). **Read the entire spec before changing files.** The full source and revised visual rules live in `docs/design/brand/`, but the root final-polish spec is the owner's current task authority. **Project:** `WGLewis0721/Arooma-App`. **Product:** installable one-file iOS PWA, not a native SwiftUI app. **Live site:** https://wglewis0721.github.io/Arooma-App/.

## Nonnegotiable assignment

1. **Use the actual art already in this repository.** The owner-approved photographic diptychs are in [`assets/collectibles/masters/approved/`](assets/collectibles/masters/approved/): Dior Sauvage Elixir, Rasasi Hawas For Him and YSL MYSLF EDP. Earlier Prodigy and Prada artwork is at [`assets/collectibles/masters/historical/`](assets/collectibles/masters/historical/) and must not be represented as fully approved Archive Foil V3. **Do not** regenerate photographic bottle/card images, silently replace them with SVG approximations, or discard the masters. See the checksum ledger in the spec.
2. Preserve the useful current app. Refine its Cover Flow, Stack, Fan, inspect/flip, local collections, wear logging, search, offline use, backups, and four 60:30:10 themes. Change the existing code, not a detached prototype.
3. iOS-quality design: crisp photoreal cards at phone scale, immediate finger-led motion, coherent springs, exceptionally consistent margins and typography, dark navy/plum or warm bone/cream backgrounds, carefully restricted foil/glass, a deliberate fountain-pen Arooma wordmark, minimum obvious chrome. Prioritize **taste and touch** over effects and feature count.
4. Primary actions should take ≤3 taps; inspecting/turning a card, saving a curated bottle and logging a wear should take one. Keep collectible **fragrance map** separate from personal **My Bottle** record. Returning users see their last shelf directly, not a mandatory splash.
5. **Lean verification only.** Source checksum/face-crop visual inspection; Cover Flow→Inspector→Flip→Add to Mine→reload; owned wear/history/edit; backup round-trip; 375/393/430 width and light/dark; offline cache. Run existing required CI **once on final changes** when possible, not after every tweak. Do not remove relevant tests to make red green; do not falsely claim physical iPhone testing or native Core Haptics.
6. One focused PR, screenshots of the **real app**, final Pages verification, and a concise changelog of what improved versus what remains limited by the web platform. Do not claim deployment until GitHub reports Pages success.

## Implementation first step

Open and inspect each original master, confirm the locked Dior design (large grapefruit + top-note names, **no Ultra Rare**), Hawas (lavender glass / green apple, **2015 EDP**), and MYSLF (black sprayer / bergamot, **2023 EDP**). Split front and back **losslessly without clipping foil or titles**; preserve the originals, create clearly named production assets, replace the eight simplified demo SVGs as runtime artwork, update `sw.js`, and inspect the result on an actual iPhone viewport before considering deeper motion polish.

## Stop conditions

Do **not** overwrite saved user collections. Do **not** silently copy from manufacturer photo sites or claim permission based on Yugipedia's disclaimer. Do **not** hide source-resolution limits behind an AI upscale. If an original source cannot be found, name the exact missing asset and keep the last approved card visible; don't improvise an aesthetically different replacement. Rights basis for public distribution remains subject to `docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md`.