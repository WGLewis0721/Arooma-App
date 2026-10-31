import SwiftUI

@main
struct AroomaNativeApp: App {
    @StateObject private var archive = CollectionStore()

    var body: some Scene {
        WindowGroup {
            AtelierRoot()
                .environmentObject(archive)
                .preferredColorScheme(archive.appearance.colorScheme)
        }
    }
}

private enum AtelierTab: Hashable {
    case gallery, shelves, discover, journal, atmosphere
}

struct AtelierRoot: View {
    @EnvironmentObject private var archive: CollectionStore
    @State private var tab: AtelierTab = .gallery
    @State private var inspection: DisplayCard?
    @State private var adding = false
    @Namespace private var cardSpace

    var body: some View {
        ZStack {
            AtelierAtmosphere(theme: archive.theme)
            if archive.onboarded {
                TabView(selection: $tab) {
                    Tab("Cards", systemImage: "rectangle.stack", value: AtelierTab.gallery) {
                        AtelierGallery(transitionNamespace: cardSpace, inspectedID: inspection?.id,
                            inspect: { card in
                                withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                                    inspection = card
                                }
                            }, add: { adding = true })
                    }
                    Tab("Shelves", systemImage: "square.grid.2x2", value: AtelierTab.shelves) {
                        AtelierShelves(focus: focus, add: { adding = true })
                    }
                    Tab("Search", systemImage: "magnifyingglass", value: AtelierTab.discover) {
                        AtelierSearch(focus: focus)
                    }
                    Tab("Today", systemImage: "square.and.pencil", value: AtelierTab.journal) {
                        AtelierWearLog(add: { adding = true }, focus: focus)
                    }
                    Tab("Style", systemImage: "paintpalette", value: AtelierTab.atmosphere) {
                        AtelierStyle()
                    }
                }
                .tint(archive.theme.palette.accent)
            } else {
                AtelierWelcome(
                    openDemo: { archive.mode = .demo; archive.onboarded = true },
                    openMine: { archive.mode = .mine; archive.onboarded = true }
                )
            }
            if let card = inspection {
                AtelierInspector(card: card, transitionNamespace: cardSpace, close: {
                    withAnimation(.spring(response: 0.51, dampingFraction: 0.9)) {
                        inspection = nil
                    }
                })
                .environmentObject(archive)
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .sheet(isPresented: $adding) {
            QuickAddSheet(onAdded: {
                adding = false
                tab = .gallery
            })
            .environmentObject(archive)
        }
    }

    private func focus(_ card: DisplayCard) {
        if archive.mode == .mine {
            if let owned = archive.bottles.first(where: { $0.id == card.bottleID }) {
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
