# Arooma: instructions for coding agents

For Codex, Cursor, Grok Build and any other tool that reads `AGENTS.md`.

Arooma is a personal cabinet for a fragrance collection, shipped as an installable iOS web app. The whole app is `index.html` (one self-contained file), tested and deployed to GitHub Pages by `.github/workflows/pages.yml`.

All design guidance lives in one place: **[docs/design/README.md](docs/design/README.md)**. The block below is generated from `docs/design/RULES_CARD.md` (`npm run docs:sync`); do not edit it here. Plans and specs follow [docs/design/PLAN_SPEC_PROTOCOL.md](docs/design/PLAN_SPEC_PROTOCOL.md). Setup for each AI tool: [docs/design/AI_TOOL_SETUP.md](docs/design/AI_TOOL_SETUP.md).

Commands: `npm start`, `npm run docs:check`, `npm test`, `npm run assets`.

<!-- design-rules-card:start -->
**Start here:** `docs/design/README.md` (router). Plans/specs: `docs/design/PLAN_SPEC_PROTOCOL.md`. Visual authority: `docs/design/brand/BRAND_BOARD.md`; V2 spec in `docs/design/specs/`.

**Look**
- Arooma is a private premium fragrance archive. The object and collectible card are the hero; not a storefront or noisy game screen.
- V2 themes follow 60:30:10: Obsidian Gold, Ivory Oud, Violet Ink and Emerald Resin. Light/dark: navy/plum and bone/cream; avoid pure black/white.
- SF Pro utility, editorial serifs for titles, calligraphy for wordmark only.
- 59:86 opaque collectible faces, selective foil edge, glass only on controls.
- Dior Archive Foil v3: front verified top notes; reverse horizontal note strips; concentration, not rarity badges.
- Preserve owner photos, liquid physics and local records.

**Behavior**
- Returning users skip intro. First run: calligraphic `Arooma`, demo/own buttons and themes. No cabinet doors.
- Demo/own stores are separate; one-tap switch. Never mix.
- Selection persists across Cover Flow/Stack/Fan; drag snaps by velocity, tap/keyboard paths and reduced motion.
- Card tap flips notes; Details opens ownership; Wear, Test, Search and Add are immediate.
- Haptics only for selection settle, wear confirmation and completed actions. Island is an in-app testing timer, not a permanent badge.
- Estimates and note overlap never become promised accuracy claims.

**Boundaries**
- Seven fictional demo bottles and four independent branded illustrations; no endorsement or scraped images.
- Rights follow `docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md`.
- No new backend, account, analytics, ads, or IAP without a dedicated implementation spec.
- Preserve self-contained PWA; never claim it is SwiftUI.
- Never force-push `main`.

**Verify**
- 375/390/430 px, landscape, reduced motion, no overflow, offline cards, fast entry.
- `npm run docs:check`, `npm run test:docs` and `npm test` before merge. iPhone Safari, Home Screen install, touch physics and haptics need real-device validation.
- Existing owner backups, photos, saved rotations, migration and Undo remain intact.
<!-- design-rules-card:end -->
