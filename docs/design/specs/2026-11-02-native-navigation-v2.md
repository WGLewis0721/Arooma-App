# Spec: Native navigation V2 (three tabs and annotated Explore cleanup)

> Part of the [Arooma design brain](../README.md). Source plan: [AROOMA_NATIVE_NAVIGATION_UX_V2_PLAN.md](../../../AROOMA_NATIVE_NAVIGATION_UX_V2_PLAN.md), which supersedes the earlier [UX consolidation](2026-11-01-swiftui-ux-consolidation.md) as the navigation roadmap. Evidence: [2026-11-02 navigation V2 evidence](../../evidence/2026-11-02-navigation-v2/README.md).

Summary: Arooma's SwiftUI app moves from four tabs (Collection, Today, Cards, Search) to three (Explore, Today, My Collection). Explore is the sample deck, with Search as a function inside it. My Collection holds owned bottles, the Wishlist as a view, Shelves and My Cards. The owner's annotated screenshot is implemented as twelve fixes, and the square mode menu is removed with no long-press replacement.

| | |
| --- | --- |
| Branch | `feat/native-navigation-v2`, from `origin/main` at `4b9e75c` |
| Scope | `ios/AroomaNative/` (navigation shell, deck, Today and Search entry), `.maestro/`, design docs |
| Not in scope | Build-notes popup, bundle ID, Codemagic or TestFlight, signing, deployment, changes to persisted records, artwork or the PWA |
| Status | Implemented; simulator evidence collected on the GitHub macOS runner. Not merged. |

## Information architecture

| Tab | Contents | Data context |
| --- | --- | --- |
| Explore | Immersive sample deck. Search (magnifier) opens a sheet. View & Style (one utility). | Sample deck (`archive.mode == .demo`) |
| Today | Wear, layer, repeat, history, undo. | Owned bottles only |
| My Collection | Owned / Wishlist segmented view, All shelves, My Cards, Quick Add (+). | Owned (`.mine`) or Wishlist (`.wishlist`) |

Each tab sets its data context on selection (`alignMode(with:)` in `AroomaApp.swift`). Switching tabs never edits saved records. The selected card in each context is kept in its own store field (`selectedDemoID`, `selectedMineID`, `selectedWishID`).

## Annotation fixes (A1 to A12)

| Ref | Annotation | Resolution in code | Where |
| --- | --- | --- | --- |
| A1 | Square mode popup | Removed, including the wordmark chip. No long-press replacement. | `AtelierGallery.swift` header, removed |
| A2 | Permanent wordmark block | Removed from Explore. The header keeps one static "EXPLORE" label. | `exploreHeader` |
| A3 | Header Quick Add and All shelves | Removed from Explore. Shelves and Quick Add are in My Collection. One View & Style utility stays. | `exploreHeader`, `MyCollectionScreen` |
| A4 | Labelled Insights strip | Removed. A quiet grabber keeps VoiceOver "Show insights" and the swipe-up gesture. | `insightGrabber` |
| A5 | Dot scrubber | Removed. The numeric counter is the single position readout. | `identity` |
| A6 | 27 / 34 counter | Kept in the identity row, with VoiceOver "Card n of N". | `identity` |
| A7 | Loose + and heart | Compact 44pt contextual actions beside the name. Explore uses `addWithoutSwitching` so the sample deck stays on screen. | `contextActions`, `compactAction`, `CollectionStore.addWithoutSwitching` |
| A8 | Large gold Add CTA | Removed from Explore. Owned sample cards show "In your collection". | `identity`, `actions` (My Collection only) |
| A9 | Sample-archive banner | Removed. The Today shortcut shows only in My Collection's owned view. | `withTodayAccessory`, `TodayAccessory` |
| A10 | Bottom bar labels and Search tab | Tabs are Explore, Today, My Collection. Search is in Explore. | `AtelierRoot.tabBar` |
| A11 | Expand icon beside the CTA | Removed. A tap on the focused card already inspects. | `actions` |
| A12 | Density | The resting Explore deck has one header, the card, the counter, two compact actions and the tab bar. | Whole deck |

## Other items from the earlier audit

The earlier 18-item audit remains the traceability index, as the plan requires. Items are carried forward as follows.

| Items | Carried forward | Evidence |
| --- | --- | --- |
| 01, 04 | Search result opens its Inspector; Close keeps query, scopes and filters. Filters sheet holds Sort. | `ExploreSearchSheet`, `AtelierSearch` (unchanged), flow `explore-search-inspector` |
| 02, 05 | Typed-name Quick Add stays one step. Quick Add returns to the tab that opened it. | `QuickAddSheet` (unchanged), `addOrigin`, flows `quick-add-context`, `return-to-today` |
| 03, 11 | One editable Shelves surface, one action from My Collection. | `MyCollectionScreen`, flow `my-collection-shelves` |
| 06, 18 | View & Style grouped, one About. | `AtelierStyle` (unchanged), flow `appearance-studio-regression` |
| 07, 15 | My Cards is a sheet inside My Collection. Card Studio, import and export are kept. | `MyCardsScreen`, flow `my-cards-studio` |
| 08 | No Today accessory while on Today. The accessory is also hidden on Explore. | `withTodayAccessory` |
| 09, 10, 13 | Not applicable as written: the surfaces they describe are not reachable from live views. | Unchanged from the earlier audit |
| 12, 14, 16, 17 | Retained: Wear, Layer and Move actions exist in their contexts. | `actions`, `contextActions` |

## Frosted trays

- The Season Compass `InsightPanel` already uses `regularMaterial`, a 78% gradient plate, a hairline rim and an opaque fallback for Reduce Transparency and Increase Contrast. This change keeps it and does not add a second material.
- View & Style, Filters and Compare remain system sheets. Their system material is unchanged.
- Card faces are opaque artwork. Glass is applied only to controls and the tray.
- The ten-point frosted checklist from the plan needs screenshots across trays and appearances. Those screenshots are in the evidence folder if the run captured them. Anything not captured is marked not run.

## Maestro flows

Flows are in `.maestro/` and run in the manual *Maestro iOS* workflow on a macOS runner. Each flow uses a clean install (`clearState: true`). No flow touches real owner data.

| Flow | Tags | Covers |
| --- | --- | --- |
| `navigation-three-tabs` | navigation | Exactly three tabs; Explore opens first |
| `explore-no-mode-menu` | explore, navigation | No mode menu on tap or long press |
| `explore-annotated-cleanup` | explore, annotations | A2 to A6, A8 to A10, A12 |
| `explore-search-inspector` | explore, search | Search from Explore, result to Inspector, Close keeps the query |
| `wishlist-in-my-collection` | wishlist, navigation | Wishlist view; one move to owned |
| `my-collection-shelves` | shelves, navigation | One action to editable Shelves; rename and cancel |
| `my-cards-studio` | cards, navigation | My Cards and Card Studio reachable (photo capture not run) |
| `explore-insights-frosted` | explore, insights | Swipe up, peek, Close Insights |
| `explore-counter-navigation` | explore, counter | Counter follows swipes both ways |
| `quick-add-context` | quick-add, navigation | Save returns to the invoking tab |
| `today-preservation` | today | Wear, undo, Today log across tabs |
| `appearance-studio-regression` | appearance | View & Style reachable from Explore |
| `smoke` | smoke | Tabs, Search, Today, Shelves |
| `quick-add-wishlist`, `quick-add-name-owned`, `quick-add-undo`, `return-to-today`, `style-sections` | (existing) | Updated for the new entry points where needed |

`tuning-presets` remains in the backlog, as recorded in the 2026-11-02 failures spec.

## Results

Run [41345230832](https://github.com/WGLewis0721/Arooma-App/actions/runs/41345230832) on `41a0abc` (macOS runner, iOS 26 simulator, Maestro 2.12.0): 12 of 19 flows pass, 7 fail. The failures are:

- Flow errors, to fix in the flows: `explore-annotated-cleanup` and `explore-counter-navigation` (one swipe moved two cards); `explore-no-mode-menu` (case-insensitive match on the tab label).
- Decision needed: `wishlist-in-my-collection` (the app stays on the empty Wishlist after a move).
- Not resolved: `explore-insights-frosted` (the upward swipe did not open the tray; the same happened on `main`).
- Possible app defect, verify first: `explore-search-inspector` (Filters not reachable from the search sheet after closing an Inspector).
- Pre-existing: `tuning-presets` (backlog, unchanged).

The frosted-tray checklist (10 of 10) was not run. Full detail, frames and gate status: [the evidence README](../../evidence/2026-11-02-navigation-v2/README.md).

## Not verified

- Physical iPhone: touch, haptics, frame pacing, frosted legibility on device.
- VoiceOver traversal and Dynamic Type across the three tabs.
- The 375, 390 and 430 pt width matrix, Reduce Motion and Reduce Transparency, unless a flow or screenshot in the evidence folder shows otherwise.
- Photo capture and OCR, which need a fixture photo.
- Upgrade from existing owner data. Flows use clean installs.
