import Foundation

// MARK: - Synthetic motion corpus for A/B replay
//
// Deterministic traces for comparing the PR #43 classifier (GyroFlipDetector) with the pulse recognizer
// (GyroPulseDetector) on identical input. SYNTHETIC: these models are assumptions about how a wrist moves and how
// an iPhone's gyroscope and accelerometer respond. They are useful for regression and for seeing where each
// detector breaks. They are NOT evidence of accuracy on a real iPhone. Physical targets stay NOT RUN until the
// calibration procedure in the spec has been run with recordings from a device.
//
// Two seed ranges are used on purpose. Development seeds (1...) are for choosing defaults. Held-out seeds (9000...)
// are reported and never used to tune. A default must not be picked on the held-out range.

/// Tiny deterministic generator, so a trace is identical on every machine and every run.
struct CorpusRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(1 << 53)
    }
    mutating func range(_ lo: Double, _ hi: Double) -> Double { lo + (hi - lo) * next() }
    /// Approximate standard normal, sum of uniforms.
    mutating func gauss(_ sigma: Double) -> Double {
        var s = 0.0
        for _ in 0..<6 { s += next() }
        return (s - 3) * sigma * 1.414
    }
}

/// One generated trial. `expected` lists the flips a correct detector should produce, in order.
struct CorpusTrial {
    var family: String
    var samples: [GyroSample]
    var expected: [GyroFlipDirection]
    /// Seconds (from the first sample) of the main excursion's peak, for latency. Empty for ordinary motion.
    var peakTimes: [Double]
    /// Main excursion parameters, for the sensitivity grid.
    var angle: Double
    var duration: Double
    var returnStroke: Bool
}

enum CorpusFamily: String, CaseIterable {
    case naturalPositive = "natural flick +"
    case naturalNegative = "natural flick -"
    case slowTilt = "slow tilt"
    case quickTilt = "quick tilt to face"
    case tremor = "hand tremor"
    case walking = "walking sway"
    case handShake = "hand shake"
    case pickUp = "pick up / reposition"
    case quickWiggle = "quick small wiggle"
    case pitchWithLeak = "pitch with twist leak"
    case setDown = "set-down tap"
}

/// Builds trials. Times are seconds from the first sample. Sampling is nominally 60 Hz with jitter; dropouts,
/// gyroscope noise and a small lift wobble are added to every trial.
enum Corpus {
    static let nominalHz = 60.0

    /// Sample times: nominal 60 Hz, each interval jittered by up to +/-15 %, and 3 % of samples dropped.
    static func times(seconds: Double, rng: inout CorpusRandom) -> [Double] {
        var out: [Double] = []
        var t = 0.0
        while t <= seconds {
            if rng.next() > 0.03 { out.append(t) }
            t += (1.0 / nominalHz) * rng.range(0.85, 1.15)
        }
        return out
    }

    static func minJerk(_ t: Double, duration: Double, angle: Double) -> Double {
        guard t >= 0, t <= duration else { return 0 }
        let s = t / duration
        return 30 * angle / duration * s * s * (1 - s) * (1 - s)
    }

    /// A deliberate flick about the long axis tilted toward the screen normal by `grip` radians, with an optional
    /// return stroke. The main excursion is a minimum-jerk bell of `angle` radians over `duration` seconds.
    static func naturalFlick(seed: UInt64, index: Int, sign: Double, angle: Double, duration: Double,
                             returnStroke: Bool) -> CorpusTrial {
        var rng = CorpusRandom(seed: seed &+ UInt64(index) &* 7919)
        let total = 4.0
        let lead = rng.range(1.0, 2.0)
        let grip = rng.range(0, Double.pi / 3) * (rng.next() < 0.5 ? 1 : -1)
        let (uy, uz) = (cos(grip), sin(grip))
        let returnStart = lead + duration + rng.range(0.1, 0.3)
        let returnAmplitude = rng.range(0.2, 0.5) * angle
        let returnDuration = rng.range(0.2, 0.3)
        let times = Self.times(seconds: total, rng: &rng)
        let wobblePhase = rng.range(0, 6.28)
        let wobbleHz = rng.range(1, 3)
        let noise = 0.02
        var samples: [GyroSample] = []
        samples.reserveCapacity(times.count)
        for t in times {
            var main = minJerk(t - lead, duration: duration, angle: angle * sign)
            if returnStroke {
                main += minJerk(t - returnStart, duration: returnDuration, angle: -returnAmplitude * sign)
            }
            let wobble = 0.12 * sin(2 * .pi * wobbleHz * t + wobblePhase)
            let accel = (t > lead && t < lead + duration)
                ? 0.5 + 0.6 * sin(.pi * (t - lead) / duration) : 0
            samples.append(GyroSample(
                timestamp: 1000 + t,
                rotationRate: GyroVector(x: wobble + rng.gauss(noise),
                                         y: uy * main + rng.gauss(noise),
                                         z: uz * main + rng.gauss(noise)),
                userAcceleration: GyroVector(x: accel + rng.gauss(0.02), y: rng.gauss(0.02), z: rng.gauss(0.02))))
        }
        return CorpusTrial(family: sign > 0 ? CorpusFamily.naturalPositive.rawValue : CorpusFamily.naturalNegative.rawValue,
                           samples: samples,
                           expected: [sign > 0 ? .positive : .negative],
                           peakTimes: [lead + duration / 2],
                           angle: angle, duration: duration, returnStroke: returnStroke)
    }

    /// Ordinary movement that must not flip the card.
    static func ordinary(_ family: CorpusFamily, seed: UInt64, index: Int) -> CorpusTrial {
        var rng = CorpusRandom(seed: seed &+ UInt64(index) &* 104729 &+ UInt64(CorpusFamily.allCases.firstIndex(of: family) ?? 0))
        let total = 8.0
        let times = Self.times(seconds: total, rng: &rng)
        let axisY = rng.range(0.3, 1), axisZ = rng.range(0.3, 1)
        var samples: [GyroSample] = []
        samples.reserveCapacity(times.count)
        // Build the family's rate and acceleration as functions of time.
        let rateAt: (Double) -> GyroVector
        let accelAt: (Double) -> GyroVector
        switch family {
        case .slowTilt:
            let start = rng.range(1, 4), dur = rng.range(1.0, 2.5)
            let amp = rng.range(0.3, 1.2)
            let axis = Int(rng.range(0, 2.99))
            rateAt = { t in
                let r = minJerk(t - start, duration: dur, angle: amp)
                return axis == 0 ? GyroVector(x: r, y: 0, z: 0) : (axis == 1 ? GyroVector(x: 0, y: r, z: 0) : GyroVector(x: 0, y: axisY * r, z: axisZ * r))
            }
            accelAt = { _ in .zero }
        case .quickTilt:
            // Raising the phone to the face is mostly a pitch about the device x axis, with some leak into the
            // twist plane. It is not a twist, so the dominance rule should keep it out.
            let start = rng.range(1, 4), dur = rng.range(0.4, 0.7)
            let amp = rng.range(0.5, 1.2)
            let sign = rng.next() < 0.5 ? 1.0 : -1.0
            let leak = rng.range(0.1, 0.3)
            rateAt = { t in
                let pitch = sign * minJerk(t - start, duration: dur, angle: amp)
                return GyroVector(x: pitch, y: leak * pitch, z: 0)
            }
            accelAt = { t in t > start && t < start + dur ? GyroVector(x: 0.2, y: 0, z: 0) : .zero }
        case .tremor:
            let hz = rng.range(6, 10), amp = rng.range(0.2, 0.5), ph = rng.range(0, 6.28)
            rateAt = { t in GyroVector(x: 0, y: amp * sin(2 * .pi * hz * t + ph), z: amp * 0.6 * sin(2 * .pi * hz * t)) }
            accelAt = { _ in .zero }
        case .walking:
            let hz = rng.range(1.8, 2.3), amp = rng.range(0.6, 1.1), ph = rng.range(0, 6.28)
            rateAt = { t in GyroVector(x: 0.2 * sin(2 * .pi * hz * t), y: amp * sin(2 * .pi * hz * t + ph), z: 0.5 * amp * sin(2 * .pi * hz * t + 1)) }
            accelAt = { t in GyroVector(x: 0.3 * sin(2 * .pi * hz * t), y: 0, z: 0.6 * sin(4 * .pi * hz * t)) }
        case .handShake:
            let hz = rng.range(3, 6), amp = rng.range(3, 9), ph = rng.range(0, 6.28)
            let dirY = rng.range(-1, 1), dirZ = rng.range(-1, 1)
            let start = rng.range(1, 3), dur = rng.range(0.8, 2.0)
            let peakAcc = rng.range(0.8, 2.4)
            rateAt = { t in
                let on = t > start && t < start + dur ? 1.0 : 0.0
                let s = on * amp * sin(2 * .pi * hz * t + ph)
                return GyroVector(x: 0, y: dirY * s, z: dirZ * s)
            }
            accelAt = { t in
                let on = t > start && t < start + dur ? 1.0 : 0.0
                return GyroVector(x: on * peakAcc * abs(sin(2 * .pi * hz * t)), y: 0, z: 0)
            }
        case .pickUp:
            let start = rng.range(1, 3), dur = rng.range(0.5, 0.8)
            let liftRate = rng.range(1.0, 2.5)
            let transl = rng.range(0.6, 1.4)
            rateAt = { t in
                let lift = minJerk(t - start, duration: dur, angle: liftRate * dur / 1.875)
                return GyroVector(x: lift, y: 0.3 * lift, z: 0)
            }
            accelAt = { t in t > start + 0.1 && t < start + 0.1 + 0.4 ? GyroVector(x: 0, y: 0, z: transl) : .zero }
        case .quickWiggle:
            // A quick, small wrist wiggle: about 10 to 20 degrees, fast enough to reach the peak requirement.
            let start = rng.range(1, 3), dur = rng.range(0.12, 0.22)
            let amp = rng.range(0.15, 0.35)
            let sign = rng.next() < 0.5 ? 1.0 : -1.0
            let grip = rng.range(-0.4, 0.4)
            rateAt = { t in
                let r = sign * minJerk(t - start, duration: dur, angle: amp)
                return GyroVector(x: 0, y: r * cos(grip), z: r * sin(grip))
            }
            accelAt = { t in t > start && t < start + dur ? GyroVector(x: 0.15, y: 0, z: 0) : .zero }
        case .pitchWithLeak:
            // Raising the phone while it also rolls: mostly about x, with a leak into the twist plane that can exceed
            // the start rate.
            let start = rng.range(1, 3), dur = rng.range(0.25, 0.5)
            let amp = rng.range(0.6, 1.2)
            let sign = rng.next() < 0.5 ? 1.0 : -1.0
            let leak = rng.range(0.5, 0.8)
            rateAt = { t in
                let pitch = sign * minJerk(t - start, duration: dur, angle: amp)
                return GyroVector(x: pitch, y: leak * pitch, z: 0)
            }
            accelAt = { t in t > start && t < start + dur ? GyroVector(x: 0.3, y: 0, z: 0) : .zero }
        case .setDown:
            // Putting the phone down: a sharp linear knock with little rotation.
            let start = rng.range(1, 3)
            let knock = rng.range(1.0, 1.6)
            rateAt = { t in GyroVector(x: 0.2 * sin(2 * .pi * 20 * (t - start)) * (t > start && t < start + 0.05 ? 1 : 0), y: 0, z: 0) }
            accelAt = { t in t > start && t < start + 0.03 ? GyroVector(x: 0, y: 0, z: knock) : .zero }
        case .naturalPositive, .naturalNegative:
            fatalError("use naturalFlick")
        }
        for t in times {
            let r = rateAt(t), a = accelAt(t)
            samples.append(GyroSample(timestamp: 1000 + t,
                                      rotationRate: GyroVector(x: r.x + rng.gauss(0.02), y: r.y + rng.gauss(0.02), z: r.z + rng.gauss(0.02)),
                                      userAcceleration: GyroVector(x: a.x + rng.gauss(0.02), y: a.y + rng.gauss(0.02), z: a.z + rng.gauss(0.02))))
        }
        return CorpusTrial(family: family.rawValue, samples: samples, expected: [], peakTimes: [],
                           angle: 0, duration: 0, returnStroke: false)
    }

    /// The natural flick grid used for the sensitivity table: total angle (rad) and duration (s) bins.
    static let angleBins: [(String, ClosedRange<Double>)] = [("0.35-0.5", 0.35...0.5), ("0.5-0.7", 0.5...0.7),
                                                             ("0.7-0.9", 0.7...0.9), ("0.9-1.2", 0.9...1.2)]
    static let durationBins: [(String, ClosedRange<Double>)] = [("0.12-0.20", 0.12...0.20), ("0.20-0.30", 0.20...0.30),
                                                                ("0.30-0.40", 0.30...0.40)]
}

// MARK: - Replay

/// Anything that turns samples into flip directions, so both detectors run through one harness.
protocol FlipRecognizer {
    mutating func feed(_ sample: GyroSample) -> GyroFlipDirection?
    var name: String { get }
    /// Seconds from the peak to the flip for the most recent flip, if known.
    var latency: Double? { get }
    /// The recognizer's own log of finished gestures (outcome strings), for the rejection-reason tally.
    var outcomes: [String] { get }
}

struct BaselineRecognizer: FlipRecognizer {
    var detector = GyroFlipDetector(configuration: .shipped, twistAxis: .yz)
    var name: String { "PR #43 classifier" }
    var latency: Double? { nil }
    var outcomes: [String] { detector.history.map { $0.outcome } }
    mutating func feed(_ sample: GyroSample) -> GyroFlipDirection? { detector.ingest(sample) }
}

struct PulseRecognizer: FlipRecognizer {
    var detector: GyroPulseDetector
    init(_ configuration: GyroPulseConfiguration = .shipped) {
        detector = GyroPulseDetector(configuration: configuration, twistAxis: .yz)
    }
    var name: String { "pulse recognizer" }
    var latency: Double? { detector.lastLatency }
    var outcomes: [String] { detector.history.map { $0.outcome } }
    mutating func feed(_ sample: GyroSample) -> GyroFlipDirection? { detector.ingest(sample) }
}

struct ReplayResult {
    var events: [(time: Double, direction: GyroFlipDirection)]
    var latencies: [Double]
}

/// Runs one trial through a recognizer, in order, and records each event with its time from the first sample.
func replay<R: FlipRecognizer>(_ trial: CorpusTrial, _ recognizer: inout R) -> ReplayResult {
    var events: [(time: Double, direction: GyroFlipDirection)] = []
    var latencies: [Double] = []
    let origin = trial.samples.first?.timestamp ?? 0
    for s in trial.samples {
        if let d = recognizer.feed(s) {
            events.append((s.timestamp - origin, d))
            if let l = recognizer.latency { latencies.append(l) }
        }
    }
    return ReplayResult(events: events, latencies: latencies)
}

/// Percentile of a list (nearest rank), or nil when empty.
func percentile(_ values: [Double], _ p: Double) -> Double? {
    guard !values.isEmpty else { return nil }
    let sorted = values.sorted()
    let rank = Int((p * Double(sorted.count)).rounded(.up)) - 1
    return sorted[max(0, min(sorted.count - 1, rank))]
}
