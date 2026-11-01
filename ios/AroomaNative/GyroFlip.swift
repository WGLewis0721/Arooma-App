import SwiftUI

// MARK: - Gyro Flip: the app side of the detector
//
// `GyroFlipDetector` (a pure file) decides what a twist is. This controller owns one detector for one
// open Inspector, subscribes it to the single shared MotionField feed, applies the suppression rules and,
// when a twist qualifies, calls the SAME `FlipMotor.flip(direction:)` that a tap or drag uses.
//
// It publishes nothing: no sample is ever observable UI state. The only output is the flip.
// Motion values are processed on this iPhone, transiently, and never stored or sent anywhere.

enum GyroFlipSettings {
    /// `@AppStorage` key. Default On, with the conservative filters in `GyroFlipConfiguration`.
    static let enabledKey = "arooma.gyroFlipEnabled"
}

@MainActor
final class GyroFlipController {
    private var detector = GyroFlipDetector()
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

    /// Feeds one sample. Called from MotionField's handler, or by the QA bridge.
    func feed(_ sample: GyroSample) {
        guard isListening else { return }
        let animating = flip?.model.isAnimating ?? false
        let suppressed = reduceMotion || !sceneActive || touching || covered || animating
        if let direction = detector.ingest(sample, suppressed: suppressed) {
            flip?.flip(direction: direction.sign)
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

/// "Flip cards with wrist twist". When the device has no motion sensor the row explains that instead of
/// showing a switch that cannot work. The holographic foil is a separate feature and is never affected.
struct GyroFlipSettingRow: View {
    @AppStorage(GyroFlipSettings.enabledKey) private var enabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        }
    }
}
