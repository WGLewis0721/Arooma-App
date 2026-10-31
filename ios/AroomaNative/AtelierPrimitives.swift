import SwiftUI
import CoreMotion
import UIKit

// MARK: - Atelier material direction
// The photographic collectible is the content. Glass appears only on floating controls.
struct AtelierAtmosphere: View {
    let theme: FragranceTheme
    @Environment(\.colorScheme) private var scheme

    private var colors: [Color] {
        if scheme == .light {
            switch theme {
            case .obsidian: return [Color(hex: 0xF2EEE7), Color(hex: 0xD8D4D1), Color(hex: 0xE8DFD5)]
            case .ivory: return [Color(hex: 0xF6EFDF), Color(hex: 0xDCC9AC), Color(hex: 0xF0E5D5)]
            case .violet: return [Color(hex: 0xF3EDF3), Color(hex: 0xDCD2DF), Color(hex: 0xECE0E8)]
            case .emerald: return [Color(hex: 0xF0F1E9), Color(hex: 0xCDD8CE), Color(hex: 0xE4E7DE)]
            }
        }
        switch theme {
        case .obsidian: return [Color(hex: 0x1B2233), Color(hex: 0x312735), Color(hex: 0x171925)]
        case .ivory: return [Color(hex: 0x292321), Color(hex: 0x54412C), Color(hex: 0x1D1E21)]
        case .violet: return [Color(hex: 0x24213A), Color(hex: 0x403049), Color(hex: 0x1A1B2C)]
        case .emerald: return [Color(hex: 0x182B29), Color(hex: 0x2A433C), Color(hex: 0x162222)]
        }
    }
    var body: some View {
        GeometryReader { bounds in
            ZStack {
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Ellipse()
                    .fill(theme.palette.accent.opacity(scheme == .light ? 0.13 : 0.16))
                    .frame(width: bounds.size.width * 1.3, height: bounds.size.height * 0.46)
                    .blur(radius: 95)
                    .offset(x: bounds.size.width * 0.18, y: -bounds.size.height * 0.17)
                Ellipse()
                    .fill(colors[1].opacity(0.47))
                    .frame(width: bounds.size.width * 1.15, height: bounds.size.height * 0.54)
                    .blur(radius: 95)
                    .offset(x: -bounds.size.width * 0.23, y: bounds.size.height * 0.41)
            }
            .frame(width: bounds.size.width, height: bounds.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct AtelierEyebrow: View {
    let text: String
    let accent: Color
    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption2, design: .default, weight: .semibold))
            .tracking(2.1)
            .foregroundStyle(accent)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .accessibilityAddTraits(.isHeader)
    }
}

struct AtelierDisplay: View {
    let title: String
    var size: CGFloat = 32
    var body: some View {
        Text(title)
            .font(.system(size: size, weight: .regular, design: .serif))
            .tracking(-0.75)
            .lineLimit(2)
            .minimumScaleFactor(0.72)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }
}

struct AtelierPlate: ViewModifier {
    let radius: CGFloat
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(scheme == .dark ? Color.white.opacity(0.065) : Color.white.opacity(0.37))
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(.primary.opacity(scheme == .dark ? 0.095 : 0.075), lineWidth: 0.65)
            }
    }
}
extension View {
    func atelierPlate(_ radius: CGFloat = 19) -> some View { modifier(AtelierPlate(radius: radius)) }
}


// One shared sensor feed, only while the interactive gallery is visible.
@MainActor final class FoilMotion: ObservableObject {
    static let shared = FoilMotion()
    @Published var x: CGFloat = 0
    @Published var y: CGFloat = 0
    private let sensor = CMMotionManager()
    private init() {}
    func start() {
        guard sensor.isDeviceMotionAvailable, !sensor.isDeviceMotionActive,
              !ProcessInfo.processInfo.isLowPowerModeEnabled else { return }
        sensor.deviceMotionUpdateInterval = 1.0 / 24.0
        sensor.startDeviceMotionUpdates(to: .main) { [weak self] sample, _ in
            guard let sample else { return }
            Task { @MainActor in
                self?.x = CGFloat(max(-1, min(1, sample.attitude.roll / 0.75)))
                self?.y = CGFloat(max(-1, min(1, sample.attitude.pitch / 0.75)))
            }
        }
    }
    func stop() { if sensor.isDeviceMotionActive { sensor.stopDeviceMotionUpdates() } }
}

struct AtelierCardSurface: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var foil = FoilMotion.shared
    let fragranceID: String
    var side: CardSide = .front
    var radius: CGFloat = 14
    var selected = false

    var body: some View {
        ZStack {
            if let fragrance = archive.fragrance(id: fragranceID),
               let path = archive.photoURL(for: fragrance),
               let picture = UIImage(contentsOfFile: path.path) {
                GeometryReader { bounds in
                    Image(uiImage: picture)
                        .resizable().scaledToFill()
                        .frame(width: bounds.size.width, height: bounds.size.height)
                        .clipped()
                }
                .aspectRatio(59.0 / 86.0, contentMode: .fit)
                .overlay(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(fragrance.house.uppercased())
                            .font(.system(size: 9, weight: .semibold)).tracking(1.4)
                        Text(fragrance.name)
                            .font(.system(size: 19, weight: .regular, design: .serif))
                            .lineLimit(2)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(13)
                    .background(LinearGradient(colors: [.clear, .black.opacity(0.87)],
                                               startPoint: .top, endPoint: .bottom))
                }
                .clipShape(RoundedRectangle(cornerRadius: radius))
            } else if let fragrance = archive.fragrance(id: fragranceID),
                      fragrance.id.hasPrefix("personal-") {
                RoundedRectangle(cornerRadius: radius)
                    .fill(LinearGradient(colors: [Color(hex: 0x232939), Color(hex: 0x493749)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .aspectRatio(59.0 / 86.0, contentMode: .fit)
                    .overlay {
                        VStack(spacing: 13) {
                            Image(systemName: "sparkles.rectangle.stack").font(.largeTitle)
                            Text(fragrance.name).font(.system(.title3, design: .serif))
                                .multilineTextAlignment(.center).padding(.horizontal, 9)
                            Text("PERSONAL COLLECTION").font(.system(size: 9)).tracking(1)
                        }
                        .foregroundStyle(.white.opacity(0.92))
                    }
            } else {
                // Original photographic card master is never changed by the foil overlay.
                CollectibleCard(id: fragranceID, side: side, cornerRadius: radius)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: radius + 0.7, style: .continuous)
                .fill(Color(hex: 0x171A20))
                .offset(x: 1.6, y: 3)
        }
        .overlay {
            if selected {
                TimelineView(.animation(minimumInterval: 1.0 / 12.0, paused: reduceMotion)) { clock in
                    let phase = reduceMotion ? 0 : sin(clock.date.timeIntervalSinceReferenceDate * 0.67)
                    let angle = Double(foil.x * 72) + phase * 8
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(AngularGradient(
                            colors: [
                                .white.opacity(0.22),
                                Color.cyan.opacity(0.35),
                                Color.purple.opacity(0.48),
                                Color.yellow.opacity(0.56),
                                .white.opacity(0.55),
                                Color.blue.opacity(0.37),
                                .white.opacity(0.14)
                            ],
                            center: .center,
                            angle: .degrees(angle)),
                            lineWidth: 2.6)
                        .overlay {
                            RoundedRectangle(cornerRadius: radius - 2, style: .continuous)
                                .strokeBorder(.white.opacity(0.055 + abs(foil.y) * 0.14 + abs(phase) * 0.015),
                                              lineWidth: 0.8)
                                .padding(3)
                        }
                }
                .allowsHitTesting(false)
            }
        }
        .shadow(color: .black.opacity(selected ? 0.32 : 0.17),
                radius: selected ? 27 : 14, x: selected ? foil.x * 7 : 0,
                y: selected ? 20 + foil.y * 4 : 10)
        .accessibilityLabel("Collectible \(fragranceID)")
    }
}

struct AtelierCapsule: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .padding(.horizontal, 3)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(.primary.opacity(0.18), lineWidth: 1))
        } else {
            content.glassEffect(.regular, in: Capsule())
        }
    }
}
extension View {
    func atelierGlass() -> some View { modifier(AtelierCapsule()) }
}

struct AtelierModePicker: View {
    @Binding var selected: CardLayout
    let accent: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        HStack(spacing: 2) {
            ForEach(CardLayout.allCases) { mode in
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.39, dampingFraction: 0.86)) {
                        selected = mode
                    }
                } label: {
                    Label(mode.rawValue, systemImage: mode.symbol)
                        .labelStyle(.titleAndIcon)
                        .font(.system(.caption, weight: selected == mode ? .semibold : .regular))
                        .foregroundStyle(selected == mode ? accent : .primary.opacity(0.8))
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected == mode ? .isSelected : [])
            }
        }
        .padding(4)
        .atelierGlass()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Card presentation")
    }
}

struct AtelierEmptyState: View {
    let title: String
    let detail: String
    let action: String
    let callback: () -> Void
    let accent: Color
    var body: some View {
        VStack(spacing: 19) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(accent)
            AtelierDisplay(title: title, size: 30)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
            Button(action, action: callback)
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .frame(minHeight: 48)
        }
        .padding(26)
    }
}
