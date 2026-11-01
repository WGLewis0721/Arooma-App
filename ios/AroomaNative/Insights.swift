import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Fragrance insight
//
// Deterministic and explainable. Three kinds of statement, always labelled:
//   • Listed  — notes as recorded on the bundled card / catalog entry.
//   • Yours   — facts from the owner's own records (wears, layers, shelves).
//   • Suggestion — a rule applied to listed notes; the reason is shown, never a guarantee.
// Missing data stays "Unknown". Nothing is invented and nothing is fetched.

enum InsightBasis: String { case listed = "Listed", yours = "Your records", suggestion = "Suggestion" }

struct InsightLine: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let basis: InsightBasis
}

enum Accord: String, CaseIterable, Identifiable {
    case citrus = "Citrus", spicy = "Spicy", woody = "Woody", amber = "Amber", floral = "Floral",
         fruity = "Fruity", aromatic = "Aromatic", musky = "Musky", sweet = "Sweet"
    var id: Self { self }

    /// Keyword → accord. Applied to listed notes only; the derivation is shown to the owner.
    static let keywords: [Accord: [String]] = [
        .citrus: ["bergamot", "lemon", "grapefruit", "orange", "mandarin", "lime", "yuzu", "citrus"],
        .spicy: ["cinnamon", "nutmeg", "cardamom", "pepper", "clove", "saffron", "ginger"],
        .woody: ["sandalwood", "vetiver", "cedar", "driftwood", "oud", "patchouli", "wood"],
        .amber: ["amber", "ambrofix", "labdanum", "benzoin", "resin"],
        .floral: ["orange blossom", "rose", "jasmine", "iris", "neroli", "tuberose", "violet"],
        .fruity: ["apple", "plum", "pear", "berry", "peach", "pineapple"],
        .aromatic: ["lavender", "sage", "mint", "rosemary", "basil"],
        .musky: ["musk", "ambrette"],
        .sweet: ["licorice", "vanilla", "tonka", "caramel", "honey", "praline"]
    ]

    static func accords(for notes: [String]) -> [Accord] {
        let lower = notes.map { $0.lowercased() }
        return Accord.allCases.filter { accord in
            (keywords[accord] ?? []).contains { key in lower.contains { $0.contains(key) } }
        }
    }
}

enum InsightEngine {
    static func sharedNotes(_ a: Fragrance, _ b: Fragrance) -> [String] {
        let bs = Set(b.notes.map { $0.lowercased() })
        return a.notes.filter { bs.contains($0.lowercased()) }
    }

    static func similarity(_ a: Fragrance, _ b: Fragrance) -> Double {
        let sa = Set(a.notes.map { $0.lowercased() }), sb = Set(b.notes.map { $0.lowercased() })
        let notes = sa.isEmpty || sb.isEmpty ? 0 : Double(sa.intersection(sb).count) / Double(sa.union(sb).count)
        let aa = Set(Accord.accords(for: a.notes)), ab = Set(Accord.accords(for: b.notes))
        let accords = aa.isEmpty || ab.isEmpty ? 0 : Double(aa.intersection(ab).count) / Double(aa.union(ab).count)
        return notes * 0.65 + accords * 0.35
    }

    /// Season suggestion from listed notes, with the reason.
    static func season(for f: Fragrance) -> (String, String)? {
        let accords = Set(Accord.accords(for: f.notes))
        guard !accords.isEmpty else { return nil }
        let fresh = accords.intersection([.citrus, .aromatic, .floral, .fruity]).count
        let warm = accords.intersection([.spicy, .amber, .woody, .sweet]).count
        if fresh > warm { return ("Spring · Summer", "more fresh accords (\(fresh)) than warm (\(warm))") }
        if warm > fresh { return ("Autumn · Winter", "more warm accords (\(warm)) than fresh (\(fresh))") }
        return ("All seasons", "balanced fresh and warm accords")
    }

    static func occasion(for f: Fragrance) -> (String, String)? {
        let accords = Set(Accord.accords(for: f.notes))
        guard !accords.isEmpty else { return nil }
        if accords.contains(.amber) || accords.contains(.sweet) { return ("Evening", "amber or sweet base notes") }
        if accords.contains(.citrus) || accords.contains(.aromatic) { return ("Daytime · Office", "citrus or aromatic opening") }
        return ("Anytime", "no strongly day or night accords")
    }

    @MainActor
    static func lines(for card: DisplayCard, in store: CollectionStore) -> [InsightLine] {
        let f = card.fragrance
        var out: [InsightLine] = []
        if f.notes.isEmpty {
            out.append(InsightLine(title: "Notes", detail: "Unknown — none recorded for this fragrance yet.", basis: .listed))
        } else {
            let rows = [("Top", f.top), ("Heart", f.heart), ("Base", f.base)].filter { !$0.1.isEmpty }
            out.append(InsightLine(title: "Notes",
                                   detail: rows.map { "\($0.0): \($0.1.joined(separator: ", "))" }.joined(separator: "\n"),
                                   basis: .listed))
            let accords = Accord.accords(for: f.notes)
            if !accords.isEmpty {
                out.append(InsightLine(title: "Accords",
                                       detail: accords.map(\.rawValue).joined(separator: " · ") + " — derived from the listed notes",
                                       basis: .suggestion))
            }
        }
        // Similar fragrances already owned.
        let owned = store.bottles.compactMap { b -> Fragrance? in
            guard b.fragranceID != f.id else { return nil }
            return store.fragrance(id: b.fragranceID)
        }
        let ranked = owned.map { ($0, similarity(f, $0)) }.filter { $0.1 > 0.05 }.sorted { $0.1 > $1.1 }
        if let best = ranked.first {
            let shared = sharedNotes(f, best.0)
            let why = shared.isEmpty ? "shares accords" : "shares \(shared.prefix(3).joined(separator: ", "))"
            out.append(InsightLine(title: "Closest in your collection", detail: "\(best.0.name) — \(why)", basis: .suggestion))
        } else {
            out.append(InsightLine(title: "Closest in your collection",
                                   detail: owned.isEmpty ? "Nothing owned yet to compare." : "Unknown — no overlapping listed notes.",
                                   basis: .suggestion))
        }
        // Layering: the owner's own history first, then a labelled suggestion.
        if let bottleID = card.bottleID {
            var partners: [UUID: Int] = [:]
            for session in store.wearSessions where session.bottleIDs.contains(bottleID) && session.bottleIDs.count > 1 {
                for other in session.bottleIDs where other != bottleID { partners[other, default: 0] += 1 }
            }
            if let top = partners.max(by: { $0.value < $1.value }),
               let b = store.bottles.first(where: { $0.id == top.key }), let pf = store.fragrance(id: b.fragranceID) {
                out.append(InsightLine(title: "You layer it with", detail: "\(pf.name) — \(top.value)× together", basis: .yours))
            }
        }
        let fAccords = Set(Accord.accords(for: f.notes))
        if !fAccords.isEmpty,
           let partner = owned.first(where: { o in
               let oa = Set(Accord.accords(for: o.notes))
               return !oa.isEmpty && !oa.isDisjoint(with: fAccords) && !oa.subtracting(fAccords).isEmpty
           }) {
            let bridge = Set(Accord.accords(for: partner.notes)).intersection(fAccords).map(\.rawValue).sorted().joined(separator: ", ")
            let adds = Set(Accord.accords(for: partner.notes)).subtracting(fAccords).map(\.rawValue).sorted().joined(separator: ", ")
            out.append(InsightLine(title: "Possible layer",
                                   detail: "\(partner.name) — bridges on \(bridge), adds \(adds). A suggestion, not a guarantee.",
                                   basis: .suggestion))
        }
        if let season = season(for: f) {
            out.append(InsightLine(title: "Season", detail: "\(season.0) — \(season.1)", basis: .suggestion))
        } else {
            out.append(InsightLine(title: "Season", detail: "Unknown", basis: .suggestion))
        }
        if let occasion = occasion(for: f) {
            out.append(InsightLine(title: "Occasion", detail: "\(occasion.0) — \(occasion.1)", basis: .suggestion))
        }
        let overlap = owned.filter { sharedNotes(f, $0).count >= 2 }
        if !f.notes.isEmpty {
            out.append(InsightLine(title: "Collection overlap",
                                   detail: overlap.isEmpty ? "No owned bottle shares two or more notes."
                                       : "\(overlap.count) owned \(overlap.count == 1 ? "bottle shares" : "bottles share") two or more notes: \(overlap.prefix(3).map(\.name).joined(separator: ", "))",
                                   basis: .yours))
        }
        if let bottleID = card.bottleID, let b = store.bottles.first(where: { $0.id == bottleID }) {
            let last = b.lastWorn.map { $0.formatted(.relative(presentation: .named)) } ?? "never"
            out.append(InsightLine(title: "Your wear history",
                                   detail: "\(b.wears.count) wears · last \(last) · \(Int(b.remaining * 100))% estimated left",
                                   basis: .yours))
        }
        if let wishID = card.wishID, let w = store.wishlist.first(where: { $0.id == wishID }) {
            let from = w.source.isEmpty ? "" : " · from \(w.source)"
            out.append(InsightLine(title: "On your Wishlist",
                                   detail: "Added \(w.added.formatted(date: .abbreviated, time: .omitted))\(from)\(w.notes.isEmpty ? "" : "\n“\(w.notes)”")",
                                   basis: .yours))
        }
        return out
    }
}

// MARK: - Season Compass (owner-approved visual Insights design)
//
// Native, data-driven interpretation of the approved Layton mockup.
// No hard-coded Layton/Hawas values, fake similarity, or season guarantees.
// Every owned or sample fragrance gets the exact same visual grammar.

private enum SeasonCompassArt {
    static func glyph(for note: String) -> String {
        let n = note.lowercased()
        let illustrations: [(String, String)] = [
            ("apple","🍎"), ("pear","🍐"), ("plum","🍑"), ("lemon","🍋"),
            ("lime","🍋‍🟩"), ("bergamot","🍋"), ("grapefruit","🍊"),
            ("orange blossom","🌼"), ("orange","🍊"), ("mandarin","🍊"),
            ("lavender","🪻"), ("violet","🌺"), ("iris","🌸"), ("jasmine","🌼"),
            ("rose","🌹"), ("floral","🌺"), ("flower","🌼"), ("neroli","🌼"),
            ("tobacco","🍂"), ("vanilla","🌼"), ("cinnamon","🪵"),
            ("sandalwood","🪵"), ("cedar","🪵"), ("wood","🪵"), ("oud","🪵"),
            ("patchouli","🌿"), ("vetiver","🌿"), ("musk","🌾"), ("amber","🟤"),
            ("pepper","🌶️"), ("ginger","🫚"), ("cardamom","🌱"), ("saffron","🌺"),
            ("sage","🌿"), ("mint","🌿"), ("honey","🍯"), ("coffee","☕️"),
            ("cacao","🍫"), ("chocolate","🍫"), ("tonka","🫘"), ("praline","🍬"),
            ("chestnut","🌰"), ("rum","🥃"), ("cognac","🥃"), ("whisk","🥃"),
            ("leather","🟫"), ("incense","🪵"), ("benzoin","🟠"),
            ("resin","🟡"), ("fig","🫒"), ("marine","🌊"), ("sea","🌊")
        ]
        return illustrations.first { n.contains($0.0) }?.1 ?? "✦"
    }

    static func symbol(for accord: Accord) -> String {
        switch accord {
        case .citrus: "circle.dotted"
        case .spicy: "sparkle"
        case .woody: "leaf"
        case .amber: "sun.max"
        case .floral: "camera.macro"
        case .fruity: "circle.grid.2x2"
        case .aromatic: "wind"
        case .musky: "cloud"
        case .sweet: "squareshape.split.2x2"
        }
    }
}

/// The original recommendation data is preserved and presented as visual affordances.
/// One score is a relative overlap heuristic, not a measured fragrance performance score.
private struct CompassInsights {
    let fragrance: Fragrance
    let accords: [Accord]
    let season: String?
    let occasion: String?
    let closest: Fragrance?
    let layer: Fragrance?
    let recordedLayer: Bool
    let affinity: Int?
    let extra: [InsightLine]

    @MainActor
    init(card: DisplayCard, store: CollectionStore) {
        let f = card.fragrance
        fragrance = f
        accords = Accord.accords(for: f.notes)
        season = InsightEngine.season(for: f)?.0
        occasion = InsightEngine.occasion(for: f)?.0
        extra = InsightEngine.lines(for: card, in: store)

        // Only compare with actual owned fragrances, never with sample demo cards.
        var seen = Set<String>()
        let owned = store.bottles.compactMap { bottle -> Fragrance? in
            guard bottle.fragranceID != f.id, seen.insert(bottle.fragranceID).inserted else { return nil }
            return store.fragrance(id: bottle.fragranceID)
        }
        let ranked = owned.map { ($0, InsightEngine.similarity(f, $0)) }
            .filter { $0.1 > 0.05 }
            .sorted { $0.1 > $1.1 }
        closest = ranked.first?.0
        // Quantize the existing similarity heuristic into five labelled comparison ticks.
        if let best = ranked.first {
            affinity = max(1, min(5, Int((best.1 * 5).rounded())))
        } else {
            affinity = nil
        }

        var historyPartner: Fragrance?
        if let bottleID = card.bottleID {
            var counts: [UUID: Int] = [:]
            for session in store.wearSessions
                where session.bottleIDs.contains(bottleID) && session.bottleIDs.count > 1 {
                for other in session.bottleIDs where other != bottleID {
                    counts[other, default: 0] += 1
                }
            }
            if let top = counts.max(by: { $0.value < $1.value }),
               let record = store.bottles.first(where: { $0.id == top.key }) {
                historyPartner = store.fragrance(id: record.fragranceID)
            }
        }
        recordedLayer = historyPartner != nil
        let currentAccords = Set(accords)
        let suggestion = owned.first { candidate in
            let other = Set(Accord.accords(for: candidate.notes))
            return !currentAccords.isEmpty && !other.isEmpty &&
                !currentAccords.isDisjoint(with: other) &&
                !other.subtracting(currentAccords).isEmpty
        }
        layer = historyPartner ?? suggestion
    }
}

struct InsightPanel: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize

    let card: DisplayCard
    let expanded: Bool
    let compare: (Fragrance?) -> Void
    let close: () -> Void

    @State private var revealedStage: String?
    @State private var showMore = false

    private var brown: Color { scheme == .dark ? Color(hex: 0xE0BC8F) : Color(hex: 0x794624) }
    private var ink: Color { scheme == .dark ? Color(hex: 0xF8EEDD) : Color(hex: 0x382418) }
    private var subdued: Color { ink.opacity(0.64) }
    private var surface: Color { scheme == .dark ? Color(hex: 0x231D24) : Color(hex: 0xF2E5D4) }
    private var plate: Color { scheme == .dark ? Color(hex: 0x332B31) : Color(hex: 0xF8EEE2) }
    private var accentGlow: Color { scheme == .dark ? Color(hex: 0xBB885A) : Color(hex: 0xD5995E) }
    private var lockedShare: Bool {
        guard let fall = Fall2026Collection.entry(for: card.fragrance.id) else { return false }
        return fall.status != "approved" || !fall.artRightsCleared || !fall.referencePhotoApproved
    }

    var body: some View {
        let insight = CompassInsights(card: card, store: archive)
        VStack(spacing: 0) {
            Capsule().fill(brown.opacity(0.35))
                .frame(width: 36, height: 5)
                .padding(.top, 9)
                .padding(.bottom, 8)
            toolbar
                .padding(.horizontal, 17)
                .padding(.bottom, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: expanded ? 17 : 10) {
                    compassHeading
                    identityAndCompass(insight)
                    if expanded {
                        ingredients(insight)
                        accords(insight)
                        recommendedMatches(insight)
                        overlap(insight)
                        detailDisclosure(insight)
                    } else {
                        Text("Swipe up for notes, accords & matches")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(subdued)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 17)
                .padding(.bottom, 22)
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(!expanded)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .foregroundStyle(ink)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [plate, surface, plate.opacity(0.96)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(.white.opacity(scheme == .dark ? 0.10 : 0.67), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.13), radius: 18, y: -5)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Text("INSIGHTS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.3)
                .foregroundStyle(brown)
            Spacer(minLength: 0)
            if !lockedShare {
                CardShareButton(card: card)
            }
            Button { compare(nil) } label: {
                Image(systemName: "rectangle.split.2x1")
                    .frame(width: 31, height: 31)
            }
            .accessibilityLabel("Compare fragrances")
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            Button(action: close) {
                Image(systemName: "chevron.down")
                    .frame(width: 31, height: 31)
            }
            .accessibilityLabel("Close Insights")
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
        }
    }

    private var compassHeading: some View {
        HStack(spacing: 10) {
            Rectangle().fill(brown.opacity(0.48)).frame(height: 0.7)
            Text("SEASON COMPASS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.3)
                .foregroundStyle(brown)
                .fixedSize()
            Rectangle().fill(brown.opacity(0.48)).frame(height: 0.7)
        }
        .accessibilityAddTraits(.isHeader)
    }

    private func identityAndCompass(_ insight: CompassInsights) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.fragrance.name)
                    .font(.system(size: expanded ? 31 : 24, weight: .regular, design: .serif))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Text(insight.fragrance.house.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.8)
                    .lineLimit(2)
                    .foregroundStyle(brown)
                Text(insight.fragrance.concentration.uppercased())
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1.0)
                    .foregroundStyle(brown)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .overlay(Capsule().strokeBorder(brown.opacity(0.4)))
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: -9) {
                SeasonCompassDial(
                    text: insight.season ?? "Unknown",
                    icon: insight.season?.contains("Summer") == true ? "sun.max" :
                        insight.season?.contains("Winter") == true ? "snowflake" : "sun.horizon",
                    tone: brown, glow: accentGlow, dark: scheme == .dark, size: expanded ? 103 : 76
                )
                SeasonCompassDial(
                    text: insight.occasion ?? "Unknown",
                    icon: insight.occasion == "Evening" ? "moon.stars" : "sun.max",
                    tone: brown, glow: accentGlow, dark: scheme == .dark, size: expanded ? 103 : 76
                )
            }
            .accessibilityElement(children: .contain)
        }
    }

    private func ingredients(_ insight: CompassInsights) -> some View {
        VStack(spacing: 6) {
            ingredientRow("TOP", notes: insight.fragrance.top)
            ingredientRow("HEART", notes: insight.fragrance.heart)
            ingredientRow("BASE", notes: insight.fragrance.base)
        }
    }

    private func ingredientRow(_ stage: String, notes: [String]) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    revealedStage = revealedStage == stage ? nil : stage
                }
            } label: {
                HStack(spacing: 8) {
                    Text(stage)
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.6)
                        .frame(width: 51, alignment: .leading)
                        .foregroundStyle(brown)
                    Rectangle()
                        .fill(brown.opacity(0.4))
                        .frame(width: 1, height: 27)
                    if notes.isEmpty {
                        Text("Notes not recorded")
                            .font(.system(size: 12, design: .serif))
                            .foregroundStyle(subdued)
                            .frame(maxWidth: .infinity)
                    } else {
                        HStack(spacing: 0) {
                            ForEach(0..<min(3, notes.count), id: \.self) { index in
                                Text(SeasonCompassArt.glyph(for: notes[index]))
                                    .font(.system(size: typeSize.isAccessibilitySize ? 19 : 27))
                                    .frame(maxWidth: .infinity)
                                    .accessibilityHidden(true)
                            }
                            if notes.count > 3 {
                                Text("+\(notes.count - 3)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(brown)
                                    .frame(width: 30)
                            }
                        }
                    }
                }
                .frame(minHeight: 47)
                .padding(.horizontal, 13)
                .background(plate, in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.55), lineWidth: 1))
                .shadow(color: .black.opacity(0.055), radius: 4, y: 2)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(stage.capitalized) notes: \(notes.isEmpty ? "not recorded" : notes.joined(separator: ", "))")
            .accessibilityHint("Show or hide all note names")
            if revealedStage == stage && !notes.isEmpty {
                Text(notes.joined(separator: "  ·  "))
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(subdued)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private func accords(_ insight: CompassInsights) -> some View {
        if !insight.accords.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("ACCORDS  ·  DERIVED FROM NOTES")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(brown)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(insight.accords) { accord in
                            HStack(spacing: 5) {
                                Image(systemName: SeasonCompassArt.symbol(for: accord))
                                    .font(.system(size: 11, weight: .medium))
                                Text(accord.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(plate, in: Capsule())
                            .overlay(Capsule().strokeBorder(brown.opacity(0.19)))
                            .accessibilityLabel("\(accord.rawValue) accord, derived from listed notes")
                        }
                    }
                }
            }
        }
    }

    private func recommendedMatches(_ insight: CompassInsights) -> some View {
        HStack(spacing: 9) {
            recommendation("CLOSEST", fragrance: insight.closest, sub: "Suggested match")
            recommendation(insight.recordedLayer ? "LAYERED WITH" : "POSSIBLE LAYER",
                           fragrance: insight.layer,
                           sub: insight.recordedLayer ? "Your wear history" : "Suggested pairing")
        }
    }

    private func recommendation(_ title: String, fragrance: Fragrance?, sub: String) -> some View {
        Button {
            if let fragrance { compare(fragrance) }
        } label: {
            HStack(spacing: 8) {
                if let fragrance {
                    AtelierCardSurface(fragranceID: fragrance.id, radius: 7,
                                      shadowed: false)
                        .frame(width: 45, height: 68)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "square.stack.3d.up")
                        .font(.title3)
                        .foregroundStyle(brown.opacity(0.45))
                        .frame(width: 45, height: 68)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(brown)
                    Text(fragrance?.name ?? "No match yet")
                        .font(.system(size: 15, design: .serif))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.leading)
                    if fragrance != nil {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(brown)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 87, alignment: .leading)
            .padding(7)
            .background(plate, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.5)))
            .shadow(color: .black.opacity(0.055), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(fragrance == nil)
        .accessibilityLabel("\(title): \(fragrance?.name ?? "no owned fragrance available"). \(sub).")
        .accessibilityHint(fragrance == nil ? "" : "Open fragrance comparison")
    }

    private func overlap(_ insight: CompassInsights) -> some View {
        HStack {
            Text("COLLECTION OVERLAP")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(brown)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 6)
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index < (insight.affinity ?? 0) ? brown : brown.opacity(0.14))
                    .frame(width: 11, height: 11)
                    .overlay(Circle().strokeBorder(brown.opacity(0.35), lineWidth: 0.6))
            }
            Text(insight.affinity.map { "\($0) / 5" } ?? "—")
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .padding(.leading, 6)
                .foregroundStyle(brown)
        }
        .padding(.horizontal, 13)
        .frame(minHeight: 44)
        .background(plate, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.5)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(insight.affinity.map {
            "Closest collection similarity: \($0) out of 5 relative note and accord overlap ticks, an estimate"
        } ?? "Collection overlap unavailable, no comparable owned fragrance")
    }

    private func detailDisclosure(_ insight: CompassInsights) -> some View {
        DisclosureGroup(isExpanded: $showMore) {
            VStack(alignment: .leading, spacing: 9) {
                ForEach(insight.extra.filter {
                    !["Notes", "Accords", "Season", "Occasion", "Closest in your collection",
                      "Possible layer", "You layer it with", "Collection overlap"].contains($0.title)
                }) { line in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(line.title).font(.system(size: 12, weight: .semibold))
                            Spacer()
                            Text(line.basis.rawValue.uppercased())
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(brown)
                        }
                        Text(line.detail)
                            .font(.system(size: 11))
                            .foregroundStyle(subdued)
                    }
                }
                if !insight.fragrance.notes.isEmpty {
                    Text("Season, occasion, accord, similarity and layering are suggestions inferred from listed notes, not guaranteed performance.")
                        .font(.system(size: 10))
                        .foregroundStyle(subdued)
                }
            }
            .padding(.top, 9)
        } label: {
            Text("YOUR RECORDS & HOW IT'S CALCULATED")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(brown)
        }
        .tint(brown)
    }
}

private struct SeasonCompassDial: View {
    let text: String
    let icon: String
    let tone: Color
    let glow: Color
    let dark: Bool
    let size: CGFloat

    private var caption: String {
        text.replacingOccurrences(of: " · ", with: "\n")
            .replacingOccurrences(of: " / ", with: "\n")
            .uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(colors: [
                        dark ? Color(hex: 0x34272E) : Color(hex: 0xFFF3E4),
                        dark ? Color(hex: 0x49303A) : Color(hex: 0xE9C7A6)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Circle()
                .strokeBorder(
                    AngularGradient(colors: [
                        glow, .white.opacity(0.9), tone.opacity(0.3), glow,
                        tone.opacity(0.4), glow
                    ], center: .center), lineWidth: 5
                )
            Circle().strokeBorder(.white.opacity(0.72), lineWidth: 1)
                .padding(8)
            VStack(spacing: size > 90 ? 6 : 3) {
                Image(systemName: icon)
                    .font(.system(size: size > 90 ? 22 : 17, weight: .ultraLight))
                Text(caption)
                    .font(.system(size: size > 90 ? 10 : 8, weight: .semibold))
                    .tracking(0.6)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(dark ? Color(hex: 0xF1DBC5) : Color(hex: 0x6A3F2C))
            .padding(7)
        }
        .frame(width: size, height: size)
        .shadow(color: glow.opacity(0.23), radius: 8, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Suggested \(text)")
    }
}

// MARK: - Compare (2–3 cards)

struct CompareSheet: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.dismiss) private var dismiss
    let primary: DisplayCard
    var suggested: Fragrance? = nil
    @State private var others: [Fragrance] = []

    private var pool: [Fragrance] {
        var seen = Set<String>()
        let owned = archive.bottles.compactMap { archive.fragrance(id: $0.fragranceID) }
        let wished = archive.wishlist.compactMap { archive.fragrance(id: $0.fragranceID) }
        return (owned + wished + Fragrance.catalog).filter { f in
            f.id != primary.fragrance.id && seen.insert(f.id).inserted
        }
    }

    var body: some View {
        NavigationStack {
            let set = [primary.fragrance] + others
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(set) { f in
                            VStack(spacing: 6) {
                                AtelierCardSurface(fragranceID: f.id, radius: 8, foil: .sheen)
                                    .frame(width: 92, height: 134)
                                Text(f.name).font(.caption.weight(.semibold)).lineLimit(2)
                                    .multilineTextAlignment(.center)
                                Text(f.concentration).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    if set.count > 1 {
                        let common = set.dropFirst().reduce(Set(set[0].notes.map { $0.lowercased() })) {
                            $0.intersection($1.notes.map { $0.lowercased() })
                        }
                        compareRow("Shared notes", common.isEmpty ? "None in common" : common.sorted().map(\.capitalized).joined(separator: ", "))
                        ForEach(set) { f in
                            let accords = Accord.accords(for: f.notes).map(\.rawValue).joined(separator: " · ")
                            compareRow(f.name, [
                                f.notes.isEmpty ? "Notes unknown" : f.notes.joined(separator: ", "),
                                accords.isEmpty ? nil : "Accords (derived): \(accords)",
                                InsightEngine.season(for: f).map { "Suggested season: \($0.0)" }
                            ].compactMap { $0 }.joined(separator: "\n"))
                        }
                    }
                    if others.count < 2 {
                        Text("Add a fragrance to compare").font(.headline)
                        ForEach(pool.filter { p in !others.contains(where: { $0.id == p.id }) }) { f in
                            Button {
                                withAnimation(.snappy) { others.append(f) }
                            } label: {
                                HStack(spacing: 12) {
                                    AtelierCardSurface(fragranceID: f.id, radius: 4, shadowed: false)
                                        .frame(width: 30, height: 44)
                                    VStack(alignment: .leading) {
                                        Text(f.name).font(.subheadline)
                                        Text(f.house).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let suggested, suggested.id != primary.fragrance.id,
                   !others.contains(where: { $0.id == suggested.id }) {
                    others = [suggested]
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
                if !others.isEmpty {
                    ToolbarItem(placement: .topBarLeading) { Button("Clear") { others.removeAll() } }
                }
            }
        }
    }

    private func compareRow(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(detail).font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .atelierPlate(14)
    }
}

// MARK: - Share a collectible as a PNG

/// The exported image is the card face only: approved artwork (or the owner's own photo card),
/// rendered offscreen at the master's native resolution. No controls, notes, prices or
/// ownership data are included.
struct CardShareImage: Transferable {
    let fragrance: Fragrance
    let photoURL: URL?

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            try await item.pngData()
        }
    }

    enum ExportError: Error { case renderFailed }

    @MainActor
    func pngData() throws -> Data {
        let width: CGFloat = 368
        let face = CardFace(fragranceID: fragrance.id, fragrance: fragrance, photoURL: photoURL,
                            side: .front, radius: 18)
            .frame(width: width, height: width * 86 / 59)
        let renderer = ImageRenderer(content: face)
        renderer.scale = 2 // ≈ 736 px wide: the approved masters' native face width
        renderer.isOpaque = false
        guard let data = renderer.uiImage?.pngData() else { throw ExportError.renderFailed }
        return data
    }
}

struct CardShareButton: View {
    @EnvironmentObject private var archive: CollectionStore
    let card: DisplayCard
    var body: some View {
        let photo = archive.photoURL(for: card.fragrance)
        ShareLink(item: CardShareImage(fragrance: card.fragrance, photoURL: photo),
                  preview: SharePreview(card.fragrance.name, image: Image(systemName: "rectangle.portrait"))) {
            Image(systemName: "square.and.arrow.up").frame(width: 30, height: 30)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(photo == nil ? "Share card image" : "Share card image, includes your photo")
    }
}
