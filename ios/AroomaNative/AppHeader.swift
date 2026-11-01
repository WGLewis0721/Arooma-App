import SwiftUI

// MARK: - The Arooma signature in the app's top-left header
//
// The approved calligraphic signature (the committed AroomaSignature master, never a font or a
// redrawn path) returns to the upper left of the three primary screens, with its warm-gold sheen
// looping for as long as the app is in the foreground and the mark is on screen.
//
// It is branding, not navigation: no menu, no gesture and no link is attached to it. VoiceOver reads
// "Arooma" once, as a header; the animation never changes what it announces.
//
// Motion: `AroomaSignatureShimmer` already pauses when the scene is not active (no catch-up flash on
// return) and shows the readable static gold signature under Reduce Motion. Here it is also capped to
// 30 redraws a second, which is plenty for a six-second sweep across a small wordmark.

struct AroomaBrandMark: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.colorScheme) private var scheme
    /// Height of the signature. About 32 pt keeps the strokes clearly readable and the mark well below
    /// the collectible card in visual weight.
    var height: CGFloat = 32

    var body: some View {
        AroomaSignatureShimmer(ink: archive.theme.ink(scheme),
                               highlight: archive.theme.keyLight,
                               minimumInterval: 1.0 / 30.0)
            .frame(width: height * SignatureGeometry.logoAspect, height: height)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Arooma")
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("arooma-brand-header")
    }
}
