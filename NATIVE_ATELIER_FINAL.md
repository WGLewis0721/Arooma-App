# Arooma Native — Atelier Final Visual System (iOS 26)

**Status:** Implemented in `feature/native-atelier-luxury-redesign` as a SwiftUI-only redesign. This document supersedes conflicting PWA delivery constraints in `AROOMA_V2_FINAL_POLISH_SPEC.md` but preserves its visual, artwork, interaction and local-first requirements.

## North star
The collectible is jewelry; every other surface is its fitted velvet tray. Photographic faces and their original metallic edges are the only hero assets. Do not regenerate cards, recolor their art, apply Liquid Glass to imagery, or place glass panels behind cards.

## Functional / content separation
**Content:** An atmospheric color-field, photographed cards, editorial fragrance copy, seasonal shelves and ownership records. Content surfaces use standard opaque/translucent materials and contact shadows, never Glass.
**Functional:** TabView, compact float controls, layout switcher, inspect/close buttons and system sheets. Liquid Glass is applied only to these controls and respects Reduce Transparency.

## Display language
- Every theme has dark and light variants with different atmospheric undertones, not a flat black/white recolor. Obsidian: graphite/navy/plum. Ivory: sand/bronze/cream. Violet: ink/plum/lavender. Emerald: fir/moss/champagne.
- 60:30:10 refers to dominant field, supporting atmosphere and restrained metal accent. Accent is functional and never washes over card art.
- New York/system-serif for title words, SF Pro/system for all labels, status, forms and navigation. Calligraphy is brand-only.
- Full-photo trading cards use the original committed approved masters through `ApprovedArtwork`. Preserve every original card face and reverse; historical Prodigy stays identified as archival.

## Native interactions
- **Onboarding:** one clear choice to Demo or Mine; four themes; visible card previews; returning owners skip it.
- **Gallery:** selected card larger and forward; neighboring cards have carefully limited perspective; finger movement directly controls position; flick release snaps with spring; selected identity persists across three layouts.
- **Inspector:** immersive flip by tapping the card or one clear Flip action; front and back are the exact photographic faces, no rebuilt notes.
- **Shelves:** editorial seasonal bays with horizontal tactile cards, not a generic inventory table.
- **Search:** readable cards, house/note matching, no network requests or fake filters.
- **Ownership:** large card hero, local metrics, wear/undo, history, notes, rotations, and bottle editing in three taps or fewer from common entry points.
- **Themes:** four materially different atmospheric palettes, both light and dark, one coherent system.
- **Gallery view setting:** the Cover Flow / Stack / Fan switcher belongs in the **Style** options screen alongside the theme and appearance pickers. Remove the three-way selector from the bottom of the Cards gallery so the collectible gains visual breathing room. Choosing a layout in Style immediately updates the gallery and persists across app restarts. No second switcher on Cards; the selector controls presentation only and must not be confused with wearing multiple fragrances together.
- **Haptics:** selection settle, wear confirmation, completed actions only; no tapping/hover/flip haptics.
- Liquid wave simulation is deliberately absent from this native experience; preserve stored fill estimates.

## Owner additions — intro calligraphy and living holographic cards (2026-10-30)
These are **approved design requirements for the next native motion/polish pass**, not claims that the current TestFlight build implements them. They take precedence over older blanket restrictions against ambient card shimmer, while preserving the requirement that the card photography itself remains unchanged.

### Signature calligraphy for the app intro
- User-provided visual references: screenshots of ornate pointed-pen monograms and flourishing brush calligraphy, with dramatic thick/thin strokes, confident swashes, hand-drawn rhythm, and an ink-on-paper character (shared in the Arooma design conversation on 2026-10-30).
- The opening **Arooma** wordmark should feel like a bespoke luxury-house hand-lettered signature, **not** default casual cursive or a generic italic serif. Use beautiful letter construction, readable connected forms, and controlled, expressive flourishes; avoid excess loops that harm legibility.
- Animate the **writing of the lettering** as if an actual calligrapher is drawing it: stroke-reveal with variable line weight, a few organic pauses, and a final restrained flourish. Respect Reduce Motion with an immediate static wordmark. No lengthy/replayed intro on returning users.
- Calligraphy remains exclusive to the brand introduction/mark; functional typography stays SF Pro and editorial fragrance headings stay serif. Obtain the appropriate typeface licensing or create original vector lettering before shipping.

### Holography that responds to the physical phone
- **Device tilt changes the perceived foil:** use Core Motion device-attitude/gravity to map the phone's orientation into an angle-dependent light source. Foil rims, select metallic details, spectral reflections, and gentle depth/parallax should respond continuously as the person tilts the iPhone. This is a *simulation of angle-dependent holographic material*, not a literal optical hologram.
- The visual response must be coherent and physically plausible: coordinated highlight direction, restrained rainbow diffraction confined primarily to foil/metal regions, matching card-edge lighting, and a subtly changing contact shadow. The product photograph, wording and original approved card art remain crisp, opaque, and unwarped. Implement any foil treatment as a non-destructive overlay/mask, never rewriting the masters.
- **Idle should not be dead:** a resting focused card has extremely subtle visual life (slow low-amplitude foil scintillation, micro-glints or near-imperceptible atmospheric motion), even when the phone is stationary. No high-frequency flashing, screen-wide automatic shimmer, particle effects, or restless bobbing. User touch/tilt takes precedence immediately over idle behavior.
- Graceful fallback: when motion permissions/data are unavailable, in Simulator, for Reduce Motion, Low Power Mode or thermal/performance constraints, use a static premium finish or a minimal input-driven highlight; no device-orientation dependency for basic usability.
- Performance and behavior acceptance: smooth, finger-coupled drag/flick motion with velocity-continuous settling; no hitching from foil compositing; low battery/CPU impact and no continuous sensor activity when gallery is not visible. Confirm on an actual iPhone under dark/light themes and different lighting, including stationary idle, gentle tilts and quick flicks.

## Owner additions — shelf overview, custom shelves and multi-fragrance wears (2026-10-30)
**Status: product requirements for the next native iOS pass; NOT implemented or validated in the installed TestFlight build.** These restore useful web-prototype functionality and redesign the confusing one-bottle-only native Journal. Preserve the already approved premium, card-first design and responsive gestures.

### 1. Pinch to reveal the whole collection / shelf overview
- Restore the previous web app's **continuous pinch-out from the focused shelf/card view to the full multi-shelf overview, and pinch-in to return to the selected shelf or card**. This is not just image enlargement or a navigation shortcut; it is a spatial zoom out/in between a focused collectible and the whole organized collection.
- Use native SwiftUI multi-touch scale/magnification plus interactive transformations; the transition should track fingers, preserve zoom intent and selection, settle with restrained spring momentum, and be reversible/interruption-safe without accidental card swipes or inspector opens.
- Overview displays named shelves with photographic miniature cards, counts and immediate access to a specific bottle; tapping a shelf or item zooms into that context. Add a visible Shelves/tab path for discoverability and for users unable to pinch. Honor Reduce Motion.
- Reference behavior in retired **index.html**: section `all shelves: pinch out to see every shelf, pinch in to go back` (~lines 2683–2870), including the overview, `zoomToBottle`, `zoomInto`, pinch and explicit Shelves-button fallback. Reimplement natively, do not restore or wrap the PWA.

### 2. Editable, configurable shelf names
- Restore **Rename shelf** directly from the shelf header or contextual action; preview/confirm name, preserve its content, and update the name everywhere including overview, detail, move, share and search.
- Preserve four seasonal shelves as **initial suggestions**, not unchangeable enum labels. Do not replace stored shelf identities when renaming, and do not silently reclassify fragrances when labels change. Allow future shelf creation/reordering without making this screen administrative or crowded.
- Keep in-app persistence compatible with already-installed iOS collections. Shelf identity and display name should be distinct, stable fields; safely migrate the existing four enum-based values to persistent shelf records rather than resetting owned bottles or their assignments.
- Reference retired web behavior at `index.html` ~lines 2879–2895 (`renameShelf`, `openRename`) and the shelf overview pencil action. Preserve the original ease of use.

### 3. Replace ambiguous 'My Bottle' / 'The journal' experience with a clear wear journal
- User report from iPhone: **the purpose of the Journal was unclear, and trying to log two or three fragrances worn together was unsuccessful.** Treat this as a core usability failure, not a styling defect.
- Rename the tab to **Wear Log** or **Today** (validate the clearest label on device); present an obvious action: **What are you wearing today?** with a preview of today's entries, not an ownership page masquerading as a diary. Keep ownership details accessible from the selected card or collection.
- Support **wearing/layering/stacking multiple different fragrances in one session**. In the logging flow, tap one fragrance, tap a second and third (or more if reasonable), then **Log wear**. Show all selected collectible thumbnails as a grouped composition, make multi-selection obvious, and allow adding/removing before confirmation.
- Create an explicit durable **Wear Session** entity containing a session ID, time/date, an ordered set of bottle IDs and optional notes/impression. Optionally capture placement or spray counts later without blocking the first useful action. One session with three bottles is **one combination/event**, not three unrelated logs; each affected bottle must also display its wear count/remaining estimate coherently.
- Permit **more than one session a day**, including repeating a fragrance when intentionally worn again. Today's entries should show the full combinations worn, with edit/undo for an entire session or one component, and never remove unrelated earlier wears. No arbitrary same-day lockout; prevent accidental double-submit at the UI level instead.
- One-tap reuse from a previous combination, with optional naming/pinning of favorite layers (e.g., 'Office combo'), so repeated layering does not require finding all the bottles again. Distinguish the **Stack** visual gallery layout from **Layer / Wear Together** fragrance activity.
- Aim for the common path in 3 interactions: open Today/Wear Log → select the fragrances → log the session (multi-select taps naturally scale with count). User should see a clear recorded confirmation and the grouped cards immediately; accessibility labels describe the combination.
- Migration/data safety: the current native `WearEvent` belongs to a single `BottleRecord`, and `wearSelected()` only updates the selected bottle while blocking another wear for that bottle on the same day. Implement additive/backward-compatible storage and reconcile old per-bottle events into history without fabricating groupings. Don't discard existing wear logs or change their meaning.
- Acceptance: from a new TestFlight install, create two-bottle and three-bottle combinations, see one grouped session for each, view them in history, edit/remove just one component, undo, repeat the combination on the same day, restart app and retain all data. Try on an actual iPhone; verify the experience is understandable without explanation.

### Interaction hierarchy
- **Cards** = admire and inspect a fragrance; **Shelves** = see and organize your entire collection (including pinch overview); **Wear Log/Today** = record what you actually wore, alone or layered; **Style** = choose the surrounding visual finish. Search supports discovery. Don't mix the meanings of card Stack layout and multi-fragrance wearing.
- A layer composition should feel like arranging physical collectible cards together, with restrained shared motion and haptics; no additional dense trackers, charts, or unnecessary controls.

## Data and releases
Retain `CollectionStore` model and existing `arooma-native-v1.json` encoding without migrations, deletions, or resetting onboarding. Keep the bundle ID `com.graymatter.arooma` so TestFlight updates install over the existing app. Use the existing `codemagic.yaml` workflow and App Store distribution profile; do not regenerate signing files.

## Minimal quality gate
1. One Xcode 26 iOS Simulator build from GitHub Actions.
2. Attempt to launch simulator and capture real onboarding/gallery screenshots; screenshot stage may be skipped if a runtime is unavailable, without falsifying success.
3. Run signed `arooma-testflight` in Codemagic after PR merge, using a new build number. Verify the upload in App Store Connect before reporting installation-ready.
4. Physical iPhone acceptance: one each of Cover Flow, Stack, Fan, flip, Demo→Mine, wear/undo, Search, four themes and persistent local data. No fabricated device-performance claim.

## Conflicts flagged
- Old instructions saying "no TestFlight needed" or "improve PWA in place" are obsolete: the owner is already using native TestFlight.
- Old liquid-physics requirements are suspended by current owner direction.
- Requirements safeguarding user data, originality of card assets, copyright review, accessibility and accurate release claims remain in force.
