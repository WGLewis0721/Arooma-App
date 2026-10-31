import SwiftUI

struct AtelierGallery: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @GestureState private var dragX: CGFloat = 0
    @State private var pinchScale: CGFloat = 1
    @State private var shelfOverview = false
    let transitionNamespace: Namespace.ID
    let inspectedID: String?
    let inspect: (DisplayCard) -> Void
    let add: () -> Void

    private var cards: [DisplayCard] { archive.displayedCards }
    private var active: DisplayCard? { archive.selected }
    private var palette: ArchivePalette { archive.theme.palette }

    var body: some View {
        VStack(spacing: 0) {
            heading
                .padding(.horizontal, 24)
                .padding(.top, 7)
                .padding(.bottom, 14)
            if cards.isEmpty {
                Spacer(minLength: 10)
                AtelierEmptyState(
                    title: "Every collection begins with one.",
                    detail: "Choose a collectible. Keep your wear history, notes and rituals private.",
                    action: "Explore fragrances", callback: add, accent: palette.accent
                )
                Spacer(minLength: 10)
            } else {
                identity
                    .padding(.horizontal, 26)
                    .padding(.bottom, 4)
                stage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                details
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                action
                    .padding(.horizontal, 24)
                    .padding(.bottom, 13)
            }
        }
        .background(AtelierAtmosphere(theme: archive.theme))
        .overlay {
            if shelfOverview {
                VStack(spacing: 0) {
                    HStack {
                        AtelierDisplay(title: "Your shelves", size: 28)
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) { shelfOverview = false }
                        } label: {
                            Image(systemName: "xmark").frame(width: 46, height: 46)
                        }
                        .atelierGlass()
                        .accessibilityLabel("Return to cards")
                    }
                    .padding(.horizontal, 23).padding(.top, 10)
                    AtelierCompactShelves(focus: { card in
                        archive.choose(card, haptic: false)
                        withAnimation(.spring(response: 0.47, dampingFraction: 0.88)) { shelfOverview = false }
                    }, add: add)
                }
                .background(AtelierAtmosphere(theme: archive.theme))
                .simultaneousGesture(MagnifyGesture().onEnded { value in
                    if value.magnification > 1.12 {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) { shelfOverview = false }
                    }
                })
                .transition(.opacity.combined(with: .scale(scale: 0.91)))
                .zIndex(10)
            }
        }
        .onAppear { FoilMotion.shared.start() }
        .onDisappear { FoilMotion.shared.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && !shelfOverview { FoilMotion.shared.start() }
            else { FoilMotion.shared.stop() }
        }
        .onChange(of: shelfOverview) { _, showing in
            if showing { FoilMotion.shared.stop() }
            else { FoilMotion.shared.start() }
        }
    }

    private var heading: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                AtelierEyebrow(text: "The fragrance archive", accent: palette.accent)
                Text("Arooma")
                    .font(.system(size: 33, weight: .regular, design: .serif))
                    .tracking(-1)
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 10)
            Button(action: add) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 46, height: 46)
            }
            .atelierGlass()
            .accessibilityLabel("Quick add a fragrance")
            Button {
                archive.enter(archive.mode == .demo ? .mine : .demo)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption.weight(.medium))
                    Text(archive.mode.rawValue)
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 46)
            }
            .atelierGlass()
            .accessibilityLabel("Switch \(archive.mode == .demo ? "to Mine" : "to Demo")")
        }
    }

    private var identity: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                AtelierEyebrow(text: active?.fragrance.house ?? "The collection", accent: palette.accent)
                AtelierDisplay(title: active?.fragrance.name ?? "", size: 32)
                    .lineLimit(1)
            }
            Spacer(minLength: 7)
            Text("\((cards.firstIndex(where: { $0.id == active?.id }) ?? 0) + 1, format: .number.precision(.integerLength(2))) / \(cards.count, format: .number.precision(.integerLength(2)))")
                .font(.system(.caption, design: .rounded).monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.bottom, 5)
        }
    }

    private var stage: some View {
        GeometryReader { geo in
            let cardWidth = max(155, min(geo.size.width * 0.73,
                                         (geo.size.height - 22) * 59.0 / 86.0,
                                         320))
            let index = cards.firstIndex(where: { $0.id == active?.id }) ?? 0

            ZStack {
                Ellipse()
                    .fill(.black.opacity(0.22))
                    .frame(width: cardWidth * 0.93, height: 19)
                    .blur(radius: 14)
                    .offset(y: cardWidth * 0.72)
                    .accessibilityHidden(true)

                ForEach(cards) { card in
                    let idx = cards.firstIndex(where: { $0.id == card.id }) ?? 0
                    let distance = idx - index
                    if abs(distance) <= 2 {
                        arranged(card: card, distance: distance, width: cardWidth)
                            .zIndex(distance == 0 ? 30 : Double(10 - abs(distance)))
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .scaleEffect(max(0.72, min(1, pinchScale)))
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 11)
                    .updating($dragX) { value, state, _ in state = value.translation.width }
                    .onEnded { value in
                        let predicted = value.predictedEndTranslation.width
                        guard abs(predicted) > max(38, cardWidth * 0.17) else { return }
                        // Velocity carries across more than one card when the flick is decisive.
                        let steps = max(1, min(3, Int((abs(predicted) / (cardWidth * 0.7)).rounded())))
                        withAnimation(reduceMotion ? nil : .spring(response: 0.51, dampingFraction: 0.86),
                                      completionCriteria: .logicallyComplete) {
                            archive.move(predicted < 0 ? steps : -steps, haptic: false)
                        } completion: {
                            HapticEngine.shared.play(.selection)
                        }
                    }
            )
            .simultaneousGesture(
                MagnifyGesture(minimumScaleDelta: 0.02)
                    .onChanged { value in pinchScale = min(1, max(0.72, value.magnification)) }
                    .onEnded { value in
                        if value.magnification < 0.88 {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.46, dampingFraction: 0.88)) {
                                shelfOverview = true
                            }
                        }
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) { pinchScale = 1 }
                    }
            )
            .accessibilityAction(named: "See all shelves") {
                withAnimation { shelfOverview = true }
            }
            .accessibilityAction(named: "Next fragrance") { archive.move(1) }
            .accessibilityAction(named: "Previous fragrance") { archive.move(-1) }
        }
    }

    private func arranged(card: DisplayCard, distance: Int, width: CGFloat) -> some View {
        let progress = CGFloat(distance) + dragX / max(width * 0.72, 1)
        let magnitude = abs(progress)
        let x: CGFloat
        let y: CGFloat
        let turn: CGFloat
        let roll: CGFloat
        let scale: CGFloat
        switch archive.layout {
        case .coverFlow:
            x = progress * width * 0.63
            y = min(magnitude, 2) * 8
            turn = -progress * 39
            roll = 0
            scale = max(0.74, 1 - magnitude * 0.115)
        case .stack:
            x = progress * width * 0.12
            y = min(magnitude, 2) * 21
            turn = progress * 4
            roll = progress * 2
            scale = max(0.79, 1 - magnitude * 0.075)
        case .fan:
            x = progress * width * 0.46
            y = min(magnitude, 2) * 32
            turn = -progress * 9
            roll = progress * 9
            scale = max(0.77, 1 - magnitude * 0.09)
        }
        return AtelierCardSurface(fragranceID: card.fragrance.id, selected: distance == 0)
            .frame(width: width, height: width * 86.0 / 59.0)
            .matchedGeometryEffect(id: "collectible-\(card.id)", in: transitionNamespace, isSource: true)
            .opacity(inspectedID == card.id ? 0 : 1)
            .scaleEffect(scale)
            .rotation3DEffect(.degrees(Double(turn)), axis: (x: 0, y: 1, z: 0), perspective: 0.67)
            .rotationEffect(.degrees(Double(roll)))
            .offset(x: x, y: y - (distance == 0 ? min(8, abs(dragX) * 0.04) : 0))
            .animation(reduceMotion ? nil : .interactiveSpring(response: 0.40, dampingFraction: 0.82),
                       value: archive.selectedID)
            .onTapGesture {
                if distance == 0 { inspect(card) }
                else {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.84),
                                  completionCriteria: .logicallyComplete) {
                        archive.choose(card, haptic: false)
                    } completion: {
                        HapticEngine.shared.play(.selection)
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(card.fragrance.house), \(card.fragrance.name)")
            .accessibilityHint(distance == 0 ? "Inspect collectible" : "Focus this card")
            .accessibilityAddTraits(.isButton)
    }

    private var details: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(active?.fragrance.concentration ?? "")
                    .font(.system(.subheadline, weight: .medium))
                    .lineLimit(1)
                Text(active?.fragrance.top.prefix(3).joined(separator: "  ·  ") ?? "")
                    .font(.system(.caption))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
            if active?.fragrance.archival == true {
                Text("ARCHIVE")
                    .font(.system(.caption2, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
            }
            if archive.selectedBottle?.lowStock == true {
                Label("Low", systemImage: "drop.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Button {
                if let active { inspect(active) }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 46, height: 46)
            }
            .atelierGlass()
            .accessibilityLabel("Open card inspector")
        }
    }

    @ViewBuilder private var action: some View {
        if archive.mode == .demo {
            Button {
                if let selected = active { archive.add(selected.fragrance) }
            } label: {
                Label("Add to My Collection", systemImage: "plus")
                    .font(.system(.subheadline, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(palette.accent)
        } else if archive.selectedBottle?.wornToday == true {
            Button {
                archive.undoWear()
            } label: {
                Label("Worn today · Undo", systemImage: "arrow.uturn.backward")
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered)
        } else {
            Button {
                archive.wearSelected()
            } label: {
                Label("Wear Today", systemImage: "checkmark")
                    .font(.system(.subheadline, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(palette.accent)
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
