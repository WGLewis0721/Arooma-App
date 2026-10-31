import SwiftUI
import PhotosUI
import UIKit

struct AtelierWelcome: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    @State private var ink: CGFloat = 0
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
                        .font(.custom("Snell Roundhand", size: min(88, geo.size.width * 0.235)))
                        .italic()
                        .foregroundStyle(archive.theme.palette.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .mask(alignment: .leading) {
                            GeometryReader { letters in
                                Rectangle().frame(width: letters.size.width * ink)
                            }
                        }
                        .accessibilityLabel("Arooma")
                    Path { path in
                        path.move(to: CGPoint(x: 22, y: 15))
                        path.addCurve(to: CGPoint(x: 278, y: 13),
                                      control1: CGPoint(x: 98, y: 34),
                                      control2: CGPoint(x: 195, y: -6))
                    }
                    .trim(from: 0, to: ink)
                    .stroke(archive.theme.palette.accent.opacity(0.65),
                            style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                    .frame(width: min(290, geo.size.width * 0.76), height: 30)
                    .accessibilityHidden(true)
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
                if reduceMotion { revealed = true; ink = 1 }
                else {
                    withAnimation(.easeOut(duration: 0.35)) { revealed = true }
                    withAnimation(.easeInOut(duration: 1.55)) { ink = 1 }
                }
            }
        }
        .background(AtelierAtmosphere(theme: archive.theme))
    }
}

struct AtelierShelves: View {
    @EnvironmentObject private var archive: CollectionStore
    @State private var renaming: FragranceShelf?
    @State private var newName = ""
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
                    AtelierEyebrow(text: "Your personalized collection", accent: archive.theme.palette.accent)
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
                            AtelierDisplay(title: archive.shelfName(shelf), size: 28)
                            Spacer()
                            Button {
                                newName = archive.shelfName(shelf)
                                renaming = shelf
                            } label: {
                                Image(systemName: "pencil").frame(width: 44, height: 44)
                            }
                            .accessibilityLabel("Rename \(archive.shelfName(shelf))")
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
        .alert("Rename shelf", isPresented: Binding(
            get: { renaming != nil },
            set: { if !$0 { renaming = nil } }
        )) {
            TextField("Shelf name", text: $newName)
            Button("Cancel", role: .cancel) { renaming = nil }
            Button("Save") {
                if let shelf = renaming { archive.renameShelf(shelf, to: newName) }
                renaming = nil
            }
        } message: {
            Text("Choose a name for this shelf. Your bottles stay where they are.")
        }
    }
}


struct AtelierCompactShelves: View {
    @EnvironmentObject private var archive: CollectionStore
    @State private var renaming: FragranceShelf?
    @State private var newName = ""
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
            VStack(spacing: 13) {
                Text("Pinch open a shelf, or tap a collectible.")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(FragranceShelf.allCases) { shelf in
                    let cards = archive.cards.filter { self.shelf(for: $0) == shelf }
                    VStack(alignment: .leading, spacing: 9) {
                        HStack(spacing: 8) {
                            AtelierDisplay(title: archive.shelfName(shelf), size: 22)
                            Spacer()
                            Text("\(cards.count)").font(.caption.monospacedDigit())
                            Button {
                                newName = archive.shelfName(shelf)
                                renaming = shelf
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption).frame(width: 42, height: 42)
                            }
                            .accessibilityLabel("Rename \(archive.shelfName(shelf))")
                        }
                        if cards.isEmpty {
                            Button(action: add) {
                                Label("Add first fragrance", systemImage: "plus")
                                    .frame(maxWidth: .infinity, minHeight: 72)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 11) {
                                    ForEach(cards) { card in
                                        Button { focus(card) } label: {
                                            VStack(spacing: 3) {
                                                AtelierCardSurface(fragranceID: card.fragrance.id)
                                                    .frame(width: 65, height: 96)
                                                Text(card.fragrance.name)
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(1)
                                                    .frame(width: 67)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Open \(card.fragrance.name)")
                                    }
                                }
                            }
                        }
                    }
                    .padding(11).atelierPlate(15)
                }
            }
            .padding(.horizontal, 17).padding(.vertical, 12)
        }
        .alert("Rename shelf", isPresented: Binding(
            get: { renaming != nil },
            set: { if !$0 { renaming = nil } }
        )) {
            TextField("Shelf name", text: $newName)
            Button("Cancel", role: .cancel) { renaming = nil }
            Button("Save") {
                if let shelf = renaming { archive.renameShelf(shelf, to: newName) }
                renaming = nil
            }
        } message: {
            Text("The bottles on this shelf stay put.")
        }
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
        return archive.catalog.filter { fragrance in
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
        return archive.fragrance(id: record.fragranceID)
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
                    if let pick = archive.dailyPick {
                        Button {
                            archive.choose(pick)
                            focus(pick)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkle")
                                    .foregroundStyle(archive.theme.palette.accent)
                                VStack(alignment: .leading, spacing: 3) {
                                    AtelierEyebrow(text: "Today's pick", accent: archive.theme.palette.accent)
                                    Text(pick.fragrance.name)
                                        .font(.system(.subheadline, design: .serif))
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(15)
                            .atelierPlate(16)
                        }
                        .buttonStyle(.plain)
                    }
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
                if let fragrance = archive.fragrance(id: record.fragranceID) {
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
                AtelierEyebrow(text: "The way it feels", accent: archive.theme.palette.accent)
                AtelierDisplay(title: "Your gallery", size: 35)
                Text("One collection. Three ways to experience it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 10) {
                    AtelierModePicker(selected: $archive.layout, accent: archive.theme.palette.accent)
                    Text("Cover Flow for depth, Stack for focus, Fan for a spread.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                AtelierEyebrow(text: "Color & atmosphere", accent: archive.theme.palette.accent)
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
                                    .frame(height: 88)
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
                DisclosureGroup("About this archive") {
                    Text("Your collection, photos, and wear history stay on your device. Arooma is not affiliated with the fragrance houses shown.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .font(.footnote)
                .padding(15)
                .atelierPlate(16)
            }
            .padding(.horizontal, 22)
            .padding(.top, 17)
            .padding(.bottom, 35)
        }
        .background(AtelierAtmosphere(theme: archive.theme))
    }
}


// MARK: - The wear log. One session can include several bottles worn together.
struct AtelierWearLog: View {
    @EnvironmentObject private var archive: CollectionStore
    @State private var selected: [UUID] = []
    @State private var impression = ""
    @State private var showAll = false
    @Binding var startingBottleID: UUID?
    let add: () -> Void
    let focus: (DisplayCard) -> Void

    private var selectedIDs: [UUID] {
        selected.filter { id in archive.bottles.contains(where: { $0.id == id }) }
    }
    private var displayedSessions: [WearSession] {
        showAll ? archive.wearSessions :
            archive.wearSessions.filter { Calendar.current.isDateInToday($0.date) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 19) {
                VStack(alignment: .leading, spacing: 7) {
                    AtelierEyebrow(text: "Your daily ritual", accent: archive.theme.palette.accent)
                    AtelierDisplay(title: "What did you wear?", size: 34)
                    Text("Tap one or more bottles. Log them together as one wear.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                if archive.mode == .demo {
                    AtelierEmptyState(title: "Your personal wear log",
                        detail: "Switch to Mine to track what you wear and your favorite combinations.",
                        action: "Open My Collection",
                        callback: { archive.enter(.mine) }, accent: archive.theme.palette.accent)
                } else if archive.bottles.isEmpty {
                    AtelierEmptyState(title: "Your first wear begins here",
                        detail: "Save a bottle with just its name or a photograph. Add the details later.",
                        action: "Add a bottle", callback: add, accent: archive.theme.palette.accent)
                } else {
                    HStack {
                        AtelierEyebrow(text: "Choose your bottles", accent: archive.theme.palette.accent)
                        Spacer()
                        Text("\(selected.count) selected")
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
                        ForEach(archive.bottles) { bottle in
                            if let scent = archive.fragrance(id: bottle.fragranceID) {
                                Button {
                                    if selected.contains(bottle.id) { selected.removeAll { $0 == bottle.id } }
                                    else { selected.append(bottle.id) }
                                } label: {
                                    VStack(spacing: 7) {
                                        AtelierCardSurface(fragranceID: scent.id, selected: selected.contains(bottle.id))
                                            .frame(height: 131)
                                            .overlay(alignment: .topTrailing) {
                                                Image(systemName: selected.contains(bottle.id) ? "checkmark.circle.fill" : "circle")
                                                    .font(.title3).foregroundStyle(selected.contains(bottle.id) ? archive.theme.palette.accent : .white)
                                                    .padding(5).shadow(radius: 3)
                                            }
                                        Text(scent.name)
                                            .font(.caption).foregroundStyle(.primary)
                                            .lineLimit(2).multilineTextAlignment(.center)
                                            .frame(height: 32, alignment: .top)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(scent.name), \(selected.contains(bottle.id) ? "selected" : "not selected")")
                            }
                        }
                    }
                    Button(action: add) {
                        Label("Quick add another bottle", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain).foregroundStyle(archive.theme.palette.accent)

                    if !selected.isEmpty {
                        VStack(spacing: 12) {
                            HStack(spacing: -15) {
                                ForEach(selectedIDs, id: \.self) { id in
                                    if let bottle = archive.bottles.first(where: { $0.id == id }) {
                                        AtelierCardSurface(fragranceID: bottle.fragranceID)
                                            .frame(width: 62, height: 90)
                                            .rotationEffect(.degrees(Double(selectedIDs.firstIndex(of: id) ?? 0) * 4 - 4))
                                    }
                                }
                                Spacer(minLength: 0)
                                VStack(alignment: .trailing, spacing: 3) {
                                    Text(selected.count > 1 ? "Layered wear" : "Solo wear")
                                        .font(.headline)
                                    Text("\(selected.count) \(selected.count == 1 ? "fragrance" : "fragrances")")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            TextField("Optional impression", text: $impression, axis: .vertical)
                                .lineLimit(1...3).textFieldStyle(.roundedBorder)
                            Button {
                                archive.recordWear(bottleIDs: selectedIDs, note: impression)
                                selected.removeAll()
                                impression = ""
                            } label: {
                                Label(selected.count > 1 ? "Log this combination" : "Log this wear", systemImage: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: 51)
                            }
                            .buttonStyle(.borderedProminent).tint(archive.theme.palette.accent)
                        }
                        .padding(15).atelierPlate(20)
                    }

                    HStack {
                        AtelierEyebrow(text: showAll ? "Your wear history" : "Worn today",
                            accent: archive.theme.palette.accent)
                        Spacer()
                        Button(showAll ? "Today only" : "All history") { showAll.toggle() }
                            .font(.caption.weight(.medium))
                    }
                    if displayedSessions.isEmpty {
                        Text("Nothing logged here yet. Choose a fragrance above to begin.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                            .atelierPlate()
                    }
                    ForEach(displayedSessions) { session in
                        sessionRow(session)
                    }
                    let legacy = archive.bottles.filter {
                        $0.wears.contains(where: { $0.sessionID == nil })
                    }
                    if showAll && !legacy.isEmpty {
                        VStack(alignment: .leading, spacing: 9) {
                            AtelierEyebrow(text: "Earlier solo wears", accent: archive.theme.palette.accent)
                            ForEach(legacy) { bottle in
                                if let scent = archive.fragrance(id: bottle.fragranceID) {
                                    Text("\(scent.name) · \(bottle.wears.filter { $0.sessionID == nil }.count) earlier records")
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(15).atelierPlate()
                    }
                }
            }
            .padding(.horizontal, 22).padding(.top, 15).padding(.bottom, 32)
        }
        .background(AtelierAtmosphere(theme: archive.theme))
        .onAppear { includeStartingBottle() }
        .onChange(of: startingBottleID) { _, _ in includeStartingBottle() }
    }

    private func includeStartingBottle() {
        guard let id = startingBottleID else { return }
        if archive.bottles.contains(where: { $0.id == id }) && !selected.contains(id) {
            selected.append(id)
        }
        startingBottleID = nil
    }

    private func sessionRow(_ session: WearSession) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.bottleIDs.count > 1 ? "Layered combination" : "Solo wear")
                        .font(.system(.headline, design: .serif))
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Wear again") { selected = session.bottleIDs }
                    .font(.caption.weight(.semibold))
            }
            ForEach(session.bottleIDs, id: \.self) { id in
                if let bottle = archive.bottles.first(where: { $0.id == id }),
                   let scent = archive.fragrance(id: bottle.fragranceID) {
                    HStack(spacing: 10) {
                        AtelierCardSurface(fragranceID: scent.id)
                            .frame(width: 35, height: 51)
                        Text(scent.name).font(.subheadline)
                        Spacer()
                        Button {
                            archive.removeBottle(id, from: session.id)
                        } label: {
                            Image(systemName: "minus.circle")
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Remove \(scent.name) from wear")
                    }
                }
            }
            if !session.note.isEmpty {
                Text(session.note).font(.subheadline).italic().foregroundStyle(.secondary)
            }
            Button(role: .destructive) { archive.deleteWearSession(session.id) } label: {
                Label("Undo this session", systemImage: "arrow.uturn.backward")
                    .font(.caption)
            }
        }
        .padding(15).atelierPlate(18)
    }
}

// MARK: - Capture first, catalog later. No long mandatory form.
struct QuickAddSheet: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var photoData: Data?
    @State private var libraryItem: PhotosPickerItem?
    @State private var cameraOpen = false
    @FocusState private var typing: Bool
    let onAdded: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AtelierEyebrow(text: "Capture now · details later", accent: archive.theme.palette.accent)
                    AtelierDisplay(title: "Add a bottle", size: 38)
                    Text("Someone just recommended a fragrance? Save the name or snap the bottle in seconds.")
                        .font(.subheadline).foregroundStyle(.secondary)

                    TextField("Fragrance name", text: $name)
                        .font(.title3).textInputAutocapitalization(.words)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .focused($typing)
                        .onSubmit(save)

                    if let photoData, let photo = UIImage(data: photoData) {
                        Image(uiImage: photo).resizable().scaledToFit()
                            .frame(maxWidth: .infinity).frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .accessibilityLabel("Captured bottle photograph")
                    }
                    HStack(spacing: 10) {
                        Button {
                            typing = false
                            cameraOpen = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                        PhotosPicker(selection: $libraryItem, matching: .images) {
                            Label("Choose Photo", systemImage: "photo")
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.bordered)
                    }
                    Button(action: save) {
                        Label("Save to My Collection", systemImage: "checkmark")
                            .font(.headline).frame(maxWidth: .infinity, minHeight: 53)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(archive.theme.palette.accent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && photoData == nil)
                    Text("Only a name or photo is required. Everything is stored privately on this iPhone.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(22)
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
            }}
            .onChange(of: libraryItem) { _, item in
                Task {
                    if let bytes = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: bytes) {
                        photoData = image.jpegData(compressionQuality: 0.84)
                    }
                }
            }
            .fullScreenCover(isPresented: $cameraOpen) {
                CameraCapture { image in
                    photoData = image.jpegData(compressionQuality: 0.84)
                    cameraOpen = false
                } onCancel: {
                    cameraOpen = false
                }
                .ignoresSafeArea()
            }
        }
    }

    private func save() {
        let typed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !typed.isEmpty || photoData != nil else { return }
        if photoData == nil,
           let known = archive.catalog.first(where: {
               $0.name.localizedCaseInsensitiveCompare(typed) == .orderedSame
           }) {
            archive.add(known)
        } else {
            archive.quickAdd(name: typed, imageData: photoData)
        }
        onAdded()
        dismiss()
    }
}

struct CameraCapture: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraCapture
        init(parent: CameraCapture) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            else { parent.onCancel() }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}
