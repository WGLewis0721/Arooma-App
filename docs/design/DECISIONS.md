# Open design decisions and decision log

> Part of the Arooma design brain. Start at [README.md](README.md) for the map and the router.

> Summary: open decisions with where each is described, then the dated decision log, newest first.

Resolve an open decision here and in its source document together, then move the row to the log. Not needed for ordinary tasks; read it when a task touches one of these topics or when you record a decision.

## Open decisions

| Decision | Where it is described |
| --- | --- |
| Stay an installable web app, or build native: a Capacitor shell with Swift widget and Live Activity extensions (proposed), or a full SwiftUI app. Real widgets and a real Dynamic Island need native | [specs/2026-10-29-widget-live-activity.md](specs/2026-10-29-widget-live-activity.md) (draft, section 8 lists the open items); [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md), "4. Motion"; Spread's release runbooks in [../reference/spread/README.md](../reference/spread/README.md) |
| Retire the `arooma.v1` fallback key (proposed: one release after this one) | [specs/2026-10-29-polish-pass.md](specs/2026-10-29-polish-pass.md), section 8 |
| Level windows on the black, ceramic and terracotta bottles, and a line in the rules card saying every bottle's liquid is always visible | [specs/2026-10-29-shelves-and-liquid.md](specs/2026-10-29-shelves-and-liquid.md), section 4 |
| Pinch and liquid feel on a real iPhone: thresholds, gains, frame rate, and whether iOS also zooms the page | [specs/2026-10-29-shelves-and-liquid.md](specs/2026-10-29-shelves-and-liquid.md), section 8 |
| Keep `localStorage` as the shelf store, or move it to a store a widget can read (needs the native build) | [specs/2026-10-29-cabinet-features.md](specs/2026-10-29-cabinet-features.md), section 8 |
| Night palette: build it (values are specified) or stay light only | [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md), "1. Color" |
| Bottle imagery: keep drawn SVG objects, or use photography. Real houses need brand and image rights | [packs/shelf-change.md](packs/shelf-change.md) |
| Display face: system `ui-serif` only, or bundle Newsreader for non-Apple browsers | [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md), "2. Typography" |
| Haptics on iPhone web: keep the Safari `switch` workaround or drop it if it proves unreliable on a device | [packs/device-layout.md](packs/device-layout.md) |
| Status bar style on a real iPhone: `default` or `black-translucent` | [packs/device-layout.md](packs/device-layout.md) |
| Whether Safari applies `prefers-reduced-transparency` and `prefers-contrast` | [platforms/APPLE_DESIGN_PRINCIPLES.md](platforms/APPLE_DESIGN_PRINCIPLES.md), "3. What a web layer can and cannot do" |

## Decision log

| Date | Decision | By | Documents updated |
| --- | --- | --- | --- |
| 2026-10-30 | Ported from the parallel polish build (`648a506`), at the owner's direction and without tests: named rotations of up to five, Stack as today's shortlist, saved view per collection, pencil and `e` to edit, Demo tag, storage line, scroll fix, 15 min / 1 h / 3 h check-ins that wait, impression note, photos that fill the picture (with the level window kept), empty-shelf view. Not ported: its full-screen welcome, its find panel (search lives in All shelves), its cover-only photos without liquid | Owner request, applied by Claude | [specs/2026-10-29-polish-pass.md](specs/2026-10-29-polish-pass.md), [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md), [packs/shelf-change.md](packs/shelf-change.md), README.md, CHANGELOG.md |
| 2026-10-29 | Every bottle shows its liquid, moving, photos included: a level window placed from the photo's outline, liquid colour sampled from the photo. Photos stay in `localStorage`, stored at 480 px or less, with a persistent-storage request, a usage line in Backup and a weekly-at-most backup reminder once a collection has five bottles; IndexedDB waits for the native build. Session check-ins stay at 20 minutes and 2 hours, rotation stays three, no automatic background removal | Owner (liquid), Claude (the rest, at the owner's direction) | [specs/2026-10-29-polish-pass.md](specs/2026-10-29-polish-pass.md), [RULES_CARD.md](RULES_CARD.md), [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md), [packs/shelf-change.md](packs/shelf-change.md) |
| 2026-10-29 | Polish pass: first run asks (empty or demo); the demo is stored apart and labelled; any bottle can be deleted; schema v3 with one-way migration that keeps `arooma.v1`; JSON backup with reviewed restore; search in the overview; edit; impressions per wear; owner photos on the shared table; Fan shows the saved rotation; the 30 second test became an in-app session with check-ins at 20 minutes and 2 hours; "Estimated remaining" and "Authenticity notes" wording. Search, earlier left open, is now built | Owner brief, applied by Claude | [specs/2026-10-29-polish-pass.md](specs/2026-10-29-polish-pass.md), [RULES_CARD.md](RULES_CARD.md), [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md), [packs/shelf-change.md](packs/shelf-change.md) |
| 2026-10-29 | The cabinet has named shelves (Spring, Summer, Autumn and Winter by default, renamable, up to 12). Pinching in shows every shelf, with a pencil to rename and an Add a shelf button. Every bottle shows its liquid and level, so the three opaque vessels got a level window, and the liquid is simulated (tilt with momentum, travelling ripples, ambient motion). The level window changes three fictional bottles and the rule card does not yet say "always visible"; both are for the owner | Owner request, applied by Claude | [specs/2026-10-29-shelves-and-liquid.md](specs/2026-10-29-shelves-and-liquid.md), [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md), [packs/shelf-change.md](packs/shelf-change.md), README.md |
| 2026-10-29 | Add bottle, delete bottle with Undo, full wear history, an authenticity evidence checklist and a compare-before-buying overlap are built into the iOS build and stored on the device. The earlier prototype's random authenticity number and fixed scent text were not ported because they imply certainty. Search was not requested and is not built | Owner request, applied by Claude | [specs/2026-10-29-cabinet-features.md](specs/2026-10-29-cabinet-features.md), [packs/shelf-change.md](packs/shelf-change.md), README.md |
| 2026-10-29 | The iOS web app is the root page. The earlier all-in-one prototype stays at `variants/collection-demo.html`. Applied by Claude when pushing the iOS build; the owner has not confirmed which page should be the root | Claude, owner to confirm | README.md |
| 2026-10-29 | Icon "The Gap": a 240 px opening between two door panels, not a 56 px seam, so a bottle fits | Claude | [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md), "5. App Store icon" |
| 2026-10-29 | Design brain forked from Spread (`WGLewis0721/spread-app` at `4c23d25`) and adapted. Spread's iOS references kept verbatim under `docs/reference/spread/` | Owner request, applied by Claude | README.md |
