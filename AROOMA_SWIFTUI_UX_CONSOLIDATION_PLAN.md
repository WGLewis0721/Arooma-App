# Arooma — Native SwiftUI UX Consolidation & Frosted-Tray Implementation Plan

> Summary: Implement the 18 owner-reviewed before/after UX concepts against the **existing native iOS 26+ app**. Reduce genuinely redundant paths and controls without deleting features, breaking local data, or changing the collectible visual identity. Give swipe-up trays a restrained **frosted, translucent native-glass** presentation. Prove the result with running-app screenshots and **Maestro MCP + repeatable YAML user-flow tests**.
>
> Date: 2026-11-01. Owner-directed handoff to Claude. **This document is a plan, not an implementation report.** No native app code or Maestro flow was changed by the creation of this plan. The Instagram/Appbrainy inspiration shots and Arooma before/after mockups in the owner's conversation are **conceptual**, not authoritative screenshots of the shipping SwiftUI app. Some contain invented labels, controls, product imagery, or screens. Never implement those inventions.

## 0. Non-negotiable product and source boundaries

1. **Only** edit the SwiftUI target under `ios/AroomaNative/`. Keep `ios/AroomaNative.xcodeproj`, bundle ID `com.graymatter.arooma`, signed Codemagic/TestFlight path, local-first persistence, existing records and migrations. The old `index.html` PWA is retired.
2. Start with `AGENTS.md`, `NATIVE_TARGET_OVERRIDE.md`, `NATIVE_ATELIER_FINAL.md`, `docs/design/README.md`, `docs/design/platforms/AROOMA_IOS_DESIGN_GUIDE.md`, `docs/design/brand/BRAND_BOARD.md`, `docs/design/FOUNDATIONAL_UX_PRINCIPLES.md`, and the applicable task packs. Resolve historical PWA conflicts in favor of the native override.
3. Keep Cover Flow / Stack / Fan physics, gestures, 3D flip, selected identity, notes, Share eligibility, Season Compass Insights, Compare, ownership and wishlist distinctions, wear/layer/history, rotations, 30 Autumn live cards, and the owner's existing card artwork intact. **The card art stays opaque; glass belongs to UI chrome and trays, never the photographic faces.**
4. Preserve the approved themes, light/dark/system behavior, accessibility, and rights gates for unlicensed photos, public sharing and purchases. Do **not** invent shopping carts, bag/checkout, reminders, scheduling, longevity claims, new profiles, backend, or monetization because they appeared in a generated mockup.
5. Build against the live implementation first. For each proposal write down its current code path and a real baseline screenshot, then either implement and test, or mark `NOT APPLICABLE — not present / not redundant` with evidence. Do not delete useful alternative entry points just to reduce the number of buttons.
6. Scope this work to UX consolidation, native materials, documented navigation, and verification. Preserve local data and offline behavior on upgrade; do not reset production state, alter persisted IDs, or rewrite storage schema.

## 1. Reference lock: what we are actually building

**North star:** a premium, object-first fragrance archive. Bottles and collectible cards are the exhibit; sparse, legible native controls are the frame. Swipe up to reveal a softly frosted sheet over the still-visible card/deck, without turning the screen into an opaque settings page. The user should always know what item is selected and where the gesture will return.

- **Visual authority (primary):** the owner-approved Arooma card/deck art, current app, `BRAND_BOARD.md`, Season Compass spec `docs/design/specs/2026-11-01-season-compass-visual-insights.md`; supplied Instagram references set **feel** (real-device gloss, translucent trays, product photography, discreet floating controls), not new functionality.
- **Borrow from Refero only:** product-first image hierarchy, restrained editorial density, contextual sheets and flow sequencing, but not brand colors or unrounded web controls.
- **Material policy:** SwiftUI iOS 26 system presentation first: `sheet`, `presentationDetents`, `presentationDragIndicator`, `presentationBackground` with a system Material where useful; native glass for the handle/header/action cluster. For the already custom draggable Season Compass tray, retain its working drag model and data views; adjust its background to an appropriate frosted material **without replacing it with a web-style overlay** or breaking peek/expanded detents. Follow native sheet/material behavior instead of adding a shader blur or continuously animated refraction.
- **Legibility:** bright enough scrim behind dense text, thin highlight/hairline edge, restrained depth, and adaptable dark-mode neutral tint. In Reduce Transparency / Increase Contrast, use a more opaque equivalent. Respect Dynamic Type/VoiceOver, 44×44 pt targets, keyboard, safe area and interactive swipe regions.
- **Do not** copy 21st.dev React, Tailwind, Radix, DOM, or WebGL into iOS. 21st.dev is visual *reference only*. Keep Apple's actual TabView and native sheet behavior. Do not add a custom tab-bar dock to imitate a web demo.

### External references (real, verified as of 2026-11-01)

**Refero visual styles:**
- [D.S. & DURGA — luxury fragrance editorial](https://www.dsanddurga.com) (Refero style ID `92962483-5537-4be9-a80c-6166e1c9c730`) — reference for art direction: product imagery dominates; minimal quiet navigation. **Do not** copy its squared web controls or replace the approved Arooma palette.
- [Perplexity Computer — botanical, material-backed editorial](https://www.perplexity.ai/products/computer) (Refero style ID `7ac8e085-270b-4af6-a12e-14bf4adc0f8f`) — reference for translucent information above atmospheric imagery and text/contrast layering, not its AI product layout.
- [Eduardo del Fraile — gallery-like dark product composition](https://www.eduardodelfraile.com) (Refero style ID `36be0546-da09-4d6b-ba8b-27495bb71cda`) — reference for dark-mode image priority and low-chrome navigation.

**Refero concrete iOS screens/flows:**
- [Airbnb contextual bottom sheet](https://refero.design/screens/298bae4d-e0f9-43b0-9248-3a5d369c75bf): clear contextual choices and exit affordance; adapt via native SwiftUI sheet/detents.
- [Artsy iOS filter/sort](https://refero.design/screens/a0542886-747d-48dd-b027-da15ec36a1fd): compare facet grouping and selected-state clarity; retain Arooma's existing filter vocabulary.
- [1Password grouped settings](https://refero.design/screens/f38aa21f-5c93-4e13-877a-2550060283b6): a readable section hierarchy for View & Style.
- [Halide Mark II gallery](https://refero.design/screens/88ed1e17-1209-40df-a9d5-af6ff6aa558b): image-first grid and subordinate actions; **not** a template for replacing Cover Flow.
- [Apple Books — Add to Collection flow](https://refero.design/flows/11917): choose destination, preserve context, eliminate excess decision steps.
- [Canopi — Add Photo to Collection](https://refero.design/flows/6074): retain preview/review where image recognition needs verification.
- [On — Search-to-Results Product Discovery](https://refero.design/flows/9598): search/scope/filter/result hierarchy. Do **not** introduce commerce.

**21st.dev (visual study only, not SwiftUI packages):**
- [Glass Tabs by deepraj21](https://mcp.21st.dev/%40deepraj21/components/glass-tabs) — study the selected segment's frosted focus, adapt with native Picker/segmented styling only where appropriate.
- [Glass Tab Bar by deepraj21](https://mcp.21st.dev/%40deepraj21/components/glass-tab-bar) — hierarchy and active state **only**; Arooma should continue using native iOS 26 TabView, not a React-style dock.
- [Liquid Glass Card by Ali Imam](https://docs.21st.dev/%40designali-in/components/liquid-glass-card) — inspect edge/light/blur treatment for an *informational tray*, not collectible card art.
- [21st.dev Liquid Glass collection](https://21st.dev/community/components/explore/liquid-glass-components) — visual sampling for frosted secondary controls, subject to contrast and reduced-transparency rules.

**SwiftUI authority:** [Apple WWDC25: Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/), [presentationBackground](https://developer.apple.com/documentation/swiftui/view/presentationbackground%28_%3A%29), [Maestro MCP docs](https://docs.maestro.dev/get-started/maestro-mcp), [Maestro iOS docs](https://docs.maestro.dev/get-started/supported-platform/ios).

**Decision rule:** Arooma's existing native behavior / local data and artwork win over mockups; Apple platform semantics win over borrowed React code; external patterns inform **presentation and flow**, not product scope.

## 2. Implement the 18 before/after items — truth-first worklist

The ID numbers match the 18 concepts in the conversation. Several overlap or include imaginary demo copy. Do not count overlapping items as separate saved taps. In the PR, record `BEFORE → AFTER → EVIDENCE → STATUS` for every ID.

| ID | Existing native evidence / target | Claude implementation instruction | Outcome / guard |
|---|---|---|---|
| **01 Search → Inspector** | `AroomaApp.swift` passes Search's result tap through `focus`, which changes to Collection first. | Tap result should open the selected `AtelierInspector` directly; provide deck-focus as an optional path and preserve selected ID/mode/return destination. | **One result tap** to actual inspector; dismiss returns to Search with query/filters preserved. |
| **02 Fast Quick Add** | `Capture.swift`: `QuickAddSheet` capture → `ScanReview` → destination buttons → confirmation. | For clearly typed/selected name, expose **Collection / Wishlist** destination and save directly in the capture sheet. Retain verification/review for camera OCR, ambiguous matches, or photo flows where facts need correction. Preserve Undo, duplicates, draft and error handling. | Simple valid name requires **one fewer screen**; photo/OCR confidence is not degraded. |
| **03 Unified Shelves** | `AtelierSections.swift` has separate `AtelierShelves` tab and `ShelfOverview` inside Collection; only the former supports rename/move. | Make **one functional shelf surface** reachable within Collection in **one tap**, supporting browse, rename, move, add, and return-to-deck. Then retire the redundant top-level Shelves tab **only after** parity and discoverability tests. | Four native main tabs; zero lost shelf actions or ownership mix-ups. |
| **04 Unified Search controls** | `Search.swift`: scope, Sort menu, Filters sheet are separate. | Keep scope visible; move Sort to the existing Filters sheet and show active state/count. Preserve every filter, sorting choice, clear action and search keyboard behavior. | One obvious route for refining results, no filter loss. |
| **05 Return to origin** | `AroomaApp.swift` Quick Add `onAdded` forces `tab = .gallery`. | Track invoking tab and return to it after a normal save. Option to jump to saved item only if the user chooses. Preserve mode changes when saving Wishlist. | Add from Today returns to Today; add from unified Shelves returns there; no forced navigation detour. |
| **06 Duplicate About** | `AtelierStyle` currently declares `DisclosureGroup("About this archive")` twice. | Keep one authoritative disclosure including full privacy, foil and rights/capability explanation; remove duplicate copy. | One disclosure; no information lost. |
| **07 Duplicate Studio opener** | `MyCardsScreen` has header `+`, overflow `Card Studio`, and intentional empty-state `Open Card Studio`. | Retain prominent creation `+` and meaningful empty-state CTA; remove repeated Studio menu entry from the **same Cards screen**. | No duplicate top-level action; Studio still one tap away. |
| **08 Today accessory** | Native `TabView` includes Today tab and `tabViewBottomAccessory` which always points to Today. | Hide/collapse the accessory **while Today is selected**; leave meaningful wear-status shortcut elsewhere if it adds value. | Today never links to itself; restored vertical space, status preserved outside Today. |
| **09 Daily pick vs Repeat Last** | `CollectionStore.dailyPick` and `AtelierWearLog.lastRitual` are **not identical** recommendations. | Check whether actual user-visible suggestions duplicate on the *same* screen; if so clarify hierarchy and one primary CTA. Do **not** merge predictive Daily Pick with replaying recorded history. | One main decision without losing either meaningful function; otherwise mark N/A. |
| **10 Wear history surfaces** | `AtelierWearLog.history` shows sessions; `WearHistoryScreen` shows per-bottle details. | Share row/timeline rendering where useful, clarify global vs bottle context; do not add a new History tab or remove per-bottle history. | One consistent chronological language, same historical records/actions. |
| **11 Add entry points** | Quick Add appears from Collection, Shelves and Today; contextual entry points serve different needs. | Route all to a shared Quick Add implementation/state (already mostly true); remove only duplicate CTAs appearing side-by-side **within one context**, not cross-tab discoverability. | Exactly one clear primary Add on each relevant surface; Add available in ≤1 action from Collection/Today/Shelves. |
| **12 Wear / Layer / History actions** | `AtelierGallery`, `AtelierInspector`, `AtelierWearLog` offer related actions in different positions. | Create a consistent, contextual action hierarchy: Wear (primary when owned), Layer (secondary), History/Details discoverable. Shared button style/action handling where useful. | Single wear from focused card remains 1 tap; two-bottle layer from focused card ≤3 actions after selection; do not invent reminders or stats. |
| **13 Ownership notes** | Personal notes exist in editor/ownership views and may be previewed. | Show one contextual preview with one Edit affordance, backed by existing `BottleEditor`, rather than two adjacent note areas that repeat copy. Preserve all notes and any distinct fragrance note-pyramid data. | One edit destination; no note loss; if not actually duplicated, N/A. |
| **14 Repeat Wear CTAs** | `AtelierWearLog` provides Repeat Last and 'Wear again' in historical row menus. | Distinguish shortcut vs history management. Avoid two equally emphasized repeat buttons on the *same* visible context; retain historical menu actions and Undo. | One prominent repeat call to action, full history controls intact; N/A if nonredundant. |
| **15 Cards management** | Cards screen mixes create, library, import/export, commercial gated UI. Related to **07**, not a separate second Studio fix. | Give prominent create CTA and relegate Import/Export/Restore to overflow. Don't expose gated paid products or separate Cards vs Bottles semantics. | Clear creation vs maintenance roles, no new screens, same data. |
| **16 Compare entry paths** | Compare already accessible in `InsightPanel`, card context menu, and recommendation tiles. | Keep contextual recommendations (including preselection) and one shared `CompareSheet`; standardize naming/icon and prefer one obvious primary entry on each visible surface. | No broken recommendation/deep-link or duplicate overlapping compare controls. Ignore fictional `Add to Bag` mockup. |
| **17 Wishlist → Owned** | `AtelierGallery`/Inspector branch on wishlist ID and expose `Move to my collection`; other branches add unowned demo. | Audit relationship-specific actions and show exactly **one** truthful primary conversion action at a time. Do not show Add and Move together for an already wishlisted item. Preserve wish ID transfer, notes and history. | One-tap Wishlist→Mine with no duplicate physical bottle; if already conditional correctly, preserve as-is. |
| **18 Group View & Style** | `AtelierStyle` has arrangement, theme, appearance, signature, recenter, about and owner-only tuning. | Group related **existing** controls into legible `Layout`, `Appearance & Atmosphere`, `Card Lighting/Motion` and `About` sections inside the **same sheet**; do not create unrelated screens or remove four palette choices. Includes 06 duplicate cleanup. | Shorter first glance, preserved controls and owner-accessible tuning. |

**Conflict resolution:** 07 and 15 are one Cards cleanup; 06 and 18 are one Style cleanup plus grouping. 09, 11, 13, 14, 16, 17 require verification of *actual* redundancy and may be correctly retained as intentional shortcuts. A generated mockup is not proof that two live actions coexist.

## 3. Frosted swipe-up tray specification

Target native surfaces: `AtelierGallery` Season Compass `insightOverlay` and `InsightPanel`; existing `AtelierStyle` and `FilterSheet` and relevant comparison/review sheets. Maintain their business logic and detent semantics.

- **Visual hierarchy:** selected deck/card remains visibly identifiable in background; tray is a floating, gently blurred layer with subtle highlight at the rim. Short, readable header and drag handle above a compact summary. Expanded tray scrolls note pyramid, accords, matches, comparison and detailed disclosure. **No text-heavy wall in the peek.**
- **iOS behavior:** use native material/presentation machinery wherever possible; medium and large detents, visible drag indicator, rubber-band/settle only as defined by Apple platform and existing gesture model. On the current custom Season Compass overlay, change only surface styling/scrim/content layout needed; preserve its custom `insight` detents and the deck's sideways swipe gestures. Gestures must not steal card flips, horizontal deck selection or accessibility scroll.
- **Rendering:** honor dark/light/system, the app's 4 palettes, Increase Contrast, Reduce Transparency, Reduce Motion. Material may be backed by a theme-appropriate opaque tint for legibility in accessibility modes. Render full sheet at ≥390pt and 375pt width without clipped footers or bottom tab overlap. Never treat cards themselves as translucent.
- **Interaction contract:** down-swipe collapses/returns without changing selected bottle; Close always works; two-stage peek/expanded states; keyboard does not obscure destination/Save; all actions have visible/tappable alternatives to gestures; no fake glass reflection on content.

## 4. Delivery phases (commit and verify incrementally)

1. **Baseline / evidence** — read current `main` and design docs. Run installed app with sample+owner fixture in a clean simulator; capture actual screens and measure flows in a table: entry, actions, screens, exit, data mutation. If simulator absent, report as **not run** and use code-review evidence only, never claim visual verification. Record the 18 IDs in a before/after matrix.
2. **Navigation/data-safe refactor** — 01, 03, 05, 08, 10. Build an explicit return-to-origin contract and one shelf data/view source; ensure mode/selection and saved data persist. Only then remove the separate Shelves tab after the unified view has parity.
3. **Task simplification** — 02, 04, 07/15, 11, 12, 14, 16, 17; establish fast direct actions without losing secondary flows, recovery or Undo. Make sure compare suggestions and Search scoped state survive sheet dismissal.
4. **Visual/material pass** — 06/18, 09/13 where genuinely duplicated, plus frosted upward trays. Preserve latest Season Compass 2026-11-01 art and note-mapping spec, all 20 botanical asset mappings and 30 live reverse cards.
5. **Automated functional and visual QA** — Maestro on iOS 26 simulator, plus Xcode build, repo tests/docs checks, screenshots of compact/regular/large widths and both appearances. Fix failures. Deliver comparison images, flow table, PR and release caveats. **Do not merge or trigger production/TestFlight distribution without the owner's explicit release instruction.**

### Proposed code touchpoints

- `ios/AroomaNative/AroomaApp.swift`: tab routing, result destination, origin-aware Quick Add, Today accessory, 4-tab parity gate.
- `ios/AroomaNative/AtelierGallery.swift`: shelf overlay integration, gestures, consistent action affordances, inspector/Insights tray styling and return.
- `ios/AroomaNative/AtelierSections.swift`: unify shelf presentation and shelf management, Today wear hierarchy, style grouping, clean duplicate disclosure.
- `ios/AroomaNative/Insights.swift`: preserve the new visual Season Compass, compare preselection, native material/contrast behavior.
- `ios/AroomaNative/Capture.swift`: direct valid-name save; keep OCR review/undo/draft semantics.
- `ios/AroomaNative/Search.swift`: direct inspect result + sort inside filters.
- `ios/AroomaNative/Commercial.swift`: Cards entry/action consolidation, no change to purchases/entitlements.
- `ios/AroomaNative/CollectionStore.swift`: only if necessary for safe one-source navigation/ownership, no storage schema change.

## 5. Maestro MCP test contract (required, not optional)

**Already in repo:** `.claude/skills/maestro-ui-testing/SKILL.md`, `reference.md`, `.maestro/smoke.yaml`, `.maestro/quick-add-wishlist.yaml`, `.maestro/tuning-presets.yaml`, and manual `.github/workflows/maestro-ios.yml`. Read these, then **verify tool names against current Maestro**; bundled references may be older. Current official MCP includes `list_devices`, `start_device`, `launch_app`, `inspect_view_hierarchy`, `tap_on`, `run_flow`, `run_flow_files`, `take_screenshot`, `check_flow_syntax`, and `cheat_sheet`. Never invent unverified APIs.

**Claude MCP setup:** `claude mcp add maestro -- maestro mcp` (on a Mac with Maestro installed); inspect available tools with Claude's MCP UI. See https://docs.maestro.dev/get-started/maestro-mcp . iOS requires Xcode/iOS 26 Simulator + Debug build + app installed. `maestro test .maestro/` is the CLI regression route. Match current UI labels and accessibility identifiers after each real screen inspection.

Before each change capture evidence; after it, use Maestro MCP to inspect view hierarchy and exercise gestures/buttons; promote stable tests to YAML files under `.maestro/`. **Update old assertions that assume a Shelves tab or mandatory Quick Add Review**; preserve separate camera/OCR review test. Suggested new test flows:

| Flow YAML (suggested) | Minimum assertions |
|---|---|
| `search-direct-inspect.yaml` | Query → result tap opens Inspector directly; Close returns Search with query/scope/sort/filter retained; no forced Collection detour. |
| `quick-add-name-owned.yaml` | Clean install → type valid name → direct save to Collection; appears once; app state correct after relaunch. |
| `quick-add-name-wishlist.yaml` | Direct Wishlist save, one wish entry; existing Undo and duplicate behavior verified; update old review-only test. |
| `quick-add-ocr-review.yaml` | Camera/photo paths still show review when needed; simulate with fixture or mark physical-camera portion NOT RUN. |
| `return-to-today.yaml` | Open Quick Add from Today → save → Today stays active and can immediately choose the new bottle. |
| `shelves-unified.yaml` | Collection → one-tap shelf view → rename shelf, move owned card, tap card returns to correct deck; no Shelves tab without parity. |
| `today-log-layer-undo.yaml` | Single wear → layered wear → history → Undo; no duplicate sessions, correct selection, no Today accessory over Today. |
| `compare-insights.yaml` | Open Insights from selected fragrance; expand sheet, select an actual recommended match and see Compare with the right selected identity; no invented fallback. |
| `wishlist-move-owned.yaml` | Wishlisted card has one Move CTA; move → one owned bottle, no duplicate, existing notes retained. |
| `search-filters-sort.yaml` | Filter & Sort sheet applies/sorts/persists through inspector navigation, Clear returns unfiltered results. |
| `cards-studio-create.yaml` | Cards has prominent create and clean overflow; existing Card Studio/photo/import/export paths still work where simulated. |
| `style-glass-accessibility.yaml` | Style has one About disclosure; change layout/theme/appearance, tray peek→expanded→close; verify dark/light/Reduce Motion/Reduce Transparency where automation supports it. |
| `preservation-smoke.yaml` | Welcome→Demo/Mine/Wishlist, Cover Flow/Stack/Fan, note reverse, 30 Autumn deck entry in internal build, offline persistence, no unrelated regressions. |

- Include negative, cancel/back, empty state, search no-results, long names, no-owned-comparable, app relaunch, and keyboard-overlap tests. Per flow capture **before/after screenshot**, hierarchy evidence, pass/fail and first failing step.
- Use a seeded **throwaway simulator only** for `clearState: true`; **never** wipe the owner's phone or real TestFlight collection. Verify an existing-data upgrade using a separate seeded fixture without clearing state.
- Reuse manual `Maestro iOS` CI workflow, expand as needed; add test artifacts on both failures and successful key captures if useful. Do not silently switch to Cloud testing (which exports data).
- For gestures Maestro cannot reliably synthesize (e.g. tilt-based foil) use native simulation if verified and request real iPhone validation; mark actual device evidence **NOT RUN** until genuinely executed.

## 6. Quantified definition of done — no self-reported 'looks good'

**Functional coverage**
- All **18 IDs** logged as `IMPLEMENTED + TESTED` or `N/A + EVIDENCED`. No unresolved item without explanation; never claim 18 unique improvements if several overlap.
- **100% functional parity** for pre-existing named actions: Browse, three layouts, shelf browse/rename/move, Demo/Mine/Wishlist, Add, OCR, Undo, notes, ownership, Today solo/layer/history, compare/recommended preselection, Search facets/sort, Studio, import/export, theme and owner tuning.
- **01:** search result → Inspector in exactly **one result selection**; Close returns to Search without clearing query/filter.
- **02:** typed name → choose destination + Save in **one capture surface** (no mandatory second Review); OCR review retained.
- **03:** shelves fully available **one action from Collection**; one editable shelf UI; four main tabs only after parity.
- **05:** zero unsolicited tab jumps after save, proven from at least Today and unified Shelves.
- **08:** zero Today→Today navigation accessory on Today tab; accessory remains functional from other tabs if shown.
- Existing focus → **Wear Today in one tap**; focused bottle → Layer → second bottle → Log in **≤3 actions** (not counting the initial browsing needed to focus bottle). One-tap Wishlist→owned conversion.
- All existing notes/data roundtrip on relaunch; no duplicate owned entries or accidental changes to demo identity. Search and user choices persist where appropriate.

**Visual fidelity**
- At least **one real native before/after screenshot per implemented ID**, grouped into a review gallery; screenshot is not a generated concept render.
- Review 375/390/430pt iPhone widths, 2 appearance modes, portrait, Dynamic Type, Reduce Motion, Reduce Transparency, and compact/expanded tray. No clipped controls or text; buttons hit targets ≥44pt when applicable.
- Frosteffect check (pass only with screenshot evidence): (1) selected product/card identifiable behind peek; (2) text readable on both dark/light; (3) visually translucent rather than opaque; (4) handle/close/compare accessible; (5) responsive detents; (6) interactive card physics not hijacked; (7) no photographic card-face blur; (8) contrast fallback works; (9) safe-area clear; (10) keyboard/dismiss behavior correct. All **10/10** checks required across key trays.
- Frame/gesture performance: inspect simulator hitch trends and compare with baseline, but **do not claim 60 fps on real iPhone** without a measured physical-device run.

**Execution / release gate**
- Native Debug and applicable internal Release build pass. Maestro targeted flows **and** full folder suite pass on iOS 26 simulator; report tool version/device/build SHA and links to evidence. Run repository's current applicable native+documentation checks; don't treat web/PWA checks as mobile proof.
- PR includes a table with baseline vs revised tap/screen counts, N/A decisions, per-ID screenshots, Maestro YAML and results, any VoiceOver/real-device gaps. Keep branch reviewable; **no automatic merge, TestFlight upload or App Store action**.
- A pass is **not** a generated screenshot, a passing TypeScript test, a compile-only result, or Claude's subjective polish rating.

## 7. Claude execution checklist

1. Read this file, current code, design-router/docs and Maestro skill. Verify latest `main` and baseline behavior; do not trust a mockup as code truth.
2. Research the linked Refero styles/screens/flows and 21st.dev inspiration; write a short reference lock in your PR. Preserve Arooma tokens and Apple-native semantics.
3. Build and run the simulator baseline. Inventory/screenshots/flow counts. Implement work phases in coherent commits.
4. Drive the app with **Maestro MCP as you code**, inspect hierarchy after every navigation refactor, write persistent .maestro YAML tests, and run the full CI-compatible suite.
5. Do final code/document parity and all quantified gates. Submit a PR with actual evidence. If the environment lacks a Mac/Xcode/simulator, stop short of claiming test success and state the exact unverified portion.
