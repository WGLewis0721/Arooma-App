# Arooma — Navigation V3 & My Collection Press-and-Hold Quick Actions
> **Owner-approved follow-up to Native Navigation V2, November 1, 2026. Authoritative on bottom navigation and My Collection quick-action behavior.**
>
> This plan **supersedes the V2 tab configuration and the instruction to eliminate all tab long-press interactions** in `AROOMA_NATIVE_NAVIGATION_UX_V2_PLAN.md`. V2's *non-overlapping* annotated Explore cleanup, frost-glass tray design, preservation/asset rules, and Maestro QA gates still apply. **Do not bring back the former square My Collection/Wishlist/Sample mode menu.** This V3 menu is a *different*, contextual **action** column triggered only by holding My Collection, not a duplicate navigation switcher. These are implementation instructions, **not a claim they have shipped**.

## 1. Locked native IA (three tabs in exactly this order)

```
[ Explore ]   [ My Collection ]   [ Search ]
      │              │                 │
 sample deck      owned deck        existing scoped
 + / heart        & Wishlist        catalog search,
 Insights          and Shelves       sorting, filters,
                    ├─ daily wear     direct Inspector
                    ├─ layering/history
                    └─ saved cards: retain existing records and recovery access
```

- **Explore:** sample and discovery cards, contextual Add/Wishlist, card details and frosted Insights; **no duplicate Search icon** because Search is now a tab.
- **My Collection:** Owned (default), Wishlist, Shelves and **Today/wear logging, layering, history, saved combinations** in the existing owner context. There is **no Today bottom tab** and **no persistent "What are you wearing today?" banner**. Keep existing data and one-tap wear capability; deliberate layering or history may open the My Collection contextual wear sheet.
- **Search:** third bottom tab; preserve query, scopes, sorting, filters, results and direct Search→Inspector→Search return.
- **Card Studio:** owner explicitly requests its removal from the visible app. Remove the Card Studio UI/entry point and redundant My Cards toolbar button as part of nav cleanup, **without erasing saved personal card files/records, requiring a storage migration, or changing purchase entitlements**. Audit whether any important remaining saved-card access/export is being removed and flag in PR for owner review rather than deleting data.
- **Collection screen layout:** move the current top-most toolbar controls into the lower context/action area as **distinct labelled controls**, but avoid duplicating the contextual Add shortcut. Show fragrance house/name and the *existing concentration and scent-note summary immediately beneath the name*; no action buttons between title and notes. Keep the large collectible card unobscured, accurate position counter, all layouts and user-owned image assets.
- **Long press is for an action column, not another mode menu:** normal tap My Collection navigates; long press exposes precisely the quick actions below. Do not build the old three-destination popup again.

## 2. My Collection tab quick-action column

### Interaction
- **Tap** My Collection tab: select/open My Collection normally, preserving the last owned-card focus and current subview as appropriate.
- **Press and hold** the My Collection tab label/icon: display a compact **vertical floating stack directly above the tab**; no tab change as a side effect of opening the stack. The existing tab remains visibly anchored/selected where appropriate.
- The stack uses Arooma's dark/light theme-aware **native frosted-glass / material** surfaces with clear icon, label, focus/pressed feedback, consistent spring, tactile feedback, correct contrast and a hit target of at least **44×44pt**. Avoid an extra full-width toolbar, duplicate permanent buttons or a four-action submenu.
- A user can lift and **tap a row** to execute; optionally support hold→slide→release if reliable with native UIKit/SwiftUI and Maestro. Tapping elsewhere, swiping away, Escape or selecting a row dismisses the column.
- **Native feasibility:** SwiftUI `TabView` does not itself guarantee a customizable long-press hit target on its system `Tab` label. Validate on the real iOS 26 simulator; use a compatible UIKit tab-bar contextual interaction if needed **without rebuilding the entire system tab bar**. If unsupported, document a precise platform blocker and obtain owner review before substituting a different gesture or permanently custom nav chrome. Do not falsely mark interaction tests passed.

### Actions, exactly top to bottom

| Row | Action after selection | What it must NOT do |
|---|---|---|
| **♡ Wishlist** | Directly navigate to **My Collection → Wishlist** (one destination). Preserve Wishlist selection and records. | No extra Collection mode dropdown; no intermediate navigation menu; no demo-mode switch. |
| **＋ Add** | Open the **existing Quick Add** sheet in the My Collection context, with direct valid-name save and OCR review only when needed; dismiss back to My Collection. | Do not open Card Studio, Search or duplicate entry screens. |
| **💧 Wear** | **Immediately record today's wear for the currently focused owned bottle.** Call the same `CollectionStore.recordWear(bottleIDs: [id])` path used by native wear logging, using the owner-selected owned bottle ID (not the sample-deck card, first catalog result, a wishlist item, or an arbitrary last-worn bottle). Dismiss the column and display a small nonblocking confirmation **"Worn today · [actual fragrance name]"** with **Undo** using existing wear/session rollback. Keep the user on the current tab; no sheet, page, selection screen or automatic navigation. | **Never navigate to a Wear screen/menu.** Never silently log a demo, wishlist, deleted or ambiguous bottle, and never create an accidental duplicate wear entry from a repeated press. |

**Wear availability and truth rules**
1. Identify the owner-selected fragrance through `archive.selectedMineID` (and validate it still points to `archive.bottles`), not through `archive.selectedBottle` if a global `archive.mode` currently reflects Explore/Search/Wishlist. The action's subtitle/secondary text must show the **specific bottle name** (e.g., `Wear · Sauvage Elixir`) so the user can see what will be recorded.
2. If there is **no valid selected owned bottle**, disable Wear with the readable reason **"Select a bottle in My Collection"**. Do not turn the row into a selection flow because the owner said Wear logs directly. A normal tap My Collection is the way to choose a bottle.
3. If currently in a Wishlist subview, do not infer that the currently shown wishlist fragrance is owned. Wear only if there is an explicitly remembered eligible owned focus, clearly shown by name; otherwise disable.
4. If that bottle **is already logged today** via the shortcut, display **"Worn today"** (disabled or an informational state) rather than creating a second accidental session. Intentionally logging a second wear can remain available via a deliberate owner flow if the app supports it. Do not let repeat gestures decrement remaining twice unintentionally.
5. The immediate action records one solo wear and a new session by the same existing data path (including remaining level and wear history). `Undo` reverses **only the newly created session ID**; do not undo another bottle's wear or reset unrelated layered sessions.
6. On successful logging provide a modest haptic and nonblocking confirmation; if disabled, keep the column available with an accessible explanation instead of silently doing nothing.

### Accessibility / reduced motion
- Accessible alternative to the press-and-hold interaction: expose **"Collection quick actions"** in VoiceOver custom actions or another clear and minimal supported accessibility path inside My Collection; no discoverability trap.
- VoiceOver should speak action, selected fragrance, whether Wear already logged, and save result. Respect reduced motion, increased contrast, reduced transparency, and safe-area/keyboard layouts.
- Test a short/long title, 375/390/430pt screen widths, dark/light themes, thumb reach, and system tab behavior in iOS 26.

## 3. Changes to current native files

The following is based on the latest native SwiftUI source, not a claim the changes have already been made:

- `ios/AroomaNative/AroomaApp.swift`: replace V2 `AtelierTab.explore/today/myCollection` with **`explore/myCollection/search`**, with real `AtelierSearch` as third Tab; relocate wear/layer/history into Collection; retain search→Inspector return state and Quick Add origin handling. Remove bottom accessory that duplicates an absent Today tab. Attach press-and-hold to **real My Collection tab hit region** and present anchored vertical action column; wire callbacks above.
- `ios/AroomaNative/AtelierGallery.swift`: keep V2 deck decluttering and compact sample-card add/heart; change owned focused-card layout to name→concentration/notes→contextual actions. Remove giant Wear bar where truly duplicated by the shortcut, without taking away 1-tap wear for users who never long-press.
- `ios/AroomaNative/AtelierSections.swift`: embed current `AtelierWearLog` with all existing wear, layer, saved-layer, undo/history functionality as a **My Collection subview/sheet** instead of standalone Today tab. Maintain one-tap primary Wear from a focused owned card and its new tab quick action.
- `ios/AroomaNative/CollectionStore.swift`: use existing `selectedMineID` and `recordWear(bottleIDs:)`; add only the smallest guard/state needed to deduplicate the shortcut and present the exact resulting session for scoped Undo. Preserve `SavedArchive` schema, user data, demo/own mode separation, persistence, and historical wear.
- `ios/AroomaNative/Search.swift`: move to real third tab, preserve current filters/sort and Inspector navigation; remove redundant Explore search button/entry.
- `ios/AroomaNative/Commercial.swift`: hide/remove Card Studio UI and redundant My Cards navigation, **but preserve saved records**; inventory whether any remaining owner content needs read/export recovery before removing surfaces.
- Design docs: reconcile `docs/design/README.md`, native platform/UX guidance, and the relevant specs with this owner's newer navigation decision. Do not treat V2's three-tab titles as still valid.

## 4. Maestro functional gates and acceptance

Read `.claude/skills/maestro-ui-testing/SKILL.md`, `.maestro/README.md`, and `.github/workflows/maestro-ios.yml`; verify the actual version of Maestro MCP tools and run iOS 26 simulator tests on macOS CI if this session lacks a Mac. Build a **Debug** app; never claim a physical-device run without executing it. Existing test flows must be updated for the removed Today tab and new Search tab.

Add persistent `.maestro` flows testing:

- `navigation-v3.yaml`: **exactly Explore, My Collection, Search** tabs, in order, no Today tab and no separate Cards tab. Explore's redundant Search icon absent. Navigation preserves owned/demo/Wishlist selections.
- `collection-long-press-actions.yaml`: tap on My Collection navigates normally; **long-press** same tab displays **exactly Wishlist, Add, Wear** as a vertical column anchored above it, and dismissal preserves the original screen.
- `collection-long-press-wishlist.yaml`: Wishlist row opens My Collection's Wishlist without intermediate menus; return to Owned works.
- `collection-long-press-add.yaml`: Add opens existing Quick Add with direct name/destination save; dismiss returns to Collection, no Card Studio.
- `collection-long-press-wear.yaml`: select a specific test **owned** bottle in My Collection; long press tab; tap **Wear**; **no new screen appears**, same tab remains; exactly one dated wear session and one remaining-value decrement; confirmation shows correct bottle; repeat press doesn't duplicate; Undo removes only that session and restores remaining. Test with Explore still focused on a different demo fragrance.
- `collection-long-press-wear-disabled.yaml`: empty owned list or deleted selection disables Wear with explanation; a Wishlist/demo focus cannot be falsely logged.
- `collection-layout-v3.yaml`: owned card title with notes **directly beneath**; context controls are placed low, card remains visually dominant; no duplicated top toolbar or wear banner.
- `collection-wear-layer-history.yaml`: direct solo wear, 2-bottle layer, saved set, history, undo **inside My Collection**, no Today tab route.
- `search-tab-v3.yaml`: tap third Search tab, query/filter/sort, open Inspector, dismiss back to Search preserving input and selected filter.

**Quantified definition of done:** (i) exactly **3** tabs in order **Explore / My Collection / Search**; (ii) **3** long-press column actions **Wishlist / Add / Wear**, with **0** extra screens for Wear; (iii) **1** committed wear session for one eligible click and **0** duplicates from repeated accidental presses; (iv) correct bottle identified by ID, one Undo scoped by session ID, never logging a sample or wishlist card; (v) all original collection/wishlist/wear/layer/history/search and card art functionality retained; (vi) no visible Card Studio and no loss of saved card files; (vii) native before/after simulator screenshots and all modified flows reported **PASS/FAIL/NOT RUN** with real evidence. Retain frosted-glass material and reduce-motion/accessibility expectations. Do not claim a feature complete if CI could not exercise the iOS tab-bar long press.

**Delivery:** focused implementation PR, updated design docs, screenshots and Maestro CI artifacts. **Do not merge, upload TestFlight, or delete user data without explicit owner instruction.**
