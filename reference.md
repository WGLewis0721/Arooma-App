# Arooma Wrist-Flick Reference
> Research brief for the native iOS card-flip recognizer. Compiled from the owner-supplied Perplexity research, checked against the cited public app/developer references, and the current Arooma source. **Historical facts and proposed engineering are explicitly separated.**
>
> **Intent:** one natural, deliberate wrist *flick* turns the currently open collectible card front↔back **exactly once**, in either direction. Ordinary tilting continues to move the holographic foil continuously. The Wrist Flip toggle fully disables the discrete gesture without disabling the foil.

## 1. Reference apps: what is actually known

| Reference | Documented interaction / implementation | Lesson for Arooma | Evidence boundary |
| --- | --- | --- | --- |
| **PhoneSaber / Lightsaber Unleashed (2008)** | A swing of the iPhone caused lightsaber sound effects. Contemporary coverage identifies the **accelerometer**. [1] | Fast motion can be an immediate discrete command, without a prescribed ending pose. | Proprietary sampling, filters and swing thresholds **not public**. |
| **Pocket Whip (2009)** | Contemporary launch announcement describes accelerometer analysis: ongoing side-to-side/vertical/circular movement made **whooshes**; a **wrist flick** caused a whip **crack**. [2] | Distinguish low-intensity ongoing movement from a short, sharp action pulse. | The actual whoosh-vs-crack classification mathematics **not disclosed**. Do not claim a recovered algorithm. |
| **iBeer (2008)** | Creator Steve Sheraton described looped beer/foam video and image sequences kept aligned with an accelerometer-derived **horizon**; crossing tilt angles selected other sequences with conditional logic. [3] | Continuous orientation effect and discrete threshold transitions can share sensors, while their own state logic stays separate. | Not evidence of fluid simulation or a gyroscope flick classifier. |
| **Smule Ocarina (2008)** | Ge Wang's paper maps **two-axis accelerometer tilt** to vibrato depth/rate; breath and touch control other aspects of synthesis and graphics. [4] | Smoothly map orientation into continuously updated output without turning every movement into a gesture. | It did **not** recognize individual “vibrato gestures.” |
| **d108/Core-Motion-Gesture** | Open-source SwiftUI/Combine accelerometer detector samples at **100 Hz**, stores bounded history, and recognizes **two Z-axis peaks within a time window** for a **double wrist flick**, then haptics. [5] | Borrow time-window classification, bounded buffering, state isolation, and haptic confirmation. | Arooma requires **one** flick. Do **not** copy the double-peak/double-flick input contract or claim its numeric parameters transfer. |
| **seedds/nxnative DmGamepad.m** | Independent Objective-C accelerometer example requests **60 Hz**, estimates gravity using a small low-pass step, detects high-pass magnitude above a default **1.5 g**, extends a shake state until roughly **120 ms** after the last crossing and records the peak. [6] | Separate slow gravity from fast acceleration and group close peaks into one event. | Its threshold detects a generic *shake*, not a reliable once-only card flip. |
| **uWave (2008–09 research)** | Uses filtered/quantized acceleration sequences and **dynamic time warping (DTW)** against templates, with user-confirmed adaptation; reported high personalized accuracy. [7] | Individual grip, day-to-day variation, and data-driven calibration matter. | Study relied on explicitly segmented gestures (a Wii Remote button); its reported accuracy is **not** Arooma's expected continuous-detection accuracy. |

**Key historical boundary:** PhoneSaber, iBeer, Pocket Whip and Ocarina predate the iPhone 4 gyroscope. Their accelerometer interactions are relevant precedents, **not** proof of specific proprietary thresholds, sensor-fusion algorithms, or modern Swift APIs.

## 2. Apple Core Motion: what each signal should do

Modern `CMDeviceMotion` exposes `rotationRate` (rad/s), `userAcceleration` (gravity removed, g), `gravity`, `attitude`, and timestamps. [8]

| Signal | Intended use |
| --- | --- |
| `gravity` + `attitude` | Slow, **continuous** foil lighting and subtle lean; independently smoothed and never reset as a side effect of flick classification |
| `rotationRate` | Fast signed rotational pulse, candidate onset/peak/fall, direction, and angular travel as *evidence* |
| `userAcceleration` | Support for sharp wrist motion or braking; strong translation/shakes may count as **negative evidence**, not a rigid veto on all flicks |
| Accurate `timestamp` | Compute measured `dt`, filter coefficients, peak timing and cooldown; don't assume a fixed sample interval |

**Architecture:** one shared `MotionField` / `CMMotionManager`, two consumers. Foil = continuously interpolated material input. Gesture = pure, discrete recognizer event wired to the **existing** `FlipMotor.flip(direction:)`. No new motion manager, duplicated rendering engine, or feed reset from a flip. Sensor processing and UI updates should remain bounded and smooth.

## 3. Arooma's actual starting point: do not regress PR #43

As of the owner research handoff, main includes **PR #43** (motion diagnostics, initial wrist-flip consistency changes, Off-switch fix, and Low Power explanation). **Fetch latest main** before making decisions; do not overwrite these improvements with the older strict detector or with the earlier experimental `fix/motion-feed-independent-v3` branch.

- `ios/AroomaNative/MaterialLight.swift` — existing **single** Core Motion feed drives holographic foil and forwards raw rate/acceleration when a subscriber exists. **Low Power Mode intentionally pauses the feed and the foil.** The owner confirmed foil resumes normally when Low Power Mode is disabled.
- `ios/AroomaNative/GyroFlipDetector.swift` — pure classifier + recent gesture log; current shipped logic accepts rotation in a `y/z` plane and a higher acceleration allowance, **but still requires high peak rate, ~32° signed angular excursion, axis share and a short time window**. A natural snap/return may fail even when visibly deliberate.
- `ios/AroomaNative/GyroFlip.swift` — controller and owner diagnostic snapshot, tuning parameters, Off state, suppression. Keep a single accepted event per gesture and manual flip alternatives.
- `ios/AroomaNative/AtelierGallery.swift` — Inspector owns the existing `FlipMotor`; interactive swipe/tap flip must remain available. Don't change deck navigation.
- `ios/AroomaNative/Tuning.swift` — **existing owner tuning controls**, including wrist-flip parameters. Extend, don't introduce a competing setting.
- `ios/Tests/GyroFlip/` and `.maestro/` — preserve tests and add more.

**Important observed failure:** Wrist Flip does work **intermittently** on the owner's real iPhone with Low Power Mode Off. This is a **recognition-quality and calibration** problem, not evidence that the entire Core Motion/foil/rendering pipeline is broken. PR #43's changed thresholds are **engineering hypotheses**, not verified real-device measurements.

## 4. Proposed recognizer (engineering hypothesis, NOT documented historical code)

Use a **single-pulse** recognizer with `settling → armed → candidate → accepted/rejected → settling` states. Detect a brief intentional burst and its **peak/fall envelope**, not a prescribed 32° finishing pose.

1. **Sample** from the existing shared device-motion stream (start by testing 60–100 Hz as hardware allows; always use real `dt`). Keep a bounded 100–200 ms pre-trigger ring buffer. Reject stale, missing, reversed or nonfinite timestamps and reset appropriately.
2. **Filter** angular-rate and acceleration with an `alpha = 1 - exp(-dt/tau)` time-aware filter, preserving low-latency peaks; keep lighting smoothing **separate**.
3. **Arm** only after a short calm interval. On a high-threshold crossing, begin a candidate, including pre-trigger samples so the rising edge is not discarded.
4. **Extract features:** peak vector and magnitude `W=||ω||`, acceleration peak `A=||a_user||`, duration, rising/falling edges, signed peak direction, peak decay, angular path `∫||ω||dt`, and optional Y/Z-plane alignment. Beware that **signed integral can cancel** during snap-and-return. Axis share and total angular displacement are features to compare, **not obligatory hard rejects**.
5. **Accept one flick** when the peak falls sufficiently after a brief pulse and a combination of rotational and (optional) acceleration evidence is met. A translation or rapid reposition alone must be rejected. Start with explicit, bounded fixed thresholds; do **not** blindly transplant Perplexity's example constants.
6. **Re-arm** only after both a refractory interval *and* sustained quiet. A return stroke is part of the same gesture. Make negative and positive direction semantics symmetric; map direction to `FlipMotor` only after classification.
7. **Suppress** acceptance while direct touch/drag, Inspector not visible, overlay open, prior flip still animating, Reduce Motion enabled, app not active, gyro Off, or Core Motion unavailable/paused. A tap/swipe flip remains available always.
8. **Instrument before tuning:** extend PR #43's real-device diagnostic log to show raw timestamps, rate/acceleration/gravity, recognizer state, candidate peak/travel/duration, accept/reject reason, current thresholds and suppression gate. Bound storage, keep local and explicitly owner-only; no data upload or analytics.
9. **A/B** existing PR #43 classifier against new pulse candidate on the *same physical recordings*. Include fast reposition, walking, shaking, normal foil tilt, finger interaction, initial neutral tilt, both wrist directions, immediate return stroke, different grip positions. Tune one variable group at a time. Use replayable pure Swift tests.
10. Keep the installed build's **working foil** untouched; if changing sensor service is unavoidable, prove motion-to-light mapping is unchanged. Preserve Low Power behavior and explain it in Settings.

**Do not jump to DTW or ML.** A transparent classifier with measured real-device traces is the right first iteration. If held-out results fail, compare dynamic-time-warping alternatives as a second-stage experiment.

## 5. Measurable engineering acceptance

**Verification must occur on a physical iPhone with Low Power Mode OFF**; Simulator synthetic replay is useful but insufficient.

| Criterion | Pass threshold |
| --- | --- |
| **Intentional recognition** | At least **38/40** natural deliberate flicks in **each direction**, counting missed flicks as failures. Record starting posture, grip and time. |
| **Exactly once** | **0 double flips** across all 80 deliberate flick trials; rebound/return never triggers a second event. |
| **Accidental flips** | At most **1/100** non-command movement trials including slow foil tilts, shaking, tapping, walking, picking up and repositioning. Include at least **15 minutes** of ordinary card browsing with zero unintended flips. |
| **Responsive feel** | Measured **p95 ≤ 250 ms** from detected peak to issuing flip command, across recognized trials; report full distribution. |
| **Foil regression** | With Low Power Off, 20 deliberate slow tilts still move the existing holographic light continuously without snap/reset/jump; **0** lighting discontinuities caused by accepted/rejected flicks. |
| **Settings and safety** | Gyro Flip Off produces **0** motion-induced flips, **0** active flip subscription; tap/drag still work. Reduce Motion suppresses automatic flip. Low Power Mode visibly explains paused motion. |
| **Automated gates** | Native Debug/Release CI green, deterministic Swift replay tests green (positives, negatives, timing jitter, dropouts, suppression, opposite direction, return, power toggles), and affected Maestro flows green. Report actual run links. |
| **Evidence** | Device model/iOS, real trial counts, threshold values, outcome/rejection logs, brief video, raw local test export when consented, baseline-vs-candidate comparison. Say **NOT RUN** for any unavailable physical test. |

If the new algorithm does not beat the PR #43 baseline **on the same traces** or produces a false-positive regression, do not ship it solely because synthetic tests pass.

## 6. Research/source links

1. [PhoneSaber contemporary Macworld coverage (2008)](https://www.macworld.com/article/191906/phonesaber.html)
2. [Pocket Whip contemporary release notice (2009)](https://www.iclarified.com/4600/app-city-releases-pocket-whip-101)
3. [iBeer creator interview](https://melmagazine.com/en-us/story/ibeer-app-history)
4. [Ge Wang, Designing Smule's Ocarina (NIME 2009)](https://nime.org/proc/nime2009_wang_a/)
5. [d108/Core-Motion-Gesture (code & developer notes)](https://github.com/d108/Core-Motion-Gesture)
6. [seedds/nxnative Objective-C shake code](https://github.com/seedds/nxnative/blob/main/dm/ios/Sources/DmGamepad.m)
7. [uWave accelerometer-based recognition project](https://www.yecl.org/project_uwave.html) and [research paper](https://www.yecl.org/publications/liu08uwave.pdf)
8. [Apple: CMDeviceMotion](https://developer.apple.com/documentation/coremotion/cmdevicemotion) and [rotationRate](https://developer.apple.com/documentation/coremotion/cmdevicemotion/rotationrate)

**Evidence handling:** these sources support the documented behavior in section 1. Section 4 and the exact pass thresholds in section 5 are **proposed Arooma engineering**, not historical implementations, and require measured validation.
