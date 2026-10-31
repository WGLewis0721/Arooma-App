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
        }
        hydrating = false
    }
    private func persist() {
        guard !hydrating else { return }
        let snapshot = SavedArchive(mode: mode, theme: theme, appearance: appearance,
            layout: layout, selectedDemoID: selectedDemoID, selectedMineID: selectedMineID,
            selectedShelf: selectedShelf, rotationID: rotationID, bottles: bottles,
            rotations: rotations, onboarded: onboarded,
            shelfNames: shelfNames, wearSessions: wearSessions, customFragrances: customFragrances, savedLayers: savedLayers)
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
        if mode == .demo { return selectedDemoID }
        return selectedMineID?.uuidString
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
        if mode == .demo { selectedDemoID = card.id }
        else { selectedMineID = card.bottleID }
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
    func matches(_ query: String, scope: CollectionMode? = nil) -> [Fragrance] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let pool: [Fragrance] = (scope ?? mode) == .demo ? catalog :
            bottles.compactMap { fragrance(id: $0.fragranceID) }
        guard !q.isEmpty else { return pool }
        let tokens = q.split(whereSeparator: \.isWhitespace).map(String.init)
        return pool.filter { f in
            let haystack = ([f.house,f.name,f.concentration,f.year] + f.notes).joined(separator: " ")
            return tokens.allSatisfy { haystack.localizedStandardContains($0) }
        }
    }
}
