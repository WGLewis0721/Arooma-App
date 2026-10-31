import SwiftUI

struct AtelierWelcome: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    let openDemo: () -> Void
    let openMine: () -> Void

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                HStack {
                    AtelierEyebrow(text: "The private fragrance archive", accent: archive.theme.palette.accent)
                    Spacer()
                    Text("01 / 01")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 26)
                .padding(.top, 19)
                Spacer(minLength: 12)
                VStack(spacing: 13) {
                    Text("Arooma")
                        .font(.custom("Snell Roundhand", size: min(82, geo.size.width * 0.22)))
                        .foregroundStyle(archive.theme.palette.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .opacity(revealed ? 1 : 0.01)
                        .offset(x: revealed ? 0 : -16)
                    AtelierDisplay(title: "A collection worth keeping.", size: 30)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 23)
                Spacer(minLength: 17)
                HStack(alignment: .center, spacing: -38) {
                    AtelierCardSurface(fragranceID: "hawas")
                        .frame(width: min(geo.size.width * 0.37, 158))
                        .rotationEffect(.degrees(-10))
                        .offset(y: 16)
                    AtelierCardSurface(fragranceID: "dior", selected: true)
                        .frame(width: min(geo.size.width * 0.47, 197))
                        .rotationEffect(.degrees(5))
                }
                .padding(.horizontal, 30)
                .accessibilityHidden(true)
                Spacer(minLength: 20)
                VStack(spacing: 14) {
                    Text("CHOOSE YOUR FINISH")
                        .font(.caption2.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 17) {
                        ForEach(FragranceTheme.allCases) { theme in
                            Button {
                                archive.theme = theme
                            } label: {
                                Circle()
                                    .fill(LinearGradient(colors: [
                                        theme.palette.field, theme.palette.secondary, theme.palette.accent
                                    ], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Circle()
                                            .strokeBorder(archive.theme == theme ? Color.primary : Color.clear, lineWidth: 2)
                                            .padding(-5)
                                    }
                                    .frame(minWidth: 53, minHeight: 53)
                            }
                            .accessibilityLabel(theme.rawValue)
                            .accessibilityAddTraits(archive.theme == theme ? .isSelected : [])
                        }
                    }
                    Text(archive.theme.rawValue)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.bottom, 17)

                VStack(spacing: 9) {
                    Button("Explore the Archive", action: openDemo)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .buttonStyle(.borderedProminent)
                        .tint(archive.theme.palette.accent)
                    Button("Open My Collection", action: openMine)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .atelierGlass()
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                if reduceMotion { revealed = true }
                else { withAnimation(.easeOut(duration: 0.8)) { revealed = true } }
            }
        }
        .background(AtelierAtmosphere(theme: archive.theme))
    }
}

struct AtelierShelves: View {
    @EnvironmentObject private var archive: CollectionStore
    let focus: (DisplayCard) -> Void
    let add: () -> Void

    private func shelf(for card: DisplayCard) -> FragranceShelf {
        guard let id = card.bottleID,
              let owned = archive.bottles.first(where: { $0.id == id }) else {
            return card.fragrance.shelf
        }
        return owned.shelf
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 27) {
                VStack(alignment: .leading, spacing: 7) {
                    AtelierEyebrow(text: "Organized by season", accent: archive.theme.palette.accent)
                    HStack(alignment: .firstTextBaseline) {
                        AtelierDisplay(title: "The shelves", size: 37)
                        Spacer()
                        Text("\(archive.cards.count) pieces")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text("A private arrangement, composed one bottle at a time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 23)
                .padding(.top, 16)

                ForEach(FragranceShelf.allCases) { shelf in
                    let cards = archive.cards.filter { self.shelf(for: $0) == shelf }
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: shelf.icon)
                                .font(.system(.subheadline, weight: .light))
                                .foregroundStyle(archive.theme.palette.accent)
                            AtelierDisplay(title: shelf.rawValue, size: 28)
                            Spacer()
                            Text("\(cards.count, format: .number.precision(.integerLength(2)))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 23)

                        if cards.isEmpty {
                            Button {
                                add()
                            } label: {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("An empty shelf. Place something here.")
                                    Spacer()
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(minHeight: 100)
                                .padding(.horizontal, 22)
                                .atelierPlate()
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 22)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(alignment: .top, spacing: 17) {
                                    ForEach(cards) { card in
                                        Button { focus(card) } label: {
                                            VStack(alignment: .leading, spacing: 8) {
                                                AtelierCardSurface(fragranceID: card.fragrance.id)
                                                    .frame(width: 150, height: 218)
                                                Text(card.fragrance.name)
                                                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                                                    .lineLimit(1)
                                                Text(card.fragrance.house)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 150, alignment: .leading)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Open \(card.fragrance.name)")
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 36)
        }
        .background(AtelierAtmosphere(theme: archive.theme))
    }
}

struct AtelierSearch: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    let focus: (DisplayCard) -> Void
    var adding = false

    private var results: [Fragrance] {
        let tokens = query.split(whereSeparator: \.isWhitespace).map(String.init)
        return Fragrance.catalog.filter { fragrance in
            guard !tokens.isEmpty else { return true }
            let all = ([fragrance.name, fragrance.house, fragrance.concentration, fragrance.year] +
                       fragrance.notes).joined(separator: " ")
            return tokens.allSatisfy { all.localizedStandardContains($0) }
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        AtelierEyebrow(text: "The fragrance index", accent: archive.theme.palette.accent)
                        AtelierDisplay(title: adding ? "Add a fragrance" : "Discover", size: 38)
                        Text("Find a house, an accord or a familiar name.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 12)
                    if results.isEmpty {
                        ContentUnavailableView.search(text: query)
                    } else {
                        ForEach(results) { fragrance in
                            Button { select(fragrance) } label: {
                                HStack(spacing: 16) {
                                    AtelierCardSurface(fragranceID: fragrance.id, radius: 9)
                                        .frame(width: 79, height: 115)
                                    VStack(alignment: .leading, spacing: 7) {
                                        AtelierEyebrow(text: fragrance.house, accent: archive.theme.palette.accent)
                                        Text(fragrance.name)
                                            .font(.system(.title3, design: .serif))
                                            .foregroundStyle(.primary)
                                        Text(fragrance.concentration)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        if fragrance.archival {
                                            Text("HISTORICAL ARTWORK")
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer(minLength: 2)
                                    Image(systemName: adding ? "plus.circle" : "chevron.right")
                                        .font(.system(size: 17, weight: .light))
                                        .foregroundStyle(archive.theme.palette.accent)
                                        .frame(width: 44, height: 44)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .atelierPlate(18)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(adding ? "Add" : "Open") \(fragrance.house) \(fragrance.name)")
                        }
                    }
                    Text("Independent fragrance archive. The original photographs and collectible compositions are not brand endorsements.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 35)
            }
            .background(AtelierAtmosphere(theme: archive.theme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if adding {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .searchable(text: $query, prompt: "House, notes, concentration")
        }
    }

    private func select(_ fragrance: Fragrance) {
        if adding {
            archive.add(fragrance)
            dismiss()
            return
        }
        let record = archive.bottles.first(where: { $0.fragranceID == fragrance.id })
        focus(DisplayCard(id: record?.id.uuidString ?? fragrance.id,
                          fragrance: fragrance, bottleID: record?.id))
    }
}

struct AtelierOwnership: View {
    @EnvironmentObject private var archive: CollectionStore
    @State private var editing: BottleRecord?
    @State private var history: BottleRecord?
    @State private var rotations = false
    let add: () -> Void
    let focus: (DisplayCard) -> Void

    private var current: BottleRecord? { archive.selectedBottle }
    private var perfume: Fragrance? {
        guard let record = current else { return nil }
        return Fragrance.find(record.fragranceID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    AtelierEyebrow(text: "Your private record", accent: archive.theme.palette.accent)
                    AtelierDisplay(title: "The journal", size: 37)
                }
                .padding(.top, 16)

                if archive.mode == .demo {
                    AtelierEmptyState(title: "Your collection is waiting.",
                                      detail: "Switch to Mine to keep personal wear logs and ownership notes.",
                                      action: "Open Mine", callback: { archive.enter(.mine) },
                                      accent: archive.theme.palette.accent)
                    .frame(maxWidth: .infinity)
                } else if let current, let perfume {
                    featured(record: current, perfume: perfume)
                    metrics(record: current)
                    primary(record: current)
                    secondary(record: current)
                    collectionList
                } else {
                    AtelierEmptyState(title: "Nothing collected. Yet.",
                                      detail: "Choose your first fragrance from the collectible archive.",
                                      action: "Browse the collection", callback: add,
                                      accent: archive.theme.palette.accent)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 23)
            .padding(.bottom, 36)
        }
        .background(AtelierAtmosphere(theme: archive.theme))
        .sheet(item: $editing) { bottle in
            NavigationStack { BottleEditor(bottle: bottle) }
        }
        .sheet(item: $history) { bottle in
            NavigationStack { WearHistoryScreen(bottleID: bottle.id) }
        }
        .sheet(isPresented: $rotations) {
            NavigationStack { RotationManager() }
        }
    }

    private func featured(record: BottleRecord, perfume: Fragrance) -> some View {
        HStack(alignment: .top, spacing: 19) {
            AtelierCardSurface(fragranceID: perfume.id, radius: 11)
                .frame(width: 130, height: 189)
            VStack(alignment: .leading, spacing: 9) {
                AtelierEyebrow(text: perfume.house, accent: archive.theme.palette.accent)
                AtelierDisplay(title: perfume.name, size: 27)
                Text(perfume.concentration)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 5)
                Text("\(Int(record.remaining * 100))%")
                    .font(.system(size: 26, design: .rounded).monospacedDigit())
                Text("Estimated remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                GeometryReader { g in
                    Capsule()
                        .fill(.primary.opacity(0.12))
                        .overlay(alignment: .leading) {
                            Capsule().fill(archive.theme.palette.accent)
                                .frame(width: max(0, g.size.width * record.remaining))
                        }
                }
                .frame(height: 4)
            }
            .frame(height: 189, alignment: .top)
        }
        .padding(16)
        .atelierPlate(22)
    }

    private func metrics(record: BottleRecord) -> some View {
        HStack(spacing: 10) {
            metric("\(record.wears.count)", caption: "WEARS")
            metric("\(record.volumeML) ml", caption: "BOTTLE")
            metric(record.lowStock ? "LOW" : "READY", caption: "STOCK")
        }
    }

    private func metric(_ value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(.title3, design: .serif))
            Text(caption)
                .font(.caption2.weight(.medium))
                .tracking(1.2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 75, alignment: .leading)
        .padding(.leading, 14)
        .atelierPlate(14)
    }

    private func primary(record: BottleRecord) -> some View {
        Button {
            if record.wornToday { archive.undoWear() }
            else { archive.wearSelected() }
        } label: {
            Label(record.wornToday ? "Undo Today's Wear" : "Wear Today",
                  systemImage: record.wornToday ? "arrow.uturn.backward" : "checkmark")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(archive.theme.palette.accent)
    }

    private func secondary(record: BottleRecord) -> some View {
        VStack(spacing: 0) {
            navigation("Wear history", systemImage: "clock") { history = record }
            Divider().opacity(0.5)
            navigation("Edit ownership and notes", systemImage: "square.and.pencil") { editing = record }
            Divider().opacity(0.5)
            navigation("Wear rotations", systemImage: "square.stack.3d.up") { rotations = true }
            if !record.personalNotes.isEmpty {
                Divider().opacity(0.5)
                Text("“\(record.personalNotes)”")
                    .font(.system(.body, design: .serif))
                    .italic()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
            }
        }
        .padding(.horizontal, 16)
        .atelierPlate(18)
    }

    private func navigation(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .frame(width: 24)
                    .foregroundStyle(archive.theme.palette.accent)
                Text(title)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var collectionList: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                AtelierEyebrow(text: "The collection", accent: archive.theme.palette.accent)
                Spacer()
                Button("Add") { add() }
                    .font(.subheadline.weight(.medium))
                    .frame(minWidth: 44, minHeight: 44)
            }
            ForEach(archive.bottles) { record in
                if let fragrance = Fragrance.find(record.fragranceID) {
                    Button {
                        archive.selectedMineID = record.id
                        focus(DisplayCard(id: record.id.uuidString, fragrance: fragrance, bottleID: record.id))
                    } label: {
                        HStack(spacing: 13) {
                            AtelierCardSurface(fragranceID: fragrance.id, radius: 6)
                                .frame(width: 45, height: 65)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fragrance.name)
                                    .font(.system(.subheadline, design: .serif))
                                Text(fragrance.house).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if record.id == current?.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(archive.theme.palette.accent)
                            }
                        }
                        .frame(minHeight: 70)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().opacity(0.4)
                }
            }
        }
    }
}

struct AtelierStyle: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                AtelierEyebrow(text: "Four signature finishes", accent: archive.theme.palette.accent)
                AtelierDisplay(title: "The atmosphere", size: 37)
                Text("Your cards never change. The environment around them does.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 13), GridItem(.flexible(), spacing: 13)], spacing: 16) {
                    ForEach(FragranceTheme.allCases) { theme in
                        Button {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
                                archive.theme = theme
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 11) {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(LinearGradient(
                                        colors: [theme.palette.field, theme.palette.secondary, theme.palette.accent.opacity(0.64)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(height: 120)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(theme.palette.accent.opacity(0.6), lineWidth: 0.8)
                                            .padding(23)
                                    }
                                    .overlay(alignment: .bottomTrailing) {
                                        Circle().fill(theme.palette.accent)
                                            .frame(width: 22, height: 22)
                                            .padding(12)
                                    }
                                Text(theme.rawValue)
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundStyle(.primary)
                                HStack(spacing: 4) {
                                    if archive.theme == theme { Image(systemName: "checkmark.circle.fill") }
                                    Text(archive.theme == theme ? "Selected" : "Preview")
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(archive.theme == theme ? .isSelected : [])
                    }
                }
                AtelierEyebrow(text: "Appearance", accent: archive.theme.palette.accent)
                Picker("Appearance", selection: $archive.appearance) {
                    ForEach(Appearance.allCases) { a in Text(a.rawValue).tag(a) }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: 48)
                VStack(alignment: .leading, spacing: 12) {
                    AtelierDisplay(title: "An independent archive", size: 24)
                    Text("Arooma is a private fragrance companion, not endorsed by the featured houses. The collectible compositions remain the original approved artwork.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Local-first · iOS 26 · No account required")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .atelierPlate(19)
            }
            .padding(.horizontal, 22)
            .padding(.top, 17)
            .padding(.bottom, 35)
        }
        .background(AtelierAtmosphere(theme: archive.theme))
    }
}
