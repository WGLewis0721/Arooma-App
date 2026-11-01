import SwiftUI

@main
struct AroomaNativeApp: App {
    @StateObject private var archive = CollectionStore()
    @StateObject private var commerce = CardCommerce()

    init() {
        // Load and apply owner tuning before any view or motor reads a physics constant.
        Tuning.shared.applyAll()
    }

    var body: some Scene {
        WindowGroup {
            AtelierRoot()
                .environmentObject(archive)
                .environmentObject(commerce)
                .task { await commerce.start() }
                .preferredColorScheme(archive.appearance.colorScheme)
        }
    }
}

private enum AtelierTab: Hashable {
    case gallery, journal, cards, search
}

struct AtelierRoot: View {
    @EnvironmentObject private var archive: CollectionStore
    @EnvironmentObject private var commerce: CardCommerce
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tab: AtelierTab = .gallery
    @State private var inspection: DisplayCard?
    @State private var adding = false
    /// The tab that opened Quick Add. A normal save returns here (item 05).
    @State private var addOrigin: AtelierTab = .gallery
    @State private var styling = false
    @State private var showingShelves = false
    @State private var startingWearBottle: UUID?
    @Namespace private var cardSpace

    var body: some View {
        ZStack {
            AtelierAtmosphere(theme: archive.theme)
            if archive.onboarded {
                tabs
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.04)),
                                            removal: .opacity))
            } else {
                AtelierWelcome(
                    openDemo: { finishWelcome(.demo) },
                    openMine: { finishWelcome(.mine) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .overlay(alignment: .top) { FramePacingHUD().padding(.top, 2) }
        .onAppear(perform: applyQALaunchArguments)
        .fullScreenCover(item: $inspection) { card in
            AtelierInspector(card: card, close: { inspection = nil })
                .environmentObject(archive)
                .navigationTransition(.zoom(sourceID: card.id, in: cardSpace))
        }
        .sheet(isPresented: $styling) {
            NavigationStack {
                AtelierStyle()
                    .navigationTitle("View & Style")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done", systemImage: "checkmark") { styling = false }
                        }
                    }
            }
            .environmentObject(archive)
            // Half height, gallery still live behind it: switching layouts visibly morphs the deck.
            .presentationDetents([.medium, .large])
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
        .sheet(isPresented: $adding) {
            QuickAddSheet(onAdded: {
                adding = false
                // Return to the screen the user came from; never a forced detour (item 05).
                tab = addOrigin
            })
            .environmentObject(archive)
            .presentationDetents([.large])
        }
        // The one editable shelf surface, one tap from Collection (item 03). Replaces the
        // separate top-level Shelves tab, which was retired after this surface took over its actions.
        .sheet(isPresented: $showingShelves) {
            NavigationStack {
                AtelierShelves(focus: { card in
                    select(card)
                    showingShelves = false
                    tab = .gallery
                }, add: { startAdd(from: .gallery) })
                .navigationTitle("Shelves")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done", systemImage: "checkmark") { showingShelves = false }
                    }
                }
            }
            .environmentObject(archive)
            .environmentObject(commerce)
        }
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            Tab("Collection", systemImage: "rectangle.stack", value: AtelierTab.gallery) {
                AtelierGallery(
                    transitionNamespace: cardSpace,
                    inspect: { card in inspection = card },
                    add: { startAdd(from: .gallery) },
                    openStyle: { styling = true },
                    openShelves: { showingShelves = true },
                    showToday: { bottleID in
                        startingWearBottle = bottleID
                        tab = .journal
                    }
                )
            }
            Tab("Today", systemImage: "drop", value: AtelierTab.journal) {
                AtelierWearLog(startingBottleID: $startingWearBottle,
                               add: { startAdd(from: .journal) }, focus: focus)
            }
            Tab("Cards", systemImage: "rectangle.portrait.on.rectangle.portrait", value: AtelierTab.cards) {
                MyCardsScreen(openLiveArchive: {
                    archive.enter(.demo)
                    archive.selectedDemoID = Fall2026Collection.fragrances.first?.id ?? "dior"
                    tab = .gallery
                })
            }
            Tab(value: AtelierTab.search, role: .search) {
                // A result opens its Inspector directly; Close returns to Search with query and filters kept (item 01).
                AtelierSearch(focus: { card in
                    select(card)
                    inspection = card
                })
            }
        }
        .legibleTint(archive.theme.palette.accent)
        .tabBarMinimizeBehavior(.onScrollDown)
        // The accessory links to Today; it is hidden while Today is the selected tab so it never links to itself (item 08).
        .tabViewBottomAccessory(isEnabled: tab != .journal) {
            TodayAccessory(open: { tab = .journal })
                .environmentObject(archive)
        }
    }

    private func startAdd(from origin: AtelierTab) {
        addOrigin = origin
        adding = true
    }

    /// Launch arguments used only by the CI capture script to photograph specific screens
    /// (`-AroomaQATab shelves|journal`, `-AroomaQAInspect YES`). Inert in normal use.
    private func applyQALaunchArguments() {
        let defaults = UserDefaults.standard
        switch defaults.string(forKey: "AroomaQATab") {
        case "shelves": showingShelves = true
        case "journal": tab = .journal
        default: break
        }
        if defaults.bool(forKey: "AroomaQAInspect"), archive.onboarded, let card = archive.selected {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.8))
                inspection = card
            }
        }
    }

    private func finishWelcome(_ mode: CollectionMode) {
        archive.mode = mode
        withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.9)) {
            archive.onboarded = true
        }
        HapticEngine.shared.play(.completed)
    }

    /// Brings a card to the front in the deck that holds it. Never changes ownership: a catalog
    /// fragrance you don't own opens in the sample archive instead of being added.
    /// Brings a card to the front in the deck that holds it, and shows the Collection tab.
    private func focus(_ card: DisplayCard) {
        select(card)
        tab = .gallery
    }

    /// Selects a card in the right collection without changing tabs.
    private func select(_ card: DisplayCard) {
        let f = card.fragrance.id
        let ownedID = card.bottleID ?? archive.bottles.first(where: { $0.fragranceID == f })?.id
        let wishID = card.wishID ?? archive.wishlist.first(where: { $0.fragranceID == f })?.id
        if card.bottleID == nil, card.wishID == nil, archive.mode == .demo,
           Fragrance.catalog.contains(where: { $0.id == f }) {
            archive.selectedDemoID = f
        } else if card.wishID == nil, let ownedID {
            archive.mode = .mine
            archive.selectedMineID = ownedID
        } else if let wishID {
            archive.mode = .wishlist
            archive.selectedWishID = wishID
        } else if Fragrance.catalog.contains(where: { $0.id == f }) {
            archive.mode = .demo
            archive.selectedDemoID = f
        }
    }
}

/// iOS 26 tab bar accessory: today's ritual is always one tap away from any tab.
struct TodayAccessory: View {
    @EnvironmentObject private var archive: CollectionStore
    let open: () -> Void
    private var todays: [Fragrance] {
        guard let session = archive.wearSessions.first(where: { Calendar.current.isDateInToday($0.date) }) else { return [] }
        return session.bottleIDs.compactMap { id in
            archive.bottles.first(where: { $0.id == id }).flatMap { archive.fragrance(id: $0.fragranceID) }
        }
    }
    var body: some View {
        Button(action: open) {
            HStack(spacing: 10) {
                Image(systemName: todays.isEmpty ? "drop" : "checkmark.seal.fill")
                    .legibleForeground(archive.theme.palette.accent)
                    .contentTransition(.symbolEffect(.replace))
                if archive.mode == .demo {
                    Text("Sample archive · log wears in My Collection")
                } else if todays.isEmpty {
                    Text("What are you wearing today?")
                } else {
                    Text("Wearing \(todays.map(\.name).joined(separator: " + "))")
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            .font(.footnote.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens Today")
    }
}
