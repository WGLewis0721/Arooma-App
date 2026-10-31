import SwiftUI

// MARK: - Collector-grade search
//
// Basic search is immediate (type and see results). Depth is progressively disclosed: scopes for
// relationship (All / Collection / Wishlist / Catalog), a Filters sheet with AND-combined facets,
// and a stable sort. Facet values come only from real records; missing data is Unknown and is
// never matched by a facet. Everything is local.

enum SearchScope: String, CaseIterable, Identifiable {
    case all = "All", collection = "Collection", wishlist = "Wishlist", catalog = "Catalog"
    var id: Self { self }
}

enum SearchSort: String, CaseIterable, Identifiable {
    case name = "Name", house = "House", lastWorn = "Last worn", mostWorn = "Most worn", remaining = "Remaining", added = "Recently added"
    var id: Self { self }
}

enum WornWithin: String, CaseIterable, Identifiable {
    case any = "Any time", week = "This week", month = "This month", never = "Never worn"
    var id: Self { self }
}

enum RemainingFilter: String, CaseIterable, Identifiable {
    case any = "Any", low = "Low (≤ 20%)", half = "Half or more"
    var id: Self { self }
}

struct SearchFilters: Equatable {
    var houses: Set<String> = []
    var notes: Set<String> = []
    var accords: Set<String> = []
    var concentrations: Set<String> = []
    var seasons: Set<String> = []
    var occasions: Set<String> = []
    var favoritesOnly = false
    var worn: WornWithin = .any
    var remaining: RemainingFilter = .any
    var usedInLayers = false

    var activeCount: Int {
        [!houses.isEmpty, !notes.isEmpty, !accords.isEmpty, !concentrations.isEmpty, !seasons.isEmpty,
         !occasions.isEmpty, favoritesOnly, worn != .any, remaining != .any, usedInLayers].filter { $0 }.count
    }
}

/// One searchable record: a fragrance plus the owner's relationship to it.
struct SearchItem: Identifiable {
    enum Relationship { case owned, wishlist, catalog }
    let id: String
    let fragrance: Fragrance
    let relationship: Relationship
    let bottle: BottleRecord?
    let wish: WishlistEntry?
    let accords: [String]
    let season: String
    let occasion: String?
    let layered: Bool
    let haystack: String

    var card: DisplayCard {
        DisplayCard(id: id, fragrance: fragrance, bottleID: bottle?.id, wishID: wish?.id)
    }
}

@MainActor
enum SearchIndex {
    static func build(_ store: CollectionStore) -> [SearchItem] {
        let layeredIDs = Set(store.wearSessions.filter { $0.bottleIDs.count > 1 }.flatMap(\.bottleIDs))
        func item(_ f: Fragrance, _ rel: SearchItem.Relationship, bottle: BottleRecord?, wish: WishlistEntry?, id: String) -> SearchItem {
            let accords = Accord.accords(for: f.notes).map(\.rawValue)
            let season = bottle.map { store.shelfName($0.shelf) } ?? store.shelfName(f.shelf)
            let occasion = InsightEngine.occasion(for: f)?.0
            let text = ([f.house, f.name, f.concentration, f.year, season] + f.notes + accords +
                        [wish?.source ?? "", wish?.notes ?? "", bottle?.personalNotes ?? ""]).joined(separator: " ")
            return SearchItem(id: id, fragrance: f, relationship: rel, bottle: bottle, wish: wish,
                              accords: accords, season: season, occasion: occasion,
                              layered: bottle.map { layeredIDs.contains($0.id) } ?? false, haystack: text)
        }
        var items: [SearchItem] = []
        var claimed = Set<String>()
        for b in store.bottles {
            guard let f = store.fragrance(id: b.fragranceID) else { continue }
            items.append(item(f, .owned, bottle: b, wish: nil, id: b.id.uuidString))
            claimed.insert(f.id)
        }
        for w in store.wishlist {
            guard let f = store.fragrance(id: w.fragranceID) else { continue }
            items.append(item(f, .wishlist, bottle: nil, wish: w, id: "wish-\(w.id.uuidString)"))
            claimed.insert(f.id)
        }
        for f in store.catalog where !claimed.contains(f.id) {
            items.append(item(f, .catalog, bottle: nil, wish: nil, id: f.id))
        }
        return items
    }

    static func filter(_ items: [SearchItem], query: String, scope: SearchScope, filters: SearchFilters,
                       sort: SearchSort) -> [SearchItem] {
        let tokens = query.split(whereSeparator: \.isWhitespace).map(String.init)
        let now = Date()
        let result = items.filter { item in
            switch scope {
            case .all: break
            case .collection: if item.relationship != .owned { return false }
            case .wishlist: if item.relationship != .wishlist { return false }
            case .catalog: if item.relationship != .catalog { return false }
            }
            if !tokens.allSatisfy({ item.haystack.localizedStandardContains($0) }) { return false }
            let f = item.fragrance
            if !filters.houses.isEmpty && !filters.houses.contains(f.house) { return false }
            if !filters.notes.isEmpty && !filters.notes.isSubset(of: Set(f.notes)) { return false }
            if !filters.accords.isEmpty && !filters.accords.isSubset(of: Set(item.accords)) { return false }
            if !filters.concentrations.isEmpty && !filters.concentrations.contains(f.concentration) { return false }
            if !filters.seasons.isEmpty && !filters.seasons.contains(item.season) { return false }
            if !filters.occasions.isEmpty && !(item.occasion.map { filters.occasions.contains($0) } ?? false) { return false }
            if filters.favoritesOnly && item.bottle?.favorite != true { return false }
            if filters.usedInLayers && !item.layered { return false }
            switch filters.worn {
            case .any: break
            case .week:
                guard let d = item.bottle?.lastWorn, now.timeIntervalSince(d) <= 7 * 86400 else { return false }
            case .month:
                guard let d = item.bottle?.lastWorn, now.timeIntervalSince(d) <= 31 * 86400 else { return false }
            case .never:
                guard let b = item.bottle, b.wears.isEmpty else { return false }
            }
            switch filters.remaining {
            case .any: break
            case .low: guard let b = item.bottle, b.remaining <= 0.2 else { return false }
            case .half: guard let b = item.bottle, b.remaining >= 0.5 else { return false }
            }
            return true
        }
        return result.sorted { a, b in
            func tie() -> Bool {
                let n = a.fragrance.name.localizedStandardCompare(b.fragrance.name)
                return n == .orderedSame ? a.id < b.id : n == .orderedAscending
            }
            switch sort {
            case .name: return tie()
            case .house:
                let h = a.fragrance.house.localizedStandardCompare(b.fragrance.house)
                return h == .orderedSame ? tie() : h == .orderedAscending
            case .lastWorn:
                let x = a.bottle?.lastWorn ?? .distantPast, y = b.bottle?.lastWorn ?? .distantPast
                return x == y ? tie() : x > y
            case .mostWorn:
                let x = a.bottle?.wears.count ?? -1, y = b.bottle?.wears.count ?? -1
                return x == y ? tie() : x > y
            case .remaining:
                let x = a.bottle?.remaining ?? 2, y = b.bottle?.remaining ?? 2
                return x == y ? tie() : x < y
            case .added:
                let x = a.bottle?.purchased ?? a.wish?.added ?? .distantPast
                let y = b.bottle?.purchased ?? b.wish?.added ?? .distantPast
                return x == y ? tie() : x > y
            }
        }
    }
}

struct AtelierSearch: View {
    @EnvironmentObject private var archive: CollectionStore
    @State private var query = ""
    @State private var scope: SearchScope = .all
    @State private var filters = SearchFilters()
    @State private var sort: SearchSort = .name
    @State private var showingFilters = false
    let focus: (DisplayCard) -> Void

    var body: some View {
        let all = SearchIndex.build(archive)
        let results = SearchIndex.filter(all, query: query, scope: scope, filters: filters, sort: sort)
        let accent = archive.theme.palette.accent
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("\(results.count) \(results.count == 1 ? "result" : "results")")
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            .contentTransition(.numericText(value: Double(results.count)))
                        Spacer()
                        if filters.activeCount > 0 {
                            Button("Clear filters") { withAnimation(.snappy) { filters = SearchFilters() } }
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .accessibilityElement(children: .combine)
                    if results.isEmpty {
                        ContentUnavailableView.search(text: query)
                        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Not in Arooma yet? Use Quick Add (+) to capture it for your Collection or Wishlist.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    ForEach(results) { item in
                        Button { focus(item.card) } label: { row(item, accent: accent) }
                            .buttonStyle(PressableCardStyle())
                    }
                    Text("Independent fragrance archive. The original photographs and collectible compositions are not brand endorsements.")
                        .font(.footnote).foregroundStyle(.secondary).padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .animation(.snappy, value: results.map(\.id))
            }
            .background(AtelierAtmosphere(theme: archive.theme))
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Name, house, note, accord…")
            .searchScopes($scope) {
                ForEach(SearchScope.allCases) { Text($0.rawValue).tag($0) }
            }
            .searchSuggestions {
                ForEach(suggestions(all), id: \.self) { suggestion in
                    Text(suggestion).searchCompletion(suggestion)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(SearchSort.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingFilters = true } label: {
                        Label(filters.activeCount > 0 ? "Filters (\(filters.activeCount))" : "Filters",
                              systemImage: filters.activeCount > 0 ? "line.3.horizontal.decrease.circle.fill"
                                                                   : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheet(filters: $filters, items: all)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func suggestions(_ items: [SearchItem]) -> [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { return [] }
        var pool = Set<String>()
        for item in items {
            pool.insert(item.fragrance.house)
            item.fragrance.notes.forEach { pool.insert($0) }
            item.accords.forEach { pool.insert($0) }
        }
        return pool.filter { $0.localizedStandardContains(q) && $0.lowercased() != q.lowercased() }.sorted().prefix(6).map { $0 }
    }

    private func row(_ item: SearchItem, accent: Color) -> some View {
        HStack(spacing: 14) {
            AtelierCardSurface(fragranceID: item.fragrance.id, radius: 8, shadowed: false)
                .frame(width: 58, height: 85)
            VStack(alignment: .leading, spacing: 4) {
                AtelierEyebrow(text: item.fragrance.house, accent: accent)
                Text(item.fragrance.name).font(.system(.headline, design: .serif)).foregroundStyle(.primary)
                Text(detail(item)).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 4)
            Text(badge(item))
                .font(.system(size: 9, weight: .bold)).tracking(0.8)
                .padding(.horizontal, 7).padding(.vertical, 4)
                .background(.primary.opacity(0.07), in: Capsule())
                .foregroundStyle(item.relationship == .catalog ? Color.secondary : accent)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .atelierPlate(16)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens it in its deck")
    }

    private func badge(_ item: SearchItem) -> String {
        switch item.relationship {
        case .owned: return item.bottle?.favorite == true ? "OWNED ♥" : "OWNED"
        case .wishlist: return "WISHLIST"
        case .catalog: return "CATALOG"
        }
    }

    private func detail(_ item: SearchItem) -> String {
        var parts = [item.fragrance.concentration]
        if item.fragrance.notes.isEmpty { parts.append("Notes unknown") }
        else { parts.append(item.fragrance.notes.prefix(3).joined(separator: ", ")) }
        if let b = item.bottle {
            parts.append("\(b.wears.count) wears")
            parts.append("\(Int(b.remaining * 100))% left")
        }
        if let w = item.wish, !w.source.isEmpty { parts.append("from \(w.source)") }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

/// Facet chooser. Every value shown exists in the owner's records or the bundled catalog.
struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: SearchFilters
    let items: [SearchItem]

    var body: some View {
        NavigationStack {
            Form {
                facet("House", values: Set(items.map(\.fragrance.house)), selection: $filters.houses)
                facet("Notes", values: Set(items.flatMap(\.fragrance.notes)), selection: $filters.notes)
                facet("Accords (derived from notes)", values: Set(items.flatMap(\.accords)), selection: $filters.accords)
                facet("Concentration", values: Set(items.map(\.fragrance.concentration)), selection: $filters.concentrations)
                facet("Season (shelf)", values: Set(items.map(\.season)), selection: $filters.seasons)
                facet("Occasion (suggested)", values: Set(items.compactMap(\.occasion)), selection: $filters.occasions)
                Section("Your records") {
                    Toggle("Favorites only", isOn: $filters.favoritesOnly)
                    Toggle("Used in a layer", isOn: $filters.usedInLayers)
                    Picker("Last worn", selection: $filters.worn) {
                        ForEach(WornWithin.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Remaining", selection: $filters.remaining) {
                        ForEach(RemainingFilter.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear all") { filters = SearchFilters() }.disabled(filters.activeCount == 0)
                }
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    @ViewBuilder
    private func facet(_ title: String, values: Set<String>, selection: Binding<Set<String>>) -> some View {
        let sorted = values.filter { !$0.isEmpty }.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        if !sorted.isEmpty {
            Section(title) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sorted, id: \.self) { value in
                            let on = selection.wrappedValue.contains(value)
                            Button {
                                if on { selection.wrappedValue.remove(value) } else { selection.wrappedValue.insert(value) }
                            } label: {
                                Text(value).font(.caption.weight(on ? .semibold : .regular))
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(on ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.06), in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}
