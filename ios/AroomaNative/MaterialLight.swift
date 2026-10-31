import SwiftUI
import CoreMotion
import UIKit
import ImageIO
import Observation

// MARK: - Motion field
//
// One shared Core Motion feed, reference-counted by the views that render live foil. The gravity
// vector is compared against a slowly drifting baseline, so whatever angle the phone is held at
// becomes "neutral" after a few seconds and only deliberate tilting moves the light.
// Off when nothing visible needs it, when the app is backgrounded, or in Low Power Mode.

@MainActor
@Observable
final class MotionField {
    static let shared = MotionField()

    /// -1...1. x: tilt right is positive. y: top edge tilted away from the viewer is positive.
    private(set) var tilt = CGPoint.zero
    private(set) var isLive = false

    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var users = 0
    @ObservationIgnored private var baseline: (x: Double, y: Double)?
    @ObservationIgnored private var smooth = (x: 0.0, y: 0.0)
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var foreground = true

    private init() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                            object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { MotionField.shared.foreground = false; MotionField.shared.reconcile() }
        })
        observers.append(center.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                            object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { MotionField.shared.foreground = true; MotionField.shared.reconcile() }
        })
        observers.append(center.addObserver(forName: Notification.Name.NSProcessInfoPowerStateDidChange,
                                            object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { MotionField.shared.reconcile() }
        })
    }

    func acquire() { users += 1; reconcile() }
    func release() { users = max(0, users - 1); reconcile() }

    private var shouldRun: Bool {
        users > 0 && foreground && manager.isDeviceMotionAvailable &&
        !ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    private func reconcile() {
        if shouldRun && !manager.isDeviceMotionActive {
            baseline = nil
            manager.deviceMotionUpdateInterval = 1.0 / 60.0
            manager.startDeviceMotionUpdates(to: .main) { motion, _ in
                guard let motion else { return }
                MainActor.assumeIsolated { MotionField.shared.ingest(motion.gravity) }
            }
            isLive = true
        } else if !shouldRun && manager.isDeviceMotionActive {
            manager.stopDeviceMotionUpdates()
            isLive = false
            tilt = .zero
        }
    }

    private func ingest(_ g: CMAcceleration) {
        if baseline == nil { baseline = (g.x, g.y) }
        guard var b = baseline else { return }
        // ~4 s time constant at 60 Hz: posture changes are absorbed, gestures are not.
        b.x += (g.x - b.x) * 0.004
        b.y += (g.y - b.y) * 0.004
        baseline = b
        let tx = max(-1, min(1, (g.x - b.x) / 0.32))
        let ty = max(-1, min(1, (g.y - b.y) / 0.32))
        smooth.x += (tx - smooth.x) * 0.22
        smooth.y += (ty - smooth.y) * 0.22
        if abs(smooth.x - tilt.x) > 0.0015 || abs(smooth.y - tilt.y) > 0.0015 {
            tilt = CGPoint(x: smooth.x, y: smooth.y)
        }
    }
}

// MARK: - Render quality

enum RenderQuality {
    /// Full shader animation unless the device is hot or saving power.
    static var allowsLiveMaterial: Bool {
        let thermal = ProcessInfo.processInfo.thermalState
        return !ProcessInfo.processInfo.isLowPowerModeEnabled && thermal != .serious && thermal != .critical
    }
    /// QA switch (`-AroomaFoilOff YES`) used by CI to A/B the shader's cost in frame pacing.
    static let foilDisabledForQA = UserDefaults.standard.bool(forKey: "AroomaFoilOff")
}

// MARK: - Contact shadow sprite

/// A soft card shadow rendered ONCE with Core Graphics, then only scaled, moved and faded per
/// frame. Replaces a live Gaussian blur per card per frame (an offscreen pass each).
enum ShadowSprite {
    static let shape = CGSize(width: 118, height: 172)
    static let pad: CGFloat = 46
    static let image: UIImage = {
        let size = CGSize(width: shape.width + pad * 2, height: shape.height + pad * 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            // Draw the shape far off-canvas and cast only its shadow back into view.
            let shift: CGFloat = 4000
            cg.setShadow(offset: CGSize(width: shift * 2, height: 0), blur: 34,
                         color: UIColor.black.cgColor)
            let rect = CGRect(x: pad - shift * 2, y: pad, width: shape.width, height: shape.height)
            UIColor.black.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 12).fill()
        }.withRenderingMode(.alwaysTemplate)
    }()
    /// Scale that makes the sprite's inner shape match the view it is placed behind.
    static let overscan = CGSize(width: (shape.width + pad * 2) / shape.width,
                                 height: (shape.height + pad * 2) / shape.height)
}

// MARK: - Theme lighting

extension FragranceTheme {
    /// The colour of the environment's key light: tints foil sheen, floor glow and shadows.
    var keyLight: Color {
        switch self {
        case .obsidian: Color(hex: 0xF4D7A1)
        case .ivory: Color(hex: 0xFFE9C7)
        case .violet: Color(hex: 0xE3D3FF)
        case .emerald: Color(hex: 0xE6F2D6)
        }
    }
    var shadowTint: Color {
        switch self {
        case .obsidian: Color(hex: 0x06070C)
        case .ivory: Color(hex: 0x3A2814)
        case .violet: Color(hex: 0x0D0818)
        case .emerald: Color(hex: 0x04100C)
        }
    }
}

// MARK: - Live holographic foil

/// GPU foil on the card that is in front. Light = device tilt + the card's own pose (yaw /
/// flip angle) + a barely perceptible idle drift, so neighbouring cards, the hero and its
/// shadow all agree on where the light is.
struct LiveFoil: ViewModifier {
    var strength: Double
    var yaw: Double
    var radius: CGFloat
    var tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.scenePhase) private var scenePhase
    @State private var motion = MotionField.shared

    func body(content: Content) -> some View {
        let live = strength > 0.01 && !reduceTransparency && !RenderQuality.foilDisabledForQA
        let level = strength
        let tintColor = tint
        // Only the hero's clock runs; neighbours keep a still (but tilt-responsive) light.
        let animate = live && strength > 0.5 && !reduceMotion && scenePhase == .active && RenderQuality.allowsLiveMaterial
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !animate)) { clock in
            let t = clock.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            let drift = animate ? CGPoint(x: sin(t * 0.37) * 0.10, y: cos(t * 0.29) * 0.07) : .zero
            let tilt = reduceMotion ? .zero : motion.tilt
            let light = CGPoint(x: tilt.x * 0.95 + drift.x - yaw / 70,
                                y: -tilt.y * 0.8 + drift.y - 0.25)
            content
                .visualEffect { view, proxy in
                    view.colorEffect(
                        ShaderLibrary.aroomaFoil(
                            .float2(proxy.size),
                            .float2(light),
                            .float(animate ? t : 0),
                            .float(live ? level : 0),
                            .float(max(6, proxy.size.width * 0.045)),
                            .color(tintColor)
                        ),
                        isEnabled: live
                    )
                }
        }
        .onAppear { motion.acquire() }
        .onDisappear { motion.release() }
    }
}

/// The focused card answers the handset with a very small physical lean (Apple TV-icon style).
struct TiltLean: ViewModifier {
    var amount: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var motion = MotionField.shared
    func body(content: Content) -> some View {
        let t = (reduceMotion || amount == 0) ? .zero : motion.tilt
        content
            .rotation3DEffect(.degrees(Double(t.x) * 4 * amount), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .rotation3DEffect(.degrees(Double(t.y) * 3 * amount), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
    }
}

// MARK: - Owner photo cache

/// Owner photographs are decoded once, downsampled for display, and kept in memory, never
/// re-read from disk inside an animation frame. Originals on disk are untouched.
enum OwnerPhotoCache {
    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 48
        return c
    }()

    static func image(at url: URL, maxPixel: CGFloat = 1100) -> UIImage? {
        let key = url.path as NSString
        if let hit = cache.object(forKey: key) { return hit }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let image = UIImage(cgImage: cg)
        cache.setObject(image, forKey: key)
        return image
    }
}
