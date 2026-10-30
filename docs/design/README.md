# Arooma design brain

The one place to start for how Arooma looks, feels or adapts to a device. This map tells you what to read for your task, and what not to.

**Audience:** developers and GenAI agents. Do not look for design guidance anywhere else, and do not create design documents outside this folder.

**Product model:** a personal cabinet of fragrance objects. Shelf, then Bottle, then Ownership record. Today Arooma is an installable iOS web app demo in one HTML file. A native app is an open decision ([DECISIONS.md](DECISIONS.md)).

**Origin:** the structure, protocol and checks are forked from the Spread design brain (`WGLewis0721/spread-app`, commit `4c23d25`). Spread's planner and landing rules were not carried over. Spread's iOS reference documents are kept verbatim in [../reference/spread/](../reference/spread/README.md).

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

Rarely needed: [DECISIONS.md](DECISIONS.md) (open decisions and the decision log).

---

## 2. Task router

| If you are doing... | Read | Then, only if needed |
| --- | --- | --- |
| Generate a standalone holographic/overframe fragrance collectible image pair | [packs/collectible-image-generation.md](packs/collectible-image-generation.md) | [brand/COLLECTIBLE_CARD_ART_DIRECTION.md](brand/COLLECTIBLE_CARD_ART_DIRECTION.md) sections 1-6 and [production handbook](brand/COLLECTIBLE_CARD_PRODUCTION.md); this is **not** the normal cabinet card style |
| A plan, spec sheet, redesign or UI review | [packs/spec-writing.md](packs/spec-writing.md) | [PLAN_SPEC_PROTOCOL.md](PLAN_SPEC_PROTOCOL.md), [specs/TEMPLATE.md](specs/TEMPLATE.md) |
| The shelf, cards, bottle art, layouts, Daily Pick, low stock, ownership record, test timer, share image | [packs/shelf-change.md](packs/shelf-change.md) | [brand/BRAND_BOARD.md](brand/BRAND_BOARD.md) sections named in the pack |
| Layout for iPhone or iPad, safe areas, Home Screen install, status bar, App Store screenshots | [packs/device-layout.md](packs/device-layout.md) | The Spread device guides named in the pack |
| Making the UI feel native: materials, color, sheets, motion | [packs/apple-native-feel.md](packs/apple-native-feel.md) | [platforms/APPLE_DESIGN_PRINCIPLES.md](platforms/APPLE_DESIGN_PRINCIPLES.md) |
| App icon, launch images, generated assets | [brand/ICON_HANDOFF.md](brand/ICON_HANDOFF.md) | Files in `assets/icons/` |
| Widget, Live Activity, native iOS release | [specs/2026-10-29-widget-live-activity.md](specs/2026-10-29-widget-live-activity.md) (draft) | [../reference/spread/README.md](../reference/spread/README.md) and the Spread documents it lists |
| Recording a decision or checking what is undecided | [DECISIONS.md](DECISIONS.md) | |
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
| brand/COLLECTIBLE_CARD_ART_DIRECTION.md | Owner-locked Dior **Archive Foil v3** composition, front top notes, no separate rarity label and a three-horizontal-strip reverse | Highest for optional collectible art only; does not override cabinet UI |
| brand/COLLECTIBLE_CARD_PRODUCTION.md | Human+AI production workflow, copy manifests, prompts and editable layered delivery requirements | Operational for collectible art only |
| assets/collectibles/templates/archive-foil-v3-{front,back}.svg | Matching editable v3 composition artboards (outside design docs) | Current collectible templates |
| tokens.json | Design tokens | Generated from `index.html` |
| brand/BRAND_BOARD.md | Palette, type, materials, motion, icon, share image, low stock, daily pick | Highest for visual and motion decisions |
| brand/ICON_HANDOFF.md | Icon files, generation and placement | Highest for icon files |
| platforms/APPLE_DESIGN_PRINCIPLES.md | Native feel: materials, color, sheets | Advisory, below the brand board. Apple facts carried over from Spread, not re-read |

**When documents disagree, higher wins and the lower one is fixed in the same change:** (1) what ships: the `:root` tokens and `BOTTLES` data in `index.html`, the running app; (2) the brand board; (3) `[Apple]` facts; (4) `[3P]` and `[Rec]` leads; (5) the Spread reference material and historical records.

---

## 4. Where the design truth lives in code

All current app behavior is in `index.html`. The Archive Foil collectible visual standard is **documentation only**, with no runtime integration.\n\nAll in `index.html`:
- Tokens: the `:root` block at the top of the `<style>`. Read them as data in [tokens.json](tokens.json).
- Bottle art: `bLinen`, `bInk`, `bFig`, `bMilk`, `bCedar`, `bSmoke`, `bEarth` (SVG, one per material family). Sample data: `BOTTLES`.
- Layouts: `place` (Cover Flow and Stack) and `fanPlace` (Fan). One DOM, three arrangements.
- Island timer, share image export and the iOS install layer: the sections of the script with those names.
- Icons: `assets/icons/icon.svg` is the source; PNGs and launch images come from `tools/generate_assets.py`.

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
