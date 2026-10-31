import Foundation

// Standalone test runner for ios/AroomaNative/DeckPhysics.swift (no XCTest dependency so it runs
// identically on the macOS CI runner and on Linux):
//   swiftc -O ios/AroomaNative/DeckPhysics.swift ios/Tests/DeckPhysics/main.swift -o /tmp/deck-tests && /tmp/deck-tests

var failures = 0
var passes = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String, line: Int = #line) {
    if condition() { passes += 1 } else { failures += 1; print("FAIL [line \(line)]: \(message)") }
}

let frame = 1.0 / 120.0

/// Runs the deck until it settles (or times out) and returns the settle event and elapsed time.
func runUntilSettled(_ deck: inout DeckModel, maxSeconds: Double = 4) -> (DeckEvent?, Double, Double) {
    var t = 0.0
    var peakOvershoot = 0.0
    let target = Double(deck.targetIndex)
    let startSide = (deck.position - target).sign
    while t < maxSeconds {
        if let e = deck.step(frame) { return (e, t, peakOvershoot) }
        t += frame
        if (deck.position - target).sign != startSide {
            peakOvershoot = max(peakOvershoot, abs(deck.position - target))
        }
        check(deck.position.isFinite, "position stays finite")
    }
    return (nil, t, peakOvershoot)
}

// 1. Centring: every layout puts the focused card exactly on the centre line at rest.
for layout in DeckLayoutKind.allCases {
    for width in [375.0, 390.0, 430.0].map({ $0 * 0.76 }) {
        let p = DeckLayoutEngine.pose(distance: 0, index: 3, layout: layout, cardWidth: width)
        check(abs(p.x) < 0.001, "\(layout) focused card x == 0 at width \(width), got \(p.x)")
        check(abs(p.yaw) < 0.001 && abs(p.roll) < 0.001, "\(layout) focused card is square to the viewer")
        check(abs(p.scale - 1) < 0.001, "\(layout) focused card at full scale")
        // The focused card is always the nearest to the viewer.
        for d in stride(from: -3.0, through: 3.0, by: 0.25) where abs(d) >= 0.5 {
            let other = DeckLayoutEngine.pose(distance: d, index: 4, layout: layout, cardWidth: width)
            if layout == .stack && d < 0 { continue } // dealt cards fly above by design
            check(other.depth < p.depth, "\(layout) card at \(d) sits behind the focused card")
        }
    }
}

// 2. Poses are continuous: no jump between adjacent sample points as a card crosses the centre.
for layout in DeckLayoutKind.allCases {
    var previous = DeckLayoutEngine.pose(distance: -3, index: 0, layout: layout, cardWidth: 300)
    var d = -3.0
    while d <= 3 {
        d += 0.01
        let p = DeckLayoutEngine.pose(distance: d, index: 0, layout: layout, cardWidth: 300)
        check(abs(p.x - previous.x) < 12, "\(layout) x is continuous at \(d)")
        check(abs(p.yaw - previous.yaw) < 3 && abs(p.roll - previous.roll) < 3, "\(layout) angles continuous at \(d)")
        check(abs(p.scale - previous.scale) < 0.02, "\(layout) scale continuous at \(d)")
        previous = p
    }
}

// 3. Rest snap is exact (selected card centred to the bit, not "within epsilon").
do {
    var deck = DeckModel(count: 20, index: 5)
    deck.hold(); deck.drag(translation: 0.62); deck.release(velocity: 0)
    let (event, time, _) = runUntilSettled(&deck)
    check(event == .settled(index: 6, changed: true), "slow release past half goes to the next card, got \(String(describing: event))")
    check(deck.position == 6.0, "exactly centred, got \(deck.position)")
    check(time < 1.2, "settles promptly (\(time)s)")
}

// 4. Slow release short of half returns; flick commits one card; nothing skips.
do {
    var deck = DeckModel(count: 20, index: 5)
    deck.hold(); deck.drag(translation: 0.3); deck.release(velocity: 0.1)
    check(runUntilSettled(&deck).0 == .settled(index: 5, changed: false), "short slow drag springs back")

    deck.hold(); deck.drag(translation: 0.05); deck.release(velocity: 9)
    check(runUntilSettled(&deck).0 == .settled(index: 6, changed: true), "a violent flick moves exactly one card")

    deck.hold(); deck.drag(translation: -0.05); deck.release(velocity: -40)
    check(runUntilSettled(&deck).0 == .settled(index: 5, changed: true), "violent flick back moves exactly one card")
}

// 5. Release target policy never chooses a card outside the two straddling the centre line.
do {
    var rng = SystemRandomNumberGenerator()
    for _ in 0..<5000 {
        let p = Double.random(in: 0...23, using: &rng)
        let v = Double.random(in: -30...30, using: &rng)
        let t = DeckModel.releaseTarget(position: p, velocity: v, count: 24)
        let ok = Double(t) == floor(p) || Double(t) == ceil(p) ||
            (floor(p) == ceil(p) && abs(Double(t) - p) == 1)
        check(ok, "release at \(p) v \(v) chose \(t)")
    }
}

// 6. 200 rapid alternating swipes on a 24-card fixture, each interrupting the previous settle.
// No uncommanded skips, the pose is continuous across every interruption, and at rest the
// deck is always on an integer that matches the last committed target.
do {
    var deck = DeckModel(count: 24, index: 12)
    var rng = SystemRandomNumberGenerator()
    var expected = 12
    for swipe in 0..<200 {
        let before = deck.position
        deck.hold()
        check(deck.position == before, "touch-down keeps the exact visible pose (swipe \(swipe))")
        let direction: Double = swipe % 3 == 0 ? -1 : (swipe % 2 == 0 ? 1 : -1)
        let travel = direction * Double.random(in: 0.1...0.9, using: &rng)
        // Move the finger in a few increments, sometimes reversing mid-drag.
        deck.drag(translation: travel * 0.5)
        if swipe % 5 == 0 { deck.drag(translation: -travel * 0.2) }
        deck.drag(translation: travel)
        let committed = deck.release(velocity: direction * Double.random(in: 0...12, using: &rng))
        check(abs(Double(committed) - deck.position) <= 1.0001, "commit is adjacent to visible pose (swipe \(swipe))")
        expected = committed
        // Let it settle partially, then interrupt (unless last swipe).
        let frames = swipe == 199 ? 1000 : Int.random(in: 0...30, using: &rng)
        for _ in 0..<frames {
            let prev = deck.position
            _ = deck.step(frame)
            check(abs(deck.position - prev) < 0.12, "no visible jump within a frame (swipe \(swipe))")
        }
    }
    check(deck.phase == .idle, "final swipe settles")
    check(deck.position == Double(expected), "deck rests on the last committed card \(expected), at \(deck.position)")
}

// 7. End stops resist and return.
do {
    var deck = DeckModel(count: 5, index: 0)
    deck.hold(); deck.drag(translation: -3)
    check(deck.position < 0 && deck.position > -0.45, "rubber band limits travel past the first card: \(deck.position)")
    deck.release(velocity: -20)
    let (event, _, _) = runUntilSettled(&deck)
    check(event == .settled(index: 0, changed: false), "returns to the first card")

    deck.place(at: 4)
    deck.hold(); deck.drag(translation: 5)
    check(deck.position > 4 && deck.position < 4.45, "rubber band at the last card: \(deck.position)")
    deck.release(velocity: 30)
    check(runUntilSettled(&deck).0 == .settled(index: 4, changed: false), "returns to the last card")
}

// 8. Overshoot is bounded so a neighbour never visually takes the centre during a settle.
do {
    var worst = 0.0
    for v in stride(from: 0.0, through: 60.0, by: 2.0) {
        var deck = DeckModel(count: 10, index: 4)
        deck.hold(); deck.drag(translation: 0.1); deck.release(velocity: v)
        let (_, _, overshoot) = runUntilSettled(&deck)
        worst = max(worst, overshoot)
    }
    check(worst < 0.35, "worst overshoot past target \(worst) cards stays below 0.35")
    print("  info: worst settle overshoot \(String(format: "%.3f", worst)) cards")
}

// 9. Single card and empty decks are inert and safe.
do {
    var one = DeckModel(count: 1, index: 0)
    one.hold(); one.drag(translation: 2); one.release(velocity: 10)
    check(runUntilSettled(&one).0 == .settled(index: 0, changed: false), "single card returns home")
    var none = DeckModel(count: 0)
    none.hold(); none.drag(translation: 2); none.release(velocity: 10)
    check(none.step(frame) == nil && none.position == 0, "empty deck does nothing")
}

// 10. Count changes keep a valid focus.
do {
    var deck = DeckModel(count: 8, index: 7)
    deck.updateCount(3, focusing: 7)
    check(deck.position == 2 && deck.settledIndex == 2, "removing cards clamps focus")
    deck.updateCount(0, focusing: 0)
    check(deck.count == 0 && deck.position == 0, "empty after deleting all")
}

// 11. Programmatic glide interrupts a settle from the visible pose.
do {
    var deck = DeckModel(count: 10, index: 2)
    deck.glide(to: 8)
    for _ in 0..<12 { _ = deck.step(frame) }
    let mid = deck.position
    check(mid > 2 && mid < 8, "glide is in flight")
    deck.glide(to: 1)
    let after = deck.position
    check(after == mid, "re-targeting does not teleport")
    check(runUntilSettled(&deck).0 == .settled(index: 1, changed: true), "re-targeted glide lands")
}

// 12. Flip: scrubbing through 90 degrees swaps faces exactly at the edge-on angle, both ways.
do {
    check(!FlipModel.showsBack(89.9) && FlipModel.showsBack(90.1), "front until edge-on")
    check(FlipModel.showsBack(269.9) && !FlipModel.showsBack(270.1), "back until edge-on on the way round")
    check(FlipModel.showsBack(-120) && !FlipModel.showsBack(-60), "negative angles")

    var flip = FlipModel()
    flip.begin(); flip.drag(degrees: 70); flip.release(velocity: 0)
    for _ in 0..<600 { flip.step(frame) }
    check(flip.angle == 0 && !flip.showsBack, "short scrub returns to the front")

    flip.begin(); flip.drag(degrees: 110); flip.release(velocity: 0)
    for _ in 0..<600 { flip.step(frame) }
    check(flip.angle == 180 && flip.showsBack, "scrub past edge-on lands on the back")

    flip.begin(); flip.drag(degrees: 20); flip.release(velocity: 900)
    check(flip.restsOnBack == false, "a flick from the back continues to the front (360)")
    for _ in 0..<600 { flip.step(frame) }
    check(flip.angle == 360, "keeps spinning the same way, got \(flip.angle)")

    flip.flip()
    for _ in 0..<600 { flip.step(frame) }
    check(flip.angle == 540 && flip.showsBack, "button flip is half a turn")
}

// 13. Layout morph blending is an identity at the ends.
do {
    let a = DeckLayoutEngine.pose(distance: 1.4, index: 1, layout: .coverFlow, cardWidth: 280)
    let b = DeckLayoutEngine.pose(distance: 1.4, index: 1, layout: .fan, cardWidth: 280)
    check(CardPose.blend(a, b, 0) == a && CardPose.blend(a, b, 1) == b, "blend endpoints")
    let mid = CardPose.blend(a, b, 0.5)
    check(abs(mid.x - (a.x + b.x) / 2) < 0.0001, "blend midpoint")
}

// 14. Frame-rate independence: 60 Hz and 120 Hz produce the same trajectory.
do {
    var a = SpringAxis(value: 0, target: 1, parameters: .deckSettle)
    var b = a
    for _ in 0..<30 { a.step(1.0 / 60.0) }
    for _ in 0..<60 { b.step(1.0 / 120.0) }
    check(abs(a.value - b.value) < 0.002, "60/120 Hz agree: \(a.value) vs \(b.value)")
}

print("Deck physics: \(passes) checks passed, \(failures) failed")
exit(failures == 0 ? 0 : 1)
