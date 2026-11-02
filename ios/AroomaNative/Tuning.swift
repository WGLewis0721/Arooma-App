import SwiftUI
import UIKit
import Observation

// MARK: - Live tuning
//
// Every physics, layout, tilt and foil constant the owner may want to refine on an iPhone lives
// here, with today's shipped value as its default. Values persist in UserDefaults, apply
// immediately, and can be copied out as plain text ("key = value" lines) and pasted back.
// The panel is hidden: long-press the Version row in View & Style. It opens on five presets
// ("feels") and five quick-adjust sliders; every individual value is under Advanced.

/// Where this build came from. Owner tools (the tuning panel, the frame-time readout) are for
/// Debug and TestFlight only; an App Store build never exposes them (App Review 2.3.1: no
/// hidden or undocumented features). Tuned values already saved still apply in every build.
enum BuildChannel {
    static let allowsOwnerTools: Bool = {
        #if DEBUG
        return true
        #else
        // TestFlight installs carry a sandbox receipt; App Store installs do not.
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }()
}

/// Tilt values read by MotionField / TiltLean.
enum TiltTuning {
    static var rangeDegrees = 45.0     // soft limit of the effective rotation
    static var gain = 1.0              // rotation multiplier before the soft limit
    static var smoothingMS = 60.0      // display-rate interpolation time constant (0 = none)
    static var driftSeconds = 0.0      // baseline re-centring time constant; 0 = Off (fixed)
    static var sampleRateHz = 60.0     // Core Motion request rate
    static var leanMaxDegrees = 4.0    // hero card's physical lean at full tilt
}

/// Foil values read by LiveFoil and HoloFoil.metal.
enum FoilTuning {
    static var lightTravelX = 1.0
    static var lightTravelY = 1.0
    static var eyeDistance = 2.1       // card heights; nearer = highlight moves more per degree
    static var sheenWidth = 18.0       // Blinn exponent; lower = wider sheen
    static var glintTightness = 220.0  // Blinn exponent of the hot core
    static var diffractionStrength = 0.34
    static var diffractionPhase = 2.4
    static var sheenStrength = 1.0
    static var glintStrength = 1.0
    static var glitterStrength = 0.9
    static var idleDrift = 0.0         // 0 = off; never larger than device motion
}

struct TuningSpec: Identifiable {
    let id: String
    let group: String
    let label: String
    let range: ClosedRange<Double>
    let step: Double
    let defaultValue: Double
    let digits: Int
    var offAtZero = false
    let apply: (Double) -> Void
}

// MARK: - Presets ("feels")

/// A named starting point. Only values that differ from the shipped defaults are listed.
struct TuningPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let summary: String
    let symbol: String
    let values: [String: Double]

    static let signature = TuningPreset(id: "signature", name: "Signature", summary: "The shipped balance: weighted cards, gentle foil.",
                                        symbol: "seal", values: [:])
    static let silk = TuningPreset(id: "silk", name: "Silk", summary: "Slow, smooth and calm. Broad soft sheen.",
                                   symbol: "wind", values: [
        "physics.settle.response": 0.56, "physics.settle.damping": 0.92,
        "physics.glide.response": 0.62, "physics.glide.damping": 0.95,
        "physics.press.response": 0.30, "physics.press.damping": 0.80,
        "physics.flip.response": 0.64, "physics.flip.damping": 0.90,
        "physics.morph.response": 0.74, "physics.morph.damping": 0.92,
        "physics.deck.flickThreshold": 1.0, "physics.deck.maxReleaseVelocity": 6,
        "tilt.gain": 0.85, "tilt.smoothing": 110,
        "foil.sheenWidth": 11, "foil.glintTightness": 150, "foil.diffractionStrength": 0.26,
        "foil.sheenStrength": 1.15, "foil.glintStrength": 0.8, "foil.glitterStrength": 0.5
    ])
    static let crisp = TuningPreset(id: "crisp", name: "Crisp", summary: "Quick, snappy settles. Tight, bright glints.",
                                    symbol: "bolt", values: [
        "physics.settle.response": 0.36, "physics.settle.damping": 0.80,
        "physics.glide.response": 0.42, "physics.glide.damping": 0.86,
        "physics.press.response": 0.18, "physics.press.damping": 0.62,
        "physics.flip.response": 0.42, "physics.flip.damping": 0.76,
        "physics.morph.response": 0.50, "physics.morph.damping": 0.82,
        "physics.deck.flickThreshold": 0.55, "physics.deck.maxReleaseVelocity": 9,
        "physics.flip.flickThreshold": 200,
        "tilt.smoothing": 30, "tilt.sampleRate": 120,
        "foil.sheenWidth": 26, "foil.glintTightness": 340, "foil.glintStrength": 1.2
    ])
    static let vivid = TuningPreset(id: "vivid", name: "Vivid Holo", summary: "Dramatic rainbow foil that answers every tilt.",
                                    symbol: "sparkles", values: [
        "tilt.gain": 1.35, "tilt.range": 40, "tilt.leanMax": 6,
        "foil.lightTravelX": 1.25, "foil.lightTravelY": 1.25, "foil.eyeDistance": 1.7,
        "foil.diffractionStrength": 0.6, "foil.diffractionPhase": 3.4,
        "foil.sheenStrength": 1.5, "foil.glintStrength": 1.6, "foil.glitterStrength": 1.4
    ])
    static let quiet = TuningPreset(id: "quiet", name: "Quiet", summary: "Understated. Barely-there foil, steady cards.",
                                    symbol: "moon", values: [
        "physics.settle.response": 0.50, "physics.settle.damping": 0.92,
        "tilt.gain": 0.7, "tilt.leanMax": 1.5,
        "foil.diffractionStrength": 0.14, "foil.sheenStrength": 0.6,
        "foil.glintStrength": 0.5, "foil.glitterStrength": 0.2
    ])

    static let all: [TuningPreset] = [.signature, .silk, .crisp, .vivid, .quiet]
}

// MARK: - Quick adjust

/// One plain-language slider that moves a related group of values together, on top of the
/// chosen preset. 1.0 is neutral (the preset as designed).
struct TuningMacro: Identifiable, Equatable {
    let id: String
    let name: String
    let low: String
    let high: String
    let range: ClosedRange<Double>
    let affects: [String]

    static let springIDs = ["settle", "glide", "press", "flip", "morph"]
    static let weight = TuningMacro(id: "weight", name: "Card weight", low: "Light", high: "Heavy", range: 0.6...1.6,
                                    affects: springIDs.flatMap { ["physics.\($0).response", "physics.\($0).damping"] })
    static let flick = TuningMacro(id: "flick", name: "Flick sensitivity", low: "Calm", high: "Eager", range: 0.5...2.0,
                                   affects: ["physics.deck.flickThreshold", "physics.deck.maxReleaseVelocity", "physics.flip.flickThreshold"])
    static let tilt = TuningMacro(id: "tilt", name: "Tilt response", low: "Subtle", high: "Strong", range: 0.4...2.5,
                                  affects: ["tilt.gain", "tilt.leanMax"])
    static let foil = TuningMacro(id: "foil", name: "Foil intensity", low: "Quiet", high: "Vivid", range: 0...2,
                                  affects: ["foil.diffractionStrength", "foil.sheenStrength", "foil.glintStrength", "foil.glitterStrength"])
    static let shine = TuningMacro(id: "shine", name: "Shine size", low: "Pinpoint", high: "Broad", range: 0.5...2,
                                   affects: ["foil.sheenWidth", "foil.glintTightness"])

    static let all: [TuningMacro] = [.weight, .flick, .tilt, .foil, .shine]

    /// How each quick adjust bends a preset value.
    static func transform(_ id: String, _ base: Double, macros: [String: Double]) -> Double {
        func m(_ macro: TuningMacro) -> Double { macros[macro.id] ?? 1 }
        switch id {
        case _ where id.hasSuffix(".response") && id.hasPrefix("physics."):
            return base * m(.weight)
        case _ where id.hasSuffix(".damping") && id.hasPrefix("physics."):
            return base + (m(.weight) - 1) * 0.1
        case "physics.deck.flickThreshold", "physics.flip.flickThreshold":
            return base / m(.flick)
        case "physics.deck.maxReleaseVelocity":
            return base * m(.flick).squareRoot()
        case "tilt.gain":
            return base * m(.tilt)
        case "tilt.leanMax":
            return base * min(m(.tilt), 1.6)
        case "foil.diffractionStrength", "foil.sheenStrength", "foil.glintStrength", "foil.glitterStrength":
            return base * m(.foil)
        case "foil.sheenWidth", "foil.glintTightness":
            return base / m(.shine)
        default:
            return base
        }
    }
}

@MainActor
@Observable
final class Tuning {
    static let shared = Tuning()
    private static let legacyPrefix = "arooma.tuning."
    private static let presetKey = "arooma.tuning.v2.preset"
    private static let macrosKey = "arooma.tuning.v2.macros"
    private static let overridesKey = "arooma.tuning.v2.overrides"

    /// The chosen feel. Every value starts from it.
    private(set) var presetID: String = TuningPreset.signature.id
    /// Quick-adjust multipliers on top of the preset (1 = neutral).
    private(set) var macros: [String: Double] = [:]
    /// Individual edits from the Advanced list or pasted values; they win over everything.
    private(set) var overrides: [String: Double] = [:]
    /// Bumped on every change so views that read static tuning re-render live.
    private(set) var revision = 0

    private init() {
        let defaults = UserDefaults.standard
        presetID = defaults.string(forKey: Self.presetKey) ?? TuningPreset.signature.id
        macros = (defaults.dictionary(forKey: Self.macrosKey) as? [String: Double]) ?? [:]
        overrides = (defaults.dictionary(forKey: Self.overridesKey) as? [String: Double]) ?? [:]
        // One-time migration from the first tuning panel: keep any value the owner changed.
        for spec in Self.specs {
            let key = Self.legacyPrefix + spec.id
            if let old = defaults.object(forKey: key) as? Double {
                if abs(old - spec.defaultValue) > spec.step / 2 { overrides[spec.id] = Self.sanitize(old, spec) }
                defaults.removeObject(forKey: key)
            }
        }
        save()
        applyAll()
    }

    var preset: TuningPreset { TuningPreset.all.first { $0.id == presetID } ?? .signature }

    /// Final value: edit → quick-adjust applied to the preset → shipped default.
    func value(_ id: String) -> Double {
        if let o = overrides[id] { return o }
        return derived(id)
    }

    /// The value before any individual edit.
    func derived(_ id: String) -> Double {
        guard let spec = Self.spec(id) else { return 0 }
        let base = preset.values[id] ?? spec.defaultValue
        return Self.sanitize(TuningMacro.transform(id, base, macros: macros), spec)
    }

    func macro(_ m: TuningMacro) -> Double { macros[m.id] ?? 1 }

    var isEdited: Bool { !overrides.isEmpty }
    var isCustomized: Bool { isEdited || macros.values.contains { abs($0 - 1) > 0.001 } }

    // MARK: Changes

    func selectPreset(_ p: TuningPreset) {
        presetID = p.id
        macros = [:]
        overrides = [:]
        commit(tilt: true)
    }

    func setMacro(_ m: TuningMacro, _ raw: Double) {
        macros[m.id] = min(max(raw, m.range.lowerBound), m.range.upperBound)
        // A quick adjust takes over the values it controls.
        for id in m.affects { overrides[id] = nil }
        commit(tilt: m.id == TuningMacro.tilt.id)
    }

    /// Advanced edit of a single value.
    func set(_ id: String, _ raw: Double) {
        guard let spec = Self.spec(id) else { return }
        let v = Self.sanitize(raw, spec)
        if abs(v - derived(id)) <= spec.step / 2 { overrides[id] = nil } else { overrides[id] = v }
        spec.apply(value(id))
        save()
        revision &+= 1
        if spec.group == "Tilt" { MotionField.shared.tuningChanged() }
    }

    func clearEdits() {
        overrides = [:]
        commit(tilt: true)
    }

    func resetAll() {
        presetID = TuningPreset.signature.id
        macros = [:]
        overrides = [:]
        commit(tilt: true)
    }

    func applyAll() {
        for spec in Self.specs { spec.apply(value(spec.id)) }
        revision &+= 1
    }

    private func commit(tilt: Bool) {
        save()
        applyAll()
        if tilt { MotionField.shared.tuningChanged() }
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(presetID, forKey: Self.presetKey)
        defaults.set(macros, forKey: Self.macrosKey)
        defaults.set(overrides, forKey: Self.overridesKey)
    }

    // MARK: Copy / paste

    func exportText() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        var lines = ["Arooma tuning (version \(version), build \(build))",
                     "preset = \(presetID)"]
        for m in TuningMacro.all { lines.append("macro.\(m.id) = \(String(format: "%.2f", macro(m)))") }
        var group = ""
        for spec in Self.specs {
            if spec.group != group { group = spec.group; lines.append(""); lines.append("# \(group)") }
            let edited = overrides[spec.id] != nil ? "  (edited)" : ""
            lines.append("\(spec.id) = \(Self.format(value(spec.id), spec))\(edited)")
        }
        return lines.joined(separator: "\n")
    }

    /// Accepts the text produced by exportText (or any "key = value" lines): the preset first,
    /// then quick adjusts, then individual values (kept only where they differ). Returns how
    /// many lines were applied.
    @discardableResult
    func importText(_ text: String) -> Int {
        var pairs: [(String, String)] = []
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            pairs.append((parts[0], parts[1].split(separator: " ").first.map(String.init) ?? parts[1]))
        }
        var applied = 0
        if let p = pairs.first(where: { $0.0 == "preset" }), let preset = TuningPreset.all.first(where: { $0.id == p.1 }) {
            presetID = preset.id
            macros = [:]
            overrides = [:]
            applied += 1
        }
        for (key, raw) in pairs where key.hasPrefix("macro.") {
            if let m = TuningMacro.all.first(where: { "macro.\($0.id)" == key }), let v = Double(raw) {
                macros[m.id] = min(max(v, m.range.lowerBound), m.range.upperBound)
                applied += 1
            }
        }
        for (key, raw) in pairs {
            guard let spec = Self.spec(key) else { continue }
            let v = raw == "Off" ? 0 : Double(raw)
            guard let v else { continue }
            let clean = Self.sanitize(v, spec)
            overrides[key] = abs(clean - derived(key)) <= spec.step / 2 ? nil : clean
            applied += 1
        }
        commit(tilt: true)
        return applied
    }

    static func format(_ v: Double, _ spec: TuningSpec) -> String {
        if spec.offAtZero && v == 0 { return "Off" }
        return String(format: "%.\(spec.digits)f", v)
    }

    fileprivate static func sanitize(_ v: Double, _ spec: TuningSpec) -> Double {
        guard v.isFinite else { return spec.defaultValue }
        return min(max(v, spec.range.lowerBound), spec.range.upperBound)
    }

    static func spec(_ id: String) -> TuningSpec? { specs.first { $0.id == id } }

    static var groups: [String] {
        var seen: [String] = []
        for spec in specs where !seen.contains(spec.group) { seen.append(spec.group) }
        return seen
    }

    // MARK: Registry (defaults = shipped values)

    static let specs: [TuningSpec] = {
        func spring(_ key: String, _ label: String, _ response: Double, _ damping: Double,
                    _ set: @escaping (SpringParameters) -> Void, _ get: @escaping () -> SpringParameters) -> [TuningSpec] {
            [
                TuningSpec(id: "physics.\(key).response", group: "Physics", label: "\(label) response (s)",
                           range: 0.12...1.5, step: 0.01, defaultValue: response, digits: 2) { v in
                    var p = get(); p.response = v; set(p)
                },
                TuningSpec(id: "physics.\(key).damping", group: "Physics", label: "\(label) damping",
                           range: 0.3...1.3, step: 0.01, defaultValue: damping, digits: 2) { v in
                    var p = get(); p.damping = v; set(p)
                }
            ]
        }
        var all: [TuningSpec] = []
        all += spring("settle", "Settle", 0.46, 0.84, { SpringParameters.deckSettle = $0 }, { SpringParameters.deckSettle })
        all += spring("glide", "Glide", 0.52, 0.90, { SpringParameters.deckGlide = $0 }, { SpringParameters.deckGlide })
        all += spring("press", "Press", 0.24, 0.68, { SpringParameters.press = $0 }, { SpringParameters.press })
        all += spring("flip", "Flip", 0.52, 0.80, { SpringParameters.flip = $0 }, { SpringParameters.flip })
        all += spring("morph", "Morph", 0.62, 0.86, { SpringParameters.morph = $0 }, { SpringParameters.morph })
        all += [
            TuningSpec(id: "physics.deck.flickThreshold", group: "Physics", label: "Deck flick threshold (cards/s)",
                       range: 0.1...4, step: 0.05, defaultValue: 0.75, digits: 2) { DeckModel.flickThreshold = $0 },
            TuningSpec(id: "physics.deck.maxReleaseVelocity", group: "Physics", label: "Max release velocity (cards/s)",
                       range: 1...20, step: 0.5, defaultValue: 7, digits: 1) { DeckModel.maxReleaseVelocity = $0 },
            TuningSpec(id: "physics.rubber.limit", group: "Physics", label: "Rubber-band limit (cards)",
                       range: 0.05...1, step: 0.01, defaultValue: 0.42, digits: 2) { DeckMath.rubberLimit = $0 },
            TuningSpec(id: "physics.rubber.coefficient", group: "Physics", label: "Rubber-band coefficient",
                       range: 0.1...1.5, step: 0.01, defaultValue: 0.55, digits: 2) { DeckMath.rubberCoefficient = $0 },
            TuningSpec(id: "physics.flip.flickThreshold", group: "Physics", label: "Flip flick threshold (°/s)",
                       range: 60...900, step: 10, defaultValue: 240, digits: 0) { FlipModel.flickThreshold = $0 },

            TuningSpec(id: "layout.coverFlow.yaw", group: "Layouts", label: "Cover Flow neighbour yaw (°)",
                       range: 0...80, step: 1, defaultValue: 54, digits: 0) { LayoutTuning.coverFlowYaw = $0 },
            TuningSpec(id: "layout.coverFlow.scaleFalloff", group: "Layouts", label: "Cover Flow scale falloff",
                       range: 0...0.4, step: 0.005, defaultValue: 0.15, digits: 3) { LayoutTuning.coverFlowScaleFalloff = $0 },
            TuningSpec(id: "layout.stack.dealRoll", group: "Layouts", label: "Stack deal-off roll (°)",
                       range: 0...30, step: 0.5, defaultValue: 9, digits: 1) { LayoutTuning.stackDealRoll = $0 },
            TuningSpec(id: "layout.stack.dealYaw", group: "Layouts", label: "Stack deal-off yaw (°)",
                       range: 0...40, step: 0.5, defaultValue: 12, digits: 1) { LayoutTuning.stackDealYaw = $0 },
            TuningSpec(id: "layout.fan.spread", group: "Layouts", label: "Fan spread (° per card)",
                       range: 4...25, step: 0.5, defaultValue: 11.5, digits: 1) { LayoutTuning.fanSpread = $0 },
            TuningSpec(id: "layout.fan.pivot", group: "Layouts", label: "Fan pivot (card heights)",
                       range: 1...5, step: 0.05, defaultValue: 2.35, digits: 2) { LayoutTuning.fanPivot = $0 },

            TuningSpec(id: "tilt.range", group: "Tilt", label: "Tilt range, soft limit (°)",
                       range: 10...90, step: 1, defaultValue: 45, digits: 0) { TiltTuning.rangeDegrees = $0 },
            TuningSpec(id: "tilt.gain", group: "Tilt", label: "Tilt sensitivity (×)",
                       range: 0.3...3, step: 0.05, defaultValue: 1, digits: 2) { TiltTuning.gain = $0 },
            TuningSpec(id: "tilt.smoothing", group: "Tilt", label: "Motion smoothing (ms)",
                       range: 0...250, step: 5, defaultValue: 60, digits: 0) { TiltTuning.smoothingMS = $0 },
            TuningSpec(id: "tilt.drift", group: "Tilt", label: "Baseline drift (s, 0 = Off)",
                       range: 0...60, step: 1, defaultValue: 0, digits: 0, offAtZero: true) { TiltTuning.driftSeconds = $0 },
            TuningSpec(id: "tilt.sampleRate", group: "Tilt", label: "Sensor rate (Hz)",
                       range: 30...120, step: 10, defaultValue: 60, digits: 0) { TiltTuning.sampleRateHz = $0 },
            TuningSpec(id: "tilt.leanMax", group: "Tilt", label: "Card lean max (°)",
                       range: 0...12, step: 0.5, defaultValue: 4, digits: 1) { TiltTuning.leanMaxDegrees = $0 },

            // Wrist flip (Gyro Flip). Defaults are the plan's initial values; see GyroTuning.
            TuningSpec(id: "gyro.axis", group: "Wrist flip", label: "Twist axis (0 x, 1 long, 2 screen)",
                       range: 0...2, step: 1, defaultValue: 1, digits: 0) { GyroTuning.axis = $0 },
            TuningSpec(id: "gyro.axisTilt", group: "Wrist flip", label: "Long axis leans toward screen (°)",
                       range: -90...90, step: 5, defaultValue: 0, digits: 0) { GyroTuning.axisTiltDegrees = $0 },
            TuningSpec(id: "gyro.startRate", group: "Wrist flip", label: "Start rate (rad/s)",
                       range: 0.4...3, step: 0.1, defaultValue: 1.0, digits: 1) { GyroTuning.startRate = $0 },
            TuningSpec(id: "gyro.peakRate", group: "Wrist flip", label: "Peak rate needed (rad/s)",
                       range: 0.8...6, step: 0.1, defaultValue: 2.2, digits: 1) { GyroTuning.peakRate = $0 },
            TuningSpec(id: "gyro.dominance", group: "Wrist flip", label: "Axis share needed (0 to 1)",
                       range: 0.3...0.95, step: 0.05, defaultValue: 0.75, digits: 2) { GyroTuning.minDominance = $0 },
            TuningSpec(id: "gyro.minAngle", group: "Wrist flip", label: "Turn needed (rad)",
                       range: 0.2...1.5, step: 0.05, defaultValue: 0.55, digits: 2) { GyroTuning.minAngle = $0 },
            TuningSpec(id: "gyro.maxDuration", group: "Wrist flip", label: "Longest twist (s)",
                       range: 0.25...1.2, step: 0.05, defaultValue: 0.45, digits: 2) { GyroTuning.maxDuration = $0 },
            TuningSpec(id: "gyro.maxAccel", group: "Wrist flip", label: "Shake limit (g)",
                       range: 0.4...3, step: 0.1, defaultValue: 0.8, digits: 1) { GyroTuning.maxAcceleration = $0 },

            TuningSpec(id: "foil.lightTravelX", group: "Holographic foil", label: "Light travel, horizontal (×)",
                       range: 0.2...3, step: 0.05, defaultValue: 1, digits: 2) { FoilTuning.lightTravelX = $0 },
            TuningSpec(id: "foil.lightTravelY", group: "Holographic foil", label: "Light travel, vertical (×)",
                       range: 0.2...3, step: 0.05, defaultValue: 1, digits: 2) { FoilTuning.lightTravelY = $0 },
            TuningSpec(id: "foil.eyeDistance", group: "Holographic foil", label: "Viewer distance (card heights)",
                       range: 0.8...6, step: 0.1, defaultValue: 2.1, digits: 1) { FoilTuning.eyeDistance = $0 },
            TuningSpec(id: "foil.sheenWidth", group: "Holographic foil", label: "Sheen width (exponent, lower = wider)",
                       range: 2...80, step: 1, defaultValue: 18, digits: 0) { FoilTuning.sheenWidth = $0 },
            TuningSpec(id: "foil.glintTightness", group: "Holographic foil", label: "Glint tightness (exponent)",
                       range: 20...1200, step: 10, defaultValue: 220, digits: 0) { FoilTuning.glintTightness = $0 },
            TuningSpec(id: "foil.diffractionStrength", group: "Holographic foil", label: "Diffraction strength",
                       range: 0...1, step: 0.01, defaultValue: 0.34, digits: 2) { FoilTuning.diffractionStrength = $0 },
            TuningSpec(id: "foil.diffractionPhase", group: "Holographic foil", label: "Diffraction phase gain",
                       range: 0...8, step: 0.1, defaultValue: 2.4, digits: 1) { FoilTuning.diffractionPhase = $0 },
            TuningSpec(id: "foil.sheenStrength", group: "Holographic foil", label: "Sheen strength (×)",
                       range: 0...3, step: 0.05, defaultValue: 1, digits: 2) { FoilTuning.sheenStrength = $0 },
            TuningSpec(id: "foil.glintStrength", group: "Holographic foil", label: "Glint strength (×)",
                       range: 0...3, step: 0.05, defaultValue: 1, digits: 2) { FoilTuning.glintStrength = $0 },
            TuningSpec(id: "foil.glitterStrength", group: "Holographic foil", label: "Glitter strength",
                       range: 0...2, step: 0.05, defaultValue: 0.9, digits: 2) { FoilTuning.glitterStrength = $0 },
            TuningSpec(id: "foil.idleDrift", group: "Holographic foil", label: "Idle drift amplitude (0 = Off)",
                       range: 0...0.3, step: 0.01, defaultValue: 0, digits: 2, offAtZero: true) { FoilTuning.idleDrift = $0 }
        ]
        return all
    }()
}

// MARK: - Hidden tuning panel

struct TuningPanel: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tuning = Tuning.shared
    @State private var probe = FramePacingProbe.shared
    @State private var confirmReset = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(TuningPreset.all) { preset in
                        Button { tuning.selectPreset(preset); flash("\(preset.name) applied.") } label: {
                            HStack(spacing: 12) {
                                Image(systemName: preset.symbol)
                                    .frame(width: 26)
                                    .foregroundStyle(.tint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name).font(.body.weight(.medium)).foregroundStyle(.primary)
                                    Text(preset.summary).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if tuning.presetID == preset.id {
                                    Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(.tint)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(tuning.presetID == preset.id ? .isSelected : [])
                    }
                } header: {
                    Text("Feel")
                } footer: {
                    Text(tuning.isCustomized ? "\(tuning.preset.name), adjusted below." : "Pick a starting point, then fine-tune below.")
                }

                Section("Quick adjust") {
                    ForEach(TuningMacro.all) { macro in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(macro.name).font(.subheadline)
                                Spacer()
                                Text(String(format: "%.2f×", tuning.macro(macro)))
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(abs(tuning.macro(macro) - 1) < 0.005 ? .secondary : .primary)
                            }
                            Slider(value: Binding(get: { tuning.macro(macro) }, set: { tuning.setMacro(macro, $0) }),
                                   in: macro.range, step: 0.05) {
                                Text(macro.name)
                            } minimumValueLabel: {
                                Text(macro.low).font(.caption2).foregroundStyle(.secondary)
                            } maximumValueLabel: {
                                Text(macro.high).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .contextMenu {
                            Button("Back to 1.00×", systemImage: "arrow.counterclockwise") { tuning.setMacro(macro, 1) }
                        }
                    }
                }

                Section {
                    Button("Recenter tilt", systemImage: "scope") {
                        MotionField.shared.recenter()
                        flash("Tilt baseline set to how you're holding the phone.")
                    }
                    Toggle("Frame-time readout", isOn: Binding(get: { probe.enabled }, set: { probe.enabled = $0 }))
                }

                Section {
                    Button("Copy values", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = tuning.exportText()
                        flash("Copied. Paste them into the conversation.")
                    }
                    Button("Paste values", systemImage: "doc.on.clipboard") {
                        let count = tuning.importText(UIPasteboard.general.string ?? "")
                        flash(count == 0 ? "No tuning values found on the clipboard." : "Applied \(count) values.")
                    }
                    NavigationLink {
                        TuningAdvanced()
                    } label: {
                        HStack {
                            Label("Advanced", systemImage: "slider.horizontal.3")
                            Spacer()
                            if tuning.isEdited {
                                Text("\(tuning.overrides.count) edited").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button("Reset everything", systemImage: "arrow.counterclockwise", role: .destructive) {
                        confirmReset = true
                    }
                } footer: {
                    if let message { Text(message) }
                    else { Text("Changes apply immediately and are kept on this iPhone.") }
                }
            }
            .navigationTitle("Tuning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Back to Signature with no adjustments or edits?", isPresented: $confirmReset,
                                titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) {
                    tuning.resetAll()
                    flash("Back to Signature.")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }

    private func flash(_ text: String) {
        message = text
        HapticEngine.shared.play(.completed)
    }
}

/// Every individual value, for fine edits. Edits win over the preset and quick adjusts.
struct TuningAdvanced: View {
    @State private var tuning = Tuning.shared

    var body: some View {
        Form {
            if tuning.isEdited {
                Section {
                    Button("Clear \(tuning.overrides.count) edits", systemImage: "arrow.uturn.backward") { tuning.clearEdits() }
                } footer: {
                    Text("Edited values are marked with a dot. Long-press a value to undo just that one.")
                }
            }
            ForEach(Tuning.groups, id: \.self) { group in
                Section(group) {
                    ForEach(Tuning.specs.filter { $0.group == group }) { spec in
                        row(spec)
                    }
                }
            }
        }
        .navigationTitle("Advanced")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ spec: TuningSpec) -> some View {
        let current = tuning.value(spec.id)
        let edited = tuning.overrides[spec.id] != nil
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if edited { Circle().fill(.tint).frame(width: 6, height: 6) }
                Text(spec.label).font(.subheadline)
                Spacer()
                Text(Tuning.format(current, spec))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(edited ? .primary : .secondary)
            }
            Slider(value: Binding(get: { tuning.value(spec.id) }, set: { tuning.set(spec.id, $0) }),
                   in: spec.range, step: spec.step)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(Tuning.format(current, spec) + (edited ? ", edited" : ""))
        .contextMenu {
            Button("Undo this edit", systemImage: "arrow.counterclockwise") { tuning.set(spec.id, tuning.derived(spec.id)) }
        }
    }
}
