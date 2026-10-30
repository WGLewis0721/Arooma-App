# Design rules card

> Part of the Arooma design brain. Start at [README.md](README.md) for the map and the router.

This card is the single source for the always-loaded design rules. `npm run docs:sync` copies the block below into `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` and `.github/copilot-instructions.md`, and the docs check fails if a copy is stale. Edit only here. Keep the block under 3,000 bytes.

<!-- card:start -->
**Start here:** `docs/design/README.md` (router). Plans/specs: `docs/design/PLAN_SPEC_PROTOCOL.md`. Current visual authority: `docs/design/brand/BRAND_BOARD.md` and [V2 spec](docs/design/specs/2026-10-30-v2-collectible-gallery-implementation.md). Read the relevant pack and sections.

**Look**
- Arooma is a private premium fragrance archive. The object and collectible card are the hero; not a storefront or noisy game screen.
- V2 themes follow 60:30:10: Obsidian Gold, Ivory Oud, Violet Ink and Emerald Resin. All have light and dark modes; dark is navy/blackened plum, not jet black, light is bone/cream/beige, not paper white.
- Maintain one system utility font stack (SF Pro), curated editorial display serifs and a dedicated calligraphic wordmark **only** for the intro; avoid script in controls.
- Collector artwork is an optional 59:86 opaque collectible face, separate from frosted navigational controls. Foil is subtle perimeter material, not rainbow noise.
- The approved Dior Archive Foil v3: front must expose verified top notes; reverse uses horizontal TOP/HEART/BASE strips; concentration replaces invented rarity labels. Do not invent variants or notes.
- Existing owner bottle photos, level windows and the local-first ownership record remain functional; do not overwrite them when changing card art.

**Behavior**
- Do not replay an obligatory intro for returning users. Cold welcome uses fountain-pen `Arooma` with a direct Demo / My Collection choice and theme switcher. No cabinet door animation.
- Demo and owner's collection are **separate** local stores. A one-tap in-app switcher changes modes; never auto-import branded demo cards into the owner's collection.
- Same selected item persists across Cover Flow, Stack and Fan; drag feels finger-led with velocity snap. Every drag has a tappable and keyboard alternative; reduced motion is respected.
- Tap a focused curated card to flip to fragrance information. Ownership actions remain accessible through Details; Wear Today, Test, Search and Add must be first-level actions.
- Haptics only for selection settle, wear confirmation and completed actions. Island is an in-app testing timer, not a permanent badge.
- Estimates and note overlap never become promised accuracy claims.

**Boundaries**
- The original seven fictional demo bottles coexist with four documented **independent** illustrated real-fragrance collectible concepts. They do not imply endorsement by the named houses. Do not scrape or commit unlicensed manufacturer photography.
- Content ownership, rights review and takedowns follow `docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md`. App Store approval is not proof of content rights.
- No new backend, account, analytics, ads, or IAP without a dedicated implementation spec.
- Preserve `index.html` as the self-contained web demo. One cannot claim this PWA is native SwiftUI; genuine native functionality requires separate work.
- Never force-push `main`.

**Verify**
- 375/390/430 widths, landscape, reduced motion, no horizontal scroll, card image delivery, offline caching, intro theme choice and returning-user fast path.
- `npm run docs:check`, `npm run test:docs` and `npm test` before merge. iPhone Safari, Home Screen install, touch physics and haptics need real-device validation.
- Existing owner backups, photos, saved rotations, migration and Undo remain intact.
<!-- card:end -->
