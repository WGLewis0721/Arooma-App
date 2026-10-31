import UIKit
import SwiftUI

enum CardSide: String { case front, back }

/// No generated artwork and no image rewriting.
/// Loads the exact committed masters from the native app bundle and crops their known two-up midpoint.
enum ApprovedArtwork {
    private static var cache = NSCache<NSString, UIImage>()
    private static let originals: [String:(name:String,folder:String)] = [
        "dior": ("dior-sauvage-elixir-original-diptych", "approved"),
        "hawas": ("rasasi-hawas-for-him-original-diptych", "approved"),
        "myslf": ("ysl-myslf-edp-original-diptych", "approved"),
        "prodigy": ("mind-games-prodigy-v2-original-diptych", "historical")
    ]
    static func image(for id: String, side: CardSide) -> UIImage? {
        let key = "\(id)-\(side.rawValue)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let source = originals[id],
              let url = Bundle.main.url(forResource: source.name, withExtension: "png", subdirectory: source.folder),
              let bitmap = UIImage(contentsOfFile: url.path)?.cgImage else { return nil }
        let half = bitmap.width / 2
        let rect = CGRect(x: side == .front ? 0 : half, y: 0,
                          width: side == .front ? half : bitmap.width - half, height: bitmap.height)
        guard let cropped = bitmap.cropping(to: rect) else { return nil }
        // Decode once, off the animation path: the first frame a card appears never stalls on
        // PNG inflation. Pixels are unchanged.
        let raw = UIImage(cgImage: cropped, scale: 1, orientation: .up)
        let image = raw.preparingForDisplay() ?? raw
        cache.setObject(image, forKey: key)
        return image
    }
}

struct CollectibleCard: View {
    let id: String
    var side: CardSide = .front
    var cornerRadius: CGFloat = 15
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Group {
            if let image = ApprovedArtwork.image(for: id, side: side) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .background(Color(hex: 0x13141D))
            } else {
                ZStack {
                    Color(hex: 0x171922)
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                            .font(.largeTitle)
                        Text("Artwork unavailable").font(.caption)
                    }.foregroundStyle(.white.opacity(0.8))
                }
                .aspectRatio(59.0/86.0, contentMode: .fit)
            }
        }
        .aspectRatio(59.0/86.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.6)
        }
        .accessibilityLabel("\(id), \(side.rawValue) collectible artwork")
    }
}
