# Native Target Override (2026-10-30)

**This supersedes all PWA / `index.html` / GitHub Pages targets in the repository.**

## Goal
Build a polished native SwiftUI iOS 26+ app that can be demoed immediately in the iOS Simulator. No TestFlight, no device provisioning, no App Store install required for the demo path. Clone the repo, open the Xcode project, and run.

## What is preserved (do not compromise)
- All design objectives in `docs/design/brand/BRAND_BOARD.md`
- Photographic card art masters and production assets
- Interaction rules, action budget, Cover Flow / Stack / Fan, local-first data model, Demo/Mine separation, wear log, rotations, search, inspector, liquid physics semantics
- Four 60:30:10 themes, typography system, content-vs-control layering
- Liquid Glass **only** on the functional/navigation layer. Never on cards or content.

## What is retired
- Single-file PWA (`index.html`, `sw.js`, `manifest.webmanifest`)
- GitHub Pages deployment as the primary demo
- Any instruction to "preserve the PWA" or "improve in place" on the web app

## Delivery
SwiftUI project that builds and runs in Simulator. Use production assets from `assets/collectibles/production/`. Follow Apple HIG materials rules for iOS 26+.

Reference the full design and interaction specification in `AROOMA_V2_FINAL_POLISH_SPEC.md` for everything except the former PWA delivery vehicle.
