# Arooma design brain

Start here for Arooma's design rules and task-specific references.

**Audience:** developers and coding agents. Keep design guidance here.

**Product:** Shelf → Bottle → Ownership. Native SwiftUI iOS 26+ in `ios/AroomaNative`; old PWA docs are historical.

**Origin:** design framework from Spread; [archived iOS references](../reference/spread/README.md).

---

## 1. Load only what you need

Stop at the first sufficient tier.

| Tier | What | Size budget | When |
| --- | --- | --- | --- |
| 0 | Generated [rules card](RULES_CARD.md) in agent instructions | 3 KB | Always loaded. Small tweaks stop here |
| 1 | This map | 9 KB | To pick a pack |
| 2 | Task pack in [packs/](packs/), with focused rules and section pointers | 6.5 KB each | Almost every task |
| 3 | Long references, read by section | n/a | Only when the pack says the detail matters |
| Data | [tokens.json](tokens.json): web-prototype tokens (historical) | 4 KB | For historic web prototype only |

Open decisions: [DECISIONS.md](DECISIONS.md).

---

**Native source:** ios/AroomaNative. Approved artwork lives in [masters](../../assets/collectibles/masters/README.md).

## 2. Task router

| If you are doing... | Read | Then, only if needed |
| --- | --- | --- |
| UX laws, hierarchy or reachability | [FOUNDATIONAL_UX_PRINCIPLES.md](FOUNDATIONAL_UX_PRINCIPLES.md) | Then consult the surface-specific pack |
| Native SwiftUI design or accessibility | [platforms/AROOMA_IOS_DESIGN_GUIDE.md](platforms/AROOMA_IOS_DESIGN_GUIDE.md) | [Apple principles](platforms/APPLE_DESIGN_PRINCIPLES.md), [Spread references](../reference/spread/README.md) |
| Native navigation, tabs, quick actions, header signature, Gyro Flip | [specs/2026-11-02-native-navigation-v3.md](specs/2026-11-02-native-navigation-v3.md) | [Plan](../../AROOMA_NAVIGATION_V3_QUICK_ACTIONS.md), [V2 spec](specs/2026-11-02-native-navigation-v2.md) (partly superseded) |
| Native cards, Wishlist, scans, sharing or discovery | [specs/2026-10-31-gesture-first-wishlist-discovery.md](specs/2026-10-31-gesture-first-wishlist-discovery.md) | [Opus prompt](prompts/OPUS_55_GESTURE_FIRST_WISHLIST_DISCOVERY.md), [motion spec](specs/2026-10-31-native-premium-motion-interaction-system.md); no unlicensed catalog |
| Catalog, image rights, ads or IAP planning | [specs/2026-10-30-unofficial-companion-strategy.md](specs/2026-10-30-unofficial-companion-strategy.md) | [Rights policy](brand/THIRD_PARTY_CONTENT_POLICY.md); strategy is not a publishing license | 
| Building an animated Scent World card (bottle miniature + real moving scene + foil) | [brand/ANIMATED_SCENT_WORLD_PIPELINE.md](brand/ANIMATED_SCENT_WORLD_PIPELINE.md) | [Aventus native player](../../ios/AroomaNative/Artwork.swift), [production manifest](../../assets/collectibles/scent-worlds/manifest.json); never ship still as animated |
| Generate an overframe collectible image pair | [packs/collectible-image-generation.md](packs/collectible-image-generation.md) | [brand/COLLECTIBLE_CARD_ART_DIRECTION.md](brand/COLLECTIBLE_CARD_ART_DIRECTION.md) and [production handbook](brand/COLLECTIBLE_CARD_PRODUCTION.md); separate from cabinet cards |
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
| FOUNDATIONAL_UX_PRINCIPLES.md | Foundational laws and checks | Native product authority wins |
| platforms/AROOMA_IOS_DESIGN_GUIDE.md | Arooma-specific native iOS guidelines | References preserved Spread guides |
| RULES_CARD.md | The hard rules, in brief | Source of agent rule cards; governs conflicts |
| DECISIONS.md | Open decisions and the decision log | Current |
| PLAN_SPEC_PROTOCOL.md, specs/TEMPLATE.md | How every plan and spec is made and shaped | Process authority; never overrides a design rule |
| AI_TOOL_SETUP.md | How AI tools reach these documents | Advisory. Vendor file conventions not re-verified |
| specs/ (README.md is the index) | One spec per request | Plans, not approval |
| packs/ | One digest per kind of task | Derived. The long documents win if they differ |
| packs/collectible-image-generation.md | Task instructions for AI-generated collectible art, not production cabinet cards | Task pack, derived from the collectible guide |
| brand/THIRD_PARTY_CONTENT_POLICY.md | Asset provenance, licensing and review | Policy for third-party content planning; not a publication license |
| specs/2026-10-30-unofficial-companion-strategy.md | Product/business strategy and staged real-catalog rollout | Chosen direction; implementation and image rights gated |
| brand/COLLECTIBLE_CARD_ART_DIRECTION.md | Locked Dior Archive Foil v3 artwork | Highest for optional collectible art only; does not override cabinet UI |
| brand/ANIMATED_SCENT_WORLD_PIPELINE.md | Required end-to-end 10-stage process for real animated miniature worlds inside fragrance bottles | Mandatory for living Scent World asset production; does not govern still cards |
| brand/COLLECTIBLE_CARD_PRODUCTION.md | Human+AI production workflow, copy manifests, prompts and editable layered delivery requirements | Operational for collectible art only |
| assets/collectibles/templates/archive-foil-v3-{front,back}.svg | Editable artboards outside docs | Current collectible templates |
| tokens.json | Design tokens | Generated from `index.html` |
| brand/BRAND_BOARD.md | Palette, type, materials, motion, icon, share image, low stock, daily pick | Highest for visual and motion decisions |
| brand/ICON_HANDOFF.md | Icon files, generation and placement | Highest for icon files |
| platforms/APPLE_DESIGN_PRINCIPLES.md | Native feel: materials, color, sheets | Advisory, below the brand board. Apple facts carried over from Spread, not re-read |

**Priority:** (1) active native SwiftUI app and its approved persisted behavior; (2) brand board and current native direction; (3) `[Apple]` facts; (4) `[3P]` and `[Rec]` leads; (5) Spread references and history. Fix lower-priority conflicts in the same change.

---

## 4. Code locations

Native: ios/AroomaNative. Approved cards: assets/collectibles/masters/approved. Web index.html is historical. See [native motion](specs/2026-10-31-native-premium-motion-interaction-system.md) and [gesture-first discovery](specs/2026-10-31-gesture-first-wishlist-discovery.md).

---

## 5. Spread reference material

[../reference/spread/README.md](../reference/spread/README.md) holds Spread's iPhone, iPad and iPhone Duo build guides, its widget and Live Activity spec, and its iOS release runbooks, unchanged. Use for research, not Arooma implementation rules.

---

## 6. Keeping the brain healthy

- Put new guidance in the relevant doc; add missing topics to this router. Link back here. Specs belong in `specs/`.
- One home per fact: link instead of copy. Keep agent files thin.
- For historical web token changes use `npm run docs:tokens`. For rule-card changes run `npm run docs:sync`. `npm run docs:check` validates links, indices and budgets.
- Docs over 6 KB need a `> Summary:` near the top. Keep pack-targeted headings stable.
- Record a decision in the document it changes and in [DECISIONS.md](DECISIONS.md). When a document is superseded, say so at its top and name its replacement. Do not delete history.
