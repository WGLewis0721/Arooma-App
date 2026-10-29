# Open design decisions and decision log

> Part of the Arooma design brain. Start at [README.md](README.md) for the map and the router.

Resolve an open decision here and in its source document together, then move the row to the log. Not needed for ordinary tasks; read it when a task touches one of these topics or when you record a decision.

## Open decisions

| Decision | Where it is described |
| --- | --- |
| Stay an installable web app, or build native: a Capacitor shell with Swift widget and Live Activity extensions (proposed), or a full SwiftUI app. Real widgets and a real Dynamic Island need native | [specs/2026-10-29-widget-live-activity.md](specs/2026-10-29-widget-live-activity.md) (draft, section 8 lists the open items); [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md), "4. Motion"; Spread's release runbooks in [../reference/spread/README.md](../reference/spread/README.md) |
| Port the earlier prototype's features into the iOS build: add bottle, search, authenticity check, blind-buy DNA matcher. Authenticity and match wording must not claim certainty | `variants/collection-demo.html`; [RULES_CARD.md](RULES_CARD.md), Behavior |
| Night palette: build it (values are specified) or stay light only | [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md), "1. Color" |
| Bottle imagery: keep drawn SVG objects, or use photography. Real houses need brand and image rights | [packs/shelf-change.md](packs/shelf-change.md) |
| Display face: system `ui-serif` only, or bundle Newsreader for non-Apple browsers | [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md), "2. Typography" |
| Haptics on iPhone web: keep the Safari `switch` workaround or drop it if it proves unreliable on a device | [packs/device-layout.md](packs/device-layout.md) |
| Status bar style on a real iPhone: `default` or `black-translucent` | [packs/device-layout.md](packs/device-layout.md) |
| Whether Safari applies `prefers-reduced-transparency` and `prefers-contrast` | [platforms/APPLE_DESIGN_PRINCIPLES.md](platforms/APPLE_DESIGN_PRINCIPLES.md), "3. What a web layer can and cannot do" |

## Decision log

| Date | Decision | By | Documents updated |
| --- | --- | --- | --- |
| 2026-10-29 | The iOS web app is the root page. The earlier all-in-one prototype stays at `variants/collection-demo.html`. Applied by Claude when pushing the iOS build; the owner has not confirmed which page should be the root | Claude, owner to confirm | README.md |
| 2026-10-29 | Icon "The Gap": a 240 px opening between two door panels, not a 56 px seam, so a bottle fits | Claude | [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md), "5. App Store icon" |
| 2026-10-29 | Design brain forked from Spread (`WGLewis0721/spread-app` at `4c23d25`) and adapted. Spread's iOS references kept verbatim under `docs/reference/spread/` | Owner request, applied by Claude | README.md |
