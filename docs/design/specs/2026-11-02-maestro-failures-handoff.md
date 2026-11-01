# Handoff: fix the three failing Maestro flows

> Part of the [Arooma design brain](../README.md). Read the [failures spec](2026-11-02-maestro-failures-spec.md) first. It is the source of truth for scope, decision rules and acceptance.

## Start here

- Repo: `WGLewis0721/Arooma-App`. The UX consolidation has merged to `main` through PR #37.
- The three failures are F1 `shelves-unified`, F2 `tuning-presets` and F3 `quick-add-undo` in the spec.
- Evidence: `docs/evidence/2026-11-01-ux-consolidation/` (README, `after/`, `after/hierarchy/`, `maestro-after/`).

## Prompt to paste

```text
Fix the three failing Maestro flows in WGLewis0721/Arooma-App.

Read docs/design/specs/2026-11-02-maestro-failures-spec.md first. It is the source of truth. Then docs/evidence/2026-11-01-ux-consolidation/README.md.

Setup:
- Create branch fix/maestro-failures from main. Do not push to main. Do not merge.
- Do not run Codemagic, TestFlight, App Store or signed-build actions.
- Do not weaken assertions. Do not add optional: true to failing steps. Do not delete failing steps.

Work in this order:
1. shelves-unified, step 7: tapOn "Rename Autumn" fails because Autumn is below the fold and not in the hierarchy. Add a scroll step before the tap. Check the hierarchy JSON in docs/evidence/2026-11-01-ux-consolidation/after/hierarchy/ first.
2. tuning-presets, step 8: assertVisible "Vivid Holo" fails. The screenshot shows the Tuning sheet, but the hierarchy at that moment has the View & Style sheet and no "Vivid Holo" node. Find out whether the sheet is missing from the snapshot or appears late. Fix the flow (wait, or a stable identifier) and change the app only if the evidence shows an app bug.
3. quick-add-undo, final step: assertVisible "Undo Test Scent" fails after Undo. The header says the bottle should not stay, and the app lands on Cards after Undo. Decide the intended behavior from the spec's decision rules, Capture.swift and AroomaApp.swift. Then fix the flow or the app, and say which.

Verify:
- maestro check-syntax on every file in .maestro/.
- Push the branch. Trigger the Maestro iOS workflow on it (workflow_dispatch). Download Maestro-results.
- Target: 9 of 9 in junit.xml. Each fixed flow must pass on two consecutive runs.
- npm run docs:check and npm run test:docs.

Record:
- docs/evidence/2026-11-02-maestro-fixes/README.md: run link, artifact id, the junit summary, and per failure the cause, the change, and whether it was a flow bug or an app bug. Copy the failing-step frames and hierarchies if any still fail.
- Update the status line in the spec.

Open a PR against main with the same content. Do not merge it.

Report back: per failure, root cause, change, run result. If a failure is still open, say what you ruled out and what would settle it.
```

## Steps in plain terms

1. Read the spec and the evidence README.
2. Create `fix/maestro-failures` from `main`.
3. Fix F1 first. It is a flow-only change in the normal case.
4. Investigate F2 with the hierarchy and the screenshot before changing anything. Add a wait or a stable identifier only if the cause is confirmed.
5. Decide F3's intended behavior from the code and the consolidation spec's item 05 (return to origin). Then fix it in the flow or the app, whichever the decision says.
6. Lint, push, run the Maestro iOS workflow on the branch, and download `Maestro-results`.
7. Repeat the run until the target passes, or stop with the evidence for what still fails.
8. Record the evidence, update the spec status, open the PR. Do not merge.

## Stop and report instead of continuing when

- F3's intended behavior cannot be decided from the code and spec. Report both readings with the evidence for each.
- A fix would change persisted data, storage, bundle ID or the Codemagic path.
- The workflow fails before the flows run (build or install). Report the job step and the log line.

## Done

- The spec's acceptance list is met, or each unmet item has evidence explaining why.
- The PR is open against `main` and not merged.
- The evidence folder for the fix is committed on the branch.
