import SwiftUI
import Foundation

enum CollectionMode: String, Codable, CaseIterable { case demo = "Demo", mine = "Mine" }
enum CardLayout: String, Codable, CaseIterable, Identifiable {
    case coverFlow = "Cover Flow", stack = "Stack", fan = "Fan"
    var id: Self { self }
    var symbol: String {
        switch self { case .coverFlow: "rectangle.on.rectangle.angled"; case .stack: "square.stack.3d.up"; case .fan: "square.on.square" }
    }
}
enum Appearance: String, Codable, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: Self { self }
    var colorScheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}
enum FragranceTheme: String, Codable, CaseIterable, Identifiable {
    case obsidian = "Obsidian Gold", ivory = "Ivory Oud", violet = "Violet Ink", emerald = "Emerald Resin"
    var id: Self { self }
    var palette: ArchivePalette {
        switch self {
        case .obsidian: ArchivePalette(field: Color(hex: 0x161B24), secondary: Color(hex: 0x312B33), accent: Color(hex: 0xB88B47))
        case .ivory: ArchivePalette(field: Color(hex: 0xF3EBDD), secondary: Color(hex: 0xD8C4AA), accent: Color(hex: 0x9F6A36))
        case .violet: ArchivePalette(field: Color(hex: 0x1B1A28), secondary: Color(hex: 0x5D5266), accent: Color(hex: 0xC9B6D9))
        case .emerald: ArchivePalette(field: Color(hex: 0x18211F), secondary: Color(hex: 0x4B5A55), accent: Color(hex: 0xD1B68B))
        }
    }
}
struct ArchivePalette {
    let field: Color
    let secondary: Color
    let accent: Color
}
extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255)/255, green: Double((hex >> 8) & 255)/255,
                  blue: Double(hex & 255)/255, opacity: 1)
    }
}

enum FragranceShelf: String, Codable, CaseIterable, Identifiable {
    case spring = "Spring", summer = "Summer", autumn = "Autumn", winter = "Winter"
    var id: Self { self }
    var icon: String {
        switch self { case .spring: "leaf"; case .summer: "sun.max"; case .autumn: "wind"; case .winter: "snowflake" }
    }
}

struct Fragrance: Identifiable, Hashable, Codable {
    let id: String
    var house: String
    var name: String
    let concentration: String
    let year: String
    let top: [String]
    let heart: [String]
    let base: [String]
    let shelf: FragranceShelf
    let archival: Bool
    // Quick captures can have an original owner's bottle photo, not a generated card.
    var photoFileName: String? = nil
    var notes: [String] { top + heart + base }
    var description: String { [house, name, concentration].joined(separator: " · ") }

    // Source identity is tied to assets/collectibles/production/manifest.json.
    // Original artwork is bundled byte-for-byte from masters/approved (and archival).
    static let catalog: [Fragrance] = [
        Fragrance(id: "dior", house: "Dior", name: "Sauvage Elixir", concentration: "Elixir",
                  year: "2021", top: ["Grapefruit", "Cinnamon", "Nutmeg", "Cardamom"],
                  heart: ["Lavender"], base: ["Licorice", "Sandalwood", "Amber", "Vetiver"],
                  shelf: .autumn, archival: false),
        Fragrance(id: "hawas", house: "Rasasi", name: "Hawas For Him", concentration: "Eau de Parfum",
                  year: "2015", top: ["Apple", "Bergamot", "Lemon", "Cinnamon"],
                  heart: ["Orange Blossom", "Cardamom", "Plum"],
                  base: ["Patchouli", "Grey Amber", "Driftwood", "Musk"],
                  shelf: .summer, archival: false),
        Fragrance(id: "myslf", house: "Yves Saint Laurent", name: "MYSLF", concentration: "Eau de Parfum",
                  year: "2023", top: ["Bergamot"], heart: ["Orange Blossom"],
                  base: ["Ambrofix", "Patchouli"], shelf: .spring, archival: false),
        Fragrance(id: "prodigy", house: "MIND GAMES", name: "Prodigy", concentration: "Extrait de Parfum",
                  year: "", top: [], heart: [], base: [],
                  shelf: .winter, archival: true)
    ]
    static func find(_ id: String) -> Fragrance? { catalog.first { $0.id == id } }
}
struct WearEvent: Codable, Identifiable, Hashable {
    var id = UUID()
    var date = Date()
    var impression = ""
    var sessionID: UUID? = nil // Optional for existing single-bottle history.
}
struct BottleRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    var fragranceID: String
    var shelf: FragranceShelf
    var purchased: Date = Date()
    var volumeML: Int = 100
    var remaining: Double = 1
    var personalNotes = ""
    var authenticityNotes = ""
    var favorite = false
    var wears: [WearEvent] = []
    var lastWorn: Date? { wears.max(by: { $0.date < $1.date })?.date }
    var lowStock: Bool { remaining <= 0.2 }
    var wornToday: Bool { wears.contains { Calendar.current.isDateInToday($0.date) } }
}
struct LayerPreset: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var bottleIDs: [UUID]
    var created = Date()
}
struct WearSession: Codable, Identifiable, Hashable {
    var id = UUID()
    var date = Date()
    var bottleIDs: [UUID]
    var note = ""
}

struct SavedRotation: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var fragranceIDs: [String]
}
struct DisplayCard: Identifiable, Hashable {
    var id: String // Stable across all layouts; owner copies have their own identity.
    var fragrance: Fragrance
    var bottleID: UUID?
}
struct SavedArchive: Codable {
    var mode: CollectionMode = .demo
    var theme: FragranceTheme = .obsidian
    var appearance: Appearance = .system
    var layout: CardLayout = .coverFlow
    var selectedDemoID: String = "dior"
    var selectedMineID: UUID?
    var selectedShelf: FragranceShelf = .autumn
    var rotationID: UUID?
    var bottles: [BottleRecord] = []
    var rotations: [SavedRotation] = []
    var onboarded: Bool = false
    // Optional fields keep already-installed native JSON decodable without a reset.
    var shelfNames: [String: String]? = nil
    var wearSessions: [WearSession]? = nil
    var customFragrances: [Fragrance]? = nil
    var savedLayers: [LayerPreset]? = nil
}
