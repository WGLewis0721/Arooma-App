import Foundation
import SwiftUI

/// A new native disk format: never reads, modifies or migrates the retired browser's localStorage.
/// All ownership data lives in the application's Documents directory and stays on device.
@MainActor final class CollectionStore: ObservableObject {
    @Published var mode: CollectionMode = .demo { didSet { persist() } }
    @Published var theme: FragranceTheme = .obsidian { didSet { persist() } }
    @Published var appearance: Appearance = .system { didSet { persist() } }
    @Published var layout: CardLayout = .coverFlow { didSet { persist() } }
    @Published var selectedDemoID = "dior" { didSet { persist() } }
    @Published var selectedMineID: UUID? { didSet { persist() } }
    @Published var selectedShelf: FragranceShelf = .autumn { didSet { persist() } }
    @Published var rotationID: UUID? { didSet { persist() } }
    @Published var bottles: [BottleRecord] = [] { didSet { persist() } }
    @Published var rotations: [SavedRotation] = [] { didSet { persist() } }
    @Published var shelfNames: [String: String] = [:] { didSet { persist() } }
    @Published var wearSessions: [WearSession] = [] { didSet { persist() } }
    @Published var customFragrances: [Fragrance] = [] { didSet { persist() } }
    @Published var savedLayers: [LayerPreset] = [] { didSet { persist() } }
    @Published var onboarded = false { didSet { persist() } }
    @Published var wishlist: [WishlistEntry] = [] { didSet { persist() } }
    @Published var selectedWishID: UUID? { didSet { persist() } }

    private var hydrating = true
    private static var location: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("arooma-native-v1.json")
    }
    init() {
        if let data = try? Data(contentsOf: Self.location),
           let saved = try? JSONDecoder().decode(SavedArchive.self, from: data) {
            mode = saved.mode; theme = saved.theme; appearance = saved.appearance
            layout = saved.layout; selectedDemoID = saved.selectedDemoID
            selectedMineID = saved.selectedMineID; selectedShelf = saved.selectedShelf
            rotationID = saved.rotationID; bottles = saved.bottles
            rotations = saved.rotations; onboarded = saved.onboarded
            shelfNames = saved.shelfNames ?? [:]; wearSessions = saved.wearSessions ?? []
            customFragrances = saved.customFragrances ?? []
            savedLayers = saved.savedLayers ?? []
            wishlist = saved.wishlist ?? []
            selectedWishID = saved.selectedWishID
            if saved.wishlistMode == true { mode = .wishlist }
        }
        hydrating = false
    }
    private func persist() {
        guard !hydrating else { return }
        // `.wishlist` is stored as Mine + wishlistMode so older builds still decode the archive.
        let snapshot = SavedArchive(mode: mode == .wishlist ? .mine : mode, theme: theme, appearance: appearance,
            layout: layout, selectedDemoID: selectedDemoID, selectedMineID: selectedMineID,
            selectedShelf: selectedShelf, rotationID: rotationID, bottles: bottles,
            rotations: rotations, onboarded: onboarded,
            shelfNames: shelfNames, wearSessions: wearSessions, customFragrances: customFragrances, savedLayers: savedLayers,
            wishlist: wishlist, selectedWishID: selectedWishID, wishlistMode: mode == .wishlist ? true : nil)
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: Self.location, options: .atomic)
        } catch {
            NSLog("Arooma could not save native collection: %@", error.localizedDescription)
        }
    }
    var catalog: [Fragrance] { Fragrance.catalog + customFragrances }
    func fragrance(id: String) -> Fragrance? { catalog.first(where: { $0.id == id }) }
    func photoURL(for fragrance: Fragrance) -> URL? {
        guard let name = fragrance.photoFileName else { return nil }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
    }
    @discardableResult
    func quickAdd(name: String, imageData: Data? = nil) -> Fragrance? {
        let clean = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(90))
        guard !clean.isEmpty || imageData != nil else { return nil }
        let identifier = UUID().uuidString
        var photoFile: String?
        if let imageData {
            let filename = "capture-\(identifier).jpg"
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(filename)
            if (try? imageData.write(to: url, options: .atomic)) != nil { photoFile = filename }
        }
        let label = clean.isEmpty ? "New fragrance" : clean
        let fragrance = Fragrance(id: "personal-\(identifier)", house: "My Collection",
            name: label, concentration: "Personal discovery", year: "",
            top: [], heart: [], base: [], shelf: .autumn, archival: false,
            photoFileName: photoFile)
        customFragrances.append(fragrance)
        add(fragrance)
        return fragrance
    }
    func renamePersonalFragrance(id: String, name: String, house: String) {
        guard let i = customFragrances.firstIndex(where: { $0.id == id }) else { return }
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        customFragrances[i].name = String(cleanName.prefix(90))
        let cleanHouse = house.trimmingCharacters(in: .whitespacesAndNewlines)
        customFragrances[i].house = cleanHouse.isEmpty ? "My Collection" : String(cleanHouse.prefix(80))
    }
    var cards: [DisplayCard] {
        switch mode {
        case .demo:
            return Fragrance.catalog.map { DisplayCard(id: $0.id, fragrance: $0, bottleID: nil) }
        case .mine:
            return bottles.compactMap { b in
                guard let f = fragrance(id: b.fragranceID) else { return nil }
                return DisplayCard(id: b.id.uuidString, fragrance: f, bottleID: b.id)
            }
        case .wishlist:
            return wishlist.compactMap { w in
                guard let f = fragrance(id: w.fragranceID) else { return nil }
                return DisplayCard(id: "wish-\(w.id.uuidString)", fragrance: f, bottleID: nil, wishID: w.id)
            }
        }
    }
    var displayedCards: [DisplayCard] {
        guard layout == .fan, mode == .mine,
              let rotation = rotations.first(where: { $0.id == rotationID }),
              !rotation.fragranceIDs.isEmpty else { return cards }
        let subset = cards.filter { rotation.fragranceIDs.contains($0.fragrance.id) }
        return subset.isEmpty ? cards : subset
    }
    var selectedID: String? {
        switch mode {
        case .demo: return selectedDemoID
        case .mine: return selectedMineID?.uuidString
        case .wishlist: return selectedWishID.map { "wish-\($0.uuidString)" }
        }
    }
    var selected: DisplayCard? {
        let current = displayedCards
        return current.first(where: { $0.id == selectedID }) ?? current.first
    }
    var selectedBottle: BottleRecord? {
        guard let id = selected?.bottleID else { return nil }
        return bottles.first(where: { $0.id == id })
    }
    func choose(_ card: DisplayCard, haptic: Bool = true) {
        guard selectedID != card.id else { return }
        switch mode {
        case .demo: selectedDemoID = card.id
        case .mine: selectedMineID = card.bottleID
        case .wishlist: selectedWishID = card.wishID
        }
        if haptic {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 240_000_000)
                HapticEngine.shared.play(.selection)
            }
        }
    }
    func move(_ offset: Int, haptic: Bool = true) {
        let items = displayedCards
        guard !items.isEmpty, let selected else { return }
        let index = items.firstIndex(of: selected) ?? 0
        let destination = max(0, min(items.count - 1, index + offset))
        choose(items[destination], haptic: haptic)
    }
    func enter(_ newMode: CollectionMode) {
        guard mode != newMode else { return }
        mode = newMode
        if let selected { choose(selected, haptic: false) }
    }
    func add(_ fragrance: Fragrance) {
        if let existing = bottles.first(where: { $0.fragranceID == fragrance.id }) {
            selectedMineID = existing.id
        } else {
            let added = BottleRecord(fragranceID: fragrance.id, shelf: fragrance.shelf)
            bottles.append(added)
            selectedMineID = added.id
        }
        mode = .mine
        HapticEngine.shared.play(.completed)
    }
    func shelfName(_ shelf: FragranceShelf) -> String {
        shelfNames[shelf.rawValue] ?? shelf.rawValue
    }
    func renameShelf(_ shelf: FragranceShelf, to name: String) {
        let normalized = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(28))
        guard !normalized.isEmpty else { return }
        shelfNames[shelf.rawValue] = normalized
        HapticEngine.shared.play(.completed)
    }

    // A wear is one event, whether it contains one bottle or a layered combination.
    // Its per-bottle events use the same session ID for reversible history and estimates.
    func saveLayer(name: String, bottleIDs: [UUID]) {
        let title = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(38))
        var ids: [UUID] = []
        for id in bottleIDs where bottles.contains(where: { $0.id == id }) {
            if !ids.contains(id) { ids.append(id) }
        }
        guard !title.isEmpty && ids.count >= 2 else { return }
        savedLayers.insert(LayerPreset(name: title, bottleIDs: ids), at: 0)
        HapticEngine.shared.play(.completed)
    }

    func deleteLayer(_ id: UUID) {
        savedLayers.removeAll { $0.id == id }
        HapticEngine.shared.play(.completed)
    }

    func recordWear(bottleIDs: [UUID], note: String = "") {
        var unique: [UUID] = []
        for id in bottleIDs where bottles.contains(where: { $0.id == id }) {
            if !unique.contains(id) { unique.append(id) }
        }
        guard !unique.isEmpty else { return }
        let session = WearSession(bottleIDs: unique, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        for id in unique {
            guard let index = bottles.firstIndex(where: { $0.id == id }) else { continue }
            bottles[index].wears.append(WearEvent(sessionID: session.id))
            bottles[index].remaining = max(0, bottles[index].remaining - 0.0075)
        }
        wearSessions.insert(session, at: 0)
        HapticEngine.shared.play(.wear)
    }

    func removeBottle(_ bottleID: UUID, from sessionID: UUID) {
        guard let sessionIndex = wearSessions.firstIndex(where: { $0.id == sessionID }),
              wearSessions[sessionIndex].bottleIDs.contains(bottleID) else { return }
        if let bottleIndex = bottles.firstIndex(where: { $0.id == bottleID }),
           let eventIndex = bottles[bottleIndex].wears.firstIndex(where: { $0.sessionID == sessionID }) {
            bottles[bottleIndex].wears.remove(at: eventIndex)
            bottles[bottleIndex].remaining = min(1, bottles[bottleIndex].remaining + 0.0075)
        }
        wearSessions[sessionIndex].bottleIDs.removeAll { $0 == bottleID }
        if wearSessions[sessionIndex].bottleIDs.isEmpty {
            wearSessions.remove(at: sessionIndex)
        }
        HapticEngine.shared.play(.completed)
    }

    func deleteWearSession(_ sessionID: UUID) {
        guard let session = wearSessions.first(where: { $0.id == sessionID }) else { return }
        for id in session.bottleIDs {
            if let index = bottles.firstIndex(where: { $0.id == id }),
               let eventIndex = bottles[index].wears.firstIndex(where: { $0.sessionID == sessionID }) {
                bottles[index].wears.remove(at: eventIndex)
                bottles[index].remaining = min(1, bottles[index].remaining + 0.0075)
            }
        }
        wearSessions.removeAll { $0.id == sessionID }
        HapticEngine.shared.play(.completed)
    }

    func wearSelected() {
        guard let id = selectedBottle?.id else { return }
        recordWear(bottleIDs: [id])
    }
    func undoWear() {
        guard let id = selectedBottle?.id, let index = bottles.firstIndex(where: { $0.id == id }),
              let eventIndex = bottles[index].wears.lastIndex(where: { Calendar.current.isDateInToday($0.date) }) else { return }
        let event = bottles[index].wears[eventIndex]
        if let sessionID = event.sessionID {
            deleteWearSession(sessionID)
        } else {
            // Preserve reversibility for pre-existing ungrouped events.
            bottles[index].wears.remove(at: eventIndex)
            bottles[index].remaining = min(1, bottles[index].remaining + 0.0075)
        }
    }
    /// Undo today's most recent wear of one specific bottle (the card in front, not the stored
    /// selection). A layered session loses only this bottle; the rest of the session survives.
    func undoTodayWear(bottleID: UUID) {
        guard let index = bottles.firstIndex(where: { $0.id == bottleID }),
              let eventIndex = bottles[index].wears.lastIndex(where: { Calendar.current.isDateInToday($0.date) })
        else { return }
        if let sessionID = bottles[index].wears[eventIndex].sessionID,
           wearSessions.contains(where: { $0.id == sessionID }) {
            removeBottle(bottleID, from: sessionID)
        } else {
            bottles[index].wears.remove(at: eventIndex)
            bottles[index].remaining = min(1, bottles[index].remaining + 0.0075)
            HapticEngine.shared.play(.completed)
        }
    }

    func update(_ bottle: BottleRecord) {
        guard let index = bottles.firstIndex(where: { $0.id == bottle.id }) else { return }
        bottles[index] = bottle
        HapticEngine.shared.play(.completed)
    }
    func delete(_ bottle: BottleRecord) {
        savedLayers = savedLayers.compactMap { original in
            var entry = original
            entry.bottleIDs.removeAll { $0 == bottle.id }
            return entry.bottleIDs.count < 2 ? nil : entry
        }
        wearSessions = wearSessions.compactMap { old in
            var session = old
            session.bottleIDs.removeAll { $0 == bottle.id }
            return session.bottleIDs.isEmpty ? nil : session
        }
        bottles.removeAll { $0.id == bottle.id }
        if selectedMineID == bottle.id { selectedMineID = bottles.first?.id }
        HapticEngine.shared.play(.completed)
    }
    func addRotation(name: String, fragranceIDs: [String]) {
        let ids = Array(Set(fragranceIDs)).sorted()
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty, !ids.isEmpty else { return }
        let rotation = SavedRotation(name: name, fragranceIDs: ids)
        rotations.append(rotation)
        rotationID = rotation.id
        HapticEngine.shared.play(.completed)
    }
    func removeRotation(_ rotation: SavedRotation) {
        rotations.removeAll { $0.id == rotation.id }
        if rotationID == rotation.id { rotationID = nil }
    }
    var dailyPick: DisplayCard? {
        let candidates = cards.filter { card in
            guard let record = bottles.first(where: { $0.id == card.bottleID }) else { return mode == .demo }
            return !record.lowStock && !record.wornToday
        }
        if mode == .demo { return candidates.first }
        return candidates.min { a, b in
            let x = bottles.first { $0.id == a.bottleID }?.lastWorn ?? .distantPast
            let y = bottles.first { $0.id == b.bottleID }?.lastWorn ?? .distantPast
            return x < y
        }
    }
    var lowStock: [BottleRecord] { bottles.filter(\.lowStock) }
    // MARK: Capture and Wishlist

    /// Saves a captured photo (JPEG) under Documents and returns its file name.
    func storeCapturePhoto(_ data: Data) -> String? {
        let filename = "capture-\(UUID().uuidString).jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        return (try? data.write(to: url, options: .atomic)) != nil ? filename : nil
    }

    /// Creates a personal fragrance identity from a capture (name and/or photo file) without
    /// choosing a destination. Returns nil when there is nothing to save.
    func makePersonalFragrance(name: String, house: String = "", photoFileName: String?) -> Fragrance? {
        let clean = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(90))
        guard !clean.isEmpty || photoFileName != nil else { return nil }
        let houseClean = house.trimmingCharacters(in: .whitespacesAndNewlines)
        let fragrance = Fragrance(id: "personal-\(UUID().uuidString)",
                                  house: houseClean.isEmpty ? "My Collection" : String(houseClean.prefix(80)),
                                  name: clean.isEmpty ? "New fragrance" : clean,
                                  concentration: "Personal discovery", year: "",
                                  top: [], heart: [], base: [], shelf: .autumn, archival: false,
                                  photoFileName: photoFileName)
        customFragrances.append(fragrance)
        return fragrance
    }

    /// Adds to the Wishlist (no duplicate for the same fragrance identity). Returns the entry.
    @discardableResult
    func addToWishlist(_ fragrance: Fragrance, source: String = "", notes: String = "",
                       photoFileName: String? = nil) -> WishlistEntry {
        if let index = wishlist.firstIndex(where: { $0.fragranceID == fragrance.id }) {
            if !source.isEmpty && wishlist[index].source.isEmpty { wishlist[index].source = source }
            if !notes.isEmpty && wishlist[index].notes.isEmpty { wishlist[index].notes = notes }
            if wishlist[index].photoFileName == nil { wishlist[index].photoFileName = photoFileName }
            selectedWishID = wishlist[index].id
            HapticEngine.shared.play(.completed)
            return wishlist[index]
        }
        let entry = WishlistEntry(fragranceID: fragrance.id, source: source, notes: notes, photoFileName: photoFileName)
        wishlist.insert(entry, at: 0)
        selectedWishID = entry.id
        HapticEngine.shared.play(.completed)
        return entry
    }

    func isWishlisted(_ fragranceID: String) -> Bool { wishlist.contains { $0.fragranceID == fragranceID } }
    func isOwned(_ fragranceID: String) -> Bool { bottles.contains { $0.fragranceID == fragranceID } }

    /// Moves a Wishlist fragrance into the Collection, keeping notes, source and photo. If the
    /// fragrance is already owned, nothing is duplicated: the entry is simply resolved.
    @discardableResult
    func moveToCollection(wishID: UUID) -> UUID? {
        guard let index = wishlist.firstIndex(where: { $0.id == wishID }) else { return nil }
        let entry = wishlist[index]
        let bottleID: UUID
        if let existing = bottles.first(where: { $0.fragranceID == entry.fragranceID }) {
            bottleID = existing.id
        } else {
            var record = BottleRecord(fragranceID: entry.fragranceID,
                                      shelf: fragrance(id: entry.fragranceID)?.shelf ?? .autumn)
            record.personalNotes = entry.notes
            record.capturePhotoFileName = entry.photoFileName
            record.source = entry.source.isEmpty ? nil : entry.source
            bottles.append(record)
            bottleID = record.id
        }
        wishlist.remove(at: index)
        if selectedWishID == wishID { selectedWishID = wishlist.first?.id }
        selectedMineID = bottleID
        HapticEngine.shared.play(.completed)
        return bottleID
    }

    func removeFromWishlist(_ wishID: UUID) {
        wishlist.removeAll { $0.id == wishID }
        if selectedWishID == wishID { selectedWishID = wishlist.first?.id }
    }

    /// Undo support for capture commits: removes a just-created bottle (no wears yet) and, if it
    /// was a personal capture nobody else references, its fragrance identity too.
    func undoCapture(bottleID: UUID?, wishID: UUID?, createdFragranceID: String?) {
        if let bottleID, let b = bottles.first(where: { $0.id == bottleID }), b.wears.isEmpty {
            bottles.removeAll { $0.id == bottleID }
            if selectedMineID == bottleID { selectedMineID = bottles.last?.id }
        }
        if let wishID { removeFromWishlist(wishID) }
        if let createdFragranceID, !isOwned(createdFragranceID), !isWishlisted(createdFragranceID) {
            customFragrances.removeAll { $0.id == createdFragranceID }
        }
    }

    /// Adds an owned bottle and returns its id (no mode switch side effects beyond `add`).
    @discardableResult
    func addOwned(_ fragrance: Fragrance, notes: String = "", source: String = "", photoFileName: String? = nil) -> UUID? {
        let existed = bottles.first(where: { $0.fragranceID == fragrance.id })?.id
        add(fragrance)
        guard existed == nil, let index = bottles.firstIndex(where: { $0.fragranceID == fragrance.id }) else { return existed }
        if !notes.isEmpty { bottles[index].personalNotes = notes }
        if !source.isEmpty { bottles[index].source = source }
        if photoFileName != nil && fragrance.photoFileName == nil { bottles[index].capturePhotoFileName = photoFileName }
        return bottles[index].id
    }

    func matches(_ query: String, scope: CollectionMode? = nil) -> [Fragrance] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let pool: [Fragrance]
        switch scope ?? mode {
        case .demo: pool = catalog
        case .mine: pool = bottles.compactMap { fragrance(id: $0.fragranceID) }
        case .wishlist: pool = wishlist.compactMap { fragrance(id: $0.fragranceID) }
        }
        guard !q.isEmpty else { return pool }
        let tokens = q.split(whereSeparator: \.isWhitespace).map(String.init)
        return pool.filter { f in
            let haystack = ([f.house,f.name,f.concentration,f.year] + f.notes).joined(separator: " ")
            return tokens.allSatisfy { haystack.localizedStandardContains($0) }
        }
    }
}
