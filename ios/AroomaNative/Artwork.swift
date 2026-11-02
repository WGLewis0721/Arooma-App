import UIKit
import SwiftUI
import AVFoundation

enum CardSide: String { case front, back }

/// No generated artwork and no image rewriting.
/// Loads the exact committed masters from the native app bundle and crops their known two-up midpoint.
enum ApprovedArtwork {
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        // 34 cards can otherwise retain hundreds of megabytes of decoded RGBA.
        cache.totalCostLimit = 96 * 1024 * 1024
        return cache
    }()
    private static let originals: [String:(name:String,folder:String)] = [
        "dior": ("dior-sauvage-elixir-original-diptych", "approved"),
        "hawas": ("rasasi-hawas-for-him-original-diptych", "approved"),
        "myslf": ("ysl-myslf-edp-original-diptych", "approved"),
        "prodigy": ("mind-games-prodigy-v2-original-diptych", "historical")
    ]
    static func image(for id: String, side: CardSide) -> UIImage? {
        let key = "\(id)-\(side.rawValue)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        if id == "aventus" {
            // The poster is the same exact first frame as the moving card.
            // It also powers previews, ambient lighting, exports and Reduce Motion.
            return side == .front ? AventusScentWorldMedia.poster : nil
        }
        if id.hasPrefix("fall2026-") {
            guard side == .front,
                  let card = Fall2026Collection.entry(for: id),
                  let original = Fall2026Collection.artwork(for: card) else { return nil }
            let decoded = original.preparingForDisplay() ?? original
            let cost = (decoded.cgImage?.bytesPerRow ?? 0) * (decoded.cgImage?.height ?? 0)
            cache.setObject(decoded, forKey: key, cost: cost)
            return decoded
        }
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
        cache.setObject(image, forKey: key, cost: cropped.bytesPerRow * cropped.height)
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
            if id == "aventus" && side == .front {
                LiveAventusScentWorldCard(isPlaying: false)
            } else if let image = ApprovedArtwork.image(for: id, side: side) {
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


// MARK: - Animated Scent World (Creed Aventus)
//
// The motion is an actual 8-second AI-generated video, NOT a Photoshop/SwiftUI
// displacement effect. It sits below the deck's existing Metal foil and physics.
// Only the focused front card plays. Flip, background, Reduce Motion or leaving
// the gallery pause playback. The offline bundled video is preferred; a URL is a
// development fallback if the video has not been ingested into the bundle yet.

private enum AventusScentWorldMedia {
    // Bundle-first, offline-only. No network fetches inside an animation frame.
    static let video: URL? = Bundle.main.url(forResource: "creed-aventus-live-card", withExtension: "mp4")
    static let poster: UIImage? = {
        guard let file = Bundle.main.url(forResource: "creed-aventus-live-card-poster", withExtension: "jpg") else { return nil }
        return UIImage(contentsOfFile: file.path)?.preparingForDisplay()
    }()
}

struct LiveAventusScentWorldCard: View {
    let isPlaying: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if let poster = AventusScentWorldMedia.poster {
                GeometryReader { bounds in
                    Image(uiImage: poster)
                        .resizable()
                        .scaledToFill()
                        .frame(width: bounds.size.width, height: bounds.size.height)
                        .clipped()
                }
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color(hex: 0x17131C), Color(hex: 0x71532D), Color(hex: 0x17131C)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                VStack(spacing: 7) {
                    Text("AROOMA").font(.caption.weight(.semibold)).tracking(3)
                    Spacer(minLength: 0)
                    Text("CREED").font(.system(size: 20, design: .serif)).tracking(3)
                    Text("AVENTUS").font(.system(size: 29, design: .serif)).tracking(2)
                    Text("SCENT WORLD").font(.caption2).tracking(2)
                }
                .foregroundStyle(Color(hex: 0xEDD5A1))
                .padding(16)
            }
            // The AVPlayer is not mounted for cards outside the focused deck slot.
            if isPlaying && !reduceMotion && scenePhase == .active,
               let videoURL = AventusScentWorldMedia.video {
                AventusLoopingVideo(url: videoURL)
                    .allowsHitTesting(false) // Keep tap, drag and flip gestures native.
            }
        }
        .aspectRatio(59.0 / 86.0, contentMode: .fit)
        .clipped()
        .accessibilityLabel("Creed Aventus, animated Scent World")
        .accessibilityHint(reduceMotion ? "Animation paused due to Reduce Motion" : "Animated sunrise and fragrant landscape in a collectible card")
    }
}

private struct AventusLoopingVideo: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> AventusVideoLayerView {
        let view = AventusVideoLayerView()
        view.start(url: url)
        return view
    }
    func updateUIView(_ uiView: AventusVideoLayerView, context: Context) {
        uiView.start(url: url)
    }
    static func dismantleUIView(_ uiView: AventusVideoLayerView, coordinator: ()) {
        uiView.stop()
    }
}

private final class AventusVideoLayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var queue: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        (layer as? AVPlayerLayer)?.videoGravity = .resizeAspectFill
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func start(url: URL) {
        if queue == nil {
            let player = AVQueuePlayer()
            player.isMuted = true
            player.allowsExternalPlayback = false
            let item = AVPlayerItem(url: url)
            looper = AVPlayerLooper(player: player, templateItem: item)
            queue = player
            (layer as? AVPlayerLayer)?.player = player
        }
        queue?.play()
    }
    func stop() {
        queue?.pause()
        (layer as? AVPlayerLayer)?.player = nil
        looper?.disableLooping()
        looper = nil
        queue = nil
    }
    deinit { queue?.pause() }
}


// A proper reverse, never a generic unavailable-art tile or an invented rarity.
struct AventusScentWorldReverse: View {
    let fragrance: Fragrance?
    private let gold = Color(hex: 0xE9C68C)

    var body: some View {
        GeometryReader { geometry in
            let unit = geometry.size.width / 720
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x24212A), Color(hex: 0x171923), Color(hex: 0x30251F)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                RoundedRectangle(cornerRadius: 24 * unit, style: .continuous)
                    .strokeBorder(gold.opacity(0.86), lineWidth: max(0.8, 3 * unit))
                    .padding(22 * unit)
                RoundedRectangle(cornerRadius: 20 * unit, style: .continuous)
                    .strokeBorder(gold.opacity(0.35), lineWidth: max(0.5, unit))
                    .padding(34 * unit)
                VStack(alignment: .leading, spacing: 18 * unit) {
                    HStack {
                        Text("AROOMA").tracking(4 * unit)
                        Spacer()
                        Text("SCENT WORLD").tracking(2.5 * unit)
                    }
                    .font(.system(size: max(8, 21 * unit), weight: .medium))
                    .foregroundStyle(gold.opacity(0.9))
                    Spacer(minLength: 0)
                    Text(fragrance?.house.uppercased() ?? "CREED")
                        .font(.system(size: max(9, 27 * unit), weight: .semibold))
                        .tracking(4 * unit)
                        .foregroundStyle(gold)
                    Text(fragrance?.name ?? "Aventus")
                        .font(.system(size: max(23, 67 * unit), design: .serif))
                        .foregroundStyle(.white)
                    Text("EAU DE PARFUM  ·  2010")
                        .font(.system(size: max(8, 18 * unit), weight: .medium))
                        .tracking(1.4 * unit)
                        .foregroundStyle(gold.opacity(0.8))
                    Rectangle().fill(gold.opacity(0.6)).frame(height: max(0.5, 1.5 * unit))
                        .padding(.vertical, 18 * unit)
                    noteRow("TOP", fragrance?.top ?? ["Calabrian Bergamot", "Sicilian Lemon", "Blackcurrant Leaf"], unit: unit)
                    noteRow("HEART", fragrance?.heart ?? ["Pineapple", "Pink Pepper", "Jasmine"], unit: unit)
                    noteRow("BASE", fragrance?.base ?? ["Birch", "Patchouli", "Musk"], unit: unit)
                    Spacer(minLength: 0)
                    Text("A SCENT IMAGINED AS A LIVING WORLD")
                        .font(.system(size: max(8, 17 * unit), weight: .medium))
                        .tracking(1.8 * unit)
                        .foregroundStyle(gold.opacity(0.77))
                }
                .padding(60 * unit)
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .aspectRatio(59.0 / 86.0, contentMode: .fit)
    }

    private func noteRow(_ name: String, _ notes: [String], unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: max(4, 7 * unit)) {
            Text(name)
                .font(.system(size: max(9, 19 * unit), weight: .semibold))
                .tracking(3 * unit)
                .foregroundStyle(gold)
            Text(notes.joined(separator: "  ·  "))
                .font(.system(size: max(11, 25 * unit), design: .serif))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
