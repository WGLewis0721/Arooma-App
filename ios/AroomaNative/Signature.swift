import SwiftUI
import AVFoundation
import UIKit

// MARK: - The Arooma signature
//
// Uses ONLY the committed brand assets (assets/brand/AROOMA_SIGNATURE.md):
//   - AroomaSignature.imageset: the 1220×482 grayscale master (white ink on black). It is drawn
//     as a luminance mask filled with ink, so the letterforms are the master's own pixels.
//   - AroomaIntroInkLight.mp4 / AroomaIntroInkDark.mp4: the Higgsfield pen-writing clips.
// No font, no redrawn path, no generated animation.

enum SignatureGeometry {
    static let logoAspect: CGFloat = 1220.0 / 482.0
    static let videoAspect: CGFloat = 1280.0 / 720.0
    /// Where the master signature sits inside the clips' final frame, measured by fitting the
    /// master PNG to frame 89 of both clips (93% silhouette overlap): x 63, y 77, 1161×459 px of
    /// 1280×720. Placing the static master here makes the hand-off from video invisible.
    static let rectInVideo = CGRect(x: 63.0 / 1280.0, y: 77.0 / 720.0,
                                    width: 1161.0 / 1280.0, height: 459.0 / 720.0)

    /// Paper and ink colours sampled from the clips, so the screen around the video is seamless.
    static func paper(dark: Bool) -> Color { dark ? Color(hex: 0x171721) : Color(hex: 0xF1ECE0) }
    static func ink(dark: Bool) -> Color { dark ? Color(hex: 0xC5B6D5) : Color(hex: 0x261F1F) }
    static func paperUI(dark: Bool) -> UIColor {
        dark ? UIColor(red: 23 / 255, green: 23 / 255, blue: 33 / 255, alpha: 1)
             : UIColor(red: 241 / 255, green: 236 / 255, blue: 224 / 255, alpha: 1)
    }
}

/// The canonical static signature, inked in any colour. Callers decide its accessibility label.
struct AroomaSignatureMark: View {
    var ink: Color
    var body: some View {
        Rectangle()
            .fill(ink)
            .mask {
                Image("AroomaSignature")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .luminanceToAlpha()
            }
            .aspectRatio(SignatureGeometry.logoAspect, contentMode: .fit)
            .accessibilityHidden(true)
    }
}

// MARK: - Intro playback

enum SignatureIntroPolicy {
    static let seenKey = "arooma.signatureIntroSeen"
    /// Video is skipped (static master instead) with Reduce Motion, in Low Power Mode, and while
    /// VoiceOver is running.
    static func prefersStatic(reduceMotion: Bool) -> Bool {
        reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled || UIAccessibility.isVoiceOverRunning
    }
    static func clipURL(dark: Bool) -> URL? {
        Bundle.main.url(forResource: dark ? "AroomaIntroInkDark" : "AroomaIntroInkLight", withExtension: "mp4")
    }
}

/// The silent pen-writing clip, then the static master laid exactly over its final frame.
/// Tap anywhere to skip. Interrupted playback (backgrounding, decode failure) lands on the
/// static master instead of a black or half-written frame.
struct SignatureIntro: View {
    /// Shared with the welcome screen so the finished logo travels into place.
    var namespace: Namespace.ID?
    var holdAfter: Double = 0.55
    let finished: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var useVideo = true
    @State private var videoVisible = false
    @State private var showStatic = false
    @State private var done = false

    private var dark: Bool { scheme == .dark }

    var body: some View {
        GeometryReader { geo in
            let videoWidth = min(geo.size.width, geo.size.height * SignatureGeometry.videoAspect)
            let videoHeight = videoWidth / SignatureGeometry.videoAspect
            let origin = CGPoint(x: (geo.size.width - videoWidth) / 2, y: (geo.size.height - videoHeight) / 2)
            let r = SignatureGeometry.rectInVideo
            ZStack {
                SignatureGeometry.paper(dark: dark)
                if useVideo, let url = SignatureIntroPolicy.clipURL(dark: dark) {
                    IntroClip(url: url, paper: SignatureGeometry.paperUI(dark: dark),
                              ready: { withAnimation(.linear(duration: 0.12)) { videoVisible = true } },
                              ended: { land() },
                              failed: { land() })
                        .frame(width: videoWidth, height: videoHeight)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .opacity(videoVisible ? 1 : 0)
                        .id(dark) // appearance change mid-intro restarts with the matching clip
                }
                AroomaSignatureMark(ink: SignatureGeometry.ink(dark: dark))
                    .frame(width: videoWidth * r.width, height: videoHeight * r.height)
                    .modifier(SharedSignatureGeometry(namespace: namespace))
                    .position(x: origin.x + videoWidth * r.midX, y: origin.y + videoHeight * r.midY)
                    .opacity(showStatic ? 1 : 0)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { land(hold: 0.15) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Arooma")
        .accessibilityAddTraits(.isHeader)
        .accessibilityAction { land(hold: 0) }
        .onAppear {
            if SignatureIntroPolicy.prefersStatic(reduceMotion: reduceMotion) || SignatureIntroPolicy.clipURL(dark: dark) == nil {
                useVideo = false
                showStatic = true
                finish(after: reduceMotion ? 0.9 : 1.1)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { land(hold: 0) }
        }
    }

    /// Crossfade from the clip's final frame to the static master, hold, then finish.
    private func land(hold: Double? = nil) {
        guard !done else { return }
        withAnimation(.easeInOut(duration: 0.32)) { showStatic = true }
        finish(after: 0.32 + (hold ?? holdAfter))
    }

    private func finish(after delay: Double) {
        guard !done else { return }
        done = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            finished()
        }
    }
}

private struct SharedSignatureGeometry: ViewModifier {
    let namespace: Namespace.ID?
    func body(content: Content) -> some View {
        if let namespace {
            content.matchedGeometryEffect(id: "arooma-signature", in: namespace)
        } else {
            content
        }
    }
}

/// AVPlayerLayer host with no player chrome. The layer stays invisible until its first frame is
/// ready (no black flash); the clip has no audio track and the session is ambient.
struct IntroClip: UIViewRepresentable {
    let url: URL
    let paper: UIColor
    let ready: () -> Void
    let ended: () -> Void
    let failed: () -> Void

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }

    final class Coordinator {
        var player: AVPlayer?
        var readyObservation: NSKeyValueObservation?
        var statusObservation: NSKeyValueObservation?
        var endObserver: NSObjectProtocol?
        func tearDown() {
            player?.pause()
            readyObservation = nil
            statusObservation = nil
            if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
            endObserver = nil
            player = nil
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.backgroundColor = paper
        view.isUserInteractionEnabled = false
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
        player.actionAtItemEnd = .pause // hold the final written frame
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.backgroundColor = paper.cgColor
        view.playerLayer.player = player
        let coordinator = context.coordinator
        coordinator.player = player
        let ready = self.ready, ended = self.ended, failed = self.failed
        coordinator.readyObservation = view.playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { layer, _ in
            guard layer.isReadyForDisplay else { return }
            DispatchQueue.main.async {
                ready()
                coordinator.player?.play()
            }
        }
        coordinator.statusObservation = item.observe(\.status, options: [.new]) { item, _ in
            if item.status == .failed { DispatchQueue.main.async { failed() } }
        }
        coordinator.endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in ended() }
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {}

    static func dismantleUIView(_ view: PlayerView, coordinator: Coordinator) {
        view.playerLayer.player = nil
        coordinator.tearDown()
    }
}

/// Full-screen replay from the options sheet.
struct SignatureReplay: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        SignatureIntro(holdAfter: 0.9) { dismiss() }
            .statusBarHidden()
    }
}
