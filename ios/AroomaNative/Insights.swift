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

// MARK: - Insight panel (peek / expanded)

struct InsightPanel: View {
    @EnvironmentObject private var archive: CollectionStore
    let card: DisplayCard
    let expanded: Bool
    let compare: () -> Void
    let close: () -> Void

    var body: some View {
        let lines = InsightEngine.lines(for: card, in: archive)
        let accent = archive.theme.palette.accent
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    AtelierEyebrow(text: "Insights", accent: accent)
                    Text(card.fragrance.name)
                        .font(.system(.title3, design: .serif))
                        .lineLimit(1)
                }
                Spacer()
                CardShareButton(card: card)
                Button(action: compare) {
                    Image(systemName: "square.split.2x1").frame(width: 30, height: 30)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Compare")
                Button(action: close) {
                    Image(systemName: "chevron.down").frame(width: 30, height: 30)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Close insights")
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(expanded ? lines : Array(lines.prefix(3))) { line in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(line.title).font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(line.basis.rawValue.uppercased())
                                    .font(.system(size: 8, weight: .bold)).tracking(1)
                                    .foregroundStyle(line.basis == .suggestion ? Color.secondary : accent)
                            }
                            Text(line.detail).font(.footnote).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    if !expanded && lines.count > 3 {
                        Text("Swipe up for \(lines.count - 3) more")
                            .font(.caption).foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDisabled(!expanded)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .top) {
            Capsule().fill(.secondary.opacity(0.5)).frame(width: 36, height: 5).padding(.top, 6)
        }
    }
}

// MARK: - Compare (2–3 cards)

struct CompareSheet: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.dismiss) private var dismiss
    let primary: DisplayCard
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
