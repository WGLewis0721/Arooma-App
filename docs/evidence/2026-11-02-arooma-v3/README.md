# Arooma V3: verification evidence (2026-11-02)

> Part of the [Arooma design brain](../../design/README.md). Companion to the [V3 implementation record](../../design/specs/2026-11-02-native-navigation-v3.md) and the [plan](../../../AROOMA_NAVIGATION_V3_QUICK_ACTIONS.md).

**Read this first.** V3 was merged at the owner's request *before any Maestro flow had run on the V3 build*. What is verified is that the app **compiles**, the Gyro Flip detector's **unit tests pass**, and every flow **passes Maestro's syntax check**. What is **not** verified is how the app behaves on a simulator or a phone: the tab-bar press-and-hold, the Wear action, the layout and the signature header have never been seen running. Every row below that depends on that says NOT RUN. Nothing is claimed that did not run.

## What was verified

| Item | Result | Evidence |
| --- | --- | --- |
| BEFORE screenshots on the V2 app | 8 captured (the Inspector capture failed: the Explore deck has no Inspect button) | [`before/`](before/), run [41357109292](https://github.com/WGLewis0721/Arooma-App/actions/runs/41357109292), artifact 13104391734, [`maestro-before/junit.xml`](maestro-before/junit.xml) |
| Gyro Flip detector unit tests | **PASS: 94 checks, 0 failed.** Synthetic traces on a macOS Swift toolchain. This is classifier logic, not a sensor. | `Native iOS 26 SwiftUI Build` run [41358378384](https://github.com/WGLewis0721/Arooma-App/actions/runs/41358378384), step "Gyro Flip detector unit tests" |
| Native Debug build and Release-proof build | **PASS** at `78b8343` | same run |
| Native Debug build with the identity identifiers | **PASS** at `b58b92c` (the "Build Debug simulator app" step of both Maestro runs below) | runs [41358788686](https://github.com/WGLewis0721/Arooma-App/actions/runs/41358788686) and [41358794490](https://github.com/WGLewis0721/Arooma-App/actions/runs/41358794490) |
| Maestro flow syntax, all 38 flows | **PASS** (the new selector forms `rightOf`, nested `below`, `checked`, `(?-i)`, `pressKey: home` and `launchApp stopApp: false` are valid) | step "Check flow syntax" of both runs |
| `npm run docs:check`, `npm run test:docs` | **PASS** | run locally before merge |
| `npm test` | Running when this was committed (120 passed, 0 failed so far); the final result is recorded in the PR description | run locally before merge |

## Maestro: NOT RUN at merge time

Two runs were dispatched on `b58b92c` and were still booting their simulators (build passed, flows had not started) when the owner asked to merge without waiting. They are left running; if they finish, their `junit.xml`, screenshots and the signature-sheen analysis should be added in a follow-up.

| Run | Selects |
| --- | --- |
| [41358788686](https://github.com/WGLewis0721/Arooma-App/actions/runs/41358788686) | `include_tags: v3`, the 14 new flows below |
| [41358794490](https://github.com/WGLewis0721/Arooma-App/actions/runs/41358794490) | `exclude_tags: v3,capture-before`, the updated and unchanged existing flows |

| New flow | What it would verify | Result |
| --- | --- | --- |
| `navigation-v3` | Exactly Explore, My Collection, Search in that order; no Today or Cards tab; no Search icon on Explore | NOT RUN |
| `collection-long-press-actions` | Hold shows exactly Wishlist, Add, Wear above the tab, does not navigate, tap elsewhere dismisses, a tap still navigates | NOT RUN |
| `collection-long-press-wishlist` | Wishlist row goes straight to the Wishlist view; Owned is one tap back | NOT RUN |
| `collection-long-press-add` | Add row opens Quick Add; a direct save returns to My Collection; no Card Studio | NOT RUN |
| `collection-long-press-wear` | One session, one decrement, no duplicate on a repeat press, Undo only that session, no navigation, Explore left on a sample card; counts read from Search | NOT RUN |
| `collection-long-press-wear-disabled` | Wear disabled with "Select a bottle in My Collection"; a Wishlist or sample focus is never logged | NOT RUN |
| `collection-layout-v3` | Notes directly beneath the name; actions below; no banner; no My Cards; one signature | NOT RUN |
| `collection-wear-layer-history` | Solo wear, two-bottle layer, saved combination, history and undo inside My Collection | NOT RUN |
| `search-tab-v3` | Search tab keeps query and filters across Inspector and back | NOT RUN |
| `card-studio-hidden` | No Card Studio or My Cards anywhere | NOT RUN |
| `signature-header-loop` | Header on all three tabs; "EXPLORE" label gone; eight timed frames; background then foreground | NOT RUN |
| `gyro-flip-settings` | Switch is On by default and persists across a relaunch | NOT RUN |
| `gyro-flip-unavailable` | With no sensor the row explains instead of showing a dead switch | NOT RUN |
| `gyro-flip-inspector` | A synthetic twist reaches `FlipMotor` through the real detector; a shake and a tilt do not; tap still flips | NOT RUN |
| `gyro-flip-off` | With the switch Off, no flip; tap still flips | NOT RUN |

Retired with the UI they covered: `navigation-three-tabs`, `today-preservation`, `return-to-today`, `my-cards-studio`, `explore-search-inspector`. Updated: `smoke`, `explore-annotated-cleanup`, `quick-add-context`.

## Acceptance (plan section 4, quantified definition of done)

| Criterion | Implemented in code | Verified by running |
| --- | --- | --- |
| (i) Exactly 3 tabs: Explore, My Collection, Search | Yes (`AtelierTab`, three `Tab`s) | NOT RUN |
| (ii) 3 long-press actions, 0 extra screens for Wear | Yes | NOT RUN. The hold itself has never been exercised. |
| (iii) 1 session per eligible press, 0 duplicates | Yes (availability re-resolved at the tap; already-worn shows "Worn today") | NOT RUN |
| (iv) Bottle by id, Undo scoped by session id, never a sample or Wishlist card | Yes (`selectedMineID` validated against `bottles`; `deleteWearSession`) | NOT RUN |
| (v) All earlier collection, Wishlist, wear, layer, history, search and art retained | Yes by construction (`AtelierWearLog`, `AtelierSearch`, the deck and records are reused unchanged) | NOT RUN |
| (vi) No visible Card Studio, no saved card lost | Yes (entry points removed; `CardCommerce` and its data untouched) | NOT RUN |
| (vii) Before and after screenshots, flows reported PASS/FAIL/NOT RUN | Before: 8 captured. After: none. Flows: all NOT RUN. | PARTIAL |
| Signature: one compact mark top left, no menu, 6 s loop, paused when inactive, static on Reduce Motion | Yes | NOT RUN. Smoothness, energy and Reduce Motion are untestable by Maestro. |
| Gyro Flip: pure detector, one `CMMotionManager`, toggle, privacy wording, suppression rules | Yes | Detector logic PASS (94 checks). Everything with a sensor or a screen: NOT RUN. |

## Gyro Flip: what is and is not proven

- **Proven:** exactly one flip event for each valid synthetic twist, none for slow tilt, shake, x or z rotation, a rebound, a dropout, a reset, the switch Off, Reduce Motion or a touch, at 30, 60 and 100 Hz, plus 300 deterministic fuzz traces with 0 false flips. These are made-up traces.
- **Not proven:** that the thresholds feel right or reject real incidental movement. Required on a physical iPhone, none done: at least 18 of 20 deliberate twists (10 each direction), at most 1 of 100 incidental movements, no double flip, no performance regression, and the six-second signature loop coexisting with live foil and the flip. **NOT RUN, no device.**
- **Raw initial thresholds** (hypotheses from the plan, in `GyroFlipConfiguration.initial`): filter 45 ms; start 1.0 rad/s, end 0.5; dominance at least 0.75; peak at least 2.2 rad/s (about 126 degrees/s); turn at least 0.55 rad (about 32 degrees) counted from the start of the candidate, which in practice needs about 0.65 to 0.7 rad of total turn; duration 0.12 to 0.45 s; user acceleration under 0.8 g; cooldown 1.2 s then 0.30 s below 0.35 rad/s; recalm 0.15 s.
- **Direction** follows the sign of the integrated twist (positive means the phone's right edge turns away). Whether that matches the card's turn on a device is unchecked.

## Known limitations and risks

- **The tab-bar hold is the main risk.** It is a `UILongPressGestureRecognizer` added to the system `UITabBar`, finding the My Collection item by accessibility label with equal thirds as a fallback. It was written without ever seeing a simulator. It may fail to fire, fire on the wrong item, or select the tab as a side effect (the root view reverts that, also unverified). The same column is reachable from VoiceOver ("Collection quick actions") and, in QA builds, with `-AroomaQATab quickactions`, and one-tap Wear today remains on the card. If the hold does not work on a device or simulator, document the platform blocker and get owner review before substituting another gesture, as the plan requires.
- **Widths.** Only the runner's iPhone 17 Pro (402 pt) is available; 375, 390 and 430 pt, both appearances and all four palettes are NOT RUN.
- **Search header.** The signature is a toolbar item with the shared glass background hidden (`sharedBackgroundVisibility`). It compiles; how it looks is unseen.
- **Reduce Motion, Reduce Transparency, Increase Contrast, background pause and resume, energy cost:** coded, not observed.
- **Share sheet.** SwiftUI cannot observe the system share sheet, so motion flips are not suppressed while it is open.
- **Card Studio audit.** Created cards, their share, export and restore, have no screen now. Records are intact. See the spec's audit and the open decision in `DECISIONS.md`.
- **Before set.** No Inspector screenshot of V2. After screenshots: none.

## Files

- [`before/`](before/): the eight V2 screenshots, 600 px wide.
- [`maestro-before/junit.xml`](maestro-before/junit.xml): the before capture run.
