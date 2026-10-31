import SwiftUI

struct GalleryView: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var fingerTravel: CGFloat = 0
    let openInspector: (DisplayCard) -> Void
    let openAdd: () -> Void

    private var cards: [DisplayCard] { archive.displayedCards }

    var body: some View {
        GeometryReader { bounds in
            VStack(spacing: 8) {
                topLine
                    .padding(.horizontal, 23)
                    .padding(.top, 10)
                if cards.isEmpty {
                    emptyCollection
                } else {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(archive.selected?.fragrance.house.uppercased() ?? "THE ARCHIVE")
                                .font(.system(.caption2, weight: .semibold))
                                .tracking(2.2)
                                .foregroundStyle(archive.theme.palette.accent)
                                .lineLimit(1)
                            Text(archive.selected?.fragrance.name ?? "")
                                .font(.system(.title2, design: .serif))
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("\((cards.firstIndex(where: { $0.id == archive.selected?.id }) ?? 0) + 1) / \(cards.count)")
                            .font(.system(.caption, design: .rounded).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 26)
                    .padding(.top, 18)

                    gallery(in: bounds.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Collectible fragrance gallery")

                    VStack(spacing: 13) {
                        selectedDetails
                        primaryAction
                        layoutControl
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 10)
                }
            }
        }
    }

    private var topLine: some View {
        HStack(spacing: 12) {
            Text("Arooma")
                .font(.system(.title, design: .serif))
                .tracking(-0.5)
            Spacer()
            Button {
                archive.enter(archive.mode == .demo ? .mine : .demo)
            } label: {
                Label(archive.mode.rawValue, systemImage: "arrow.left.arrow.right")
                    .font(.system(.caption, weight: .semibold))
                    .frame(minHeight: 44)
                    .padding(.horizontal, 15)
            }
            .controlGlass()
            .accessibilityLabel("Switch from \(archive.mode.rawValue) collection")
        }
    }

    private var selectedDetails: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(archive.selected?.fragrance.concentration ?? "COLLECTIBLE")
                    .font(.system(.subheadline, weight: .medium))
                Text((archive.selected?.fragrance.top.prefix(3).joined(separator: " · ") ?? ""))
                    .font(.system(.caption))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if archive.selected?.fragrance.archival == true {
                Text("ARCHIVAL")
                    .font(.system(.caption2, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
            } else if archive.selectedBottle?.lowStock == true {
                Label("Low", systemImage: "drop")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Button {
                if let selected = archive.selected { openInspector(selected) }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .frame(width: 44, height: 44)
            }
            .controlGlass()
            .accessibilityLabel("Inspect selected card")
        }
    }

    @ViewBuilder private var primaryAction: some View {
        if archive.mode == .demo {
            Button {
                if let card = archive.selected { archive.add(card.fragrance) }
            } label: {
                Label("Add to My Collection", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(archive.theme.palette.accent)
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
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(archive.theme.palette.accent)
        }
    }

    private var layoutControl: some View {
        HStack(spacing: 8) {
            ForEach(CardLayout.allCases) { layout in
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.86)) {
                        archive.layout = layout
                    }
                } label: {
                    Text(layout.rawValue)
                        .font(.system(.caption, weight: archive.layout == layout ? .bold : .medium))
                        .foregroundStyle(archive.layout == layout ? .primary : .secondary)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .contentShape(Rectangle())
                }
                .accessibilityAddTraits(archive.layout == layout ? .isSelected : [])
            }
        }
        .padding(4)
        .controlGlass(corner: 22)
        .overlay(alignment: .topTrailing) {
            if archive.layout == .fan && !archive.rotations.isEmpty && archive.mode == .mine {
                Menu {
                    ForEach(archive.rotations) { rotation in
                        Button(rotation.name) { archive.rotationID = rotation.id }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .frame(width: 44, height: 44)
                }
                .offset(y: -54)
            }
        }
    }

    private func gallery(in size: CGSize) -> some View {
        let width = min(size.width * 0.67, 290, (size.height - 18) * 59.0 / 86.0)
        let active = cards.firstIndex(where: { $0.id == archive.selected?.id }) ?? 0
        return ZStack {
            ForEach(cards) { card in
                let index = cards.firstIndex(where: { $0.id == card.id }) ?? 0
                let distance = index - active
                if abs(distance) <= 2 {
                    cardPosition(card: card, distance: distance, width: width)
                        .zIndex(distance == 0 ? 20 : Double(10 - abs(distance)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 8)
                .updating($fingerTravel) { gesture, state, _ in state = gesture.translation.width }
                .onEnded { gesture in
                    let prediction = gesture.predictedEndTranslation.width
                    let threshold = max(36, width * 0.27)
                    guard abs(prediction) > threshold else { return }
                    let delta = prediction < 0 ? 1 : -1
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.86)) {
                        archive.move(delta)
                    }
                }
        )
        .accessibilityAction(named: "Next card") { archive.move(1) }
        .accessibilityAction(named: "Previous card") { archive.move(-1) }
    }

    private func cardPosition(card: DisplayCard, distance: Int, width: CGFloat) -> some View {
        let d = CGFloat(distance)
        let movement = fingerTravel / max(width, 1)
        let relative = d + movement
        let xOffset: CGFloat
        let tilt: Double
        let scale: CGFloat
        let yOffset: CGFloat
        switch archive.layout {
        case .coverFlow:
            xOffset = relative * width * 0.60
            tilt = Double(-relative * 38)
            scale = distance == 0 ? 1.0 : 0.8
            yOffset = distance == 0 ? -4 : 12
        case .stack:
            xOffset = relative * width * 0.14
            tilt = Double(relative * 5)
            scale = 1.0 - CGFloat(abs(distance)) * 0.085
            yOffset = CGFloat(abs(distance)) * 19
        case .fan:
            xOffset = relative * width * 0.47
            tilt = Double(relative * 11)
            scale = distance == 0 ? 1 : 0.84
            yOffset = CGFloat(abs(distance)) * 28
        }
        return CollectibleCard(id: card.fragrance.id)
            .frame(width: width, height: width * 86 / 59)
            .shadow(color: .black.opacity(distance == 0 ? 0.34 : 0.17),
                    radius: distance == 0 ? 24 : 11, x: 0, y: distance == 0 ? 18 : 9)
            .scaleEffect(max(0.7, scale))
            .rotation3DEffect(.degrees(tilt), axis: (x: 0, y: 1, z: 0), perspective: 0.62)
            .rotationEffect(.degrees(archive.layout == .fan ? Double(relative * 7) : 0))
            .offset(x: xOffset, y: yOffset)
            .animation(reduceMotion ? nil : .interactiveSpring(response: 0.36, dampingFraction: 0.86),
                       value: archive.selected?.id)
            .onTapGesture {
                if distance == 0 { openInspector(card) }
                else {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.86)) {
                        archive.choose(card)
                    }
                }
            }
            .accessibilityLabel("\(card.fragrance.house) \(card.fragrance.name)")
            .accessibilityHint(distance == 0 ? "Double tap to inspect card" : "Double tap to focus card")
    }

    private var emptyCollection: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 42, weight: .ultraLight))
                .foregroundStyle(archive.theme.palette.accent)
            GalleryHeading(text: "Every collection begins with one.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
            Text("Choose a fragrance from the catalog. Your personal notes and wears stay on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Explore Fragrances", action: openAdd)
                .buttonStyle(.borderedProminent)
                .tint(archive.theme.palette.accent)
                .frame(minHeight: 44)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
