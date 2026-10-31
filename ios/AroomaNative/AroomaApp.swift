import SwiftUI
import AVFoundation

@main
struct AroomaNativeApp: App {
    @StateObject private var archive = CollectionStore()

    init() {
        // The intro clips are silent; never interrupt the owner's own audio.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    var body: some Scene {
        WindowGroup {
            AtelierRoot()
                .environmentObject(archive)
                .preferredColorScheme(archive.appearance.colorScheme)
        }
    }
}

private enum AtelierTab: Hashable {
    case gallery, shelves, journal, search
}

struct AtelierRoot: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tab: AtelierTab = .gallery
    @State private var inspection: DisplayCard?
    @State private var adding = false
    @State private var styling = false
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
                tab = .gallery
            })
            .environmentObject(archive)
            .presentationDetents([.large])
        }
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            Tab("Collection", systemImage: "rectangle.stack", value: AtelierTab.gallery) {
                AtelierGallery(
                    transitionNamespace: cardSpace,
                    inspect: { card in inspection = card },
                    add: { adding = true },
                    openStyle: { styling = true },
                    showToday: { bottleID in
                        startingWearBottle = bottleID
                        tab = .journal
                    }
                )
            }
            Tab("Shelves", systemImage: "books.vertical", value: AtelierTab.shelves) {
                AtelierShelves(focus: focus, add: { adding = true })
            }
            Tab("Today", systemImage: "drop", value: AtelierTab.journal) {
                AtelierWearLog(startingBottleID: $startingWearBottle,
                               add: { adding = true }, focus: focus)
            }
            Tab(value: AtelierTab.search, role: .search) {
                AtelierSearch(focus: { card in focus(card) })
            }
        }
        .tint(archive.theme.palette.accent)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            TodayAccessory(open: { tab = .journal })
                .environmentObject(archive)
        }
    }

    /// Launch arguments used only by the CI capture script to photograph specific screens
    /// (`-AroomaQATab shelves|journal`, `-AroomaQAInspect YES`). Inert in normal use.
    private func applyQALaunchArguments() {
        let defaults = UserDefaults.standard
        switch defaults.string(forKey: "AroomaQATab") {
        case "shelves": tab = .shelves
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

    private func focus(_ card: DisplayCard) {
        if archive.mode == .mine {
            if let owned = archive.bottles.first(where: { $0.id == card.bottleID }) {
                archive.selectedMineID = owned.id
            } else if let owned = archive.bottles.first(where: { $0.fragranceID == card.fragrance.id }) {
                archive.selectedMineID = owned.id
            } else {
                archive.add(card.fragrance)
            }
        } else {
            archive.choose(DisplayCard(id: card.fragrance.id,
                                       fragrance: card.fragrance, bottleID: nil), haptic: false)
        }
        tab = .gallery
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
                    .foregroundStyle(archive.theme.palette.accent)
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
