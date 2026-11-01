# Maestro flow failures: fix evidence (2026-11-02)

> Part of the [Arooma design brain](../../design/README.md). Companion to the [failures spec](../../design/specs/2026-11-02-maestro-failures-spec.md) and the [2026-11-01 evidence](../2026-11-01-ux-consolidation/README.md).

**Result in one line:** two of the three failing flows are fixed and verified on two consecutive CI runs (`shelves-unified`, `quick-add-undo`). A fourth flow that was failing, `quick-add-name-owned`, is fixed and passed once. `tuning-presets` is still failing and is left as a backlog item with the evidence below. The suite is **8 of 9**, not the 9 of 9 the spec asks for.

## Runs

| Run | Head | Artifact | Result |
| --- | --- | --- | --- |
| [41332782764](https://github.com/WGLewis0721/Arooma-App/actions/runs/41332782764) (source, before) | `31ea0c1` | 13095105625 | 9 flows, 6 pass, 3 fail |
| [41336948314](https://github.com/WGLewis0721/Arooma-App/actions/runs/41336948314) | `04e17b4` | 13096357038 | 11 flows (9 plus 2 temporary diagnostics): `shelves-unified` and `quick-add-undo` pass; `quick-add-name-owned` and `tuning-presets` fail |
| [41339765579](https://github.com/WGLewis0721/Arooma-App/actions/runs/41339765579) | `46b7738` | 13097118455 | No flow ran: `iOS driver not ready in time` (Maestro XCTest runner start-up). See `maestro-run-2/README.txt`. Re-dispatched once. |
| [41341165470](https://github.com/WGLewis0721/Arooma-App/actions/runs/41341165470) | `46b7738` | 13098053045 | 12 flows (9 plus 3 temporary diagnostics): 10 pass, `tuning-presets` fails, and one diagnostic fails on purpose to dump a hierarchy |

All runs: GitHub-hosted `macos-26`, Debug build with `CODE_SIGNING_ALLOWED=NO`, iPhone 17 Pro simulator on iOS 26.4, Maestro CLI 2.12.0. The workflow's "Check flow syntax" step (`maestro check-syntax` on every `.maestro/*.yaml`) passed in all three runs that reached it. It was not run locally: the sandbox denied installing the CLI.

Per-flow results (junit), the two runs that reached the flows:

| Flow | Run 41336948314 | Run 41341165470 |
| --- | --- | --- |
| `smoke` | pass | pass |
| `search-direct-inspect` | pass | pass |
| `style-sections` | pass | pass |
| `shelves-unified` (F1) | **pass** | **pass** |
| `quick-add-undo` (F3) | **pass** | **pass** |
| `quick-add-name-owned` | **fail** (Done tap too late) | **pass** |
| `quick-add-wishlist` | pass | pass |
| `return-to-today` | pass | pass |
| `tuning-presets` (F2) | fail | fail |

Runs 41336948314 and 41341165470 ran the Quick Add flows with different content: `quick-add-name-owned`, `quick-add-wishlist` and `return-to-today` got the QA argument only in the second. So the second pass of those three is their only pass on the fixed flow.

The merged tree removes the temporary diagnostic flows and restores `tuning-presets.yaml` to its pre-existing steps. It was not run as a whole. Removing flows cannot change the others.

## F1 `shelves-unified`: flow bug, fixed

- **Cause:** the shelf list in `AtelierShelves` is a `LazyVStack`. Only Spring and Summer were in the accessibility tree; Autumn was below the fold, so `tapOn "Rename Autumn"` found nothing. The failing hierarchy had `Rename Spring` and `Rename Summer` and a scroll bar reporting 3 pages.
- **Change:** a `scrollUntilVisible` on "Rename Autumn" before the tap. No assertion changed; no app change.
- **Result:** pass on both runs that ran it. Rename, Cancel, Done and "Add to my collection" all passed, so nothing else was hiding behind the first failure.

## F3 `quick-add-undo`: flow bug, with a QA-only app seam

- **The premise in the spec is wrong.** The app does not land on Cards after Undo. Undo never ran. `QuickAddSheet.undoDirect` restores the draft and keeps the sheet open; it never changes tabs.
- **Cause:** the one-step save closes itself after 4 s (`saveDirect`, then `finishDirect`, then `onAdded` returns to the origin tab, which is correct for item 05). In the source run the Undo touch arrived **6.28 s** after the save, so the sheet was already gone and the tap at (304, 809) landed on the **Cards** tab, whose bounds in the failing hierarchy are `[208,795][307,849]`. That is why the final screen was Cards. Timings are in `diagnosis/f3-save-to-next-tap.txt`.
- **Why the flow alone cannot fix it:** Maestro's iOS driver waits a fixed 3 s (`SCREEN_SETTLE_TIMEOUT_MS`) for a static screen after every tap. Arooma's foil animation means the screen never goes static, so the wait always runs out. The runner log shows the save touch at 43.77 and the Undo touch at 50.05, with `isScreenStatic` polled repeatedly in between and never returning true. `waitToSettleTimeoutMs` does not shorten that part. Two taps cannot be under 4 s apart.
- **Intended behaviour (decision):** the 4 s window stays. After Undo the bottle is removed, the typed name returns to the field and Quick Add stays open. The flow's header ("the bottle does not stay in the collection") and its final assertion ("Undo Test Scent" visible) agree: the name is back in the field. The old assertion alone could also be satisfied by a committed bottle's card on the Collection tab, so it could pass falsely.
- **Change:**
  - Flow: `launchApp` passes `arguments: AroomaQAUndoWindow: 30`. New assertions: Save is offered again (`direct-collection`), then after Close the collection is empty ("Add a fragrance" visible, name not visible). No existing assertion changed.
  - App: `QuickAddSheet.undoWindow` reads `-AroomaQAUndoWindow <seconds>` only when `BuildChannel.allowsOwnerTools` is true (Debug and TestFlight). App Store builds and normal launches keep 4 s. Same pattern as the existing `AroomaQATab` and `AroomaQAInspect` arguments. No user-visible change.
- **Classification:** a flow bug (the flow assumed Undo stays tappable for about 6 s; the code promises 4 s) that needed a test seam in the app. It is not an app bug: nothing in the spec says the window must be longer.
- **Result:** pass on both runs. The 30 s window took effect (the Undo touch came 4.85 s after the save in run 41336948314, past the 4 s default), so Maestro does deliver `launchApp.arguments` to the app as launch arguments.

## Scope extension: the other Done-tapping Quick Add flows

`quick-add-name-owned` failed in run 41336948314 for the same reason as F3: the Done touch came **6.43 s** after the save and landed at (351, 809), which is the Search tab; the screen it ended on was Search ("35 results"). It had passed in the source run only by luck. Save-to-Done intervals in the source run were 4.45 s, 4.36 s and 3.27 s for `quick-add-name-owned`, `quick-add-wishlist` and `return-to-today`, all at or past the 4 s window, and 5.05 s and 5.31 s for the last two in the next run. They pass when the touch lands while the sheet is still sliding away.

- **Change:** the same `-AroomaQAUndoWindow 30` argument on those three flows. No assertion changed. This is outside the three flows the spec names; it is here because 9 of 9 cannot hold otherwise.
- **Classification:** flow bug (timing assumption). **Result:** `quick-add-name-owned` failed before and passed after; wishlist and return-to-today passed. One run with the change; the spec's two-run bar is not met for these three.

## F2 `tuning-presets`: not fixed, backlog

What is established (`diagnosis/`):

- The Tuning sheet is on screen. The failing frame and a passing diagnostic's frame are pixel-identical below the status bar.
- It is in the app's own XCTest accessibility snapshot for the whole failing window: a `CollectionView` (the Tuning `Form`) next to the View & Style `ScrollView` appears in the first snapshot after the press and stays through the last, about 18 s later. So it is not missing from the app and not the exact-text hypothesis.
- Maestro's hierarchy, built from that same snapshot, shows only **one** sheet at a time. When the check works it shows only Tuning (View & Style disappears, consistent with XCTest keeping only the top modal); when it fails it shows only View & Style. Maestro's runner has no sheet filter of its own (`ViewHierarchyHandler.swift`, cli-2.12.0) and the CLI only drops nodes that are almost entirely off screen, so the choice is most likely made upstream of Maestro, in XCTest's accessibility capture. That reading is inferred from source and logs, not shown directly.
- **It appears late, by a variable amount.** `tuning-presets` is flow #4 in every run and the first to open Tuning; it never saw "Vivid Holo" within about 18 s, three runs in a row. Every later opening in the same session saw it within 0.8 s to 9.9 s (`f2-time-to-first-sighting.txt`).
- Ruled out: a screenshot request as the trigger (`tuning-presets` took one and still failed); `snapshotKeyHonorModalViews` (it is 0 in both the app and `testmanagerd`, so changing it would do nothing); the exact-text hypothesis; the app being blocked (snapshots return in 0.1 to 0.2 s); `assertVisible` against `extendedWaitUntil` (same result, different positions).
- Also found: at the half-height detent the "Quick adjust" header is below the fold, so the second assertion would need a scroll even once the first passes.

**What would settle it** (not run): `tuning-presets` as the only flow (`include_tags: owner-tools`) to see whether it is the first opening, the position, or chance; `extendedWaitUntil` with 60 s on the first opening; the `device-simulator.log` from a run where the sheet appears at about 10 s, to see what changes at that moment. A fix would be a longer wait (a flow fix), unless the cause is in the app's presentation of a second sheet.

- **Classification so far:** unknown. Nothing shows an app bug, so F2 changes nothing in the app.
- **State on `main`:** the flow is unchanged apart from a three-line KNOWN FAILING comment. It still fails. Logged in `docs/design/DECISIONS.md` under open decisions.

## Gates

| Gate | Status |
| --- | --- |
| `maestro check-syntax` on every `.maestro/` file | Passed in CI on every run that reached it; not run locally (CLI install denied in the sandbox) |
| Maestro iOS workflow on the branch, 9 of 9 | NOT MET: 8 of 9 |
| Each fixed flow passes on two consecutive runs | MET for F1 and F3. One pass for the three hardened Quick Add flows. F2 not fixed. |
| `npm run docs:check` and `npm run test:docs` | Passed (see the PR) |
| `npm test` | Passed: 221 checks, 0 failures |
| Evidence folder, same layout as 2026-11-01 | This folder: `maestro-run-N/` holds junit, per-flow commands and logs, failing hierarchies and downscaled frames; the 41 MB device logs are not committed |

Not verified, as before: physical-device behaviour, haptics, VoiceOver, the width and appearance matrix, Release build, and the OCR flow.

## Files

- `maestro-run-1/`, `maestro-run-3/`: junit, `flows/<flow>/` with `commands.json`, `maestro.log`, hierarchies, frames and `touches.txt`. Run 1 includes the two first diagnostic flows; run 3 the other three. The diagnostic flows themselves were deleted from `.maestro/`.
- `maestro-run-2/`: why that run produced nothing.
- `diagnosis/`: `f3-save-to-next-tap.txt`, `f2-snapshot-signatures.txt`, `f2-time-to-first-sighting.txt`.
