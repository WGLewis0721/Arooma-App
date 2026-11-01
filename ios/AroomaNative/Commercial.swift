import SwiftUI
import StoreKit
import PhotosUI
import UIKit
import CryptoKit
import UniformTypeIdentifiers
import Vision
import CoreImage

// MARK: - Commercial catalog and StoreKit products
// Product identifiers must be created in App Store Connect with exactly these values.
// Artwork release and payment eligibility are separate from product code: no real-brand
// collectible is sold without a documented commercial redistribution license.
enum AroomaProducts {
    static let annual = "com.graymatter.arooma.library.annual"
    static let booster = "com.graymatter.arooma.booster.season01"
    static let cardPrefix = "com.graymatter.arooma.card."
    static let framePack = "com.graymatter.arooma.frames.archive"
    static let IDs = [annual, booster, framePack] + CardEdition.catalog.map { cardPrefix + $0.id }
}

struct CardEdition: Identifiable, Hashable, Codable {
    let id: String
    let fragranceID: String
    let title: String
    let series: String
    let finish: String

    // Preview inventory. Releasing these as paid goods requires rights clearance.
    static let catalog: [CardEdition] = [
        .init(id: "dior-archive", fragranceID: "dior", title: "Sauvage Elixir", series: "Archive Foil", finish: "Spectrum"),
        .init(id: "hawas-archive", fragranceID: "hawas", title: "Hawas for Him", series: "Archive Foil", finish: "Prismatic"),
        .init(id: "myslf-archive", fragranceID: "myslf", title: "MYSLF", series: "Archive Foil", finish: "Iridescent"),
        .init(id: "prodigy-archive", fragranceID: "prodigy", title: "Prodigy", series: "Historical", finish: "Iridescent")
    ]
    static func find(_ id: String) -> CardEdition? { catalog.first { $0.id == id } }
}

enum CommercialRelease {
    // This must not be enabled merely because a StoreKit product is registered.
    // First: per-art commercial rights + actual App Store products + server-backed
    // recoverable consumable ledger + public odds disclosure and tested restore.
    static let paidCardsApproved = false
    static let paidBoostersApproved = false
    static let membershipApproved = false

    /// App Review rejects visible purchase screens that cannot complete a purchase (2.1) and
    /// subscription offers without full terms (3.1.2). Until at least one offer is approved
    /// and registered, the storefront, Restore Purchases and App Store product lookups are not
    /// shown at all; My Cards and Card Studio ship as complete free features.
    static var storefrontVisible: Bool { paidCardsApproved || paidBoostersApproved || membershipApproved }
}

enum CardFinish: String, CaseIterable, Codable, Identifiable {
    case obsidian = "Obsidian", ivory = "Ivory", violet = "Violet", emerald = "Emerald"
    var id: String { rawValue }
    var theme: FragranceTheme {
        switch self {
        case .obsidian: .obsidian
        case .ivory: .ivory
        case .violet: .violet
        case .emerald: .emerald
        }
    }
}

struct CreatedCard: Codable, Identifiable, Hashable {
    var id = UUID()
    var fragranceID: String?
    var title: String
    var caption: String
    var photoName: String
    var finish: CardFinish
    var created = Date()
    /// Kept separate from photo pixels so grades can be changed without quality loss.
    var photoFilter: StudioPhotoFilter = .original
}

// Backward-compatible decoder: personal cards saved before filters default to Original.
extension CreatedCard {
    enum CodingKeys: String, CodingKey {
        case id, fragranceID, title, caption, photoName, finish, created, photoFilter
    }

    init(from decoder: Decoder) throws {
        let fields = try decoder.container(keyedBy: CodingKeys.self)
        id = try fields.decode(UUID.self, forKey: .id)
        fragranceID = try fields.decodeIfPresent(String.self, forKey: .fragranceID)
        title = try fields.decode(String.self, forKey: .title)
        caption = try fields.decode(String.self, forKey: .caption)
        photoName = try fields.decode(String.self, forKey: .photoName)
        finish = try fields.decode(CardFinish.self, forKey: .finish)
        created = try fields.decode(Date.self, forKey: .created)
        photoFilter = try fields.decodeIfPresent(StudioPhotoFilter.self, forKey: .photoFilter) ?? .original
    }

    func encode(to encoder: Encoder) throws {
        var fields = encoder.container(keyedBy: CodingKeys.self)
        try fields.encode(id, forKey: .id)
        try fields.encodeIfPresent(fragranceID, forKey: .fragranceID)
        try fields.encode(title, forKey: .title)
        try fields.encode(caption, forKey: .caption)
        try fields.encode(photoName, forKey: .photoName)
        try fields.encode(finish, forKey: .finish)
        try fields.encode(created, forKey: .created)
        try fields.encode(photoFilter, forKey: .photoFilter)
    }
}

struct AcquiredCard: Codable, Identifiable, Hashable {
    var id: String { editionID + ":" + source }
    let editionID: String
    let source: String
    let grantedAt: Date
}
struct CommercialArchive: Codable {
    var created: [CreatedCard] = []
    var grants: [AcquiredCard] = []
    var fulfilledTransactions: [UInt64] = []
    var earnedPackCards: [String] = []
}

// MARK: - Card ownership and commerce
@MainActor final class CardCommerce: ObservableObject {
    @Published private(set) var created: [CreatedCard] = []
    @Published private(set) var grants: [AcquiredCard] = []
    @Published private(set) var ownedProductIDs: Set<String> = []
    @Published private(set) var membershipActive = false
    @Published private(set) var products: [String: Product] = [:]
    @Published var busy = false
    @Published var status = ""
    private var fulfilledTransactions: Set<UInt64> = []
    private var earnedPackCards: [String] = []
    private var listener: Task<Void, Never>?
    private let photoRenderCache = NSCache<NSString, UIImage>()

    private static var documentDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private static var recordURL: URL { documentDirectory.appendingPathComponent("arooma-cards-v1.json") }

    init() {
        if let data = try? Data(contentsOf: Self.recordURL),
           let value = try? JSONDecoder().decode(CommercialArchive.self, from: data) {
            created = value.created
            grants = value.grants
            fulfilledTransactions = Set(value.fulfilledTransactions)
            earnedPackCards = value.earnedPackCards
        }
    }
    deinit { listener?.cancel() }

    func start() async {
        guard listener == nil, CommercialRelease.storefrontVisible else { return }
        listener = Task { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard let self else { break }
                if case .verified(let transaction) = update {
                    await self.fulfill(transaction)
                }
            }
        }
        await refresh()
    }
    func refresh() async {
        do {
            let fetched = try await Product.products(for: AroomaProducts.IDs)
            products = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
        } catch {
            status = "The App Store is unavailable. Your saved cards still work offline."
        }
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var purchased = Set<String>()
        var subscription = false
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result, transaction.revocationDate == nil else { continue }
            purchased.insert(transaction.productID)
            if transaction.productID == AroomaProducts.annual { subscription = true }
        }
        ownedProductIDs = purchased
        membershipActive = subscription
        // Purchases that are no longer entitled are never displayed as an active membership.
        // Consumable pack cards need a server-backed ledger before they are sold.
    }

    func restore() async {
        do {
            try await AppStore.sync() // Explicit user action only.
            await refreshEntitlements()
            status = "Available purchases have been refreshed."
        } catch {
            status = "Could not restore purchases: \(error.localizedDescription)"
        }
    }

    func purchase(_ id: String) async {
        guard let product = products[id] else {
            status = "This offer isn't available in the App Store yet."
            return
        }
        guard CommercialRelease.membershipApproved && id == AroomaProducts.annual
           || CommercialRelease.paidCardsApproved && id.hasPrefix(AroomaProducts.cardPrefix)
           || CommercialRelease.paidCardsApproved && id == AroomaProducts.framePack
           || CommercialRelease.paidBoostersApproved && id == AroomaProducts.booster else {
            status = "Purchases open after content licensing and entitlement recovery are approved."
            return
        }
        busy = true
        defer { busy = false }
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await fulfill(transaction)
                status = "Purchase complete."
            case .success(.unverified):
                status = "This transaction could not be verified. No content was unlocked."
            case .pending:
                status = "Your purchase is pending."
            case .userCancelled: break
            @unknown default:
                status = "The purchase could not be completed."
            }
        } catch {
            status = error.localizedDescription
        }
    }

    private func fulfill(_ transaction: StoreKit.Transaction) async {
        guard transaction.revocationDate == nil else {
            await refreshEntitlements()
            return
        }
        if transaction.productID == AroomaProducts.booster {
            // Never enable paid boosters without a remote, recoverable grant ledger.
            // Local data cannot guarantee restoration after device loss or reinstall.
            if CommercialRelease.paidBoostersApproved,
               !fulfilledTransactions.contains(transaction.id) {
                status = "Pack delivery requires the approved recovery service."
                return // Intentionally leave unfinished for recovery; do not invent a grant.
            }
        } else if let edition = CardEdition.catalog.first(where: {
            AroomaProducts.cardPrefix + $0.id == transaction.productID
        }), !grants.contains(where: { $0.editionID == edition.id && $0.source == transaction.productID }) {
            grants.append(.init(editionID: edition.id,
                                source: transaction.productID, grantedAt: transaction.purchaseDate))
            save()
        }
        await refreshEntitlements()
        await transaction.finish()
    }

    func owns(_ edition: CardEdition) -> Bool {
        grants.contains { $0.editionID == edition.id } ||
        ownedProductIDs.contains(AroomaProducts.cardPrefix + edition.id)
    }
    func hasLibraryAccess(_ edition: CardEdition) -> Bool {
        owns(edition) || membershipActive
    }
    /// A portable, complete backup for personal Card Studio creations.
    /// Purchased entitlements are deliberately excluded; StoreKit owns those.
    func backupData() -> Data? {
        var photos: [String: Data] = [:]
        for card in created {
            guard let data = try? Data(contentsOf: Self.documentDirectory.appendingPathComponent(card.photoName)) else {
                status = "Some source photos are missing. The backup was not created."
                return nil
            }
            photos[card.photoName] = data
        }
        return try? JSONEncoder().encode(StudioBackup(version: 1, cards: created, photos: photos))
    }
    func importBackup(_ data: Data) -> Bool {
        guard data.count <= 200_000_000,
              let backup = try? JSONDecoder().decode(StudioBackup.self, from: data),
              backup.version == 1, backup.cards.count <= 2000 else {
            status = "Unsupported or oversized backup. Nothing was imported."
            return false
        }
        let names = Set(backup.cards.map(\.photoName))
        guard names.count == backup.cards.count,
              names.allSatisfy({ $0.hasPrefix("studio-") &&
                  ($0.hasSuffix(".jpg") || $0.hasSuffix(".png")) && !$0.contains("/") }),
              names.allSatisfy({ name in
                  guard let bytes = backup.photos[name] else { return false }
                  return bytes.count <= 12_000_000 && UIImage(data: bytes) != nil
              }) else {
            status = "Backup contains missing or invalid photos. Nothing was imported."
            return false
        }
        // Merge into the existing library, never replace it. Names are remapped to prevent
        // overwriting files already on the phone and the backed-up UUIDs are preserved.
        var imported: [CreatedCard] = []
        var written: [URL] = []
        do {
            for card in backup.cards where !created.contains(where: { $0.id == card.id }) {
                let filename = "studio-\(UUID().uuidString).\(card.photoName.hasSuffix(".png") ? "png" : "jpg")"
                let destination = Self.documentDirectory.appendingPathComponent(filename)
                try backup.photos[card.photoName]!.write(to: destination, options: .atomic)
                written.append(destination)
                var replacement = card
                replacement.photoName = filename
                imported.append(replacement)
            }
        } catch {
            for file in written { try? FileManager.default.removeItem(at: file) }
            status = "Import failed. Existing cards were not changed."
            return false
        }
        created.insert(contentsOf: imported, at: 0)
        save()
        status = "Imported \(imported.count) personal cards. Existing cards were preserved."
        return true
    }
    func photo(for card: CreatedCard) -> UIImage? {
        let key = NSString(string: card.id.uuidString + ":" + card.photoFilter.rawValue)
        if let cached = photoRenderCache.object(forKey: key) { return cached }
        guard let original = UIImage(contentsOfFile: Self.documentDirectory.appendingPathComponent(card.photoName).path) else {
            return nil
        }
        let rendered = StudioPhotoFilters.render(image: original, preset: card.photoFilter,
                                                 maxDimension: 1600) ?? original
        photoRenderCache.setObject(rendered, forKey: key)
        return rendered
    }
    @discardableResult
    func create(title: String, caption: String, photo: Data, finish: CardFinish, fragranceID: String?,
                cutout: Bool = false, filter: StudioPhotoFilter = .original) -> Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let raw = UIImage(data: photo),
              let imageBytes = cutout ? raw.pngData() : raw.jpegData(compressionQuality: 0.86) else {
            status = "Choose a readable bottle photo and enter a card name."
            return false
        }
        let filename = "studio-\(UUID().uuidString).\(cutout ? "png" : "jpg")"
        do {
            try imageBytes.write(to: Self.documentDirectory.appendingPathComponent(filename), options: .atomic)
            created.insert(.init(fragranceID: fragranceID, title: String(title.prefix(80)),
                                 caption: String(caption.prefix(120)), photoName: filename,
                                 finish: finish, photoFilter: filter), at: 0)
            save()
            return true
        } catch {
            status = "Could not save the card photo: \(error.localizedDescription)"
            return false
        }
    }
    func deleteCreated(_ id: UUID) {
        guard let card = created.first(where: { $0.id == id }) else { return }
        created.removeAll { $0.id == id }
        photoRenderCache.removeObject(forKey: NSString(string: id.uuidString + ":" + card.photoFilter.rawValue))
        save()
        // Delete photo only when it is no longer used by a design.
        if !created.contains(where: { $0.photoName == card.photoName }) {
            try? FileManager.default.removeItem(at: Self.documentDirectory.appendingPathComponent(card.photoName))
        }
    }
    private func save() {
        let record = CommercialArchive(created: created, grants: grants,
                                       fulfilledTransactions: Array(fulfilledTransactions),
                                       earnedPackCards: earnedPackCards)
        do {
            try JSONEncoder().encode(record).write(to: Self.recordURL, options: .atomic)
        } catch {
            status = "Card library could not be saved: \(error.localizedDescription)"
        }
    }
}

struct StudioBackup: Codable {
    let version: Int
    let cards: [CreatedCard]
    let photos: [String: Data]
}

struct StudioBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = contents
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Reusable card compositions
struct StudioCardFace: View {
    let title: String
    let caption: String
    let image: UIImage?
    let finish: CardFinish
    var liveFoil = true
    var body: some View {
        let palette = finish.theme.palette
        ZStack {
            RoundedRectangle(cornerRadius: 19)
                .fill(LinearGradient(colors: [palette.field, palette.secondary, palette.field],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack(spacing: 9) {
                HStack {
                    Text("AROOMA").font(.caption2.weight(.semibold)).tracking(3)
                    Spacer()
                    Image(systemName: "sparkle")
                }.foregroundStyle(palette.accent)
                Spacer(minLength: 0)
                Group {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                    } else {
                        Image(systemName: "camera.macro")
                            .resizable().scaledToFit().padding(42)
                            .foregroundStyle(palette.accent)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 245)
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
                Spacer(minLength: 0)
                Text(title).font(.system(size: 25, weight: .medium, design: .serif))
                    .lineLimit(2).minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(caption.isEmpty ? "PERSONAL EDITION" : caption.uppercased())
                    .font(.caption2).tracking(1.3).lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(palette.accent)
            }
            .foregroundStyle(.white)
            .padding(20)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 19)
                .strokeBorder(LinearGradient(colors: [palette.accent, .white.opacity(0.35), palette.accent],
                                             startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.6)
        }
        .aspectRatio(59.0 / 86.0, contentMode: .fit)
        .clipped()
        .modifier(LiveFoil(strength: liveFoil ? 0.55 : 0,
                           yaw: 0, radius: 19, tint: palette.accent))
    }
}

struct StudioPNG: Transferable {
    let card: CreatedCard
    let photo: UIImage?
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            try await item.png()
        }
    }
    enum Failure: Error { case rendering }
    @MainActor func png() throws -> Data {
        let view = StudioCardFace(title: card.title, caption: card.caption, image: photo,
                                  finish: card.finish, liveFoil: false)
            .frame(width: 590, height: 860)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let data = renderer.uiImage?.pngData() else { throw Failure.rendering }
        return data
    }
}

// MARK: - On-device bottle cutout
enum BottleCutout {
    // Optional native Vision segmentation. The original photo always remains available.
    static func isolate(_ data: Data) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            guard let cgImage = UIImage(data: data)?.cgImage else { return nil as Data? }
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                guard let observation = request.results?.first,
                      !observation.allInstances.isEmpty else { return nil as Data? }
                let buffer = try observation.generateMaskedImage(
                    ofInstances: observation.allInstances,
                    from: handler,
                    croppedToInstancesExtent: false
                )
                let context = CIContext()
                let image = CIImage(cvPixelBuffer: buffer)
                guard let result = context.createCGImage(image, from: image.extent) else { return nil as Data? }
                return UIImage(cgImage: result).pngData()
            } catch {
                return nil as Data?
            }
        }.value
    }
}

// MARK: - Personal Card Studio
struct CardStudioScreen: View {
    @EnvironmentObject private var commerce: CardCommerce
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var sourcePhoto: Data?
    @State private var usingCutout = false
    @State private var isolating = false
    @State private var title = ""
    @State private var caption = ""
    @State private var finish: CardFinish = .obsidian
    @State private var photoFilter: StudioPhotoFilter = .original
    @State private var filteredPreview: UIImage?
    @State private var fragranceID: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    StudioCardFace(title: title.isEmpty ? "Your fragrance" : title,
                                   caption: caption, image: filteredPreview ?? photoData.flatMap(UIImage.init(data:)),
                                   finish: finish)
                        .frame(width: 236, height: 344)
                        .shadow(radius: 16, y: 10)
                        .padding(.top, 16)
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(photoData == nil ? "Choose bottle photo" : "Change bottle photo", systemImage: "photo.on.rectangle")
                    }.buttonStyle(.bordered)
                    if let photoData {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PHOTO FILTERS")
                                .font(.caption2.weight(.semibold))
                                .tracking(1.8)
                                .foregroundStyle(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 12) {
                                    ForEach(StudioPhotoFilter.allCases) { preset in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.18)) { photoFilter = preset }
                                        } label: {
                                            VStack(spacing: 6) {
                                                StudioFilterThumbnail(photo: photoData, preset: preset)
                                                    .overlay {
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .strokeBorder(photoFilter == preset
                                                                ? archive.theme.palette.accent : .clear, lineWidth: 2.5)
                                                    }
                                                Text(preset.rawValue)
                                                    .font(.caption2.weight(photoFilter == preset ? .bold : .regular))
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.center)
                                                    .frame(width: 76)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(preset.rawValue + " photo filter")
                                        .accessibilityAddTraits(photoFilter == preset ? [.isSelected] : [])
                                    }
                                }
                                .padding(.vertical, 3)
                            }
                            Text(photoFilter.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if sourcePhoto != nil {
                        Button {
                            if usingCutout {
                                photoData = sourcePhoto
                                usingCutout = false
                            } else if let sourcePhoto {
                                isolating = true
                                Task {
                                    let isolated = await BottleCutout.isolate(sourcePhoto)
                                    if let isolated {
                                        photoData = isolated
                                        usingCutout = true
                                    } else {
                                        commerce.status = "Subject isolation was unavailable. The original photo is intact."
                                    }
                                    isolating = false
                                }
                            }
                        } label: {
                            Label(usingCutout ? "Use original photo" : "Isolate bottle",
                                  systemImage: usingCutout ? "arrow.uturn.backward" : "person.crop.rectangle.stack")
                        }
                        .buttonStyle(.bordered)
                        .disabled(isolating)
                        if isolating { ProgressView("Separating bottle from background") }
                    }
                    TextField("Card title", text: $title).textInputAutocapitalization(.words)
                    TextField("Edition caption (optional)", text: $caption)
                    Picker("Finish", selection: $finish) {
                        ForEach(CardFinish.allCases) { style in Text(style.rawValue).tag(style) }
                    }
                    .pickerStyle(.segmented)
                    Picker("Link to bottle", selection: $fragranceID) {
                        Text("Personal card").tag(nil as String?)
                        ForEach(archive.bottles) { bottle in
                            if let fragrance = archive.fragrance(id: bottle.fragranceID) {
                                Text(fragrance.name).tag(Optional(fragrance.id))
                            }
                        }
                    }
                    Text("Filters change the look, not the container shape. The selected photo and filter choice are saved separately on this iPhone. Share only when you choose.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button {
                        guard let data = photoData else { return }
                        saving = true
                        if commerce.create(title: title, caption: caption, photo: data,
                                           finish: finish, fragranceID: fragranceID,
                                           cutout: usingCutout, filter: photoFilter) {
                            dismiss()
                        }
                        saving = false
                    } label: {
                        Label("Save to My Cards", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(saving || title.trimmingCharacters(in: .whitespaces).isEmpty || photoData == nil)
                }
                .padding(20)
            }
            .navigationTitle("Card Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task(id: photoItem) {
                if let photoItem, let data = try? await photoItem.loadTransferable(type: Data.self),
                   UIImage(data: data) != nil {
                    sourcePhoto = data
                    photoData = data
                    usingCutout = false
                }
            }
            .onChange(of: photoData) { _, _ in renderFilterPreview() }
            .onChange(of: photoFilter) { _, _ in renderFilterPreview() }
        }
    }

    private func renderFilterPreview() {
        guard let bytes = photoData else {
            filteredPreview = nil
            return
        }
        filteredPreview = nil
        let selected = photoFilter
        Task {
            let image = await Task.detached(priority: .userInitiated) {
                StudioPhotoFilters.render(data: bytes, preset: selected, maxDimension: 1100)
            }.value
            guard photoData == bytes && photoFilter == selected else { return }
            filteredPreview = image
        }
    }
}

// MARK: - Two independent collections: physical bottles and digital cards
struct MyCardsScreen: View {
    @EnvironmentObject private var archive: CollectionStore
    @EnvironmentObject private var commerce: CardCommerce
    @State private var studio = false
    @State private var selectedCard: CreatedCard?
    @State private var section = 0
    @State private var exporting = false
    @State private var importing = false
    @State private var exportDocument: StudioBackupDocument?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("THE DIGITAL ARCHIVE").font(.caption2.weight(.semibold))
                                .tracking(2).foregroundStyle(archive.theme.palette.accent)
                            Text("My Cards").font(.system(.largeTitle, design: .serif))
                        }
                        Spacer()
                        Button { studio = true } label: {
                            Image(systemName: "plus").frame(width: 44, height: 44)
                        }.buttonStyle(.glass).accessibilityLabel("Create card")
                    }
                    if CommercialRelease.storefrontVisible {
                        Picker("Cards", selection: $section) {
                            Text("My Cards").tag(0)
                            Text("Discover").tag(1)
                        }.pickerStyle(.segmented)
                    }
                    if section == 0 || !CommercialRelease.storefrontVisible { ownedSection } else { discoverSection }
                    if !commerce.status.isEmpty {
                        Text(commerce.status).font(.footnote).foregroundStyle(.secondary)
                    }
                }.padding(20)
            }
            .navigationTitle("Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Card Studio", systemImage: "paintbrush.pointed") { studio = true }
                        Button("Export My Cards", systemImage: "square.and.arrow.up") {
                            if let data = commerce.backupData() {
                                exportDocument = StudioBackupDocument(data: data)
                                exporting = true
                            }
                        }
                        Button("Import My Cards", systemImage: "square.and.arrow.down") {
                            importing = true
                        }
                        if CommercialRelease.storefrontVisible {
                            Button("Restore Purchases", systemImage: "arrow.clockwise") {
                                Task { await commerce.restore() }
                            }
                        }
                    } label: { Image(systemName: "ellipsis.circle") }
                        .accessibilityLabel("Card library actions")
                }
            }
            .sheet(isPresented: $studio) {
                CardStudioScreen().environmentObject(archive).environmentObject(commerce)
            }
            .sheet(item: $selectedCard) { card in
                CreatedCardDetails(card: card)
                    .environmentObject(commerce)
            }
            .fileExporter(isPresented: $exporting, document: exportDocument,
                          contentType: .json, defaultFilename: "Arooma-My-Cards") { result in
                if case .failure(let error) = result { commerce.status = error.localizedDescription }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    if let data = try? Data(contentsOf: url) { _ = commerce.importBackup(data) }
                    else { commerce.status = "Could not read the chosen backup file." }
                case .failure(let error):
                    commerce.status = error.localizedDescription
                }
            }
        }
    }

    private var ownedSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if commerce.created.isEmpty && !CardEdition.catalog.contains(where: commerce.hasLibraryAccess) {
                ContentUnavailableView("No digital cards yet", systemImage: "rectangle.on.rectangle.angled",
                    description: Text(CommercialRelease.storefrontVisible
                        ? "Create your first personal card in Studio, or browse available editions."
                        : "Turn a photo of any bottle into your own collectible card in Card Studio."))
                Button("Open Card Studio") { studio = true }.buttonStyle(.borderedProminent)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(commerce.created) { card in
                    Button { selectedCard = card } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            StudioCardFace(title: card.title, caption: card.caption,
                                           image: commerce.photo(for: card), finish: card.finish)
                            Text(card.title).font(.subheadline.weight(.medium)).lineLimit(1)
                        }
                    }.buttonStyle(.plain)
                }
                ForEach(CardEdition.catalog.filter(commerce.hasLibraryAccess)) { edition in
                    VStack(alignment: .leading, spacing: 7) {
                        CollectibleCard(id: edition.fragranceID).frame(maxWidth: .infinity)
                        Text(edition.title).font(.subheadline.weight(.medium))
                        if commerce.membershipActive && !commerce.owns(edition) {
                            Text("Library access · subscription")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Text("My Bottles and My Cards are independent. A card can represent a fragrance you don't physically own.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Arooma Card Library").font(.system(.title2, design: .serif))
                Text("The collection catalog is prepared for exact-card purchases, seasonal editions, and membership access. Sales remain closed until artwork rights and recovery are verified.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(CardEdition.catalog) { edition in
                HStack(spacing: 14) {
                    CollectibleCard(id: edition.fragranceID)
                        .frame(width: 82, height: 120)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(edition.title).font(.headline)
                        Text("\(edition.series) · \(edition.finish)").font(.caption)
                        Text(commerce.owns(edition) ? "In My Cards" : "Preview edition")
                            .font(.caption).foregroundStyle(.secondary)
                        if let product = commerce.products[AroomaProducts.cardPrefix + edition.id] {
                            Text(product.displayPrice).font(.caption.weight(.medium))
                        }
                        if !commerce.owns(edition) {
                            Button("Acquire exact card") {
                                Task { await commerce.purchase(AroomaProducts.cardPrefix + edition.id) }
                            }
                            .font(.caption.weight(.semibold))
                            .disabled(!CommercialRelease.paidCardsApproved || commerce.busy)
                        }
                    }
                    Spacer()
                }.padding(.vertical, 5)
            }
            Divider()
            Text("Library Membership").font(.system(.title2, design: .serif))
            Text(commerce.membershipActive ? "Membership active" :
                    (commerce.products[AroomaProducts.annual]?.displayPrice ?? "Annual price unavailable"))
                .foregroundStyle(.secondary)
            Button("View Membership") {
                Task { await commerce.purchase(AroomaProducts.annual) }
            }
            .buttonStyle(.bordered)
            .disabled(!CommercialRelease.membershipApproved || commerce.busy)
            Divider()
            Text("Seasonal Booster").font(.system(.title2, design: .serif))
            Text("A booster contains randomized digital cards. Paid packs stay unavailable until edition contents, odds, licensing and recoverable card grants are published.")
                .font(.subheadline).foregroundStyle(.secondary)
            Button("Open Booster") {
                Task { await commerce.purchase(AroomaProducts.booster) }
            }.buttonStyle(.bordered).disabled(!CommercialRelease.paidBoostersApproved || commerce.busy)
            Divider()
            Button("Restore Purchases") { Task { await commerce.restore() } }
                .buttonStyle(.bordered)
            Text("Arooma is independent of the fragrance houses pictured. Card artwork distribution and purchases require documented permissions.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}
struct CreatedCardDetails: View {
    @EnvironmentObject private var commerce: CardCommerce
    @Environment(\.dismiss) private var dismiss
    let card: CreatedCard
    @State private var confirmDelete = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StudioCardFace(title: card.title, caption: card.caption,
                                   image: commerce.photo(for: card), finish: card.finish)
                        .frame(width: 295, height: 430)
                    ShareLink(item: StudioPNG(card: card, photo: commerce.photo(for: card)),
                              preview: SharePreview(card.title, image: Image(systemName: "rectangle.portrait"))) {
                        Label("Share Card Image", systemImage: "square.and.arrow.up")
                    }.buttonStyle(.borderedProminent)
                    Text("Filter: \(card.photoFilter.rawValue)")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Created \(card.created.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Delete Personal Card", role: .destructive) { confirmDelete = true }
                        .buttonStyle(.bordered)
                }.padding(20)
            }
            .navigationTitle(card.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .confirmationDialog("Delete this digital card?", isPresented: $confirmDelete) {
                Button("Delete Card", role: .destructive) {
                    commerce.deleteCreated(card.id)
                    dismiss()
                }
            }
        }
    }
}
