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
    static let remoteVideo = URL(string: "https://d2ol7oe51mr4n9.cloudfront.net/user_3IkKBBXHZvEZQt2d8pBaRYd083T/c8178739-0924-4668-a8d2-52449cfc34b0.mp4")!
    static var video: URL {
        Bundle.main.url(forResource: "creed-aventus-live-card", withExtension: "mp4") ?? remoteVideo
    }
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
                Image(uiImage: poster).resizable().scaledToFill()
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
            if isPlaying && !reduceMotion && scenePhase == .active {
                AventusLoopingVideo()
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
    func makeUIView(context: Context) -> AventusVideoLayerView {
        let view = AventusVideoLayerView()
        view.start()
        return view
    }
    func updateUIView(_ uiView: AventusVideoLayerView, context: Context) {
        uiView.start()
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

    func start() {
        if queue == nil {
            let player = AVQueuePlayer()
            player.isMuted = true
            player.allowsExternalPlayback = false
            let item = AVPlayerItem(url: AventusScentWorldMedia.video)
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
