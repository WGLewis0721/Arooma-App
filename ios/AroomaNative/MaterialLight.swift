import SwiftUI
import CoreMotion
import UIKit
import ImageIO
import Observation
import simd

// MARK: - Motion field
//
// One shared Core Motion feed, reference-counted by the views that render live foil.
// It tracks the iPhone's full attitude (not just gravity, so turning an upright phone left/right
// counts) relative to a reference orientation that drifts slowly toward the current one: the way
// the owner is holding the phone becomes "neutral" after ~15 s, and every deliberate tilt moves
// the light. The light and the viewer are treated as fixed in the room; the card turns under
// them. Off when nothing visible needs it, in the background, in Low Power Mode, or when hot.

@MainActor
@Observable
final class MotionField {
    static let shared = MotionField()

    /// Rotation taking room-fixed directions (as seen at the reference pose) into the device's
    /// current frame. Identity when still at the reference, or when no sensor is running.
    private(set) var relative = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
    /// -1...1 summary of the same rotation, for the hero card's small physical lean.
    private(set) var tilt = CGPoint.zero
    private(set) var isLive = false

    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var users = 0
    @ObservationIgnored private var reference: simd_quatd?
    @ObservationIgnored private var smoothed = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
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
        observers.append(center.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification,
                                            object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { MotionField.shared.reconcile() }
        })
    }

    func acquire() { users += 1; reconcile() }
    func release() { users = max(0, users - 1); reconcile() }

    private var shouldRun: Bool {
        users > 0 && foreground && manager.isDeviceMotionAvailable && RenderQuality.allowsLiveMaterial
    }

    private func reconcile() {
        if shouldRun && !manager.isDeviceMotionActive {
            reference = nil
            manager.deviceMotionUpdateInterval = 1.0 / 60.0
            manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { motion, _ in
                guard let motion else { return }
                MainActor.assumeIsolated { MotionField.shared.ingest(motion.attitude.quaternion) }
            }
            isLive = true
        } else if !shouldRun && manager.isDeviceMotionActive {
            manager.stopDeviceMotionUpdates()
            isLive = false
            relative = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
            smoothed = relative
            tilt = .zero
        }
    }

    private func ingest(_ q: CMQuaternion) {
        let current = simd_quatd(ix: q.x, iy: q.y, iz: q.z, r: q.w)
        if reference == nil { reference = current }
        guard var ref = reference else { return }
        // Re-centre very slowly (~15 s at 60 Hz) so posture is absorbed but tilts are not.
        ref = simd_slerp(ref, current, 0.0011)
        reference = ref
        let rel = simd_normalize(simd_mul(simd_inverse(current), ref))
        // Light low-pass removes hand tremor without adding perceptible lag.
        smoothed = simd_normalize(simd_slerp(smoothed, rel, 0.4))
        let change = simd_mul(simd_inverse(relative), smoothed).angle
        guard change > 0.0012 else { return }
        relative = smoothed
        let eye = smoothed.act(simd_double3(0, 0, 1))
        tilt = CGPoint(x: max(-1, min(1, eye.x / 0.3)), y: max(-1, min(1, eye.y / 0.3)))
    }
}

/// Card-frame light and eye directions for the foil shader.
enum MaterialOptics {
    /// Room light above and slightly in front of the viewer, as seen at the reference pose.
    static let light0 = simd_normalize(simd_double3(-0.08, 0.3, 1))
    static let eye0 = simd_double3(0, 0, 1)

    /// `yaw` is the card's own rotation about its vertical axis in degrees (deck pose, flip).
    static func vectors(relative: simd_quatd, yaw: Double) -> (light: simd_float3, eye: simd_float3) {
        let theta = -yaw * .pi / 180
        let turn = simd_quatd(angle: theta, axis: simd_double3(0, 1, 0))
        let q = simd_mul(turn, relative)
        let l = q.act(light0), e = q.act(eye0)
        return (simd_float3(Float(l.x), Float(l.y), Float(l.z)), simd_float3(Float(e.x), Float(e.y), Float(e.z)))
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

/// GPU foil on the card that is in front. There is no clock: the shader re-renders only when the
/// phone's attitude, the card's pose or a finger press changes, so a still card on a still phone
/// is static, and tilting only the phone visibly moves the highlight, colour and glitter.
struct LiveFoil: ViewModifier {
    var strength: Double
    var yaw: Double
    var radius: CGFloat
    var tint: Color
    /// Finger position on the card (0...1) and press amount (0...1).
    var touch: CGPoint = .zero
    var pressure: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var motion = MotionField.shared

    func body(content: Content) -> some View {
        let live = strength > 0.01 && !reduceTransparency && !RenderQuality.foilDisabledForQA
        let level = Float(strength)
        let tintColor = tint
        // Reduce Motion: the light holds still (no tilt-driven change), touch still answers.
        let attitude = reduceMotion ? simd_quatd(ix: 0, iy: 0, iz: 0, r: 1) : motion.relative
        let v = MaterialOptics.vectors(relative: attitude, yaw: yaw)
        let press = SIMD3<Float>(Float(touch.x), Float(touch.y), Float(max(0, min(1, pressure))))
        content
            .visualEffect { view, proxy in
                view.colorEffect(
                    ShaderLibrary.aroomaFoil(
                        .float2(proxy.size),
                        .float3(v.light.x, v.light.y, v.light.z),
                        .float3(v.eye.x, v.eye.y, v.eye.z),
                        .float3(press.x, press.y, press.z),
                        .float(live ? level : 0),
                        .float(max(6, proxy.size.width * 0.045)),
                        .color(tintColor)
                    ),
                    isEnabled: live
                )
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
