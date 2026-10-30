# Spec: Polish pass (own collection, backup, wear loop, photos, rotations)

> Part of the Arooma design brain. Start at [../README.md](../README.md). Follow [../PLAN_SPEC_PROTOCOL.md](../PLAN_SPEC_PROTOCOL.md).

| | |
| --- | --- |
| Request | "Arooma: Polish and Iterate the Web Prototype": a polish-and-fix pass with acceptance IDs FR, BK, CM, WL, BP, PL, WO, TS |
| Restated | Make the single-file web prototype something an owner can actually keep their own collection in, on an iPhone, without losing it |
| Surface | Shelf, card, panels, test timer, share image |
| Size | L |
| Author | Claude, 2026-10-29 |
| Status | In review, built in `index.html` |
| Governing docs read | RULES_CARD.md, brand/BRAND_BOARD.md (all), packs/shelf-change.md, packs/device-layout.md, specs/2026-10-29-cabinet-features.md, specs/2026-10-29-shelves-and-liquid.md |

## 1. Problem

A new owner opened the app and got seven fictional bottles they could not fully remove (the last bottle could not be deleted), mixed in with anything they added. Their data lived only in this browser with no way out, Fan was a second view of everything, and the timer defaulted to 30 seconds with Dynamic Island language the web cannot deliver.

## 2. What changed

- **First run.** The doors open on a choice: Start my collection (empty) or Explore the demo. Nothing is saved until the owner chooses.
- **Two collections, never mixed.** Storage schema 3 keeps `own` and `demo` apart. The demo is labeled in the eyebrow and on the plank. A v1 or v2 save migrates on load and is written back at once: owner bottles to `own`, samples to `demo`.
- **Empty shelf.** A Paper-quiet empty state with Add a bottle and a second action (Explore the demo, or See all shelves).
- **Delete anything.** The last-bottle guard is gone; demo samples delete too. Undo for a few seconds.
- **Menu.** Find, Rotations, Compare, Share, Back up, Restore, then the collection actions: Clear my collection and Explore the demo (or Back to my collection, Reset the demo). Each destructive or switching action confirms first. The menu opens with a plain storage line: "Saved on this device, in this browser only. Nothing is uploaded." plus the last backup date.
- **Backup.** A JSON file (`app`, `kind`, `schema`, `exportedAt`, `collection`) with every shelf, bottle, note, wear, impression, photo and rotation, delivered through the share sheet or a download. Restore validates first, says what the file holds, and offers Add to my collection (merge, existing bottles untouched) or Replace (asks a second time). A bad file changes nothing.
- **Find.** "/" or the menu. Searches house and fragrance, ignoring case and accents, across every shelf. Picking a result selects the bottle (or zooms to it from the overview).
- **Edit is visible.** A pencil sits on the selected card; the bottle menu lists Edit first; the `e` key edits.
- **Position.** A new bottle lands at the end of its shelf and is selected. A delete hands the slot to the next bottle; Undo returns it to the same slot. A move follows the bottle with Undo.
- **Wear loop.** Wear today is one tap with a quiet toast. Under it, "Add how it wore today" opens an optional impression (opening, development, projection, longevity, a note), editable later from Wear history. The record's back shows Recent wears with the impression summary. The daily pick cites history honestly.
- **Photos.** Any bottle can carry the owner's photo, resized to 640 px JPEG, with zoom and position sliders, shown with object-fit cover in the same art well and baseline as the drawings.
- **Layouts with jobs.** Cover Flow browses the shelf. Stack is the five best candidates for today plus the selected bottle. Fan presents a saved rotation (up to five, named, up to twelve rotations); the selected bottle joins as a guest. With no rotation, Fan opens the rotation maker.
- **Wording.** "Estimated remaining" and "Estimated N% left". Authenticity is "Authenticity notes". Compare speaks of overlap in listed notes.
- **Timer.** An in-app testing aid with check-ins at 15 minutes, 1 hour and 3 hours. The 30 second default is gone. A due check-in offers Log impression.
- **Haptics.** Removed from card flips; added on a due check-in and a saved backup.
- **Fix.** Closing a panel resets any page scroll an input caused.

## 3. Acceptance report

Evidence is the smoke test (`npm test`, 173 checks, all passing on Chromium) unless noted. Nothing here is device-tested.

| ID | Result | Evidence |
| --- | --- | --- |
| FR-1 | Done | "first run offers Start my collection or Explore demo", "FR-1: Start my collection opens a truly empty cabinet" |
| FR-2 | Done | "FR-2: the demo is labeled and the own collection is untouched", "back to my collection, exactly as left" |
| FR-3 | Done | "FR-3: the last bottle can be deleted", "a demo sample can be deleted too" |
| FR-4 | Done | "FR-4: the empty shelf has a clear Add a bottle action"; screenshots 30, 21b |
| FR-5 | Done | "Clear and Load demo are separate menu actions", "Clear asks first", "Explore the demo asks first" |
| FR-6 | Done | "FR-6: a v1 save ... migrates to schema 3"; v2 and hostile-storage checks still pass |
| BK-1 | Done | "BK-1: the backup is a JSON file with every shelf, bottle, photo, wear, impression and rotation" |
| BK-2 | Done | review states merge or replace before changing anything; replace asks twice; three invalid files refused |
| BK-3 | Done | "BK-3: export, clear, import round-trips to an identical collection" (byte-identical JSON) |
| BK-4 | Done | "BK-4: the menu says data lives on this device and suggests a backup"; last backup date stored |
| CM-1 | Done | name, house, case and accent search checks; 60-bottle search |
| CM-2 | Done | pencil on the selected card opens edit; edit saved in place |
| CM-3 | Done | selection checks in Stack, Fan (with rotation) and Cover Flow, demo and own |
| CM-4 | Done | lands at 01 / 01 and 03 / 03; delete hands over the slot; Undo restores 02 / 03; move follows with Undo |
| CM-5 | Partial | duplicates, missing optional fields, 40-character names with ellipsis, 60 bottles render and step 20 times within budget. Not measured on an iPhone; 150-bottle ceiling untested |
| CM-6 | Done | Wear today stays in the main row; quiet toast; meta line reads "Worn today" |
| WL-1 | Done | "WL-1: one tap logs a wear and confirms quietly" |
| WL-2 | Done | impression offered, not forced; saved against today's wear |
| WL-3 | Done | "WL-3: the record shows a timeline with the impression"; screenshot 32 |
| WL-4 | Done | pick reason built from days since last wear and the last longevity note |
| WL-5 | Done | no feeds, counts across users, or sharing of history; nothing leaves the device |
| BP-1 | Done | photo upload, stored as JPEG, shown on the card and in the share image |
| BP-2 | Done | object-fit cover check; zoom and position sliders |
| BP-3 | Partial | drawn set covers clear, near-black, amber, opaque white, smoke, green, clay and metallic caps. Real photos of mixed bottles were not tested; only a synthetic image |
| BP-4 | Partial | photos and drawings share the art well, baseline and card; judged from screenshots only, not with real photos |
| PL-1 | Partial | spacing, ellipsis, demo tag placement, record timeline refined; no designer review or device pass |
| PL-2 | Done | Stack shortlist and Fan rotation captions; Fan with no rotation opens the maker |
| PL-3 | Done | selection persists; neighbors animate between positions (existing layout transitions) |
| PL-4 | Partial | every gesture has a tap or key path; scroll inside panels does not move cards. Accidental activation on a real touch screen untested |
| PL-5 | Done | liquid tests, and Reduce Motion draws it flat at the estimated level |
| WO-1 | Done | "Estimated remaining" check; no "true liquid level" text |
| WO-2 | Done | compare check: overlap, listed notes only, no promise |
| WO-3 | Done | "Authenticity notes"; "does not verify authenticity" check |
| WO-4 | Done | timer runs to a 15 minute check-in; copy says in-app aid |
| TS-1 | Done | 173 checks, all prior checks kept or updated to the new first run |
| TS-2 | Not done | no device access in this session |
| TS-3 | Done | checklist below, marked untested |

## 4. Rules changed

The owner's brief lifted three rules; the rules card and brand board now say: Clay is the one accent for a state that needs it; haptics are allowed where they carry meaning; owner photos are allowed and never blocked. Fan's job changed from "3-bottle rotation" to "saved rotation of up to five". "Truthful liquid level" became "Estimated remaining".

## 5. Device checklist (untested)

Run on a real iPhone, Safari and Home Screen install. Every item is untested.

- [ ] Add and edit panels: keyboard does not hide the Save button; the page returns to place after closing.
- [ ] Photo: camera and library both work from the file picker; a HEIC photo converts; sliders are usable with a thumb.
- [ ] Gestures: swipe in Cover Flow does not trigger a flip; scrolling a panel never moves cards; pinch does not zoom the page.
- [ ] 375 x 667 (SE): long names, the empty state and the welcome fit without horizontal scroll.
- [ ] Reduce Motion on: doors, layouts and the overview cross-fade; the liquid is flat.
- [ ] VoiceOver: welcome buttons, empty state, card, pencil, Wear today, impression segments, search results are announced and reachable.
- [ ] Reload and relaunch from the Home Screen: collection, selection, layout and rotation persist.
- [ ] Backup through the share sheet to Files, then Restore from Files: merge and replace both round-trip.
- [ ] 150 bottles with photos: storage quota message appears before failure; scrolling stays smooth.
- [ ] Haptics on selection settle, wear and a due check-in.

## 6. Deferred

- Real Dynamic Island, widgets and a store a widget can read: needs the native build.
- Night palette.
- Photo background removal or automatic lighting match.
- Storing photos outside `localStorage` (IndexedDB) for large collections.

## 7. Open design questions

1. Should Stack's shortlist be the top five by "due to wear", or something the owner sets (a "today" tray)?
2. Is twelve rotations of five the right ceiling, and should a rotation be allowed to span shelves in Fan's caption?
3. Should a photo bottle show an estimated level (a hairline gauge on the card) since its liquid is no longer drawn?
4. Should the app nudge for a backup after N changes, or only show the last backup date in the menu?
5. Should impressions be asked for at the 3 hour check-in by default, or only when the owner taps?
6. Is "Demo collection" on the plank enough, or should the demo use a slightly different ground so it never reads as the owner's shelf in a screenshot?
