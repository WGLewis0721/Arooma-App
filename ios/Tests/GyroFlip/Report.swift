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
