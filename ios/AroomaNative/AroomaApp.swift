import SwiftUI

@main
struct AroomaNativeApp: App {
    @StateObject private var archive = CollectionStore()
    var body: some Scene {
        WindowGroup {
            ArchiveRoot()
                .environmentObject(archive)
                .preferredColorScheme(archive.appearance.colorScheme)
        }
    }
}

private enum ArchiveTab: Hashable {
    case cards, shelves, search, bottle, style
}

struct ArchiveRoot: View {
    @EnvironmentObject private var archive: CollectionStore
    @State private var tab: ArchiveTab = .cards
    @State private var inspected: DisplayCard?
    @State private var showAdd = false

    var body: some View {
        ZStack {
            ArchiveBackdrop(theme: archive.theme)
            if archive.onboarded {
                TabView(selection: $tab) {
                    Tab("Cards", systemImage: "rectangle.stack", value: ArchiveTab.cards) {
                        GalleryView(openInspector: { inspected = $0 }, openAdd: { showAdd = true })
                    }
                    Tab("Shelves", systemImage: "square.grid.2x2", value: ArchiveTab.shelves) {
                        ShelfScreen(open: focusCard)
                    }
                    Tab("Search", systemImage: "magnifyingglass", value: ArchiveTab.search) {
                        DiscoveryScreen(open: focusCard)
                    }
                    Tab("My Bottle", systemImage: "drop", value: ArchiveTab.bottle) {
                        MyBottleScreen(openAdd: { showAdd = true })
                    }
                    Tab("Style", systemImage: "paintpalette", value: ArchiveTab.style) {
                        StyleScreen()
                    }
                }
                .tint(archive.theme.palette.accent)
            } else {
                WelcomeScreen(
                    openDemo: { archive.mode = .demo; archive.onboarded = true },
                    openMine: { archive.mode = .mine; archive.onboarded = true }
                )
            }
        }
        .fullScreenCover(item: $inspected) { card in
            InspectorScreen(card: card, close: { inspected = nil })
                .environmentObject(archive)
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                DiscoveryScreen(open: { card in
                    archive.add(card.fragrance)
                    showAdd = false
                    tab = .cards
                }, addMode: true)
            }
            .environmentObject(archive)
        }
    }

    private func focusCard(_ card: DisplayCard) {
        // Catalog choices from Search or Shelves keep their identity when moved into Cards.
        if archive.mode == .mine && card.bottleID == nil {
            archive.add(card.fragrance)
        } else {
            archive.choose(card, haptic: false)
        }
        tab = .cards
    }
}
