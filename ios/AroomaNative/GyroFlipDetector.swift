import Foundation

// MARK: - Gyro Flip detector
//
// A pure classifier for "a deliberate wrist twist". It knows nothing about Core Motion, SwiftUI or
// the card: callers hand it timestamped samples and it answers with at most one flip request.
// Foundation only, so the standalone test runner (ios/Tests/GyroFlip/main.swift) compiles it on its
// own on macOS and Linux.
//
// Inputs are `CMDeviceMotion.rotationRate` (rad/s) and `userAcceleration` (g, gravity removed),
// both read from the one shared MotionField feed. The detector never starts a sensor.
//
// The numbers below are INITIAL CALIBRATION HYPOTHESES, not measurements of a real iPhone. They are
// the values in AROOMA_NAVIGATION_V3_QUICK_ACTIONS.md section 1B. A physical-iPhone session must
// confirm them before the gesture is called verified.

/// A 3-vector of Doubles. No simd, so it builds wherever Swift does.
struct GyroVector: Equatable {
    var x: Double
    var y: Double
    var z: Double

    static let zero = GyroVector(x: 0, y: 0, z: 0)

    var magnitude: Double { (x * x + y * y + z * z).squareRoot() }
    var isFinite: Bool { x.isFinite && y.isFinite && z.isFinite }
}

/// One sensor sample. `rotationRate` is rad/s about the device axes, `userAcceleration` is in g.
struct GyroSample: Equatable {
    var timestamp: TimeInterval
    var rotationRate: GyroVector
    var userAcceleration: GyroVector
}

/// Which device axis carries the twist. Portrait is the app's only orientation, so this is `.y`
/// (the device's vertical axis). A landscape build would pass `.x`.
enum GyroTwistAxis: Equatable {
    case x, y, z
    /// Rotation about the long axis, the screen normal, or any axis between them. A natural wrist twist is
    /// rarely about one device axis: with the forearm pointing at the screen it is mostly about `z`. The twist
    /// axis is fixed from the first moments of each twist, so a twist about a steady axis counts and a
    /// wobble does not. Rotation about `x` (lifting or lowering the phone) never counts.
    case yz
}

enum GyroFlipDirection: Equatable {
    case positive, negative

    /// +1 or -1: the value `FlipMotor.flip(direction:)` takes. Positive means the phone's right edge
    /// turned away from the viewer, which is the way the card's own +y rotation turns.
    var sign: Double { self == .positive ? 1 : -1 }
}

struct GyroFlipConfiguration: Equatable {
    /// Longest step integrated in one sample (s).
    var maxStep = 0.05
    /// A gap longer than this drops the candidate and re-seeds the filter (s).
    var maxGap = 0.15
    /// Exponential low-pass time constant on the rotation rate (s).
    var filterTimeConstant = 0.045
    /// A candidate starts when the filtered twist rate exceeds this (rad/s) ...
    var startRate = 1.0
    /// ... and is abandoned when it falls back below this (rad/s).
    var endRate = 0.5
    /// |twist| / |rotation| must be at least this while the rate is above `startRate`.
    var minDominance = 0.75
    /// The candidate must reach this peak twist rate (rad/s, about 126 degrees/s) ...
    var peakRate = 2.2
    /// ... turn through this much (rad, about 32 degrees, counted from the candidate's start) ...
    var minAngle = 0.55
    /// ... within this window (s).
    var minDuration = 0.12
    var maxDuration = 0.45
    /// Large shakes and translations are rejected above this user acceleration (g).
    var maxUserAcceleration = 0.8
    /// After a flip: at least this long (s) ...
    var cooldown = 1.2
    /// ... and a calm phone (|twist| below this, rad/s, for `rearmCalm` seconds) before the next one.
    var rearmRate = 0.35
    var rearmCalm = 0.30
    /// After a rejected candidate, or after a reset: the phone must be calm this long (s) first.
    var calmRate = 0.35
    var calmTime = 0.15
    /// Turns the twist axis within the device's y-z plane (radians). 0 is the long axis; a positive value
    /// leans it toward the screen normal. Only applies when the twist axis is `.y`. A real wrist twist is
    /// not guaranteed to be about the long axis, so this exists to be measured and set on a physical iPhone.
    var axisTilt = 0.0

    /// The plan's initial values (AROOMA_NAVIGATION_V3_QUICK_ACTIONS.md section 1B). The unit tests pin these.
    static let initial = GyroFlipConfiguration()

    /// What the app ships after the first physical-iPhone report that a flick did not flip the card. Only the
    /// shake limit differs: the accelerometer sits about 10 cm from the wrist's axis, so a vigorous flick alone
    /// produces roughly 1 g of linear acceleration, and the plan's 0.8 g rejected it as a shake. Large shakes
    /// are still rejected: above 1.5 g, and by the peak, angle, duration and direction rules.
    static let shipped: GyroFlipConfiguration = {
        var c = GyroFlipConfiguration()
        c.maxUserAcceleration = 1.5
        return c
    }()
}

struct GyroFlipDetector {
    enum Phase: Equatable {
        /// Waiting for the phone to be still. Where a fresh or reset detector starts, so the tail of a
        /// motion that began before the reset can never flip the card.
        case needsCalm
        /// Armed: watching for a twist to start.
        case idle
        /// A twist is under way and being measured.
        case candidate
        /// A flip was just requested; waiting out the cooldown.
        case cooldown
    }

    /// Why the last candidate ended, for the owner-tools readout only. It never influences a decision.
    enum Outcome: Equatable {
        case none
        case flipped
        case rejected(String)
    }

    var configuration: GyroFlipConfiguration
    var twistAxis: GyroTwistAxis
    /// Off means no processing at all: samples are ignored and state is cleared.
    var isEnabled = true
    private(set) var phase: Phase = .needsCalm
    private(set) var lastOutcome: Outcome = .none

    /// Read-only live values for the owner-tools readout.
    var filteredRate: GyroVector { filtered }
    var candidateAngle: Double { angle }
    var candidatePeak: Double { peak }
    var currentTwistRate: Double { twist(of: filtered) }
    var currentDominance: Double { abs(twist(of: filtered)) / max(0.001, filtered.magnitude) }

    private var hasLast = false
    private var lastTimestamp: TimeInterval = 0
    private var filtered = GyroVector.zero
    private var startTime: TimeInterval = 0
    private var angle = 0.0
    private var peak = 0.0
    private var sign = 0.0
    private var triggerTime: TimeInterval = 0
    private var calm = 0.0
    /// For `.yz`: the unit twist direction in the y-z plane, fixed when a candidate starts.
    private var planeY = 0.0
    private var planeZ = 0.0

    init(configuration: GyroFlipConfiguration = .initial, twistAxis: GyroTwistAxis = .y) {
        self.configuration = configuration
        self.twistAxis = twistAxis
    }

    /// Clears every trace of earlier samples. Call when the Inspector disappears, the app changes
    /// scene phase, the setting is switched, the selected card changes or a gesture is cancelled.
    mutating func reset() {
        hasLast = false
        lastTimestamp = 0
        filtered = .zero
        phase = .needsCalm
        startTime = 0
        angle = 0
        peak = 0
        sign = 0
        triggerTime = 0
        calm = 0
        planeY = 0
        planeZ = 0
    }

    private mutating func abandon(to next: Phase) {
        phase = next
        angle = 0
        peak = 0
        sign = 0
        calm = 0
    }

    private func twist(of v: GyroVector) -> Double {
        switch twistAxis {
        case .x: return v.x
        case .y:
            let t = configuration.axisTilt
            return t == 0 ? v.y : v.y * cos(t) + v.z * sin(t)
        case .z: return v.z
        case .yz:
            // Armed: how fast the phone turns in the y-z plane. Measuring: the signed rate along the twist
            // direction fixed at the start of this candidate.
            if phase == .candidate { return v.y * planeY + v.z * planeZ }
            return (v.y * v.y + v.z * v.z).squareRoot()
        }
    }

    /// Feeds one sample. `suppressed` is true while anything else owns the card: a touch or drag,
    /// a sheet over the Inspector, a flip still settling, Reduce Motion, an inactive scene.
    /// Returns a direction at most once per twist, at the moment the twist qualifies.
    @discardableResult
    mutating func ingest(_ sample: GyroSample, suppressed: Bool = false) -> GyroFlipDirection? {
        guard isEnabled else {
            if hasLast || phase != .needsCalm { reset() }
            return nil
        }
        let c = configuration
        guard sample.timestamp.isFinite, sample.rotationRate.isFinite, sample.userAcceleration.isFinite else {
            reset()
            return nil
        }

        let gap = hasLast ? sample.timestamp - lastTimestamp : 0
        let step: Double
        if !hasLast || gap <= 0 || gap > c.maxGap {
            // First sample, a repeated or backwards timestamp, or a dropout: re-seed the filter and
            // drop any twist that was being measured.
            filtered = sample.rotationRate
            hasLast = true
            lastTimestamp = sample.timestamp
            if phase == .candidate { lastOutcome = .rejected("dropout"); abandon(to: .needsCalm) }
            step = 0
        } else {
            step = min(max(gap, 0), c.maxStep)
            lastTimestamp = sample.timestamp
            let alpha = 1 - exp(-step / c.filterTimeConstant)
            filtered.x += alpha * (sample.rotationRate.x - filtered.x)
            filtered.y += alpha * (sample.rotationRate.y - filtered.y)
            filtered.z += alpha * (sample.rotationRate.z - filtered.z)
        }

        let rate = twist(of: filtered)
        let dominance = abs(rate) / max(0.001, filtered.magnitude)
        let acceleration = sample.userAcceleration.magnitude

        switch phase {
        case .cooldown:
            calm = abs(rate) < c.rearmRate ? calm + step : 0
            if sample.timestamp - triggerTime >= c.cooldown && calm >= c.rearmCalm {
                abandon(to: .idle)
            }
            return nil

        case .needsCalm:
            calm = abs(rate) < c.calmRate ? calm + step : 0
            if calm >= c.calmTime { abandon(to: .idle) }
            return nil

        case .idle:
            if suppressed { return nil }
            if abs(rate) > c.startRate && dominance >= c.minDominance && acceleration < c.maxUserAcceleration {
                phase = .candidate
                startTime = sample.timestamp
                angle = 0
                peak = abs(rate)
                if twistAxis == .yz {
                    // `rate` is the in-plane magnitude here. Fix the direction, with its larger component
                    // positive, so a left twist and a right twist come out with opposite signs.
                    let r = max(rate, 0.001)
                    var uy = filtered.y / r
                    var uz = filtered.z / r
                    let flip = abs(uy) >= abs(uz) ? (uy < 0) : (uz < 0)
                    if flip { uy = -uy; uz = -uz }
                    planeY = uy
                    planeZ = uz
                    sign = (filtered.y * uy + filtered.z * uz) > 0 ? 1 : -1
                } else {
                    sign = rate > 0 ? 1 : -1
                }
            }
            return nil

        case .candidate:
            if suppressed || acceleration >= c.maxUserAcceleration {
                lastOutcome = .rejected(suppressed ? "touch or sheet" : "shake")
                abandon(to: .needsCalm)
                return nil
            }
            if abs(rate) > c.startRate && dominance < c.minDominance {
                lastOutcome = .rejected("other axis \(String(format: "%.2f", dominance))")
                abandon(to: .needsCalm)
                return nil
            }
            if rate * sign < 0 {
                lastOutcome = .rejected("reversed")
                abandon(to: .needsCalm)
                return nil
            }
            angle += rate * step
            peak = max(peak, abs(rate))
            let duration = sample.timestamp - startTime
            if peak >= c.peakRate && abs(angle) >= c.minAngle
                && duration >= c.minDuration && duration <= c.maxDuration {
                let direction: GyroFlipDirection = angle > 0 ? .positive : .negative
                lastOutcome = .flipped
                phase = .cooldown
                triggerTime = sample.timestamp
                angle = 0
                peak = 0
                sign = 0
                calm = 0
                return direction
            }
            if duration > c.maxDuration || abs(rate) < c.endRate {
                if duration > c.maxDuration {
                    lastOutcome = .rejected("too long")
                } else if peak < c.peakRate {
                    lastOutcome = .rejected("too weak, peak \(String(format: "%.1f", peak))")
                } else {
                    lastOutcome = .rejected("too small, angle \(String(format: "%.2f", abs(angle)))")
                }
                abandon(to: .needsCalm)
            }
            return nil
        }
    }
}
