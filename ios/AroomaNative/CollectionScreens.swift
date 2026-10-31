import SwiftUI

struct ShelfScreen: View {
    @EnvironmentObject private var archive: CollectionStore
    let open: (DisplayCard) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 29) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("THE PRIVATE ARCHIVE").font(.caption2.weight(.semibold))
                                .tracking(2).foregroundStyle(archive.theme.palette.accent)
                            GalleryHeading(text: "Your shelves")
                        }
                        Spacer()
                        Text("\(archive.cards.count) cards")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 10)
                    ForEach(FragranceShelf.allCases) { shelf in
                        let cards = archive.cards.filter {
                            ($0.bottleID.flatMap { id in archive.bottles.first(where: { $0.id == id })?.shelf }
                             ?? $0.fragrance.shelf) == shelf
                        }
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(shelf.rawValue)
                                    .font(.system(.title, design: .serif))
                                Spacer()
                                Text("\(cards.count)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.bottom, 3)
                            Divider().overlay(archive.theme.palette.accent.opacity(0.3))
                            if cards.isEmpty {
                                Text("An empty shelf. Something worth saving belongs here.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 18)
                            } else {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 11), count: 3),
                                          spacing: 20) {
                                    ForEach(cards) { card in
                                        Button { archive.selectedShelf = shelf; open(card) } label: {
                                            VStack(alignment: .leading, spacing: 8) {
                                                CollectibleCard(id: card.fragrance.id, cornerRadius: 8)
                                                    .shadow(color: .black.opacity(0.18), radius: 8, y: 5)
                                                Text(card.fragrance.name)
                                                    .font(.system(.caption, weight: .semibold))
                                                    .lineLimit(1)
                                                    .foregroundStyle(.primary)
                                                Text(card.fragrance.house)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Open \(card.fragrance.name)")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 19)
                .padding(.bottom, 28)
            }
            .background(ArchiveBackdrop(theme: archive.theme))
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct DiscoveryScreen: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    let open: (DisplayCard) -> Void
    var addMode = false

    private var results: [Fragrance] {
        let tokens = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !tokens.isEmpty else { return archive.catalog }
        return archive.catalog.filter { fragrance in
            let fullText = ([fragrance.house, fragrance.name, fragrance.concentration, fragrance.year] +
                            fragrance.notes).joined(separator: " ")
            return tokens.allSatisfy { fullText.localizedStandardContains($0) }
        }
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(results) { fragrance in
                        Button {
                            if addMode {
                                archive.add(fragrance)
                                dismiss()
                            } else {
                                let owned = archive.bottles.first(where: { $0.fragranceID == fragrance.id })
                                open(DisplayCard(id: owned?.id.uuidString ?? fragrance.id,
                                                 fragrance: fragrance, bottleID: owned?.id))
                            }
                        } label: {
                            HStack(spacing: 14) {
                                CollectibleCard(id: fragrance.id, cornerRadius: 7)
                                    .frame(width: 62, height: 91)
                                    .shadow(color: .black.opacity(0.14), radius: 5, y: 3)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(fragrance.house.uppercased())
                                        .font(.caption2.weight(.semibold))
                                        .tracking(1.1)
                                        .foregroundStyle(archive.theme.palette.accent)
                                    Text(fragrance.name)
                                        .font(.system(.headline, design: .serif))
                                        .foregroundStyle(.primary)
                                    Text(fragrance.concentration)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if fragrance.archival {
                                        Text("Historical art edition")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(minLength: 0)
                                Image(systemName: addMode ? "plus.circle" : "chevron.right")
                                    .font(.body)
                                    .foregroundStyle(archive.theme.palette.accent)
                            }
                            .frame(minHeight: 96)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(addMode ? "ADD A FRAGRANCE" : "FRAGRANCE CATALOG")
                } footer: {
                    Text("This is a curated, offline demo catalog. Arooma is not affiliated with the fragrance houses.")
                        .font(.caption)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ArchiveBackdrop(theme: archive.theme))
            .navigationTitle(addMode ? "Add a bottle" : "Discover")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, prompt: "House, name, concentration or note")
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .toolbar {
                if addMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }
}

struct MyBottleScreen: View {
    @EnvironmentObject private var archive: CollectionStore
    let openAdd: () -> Void
    @State private var editing: BottleRecord?
    @State private var history: BottleRecord?
    @State private var showRotations = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("COLLECTION JOURNAL")
                            .font(.caption2.weight(.semibold))
                            .tracking(2).foregroundStyle(archive.theme.palette.accent)
                        GalleryHeading(text: "My Bottle")
                    }
                    .padding(.top, 12)

                    if archive.mode == .demo {
                        ContentUnavailableView {
                            Label("Your own cabinet", systemImage: "drop")
                        } description: {
                            Text("Switch to Mine to see your wear history and personal fragrance notes.")
                        } actions: {
                            Button("Open My Collection") { archive.enter(.mine) }
                                .buttonStyle(.borderedProminent)
                                .tint(archive.theme.palette.accent)
                        }
                    } else if archive.bottles.isEmpty {
                        ContentUnavailableView {
                            Label("Nothing bottled yet", systemImage: "rectangle.stack.badge.plus")
                        } description: {
                            Text("Choose an existing collectible to start a private collection.")
                        } actions: {
                            Button("Find a fragrance", action: openAdd).buttonStyle(.borderedProminent)
                        }
                    } else {
                        if let pick = archive.dailyPick {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("TODAY'S PICK").font(.caption2.weight(.bold))
                                        .tracking(1.8).foregroundStyle(archive.theme.palette.accent)
                                    Text(pick.fragrance.name).font(.system(.title3, design: .serif))
                                }
                                Spacer()
                                Button("Focus") { archive.choose(pick) }
                                    .frame(minWidth: 55, minHeight: 44)
                            }
                            .padding(17)
                            .background(archive.theme.palette.secondary.opacity(0.14),
                                        in: RoundedRectangle(cornerRadius: 18))
                        }
                        if !archive.lowStock.isEmpty {
                            Label("\(archive.lowStock.count) bottle(s) at or below 20% remaining",
                                  systemImage: "drop.triangle")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                        if let record = archive.selectedBottle,
                           let fragrance = archive.fragrance(id: record.fragranceID) {
                            HStack(alignment: .top, spacing: 18) {
                                CollectibleCard(id: fragrance.id, cornerRadius: 9)
                                    .frame(width: 112, height: 164)
                                VStack(alignment: .leading, spacing: 9) {
                                    Text(fragrance.house.uppercased())
                                        .font(.caption2.weight(.semibold)).tracking(1.3)
                                        .foregroundStyle(archive.theme.palette.accent)
                                    Text(fragrance.name).font(.system(.title2, design: .serif))
                                    Text(fragrance.concentration).font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("\(Int(record.remaining * 100))% estimated remaining")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(record.lowStock ? Color.orange : Color.secondary)
                                    Text("\(record.wears.count) wears recorded")
                                        .font(.subheadline.weight(.medium))
                                }
                                Spacer(minLength: 0)
                            }

                            HStack(spacing: 10) {
                                if record.wornToday {
                                    Button("Undo Today's Wear") { archive.undoWear() }
                                        .buttonStyle(.bordered)
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                } else {
                                    Button("Wear Today") { archive.wearSelected() }
                                        .buttonStyle(.borderedProminent)
                                        .tint(archive.theme.palette.accent)
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                }
                                Button {
                                    history = record
                                } label: {
                                    Label("History", systemImage: "clock")
                                        .frame(minHeight: 48)
                                }
                                .buttonStyle(.bordered)
                            }
                            Button {
                                editing = record
                            } label: {
                                Label("Edit Bottle Details", systemImage: "square.and.pencil")
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            Divider()
                            HStack {
                                Text("COLLECTION").font(.caption.weight(.bold)).tracking(1.5)
                                Spacer()
                                Button("Add") { openAdd() }.frame(minHeight: 44)
                            }
                            ForEach(archive.bottles) { bottle in
                                if let item = archive.fragrance(id: bottle.fragranceID) {
                                    Button { archive.selectedMineID = bottle.id } label: {
                                        HStack {
                                            Text(item.name).font(.system(.body, design: .serif))
                                            Spacer()
                                            if bottle.id == record.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(archive.theme.palette.accent)
                                            }
                                        }
                                        .frame(minHeight: 47)
                                    }
                                    .buttonStyle(.plain)
                                    Divider()
                                }
                            }
                        }
                        Button {
                            showRotations = true
                        } label: {
                            Label("Manage Wear Rotations", systemImage: "square.stack.3d.up")
                                .frame(minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 36)
            }
            .background(ArchiveBackdrop(theme: archive.theme))
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $editing) { record in
            NavigationStack { BottleEditor(bottle: record) }
        }
        .sheet(item: $history) { record in
            NavigationStack { WearHistoryScreen(bottleID: record.id) }
        }
        .sheet(isPresented: $showRotations) {
            NavigationStack { RotationManager() }
        }
    }
}

struct BottleEditor: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: BottleRecord
    @State private var confirmDelete = false

    init(bottle: BottleRecord) {
        _draft = State(initialValue: bottle)
    }
    var body: some View {
        Form {
            Section("Ownership") {
                Picker("Shelf", selection: $draft.shelf) {
                    ForEach(FragranceShelf.allCases) { shelf in Text(shelf.rawValue).tag(shelf) }
                }
                Stepper("Bottle size · \(draft.volumeML) ml", value: $draft.volumeML, in: 5...1000, step: 5)
                VStack(alignment: .leading) {
                    Text("Estimated remaining · \(Int(draft.remaining * 100))%")
                    Slider(value: $draft.remaining, in: 0...1, step: 0.01)
                        .tint(archive.theme.palette.accent)
                }
                Toggle("Favorite", isOn: $draft.favorite)
            }
            Section("Your notes") {
                TextField("Personal impressions", text: $draft.personalNotes, axis: .vertical)
                    .lineLimit(3...7)
                TextField("Authenticity observations", text: $draft.authenticityNotes, axis: .vertical)
                    .lineLimit(2...6)
            }
            Section {
                Button("Delete from My Collection", role: .destructive) {
                    confirmDelete = true
                }
            }
        }
        .navigationTitle("My Bottle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { archive.update(draft); dismiss() }
                    .fontWeight(.semibold)
            }
        }
        .confirmationDialog("Remove this bottle and its wear history?", isPresented: $confirmDelete) {
            Button("Delete Bottle", role: .destructive) {
                archive.delete(draft)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This is permanent unless you have a separate collection backup.")
        }
    }
}

struct WearHistoryScreen: View {
    @EnvironmentObject private var archive: CollectionStore
    let bottleID: UUID
    var body: some View {
        let bottle = archive.bottles.first { $0.id == bottleID }
        List {
            if let bottle {
                ForEach(bottle.wears.sorted(by: { $0.date > $1.date })) { wear in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(wear.date, format: .dateTime.month(.wide).day().year())
                        Text(wear.date, format: .dateTime.hour().minute())
                            .font(.caption).foregroundStyle(.secondary)
                        if !wear.impression.isEmpty {
                            Text(wear.impression).font(.subheadline)
                        }
                    }
                    .frame(minHeight: 47)
                }
            }
        }
        .navigationTitle("Wear History")
        .overlay {
            if bottle?.wears.isEmpty != false {
                ContentUnavailableView("No wears yet", systemImage: "clock",
                                       description: Text("Record your first wear from the card gallery."))
            }
        }
    }
}

struct RotationManager: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var picked: Set<String> = []
    var body: some View {
        Form {
            Section("New rotation") {
                TextField("A name for your rotation", text: $name)
                ForEach(archive.bottles, id: \.id) { bottle in
                    if let fragrance = archive.fragrance(id: bottle.fragranceID) {
                        Toggle(fragrance.name, isOn: Binding(
                            get: { picked.contains(fragrance.id) },
                            set: { selected in
                                if selected { picked.insert(fragrance.id) }
                                else { picked.remove(fragrance.id) }
                            }
                        ))
                    }
                }
                Button("Save Rotation") {
                    archive.addRotation(name: name, fragranceIDs: Array(picked))
                    name = ""; picked.removeAll()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || picked.isEmpty)
            }
            Section("Saved rotations") {
                ForEach(archive.rotations) { rotation in
                    HStack {
                        Button {
                            archive.rotationID = rotation.id
                            archive.layout = .fan
                            dismiss()
                        } label: {
                            VStack(alignment: .leading) {
                                Text(rotation.name).font(.headline)
                                Text("\(rotation.fragranceIDs.count) fragrances")
                                    .font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        Button(role: .destructive) { archive.removeRotation(rotation) } label: {
                            Image(systemName: "trash").frame(width: 44, height: 44)
                        }
                    }
                }
            }
        }
        .navigationTitle("Wear Rotations")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
    }
}

struct StyleScreen: View {
    @EnvironmentObject private var archive: CollectionStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("FINISHES & MATERIALS")
                        .font(.caption2.weight(.semibold))
                        .tracking(2).foregroundStyle(archive.theme.palette.accent)
                    GalleryHeading(text: "Your Arooma")
                    Text("The cards keep their original photographic finish. Only the surrounding archive changes.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(FragranceTheme.allCases) { theme in
                            Button {
                                withAnimation(.easeInOut(duration: 0.27)) { archive.theme = theme }
                            } label: {
                                VStack(alignment: .leading, spacing: 11) {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(LinearGradient(colors: [theme.palette.field, theme.palette.secondary],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(height: 98)
                                        .overlay(alignment: .bottomTrailing) {
                                            Circle().fill(theme.palette.accent)
                                                .frame(width: 27, height: 27).padding(14)
                                        }
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(archive.theme == theme ? theme.palette.accent : .clear, lineWidth: 3)
                                        }
                                    Text(theme.rawValue)
                                        .font(.system(.body, design: .serif))
                                        .foregroundStyle(.primary)
                                    if archive.theme == theme {
                                        Label("Selected", systemImage: "checkmark")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("APPEARANCE").font(.caption.weight(.semibold)).tracking(1.6)
                    Picker("Appearance", selection: $archive.appearance) {
                        ForEach(Appearance.allCases) { value in Text(value.rawValue).tag(value) }
                    }.pickerStyle(.segmented)
                    Divider()
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About Arooma").font(.system(.title3, design: .serif))
                        Text("An independent, local-first fragrance companion. Not affiliated with, endorsed by, or sponsored by the fragrance houses shown. Brand names are used for identification. Original card compositions remain subject to their documented image-rights review.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Native iOS 26+ · Collection data stays on this iPhone")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(22)
                .padding(.bottom, 35)
            }
            .background(ArchiveBackdrop(theme: archive.theme))
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
