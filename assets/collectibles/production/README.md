# Production collectible faces

`tools/derive_collectibles.py` verifies each immutable master SHA-256 and splits its
left and right halves without resizing or trimming into any card artwork. It writes
quality 95 WebP faces, a manifest with output hashes and crop bounds, and a contact
sheet of the actual results. Rerunning the script is deterministic; it validates
each temporary export before replacing a production face.

| Card | Source status | Runtime use |
| --- | --- | --- |
| Dior Sauvage Elixir | Approved Archive Foil V3 | Original photographic front/back |
| Rasasi Hawas For Him | Approved reviewed card | Original photographic front/back |
| YSL MYSLF EDP | Approved original pair | Original photographic front/back, fitted to bezel without stretch |
| MIND GAMES Prodigy | Historical V2 | Archival label; existing Ultra Rare wording is retained, not described as V3 |

The exact source paths and checksums are in [`manifest.json`](manifest.json).
These files are owner design handoff assets. Their presence in the repository does
not establish rights for public catalog distribution, marketing or App Store use.
Provenance and permitted use require review under
[`docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md`](../../../docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md).
