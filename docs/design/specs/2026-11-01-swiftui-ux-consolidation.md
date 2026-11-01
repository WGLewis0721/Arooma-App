# Spec: SwiftUI UX consolidation and frosted trays

> Part of the [Arooma design brain](../README.md). Summary: Implements the 18 owner-reviewed UX items in [AROOMA_SWIFTUI_UX_CONSOLIDATION_PLAN.md](../../../AROOMA_SWIFTUI_UX_CONSOLIDATION_PLAN.md) that verified redundancy or navigation cost justified. Each item is IMPLEMENTED, RETAINED (intentional, not redundant), or NOT APPLICABLE (not reachable in the live UI), with code evidence. Verification is limited to the macOS CI build and the Maestro flows in `.maestro/`; nothing here is claimed as verified on a physical iPhone.

| | |
| --- | --- |
| Request | Consolidate redundant paths, simplify navigation and give swipe-up trays a frosted native treatment, without losing features, data or artwork. |
| Surface | Native SwiftUI app: tabs, Search, Quick Add, Collection shelves, View & Style, Cards, Season Compass tray. |
| Status | Implementation record. The branch is not merged. Simulator flows run on GitHub's macOS runner; physical-device checks are owed. |
| Source plan | [AROOMA_SWIFTUI_UX_CONSOLIDATION_PLAN.md](../../../AROOMA_SWIFTUI_UX_CONSOLIDATION_PLAN.md) |

## Decisions

| ID | Status | Change or evidence |
| --- | --- | --- |
| 01 Search → Inspector | IMPLEMENTED | A result selects its card and opens the Inspector directly (`AroomaApp.swift`, `select(_:)`). Close returns to Search with its state. Flow: `search-direct-inspect.yaml`. |
| 02 Quick Add | IMPLEMENTED (plain names) | A typed name with no photo and no label text saves to Collection or Wishlist in one step, with inline Undo and Done (`Capture.swift`, `saveDirect`). Photo and label captures still use the review card. |
| 03 Shelves | IMPLEMENTED | The editable shelf surface opens in one tap from Collection (All shelves) as a sheet. The separate Shelves tab is retired (four main tabs). Pinch keeps the spatial overview. Flow: `shelves-unified.yaml`. |
| 04 Search controls | IMPLEMENTED | Sort moved into the Filters sheet (`Search.swift`). |
| 05 Return to origin | IMPLEMENTED | Quick Add returns to the tab that opened it (Collection or Today) instead of forcing Collection. Flow: `return-to-today.yaml`. |
| 06 Duplicate About | IMPLEMENTED | One About disclosure remains, with the complete text (`AtelierStyle`). |
| 07 Duplicate Studio opener | IMPLEMENTED | The overflow Card Studio entry is removed; the header + and the empty-state button remain (`Commercial.swift`). |
| 08 Today accessory | IMPLEMENTED | The bottom accessory is disabled while Today is selected on iOS 26.1+ (`tabViewBottomAccessory(isEnabled:)`). On iOS 26.0 the accessory is shown but renders empty on Today, because `isEnabled:` needs 26.1 and the deployment target stays at 26.0. Verified only by compile in CI; not checked on device. |
| 09 Daily pick vs Repeat Last | NOT APPLICABLE | `AtelierOwnership`, the only view that showed the Daily Pick, is not referenced anywhere. The live Today screen shows only "Wear it again". |
| 10 Wear history surfaces | NOT APPLICABLE (as written) | The per-bottle `WearHistoryScreen` is reachable only from the unreferenced `AtelierOwnership`. Today's session timeline is the only history on live screens and is unchanged. |
| 11 Add entry points | RETAINED | Each surface has one Add in its context: the Collection header +, the Today picker header Add, and empty-state buttons that only appear when there is nothing to add. |
| 12 Wear / Layer / History | RETAINED | Collection shows Wear today as primary, Layer as secondary and Inspect as an icon. The Inspector shows Wear today and Details. |
| 13 Ownership notes | NOT APPLICABLE | The personal-notes preview is only in the unreferenced `AtelierOwnership`. `BottleEditor` is the single edit destination. |
| 14 Repeat wear CTAs | RETAINED | "Wear it again" is the prominent card; the per-session "Wear again" is a secondary menu item. They are not equally emphasized. |
| 15 Cards management | IMPLEMENTED (with 07) | Create is the header +; Import, Export and Restore stay in the overflow menu. |
| 16 Compare entry paths | RETAINED | The Insights panel has one Compare button; the card context menu and recommendation tiles are on other surfaces. |
| 17 Wishlist → Owned | RETAINED | A wishlisted card shows one primary action, Move to my collection. Unowned cards show Add to my collection, and Add to Wishlist only when not wishlisted. |
| 18 Group View & Style | IMPLEMENTED | Sections are Layout, Atmosphere and Appearance, Card lighting, and About (with the single About). Four palettes and owner tuning are unchanged. |

## Frosted trays

- The Season Compass tray (`InsightPanel`) uses a native `regularMaterial` behind its approved gradient at 78% opacity, with a hairline rim highlight.
- Reduce Transparency and Increase Contrast fall back to the opaque plate. The card face is never blurred.
- `FilterSheet` and `AtelierStyle` keep their system sheet presentation. No separate material was added to them.
- The ten-point frosted checklist from the plan needs device screenshots. It has **not** been run.

## Not verified

- Physical-device behavior, including touch feel, frosted legibility, haptics and frame pacing.
- Camera, photo-library and OCR paths. The `quick-add-ocr-review` flow from the plan is not written: it needs a fixture photo and the simulator photo picker.
- VoiceOver, Dynamic Type and the 375/390/430 pt width matrix. Only the flows listed above were run.
- Existing-data upgrade with a seeded fixture. The Maestro flows use clean installs.

## Maestro flows

Flows are in `.maestro/`, run by the manual *Maestro iOS* workflow on a macOS runner. Selectors use stable accessibility identifiers (`all-shelves`, `direct-collection`, `direct-done`, `scan-*`, `quick-add-review`, `view-and-style`) where visible text would be ambiguous.

**Latest result (run 41332782764, head `31ea0c1`):** 6 of 9 flows pass (`smoke`, `quick-add-wishlist`, `quick-add-name-owned`, `search-direct-inspect`, `return-to-today`, `style-sections`). Three fail: `quick-add-undo` (final assertion after Undo), `shelves-unified` (Rename Autumn below the fold, no scroll step) and `tuning-presets` (`Vivid Holo` assertion while the Tuning sheet is on screen). Flows were not edited after this run. Full evidence, the per-ID matrix and the gate status are in [the evidence README](../../evidence/2026-11-01-ux-consolidation/README.md).
