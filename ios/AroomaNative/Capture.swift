import SwiftUI
import PhotosUI
import UIKit
import Vision

// MARK: - Capture draft
//
// Capture first, choose a destination second. The draft (name, photo file, what the label said)
// is written on every change, so it survives leaving the sheet or relaunching the app, and it is
// never lost by going back from the review step.

struct CaptureDraft: Codable, Equatable {
    var name = ""
    var house = ""
    var source = ""
    var notes = ""
    var photoFileName: String? = nil
    var recognized: [String] = []
    var barcodes: [String] = []
    var matchedID: String? = nil

    var isEmpty: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && photoFileName == nil
    }

    private static let key = "arooma.captureDraft"
    static func load() -> CaptureDraft {
        guard let data = UserDefaults.standard.data(forKey: key),
              let draft = try? JSONDecoder().decode(CaptureDraft.self, from: data) else { return CaptureDraft() }
        return draft
    }
    func save() {
        if let data = try? JSONEncoder().encode(self) { UserDefaults.standard.set(data, forKey: Self.key) }
    }
    static func clear() { UserDefaults.standard.removeObject(forKey: key) }
}

// MARK: - On-device label reading (Vision)

/// Reads printed text and barcodes from a still photo, entirely on device. Reading text is not
/// identifying a fragrance: the result is only used to suggest names and to look for matches in
/// Arooma's own bundled catalog and the owner's records.
enum LabelReader {
    static func read(_ image: UIImage) async -> (lines: [String], barcodes: [String]) {
        guard let cg = image.cgImage else { return ([], []) }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        return await Task.detached(priority: .userInitiated) { () -> ([String], [String]) in
            let text = VNRecognizeTextRequest()
            text.recognitionLevel = .accurate
            text.usesLanguageCorrection = false
            let codes = VNDetectBarcodesRequest()
            let handler = VNImageRequestHandler(cgImage: cg, orientation: orientation, options: [:])
            try? handler.perform([text, codes])
            let lines = (text.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            let barcodes = (codes.results ?? []).compactMap { $0.payloadStringValue }
            return (lines, Array(Set(barcodes)))
        }.value
    }

    /// Plausible name lines: short, mostly letters, de-duplicated, longest first.
    static func nameCandidates(_ lines: [String]) -> [String] {
        var seen = Set<String>()
        return lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                let letters = line.filter(\.isLetter).count
                return line.count >= 3 && line.count <= 40 && letters * 10 >= line.count * 6
            }
            .filter { seen.insert($0.lowercased()).inserted }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }
}

extension CGImagePropertyOrientation {
    init(_ o: UIImage.Orientation) {
        switch o {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

/// Matches recognized text or a typed name against fragrances Arooma actually has records for.
/// A match is only a candidate for the owner to confirm; nothing is inferred beyond the record.
enum CatalogMatcher {
    private static func tokens(_ s: String) -> [String] {
        s.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init).filter { $0.count >= 3 }
    }

    static func candidates(text: [String], in pool: [Fragrance]) -> [Fragrance] {
        let haystack = Set(text.flatMap { tokens($0) })
        guard !haystack.isEmpty else { return [] }
        let scored: [(Fragrance, Double)] = pool.compactMap { f in
            let name = tokens(f.name)
            guard !name.isEmpty else { return nil }
            let nameHit = Double(name.filter { haystack.contains($0) }.count) / Double(name.count)
            let house = tokens(f.house)
            let houseHit = house.isEmpty ? 0 : Double(house.filter { haystack.contains($0) }.count) / Double(house.count)
            let score = nameHit + houseHit * 0.5
            return nameHit >= 0.99 || score >= 1.0 ? (f, score) : nil
        }
        return scored.sorted { $0.1 > $1.1 }.prefix(3).map(\.0)
    }
}

// MARK: - Quick Add

struct QuickAddSheet: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft = CaptureDraft.load()
    @State private var libraryItem: PhotosPickerItem?
    @State private var cameraOpen = false
    @State private var reading = false
    @State private var photoFailed = false
    @State private var reviewing = false
    @FocusState private var typing: Bool
    let onAdded: () -> Void

    private var trimmed: String { draft.name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var pool: [Fragrance] { Fragrance.catalog + archive.customFragrances }
    private var typedSuggestions: [Fragrance] {
        guard trimmed.count >= 2 else { return [] }
        return Array(archive.matches(trimmed, scope: .demo).prefix(3))
    }
    private var labelMatches: [Fragrance] { CatalogMatcher.candidates(text: draft.recognized, in: pool) }
    private var matched: Fragrance? { draft.matchedID.flatMap { id in pool.first { $0.id == id } } }

    var body: some View {
        NavigationStack {
            Group {
                if reviewing {
                    ScanReview(draft: $draft, matched: matched, back: {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.86)) { reviewing = false }
                    }, finished: {
                        onAdded()
                        dismiss()
                    })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    capture
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .navigationTitle(reviewing ? "Where does it go?" : "Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                if !draft.isEmpty && !reviewing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Discard", role: .destructive) { discard() }
                    }
                }
            }
            .onChange(of: draft) { _, value in value.save() }
            .onChange(of: libraryItem) { _, item in
                Task {
                    if let bytes = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: bytes) {
                        await usePhoto(image)
                        photoFailed = false
                    } else if item != nil {
                        photoFailed = true
                    }
                }
            }
            .fullScreenCover(isPresented: $cameraOpen) {
                CameraCapture { image in
                    cameraOpen = false
                    Task { await usePhoto(image) }
                } onCancel: {
                    cameraOpen = false
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: Step 1: capture

    private var capture: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                preview.frame(maxWidth: .infinity).padding(.top, 4)
                TextField("Fragrance name", text: $draft.name)
                    .font(.title3)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.next)
                    .focused($typing)
                    .onSubmit(review)
                    .padding(14)
                    .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                HStack(spacing: 10) {
                    Button {
                        typing = false
                        cameraOpen = true
                    } label: {
                        Label("Take Photo", systemImage: "camera").frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.glass)
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    PhotosPicker(selection: $libraryItem, matching: .images) {
                        Label(draft.photoFileName == nil ? "Choose Photo" : "Change Photo", systemImage: "photo")
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.glass)
                }
                if reading {
                    Label("Reading the label on this iPhone…", systemImage: "text.viewfinder")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if photoFailed {
                    Label("That photo could not be read. Try another, or continue with the name only.",
                          systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.secondary)
                }
                matchesSection
                labelSection
                TextField("Recommended by, or where you found it (optional)", text: $draft.source)
                    .font(.subheadline)
                    .padding(12)
                    .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text("Only a name or a photo is needed. The draft is kept on this iPhone until you choose where it goes.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(20)
            .animation(reduceMotion ? nil : .snappy, value: draft.recognized)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button(action: review) {
                Label("Review", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.headline).frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.glassProminent)
            .tint(archive.theme.palette.accent)
            .disabled(draft.isEmpty && draft.matchedID == nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .onAppear { if draft.isEmpty { typing = true } }
    }

    @ViewBuilder private var matchesSection: some View {
        let candidates = (labelMatches + typedSuggestions).reduce(into: [Fragrance]()) { acc, f in
            if !acc.contains(where: { $0.id == f.id }) { acc.append(f) }
        }
        if !candidates.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                AtelierEyebrow(text: "Arooma has a record for", accent: archive.theme.palette.accent)
                ForEach(candidates) { fragrance in
                    Button {
                        draft.matchedID = draft.matchedID == fragrance.id ? nil : fragrance.id
                    } label: {
                        HStack(spacing: 12) {
                            AtelierCardSurface(fragranceID: fragrance.id, radius: 4, shadowed: false)
                                .frame(width: 30, height: 44)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(fragrance.name).font(.subheadline.weight(.medium))
                                Text("\(fragrance.house) · \(fragrance.concentration)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: draft.matchedID == fragrance.id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(archive.theme.palette.accent)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableCardStyle())
                    .accessibilityLabel("Use \(fragrance.house) \(fragrance.name)")
                    .accessibilityAddTraits(draft.matchedID == fragrance.id ? .isSelected : [])
                }
                Text("A possible match, not an identification. Confirm it only if it is the same bottle and concentration.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var labelSection: some View {
        let names = LabelReader.nameCandidates(draft.recognized)
        if !names.isEmpty || !draft.barcodes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                AtelierEyebrow(text: "Read from the label", accent: archive.theme.palette.accent)
                if !names.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(names, id: \.self) { line in
                                Button(line) { draft.name = line }
                                    .font(.caption)
                                    .buttonStyle(.glass)
                                    .accessibilityHint("Use as the fragrance name")
                            }
                        }
                    }
                }
                ForEach(draft.barcodes, id: \.self) { code in
                    Label("Barcode \(code). No product catalog is connected, so it is kept with your notes.",
                          systemImage: "barcode")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var preview: some View {
        let shown = matched ?? Fragrance(id: "personal-preview", house: draft.house.isEmpty ? "My Collection" : draft.house,
                                         name: trimmed.isEmpty ? "Your discovery" : trimmed,
                                         concentration: "", year: "", top: [], heart: [], base: [],
                                         shelf: .autumn, archival: false, photoFileName: draft.photoFileName)
        return CapturePreviewCard(fragrance: shown, photoFileName: matched == nil ? draft.photoFileName : nil)
            .frame(width: 150, height: 150 * 86 / 59)
            .shadow(color: archive.theme.shadowTint.opacity(0.4), radius: 18, y: 12)
            .rotation3DEffect(.degrees(-6), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .animation(reduceMotion ? nil : .snappy, value: trimmed)
    }

    // MARK: Actions

    private func usePhoto(_ image: UIImage) async {
        guard let jpeg = image.jpegData(compressionQuality: 0.84) else { photoFailed = true; return }
        let old = draft.photoFileName
        if let saved = archive.storeCapturePhoto(jpeg) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { draft.photoFileName = saved }
            if let old, old != saved, !photoInUse(old) { deletePhoto(old) }
        }
        reading = true
        let result = await LabelReader.read(image)
        reading = false
        draft.recognized = result.lines
        draft.barcodes = result.barcodes
        if trimmed.isEmpty, let best = CatalogMatcher.candidates(text: result.lines, in: pool).first {
            draft.matchedID = best.id
        }
    }

    private func review() {
        guard !draft.isEmpty || draft.matchedID != nil else { return }
        typing = false
        if !draft.barcodes.isEmpty, !draft.notes.contains("Barcode") {
            draft.notes = (draft.notes.isEmpty ? "" : draft.notes + "\n") + "Barcode: " + draft.barcodes.joined(separator: ", ")
        }
        withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.86)) { reviewing = true }
    }

    private func discard() {
        if let file = draft.photoFileName, !photoInUse(file) { deletePhoto(file) }
        draft = CaptureDraft()
        CaptureDraft.clear()
    }

    private func photoInUse(_ file: String) -> Bool {
        archive.customFragrances.contains { $0.photoFileName == file } ||
        archive.wishlist.contains { $0.photoFileName == file } ||
        archive.bottles.contains { $0.capturePhotoFileName == file }
    }

    private func deletePhoto(_ file: String) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(file)
        try? FileManager.default.removeItem(at: url)
    }
}

/// Card preview for a capture: the matched collectible, the owner's photo, or the personal card.
struct CapturePreviewCard: View {
    @EnvironmentObject private var archive: CollectionStore
    let fragrance: Fragrance
    let photoFileName: String?

    var body: some View {
        Group {
            if let photoFileName, let image = OwnerPhotoCache.image(at: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(photoFileName)) {
                Image(uiImage: image)
                    .resizable().scaledToFill()
                    .overlay(alignment: .bottomLeading) {
                        Text(fragrance.name)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    }
            } else if fragrance.id == "personal-preview" {
                PersonalCardArt(fragrance: fragrance)
            } else {
                AtelierCardSurface(fragranceID: fragrance.id, radius: 12, foil: .sheen, shadowed: false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("Preview of \(fragrance.name)")
    }
}

// MARK: - Step 2: scan review card
//
// One card, four directions, one outcome per gesture:
//   right → Collection · left → Wishlist · up → facts · down → back to capture (draft kept).
// Destinations are labelled while the finger moves; nothing commits until a deliberate release
// past the threshold. Buttons do the same. After a commit, Undo is offered.

struct ScanReview: View {
    @EnvironmentObject private var archive: CollectionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var draft: CaptureDraft
    let matched: Fragrance?
    let back: () -> Void
    let finished: () -> Void

    @State private var offset: CGSize = .zero
    @State private var axis: Axis?
    @State private var showFacts = false
    @State private var committed: Commit?
    @State private var previousMode: CollectionMode = .mine
    @State private var commitToken = UUID()

    enum Destination { case collection, wishlist }
    struct Commit {
        let destination: Destination
        let bottleID: UUID?
        let wishID: UUID?
        let createdFragranceID: String?
        let alreadyThere: Bool
    }

    private static let threshold: CGFloat = 110

    private var displayName: String {
        matched?.name ?? (draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unnamed fragrance" : draft.name)
    }

    var body: some View {
        let accent = archive.theme.palette.accent
        VStack(spacing: 14) {
            if let committed {
                confirmation(committed)
            } else {
                Text("Swipe right for Collection, left for Wishlist")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            Spacer(minLength: 0)
            ZStack {
                // Landing labels that teach the gesture as the finger moves.
                HStack {
                    landing("Wishlist", "heart.fill", active: offset.width < 0, progress: -offset.width / Self.threshold)
                    Spacer()
                    landing("Collection", "checkmark.seal.fill", active: offset.width > 0, progress: offset.width / Self.threshold)
                }
                .padding(.horizontal, 18)
                card
            }
            Spacer(minLength: 0)
            if showFacts { facts.transition(.move(edge: .bottom).combined(with: .opacity)) }
            if committed == nil {
                HStack(spacing: 10) {
                    Button { commit(.wishlist) } label: {
                        Label("Wishlist", systemImage: "heart").frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.glass)
                    Button { commit(.collection) } label: {
                        Label("Collection", systemImage: "checkmark.seal").frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(accent)
                }
                HStack(spacing: 10) {
                    Button(action: back) { Label("Back", systemImage: "chevron.down").frame(maxWidth: .infinity, minHeight: 32) }
                        .buttonStyle(.glass)
                    Button { withAnimation(.snappy) { showFacts.toggle() } } label: {
                        Label(showFacts ? "Hide facts" : "Facts", systemImage: "text.magnifyingglass")
                            .frame(maxWidth: .infinity, minHeight: 32)
                    }
                    .buttonStyle(.glass)
                }
                .font(.subheadline)
            }
        }
        .padding(20)
        .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.82), value: committed != nil)
    }

    private func landing(_ title: String, _ symbol: String, active: Bool, progress: CGFloat) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.title2)
            Text(title.uppercased()).font(.system(size: 10, weight: .bold)).tracking(1.2)
        }
        .foregroundStyle(archive.theme.palette.accent)
        .opacity(active ? Double(min(1, max(0.15, progress))) : 0.12)
        .scaleEffect(active && progress >= 1 ? 1.12 : 1)
        .animation(.snappy(duration: 0.18), value: active && progress >= 1)
        .accessibilityHidden(true)
    }

    private var card: some View {
        let shown = matched ?? Fragrance(id: "personal-preview", house: draft.house.isEmpty ? "My Collection" : draft.house,
                                         name: displayName, concentration: "", year: "", top: [], heart: [], base: [],
                                         shelf: .autumn, archival: false)
        return CapturePreviewCard(fragrance: shown, photoFileName: matched == nil ? draft.photoFileName : nil)
            .frame(width: 200, height: 200 * 86 / 59)
            .shadow(color: archive.theme.shadowTint.opacity(0.45), radius: 20, y: 14)
            .rotationEffect(.degrees(Double(offset.width / 18)), anchor: .bottom)
            .offset(offset)
            .opacity(committed == nil ? 1 : 0.35)
            .gesture(reviewDrag, including: committed == nil ? .all : .none)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(displayName)
            .accessibilityAction(named: "Add to Collection") { commit(.collection) }
            .accessibilityAction(named: "Add to Wishlist") { commit(.wishlist) }
            .accessibilityAction(named: "Show facts") { withAnimation { showFacts = true } }
            .accessibilityAction(named: "Back to capture") { back() }
    }

    private var reviewDrag: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let t = value.translation
                if axis == nil { axis = abs(t.width) >= abs(t.height) ? .horizontal : .vertical }
                offset = axis == .horizontal ? CGSize(width: t.width, height: t.height * 0.15)
                                             : CGSize(width: t.width * 0.1, height: t.height * 0.5)
            }
            .onEnded { value in
                let t = value.translation, p = value.predictedEndTranslation
                defer { axis = nil }
                if axis == .horizontal {
                    let reach = abs(t.width) > Self.threshold || abs(p.width) > Self.threshold * 2.2
                    if reach && (t.width > 0) == (p.width > 0) {
                        commit(t.width > 0 ? .collection : .wishlist)
                        return
                    }
                } else if axis == .vertical {
                    if t.height < -70 || p.height < -180 {
                        withAnimation(.snappy) { showFacts = true }
                    } else if t.height > 90 || p.height > 220 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { offset = .zero }
                        back()
                        return
                    }
                }
                withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) { offset = .zero }
            }
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let matched {
                AtelierEyebrow(text: "Arooma record", accent: archive.theme.palette.accent)
                Text("\(matched.house) · \(matched.name) · \(matched.concentration)").font(.subheadline)
                let rows = [("Top", matched.top), ("Heart", matched.heart), ("Base", matched.base)].filter { !$0.1.isEmpty }
                if rows.isEmpty { Text("Notes: Unknown").font(.footnote).foregroundStyle(.secondary) }
                ForEach(rows.indices, id: \.self) { i in
                    Text("\(rows[i].0): \(rows[i].1.joined(separator: ", "))").font(.footnote).foregroundStyle(.secondary)
                }
                if archive.isOwned(matched.id) { Label("Already in your collection", systemImage: "checkmark.seal").font(.caption) }
                if archive.isWishlisted(matched.id) { Label("Already on your Wishlist", systemImage: "heart").font(.caption) }
            } else {
                AtelierEyebrow(text: "Not identified", accent: archive.theme.palette.accent)
                Text("No matching record. Notes, concentration and house are Unknown until you add them; nothing is guessed.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if !draft.recognized.isEmpty {
                Text("Label text: " + draft.recognized.prefix(6).joined(separator: " · "))
                    .font(.caption).foregroundStyle(.tertiary).lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .atelierPlate(16)
    }

    private func confirmation(_ c: Commit) -> some View {
        HStack(spacing: 10) {
            Image(systemName: c.destination == .collection ? "checkmark.seal.fill" : "heart.fill")
                .foregroundStyle(archive.theme.palette.accent)
            Text(c.alreadyThere ? "Already there — selected it"
                 : (c.destination == .collection ? "Added to your collection" : "Saved to your Wishlist"))
                .font(.subheadline.weight(.medium))
            Spacer()
            Button("Undo") { undo(c) }.font(.subheadline.weight(.semibold))
            Button("Done") { finish() }.font(.subheadline)
        }
        .padding(12)
        .glassEffect(.regular, in: Capsule())
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: Commit / Undo

    private func commit(_ destination: Destination) {
        guard committed == nil else { return } // one commit per gesture or tap
        previousMode = archive.mode
        var created: String?
        let fragrance: Fragrance
        if let matched {
            fragrance = matched
        } else if let f = archive.makePersonalFragrance(name: draft.name, house: draft.house, photoFileName: draft.photoFileName) {
            fragrance = f
            created = f.id
        } else { return }
        let photoForRecord = matched == nil ? nil : draft.photoFileName
        switch destination {
        case .collection:
            let already = archive.isOwned(fragrance.id)
            let id = archive.addOwned(fragrance, notes: draft.notes, source: draft.source, photoFileName: photoForRecord)
            committed = Commit(destination: .collection, bottleID: already ? nil : id, wishID: nil,
                               createdFragranceID: created, alreadyThere: already)
        case .wishlist:
            let already = archive.isWishlisted(fragrance.id)
            let entry = archive.addToWishlist(fragrance, source: draft.source, notes: draft.notes, photoFileName: photoForRecord)
            archive.mode = .wishlist
            committed = Commit(destination: .wishlist, bottleID: nil, wishID: already ? nil : entry.id,
                               createdFragranceID: created, alreadyThere: already)
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            offset = CGSize(width: destination == .collection ? 420 : -420, height: 0)
        }
        // The draft has become a record; keep its photo file, clear the draft.
        CaptureDraft.clear()
        let token = UUID()
        commitToken = token
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if committed != nil && commitToken == token { finish() }
        }
    }

    private func undo(_ c: Commit) {
        archive.undoCapture(bottleID: c.bottleID, wishID: c.wishID, createdFragranceID: c.createdFragranceID)
        archive.mode = previousMode
        draft.save() // the draft comes back exactly as it was
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            committed = nil
            offset = .zero
        }
    }

    private func finish() {
        guard committed != nil else { return }
        committed = nil
        draft = CaptureDraft()
        CaptureDraft.clear()
        finished()
    }
}
