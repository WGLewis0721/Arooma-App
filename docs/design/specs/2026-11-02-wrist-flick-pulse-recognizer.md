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

State machine: `settling → armed → candidate → (confirming) → cooldown → armed`, with rejection returning to `settling`.

- **Settling and arming.** The phone must be calm (twist rate below 0.35 rad/s) for 0.15 s before anything can arm. A fresh or reset detector cannot flip from the tail of an earlier motion.
- **Excursion.** It starts when the twist-plane rate rises above 1.0 rad/s with at least 75% of the rotation in the twist plane. It ends when the rate falls below 0.5 rad/s, or when it reverses while still above that level (an oscillation, which is how a shake is caught at 60 Hz).
- **Features, measured once at the end.** Peak rate; turn, the integral of |rate| over the excursion (sign-free, so a snap cannot cancel itself); duration from start to end; share of rotation in the twist direction at the peak; strongest user acceleration.
- **Decision.** Reject unless peak ≥ 2.2 rad/s, turn ≥ 0.55 rad, duration ≥ 0.12 s and share at the peak ≥ 0.75. Reject at once if user acceleration reaches 1.5 g (shake or translation).
- **Confirmation (30 ms).** An excursion that passes the decision waits 30 ms. A reversal of half the peak or more in that window, or an acceleration at the limit, rejects it as oscillation. This removed every hand-shake and mixed-motion false flip in the synthetic set, at a cost of about 30 ms of latency.
- **Direction.** The sense of rotation about the device axis that dominates the peak, not the sign of a canonical projection. Near the long axis, a right-edge-away turn is positive whatever the grip angle.
- **Cooldown.** After a flip, 1.2 s and 0.3 s of calm are required before the next excursion can arm. A return stroke inside that time is logged as "ignored: return stroke" and never flips. A flick and its rebound are one gesture.
- **Suppression** (unchanged): touch or drag, a sheet over the Inspector, a flip still animating, Reduce Motion, an inactive scene, and Off. Suppression during an excursion rejects it. Off clears all state and creates no motion work.
- **Tuning** (unchanged labels and ranges): Twist axis, Long axis leans, Start rate, Peak rate needed, Axis share needed, Turn needed, Longest twist, Shake limit, Pause after a flip. `GyroTuning.pulseConfiguration` maps them onto the recognizer.

## Synthetic measurements

Method. `ios/Tests/GyroFlip/Corpus.swift` generates deterministic traces: 60 Hz nominal with ±15% jitter, 3% dropped samples, gyroscope noise, a small lift wobble, and natural flicks with an optional return stroke. The natural-flick prior is stated, not fitted: total angle 0.35 to 1.2 rad, peak 2 to 5 rad/s, duration from the minimum-jerk shape. Ordinary families: slow tilt, quick tilt to the face (a pitch with leakage into the twist plane), hand tremor, walking sway, hand shake (3 to 6 Hz, up to 2.4 g) and pick-up or reposition. Defaults were chosen on development seeds (1…). Held-out seeds (9000…) are reported only. Reproduce with `gyro-tests`.

| Measure | PR #43, development | Pulse, development | PR #43, held-out | Pulse, held-out |
| --- | --- | --- | --- | --- |
| Flicks recognized, + and − | 35% and 38% | 44% and 43% | 44% and 31% | 50% and 42% |
| Wrong direction | 17 | **0** | 22 | **0** |
| Double flips | 0 | 0 | 0 | 0 |
| Latency from peak, p50 and p95 | 94 and 165 ms | 195 and 221 ms | 104 and 172 ms | 192 and 220 ms |
| Ordinary false events per 100 trials | 0.17 | 0.00 | 0.00 | 0.00 |

Flick recognition by size and duration, development seeds, pulse recognizer: flicks of 0.7 rad (40°) and larger were recognized in every cell (100%, 14 of 14, 74 of 74, 24 of 24). Flicks of 0.5 to 0.7 rad were recognized in 0 to 53% of trials, depending on duration (0 of 4 in the shortest bin, 33% and 53% in the two longer bins). Flicks below 0.5 rad were not recognized, because they fall under the 0.55 rad turn requirement. Held-out seeds show the same pattern.

What these numbers do not show: real wrist motion. A natural flick's peak, size and duration distribution is an assumption. The owner's recordings are the only evidence that can change it. Every synthetic result here is labelled as such.

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

Use an owner-tools build (Debug or internal TestFlight). Use a phone with Low Power Mode off, and hold it the way you normally do.

1. In View & Style, keep **Flip cards with wrist twist** on, and turn on **Show motion readout** and **Record a motion trace for the next open card**. Open a card in the Inspector. Recording needs the motion sensor running, so it does nothing while the flip is off.
2. Make 40 deliberate flicks, 20 each direction, about 1 second apart. Vary grip and starting posture a little. Close the Inspector. A file `gyro-trace-…jsonl` is written to the app's Documents folder, and the readout names it.
3. Make the ordinary-movement trials in a separate session: browsing with taps and drags, lifting and placing the phone, walking, slow and quick tilts, a shake. Then leave one session for 15 minutes of browsing. Record each as its own trace.
4. Replay each file on a Mac: `swiftc -O ios/AroomaNative/GyroFlipDetector.swift ios/AroomaNative/GyroPulseDetector.swift ios/AroomaNative/GyroTrace.swift ios/Tests/GyroFlip/Corpus.swift ios/Tests/GyroFlip/Report.swift ios/Tests/GyroFlip/main.swift -o gyro-tests` and `./gyro-tests --replay <file>`. The output shows each recognizer's flips beside the flips the app produced.
5. Count misses, wrong directions, double flips and accidental flips for each trial set. Compare them with the thresholds above.
6. If deliberate flicks are missed as "too small", lower **Turn needed** by 0.05 rad and replay. If they are missed as "too weak", lower **Peak rate needed** by 0.2 rad/s. If accidental flips appear during browsing or tilting, raise **Turn needed** or **Start rate** by the same steps. Change one control at a time.
7. Record the final values, the counts and the trace file names in the evidence folder. Each physical target above moves from NOT RUN only when its count is in that folder.

## Privacy

Motion readings are still processed on this iPhone and used only for the foil and, if on, card flips. Owner-tools recording writes the raw readings for one session to the Documents folder, only after the owner switches it on, and only in an owner-tools build. Nothing is uploaded. The user-facing copy in View & Style is unchanged for normal builds.

## Limitations

- No physical measurement exists. Every physical target is NOT RUN.
- The synthetic corpus and its prior are assumptions. The 0.55 rad and 2.2 rad/s defaults are the plan's values, kept because no recording exists to change them.
- Latency is higher than PR #43's (p95 221 ms against 165 ms), because the decision waits for the end of the excursion. It is still inside the 250 ms target on synthetic traces.
- Recognition of flicks below about 0.5 rad is unavailable at the default turn requirement, by design, until calibration says otherwise.
- The live app and the replay use the same code, but the device's real sample timing is not reproduced exactly by the synthetic corpus.
- Screen-normal twists flip only when they dominate; a twist that is mostly about the screen normal follows the screen-normal sense.
