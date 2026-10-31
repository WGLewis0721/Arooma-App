# Arooma: instructions for GitHub Copilot

**ACTIVE OWNER OVERRIDE (2026-10-30):** The PWA is retired. Build a native SwiftUI iOS 26+ app for immediate simulator demo (no TestFlight). Do not port the single-file web app.

Read [AROOMA_V2_FINAL_POLISH_SPEC.md](../AROOMA_V2_FINAL_POLISH_SPEC.md) and the brand board. Preserve design objectives, art masters, and interactions. Liquid Glass on functional layer only.

All design guidance lives in one place: **[docs/design/README.md](../docs/design/README.md)**.

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
- Native SwiftUI only. PWA is retired.
- Never force-push `main`.

**Verify**
- Simulator on iPhone sizes, reduced motion, safe areas, Dynamic Type.
- Design docs check. Real device optional for final polish.
- Existing owner backups, photos, saved rotations, migration and Undo remain intact.
<!-- design-rules-card:end -->
