import SwiftUI

// The deck has ONE continuous position. Gesture updates, transforms and spring settling
// share that position; changing the selected identity never rebases an active gesture.
struct AtelierGallery: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var deckPosition: CGFloat = 0
    @State private var dragStart: CGFloat?
    @State private var isDragging = false
    @State private var pinchScale: CGFloat = 1
    @State private var pinching = false
    @State private var ignoreDragRelease = false
    @State private var shelfOverview = false
    @AppStorage("arooma.deckTipV2") private var understoodDeck = false

    let transitionNamespace: Namespace.ID
    let inspectedID: String?
    let inspect: (DisplayCard) -> Void
    let add: () -> Void
    let openSearch: () -> Void
    let openStyle: () -> Void
    let showToday: (UUID) -> Void

    private var cards: [DisplayCard] { archive.displayedCards }
    private var active: DisplayCard? { archive.selected }
    private var accent: Color { archive.theme.palette.accent }
    private var activeIndex: Int {
        cards.firstIndex(where: { $0.id == active?.id }) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 21)
                .padding(.top, 8)
            if cards.isEmpty {
                Spacer()
                AtelierEmptyState(
                    title: "A collection starts with one bottle.",
                    detail: "Capture a name or a photo in seconds. Make it yours later.",
                    action: "Add a fragrance", callback: add, accent: accent
                )
                Spacer()
            } else {
                shelfBar
                    .padding(.horizontal, 23)
                    .padding(.top, 17)
                stage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                selectedIdentity
                    .padding(.horizontal, 25)
                    .padding(.top, 3)
                bottomAction
                    .padding(.horizontal, 22)
                    .padding(.top, 17)
                    .padding(.bottom, 16)
            }
        }
        .background(AtelierAtmosphere(theme: archive.theme))
        .overlay {
            if shelfOverview {
                overview
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .zIndex(30)
            }
        }
        .onAppear {
            synchronizeSelection(animated: false)
            if scenePhase == .active { FoilMotion.shared.start() }
        }
        .onDisappear { FoilMotion.shared.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && !shelfOverview { FoilMotion.shared.start() }
            else { FoilMotion.shared.stop() }
        }
        .onChange(of: archive.mode) { _, _ in synchronizeSelection(animated: false) }
        .onChange(of: archive.selectedID) { _, _ in
            if !isDragging && !pinching { synchronizeSelection(animated: true) }
        }
        .onChange(of: cards.map(\.id)) { _, _ in
            if !isDragging { synchronizeSelection(animated: false) }
        }
        .onChange(of: shelfOverview) { _, showing in
            if showing { FoilMotion.shared.stop() }
            else if scenePhase == .active { FoilMotion.shared.start() }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("AROOMA")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .tracking(3.5)
                Text("THE PRIVATE FRAGRANCE CABINET")
                    .font(.system(size: 8.5, weight: .medium))
                    .tracking(1.65)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 5)
            headerButton("magnifyingglass", label: "Search fragrances", action: openSearch)
            headerButton("plus", label: "Quick add a bottle", action: add)
            headerButton("slider.horizontal.3", label: "View and appearance options", action: openStyle)
        }
    }

    private func headerButton(_ symbol: String, label: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 44, height: 46)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel(label)
    }

    private var shelfBar: some View {
        HStack(spacing: 9) {
            Menu {
                Button("My collection", systemImage: "square.stack") { archive.enter(.mine) }
                Button("Explore sample cards", systemImage: "sparkles") { archive.enter(.demo) }
            } label: {
                HStack(spacing: 5) {
                    Text(archive.mode == .mine ? "MY COLLECTION" : "SAMPLE COLLECTION")
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
                }
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(accent)
                .frame(minHeight: 44)
            }
            Spacer()
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.88)) {
                    shelfOverview = true
                }
            } label: {
                Label("All shelves", systemImage: "square.grid.2x2")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
    }

    private var stage: some View {
        GeometryReader { geo in
            let w = max(140, min(geo.size.width * 0.76,
                                  (geo.size.height - 37) * (59.0 / 86.0), 339))
            let stride = w * 0.73
            ZStack {
                Ellipse()
                    .fill(.black.opacity(0.20))
                    .frame(width: w * 0.93, height: 24)
                    .blur(radius: 19)
                    .offset(y: w * 0.76)
                    .accessibilityHidden(true)

                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    let distance = CGFloat(index) - deckPosition
                    if abs(distance) < 3.0 {
                        cardAt(card, index: index, distance: distance, width: w)
                            .zIndex(100 - Double(abs(distance) * 10))
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .overlay(alignment: .bottom) {
                if !understoodDeck {
                    HStack(spacing: 7) {
                        Image(systemName: "hand.draw")
                        Text("SWIPE TO BROWSE · TAP TO INSPECT")
                    }
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.7)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 12)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, 2)
                    .allowsHitTesting(false)
                }
            }
            .scaleEffect(pinchScale)
            .contentShape(Rectangle())
            .highPriorityGesture(dragGesture(stride: stride))
            .simultaneousGesture(
                MagnifyGesture(minimumScaleDelta: 0.025)
                    .onChanged { gesture in
                        pinching = true
                        if !understoodDeck { understoodDeck = true }
                        pinchScale = max(0.79, min(1, gesture.magnification))
                    }
                    .onEnded { gesture in
                        if gesture.magnification < 0.88 {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.44, dampingFraction: 0.88)) {
                                shelfOverview = true
                            }
                        }
                        withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.88)) {
                            pinchScale = 1
                        }
                        dragStart = nil
                        isDragging = false
                        ignoreDragRelease = true
                        pinching = false
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(350))
                            ignoreDragRelease = false
                        }
                    }
            )
            .accessibilityAction(named: "Previous card") { moveBy(-1) }
            .accessibilityAction(named: "Next card") { moveBy(1) }
            .accessibilityAction(named: "See every shelf") {
                withAnimation { shelfOverview = true }
            }
        }
    }

    private func dragGesture(stride: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { gesture in
                guard !pinching && !shelfOverview else { return }
                if dragStart == nil { dragStart = deckPosition }
                if !understoodDeck { understoodDeck = true }
                isDragging = true
                let start = dragStart ?? deckPosition
                let proposed = start - gesture.translation.width / max(1, stride)
                // Resist the ends instead of letting the first or last card slide out of frame.
                let maximum = CGFloat(max(0, cards.count - 1))
                let bounded = proposed < 0 ? proposed * 0.12 :
                    (proposed > maximum ? maximum + (proposed - maximum) * 0.12 : proposed)
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) { deckPosition = bounded }
            }
            .onEnded { gesture in
                guard !pinching && !shelfOverview && !ignoreDragRelease else {
                    dragStart = nil
                    isDragging = false
                    ignoreDragRelease = false
                    synchronizeSelection(animated: true)
                    return
                }
                let start = Int((dragStart ?? deckPosition).rounded())
                let moved = abs(gesture.translation.width)
                let projected = abs(gesture.predictedEndTranslation.width)
                let crossed = moved > stride * 0.21 || projected > stride * 0.48
                let direction = gesture.translation.width < 0 ? 1 : -1
                let target = max(0, min(cards.count - 1, start + (crossed ? direction : 0)))
                dragStart = nil
                isDragging = false
                settle(at: target)
            }
    }

    private func cardAt(_ card: DisplayCard, index: Int,
                        distance: CGFloat, width: CGFloat) -> some View {
        let magnitude = abs(distance)
        let isFocused = magnitude < 0.45
        let x: CGFloat
        let y: CGFloat
        let yaw: Double
        let roll: Double
        let scale: CGFloat
        switch archive.layout {
        case .coverFlow:
            x = distance * width * 0.72
            y = min(magnitude, 2) * 9
            yaw = Double(-distance * 30)
            roll = 0
            scale = max(0.72, 1 - magnitude * 0.14)
        case .stack:
            x = distance * width * 0.14
            y = min(magnitude, 2) * 23
            yaw = Double(distance * 3)
            roll = Double(distance * 2)
            scale = max(0.79, 1 - magnitude * 0.075)
        case .fan:
            x = distance * width * 0.52
            y = min(magnitude, 2) * 30
            yaw = Double(-distance * 10)
            roll = Double(distance * 10)
            scale = max(0.75, 1 - magnitude * 0.105)
        }
        return AtelierCardSurface(fragranceID: card.fragrance.id, selected: isFocused)
            .frame(width: width, height: width * 86.0 / 59.0)
            .matchedGeometryEffect(id: "collectible-\(card.id)", in: transitionNamespace,
                                   isSource: true)
            .opacity(inspectedID == card.id ? 0 : 1)
            .scaleEffect(scale * (isDragging && isFocused ? 1.025 : 1))
            .rotation3DEffect(.degrees(yaw), axis: (x: 0, y: 1, z: 0), perspective: 0.60)
            .rotationEffect(.degrees(roll))
            .offset(x: x, y: y - (isDragging && isFocused ? 7 : 0))
            .onTapGesture {
                understoodDeck = true
                if isFocused { inspect(card) }
                else { settle(at: index) }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(card.fragrance.house), \(card.fragrance.name)")
            .accessibilityHint(isFocused ? "Double tap to inspect the collectible" : "Double tap to focus")
            .accessibilityAddTraits(.isButton)
    }

    private var selectedIdentity: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(active?.fragrance.house.uppercased() ?? "YOUR COLLECTION")
                    .font(.system(size: 10, weight: .semibold)).tracking(2)
                    .foregroundStyle(accent)
                Spacer()
                Text("\(activeIndex + 1) / \(cards.count)")
                    .font(.system(.caption, design: .rounded).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(active?.fragrance.name ?? "")
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .lineLimit(1).minimumScaleFactor(0.76)
                    Text(active?.fragrance.concentration ?? "")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Button {
                    if let active { inspect(active) }
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 46, height: 46)
                }
                .atelierGlass()
                .accessibilityLabel("Inspect selected fragrance")
            }
        }
    }

    @ViewBuilder private var bottomAction: some View {
        if archive.mode == .demo {
            Button {
                if let active { archive.add(active.fragrance) }
            } label: {
                Label("Add this fragrance", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 51)
            }
            .buttonStyle(.borderedProminent).tint(accent)
        } else if let bottle = archive.selectedBottle {
            Button {
                showToday(bottle.id)
            } label: {
                Label("Wear or layer this fragrance", systemImage: "square.stack.3d.up")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 51)
            }
            .buttonStyle(.borderedProminent).tint(accent)
        }
    }

    private var overview: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                AtelierDisplay(title: "Your shelves", size: 29)
                Spacer()
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.88)) {
                        shelfOverview = false
                    }
                } label: {
                    Image(systemName: "xmark").frame(width: 46, height: 46)
                }
                .atelierGlass().accessibilityLabel("Back to cards")
            }
            .padding(.horizontal, 22).padding(.top, 10)
            AtelierCompactShelves(focus: { card in
                if archive.mode == .mine {
                    archive.choose(card, haptic: false)
                } else {
                    archive.choose(DisplayCard(id: card.fragrance.id,
                                               fragrance: card.fragrance, bottleID: nil), haptic: false)
                }
                synchronizeSelection(animated: false)
                withAnimation(reduceMotion ? nil : .spring(response: 0.44, dampingFraction: 0.9)) {
                    shelfOverview = false
                }
            }, add: add)
        }
        .background(AtelierAtmosphere(theme: archive.theme))
        .simultaneousGesture(
            MagnifyGesture().onEnded { gesture in
                if gesture.magnification > 1.13 {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.89)) {
                        shelfOverview = false
                    }
                }
            }
        )
    }

    private func moveBy(_ direction: Int) {
        settle(at: max(0, min(cards.count - 1, activeIndex + direction)))
    }

    private func settle(at target: Int) {
        guard cards.indices.contains(target) else { return }
        let old = activeIndex
        withAnimation(reduceMotion ? nil : .spring(response: 0.46, dampingFraction: 0.88),
                      completionCriteria: .logicallyComplete) {
            deckPosition = CGFloat(target)
            archive.choose(cards[target], haptic: false)
        } completion: {
            if old != target { HapticEngine.shared.play(.selection) }
        }
    }

    private func synchronizeSelection(animated: Bool) {
        let target = CGFloat(activeIndex)
        guard abs(deckPosition - target) > 0.001 else { return }
        if animated && !reduceMotion {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.89)) { deckPosition = target }
        } else {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) { deckPosition = target }
        }
    }
}

struct AtelierInspector: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flipped = false
    @State private var editing: BottleRecord?
    let card: DisplayCard
    let transitionNamespace: Namespace.ID
    let close: () -> Void

    private var palette: ArchivePalette { archive.theme.palette }

    var body: some View {
        GeometryReader { geo in
            let cardWidth = min(geo.size.width - 38, (geo.size.height - 212) * 59.0 / 86.0, 350)
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        AtelierEyebrow(text: card.fragrance.house, accent: palette.accent)
                        AtelierDisplay(title: card.fragrance.name, size: 27)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .frame(width: 46, height: 46)
                    }
                    .atelierGlass()
                    .accessibilityLabel("Close inspector")
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                Spacer(minLength: 5)
                ZStack {
                    AtelierCardSurface(fragranceID: card.fragrance.id, side: .front, selected: true)
                        .opacity(flipped ? 0 : 1)
                    AtelierCardSurface(fragranceID: card.fragrance.id, side: .back, selected: true)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .opacity(flipped ? 1 : 0)
                }
                .frame(width: max(155, cardWidth), height: max(155, cardWidth) * 86.0 / 59.0)
                .matchedGeometryEffect(id: "collectible-\(card.id)", in: transitionNamespace, isSource: false)
                .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.69)
                .contentShape(Rectangle())
                .onTapGesture(perform: flip)
                .accessibilityLabel("\(card.fragrance.name), \(flipped ? "back with fragrance map" : "front")")
                .accessibilityHint("Double tap to flip")
                Spacer(minLength: 5)

                Text(flipped ? "FRAGRANCE MAP  ·  REVERSE" : "ARCHIVE FOIL  ·  FRONT")
                    .font(.system(.caption2, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 26)

                HStack(spacing: 12) {
                    Button(action: flip) {
                        Label("Flip", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .atelierGlass()
                    if archive.mode == .demo {
                        Button {
                            archive.add(card.fragrance)
                            close()
                        } label: {
                            Label("Collect", systemImage: "plus")
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(palette.accent)
                    } else {
                        Button {
                            editing = archive.bottles.first(where: { $0.id == card.bottleID })
                        } label: {
                            Label("My Bottle", systemImage: "square.and.pencil")
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .atelierGlass()
                    }
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 22)
                .padding(.bottom, 13)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AtelierAtmosphere(theme: archive.theme))
        .sheet(item: $editing) { record in
            NavigationStack { BottleEditor(bottle: record) }
        }
    }

    private func flip() {
        withAnimation(reduceMotion ? nil : .spring(response: 0.57, dampingFraction: 0.88)) {
            flipped.toggle()
        }
    }
}
