# UX consolidation: verification evidence (2026-11-01)

> Part of the [Arooma design brain](../../design/README.md). Companion to the [implementation spec](../../design/specs/2026-11-01-swiftui-ux-consolidation.md) and the [source plan](../../../AROOMA_SWIFTUI_UX_CONSOLIDATION_PLAN.md).

**Result in one line:** the Debug build passes on the macOS CI runner, and 6 of 9 Maestro flows pass. Three flows fail. Most visual and device gates were not run, so this branch is not ready to merge on the strength of this evidence.

## Run identity

| Item | Value |
| --- | --- |
| Branch | `feat/swiftui-ux-consolidation` |
| Build SHA (app and flows) | `31ea0c1aab4b223d3080c4a7472c96dc77a0f370` |
| After run | [41332782764](https://github.com/WGLewis0721/Arooma-App/actions/runs/41332782764), Maestro iOS workflow |
| Baseline run | 41330577932 (commit `c3205eb`, flows added before the consolidation code) |
| Runner | GitHub-hosted `macos-26`, Debug build with `CODE_SIGNING_ALLOWED=NO` |
| Simulator | iPhone (first device with an iOS 26 runtime, chosen by the workflow); runtime iOS 26.4. Model name not captured in the logs. |
| Tool | Maestro CLI 2.12.0 |
| Artifact | `Maestro-results`, id 13095105625, kept until 2026-11-15 |

## Gate status (plan section 6)

| Gate | Status | Evidence |
| --- | --- | --- |
| Native Debug build passes | MET | "Build Debug simulator app" succeeded on `31ea0c1`. |
| Targeted Maestro flows and full folder suite pass | NOT MET | 6 of 9 pass. Failures below. |
| Native Release build | NOT RUN | Not part of this workflow. |
| One real before/after screenshot per implemented ID | NOT MET | Maestro saves screenshots only for failing steps. No per-ID screenshots were captured for passing flows. |
| 375, 390 and 430 pt widths; both appearance modes; Dynamic Type; Reduce Motion; Reduce Transparency; compact and expanded trays | NOT RUN | No simulator matrix was run. |
| Frosted-tray 10/10 checklist | NOT RUN | Needs screenshots across trays. |
| Frame and gesture performance | NOT RUN | Requires a physical device. |
| Baseline vs revised tap and screen counts | NOT MEASURED | No count table was produced. |
| VoiceOver and physical-device behavior | NOT RUN | See the spec's "Not verified" list. |

## Maestro flows (run 41332782764)

| Flow | Result | Detail |
| --- | --- | --- |
| `smoke` | PASS | Tabs, All shelves sheet, Today and Cards reachable. Baseline: PASS. |
| `quick-add-wishlist` | PASS | One-step Wishlist save. Baseline: FAIL at step 11 (review card still open, `before/quick-add-wishlist-failed-step11.jpg`). |
| `quick-add-name-owned` | PASS | One-step Collection save; the item survives relaunch. |
| `search-direct-inspect` | PASS | Result opens the Inspector directly; Close returns to Search. |
| `return-to-today` | PASS | Quick Add opened from Today returns to Today. |
| `style-sections` | PASS | Arrangement, Atmosphere, Card lighting and About are present; About is reached by scrolling. |
| `quick-add-undo` | FAIL | Fails at the last step, `assertVisible "Undo Test Scent"`, after Undo. The frame (`after/quick-add-undo-failed-step12.jpg`) and the hierarchy (`after/hierarchy/step-012-*.json`) show the Cards tab selected, not Collection. The flow header says the bottle should not stay in the collection, which contradicts the final assertion. The cause is not established. |
| `shelves-unified` | FAIL | Fails at step 7, `tapOn "Rename Autumn"`. The Autumn shelf is below the fold of the Shelves sheet and the flow has no scroll step. The hierarchy at the failure lists Rename Spring and Rename Summer but no Autumn row (`after/hierarchy/step-007-*.json`). The All shelves tap and the "The shelves" header passed. |
| `tuning-presets` | FAIL | Fails at step 8, `assertVisible "Vivid Holo"`. The frame (`after/tuning-presets-failed-step8.jpg`) shows the Tuning sheet with "Vivid Holo" on screen. The hierarchy captured at the same failure (`after/hierarchy/step-008-*.json`) shows the View & Style sheet and has no "Vivid Holo" node. The screenshot and the snapshot disagree. Open question: whether the Tuning sheet is missing from Maestro's accessibility snapshot, or appears after it. Baseline failed earlier, at step 6 (Version row below the fold). The scroll step now works. |

Logs for every flow, with commands and manifests, are in `maestro-after/flows/`. The JUnit report is `maestro-after/junit.xml`. The final view hierarchy is `maestro-after/final-hierarchy.txt`.

## Decision IDs

BEFORE means the code before the consolidation batch, or the baseline run where one exists. The baseline run had only three flows, so most BEFORE cells come from code, not frames.

| ID | Spec status | BEFORE | AFTER | Evidence | Verified in this run? |
| --- | --- | --- | --- | --- | --- |
| 01 Search to Inspector | IMPLEMENTED | Result path went through an extra step (code) | Opens Inspector directly | `search-direct-inspect` PASS | Yes, by flow. No screenshot. |
| 02 Quick Add, plain name | IMPLEMENTED | Typed name always went to the review card (`before/quick-add-wishlist-failed-step11.jpg`) | One-step save to Collection or Wishlist | `quick-add-wishlist` and `quick-add-name-owned` PASS; `quick-add-undo` FAIL | Partly. The Undo path fails. |
| 03 Shelves | IMPLEMENTED | Separate Shelves tab (code) | All shelves opens one tap from Collection; tab retired | `smoke` PASS; `shelves-unified` FAIL at step 7 | Partly. Reorder and rename not reached. |
| 04 Sort in Filters | IMPLEMENTED | Sort in the toolbar (code) | Sort inside the Filters sheet | None | No. Code only. |
| 05 Return to origin | IMPLEMENTED | Quick Add always forced Collection (code) | Returns to the originating tab | `return-to-today` PASS | Yes, by flow. |
| 06 Duplicate About | IMPLEMENTED | Two About entries (code) | One About, with the full text | `style-sections` PASS | Partly. Reachability checked; absence of the duplicate not asserted. |
| 07 Card Studio opener | IMPLEMENTED | Overflow menu had a Card Studio entry (code) | Entry removed; header + and empty-state button remain | None | No. Code only. |
| 08 Today accessory | IMPLEMENTED | Always shown (code) | Hidden on Today on iOS 26.1+; empty on Today on iOS 26.0 | Compile only | No. Behavior not checked. |
| 09 Daily pick vs Repeat | NOT APPLICABLE | Daily Pick only in `AtelierOwnership` | Unchanged | Code reference search: `AtelierOwnership` unreferenced | N/A |
| 10 Wear history surfaces | NOT APPLICABLE | Per-bottle history only in unreferenced `AtelierOwnership` | Unchanged | Code reference search | N/A |
| 11 Add entry points | RETAINED | One Add per surface | Unchanged | Add from empty state used by quick-add flows | Yes, by flow. |
| 12 Wear / Layer / History | RETAINED | Wear today primary, Layer secondary | Unchanged | None | No. |
| 13 Ownership notes | NOT APPLICABLE | Notes preview only in unreferenced `AtelierOwnership` | Unchanged | Code reference search | N/A |
| 14 Repeat wear CTAs | RETAINED | Two wear actions with different emphasis | Unchanged | None | No. |
| 15 Cards management | IMPLEMENTED with 07 | Import, Export and Restore in overflow (code) | Create is the header +; maintenance stays in overflow | `smoke` asserts My Cards only | Partly. Create and import not exercised. |
| 16 Compare entry paths | RETAINED | Compare on several surfaces | Unchanged | None | No. |
| 17 Wishlist to Owned | RETAINED | One primary action on a wishlisted card | Unchanged; `wishlist-move-owned` not written | None | No. |
| 18 View and Style grouping | IMPLEMENTED | Ungrouped, duplicated About (code) | Layout, Atmosphere, Appearance, Card lighting, About | `style-sections` PASS | Partly. Appearance and Signature not asserted. |
| Tuning presets (owner tool, not one of the 18) | Existing | Baseline failed at step 6 | Passes step 6; fails at step 8 | `tuning-presets` FAIL | Failing |

## Not verified

- Physical iPhone: touch feel, frosted legibility, haptics, frame pacing.
- VoiceOver, Dynamic Type, the 375/390/430 pt width matrix, Reduce Motion, Reduce Transparency.
- Camera, photo picker and OCR. The `quick-add-ocr-review` flow is not written; it needs a fixture photo.
- Upgrade with seeded owner data. Flows use clean installs.
- `tabViewBottomAccessory` on iOS 26.0: compiled in CI, not exercised.
- Release build.

## Files

- `before/`: baseline frames, downscaled to 600 px wide JPEG.
- `after/`: failing-step frames and the final screen, downscaled the same way.
- `after/hierarchy/`: view hierarchies captured at the three failing steps.
- `maestro-before/`, `maestro-after/`: JUnit reports, final view hierarchies and per-flow logs. The 36 MB zip is not committed; the Actions artifact above holds it until 2026-11-15.
