# Spec: All-shelves zoom, named shelves, and living liquid

> Part of the Arooma design brain. Start at [../README.md](../README.md). Follow [../PLAN_SPEC_PROTOCOL.md](../PLAN_SPEC_PROTOCOL.md). Saved as `docs/design/specs/2026-10-29-shelves-and-liquid.md`.

| | |
| --- | --- |
| Request | "Make a pinch to zoom so you can zoom out and see all your shelves as a way to show all items in the collection. Right now I only see one shelf and let the user rename them. The default is season shelves but the pencils will let the user know they can change the name. Let them also add a new shelf in the zoomed out view." And: "Bring the liquid in the bottles to life. The user should always be able to see the liquid and fill level of the bottles. Bring them to life with physics, momentum, and directional undulating." |
| Restated | The owner sees the whole collection as named shelves by pinching out, renames or adds shelves there, and every bottle shows its liquid and fill level, which moves like real liquid |
| Surface | Shelf, a new all-shelves view, rename and add panels, every bottle drawing, the share image |
| Size | L (a new view, a data model change, a gesture, and a change to bottle art that touches a rule) |
| Author | Claude, 2026-10-29, for the owner |
| Status | In review. Built in `index.html`; the owner decides section 8 |
| Governing docs read | `RULES_CARD.md`; `PLAN_SPEC_PROTOCOL.md`; `packs/shelf-change.md`; `packs/device-layout.md`; `brand/BRAND_BOARD.md` sections 3, 4 and 7; `DECISIONS.md`; `specs/2026-10-29-cabinet-features.md` |

## 1. Problem

`[Assumption]` The owner has more bottles than fit one row of Cover Flow, and thinks of them in groups: what suits the season, what is for evenings. Today the app has one shelf titled "Autumn shelf" holding everything, so the only way to see the whole collection is to swipe through it card by card, and the title cannot change. Separately, the liquid in each bottle is a flat colored band. On three bottles (black glass, white ceramic, terracotta) it is not drawn at all, so their fill level cannot be seen.

## 2. Evidence and context

- `[Repo]` One shelf, one title, all bottles in one row. The title and the share image's "Autumn 2026" were fixed text.
- `[Repo]` Bottle art: four vessels draw liquid as a flat clipped rectangle; the black, ceramic and terracotta vessels draw none.
- `[Repo]` Rules that bite: the selected bottle persists across layouts; every drag has a tap and a keyboard path; Reduce Motion means cross-fades only; bottle art stays neutral and true to each house with a truthful liquid level; no new colors, fonts or decorative styles; remaining volume is an estimate.
- `[Apple]` Not re-read for this spec. The pinch on the web uses pointer events, `ctrl` plus `wheel`, and WebKit gesture events; none of it was checked against Apple's pages or on a device.

## 3. Goals, non-goals and budget

- **Goals:** pinch in to see every shelf, pinch out to open one; default shelves are the four seasons; a pencil on each shelf renames it; add a shelf from the zoomed-out view; every bottle shows liquid and level; liquid reacts to motion with momentum, travels in the direction of movement, and is never dead still.
- **Non-goals:** dragging bottles between shelves (a menu moves them); reordering shelves; shelf-specific Fan rotations; device tilt (accelerometer) control of the liquid; a liquid color picker; any network call.
- **Appetite:** one session. No new color, face or decorative style, and one file.

## 4. Rules that apply and exceptions needed

| Rule (document and section) | How this request touches it |
| --- | --- |
| `RULES_CARD.md`, Behavior: the selected bottle persists across layouts | Zooming out and in keeps the same bottle selected; opening another shelf selects that shelf's last or first bottle, and snapping back restores the old selection |
| `RULES_CARD.md`, Behavior: every drag has a tap and a keyboard path; Reduce Motion means cross-fades only | The pinch also has the Shelves button, Open shelf, `-` and Escape, ctrl and wheel, and Safari gesture events. Reduce Motion swaps the layers with no scaling and draws the liquid flat |
| `RULES_CARD.md`, Look: cards opaque, glass only on switcher, toolbar and header buttons | Shelf rows are opaque, built from the stage gradient and plank already in use. The new Shelves button and the overview bar are glass like the existing ones |
| `RULES_CARD.md`, Look: no new colors, fonts or decorative styles | None. Three level windows use colors inside the bottle drawings, as every vessel does |
| `RULES_CARD.md`, Look: bottle art stays neutral and true to each house, truthful liquid level | **See the exception below** |
| `RULES_CARD.md`, Behavior: remaining volume is an estimate | Unchanged. The drawn level is the estimate |
| `RULES_CARD.md`, Behavior: haptics at three moments | Unchanged. Liquid kicks have no haptic; adding a shelf uses the completed-action tick |
| `RULES_CARD.md`, Boundaries: no network call, one file | Holds |

**Exceptions needed (owner decides, do not assume):**
1. **A level window on three vessels.** The black-glass, white-ceramic and terracotta bottles are opaque, so the request to always see the liquid cannot be met without changing their drawing. Each now has a narrow window on one side showing the liquid against a pale backdrop. The terracotta label is 10 units narrower to make room. This changes how three fictional houses' bottles look. Alternative: make them translucent, which changes their material more. Default: keep the windows.
2. **Rule wording.** The card says "truthful liquid level" but not "always visible". Proposed addition to the Look bullet on bottle art: "Every bottle shows its liquid and level; an opaque vessel gets a level window." Not applied to `RULES_CARD.md`, which the owner controls.

## 5. Options and the chosen concept

### Options considered

| Option | Idea | Pros | Cons |
| --- | --- | --- | --- |
| A | Pinch zooms the Cover Flow itself out into a grid of every bottle, with no shelves | Simplest, one flat collection | The owner asked for named shelves and renaming |
| B | A separate all-shelves view the shelf zooms into and out of; shelves are named groups, one bottle on one shelf | Matches the request; keeps Cover Flow, Stack and Fan unchanged inside a shelf; rename and add have a natural home | Needs a data model change and per-shelf layout code |
| C | Shelves as horizontal pages inside the stage with a pager | Reuses the stage | Does not show the whole collection at once; no zoom-out |

**Chosen:** B. **Rejected:** A (ignores shelves), C (does not meet "see all items").

### Breadboard of the chosen concept

- **Header:** title is the shelf in view (or "All shelves"). Three glass buttons: Shelves, Add bottle, Cabinet menu.
- **Shelf view:** unchanged, but only the shelf's bottles. The cap reads `02 / 05`; card numbers restart on each shelf.
- **All shelves view:** a scrolling column of shelf rows. Each row has the name (tap to open), `05 objects`, and a pencil. Under it the bottles stand on a plank, wrapping onto another plank when a row is full. The shelf you were on has an Olive ring and "here". The selected bottle is lifted and underlined. An empty shelf says "Nothing here yet" with an Add a bottle button. The bar has Add a shelf and Open shelf.
- **Rename panel:** a name field, Cancel, Save, and (for an empty shelf, when more than one exists) Remove this empty shelf with Undo.
- **Add a shelf panel:** a name field, Cancel, Add shelf. The new shelf appears at the end, empty, with a toast that points to the plus button.
- **Bottle menu:** a new Move to another shelf row; the bottle's shelf comes into view with Undo. The Add bottle panel has a Shelf field.
- **Zoom:** one number from 0 (shelf) to 1 (all shelves), driven by the fingers while pinching and tweened for buttons and keys. Release snaps to the nearer end with a hysteresis.
- **Liquid:** a path per bottle, redrawn each frame while visible.

### States

- **First run:** four seasonal shelves; the seven sample bottles sit on Autumn (five), Spring (one) and Summer (one). Winter is empty on purpose, to show the empty state.
- **Empty shelf:** shown in the overview; opening it from there opens Add a bottle with that shelf preselected. A pinch-out over an empty shelf stays in the overview and says so.
- **Old saves:** a version 1 save moves onto the Autumn shelf, where it was shown before.
- **Limits:** 12 shelves, 40 bottles, 28 characters in a name.
- **Fan:** the saved three-bottle rotation, across shelves; the header names the shelf of the selected bottle.
- **Undo:** delete, move and remove-shelf each offer it.
- **Reduce Motion:** layers swap with no scale; liquid flat and exact.

## 6. Platform behavior

- **Widths and orientation:** checked at 393 by 852, 375 by 667, 390 by 844, 430 by 932. The title truncates with an ellipsis and drops to 28 px at 380 or narrower so three header buttons fit. Landscape keeps the existing prompt.
- **Install mode:** the overview respects the bottom safe area through the existing toolbar rules.
- **Appearance:** light only, tokens only.
- **Accessibility:** each pencil is named "Rename <shelf>" and is 44 px; each miniature bottle is a button named with its house and fragrance, and "selected" when it is; the Shelves button reports pressed; the hidden layer is `visibility: hidden` and `aria-hidden`. Miniature bottles are 40 px wide, under 44, with a 6 px gap. Status is not by color alone: the current shelf says "here" and the selected bottle is lifted.
- **Input:** touch pinch (pointer events), ctrl and wheel for a trackpad, WebKit gesture events for Safari, buttons, `-`, `+` and Escape.
- **Haptics and motion:** no new haptic moment. Reduce Motion as above.

## 7. Technical approach

- **Where it lives:** `index.html`. New sections: shelves in the data model, the view (`VIEW`, `VPOS`, `syncShelf`), the overview and zoom, shelf panels, the liquid module `LQ`, and `liq()` and `sight()` in the bottle drawings.
- **Data and state:** key `arooma.v1`, now `{v:2, shelves:[{id,name}], bottles:[{..., shelf}]}`. A version 1 save is accepted and migrated on load. Nothing leaves the device.
- **Per-shelf view:** every layout function reads the bottle's place on the shelf in view. The selected bottle decides the shelf, so selecting any bottle changes the shelf.
- **Zoom:** `Z` drives CSS variables; the shelf layer and overview cross-scale and cross-fade from it.
- **Liquid model:** per bottle, a damped spring for tilt (about 1.65 Hz, low damping) driven by the card's acceleration, which is read from a tracker that mirrors the card's CSS transition, plus the card's lean so the surface stays level with the room; a second spring for a small bounce; two travelling ripples whose energy comes from motion and whose direction follows the card's velocity; a slow ambient ripple and sway. Headroom and depth limit tilt and amplitude, so a full bottle barely moves and a low one pools. Frame cost: about a dozen paths when a shelf is in view; the loop skips hidden bottles and runs at half rate when calm.
- **Do not touch:** one file, no network, no new color, cards opaque. All hold.
- **Dependencies:** none.
- **Performance and privacy:** the loop stops when the page is hidden and never starts under Reduce Motion.

## 8. Risks, rabbit holes and open questions

| Item | Why it matters | Proposed default | Who decides |
| --- | --- | --- | --- |
| Level windows on three vessels | Changes the look of three fictional houses' bottles | Keep (section 4, exception 1) | Owner |
| Rule wording for "always visible" | The card does not say it | Add the proposed line | Owner |
| Pinch on a real iPhone | Tested with synthetic touch, wheel and gesture events in a desktop engine only. Real iOS may deliver two-finger events differently, may still try to zoom the page, or may cancel pointer events | Check on a device before relying on it | Owner |
| Liquid tuning | The gains were set by eye in a desktop engine at 60 fps. Feel on a phone, and battery over a long session, are unmeasured | Tune on a device; the constants are at the top of `LQ` | Owner |
| Device tilt | Real phone tilt would make the liquid respond to the phone itself, but iOS asks permission for motion data | Not built | Owner |
| One bottle on one shelf | A bottle cannot be on two shelves, so "Autumn" and "Evenings" cannot overlap | Keep it simple | Owner |
| Fan across shelves | The rotation can span shelves, so the title changes as the fan turns | Keep; a per-shelf rotation is a later spec | Owner |
| Moving by menu, not drag | The overview has no drag between shelves | Keep; a drag would need a tap and keyboard path too | Owner |

## 9. Verification and prototype plan

### Acceptance criteria

- Given the shelf view, when the owner pinches in (touch, trackpad or Safari gesture) or taps Shelves, then every shelf appears and the title reads "All shelves".
- Given the overview, when the owner pinches out over a shelf, then that shelf opens with its last selected bottle, and snapping back leaves the original selection.
- Given a shelf, then a pencil beside its name opens a rename panel, a blank name is refused, and a saved name shows in the overview, the shelf title, the share image and storage.
- Given the overview, when the owner adds a shelf, then it appears empty at the end and survives a reload; Add a bottle on it preselects it.
- Given any bottle, then its liquid is drawn at the level its estimate gives, including the three opaque vessels through their windows.
- Given a swipe, then the liquid tilts one way then the other and settles to a gentle ripple; in Fan the leaning cards keep the liquid level with the room.
- Given Reduce Motion, then the liquid is flat, still and at the true level, and the overview appears without scaling.

### Checks

- `npm run docs:check` and `npm test`. The smoke test covers each criterion, using synthetic two-finger touch through the browser's debugging protocol, ctrl and wheel events, and gesture events, and runs at 393 by 852, 375 by 667 and with Reduce Motion.
- Owed on a physical iPhone: pinch with two real fingers anywhere on screen (and that the page itself does not zoom), scroll the overview while another pinch begins, the Add and Rename keyboards over the panels, liquid feel and frame rate on a few bottles at once, battery over ten minutes, Home Screen install.

### Prototype plan

The open question is feel, so the liquid constants and the pinch thresholds should be tried on a device. What must be real: two-finger touch and the frame rate. What can be faked: nothing in the data. Tester questions: Do you know how to see all your shelves? Is the liquid believable, and does it distract? How can we make it better?

## 10. Rollout, rollback and release

Ships with the web app on the next push to `main`. To revert, revert the commit; a version 2 save is read by older builds only for its bottles, which then all show on the one shelf. Release authority stays with the owner.

## 11. Decision record

| Date | Decision | By | Documents updated |
| --- | --- | --- | --- |
| 2026-10-29 | Add named shelves (four seasons by default), an all-shelves overview reached by pinch, rename pencils and add-shelf; make every liquid visible (level windows on three opaque vessels) and physical | Owner request, applied by Claude | `DECISIONS.md`, `brand/BRAND_BOARD.md`, `packs/shelf-change.md`, `README.md` |
