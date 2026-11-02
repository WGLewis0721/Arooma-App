import Foundation

// Standalone test runner for ios/AroomaNative/GyroFlipDetector.swift. No XCTest, so it runs the same on
// the macOS CI runner and on Linux:
//   swiftc -O ios/AroomaNative/GyroFlipDetector.swift ios/Tests/GyroFlip/main.swift -o /tmp/gyro-tests && /tmp/gyro-tests
//
// These are SYNTHETIC traces. They prove the classifier's logic (exactly one event per valid twist, none
// for rejected motion). They say nothing about a real iPhone's gyroscope: that needs the physical test in
// AROOMA_NAVIGATION_V3_QUICK_ACTIONS.md section 1B (>= 18/20 intentional, <= 1/100 accidental).

var failures = 0
var passes = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String, line: Int = #line) {
    if condition() { passes += 1 } else { failures += 1; print("FAIL [line \(line)]: \(message)") }
}

typealias RateFn = (Double) -> GyroVector
typealias AccelFn = (Double) -> GyroVector

let still: AccelFn = { _ in GyroVector.zero }

/// Minimum-jerk angular velocity: a smooth bell that turns through `angle` radians in `duration` seconds.
func minJerk(_ t: Double, duration: Double, angle: Double) -> Double {
    guard t >= 0, t <= duration else { return 0 }
    let s = t / duration
    return 30 * angle / duration * s * s * (1 - s) * (1 - s)
}

/// A twist starting at `start` seconds. `axis` 0 = x, 1 = y (the twist axis), 2 = z.
func twist(at start: Double, duration: Double, angle: Double, axis: Int = 1) -> RateFn {
    return { t in
        let r = minJerk(t - start, duration: duration, angle: angle)
        switch axis {
        case 0: return GyroVector(x: r, y: 0, z: 0)
        case 2: return GyroVector(x: 0, y: 0, z: r)
        default: return GyroVector(x: 0, y: r, z: 0)
        }
    }
}

func sum(_ parts: [RateFn]) -> RateFn {
    return { t in
        var out = GyroVector.zero
        for part in parts {
            let v = part(t)
            out.x += v.x; out.y += v.y; out.z += v.z
        }
        return out
    }
}

func makeTrace(seconds: Double, hz: Double = 60, rate: RateFn, accel: AccelFn = still) -> [GyroSample] {
    let count = Int((seconds * hz).rounded())
    return (0...count).map { i in
        let t = Double(i) / hz
        return GyroSample(timestamp: 1000 + t, rotationRate: rate(t), userAcceleration: accel(t))
    }
}

struct Event { let time: Double; let direction: GyroFlipDirection }

/// Runs a trace through a detector. `suppress`/`drop` take seconds since the first sample.
func run(_ samples: [GyroSample], hz: Double = 60, enabled: Bool = true, resetAtSample: Int? = nil,
         suppress: (Double) -> Bool = { _ in false }, drop: (Double) -> Bool = { _ in false },
         detector start: GyroFlipDetector? = nil) -> [Event] {
    var detector = start ?? GyroFlipDetector()
    detector.isEnabled = enabled
    var events: [Event] = []
    for (i, s) in samples.enumerated() {
        let rel = Double(i) / hz
        if drop(rel) { continue }
        if let resetAtSample, i == resetAtSample { detector.reset() }
        if let direction = detector.ingest(s, suppressed: suppress(rel)) {
            events.append(Event(time: rel, direction: direction))
        }
    }
    return events
}

// MARK: 1. Rejected motion: no false flip

do {
    check(run(makeTrace(seconds: 4, rate: twist(at: 0.2, duration: 3.0, angle: 1.0))).isEmpty,
          "slow tilt (1 rad over 3 s) does not flip")
    check(run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.9, angle: 0.8))).isEmpty,
          "slow wrist turn (0.8 rad over 0.9 s) does not flip")
    check(run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.2, angle: 0.25))).isEmpty,
          "tiny wiggle (0.25 rad over 0.2 s) does not flip")

    let shake: RateFn = { t in GyroVector(x: 0, y: (t > 0.2 && t < 1.0) ? 8 * sin(2 * .pi * 4 * t) : 0, z: 0) }
    let shakeAccel: AccelFn = { t in
        (t > 0.2 && t < 1.0) ? GyroVector(x: 1.6 * sin(2 * .pi * 4 * t + 1), y: 0, z: 0) : .zero
    }
    check(run(makeTrace(seconds: 2, rate: shake, accel: shakeAccel)).isEmpty, "accidental shake (4 Hz, 1.6 g) does not flip")
    check(run(makeTrace(seconds: 2, rate: shake)).isEmpty, "rotation-only oscillation (4 Hz, 8 rad/s) does not flip")

    check(run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: 0.8, axis: 0))).isEmpty,
          "x-axis tilt does not flip")
    check(run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: 0.8, axis: 2))).isEmpty,
          "z-axis screen-plane spin does not flip")
    check(run(makeTrace(seconds: 3, rate: sum([twist(at: 0.5, duration: 0.35, angle: 0.8, axis: 1),
                                                twist(at: 0.5, duration: 0.35, angle: 1.6, axis: 0)]))).isEmpty,
          "a y twist buried in a larger x tilt is not dominant, so it does not flip")

    let sway: RateFn = { t in GyroVector(x: 0, y: 0.8 * sin(2 * .pi * 2 * t), z: 0) }
    let swayAccel: AccelFn = { t in GyroVector(x: 0.4 * sin(2 * .pi * 2 * t), y: 0, z: 0) }
    check(run(makeTrace(seconds: 4, rate: sway, accel: swayAccel)).isEmpty, "walking sway does not flip")

    let lift = twist(at: 0.4, duration: 0.6, angle: 1.2, axis: 0)
    check(run(makeTrace(seconds: 3, rate: lift, accel: { t in t > 0.4 && t < 1.0 ? GyroVector(x: 0, y: 0.5, z: 0) : .zero })).isEmpty,
          "lifting the phone (x rotation with acceleration) does not flip")
}

// MARK: 2. Valid twists: exactly one event, with the right direction

do {
    let plus = run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: 0.8)))
    check(plus.count == 1 && plus.first?.direction == .positive, "a +y twist flips once, positive")
    let minus = run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: -0.8)))
    check(minus.count == 1 && minus.first?.direction == .negative, "a -y twist flips once, negative")
    check(GyroFlipDirection.positive.sign == 1 && GyroFlipDirection.negative.sign == -1, "direction signs are +1 / -1")
    if let first = plus.first { check(first.time > 0.5 && first.time < 1.0, "the flip fires during the twist, not long after (\(first.time) s)") }

    // Rebound: the phone is turned back at once. Only the first turn counts.
    let rebound = run(makeTrace(seconds: 3, rate: sum([twist(at: 0.5, duration: 0.35, angle: 0.8),
                                                        twist(at: 0.9, duration: 0.35, angle: -0.8)])))
    check(rebound.count == 1 && rebound.first?.direction == .positive, "turn-back rebound does not flip the card back")

    // Two separate twists after the cooldown, same and opposite direction.
    let same = run(makeTrace(seconds: 5, rate: sum([twist(at: 0.5, duration: 0.35, angle: 0.8),
                                                     twist(at: 2.6, duration: 0.35, angle: 0.8)])))
    check(same.count == 2 && same[0].direction == .positive && same[1].direction == .positive, "two twists 2 s apart flip twice")
    let alternating = run(makeTrace(seconds: 6, rate: sum([twist(at: 0.5, duration: 0.35, angle: 0.8),
                                                            twist(at: 1.1, duration: 0.5, angle: -0.8),
                                                            twist(at: 3.0, duration: 0.35, angle: -0.8)])))
    check(alternating.count == 2 && alternating[0].direction == .positive && alternating[1].direction == .negative,
          "twist, return, then a deliberate opposite twist: exactly two flips")
    let tooSoon = run(makeTrace(seconds: 4, rate: sum([twist(at: 0.5, duration: 0.35, angle: 0.8),
                                                        twist(at: 1.3, duration: 0.35, angle: 0.8)])))
    check(tooSoon.count == 1, "a second twist 0.8 s later is inside the cooldown")
}

// MARK: 3. Dropouts, pauses, toggle, suppression

do {
    let valid = makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: 0.8))
    check(run(valid, drop: { $0 > 0.6 && $0 < 0.8 }).isEmpty, "a 0.2 s dropout mid-twist resets the candidate")
    let small = run(valid, drop: { $0 > 0.68 && $0 < 0.71 })
    check(small.count == 1, "a 0.04 s dropout does not stop a valid twist")
    check(run(valid, resetAtSample: 39).isEmpty, "a reset mid-twist (view disappears) cannot flip from the remainder")
    let later = run(makeTrace(seconds: 3, rate: twist(at: 1.5, duration: 0.35, angle: 0.8)), resetAtSample: 30)
    check(later.count == 1, "after a reset, a full twist 1 s later flips once")
    check(run(makeTrace(seconds: 3, rate: twist(at: 0.0, duration: 0.35, angle: 0.8))).isEmpty,
          "a twist already under way at the first sample (no calm yet) does not flip")
    check(run(valid, enabled: false).isEmpty, "toggle Off: zero events")
    check(run(valid, suppress: { _ in true }).isEmpty, "suppressed for the whole twist (Reduce Motion, touch, sheet): zero events")
    check(run(valid, suppress: { $0 > 0.6 }).isEmpty, "a touch that begins mid-twist cancels it")
    check(run(valid, suppress: { $0 < 0.4 }).count == 1, "suppression that ends before the twist does not block it")

    // A disabled detector holds no state.
    var detector = GyroFlipDetector()
    detector.isEnabled = false
    for s in valid { _ = detector.ingest(s) }
    check(detector.phase == .needsCalm, "a disabled detector stays reset")
    detector.isEnabled = true
    check(detector.ingest(valid[0]) == nil, "first sample after enabling is not a flip")

    // Invalid timestamps and values reset, never crash.
    var bad = GyroFlipDetector()
    _ = bad.ingest(GyroSample(timestamp: .nan, rotationRate: .zero, userAcceleration: .zero))
    _ = bad.ingest(GyroSample(timestamp: 1, rotationRate: GyroVector(x: .infinity, y: 0, z: 0), userAcceleration: .zero))
    check(bad.phase == .needsCalm, "non-finite samples reset the detector")
    var back = GyroFlipDetector()
    _ = back.ingest(GyroSample(timestamp: 5, rotationRate: .zero, userAcceleration: .zero))
    _ = back.ingest(GyroSample(timestamp: 4, rotationRate: .zero, userAcceleration: .zero))
    check(back.phase == .needsCalm, "a timestamp that goes backwards does not advance state")
}

// MARK: 4. Phases

do {
    var d = GyroFlipDetector()
    check(d.phase == .needsCalm, "a new detector starts needing calm")
    var fired = false
    for s in makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: 0.8)) {
        if d.ingest(s) != nil { fired = true; check(d.phase == .cooldown, "a flip puts the detector in cooldown") }
    }
    check(fired, "the phase walk saw a flip")
    check(d.phase == .idle, "after the cooldown and a calm phone it is armed again")
    d.reset()
    check(d.phase == .needsCalm, "reset returns to needing calm")
}

// MARK: 5. Parameter grids

do {
    // Near misses: too small, whatever the speed. Slow: too slow, whatever the size.
    for angle in [0.3, 0.4, 0.5, 0.6] {
        for duration in [0.2, 0.3, 0.4, 0.5, 0.8] {
            let n = run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: duration, angle: angle))).count
            check(n == 0, "near miss angle \(angle) over \(duration) s must not flip (got \(n))")
        }
    }
    for duration in [0.8, 1.0, 1.5] {
        let n = run(makeTrace(seconds: 4, rate: twist(at: 0.5, duration: duration, angle: 0.7))).count
        check(n == 0, "slow 0.7 rad over \(duration) s must not flip (got \(n))")
    }
    // Clear twists flip exactly once, both directions.
    for angle in [1.0, 1.3, 1.8] {
        for duration in [0.2, 0.3, 0.4, 0.5] {
            for signv in [1.0, -1.0] {
                let n = run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: duration, angle: angle * signv))).count
                check(n == 1, "clear twist \(angle * signv) rad over \(duration) s must flip once (got \(n))")
            }
        }
    }
    // The same twist at other sample rates.
    for hz in [30.0, 60.0, 100.0] {
        let n = run(makeTrace(seconds: 3, hz: hz, rate: twist(at: 0.5, duration: 0.35, angle: 0.8)), hz: hz).count
        check(n == 1, "0.8 rad twist flips once at \(Int(hz)) Hz (got \(n))")
        let m = run(makeTrace(seconds: 3, hz: hz, rate: twist(at: 0.5, duration: 0.35, angle: 0.5)), hz: hz).count
        check(m == 0, "0.5 rad twist does not flip at \(Int(hz)) Hz (got \(m))")
    }
}

// MARK: 6. Deterministic fuzz: incidental motion never flips

struct LCG {
    var state: UInt64
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(1 << 53)
    }
    mutating func range(_ lo: Double, _ hi: Double) -> Double { lo + (hi - lo) * next() }
}

do {
    var rng = LCG(state: 20261101)
    var falseFlips = 0
    // 100 trials of 8 s: slow, mixed-axis rotation with every axis kept under 1.8 rad/s and acceleration under 0.7 g.
    for _ in 0..<100 {
        var axes: [[(amp: Double, freq: Double, phase: Double)]] = []
        for _ in 0..<3 { axes.append((0..<3).map { _ in (rng.range(0, 0.6), rng.range(0.4, 3.0), rng.range(0, 6.28)) }) }
        var accel: [(amp: Double, freq: Double, phase: Double)] = []
        for _ in 0..<3 { accel.append((rng.range(0, 0.23), rng.range(0.4, 3.0), rng.range(0, 6.28))) }
        let rate: RateFn = { t in
            func axis(_ i: Int) -> Double { axes[i].reduce(0) { $0 + $1.amp * sin(2 * .pi * $1.freq * t + $1.phase) } }
            return GyroVector(x: axis(0), y: axis(1), z: axis(2))
        }
        let acc: AccelFn = { t in
            func a(_ i: Int) -> Double { accel[i].amp * sin(2 * .pi * accel[i].freq * t + accel[i].phase) }
            return GyroVector(x: a(0), y: a(1), z: a(2))
        }
        falseFlips += run(makeTrace(seconds: 8, rate: rate, accel: acc)).count
    }
    check(falseFlips == 0, "100 incidental-motion traces: \(falseFlips) false flips")

    // 100 violent shakes: up to 12 rad/s about any axis, with acceleration always at least 1.0 g.
    falseFlips = 0
    for _ in 0..<100 {
        let f = rng.range(2, 6), ph = rng.range(0, 6.28)
        let dirx = rng.range(-1, 1), diry = rng.range(-1, 1), dirz = rng.range(-1, 1)
        let amp = rng.range(4, 12)
        let rate: RateFn = { t in
            let s = amp * sin(2 * .pi * f * t + ph)
            return GyroVector(x: dirx * s, y: diry * s, z: dirz * s)
        }
        let acc: AccelFn = { t in GyroVector(x: 1.0 + abs(sin(2 * .pi * f * t)) * 1.5, y: 0, z: 0) }
        falseFlips += run(makeTrace(seconds: 6, rate: rate, accel: acc)).count
    }
    check(falseFlips == 0, "100 violent shakes: \(falseFlips) false flips")

    // 100 large rotations whose twist axis is never dominant (y at most 0.6 of the whole).
    falseFlips = 0
    for _ in 0..<100 {
        let ax = rng.range(-1, 1), az = rng.range(-1, 1)
        let norm = (ax * ax + az * az).squareRoot()
        let ux = norm > 0.001 ? ax / norm * 0.8 : 0.8, uz = norm > 0.001 ? az / norm * 0.8 : 0
        let uy = 0.6 // 0.6 / sqrt(0.6^2 + 0.8^2) = 0.6: below the 0.75 dominance
        let start = rng.range(0.4, 1.5), dur = rng.range(0.2, 0.5), ang = rng.range(0.8, 2.0)
        let rate: RateFn = { t in
            let r = minJerk(t - start, duration: dur, angle: ang)
            return GyroVector(x: ux * r, y: uy * r, z: uz * r)
        }
        falseFlips += run(makeTrace(seconds: 3, rate: rate)).count
    }
    check(falseFlips == 0, "100 non-dominant large rotations: \(falseFlips) false flips")
}

// MARK: 7. Determinism

do {
    let trace = makeTrace(seconds: 5, rate: sum([twist(at: 0.5, duration: 0.35, angle: 0.8), twist(at: 2.6, duration: 0.35, angle: -0.9)]))
    let a = run(trace), b = run(trace)
    check(a.count == b.count && zip(a, b).allSatisfy { $0.time == $1.time && $0.direction == $1.direction },
          "the same trace gives the same events every time")
    check(GyroFlipConfiguration.initial.peakRate == 2.2 && GyroFlipConfiguration.initial.minAngle == 0.55
          && GyroFlipConfiguration.initial.cooldown == 1.2 && GyroFlipConfiguration.initial.maxUserAcceleration == 0.8,
          "the initial configuration is the one in the plan")
}

// MARK: 8. Adjustable twist axis, and the outcome the owner-tools readout shows

do {
    // A twist about an axis halfway between the long axis and the screen normal (45 degrees in the y-z plane).
    let diagonal: RateFn = { t in
        let r = minJerk(t - 0.5, duration: 0.35, angle: 0.8)
        return GyroVector(x: 0, y: r * cos(Double.pi / 4), z: r * sin(Double.pi / 4))
    }
    let trace = makeTrace(seconds: 3, rate: diagonal)
    check(run(trace).isEmpty, "a twist 45 degrees off the long axis is rejected by the plan's dominance")
    var tilted = GyroFlipDetector()
    tilted.configuration.axisTilt = Double.pi / 4
    check(run(trace, detector: tilted).count == 1, "with the axis tilted to match, the same twist flips exactly once")
    var tiltedX = GyroFlipDetector()
    tiltedX.configuration.axisTilt = Double.pi / 4
    check(run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: 0.8, axis: 0)), detector: tiltedX).isEmpty,
          "tilting the axis does not make an x-axis tilt flip")
    check(GyroFlipConfiguration.initial.axisTilt == 0, "the shipped axis tilt is 0")

    var valid = GyroFlipDetector()
    for s in makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: 0.8)) { valid.ingest(s) }
    check(valid.lastOutcome == .flipped, "a valid twist records .flipped")
    var slow = GyroFlipDetector()
    for s in makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.9, angle: 0.8)) { slow.ingest(s) }
    let slowRejected: Bool = { if case .rejected = slow.lastOutcome { return true } else { return false } }()
    check(slowRejected, "a slow turn records a rejection reason")
    var other = GyroFlipDetector()
    for s in makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: 0.8, axis: 2)) { other.ingest(s) }
    check(other.lastOutcome == .none, "a rotation that never starts a candidate records nothing")
}

// MARK: 9. The shipped configuration: long axis or screen normal, and a 1.5 g shake limit
//
// The first physical-iPhone report said a flick did not flip the card. Two assumptions in the plan were the
// likely cause: a single twist axis, and a 0.8 g shake limit that a vigorous flick exceeds on its own.

func shipped() -> GyroFlipDetector { GyroFlipDetector(configuration: .shipped, twistAxis: .yz) }

do {
    let plan = GyroFlipConfiguration.initial, now = GyroFlipConfiguration.shipped
    check(now.maxUserAcceleration == 1.5 && now.peakRate == plan.peakRate && now.minAngle == plan.minAngle
          && now.minDominance == plan.minDominance && now.startRate == plan.startRate
          && now.maxDuration == plan.maxDuration && now.cooldown == plan.cooldown,
          "the shipped configuration differs from the plan only in the shake limit")

    for (name, axis) in [("long axis", 1), ("screen normal", 2)] {
        let plus = run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: 0.8, axis: axis)), detector: shipped())
        let minus = run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: -0.8, axis: axis)), detector: shipped())
        check(plus.count == 1 && plus.first?.direction == .positive, "\(name) twist, positive: one positive flip (got \(plus.count))")
        check(minus.count == 1 && minus.first?.direction == .negative, "\(name) twist, negative: one negative flip (got \(minus.count))")
    }

    // A twist about an axis between the long axis and the screen normal, at 20, 45 and 70 degrees.
    for degrees in [20.0, 45.0, 70.0] {
        let a = degrees * Double.pi / 180
        func diagonal(_ sign: Double) -> RateFn {
            return { t in
                let r = sign * minJerk(t - 0.5, duration: 0.35, angle: 0.8)
                return GyroVector(x: 0, y: r * cos(a), z: r * sin(a))
            }
        }
        let plus = run(makeTrace(seconds: 3, rate: diagonal(1)), detector: shipped())
        let minus = run(makeTrace(seconds: 3, rate: diagonal(-1)), detector: shipped())
        check(plus.count == 1 && plus.first?.direction == .positive, "a twist \(Int(degrees)) degrees toward the screen flips positive (got \(plus.count))")
        check(minus.count == 1 && minus.first?.direction == .negative, "the opposite twist flips negative (got \(minus.count))")
    }

    // Lifting or lowering the phone (about x) never counts, alone or with a small twist.
    check(run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: 0.8, axis: 0)), detector: shipped()).isEmpty,
          "an x-axis tilt does not flip")
    check(run(makeTrace(seconds: 3, rate: sum([twist(at: 0.5, duration: 0.35, angle: 0.8, axis: 1),
                                                twist(at: 0.5, duration: 0.35, angle: 1.6, axis: 0)])), detector: shipped()).isEmpty,
          "a twist mixed with a larger x tilt does not flip")
    check(run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.9, angle: 0.8, axis: 2)), detector: shipped()).isEmpty,
          "a slow turn about the screen normal does not flip")
    check(run(makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.2, angle: 0.25, axis: 2)), detector: shipped()).isEmpty,
          "a tiny wiggle about the screen normal does not flip")

    // The reason for the change: a vigorous flick carries about 1.2 g of linear acceleration by itself.
    let flickAccel: AccelFn = { t in (t > 0.45 && t < 0.75) ? GyroVector(x: 1.2, y: 0, z: 0) : GyroVector.zero }
    let flick = makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.2, angle: 1.2), accel: flickAccel)
    check(run(flick, detector: shipped()).count == 1, "a vigorous flick with 1.2 g flips with the shipped configuration")
    check(run(flick).isEmpty, "the plan's 0.8 g limit rejected the same flick")

    // Shakes still do not flip: rotation with 1.6 g of acceleration, about the long axis and the screen normal.
    for axis in [1, 2] {
        let rate: RateFn = { t in
            let r = (t > 0.2 && t < 1.0) ? 8.0 * sin(2 * .pi * 4 * t) : 0
            return axis == 1 ? GyroVector(x: 0, y: r, z: 0) : GyroVector(x: 0, y: 0, z: r)
        }
        let acc: AccelFn = { t in (t > 0.2 && t < 1.0) ? GyroVector(x: 1.6 * sin(2 * .pi * 4 * t + 1), y: 0, z: 0) : GyroVector.zero }
        check(run(makeTrace(seconds: 2, rate: rate, accel: acc), detector: shipped()).isEmpty, "a 4 Hz shake (axis \(axis)) does not flip")
        check(run(makeTrace(seconds: 2, rate: rate), detector: shipped()).isEmpty, "a 4 Hz rotation-only oscillation (axis \(axis)) does not flip")
    }

    // One event per twist, cooldown and the rebound, on the screen-normal axis.
    let rebound = run(makeTrace(seconds: 3, rate: sum([twist(at: 0.5, duration: 0.35, angle: 0.8, axis: 2),
                                                         twist(at: 0.9, duration: 0.35, angle: -0.8, axis: 2)])), detector: shipped())
    check(rebound.count == 1 && rebound.first?.direction == .positive, "a twist and its immediate return flip once, in the first direction")
    let spaced = run(makeTrace(seconds: 5, rate: sum([twist(at: 0.5, duration: 0.35, angle: 0.8, axis: 2),
                                                        twist(at: 2.6, duration: 0.35, angle: 0.8, axis: 2)])), detector: shipped())
    check(spaced.count == 2, "two twists 2 s apart flip twice (got \(spaced.count))")
    let tooSoon = run(makeTrace(seconds: 4, rate: sum([twist(at: 0.5, duration: 0.35, angle: 0.8, axis: 2),
                                                         twist(at: 1.3, duration: 0.35, angle: 0.8, axis: 2)])), detector: shipped())
    check(tooSoon.count == 1, "a second twist 0.8 s later is inside the cooldown")

    // The toggle and suppression still hold.
    let valid = makeTrace(seconds: 3, rate: twist(at: 0.5, duration: 0.35, angle: 0.8, axis: 2))
    check(run(valid, enabled: false, detector: shipped()).isEmpty, "Off flips nothing")
    check(run(valid, suppress: { _ in true }, detector: shipped()).isEmpty, "a suppressed twist flips nothing")
}

do {
    var rng = LCG(state: 20261102)
    var falseFlips = 0
    // 100 trials of 8 s: slow, mixed-axis rotation with every axis under 1.5 rad/s and acceleration under 0.7 g.
    for _ in 0..<100 {
        var axes: [[(amp: Double, freq: Double, phase: Double)]] = []
        for _ in 0..<3 { axes.append((0..<3).map { _ in (rng.range(0, 0.5), rng.range(0.4, 3.0), rng.range(0, 6.28)) }) }
        var accel: [(amp: Double, freq: Double, phase: Double)] = []
        for _ in 0..<3 { accel.append((rng.range(0, 0.23), rng.range(0.4, 3.0), rng.range(0, 6.28))) }
        let rate: RateFn = { t in
            func axis(_ i: Int) -> Double { axes[i].reduce(0) { $0 + $1.amp * sin(2 * .pi * $1.freq * t + $1.phase) } }
            return GyroVector(x: axis(0), y: axis(1), z: axis(2))
        }
        let acc: AccelFn = { t in
            func a(_ i: Int) -> Double { accel[i].amp * sin(2 * .pi * accel[i].freq * t + accel[i].phase) }
            return GyroVector(x: a(0), y: a(1), z: a(2))
        }
        falseFlips += run(makeTrace(seconds: 8, rate: rate, accel: acc), detector: shipped()).count
    }
    check(falseFlips == 0, "100 incidental-motion traces (shipped): \(falseFlips) false flips")

    // 100 violent shakes: up to 12 rad/s about any axis, with acceleration always at least 1.0 g and up to 2.5 g.
    falseFlips = 0
    for _ in 0..<100 {
        let f = rng.range(2, 6), ph = rng.range(0, 6.28)
        let dirx = rng.range(-1, 1), diry = rng.range(-1, 1), dirz = rng.range(-1, 1)
        let amp = rng.range(4, 12)
        let rate: RateFn = { t in
            let s = amp * sin(2 * .pi * f * t + ph)
            return GyroVector(x: dirx * s, y: diry * s, z: dirz * s)
        }
        let acc: AccelFn = { t in GyroVector(x: 1.0 + abs(sin(2 * .pi * f * t)) * 1.5, y: 0, z: 0) }
        falseFlips += run(makeTrace(seconds: 6, rate: rate, accel: acc), detector: shipped()).count
    }
    check(falseFlips == 0, "100 violent shakes (shipped): \(falseFlips) false flips")

    // 100 large lifts and lowerings: mostly about x, with only a small part about the long axis or screen normal.
    falseFlips = 0
    for _ in 0..<100 {
        let phi = rng.range(0, 6.28)
        let start = rng.range(0.4, 1.5), dur = rng.range(0.2, 0.5), ang = rng.range(0.8, 2.0)
        let rate: RateFn = { t in
            let r = minJerk(t - start, duration: dur, angle: ang)
            return GyroVector(x: 0.95 * r, y: 0.3 * r * cos(phi), z: 0.3 * r * sin(phi))
        }
        falseFlips += run(makeTrace(seconds: 3, rate: rate), detector: shipped()).count
    }
    check(falseFlips == 0, "100 x-dominant lifts (shipped): \(falseFlips) false flips")
}

print("Gyro flip: \(passes) checks passed, \(failures) failed")
exit(failures == 0 ? 0 : 1)
