# Spec: Gesture-first discovery, Wishlist, card sharing and fragrance intelligence

> Part of the [Arooma design brain](../README.md). Prepared for the existing native iOS 26 SwiftUI target. Read [the spec protocol](../PLAN_SPEC_PROTOCOL.md), [the rules card](../RULES_CARD.md), the [brand board](../brand/BRAND_BOARD.md), the [native physics spec](2026-10-31-native-premium-motion-interaction-system.md), and the [independent companion strategy](2026-10-30-unofficial-companion-strategy.md).

| | |
| --- | --- |
| Request | Consolidate multiple card behaviors into one or two intuitive gestures. Rename To Try to Wishlist; share cards as images; offer contextual comparisons; scan bottles for details and move to Wishlist or Collection; enable authorized stylized-card downloads; implement card-database-level search and filters. |
| Restated | An iPhone fragrance enthusiast captures, evaluates, saves, shares, compares and organizes bottles through a small number of predictable direct interactions, with native accessibility alternatives. |
| Surface | Native Collection/Deck, Card Inspector, Scan/Quick Add, Wishlist, Search, Insight sheet, Settings, Share Sheet |
| Size | L, cross-app data and interaction work |
| Author | ChatGPT for Arooma, 2026-10-31 |
| Status | **Implementation specification; not built by this document** |
| Governing docs read | docs/design/RULES_CARD.md; docs/design/brand/BRAND_BOARD.md; docs/design/PLAN_SPEC_PROTOCOL.md; docs/design/packs/spec-writing.md; docs/design/specs/2026-10-30-unofficial-companion-strategy.md; docs/design/specs/2026-10-31-native-premium-motion-interaction-system.md |

## 1. Problem

[Owner] A fragrance enthusiast sees a bottle in a store, hears a recommendation, checks reviews, and wants the bottle in Arooma without filling in a long form. If already owned, they want its place in their cabinet; otherwise, a Wishlist entry and meaningful facts. While browsing their physical-feeling cards, they want immediate insight, images to send to a friend, and a compact way to find bottles by family/notes/occasion. The app must do more *with* a card, not surround it with more buttons. But overloaded swipes with hidden or unpredictable outcomes make an interface worse, not better.

**Product loop:** Discover → Capture → Evaluate → Wishlist or Collection → Wear/Layer → Remember/Share → Repeat. A fragrance is one record that changes relationship/state; not two unrelated records.

## 2. Evidence and context

- [Repo] Native SwiftUI application under ios/AroomaNative, bundled approved card masters; existing CollectionStore.swift, Models.swift, AtelierGallery.swift, AtelierSections.swift, AroomaApp.swift, DeckPhysics.swift, DeckMotor.swift and HoloFoil.metal.
- [Repo] Quick Add accepts typed names and bottle photographs; name-only unmatched search results can be saved, **currently as owned**. CollectionStore saves owned bottles, sessions, shelves, custom fragrances, and layered combinations. Existing basic search checks house/name/concentration/notes. No first-class Wishlist, verified real-world product lookup, share-image pipeline, or comprehensive facets were verified in source.
- [Repo] Owner-approved media usage and independent catalog strategy: docs/design/specs/2026-10-30-unofficial-companion-strategy.md; brand/THIRD_PARTY_CONTENT_POLICY.md. The current catalog is a small approved/demo set, not a comprehensive verified perfume index.
- [Apple] SwiftUI DragGesture, GestureState, composed exclusive/simultaneous/sequenced gestures and Button actions support stateful input. https://developer.apple.com/documentation/swiftui/composing-swiftui-gestures
- [Apple] VisionKit DataScannerViewController recognizes camera text and barcodes where supported, with permission and availability checks. It **does not identify a perfume or supply olfactory notes**. https://developer.apple.com/documentation/visionkit/datascannerviewcontroller
- [Apple] SwiftUI ImageRenderer renders an image from a view; ShareLink uses Transferable to present system sharing. https://developer.apple.com/documentation/swiftui/imagerenderer ; https://developer.apple.com/documentation/swiftui/sharelink
- [Apple] searchable, searchScopes, search suggestions and tokens can support layered faceted search. https://developer.apple.com/documentation/swiftui/search
- [Apple] iOS system Home indicator, app switcher and interactive-dismiss gestures belong to the OS; do not attempt to intercept bottom-edge swipes or copy their exact behavior.

## 3. Goals, non-goals and budget

**Goals**
1. Extend the **same card object** with direct manipulation, insights, details, sharing and context actions. Clear gesture ownership, discoverable signifiers, and accessible equivalent actions.
2. Distinguish **Wishlist**, **Owned**, and optionally **Tested** as user relationships to a stable product identity. Wishlist is the canonical name everywhere; replace the older "To Try" terminology.
3. One-screen photo/text capture, on-device OCR/barcode scanning, *verified* catalog identification when data exists, honest fallback when it does not, and one deliberate destination action. Never force a network request before saving.
4. Card image export via iOS share sheet and optional Photos save, without screenshotting the whole app or exporting private ownership records by default.
5. Contextual "Insight" offers quick **similar to**, **layers with**, **best season**, **occasion** and overlap indications with sources/confidence/subjectivity noted. No fabricated fragrance data or counterfeit-authenticity claim.
6. Yu-Gi-Oh-style *search depth*, not copying another app's UI: field/term search, facets, sort, counts, saved presets where appropriate, and responsive results.
7. Existing deck physics, user collections, named shelves, wears, layers, photos and local-first privacy must remain intact.

**Non-goals**
- No forced account, speculative public scraping, automatic ingestion of manufacturer imagery, instant worldwide fragrance recognition, affiliate commerce, shipping purchases, paywall, generic chatbot, permanent extra navigation tabs, or full external card-database clone.
- Do not interpret Apple-style gesture consolidation as taking control of Home/app-switcher gestures.
- Avoid a modal on every swipe, accidental purchases/ownership changes, or random "AI" recommendations without evidence.

**Appetite:** Large but staged: Phase 0 gesture and data foundation; Phase 1 Wishlist/share/filter/insight from known data; Phase 2 camera + reliable catalog lookup; Phase 3 opt-in licensed card downloads. Shipping each phase requires its own tests.

## 4. Rules that apply and exceptions needed

| Rule and document | Application |
| --- | --- |
| docs/design/RULES_CARD.md Look | Cards remain the visual focus. Original approved image masters stay untouched. No new decorative controls or fonts. |
| docs/design/RULES_CARD.md Behavior | Keep DeckMotor's continuous momentum, three presentations, persistent selection, and reduced-motion/tap alternatives. No repeated haptics during drag. |
| docs/design/brand/BRAND_BOARD.md V2 appearance | Preserve existing palettes, calligraphic wordmark, system typography and readable collectible art. |
| docs/design/specs/2026-10-31-native-premium-motion-interaction-system.md | One unified card pose, working tilt-reactive foil, interruption-safe zoom/inspect. No duplicate independent gesture animation engine. |
| docs/design/specs/2026-10-30-unofficial-companion-strategy.md | Product facts, origin/variant data, commercial brand imagery and user photos have separate provenance/rights rules. |
| docs/design/PLAN_SPEC_PROTOCOL.md | Deliver labeled assumptions, measurable tests, privacy, fallbacks and separate implementation review. |

**Exceptions needed and owner-authorized direction:** This request authorizes planning a new **opt-in network catalog query and downloadable card assets** even though the existing default app is offline-only. Network catalog, per-image rights, source terms, privacy policy and any licensed content still need independent decisions and implementation review. No blanket license or right to share manufacturer artwork is inferred. No third-party SDK or subscription entitlement is automatically approved by this spec. New native data types and storage keys are permitted if backward compatible.

## 5. Options and the chosen concept

### Options considered

| Option | Experience | Advantage | Cost/risk |
| --- | --- | --- | --- |
| A. More buttons | A full toolbar on each card for wishlist, compare, export, scanner | Obvious | Destroys card hierarchy; slow repetitive taps |
| B. Secret multi-swipe commands | Different flicks dispatch every action, no visible controls | Clean screenshots | Fragile, inaccessible, collisions and accidental state changes |
| C. Context-first physical card + progressive actions | One card surface: tap/drag/pinch/hold; lightweight insight tray, explicit action landing targets in scan review, Share as system action | Predictable, tactile, spacious, accessible | Requires gesture arbitration and view-state testing |

**Chosen C.** Use only gestures with clear object intent and visible feedback; critical actions always have tap, VoiceOver and keyboard alternatives. Reject A as cluttered and B as brittle.

### Breadboard of the chosen concept

1. **Collection/Cabinet:** Cards remain center stage. Horizontal drag browses adjacent cards; tap focused card opens Inspector; swipe **up on the focused card** reveals Insight. Short upward drag settles an insight peek; longer upward drag settles into expanded insights, not a different unrelated screen. Swipe down collapses the peek. Hold reveals standard contextual menu (Share Image, Compare, Wear/Layer, Add/Move); pinch opens the existing shelf overview. Discoverability: a subtle "Insights" grabber appears when a card is focused, with VoiceOver/tap alternative.
2. **Inspector:** Horizontal drag scrubs the 3D front/back flip; vertical down dismisses only when not editing/scrolling. System close remains. Insight expandable within inspector, never compete with flip. Share action available in context menu or sheet.
3. **Scan/Quick Add:** Capture photo using camera or import; on-device text/barcode candidates are parsed into *candidate identifiers*. First persist draft immediately. Review a single card with name, concentration and source/verification; tap to correct ambiguity. **Swipe right inside the preview card** commits **Collection**; **swipe left** commits **Wishlist**; **swipe up** expands insights/notes; **swipe down** returns to camera or prior view without discarding the draft. Destination landing labels are visible while dragging; commit only after crossing threshold on release, show confirmation with **Undo**, and never trigger another action from that same gesture. Non-swipe buttons remain in the review sheet as an alternative.
4. **Wishlist:** A filtered collection state, not a second unrelated fragrance database. A recommendation can have source URL/person/timestamp/notes, "Tested" observation, and a move-to-owned action. Moving to Owned preserves identity, notes, photos, and acquisition history. An owned fragrance may optionally remain tagged Wishlisted for another size/variant only by explicit choice.
5. **Insight/Quick Compare:** Shallow peek shows season, known notes/families, one closest-owned match and one possible layer. Expanded view shows similarities and differences with source labels, reason strings, and a simple compare tray for 2–3 cards. "Layers well" is a **suggestion** based on known accord/notes and/or the user's successful pairings, not chemical compatibility or an objective guarantee.
6. **Share image:** Context menu Share → native share sheet carrying a rendered PNG of the **selected collectible card only**. Include explicit variants for a single card, selected shelf, or saved layered combination as future options; don't expose diary notes, purchase price, private person/contact info or metadata by default. Use only rights-cleared/publicly shareable art; owner photos require an explicit share decision.
7. **Search:** Preserve the existing native Search destination and offer a two-level UX: instant simple query + expandable advanced filters. Scope Owned / Wishlist / Tested / All; facets brand, note, accord, concentration, season, occasion, favorites, last worn, remaining estimate, used-in-layer; logical AND across facets; clear-all; stable sorting; result counts; persist optional saved searches. Unknown values are **Unknown**, not silently guessed.
8. **Settings / Offline card downloads:** Toggle **Download stylized cards when online** (default **Off**), separate **Wi-Fi only** option, Download now and clear-cache actions, progress/failure detail and disk usage. Preview metadata can arrive without licensed art. Download only content backed by an approved distribution license/owner permission; never infer a card is available because the internet is connected. Cache scoped to rights/ID/version, validate checksums and avoid overwriting personal photos.

### Interaction ownership and native capability matrix

| Context + input | Single intended outcome | Actual iOS / SwiftUI capability | Arbitration / accessible alternative |
| --- | --- | --- | --- |
| Gallery horizontal drag | Browse a single adjacent card, velocity-aware settle | Existing DeckMotor/DeckPhysics; DragGesture, GestureState, predicted end / velocity, CADisplayLink where already used | Axis-lock once direction crosses threshold; tapping neighbor or accessibility increment/decrement |
| Focused card vertical short/long upward drag | Peek / expand Insight based on distance and predicted velocity | DragGesture, view-state detents, spring animation; optionally system sheet presentationDetents for expanded view | Don't begin if movement is horizontal; labeled Insights button or accessibility custom action |
| Focused card long press | Context actions | SwiftUI contextMenu, Button, optional sequenced long-press/drag | Button action for Share/Compare; don't steal VoiceOver double tap |
| Gallery two-finger pinch | Existing spatial shelf overview | MagnifyGesture, simultaneous/exclusive recognition with deck drag; current ShelfOverview | Visible Shelves route; no competing drag commit |
| Inspector horizontal vs vertical swipe | Flip vs dismiss | Existing FlipMotor; DragGesture axis lock; presentation dismissal API | Visible Flip and Close; do not override system sheet-edge behavior |
| Scan live label text / barcode | OCR and candidate identifiers | VisionKit DataScannerViewController via UIViewControllerRepresentable (when supported), or still-image Vision recognize-text/barcode requests | Camera permission, isSupported/isAvailable, PhotosPicker, manual name entry |
| Scan review card right/left | Save to Owned / Wishlist | DragGesture state, threshold on release, target highlighting, discrete sensoryFeedback/Core Haptics at commit | Visible Add to Collection / Add to Wishlist controls and Undo |
| Scan review upward/downward swipe | Expand facts / back to camera | DragGesture with axis-lock, sheet detents, native dismiss with draft preserved | Insights and Back buttons |
| Share card as image | Export collectible PNG to share sheet | ImageRenderer creates bitmap from offscreen deterministic card/export view; Transferable image/file via ShareLink or UIActivityViewController | Share contextMenu item; VoiceOver Share action; no accidental ownership metadata |
| Save image to Photos | Persist rendered image on device with authorization | Photos framework (PHPhotoLibrary) or system share sheet Save Image action | Save Image is user initiated; failure/denied permission handled |
| Advanced collection search | Text + grouped facets and sort | SwiftUI searchable, searchSuggestions, searchScopes, optional tokenized searchable; native Picker/Menu for facets | VoiceOver announces result count; clear filters |
| Online metadata and licensed artwork | Update candidate and cache offline | URLSession async/await, Codable, cache manifest, file storage, NWPathMonitor optional for hints | Explicit consent; handle unknown/failed/offline; no silent uploads |

**Critical constraint:** Recognizing text (e.g., "Sauvage") or barcode is NOT guaranteed identification of brand, concentration, batch or notes. The app needs an authorized, variant-specific product index, source links, a confidence/match rule and an explicit user confirmation for uncertain or multiple candidates. If no catalog is available, show recognized text, keep the photo/name draft, and offer both destinations without invented details.

### States

- **First run:** no known bottles, sample/demo separate from Owned; clear Quick Add + Wishlist entry.
- **Empty Wishlist/Owned/Tested:** no empty black screen; contextual capture prompt.
- **Scan permission denied/camera unsupported:** photo library, paste/type name and save draft.
- **Scan ambiguous/no match:** show candidate list or "Unknown fragrance" with visible editable text, never hallucinated notes.
- **Network absent/timeout:** local draft remains usable; no blocked save; optionally retry lookup.
- **Online metadata loaded but art not licensed:** factual details available; generic/user photo card, "Artwork unavailable".
- **Download toggled off or low power:** existing cards stay; no background high-cost activity.
- **Share unavailable/renderer error:** clear retry, no private data leak or blank image.
- **Duplicate product / different concentration / bottle size:** explicit choices; preserve existing identity, do not collapse variants incorrectly.
- **Gesture interrupted, reversed or uncertain:** spring back without mutation; no double commit.
- **Undo destination:** restore previous relationship state, including previous shelf and notes.
- **Low-stock or empty notes:** show estimates and unknown values honestly; no fabricated facts.
- **Large collection (500+ records):** lazy results, smooth filters, stable sort and voice access.
- **Stored image rights revoked:** withdraw download/display eligibility without deleting owner's metadata or personal capture.

## 6. Platform behavior

- **Widths/orientation:** test 375, 390 and 430 pt portrait layouts, smaller Dynamic Type truncation, landscape and large Dynamic Type; preserve safe areas. This is an iOS 26 native app, **not** the legacy Safari/PWA.
- **System gesture precedence:** never attempt to replace or capture swipe up from the Home indicator, bottom safe-area system navigation, Control Center/Notification Center edges, system interactive dismissal, or OS app switcher. All directional actions originate **within the clearly interactive scan/card region**.
- **Gesture resolution:** one event may select exactly one branch by axis, intent, threshold and velocity; per-surface state machine: idle → tracking → preview → commit/cancel. Prefer visuals that teach actions while the finger moves rather than post-hoc surprise.
- **Accessibility:** 44 pt minimum tap targets; alternate Buttons, contextMenu actions, accessibilityAction/custom actions, VoiceOver labels/hints, Dynamic Type, Switch Control/keyboard support. No essential feature is gesture-only, color-only, tilt-only or long-press-only.
- **Motion:** reduced motion substitutes static/predictable presentation; haptics occur only on a real state commit, not every frame; existing card momentum preserved.
- **Privacy:** camera recognition can be local; explicit opt-in before metadata query involving captured photo/barcode/text, and preferably transmit normalized confirmed product identity only. No image upload by default. Set camera/Photo permissions only as required. No personal collection records uploaded to download card art.
- **Appearance:** use existing system light/dark and four branded palettes, approved signature and collectible masters; avoid new colors/fonts/illustration style unless separately approved.

## 7. Technical approach

**Current foundations:** ios/AroomaNative/AtelierGallery.swift (deck/inspector gestures), AtelierSections.swift (Search, Today, Quick Add, Shelves, Style), AroomaApp.swift (native tab routing), CollectionStore.swift (local archive), Models.swift (Codable identity), DeckMotor.swift, DeckPhysics.swift, MaterialLight.swift and HoloFoil.metal.

**Recommended modules, names illustrative:**
- FragranceIdentity.swift: source-safe canonical product ID + house + name + concentration + size/variant + optional metadata with provenance timestamp and confidence. Separate display text from verified attributes.
- FragranceRelationship.swift: user's state set: Wishlist / Owned / Tested, timestamps, source URL/person (locally stored), notes and photo references. Do not use a Boolean that conflates wishlisted with owned.
- CapturePipeline.swift: camera, VisionKit/Vision OCR/barcodes, de-dup, local draft, match provider protocol, consent and manual correction. Separate local Vision work from optional URLSession provider; no guessed endpoint.
- GestureCoordinator.swift: surface-specific axis lock, bounded detents, predicted velocity and commit/undo intent; extend existing physics instead of duplicating it.
- FragranceInsight.swift: deterministic, transparent rules from factual notes/accords, existing favorites/history, explainable "suggested" season and layering; unknown remains unknown.
- CardExport.swift: immutable export composition + ImageRenderer bitmap and Transferable representation, file-scoped temporary export, system ShareLink. Ensure only approved pixels/metadata go out.
- CollectionSearchIndex.swift: normalized local search and indexed filter facets, multi-select AND semantics, stable sort + saved predicates.
- DownloadedCardStore.swift: explicit licensed manifest, URLSession, SHA-256/checksum validation, cache limit, versioning and Settings toggle.
- Existing CollectionStore stores identity, relationships, tested observations and any cached references; migrations should be additive with optional Codable keys and round-trip tests. Previous saved custom fragrances, BottleRecords, WearSessions, layered presets and shelf names must survive unchanged. Use the exact target bundle identifier com.graymatter.arooma.

**Source reality:** Arooma currently has no verified remotely hosted catalog endpoint or per-card redistribution license in the inspected repo. Provide a protocol plus local fixtures for a demonstrable camera→candidate→choose flow. **Do not call it universal auto-identification until a real source is licensed, integrated and tested.** Keep downloads OFF until the manifest/rights basis is approved.

**File-system/source changes:** an app image export must be accessible for the iOS share sheet; preserve original art masters and separate cacheable licensed art from user-owned photos. If the user expects Save to Photos, implement Photos framework permission/error states; system share Save Image may serve as simpler fallback.

**Performance:** compose exported card images offscreen and on demand, never on every render frame; cache thumbnails; scan with appropriate quality/energy profile, suspend camera when hidden; index/facet search work away from animation loop. Avoid costly Metal foil snapshots when an approved static image composite suffices.

**Network/privacy & rights:** no implicit sharing of photos, personal notes or inventory. Product/source metadata and manufacturer photos have separate licensing. Implement explicit notice/consent and documented data handling before network rollout. App Store media policy and privacy review required for distribution.

## 8. Risks, rabbit holes and open questions

| Item | Impact | Proposed default | Owner |
| --- | --- | --- | --- |
| Unknown product/notes catalog | Scan appears magical but produces false claims | Offline OCR + editable candidate; provider protocol; opt-in real lookup only after source selection | Product/content owner |
| Image rights | Download/share could redistribute unlicensed material | Only owner-created, licensed or distribution-approved art, track license per asset | Owner + legal |
| Unintuitive gesture collisions | Accidental save or lost browse | Dedicated interaction region and one axis-locked gesture owner with visual preview, Undo and buttons | UX/engineer |
| Real image export fidelity | Foil may look different as static PNG | Export approved static composite; test pixel dimensions and alpha, no need to simulate live holography | Designer |
| Insights misleading | "Best season" sounds objective | Label as suggestion; show basis and "Unknown" instead of confident ranking | Product owner |
| Wishlist/Owned migration | Historical bottles vanish or duplicate | Stable identity, additive relationship state, migration idempotence tests | Engineer |
| Additional backend/monetization | Cost and privacy obligations | No deployment or billing in this spec; later explicit decision | Owner |
| Settings toggle behavior | User assumes unlimited internet cards | Feature-gate toggle unless licensed manifest exists; clear download errors and storage controls | Product owner |
| System gesture collision | App interferes with OS navigation | No gestures originating at Home/other reserved screen edges | Engineer |
| Approximate barcode identification | Incorrect concentration/size | Lookup by variant; show candidate confirmation; never silently resolve close matches | Content owner |

## 9. Verification and prototype plan

### Acceptance criteria

1. **Navigation:** Given a selected gallery card, horizontal swipe browses one card; vertical short swipe reveals Insight peek; longer swipe expands Insight; downward swipe collapses. A clear visible action alternative gives the same result with VoiceOver. No false triggers when changing direction.
2. **System-safe gesture:** Repeating native Home, app switcher, back/close and system sheet gestures 30 times does not trigger an Arooma action.
3. **Capture:** In 10–15 seconds, a test user can take a photo or type a name, save a draft offline and retain it after app relaunch.
4. **Scan destination:** From an identified or unknown bottle draft, a right swipe inside the preview selects Collection, left selects Wishlist, up shows details, down goes back; at most one commit per gesture, a visible button duplicates each, and Undo works.
5. **Model integrity:** A Wishlist item remains in Wishlist until explicitly acquired; converting it to Owned preserves photo, source and notes, never creates a duplicate identity by accident; none of the prior owned records are reclassified.
6. **Insight credibility:** Every surfaced similarity, season, layering suggestion or notes field has a deterministic basis and label; unknown or unmatched metadata remains unknown.
7. **Export:** Sharing a single card yields a valid high-resolution PNG without app chrome, raw location, purchase/diary details or unauthorized media; AirDrop/Messages/files work through the system share sheet.
8. **Search:** Search across 500 seeded records by name, brand, note, accord and occasion; apply multiple facets, clear filters, sort, scope Wishlist versus Owned, produce correct counts and preserve selection.
9. **Offline/rights:** Disabling the network or image downloads still permits capture, Wishlist, filtering of cached facts and sharing of eligible owned art. No unlicensed card download or accidental photo upload occurs.
10. **Performance/accessibility:** Existing 60/120 Hz motion performance not degraded during gallery browsing; CPU-intensive OCR/export occurs only on demand; reduced motion and full keyboard/VoiceOver alternatives work.
11. **Compatibility:** Existing local archive, photos, wears, renamed shelves and saved layers pass round-trip migration and app restart.

### Checks

- Docs: npm run docs:check, npm run test:docs, npm test.
- Native: xcodebuild AroomaNative iOS Simulator; XCTest/Swift pure-model tests on capture, search predicates, migration, commit/undo and compare rule explanations. Include tests for denied camera permission, offline lookup and image-export error.
- QA: 375/390/430 pt widths, landscape, Dynamic Type, contrast, Reduce Motion, Reduce Transparency, VoiceOver, switch/keyboard input and tap alternatives.
- Physical iPhone: camera quality/permissions, swift swipe intent and rejection, OS edge gestures, PNG share sheet, Photos permission, AirDrop, Metal/deck frame pacing, image caching, battery and resumed background capture.
- No claim of real-world product recognition, public image rights, network compliance, TestFlight availability or 120 Hz performance until actually verified.

### Prototype plan

- **Must be real:** existing native card engine; a complete focused-card peek/expand; camera capture with local Vision text; real scan-card decision with undo; ImageRenderer export and system share sheet; search facets on seeded data.
- **Can be faked only in an explicitly labeled internal fixture:** product catalog responses, editorial season/accord data and downloadable licensed art. Never represent fixtures as live fragrance recognition.
- **Where:** native SwiftUI application in Simulator for state correctness, physical iPhone for gesture and camera testing.
- **Ask testers:** "What would swiping this card do?", "Can you tell whether you own this bottle?", "How would you share this or save it for later?"

## 10. Rollout, rollback and release

1. Create feature branch. Implement pure data and gesture state machine and tests, no external service; retain the current gallery behind a temporary internal flag if needed.
2. Add Wishlist, Insight peek, local search facets, static card export, camera OCR/barcode and explicit destination actions as a coherent native vertical slice.
3. Ship only after CI, device QA and owner review. Implement verified catalog network integration and licensed card downloads in their own auditable follow-up, behind default-OFF toggles.
4. Preserve the existing local archive; migration includes restorable versioned backup, no overwrites of personal photos, and rollback path.
5. Create a reviewable PR including before/after recordings, screen video of each gesture, tests, rights/provider assumptions and a transparent list of device checks still owed. This spec is **not** permission to merge, release, enable network or submit billing.

## 11. Decision record

| Date | Decision | By | Documents updated |
| --- | --- | --- | --- |
| 2026-10-31 | Prefer gesture-consolidated native product interaction, rename To Try to Wishlist, add image sharing/insight/search/scan destination flow; require real catalog/rights verification for enrichment and downloads | Owner direction, detailed as implementation proposal | This spec, spec index, design decision log |
