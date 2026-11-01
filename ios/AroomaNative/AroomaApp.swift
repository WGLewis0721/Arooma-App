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

/// The three bottom tabs (Native Navigation V3), in this order. Explore is the sample deck. My Collection
/// holds owned bottles, the Wishlist view, Shelves and the Wear log (wear, layering, history). Search is the
/// existing scoped catalog search. There is no Today tab and no Cards tab.
private enum AtelierTab: Hashable {
    case explore, myCollection, search
}

struct AtelierRoot: View {
    @EnvironmentObject private var archive: CollectionStore
    @EnvironmentObject private var commerce: CardCommerce
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: AtelierTab = .explore
    @State private var inspection: DisplayCard?
    @State private var adding = false
    /// The tab that opened Quick Add. A normal save returns here (item 05).
    @State private var addOrigin: AtelierTab = .explore
    @State private var styling = false
    @State private var showingShelves = false
    @State private var showingWearLog = false
    @State private var startingWearBottle: UUID?
    // My Collection quick actions (press and hold the tab).
    @State private var quickActionsShown = false
    @State private var quickActionsAnchor: CGRect?
    /// While a hold is in progress, the tab that was selected when it began. A hold must never select
    /// My Collection as a side effect, so any change it causes is reverted.
    @State private var holdTabSnapshot: AtelierTab?
    @State private var holdGuardUntil = Date.distantPast
    @State private var wearToast: WearToastModel?
    @Namespace private var cardSpace

    var body: some View {
        ZStack {
            AtelierAtmosphere(theme: archive.theme)
            if archive.onboarded {
                tabBar
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
        .overlay(alignment: .bottom) { wearToastLayer }
        .overlay { quickActionsLayer }
        .onAppear {
            // A returning user may have last used My Collection. Explore must still open the sample deck.
            alignMode(with: tab)
            applyQALaunchArguments()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { dismissQuickActions() }
        }
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
        // Wear, layering, saved combinations and history: the existing wear log, now a part of My Collection.
        .sheet(isPresented: $showingWearLog) {
            NavigationStack {
                AtelierWearLog(startingBottleID: $startingWearBottle,
                               add: closeWearLogThenAdd,
                               focus: focus)
                    .navigationTitle("Wear log")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done", systemImage: "checkmark") { showingWearLog = false }
                        }
                    }
            }
            .environmentObject(archive)
        }
    }

    // MARK: Tabs

    private var tabBar: some View {
        TabView(selection: $tab) {
            Tab("Explore", systemImage: "sparkles", value: AtelierTab.explore) {
                AtelierGallery(
                    context: .explore,
                    transitionNamespace: cardSpace,
                    inspect: { card in inspection = card },
                    add: { startAdd(from: .explore) },
                    openStyle: { styling = true },
                    showToday: { openWearLog($0) }
                )
            }
            Tab("My Collection", systemImage: "rectangle.stack", value: AtelierTab.myCollection) {
                MyCollectionScreen(
                    transitionNamespace: cardSpace,
                    inspect: { card in inspection = card },
                    add: { startAdd(from: .myCollection) },
                    openShelves: { showingShelves = true },
                    openWearLog: { openWearLog($0) },
                    quickActions: { presentQuickActions(anchor: nil) }
                )
            }
            Tab("Search", systemImage: "magnifyingglass", value: AtelierTab.search) {
                SearchTabScreen()
            }
        }
        .legibleTint(archive.theme.palette.accent)
        .tabBarMinimizeBehavior(.onScrollDown)
        // Press and hold the real My Collection tab item (a UIKit hook; the system tab bar is not replaced).
        .background {
            TabBarHoldRecognizer(tabTitle: "My Collection", tabCount: 3, tabIndex: 1,
                                 began: { beginHold($0) }, ended: { endHold() })
        }
        .onChange(of: tab) { _, selected in tabChanged(to: selected) }
    }

    private func tabChanged(to selected: AtelierTab) {
        // A press and hold on My Collection must not select it as a side effect.
        if Date() < holdGuardUntil, let snapshot = holdTabSnapshot, selected != snapshot {
            tab = snapshot
            return
        }
        alignMode(with: selected)
    }

    /// Each tab owns its data context. Explore is always the sample deck. My Collection shows owned or
    /// Wishlist records and keeps the view last chosen there. Search reads every record and changes none.
    /// Switching tabs never edits saved records.
    private func alignMode(with selected: AtelierTab) {
        switch selected {
        case .explore:
            if archive.mode != .demo { archive.enter(.demo) }
        case .myCollection:
            if archive.mode == .demo { archive.enter(.mine) }
            archive.syncOwnedFocus()
        case .search:
            break
        }
    }

    // MARK: Quick actions

    private func beginHold(_ itemFrame: CGRect) {
        holdTabSnapshot = tab
        holdGuardUntil = .distantFuture
        presentQuickActions(anchor: itemFrame)
    }

    private func endHold() {
        // Keep the guard a moment after the finger lifts, in case the system selects the tab on touch-up.
        holdGuardUntil = Date().addingTimeInterval(0.8)
    }

    private func presentQuickActions(anchor: CGRect?) {
        quickActionsAnchor = anchor
        withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.34, dampingFraction: 0.82)) {
            quickActionsShown = true
        }
        HapticEngine.shared.play(.selection)
    }

    private func dismissQuickActions() {
        guard quickActionsShown else { return }
        holdGuardUntil = .distantPast
        withAnimation(reduceMotion ? .easeInOut(duration: 0.12) : .spring(response: 0.3, dampingFraction: 0.9)) {
            quickActionsShown = false
        }
    }

    @ViewBuilder private var quickActionsLayer: some View {
        if quickActionsShown {
            GeometryReader { geo in
                let origin = geo.frame(in: .global)
                let width = QuickActionsColumn.width
                let height = QuickActionsColumn.height
                let centerX = quickActionsAnchor.map { $0.midX - origin.minX } ?? geo.size.width / 2
                let x = min(max(centerX, 12 + width / 2), geo.size.width - 12 - width / 2)
                let bottom = quickActionsAnchor.map { $0.minY - origin.minY - 14 } ?? geo.size.height - 130
                ZStack {
                    Color.black.opacity(0.14)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { dismissQuickActions() }
                        .accessibilityHidden(true)
                    QuickActionsColumn(
                        wear: archive.quickWearAvailability,
                        wishlist: quickWishlist,
                        add: quickAdd,
                        wearNow: quickWear,
                        dismiss: dismissQuickActions
                    )
                    .position(x: x, y: bottom - height / 2)
                    .transition(.scale(scale: 0.92, anchor: .bottom).combined(with: .opacity))
                }
            }
            .transition(.opacity)
        }
    }

    /// Wishlist: straight to My Collection's Wishlist view. No intermediate menu, no demo-mode switch.
    private func quickWishlist() {
        dismissQuickActions()
        archive.enter(.wishlist)
        tab = .myCollection
    }

    /// Add: the existing Quick Add sheet, in My Collection's context. Saving or closing returns to My Collection.
    private func quickAdd() {
        dismissQuickActions()
        tab = .myCollection
        startAdd(from: .myCollection)
    }

    /// Wear: logs today's wear for the owner-selected OWNED bottle at once. No navigation, no sheet, no
    /// selection step. Availability is resolved again here, at the moment of the tap, so a repeated press
    /// finds the bottle already worn and cannot create a second session.
    private func quickWear() {
        dismissQuickActions()
        guard case .ready(let bottleID, let name) = archive.quickWearAvailability,
              let session = archive.recordWear(bottleIDs: [bottleID]) else { return }
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85)) {
            wearToast = WearToastModel(sessionID: session, name: name)
        }
        AccessibilityNotification.Announcement("Worn today. \(name)").post()
    }

    @ViewBuilder private var wearToastLayer: some View {
        if let toast = wearToast {
            WearToastView(model: toast) { undoWear(toast) }
                .padding(.horizontal, 20)
                .padding(.bottom, 88)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: toast.id) {
                    try? await Task.sleep(for: .seconds(Self.wearToastSeconds))
                    guard !Task.isCancelled, wearToast?.id == toast.id else { return }
                    withAnimation { wearToast = nil }
                }
        }
    }

    /// How long the confirmation stays: 6 s. QA builds can lengthen it with the same
    /// `-AroomaQAUndoWindow <seconds>` launch argument the Quick Add flows use (Debug and TestFlight only).
    private static var wearToastSeconds: Double {
        guard BuildChannel.allowsOwnerTools else { return 6 }
        let override = UserDefaults.standard.double(forKey: "AroomaQAUndoWindow")
        return override > 0 ? override : 6
    }

    /// Undo reverses ONLY the session this press created, never another bottle's wear or a layered session.
    private func undoWear(_ toast: WearToastModel) {
        archive.deleteWearSession(toast.sessionID)
        withAnimation(reduceMotion ? nil : .snappy) { wearToast = nil }
    }

    // MARK: Routes

    private func startAdd(from origin: AtelierTab) {
        addOrigin = origin
        adding = true
    }

    /// Opens the Wear log sheet, optionally with one bottle already chosen (Layer on a focused card).
    private func openWearLog(_ bottleID: UUID?) {
        startingWearBottle = bottleID
        showingWearLog = true
    }

    /// The wear log's "Add a bottle": close it first, then open Quick Add (one sheet at a time).
    private func closeWearLogThenAdd() {
        showingWearLog = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            startAdd(from: .myCollection)
        }
    }

    /// Launch arguments used only by the CI capture script to photograph specific screens
    /// (`-AroomaQATab shelves|wear|collection|search|quickactions`, `-AroomaQAInspect YES`). Inert in normal use.
    /// `quickactions` shows the column directly (it does NOT exercise the tab-bar hold).
    private func applyQALaunchArguments() {
        let defaults = UserDefaults.standard
        switch defaults.string(forKey: "AroomaQATab") {
        case "shelves": showingShelves = true
        case "journal", "today", "wear": showingWearLog = true
        case "collection": tab = .myCollection
        case "search": tab = .search
        case "quickactions":
            tab = .myCollection
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.0))
                presentQuickActions(anchor: nil)
            }
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

    /// Brings a card to the front in its deck and shows My Collection (the wear log's session links).
    /// Never changes ownership: a catalog fragrance you don't own stays in the sample archive.
    private func focus(_ card: DisplayCard) {
        select(card)
        showingWearLog = false
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

/// Search, the third tab. A result opens its Inspector from inside this screen, so closing the Inspector
/// returns to the same query, scopes, filters and sort. It changes no selection and no saved record.
struct SearchTabScreen: View {
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

/// My Collection (Native Navigation V3). Owned bottles are the default view; the Wishlist is a view inside
/// this tab, not a tab. The signature sits at the upper left beside the Owned/Wishlist control. Shelves, the
/// Wear log and Add are labelled controls in the lower area, below the card and its notes.
struct MyCollectionScreen: View {
    @EnvironmentObject private var archive: CollectionStore
    let transitionNamespace: Namespace.ID
    let inspect: (DisplayCard) -> Void
    let add: () -> Void
    let openShelves: () -> Void
    let openWearLog: (UUID?) -> Void
    let quickActions: () -> Void

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
                AroomaBrandMark()
                Spacer(minLength: 8)
                Picker("Collection view", selection: viewChoice) {
                    Text("Owned").tag(0)
                    Text("Wishlist").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 190)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            AtelierGallery(
                context: .collection,
                transitionNamespace: transitionNamespace,
                inspect: inspect,
                add: add,
                openStyle: {},
                showToday: { openWearLog($0) },
                quickActions: quickActions
            )
            tools
        }
    }

    /// Distinct labelled controls, low on the screen. Hidden while the deck is empty, where the empty state's
    /// own button is the single Add.
    @ViewBuilder private var tools: some View {
        if !archive.displayedCards.isEmpty {
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    if archive.mode == .mine {
                        toolButton("Shelves", symbol: "square.grid.2x2", id: "all-shelves", action: openShelves)
                        toolButton("Wear log", symbol: "clock.arrow.circlepath", id: "wear-log") { openWearLog(nil) }
                    }
                    toolButton("Add", symbol: "plus", id: "quick-add-a-bottle", action: add)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private func toolButton(_ title: String, symbol: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.footnote.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.glass)
        .accessibilityIdentifier(id)
    }
}
