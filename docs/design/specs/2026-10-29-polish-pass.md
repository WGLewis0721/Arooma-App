# Spec: Polish pass on the web prototype, ownership, backup, wear loop and photos

> Part of the Arooma design brain. Start at [../README.md](../README.md). Follow [../PLAN_SPEC_PROTOCOL.md](../PLAN_SPEC_PROTOCOL.md). Saved as `docs/design/specs/2026-10-29-polish-pass.md`.

> Summary: what changed and why (1 to 5), how it works in `index.html` (6, 7), the acceptance report by ID (9), the manual device checklist that is still owed (9), and open questions for the owner (8).

| | |
| --- | --- |
| Request | "Arooma: polish and iterate the web prototype", an acceptance sheet with IDs FR, BK, CM, WL, BP, PL, WO, TS |
| Restated | Someone keeping a real collection can start empty, add and photograph their own bottles, find one quickly, log wears and how they wore, and back it all up, in a cabinet that stays calm and honest about what it knows |
| Surface | Shelf, cards and record, every panel, the overview, the Island chip, the share image |
| Size | L (data model, several surfaces, wording and a rule change) |
| Author | Claude, 2026-10-29, for the owner |
| Status | In review. Built in `index.html` on branch `polish/warm-archive-pass`; owner decides section 8 |
| Governing docs read | `RULES_CARD.md`; `README.md`; `PLAN_SPEC_PROTOCOL.md`; `packs/shelf-change.md`; `brand/BRAND_BOARD.md`; `DECISIONS.md`; `specs/2026-10-29-cabinet-features.md` |

## 1. Problem

The first time someone opens Arooma, seven fictional bottles are already on their shelf and the last one can never be removed. When they add their own, the samples stay mixed in. Their data lives in one browser with no way out. They can log that they wore something but not how it wore, so the next morning's pick knows nothing useful. Their own bottles can only be one of seven drawings. And the test timer runs for 30 seconds, which measures nothing.

## 2. Evidence and context

- `[Repo]` Before this pass: one storage key holding samples and real bottles together; `N<=1` blocked delete; Fan filled its rotation with any three bottles; no search, edit, export or import; impressions from the test timer were not saved; card names overflowed at 28 characters.
- `[Repo]` Rules that bite: no network call, one file, no new colors or fonts, cards opaque, haptics at three moments, remaining volume is an estimate, no authenticity or match claims.
- The brief lifts three old limits: an accent where a state needs one (not needed here), haptics beyond three moments if purposeful (kept at three kinds), and user photos (built).

## 3. Goals, non-goals and budget

- **Goals:** the FR, BK, CM, WL, BP, PL and WO items in section 9, with tests.
- **Non-goals:** accounts, sync, any server, barcode scanning, a social or ranking surface, a journal or dashboard view, a native build, background removal for photos.
- **Appetite:** one session, one file, no new token.

## 4. Rules that apply and exceptions needed

| Rule (document and section) | How this pass touches it |
| --- | --- |
| `RULES_CARD.md`, Look: liquid level | Owner photos carry a level window like the opaque drawings, liquid coloured from the photo and simulated. Owner decision, 2026-10-29: show the liquid and keep the motion |
| `RULES_CARD.md`, Look: no new colors, fonts, decorative styles | None added. The empty state reuses the card recipe; search reuses inputs and paper rows |
| `RULES_CARD.md`, Behavior: haptics at three moments | Kept to the three kinds. Completed action now also covers add, edit, impression saved, export and restore |
| `RULES_CARD.md`, Behavior: Dynamic Island | Reworded to "Island chip, in-app timer". The visual stays as the brand board specifies |
| `RULES_CARD.md`, Boundaries: network | Nothing leaves the device. Export uses the share sheet or a download; import reads a local file |

## 5. Options and the chosen concept

| Option | Idea | Why not, or why |
| --- | --- | --- |
| A | Keep one store; mark demo bottles and hide them on request | Demo and owner data still share a key, so a reset or a bug can touch real data |
| B | Separate stores for the collection and the demo, mode switch in the menu, first run asks | **Chosen.** Demo changes can never reach the owner's data, and the label is the mode itself |
| C | No demo at all; an empty cabinet with a tour | Loses the quickest way to understand the three layouts |

Search: a header button (rejected: a fourth header button truncates the title at 375 wide), a menu-only panel (rejected: two taps), or **the top of the All shelves view** (chosen: one tap, and it is where you look across a cabinet). Photos: IndexedDB blobs (deferred, see 8) or **shrunk data URLs in the same JSON** (chosen: one store, one export file).

### Breadboard

- **First run:** doors open on a paper card, "Your cabinet is open", with Start my collection and Explore demo.
- **Empty cabinet:** a card with Add a bottle, Restore a backup, Explore the demo instead. Layouts and Daily Pick wait.
- **Header:** All shelves and search, Add, Cabinet menu. The eyebrow reads "Demo · 07 objects" in the demo.
- **Cabinet menu:** (demo: Back to my collection), Find a bottle, Compare, Share, Backup and restore, Explore the demo or Reset the demo, Remove sample bottles (only if an old save mixed them in), Clear my collection, Replay the doors.
- **Bottle menu:** Edit details, Wear history, Add to or Remove from rotation, Move, Authenticity notes, Delete.
- **Info area:** reason, notes, Last worn and Estimated remaining, Wear today, Test, More; after a wear, "Add how it wore".
- **Record (back):** five rows, Recent wears with up to three impressions, the owner's line, Edit details.
- **Panels:** Add or edit (with the photo editor: preview, Size, Left and right, Up and down, drag), How it wore, Wear history (Add impression or Edit per wear), Backup and restore, Restore review (replace or add, then a second confirm to replace a non-empty collection).

### States

First run, empty collection, empty demo, one bottle (Fan shows it as visiting), 200 bottles (limit), duplicate name (asked once), long name (ellipsis, full in its label), no notes (line hidden), photo too large or not an image (message), storage full (one warning to export), damaged or hostile saves (first run or cleaned data, old key untouched), import of a non-Arooma or newer file (refused, nothing changed), undo after delete, move, clear, remove samples, restore and rotation changes.

## 6. Platform behavior

Widths 375, 390, 393 and 430 tested in Chromium with a touch viewport; landscape keeps the existing prompt. Inputs are 16 px. Every new control is at least 34 px tall and the primary ones 44 px. Photo position has sliders as the tap and keyboard path for the drag. Search takes `/` and Escape. Reduce Motion keeps the existing cross-fade rule. Safari and the Home Screen app keep separate storage, which the backup panel says.

## 7. Technical approach

- **Storage:** `arooma.cabinet` `{v:3, shelves, bottles, rot}`; `arooma.demo` the same shape, written only once changed; `arooma.prefs` `{mode, backupAt}`; `arooma.test` the running session. `cleanState` accepts v1, v2 and v3 and is used for loading, migration and import alike. Migration copies `arooma.v1` into `arooma.cabinet` once and never deletes it.
- **Photos:** `readPhoto` decodes, lets the browser apply orientation, shrinks to 560 px or less, keeps PNG or WebP when the image has transparency and JPEG otherwise, and refuses anything over 600,000 characters. `photoArt(img)` draws it with `preserveAspectRatio="xMidYMax meet"` on the shared table and light, plus a level window from `photoWin(img)`: the stored aspect ratio gives the bottle's real outline in the frame, the window sits in its lower body at `img.w` across, and its liquid uses `img.c`, the average of the coloured, opaque pixels in the lower middle of the photo (neutral amber when the photo gives no reliable colour). A full bottle fills 92% of the window so the surface keeps room to move. Photos are stored at 480 px or less (about 30 to 120 KB). The first successful save asks `navigator.storage.persist()`. Backup shows the collection's size, and a reminder appears at most weekly once there are five bottles and no export in 30 days.
- **Search:** `findHits` splits the query into words, removes accents and needs every word in the house or name.
- **Do not touch:** tokens, the liquid engine, the layout transforms, the share canvas shape.

## 8. Risks and decisions

| Item | Decision | By |
| --- | --- | --- |
| Liquid on photo bottles | Shown through a level window, coloured from the photo, with the same motion | Owner |
| Photo storage | Stay in `localStorage`: shrink to 480 px, request persistent storage, show usage, remind to back up. A real collection of 60 photos fits in about 3 to 5 MB, so the reminder matters. IndexedDB or files come with the native build, where the widget needs a shared store anyway | Claude, at the owner's direction |
| Photo backgrounds | Keep the "cut-out sits best" hint. On-device background removal needs native Vision; do it in the native build | Claude |
| Session check-ins at 20 minutes and 2 hours | Keep; they match how a skin test actually moves | Claude |
| Rotation of three | Keep; it matches the Fan geometry and a weekly rotation | Claude |
| `arooma.v1` fallback | Keep for one release, then remove in its own spec | Owner to confirm |
| Device risk | The level window position is a guess from the outline; the owner can slide it. Check on real photos of real bottles | Owed on a device |

## 9. Verification and acceptance report

`npm test` runs 191 checks, all passing in headless Chromium (111 before this pass, all kept; four changed meaning by request: no forced samples, last bottle deletable, demo in its own key, the timer reads minutes). `npm run docs:check` passes. Nothing here was run on an iPhone.

| ID | Result | Evidence |
| --- | --- | --- |
| FR-1 | Done | Test: first run has 0 bottles and both choices; Start my collection saves an empty v3 cabinet |
| FR-2 | Done | Eyebrow says Demo; a bottle added in the demo is absent from `arooma.cabinet`; migrated samples are tagged Sample |
| FR-3 | Done | Test deletes the last bottle, empty state returns, Undo restores |
| FR-4 | Done | Empty card with Add a bottle, Restore a backup and the demo; screenshot 30 |
| FR-5 | Done | Separate menu rows, each with its own confirm; Clear leaves the demo untouched |
| FR-6 | Done | v1 and v2 saves migrate to v3 once; old key byte-identical; damaged saves fall back to first run |
| BK-1 | Done | Export JSON holds shelves, bottles, notes, photos, wears, impressions and rotation |
| BK-2 | Done | Review panel states contents, Replace or Add; non-empty Replace asks again; bad files change nothing |
| BK-3 | Done | Export, clear, restore compared key by key: identical |
| BK-4 | Done | Backup panel, empty card and menu row say the data lives in this browser on this device |
| CM-1 | Done | Accent-free, case-free, all-words search in the overview; `/` opens it |
| CM-2 | Done | Edit details is the first bottle-menu row and a link on the record |
| CM-3 | Done | Existing layout tests plus Fan visiting state |
| CM-4 | Done | Add and move go to the end of the shelf; delete selects the next on the same shelf; Undo restores the place |
| CM-5 | Done in Chromium | Ellipsis, hidden empty notes, duplicate asked once, 60 bottles under 25 ms per step headless; device speed owed |
| CM-6 | Done | One tap, toast with Undo, meta reads Worn today |
| WL-1 | Done | One tap |
| WL-2 | Done | Optional link after a wear, history per wear, test session; every field optional |
| WL-3 | Done | Record shows three latest wears with impressions |
| WL-4 | Done | "You haven't worn this in a while: 40 days. Last time you noted over 6 hours." |
| WL-5 | Done | No feed or ranking; no request leaves the page in the test |
| BP-1 | Done | Six photos stored; PNG or WebP kept for transparency, JPEG otherwise |
| BP-2 | Done | `meet` everywhere; size and position by slider and drag, saved |
| BP-3 | Done in Chromium | Generated clear, near-black, amber, opaque white with background, metal cap, irregular and wide images; screenshots 35 to 40 |
| BP-4 | Done in Chromium | Same table, baseline, shadow, light and moving liquid for every photo; true scale is set by the owner, and a photo with a background still reads as a picture |
| PL-1 | Partial | Long-name ellipsis, record timeline, empty state on the card recipe, install hint style bug fixed; no token or shadow values changed |
| PL-2 | Done | Cover Flow browses, Stack shortlists, Fan shows only the saved rotation; share image in Fan is the rotation |
| PL-3 | Done | One DOM kept; selection survives every layout and the visiting state |
| PL-4 | Done | Every new drag has sliders or buttons; search, edit and impressions never need a gesture |
| PL-5 | Done | Liquid engine unchanged; Reduce Motion tests pass |
| WO-1 | Done | "Estimated remaining" everywhere; test scans all text |
| WO-2 | Done | Compare says it compares notes you entered and cannot predict wear or liking |
| WO-3 | Done | "Authenticity notes", "Your checks", "cannot verify" |
| WO-4 | Done | 30 second default removed; check-ins at 0, 20 minutes, 2 hours; labelled an in-app timer |
| TS-1 | Done | 187 checks |
| TS-2 | Not done | No device available in this session |
| TS-3 | Done | Checklist below, untested |

### Manual device checklist (untested, owed on a real iPhone, Safari and Home Screen)

- [ ] Add and edit panels: the keyboard does not cover the field in focus; Done and Save stay reachable; date pickers open.
- [ ] Photo picker: a Photos library image (HEIC) imports, is upright, and survives a reload; a large image does not freeze the page.
- [ ] Touch: dragging cards never triggers a flip; scrolling a panel never moves the shelf; a photo drag does not scroll the panel.
- [ ] 375 by 667 with a 48-character name and the largest text setting.
- [ ] Reduce Motion: no slides, the liquid is flat.
- [ ] VoiceOver: first-run choices, empty state, search results, Wear today, Add how it wore, the impression buttons, the restore choices.
- [ ] Reload and relaunch from the Home Screen: collection, mode and a running test session return.
- [ ] Export to Files, Clear, Restore from Files: same collection. Note that Safari and the Home Screen app do not share it.
- [ ] 60 bottles with 20 photos: Cover Flow, Stack and the overview stay smooth; storage warning appears if the quota is hit.
- [ ] Haptics at settle, wear and completed action only.

## 10. Rollout, rollback and release

Ships with the next merge to `main` after owner review. Rollback is a revert: older builds still read `arooma.v1`, which this build never changes, so a reverted app shows the collection as it was before migration (later changes live only in `arooma.cabinet`).

## 11. Decision record

| Date | Decision | By | Documents updated |
| --- | --- | --- | --- |
| 2026-10-29 | Separate stores for collection and demo, first-run choice, schema v3 with one-way migration; backup as one JSON file; search in the overview; impressions per wear; owner photos on the shared table with no drawn liquid; Fan as the saved rotation; testing session at 0, 20 minutes and 2 hours | Owner brief, applied by Claude | `RULES_CARD.md`, `brand/BRAND_BOARD.md`, `packs/shelf-change.md`, `DECISIONS.md`, `specs/README.md` |
