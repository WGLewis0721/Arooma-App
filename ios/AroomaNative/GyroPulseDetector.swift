import Foundation

// MARK: - Gyro pulse recognizer
//
// Implements the single-pulse recognizer proposed in reference.md, section 4. It is a pure file, Foundation
// only, so the standalone runner in ios/Tests/GyroFlip compiles it on macOS and Linux. It answers the same
// question as GyroFlipDetector (PR #43) and takes the same inputs, but decides differently:
//
//   * One excursion is one candidate. It starts when the twist-plane rate rises above `startRate` and ends when
//     it falls back below `endRate`. A return stroke therefore begins a new excursion, which is ignored while the
//     detector is in cooldown. A flick and its rebound are one gesture, one flip.
//   * The decision is made once, at the end of the excursion, from measured features only: the peak rate, the
//     sign-free turn (integral of |rate|, so a snap and its return cannot cancel), the duration, the dominance at
//     the peak and the strongest user acceleration. The direction is the sign of the rate at the peak, not the
//     sign of a net angle.
//   * The signal goes through a low-latency filter (45 ms in PR #43). That filter attenuated short peaks; the
//     time constant here is 20 ms, so a 0.2 s flick keeps most of its measured peak.
//   * Hysteresis: arming needs `startRate`, the excursion ends at `endRate`, and re-arming needs a calm phone for
//     `rearmCalm` seconds after the cooldown (settling before re-arming).
//
// The numbers below are engineering hypotheses. They are validated on synthetic traces here, and they must be
// confirmed on recordings from a physical iPhone (see the calibration procedure in the spec) before any claim of
// physical accuracy.

/// Tunable parameters of the pulse recognizer. Defaults keep the PR #43 thresholds that the team already reviewed;
/// only the filter time constant and the decision structure changed. Each change is listed in the spec.
struct GyroPulseConfiguration: Equatable {
    /// Longest step integrated in one sample (s).
    var maxStep = 0.05
    /// A gap longer than this resets the detector (s).
    var maxGap = 0.15
    /// Low-latency filter time constant on the rotation rate (s). PR #43 used 0.045.
    var filterTimeConstant = 0.02
    /// An excursion starts when the twist rate rises above this (rad/s) while the detector is armed.
    var startRate = 1.0
    /// An excursion ends when the twist rate falls below this (rad/s). Hysteresis against `startRate`.
    var endRate = 0.5
    /// The phone counts as calm below this rate (rad/s), for settling and re-arming.
    var calmRate = 0.35
    /// The excursion peak must reach this (rad/s, about 126 degrees/s).
    var peakRate = 2.2
    /// The turn (integral of |rate| over the excursion, rad) must reach this, about 32 degrees.
    var minTurn = 0.55
    /// Excursion duration, from the start crossing to the end (s).
    var minDuration = 0.12
    var maxDuration = 0.45
    /// The share of the rotation in the twist direction, at the peak, must reach this.
    var minDominance = 0.75
    /// Acceleration evidence: a user acceleration at or above this (g) rejects the excursion as a shake or a
    /// translation. Shipped at 1.5 g: a vigorous flick alone produces about 1.2 g at the accelerometer.
    var maxUserAcceleration = 1.5
    /// Confirmation window after the excursion has passed every rule (s). During it, a reversal of at least
    /// `shakeAmplitude` times the peak, or a user acceleration at the limit, rejects the excursion as oscillation.
    /// Chosen on the development seeds: 0.03 s removed the hand-shake and mixed-motion false flips with no loss of
    /// recognition, and kept p95 latency near 220 ms. Longer windows add latency without further gain. Zero disables.
    var confirmWindow = 0.03
    /// A reversal this large, as a fraction of the peak, inside the confirmation window marks oscillation.
    var shakeAmplitude = 0.5
    /// After an accepted flick: at least this long (s) ...
    var cooldown = 1.2
    /// ... and calm (below `rearmRate`) for this long (s) before the next excursion can start.
    var rearmRate = 0.35
    var rearmCalm = 0.30
    /// After a rejected excursion or a reset: calm for this long (s) before arming.
    var calmTime = 0.15
    /// Turns the twist axis within the device's y-z plane (radians). See GyroFlipConfiguration.axisTilt.
    var axisTilt = 0.0

    static let initial = GyroPulseConfiguration()

    /// The values the app ships with: the PR #43 shake limit (1.5 g) and the shared thresholds above.
    static let shipped = GyroPulseConfiguration()
}

struct GyroPulseDetector {
    enum Phase: Equatable {
        /// Waiting for a calm phone before the detector can arm. Where a fresh or reset detector starts.
        case settling
        /// Armed: watching for an excursion to start.
        case armed
        /// An excursion is under way and being measured.
        case candidate
        /// The excursion passed its rules; waiting out the confirmation window for oscillation.
        case confirming
        /// A flip was just requested. Return strokes are logged and ignored until the cooldown and calm rules pass.
        case cooldown
    }

    /// Why the last excursion ended, for the owner-tools readout. It never influences a decision.
    enum Outcome: Equatable {
        case none
        case flipped
        case rejected(String)
    }

    var configuration: GyroPulseConfiguration
    var twistAxis: GyroTwistAxis
    /// Off means no processing at all: samples are ignored and state is cleared.
    var isEnabled = true
    private(set) var phase: Phase = .settling
    private(set) var lastOutcome: Outcome = .none
    /// The last few gestures, oldest first, using the same record as PR #43 so the readout is unchanged.
    private(set) var history: [GyroFlipDetector.GestureRecord] = []
    static let historyLimit = GyroFlipDetector.historyLimit

    /// Read-only live values for the owner-tools readout.
    var filteredRate: GyroVector { filtered }
    var candidateAngle: Double { turn }
    var candidatePeak: Double { peak }
    var currentTwistRate: Double { projected(filtered) }
    var currentDominance: Double { abs(projected(filtered)) / max(0.001, filtered.magnitude) }
    /// Seconds from the peak of the most recent flip to the flip itself, for the trace and the readout.
    private(set) var lastLatency: Double?

    private var hasLast = false
    private var lastTimestamp: TimeInterval = 0
    private var filtered = GyroVector.zero
    private var startTime: TimeInterval = 0
    private var peakTime: TimeInterval = 0
    private var triggerTime: TimeInterval = 0
    private var turn = 0.0
    private var peak = 0.0
    private var peakSign = 0.0
    /// The filtered rotation vector at the peak. The flip direction comes from its dominant device axis.
    private var peakVector = GyroVector.zero
    private var confirmDeadline: TimeInterval = 0
    private var dominanceAtPeak = 0.0
    private var accelerationPeak = 0.0
    private var calm = 0.0
    /// For `.yz`: the unit twist direction fixed when an excursion starts.
    private var planeY = 0.0
    private var planeZ = 0.0
    /// Direction of an excursion for the single-axis modes (+1 or -1), fixed at its start.
    private var axisSign = 0.0
    private var lastMissedTime = -10.0
    private var lastIgnoredTime = -10.0

    init(configuration: GyroPulseConfiguration = .shipped, twistAxis: GyroTwistAxis = .yz) {
        self.configuration = configuration
        self.twistAxis = twistAxis
    }

    /// Clears every trace of earlier samples. Same callers as GyroFlipDetector.reset().
    mutating func reset() {
        hasLast = false
        lastTimestamp = 0
        filtered = .zero
        phase = .settling
        startTime = 0
        peakTime = 0
        triggerTime = 0
        turn = 0
        peak = 0
        peakSign = 0
        peakVector = .zero
        confirmDeadline = 0
        dominanceAtPeak = 0
        accelerationPeak = 0
        calm = 0
        planeY = 0
        planeZ = 0
        axisSign = 0
    }

    /// The rate that decides arming and calm: the plane magnitude for `.yz`, otherwise the signed axis rate.
    private func armingRate(_ v: GyroVector) -> Double {
        switch twistAxis {
        case .x: return v.x
        case .y: return axisRate(v)
        case .z: return v.z
        case .yz: return (v.y * v.y + v.z * v.z).squareRoot()
        }
    }

    private func axisRate(_ v: GyroVector) -> Double {
        let t = configuration.axisTilt
        return t == 0 ? v.y : v.y * cos(t) + v.z * sin(t)
    }

    /// The rate used while an excursion is measured: signed along the direction fixed at its start.
    private func projected(_ v: GyroVector) -> Double {
        // Signed along the excursion's direction while it is measured and while it is being confirmed.
        let measuring = phase == .candidate || phase == .confirming
        switch twistAxis {
        case .yz:
            if measuring { return v.y * planeY + v.z * planeZ }
            return (v.y * v.y + v.z * v.z).squareRoot()
        default:
            if measuring, axisSign != 0 { return abs(armingRate(v)) * axisSign }
            return armingRate(v)
        }
    }

    /// The flip direction: the sense of rotation about the device axis that dominates the peak. About the long axis
    /// it is the right edge turning away (+) or toward (-), whatever the grip angle. Near the screen normal it follows
    /// the screen-normal sense. Projecting onto a canonical axis instead inverts the direction for some grips.
    private func direction(of v: GyroVector) -> GyroFlipDirection {
        let sign: Double
        switch twistAxis {
        case .x: sign = v.x
        case .y: sign = axisRate(v)
        case .z: sign = v.z
        case .yz:
            let plane = (v.y * v.y + v.z * v.z).squareRoot()
            sign = abs(v.y) >= 0.2 * plane ? v.y : v.z
        }
        return sign >= 0 ? .positive : .negative
    }

    private func axisDescription() -> String {
        switch twistAxis {
        case .x: return "x"
        case .y: return "y"
        case .z: return "z"
        case .yz: return "y\(String(format: "%.2f", planeY)) z\(String(format: "%.2f", planeZ))"
        }
    }

    private mutating func record(_ outcome: String, peak: Double, turn: Double, duration: Double,
                                 acceleration: Double, latency: Double? = nil) {
        history.append(GyroFlipDetector.GestureRecord(outcome: outcome, peak: peak, angle: abs(turn),
                                                      duration: max(0, duration), acceleration: acceleration,
                                                      axis: axisDescription(), latency: latency))
        if history.count > Self.historyLimit { history.removeFirst(history.count - Self.historyLimit) }
    }

    /// A twist-like motion that arrived while the detector was not armed. At most one per half second.
    private mutating func recordMissed(_ why: String, at time: TimeInterval, rate: Double, acceleration: Double) {
        guard time - lastMissedTime > 0.5 else { return }
        lastMissedTime = time
        record("missed: \(why)", peak: abs(rate), turn: 0, duration: 0, acceleration: acceleration)
    }

    /// A return stroke during cooldown, logged as part of the same gesture. At most one per half second.
    private mutating func recordIgnored(at time: TimeInterval, rate: Double, acceleration: Double) {
        guard time - lastIgnoredTime > 0.5 else { return }
        lastIgnoredTime = time
        record("ignored: return stroke", peak: abs(rate), turn: 0, duration: 0, acceleration: acceleration)
    }

    /// Ends the current excursion as rejected, with the reason, and resets the measurements.
    private mutating func endExcursion(rejected reason: String, to next: Phase, now: TimeInterval) {
        lastOutcome = .rejected(reason)
        record("rejected: \(reason)", peak: peak, turn: turn, duration: now - startTime, acceleration: accelerationPeak)
        phase = next
        turn = 0
        peak = 0
        peakSign = 0
        dominanceAtPeak = 0
        accelerationPeak = 0
        calm = 0
    }

    /// Emits the flip for the excursion that just passed, and starts the cooldown.
    private mutating func acceptFlick(now t: TimeInterval, duration: Double) -> GyroFlipDirection {
        let direction = direction(of: peakVector)
        let latency = t - peakTime
        lastLatency = latency
        lastOutcome = .flipped
        record(direction == .positive ? "FLIP +" : "FLIP -", peak: peak, turn: turn, duration: duration,
               acceleration: accelerationPeak, latency: latency)
        phase = .cooldown
        triggerTime = t
        turn = 0
        peak = 0
        peakSign = 0
        peakVector = .zero
        dominanceAtPeak = 0
        accelerationPeak = 0
        calm = 0
        return direction
    }

    /// Feeds one sample. `suppressed` is true while anything else owns the card (a touch or drag, a sheet, a
    /// flip still settling, Reduce Motion, an inactive scene). Returns a direction at most once per gesture.
    @discardableResult
    mutating func ingest(_ sample: GyroSample, suppressed: Bool = false) -> GyroFlipDirection? {
        guard isEnabled else {
            if hasLast || phase != .settling { reset() }
            return nil
        }
        let c = configuration
        guard sample.timestamp.isFinite, sample.rotationRate.isFinite, sample.userAcceleration.isFinite else {
            reset()
            return nil
        }

        let gap = hasLast ? sample.timestamp - lastTimestamp : 0
        var step = 0.0
        if !hasLast || gap <= 0 || gap > c.maxGap {
            // First sample, a repeated or backwards timestamp, or a dropout: re-seed the filter and drop any
            // excursion that was being measured. The measured dt is the only time base used.
            filtered = sample.rotationRate
            hasLast = true
            lastTimestamp = sample.timestamp
            if phase == .candidate {
                endExcursion(rejected: "dropout", to: .settling, now: sample.timestamp)
            }
        } else {
            step = min(max(gap, 0), c.maxStep)
            lastTimestamp = sample.timestamp
            let alpha = 1 - exp(-step / c.filterTimeConstant)
            filtered.x += alpha * (sample.rotationRate.x - filtered.x)
            filtered.y += alpha * (sample.rotationRate.y - filtered.y)
            filtered.z += alpha * (sample.rotationRate.z - filtered.z)
        }

        let t = sample.timestamp
        let acceleration = sample.userAcceleration.magnitude
        let armed = armingRate(filtered)
        let dominance = abs(armed) / max(0.001, filtered.magnitude)

        switch phase {
        case .settling:
            calm = armed < c.calmRate ? calm + step : 0
            if calm >= c.calmTime {
                phase = .armed
                calm = 0
            }
            return nil

        case .armed:
            if suppressed { return nil }
            guard armed > c.startRate, dominance >= c.minDominance else { return nil }
            if acceleration >= c.maxUserAcceleration {
                recordMissed("shake, \(String(format: "%.1f", acceleration)) g", at: t, rate: armed, acceleration: acceleration)
                return nil
            }
            // An excursion starts. Fix its direction now: for `.yz` the unit vector in the plane, larger
            // component positive, so a left and a right twist have opposite signs; for one axis, the sign of
            // the rate.
            phase = .candidate
            startTime = t
            peakTime = t
            turn = 0
            peak = 0
            peakSign = 0
            dominanceAtPeak = 0
            accelerationPeak = acceleration
            if twistAxis == .yz {
                let r = max(armed, 0.001)
                var uy = filtered.y / r
                var uz = filtered.z / r
                let flip = abs(uy) >= abs(uz) ? (uy < 0) : (uz < 0)
                if flip { uy = -uy; uz = -uz }
                planeY = uy
                planeZ = uz
            } else {
                axisSign = armed > 0 ? 1 : -1
            }
            return nil

        case .candidate:
            let age = t - startTime
            accelerationPeak = max(accelerationPeak, acceleration)
            if suppressed {
                endExcursion(rejected: "touch or sheet", to: .settling, now: t)
                return nil
            }
            if acceleration >= c.maxUserAcceleration {
                endExcursion(rejected: "shake \(String(format: "%.1f", acceleration)) g", to: .settling, now: t)
                return nil
            }
            let p = projected(filtered)
            let share = abs(p) / max(0.001, filtered.magnitude)
            turn += abs(p) * step
            if abs(p) > peak {
                peak = abs(p)
                peakTime = t
                peakSign = p >= 0 ? 1 : -1
                peakVector = filtered
                dominanceAtPeak = share
            }
            if age > c.maxDuration {
                endExcursion(rejected: "too long", to: .settling, now: t)
                return nil
            }
            // The excursion ends when the rate falls below `endRate`, or when it reverses while still above it.
            // A reversal inside one excursion is an oscillation (a shake), and sampling at 60 Hz can skip the
            // narrow band near zero where a shake crosses, so the reversal is the end. A return stroke after a real
            // flick starts only once the rate has fallen below `endRate`, so it is never seen here.
            let reversed = p * peakSign < 0
            guard abs(p) < c.endRate || reversed else { return nil }

            // The excursion has ended. Decide from the measured features; a pass starts the confirmation window.
            let reason: String?
            if peak < c.peakRate {
                reason = "too weak, peak \(String(format: "%.1f", peak))"
            } else if turn < c.minTurn {
                reason = "too small, turn \(String(format: "%.2f", turn))"
            } else if age < c.minDuration {
                reason = "too brief, \(String(format: "%.2f", age)) s"
            } else if dominanceAtPeak < c.minDominance {
                reason = "wrong axis (share \(String(format: "%.2f", dominanceAtPeak)))"
            } else {
                reason = nil
            }
            if let reason {
                endExcursion(rejected: reason, to: .settling, now: t)
                return nil
            }
            if c.confirmWindow > 0 {
                phase = .confirming
                confirmDeadline = t + c.confirmWindow
                return nil
            }
            return acceptFlick(now: t, duration: age)

        case .confirming:
            let p = projected(filtered)
            if suppressed {
                endExcursion(rejected: "touch or sheet", to: .settling, now: t)
                return nil
            }
            if acceleration >= c.maxUserAcceleration {
                endExcursion(rejected: "shake \(String(format: "%.1f", acceleration)) g", to: .settling, now: t)
                return nil
            }
            if p * peakSign < 0, abs(p) >= c.shakeAmplitude * peak {
                endExcursion(rejected: "oscillation, reversal \(String(format: "%.1f", abs(p))) rad/s", to: .settling, now: t)
                return nil
            }
            if t >= confirmDeadline {
                return acceptFlick(now: t, duration: confirmDeadline - startTime)
            }
            return nil

        case .cooldown:
            if abs(armed) > c.startRate, dominance >= c.minDominance {
                recordIgnored(at: t, rate: armed, acceleration: acceleration)
            }
            calm = abs(armed) < c.rearmRate ? calm + step : 0
            if t - triggerTime >= c.cooldown && calm >= c.rearmCalm {
                phase = .armed
                calm = 0
            }
            return nil
        }
    }
}
