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
