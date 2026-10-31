# Arooma design brain

The one place to start for how Arooma looks, feels or adapts to a device. This map tells you what to read for your task, and what not to.

**Audience:** developers and coding agents. Keep design guidance here.

**Product model:** a personal cabinet of fragrance objects. Shelf, then Bottle, then Ownership record. Today Arooma is an installable iOS web app demo in one HTML file. A native app is an open decision ([DECISIONS.md](DECISIONS.md)).

**Origin:** structure and checks came from Spread (`WGLewis0721/spread-app`, `4c23d25`); its iOS reference remains in [../reference/spread/](../reference/spread/README.md).

---

## 1. Load only what you need

Stop at the first tier that answers your question.

| Tier | What | Size budget | When |
| --- | --- | --- | --- |
| 0 | The rules card, already copied into `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` and `.github/copilot-instructions.md` ([source](RULES_CARD.md)) | 3 KB | Always loaded. Small tweaks stop here |
| 1 | This map | 9 KB | To pick a pack |
| 2 | A task pack in [packs/](packs/): a digest of the rules, facts and checklist for one kind of task, with pointers to exact sections | 6.5 KB each | Almost every task |
| 3 | The long documents, read **by section** using the pointers in the pack | n/a | Only when the pack says the detail matters |
| Data | [tokens.json](tokens.json): every design token, generated from the `:root` block in `index.html` | 4 KB | Instead of reading CSS or prose for token values |

Open decisions: [DECISIONS.md](DECISIONS.md).

---

**Native source:** ios/AroomaNative. Approved artwork lives in [masters](../../assets/collectibles/masters/README.md).

## 2. Task router

| If you are doing... | Read | Then, only if needed |
| --- | --- | --- |
| Native gesture-first cards, Wishlist, scan destination choices, image sharing, quick fragrance insights or advanced search | [specs/2026-10-31-gesture-first-wishlist-discovery.md](specs/2026-10-31-gesture-first-wishlist-discovery.md) | [Opus implementation prompt](prompts/OPUS_55_GESTURE_FIRST_WISHLIST_DISCOVERY.md) and [native motion spec](specs/2026-10-31-native-premium-motion-interaction-system.md); do not assume a verified catalog or media license |
| Real fragrance catalog, brand-photo use, independent-app disclosure, image rights, ads or optional IAP planning | [specs/2026-10-30-unofficial-companion-strategy.md](specs/2026-10-30-unofficial-companion-strategy.md) | [brand/THIRD_PARTY_CONTENT_POLICY.md](brand/THIRD_PARTY_CONTENT_POLICY.md). Strategy only; do not import or publish third-party media based on these docs | 
| Generate a standalone holographic/overframe fragrance collectible image pair | [packs/collectible-image-generation.md](packs/collectible-image-generation.md) | [brand/COLLECTIBLE_CARD_ART_DIRECTION.md](brand/COLLECTIBLE_CARD_ART_DIRECTION.md) sections 1-6 and [production handbook](brand/COLLECTIBLE_CARD_PRODUCTION.md); this is **not** the normal cabinet card style |
| A plan, spec sheet, redesign or UI review | [packs/spec-writing.md](packs/spec-writing.md) | [PLAN_SPEC_PROTOCOL.md](PLAN_SPEC_PROTOCOL.md), [specs/TEMPLATE.md](specs/TEMPLATE.md) |
| The shelf, cards, bottle art, layouts, Daily Pick, low stock, ownership record, test timer, share image | [packs/shelf-change.md](packs/shelf-change.md) | [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md) sections named in the pack |
| Layout for iPhone or iPad, safe areas, Home Screen install, status bar, App Store screenshots | [packs/device-layout.md](packs/device-layout.md) | The Spread device guides named in the pack |
| Making the UI feel native: materials, color, sheets, motion | [packs/apple-native-feel.md](packs/apple-native-feel.md) | [platforms/APPLE_DESIGN_PRINCIPLES.md](platforms/APPLE_DESIGN_PRINCIPLES.md) |
| App icon, launch images, generated assets | [brand/ICON_HANDOFF.md](brand/ICON_HANDOFF.md) | Files in `assets/icons/` |
| Widget, Live Activity, native iOS release | [specs/2026-10-29-widget-live-activity.md](specs/2026-10-29-widget-live-activity.md) (draft) | [../reference/spread/README.md](../reference/spread/README.md) and the Spread documents it lists |
| Recording a decision or checking what is undecided | [DECISIONS.md](DECISIONS.md) | |
| Opus implementation prompts | [prompts/OPUS_55_GESTURE_FIRST_WISHLIST_DISCOVERY.md](prompts/OPUS_55_GESTURE_FIRST_WISHLIST_DISCOVERY.md) | [Earlier motion and signature handoff](prompts/OPUS_55_NATIVE_INTEGRATION.md) |
| Pointing an AI tool at these docs | [AI_TOOL_SETUP.md](AI_TOOL_SETUP.md) | |

A change touching both the shelf and a device concern needs both packs. If no row fits, add one.

---

## 3. Folder map and authority

All paths are under `docs/design/`.

| Path | Governs | Status and authority |
| --- | --- | --- |
| RULES_CARD.md | The hard rules, in brief | Source of the generated card in agent files. Summarizes the rows below; they win if they differ |
| DECISIONS.md | Open decisions and the decision log | Current |
| PLAN_SPEC_PROTOCOL.md, specs/TEMPLATE.md | How every plan and spec is made and shaped | Process authority; never overrides a design rule |
| AI_TOOL_SETUP.md | How AI tools reach these documents | Advisory. Vendor file conventions not re-verified |
| specs/ (README.md is the index) | One spec per request | Plans, not approval |
| packs/ | One digest per kind of task | Derived. The long documents win if they differ |
| packs/collectible-image-generation.md | Task instructions for AI-generated collectible art, not production cabinet cards | Task pack, derived from the collectible guide |
| brand/THIRD_PARTY_CONTENT_POLICY.md | Unofficial real-fragrance companion positioning, asset provenance, fair-use review gates, takedown and Apple review preparation | Policy for third-party content planning; not a publication license |
| specs/2026-10-30-unofficial-companion-strategy.md | Product/business strategy and staged real-catalog rollout | Chosen direction; implementation and image rights gated |
| brand/COLLECTIBLE_CARD_ART_DIRECTION.md | Owner-locked Dior **Archive Foil v3** composition, front top notes, no separate rarity label and a three-horizontal-strip reverse | Highest for optional collectible art only; does not override cabinet UI |
| brand/COLLECTIBLE_CARD_PRODUCTION.md | Human+AI production workflow, copy manifests, prompts and editable layered delivery requirements | Operational for collectible art only |
| assets/collectibles/templates/archive-foil-v3-{front,back}.svg | Matching editable v3 composition artboards (outside design docs) | Current collectible templates |
| tokens.json | Design tokens | Generated from `index.html` |
| brand/BRAND_BOARD.md | Palette, type, materials, motion, icon, share image, low stock, daily pick | Highest for visual and motion decisions |
| brand/ICON_HANDOFF.md | Icon files, generation and placement | Highest for icon files |
| platforms/APPLE_DESIGN_PRINCIPLES.md | Native feel: materials, color, sheets | Advisory, below the brand board. Apple facts carried over from Spread, not re-read |

**Priority:** (1) running `index.html`; (2) brand board; (3) `[Apple]` facts; (4) `[3P]` and `[Rec]` leads; (5) Spread references and history. Fix lower-priority conflicts in the same change.

---

## 4. Code locations

Current native app: ios/AroomaNative. Original cards: assets/collectibles/masters/approved. Historic index.html is not the native source. See [native motion](specs/2026-10-31-native-premium-motion-interaction-system.md) and [gesture-first discovery](specs/2026-10-31-gesture-first-wishlist-discovery.md).

---

## 5. Spread reference material

[../reference/spread/README.md](../reference/spread/README.md) holds Spread's iPhone, iPad and iPhone Duo build guides, its widget and Live Activity spec, and its iOS release runbooks, unchanged. They describe a different product. Use them for Apple facts, checklists and process, never as Arooma rules.

---

## 6. Keeping the brain healthy

- New design information goes in the document whose scope it matches. If none fits, add one in the right subfolder and a row to the router and the table. Each document links back to this file near the top. Specs go in `specs/`.
- One home per fact: link instead of copying. The only deliberate copies are the generated card blocks. No design rules in `README.md` outside the generated block.
- After editing the `:root` tokens in `index.html` run `npm run docs:tokens`. After editing the rules card run `npm run docs:sync`. `npm run docs:check` (also in CI) fails when either is stale, when a link or pack pointer breaks, or when a tier passes its budget.
- A document over 6 KB opens with a `> Summary:` line under its breadcrumb. Keep section headings short and stable, because packs point at them.
- Record a decision in the document it changes and in [DECISIONS.md](DECISIONS.md). When a document is superseded, say so at its top and name its replacement. Do not delete history.
