import SwiftUI

struct WelcomeScreen: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let openDemo: () -> Void
    let openMine: () -> Void
    @State private var ink: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 50)
                VStack(spacing: 12) {
                    Text("A  P E R S O N A L  F R A G R A N C E  A R C H I V E")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.3)
                        .foregroundStyle(.secondary)
                    ZStack(alignment: .leading) {
                        Text("Arooma")
                            .font(.custom("Snell Roundhand", size: min(84, geometry.size.width * 0.19)))
                            .italic()
                            .foregroundStyle(archive.theme.palette.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .mask(alignment: .leading) {
                                GeometryReader { rect in
                                    Rectangle().frame(width: rect.size.width * ink)
                                }
                            }
                        if reduceMotion {
                            Text("Arooma")
                                .font(.custom("Snell Roundhand", size: min(84, geometry.size.width * 0.19)))
                                .italic()
                                .foregroundStyle(archive.theme.palette.accent)
                        }
                    }
                    .frame(height: 116)
                    Path { path in
                        path.move(to: CGPoint(x: 26, y: 10))
                        path.addCurve(to: CGPoint(x: 260, y: 8),
                                      control1: CGPoint(x: 105, y: 34), control2: CGPoint(x: 200, y: -3))
                    }
                    .trim(from: 0, to: ink)
                    .stroke(archive.theme.palette.accent.opacity(0.75),
                            style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
                    .frame(width: 290, height: 32)
                    .accessibilityHidden(true)
                }
                Spacer(minLength: 48)
                VStack(spacing: 24) {
                    Text("A little ritual for the bottles you love.")
                        .font(.system(.title, design: .serif))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 35)
                    VStack(spacing: 12) {
                        Text("CHOOSE YOUR FINISH")
                            .font(.caption2.weight(.semibold))
                            .tracking(2)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 18) {
                            ForEach(FragranceTheme.allCases) { theme in
                                Button {
                                    withAnimation(.easeInOut(duration: reduceMotion ? 0 : 0.28)) {
                                        archive.theme = theme
                                    }
                                } label: {
                                    Circle()
                                        .fill(LinearGradient(colors: [
                                            theme.palette.field,theme.palette.secondary,theme.palette.accent
                                        ], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 43, height: 43)
                                        .overlay {
                                            Circle().strokeBorder(archive.theme == theme ? Color.primary : Color.clear, lineWidth: 2)
                                                .padding(-5)
                                        }
                                        .frame(minWidth: 52, minHeight: 52)
                                }
                                .accessibilityLabel(theme.rawValue)
                                .accessibilityAddTraits(archive.theme == theme ? .isSelected : [])
                            }
                        }
                        Text(archive.theme.rawValue)
                            .font(.system(.subheadline, design: .serif))
                        Picker("Appearance", selection: $archive.appearance) {
                            ForEach(Appearance.allCases) { value in Text(value.rawValue).tag(value) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 38)
                    }
                    VStack(spacing: 14) {
                        Button(action: openDemo) {
                            Text("Explore the Cards")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(archive.theme.palette.accent)
                        Button("Open My Collection", action: openMine)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .padding(.horizontal, 30)
                }
                Spacer(minLength: 35)
                Text("AN INDEPENDENT FRAGRANCE COMPANION")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                ink = reduceMotion ? 1 : 0
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.35)) { ink = 1 }
            }
        }
    }
}

struct InspectorScreen: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    let card: DisplayCard
    let close: () -> Void
    @State private var angle: Double = 0
    @State private var showOwned = false

    var body: some View {
        GeometryReader { geometry in
            let maxWidth = min(geometry.size.width - 32,
                               (geometry.size.height - 186) * 59 / 86)
            ZStack {
                ArchiveBackdrop(theme: archive.theme)
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.fragrance.house.uppercased())
                                .font(.caption2.weight(.semibold))
                                .tracking(2.1)
                                .foregroundStyle(archive.theme.palette.accent)
                            Text(card.fragrance.name)
                                .font(.system(.title2, design: .serif))
                        }
                        Spacer(minLength: 12)
                        Button(action: close) {
                            Image(systemName: "xmark")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 46, height: 46)
                        }
                        .controlGlass(corner: 23)
                        .accessibilityLabel("Close inspector")
                    }
                    .padding(.horizontal, 19)

                    Spacer(minLength: 0)

                    ZStack {
                        CollectibleCard(id: card.fragrance.id, side: .front, cornerRadius: 14)
                            .opacity(angle < 90 ? 1 : 0)
                        CollectibleCard(id: card.fragrance.id, side: .back, cornerRadius: 14)
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            .opacity(angle >= 90 ? 1 : 0)
                    }
                    .frame(width: maxWidth, height: maxWidth * 86 / 59)
                    .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.64)
                    .shadow(color: .black.opacity(0.38), radius: 27, x: 0, y: 20)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: flip)
                    .accessibilityLabel("\(card.fragrance.name), \(angle < 90 ? "front" : "fragrance map")")
                    .accessibilityHint("Double tap to flip collectible card")

                    Spacer(minLength: 0)

                    if card.fragrance.archival {
                        Text("HISTORICAL CARD ART · NOT ARCHIVE FOIL V3")
                            .font(.system(.caption2))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(angle < 90 ? "THE COLLECTIBLE" : "THE FRAGRANCE MAP")
                            .font(.system(.caption2, weight: .medium))
                            .tracking(1.6)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Button(action: flip) {
                            Label("Flip Card", systemImage: "arrow.triangle.2.circlepath")
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .controlGlass(corner: 18)
                        if archive.mode == .demo {
                            Button {
                                archive.add(card.fragrance)
                                close()
                            } label: {
                                Label("Add to Mine", systemImage: "plus")
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(archive.theme.palette.accent)
                        } else {
                            Button {
                                showOwned = true
                            } label: {
                                Label("My Bottle", systemImage: "drop")
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                            .controlGlass(corner: 18)
                        }
                    }
                    .font(.system(.subheadline, weight: .semibold))
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showOwned) {
            NavigationStack {
                if let bottle = archive.selectedBottle {
                    BottleEditor(bottle: bottle)
                } else {
                    ContentUnavailableView("Select your bottle", systemImage: "drop")
                }
            }
        }
    }
    private func flip() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.12) :
                        .spring(response: 0.58, dampingFraction: 0.88)) {
            angle = angle < 90 ? 180 : 0
        }
        // Flipping is intentionally silent: only selection, wears, and completed actions haptic.
    }
}
