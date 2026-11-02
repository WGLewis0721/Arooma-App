import Foundation

// MARK: - Gyro trace file (owner tools)
//
// A plain JSON Lines recording of the motion samples the wrist-flick recognizers consumed, plus the live flip events
// the app produced while recording. It is written only in owner-tools builds, only when the owner starts a recording,
// and only to the app's own Documents folder. It is never uploaded. The same file is replayed offline by
// ios/Tests/GyroFlip (`gyro-tests --replay <file>`), so PR #43 and the pulse recognizer can be compared on the
// identical physical motion.
//
// Format (version 1):
//   {"format":"arooma-gyro-trace","version":1,"label":"flick+","expected":20,"note":"..."}   one header line
//   {"t":123.456789,"w":[x,y,z],"a":[x,y,z]}                          one line per sample (rad/s and g)
//   {"live":"FLIP +","t":123.567890,"latency":0.142}                  one line per flip the live app produced

struct GyroTraceFile {
    /// What the owner did in this session: "flick+", "flick-" or "ordinary". Empty when unknown.
    var label: String
    /// How many actions the owner performed: flicks for a flick session, ordinary movements for an ordinary one.
    var expected: Int
    var note: String
    var samples: [GyroSample]
    /// Flip events the app produced while recording (label, sample time, seconds from the peak when known).
    var liveEvents: [(label: String, time: Double, latency: Double?)]
}

enum GyroTraceCodec {
    static let format = "arooma-gyro-trace"
    static let version = 1

    static func encode(_ file: GyroTraceFile) -> String {
        var lines: [String] = []
        lines.append("{\"format\":\"\(format)\",\"version\":\(version),\"label\":\"\(escape(file.label))\",\"expected\":\(file.expected),\"note\":\"\(escape(file.note))\"}")
        for s in file.samples {
            lines.append(String(format: "{\"t\":%.6f,\"w\":[%.5f,%.5f,%.5f],\"a\":[%.5f,%.5f,%.5f]}",
                                s.timestamp, s.rotationRate.x, s.rotationRate.y, s.rotationRate.z,
                                s.userAcceleration.x, s.userAcceleration.y, s.userAcceleration.z))
        }
        for e in file.liveEvents {
            var line = "{\"live\":\"\(escape(e.label))\",\"t\":\(String(format: "%.6f", e.time))"
            if let l = e.latency { line += ",\"latency\":\(String(format: "%.4f", l))" }
            lines.append(line + "}")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Reads a trace. Unknown lines are skipped, so later versions can add fields without breaking older replays.
    /// Returns nil only when the header is missing or the file is not a trace at all.
    static func decode(_ text: String) -> GyroTraceFile? {
        var note = ""
        var label = ""
        var expected = 0
        var samples: [GyroSample] = []
        var live: [(label: String, time: Double, latency: Double?)] = []
        var sawHeader = false
        for raw in text.split(whereSeparator: \.isNewline) {
            guard let data = raw.data(using: .utf8),
                  let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { continue }
            if let format = object["format"] as? String {
                guard format == Self.format else { return nil }
                sawHeader = true
                note = object["note"] as? String ?? ""
                label = object["label"] as? String ?? ""
                expected = Int(number(object["expected"]) ?? 0)
            } else if let w = vector(object["w"]), let a = vector(object["a"]), let t = number(object["t"]) {
                samples.append(GyroSample(timestamp: t,
                                          rotationRate: GyroVector(x: w[0], y: w[1], z: w[2]),
                                          userAcceleration: GyroVector(x: a[0], y: a[1], z: a[2])))
            } else if let label = object["live"] as? String, let t = number(object["t"]) {
                live.append((label, t, number(object["latency"])))
            }
        }
        guard sawHeader else { return nil }
        return GyroTraceFile(label: label, expected: expected, note: note, samples: samples, liveEvents: live)
    }

    private static func vector(_ value: Any?) -> [Double]? {
        guard let array = value as? [Any], array.count == 3 else { return nil }
        let numbers = array.compactMap { number($0) }
        return numbers.count == 3 ? numbers : nil
    }

    private static func number(_ value: Any?) -> Double? {
        if let d = value as? Double { return d }
        if let n = value as? NSNumber { return n.doubleValue }
        return nil
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
