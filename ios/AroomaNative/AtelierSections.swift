import SwiftUI
import PhotosUI
import UIKit

// MARK: - Shared press feel

/// Cards used as buttons sink slightly under the finger and spring back: immediate, physical,
/// no default highlight flash.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.955 : 1)
            .brightness(configuration.isPressed ? -0.035 : 0)
            .animation(.spring(response: 0.26, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

// MARK: - First run

struct AtelierWelcome: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(SignatureIntroPolicy.seenKey) private var introSeen = false
    /// First launch only: the pen-writing intro, ending on the exact master signature.
    @State private var showingIntro = !UserDefaults.standard.bool(forKey: SignatureIntroPolicy.seenKey)
    @State private var cameFromIntro = false
    @State private var settled = false
    @State private var dealt = false
    @State private var handle: CGSize = .zero
    @Namespace private var swatchRing
    @Namespace private var signatureSpace
    let openDemo: () -> Void
    let openMine: () -> Void

    var body: some View {
        ZStack {
            if showingIntro {
                SignatureIntro(namespace: signatureSpace) {
                    introSeen = true
                    cameFromIntro = true
                    withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .spring(response: 0.8, dampingFraction: 0.9)) {
                        showingIntro = false
                    }
                }
                .transition(.opacity)
                .zIndex(2)
            } else {
                welcome
                    .transition(.opacity)
            }
        }
    }

    private var welcome: some View {
        GeometryReader { geo in
            let accent = archive.theme.palette.accent
            VStack(spacing: 0) {
                AtelierEyebrow(text: "The private fragrance archive", accent: accent)
                    .padding(.top, 18)
                    .opacity(settled ? 1 : 0)
                Spacer(minLength: 8)
                VStack(spacing: 10) {
                    // The exact master signature (assets/brand), inked in the theme's metal.
                    AroomaSignatureMark(ink: accent)
                        .frame(width: min(geo.size.width * 0.8, 330),
                               height: min(geo.size.width * 0.8, 330) / SignatureGeometry.logoAspect)
                        .matchedGeometryEffect(id: "arooma-signature", in: signatureSpace)
                        .accessibilityElement()
                        .accessibilityLabel("Arooma")
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHidden(cameFromIntro) // already announced by the intro
                    AtelierDisplay(title: "A collection worth keeping.", size: 27)
                        .multilineTextAlignment(.center)
                        .opacity(settled ? 1 : 0)
                        .offset(y: settled ? 0 : 8)
                }
                Spacer(minLength: 10)
                hand(width: min(geo.size.width * 0.44, 200))
                    .frame(height: min(geo.size.width * 0.44, 200) * 86 / 59 + 20)
                Spacer(minLength: 14)
                Group {
                    themePicker(accent: accent)
                        .padding(.bottom, 18)
                    VStack(spacing: 10) {
                        Button(action: openDemo) {
                            Text("Explore the Archive")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(accent)
                        Button(action: openMine) {
                            Text("Start My Collection")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .buttonStyle(.glass)
                    }
                    .padding(.horizontal, 26)
                    .padding(.bottom, 16)
                }
                .opacity(settled ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AtelierAtmosphere(theme: archive.theme))
        .onAppear {
            if reduceMotion { settled = true; dealt = true; return }
            withAnimation(.easeOut(duration: 0.55).delay(cameFromIntro ? 0.35 : 0.1)) { settled = true }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.78).delay(cameFromIntro ? 0.45 : 0.25)) { dealt = true }
        }
    }

    /// Three collectibles dealt onto the table. The front card can be picked up and tilted:
    /// the first thing a new owner touches already answers like an object.
    private func hand(width w: CGFloat) -> some View {
        let yaw = Double(handle.width / 3).clamped(to: -34...34)
        let pitch = Double(-handle.height / 4).clamped(to: -22...22)
        return ZStack {
            AtelierCardSurface(fragranceID: "hawas", foil: .sheen)
                .frame(width: w * 0.86, height: w * 0.86 * 86 / 59)
                .rotationEffect(.degrees(dealt ? -13 : -40), anchor: .bottom)
                .offset(x: dealt ? -w * 0.42 : 0, y: dealt ? 14 : 420)
            AtelierCardSurface(fragranceID: "myslf", foil: .sheen)
                .frame(width: w * 0.86, height: w * 0.86 * 86 / 59)
                .rotationEffect(.degrees(dealt ? 12 : 40), anchor: .bottom)
                .offset(x: dealt ? w * 0.42 : 0, y: dealt ? 16 : 440)
                .animation(reduceMotion ? nil : .spring(response: 0.8, dampingFraction: 0.78).delay(0.08), value: dealt)
            AtelierCardSurface(fragranceID: "dior", yaw: yaw, lift: handle == .zero ? 0.2 : 0.8,
                               foil: .live, lean: 1)
                .frame(width: w, height: w * 86 / 59)
                .rotation3DEffect(.degrees(yaw), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                .rotation3DEffect(.degrees(pitch), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                .offset(y: dealt ? -6 : 460)
                .animation(reduceMotion ? nil : .spring(response: 0.8, dampingFraction: 0.8).delay(0.16), value: dealt)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in handle = value.translation }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { handle = .zero }
                        }
                )
        }
        .accessibilityHidden(true)
    }

    private func themePicker(accent: Color) -> some View {
        VStack(spacing: 10) {
            Text("CHOOSE YOUR FINISH")
                .font(.caption2.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.secondary)
            HStack(spacing: 14) {
                ForEach(FragranceTheme.allCases) { theme in
                    Button {
                        withAnimation(reduceMotion ? nil : .smooth(duration: 0.6)) { archive.theme = theme }
                    } label: {
                        ZStack {
                            if archive.theme == theme {
                                Circle()
                                    .strokeBorder(Color.primary.opacity(0.85), lineWidth: 1.5)
                                    .matchedGeometryEffect(id: "ring", in: swatchRing)
                                    .frame(width: 50, height: 50)
                            }
                            Circle()
                                .fill(LinearGradient(colors: [theme.palette.field, theme.palette.secondary,
                                                              theme.palette.accent],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 38, height: 38)
                        }
                        .frame(width: 52, height: 52)
                    }
                    .buttonStyle(PressableCardStyle())
                    .accessibilityLabel(theme.rawValue)
                    .accessibilityAddTraits(archive.theme == theme ? .isSelected : [])
                }
            }
            Text(archive.theme.rawValue)
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self { min(max(self, range.lowerBound), range.upperBound) }
}

// MARK: - Shelves

struct AtelierShelves: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var renaming: FragranceShelf?
    @State private var newName = ""
    let focus: (DisplayCard) -> Void
    let add: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 7) {
                    AtelierEyebrow(text: archive.mode == .mine ? "Your collection" : "The sample archive",
                                   accent: archive.theme.palette.accent)
                    HStack(alignment: .firstTextBaseline) {
                        AtelierDisplay(title: "The shelves", size: 37)
                        Spacer()
                        Text("\(archive.cards.count) pieces")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text("Drag along a shelf. Tap a card to bring it to the front. Hold to move it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 23)
                .padding(.top, 16)

                ForEach(FragranceShelf.allCases) { shelf in
                    ShelfLedge(shelf: shelf, cards: archive.cardsOnShelf(shelf), focus: focus, add: add,
                               rename: { newName = archive.shelfName(shelf); renaming = shelf })
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

extension CollectionStore {
    func shelf(for card: DisplayCard) -> FragranceShelf {
        guard let id = card.bottleID, let owned = bottles.first(where: { $0.id == id }) else {
            return card.fragrance.shelf
        }
        return owned.shelf
    }
    func cardsOnShelf(_ shelf: FragranceShelf) -> [DisplayCard] {
        cards.filter { self.shelf(for: $0) == shelf }
    }
    func moveCard(_ card: DisplayCard, to shelf: FragranceShelf) {
        guard let id = card.bottleID, var record = bottles.first(where: { $0.id == id }) else { return }
        record.shelf = shelf
        update(record)
    }
}

/// One physical shelf: cards stand on a lit ledge and turn toward you as they scroll to centre.
struct ShelfLedge: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let shelf: FragranceShelf
    let cards: [DisplayCard]
    let focus: (DisplayCard) -> Void
    let add: () -> Void
    let rename: () -> Void

    var body: some View {
        let accent = archive.theme.palette.accent
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: shelf.icon)
                    .font(.system(.subheadline, weight: .light))
                    .foregroundStyle(accent)
                AtelierDisplay(title: archive.shelfName(shelf), size: 27)
                Spacer()
                Text("\(cards.count, format: .number.precision(.integerLength(2)))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(cards.count)))
                Button(action: rename) {
                    Image(systemName: "pencil").frame(width: 30, height: 30)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Rename \(archive.shelfName(shelf))")
            }
            .padding(.horizontal, 23)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .bottom, spacing: 16) {
                    ForEach(cards) { card in
                        Button { focus(card) } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                AtelierCardSurface(fragranceID: card.fragrance.id, radius: 11, foil: .sheen)
                                    .frame(width: 132, height: 192)
                                Text(card.fragrance.name)
                                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                                    .lineLimit(1)
                                Text(card.fragrance.house)
                                    .font(.caption2).foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 132, alignment: .leading)
                        }
                        .buttonStyle(PressableCardStyle())
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .rotation3DEffect(.degrees(reduceMotion ? 0 : phase.value * -32),
                                                  axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                                .scaleEffect(1 - abs(phase.value) * 0.08)
                                .offset(y: abs(phase.value) * 8)
                        }
                        .contextMenu { moveMenu(card) }
                        .accessibilityLabel("\(card.fragrance.house) \(card.fragrance.name)")
                        .accessibilityHint("Opens it in the collection")
                    }
                    Button(action: add) {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .foregroundStyle(.secondary.opacity(0.6))
                            .frame(width: cards.isEmpty ? 132 : 76, height: 192)
                            .overlay {
                                VStack(spacing: 6) {
                                    Image(systemName: "plus").font(.title3.weight(.light))
                                    if cards.isEmpty {
                                        Text("Place a bottle here").font(.caption)
                                    }
                                }
                                .foregroundStyle(.secondary)
                            }
                            .padding(.bottom, cards.isEmpty ? 0 : 44)
                    }
                    .buttonStyle(PressableCardStyle())
                    .accessibilityLabel("Add a bottle")
                }
                .scrollTargetLayout()
                .padding(.vertical, 10)
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, 23, for: .scrollContent)
            .scrollClipDisabled()
            .background(alignment: .bottom) {
                // The ledge itself: a lit edge with a soft shadow beneath, in the theme's accent.
                VStack(spacing: 0) {
                    LinearGradient(colors: [accent.opacity(0.55), accent.opacity(0.08)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 3)
                    LinearGradient(colors: [archive.theme.shadowTint.opacity(0.3), .clear],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 16)
                }
                .padding(.horizontal, 14)
                .offset(y: -38)
                .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder private func moveMenu(_ card: DisplayCard) -> some View {
        Button("Bring to front", systemImage: "rectangle.stack") { focus(card) }
        if card.bottleID != nil {
            Menu("Move to shelf", systemImage: "arrow.right.square") {
                ForEach(FragranceShelf.allCases.filter { $0 != shelf }) { other in
                    Button(archive.shelfName(other), systemImage: other.icon) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            archive.moveCard(card, to: other)
                        }
                    }
                }
            }
        }
    }
}

/// Pinch-out from the deck. Every shelf at a glance, mini cards fanned like a held set.
/// Pinch back in (or tap a card) to return; progress is the same value the pinch drives.
struct ShelfOverview: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var progress: CGFloat
    let focus: (DisplayCard) -> Void
    let add: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                AtelierDisplay(title: "Every shelf", size: 30)
                Spacer()
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.88)) { progress = 0 }
                } label: {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .semibold)).frame(width: 30, height: 30)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Back to cards")
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            Text("Tap a card to bring it forward, or pinch open to return.")
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.bottom, 6)
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(Array(FragranceShelf.allCases.enumerated()), id: \.element) { i, shelf in
                        let cards = archive.cardsOnShelf(shelf)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: shelf.icon).foregroundStyle(archive.theme.palette.accent)
                                Text(archive.shelfName(shelf)).font(.system(.title3, design: .serif))
                                Spacer()
                                Text("\(cards.count)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            }
                            if cards.isEmpty {
                                Button(action: add) {
                                    Label("Place a first bottle", systemImage: "plus")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, minHeight: 60)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: -22) {
                                        ForEach(Array(cards.enumerated()), id: \.element.id) { j, card in
                                            Button { focus(card) } label: {
                                                AtelierCardSurface(fragranceID: card.fragrance.id, radius: 7, foil: .sheen)
                                                    .frame(width: 70, height: 102)
                                                    .rotationEffect(.degrees(Double(j % 3) * 2.5 - 2.5), anchor: .bottom)
                                            }
                                            .buttonStyle(PressableCardStyle())
                                            .accessibilityLabel("Bring \(card.fragrance.name) to the front")
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(14)
                        .atelierPlate(18)
                        .offset(y: (1 - progress) * CGFloat(30 + i * 22))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .simultaneousGesture(
            MagnifyGesture(minimumScaleDelta: 0.02)
                .onChanged { value in
                    progress = min(1, max(0, 1 - (value.magnification - 1) / 0.42))
                }
                .onEnded { value in
                    let close = progress < 0.6 || value.velocity > 0.6
                    withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.86)) {
                        progress = close ? 0 : 1
                    }
                }
        )
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
                        Text("Search by name or note. If it’s missing, save the name instantly.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 12)
                    if results.isEmpty {
                        ContentUnavailableView.search(text: query)
                        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button {
                                if let fragrance = archive.quickAdd(name: query) {
                                    let bottle = archive.bottles.first(where: {
                                        $0.fragranceID == fragrance.id
                                    })
                                    focus(DisplayCard(id: bottle?.id.uuidString ?? fragrance.id,
                                                      fragrance: fragrance, bottleID: bottle?.id))
                                    dismiss()
                                }
                            } label: {
                                Label("Save this fragrance name now", systemImage: "plus")
                                    .frame(maxWidth: .infinity, minHeight: 51)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(archive.theme.palette.accent)
                            Text("No catalog match required. You can add the house or a photo later.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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


// MARK: - View & Style

struct AtelierStyle: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var replayingIntro = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AtelierEyebrow(text: "Arrangement", accent: archive.theme.palette.accent)
                HStack(spacing: 10) {
                    ForEach(CardLayout.allCases) { layout in
                        Button {
                            withAnimation(reduceMotion ? nil : .snappy) { archive.layout = layout }
                        } label: {
                            VStack(spacing: 8) {
                                LayoutThumbnail(layout: layout, selected: archive.layout == layout,
                                                accent: archive.theme.palette.accent)
                                    .frame(height: 74)
                                Text(layout.rawValue)
                                    .font(.system(.caption, weight: archive.layout == layout ? .semibold : .regular))
                                    .foregroundStyle(archive.layout == layout ? archive.theme.palette.accent : .primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .atelierPlate(16)
                            .overlay {
                                if archive.layout == layout {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(archive.theme.palette.accent.opacity(0.8), lineWidth: 1.2)
                                }
                            }
                        }
                        .buttonStyle(PressableCardStyle())
                        .accessibilityLabel(layout.rawValue)
                        .accessibilityAddTraits(archive.layout == layout ? .isSelected : [])
                    }
                }
                Text(archive.layout.choreography)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: archive.layout)

                AtelierEyebrow(text: "Atmosphere", accent: archive.theme.palette.accent)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(FragranceTheme.allCases) { theme in
                        Button {
                            withAnimation(reduceMotion ? nil : .smooth(duration: 0.55)) { archive.theme = theme }
                        } label: {
                            ThemeSwatch(theme: theme, selected: archive.theme == theme)
                        }
                        .buttonStyle(PressableCardStyle())
                        .accessibilityLabel(theme.rawValue)
                        .accessibilityAddTraits(archive.theme == theme ? .isSelected : [])
                    }
                }
                AtelierEyebrow(text: "Appearance", accent: archive.theme.palette.accent)
                Picker("Appearance", selection: $archive.appearance) {
                    ForEach(Appearance.allCases) { a in Text(a.rawValue).tag(a) }
                }
                .pickerStyle(.segmented)
                AtelierEyebrow(text: "Signature", accent: archive.theme.palette.accent)
                Button { replayingIntro = true } label: {
                    HStack(spacing: 14) {
                        AroomaSignatureMark(ink: archive.theme.palette.accent)
                            .frame(height: 30)
                        Spacer(minLength: 8)
                        Label("Replay intro", systemImage: "play.circle")
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Replay the Arooma signature intro")
                DisclosureGroup("About this archive") {
                    Text("Your collection, photos, and wear history stay on your device. Arooma is not affiliated with the fragrance houses shown. Card foil responds to how you hold your iPhone; it switches off in Low Power Mode and with Reduce Motion.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .padding(.top, 6)
                }
                .font(.footnote)
                .padding(15)
                .atelierPlate(16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 30)
        }
        .scrollContentBackground(.hidden)
        .fullScreenCover(isPresented: $replayingIntro) { SignatureReplay() }
    }
}

/// Five tiny cards posed by the SAME layout engine the gallery uses, so the preview is honest.
struct LayoutThumbnail: View {
    let layout: CardLayout
    let selected: Bool
    let accent: Color
    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width * 0.34, geo.size.height * 0.62)
            ZStack {
                ForEach([-2, -1, 1, 2, 0], id: \.self) { d in
                    let pose = DeckLayoutEngine.pose(distance: Double(d), index: d + 2, layout: layout.kind, cardWidth: Double(w))
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(d == 0 ? (selected ? accent : Color.primary.opacity(0.55)) : Color.primary.opacity(0.18 + 0.08 * Double(2 - abs(d))))
                        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
                        .frame(width: w, height: w * 86 / 59)
                        .scaleEffect(pose.scale)
                        .rotation3DEffect(.degrees(pose.yaw), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                        .rotationEffect(.degrees(pose.roll), anchor: UnitPoint(x: 0.5, y: pose.pivotY))
                        .offset(x: pose.x, y: pose.y)
                        .opacity(pose.opacity)
                        .zIndex(pose.depth)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }
}

struct ThemeSwatch: View {
    let theme: FragranceTheme
    let selected: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack {
                LinearGradient(colors: [theme.palette.field, theme.palette.secondary],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [theme.keyLight.opacity(0.35), .clear], center: .init(x: 0.7, y: 0.2),
                               startRadius: 2, endRadius: 90)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(theme.palette.field.opacity(0.9))
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(theme.palette.accent, lineWidth: 1))
                    .frame(width: 34, height: 50)
                    .rotationEffect(.degrees(-6))
                    .shadow(color: theme.shadowTint.opacity(0.5), radius: 6, y: 4)
            }
            .frame(height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? theme.palette.accent : Color.primary.opacity(0.1), lineWidth: selected ? 1.6 : 0.6)
            }
            HStack(spacing: 5) {
                Text(theme.rawValue).font(.system(.subheadline, design: .serif)).foregroundStyle(.primary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.palette.accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
}

// MARK: - Today: the wear and layering journal

struct AtelierWearLog: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selected: [UUID] = []
    @State private var impression = ""
    @State private var showAll = false
    @State private var namingLayer = false
    @State private var newLayerName = ""
    @State private var addingNote = false
    @State private var stamp = 0
    @State private var justLogged: UUID?
    @Binding var startingBottleID: UUID?
    let add: () -> Void
    let focus: (DisplayCard) -> Void

    private var accent: Color { archive.theme.palette.accent }
    private var selectedIDs: [UUID] {
        selected.filter { id in archive.bottles.contains(where: { $0.id == id }) }
    }
    private var displayedSessions: [WearSession] {
        showAll ? archive.wearSessions :
            archive.wearSessions.filter { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    AtelierEyebrow(text: Date.now.formatted(.dateTime.weekday(.wide).month().day()), accent: accent)
                    AtelierDisplay(title: "What are you wearing?", size: 34)
                    Text("Tap one bottle, or several to layer them. Log it as one wear.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                if archive.mode == .demo {
                    AtelierEmptyState(title: "Your personal wear log",
                        detail: "Switch to your collection to track what you wear and the layers you love.",
                        action: "Open My Collection",
                        callback: { archive.enter(.mine) }, accent: accent)
                } else if archive.bottles.isEmpty {
                    AtelierEmptyState(title: "Your first wear begins here",
                        detail: "Save a bottle with just its name or a photograph. Add the details later.",
                        action: "Add a bottle", callback: add, accent: accent)
                } else {
                    if !archive.savedLayers.isEmpty { savedLayers }
                    picker
                    history
                }
            }
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, selected.isEmpty ? 30 : 250)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AtelierAtmosphere(theme: archive.theme))
        .safeAreaInset(edge: .bottom) {
            if !selectedIDs.isEmpty {
                compositionTray
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.84), value: selectedIDs)
        .alert("Save this combination", isPresented: $namingLayer) {
            TextField("e.g. Workday layer", text: $newLayerName)
            Button("Cancel", role: .cancel) {}
            Button("Save") { archive.saveLayer(name: newLayerName, bottleIDs: selectedIDs) }
        } message: {
            Text("Give these fragrances a name so you can wear them together again.")
        }
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

    private func toggle(_ id: UUID) {
        if selected.contains(id) { selected.removeAll { $0 == id } }
        else { selected.append(id) }
    }

    // MARK: Saved layers

    private var savedLayers: some View {
        VStack(alignment: .leading, spacing: 10) {
            AtelierEyebrow(text: "Your layers", accent: accent)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(archive.savedLayers) { layer in
                        let ids = layer.bottleIDs.filter { id in archive.bottles.contains(where: { $0.id == id }) }
                        Button { selected = ids } label: {
                            HStack(spacing: 12) {
                                ComposedSet(bottleIDs: ids, cardWidth: 34, spread: 7)
                                    .frame(width: 70, height: 60)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(layer.name)
                                        .font(.system(.subheadline, design: .serif))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text("\(ids.count) scents · tap to wear")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 10).padding(.horizontal, 12)
                            .frame(width: 220, alignment: .leading)
                            .atelierPlate(16)
                        }
                        .buttonStyle(PressableCardStyle())
                        .contextMenu {
                            Button("Delete saved layer", systemImage: "trash", role: .destructive) {
                                archive.deleteLayer(layer.id)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollClipDisabled()
        }
    }

    // MARK: Picker

    private var picker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AtelierEyebrow(text: "Your bottles", accent: accent)
                Spacer()
                Button(action: add) {
                    Label("Add", systemImage: "plus").font(.caption.weight(.semibold))
                }
                .buttonStyle(.glass)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 98), spacing: 14)], spacing: 16) {
                ForEach(archive.bottles) { bottle in
                    if let scent = archive.fragrance(id: bottle.fragranceID) {
                        let isOn = selected.contains(bottle.id)
                        let order = selectedIDs.firstIndex(of: bottle.id)
                        Button { toggle(bottle.id) } label: {
                            VStack(spacing: 7) {
                                AtelierCardSurface(fragranceID: scent.id, radius: 9,
                                                   lift: isOn ? 1 : 0, foil: isOn ? .sheen : FoilMode.none)
                                    .frame(height: 138)
                                    .overlay(alignment: .topTrailing) {
                                        ZStack {
                                            Circle().fill(isOn ? accent : Color.black.opacity(0.35))
                                            if let order {
                                                Text("\(order + 1)")
                                                    .font(.caption2.weight(.bold)).foregroundStyle(.white)
                                                    .contentTransition(.numericText(value: Double(order)))
                                            }
                                        }
                                        .frame(width: 22, height: 22)
                                        .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 1))
                                        .padding(6)
                                    }
                                    .offset(y: isOn ? -6 : 0)
                                    .scaleEffect(isOn ? 1.03 : 1)
                                Text(scent.name)
                                    .font(.caption).foregroundStyle(.primary)
                                    .lineLimit(2).multilineTextAlignment(.center)
                                    .frame(height: 32, alignment: .top)
                            }
                            .opacity(!selected.isEmpty && !isOn ? 0.72 : 1)
                        }
                        .buttonStyle(PressableCardStyle())
                        .sensoryFeedback(.selection, trigger: isOn)
                        .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.7), value: isOn)
                        .accessibilityLabel(scent.name)
                        .accessibilityValue(isOn ? "Selected, \(order.map { "layer \($0 + 1)" } ?? "")" : "Not selected")
                        .accessibilityAddTraits(isOn ? .isSelected : [])
                    }
                }
            }
        }
    }

    // MARK: Composition tray

    private var compositionTray: some View {
        let ids = selectedIDs
        return VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                ComposedSet(bottleIDs: ids, cardWidth: 50, spread: 10)
                    .frame(width: 120, height: 86)
                    .keyframeAnimator(initialValue: StampPose(), trigger: stamp) { content, pose in
                        content.scaleEffect(pose.scale).offset(y: pose.y)
                    } keyframes: { _ in
                        KeyframeTrack(\.scale) {
                            CubicKeyframe(0.9, duration: 0.08)
                            SpringKeyframe(1.06, duration: 0.16, spring: .snappy)
                            SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
                        }
                        KeyframeTrack(\.y) {
                            CubicKeyframe(6, duration: 0.08)
                            SpringKeyframe(-4, duration: 0.16, spring: .snappy)
                            SpringKeyframe(0, duration: 0.3, spring: .smooth)
                        }
                    }
                VStack(alignment: .leading, spacing: 3) {
                    Text(ids.count > 1 ? "Layered · \(ids.count)" : "Solo wear")
                        .font(.system(.headline, design: .serif))
                        .contentTransition(.numericText(value: Double(ids.count)))
                    Text(ids.compactMap { id in archive.bottles.first(where: { $0.id == id })
                        .flatMap { archive.fragrance(id: $0.fragranceID)?.name } }.joined(separator: " + "))
                        .font(.caption).foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Button { selected.removeAll(); impression = "" } label: {
                    Image(systemName: "xmark").font(.caption.weight(.bold)).frame(width: 26, height: 26)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Clear selection")
            }
            if addingNote {
                TextField("How does it wear today?", text: $impression, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(10)
                    .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            HStack(spacing: 10) {
                Button(action: log) {
                    Label(ids.count > 1 ? "Log this layer" : "Log this wear", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.glassProminent)
                .tint(accent)
                Button {
                    withAnimation(.snappy) { addingNote.toggle() }
                } label: {
                    Image(systemName: addingNote ? "text.badge.checkmark" : "text.bubble")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Add an impression")
                if ids.count > 1 {
                    Button { newLayerName = ""; namingLayer = true } label: {
                        Image(systemName: "bookmark").frame(width: 36, height: 36)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Save this layer for later")
                }
            }
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func log() {
        let ids = selectedIDs
        guard !ids.isEmpty else { return }
        stamp += 1
        archive.recordWear(bottleIDs: ids, note: impression)
        justLogged = archive.wearSessions.first?.id
        // Let the stamp land before the tray leaves.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 380))
            selected.removeAll()
            impression = ""
            addingNote = false
        }
    }

    // MARK: History

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AtelierEyebrow(text: showAll ? "Your wear history" : "Worn today", accent: accent)
                Spacer()
                Button(showAll ? "Today only" : "All history") {
                    withAnimation(.snappy) { showAll.toggle() }
                }
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
                    .transition(.asymmetric(insertion: .scale(scale: 0.92).combined(with: .opacity),
                                            removal: .opacity))
            }
            let legacy = archive.bottles.filter { $0.wears.contains(where: { $0.sessionID == nil }) }
            if showAll && !legacy.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    AtelierEyebrow(text: "Earlier solo wears", accent: accent)
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
        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.85), value: archive.wearSessions.map(\.id))
    }

    private func sessionRow(_ session: WearSession) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ComposedSet(bottleIDs: session.bottleIDs, cardWidth: 36, spread: 8)
                .frame(width: 78, height: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(session.bottleIDs.count > 1 ? "Layered · \(session.bottleIDs.count)" : "Solo wear")
                    .font(.system(.headline, design: .serif))
                Text(session.bottleIDs.compactMap { id in archive.bottles.first(where: { $0.id == id })
                    .flatMap { archive.fragrance(id: $0.fragranceID)?.name } }.joined(separator: " + "))
                    .font(.subheadline)
                    .lineLimit(2)
                Text(session.date.formatted(date: showAll ? .abbreviated : .omitted, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
                if !session.note.isEmpty {
                    Text("“\(session.note)”").font(.footnote).italic().foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Menu {
                Button("Wear again", systemImage: "arrow.clockwise") { selected = session.bottleIDs }
                ForEach(session.bottleIDs, id: \.self) { id in
                    if let bottle = archive.bottles.first(where: { $0.id == id }),
                       let scent = archive.fragrance(id: bottle.fragranceID), session.bottleIDs.count > 1 {
                        Button("Remove \(scent.name)", systemImage: "minus.circle") {
                            archive.removeBottle(id, from: session.id)
                        }
                    }
                }
                Button("Undo this wear", systemImage: "arrow.uturn.backward", role: .destructive) {
                    archive.deleteWearSession(session.id)
                }
            } label: {
                Image(systemName: "ellipsis").frame(width: 32, height: 32)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Wear options")
        }
        .padding(14)
        .atelierPlate(18)
        .overlay {
            if justLogged == session.id {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(accent.opacity(0.7), lineWidth: 1.2)
                    .allowsHitTesting(false)
            }
        }
    }
}

/// Several bottles shown as one composed set: aligned on a shared baseline, overlapped and
/// fanned symmetrically, top layer last. Re-fans with a spring as members change.
struct ComposedSet: View {
    @EnvironmentObject private var archive: CollectionStore
    let bottleIDs: [UUID]
    let cardWidth: CGFloat
    let spread: Double

    var body: some View {
        let ids = bottleIDs.filter { id in archive.bottles.contains(where: { $0.id == id }) }
        let n = ids.count
        ZStack {
            ForEach(Array(ids.enumerated()), id: \.element) { i, id in
                if let bottle = archive.bottles.first(where: { $0.id == id }) {
                    let centred = Double(i) - Double(n - 1) / 2
                    AtelierCardSurface(fragranceID: bottle.fragranceID, radius: max(3, cardWidth * 0.08), foil: .sheen)
                        .frame(width: cardWidth, height: cardWidth * 86 / 59)
                        .rotationEffect(.degrees(centred * spread), anchor: .bottom)
                        .offset(x: CGFloat(centred) * cardWidth * 0.42)
                        .zIndex(Double(i))
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: ids)
        .accessibilityHidden(true)
    }
}

// MARK: - Quick Add: capture now, details later

struct QuickAddSheet: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var name = ""
    @State private var photoData: Data?
    @State private var libraryItem: PhotosPickerItem?
    @State private var cameraOpen = false
    @State private var saving = false
    @State private var photoFailed = false
    @FocusState private var typing: Bool
    let onAdded: () -> Void

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var suggestions: [Fragrance] {
        guard trimmed.count >= 2 else { return [] }
        return Array(archive.matches(trimmed, scope: .demo).prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    preview
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    TextField("Fragrance name", text: $name)
                        .font(.title3)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($typing)
                        .onSubmit(save)
                        .padding(14)
                        .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    if !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            AtelierEyebrow(text: "In the archive", accent: archive.theme.palette.accent)
                            ForEach(suggestions) { fragrance in
                                Button { addKnown(fragrance) } label: {
                                    HStack(spacing: 12) {
                                        AtelierCardSurface(fragranceID: fragrance.id, radius: 4, shadowed: false)
                                            .frame(width: 30, height: 44)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(fragrance.name).font(.subheadline.weight(.medium))
                                            Text(fragrance.house).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(archive.theme.palette.accent)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PressableCardStyle())
                                .accessibilityLabel("Add \(fragrance.house) \(fragrance.name)")
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    HStack(spacing: 10) {
                        Button {
                            typing = false
                            cameraOpen = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .buttonStyle(.glass)
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                        PhotosPicker(selection: $libraryItem, matching: .images) {
                            Label(photoData == nil ? "Choose Photo" : "Change Photo", systemImage: "photo")
                                .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .buttonStyle(.glass)
                    }
                    if photoFailed {
                        Label("That photo could not be read. Try another, or save with the name only.",
                              systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Text("Only a name or a photo is needed. Everything stays private on this iPhone.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(20)
                .animation(reduceMotion ? nil : .snappy, value: suggestions.map(\.id))
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Label("Save to My Collection", systemImage: "checkmark")
                        .font(.headline).frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.glassProminent)
                .tint(archive.theme.palette.accent)
                .disabled((trimmed.isEmpty && photoData == nil) || saving)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
            .onAppear { typing = true }
            .onChange(of: libraryItem) { _, item in
                Task {
                    if let bytes = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: bytes) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            photoData = image.jpegData(compressionQuality: 0.84)
                        }
                        photoFailed = false
                    } else if item != nil {
                        photoFailed = true
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

    /// A live collectible preview: the card you are making, updating as you type or add a photo.
    private var preview: some View {
        let draft = Fragrance(id: "personal-preview", house: "My Collection",
                              name: trimmed.isEmpty ? "Your discovery" : trimmed,
                              concentration: "", year: "", top: [], heart: [], base: [],
                              shelf: .autumn, archival: false)
        return ZStack {
            if let photoData, let photo = UIImage(data: photoData) {
                Image(uiImage: photo)
                    .resizable().scaledToFill()
                    .frame(width: 150, height: 150 * 86 / 59)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .bottomLeading) {
                        Text(draft.name)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .accessibilityLabel("Captured bottle photograph")
            } else {
                PersonalCardArt(fragrance: draft)
                    .frame(width: 150, height: 150 * 86 / 59)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)
            }
        }
        .shadow(color: archive.theme.shadowTint.opacity(0.4), radius: 18, y: 12)
        .rotation3DEffect(.degrees(saving ? 0 : -6), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .scaleEffect(saving ? 0.6 : 1)
        .offset(y: saving ? 260 : 0)
        .opacity(saving ? 0 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.8), value: saving)
        .animation(reduceMotion ? nil : .snappy, value: trimmed)
    }

    private func addKnown(_ fragrance: Fragrance) {
        guard !saving else { return }
        saving = true
        archive.add(fragrance)
        finish()
    }

    private func save() {
        guard !saving, !trimmed.isEmpty || photoData != nil else { return }
        saving = true
        if photoData == nil,
           let known = archive.catalog.first(where: {
               $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
           }) {
            archive.add(known)
        } else {
            archive.quickAdd(name: trimmed, imageData: photoData)
        }
        finish()
    }

    private func finish() {
        typing = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 340))
            onAdded()
            dismiss()
        }
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
