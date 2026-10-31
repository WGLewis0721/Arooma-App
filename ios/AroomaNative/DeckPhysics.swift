import Foundation

// MARK: - Arooma deck physics
//
// Pure Swift, no SwiftUI. Every visible card pose in the gallery, the inspector flip and the
// layout morph is derived from the small value types in this file. They are stepped by a single
// display-link driver (DeckMotor) so that the value on screen IS the model value: a new touch
// always begins from the exact visible pose and the measured velocity, never from an animation
// target that SwiftUI has already jumped to. This file is compiled into the app and into the
// standalone test runner in ios/Tests, which runs on macOS CI and on Linux.

/// Spring parameters expressed the same way as SwiftUI springs: `response` is the undamped
/// period in seconds and `damping` is the damping fraction (1 = critical).
struct SpringParameters: Equatable {
    var response: Double
    var damping: Double

    var stiffness: Double { let w = 2 * Double.pi / response; return w * w }
    var friction: Double { 4 * Double.pi * damping / response }

    /// Card settling into the center slot after release: weighted, one soft overshoot at most.
    static var deckSettle = SpringParameters(response: 0.46, damping: 0.84)
    /// Programmatic moves (tap a neighbour, VoiceOver, search focus): a little calmer.
    static var deckGlide = SpringParameters(response: 0.52, damping: 0.9)
    /// Finger-down lift and release of the pressed card.
    static var press = SpringParameters(response: 0.24, damping: 0.68)
    /// Inspector flip after the finger lets go.
    static var flip = SpringParameters(response: 0.52, damping: 0.8)
    /// Cover Flow, Stack and Fan morphing into one another.
    static var morph = SpringParameters(response: 0.62, damping: 0.86)
}

/// One damped harmonic oscillator, integrated with semi-implicit Euler at a fixed small sub-step.
/// Fixed sub-steps keep the motion identical at 60 Hz, 120 Hz and in tests.
struct SpringAxis: Equatable {
    var value: Double
    var velocity: Double = 0
    var target: Double
    var parameters: SpringParameters
    var restDistance = 0.0004
    var restVelocity = 0.004

    init(value: Double, target: Double? = nil, parameters: SpringParameters) {
        self.value = value
        self.target = target ?? value
        self.parameters = parameters
    }

    var isResting: Bool {
        abs(value - target) < restDistance && abs(velocity) < restVelocity
    }

    static let substep = 1.0 / 480.0

    mutating func step(_ dt: Double) {
        guard dt > 0, dt.isFinite else { return }
        // A long hitch (backgrounding, breakpoint) must not explode the integrator.
        var remaining = min(dt, 0.1)
        let k = parameters.stiffness
        let c = parameters.friction
        while remaining > 0 {
            let h = min(Self.substep, remaining)
            let acceleration = -k * (value - target) - c * velocity
            velocity += acceleration * h
            value += velocity * h
            remaining -= h
        }
    }

    /// Lands exactly on the target once motion is imperceptible, so a resting card is centred
    /// to the floating-point bit, not "almost".
    @discardableResult
    mutating func snapIfResting() -> Bool {
        guard isResting else { return false }
        value = target
        velocity = 0
        return true
    }
}

enum DeckMath {
    /// iOS-style rubber band: the further past the edge, the stronger the resistance.
    /// `limit` is the maximum distance (deck units) the content can ever travel past the edge.
    /// Owner-tunable (hidden tuning panel); defaults are the shipped values.
    static var rubberLimit = 0.42
    static var rubberCoefficient = 0.55

    static func rubberBand(_ overshoot: Double, limit: Double? = nil, coefficient: Double? = nil) -> Double {
        guard overshoot != 0 else { return 0 }
        let limit = max(0.05, limit ?? rubberLimit)
        let coefficient = max(0.05, coefficient ?? rubberCoefficient)
        let sign: Double = overshoot < 0 ? -1 : 1
        let x = abs(overshoot)
        return sign * (1 - 1 / (x * coefficient / limit + 1)) * limit
    }

    static func clamp<T: Comparable>(_ value: T, _ lower: T, _ upper: T) -> T {
        min(max(value, lower), upper)
    }

    static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

    /// Smooth 0...1 ramp, used for depth fades.
    static func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = clamp((x - edge0) / (edge1 - edge0), 0, 1)
        return t * t * (3 - 2 * t)
    }
}

// MARK: - The deck

enum DeckPhase: Equatable { case idle, held, dragging, settling }

enum DeckEvent: Equatable {
    /// The deck came to rest on this index. Fire selection haptics and persist selection here only.
    case settled(index: Int, changed: Bool)
}

/// The single source of truth for the gallery deck: a signed continuous position in card units,
/// its velocity and the gesture phase. Selection is written to storage only on settle.
struct DeckModel: Equatable {
    private(set) var count: Int
    private(set) var axis: SpringAxis
    private(set) var phase: DeckPhase = .idle
    private(set) var settledIndex: Int
    private var dragOrigin: Double = 0

    /// Above this release speed (cards per second) a release commits to the next card in the
    /// direction of travel. Below it, the card nearest the centre wins.
    static var flickThreshold = 0.75
    /// Release velocity handed to the spring is bounded so a violent flick cannot overshoot
    /// far enough to visually present a card that will not be selected.
    static var maxReleaseVelocity = 7.0

    init(count: Int, index: Int = 0) {
        self.count = max(0, count)
        let start = Double(DeckMath.clamp(index, 0, max(0, count - 1)))
        self.axis = SpringAxis(value: start, parameters: .deckSettle)
        self.settledIndex = Int(start)
    }

    var maxIndex: Int { max(0, count - 1) }
    var position: Double { axis.value }
    var velocity: Double { axis.velocity }
    var targetIndex: Int { Int(axis.target.rounded()) }
    var isInteracting: Bool { phase == .held || phase == .dragging }
    var isAnimating: Bool { phase == .settling }

    /// The card that is visually foremost right now, mid-drag included. Used for labels only;
    /// never written to storage until the deck settles.
    var focusedIndex: Int {
        guard count > 0 else { return 0 }
        return DeckMath.clamp(Int(position.rounded()), 0, maxIndex)
    }

    // MARK: Touch

    /// Finger down. Any settling motion stops where it visibly is; the finger now owns the pose.
    mutating func hold() {
        guard count > 0 else { return }
        axis.target = axis.value
        axis.velocity = 0
        dragOrigin = axis.value
        phase = .held
    }

    /// `translation` is in deck units, positive toward higher indices
    /// (i.e. `-dragTranslation.width / stride`).
    mutating func drag(translation: Double) {
        guard count > 0 else { return }
        if phase != .held && phase != .dragging { hold() }
        phase = .dragging
        let raw = dragOrigin + translation
        let upper = Double(maxIndex)
        let bounded: Double
        if raw < 0 { bounded = DeckMath.rubberBand(raw) }
        else if raw > upper { bounded = upper + DeckMath.rubberBand(raw - upper) }
        else { bounded = raw }
        axis.value = bounded
        axis.target = bounded
        axis.velocity = 0
    }

    /// The index a release will commit to. One-card-snap policy: only the two cards straddling
    /// the centre line are candidates, so a release can never skip a card the user did not see.
    static func releaseTarget(position: Double, velocity: Double, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let maxIndex = count - 1
        let lower = floor(position)
        let upper = ceil(position)
        var target: Double
        if abs(velocity) >= flickThreshold {
            if lower == upper { target = position + (velocity > 0 ? 1 : -1) }
            else { target = velocity > 0 ? upper : lower }
        } else {
            target = position.rounded()
        }
        return DeckMath.clamp(Int(target), 0, maxIndex)
    }

    /// Finger up. `velocity` is in deck units per second, positive toward higher indices.
    @discardableResult
    mutating func release(velocity: Double) -> Int {
        guard count > 0 else { return 0 }
        let v = velocity.isFinite ? velocity : 0
        let target = phase == .dragging
            ? Self.releaseTarget(position: axis.value, velocity: v, count: count)
            : DeckMath.clamp(Int(axis.value.rounded()), 0, maxIndex)
        axis.parameters = .deckSettle
        axis.target = Double(target)
        // Only momentum toward the target is kept; momentum away from it (a flick against an
        // end stop) is discarded so the edge resists rather than whips.
        let toward = (Double(target) - axis.value).sign == v.sign ? v : v * 0.25
        axis.velocity = DeckMath.clamp(toward, -Self.maxReleaseVelocity, Self.maxReleaseVelocity)
        phase = .settling
        return target
    }

    /// Cancelled touch (pinch took over, system gesture): settle to the nearest card.
    mutating func cancel() {
        guard count > 0 else { return }
        axis.parameters = .deckSettle
        axis.target = Double(DeckMath.clamp(Int(axis.value.rounded()), 0, maxIndex))
        phase = .settling
    }

    // MARK: Programmatic

    /// Animated move (tap a neighbour, accessibility action, keyboard, external selection).
    /// Starts from the visible pose and current velocity, so it interrupts cleanly.
    mutating func glide(to index: Int) {
        guard count > 0 else { return }
        axis.parameters = .deckGlide
        axis.target = Double(DeckMath.clamp(index, 0, maxIndex))
        phase = .settling
    }

    /// Non-animated placement (first appearance, mode switch, Reduce Motion).
    mutating func place(at index: Int) {
        guard count > 0 else { return }
        let i = DeckMath.clamp(index, 0, maxIndex)
        axis = SpringAxis(value: Double(i), parameters: .deckSettle)
        settledIndex = i
        phase = .idle
    }

    /// The collection changed underneath the deck (add, delete, rotation filter).
    mutating func updateCount(_ newCount: Int, focusing index: Int) {
        count = max(0, newCount)
        guard count > 0 else {
            axis = SpringAxis(value: 0, parameters: .deckSettle)
            settledIndex = 0
            phase = .idle
            return
        }
        place(at: index)
    }

    // MARK: Time

    mutating func step(_ dt: Double) -> DeckEvent? {
        guard phase == .settling else { return nil }
        axis.step(dt)
        guard axis.snapIfResting() else { return nil }
        phase = .idle
        let index = DeckMath.clamp(Int(axis.value.rounded()), 0, maxIndex)
        let changed = index != settledIndex
        settledIndex = index
        return .settled(index: index, changed: changed)
    }
}

// MARK: - Layout poses

enum DeckLayoutKind: String, CaseIterable { case coverFlow, stack, fan }

/// Everything needed to draw one card. Values are layout-space: points, degrees, 0...1 shading.
struct CardPose: Equatable {
    var x: Double = 0
    var y: Double = 0
    var scale: Double = 1
    /// Rotation around the vertical axis, degrees. Positive turns the card's right edge away.
    var yaw: Double = 0
    /// In-plane rotation, degrees, around `pivotY` (unit point, 0.5 = card centre).
    var roll: Double = 0
    var pivotY: Double = 0.5
    /// Larger is nearer the viewer. Used directly as zIndex.
    var depth: Double = 0
    /// Additional darkening from distance to the light, 0...1.
    var shade: Double = 0
    var opacity: Double = 1

    static func blend(_ a: CardPose, _ b: CardPose, _ t: Double) -> CardPose {
        if t <= 0 { return a }
        if t >= 1 { return b }
        let l = DeckMath.lerp
        return CardPose(x: l(a.x, b.x, t), y: l(a.y, b.y, t), scale: l(a.scale, b.scale, t),
                        yaw: l(a.yaw, b.yaw, t), roll: l(a.roll, b.roll, t),
                        pivotY: l(a.pivotY, b.pivotY, t), depth: l(a.depth, b.depth, t),
                        shade: l(a.shade, b.shade, t), opacity: l(a.opacity, b.opacity, t))
    }
}

/// Layout shape parameters, tunable live from the hidden tuning panel. Defaults are shipped values.
enum LayoutTuning {
    static var coverFlowYaw = 54.0          // degrees a neighbour hinges away
    static var coverFlowScaleFalloff = 0.15 // scale lost by the first neighbour
    static var stackDealRoll = 9.0          // degrees the dealt card turns in-plane
    static var stackDealYaw = 12.0          // degrees the dealt card turns toward the viewer
    static var fanSpread = 11.5             // degrees between fanned cards
    static var fanPivot = 2.35              // pivot below the card, in card heights from the top
}

enum DeckLayoutEngine {
    /// How far apart neighbouring cards sit, in points, for a given card width. Used to convert
    /// finger travel into deck units so the card under the finger tracks it one-to-one.
    static func stride(for layout: DeckLayoutKind, cardWidth w: Double) -> Double {
        switch layout {
        case .coverFlow: return w * 0.60
        case .stack: return w * 1.04
        // Arc length per card at the card centre: pivot 1.85 card heights below, 11.5° apart.
        // Matching it keeps the fanned card exactly under the finger.
        case .fan:
            let pivot = max(0.6, LayoutTuning.fanPivot)
            return w * (pivot - 0.5) * (86.0 / 59.0) * max(1, LayoutTuning.fanSpread) * .pi / 180
        }
    }

    /// Deterministic hand-placed misalignment so a stack reads as real cards, not a template.
    static func handJitter(_ index: Int) -> Double {
        let values = [0.0, 0.9, -0.7, 1.3, -1.1, 0.5, -1.4, 0.8]
        return values[((index % values.count) + values.count) % values.count]
    }

    static func pose(distance d: Double, index: Int, layout: DeckLayoutKind, cardWidth w: Double) -> CardPose {
        let m = abs(d)
        var p = CardPose()
        switch layout {
        case .coverFlow:
            // Cinematic: neighbours hinge away and tuck behind the hero; distant cards compress.
            let s = DeckMath.clamp(d, -1, 1)
            let rest = d - s
            p.x = w * (0.60 * s + 0.24 * rest)
            p.yaw = -s * LayoutTuning.coverFlowYaw
            p.scale = max(0.5, 1 - LayoutTuning.coverFlowScaleFalloff * abs(s) - 0.045 * abs(rest))
            p.y = 0
            p.depth = -m
            p.shade = 0.10 * abs(s) + 0.07 * abs(rest)
            p.opacity = 1 - DeckMath.smoothstep(3.0, 3.8, m)
        case .stack:
            if d >= 0 {
                // Waiting cards compress upward and backward under the weight of the top card.
                let c = d <= 1 ? d : 1 + (d - 1) * 0.55
                p.y = -w * 0.075 * c
                p.scale = max(0.78, 1 - 0.055 * c)
                p.roll = handJitter(index) * min(1, d)
                p.depth = -d
                p.shade = min(0.42, 0.13 * c)
                p.opacity = 1 - DeckMath.smoothstep(4.2, 5.0, d)
            } else {
                // The top card is dealt off to the left, lifting toward the viewer and turning.
                p.x = d * w * 1.06
                p.y = m * w * 0.05
                p.roll = d * LayoutTuning.stackDealRoll
                p.yaw = m * LayoutTuning.stackDealYaw
                p.scale = 1 + 0.025 * min(1, m)
                p.depth = 1 + m
                p.shade = 0
                p.opacity = 1 - DeckMath.smoothstep(1.35, 1.9, m)
            }
        case .fan:
            // A held hand of cards: rotation about a pivot far below, focused card raised.
            let spread = LayoutTuning.fanSpread
            let clamped = DeckMath.clamp(d, -3.6, 3.6)
            p.roll = clamped * spread
            p.pivotY = LayoutTuning.fanPivot
            p.y = -w * 0.07 * max(0, 1 - m)
            p.scale = max(0.82, 1 - 0.045 * min(m, 3))
            p.depth = -m
            p.shade = min(0.36, 0.09 * m)
            p.opacity = 1 - DeckMath.smoothstep(3.3, 3.9, m)
        }
        return p
    }

    /// Cards further than this from the centre are not built at all.
    static let visibleRadius = 4.2
}

// MARK: - Inspector flip

/// Continuous, scrubbable rotation around the card's vertical axis. The angle accumulates
/// (0, 180, 360...) so repeated flips in one direction keep spinning that way.
struct FlipModel: Equatable {
    private(set) var axis = SpringAxis(value: 0, parameters: .flip)
    private var origin: Double = 0
    private(set) var dragging = false

    static var flickThreshold = 240.0 // degrees per second

    var angle: Double { axis.value }
    var isAnimating: Bool { !dragging && !axis.isResting }

    /// True when the reverse face is the one facing the viewer at this instant.
    static func showsBack(_ angle: Double) -> Bool {
        let n = (angle.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return n > 90 && n < 270
    }
    var showsBack: Bool { Self.showsBack(angle) }
    /// The face the card will come to rest on.
    var restsOnBack: Bool { Self.showsBack(axis.target) }

    mutating func begin() {
        axis.target = axis.value
        axis.velocity = 0
        origin = axis.value
        dragging = true
    }

    mutating func drag(degrees: Double) {
        if !dragging { begin() }
        axis.value = origin + degrees
        axis.target = axis.value
        axis.velocity = 0
    }

    @discardableResult
    mutating func release(velocity: Double) -> Double {
        dragging = false
        axis.parameters = .flip
        let v = velocity.isFinite ? velocity : 0
        let base = (axis.value / 180).rounded(.down) * 180
        let target: Double
        if abs(v) >= Self.flickThreshold { target = v > 0 ? base + 180 : base }
        else { target = (axis.value / 180).rounded() * 180 }
        axis.target = target
        axis.velocity = DeckMath.clamp(v, -1400, 1400)
        return target
    }

    /// Tap / button flip: half a turn from wherever the card currently is.
    mutating func flip(direction: Double = 1) {
        dragging = false
        axis.parameters = .flip
        let resting = (axis.target / 180).rounded() * 180
        axis.target = resting + (direction >= 0 ? 180 : -180)
    }

    mutating func step(_ dt: Double) {
        guard !dragging else { return }
        axis.step(dt)
        axis.snapIfResting()
    }
}
