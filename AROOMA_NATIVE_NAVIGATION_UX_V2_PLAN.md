# Arooma — Native Navigation & Deck Cleanup V2
> **Authoritative owner-approved plan • 2026-11-01 • SWIFTUI ONLY**
>
> This **replaces** `AROOMA_SWIFTUI_UX_CONSOLIDATION_PLAN.md` as the implementation roadmap. That document remains historical background for the earlier 18 before/after concepts and Refero research, **not** an alternative navigation spec. This plan includes the owner's annotated in-app screenshot, the explicit resolution of the redundant long-press menu, and the unimplemented parts of the prior audit. **No production code was changed by this planning commit.**

## 1. Goal and source of truth

Make Arooma feel like **a collectible fragrance archive**, not a UI full of alternate ways to reach the same place. The photographed 3D collectible cards remain the hero. Every common user goal has one obvious route; small contextual actions replace persistent duplicates. A native frosted-glass, swipe-up Insights tray contains detail without cluttering the deck.

**Authority order:** (1) owner decisions in the current chat, including the yellow-annotated Arooma screen dated 2026-11-01; (2) verified behavior of latest `main` in `ios/AroomaNative`; (3) `AGENTS.md`, `NATIVE_TARGET_OVERRIDE.md`, `NATIVE_ATELIER_FINAL.md`, `docs/design/README.md`, `docs/design/brand/BRAND_BOARD.md` and current iOS/Season Compass specs; (4) approved before/after mockups and Refero/21st.dev as **visual/flow guidance only**. Mockups contain fictional controls/products: never code a mockup invention. If code contradicts an actual approved UX decision, update code and documentation together. Do not port the retired PWA.

### Actual native baseline, verified from source at plan creation

- `AroomaApp.swift` currently exposes **four** `AtelierTab` cases: `gallery`, `journal`, `cards`, `search`; tab titles **Collection, Today, Cards, Search**.
- `AtelierGallery.header` currently has the Arooma signature wordmark **and** a `Menu` with **My collection / Wishlist / Explore sample cards**, **All shelves**, header **Quick add a bottle**, and **View and style**.
- `AtelierGallery` draws `DeckScrubber` dots, a separately visible **Insights** labelled grabber, a numeric card counter `27 / 34`-style, a large contextual **Add to my collection** button, and (for sample mode) an extra ownership/wear prompt.
- `AroomaApp.swift` already contains a single editable Shelves sheet, origin-aware Quick Add, Search-result-to-Inspector, and an accessory hidden while Today is selected. **Preserve these fixes.**
- `Search.swift` already contains filtering/sorting and search scopes; `Capture.swift` already offers direct valid-name saves while keeping review for OCR. **Do not rebuild them or reintroduce extra steps.**
- `Commercial.swift` contains the independent `MyCardsScreen` and `CardStudioScreen` for user-created digital cards. These are **not** the same data as owned bottles, and must survive the change from a Cards bottom tab.

## 2. Locked information architecture: EXACTLY THREE bottom tabs

```text
Arooma
├── Explore                   (tab 1; default immersive sample/card deck)
│   ├── focused collectible ─ tap → Inspector / flip
│   ├── + Add to My Collection / Move from Wishlist
│   ├── ♡ Add to Wishlist / show saved wishlist state
│   ├── Search (magnifier) ─ query / scope / filters / sorting
│   │   └── select result → Inspector (close returns to Search)
│   ├── swipe up → frosted Insights tray / Compare
│   └── View & Style (single discreet existing utility)
├── Today                     (tab 2)
│   └── solo wear / layer / repeat / saved combinations / wear history
└── My Collection             (tab 3)
    ├── Owned bottles (default; existing real ownership)
    │   ├── immersive owned deck / inspector / wear
    │   └── editable Shelves (browse / rename / move)
    ├── Wishlist (inside My Collection; not a tab)
    └── My Cards (secondary destination)
        └── personal digital cards / Card Studio / import / export / approved commercial paths
```

### Required semantics

1. **Explore is discovery. Search is a function.** Normal tap of Explore opens the **sample/demo deck immediately**. The search magnifier is available *within Explore*, not a separate bottom tab. Reuse the existing Search view/index/facets/sort; opening and closing preserves query and return context. Search must still find owned, wishlist and catalog results via existing scopes. Do not duplicate search logic.
2. **My Collection is actual ownership.** It must not silently open demo cards, reinterpret purchased/created digital cards as perfume bottles, or require a mode dropdown. Default to **Owned** and offer a visible **Wishlist** view inside this tab. Shelves operate only on appropriate saved records. The existing **My Cards / Card Studio** library remains reachable within My Collection as a secondary destination, not secretly deleted.
3. **Today remains unchanged in function**: wear, layer, history, undo and saved-layer recovery remain accessible; no new reminders, performance claims, or false advice.
4. **No long-press menu.** Permanently remove the **square floating three-item menu** and the mode-switch dropdown at the wordmark. Do **not** relocate them to a long-press on Explore, a new header button, or another hidden popup. Their former destinations already have homes.
5. **Native TabView** with exactly `Explore | Today | My Collection`, in that order. Do not implement an artificial React/FAB dock. Keep the native iOS 26 tab appearance/VoiceOver.
6. **Stable state across tabs:** Explore keeps its selected sample card/layout; My Collection keeps its selected owned card, selected Wishlist view and shelf; Today keeps its composition until explicitly cleared; Search keeps its state while its sheet/stack is open. A global `archive.mode` currently drives all three data modes, so refactor carefully to avoid switching Explore into Mine or My Collection into Demo unexpectedly. Keep original IDs, ownership, histories, photos, imports and entitlements. Switching tabs must not mutate saved user data.

## 3. Yellow-annotation fixes — explicit screen-by-screen specification

These are not vague “less clutter” suggestions. Each row maps one visible annotation to a specific behavior and validation.

| Ref | Screenshot markup | Remove / change | What must remain |
|---|---|---|---|
| **A1** | Big yellow circle: **My collection / Wishlist / Explore sample cards** popup | **Delete the entire popup** and its `Menu` trigger, including long-press replacement idea. Distinct destinations now live in three-tab IA. | Collection/Wishlist records and demo deck remain reachable as above. |
| **A2** | Circle/cross through the decorative **Arooma** top-left header block | Remove the redundant **permanent prominent wordmark/mode selector** from the Explore deck header. If identification is needed, use one compact static **Explore** label. Keep approved logo on intro and approved collectible art. | App branding, custom art and themes untouched. |
| **A3** | Yellow X on multiple top utility controls | Remove **header Quick Add** and **All Shelves** from **Explore** because Add becomes contextual and Shelves belongs in My Collection. Keep at most **one** discreet **View & Style** utility (sliders) if it is the only functional entry, positioned to avoid competing with art; View & Style can alternatively be accessed from a clear My Collection settings destination. | All themes/layout switches, owner tuning and shelves remain accessible. Do not delete settings because a screenshot crosses an icon. |
| **A4** | X through “Insights” strip beneath card | Remove the persistent **labelled Insights bar** from the resting deck. The **upward swipe on focused card** still opens the **frosted two-detent Insights tray**. Preserve a subtle functional grabber / VoiceOver `Show insights` action and a gesture-free access path so the feature is discoverable and accessible. | Season Compass, notes, accords, actual matches, Compare, close/collapse and swipe physics. |
| **A5** | X through the long row of dots | Remove visible `DeckScrubber` **dot row**. Keep the accurate small numeric **current / total** position, including `27 / 34`; one counter only. If dots presently support random access, preserve that capability via tapping/dragging the numeric counter or existing overview, with accessible increment/decrement actions. | Swipe, tap, pinch/overview, jumping to cards, focus and layout changes. |
| **A6** | Circle around `27 / 34` | Keep the subtle counter in the upper-right of the fragrance identity region; update continuously during gestures. | Correct indices, stable identity, voice-readable “Card 27 of 34.” |
| **A7** | Circles around yellow `+` and heart beside name | Place **two compact contextual actions** beside or just below the fragrance name without truncating it: `+` = Add to My Collection (or Move from Wishlist if wishlisted); heart = add/remove Wishlist. Update visual selected state and accessible labels. Ownership-specific actions must be truthful. | The underlying `archive.add`, `addToWishlist`, `moveToCollection` rules, undo and duplicate prevention. For owned items, don't show a nonsensical Add action; keep Wear Today in Today/owned context. Don't silently reinterpret Wishlist heart as a different function. |
| **A8** | Cross through big gold **Add to my collection** CTA | Remove the large redundant CTA in **Explore** once compact `+` has feature parity. Also remove any separate top Add button performing the same action on that screen. The compact control must be a real 44-point minimum hit target, even with a small glyph. | Still one tap to add/move. If an owned card is in focus, retain an appropriately contextual Wear action from its owner screen, not a dead Add button. |
| **A9** | Strike-through “Sample archive · log wears in My Collection” | Delete this persistent banner/CTA. Explore and My Collection are self-explanatory destinations. Use short empty-state teaching **only if** needed, never a permanent nag. | Today cannot log a demo fragrance as an owned one, and no false ownership is implied. |
| **A10** | Bottom bar arrows/crossed labels | Rename bottom-left Collection → **Explore**, middle stays **Today**, former Cards destination → **My Collection**, remove bottom-bar Search entirely. Place **Search magnifier within Explore** (not separate tab). | The digital Cards library becomes a subdestination within My Collection, not lost. |
| **A11** | Existing expand/inspect icon near big CTA | If tap on the **focused card** already opens the same Inspector, remove the redundant expand icon from resting Explore; otherwise consolidate into one well-labelled inspection affordance. | Focused-card inspection and card-back flip reachable through touch and VoiceOver. |
| **A12** | All yellow strike-throughs and density complaint | After cleanup, the visually dominant card must occupy the same or larger share of the viewport; no permanent bottom banners, duplicated mode controls, extra full-width CTA or crowded label row. | Cards remain full-art, reversible, dynamic, correctly proportioned at 59:86; no photo/foil regressions. |

**Recommended resting Explore composition:** one restrained header (Explore + search + optional one View & Style utility) → large uninterrupted Cover Flow card → subtle/gesture-free Insights access → fragrance identity with small `27 / 34` → two contextual `+`/heart buttons → native 3-tab bar. There is **no** fourth toolbar of actions, permanent extra banner, mode popup, or dot row.

## 4. Keep the other before/after UX fixes in this plan

This new plan is the **single implementation target**. The 18-item audit from `AROOMA_SWIFTUI_UX_CONSOLIDATION_PLAN.md` remains the traceability index. No feature from it should be silently forgotten. Record the final state below and in the PR; items already implemented must be **verified, not rebuilt**.

| Original IDs | Combined requirement in this plan | Acceptance |
|---|---|---|
| 01, 04 | Search direct-to-Inspector and one Filter & Sort sheet **inside Explore** | One result selection reaches Inspector, Close preserves Search query/scopes/filters/sort; no bottom Search tab. |
| 02, 05 | Fast typed-name Quick Add, OCR/photo review when needed, **return to invoking context** | Simple name saves without mandatory second review; returning to Today/Explore/My Collection does not force a tab jump. |
| 03, 11 | One **editable Shelves** surface and one clear Add affordance in each relevant context | Shelves visible one action from My Collection, rename/move/organize parity; no top Explore shelves button or duplicate Add controls. |
| 06, 18 | Group View & Style; one About disclosure; preserve real palettes, layouts, appearance, owner tuning | Same settings with one clean IA, using the frosted presentation rules below. |
| 07, 15 | Remove duplicate Card Studio opener while preserving personal cards, Studio, import/export | My Cards is a secondary My Collection destination; no digital card data loss. |
| 08 | No redundant Today→Today bottom accessory | No accessory while Today selected; relevant shortcut may remain elsewhere only if actually useful. |
| 09, 10, 14 | Preserve distinct Daily Pick vs repeat-last; unify genuine history presentation, avoid duplicate adjacent Wear Again controls | Distinct semantics preserved; no fabricated separate History tab. |
| 12, 13, 16, 17 | Coherent Wear/Layer actions, a single personal note edit surface, predictable Compare, and one Wishlist→owned CTA | Conditional actions, notes, recommended Compare preselection, wear and Undo retain full behavior. |
| New annotated items A1–A12 | Three-tab IA and the actual screen fixes in §3 | All annotation fixes validated on the native app. |

**Never** treat ten generated before/after mockups as ten factual code bugs. The previous 18 IDs overlap and some generated screens show imagined features. For each feature write `OBSERVED`, `IMPLEMENTED`, `ALREADY CORRECT`, or `NOT APPLICABLE` with evidence.

## 5. Frosted-glass upward trays (owner preference)

**Scope:** the existing Season Compass `InsightPanel` opened by upward deck swipe, View & Style sheet, Filters sheet, comparison sheet and any existing context sheets where material improves usability. Do not put Liquid Glass on opaque collectible front/back artwork.

- Follow native iOS 26 sheet/Material design. Prefer Apple's system sheet materials and `presentationDetents`, `presentationDragIndicator`, `presentationBackground` when they fit. The custom `AtelierGallery.insightOverlay` currently has working `insight` detents; **keep its gesture physics** and switch its chrome to an appropriate translucent material rather than rewriting it as a web-like container.
- The deck remains visibly recognizable **behind the peek**, but all ingredient labels, note rows and controls meet contrast/readability requirements. Compact peek = identity and short information; expanded = scrollable verified notes/accords/matches/Compare.
- Prefer a gentle rim highlight, tasteful background separation, native haptics and consistent spring settling; no added liquid animation, card blurring, fake 3D reflections, wallpaper textures over data or glowing control clutter.
- Reduce Transparency, Reduce Motion, Increase Contrast and Dynamic Type must have readable functional fallbacks. Respect safe areas and keyboard; the user can dismiss via down-swipe and explicit accessible Close. One-finger card browsing must not get trapped by the tray.

Apple native design references:
- https://developer.apple.com/videos/play/wwdc2025/323/
- https://developer.apple.com/documentation/swiftui/view/presentationbackground(_:)
- https://developer.apple.com/documentation/swiftui/view-presentation

## 6. Concrete native implementation map

Use the **existing** source; inspect code again immediately before editing because some earlier audit fixes are already present.

1. **`ios/AroomaNative/AroomaApp.swift`**: replace `AtelierTab.gallery/journal/cards/search` with 3 semantic destinations `explore/today/myCollection`; default Explore (demo), preserve tab-independent selection/state; move Search to contextual sheet/navigation in Explore; route My Collection ownership/Wishlist, Shelves and My Cards. Keep direct Inspector and origin-return actions. No resurrected collection-switch menu. Preserve native TabView and bottom accessory logic.
2. **`ios/AroomaNative/AtelierGallery.swift`**: make reusable deck content for Explore vs Owned/Wishlist **without creating data copies**. Remove mode menu, prominent permanent wordmark, top redundant action buttons, dots, persistent labelled Insights, duplicate big Add, persistent sample banner, redundant inspect icon (if provably same), and inject compact contextual `+`/heart. Keep true `position/total`, selected identity, DeckMotor, interactive physics, 3D flip, gestures, all layouts, preexisting accessibility actions and InsightPanel.
3. **`ios/AroomaNative/CollectionStore.swift`** (only if necessary): separate transient presentation selection from persisted ownership/demo/wishlist records; do not change persisted data schema, IDs, local files, cards or migration. Never let Explore tab switch destroy owned selection or vice versa.
4. **`ios/AroomaNative/AtelierSections.swift`**: owned/Wishlist navigation and single editable Shelves; Today composition/records retained; View & Style groupings; no extra page solely to replace a deleted menu.
5. **`ios/AroomaNative/Search.swift`**: preserve SearchIndex, scope, sort/filter and query while making the existing view accessible from Explore icon. Keep direct result→Inspector with correct return.
6. **`ios/AroomaNative/Commercial.swift`**: keep `MyCardsScreen`/Studio/import/export reachable from My Collection without relabeling digital cards as owned physical bottles. Preserve paid/rights gates.
7. **`ios/AroomaNative/Capture.swift`**: preserve existing one-screen direct typed save, ambiguity/OCR review, photo, Undo and origin return.
8. **`ios/AroomaNative/Insights.swift`**: keep Season Compass visual/data fidelity, sourced note maps and Compare; use frosted tray materials, accessible detents and meaningful contrast only.

### Context-dependent actions contract

| State of focused fragrance | Main compact action | Heart | Other action |
|---|---|---|---|
| Demo/Explore unowned, not wishlisted | `+` **Add to My Collection** | **Add to Wishlist** | Tap focused card for Inspector; swipe up for Insights. |
| Sample already wishlisted | `+` **Move to My Collection** | **Remove from Wishlist** (selected visual state) | Same inspection, no duplicate Add CTA. |
| Already owned | No `+` Add again; show ownership state | Preserve existing distinct Favorite semantics where relevant, do not confuse with Wishlist | Wear Today / Layer / note edit and history from owned context/Today. |
| User-created digital card | Not a bottle; no automatic physical ownership action | Follow existing digital card affordances | Card Studio / import / export within My Cards. |

## 7. Maestro MCP: must test the *actual* user flows

Existing project support: `.claude/skills/maestro-ui-testing/SKILL.md` and `reference.md`, `.maestro/`, `.github/workflows/maestro-ios.yml`, Debug simulator bundle `com.graymatter.arooma`. Follow them, but use current Maestro MCP tool names after inspecting `cheat_sheet`. Current docs: https://docs.maestro.dev/get-started/maestro-mcp and https://docs.maestro.dev/get-started/supported-platform/ios .

Claude setup on macOS with Xcode 26, iOS 26 Simulator, Java and Maestro: `claude mcp add maestro -- maestro mcp`. Boot available simulator, build/install **Debug** app, use Maestro MCP `list_devices`, `start_device` when available, `inspect_view_hierarchy`, `tap_on`, `run_flow`, `run_flow_files`, `take_screenshot`, `check_flow_syntax`; run CLI `maestro test .maestro/` for stable YAML. The repo's old skill may call earlier commands `inspect_screen` or `run`; check installed command names, don't assume either works. Never claim an iPhone test based on simulator evidence.

### Required cases and YAML file targets

| Flow / target | Assertions on real Debug simulator |
|---|---|
| `navigation-three-tabs.yaml` | Exactly Explore, Today, My Collection appear; **no** Search, Cards, Collection or Shelves as separate bottom tabs; first launch Explore opens sample deck; switches do not lose independently focused identities. |
| `explore-no-mode-menu.yaml` | Explore tap opens deck; long-press Explore does **not** show square Collection/Wishlist/Sample popup; menu absent from header; primary tab destinations still accessible. |
| `explore-annotated-cleanup.yaml` | No large Add, sample-banner, labelled Insights bar, dot scrubber, header Add or extra shelf shortcut; numeric current/total visible; compact `+`/heart accessible; all 34 internal cards still swipe/flip as expected. |
| `explore-search-inspector.yaml` | Magnifier within Explore → type query → filter/sort → result → Inspector → close back to same Search query; Search has no tab. |
| `wishlist-in-my-collection.yaml` | My Collection → Wishlist → tap item → move to owned once; no duplicate bottle; selection and wishlist count stable after relaunch. |
| `my-collection-shelves.yaml` | My Collection → Shelves within one action → rename/move card → return without forced Explore; owned IDs and notes intact. |
| `my-cards-studio.yaml` | My Collection → My Cards → Studio → create with test photo if supported, return and see saved digital card; import/export affordances still present; unrelated owned count unchanged. |
| `explore-insights-frosted.yaml` | Swipe up on focused card → peek → expanded → Compare → close; hierarchy/accessibility actions work; overlay never changes selection and swipe to browse works after collapse. |
| `explore-counter-navigation.yaml` | 1 / total → swipe to 2 / total and back → numeric counter matches, no dots; counter/overview retains random-access and accessibility path. |
| `quick-add-context.yaml` | Direct valid name save, photo/OCR review where applicable, after save returns Today / My Collection / Explore as invoked. |
| `today-preservation.yaml` | Single wear in one action, multi-bottle layer, repeat, history, undo; no Today accessory on Today tab. |
| `appearance-studio-regression.yaml` | Style themes, light/dark, three layouts, personal card creation and existing Season Compass all reachable. |

Also test empty owned collection, empty Wishlist, selected card already owned, offline catalog, no matching Search result, long fragrance names, Reduce Motion/Transparency, VoiceOver/action label accessibility (manual where required), 375/390/430pt sizes, cancellation/interruptions, background resume, and seeded old-data upgrade.

**Never** run `clearState: true` on real user data; disposable simulator only. For all tests report `PASS/FAIL/NOT RUN`, real device model/simulator/OS, build SHA, first failing step, screenshots and hierarchy. Do not use Maestro Cloud unless separately approved.

## 8. Implementation order and numerical success gates

### Phase 0: baseline
- Record the real iOS screenshot corresponding to the yellow markup and the current 4-tab map.
- For each A1–A12, capture current native evidence and tap/action counts. Confirm existing earlier 18 fixes before touching code.
- Record seeded user/demo/Wishlist/personal-card state and verify a clean build.

### Phase 1: restructure navigation and data contexts
- Three-tab `TabView`, Explore default demo, Search as an Explore tool, My Collection = owned + Wishlist + Shelves + digital My Cards, no long-press/mode popup.
- Ensure selected card identity, demo/owned/Wishlist states, user photos, card purchases and wear history persist separately. Regression-test navigation before visual changes.

### Phase 2: annotated deck declutter
- Implement A1–A12 against real `AtelierGallery`: header, identity actions, scrubber replacement, no duplicate Add/Inspect/Insights/notice, accurate counter.
- Validate live flow each time with Maestro rather than deleting controls by screenshot resemblance.

### Phase 3: native materials and residual audit
- Finish frosted Insight/Filter/Style sheets and any **actually unimplemented** prior 18 refinements. Maintain artwork, note maps, 3D flip, responsive motion, safe-area and privacy rules.

### Phase 4: measured final QA + PR
- Run Debug/Release native build, full Maestro CLI suite plus interactive MCP exploration, applicable docs checks and unit tests. Real screenshots in PR, before/after action counts, accessibility and remaining physical-device gaps.
- **Open a PR** with phase commits and evidence; **do not merge or trigger TestFlight** without owner instruction.

### Required numerical result

1. **Exactly 3 bottom tabs:** Explore, Today, My Collection. **0** bottom Search tab; **0** bottom Cards tab.
2. **0** Collection/Wishlist/Sample mode menus anywhere (tap **or long press**); 0 header mode chip.
3. Resting Explore shows **0** pagination dot rows, **0** persistent sample banners, **0** full-width Add CTAs, **0** top Add duplicates, **0** labelled Insights strips; **1** current/total counter with correct dynamic values.
4. **One** contextual `+` and **one** Wishlist heart where relevant; one action to Add to Collection and one action to Wishlist; at least 44pt hit areas; no duplicate owned entry.
5. Search opens in **one Explore search action**; selecting result reaches Inspector in **one selection**, closing preserves query/filter context.
6. My Collection → Wishlist **≤1 navigation action**; My Collection → editable Shelves **≤1 navigation action**; My Cards remains reachable **≤2 actions** and retains full Studio/import/export functionality.
7. From selected owned bottle, **Wear Today ≤1 action**; Layer and log with one additional bottle **≤3 actions after initial focus**. Every critical original feature has 100% parity and saved-record roundtrip.
8. Frosted tray visual checks **10/10**: real card visible, legible text both appearances, responsive two detents, drag/collapse/close, accessible alternative, Compare works, art opaque, reduce-transparency fallback, safe-area correct, no touch conflict.
9. **Every required Maestro flow PASS** on the iOS 26 simulator or explicitly `NOT RUN` with precise blocker; do **not** call incomplete runs passing. Collect real before/after iOS screenshots (not generated mockups) for all A1–A12.
10. Preserve 34 internal autumn/demo cards (as provided by the current build), approved dual-sided art, selection in all 3 layouts, 20 botanical note assets, physical records, wishlist, personal cards, offline storage and release rights gates.

## 9. Refero / 21st.dev inspiration and limits

Use visual examples strictly for *presentation* and learn their structure, not their product features:

- **Refero**: [Airbnb iOS contextual bottom sheet](https://refero.design/screens/298bae4d-e0f9-43b0-9248-3a5d369c75bf), [Artsy iOS filters](https://refero.design/screens/a0542886-747d-48dd-b027-da15ec36a1fd), [1Password iOS settings](https://refero.design/screens/f38aa21f-5c93-4e13-877a-2550060283b6), [Halide Mark II gallery](https://refero.design/screens/88ed1e17-1209-40df-a9d5-af6ff6aa558b), [Apple Books Add to Collection flow](https://refero.design/flows/11917), [On search flow](https://refero.design/flows/9598). For brand direction, use Refero source `92962483-5537-4be9-a80c-6166e1c9c730` **D.S. & DURGA** and `7ac8e085-270b-4af6-a12e-14bf4adc0f8f` **Perplexity Computer**, subordinate to Arooma's `BRAND_BOARD`.
- **21st.dev**: visual only for material edge, frosted lower sheets, segmented control selected states and small circular action treatments: [Liquid Glass collection](https://21st.dev/community/components/explore/liquid-glass-components), [Liquid Glass Card](https://docs.21st.dev/%40designali-in/components/liquid-glass-card), [Glass Tabs](https://mcp.21st.dev/%40deepraj21/components/glass-tabs). Do not import React components or recreate the screenshot's rounded bottom dock rather than native SwiftUI `TabView`.
- **Approved Arooma design**: existing native collection/card art and the user's attached close-up app screenshot; the Instagram screenshots show visual density, glossy material and card/product dominance, **not** an approved e-commerce system.

## 10. One-paragraph Claude start instruction

Read `AROOMA_NATIVE_NAVIGATION_UX_V2_PLAN.md` in the repository root of `WGLewis0721/Arooma-App`. Execute the **three-tab Explore / Today / My Collection redesign** and the **A1–A12 owner annotations**, preserving the older 18-point UX corrections and every existing native feature. Remove the redundant square mode popup entirely, including long-press access; embed Search within Explore and Wishlist, editable Shelves and digital My Cards within My Collection; simplify the card deck's resting chrome and apply native frosted glass to swipe-up trays. Verify real behavior with the **new Maestro MCP** and committed `.maestro` flow tests, demonstrate the exact measurable success gates with simulator screenshots and honest pass/fail evidence, update relevant native design docs, and open a review PR. Do **not** rebuild the PWA, invent missing screens, merge, or deploy.
