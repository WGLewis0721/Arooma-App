import SwiftUI

extension CardLayout {
    var kind: DeckLayoutKind {
        switch self { case .coverFlow: .coverFlow; case .stack: .stack; case .fan: .fan }
    }
    var choreography: String {
        switch self {
        case .coverFlow: "Cinematic depth. Neighbours hinge away from the hero."
        case .stack: "A weighted deck. Deal the top card away to reveal the next."
        case .fan: "A held hand. The chosen card rises from the spread."
        }
    }
}

// MARK: - Collection gallery
//
// Every card pose on this screen is a pure function of DeckMotor's continuous position, press
// spring and layout morph (see DeckPhysics.swift). The finger writes the position directly;
// release hands the measured velocity to a spring stepped by a display link; selection is
// persisted only when the deck comes to rest. Nothing here uses withAnimation for the deck, so
// a new touch always catches the card exactly where it is drawn.
struct AtelierGallery: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var motor = DeckMotor()
    @State private var touching = false
    @State private var dragging = false
    @State private var slop: CGFloat = 0
    /// Where the finger is on the hero card (unit coordinates), for the foil's press response.
    @State private var touchUV = CGPoint(x: 0.5, y: 0.5)
    @GestureState private var fingerDown = false
    @State private var pinching = false
    /// 0 = deck, 1 = spatial shelf overview. Driven continuously by pinch.
    @State private var overview: CGFloat = 0
    @AppStorage("arooma.deckTipV3") private var understoodDeck = false

    let transitionNamespace: Namespace.ID
    let inspect: (DisplayCard) -> Void
    let add: () -> Void
    let openStyle: () -> Void
    let showToday: (UUID) -> Void

    private var cards: [DisplayCard] { archive.displayedCards }
    private var accent: Color { archive.theme.palette.accent }
    private var storedIndex: Int {
        cards.firstIndex(where: { $0.id == archive.selected?.id }) ?? 0
    }
    private var focusedCard: DisplayCard? {
        cards.indices.contains(motor.focusedIndex) ? cards[motor.focusedIndex] : cards.first
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                if cards.isEmpty {
                    Spacer()
                    AtelierEmptyState(
                        title: "A collection starts with one bottle.",
                        detail: "Capture a name or a photo in seconds. Make it yours later.",
                        action: "Add a fragrance", callback: add, accent: accent
                    )
                    Spacer()
                } else {
                    stage
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .layoutPriority(1)
                    DeckScrubber(count: cards.count, position: motor.position, accent: accent) { index in
                        understoodDeck = true
                        motor.glide(to: index)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 2)
                    identity
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                    actions
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 12)
                }
            }
            .scaleEffect(1 - 0.1 * overview)
            .opacity(1 - Double(overview) * 0.92)
            .allowsHitTesting(overview < 0.5)

            if overview > 0.001 {
                ShelfOverview(progress: $overview, focus: { card in
                    focusFromOverview(card)
                }, add: add)
                .opacity(Double(overview))
                .scaleEffect(1.08 - 0.08 * overview)
                .allowsHitTesting(overview > 0.5)
                .zIndex(10)
            }
        }
        .background(AtelierAtmosphere(theme: archive.theme))
        .onAppear {
            motor.reduceMotion = reduceMotion
            bindMotor()
            configure()
            if UserDefaults.standard.bool(forKey: "AroomaAutoplay") {
                Task { await autoplay() }
            }
        }
        .onChange(of: cards.map(\.id)) { _, _ in configure() }
        .onChange(of: archive.mode) { _, _ in configure() }
        .onChange(of: archive.selectedID) { _, _ in
            // External selection (search, shelves, Today) glides the deck from where it is.
            if !motor.isInteracting && storedIndex != motor.deck.targetIndex {
                motor.glide(to: storedIndex)
            }
        }
        .onChange(of: archive.layout) { _, layout in motor.morph(to: layout.kind) }
        .onChange(of: reduceMotion) { _, value in motor.reduceMotion = value }
        .onChange(of: fingerDown) { _, down in
            // The system can cancel a touch (Control Centre, a context menu) without onEnded.
            if !down && touching {
                touching = false
                dragging = false
                motor.liftWithoutDrag()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                AroomaSignatureMark(ink: accent)
                    .frame(height: 30)
                    .accessibilityElement()
                    .accessibilityLabel("Arooma")
                    .accessibilityAddTraits(.isHeader)
                Menu {
                    Button("My collection", systemImage: "square.stack") { archive.enter(.mine) }
                    Button("Explore sample cards", systemImage: "sparkles") { archive.enter(.demo) }
                } label: {
                    HStack(spacing: 5) {
                        Text(archive.mode == .mine ? "MY COLLECTION" : "SAMPLE ARCHIVE")
                        Image(systemName: "chevron.down").font(.system(size: 8, weight: .bold))
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 30)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Collection: \(archive.mode == .mine ? "mine" : "sample archive")")
            }
            Spacer(minLength: 4)
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    glassButton("square.grid.2x2", label: "All shelves") { openOverview() }
                    glassButton("plus", label: "Quick add a bottle", action: add)
                    glassButton("slider.horizontal.3", label: "View and style", action: openStyle)
                }
            }
        }
    }

    private func glassButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }

    // MARK: Stage

    private func cardWidth(for size: CGSize) -> CGFloat {
        max(130, min(size.width * 0.70, (size.height - 44) * (59.0 / 86.0), 340))
    }

    private var stage: some View {
        GeometryReader { geo in
            let w = cardWidth(for: geo.size)
            let h = w * 86.0 / 59.0
            let unit = motor.stride(cardWidth: Double(w))
            let position = motor.position
            ZStack {
                // The table: a soft pool of the theme's key light the deck rests in.
                Ellipse()
                    .fill(RadialGradient(colors: [archive.theme.keyLight.opacity(0.16), .clear],
                                         center: .center, startRadius: 4, endRadius: w * 0.9))
                    .frame(width: w * 2.1, height: w * 0.5)
                    .offset(y: h * 0.5)
                    .accessibilityHidden(true)

                ForEach(visibleCards(around: position), id: \.card.id) { entry in
                    deckCard(entry.card, index: entry.index, position: position, width: w)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .overlay(alignment: .bottom) {
                if !understoodDeck {
                    Label("Swipe to browse · tap to inspect · pinch for shelves", systemImage: "hand.draw")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 7).padding(.horizontal, 12)
                        .glassEffect(.regular, in: Capsule())
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(deckDrag(unit: unit, stage: geo.size, card: CGSize(width: w, height: h)))
            .simultaneousGesture(pinchToOverview)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(focusedCard.map { "\($0.fragrance.house), \($0.fragrance.name)" } ?? "Collection")
            .accessibilityValue("Card \(motor.focusedIndex + 1) of \(cards.count)")
            .accessibilityHint("Swipe up or down to browse. Double tap to inspect.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: motor.glide(to: min(cards.count - 1, motor.deck.targetIndex + 1))
                case .decrement: motor.glide(to: max(0, motor.deck.targetIndex - 1))
                @unknown default: break
                }
            }
            .accessibilityAction { if let focusedCard { inspect(focusedCard) } }
            .accessibilityAction(named: "Show every shelf") { openOverview() }
        }
    }

    private struct DeckEntry { let index: Int; let card: DisplayCard }

    private func visibleCards(around position: Double) -> [DeckEntry] {
        guard !cards.isEmpty else { return [] }
        let lower = max(0, Int(floor(position - DeckLayoutEngine.visibleRadius)))
        let upper = min(cards.count - 1, Int(ceil(position + DeckLayoutEngine.visibleRadius)))
        guard lower <= upper else { return [] }
        return (lower...upper).map { DeckEntry(index: $0, card: cards[$0]) }
    }

    private func deckCard(_ card: DisplayCard, index: Int, position: Double, width w: CGFloat) -> some View {
        let d = Double(index) - position
        let pose = motor.pose(distance: d, index: index, cardWidth: Double(w))
        let nearness = max(0, 1 - abs(d))
        let lift = motor.press.value * nearness
        return AtelierCardSurface(
            fragranceID: card.fragrance.id,
            yaw: pose.yaw,
            lift: lift,
            shade: pose.shade,
            foil: abs(d) < 1.15 ? .live : .sheen,
            foilStrength: max(0, 1 - abs(d) * 1.8), // shader off beyond ~half a slot
            lean: nearness * nearness,
            touch: touchUV,
            pressure: abs(d) < 0.5 ? lift : 0
        )
        .frame(width: w, height: w * 86.0 / 59.0)
        .matchedTransitionSource(id: card.id, in: transitionNamespace)
        .scaleEffect(pose.scale * (1 + 0.03 * lift))
        .rotation3DEffect(.degrees(pose.yaw), axis: (x: 0, y: 1, z: 0), anchor: .center, perspective: 0.5)
        .rotationEffect(.degrees(pose.roll), anchor: UnitPoint(x: 0.5, y: pose.pivotY))
        .offset(x: pose.x, y: pose.y - 12 * lift)
        .opacity(pose.opacity)
        .zIndex(pose.depth)
        .onTapGesture { tapped(index: index, card: card) }
        .contextMenu { cardMenu(card) }
    }

    @ViewBuilder private func cardMenu(_ card: DisplayCard) -> some View {
        Button("Inspect", systemImage: "arrow.up.left.and.arrow.down.right") { inspect(card) }
        if let id = card.bottleID {
            Button("Wear today", systemImage: "drop") { archive.recordWear(bottleIDs: [id]) }
            Button("Layer with others", systemImage: "square.stack.3d.up") { showToday(id) }
        } else {
            Button("Add to my collection", systemImage: "plus") { archive.add(card.fragrance) }
        }
    }

    // MARK: Gestures

    private func deckDrag(unit: Double, stage: CGSize, card: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($fingerDown) { _, state, _ in state = true }
            .onChanged { value in
                touchUV = CGPoint(x: (value.location.x - stage.width / 2) / card.width + 0.5,
                                  y: (value.location.y - stage.height / 2) / card.height + 0.5)
                if !touching {
                    touching = true
                    dragging = false
                    motor.hold()
                }
                guard !pinching else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                if !dragging {
                    // Horizontal intent only; a vertical wander stays a tap/press.
                    guard abs(dx) > 7, abs(dx) > abs(dy) * 0.9 else { return }
                    dragging = true
                    slop = dx > 0 ? 7 : -7
                    if !understoodDeck { withAnimation(.easeOut(duration: 0.3)) { understoodDeck = true } }
                }
                motor.drag(translation: -Double(dx - slop) / unit)
            }
            .onEnded { value in
                guard touching else { return }
                touching = false
                if dragging && !pinching {
                    motor.release(velocity: -Double(value.velocity.width) / unit)
                } else {
                    motor.liftWithoutDrag()
                }
                dragging = false
            }
    }

    private var pinchToOverview: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.02)
            .onChanged { value in
                if !pinching {
                    pinching = true
                    if touching { motor.liftWithoutDrag() }
                    understoodDeck = true
                }
                overview = min(1, max(0, (1 - value.magnification) / 0.42))
            }
            .onEnded { value in
                pinching = false
                let commit = overview > 0.42 || value.velocity < -0.6
                withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.86)) {
                    overview = commit ? 1 : 0
                }
            }
    }

    private func tapped(index: Int, card: DisplayCard) {
        if !understoodDeck { understoodDeck = true }
        if abs(Double(index) - motor.position) < 0.5 {
            inspect(card)
        } else {
            motor.glide(to: index)
        }
    }

    private func openOverview() {
        withAnimation(reduceMotion ? nil : .spring(response: 0.46, dampingFraction: 0.86)) { overview = 1 }
    }

    private func focusFromOverview(_ card: DisplayCard) {
        archive.choose(card, haptic: false)
        withAnimation(reduceMotion ? nil : .spring(response: 0.44, dampingFraction: 0.88)) { overview = 0 }
    }

    // MARK: Identity and actions

    private var identity: some View {
        let card = focusedCard
        let notes = card.map { Array($0.fragrance.top.prefix(3)) } ?? []
        let edge: Edge = motor.travelDirection >= 0 ? .trailing : .leading
        return VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(card?.fragrance.house.uppercased() ?? "")
                    .font(.system(size: 10, weight: .semibold)).tracking(2.1)
                    .foregroundStyle(accent)
                    .lineLimit(1)
                Spacer()
                HStack(spacing: 2) {
                    Text(String(format: "%02d", motor.focusedIndex + 1))
                        .contentTransition(.numericText(value: Double(motor.focusedIndex)))
                    Text("/ \(String(format: "%02d", cards.count))").foregroundStyle(.tertiary)
                }
                .font(.system(.caption, design: .rounded).monospacedDigit())
                .foregroundStyle(.secondary)
            }
            ZStack(alignment: .leading) {
                Text(card?.fragrance.name ?? "")
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .tracking(-0.6)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .id(card?.id ?? "")
                    .transition(reduceMotion ? .opacity : .push(from: edge))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
            Text(([card?.fragrance.concentration ?? ""] + notes).filter { !$0.isEmpty }.joined(separator: "  ·  "))
                .font(.footnote).foregroundStyle(.secondary)
                .lineLimit(1)
                .id("notes-\(card?.id ?? "")")
                .transition(.opacity)
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: card?.id)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var actions: some View {
        if let card = focusedCard {
            HStack(spacing: 10) {
                if let bottleID = card.bottleID {
                    let worn = archive.bottles.first(where: { $0.id == bottleID })?.wornToday ?? false
                    Button {
                        if worn { archive.undoTodayWear(bottleID: bottleID) }
                        else { archive.recordWear(bottleIDs: [bottleID]) }
                    } label: {
                        Label(worn ? "Worn today · Undo" : "Wear today",
                              systemImage: worn ? "checkmark.circle.fill" : "drop")
                            .contentTransition(.symbolEffect(.replace))
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 34)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(accent)
                    Button { showToday(bottleID) } label: {
                        Label("Layer", systemImage: "square.stack.3d.up")
                            .font(.subheadline.weight(.semibold))
                            .frame(minHeight: 34)
                    }
                    .buttonStyle(.glass)
                    .accessibilityHint("Combine with other bottles in Today")
                } else {
                    Button { archive.add(card.fragrance) } label: {
                        Label("Add to my collection", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 34)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(accent)
                }
                Button { inspect(card) } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Inspect \(card.fragrance.name)")
            }
            .animation(reduceMotion ? nil : .snappy, value: card.id)
        }
    }

    // MARK: Motor plumbing

    private func configure() {
        motor.reduceMotion = reduceMotion
        motor.configure(count: cards.count, index: storedIndex, layout: archive.layout.kind)
    }

    /// The motor's callbacks read the store directly (never a captured copy of this view), so
    /// a commit or settle always resolves against the live card list.
    private func bindMotor() {
        let store = archive
        motor.onCommit = { index in
            let list = store.displayedCards
            guard list.indices.contains(index) else { return }
            store.choose(list[index], haptic: false)
        }
        motor.onSettle = { index, changed, speed in
            let list = store.displayedCards
            guard list.indices.contains(index) else { return }
            store.choose(list[index], haptic: false)
            if changed { HapticEngine.shared.play(.settle(speed: speed)) }
        }
    }

    // MARK: QA autoplay (launch argument -AroomaAutoplay YES)
    // Drives the real engine with synthetic finger curves so a simulator screen recording shows
    // genuine physics output: drag, flick, reversal mid-settle, all three layout morphs, inspect.
    // It is NOT real touch input and is never active unless the argument is passed.

    private func synthSwipe(cards travel: Double, duration: Double, release velocity: Double) async {
        motor.hold()
        let steps = max(1, Int(duration * 120))
        for step in 1...steps {
            let t = Double(step) / Double(steps)
            motor.drag(translation: travel * (1 - pow(1 - t, 2.2)))
            try? await Task.sleep(for: .milliseconds(8))
        }
        motor.release(velocity: velocity)
    }

    private func autoplay() async {
        try? await Task.sleep(for: .seconds(1.6))
        await synthSwipe(cards: 0.55, duration: 0.32, release: 2.4)
        try? await Task.sleep(for: .seconds(0.9))
        await synthSwipe(cards: 0.3, duration: 0.14, release: 6)
        try? await Task.sleep(for: .seconds(0.18))
        await synthSwipe(cards: -0.4, duration: 0.2, release: -4) // reversal mid-settle
        try? await Task.sleep(for: .seconds(0.9))
        await synthSwipe(cards: 0.25, duration: 0.5, release: 0.1) // slow, springs back
        try? await Task.sleep(for: .seconds(1.0))
        for layout in [CardLayout.stack, .fan, .coverFlow] {
            archive.layout = layout
            try? await Task.sleep(for: .seconds(1.3))
            await synthSwipe(cards: 0.6, duration: 0.3, release: 3)
            try? await Task.sleep(for: .seconds(0.9))
            await synthSwipe(cards: -0.6, duration: 0.3, release: -3)
            try? await Task.sleep(for: .seconds(1.0))
        }
        if let card = focusedCard { inspect(card) }
    }
}

// MARK: - Scrubber

/// One tick per card. The active tick stretches continuously with the deck position, and
/// dragging along the row glides the deck: fast travel through a dense collection.
struct DeckScrubber: View {
    let count: Int
    let position: Double
    let accent: Color
    let select: (Int) -> Void
    @State private var lastSent = -1

    var body: some View {
        GeometryReader { geo in
            let slot = min(22, geo.size.width / CGFloat(max(1, count)))
            let total = slot * CGFloat(count)
            HStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    let near = max(0, 1 - abs(Double(i) - position))
                    Capsule()
                        .fill(near > 0.5 ? accent : Color.primary.opacity(0.22 + 0.4 * near))
                        .frame(width: max(3, min(slot - 3, 4 + CGFloat(near) * 14)), height: 4)
                        .frame(width: slot)
                }
            }
            .frame(width: total, height: 30)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                let i = Int((value.location.x / max(1, slot)).rounded(.down))
                let clamped = max(0, min(count - 1, i))
                if clamped != lastSent { lastSent = clamped; select(clamped) }
            }.onEnded { _ in lastSent = -1 })
            .frame(maxWidth: .infinity)
        }
        .frame(height: 30)
        .opacity(count > 1 ? 1 : 0)
        .accessibilityHidden(true)
    }
}

// MARK: - Inspector

/// Presented full screen with the iOS zoom navigation transition from the exact gallery card,
/// so the same collectible grows into the inspector and shrinks back into its slot on dismiss.
/// Horizontal drag scrubs a true two-sided flip; vertical pull dismisses.
struct AtelierInspector: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flip = FlipMotor()
    @State private var axisLock: Axis?
    @State private var pull: CGSize = .zero
    @State private var pressUV = CGPoint(x: 0.5, y: 0.5)
    @State private var pressing: Double = 0
    @State private var editing: BottleRecord?
    @State private var appeared = false
    @State private var stamp = 0
    let card: DisplayCard
    let close: () -> Void

    private var palette: ArchivePalette { archive.theme.palette }
    private var bottle: BottleRecord? { archive.bottles.first(where: { $0.id == card.bottleID }) }

    var body: some View {
        GeometryReader { geo in
            let cardW = max(150, min(geo.size.width - 84, (geo.size.height - 360) * 59.0 / 86.0, 330))
            ZStack {
                ambient
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                    Spacer(minLength: 6)
                    flippingCard(width: cardW)
                    Spacer(minLength: 6)
                    Text(flip.showsBack ? "REVERSE  ·  NOTE MAP" : "FRONT  ·  TOP NOTES")
                        .font(.system(.caption2, weight: .semibold))
                        .tracking(1.8)
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: flip.showsBack)
                        .padding(.bottom, 12)
                    details
                        .padding(.horizontal, 24)
                    actions
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 10)
                }
                .opacity(1 - min(0.5, Double(max(0, pull.height)) / 500))
            }
        }
        .background(AtelierAtmosphere(theme: archive.theme))
        .overlay(alignment: .top) { FramePacingHUD().padding(.top, 2) }
        .sheet(item: $editing) { record in
            NavigationStack { BottleEditor(bottle: record) }
                .environmentObject(archive)
        }
        .onAppear {
            flip.reduceMotion = reduceMotion
            flip.onEdge = { HapticEngine.shared.play(.flipEdge) }
            withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.86).delay(0.12)) {
                appeared = true
            }
            if UserDefaults.standard.bool(forKey: "AroomaAutoplay") {
                Task { await autoplay() }
            }
        }
        .accessibilityAction(named: "Flip card") { flip.flip() }
    }

    /// The card's own colours, blurred into the room, so each collectible lights its inspector.
    private var ambient: some View {
        GeometryReader { geo in
            if let art = ApprovedArtwork.image(for: card.fragrance.id, side: .front) {
                Image(uiImage: art)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .blur(radius: 70)
                    .opacity(0.42)
                    .clipped()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button(action: close) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Close")
            Spacer()
            if let bottle {
                Button {
                    var updated = bottle
                    updated.favorite.toggle()
                    archive.update(updated)
                } label: {
                    Image(systemName: bottle.favorite ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(bottle.favorite ? palette.accent : .primary)
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.bounce, value: bottle.favorite)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel(bottle.favorite ? "Remove from favorites" : "Mark as favorite")
            }
        }
    }

    private func flippingCard(width w: CGFloat) -> some View {
        let angle = flip.angle
        let back = flip.showsBack
        let frontYaw = angle.remainder(dividingBy: 360)
        let backYaw = (angle - 180).remainder(dividingBy: 360)
        let facing = abs(cos(angle * .pi / 180))
        return ZStack {
            AtelierCardSurface(fragranceID: card.fragrance.id, side: .front, radius: 16,
                               yaw: frontYaw, lift: 0.6, foil: .live, lean: 0.7,
                               touch: pressUV, pressure: pressing, shadowed: false)
                .opacity(back ? 0 : 1)
            AtelierCardSurface(fragranceID: card.fragrance.id, side: .back, radius: 16,
                               yaw: backYaw, lift: 0.6, foil: .live, foilStrength: 0.6, lean: 0.7,
                               touch: CGPoint(x: 1 - pressUV.x, y: pressUV.y), pressure: pressing, shadowed: false)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(back ? 1 : 0)
        }
        .frame(width: w, height: w * 86.0 / 59.0)
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.42)
        .background {
            // Contact shadow on the "table": narrows as the card turns edge-on.
            Ellipse()
                .fill(archive.theme.shadowTint.opacity(0.5))
                .frame(width: w * (0.25 + 0.75 * facing), height: 26)
                .blur(radius: 18)
                .offset(y: w * 86.0 / 59.0 * 0.5 + 18)
        }
        .keyframeAnimator(initialValue: StampPose(), trigger: stamp) { content, pose in
            content.scaleEffect(pose.scale).offset(y: pose.y)
        } keyframes: { _ in
            KeyframeTrack(\.scale) {
                CubicKeyframe(0.94, duration: 0.09)
                SpringKeyframe(1.03, duration: 0.16, spring: .snappy)
                SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
            }
            KeyframeTrack(\.y) {
                CubicKeyframe(8, duration: 0.09)
                SpringKeyframe(-6, duration: 0.16, spring: .snappy)
                SpringKeyframe(0, duration: 0.35, spring: .smooth)
            }
        }
        .scaleEffect(1 - min(0.22, max(0, pull.height) / 1100))
        .offset(pull)
        .contentShape(Rectangle())
        .onTapGesture { flip.flip() }
        .gesture(cardDrag(width: w))
        .simultaneousGesture(
            // The finger bends the foil: a glint follows it while pressed.
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    pressUV = CGPoint(x: value.location.x / w, y: value.location.y / (w * 86.0 / 59.0))
                    if pressing == 0 { withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) { pressing = 1 } }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { pressing = 0 }
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.fragrance.name), \(back ? "reverse with fragrance map" : "front")")
        .accessibilityHint("Double tap to flip")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { flip.flip() }
    }

    private func cardDrag(width w: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                let t = value.translation
                if axisLock == nil {
                    axisLock = abs(t.width) >= abs(t.height) ? .horizontal : .vertical
                    if axisLock == .horizontal { flip.begin() }
                }
                if axisLock == .horizontal {
                    flip.drag(degrees: Double(t.width / (w * 0.95)) * 180)
                } else {
                    pull = CGSize(width: t.width * 0.3, height: t.height > 0 ? t.height : t.height * 0.2)
                }
            }
            .onEnded { value in
                if axisLock == .horizontal {
                    flip.release(velocity: Double(value.velocity.width / (w * 0.95)) * 180)
                } else if value.translation.height > 120 || value.velocity.height > 900 {
                    close()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { pull = .zero }
                }
                axisLock = nil
            }
    }

    private var details: some View {
        let f = card.fragrance
        let rows: [(String, [String])] = [("TOP", f.top), ("HEART", f.heart), ("BASE", f.base)]
            .filter { !$0.1.isEmpty }
        return VStack(alignment: .leading, spacing: 8) {
            AtelierEyebrow(text: f.house, accent: palette.accent)
            Text(f.name)
                .font(.system(size: 30, weight: .regular, design: .serif))
                .tracking(-0.6)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text([f.concentration, f.year].filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.subheadline).foregroundStyle(.secondary)
            if rows.isEmpty {
                Text(f.archival ? "Historical edition. Notes are not verified." : "Notes not yet recorded.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(row.0)
                        .font(.system(size: 9, weight: .bold)).tracking(1.4)
                        .foregroundStyle(palette.accent)
                        .frame(width: 44, alignment: .leading)
                    Text(row.1.joined(separator: "  ·  "))
                        .font(.footnote)
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.85).delay(0.18 + Double(i) * 0.06),
                           value: appeared)
            }
            if let bottle { ownership(bottle) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ownership(_ bottle: BottleRecord) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(bottle.remaining * 100))% est.")
                    .font(.system(.subheadline, design: .rounded).monospacedDigit())
                GeometryReader { g in
                    Capsule().fill(.primary.opacity(0.12))
                        .overlay(alignment: .leading) {
                            Capsule().fill(palette.accent).frame(width: g.size.width * bottle.remaining)
                        }
                }
                .frame(height: 3)
            }
            .frame(width: 90)
            Divider().frame(height: 24)
            Text("\(bottle.wears.count) wears")
                .font(.subheadline.monospacedDigit())
                .contentTransition(.numericText(value: Double(bottle.wears.count)))
            if let last = bottle.lastWorn {
                Divider().frame(height: 24)
                Text(last, format: .relative(presentation: .named))
                    .font(.subheadline).foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 6)
        .opacity(appeared ? 1 : 0)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.36), value: appeared)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var actions: some View {
        HStack(spacing: 10) {
            if let bottle {
                Button {
                    if bottle.wornToday {
                        archive.undoTodayWear(bottleID: bottle.id)
                    } else {
                        archive.recordWear(bottleIDs: [bottle.id])
                        stamp += 1
                    }
                } label: {
                    Label(bottle.wornToday ? "Worn today · Undo" : "Wear today",
                          systemImage: bottle.wornToday ? "checkmark.circle.fill" : "drop")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.glassProminent)
                .tint(palette.accent)
                Button { editing = bottle } label: {
                    Label("Details", systemImage: "square.and.pencil")
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 36)
                }
                .buttonStyle(.glass)
            } else {
                Button {
                    archive.add(card.fragrance)
                    stamp += 1
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(420))
                        close()
                    }
                } label: {
                    Label("Add to my collection", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.glassProminent)
                .tint(palette.accent)
            }
            Button { flip.flip() } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Flip card")
        }
    }

    private func autoplay() async {
        try? await Task.sleep(for: .seconds(1.2))
        flip.begin()
        for step in 1...60 {
            flip.drag(degrees: 110 * Double(step) / 60)
            try? await Task.sleep(for: .milliseconds(9))
        }
        for step in 1...30 { // scrub back through edge-on without letting go
            flip.drag(degrees: 110 - 40 * Double(step) / 30)
            try? await Task.sleep(for: .milliseconds(9))
        }
        flip.release(velocity: 600)
        try? await Task.sleep(for: .seconds(1.6))
        flip.flip()
        try? await Task.sleep(for: .seconds(1.6))
        close()
    }
}

/// Shared keyframe value for the "stamp" a card or set makes when a wear is logged.
struct StampPose {
    var scale = 1.0
    var y = 0.0
}
