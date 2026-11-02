# Animated Scent World production instructions

All living Scent World assets MUST follow [the dedicated 10-stage animated production spec](../../../docs/design/brand/ANIMATED_SCENT_WORLD_PIPELINE.md). A static PNG is not complete animated artwork.

# Arooma · Living Scent World (Aventus)

This is a **real 8-second AI-generated animation** of a miniature fragrance world embedded in a premium card frame. It is not an oscillating image, depth filter or overlay-only effect.

- Model motion source: Higgsfield/Seedance 2.0, 8-second AI image-to-video of the original Aventus Scent World.
- Card master: static gold/foil card border and scent information composited over the genuinely moving Scent World.
- Verified MP4: H.264, 720 × 1050, 8.000 seconds, 24 fps, silent; SHA-256 `2ecbb30aa08006e73d0988d33f63abb888274e142f851a55e0a5cd10c98ab1e1`.
- Hosted owner-created video: https://d2ol7oe51mr4n9.cloudfront.net/user_3IkKBBXHZvEZQt2d8pBaRYd083T/c8178739-0924-4668-a8d2-52449cfc34b0.mp4
- Repository ingest: the commit-triggered GitHub Action downloads the master, verifies its immutable checksum, extracts a poster, and commits both resources to this feature branch.
- Native: `LiveAventusScentWorldCard` in `Artwork.swift`; `CardFace` selects it for the front of `aventus`. Only the focused card plays. When the app is backgrounded, flipped, off-center or Reduce Motion is enabled, playback stops or shows a poster. AVPlayerLooper repeats the bundled clip. Until ingested, the same exact hosted MP4 is a development fallback, subject to network access.
- The owner's actual preview remains usable on iPhone: https://d2ol7oe51mr4n9.cloudfront.net/user_3IkKBBXHZvEZQt2d8pBaRYd083T/c8178739-0924-4668-a8d2-52449cfc34b0.mp4

**Review gates:** preview on an actual iPhone, confirm moving sunrise/valley/leaves, frame registration and text readability, flip and swipe behavior, Reduce Motion, thermal impact, and offline resource loading. Do not claim TestFlight release or rights clearance from this PR. This project is independent of Creed and is not endorsed by its fragrance house. See `docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md`.

## Native video/Metal compatibility fix (November 2026)

The AVPlayerLayer must **not** be passed through the card's Metal `colorEffect` / `LiveFoil` pipeline. That produced a bright prohibition placeholder on the iPhone even with a valid MP4. `AtelierCardSurface` now keeps the AVPlayerLayer untouched and applies `LiveFoil` only to an independent SwiftUI vector-gradient overlay. Existing holo treatment on static cards stays unchanged. A bundled poster is always underneath the player, and the bundled local MP4 is the only playback source. The front stays live, the reverse shows verified note groups. The native CI verifies both binary files in the compiled app bundle. Runtime playback on physical iPhone still needs owner verification after the new build.

## Louis Vuitton Imagination — approved two-sided static card

- Front: Scent World lives inside the aquamarine Imagination bottle, on a plain dark studio background.
- Reverse: Minimal structured fragrance note map; two-sided design with matching iridescent edge.
- Both images are the owner-selected Higgsfield generations listed in the manifest. Their SHA-256 hashes are checked at ingestion.
- Native ID `imagination` is registered in the catalog and backed by the two bundled PNG resources.
- `ApprovedArtwork.image(for:side:)` loads the exact files without resizing or rewriting them; the deck's existing SwiftUI foil, gestures, Cover Flow/Stack/Fan, and flip work as for other static approved artworks.
- **Not animated**: these are still images. This merge does not purport to contain an Imagination video. A separate video generation and native playback integration would be needed for the moving Scent World.
- Independent Arooma artistic interpretation; no implied Louis Vuitton endorsement.
