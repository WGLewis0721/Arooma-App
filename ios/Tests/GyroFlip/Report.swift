import Foundation

// MARK: - A/B evaluation on identical traces
//
// Both recognizers see the same generated trials, in the same order. Results are counts and timings from SYNTHETIC
// traces (see Corpus.swift). They say where each recognizer breaks under the stated models; they are not
// physical accuracy.

struct FlickStats {
    /// For trials with no flip: the rejection reason the recognizer logged last, grouped by its first words.
    var missReasons: [String: Int] = [:]
    var trials = 0
    var recognized = 0
    var missed = 0
    var wrongDirection = 0
    var double = 0
    var latencies: [Double] = []
    /// Per grid cell (angle bin, duration bin): trials and recognized trials.
    var cellTrials: [[Int]] = Array(repeating: Array(repeating: 0, count: Corpus.durationBins.count), count: Corpus.angleBins.count)
    var cellHits: [[Int]] = Array(repeating: Array(repeating: 0, count: Corpus.durationBins.count), count: Corpus.angleBins.count)
}

struct OrdinaryStats {
    var trials = 0
    var falseTrials = 0
    var falseEvents = 0
}

/// Parameters of the natural-flick prior. Stated, not fitted. The total angle is drawn uniformly, and so is the peak
/// rate (2 to 5 rad/s, about 115 to 290 degrees/s, a deliberate wrist flick). The duration follows from the
/// minimum-jerk shape (peak = 1.875 x angle / duration), and draws outside 0.12 to 0.40 s are redrawn.
enum FlickPrior {
    static let angle = 0.35...1.2
    static let peak = 2.0...5.0
    static let duration = 0.12...0.40
}

/// Generates the flick trials for one seed range: `perSign` positive and `perSign` negative trials.
func makeFlickTrials(seedBase: UInt64, perSign: Int) -> [(trial: CorpusTrial, angleBin: Int?, durationBin: Int?)] {
    var out: [(CorpusTrial, Int?, Int?)] = []
    var rng = CorpusRandom(seed: seedBase)
    for i in 0..<perSign {
        for sign in [1.0, -1.0] {
            var a = 0.0, d = 0.0
            repeat {
                a = rng.range(FlickPrior.angle.lowerBound, FlickPrior.angle.upperBound)
                let peak = rng.range(FlickPrior.peak.lowerBound, FlickPrior.peak.upperBound)
                d = 1.875 * a / peak
            } while !FlickPrior.duration.contains(d)
            let ret = rng.next() < 0.5
            let trial = Corpus.naturalFlick(seed: seedBase, index: i * 2 + (sign > 0 ? 0 : 1), sign: sign,
                                            angle: a, duration: d, returnStroke: ret)
            let ab = Corpus.angleBins.firstIndex { $0.1.contains(a) }
            let db = Corpus.durationBins.firstIndex { $0.1.contains(d) }
            out.append((trial, ab, db))
        }
    }
    return out
}

/// Runs a recognizer over flick trials.
func evaluateFlicks<R: FlipRecognizer>(_ trials: [(trial: CorpusTrial, angleBin: Int?, durationBin: Int?)],
                                       recognizer make: () -> R) -> FlickStats {
    var stats = FlickStats()
    for item in trials {
        var r = make()
        let result = replay(item.trial, &r)
        stats.trials += 1
        let expected = item.trial.expected.first ?? .positive
        let hit = result.events.count == 1 && result.events[0].direction == expected
        if result.events.count == 0 {
            stats.missed += 1
            let last = r.outcomes.last(where: { $0.hasPrefix("rejected") || $0.hasPrefix("missed") }) ?? "no gesture logged"
            stats.missReasons[reasonGroup(last), default: 0] += 1
        }
        if result.events.count >= 2 { stats.double += 1 }
        if result.events.count == 1 && result.events[0].direction != expected { stats.wrongDirection += 1 }
        if hit {
            stats.recognized += 1
            if let peak = item.trial.peakTimes.first { stats.latencies.append(result.events[0].time - peak) }
        }
        if let ab = item.angleBin, let db = item.durationBin {
            stats.cellTrials[ab][db] += 1
            if hit { stats.cellHits[ab][db] += 1 }
        }
    }
    return stats
}

/// Runs a recognizer over ordinary-motion trials, per family.
func evaluateOrdinary<R: FlipRecognizer>(seedBase: UInt64, trialsPerFamily: Int, recognizer make: () -> R) -> [String: OrdinaryStats] {
    var out: [String: OrdinaryStats] = [:]
    for family in CorpusFamily.allCases where family != .naturalPositive && family != .naturalNegative {
        var st = OrdinaryStats()
        for i in 0..<trialsPerFamily {
            var r = make()
            let trial = Corpus.ordinary(family, seed: seedBase, index: i)
            let result = replay(trial, &r)
            st.trials += 1
            if !result.events.isEmpty { st.falseTrials += 1; st.falseEvents += result.events.count }
        }
        out[family.rawValue] = st
    }
    return out
}

/// Groups a log entry such as "rejected: too small, turn 0.48" into "too small", so tallies stay readable.
func reasonGroup(_ outcome: String) -> String {
    var text = outcome
    for prefix in ["rejected: ", "missed: ", "ignored: "] where text.hasPrefix(prefix) { text = String(text.dropFirst(prefix.count)) }
    let stop = text.firstIndex(where: { $0 == "," || $0 == "(" || $0.isNumber }) ?? text.endIndex
    let group = text[..<stop].trimmingCharacters(in: .whitespaces)
    return group.isEmpty ? outcome : group
}

func pct(_ n: Int, _ d: Int) -> String { d == 0 ? "-" : String(format: "%.0f%%", 100 * Double(n) / Double(d)) }
func ms(_ v: Double?) -> String { v.map { String(format: "%.0f ms", $0 * 1000) } ?? "-" }

/// Prints the comparison as text: flick outcomes, latency, the sensitivity grid and ordinary-motion false events.
func printComparison(label: String, seedBase: UInt64, perSign: Int, ordinaryTrials: Int) {
    let flicks = makeFlickTrials(seedBase: seedBase, perSign: perSign)
    let positives = flicks.filter { $0.trial.expected.first == .positive }
    let negatives = flicks.filter { $0.trial.expected.first == .negative }
    print("\n=== \(label): seeds from \(seedBase), \(perSign) flicks per direction, \(ordinaryTrials) ordinary trials per family ===")
    print("prior: total angle \(FlickPrior.angle) rad, peak \(FlickPrior.peak) rad/s, duration \(FlickPrior.duration) s, half with a return stroke")

    let base = { BaselineRecognizer() }
    let pulse = { PulseRecognizer() }
    _ = pulse
    let bp = evaluateFlicks(positives, recognizer: base), bn = evaluateFlicks(negatives, recognizer: base)
    let pp = evaluateFlicks(positives, recognizer: pulse), pn = evaluateFlicks(negatives, recognizer: pulse)
    let rows: [(name: String, p: FlickStats, n: FlickStats)] = [("PR #43", bp, bn), ("pulse", pp, pn)]

    print("\nDeliberate flicks (exactly one flip, correct direction):")
    print("| recognizer | + recognized | - recognized | missed | wrong direction | double flips | latency p50 | latency p95 |")
    print("| --- | --- | --- | --- | --- | --- | --- | --- |")
    for (name, p, n) in rows {
        let lat = p.latencies + n.latencies
        print("| \(name) | \(pct(p.recognized, p.trials)) (\(p.recognized)/\(p.trials)) | \(pct(n.recognized, n.trials)) (\(n.recognized)/\(n.trials)) | \(p.missed + n.missed) | \(p.wrongDirection + n.wrongDirection) | \(p.double + n.double) | \(ms(percentile(lat, 0.5))) | \(ms(percentile(lat, 0.95))) |")
    }

    print("\nWhy flicks were missed (last rejection logged by each recognizer, all missed flicks):")
    for (name, p, n) in rows {
        var tally: [String: Int] = [:]
        for (k, v) in p.missReasons { tally[k, default: 0] += v }
        for (k, v) in n.missReasons { tally[k, default: 0] += v }
        let line = tally.sorted { $0.value > $1.value }.map { "\($0.key) \($0.value)" }.joined(separator: ", ")
        print("- \(name): \(line.isEmpty ? "none" : line)")
    }

    print("\nSensitivity grid, both directions (recognized / trials), rows total angle (rad), columns duration (s):")
    for (name, _, _) in rows {
        let all = name == "PR #43" ? (bp, bn) : (pp, pn)
        print("\n\(name):")
        var header = "| angle \\ duration |"
        for d in Corpus.durationBins { header += " \(d.0) |" }
        print(header)
        print("| --- | --- | --- | --- |")
        for (ai, a) in Corpus.angleBins.enumerated() {
            var line = "| \(a.0) |"
            for di in 0..<Corpus.durationBins.count {
                let trials = all.0.cellTrials[ai][di] + all.1.cellTrials[ai][di]
                let hits = all.0.cellHits[ai][di] + all.1.cellHits[ai][di]
                line += " \(pct(hits, trials)) (\(hits)/\(trials)) |"
            }
            print(line)
        }
    }

    print("\nOrdinary motion, flip events per family (trials with an event / trials):")
    let baseOrd = evaluateOrdinary(seedBase: seedBase &+ 50_000, trialsPerFamily: ordinaryTrials, recognizer: base)
    let pulseOrd = evaluateOrdinary(seedBase: seedBase &+ 50_000, trialsPerFamily: ordinaryTrials, recognizer: pulse)
    print("| family | PR #43 | pulse |")
    print("| --- | --- | --- |")
    var baseTotal = 0, pulseTotal = 0, totalTrials = 0
    for family in CorpusFamily.allCases where family != .naturalPositive && family != .naturalNegative {
        let b = baseOrd[family.rawValue]!, p = pulseOrd[family.rawValue]!
        baseTotal += b.falseEvents; pulseTotal += p.falseEvents; totalTrials += b.trials
        print("| \(family.rawValue) | \(b.falseTrials)/\(b.trials) | \(p.falseTrials)/\(p.trials) |")
    }
    print("All families: PR #43 \(baseTotal) events in \(totalTrials) trials (\(String(format: "%.2f", 100 * Double(baseTotal) / Double(totalTrials))) per 100); pulse \(pulseTotal) events (\(String(format: "%.2f", 100 * Double(pulseTotal) / Double(totalTrials))) per 100)")
}

// MARK: - Replay of a device trace (gyro-tests --replay <file>)

/// Replays a recorded owner trace through both recognizers and prints each one's events beside the live app's events
/// from the same recording. Returns the process exit code: 0 when the file was read, 2 when it could not be.
func replayFile(_ path: String) -> Int32 {
    guard let data = FileManager.default.contents(atPath: path),
          let text = String(data: data, encoding: .utf8),
          let file = GyroTraceCodec.decode(text) else {
        print("cannot read a gyro trace from \(path)")
        return 2
    }
    let trial = CorpusTrial(family: "device trace", samples: file.samples, expected: [], peakTimes: [],
                            angle: 0, duration: 0, returnStroke: false)
    var baseline = BaselineRecognizer()
    var pulse = PulseRecognizer()
    let origin = file.samples.first?.timestamp ?? 0
    let b = replay(trial, &baseline), p = replay(trial, &pulse)
    print("trace: \(file.samples.count) samples over \(String(format: "%.2f", (file.samples.last?.timestamp ?? origin) - origin)) s. \(file.note)")
    print("live app events: \(file.liveEvents.isEmpty ? "none" : file.liveEvents.map { "\($0.label) at \(String(format: "%.2f", $0.time - origin))" }.joined(separator: ", "))")
    print("PR #43 classifier: \(b.events.isEmpty ? "none" : b.events.map { "\($0.direction == .positive ? "+" : "-") at \(String(format: "%.2f", $0.time))" }.joined(separator: ", "))")
    print("pulse recognizer:  \(p.events.isEmpty ? "none" : p.events.map { "\($0.direction == .positive ? "+" : "-") at \(String(format: "%.2f", $0.time))" }.joined(separator: ", "))")
    return 0
}

// MARK: - Owner calibration over labeled sessions (gyro-tests --calibrate <folder>)
//
// Each trace file is one session recorded in owner tools with a label (flick+, flick-, ordinary) and the number of
// actions the owner performed. The sweep replays every session through the pulse recognizer for each pair of
// thresholds and reports how many flicks were recognized (with the right face) and how many ordinary movements
// flipped the card. The target is the plan's: at least 95% of flicks, no wrong faces, at most 1 accidental flip per
// 100 ordinary actions.

func calibrate(directory path: String) -> Int32 {
    let fm = FileManager.default
    guard let names = try? fm.contentsOfDirectory(atPath: path) else {
        print("cannot read the folder \(path)")
        return 2
    }
    var flickSessions: [(name: String, file: GyroTraceFile)] = []
    var ordinarySessions: [(name: String, file: GyroTraceFile)] = []
    var skipped = 0
    for name in names.sorted() where name.hasSuffix(".jsonl") {
        let full = (path as NSString).appendingPathComponent(name)
        guard let data = fm.contents(atPath: full), let text = String(data: data, encoding: .utf8),
              let file = GyroTraceCodec.decode(text) else { skipped += 1; continue }
        switch file.label {
        case "flick+", "flick-": flickSessions.append((name, file))
        case "ordinary": ordinarySessions.append((name, file))
        default: skipped += 1
        }
    }
    print("sessions: \(flickSessions.count) flick, \(ordinarySessions.count) ordinary; \(skipped) skipped (unlabeled or not a trace)")
    guard !flickSessions.isEmpty, !ordinarySessions.isEmpty else {
        print("need at least one flick session (label flick+ or flick-) and one ordinary session (label ordinary).")
        return 2
    }
    let flickActions = flickSessions.reduce(0) { $0 + max(1, $1.file.expected) }
    let ordinaryActions = ordinarySessions.reduce(0) { $0 + max(1, $1.file.expected) }
    print("flicks performed: \(flickActions); ordinary actions performed: \(ordinaryActions)")
    print("target: at least 95% of flicks recognized with the right face, no wrong faces, at most 1 accidental flip per 100 ordinary actions\n")
    print("| turn (rad) | peak (rad/s) | flicks recognized | wrong face | accidental per 100 ordinary | meets target |")
    print("| --- | --- | --- | --- | --- | --- |")

    // Among settings that meet the target, prefer the most recognition, then the most conservative thresholds.
    var best: (turn: Double, peak: Double, recognized: Double)? = nil
    for turn in [0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55] {
        for peak in [1.8, 2.0, 2.2, 2.4] {
            var c = GyroPulseConfiguration.shipped
            c.minTurn = turn
            c.peakRate = peak
            var correct = 0, wrong = 0, accidental = 0
            for session in flickSessions {
                let trial = CorpusTrial(family: session.name, samples: session.file.samples, expected: [], peakTimes: [],
                                        angle: 0, duration: 0, returnStroke: false)
                var r = PulseRecognizer(c)
                let events = replay(trial, &r).events
                let wantPositive = session.file.label == "flick+"
                for e in events {
                    if (e.direction == .positive) == wantPositive { correct += 1 } else { wrong += 1 }
                }
            }
            for session in ordinarySessions {
                let trial = CorpusTrial(family: session.name, samples: session.file.samples, expected: [], peakTimes: [],
                                        angle: 0, duration: 0, returnStroke: false)
                var r = PulseRecognizer(c)
                accidental += replay(trial, &r).events.count
            }
            let recognized = Double(correct) / Double(flickActions)
            let per100 = Double(accidental) / Double(ordinaryActions) * 100
            let meets = recognized >= 0.95 && wrong == 0 && per100 <= 1.0
            print(String(format: "| %.2f | %.1f | %d / %d (%.0f%%) | %d | %.2f | %@ |",
                         turn, peak, correct, flickActions, recognized * 100, wrong, per100, meets ? "yes" : "no"))
            if meets {
                let better = best.map { recognized > $0.recognized || (recognized == $0.recognized && (turn > $0.turn || (turn == $0.turn && peak > $0.peak))) } ?? true
                if better { best = (turn, peak, recognized) }
            }
        }
    }
    if let best {
        print(String(format: "\nhighest recognition that meets the target: turn %.2f rad, peak %.1f rad/s (%.0f%% of flicks); ties go to the stricter thresholds", best.turn, best.peak, best.recognized * 100))
    } else {
        print("\nno setting in this grid meets the target. Look at the table: wrong faces point at the direction, misses at the thresholds.")
    }
    return 0
}

// MARK: - Turn sweep (the one threshold that decides recognition versus accidental flips)

/// Recognition on both seed ranges and accidental flips across every ordinary family, for each minimum turn.
/// Development seeds chose the default; held-out seeds are reported only.
func printTurnSweep() {
    print("\n=== minimum turn sweep, pulse recognizer (peak 2.2 rad/s; development chose 0.35, held-out is reported) ===")
    print("| turn (rad) | recognized, dev | recognized, held-out | wrong face, dev / held-out | accidental per 100 ordinary, dev | held-out |")
    print("| --- | --- | --- | --- | --- | --- |")
    let dev = makeFlickTrials(seedBase: 1, perSign: 200), held = makeFlickTrials(seedBase: 9000, perSign: 200)
    let families = CorpusFamily.allCases.filter { $0 != .naturalPositive && $0 != .naturalNegative }
    for turn in [0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55] {
        var c = GyroPulseConfiguration.shipped
        c.minTurn = turn
        let make = { PulseRecognizer(c) }
        func recognized(_ set: [(trial: CorpusTrial, angleBin: Int?, durationBin: Int?)]) -> (Int, Int, Int) {
            let p = evaluateFlicks(set.filter { $0.trial.expected.first == .positive }, recognizer: make)
            let n = evaluateFlicks(set.filter { $0.trial.expected.first == .negative }, recognizer: make)
            return (p.recognized + n.recognized, p.trials + n.trials, p.wrongDirection + n.wrongDirection)
        }
        func accidental(_ seed: UInt64) -> (Int, Int) {
            var events = 0, trials = 0
            for family in families {
                for i in 0..<100 { var r = make(); events += replay(Corpus.ordinary(family, seed: seed &+ 50_000, index: i), &r).events.count; trials += 1 }
            }
            return (events, trials)
        }
        let d = recognized(dev), h = recognized(held)
        let da = accidental(1), ha = accidental(9000)
        print(String(format: "| %.2f | %d / %d (%.0f%%) | %d / %d (%.0f%%) | %d / %d | %.2f | %.2f |",
                     turn, d.0, d.1, Double(d.0) / Double(d.1) * 100, h.0, h.1, Double(h.0) / Double(h.1) * 100,
                     d.2, h.2, Double(da.0) / Double(da.1) * 100, Double(ha.0) / Double(ha.1) * 100))
    }
}
