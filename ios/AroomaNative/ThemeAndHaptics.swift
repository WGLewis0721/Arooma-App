import SwiftUI
import CoreHaptics

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
enum HapticCue { case selection, wear, completed }

/// Direct Core Haptics; simulator and devices without a haptic engine silently skip.
@MainActor final class HapticEngine {
    static let shared = HapticEngine()
    private var engine: CHHapticEngine?
    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let newEngine = try CHHapticEngine()
            newEngine.isAutoShutdownEnabled = true
            newEngine.resetHandler = { [weak newEngine] in
                try? newEngine?.start()
            }
            engine = newEngine
            try newEngine.start()
        } catch { engine = nil }
    }
    func play(_ cue: HapticCue) {
        guard let engine else { return }
        let intensity: Float
        let sharpness: Float
        switch cue {
        case .selection: intensity = 0.25; sharpness = 0.65
        case .wear: intensity = 0.58; sharpness = 0.45
        case .completed: intensity = 0.4; sharpness = 0.7
        }
        do {
            let event = CHHapticEvent(eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ], relativeTime: 0)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            try engine.start()
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch { /* An app must still operate with System Haptics off. */ }
    }
}
