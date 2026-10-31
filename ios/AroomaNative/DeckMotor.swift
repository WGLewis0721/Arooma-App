import SwiftUI
import QuartzCore
import Observation

// MARK: - Frame driver
//
// One CADisplayLink per motor, running only while something is actually moving or a finger is
// down. It requests the display's native rate (120 Hz on ProMotion iPhones; the Info.plist sets
// CADisableMinimumFrameDurationOnPhone) and stops itself the moment every spring is at rest.

@MainActor
final class FrameDriver {
    private var link: CADisplayLink?
    private var last: CFTimeInterval = 0
    private var tick: ((Double) -> Bool)?
    private let label: String

    init(label: String) { self.label = label }

    var isRunning: Bool { link != nil }

    /// `tick` receives the frame delta in seconds and returns false when the motion is finished.
    func run(_ tick: @escaping (Double) -> Bool) {
        self.tick = tick
        guard link == nil else { return }
        let proxy = DisplayLinkProxy(owner: self)
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.fire(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        self.link = link
        last = 0
    }

    func stop() {
        link?.invalidate()
        link = nil
        tick = nil
        last = 0
    }

    fileprivate func fire(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = last == 0 ? (link.targetTimestamp - link.timestamp) : (now - last)
        last = now
        FramePacingProbe.shared.record(timestamp: now, expected: link.targetTimestamp - link.timestamp)
        guard let tick else { stop(); return }
        if !tick(max(1.0 / 240.0, dt)) { stop() }
    }
}

@MainActor
private final class DisplayLinkProxy: NSObject {
    weak var owner: FrameDriver?
    init(owner: FrameDriver) { self.owner = owner }
    @objc func fire(_ link: CADisplayLink) {
        guard let owner else { link.invalidate(); return }
        owner.fire(link)
    }
}

// MARK: - Deck motor

/// Observable wrapper that steps DeckModel, the press spring and the layout morph together.
/// The gallery stage derives every card pose from these three values and nothing else.
@MainActor
@Observable
final class DeckMotor {
    private(set) var deck = DeckModel(count: 0)
    private(set) var press = SpringAxis(value: 0, parameters: .press)
    private(set) var morph = SpringAxis(value: 1, parameters: .morph)
    private(set) var layoutFrom: DeckLayoutKind = .coverFlow
    private(set) var layoutTo: DeckLayoutKind = .coverFlow
    /// Sign of the most recent travel, used to choose the direction label text slides.
    private(set) var travelDirection: Double = 1

    @ObservationIgnored var onSettle: ((Int, Bool, Double) -> Void)?
    @ObservationIgnored var reduceMotion = false
    @ObservationIgnored private let driver = FrameDriver(label: "deck")
    @ObservationIgnored private var lastReleaseSpeed = 0.0

    var position: Double { deck.position }
    var focusedIndex: Int { deck.focusedIndex }
    var isInteracting: Bool { deck.isInteracting }
    var isMoving: Bool { deck.isInteracting || deck.isAnimating || !morph.isResting }

    func pose(distance: Double, index: Int, cardWidth: Double) -> CardPose {
        let target = DeckLayoutEngine.pose(distance: distance, index: index, layout: layoutTo, cardWidth: cardWidth)
        guard morph.value < 1 || layoutFrom != layoutTo else { return target }
        let source = DeckLayoutEngine.pose(distance: distance, index: index, layout: layoutFrom, cardWidth: cardWidth)
        return CardPose.blend(source, target, morph.value)
    }

    func stride(cardWidth: Double) -> Double {
        DeckLayoutEngine.stride(for: layoutTo, cardWidth: cardWidth)
    }

    // MARK: Configuration

    func configure(count: Int, index: Int, layout: DeckLayoutKind) {
        if deck.count != count || (!deck.isInteracting && !deck.isAnimating && deck.settledIndex != index) {
            deck.updateCount(count, focusing: index)
        }
        if layoutTo != layout && morph.isResting { layoutFrom = layout; layoutTo = layout }
    }

    func morph(to layout: DeckLayoutKind) {
        guard layout != layoutTo else { return }
        if reduceMotion {
            layoutFrom = layout; layoutTo = layout
            morph = SpringAxis(value: 1, parameters: .morph)
            return
        }
        // Start the new morph from the currently displayed blend so a second switch mid-morph
        // does not snap: freeze the visible pose as the new "from" by keeping the old pair when
        // the previous morph is less than half done.
        if morph.value < 0.5 { layoutTo = layout } else { layoutFrom = layoutTo; layoutTo = layout; morph.value = 0 }
        morph.target = 1
        morph.velocity = 0
        run()
    }

    // MARK: Touch

    func hold() {
        deck.hold()
        press.target = 1
        run()
    }

    func drag(translation units: Double) {
        let before = deck.position
        deck.drag(translation: units)
        if deck.position != before { travelDirection = deck.position > before ? 1 : -1 }
        run()
    }

    func release(velocity: Double) {
        press.target = 0
        lastReleaseSpeed = abs(velocity)
        if reduceMotion {
            let target = DeckModel.releaseTarget(position: deck.position, velocity: velocity, count: deck.count)
            place(target, notify: true)
            return
        }
        deck.release(velocity: velocity)
        run()
    }

    /// Finger lifted without dragging (a tap), or the gesture was cancelled.
    func liftWithoutDrag() {
        press.target = 0
        lastReleaseSpeed = 0
        deck.cancel()
        run()
    }

    func glide(to index: Int) {
        guard index != deck.targetIndex || deck.phase == .idle else { return }
        travelDirection = Double(index) >= deck.position ? 1 : -1
        lastReleaseSpeed = 0
        if reduceMotion { place(index, notify: true); return }
        deck.glide(to: index)
        run()
    }

    func place(_ index: Int, notify: Bool = false) {
        let previous = deck.settledIndex
        deck.place(at: index)
        if notify { onSettle?(deck.settledIndex, deck.settledIndex != previous, 0) }
    }

    // MARK: Time

    private func run() {
        driver.run { [weak self] dt in
            guard let self else { return false }
            return self.step(dt)
        }
    }

    private func step(_ dt: Double) -> Bool {
        if let event = deck.step(dt), case let .settled(index, changed) = event {
            onSettle?(index, changed, lastReleaseSpeed)
        }
        if !press.isResting {
            press.step(dt)
            press.snapIfResting()
        }
        if !morph.isResting {
            morph.step(dt)
            if morph.snapIfResting() { layoutFrom = layoutTo }
        }
        return deck.isInteracting || deck.isAnimating || !press.isResting || !morph.isResting
    }
}

// MARK: - Flip motor (inspector)

@MainActor
@Observable
final class FlipMotor {
    private(set) var model = FlipModel()
    @ObservationIgnored var onEdge: (() -> Void)?
    @ObservationIgnored var reduceMotion = false
    @ObservationIgnored private let driver = FrameDriver(label: "flip")
    @ObservationIgnored private var lastFaceBack = false

    var angle: Double { model.angle }
    var showsBack: Bool { model.showsBack }

    func begin() { model.begin(); lastFaceBack = model.showsBack }

    func drag(degrees: Double) {
        model.drag(degrees: degrees)
        noteEdge()
    }

    func release(velocity: Double) {
        model.release(velocity: velocity)
        if reduceMotion { settleImmediately(); return }
        run()
    }

    func flip(direction: Double = 1) {
        lastFaceBack = model.showsBack
        model.flip(direction: direction)
        if reduceMotion { settleImmediately(); return }
        run()
    }

    private func settleImmediately() {
        for _ in 0..<600 { model.step(1.0 / 120.0) }
        noteEdge()
    }

    private func noteEdge() {
        if model.showsBack != lastFaceBack {
            lastFaceBack = model.showsBack
            onEdge?()
        }
    }

    private func run() {
        driver.run { [weak self] dt in
            guard let self else { return false }
            self.model.step(dt)
            self.noteEdge()
            return self.model.isAnimating
        }
    }
}

// MARK: - Frame pacing probe

/// Real frame-interval measurement for every animated frame the deck and flip motors render.
/// Enabled with the launch argument `-AroomaFramePacing YES` (Xcode scheme → Arguments), on a
/// device or simulator. Reports to the console every 3 seconds of animation and drives the HUD.
/// A hitch is any frame that arrived later than 1.5× the display's target interval; hitch time
/// is the time beyond the target, summed, per second of animation (Apple's hitch-ratio metric).
@MainActor
@Observable
final class FramePacingProbe {
    static let shared = FramePacingProbe()
    let enabled = UserDefaults.standard.bool(forKey: "AroomaFramePacing")

    private(set) var summary = "measuring…"
    @ObservationIgnored private var lastTimestamp: CFTimeInterval = 0
    @ObservationIgnored private var frames = 0
    @ObservationIgnored private var hitches = 0
    @ObservationIgnored private var hitchTime: Double = 0
    @ObservationIgnored private var animatedTime: Double = 0
    @ObservationIgnored private var worst: Double = 0
    @ObservationIgnored private var expectedSum: Double = 0

    func record(timestamp: CFTimeInterval, expected: Double) {
        guard enabled else { return }
        defer { lastTimestamp = timestamp }
        guard lastTimestamp > 0 else { return }
        let delta = timestamp - lastTimestamp
        // A gap longer than 250 ms is a new animation, not a hitch.
        guard delta < 0.25, expected > 0 else { return }
        frames += 1
        animatedTime += delta
        expectedSum += expected
        worst = max(worst, delta)
        if delta > expected * 1.5 {
            hitches += 1
            hitchTime += delta - expected
        }
        if animatedTime >= 3 { flush() }
    }

    private func flush() {
        let fps = Double(frames) / animatedTime
        let target = Double(frames) / expectedSum
        let hitchMsPerS = hitchTime * 1000 / animatedTime
        let line = String(format: "frames=%d fps=%.1f target=%.0fHz hitches=%d hitch=%.1fms/s worst=%.1fms",
                          frames, fps, target, hitches, hitchMsPerS, worst * 1000)
        summary = line
        print("AroomaFramePacing \(line)")
        fflush(stdout)
        frames = 0; hitches = 0; hitchTime = 0; animatedTime = 0; worst = 0; expectedSum = 0
    }
}

struct FramePacingHUD: View {
    @State private var probe = FramePacingProbe.shared
    var body: some View {
        if probe.enabled {
            Text(probe.summary)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(.black.opacity(0.62), in: Capsule())
                .foregroundStyle(.green)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
