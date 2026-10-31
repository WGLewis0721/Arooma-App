import SwiftUI
import CoreHaptics
import QuartzCore

struct ArchiveBackdrop: View {
    var theme: FragranceTheme
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let p = theme.palette
        ZStack {
            if scheme == .dark {
                LinearGradient(colors: [theme == .ivory ? Color(hex: 0x1B1A24) : p.field,
                                        Color(hex: 0x17131E), p.secondary.opacity(theme == .ivory ? 0.20 : 0.82)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [p.secondary.opacity(0.65), .clear],
                               center: .init(x: 0.64, y: 0.35), startRadius: 10, endRadius: 460)
            } else {
                LinearGradient(colors: [Color(hex: 0xF4EEE4), Color(hex: 0xEDE3D6),
                                        Color(hex: 0xDCCDBA)], startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [p.accent.opacity(0.07), .clear],
                               center: .init(x: 0.6, y: 0.38), startRadius: 15, endRadius: 430)
            }
        }.ignoresSafeArea()
    }
}

struct GalleryHeading: View {
    let text: String
    var body: some View {
        Text(text).font(.system(.largeTitle, design: .serif, weight: .regular))
            .tracking(-0.7)
            .minimumScaleFactor(0.7)
            .lineLimit(2)
    }
}

/// Only for floating controls. Never apply this to a card or the shelf contents.
struct FunctionalGlass: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var corner: CGFloat = 24
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: corner))
        } else {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: corner))
        }
    }
}
extension View {
    func controlGlass(corner: CGFloat = 24) -> some View {
        modifier(FunctionalGlass(corner: corner))
    }
}
enum HapticCue {
    /// A card came to rest in the centre slot after a user-driven move.
    case selection
    /// Same, scaled by how fast the card was travelling when released (0...~8 cards/s).
    case settle(speed: Double)
    /// The inspector card turned edge-on and the other face became visible.
    case flipEdge
    /// One wear (solo or layered) was logged.
    case wear
    /// A save, add, rename or delete finished.
    case completed
}

/// Arooma's tactile vocabulary, on Core Haptics. Every cue is short and discrete; nothing buzzes
/// continuously and nothing fires per frame. Devices without a haptic engine, and the simulator,
/// skip silently. The engine is prewarmed so the first cue is not late.
@MainActor final class HapticEngine {
    static let shared = HapticEngine()
    private var engine: CHHapticEngine?
    private var lastPlayed: [String: CFTimeInterval] = [:]
    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let newEngine = try CHHapticEngine()
            newEngine.isAutoShutdownEnabled = true
            newEngine.playsHapticsOnly = true
            newEngine.resetHandler = { [weak newEngine] in
                try? newEngine?.start()
            }
            engine = newEngine
            try newEngine.start()
        } catch { engine = nil }
    }

    private func transient(_ intensity: Float, _ sharpness: Float, at time: TimeInterval = 0) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        ], relativeTime: time)
    }

    func play(_ cue: HapticCue) {
        guard let engine else { return }
        var events: [CHHapticEvent] = []
        var curves: [CHHapticParameterCurve] = []
        let key: String
        switch cue {
        case .selection:
            key = "settle"
            events = [transient(0.32, 0.42)]
        case .settle(let speed):
            key = "settle"
            // A card set down gently is a soft tap; one thrown into place lands with more weight.
            let weight = Float(min(1, speed / 6))
            events = [transient(0.24 + 0.28 * weight, 0.30 + 0.15 * weight)]
        case .flipEdge:
            key = "flip"
            events = [transient(0.30, 0.92)]
        case .wear:
            key = "wear"
            // A stamp: firm strike, a short resonant decay, then a light confirming tap.
            events = [
                transient(0.78, 0.48),
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.36),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.18)
                ], relativeTime: 0.012, duration: 0.16),
                transient(0.36, 0.7, at: 0.2)
            ]
            curves = [CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
                .init(relativeTime: 0.012, value: 1.0),
                .init(relativeTime: 0.17, value: 0.0)
            ], relativeTime: 0)]
        case .completed:
            key = "completed"
            events = [transient(0.46, 0.68), transient(0.30, 0.8, at: 0.085)]
        }
        // Debounce identical cues (e.g. two settles inside one frame burst).
        let now = CACurrentMediaTime()
        if let last = lastPlayed[key], now - last < 0.06 { return }
        lastPlayed[key] = now
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            try engine.start()
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch { /* An app must still operate with System Haptics off. */ }
    }
}
