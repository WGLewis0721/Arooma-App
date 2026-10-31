# Spec: Arooma Native, premium motion and interaction system

> Part of the Arooma design brain. Start at [../README.md](../README.md). Implementation brief for Opus 5.5, 2026-10-31. Read [../PLAN_SPEC_PROTOCOL.md](../PLAN_SPEC_PROTOCOL.md) and the current SwiftUI source before changing anything.

| | |
| --- | --- |
| Request | "The cards and overall app still feel flat and static. Make full use of outstanding native iOS/SwiftUI motion, momentum and interaction capabilities, to the quality of a $25/year app." |
| Restated | Turn an already-built, standalone iOS 26 SwiftUI fragrance collector into a dynamic, physical, seamless product with deeply integrated gestures and legible workflows. |
| Surface | Native iPhone: gallery, card overlap, inspector, shelves, onboarding, Quick Add, Today/Wear Log, View & Style |
| Size | L, system-level redesign and implementation |
| Author | OpenAI implementation handoff, 2026-10-31 |
| Status | Implemented on branch feat/native-physical-deck-motion (section 12); real-device validation pending |
| Governing context | Root [NATIVE_ATELIER_FINAL.md](../../../NATIVE_ATELIER_FINAL.md), [Apple-native pack](../packs/apple-native-feel.md), [design rules](../RULES_CARD.md), [Apple design principles](../platforms/APPLE_DESIGN_PRINCIPLES.md) |

## 1. Problem

A person opens Arooma on their physical iPhone expecting the feeling of handling a luxury collectible deck. The cards are attractive but overlap like static photographs, their motion reads as sliding, and the whole app feels like disconnected screens with ordinary buttons. Previous attempts introduced springs, 3D transforms, Core Motion tilt data and decorative gradients, but the owner reports that the result remains flat and unconvincing. The job is to replace the *experience*, not to keep layering effects onto the current implementation.

**Non-negotiable test:** With three visible cards and no labels, the interaction must still communicate which card is foremost, what will happen when touched, and how the physical deck is arranged.

## 2. Evidence and context

- **[Owner/iPhone]** Current cards are visually flat; overlapping cards lack presence; prior scrolling skipped or miscentered cards; the overall experience lacks premium motion and useful affordances. A successful CI compile did not prove good touch physics.
- **[Repo]** Native entry point: **ios/AroomaNative/AroomaApp.swift**; currently Collection, Shelves, Today with Search/Style/Quick Add sheets.
- **[Repo]** **ios/AroomaNative/AtelierGallery.swift** implements fractional deckPosition, drag-to-snap, hardcoded Cover Flow/Stack/Fan transforms, a shelf overview, matchedGeometryEffect, and an inspector with flipDragX. Inspect current branch, not an older PR diff.
- **[Repo]** **ios/AroomaNative/AtelierPrimitives.swift** owns AtelierCardSurface, Core Motion sampling through FoilMotion, and AtelierFoilMaterial. Current foil is primarily a uniform colored/white gradient overlay plus a border; it is not a convincing material-specific optical response.
- **[Repo]** **ios/AroomaNative/AtelierSections.swift** owns Welcome, shelf views, contextual Style picker, Today, multi-fragrance saved combinations and Quick Add. **CollectionStore.swift** persists existing local archive data; **Artwork.swift** loads the approved card masters.
- **[Apple]** The [Human Interface Guidelines for Motion](https://developer.apple.com/design/human-interface-guidelines/motion) call for purposeful, interruptible, responsive movement, not gratuitous animation.
- **[Apple]** [What's new in SwiftUI, WWDC25](https://developer.apple.com/videos/play/wwdc2025/256/) covers the current platform design, animation and layout systems, and SwiftUI performance instrumentation.
- **[Apple]** [Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/) explains native iOS 26 material and navigation behavior. Apply system Liquid Glass judiciously to controls and navigation, not indiscriminately over collectible art.

## 3. Goals, non-goals and effort

**Goals**
1. A card feels like a physical, slightly substantial collectible with coherent apparent thickness, depth, inertia, occlusion, pressure, light, contact shadows and settle feedback. Neighbor cards have carefully calculated position, angle, spacing, stacking order, exposure and scale. These relationships remain convincing mid-drag, not just at rest.
2. Finger motion directly controls the visual state; release transfers measured velocity into a spring with believable mass and damping. No skipping, recenter jitter, disappearing card or delayed response. Continuous gestures can reverse and interrupt ongoing motion.
3. Foil/gloss responds unmistakably but tastefully to real device tilt, view angle, card rotation and touch, with a subdued living idle highlight. The card must visibly reveal different material qualities as the handset moves, instead of showing the same generic animation on every bottle.
4. The interface is enjoyable to manipulate and also understandable: direct paths from discovery to collection, collection to inspection, inspection to wear, and shelf to collection. Favor under three interactions for common single-bottle actions; multi-select naturally scales with number of fragrances.
5. The three gallery layouts feel *different in choreography* yet preserve the same selected object and a consistent physical world. Themes affect environmental lighting and typography coherently across all screens.
6. Strong accessibility and measurable real-device animation performance. No promises based on simulator screenshots alone.

**Non-goals**
- A wholesale backend rewrite, fabricated fragrance catalog, scraped brand photography, new subscription/paywall, unrelated charts, ambient particles or a long loading animation.
- Moving all state into a giant global ObservableObject or replacing the gallery with a web view.
- Adding technical features only to increase an API checklist. Use a capability when it improves an observable interaction.

**Effort:** Large, cross-screen native polish pass. Prefer one striking, fully functioning card interaction and connected navigation over broad but shallow changes.

## 4. Rules, priorities and explicit creative latitude

| Priority | Requirement |
| --- | --- |
| 1. Working product | Existing bottle records, user photos, wear sessions, saved layers, shelf names, favorites and persistence must survive updates. Keep bundle identifier **com.graymatter.arooma**. No destructive migration or silent data loss. |
| 2. Cards are the content | Keep the approved collectible masters recognizable and unaltered on disk, including front and reverse. Lighting, reflections, masks and custom effects can be built *around* those images without rewriting them. Honor rights and privacy of user photos. |
| 3. Creative freedom | Opus may meaningfully redesign layout, color distribution, presentation hierarchy, motion choreography, staging and controls. Older decorative limitations are guidance, not an excuse to preserve a flat, weak implementation. Document any material deviation clearly. |
| 4. Native feel | Integrate real iOS 26 SwiftUI patterns, physics, navigation, animation, haptics and accessibility. Use native APIs and profile them, rather than imitating Apple with generic CSS-like treatments. |
| 5. User trust | No network calls, tracking, accounts, AI identification promises, external uploads or monetization without a clear separate decision and implementation. |

**Exceptions:** None needed for physically responsive, non-destructive rendering and native transitions. New third-party art, fonts, subscriptions, network services and branded assets require rights/product decisions first; don't silently introduce them.

## 5. Alternatives and chosen concept

| Option | Concept | Advantages | Limitations |
| --- | --- | --- | --- |
| A. Cosmetic polish | Stronger shadows and more reflective overlays on the existing horizontal carousel | Quick and low risk | Repeats the failed approach: effects without object physics |
| B. One coherent native physical-deck engine | A continuous pose/velocity model drives layout, lighting, occlusion, touch response, spring settle and inspection | Product-defining feel, consistency across modes, testable states | Requires restructuring and careful profiling |
| C. Full SceneKit/RealityKit deck | Actual 3D scene with lights and cards as entities | High material expressiveness | Larger maintenance and accessibility burden; may be overkill for a primarily 2D iPhone collection |

**Chosen: B.** Begin in native SwiftUI with a dedicated deck-interaction model, gesture-coherent transforms and a separate GPU-conscious foil renderer. Use low-level Metal shaders, RealityKit or a UIKit gesture bridge only for a *proven gap*, with profiling demonstrating that the result is superior. Do not choose C reflexively or simply crank the transform angles of A.

### Breadboard of the experience

**Collection**: One visually dominant centered card, neighboring physical cards receding naturally, a compact collection label and index, and minimal contextual chrome. Touch lifts, drag repositions, release settles; tap expands the *same card* into Inspect. Long-press may open a concise menu, but must not compete with swipe.

**Inspect**: A continuous card-to-inspector spatial transition preserves the card image and pose. Rotate the card by touch to flip; reveal the back as a true back face without image popping at 90 degrees; rotate back or dismiss into the original gallery position. Essential ownership controls live here, not in duplicate toolbars.

**Shelves**: Pinch away from a card to a spatial overview of the collection, maintaining visual context; pinch/tap back into a chosen shelf. Rename and organize shelves without interrupting browsing.

**Today**: The primary action clearly says what to do: "What are you wearing?" Tap one bottle or combine two/three, log a single wear session, save/reuse combinations and see the result in history. The miniature selected cards should align and overlap like a composed set, not stacked random thumbnails.

**Quick Add / Search**: One obvious entry point. Name-only or photo-only capture within roughly 10–15 seconds; no forced metadata form. An unmatched search name can be saved immediately.

**View & Style**: Cover Flow, Stack, Fan and atmosphere/theme in the same options area. Switching views morphs the existing objects into their new layout instead of reconstructing or teleporting them. Returning users bypass the intro.

### Required states

First-run, returning, empty collection, one card, dense collection, left/right endpoint, rapid reversal, interrupted transition, current card removed, orientation change, background/foreground, simulator without motion sensor, Low Power Mode, thermal throttle, Reduce Motion, Reduce Transparency, offline, unavailable photo, failed photo save, zero matched search results, empty/partial saved layer, accidental double-submit, voice-driven accessibility navigation.

## 6. High-value native iOS / SwiftUI capabilities

Use and justify the best-fitting native capabilities, rather than adding everything mechanically:

- **Direct touch and physics:** DragGesture / GestureState or a focused UIKit recognizer when needed; actual translation and predicted velocity; one single continuous deck progress/pose source; rubber-band endpoints; spring animations with velocity continuity and stateful interruption. A settle must not rebase the visible index mid-gesture. Keep the selected card visually centered to within 1 pt at rest.
- **View identity and transitions:** matchedGeometryEffect and, where appropriate, the available iOS 26 navigation transition APIs; explicit transition ownership so source and destination do not duplicate or pop. Provide gesture-driven inspection dismissal when it does not conflict with flip.
- **Sequenced animation:** Animatable/AnimatableModifier, phaseAnimator and keyframeAnimator where appropriate for meaningful press/lift/flip/land choreography; avoid phase animation for continuous gesture pose. Use contentTransition / symbolEffect on small supporting elements when it reinforces their state.
- **Optical materials:** Core Motion orientation combined with card angle, normal, light direction and user touch; per-region masks for foil rim, metallic areas and glossy surface; restrained diffraction and specular highlight. SwiftUI Canvas/TimelineView is acceptable for economical ambience; use Metal shader modifiers or an efficient renderer if measurement shows they improve the optical response without stutter. The photograph and readable text must remain crisp.
- **Tactile/audio language:** sensoryFeedback or Core Haptics, with coordinated, discrete cues at card pick-up/settle, flip threshold and successful wear logging. No constant buzz, fake clicks or default haptics on every frame. Optional subtle original sound only if justified and user-controllable.
- **Native controls:** Liquid Glass in its appropriate functional layer, readable SF Symbols, native sheet presentation detents, predictable back/dismiss actions, Dynamic Type, VoiceOver, reduced motion/transparency and system color appearance.
- **Performance:** SwiftUI Instruments, Animation Hitches, Core Animation and Energy Log to find body-recompute storms, expensive blur passes, image-decoding spikes, overdraw and motion-sensor overhead. Decode/cache art once per needed size; never reload huge UIImage data each animation frame. Suspend sensor/render work when offscreen, backgrounded or low power.

### Physical motion requirements

**Pressed:** Immediate under-finger displacement, subtle lift and shadow with a material-specific light reaction; no laggy scale button look.

**Dragging:** Translate continuously with finger, adjust neighbor cards' occlusion and angle continuously, preserve geometric center line and correct z-order as depth crosses. Selected card can be partially between indices and remain believable.

**Release:** Use measured velocity to shape spring characteristics and trajectory without accidentally skipping multiple cards. Reversal during settling should seamlessly take control of the current pose, not begin from an old target index. Boundaries resist and return.

**Idle:** Extremely restrained light changes make the foil feel alive but do not move the cards themselves or distract from reading. Motionless phone is not a dead photograph.

**Tilt:** Slowly tilting a real iPhone produces a clearly different highlight location and chromatic response, with physically consistent lighting across the front, edge, neighboring card and shadow. If tilt is unavailable or disabled, interaction still works and looks intentional.

**Flip:** A reversible and directly scrubbable 3D rotation around the card's axis. Front/back visibility must track the actual instantaneous angle, not a premature binary swap. The selected card remains the same object across gallery, inspect, reverse and exit.

**View switch:** Cover Flow has cinematic depth, Stack has weighted tactile compression, Fan opens into a deliberate spread. No layout causes a different card to become selected or an unexplained index jump.

## 7. Technical architecture

- Read current **ios/AroomaNative/AtelierGallery.swift**, **AtelierPrimitives.swift**, **AtelierSections.swift**, **AroomaApp.swift**, **Artwork.swift**, **CollectionStore.swift**, **Models.swift** and **ios/AroomaNative.xcodeproj** before editing.
- Extract a testable deck state machine/model that represents signed continuous progress, current focused ID, velocity/gesture phase and bounded targets. The SwiftUI render tree should derive *all* card poses and depth ordering from that model. Avoid independent animation states for card x, scale, zIndex and selection that can fight.
- Make material response depend on computed card pose and shared orientation, not simply an unrelated global rainbow gradient. Use visibility-scoped sensor subscriptions and a well-defined quality fallback.
- Keep approved assets immutable. Separate physical collectible presentation from business domain state, user data and local storage. Avoid expensive writes for each gesture frame. Document any dependency/library and license, with a preference for built-in SDK frameworks.
- Use the existing native Xcode scheme **AroomaNative**, iOS 26 target and Codemagic configuration. No web prototype substitution. Keep the application upgradable over the existing TestFlight install.
- Build explicit motion/visual regression tests where possible. Structural/UI tests should verify selection continuity, one-card snap, front/back state, restored settings and all persistence invariants.

## 8. Risks and mitigation

| Risk | Proposed handling | Who decides |
| --- | --- | --- |
| Shader overdraw and battery drain | Limit full-card effects to focused objects; measure GPU/frame times and energy; offer low-power/reduce-motion fallback | Implementer, with owner sign-off on look |
| Gesture collisions (swipe/pinch/flip) | Document recognizer ownership and exclusivity; test two-finger gestures during release | Implementer |
| Card images become washed-out or unreadable | Separate optical channels and masks; compare against approved originals | Owner visual review |
| Fancy animation makes common tasks slower | Settle quickly, make transitions interruptible and preserve under-three-tap paths | Owner/device test |
| 120 Hz target missed on some devices | Aim for device-native refresh where achievable; baseline smooth 60 fps, measure actual hitches | Implementer |
| Existing journal/archive migration | Additive fields and explicit migration tests; do not rewrite or reset existing local data | Implementer |
| Feature overload for a $25/year product | Solve the deck, collecting and wear ritual deeply before inventing premium dashboards | Owner |

## 9. Verification and prototype plan

### Acceptance criteria

1. **Center and order:** On 375/390/430 pt widths and real iPhones, every snapped selected card's optical center is within 1 pt of the intended deck center in Cover Flow, Stack and Fan; no flick lands with a permanently off-center card.
2. **No skipped selection:** At least 100 alternating and rapid swipes of a 20-plus-card fixture show no uncommanded skips, duplicated cards, swapped identity, stale z-order or sudden jump when input reverses. A deliberate flick follows the chosen one-card-snap policy.
3. **Continuity:** Begin a drag, change direction mid-drag, release while animated, touch again, open and close Inspect. The next interaction continues from the visible pose and the same collectible.
4. **Holography:** On a **physical** tilt-capable iPhone, pan/tilt the handset and observe highlights move coherently across foil areas. At rest the focused card has subtle material life; with Reduce Motion/Low Power Mode the effect is appropriately reduced.
5. **Flip:** Scrub a card through the halfway angle and back without front/reverse image popping or contradictory visible faces.
6. **Spatial transition:** Tap a focused gallery card, inspect it, then dismiss; the exact collectible returns to its starting card location, with no duplicated image or flash.
7. **Usefulness:** A new user knows how to browse, quick add a bottle and log layered wear without an explanation; a returning owner retains their collection, recorded sessions, named shelves and favorite layers.
8. **Perf:** Measure steady-state and rapid interaction on device: smooth 60 fps on supported baseline hardware and use 120 Hz smoothly where available; target a low animation-hitch rate (e.g., at most 10 ms per second), no conspicuous dropped frames, and reasonable energy cost. Report actual measurement, device and duration, not invented percentages.
9. **Accessibility:** All essential features work without tilt or pinch; VoiceOver, Dynamic Type, Reduce Motion, Reduce Transparency and Increase Contrast preserve clarity and usability.
10. **Build:** Native iOS CI, app smoke tests and design-doc checks pass for final exact commit. No claim of TestFlight availability until a signed upload actually completes.

### Real-device prototype

Before polishing every screen, build a single **fully functional native deck/inspect/flip vertical slice** using the existing approved artwork, with Core Motion and real haptics. Test it on an iPhone, ideally comparing two or three spring/lighting systems. Reject the one that just has impressive effects but poor interruptibility. Then integrate the winning system into the product instead of shipping a separate disposable mock-up.

**Device-test questions:** Does the card feel like an object with weight? Can you predict where it will settle? Can you reach your next useful task without searching the UI?

**Checks:** Run the repository's docs checks/tests, native simulator xcodebuild, appropriate XCTest/XCUITest coverage, Instruments on real hardware and a signed TestFlight build once release authority is confirmed. Save a short before/after interaction recording or equivalent reproducible evidence; static screenshots alone are not sufficient.

## 10. Rollout, rollback and release

Create a dedicated feature branch, implement in substantial integrated changes, keep a focused visual QA log and open a PR. Protect existing collection data. If necessary isolate new rendering/gesture implementations behind an internal feature flag with the old implementation available as rollback. Run native CI and submit a device-test build using the existing Codemagic **arooma-testflight** workflow after authorized merge/release. Supply an explicit handoff: files changed, capabilities used, how to test every signature gesture, device performance measurements, known gaps and the real TestFlight build/version if actually uploaded. Do not report success from compiler-only verification or substitute a web preview.

## 11. Decision record

| Date | Decision | By | Documents updated |
| --- | --- | --- | --- |
| 2026-10-31 | Prioritize physical, interruption-safe native card behavior and coherent cross-screen motion over decorative polish; allow meaningful redesign, preserve user data and collectible identities | Owner feedback translated into implementation brief | This spec; existing source remains unchanged |
| 2026-10-31 | Implement option B: display-link deck engine, GPU foil, zoom transitions and connected screens; device validation still pending | Implementation (Claude Code) | This spec section 12; ios/AroomaNative; ios/Tests |

## 12. Implementation record (2026-10-31, branch feat/native-physical-deck-motion)

Status: implemented in the native target; simulator-built and simulator-captured by CI. **Not yet validated on a physical iPhone** (no device was available to the implementer). Acceptance criteria 4 (holography on hardware), 8 (device frame pacing) and the haptic feel remain owner/device checks.

### Reference apps studied for polish level

| App | What Arooma borrows |
| --- | --- |
| Apple Wallet | A card is picked up, lifts with a deeper shadow and drops back into the stack; tilt shine on the hero card |
| Photos / Apple Music (iOS 18+) | Zoom navigation transition from the exact thumbnail, pull-down dismissal, artwork-derived ambient backdrop |
| Apple Invites | Full-bleed card as the hero of the screen, glass controls floating over it |
| Pokémon TCG Pocket | The benchmark for tilt-reactive foil and a scrubbable two-sided card inspection |
| (Not Boring) Weather / Habits | Physical, sparing haptics that confirm an outcome instead of decorating every touch |
| Halide | Tactile controls that respond under the finger before the action completes |
| Things 3 | Quick entry that saves first and lets details come later (Quick Add) |
| Mela (ADA 2025 Interaction finalist) | Calm content-first navigation; the object, not the chrome |

### What was built and why

- **One deck engine** (`DeckPhysics.swift`, pure Swift): continuous position, velocity and phase; fixed-step springs (identical at 60/120 Hz); one-card-snap release (only the two cards straddling the centre line are candidates, so a release can never skip a card); iOS rubber band; exact rest snap (centred to the bit). Card poses for all three layouts are pure functions of distance, so the morph between layouts blends poses rather than rebuilding views.
- **Display-link motor** (`DeckMotor.swift`): replaces `withAnimation` for the deck. SwiftUI animations jump state to the target immediately, so a new touch used to start from a pose that was not on screen. Now touch-down freezes the deck where it is drawn and release hands the measured finger velocity to the spring. Selection is written to disk once, on settle.
- **GPU foil** (`HoloFoil.metal` + `LiveFoil`): sheen, glint, diffraction and rim sparkle as additive light on the unaltered master. Diffraction is masked by the rim and by the bright, low-saturation regions of each card's own art, so cards differ. Light = Core Motion tilt (gravity against a drifting baseline, so any holding posture is neutral) + card yaw + a barely moving idle drift. Off for cards further than one slot from centre; static sheen elsewhere.
- **Physical card**: Lambert shading from yaw, visible edge thickness, catch-light, lift-aware contact shadow, small tilt lean on the hero.
- **Spatial transitions**: inspector uses the system zoom navigation transition from the gallery card; horizontal drag scrubs the flip (faces swap at exactly edge-on), vertical pull dismisses; pinch on the deck continuously drives the shelf overview and pinch-out returns.
- **Screens**: Shelves with scroll-transition depth and move-to-shelf; Today with a composition tray of fanned cards and a stamp on logging; Quick Add with a live card preview and catalog suggestions; dealt, touchable welcome hand; Style sheet at half height so layout and theme changes visibly morph the live gallery; Search as an iOS 26 search tab; a tab bar accessory for today's wear.

### Deviations from earlier guidance

- Haptics add a flip edge tick (allowed by this spec section 6); settle intensity scales with release speed. Still no per-frame or decorative haptics.
- The Collection header wordmark uses the calligraphic face (wordmark-only use, per the rules card).

### Gesture ownership

| Surface | Gesture | Owner |
| --- | --- | --- |
| Deck | One-finger drag (horizontal intent past 7 pt) | Deck engine; vertical wander stays a press |
| Deck | Tap | Focused card opens Inspect; neighbour glides to centre |
| Deck | Two-finger pinch | Shelf overview progress; cancels any deck drag in progress |
| Deck | Long press | Context menu (Inspect, Wear, Layer, Add) |
| Inspector card | Horizontal drag / tap | Flip scrub / half turn |
| Inspector card | Vertical drag | Pull to dismiss |

### How to verify on device

1. Xcode → AroomaNative scheme → Run on an iPhone. Add launch argument `-AroomaFramePacing YES` to show the frame-pacing HUD and console lines (`AroomaFramePacing frames=… fps=… hitch=…ms/s`).
2. Drag slowly, reverse mid-drag, flick, and touch the deck while it is still settling: the card must be caught where it is drawn.
3. Tilt the phone slowly with the hero card visible; compare a gold-lettered card with a darker one.
4. Tap the hero, scrub the flip back and forth across edge-on, pull down to dismiss.
5. `-AroomaAutoplay YES` replays the scripted engine choreography used in the CI recording (synthetic finger, real physics).

### Evidence and measurements

Before/after captures, engine-playback recordings and the simulator frame-pacing A/B are in [docs/evidence/2026-10-31-native-motion](../../evidence/2026-10-31-native-motion/README.md). Simulator figures only rank relative cost (the foil shader was the largest); device pacing is still unmeasured.

### Tests

- `ios/Tests/DeckPhysics/main.swift`: centring for all layouts and widths, pose continuity, exact rest snap, one-card snap under violent flicks, 5,000 random release-policy cases, 200 interrupted alternating swipes on a 24-card deck with no visible jump, end stops, bounded overshoot, empty/single decks, count changes, glide interruption, flip face visibility and flip landing, 60/120 Hz agreement.
- `ios/Tests/ArchiveCompat/main.swift`: existing archive JSON (minimal and a full owner archive with sessions, layers, renamed shelves, personal capture) decodes and round-trips.
- CI (`native-ios.yml`) builds this branch and the baseline, photographs the same seeded states in both, records the autoplay, and composes before/after sheets (artifact `Arooma-Before-After`).
