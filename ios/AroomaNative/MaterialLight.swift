import SwiftUI
import CoreMotion
import UIKit
import ImageIO
import Observation
import simd

// MARK: - Motion field
//
// One shared Core Motion feed, reference-counted by the views that render live foil.
// It tracks the iPhone's full attitude relative to a reference orientation. By default the
// reference is FIXED when the gallery opens (drift Off), so a card held at an angle keeps the
// look of that angle; the owner can recenter manually or enable a slow drift in the tuning panel.
// Light and viewer are fixed in the room; the card turns under them. Sensor samples (30-120 Hz)
// are interpolated at display rate so the light never steps on a 120 Hz screen.
// Off in the background, in Low Power Mode, when hot, or when nothing visible needs it.

@MainActor
@Observable
final class MotionField {
    static let shared = MotionField()

    /// Rotation taking room-fixed directions (as seen at the reference pose) into the device's
    /// current frame, after sensitivity and the soft range limit. Identity when no sensor runs.
    private(set) var relative = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
    /// -1...1 summary of the same rotation, for the hero card's small physical lean.
    private(set) var tilt = CGPoint.zero
    private(set) var isLive = false

    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var users = 0
    @ObservationIgnored private var reference: simd_quatd?
    @ObservationIgnored private var lastRaw: simd_quatd?
    @ObservationIgnored private var lastSampleTime: TimeInterval = 0
    @ObservationIgnored private var target = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var foreground = true
    @ObservationIgnored private var pendingStop: Task<Void, Never>?
    @ObservationIgnored private var stoppedAt: Date?
    @ObservationIgnored private let interpolator = FrameDriver(label: "tilt")

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

    func acquire() {
        users += 1
        pendingStop?.cancel()
        pendingStop = nil
        reconcile()
    }

    /// Cards hand the sensor to each other as the deck moves; a short grace period keeps it
    /// (and its reference) alive across those hand-offs instead of re-centring mid-browse.
    func release() {
        users = max(0, users - 1)
        guard users == 0 else { return }
        pendingStop?.cancel()
        pendingStop = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            MotionField.shared.reconcile()
        }
    }

    /// Makes the current physical angle the neutral one (gallery open, or the Recenter action).
    func recenter() {
        if let lastRaw { reference = lastRaw } else { reference = nil }
        recompute()
    }

    /// Called by the tuning panel when any tilt value changes.
    func tuningChanged() {
        if manager.isDeviceMotionActive {
            manager.deviceMotionUpdateInterval = 1.0 / max(30, min(120, TiltTuning.sampleRateHz))
        }
        recompute()
    }

    private var shouldRun: Bool {
        users > 0 && foreground && manager.isDeviceMotionAvailable && RenderQuality.allowsLiveMaterial
    }

    private func reconcile() {
        if shouldRun && !manager.isDeviceMotionActive {
            // Keep the reference across brief stops; a real absence (left the gallery) resets it.
            if let stoppedAt, Date().timeIntervalSince(stoppedAt) > 3 { reference = nil }
            stoppedAt = nil
            lastSampleTime = 0
            manager.deviceMotionUpdateInterval = 1.0 / max(30, min(120, TiltTuning.sampleRateHz))
            manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { motion, _ in
                guard let motion else { return }
                MainActor.assumeIsolated {
                    MotionField.shared.ingest(motion.attitude.quaternion, at: motion.timestamp)
                }
            }
            isLive = true
        } else if !shouldRun && manager.isDeviceMotionActive {
            manager.stopDeviceMotionUpdates()
            interpolator.stop()
            stoppedAt = Date()
            isLive = false
            relative = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
            target = relative
            tilt = .zero
        }
    }

    private func ingest(_ q: CMQuaternion, at time: TimeInterval) {
        let current = simd_quatd(ix: q.x, iy: q.y, iz: q.z, r: q.w)
        let dt = lastSampleTime > 0 ? max(0, min(0.25, time - lastSampleTime)) : 0
        lastSampleTime = time
        lastRaw = current
        if reference == nil { reference = current }
        // Optional slow re-centring; Off by default so a held angle keeps its look.
        if TiltTuning.driftSeconds > 0, dt > 0, let ref = reference {
            let alpha = 1 - exp(-dt / TiltTuning.driftSeconds)
            reference = simd_slerp(ref, current, alpha)
        }
        recompute()
    }

    /// Raw rotation since the reference → sensitivity → soft range limit (no hard clipping).
    private func recompute() {
        guard let ref = reference, let raw = lastRaw else { return }
        let rel = simd_normalize(simd_mul(simd_inverse(raw), ref))
        let angle = rel.angle
        if angle > 1e-6 {
            let range = max(5, TiltTuning.rangeDegrees) * .pi / 180
            let shaped = range * tanh(angle * max(0.1, TiltTuning.gain) / range)
            target = simd_quatd(angle: shaped, axis: rel.axis)
        } else {
            target = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
        }
        interpolator.run { [weak self] dt in
            guard let self else { return false }
            return self.interpolate(dt)
        }
    }

    /// Display-rate easing toward the latest sample, so 60 Hz sensor data looks continuous at
    /// 120 Hz. Stops as soon as it has converged.
    private func interpolate(_ dt: Double) -> Bool {
        let tau = TiltTuning.smoothingMS / 1000
        let alpha = tau <= 0.001 ? 1 : 1 - exp(-dt / tau)
        let next = simd_normalize(simd_slerp(relative, target, alpha))
        let remaining = simd_mul(simd_inverse(next), target).angle
        if simd_mul(simd_inverse(relative), next).angle > 0.00005 || remaining < 0.0002 {
            relative = remaining < 0.0002 ? target : next
            let eye = relative.act(simd_double3(0, 0, 1))
            tilt = CGPoint(x: tanh(eye.x / 0.35), y: tanh(eye.y / 0.35))
        }
        return remaining >= 0.0002
    }
}

/// Card-frame light and eye directions for the foil shader.
enum MaterialOptics {
    /// Room light above and slightly in front of the viewer, as seen at the reference pose.
    static let light0 = simd_normalize(simd_double3(-0.08, 0.3, 1))
    static let eye0 = simd_double3(0, 0, 1)

    /// `yaw` is the card's own rotation about its vertical axis in degrees (deck pose, flip).
    /// `idle` is an optional, tiny extra light offset (tuning; Off by default).
    static func vectors(relative: simd_quatd, yaw: Double, idle: CGPoint = .zero) -> (light: simd_float3, eye: simd_float3) {
        let theta = -yaw * .pi / 180
        let turn = simd_quatd(angle: theta, axis: simd_double3(0, 1, 0))
        let q = simd_mul(turn, relative)
        var l = q.act(light0)
        // Light-travel gains: how far the highlight moves per degree, horizontally / vertically.
        l.x = l.x * FoilTuning.lightTravelX + Double(idle.x)
        l.y = l.y * FoilTuning.lightTravelY + Double(idle.y)
        l = simd_normalize(l)
        let e = q.act(eye0)
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

/// GPU foil on the card that is in front. The shader re-renders only when the phone's attitude
/// (interpolated at display rate), the card's pose, a finger press or a tuning value changes, so
/// a still card on a still phone is static and tilting only the phone visibly moves the light.
/// The optional idle drift (tuning, Off by default) is tiny and added on top of real motion.
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
    @Environment(\.scenePhase) private var scenePhase
    @State private var motion = MotionField.shared
    @State private var tuning = Tuning.shared

    func body(content: Content) -> some View {
        let _ = tuning.revision
        let drifting = FoilTuning.idleDrift > 0 && !reduceMotion && scenePhase == .active && strength > 0.5
        if drifting {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { clock in
                let t = clock.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
                let a = FoilTuning.idleDrift
                foil(content, idle: CGPoint(x: sin(t * 0.37) * a, y: cos(t * 0.29) * a * 0.7))
            }
            .onAppear { motion.acquire() }
            .onDisappear { motion.release() }
        } else {
            foil(content, idle: .zero)
                .onAppear { motion.acquire() }
                .onDisappear { motion.release() }
        }
    }

    private func foil(_ content: Content, idle: CGPoint) -> some View {
        let live = strength > 0.01 && !reduceTransparency && !RenderQuality.foilDisabledForQA
        let level = Float(strength)
        let tintColor = tint
        // Reduce Motion: the light holds still (no tilt-driven change); touch still answers.
        let attitude = reduceMotion ? simd_quatd(ix: 0, iy: 0, iz: 0, r: 1) : motion.relative
        let v = MaterialOptics.vectors(relative: attitude, yaw: yaw, idle: idle)
        let press = SIMD3<Float>(Float(touch.x), Float(touch.y), Float(max(0, min(1, pressure))))
        let shape = SIMD4<Float>(Float(max(1, FoilTuning.sheenWidth)), Float(max(4, FoilTuning.glintTightness)),
                                 Float(FoilTuning.diffractionStrength), Float(FoilTuning.diffractionPhase))
        let gains = SIMD4<Float>(Float(FoilTuning.sheenStrength), Float(FoilTuning.glintStrength),
                                 Float(FoilTuning.glitterStrength), Float(max(0.5, FoilTuning.eyeDistance)))
        return content
            .visualEffect { view, proxy in
                view.colorEffect(
                    ShaderLibrary.aroomaFoil(
                        .float2(proxy.size),
                        .float3(v.light.x, v.light.y, v.light.z),
                        .float3(v.eye.x, v.eye.y, v.eye.z),
                        .float3(press.x, press.y, press.z),
                        .float4(shape.x, shape.y, shape.z, shape.w),
                        .float4(gains.x, gains.y, gains.z, gains.w),
                        .float(live ? level : 0),
                        .float(max(6, proxy.size.width * 0.045)),
                        .color(tintColor)
                    ),
                    isEnabled: live
                )
            }
    }
}

/// The focused card answers the handset with a small physical lean (Apple TV-icon style),
/// up to the tunable maximum.
struct TiltLean: ViewModifier {
    var amount: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var motion = MotionField.shared
    func body(content: Content) -> some View {
        let t = (reduceMotion || amount == 0) ? .zero : motion.tilt
        let maxDeg = TiltTuning.leanMaxDegrees * amount
        content
            .rotation3DEffect(.degrees(Double(t.x) * maxDeg), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .rotation3DEffect(.degrees(Double(t.y) * maxDeg * 0.75), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
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
