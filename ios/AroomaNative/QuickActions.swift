import SwiftUI
import UIKit

// MARK: - My Collection quick actions (Native Navigation V3, section 2)
//
// Tap the My Collection tab and it opens normally. Press and hold it and a compact frosted column floats
// directly above it with three rows: Owned, Wishlist, Add. The menu switches collection
// views or starts capture; the card-level Wear Today action remains in the gallery.
//
// Wear logs today's wear for the owner-selected OWNED bottle at once, with no navigation, through the same
// `CollectionStore.recordWear(bottleIDs:)` path as every other wear. It never touches a sample-deck card,
// a Wishlist item or an arbitrary last-worn bottle.

// MARK: Wear availability and truth rules

enum QuickWearAvailability: Equatable {
    /// One owned bottle is selected and has not been worn today: Wear will log it.
    case ready(bottleID: UUID, name: String)
    /// That bottle was already logged today. The row reads "Worn today"; a repeat press cannot add a second.
    case alreadyWorn(name: String)
    /// No valid owned selection (empty collection, or the selected bottle was deleted).
    case unavailable

    static let unavailableReason = "Select a bottle in My Collection"
}

extension CollectionStore {
    /// The owner-selected owned bottle, validated against the bottle list. Deliberately NOT `selectedBottle`
    /// (which follows whatever deck is showing, so it can be a sample card on Explore or a Wishlist entry).
    var quickWearAvailability: QuickWearAvailability {
        guard let id = selectedMineID,
              let bottle = bottles.first(where: { $0.id == id }),
              let scent = fragrance(id: bottle.fragranceID) else { return .unavailable }
        return bottle.wornToday ? .alreadyWorn(name: scent.name) : .ready(bottleID: bottle.id, name: scent.name)
    }

    /// While My Collection's owned deck is on screen, the card in front IS the owner's selection, even if it
    /// was never swiped to (a first bottle has no stored selection yet). Does nothing in any other mode.
    func syncOwnedFocus() {
        guard mode == .mine, let id = selected?.bottleID, selectedMineID != id else { return }
        selectedMineID = id
    }
}

// MARK: Wear confirmation

/// "Worn today · Name" with Undo. Carries the session this press created, so Undo reverses only that session.
struct WearToastModel: Identifiable, Equatable {
    let id = UUID()
    let sessionID: UUID
    let name: String
}

struct WearToastView: View {
    let model: WearToastModel
    let undo: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .accessibilityHidden(true)
            Text("Worn today · \(model.name)")
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityIdentifier("wear-toast-text")
            Spacer(minLength: 4)
            Button("Undo", action: undo)
                .font(.subheadline.weight(.semibold))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityIdentifier("wear-toast-undo")
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(minHeight: 48)
        .atelierGlass()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("wear-toast")
    }
}

// MARK: The column

struct QuickActionsColumn: View {
    let owned: () -> Void
    let wishlist: () -> Void
    let add: () -> Void
    let wearNow: () -> Void
    let dismiss: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    static let width: CGFloat = 244
    static let rowHeight: CGFloat = 58
    static let height: CGFloat = rowHeight * 3 + 2

    private var plate: Color { scheme == .dark ? Color(hex: 0x332B31) : Color(hex: 0xF8EEE2) }
    private var surface: Color { scheme == .dark ? Color(hex: 0x231D24) : Color(hex: 0xF2E5D4) }

    var body: some View {
        VStack(spacing: 0) {
            QuickActionRow(symbol: "square.stack", title: "Owned", detail: nil, enabled: true,
                           id: "quick-action-owned", action: owned)
            Divider().padding(.leading, 56)
            QuickActionRow(symbol: "heart", title: "Wishlist", detail: nil, enabled: true,
                           id: "quick-action-wishlist", action: wishlist)
            Divider().padding(.leading, 56)
            QuickActionRow(symbol: "plus", title: "Add", detail: nil, enabled: true,
                           id: "quick-action-add", action: add)
         }
        .frame(width: Self.width)
        .background {
            // Frosted: a native material over the deck. Reduce Transparency and Increase Contrast get the
            // opaque plate, so legibility never depends on blur (same rule as the Insights tray).
            let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
            let gradient = LinearGradient(colors: [plate, surface], startPoint: .topLeading, endPoint: .bottomTrailing)
            if reduceTransparency || contrast == .increased {
                shape.fill(gradient)
            } else {
                shape.fill(.regularMaterial).overlay { shape.fill(gradient).opacity(0.55) }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(scheme == .dark ? 0.26 : 0.8),
                                            .white.opacity(scheme == .dark ? 0.06 : 0.25)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 0.8)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(scheme == .dark ? 0.34 : 0.16), radius: 20, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Collection quick actions")
        .accessibilityIdentifier("collection-quick-actions")
        .accessibilityAction(.escape) { dismiss() }
    }


}

struct QuickActionRow: View {
    let symbol: String
    let title: String
    let detail: String?
    let enabled: Bool
    let id: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .medium))
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 17, weight: .semibold))
                    if let detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: QuickActionsColumn.rowHeight, alignment: .leading)
            .contentShape(Rectangle())
            .opacity(enabled ? 1 : 0.55)
        }
        .buttonStyle(PressableCardStyle())
        .disabled(!enabled)
        // One element per row. The label is the action; the bottle name (or the reason Wear is off) is the value.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(detail ?? "")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(id)
    }
}

// MARK: The hold on the real tab-bar item

/// Attaches a press-and-hold recognizer to the system tab bar and reports it when the touch is on the
/// item titled `tabTitle`. SwiftUI's `TabView` gives a `Tab` no long-press hook, so this is the "compatible
/// UIKit tab-bar contextual interaction" the plan allows: the system tab bar is NOT rebuilt or replaced.
///
/// How it stays safe:
/// - The recognizer only begins when the touch lands on that one item, so every other tab, and a normal
///   tap on this one, behave exactly as before.
/// - It recognises alongside the tab bar's own gestures, and cancels the touch once it fires, so the hold
///   does not also select the tab. `AtelierRoot` additionally reverts any tab change that the hold itself
///   caused (belt and braces: this was validated only on the iOS 26 Simulator).
/// - The item is found by its accessibility label (public API). If the label is not found, thirds of the
///   bar are used (three equal tabs).
struct TabBarHoldRecognizer: UIViewRepresentable {
    let tabTitle: String
    let tabCount: Int
    let tabIndex: Int
    /// The item's frame in window coordinates when the hold is recognised.
    let began: (CGRect) -> Void
    let ended: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = ProbeView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        let coordinator = context.coordinator
        view.onWindow = { [weak view, weak coordinator] in
            guard let view, let coordinator else { return }
            coordinator.attachSoon(from: view)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let c = context.coordinator
        c.tabTitle = tabTitle
        c.tabCount = tabCount
        c.tabIndex = tabIndex
        c.began = began
        c.ended = ended
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class ProbeView: UIView {
        var onWindow: (() -> Void)?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil { onWindow?() }
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var tabTitle = ""
        var tabCount = 3
        var tabIndex = 1
        var began: (CGRect) -> Void = { _ in }
        var ended: () -> Void = {}
        private weak var bar: UITabBar?
        private var recognizer: UILongPressGestureRecognizer?
        private var attempts = 0

        /// SwiftUI builds the tab bar lazily, so look for it for a few seconds.
        func attachSoon(from view: UIView) {
            attempts = 0
            tryAttach(from: view)
        }

        private func tryAttach(from view: UIView) {
            guard recognizer == nil else { return }
            if let window = view.window, let found = Self.findTabBar(in: window) {
                install(on: found)
                return
            }
            attempts += 1
            guard attempts < 30 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self, weak view] in
                guard let self, let view else { return }
                self.tryAttach(from: view)
            }
        }

        private static func findTabBar(in view: UIView) -> UITabBar? {
            if let bar = view as? UITabBar { return bar }
            for sub in view.subviews {
                if let bar = findTabBar(in: sub) { return bar }
            }
            return nil
        }

        private static func findItem(in view: UIView, label: String) -> UIView? {
            if view.accessibilityLabel == label { return view }
            for sub in view.subviews {
                if let hit = findItem(in: sub, label: label) { return hit }
            }
            return nil
        }

        private func install(on bar: UITabBar) {
            let press = UILongPressGestureRecognizer(target: self, action: #selector(handle(_:)))
            press.minimumPressDuration = 0.45
            press.allowableMovement = 28
            press.cancelsTouchesInView = true
            press.delaysTouchesBegan = false
            press.delaysTouchesEnded = false
            press.delegate = self
            bar.addGestureRecognizer(press)
            self.bar = bar
            self.recognizer = press
        }

        func detach() {
            if let recognizer, let bar { bar.removeGestureRecognizer(recognizer) }
            recognizer = nil
            bar = nil
        }

        /// The item's frame in the bar's own coordinates, if `point` is on it.
        private func itemFrame(containing point: CGPoint, in bar: UITabBar) -> CGRect? {
            if let item = Self.findItem(in: bar, label: tabTitle) {
                let frame = item.convert(item.bounds, to: bar)
                if frame.width > 8, frame.insetBy(dx: -6, dy: -6).contains(point) { return frame }
                if frame.width > 8 { return nil }
            }
            // Fallback: equal thirds of the bar (three tabs, equal width).
            let count = max(1, tabCount)
            let width = bar.bounds.width / CGFloat(count)
            let frame = CGRect(x: width * CGFloat(tabIndex), y: bar.bounds.minY, width: width, height: bar.bounds.height)
            return frame.contains(point) ? frame : nil
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let bar = gestureRecognizer.view as? UITabBar else { return false }
            return itemFrame(containing: gestureRecognizer.location(in: bar), in: bar) != nil
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        @objc private func handle(_ gesture: UILongPressGestureRecognizer) {
            guard let bar = gesture.view as? UITabBar else { return }
            switch gesture.state {
            case .began:
                let local = itemFrame(containing: gesture.location(in: bar), in: bar) ?? bar.bounds
                began(bar.convert(local, to: nil))
            case .ended, .cancelled, .failed:
                ended()
            default:
                break
            }
        }
    }
}
