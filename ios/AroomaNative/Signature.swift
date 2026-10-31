import SwiftUI
import UIKit

// MARK: - The Arooma signature
//
// Uses ONLY the committed master: AroomaSignature.imageset, the 1220×482 grayscale master
// (white ink on black), drawn as a luminance mask so the letterforms are the master's own pixels.
// No font, no redrawn path, no writing animation. The signature is fully legible at all times;
// its "life" is a slow metallic highlight travelling across the ink, masked to the letterforms.

enum SignatureGeometry {
    static let logoAspect: CGFloat = 1220.0 / 482.0
}

/// The exact master signature as an alpha mask.
struct SignatureMask: View {
    var body: some View {
        Image("AroomaSignature")
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .luminanceToAlpha()
    }
}

/// The canonical static signature, inked in any colour. Callers decide its accessibility label.
struct AroomaSignatureMark: View {
    var ink: Color
    var body: some View {
        Rectangle()
            .fill(ink)
            .mask { SignatureMask() }
            .aspectRatio(SignatureGeometry.logoAspect, contentMode: .fit)
            .accessibilityHidden(true)
    }
}

/// The living wordmark: the full signature, always legible, with a restrained metallic
/// highlight that glides across the ink and then rests off the letters before the next pass,
/// so the loop has no visible restart. Static with Reduce Motion or while the app is inactive.
struct AroomaSignatureShimmer: View {
    var ink: Color
    var highlight: Color = .white
    /// Seconds per cycle; the highlight travels for 60% of it and rests for the remainder.
    var period: Double = 6.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Ink with a faint vertical metallic falloff, like light across a pen stroke.
            Rectangle()
                .fill(LinearGradient(colors: [ink, ink.opacity(0.86), ink],
                                     startPoint: .top, endPoint: .bottom))
                .mask { SignatureMask() }
            if !reduceMotion {
                TimelineView(.animation(minimumInterval: nil, paused: scenePhase != .active)) { clock in
                    let t = clock.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period * 1000)
                    let phase = t.truncatingRemainder(dividingBy: period) / period
                    let travel = min(1, phase / 0.6)
                    let eased = travel * travel * (3 - 2 * travel)
                    GeometryReader { g in
                        // Band centre runs from fully left of the glyphs to fully right of them, so the wrap
                        // from the end of one pass to the start of the next is never visible.
                        let bandWidth = g.size.width * 0.28
                        let x = -bandWidth + eased * (g.size.width + bandWidth * 2)
                        LinearGradient(stops: [
                            .init(color: highlight.opacity(0), location: 0),
                            .init(color: highlight.opacity(0.55), location: 0.42),
                            .init(color: highlight.opacity(0.95), location: 0.5),
                            .init(color: highlight.opacity(0.55), location: 0.58),
                            .init(color: highlight.opacity(0), location: 1)
                        ], startPoint: .leading, endPoint: .trailing)
                        .frame(width: bandWidth, height: g.size.height * 1.8)
                        .rotationEffect(.degrees(16))
                        .position(x: x, y: g.size.height / 2)
                    }
                    .mask { SignatureMask() }
                    .blendMode(.plusLighter)
                }
                .allowsHitTesting(false)
            }
        }
        .aspectRatio(SignatureGeometry.logoAspect, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Full-screen replay from the options sheet: the living signature, dismissed by any tap.
struct SignatureReplay: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var archive: CollectionStore

    var body: some View {
        GeometryReader { geo in
            ZStack {
                AtelierAtmosphere(theme: archive.theme)
                AroomaSignatureShimmer(ink: archive.theme.palette.accent, highlight: archive.theme.keyLight)
                    .frame(width: min(geo.size.width * 0.84, 420))
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.45)
                Text("Tap to close")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .position(x: geo.size.width / 2, y: geo.size.height - 60)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Arooma")
        .accessibilityAddTraits(.isHeader)
        .accessibilityAction { dismiss() }
        .statusBarHidden()
    }
}
