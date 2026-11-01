# Spec: Maestro flow failures after the UX consolidation

> Part of the [Arooma design brain](../README.md). Follows [SwiftUI UX consolidation and frosted trays](2026-11-01-swiftui-ux-consolidation.md). Evidence: [2026-11-01 verification evidence](../../evidence/2026-11-01-ux-consolidation/README.md). Handoff: [maestro-failures-handoff](2026-11-02-maestro-failures-handoff.md).

Summary: Three of nine Maestro flows fail on run `41332782764` (head `31ea0c1`). The app and flow code at that head is the code merged to `main` through PR #37; nothing under `ios/`, `.maestro/` or `.github/` changed after it. This spec defines each failure, what counts as fixed, and the limits on the fix. It does not cover new screenshot, width or device work.

| | |
| --- | --- |
| Source run | [41332782764](https://github.com/WGLewis0721/Arooma-App/actions/runs/41332782764), Maestro iOS workflow, `macos-26`, Maestro CLI 2.12.0, iOS 26.4 simulator |
| Passing | `smoke`, `quick-add-wishlist`, `quick-add-name-owned`, `search-direct-inspect`, `return-to-today`, `style-sections` |
| Failing | `shelves-unified`, `tuning-presets`, `quick-add-undo` |
| Status | Partly fixed (2026-11-02). F1 `shelves-unified` and F3 `quick-add-undo` fixed and passing on two consecutive CI runs; `quick-add-name-owned`, `quick-add-wishlist` and `return-to-today` hardened against the same 4 s toast race (one passing run). F2 `tuning-presets` still fails and is in the backlog. Suite is 8 of 9. Evidence: [2026-11-02 fixes](../../evidence/2026-11-02-maestro-fixes/README.md). |

## Failure register

Each entry lists what was observed, where the evidence is, and the open question. The evidence paths are relative to `docs/evidence/2026-11-01-ux-consolidation/`.

### F1 `shelves-unified`: step 7, `tapOn "Rename Autumn"`, element not found

- **Observed:** All shelves opens the sheet and "The shelves" is visible. The hierarchy at the failure lists `Rename Spring` and `Rename Summer`, and no Autumn row. The frame shows Spring and Summer; Autumn is below the fold.
- **Evidence:** `after/shelves-unified-failed-step7.jpg`, `after/hierarchy/step-007-tapOnElement-Rename_Autumn.json`, `maestro-after/flows/shelves-unified/maestro.log`.
- **Likely cause:** the flow has no scroll step. The shelf list is lazy, so Autumn is not in the tree until it is scrolled into view.
- **Code:** `AtelierShelves` in `ios/AroomaNative/AtelierSections.swift`; presented from `AtelierRoot` in `ios/AroomaNative/AroomaApp.swift`.

### F2 `tuning-presets`: step 8, `assertVisible "Vivid Holo"`, assertion false

- **Observed:** every command before the assertion completes, including the scroll to the Version row and the long press. The screenshot at step 8 shows the Tuning sheet with "Vivid Holo" on screen. The hierarchy captured at the same failure shows the View & Style sheet, with a Version row and no "Vivid Holo" node.
- **Evidence:** `after/tuning-presets-failed-step8.jpg`, `after/hierarchy/step-008-assertCondition-Vivid_Holo.json`, `maestro-after/flows/tuning-presets/maestro.log`.
- **Open question:** the screenshot and the snapshot disagree. Either the Tuning sheet, presented from View & Style, is missing from Maestro's accessibility snapshot, or it appears after the snapshot is taken. The exact-text hypothesis in the earlier draft is not supported: no node carries a combined "Vivid Holo" label.
- **Code:** `Tuning.swift` (preset list), `AtelierStyle` in `ios/AroomaNative/AtelierSections.swift` (Version row and long press).

### F3 `quick-add-undo`: step 12, `assertVisible "Undo Test Scent"`, assertion false

- **Observed:** every command before the final assertion completes: the name is typed, Collection is chosen, "Added to your collection" appears, Undo is tapped, and the toast text is gone. The final assertion then fails. The hierarchy shows the Cards tab selected, with "My Cards" and "No digital cards yet".
- **Evidence:** `after/quick-add-undo-failed-step12.jpg`, `after/hierarchy/step-012-assertCondition-Undo_Test_Scent.json`, `maestro-after/flows/quick-add-undo/maestro.log`.
- **Contradiction:** the flow's header comment says the bottle "does not stay in the collection". The final assertion expects "Undo Test Scent" to stay visible. One of the two is wrong.
- **Open question:** why the app lands on Cards after Undo. The Collection add path calls `startAdd(from: .gallery)`, so the return tab should be Collection, not Cards.
- **Code:** `AtelierRoot` `onAdded` sets `tab = addOrigin` in `AroomaApp.swift`. `QuickAddSheet.undoDirect`, `finishDirect` and the `directToken` timer are in `ios/AroomaNative/Capture.swift`.

## Decision rules

- A failure is a **flow bug** when the flow asserts something the code or spec does not promise. Fix the flow and say so in the commit message.
- A failure is an **app bug** when the app violates the behavior in this spec or in `2026-11-01-swiftui-ux-consolidation.md`. Fix the app with the smallest change that restores that behavior.
- F3 needs a decision on the intended behavior first. Decide from the code, the header comment and the consolidation spec's item 05 (return to origin). Record the decision in the fix PR.
- Do not weaken an assertion to make a flow pass. Do not add `optional: true` to a failing assertion. Do not delete a failing step.

## Acceptance

Fixed means all of the following:

1. `maestro check-syntax` passes for every file in `.maestro/`.
2. The Maestro iOS workflow, triggered by `workflow_dispatch` on the fix branch, reports **9 of 9** in `junit.xml`.
3. Each fixed flow passes on two consecutive runs. F2 is the most likely to be flaky.
4. `npm run docs:check` and `npm run test:docs` pass.
5. The fix PR contains the run link, the artifact id and a short note per failure: cause, change, and whether it was a flow bug or an app bug.
6. The evidence for the fix is in `docs/evidence/2026-11-02-maestro-fixes/`, with the same layout as the 2026-11-01 folder.

If a failure cannot be fixed, the PR says so, with the evidence that shows why. A partial result is acceptable. A false pass is not.

## Constraints

- Only change `ios/AroomaNative/`, `.maestro/` and docs. Keep the bundle ID `com.graymatter.arooma`, the Codemagic and TestFlight configuration, persisted IDs, and the storage schema unchanged.
- Maestro flows run against a clean install with `clearState: true`. Never point a flow at real owner data.
- No signed builds, TestFlight uploads, App Store actions or Codemagic runs. These are manual and outside this spec.
- Card artwork stays opaque. Glass stays on chrome and trays only.
- Do not merge to `main`. The fix PR is opened for review.

## Out of scope

These remain listed as **not run** in the evidence README. Do not claim them from this work:

- One real screenshot per implemented ID.
- The 375, 390 and 430 pt width matrix, appearance modes, Dynamic Type, Reduce Motion and Reduce Transparency.
- The 10/10 frosted-tray checklist.
- Physical-device behavior, haptics, frame pacing and VoiceOver.
- The `quick-add-ocr-review` flow, which needs a fixture photo.
- Release build.

## Commands

- Lint a flow: `maestro check-syntax .maestro/<flow>.yaml`. On the Linux sandbox the CLI is at `~/.maestro/bin/maestro`. On macOS, install it with `curl -Ls "https://get.maestro.mobile.dev" | bash`.
- Run CI on a branch: GitHub Actions, *Maestro iOS*, *Run workflow*, choose the branch. Leave the tag inputs empty to run all flows. Use `include_tags` to run one flow group.
- Download results: the `Maestro-results` artifact on the run. It holds `junit.xml`, `run/<timestamp>/<flow>/` logs, screenshots and hierarchies, and `final-screen.png`.
