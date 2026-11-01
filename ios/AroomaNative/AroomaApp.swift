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

/// The three bottom tabs (Native Navigation V2). Explore is the sample deck with its search. Today is
/// the wear log. My Collection holds owned bottles, the Wishlist view, Shelves and My Cards.
private enum AtelierTab: Hashable {
    case explore, today, myCollection
}

struct AtelierRoot: View {
    @EnvironmentObject private var archive: CollectionStore
    @EnvironmentObject private var commerce: CardCommerce
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tab: AtelierTab = .explore
    @State private var inspection: DisplayCard?
    @State private var adding = false
    /// The tab that opened Quick Add. A normal save returns here (item 05).
    @State private var addOrigin: AtelierTab = .explore
    @State private var styling = false
    @State private var searching = false
    @State private var showingShelves = false
    @State private var showingMyCards = false
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
        .sheet(isPresented: $searching) {
            // Search belongs to Explore, not to a tab. A result opens its Inspector from inside this sheet,
            // so closing the Inspector returns to the same query, scopes, filters and sort.
            ExploreSearchSheet()
                .environmentObject(archive)
                .presentationDragIndicator(.visible)
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
        // The one editable shelf surface, reached from My Collection (one action).
        .sheet(isPresented: $showingShelves) {
            NavigationStack {
                AtelierShelves(focus: { card in
                    select(card)
                    showingShelves = false
                    tab = .myCollection
                }, add: { startAdd(from: .myCollection) })
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
        // Digital cards and Card Studio: a secondary destination of My Collection, not a tab.
        .sheet(isPresented: $showingMyCards) {
            MyCardsScreen(openLiveArchive: openLiveArchive)
                .environmentObject(archive)
                .environmentObject(commerce)
        }
    }

    private var tabs: some View {
        withTodayAccessory(tabBar)
    }

    private var tabBar: some View {
        TabView(selection: $tab) {
            Tab("Explore", systemImage: "sparkles", value: AtelierTab.explore) {
                AtelierGallery(
                    context: .explore,
                    transitionNamespace: cardSpace,
                    inspect: { card in inspection = card },
                    add: { startAdd(from: .explore) },
                    openSearch: { searching = true },
                    openStyle: { styling = true },
                    showToday: openToday
                )
            }
            Tab("Today", systemImage: "drop", value: AtelierTab.today) {
                AtelierWearLog(startingBottleID: $startingWearBottle,
                               add: { startAdd(from: .today) }, focus: focus)
            }
            Tab("My Collection", systemImage: "rectangle.stack", value: AtelierTab.myCollection) {
                MyCollectionScreen(
                    transitionNamespace: cardSpace,
                    inspect: { card in inspection = card },
                    add: { startAdd(from: .myCollection) },
                    openShelves: { showingShelves = true },
                    openMyCards: { showingMyCards = true },
                    showToday: openToday
                )
            }
        }
        .legibleTint(archive.theme.palette.accent)
        .tabBarMinimizeBehavior(.onScrollDown)
        .onChange(of: tab) { _, selected in alignMode(with: selected) }
    }

    /// The Today shortcut appears only in My Collection's owned view. It is hidden on Explore, where the
    /// sample deck never logs wears (annotation A9), and on Today itself (item 08).
    @ViewBuilder private func withTodayAccessory<Content: View>(_ content: Content) -> some View {
        let visible = tab == .myCollection && archive.mode == .mine
        if #available(iOS 26.1, *) {
            content.tabViewBottomAccessory(isEnabled: visible) {
                TodayAccessory(open: { tab = .today }).environmentObject(archive)
            }
        } else {
            content.tabViewBottomAccessory {
                if visible {
                    TodayAccessory(open: { tab = .today }).environmentObject(archive)
                }
            }
        }
    }

    /// Each tab owns its data context. Explore is always the sample deck. My Collection shows owned or
    /// Wishlist records and keeps the view last chosen there. Today reads owned records only.
    /// Switching tabs never edits saved records.
    private func alignMode(with selected: AtelierTab) {
        switch selected {
        case .explore:
            if archive.mode != .demo { archive.enter(.demo) }
        case .myCollection:
            if archive.mode == .demo { archive.enter(.mine) }
        case .today:
            break
        }
    }

    private func startAdd(from origin: AtelierTab) {
        addOrigin = origin
        adding = true
    }

    /// Opens Today, optionally with one bottle already selected (from Layer in My Collection).
    private func openToday(_ bottleID: UUID) {
        startingWearBottle = bottleID
        tab = .today
    }

    /// My Cards' Autumn entry opens the sample deck at its first autumn fragrance in Explore.
    private func openLiveArchive() {
        showingMyCards = false
        archive.enter(.demo)
        archive.selectedDemoID = Fall2026Collection.fragrances.first?.id ?? "dior"
        tab = .explore
    }

    /// Launch arguments used only by the CI capture script to photograph specific screens
    /// (`-AroomaQATab shelves|journal|collection|search`, `-AroomaQAInspect YES`). Inert in normal use.
    private func applyQALaunchArguments() {
        let defaults = UserDefaults.standard
        switch defaults.string(forKey: "AroomaQATab") {
        case "shelves": showingShelves = true
        case "journal", "today": tab = .today
        case "collection": tab = .myCollection
        case "search": searching = true
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
        // "Start My Collection" lands on the owned deck; "Explore the Archive" lands on the sample deck.
        tab = mode == .mine ? .myCollection : .explore
        withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.9)) {
            archive.onboarded = true
        }
        HapticEngine.shared.play(.completed)
    }

    /// Brings a card to the front in its deck and shows My Collection (Today's session links).
    /// Never changes ownership: a catalog fragrance you don't own stays in the sample archive.
    private func focus(_ card: DisplayCard) {
        select(card)
        tab = .myCollection
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

/// Search, presented from Explore (plan section 2). Results open the Inspector from inside this sheet,
/// so closing the Inspector returns to the same Search state.
struct ExploreSearchSheet: View {
    @EnvironmentObject private var archive: CollectionStore
    @State private var inspection: DisplayCard?

    var body: some View {
        AtelierSearch(focus: { card in inspection = card })
            .fullScreenCover(item: $inspection) { card in
                AtelierInspector(card: card, close: { inspection = nil })
                    .environmentObject(archive)
            }
    }
}

/// My Collection (Native Navigation V2). Owned bottles are the default view; the Wishlist is a view
/// inside this tab, not a tab. Shelves, My Cards and Quick Add are one action each.
struct MyCollectionScreen: View {
    @EnvironmentObject private var archive: CollectionStore
    let transitionNamespace: Namespace.ID
    let inspect: (DisplayCard) -> Void
    let add: () -> Void
    let openShelves: () -> Void
    let openMyCards: () -> Void
    let showToday: (UUID) -> Void

    /// 0 = owned, 1 = Wishlist. Changing it changes the data context, never the saved records.
    private var viewChoice: Binding<Int> {
        Binding(
            get: { archive.mode == .wishlist ? 1 : 0 },
            set: { archive.enter($0 == 1 ? .wishlist : .mine) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Picker("Collection view", selection: viewChoice) {
                    Text("Owned").tag(0)
                    Text("Wishlist").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 230)
                Spacer(minLength: 4)
                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        headerButton("square.grid.2x2", label: "All shelves", action: openShelves)
                        headerButton("rectangle.portrait.on.rectangle.portrait", label: "My Cards", action: openMyCards)
                        headerButton("plus", label: "Quick add a bottle", action: add)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            AtelierGallery(
                context: .collection,
                transitionNamespace: transitionNamespace,
                inspect: inspect,
                add: add,
                openSearch: {},
                openStyle: {},
                showToday: showToday
            )
        }
    }

    private func headerButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 30, height: 30)
        }
        .accessibilityIdentifier(label.lowercased().replacingOccurrences(of: " ", with: "-"))
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }
}

/// iOS 26 tab bar accessory: today's ritual is one tap away from My Collection's owned view.
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
                if todays.isEmpty {
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
