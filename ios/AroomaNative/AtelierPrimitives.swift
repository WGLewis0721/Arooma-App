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


// MARK: - The physical collectible
//
// A card is drawn as an object: opaque art (never altered), an optional optical layer (live GPU
// foil on the hero, a cheap static sheen elsewhere), Lambert shading from its angle to the light,
// a rim catch-light, a visible edge thickness that shows as it turns, and a contact shadow that
// widens and softens as the card lifts off the table.

enum FoilMode: Equatable { case none, sheen, live }

struct AtelierCardSurface: View {
    @EnvironmentObject private var archive: CollectionStore
    let fragranceID: String
    var side: CardSide = .front
    var radius: CGFloat = 14
    var selected = false
    /// Rotation about the vertical axis the card is drawn at (degrees), for lighting only.
    var yaw: Double = 0
    /// 0 resting on the table ... 1 lifted under the finger.
    var lift: Double = 0
    /// Extra darkening from distance / depth.
    var shade: Double = 0
    var foil: FoilMode? = nil
    var foilStrength: Double = 1
    /// How much the card leans toward device tilt (0 = none, 1 = hero).
    var lean: Double = 0
    var shadowed = true

    var body: some View {
        let mode = foil ?? (selected ? .live : .none)
        let fragrance = archive.fragrance(id: fragranceID)
        let photo = fragrance.flatMap { archive.photoURL(for: $0) }
        let theme = archive.theme
        let facing = cos(yaw * .pi / 180)
        let lambert = min(0.62, shade + (1 - max(0, facing)) * 0.5)
        CardFace(fragranceID: fragranceID, fragrance: fragrance, photoURL: photo, side: side, radius: radius)
            .equatable()
            .modifier(FoilLayer(mode: mode, strength: foilStrength, yaw: yaw, radius: radius, tint: theme.keyLight))
            .overlay {
                if lambert > 0.004 {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(Color.black.opacity(lambert))
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                // Catch-light along the edge facing the key light.
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [
                            .white.opacity(0.34 + 0.2 * lift),
                            .white.opacity(0.04),
                            .white.opacity(0.12)
                        ], startPoint: UnitPoint(x: 0.5 - yaw / 120, y: 0), endPoint: UnitPoint(x: 0.5 + yaw / 120, y: 1)),
                        lineWidth: 0.8
                    )
                    .allowsHitTesting(false)
            }
            .background {
                // Edge thickness: visible when the card is turned or lifted.
                RoundedRectangle(cornerRadius: radius + 0.6, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x2A2620), Color(hex: 0x0E0F14)],
                                         startPoint: .top, endPoint: .bottom))
                    .offset(x: sin(yaw * .pi / 180) * 3.4 + 0.5, y: 1.8 + lift * 1.2)
            }
            .background {
                if shadowed {
                    Image(uiImage: ShadowSprite.image)
                        .resizable()
                        .foregroundStyle(theme.shadowTint)
                        .scaleEffect(x: ShadowSprite.overscan.width * (0.94 + 0.06 * lift),
                                     y: ShadowSprite.overscan.height * (0.96 + 0.04 * lift))
                        .opacity(0.78 - 0.18 * lift)
                        .offset(x: -yaw * 0.12, y: 10 + 18 * lift)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .modifier(TiltLean(amount: lean))
            .accessibilityLabel(fragrance.map { "\($0.house) \($0.name), \(side == .front ? "front" : "reverse")" } ?? "Collectible")
    }
}

/// Art only. Equatable so 120 Hz pose changes never rebuild or re-decode the image.
struct CardFace: View, Equatable {
    let fragranceID: String
    let fragrance: Fragrance?
    let photoURL: URL?
    let side: CardSide
    let radius: CGFloat

    var body: some View {
        Group {
            if let photoURL, let picture = OwnerPhotoCache.image(at: photoURL) {
                ZStack(alignment: .bottomLeading) {
                    Color(hex: 0x14161D)
                    GeometryReader { bounds in
                        Image(uiImage: picture)
                            .resizable().scaledToFill()
                            .frame(width: bounds.size.width, height: bounds.size.height)
                            .clipped()
                    }
                    if side == .front {
                        VStack(alignment: .leading, spacing: 3) {
                            Text((fragrance?.house ?? "").uppercased())
                                .font(.system(size: 9, weight: .semibold)).tracking(1.4)
                            Text(fragrance?.name ?? "")
                                .font(.system(size: 19, weight: .regular, design: .serif))
                                .lineLimit(2)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(13)
                        .background(LinearGradient(colors: [.clear, .black.opacity(0.84)],
                                                   startPoint: .top, endPoint: .bottom))
                    } else {
                        PersonalReverse(fragrance: fragrance)
                    }
                }
                .aspectRatio(59.0 / 86.0, contentMode: .fit)
            } else if let fragrance, fragrance.id.hasPrefix("personal-") {
                if side == .front { PersonalCardArt(fragrance: fragrance) }
                else { PersonalReverse(fragrance: fragrance) }
            } else {
                // Original photographic card master; the optical layer never changes it.
                CollectibleCard(id: fragranceID, side: side, cornerRadius: radius)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Personal discoveries get a composed, archival card of their own instead of a placeholder.
struct PersonalCardArt: View {
    let fragrance: Fragrance
    private static let inks: [(Color, Color)] = [
        (Color(hex: 0x1A2133), Color(hex: 0x3D2C44)),
        (Color(hex: 0x1C2A26), Color(hex: 0x3B4B3F)),
        (Color(hex: 0x2B1C22), Color(hex: 0x5A3436)),
        (Color(hex: 0x221E2E), Color(hex: 0x45385A))
    ]
    private var ink: (Color, Color) {
        let seed = fragrance.id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return Self.inks[seed % Self.inks.count]
    }
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                LinearGradient(colors: [ink.0, ink.1], startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [Color(hex: 0xE9CF9A).opacity(0.22), .clear],
                               center: .init(x: 0.7, y: 0.25), startRadius: 2, endRadius: w * 0.9)
                RoundedRectangle(cornerRadius: w * 0.045, style: .continuous)
                    .strokeBorder(Color(hex: 0xD8B877).opacity(0.65), lineWidth: max(0.6, w * 0.004))
                    .padding(w * 0.055)
                Text(String(fragrance.name.prefix(1)).uppercased())
                    .font(.system(size: w * 0.56, weight: .light, design: .serif))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xF3DDAA), Color(hex: 0xA77F45)],
                                                    startPoint: .top, endPoint: .bottom))
                    .opacity(0.88)
                    .offset(y: -w * 0.12)
                VStack(alignment: .leading, spacing: w * 0.02) {
                    Text("PERSONAL ARCHIVE")
                        .font(.system(size: max(6, w * 0.032), weight: .semibold))
                        .tracking(w * 0.008)
                        .foregroundStyle(Color(hex: 0xD8B877))
                    Spacer()
                    Text(fragrance.house.uppercased())
                        .font(.system(size: max(6, w * 0.036), weight: .semibold))
                        .tracking(w * 0.006)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                    Text(fragrance.name)
                        .font(.system(size: max(9, w * 0.085), weight: .regular, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(w * 0.1)
            }
        }
        .aspectRatio(59.0 / 86.0, contentMode: .fit)
    }
}

struct PersonalReverse: View {
    let fragrance: Fragrance?
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Color(hex: 0x15161E)
                RoundedRectangle(cornerRadius: w * 0.045, style: .continuous)
                    .strokeBorder(Color(hex: 0xD8B877).opacity(0.5), lineWidth: max(0.6, w * 0.004))
                    .padding(w * 0.055)
                VStack(spacing: w * 0.04) {
                    Text("Arooma")
                        .font(.custom("Snell Roundhand", size: w * 0.16))
                        .foregroundStyle(Color(hex: 0xD8B877))
                    Text((fragrance?.name ?? "").uppercased())
                        .font(.system(size: max(6, w * 0.035), weight: .semibold))
                        .tracking(w * 0.008)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, w * 0.12)
                    Text("Notes to be discovered")
                        .font(.system(size: max(7, w * 0.045), design: .serif))
                        .italic()
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .aspectRatio(59.0 / 86.0, contentMode: .fit)
    }
}

/// Chooses the optical channel without changing view identity as strength varies.
private struct FoilLayer: ViewModifier {
    let mode: FoilMode
    let strength: Double
    let yaw: Double
    let radius: CGFloat
    let tint: Color
    func body(content: Content) -> some View {
        switch mode {
        case .live:
            content.modifier(LiveFoil(strength: strength, yaw: yaw, radius: radius, tint: tint))
        case .sheen:
            content.overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(stops: [
                        .init(color: .clear, location: 0.18),
                        .init(color: tint.opacity(0.13), location: 0.42),
                        .init(color: .white.opacity(0.10), location: 0.5),
                        .init(color: .clear, location: 0.7)
                    ], startPoint: UnitPoint(x: 0 - yaw / 90, y: 0), endPoint: UnitPoint(x: 1 - yaw / 90, y: 1)))
                    .blendMode(.screen)
                    .allowsHitTesting(false)
            }
        case .none:
            content
        }
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
