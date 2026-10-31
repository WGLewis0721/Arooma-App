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
    /// What the cards are morphing FROM: a layout, or the exact blend that was on screen when a
    /// new layout was chosen mid-morph (so a second switch never snaps).
    private(set) var source: MorphSource = .layout(.coverFlow)
    private(set) var layoutTo: DeckLayoutKind = .coverFlow
    /// Sign of the most recent travel, used to choose the direction label text slides.
    private(set) var travelDirection: Double = 1

    @ObservationIgnored var onSettle: ((Int, Bool, Double) -> Void)?
    /// Called the moment a release or glide commits to a card, so the selection is saved before
    /// the spring finishes (quitting mid-settle never loses it).
    @ObservationIgnored var onCommit: ((Int) -> Void)?
    @ObservationIgnored var reduceMotion = false
    @ObservationIgnored private let driver = FrameDriver(label: "deck")
    @ObservationIgnored private var lastReleaseSpeed = 0.0

    var position: Double { deck.position }
    var focusedIndex: Int { deck.focusedIndex }
    var isInteracting: Bool { deck.isInteracting }
    var isMoving: Bool { deck.isInteracting || deck.isAnimating || !morph.isResting }

    func pose(distance: Double, index: Int, cardWidth: Double) -> CardPose {
        let target = DeckLayoutEngine.pose(distance: distance, index: index, layout: layoutTo, cardWidth: cardWidth)
        if case .layout(let kind) = source, kind == layoutTo { return target }
        guard morph.value < 1 else { return target }
        let from = source.pose(distance: distance, index: index, cardWidth: cardWidth)
        return CardPose.blend(from, target, morph.value)
    }

    func stride(cardWidth: Double) -> Double {
        DeckLayoutEngine.stride(for: layoutTo, cardWidth: cardWidth)
    }

    // MARK: Configuration

    func configure(count: Int, index: Int, layout: DeckLayoutKind) {
        if deck.count != count || (!deck.isInteracting && !deck.isAnimating && deck.settledIndex != index) {
            deck.updateCount(count, focusing: index)
        }
        if layoutTo != layout && morph.isResting { source = .layout(layout); layoutTo = layout }
    }

    func morph(to layout: DeckLayoutKind) {
        guard layout != layoutTo else { return }
        if reduceMotion {
            source = .layout(layout); layoutTo = layout
            morph = SpringAxis(value: 1, parameters: .morph)
            return
        }
        // The new morph starts from exactly what is on screen now.
        if morph.isResting {
            source = .layout(layoutTo)
        } else {
            source = MorphSource.blend(source, layoutTo, morph.value).collapsed()
        }
        layoutTo = layout
        morph.value = 0
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
        let target = deck.release(velocity: velocity)
        onCommit?(target)
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
        onCommit?(deck.targetIndex)
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
            if morph.snapIfResting() { source = .layout(layoutTo) }
        }
        return deck.isInteracting || deck.isAnimating || !press.isResting || !morph.isResting
    }
}

/// The pose a card is morphing from: a plain layout, or a blend frozen mid-morph.
indirect enum MorphSource {
    case layout(DeckLayoutKind)
    case blend(MorphSource, DeckLayoutKind, Double)

    func pose(distance: Double, index: Int, cardWidth: Double) -> CardPose {
        switch self {
        case .layout(let kind):
            return DeckLayoutEngine.pose(distance: distance, index: index, layout: kind, cardWidth: cardWidth)
        case .blend(let from, let to, let t):
            let a = from.pose(distance: distance, index: index, cardWidth: cardWidth)
            let b = DeckLayoutEngine.pose(distance: distance, index: index, layout: to, cardWidth: cardWidth)
            return CardPose.blend(a, b, t)
        }
    }

    private var depth: Int {
        if case .blend(let from, _, _) = self { return from.depth + 1 }
        return 0
    }

    /// Bounds the nesting for someone tapping layouts very fast. Only the oldest, almost
    /// finished blend is resolved, so the visible pose barely moves.
    func collapsed() -> MorphSource {
        guard depth > 3, case .blend(let from, let to, let t) = self else { return self }
        if case .blend(_, let inner, _) = from, t > 0 { return .blend(.layout(inner), to, t) }
        return self
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

// MARK: - Frame-time readout (hidden, off by default)

/// On-device pacing check for the owner. Off by default; toggled by a long press on
/// "About this archive" in View & Style (or launch argument `-AroomaFramePacing YES`).
/// While on, its own CADisplayLink times every frame the app delivers, whatever is animating,
/// and the readout shows the last second: average frame time, fps against the display's target,
/// hitches (frames later than 1.5× target) and the worst frame. Nothing is logged or sent.
@MainActor
@Observable
final class FramePacingProbe {
    static let shared = FramePacingProbe()
    static let key = "AroomaFramePacing"

    var enabled: Bool = UserDefaults.standard.bool(forKey: FramePacingProbe.key) {
        didSet {
            UserDefaults.standard.set(enabled, forKey: Self.key)
            enabled ? start() : stop()
        }
    }
    private(set) var summary = "measuring…"
    private(set) var hitchedLastSecond = false

    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private var last: CFTimeInterval = 0
    @ObservationIgnored private var windowStart: CFTimeInterval = 0
    @ObservationIgnored private var frames = 0
    @ObservationIgnored private var hitches = 0
    @ObservationIgnored private var worst: Double = 0
    @ObservationIgnored private var total: Double = 0
    @ObservationIgnored private var expected: Double = 1.0 / 60.0

    private init() {
        if enabled { start() }
    }

    private func start() {
        guard link == nil else { return }
        let proxy = ProbeProxy()
        let link = CADisplayLink(target: proxy, selector: #selector(ProbeProxy.fire(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        self.link = link
        last = 0
    }

    private func stop() {
        link?.invalidate()
        link = nil
    }

    fileprivate func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        expected = max(1.0 / 240.0, link.targetTimestamp - link.timestamp)
        defer { last = now }
        guard last > 0 else { windowStart = now; return }
        let delta = now - last
        guard delta < 0.5 else { windowStart = now; return } // app was suspended
        frames += 1
        total += delta
        worst = max(worst, delta)
        if delta > expected * 1.5 { hitches += 1 }
        if now - windowStart >= 1 {
            let avg = total / Double(max(1, frames))
            summary = String(format: "%.1f ms · %.0f fps / %.0f Hz · hitches %d · worst %.0f ms",
                             avg * 1000, Double(frames) / (now - windowStart), 1 / expected, hitches, worst * 1000)
            hitchedLastSecond = hitches > 0
            frames = 0; hitches = 0; worst = 0; total = 0; windowStart = now
        }
    }
}

@MainActor
private final class ProbeProxy: NSObject {
    @objc func fire(_ link: CADisplayLink) { FramePacingProbe.shared.tick(link) }
}

struct FramePacingHUD: View {
    @State private var probe = FramePacingProbe.shared
    var body: some View {
        if probe.enabled {
            Text(probe.summary)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(.black.opacity(0.66), in: Capsule())
                .foregroundStyle(probe.hitchedLastSecond ? .orange : .green)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
