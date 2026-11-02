import SwiftUI

// MARK: - Gyro Flip: the app side of the detector
//
// `GyroFlipDetector` (a pure file) decides what a twist is. This controller owns one detector for one
// open Inspector, subscribes it to the single shared MotionField feed, applies the suppression rules and,
// when a twist qualifies, calls the SAME `FlipMotor.flip(direction:)` that a tap or drag uses.
//
// It publishes nothing: no sample is ever observable UI state. The only output is the flip. (The owner-tools
// readout pulls a snapshot ten times a second; nothing is pushed, stored or sent.)
// Motion values are processed on this iPhone, transiently, and never stored or sent anywhere.

enum GyroFlipSettings {
    /// `@AppStorage` key for the switch in View & Style. Default On.
    static let enabledKey = "arooma.gyroFlipEnabled"

    /// The one place that decides whether the motion subscription may run. It reads UserDefaults directly, at
    /// the moment of use, instead of trusting a view's `@AppStorage` copy: on the Simulator an Inspector opened
    /// after the switch was turned Off still came up listening, because the copy it read said On.
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }
}

/// Wrist-flip values the owner can change live (Tuning panel, group "Wrist flip"). The defaults are the plan's
/// values except the twist axis (long axis or screen normal) and the shake limit (1.5 g), changed after the
/// first physical-iPhone report. They exist because the thresholds and the axis were hypotheses.
enum GyroTuning {
    /// 0 = x, 1 = y (the long axis), 2 = z (the screen normal), 3 = the long axis or the screen normal.
    static var axis = 3.0
    /// Leans the long axis toward the screen normal, in degrees (a twist is rarely exactly about one axis).
    static var axisTiltDegrees = 0.0
    static var startRate = GyroFlipConfiguration.initial.startRate
    static var peakRate = GyroFlipConfiguration.initial.peakRate
    static var minDominance = GyroFlipConfiguration.initial.minDominance
    static var minAngle = GyroFlipConfiguration.initial.minAngle
    static var maxDuration = GyroFlipConfiguration.initial.maxDuration
    static var maxAcceleration = GyroFlipConfiguration.shipped.maxUserAcceleration
    static var cooldown = GyroFlipConfiguration.shipped.cooldown

    static var configuration: GyroFlipConfiguration {
        var c = GyroFlipConfiguration.shipped
        c.startRate = startRate
        // The candidate is abandoned below half the start rate (the plan's 1.0 and 0.5).
        c.endRate = startRate * 0.5
        c.peakRate = peakRate
        c.minDominance = minDominance
        c.minAngle = minAngle
        c.maxDuration = maxDuration
        c.maxUserAcceleration = maxAcceleration
        c.cooldown = cooldown
        c.axisTilt = axisTiltDegrees * Double.pi / 180
        return c
    }

    static var twistAxis: GyroTwistAxis {
        axis < 0.5 ? .x : (axis < 1.5 ? .y : (axis < 2.5 ? .z : .yz))
    }
}

/// Owner-tools readout of what the detector sees. Plain values, never stored or sent.
struct GyroDiagnostics {
    var listening = false
    var samples = 0
    var rate = GyroVector.zero
    var twistRate = 0.0
    var dominance = 0.0
    var peakTwist = 0.0
    var phase = ""
    var outcome = ""
    var blocked = ""
    /// The last few gestures, oldest first.
    var history: [GyroFlipDetector.GestureRecord] = []
}

@MainActor
final class GyroFlipController {
    private var detector = GyroFlipDetector()
    private var sampleCount = 0
    private var peakTwist = 0.0
    private var peakTwistTime = 0.0
    private weak var flip: FlipMotor?
    private(set) var isListening = false
    private var qaTask: Task<Void, Never>?

    // Suppression inputs. The Inspector keeps these current; any one of them blocks a motion flip.
    // Manual flipping (tap, drag, VoiceOver) is never affected by them.
    var reduceMotion = false
    var sceneActive = true
    /// A finger is on the card, or a drag is under way.
    var touching = false
    /// A sheet (edit, photo, Compare, system share) is over the Inspector.
    var covered = false

    func attach(_ flip: FlipMotor) { self.flip = flip }

    /// Starts listening. Takes a MotionField reference (the sensor runs while we listen, subject to its
    /// Low Power, thermal and foreground rules) and registers as the single raw-sample subscriber.
    func start() {
        guard !isListening else { return }
        isListening = true
        detector.reset()
        reloadTuning()
        sampleCount = 0
        peakTwist = 0
        MotionField.shared.acquire()
        MotionField.shared.setRawSink { [weak self] sample in
            self?.feed(sample)
        }
    }

    /// Stops listening and drops all state. With the setting Off this leaves zero extra work behind.
    func stop() {
        qaTask?.cancel()
        qaTask = nil
        guard isListening else { return }
        isListening = false
        MotionField.shared.setRawSink(nil)
        MotionField.shared.release()
        detector.reset()
    }

    /// Clears the detector without stopping: selection change, scene change, a cancelled gesture.
    func resetDetector() { detector.reset() }

    /// Picks up the owner's Tuning values (axis, thresholds). A no-op for an untouched build.
    func reloadTuning() {
        detector.configuration = GyroTuning.configuration
        detector.twistAxis = GyroTuning.twistAxis
    }

    func snapshot() -> GyroDiagnostics {
        var d = GyroDiagnostics()
        d.listening = isListening
        d.samples = sampleCount
        d.rate = detector.filteredRate
        d.twistRate = detector.currentTwistRate
        d.dominance = detector.currentDominance
        d.peakTwist = peakTwist
        switch detector.phase {
        case .needsCalm: d.phase = "waiting for calm"
        case .idle: d.phase = "armed"
        case .candidate: d.phase = "measuring"
        case .cooldown: d.phase = "cooldown"
        }
        switch detector.lastOutcome {
        case .none: d.outcome = "-"
        case .flipped: d.outcome = "FLIPPED"
        case .rejected(let why): d.outcome = "rejected: \(why)"
        }
        // Worked out only when the readout asks, never per sample.
        var reasons: [String] = []
        if reduceMotion { reasons.append("reduce-motion") }
        if !sceneActive { reasons.append("scene") }
        if touching { reasons.append("touch") }
        if covered { reasons.append("sheet") }
        if flip?.model.isAnimating ?? false { reasons.append("flipping") }
        d.blocked = reasons.isEmpty ? "-" : reasons.joined(separator: ",")
        d.history = detector.history
        return d
    }

    /// Feeds one sample. Called from MotionField's handler, or by the QA bridge.
    func feed(_ sample: GyroSample) {
        guard isListening else { return }
        let animating = flip?.model.isAnimating ?? false
        let suppressed = reduceMotion || !sceneActive || touching || covered || animating
        if let direction = detector.ingest(sample, suppressed: suppressed) {
            flip?.flip(direction: direction.sign)
        }
        sampleCount += 1
        let twistNow = abs(detector.currentTwistRate)
        if twistNow >= peakTwist || sample.timestamp - peakTwistTime > 3 {
            peakTwist = twistNow
            peakTwistTime = sample.timestamp
        }
    }

    // MARK: QA bridge (Debug and TestFlight only)

    /// Replays a synthetic trace through `feed`, in real time, so a Simulator run (which has no gyroscope)
    /// can prove that an event reaches `FlipMotor` through the same detector and the same suppression rules.
    /// Never active unless `-AroomaQAGyroTrace <name>` is passed in a build that allows owner tools.
    func runQATrace(_ trace: GyroQATrace) {
        guard BuildChannel.allowsOwnerTools else { return }
        qaTask?.cancel()
        qaTask = Task { @MainActor [weak self] in
            for sample in trace.samples() {
                guard let self, !Task.isCancelled else { return }
                self.feed(sample)
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }
}

/// Synthetic motion for the QA bridge. 60 Hz, a 0.4 s still lead-in so the detector is armed, then the
/// gesture, then 0.9 s of stillness.
enum GyroQATrace: String {
    case twist, twistBack, shake, tilt

    static var requested: GyroQATrace? {
        guard BuildChannel.allowsOwnerTools,
              let raw = UserDefaults.standard.string(forKey: "AroomaQAGyroTrace") else { return nil }
        return GyroQATrace(rawValue: raw)
    }

    func samples() -> [GyroSample] {
        let hz = 60.0
        let lead = 0.4, tail = 0.9
        let gesture: Double
        switch self {
        case .twist, .twistBack, .tilt: gesture = 0.35
        case .shake: gesture = 0.8
        }
        let count = Int(((lead + gesture + tail) * hz).rounded())
        return (0...count).map { (i: Int) -> GyroSample in
            let t = Double(i) / hz
            let g = t - lead
            var rate = GyroVector.zero
            var accel = GyroVector.zero
            switch self {
            case .twist: rate.y = Self.minJerk(g, duration: gesture, angle: 0.8)
            case .twistBack: rate.y = Self.minJerk(g, duration: gesture, angle: -0.8)
            case .tilt: rate.x = Self.minJerk(g, duration: gesture, angle: 0.8)
            case .shake:
                if g > 0 && g < gesture {
                    rate.y = 8 * sin(2 * .pi * 4 * g)
                    accel.x = 1.6 * sin(2 * .pi * 4 * g + 1)
                }
            }
            return GyroSample(timestamp: 5000 + t, rotationRate: rate, userAcceleration: accel)
        }
    }

    /// Minimum-jerk angular velocity: a smooth bell turning through `angle` radians in `duration` seconds.
    private static func minJerk(_ t: Double, duration: Double, angle: Double) -> Double {
        guard t >= 0, t <= duration else { return 0 }
        let s = t / duration
        return 30 * angle / duration * s * s * (1 - s) * (1 - s)
    }
}

// MARK: - Settings row (View & Style, Card lighting)

enum MotionHUDSettings {
    static let key = "arooma.motionHUD"
}

/// Owner tools only (Debug and TestFlight): a small monospaced readout of the motion feed and, inside the
/// Inspector, of what the wrist-flip detector sees. It exists to answer "is the sensor running, and what
/// does a real twist look like" on a physical iPhone. Never shown in an App Store build.
struct MotionHUD: View {
    var gyro: GyroFlipController?
    @AppStorage(MotionHUDSettings.key) private var on = false

    var body: some View {
        if BuildChannel.allowsOwnerTools && on {
            TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                let m = MotionField.shared.diagnostics()
                let age: String = m.sampleAge.map { f($0) + "s" } ?? "-"
                let running: String = m.running ? "RUNNING" : "STOPPED"
                VStack(alignment: .leading, spacing: 1) {
                    Text("motion \(running)  users \(m.users)  sample age \(age)")
                    Text("sensor \(yn(m.sensorAvailable))  foreground \(yn(m.foreground))  low power \(yn(m.lowPower))  thermal \(m.thermal)")
                    Text("foil tilt x \(f(m.tilt.x))  y \(f(m.tilt.y))")
                    if let gyro {
                        let g = gyro.snapshot()
                        let listening: String = g.listening ? "LISTENING" : "off"
                        Text("wrist flip \(listening)  samples \(g.samples)  \(g.phase)")
                        Text("rad/s  x \(f(g.rate.x))  y \(f(g.rate.y))  z \(f(g.rate.z))")
                        Text("twist \(f(g.twistRate))  axis share \(f(g.dominance))  peak 3s \(f(g.peakTwist))")
                        Text("last \(g.outcome)  blocked by \(g.blocked)")
                        Text("recent gestures, newest first (pk rad/s, ang rad, dur s, acc g)")
                            .foregroundStyle(.secondary)
                        if g.history.isEmpty {
                            Text("none yet: flick the phone")
                        }
                        ForEach(Array(g.history.suffix(5).reversed().enumerated()), id: \.offset) { _, r in
                            Text("\(r.outcome)  pk \(f1(r.peak)) ang \(f2(r.angle)) dur \(f2(r.duration)) acc \(f1(r.acceleration)) \(r.axis)")
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                    }
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }

    private func f(_ v: Double) -> String { String(format: "%+.2f", v) }
    private func f1(_ v: Double) -> String { String(format: "%.1f", v) }
    private func f2(_ v: Double) -> String { String(format: "%.2f", v) }
    private func yn(_ v: Bool) -> String { v ? "yes" : "NO" }
}

/// "Flip cards with wrist twist". When the device has no motion sensor the row explains that instead of
/// showing a switch that cannot work. The holographic foil is a separate feature and is never affected.
struct GyroFlipSettingRow: View {
    @AppStorage(GyroFlipSettings.enabledKey) private var enabled = true
    @AppStorage(MotionHUDSettings.key) private var showReadout = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Low Power Mode switches the motion sensor off (card foil and wrist flip alike). Saying so here stops a
    /// working feature from looking broken.
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if lowPower {
                Label("Low Power Mode is on, so card foil and wrist flip are paused. Turn it off to use them.",
                      systemImage: "battery.25percent")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("low-power-note")
            }
            if MotionField.shared.isSensorAvailable {
                Toggle("Flip cards with wrist twist", isOn: $enabled)
                    .font(.subheadline)
                    .accessibilityIdentifier("gyro-flip-toggle")
                Text(reduceMotion
                     ? "Paused while Reduce Motion is on. Tap or drag still turns a card over."
                     : "Turn an open card over by twisting your iPhone left or right. Tap or drag always works too.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Label("Wrist-twist flipping needs the motion sensor, which is not available right now. Tap or drag still turns a card over.",
                      systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("gyro-flip-unavailable")
            }
            Text("Motion readings stay on this iPhone. They are used as they arrive, only to light the foil and, if this is on, to flip an open card. They are never stored or sent.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            if BuildChannel.allowsOwnerTools {
                Toggle("Show motion readout (owner tools)", isOn: $showReadout)
                    .font(.footnote)
                    .accessibilityIdentifier("motion-readout-toggle")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.NSProcessInfoPowerStateDidChange)) { _ in
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }
}
