import SwiftUI
import UIKit
import Observation

// MARK: - Live tuning
//
// Every physics, layout, tilt and foil constant the owner may want to refine on an iPhone lives
// here, with today's shipped value as its default. Values persist in UserDefaults, apply
// immediately, and can be copied out as plain text ("key = value" lines) and pasted back.
// The panel is hidden: long-press the Version row in View & Style.

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

@MainActor
@Observable
final class Tuning {
    static let shared = Tuning()
    private static let prefix = "arooma.tuning."

    private(set) var values: [String: Double] = [:]
    /// Bumped on every change so views that read static tuning re-render live.
    private(set) var revision = 0

    private init() {
        for spec in Self.specs {
            let stored = UserDefaults.standard.object(forKey: Self.prefix + spec.id) as? Double
            values[spec.id] = Self.sanitize(stored ?? spec.defaultValue, spec)
        }
        applyAll()
    }

    func value(_ id: String) -> Double { values[id] ?? Self.spec(id)?.defaultValue ?? 0 }

    func set(_ id: String, _ raw: Double) {
        guard let spec = Self.spec(id) else { return }
        let v = Self.sanitize(raw, spec)
        values[id] = v
        UserDefaults.standard.set(v, forKey: Self.prefix + id)
        spec.apply(v)
        revision &+= 1
        if spec.group == "Tilt" { MotionField.shared.tuningChanged() }
    }

    func applyAll() {
        for spec in Self.specs { spec.apply(value(spec.id)) }
        revision &+= 1
    }

    func resetAll() {
        for spec in Self.specs {
            UserDefaults.standard.removeObject(forKey: Self.prefix + spec.id)
            values[spec.id] = spec.defaultValue
        }
        applyAll()
        MotionField.shared.tuningChanged()
    }

    func exportText() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        var lines = ["Arooma tuning values (version \(version), build \(build))"]
        var group = ""
        for spec in Self.specs {
            if spec.group != group { group = spec.group; lines.append(""); lines.append("# \(group)") }
            let changed = abs(value(spec.id) - spec.defaultValue) > spec.step / 2 ? "  (default \(Self.format(spec.defaultValue, spec)))" : ""
            lines.append("\(spec.id) = \(Self.format(value(spec.id), spec))\(changed)")
        }
        return lines.joined(separator: "\n")
    }

    /// Accepts the text produced by exportText (or any "key = value" lines). Returns how many
    /// known values were applied.
    @discardableResult
    func importText(_ text: String) -> Int {
        var applied = 0
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2, Self.spec(parts[0]) != nil else { continue }
            let number = parts[1].split(separator: " ").first.map(String.init) ?? parts[1]
            if let v = Double(number) { set(parts[0], v); applied += 1 }
        }
        return applied
    }

    static func format(_ v: Double, _ spec: TuningSpec) -> String {
        if spec.offAtZero && v == 0 { return "Off" }
        return String(format: "%.\(spec.digits)f", v)
    }

    private static func sanitize(_ v: Double, _ spec: TuningSpec) -> Double {
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
                    Toggle("Frame-time readout", isOn: Binding(get: { probe.enabled }, set: { probe.enabled = $0 }))
                    Button("Recenter tilt now", systemImage: "scope") {
                        MotionField.shared.recenter()
                        flash("Tilt baseline set to the current angle.")
                    }
                    Button("Copy values", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = tuning.exportText()
                        flash("Copied. Paste them into the conversation.")
                    }
                    Button("Paste values", systemImage: "doc.on.clipboard") {
                        let count = tuning.importText(UIPasteboard.general.string ?? "")
                        flash(count == 0 ? "No tuning values found on the clipboard." : "Applied \(count) values.")
                    }
                    Button("Reset to defaults", systemImage: "arrow.counterclockwise", role: .destructive) {
                        confirmReset = true
                    }
                } footer: {
                    if let message { Text(message) }
                    else { Text("Changes apply immediately and are kept on this iPhone.") }
                }
                ForEach(Tuning.groups, id: \.self) { group in
                    Section(group) {
                        ForEach(Tuning.specs.filter { $0.group == group }) { spec in
                            row(spec)
                        }
                    }
                }
            }
            .navigationTitle("Tuning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Reset every tuning value to the shipped defaults?", isPresented: $confirmReset,
                                titleVisibility: .visible) {
                Button("Reset to defaults", role: .destructive) {
                    tuning.resetAll()
                    flash("All values reset.")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }

    private func row(_ spec: TuningSpec) -> some View {
        let current = tuning.value(spec.id)
        let isDefault = abs(current - spec.defaultValue) <= spec.step / 2
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(spec.label).font(.subheadline)
                Spacer()
                Text(Tuning.format(current, spec))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(isDefault ? .secondary : .primary)
            }
            Slider(value: Binding(get: { tuning.value(spec.id) }, set: { tuning.set(spec.id, $0) }),
                   in: spec.range, step: spec.step)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(Tuning.format(current, spec))
        .contextMenu {
            Button("Reset this value", systemImage: "arrow.counterclockwise") { tuning.set(spec.id, spec.defaultValue) }
        }
    }

    private func flash(_ text: String) {
        message = text
        HapticEngine.shared.play(.completed)
    }
}
