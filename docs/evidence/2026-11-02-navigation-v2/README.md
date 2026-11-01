# Native navigation V2: evidence (2026-11-02)

> Part of the [Arooma design brain](../../design/README.md). Spec: [native navigation V2](../../design/specs/2026-11-02-native-navigation-v2.md). Source plan: [AROOMA_NATIVE_NAVIGATION_UX_V2_PLAN.md](../../../AROOMA_NATIVE_NAVIGATION_UX_V2_PLAN.md).

**Result in one line:** the full Maestro folder ran on the GitHub macOS runner and 12 of 19 flows passed. Seven failed. Four failures are caused by the flows, one needs a device check, and two may be app behavior that needs a decision or a fix. Most of the plan's visual and device gates were not run.

## Runs

| Purpose | Ref | Run | Result |
| --- | --- | --- | --- |
| Before: unchanged `main` app, capture flow only | `chore/nav-v2-before-capture` at `2a72643` | [41344752409](https://github.com/WGLewis0721/Arooma-App/actions/runs/41344752409) | Captured 4 frames; failed at the shelves `Done` tap |
| After: full Maestro folder | `feat/native-navigation-v2` at `41a0abc` | [41345230832](https://github.com/WGLewis0721/Arooma-App/actions/runs/41345230832) | 12 pass, 7 fail |

Environment for both runs: GitHub-hosted `macos-26`, Debug simulator build (unsigned), iOS 26 simulator, Maestro CLI 2.12.0. The After artifact is `Maestro-results` (id 13100335017), kept until 2026-11-15.

**What the After run did not include:** commit `63c6b71` (aligns the data context with Explore on launch, for returning users whose last view was My Collection) and the docs commit `11e0383`. Both are on `main` and were not exercised by a flow.

## Flow results (run 41345230832)

| Flow | Result | First failing step | Classification |
| --- | --- | --- | --- |
| `smoke` | PASS | | |
| `navigation-three-tabs` | PASS | | |
| `my-collection-shelves` | PASS | | |
| `my-cards-studio` | PASS | | |
| `today-preservation` | PASS | | |
| `appearance-studio-regression` | PASS | | |
| `quick-add-context` | PASS | | |
| `quick-add-name-owned` | PASS | | |
| `quick-add-wishlist` | PASS | | |
| `quick-add-undo` | PASS | | |
| `return-to-today` | PASS | | |
| `style-sections` | PASS | | |
| `explore-annotated-cleanup` | FAIL | Step 17: `assertVisible "Card 2 of .*"` after one left swipe. The counter reads 03 / 04. | **Flow error.** One fast swipe moved two cards. The absence checks before it passed. |
| `explore-counter-navigation` | FAIL | Step 7: `assertVisible "Card 2 of .*"` after one left swipe. Same result as above. | **Flow error**, same cause. |
| `explore-no-mode-menu` | FAIL | Step 9: `assertNotVisible "My collection"` | **Flow error.** The match is the tab-bar label "My Collection", so text matching is case-insensitive here. No menu is on screen. |
| `wishlist-in-my-collection` | FAIL | Step 12: `assertVisible id: wear-today` after `wishlist-move` | **Expected behavior is undecided.** After the move, the app stays on the Wishlist view, which is now empty. The flow expected the Owned deck. Decide whether a move should switch to Owned. |
| `explore-insights-frosted` | FAIL | Step 6: `assertVisible "Close Insights"` after an upward swipe. No tray opened. | **Not resolved.** The same swipe did not open the tray on `main` in the before capture, so this is not a regression from this change. Needs a device check. The grabber tap path is not yet covered by a flow. |
| `explore-search-inspector` | FAIL | Step 13: `tapOn "Filters"`, element not found, after closing the Inspector | **Possible app defect.** The search sheet's accessibility tree has no Filters item at that step. If Filters and Sort are unreachable, that is a regression and needs a fix. Verify on a device first. |
| `tuning-presets` | FAIL | Step 9: `assertVisible "Quick adjust"` | **Pre-existing backlog flow**, unchanged in this PR. It moved to the backlog in #38. |

Total suite time: 1082 s.

## What the frames show

These frames were captured from the run and downscaled to 600 px wide. Hierarchies for each failing step are in `after/hierarchy/`.

| Frame | Shows | Confirms |
| --- | --- | --- |
| `after/nav-01-explore-first-launch.jpg` | Explore first launch | Three tabs at the bottom: Explore, Today, My Collection |
| `after/nav-02-today.jpg` | Today | Today tab reachable |
| `after/nav-03-my-collection.jpg` | My Collection | Owned and Wishlist segmented control; All shelves, My Cards and + at top right |
| `after/explore-annotated-after.jpg` | Explore resting deck | "EXPLORE" label; search and View & Style; card; grabber with no text; counter 01 / 04; + and heart; no dots, no banner, no gold CTA, no square menu |
| `after/inspector-from-search.jpg` | Inspector opened from Search | Result opens the Inspector |
| `after/today-after-wear.jpg` | Today after a wear | Wear logged |
| `after/my-cards.jpg`, `after/my-cards-studio.jpg` | My Cards and Card Studio | Reachable from My Collection |
| `after/wishlist-view.jpg` | Wishlist view | Empty Wishlist state with Capture action |
| `after/fail-*.jpg` | Failing steps | See the table above |

Before frames, from `main` (`before/`): `01-explore-deck.jpg` (the annotated state, with the square menu, banner and dots), `02-square-mode-menu.jpg` (the square menu open), `03-swipe-up-no-tray.jpg` (the upward swipe did not open the tray in this capture), `04-all-shelves.jpg` (blank frame after tapping All shelves; the shelves did not render in this capture).

## Plan gates

| Gate | Status | Evidence |
| --- | --- | --- |
| Exactly three bottom tabs | MET by flow and frame | `navigation-three-tabs` PASS; `nav-01` frame |
| No mode menu, tap or long press | MET by frame; flow failed | `explore-annotated-after` frame. `explore-no-mode-menu` failed on a case-sensitive assertion (see table). |
| Resting Explore: no dots, banners, full-width CTA, top Add, labelled Insights | MET by frame; flow failed later | The absence assertions in `explore-annotated-cleanup` passed. The flow failed at its last assertion. |
| One counter, correct values | Partly | Counter shows `01 / 04`. The swipe assertion failed for the flow reason above. |
| One + and one heart beside the name | MET by flow and frame | `explore-add-to-collection` and `explore-wishlist-toggle` assertions passed |
| Search in one action; result reaches Inspector; Close keeps the query | Partly | Inspector and query steps passed. Filters failed afterwards (see table). |
| My Collection → Wishlist ≤ 1 action; → Shelves ≤ 1 action; My Cards ≤ 2 actions | MET by flow | `wishlist-in-my-collection` reached the Wishlist view; `my-collection-shelves` PASS; `my-cards-studio` PASS |
| Wear Today ≤ 1 action from an owned bottle | MET by flow | `today-preservation` PASS |
| Frosted tray checks, 10 of 10 | NOT RUN | The tray did not open in the flow, so no tray frame exists |
| Every required Maestro flow passes | NOT MET | 7 of 19 fail |
| Real before and after iOS screenshots for every annotation A1 to A12 | Partly | Before: 4 frames, 2 useful. After: the frames above. Not every annotation has its own frame. |
| 34 internal autumn cards preserved | NOT VERIFIED | The CI build shows `/ 04`. The 34-card Autumn set is not in this build. The before frame also shows `/ 04`, so this is not a change from this PR. |

## Not verified

- Physical iPhone: touch, haptics, frame pacing, frosted legibility.
- The upward insights gesture on any device, and the grabber tap path.
- VoiceOver traversal, Dynamic Type, the 375, 390 and 430 pt width matrix, Reduce Motion, Reduce Transparency.
- Photo capture and OCR.
- Upgrade from existing owner data.
- The `63c6b71` launch-alignment fix (not in the run).
