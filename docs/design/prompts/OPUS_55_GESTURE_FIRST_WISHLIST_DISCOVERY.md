# Claude Opus 5.5 implementation: Arooma gesture-first discovery, Wishlist and card intelligence

## Objective and workflow

You are the principal SwiftUI iOS interaction engineer and product architect for the native Arooma fragrance companion. Implement a **substantive, production-minded native interaction update**, not a website prototype, mockup, or planning-only exercise. Make existing cards more powerful without surrounding them with more buttons: focus on a coherent gesture grammar, a first-class **Wishlist**, shareable collectible card images, on-demand explainable insight, local camera capture/scan, reliable destination gestures, and rich search/filtering.

**Authoritative, complete acceptance spec:**
https://github.com/WGLewis0721/Arooma-App/blob/main/docs/design/specs/2026-10-31-gesture-first-wishlist-discovery.md

Read that file in full before editing, plus:
- docs/design/RULES_CARD.md
- docs/design/brand/BRAND_BOARD.md
- docs/design/specs/2026-10-31-native-premium-motion-interaction-system.md
- docs/design/specs/2026-10-30-unofficial-companion-strategy.md
- docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md
- current main implementation under ios/AroomaNative/

The current application has an existing physical gallery deck, Core Motion + Metal foil, Quick Add, Search, Today, Shelves, user photographs and layered wears. **Extend that architecture and preserve data**; do not replace the physical deck or reimplement already working functionality.

## Product experience to achieve

Arooma's loop is **Discover → Capture → Evaluate → Wishlist or Collection → Wear/Layer → Remember/Share → Repeat**. One fragrance identity follows the user through the loop; Wishlist and Owned are relationships/states, not two disconnected databases.

Consolidate actions into predictable, physics-consistent gestures:
1. In the **focused card**: horizontal drag browses; upward drag reveals contextual Insight (peek on short, expand on long); downward drag closes it; tap opens Inspector; long-press opens native actions including Share Image, Compare and Wear/Layer; pinch retains existing shelf overview. Card motion must follow the finger and preserve DeckMotor's interruptible momentum and center alignment.
2. In the **scan review**, after photo capture or typed entry: right swipe on the interior preview card chooses **Collection**, left chooses **Wishlist**, up opens notes/insights and down returns to the camera/previous view **without deleting the captured draft**. Show destination previews as the finger moves; commit only once on release after an intentional threshold; a small confirmation + Undo should follow.
3. Every gesture must have a discoverable **tap/Button/accessibility equivalent**. Respect safe areas, navigation/back/interactive dismissal and **never** try to override iOS bottom-screen Home/app-switcher, Control Center or notification gestures. Do not route the same drag into two competing actions.
4. Preserve card-first visual hierarchy with clean native sheets and context menus. No button farm, extra permanent toolbar or artificial full-screen onboarding explaining gestures.

## Native API mapping (use these capabilities where appropriate)

| Required behavior | Native capability / implementation direction |
| --- | --- |
| Unified directional gesture + short/long release | SwiftUI DragGesture, GestureState, axis locking, predicted velocity, explicit state machine; simultaneous/exclusive/sequenced gestures and existing DeckPhysics/DeckMotor, native spring animation |
| Contextual actions, preview and Undo | SwiftUI contextMenu and Button; system animations/haptics using sensoryFeedback or existing Core Haptics only at committed actions; in-app undo state |
| Insight peek/expand | One integrated card affordance + bounded drag detents; SwiftUI sheet presentationDetents if appropriate, but don't allow native sheet pull-dismiss to hijack gallery swipes |
| Camera photo and on-device label/barcode capture | Existing Quick Add + PhotosPicker; VisionKit DataScannerViewController in UIViewControllerRepresentable with supported/available + permission checks; still image Vision text/barcode recognition as fallback; AVFoundation only when custom camera necessary |
| Fragrance product identification | Explicit variant-specific match-provider interface and normalized local candidate data. Text recognition or barcode alone is not reliable fragrance identity. Handle ambiguous/no-match/unknown. **No invented external catalog endpoint or notes.** |
| Share collectible as PNG | SwiftUI ImageRenderer to render a deterministic static export view; Transferable and ShareLink or UIActivityViewController for share sheet; Photos framework only for user-initiated Save to Photos; protect user-only/private fields |
| Search and Yugioh-like filters | SwiftUI searchable, searchScopes, searchSuggestions, tokenized search if useful, Menu/Pickers for facets, local index, stable sort; test with hundreds of fixtures |
| Download stylized cards when online | Settings toggle default OFF, URLSession async/await, verified *licensed* asset manifest, integrity validation and persistent local cache; only activate after real asset licenses/provider and privacy decision |
| Accessibility and edge behavior | Accessible Buttons, accessibilityAction, FocusState, keyboard equivalents, VoiceOver, Reduce Motion/Transparency, target sizes and device safe-area respect |

Use native iOS 26 APIs when useful and verify compilation against the actual deployment target. Prefer one coherent interaction model over adding a technically fashionable API just to use it.

## Data migration and behavior requirements

- Change all user-facing "To Try" references to **Wishlist**. Create a first-class Wishlist relationship, timestamps and optional saved recommendation provenance. Wishlist items must never enter owned wear sessions until intentionally moved to Owned. Keep existing photos, personal notes, renamed shelves and layered combinations intact.
- Existing CollectionStore's quickAdd currently defaults to owned. Separate **capture** from **destination selection**: save the captured draft immediately and avoid committing to Owned until chosen, without breaking older app archives. De-duplicate cautiously by stable source/product/variant, not fuzzy name alone.
- On-demand Insight must say **similar to**, **possible layers**, **suggested season**, **occasions**, **known notes**, and **why**. Base this on verified catalog fields or the user's wear/impression history. Missing info remains Unknown; don't fabricate stats, "authenticity" or deterministic pairing truth. Provide an option to compare 2–3 cards without replacing the existing physical deck.
- Card exporting is a *static image* showing only eligible artwork and intentionally shared labels. Keep original approved art untouched; don't treat a live GPU holographic shader as the only way to rasterize a card. Do not export hidden ownership/price/notes/location metadata.
- Scanner should be fast: name or photo saved in roughly 10–15 seconds in a realistic device test. Recognition and enrichment are *optional follow-up*, never a save blocker.
- Settings: **Download stylized cards when online**, optional **Wi-Fi only**, a manual download action, disk usage and clear-cache; default OFF, show "unavailable" rather than pretend network content exists without an approved catalog/art manifest. Do not upload a private bottle photo without explicit permission.
- Search: name/house/notes/accord/concentration/season/occasion/Owned/Wishlist/Tested/favorites/last worn/remaining/layer-use with AND facets, result counts, clear all, and stable sort. Reuse native Search destination and existing local records.

## Execution order and constraints

**Step 1. Repo inspection and design verification.** Check current main and recent native motion PRs. Inventory actual data types and UI; identify gesture collisions and a minimal additive migration. Confirm which features are already implemented. Record missing metadata and licensed-art dependencies, and don't claim a real product database exists if it doesn't.

**Step 2. A working native vertical slice.** Implement one card's insight peek/expand, share-image generation with actual system share sheet, offline photo/typed-name scan review with right/left/up/down actions and Undo, first-class Wishlist/Owned, and scoped searchable filtering. Use clearly labeled local fixtures where a real authoritative source does not exist. No backend calls, mock facts portrayed as verified, or paid features.

**Step 3. End-to-end integration.** Extend capture, gallery, Inspector, Today, shelves and native Search around one stable fragrance identity. Implement confidence-checkable metadata provider interface and a conservative download settings UI with default OFF. Make the full loop work without starting from a fictional sample catalog.

**Step 4. Performance, quality and release evidence.** Write pure model tests for migration, match ambiguity, dedup, filtered search, drag state/thresholds, Undo and image export. Run native simulator xcodebuild and repo docs/tests. Record actual iPhone behavior where device access exists; otherwise label simulator-only and provide a detailed physical-device checklist. Confirm no negative impact on deck physics/Metal foil smoothness.

## Definition of done

- On a physical iPhone, the selected card's horizontal and vertical gestures have clear, non-colliding outcomes; tap and accessibility paths work; OS reserved edge swipes remain intact.
- In scan review, **left → Wishlist, right → Collection, up → Insight, down → Back**, with visible feedback and one safe commit per swipe, supported buttons and Undo. Ambiguous/no-match paths preserve the photo/name.
- A card can be exported as a crisp PNG through Apple's share sheet without leaking private metadata. Exported art is eligible for sharing.
- Owned, Wishlist, and optionally Tested are correct categories of one fragrance; migrations are idempotent and previous user records are retained.
- Search filters correctly and fast on a large seeded dataset; insight explanations are honest and sourced or clearly marked as suggestions.
- The existing holographic/gallery/swipe/flip experience remains responsive; no new app tabs or mandatory long-form user flows.
- Network metadata and stylized-card downloads are disabled unless a legitimate provider and per-asset rights are in place. A clear, working local-first version should ship even if these integrations remain blocked.

## Deliverables

Open a reviewable PR **targeting main, without merging or pushing a TestFlight build unless separately instructed**. Include modified Swift files, tests, updated docs/decision record, before/after interaction recordings, source/permission assumptions, and exact user instructions for a 60-second device smoke test. Report which requirements passed, which have only simulator verification and which require an external catalog/license. Do not stop at a plan; build the best truthful, working native version possible now.

**Priority:** One physical object, many intuitive behaviors. Fewer controls, more capability, zero fake intelligence.
