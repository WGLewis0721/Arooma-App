# Arooma V3: verification evidence (2026-11-02)

> Part of the [Arooma design brain](../../design/README.md). Companion to the [V3 implementation record](../../design/specs/2026-11-02-native-navigation-v3.md) and the [plan](../../../AROOMA_NAVIGATION_V3_QUICK_ACTIONS.md).

**Read this first.** V3 was merged (PR #41) before any Maestro flow had run on it. The first Maestro results arrived afterwards and were mixed: **12 of 15 new flows passed and 4 of 14 existing flows passed**. Most failures were flows that no longer matched the V3 screens, plus one real V3 regression (My Collection hid Shelves and Add on an empty collection), all fixed in the follow-up PR. Whether those fixes work is **not yet verified by a Maestro run**: the confirming runs were still executing when that PR was merged. Nothing here claims a pass that did not happen.

Every Maestro result below is the iOS 26 Simulator on a GitHub macOS runner. **None of it is a physical iPhone.**

## Verified

| Item | Result | Evidence |
| --- | --- | --- |
| Gyro Flip detector unit tests | **PASS, 94 checks.** Synthetic traces, not a sensor. | `Native iOS 26 SwiftUI Build` run [41358378384](https://github.com/WGLewis0721/Arooma-App/actions/runs/41358378384) |
| Native Debug and Release-proof builds | **PASS** for the merged V3 build and for the follow-up commits | runs above, and [41363118023](https://github.com/WGLewis0721/Arooma-App/actions/runs/41363118023) |
| Maestro flow syntax, all flows | **PASS** | step "Check flow syntax" of every Maestro run |
| `npm run docs:check`, `npm run test:docs`, `npm test` (221 checks, PWA untouched) | **PASS** | local, before each merge |
| BEFORE screenshots (V2 app) | 8 captured; the Inspector capture failed | [`before/`](before/), run [41357109292](https://github.com/WGLewis0721/Arooma-App/actions/runs/41357109292) |
| AFTER screenshots (first V3 build, before the polish commit) | 8 captured | [`after/`](after/) |

## First Maestro results on the V3 build

Runs [41358788686](https://github.com/WGLewis0721/Arooma-App/actions/runs/41358788686) (new flows) and [41358794490](https://github.com/WGLewis0721/Arooma-App/actions/runs/41358794490) (existing flows), build `b58b92c`. Raw files: [`maestro-first-run/`](maestro-first-run/).

### New V3 flows: 12 of 15 passed

| Flow | Result | What it showed |
| --- | --- | --- |
| `navigation-v3` | PASS | Explore, My Collection, Search in that order; no Today or Cards tab |
| `collection-long-press-actions` | **PASS** | Holding the My Collection tab shows Wishlist, Add and Wear above it, does not navigate, a tap elsewhere dismisses it, a tap on the tab still navigates |
| `collection-long-press-wishlist` | PASS | Wishlist row goes straight to the Wishlist view |
| `collection-long-press-add` | PASS | Add row opens Quick Add; a save returns to My Collection |
| `collection-long-press-wear-disabled` | PASS | With no owned selection Wear is disabled and says why |
| `collection-layout-v3` | PASS | Notes directly beneath the name; actions below; one signature |
| `collection-wear-layer-history` | PASS | Wear, a two-bottle layer, saved combination and history inside My Collection |
| `card-studio-hidden` | PASS | No Card Studio or My Cards |
| `signature-header-loop` | PASS | Signature on all three tabs; see "Signature" below |
| `gyro-flip-settings` | PASS | Switch On by default, persists across a relaunch |
| `gyro-flip-unavailable` | PASS | With no sensor the row explains instead of showing a dead switch |
| `gyro-flip-inspector` | PASS | A synthetic twist reaches `FlipMotor` through the real detector; a shake and a tilt do not; a tap still flips |
| `collection-long-press-wear` | **FAIL at the last step** | Steps 1 to 41 passed: Wear from Explore logged the selected owned bottle with no navigation, a confirmation appeared, a repeat press logged nothing, and Search showed exactly "1 wears · 99% left" for both bottles. The **scoped Undo was not exercised**: the flow's `hideKeyboard` tapped a result, whose Inspector covered the toast |
| `search-tab-v3` | FAIL (flow) | Looked for a "Filters" button, which does not exist while a search is active |
| `gyro-flip-off` | **FAIL, unexplained** | With the switch Off and a synthetic twist, the card was on its reverse. The code says it cannot be (no subscription starts when Off), and `gyro-flip-settings` shows the setting persists. Not understood. A QA marker was added to settle it; see the follow-up |

### Existing flows: 4 of 14 passed

| Flow | Result | Cause |
| --- | --- | --- |
| `appearance-studio-regression`, `style-sections`, `quick-add-context`, `quick-add-undo` | PASS | |
| `my-collection-shelves`, `quick-add-wishlist` | FAIL | **Real V3 regression.** My Collection hid Shelves and the Add handle while the collection was empty |
| `smoke` | FAIL (flow and app) | The Search keyboard covered the tab bar and dragging the results did not dismiss it |
| `explore-no-mode-menu` | FAIL (flow) | "My collection" (the old menu item) also matches the new "My Collection" tab label |
| `quick-add-name-owned` | FAIL (flow) | A relaunch lands on Explore by design; the flow expected My Collection |
| `wishlist-in-my-collection` | FAIL (flow) | After moving the last wish the Wishlist view stays on screen, empty; the flow expected the Owned card |
| `explore-counter-navigation`, `explore-annotated-cleanup` | FAIL | Maestro's default swipe settled two cards on ("03 / 04") instead of one. Gallery code is unchanged, so this is not shown to be a V3 effect |
| `explore-insights-frosted` | FAIL | Swipe up did not open the Insights tray. Gallery code unchanged; cause not established |
| `tuning-presets` | FAIL | Known backlog item F2, unrelated to V3 ([DECISIONS.md](../../design/DECISIONS.md)) |

Several of these flows were written for V2 and were never run against the app before (the [V2 evidence](../2026-11-02-navigation-v2/README.md) is a placeholder), so for them there is no earlier pass to compare with.

## Acceptance (plan section 4)

"Simulator" means the first Maestro run above. Items marked NOT VERIFIED have no run yet.

| Criterion | Result |
| --- | --- |
| (i) Exactly 3 tabs: Explore, My Collection, Search | **PASS, simulator** |
| (ii) 3 long-press actions, no extra screen for Wear | **PASS, simulator** (hold, Wishlist, Add, Wear steps). Hold on a physical iPhone: NOT RUN |
| (iii) 1 session per eligible press, no duplicate | **PASS, simulator** (exact "1 wears" after one wear and a repeat press) |
| (iv) Bottle by id, never a sample or Wishlist card | **PASS, simulator** (Beta logged, Alpha unchanged; disabled-Wear flow). Undo scoped to its own session: **NOT VERIFIED** |
| (v) Earlier collection, Wishlist, wear, layer, history, search and art retained | **PARTIAL.** Wear, layer, history, Quick Add and Undo, styles and appearance passed. The rest of the existing flows failed for the reasons above and await the re-run |
| (vi) No visible Card Studio, no saved card lost | **PASS, simulator** for "not visible". Recovery of created cards: open question, see below |
| (vii) Before and after screenshots; flows reported | **PASS** for the set captured; flow results are in the tables above |
| Signature: compact mark top left on all tabs | **PASS, simulator.** Smoothness, energy cost and Reduce Motion: NOT RUN |
| Gyro Flip: toggle, privacy wording, routing, no flip for shake or tilt | **PASS, simulator** (synthetic). **Off means no flip: FAIL, unexplained.** Real thresholds and feel: NOT RUN, no device |

## Signature

[`after/signature-sheen-frames.jpg`](after/signature-sheen-frames.jpg) and [`after/signature-sheen-analysis.txt`](after/signature-sheen-analysis.txt) analyse nine header frames. The gold highlight is on the lettering in 2 of 9 frames (`t00` and `t03`), at the same place on the end swash, and the Maestro log puts those two screenshots **5.98 s apart**, one full 6 s loop. That is what a looping sweep looks like. It does not show smoothness or that nothing stutters.

## Gyro Flip: what is and is not proven

- **Proven (synthetic):** one flip per valid twist, none for slow tilt, shake, x or z rotation, rebound, dropout, reset, Reduce Motion or a touch, at 30, 60 and 100 Hz, plus 300 deterministic fuzz traces with no false flip. On the simulator, a replayed twist reaches `FlipMotor` through the real detector and a shake or tilt does not.
- **Not proven:** that the thresholds feel right or reject real movement. Needed on a physical iPhone: at least 18 of 20 deliberate twists (10 each way), at most 1 of 100 incidental movements, no double flip, no performance regression. **NOT RUN, no device.**
- **Off:** see `gyro-flip-off` above.
- **Direction:** positive means the phone's right edge turns away. Whether that matches the card on a device is unchecked.
- Initial thresholds are in `GyroFlipConfiguration.initial` (filter 45 ms; start 1.0 rad/s, end 0.5; dominance at least 0.75; peak at least 2.2 rad/s; turn at least 0.55 rad; 0.12 to 0.45 s; user acceleration under 0.8 g; cooldown 1.2 s then 0.30 s below 0.35 rad/s).

## Known limitations

- **The tab-bar hold works on the simulator and is not tested on a physical iPhone.** It is a `UILongPressGestureRecognizer` on the system tab bar. A real thumb, haptics and VoiceOver may differ.
- **Widths.** Only the runner's iPhone 17 Pro (402 pt) was used. 375, 390 and 430 pt, both appearances and all four palettes: NOT RUN.
- **Seen in the AFTER screenshots and fixed afterwards, not re-photographed yet:** hard background bands on My Collection, the Search signature at about half size, the disabled Wear reason cut off.
- **Not observed:** Reduce Motion, Reduce Transparency, Increase Contrast, haptics, VoiceOver, background pause and resume, energy cost.
- **Share sheet.** SwiftUI cannot observe the system share sheet, so motion flips are not suppressed while it is open.
- **Card Studio audit.** Created cards, their share, export and restore, have no screen now. Records are intact. See the spec and `DECISIONS.md`.

## Follow-up

The fix PR changes the app (Shelves and the Add handle on an empty collection, search keyboard dismissal, a QA marker for the motion subscription, the three polish items) and the flows above. Its confirming Maestro runs were [41362987517](https://github.com/WGLewis0721/Arooma-App/actions/runs/41362987517) (existing flows) and [41363883218](https://github.com/WGLewis0721/Arooma-App/actions/runs/41363883218) (new flows). Their results go in the next update of this file, with fresh AFTER screenshots of the polished screens.

## Files

- [`before/`](before/): eight V2 screenshots, 600 px wide, and [`maestro-before/junit.xml`](maestro-before/junit.xml).
- [`after/`](after/): eight screenshots of the first V3 build, the signature frames and their analysis.
- [`maestro-first-run/`](maestro-first-run/): JUnit for the two first runs.
