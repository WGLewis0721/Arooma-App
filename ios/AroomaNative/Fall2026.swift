import SwiftUI
import UIKit

/// Fragrance identities behind 30 editorial card fronts. The original native live deck
/// presents them with its existing motor, foil, flip and ownership flows; public sales
/// remain disabled pending the separate artwork rights/metadata review.
/// Research-backed scent notes, independent of image approval or distribution rights.
struct Fall2026NotePyramid: Decodable, Hashable {
    let top: [String]
    let heart: [String]
    let base: [String]
    let sourceURL: String
    let sourceType: String

    var complete: Bool {
        !top.isEmpty && !heart.isEmpty && !base.isEmpty && URL(string: sourceURL)?.scheme == "https"
    }
}

struct Fall2026Card: Decodable, Identifiable, Hashable {
    let rank: Int
    let id: String
    let house: String
    let name: String
    let variant: String
    /// Visual scene direction is intentionally kept separate from actual perfume notes.
    let sceneBrief: String
    let notePyramid: Fall2026NotePyramid
    let status: String
    let referencePhotoApproved: Bool
    let productFactsVerified: Bool
    let artRightsCleared: Bool

    var title: String { name }
    var assetName: String { "fall2026-" + id }
}

private struct Fall2026Manifest: Decodable {
    let version: Int
    let collectionID: String
    let cards: [Fall2026Card]
}

enum Fall2026Collection {
    // The temporary proof preview exists only in a separately flagged *internal TestFlight*
    // build. A normal App Store build requires all 30 artwork/fact/rights approvals.
    static let internalProofBuild: Bool = {
        #if AROOMA_INTERNAL_PREVIEW || DEBUG
        true
        #else
        false
        #endif
    }()

    /// Always retain stable identities for an owner who captured a fragrance in TestFlight.
    /// A later app without the artwork must not make their bottle or journal disappear.
    static let entries: [Fall2026Card] = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(Fall2026Manifest.self, from: data),
              manifest.version == 1, manifest.collectionID == "fall-2026-men",
              manifest.cards.count == 30,
              Set(manifest.cards.map(\.id)).count == 30,
              Set(manifest.cards.map(\.rank)) == Set(1...30),
              manifest.cards.allSatisfy({ $0.notePyramid.complete }) else { return [] }
        return manifest.cards.sorted { $0.rank < $1.rank }
    }()

    /// Only the private demo or an independently approved commercial set gets artwork.
    static let cards: [Fall2026Card] = {
        guard entries.count == 30,
              entries.allSatisfy({
                  UIImage(named: $0.assetName) != nil &&
                  (internalProofBuild || ($0.status == "approved" &&
                   $0.referencePhotoApproved && $0.productFactsVerified &&
                   $0.artRightsCleared))
              }) else { return [] }
        return entries
    }()

    static var available: Bool { cards.count == 30 }

    /// Generated Image Sets are packaged only for internal TestFlight / local debug.
    static func artwork(for card: Fall2026Card) -> UIImage? {
        UIImage(named: card.assetName)
    }

    static func entry(for fragranceID: String) -> Fall2026Card? {
        guard fragranceID.hasPrefix("fall2026-") else { return nil }
        let id = String(fragranceID.dropFirst("fall2026-".count))
        return entries.first { $0.id == id }
    }

    /// These are catalog entries, not fake ownership grants or paid entitlements.
    static var fragrances: [Fragrance] {
        entries.map { card in
            Fragrance(id: card.assetName, house: card.house, name: card.name,
                      concentration: card.variant, year: "",
                      top: card.notePyramid.top, heart: card.notePyramid.heart,
                      base: card.notePyramid.base, shelf: .autumn, archival: false)
        }
    }
}

/// Uses the same true 3D flip and angle-dependent foil as the four original cards.
/// The reverse presents the sourced actual note pyramid of the precise fragrance variant.
struct Fall2026Reverse: View {
    let card: Fall2026Card

    private let bronze = Color(hex: 0xC9AC79)
    private let ink = Color(hex: 0x0F1118)


    var body: some View {
        GeometryReader { bounds in
            let width = bounds.size.width
            let scale = width / 340.0
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(ink)
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(bronze.opacity(0.75), lineWidth: max(0.7, 1.1 * scale))
                    .padding(9 * scale)
                VStack(alignment: .leading, spacing: 9 * scale) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2 * scale) {
                            Text(card.house.uppercased())
                                .font(.system(size: 10 * scale, weight: .medium, design: .serif))
                                .tracking(1.4 * scale)
                                .lineLimit(1).minimumScaleFactor(0.7)
                            Text(card.name.uppercased())
                                .font(.system(size: 28 * scale, weight: .regular, design: .serif))
                                .lineLimit(2)
                                .minimumScaleFactor(0.6)
                        }
                        Spacer(minLength: 2)
                        Text(card.variant.uppercased())
                            .font(.system(size: 8 * scale, weight: .medium))
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: width * 0.27)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Rectangle().fill(bronze).frame(height: max(0.7, scale))
                    Text("AUTUMN ARCHIVE  ·  2026")
                        .font(.system(size: 10 * scale, weight: .semibold))
                        .tracking(scale)
                        .foregroundStyle(bronze)
                    Text("A sourced olfactory map of the fragrance, from first impression to lasting trail.")
                        .font(.system(size: 11 * scale, design: .serif).italic())
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.white.opacity(0.80))
                    ForEach(0..<3, id: \.self) { index in
                        noteStrip(index: index, width: width, scale: scale)
                    }
                    Spacer(minLength: 0)
                    Rectangle().fill(bronze.opacity(0.8)).frame(height: max(0.7, scale))
                    HStack(spacing: 0) {
                        footer(card.variant, label: "CONCENTRATION", scale: scale)
                        footer("ARTIST SERIES", label: "COLLECTION", scale: scale)
                        footer("FALL 2026", label: "EDITION", scale: scale)
                    }
                    HStack {
                        Spacer(minLength: 0)
                        Text("AROOMA  ·  SOURCED FRAGRANCE NOTES")
                            .font(.system(size: 8 * scale))
                            .tracking(1.2 * scale)
                        Spacer(minLength: 0)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24 * scale)
                .padding(.vertical, 27 * scale)
            }
        }
        .aspectRatio(59.0 / 86.0, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(card.house + ", " + card.name + ", top notes: " +
                            card.notePyramid.top.joined(separator: ", ") + "; heart notes: " +
                            card.notePyramid.heart.joined(separator: ", ") + "; base notes: " +
                            card.notePyramid.base.joined(separator: ", "))
    }

    private func noteStrip(index: Int, width: CGFloat, scale: CGFloat) -> some View {
        let label = ["TOP NOTES", "HEART NOTES", "BASE NOTES"][index]
        let notes = [card.notePyramid.top, card.notePyramid.heart, card.notePyramid.base][index]
        let value = notes.joined(separator: " · ")
        return HStack(spacing: 10 * scale) {
            if let picture = ApprovedArtwork.image(for: card.assetName, side: .front) {
                Image(uiImage: picture)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width * 0.47, height: 65 * scale)
                    .clipped()
                    .overlay(ink.opacity(Double(index) * 0.13))
            } else {
                Rectangle().fill(bronze.opacity(0.12))
                    .frame(width: width * 0.47, height: 65 * scale)
            }
            VStack(alignment: .leading, spacing: 4 * scale) {
                Text(label)
                    .font(.system(size: 9 * scale, weight: .semibold))
                    .tracking(0.7 * scale)
                    .foregroundStyle(bronze)
                Text(value)
                    .font(.system(size: 10 * scale, design: .serif).italic())
                    .lineLimit(4)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer(minLength: 0)
        }
        .frame(height: 65 * scale)
        .overlay(alignment: .bottom) {
            Rectangle().fill(bronze.opacity(0.65))
                .frame(height: max(0.5, scale * 0.7))
        }
    }

    private func footer(_ value: String, label: String, scale: CGFloat) -> some View {
        VStack(spacing: 3 * scale) {
            Text(value.uppercased())
                .font(.system(size: 8 * scale, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(label)
                .font(.system(size: 7 * scale))
                .tracking(0.4 * scale)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }
}
