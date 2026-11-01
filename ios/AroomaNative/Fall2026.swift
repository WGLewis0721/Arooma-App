import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Browse-only editorial library. Publishing is all-or-nothing: missing images, incomplete
/// rights reviews or unverified product identities keep the entire season unavailable.
/// Loading this catalog never grants a card, records physical ownership or enables sales.
struct Fall2026Card: Decodable, Identifiable, Hashable {
    let rank: Int
    let id: String
    let house: String
    let name: String
    let variant: String
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
        #if AROOMA_INTERNAL_PREVIEW
        true
        #else
        false
        #endif
    }()

    static let cards: [Fall2026Card] = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(Fall2026Manifest.self, from: data),
              manifest.version == 1, manifest.collectionID == "fall-2026-men",
              manifest.cards.count == 30,
              Set(manifest.cards.map(\.id)).count == 30,
              Set(manifest.cards.map(\.rank)) == Set(1...30),
              manifest.cards.allSatisfy({
                  UIImage(named: $0.assetName) != nil &&
                  (internalProofBuild || ($0.status == "approved" &&
                   $0.referencePhotoApproved && $0.productFactsVerified &&
                   $0.artRightsCleared))
              }) else {
            return []
        }
        return manifest.cards.sorted { $0.rank < $1.rank }
    }()

    static var available: Bool { cards.count == 30 }

    static func artwork(for card: Fall2026Card) -> UIImage? {
        UIImage(named: card.assetName)
    }
}

struct AutumnArchiveScreen: View {
    @State private var query = ""
    @State private var selected: Fall2026Card?

    private var matches: [Fall2026Card] {
        guard !query.isEmpty else { return Fall2026Collection.cards }
        return Fall2026Collection.cards.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.house.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(Fall2026Collection.internalProofBuild ? "INTERNAL ARTWORK PROOFS · FALL 2026" : "FALL 2026")
                        .font(.caption2.weight(.semibold))
                        .tracking(3)
                        .foregroundStyle(.secondary)
                    Text("Autumn Archive")
                        .font(.system(.largeTitle, design: .serif))
                    Text(Fall2026Collection.internalProofBuild
                         ? "30 collectible artwork proofs for review. Product accuracy and commercial rights are not yet approved. Not for sale or sharing as official brand artwork."
                         : "30 fragrances, 30 illustrated collector cards. Browse the season without adding anything to your owned collection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                        ForEach(matches) { card in
                            Button { selected = card } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    if let image = Fall2026Collection.artwork(for: card) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .aspectRatio(59.0 / 86.0, contentMode: .fit)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                    Text(card.name)
                                        .font(.caption.weight(.semibold))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Text(card.house)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(card.house + " " + card.name + ". Open collectible.")
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Autumn Archive")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search the season")
            .sheet(item: $selected) { card in
                AutumnArchiveDetail(card: card)
            }
        }
    }
}

struct AutumnArchiveDetail: View {
    let card: Fall2026Card
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsBack = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Group {
                        if showsBack {
                            back
                        } else if let image = Fall2026Collection.artwork(for: card) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .modifier(LiveFoil(strength: 0.35, yaw: 0,
                                                   radius: 16, tint: .white))
                        }
                    }
                    .aspectRatio(59.0 / 86.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 14)
                    .onTapGesture { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { showsBack.toggle() } }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(showsBack ? "Card details. Tap to see artwork." : "Artwork. Tap to flip card.")

                    Button(showsBack ? "See artwork" : "Flip card", systemImage: "arrow.triangle.2.circlepath") {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { showsBack.toggle() }
                    }
                    .buttonStyle(.bordered)

                    if !Fall2026Collection.internalProofBuild {
                        ShareLink(item: AutumnCardPNG(card: card),
                                  preview: SharePreview(card.name, image: Image(systemName: "rectangle.portrait"))) {
                            Label("Share card", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Label("Internal proof · not approved for distribution", systemImage: "exclamationmark.shield")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                }
                .padding(.top, 16)
            }
            .navigationTitle(card.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var back: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let ink = Color(hex: 0x0E1015)
            let copper = Color(hex: 0xC7A46C)
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(ink)
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(copper.opacity(0.70), lineWidth: 1.3)
                    .padding(8)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(card.house.uppercased())
                                .font(.system(size: 10, weight: .medium, design: .serif))
                                .tracking(1.7)
                            Text(card.name.uppercased())
                                .font(.system(size: 29, weight: .regular, design: .serif))
                                .minimumScaleFactor(0.5)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Text(card.variant.uppercased())
                            .font(.system(size: 8, weight: .medium))
                            .tracking(0.8)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: w * 0.28)
                    }
                    Rectangle().fill(copper.opacity(0.9)).frame(height: 1)
                    Text("An independently illustrated fragrance collectible from Arooma's Autumn Archive.")
                        .font(.system(size: 11, design: .serif).italic())
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("FRAGRANCE MAP")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.3)
                        .foregroundStyle(copper)
                    noteRow("TOP", index: 0, width: w)
                    noteRow("HEART", index: 1, width: w)
                    noteRow("BASE", index: 2, width: w)
                    Spacer(minLength: 0)
                    Rectangle().fill(copper.opacity(0.8)).frame(height: 1)
                    HStack(spacing: 0) {
                        fact(card.variant.uppercased(), "CONCENTRATION")
                        fact("INDEPENDENT", "COLLECTION")
                        fact("FALL 2026", "EDITION")
                    }
                    .frame(height: 34)
                    HStack {
                        Spacer()
                        Text("AROOMA  ·  FRAGRANCE COLLECTION")
                            .font(.system(size: 8))
                            .tracking(1.4)
                        Spacer()
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
            }
        }
        .accessibilityLabel(card.house + " " + card.name + " reverse artwork proof; fragrance note information awaits verification.")
    }

    private func fact(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 9, weight: .medium)).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.system(size: 7)).tracking(0.7).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func noteRow(_ stage: String, index: Int, width: CGFloat) -> some View {
        HStack(spacing: 9) {
            if let image = Fall2026Collection.artwork(for: card) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width * 0.51, height: 65)
                    .clipped()
                    .overlay(Color.black.opacity(index == 0 ? 0.06 : index == 1 ? 0.22 : 0.35))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(stage).font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: 0xC7A46C))
                Text("Notes under verification")
                    .font(.system(size: 9, design: .serif).italic())
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(height: 65)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(hex: 0xC7A46C).opacity(0.5)).frame(height: 0.65)
        }
    }

}

struct AutumnCardPNG: Transferable {
    let card: Fall2026Card

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let data = Fall2026Collection.artwork(for: item.card)?.pngData() else {
                throw CocoaError(.fileNoSuchFile)
            }
            return data
        }
    }
}
