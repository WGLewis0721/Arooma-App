# Spec: wrist-flick pulse recognizer

> Part of the [Arooma design brain](../README.md). Follows the [V3 navigation amendment](../../../AROOMA_NAVIGATION_V3_QUICK_ACTIONS.md) (section 1B, Gyro Flip) and the [research distillation](../../../reference.md). Evidence: [2026-11-02 wrist-flick evidence](../../evidence/2026-11-02-wrist-flick-pulse/README.md).

Summary: one natural wrist flick should turn the open collectible once, in either direction, while the holographic light keeps following the phone. This spec replaces the instantaneous threshold classifier with a single-pulse recognizer, fixes two measured defects in it, and adds an owner-only way to record real motion for replay. Everything was verified on synthetic traces and on the CI runner. **No physical iPhone was used. Every physical target below is NOT RUN.**

| | |
| --- | --- |
| Branch | `feat/wrist-flick-pulse`, from `origin/main` at `19daf69` |
| Baseline | PR #43 (`03a1f4e`): `GyroFlipDetector.swift`, kept unchanged for replay |
| Live detector | `GyroPulseDetector.swift` (new), used by `GyroFlipController` |
| Shared motion | Unchanged. The single `CMMotionManager` in `MaterialLight.swift` still feeds foil and detector. |
| Status | Implemented; synthetic verification passing; physical verification NOT RUN |

## What was measured on the baseline

Replayed on identical synthetic traces (development seeds unless marked):

1. **Direction was inverted for some grips.** The PR #43 classifier takes the direction from a canonical axis in the device's y-z plane, flipping the axis so its larger component is positive. For a twist whose axis tilts to one side of the long axis, that flips the sign. On development seeds PR #43 reported the wrong face in **17 of 400** flicks; on held-out seeds, **22 of 400**. The pulse recognizer reports **0** in both. A single trace shows it directly: a negative flick is reported as `+` by PR #43 and `-` by the pulse recognizer.
2. **The smoothing filter shrank short peaks.** PR #43 smooths the rate with a 45 ms time constant. A 0.12 s flick keeps only **65%** of its true peak after that filter (2.2 rad/s reads as about 1.4); a 0.20 s flick keeps 79%. The pulse recognizer uses 20 ms: 86% and 93%.
3. **Most misses were the two plan thresholds.** Of the flicks PR #43 missed on development seeds, its last logged rejection was "too small" (turn below 0.55 rad, about 32°) in 167 cases and "too weak" (peak below 2.2 rad/s) in 59. The pulse recognizer's counts are similar (157 and 70). Both are owner-tunable, and both are the calibration lever.
4. **PR #43 decided in the middle of a flick.** It flips the moment its turn reaches the threshold. That is fast (p95 165 ms here) but it also meant a return stroke could reject a flick that was still deciding.

## The pulse recognizer

Four stages, one deterministic function of the sample stream. There are no thresholds beyond those listed below, and no learned or adaptive parts.

1. **Pulse.** A quick twist about the long axis or the screen normal: the twist-plane rate rises above `startRate` (1.0 rad/s) while at least `minDominance` (75%) of the rotation is in that plane. The pulse ends when the rate falls below `endRate` (0.5 rad/s), or reverses while still above it. A reversal inside one pulse is an oscillation, which is how a shake is caught at 60 Hz. A return stroke after a real flick starts only after the pulse has ended, so it is never seen here.
2. **Intent.** The pulse counts only if it is fast enough (peak at least `peakRate`, 2.2 rad/s), large enough (turn, the integral of |rate| over the pulse, at least `minTurn`, 0.30 rad), not sustained (no longer than `maxDuration`, 0.45 s), and not shake-like (user acceleration below `maxUserAcceleration`, 1.5 g, and no reversal of half the peak during a `confirmWindow` of 30 ms). A quick small wiggle fails on turn; a pitch or a roll fails on the axis share; a set-down knock fails on turn and on the acceleration check.
3. **Flip once.** The direction is the sense of rotation about the device axis that dominates the peak. It does not depend on a canonical projection, so the grip cannot invert it. After a flip the detector enters `cooldown` (1.2 s). A return stroke during cooldown is logged as "ignored" and never flips.
4. **Reset.** The detector re-arms only after the cooldown and after `rearmCalm` (0.3 s) of calm. A rejected pulse needs `calmTime` (0.15 s) of calm before it can arm again. Suppression (touch, sheet, animation, Reduce Motion, inactive scene, Off) cancels a pulse in progress.

What changed from PR #43, and why:

- The **filter** is 20 ms instead of 45 ms (measured above). This is the only change in the measurement path.
- The **direction** comes from the dominant device axis at the peak, not from a canonical projection (measured above).
- The **decision** is made once, at the end of the pulse, not in the middle of it. This costs latency (about 175 ms median from peak on synthetic traces) and removed PR #43's "reversed" rejection, which rejected a flick whose return stroke began before it had finished.
- The **duration floor** (0.12 s) and the **end-of-pulse dominance check** were removed. An ablation showed neither changed recognition or accidental flips on the corpus. The start-of-pulse dominance check stays: it is what rejects pitches.
- The **turn default** moved from 0.55 rad (the plan's value) to 0.30 rad. The ablation put the turn requirement at the centre of the misses. The turn sweep below shows where small quick wiggles start to flip and where recognition falls away. 0.30 rad is the lowest turn that kept ordinary movement at or below 1 accidental flip per 100 on the development seeds (0.56 per 100), and it recognizes 97 to 98% of synthetic flicks. The earlier 0.35 rad default recognized 86 to 88% with zero accidental flips in the same runs.

Owner tuning (View & Style, Wrist flip) keeps its labels and ranges. "Turn needed" is `minTurn`; "Peak rate needed" is `peakRate`; "Start rate", "Axis share needed", "Longest twist", "Shake limit" and "Pause after a flip" map as before.

**Wrist-twist feels.** A separate "Wrist twist" section in the tuning panel offers three starting points that change only the wrist twist, not the holographic feel: Standard (0.30 rad, the default), Sensitive (0.25 rad: flips on gentler twists, more accidental flips, 3.4 per 100 ordinary movements on the synthetic corpus) and Firm (0.40 rad: fewer accidental flips, more missed twists). Choosing a feel clears the individual wrist-twist edits and keeps the holographic ones. The synthetic numbers for each feel come from the same gyro-tests run that CI reports.

## Synthetic measurements

Method. `ios/Tests/GyroFlip/Corpus.swift` generates deterministic traces: 60 Hz nominal with ±15% jitter, 3% dropped samples, gyroscope noise, a small lift wobble, and natural flicks with an optional return stroke. The natural-flick prior is stated, not fitted: total angle 0.35 to 1.2 rad, peak 2 to 5 rad/s, duration from the minimum-jerk shape. Nine ordinary families: slow tilt, quick tilt to the face (a pitch with leakage into the twist plane), hand tremor, walking sway, hand shake (3 to 6 Hz, up to 2.4 g), pick-up or reposition, quick small wiggle (10 to 20 degrees, fast), pitch with a strong twist leak, and a set-down knock. Development seeds (1…) chose the default. Held-out seeds (9000…) are reported only. Reproduce with `gyro-tests`.

| Measure | PR #43, development | Pulse, development | PR #43, held-out | Pulse, held-out |
| --- | --- | --- | --- | --- |
| Flicks recognized, + and − | 35% and 38% | 96% and 97% | 44% and 31% | 98% and 98% |
| Wrong face | 17 | **0** | 22 | **0** |
| Double flips | 0 | 0 | 0 | 0 |
| Latency from peak, p50 and p95 | 94 and 165 ms | 170 and 218 ms | 104 and 172 ms | 173 and 214 ms |
| Accidental flips per 900 ordinary trials (nine families) | 1 | 5 | 0 | 3 |

These pulse numbers are the 0.30 rad default, from CI run 41373863825 (head `7a7668d`). The 0.35 rad numbers that this table used before (88% and 85%, zero accidental flips) are in the turn sweep below.

Flick recognition by size and duration, pulse, both seed ranges: flicks of 0.5 rad and larger were recognized in every cell (100%). Flicks of 0.35 to 0.5 rad were recognized 52 to 75% of the time. Under 0.35 rad, flicks are below the turn requirement by design.

Turn sweep (pulse, peak 2.2 rad/s; ordinary per 100 means per 100 ordinary trials across all nine families):

| Minimum turn (rad) | Recognized, dev | Recognized, held-out | Wrong face (dev / held-out) | Accidental per 100, dev | Accidental per 100, held-out |
| --- | --- | --- | --- | --- | --- |
| 0.25 | 98% | 98% | 0 / 0 | 3.44 | 3.44 |
| **0.30 (default)** | **97%** | **98%** | **0 / 0** | **0.56** | **0.33** |
| 0.35 | 86% | 88% | 0 / 0 | 0.00 | 0.00 |
| 0.40 | 76% | 75% | 0 / 0 | 0.00 | 0.00 |
| 0.45 | 67% | 63% | 0 / 0 | 0.00 | 0.00 |
| 0.50 | 53% | 57% | 0 / 0 | 0.00 | 0.00 |
| 0.55 (plan) | 43% | 46% | 0 / 0 | 0.00 | 0.00 |

What these numbers do not show: real wrist motion. The natural-flick prior, the wiggle and tilt models, and the sample jitter are assumptions. The owner's recordings are the only evidence that can change the default. Every synthetic result here is labelled as such.

## Physical acceptance targets (NOT RUN)

Every target below requires a physical iPhone with Low Power Mode off, and none has been run.

| Target | Threshold | Status |
| --- | --- | --- |
| Deliberate recognition, each direction | At least 38 of 40 | NOT RUN |
| Double flips across 80 deliberate trials | 0 | NOT RUN |
| Accidental flips across 100 ordinary movement trials, plus 15 minutes of browsing | At most 1 in 100; 0 while browsing | NOT RUN |
| Flip latency from the recognized peak, p95 | At most 250 ms | NOT RUN (synthetic p95 221 ms) |
| Holographic light, 20 slow tilts | Continuous, no snap or jump | NOT RUN |
| Off: zero motion flips; tap and drag still work | Yes | Code path covered by tests; NOT RUN on device |
| Reduce Motion suppresses motion flips | Yes | Code path covered by tests; NOT RUN on device |

## Owner calibration procedure

The calibration uses one owner-tools build (Debug or internal TestFlight), a phone with Low Power Mode off, held the way you normally hold it. Each recording is one session with a label and a count. Labels: **Flick +**, **Flick −** and **Ordinary**. Set the count to the number of actions you perform (flicks, or ordinary movements).

1. In View & Style, keep **Flip cards with wrist twist** on. Turn on **Record a motion trace for the next open card**. Set the session label and count.
2. Open a card in the Inspector and perform the session. Close the Inspector. A trace file is written on the iPhone. In View & Style, **Share last motion trace** sends it to your Mac (AirDrop or Files). The file is not otherwise visible outside the app.
3. Record these sessions: 20 flicks to the right (Flick +), 20 flicks to the left (Flick −), varying grip and posture a little, about one second apart. Then Ordinary sessions of 100 actions each: browsing with taps and drags, lifting and placing, walking, slow and quick tilts, quick small wrist wiggles, setting the phone down, a shake. Use at least one 15-minute browsing session as an Ordinary session.
4. Copy the trace files into one folder on your Mac. Run `swiftc -O ios/AroomaNative/GyroFlipDetector.swift ios/AroomaNative/GyroPulseDetector.swift ios/AroomaNative/GyroTrace.swift ios/Tests/GyroFlip/Corpus.swift ios/Tests/GyroFlip/Report.swift ios/Tests/GyroFlip/main.swift -o gyro-tests`, then `./gyro-tests --calibrate <folder>`. It prints recognition, wrong faces and accidental flips for each pair of **Turn needed** and **Peak rate needed**, and the setting that meets the target: at least 95% of flicks recognized with the right face, no wrong faces, and at most 1 accidental flip per 100 ordinary actions. Ties go to the stricter thresholds.
5. Set those two values in the Tuning panel (Wrist flip), then repeat step 3 once to confirm. `./gyro-tests --replay <file>` shows any one trace through both recognizers beside the flips the app produced.
6. Record the values, the counts and the trace file names in the evidence folder. A physical target above moves from NOT RUN only when its count is in that folder.

## Privacy

Motion readings are still processed on this iPhone and used only for the foil and, if on, card flips. Owner-tools recording writes the raw readings for one session to a file in the app's own storage, only after the owner switches it on, and only in an owner-tools build. The file leaves the phone only when the owner chooses Share. Nothing is uploaded automatically. The user-facing copy in View & Style is unchanged for normal builds.

## Limitations

- No physical measurement exists. Every physical target is NOT RUN. The synthetic results are a regression harness and a comparison, not accuracy on a phone.
- The default turn (0.30 rad) is a synthetic choice, not a measured value. The calibration sets it. Gentler twists than about 0.30 rad are missed at the default. The Sensitive feel accepts them at the cost of more accidental flips.
- Users cannot see when the twist is armed, so a twist will not always trigger when they expect it. Tap and drag remain the reliable way to flip. No in-app cue exists yet.
- Latency is higher than PR #43's (p95 about 220 ms against 165 ms), because the decision waits for the end of the pulse. It is inside the 250 ms target on synthetic traces.
- The synthetic corpus cannot reproduce the sensor's real sample timing, its noise, or the way a phone sits in a hand. The calibration sessions are the only test of those.
- A twist that is mostly about the screen normal flips only when it dominates; its direction follows the screen-normal sense.
