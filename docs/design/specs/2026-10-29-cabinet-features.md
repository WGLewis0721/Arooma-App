# Spec: Add and delete bottles, wear history, evidence check and compare-before-buying

> Part of the Arooma design brain. Start at [../README.md](../README.md). Follow [../PLAN_SPEC_PROTOCOL.md](../PLAN_SPEC_PROTOCOL.md). Saved as `docs/design/specs/2026-10-29-cabinet-features.md`.

| | |
| --- | --- |
| Request | "Can you see what grok was doing? And take over? It was pushing those last 4 features", then "Add bottle, Authenticity check, DNA matcher, or full Wear tracking. If you don't see any trace or commit in the repo then add them", then "Oh and delete bottle" |
| Restated | The owner keeps a real collection in the iOS web app: adds and removes bottles, logs and edits wears, records what they checked about a bottle's authenticity, and compares a bottle they might buy with what they own |
| Surface | Shelf, card (front and ownership record), a bottom panel for each flow, the share image |
| Size | M (new data model and storage, six panels, no new look) |
| Author | Claude, 2026-10-29, for the owner |
| Status | In review. Built in `index.html`; the owner decides section 8 |
| Governing docs read | `RULES_CARD.md`; `PLAN_SPEC_PROTOCOL.md`; `packs/shelf-change.md`; `packs/device-layout.md`; `brand/BRAND_BOARD.md` sections 1, 3, 4 and 7; `DECISIONS.md` |

## 1. Problem

`[Assumption]` The owner buys a bottle and wants it on the shelf the same evening. They want to log that they wore it, fix the date when they forgot, and see how often they reach for it. Before the next purchase they want to ask whether it is close to something they already own. Today the iOS build has seven fixed bottles, a wear button that forgets on reload, and no way to add, change or remove anything. The earlier prototype had stubs for these, but they were not usable.

## 2. Evidence and context

- `[Repo]` What Grok left: no pending branch or commit. On `main` there is one commit that holds `variants/collection-demo.html`, an all-in-one prototype. Its authenticity check returns a random number. Its DNA matcher shows the same hard-coded "soft woods" text for any input. Neither is safe to port, because they imply certainty the rules forbid.
- `[Repo]` The iOS build kept bottles in a constant, wear in a memory-only map, and fixed the count at seven in the eyebrow, the door label, the share image and the Stack lean table.
- `[Repo]` Rules that bite: remaining volume is an estimate; never claim authenticity is verified or a scent match is certain; no network call; sample houses are fictional; haptics at three moments only; every drag has a tap and a keyboard path.
- Search was named in the earlier prototype's feature list, but the owner's list for this request did not include it. It is not built.

## 3. Goals, non-goals and budget

- **Goals:** add a bottle from a short form; delete one with Undo; log, back-date and remove wears; record an evidence checklist per bottle; compare candidate notes with the cabinet; keep it all across reloads on the device; keep every claim honest.
- **Non-goals:** search; photos of real bottles; barcode or batch-code scanning; any server lookup; accounts or sync; editing a bottle after adding it; notes-to-profile accuracy beyond a small built-in word list.
- **Appetite:** one session. No new color, face or decorative style, and one file.

## 4. Rules that apply and exceptions needed

| Rule (document and section) | How this request touches it |
| --- | --- |
| `RULES_CARD.md`, Look: no new colors, cards opaque, glass only on switcher, toolbar and header buttons | Panels reuse Oat, Paper, Hair and the share sheet's shape. The two new header buttons are glass like the old ones. Delete text uses Clay Deep, no red |
| `RULES_CARD.md`, Behavior: remaining volume is an estimate | The add form labels the slider "Remaining, estimate"; the card and record keep "about" and "(estimate)" |
| `RULES_CARD.md`, Behavior: never claim authenticity verified or a match certain | The checklist records what the owner observed and says it cannot verify. Compare says "overlap in listed notes" and says what it does not predict |
| `RULES_CARD.md`, Behavior: haptics at three moments | Wear uses the wear tick; add, delete, undo of a delete and saving evidence use the completed-action tick |
| `RULES_CARD.md`, Behavior: every drag has a tap and a keyboard path | No new drags. The remaining-volume range input works with arrow keys |
| `RULES_CARD.md`, Boundaries: no backend, account, analytics or network call without a spec; one file; fictional houses | Data stays in `localStorage` on the device. No request leaves the page. Houses the owner types are theirs; the app draws a neutral vessel, never a logo or label |
| `RULES_CARD.md`, Verify: 375, 390, 430, landscape prompt, reduced motion, no horizontal scroll | Smoke test covers 393 and 375 by 667. Panels use the existing reduced-motion rule |

**Exceptions needed (owner decides, do not assume):** None forbidden. Two items to confirm are in section 8: `localStorage` as the store, and whether an evidence checklist satisfies "never claim authenticity".

## 5. Options and the chosen concept

### Options considered

| Option | Idea | Pros | Cons |
| --- | --- | --- | --- |
| A | Port Grok's prototype features as they are | Fast, matches the old demo | Random authenticity number and a fixed "soft woods" answer break the claims rule |
| B | Rebuild each feature in the iOS build with honest wording, stored on the device | Meets the rules; works offline; same look | More code; storage is per browser |

**Chosen:** B. **Rejected:** A, because a random result presented as a check misleads the owner.

### Breadboard of the chosen concept

- **Header:** two glass buttons, Add (plus) and Cabinet menu (three dots). The old Share and Replay doors buttons moved into the menu.
- **Actions row:** Wear today, Test, and a round More button for the selected bottle.
- **Cabinet menu panel:** Compare notes before buying, Share shelf image, Replay the cabinet doors, Reset demo data.
- **Bottle menu panel:** Wear history, Check authenticity, Delete bottle.
- **Add panel:** House, Fragrance, Concentration, Size, Remaining (estimate), Notes, Acquired, Vessel (seven neutral drawings), a line for the record. Errors appear in text under the form.
- **Wear history panel:** summary line (count, last, first, average gap), a date field with Add wear, a row per wear with a remove button.
- **Authenticity panel:** five observations, each Matches, Differs or Not checked, with a live summary and Save to record. The record shows the saved result as "Evidence checked".
- **Compare panel:** notes field and four example chips, a recognized-notes line, the three closest bottles with overlap, a radar of eight note families, a one-paragraph reading.
- **Delete:** confirm panel, then a toast with Undo for six seconds. Undo restores the bottle at its old position.

### States

- **Empty:** not possible. The last bottle cannot be deleted; the menu says to add another first.
- **First run:** seven sample bottles, nothing stored until the first change.
- **Fewer than three bottles:** Fan is disabled and a Fan view falls back to Cover Flow.
- **More than eight:** the share image shows the first eight and says "Eight of N objects". The shelf holds at most 40.
- **Damaged storage:** malformed or wrong-shaped data falls back to the samples. Saved text is sanitized and always rendered as text.
- **Undo:** wear, wear removal and delete each offer one.
- **Refused:** a blank house or name, a size outside 5 to 500 ml, a future or duplicate wear date show a message in the panel.

## 6. Platform behavior

- **Widths and orientation:** checked at 393 by 852 and 375 by 667. Panels cap at 88 percent of the height and scroll inside themselves. Landscape keeps the existing prompt.
- **Install mode:** panels respect the bottom safe area. iOS keeps Safari and Home Screen storage separate, so a shelf built in Safari does not appear in the installed app.
- **Appearance:** light only, tokens only.
- **Accessibility:** each panel is a dialog with Escape to close and focus returned to the opener. Inputs are 16 px so iOS does not zoom. The evidence buttons use text states, not color. Controls are 40 to 44 px. The example chips in Compare are about 34 px and only shortcut typing.
- **Input:** touch, keyboard and pointer.
- **Haptics and motion:** only the three allowed moments. Panels slide like the share sheet and cross-fade under reduced motion.

## 7. Technical approach

- **Where it lives:** `index.html`. New sections: data model and storage, panels, add and delete, wear, evidence, compare.
- **Data and state:** key `arooma.v1` holds `{v:1, bottles:[{id, house, name, conc, ml, left, notes, vessel, acq, log[], auth, cool, note, sample}]}`. `log` is a list of local `YYYY-MM-DD` dates, newest first. `auth` is `{v:[five of 0|1|2], at}`. Drawing, scent profile, low stock and the fit line are derived on load. Nothing leaves the device.
- **Scent profile:** a built-in list of about 120 note words, each scored across eight families (Fresh, Green, Woody, Smoky, Earthy, Warm, Sweet, Musky). Overlap is the sum of the smaller values over the sum of the larger. It is a similarity of listed words, not of smell.
- **Daily Pick:** unchanged except it skips bottles already worn today, treats a never-worn bottle as the longest unworn, and copes with a shelf where every bottle is low.
- **Do not touch:** one file, no network, no new color or face, cards opaque. All hold.
- **Dependencies:** none.
- **Performance and privacy:** the shelf is limited to 40 cards. Stored text is length-limited and escaped on display.

## 8. Risks, rabbit holes and open questions

| Item | Why it matters | Proposed default | Who decides |
| --- | --- | --- | --- |
| `localStorage` as the store | Cleared with Safari data; separate between a Safari tab and the Home Screen app; not shared with a future widget | Keep for the web app. A native widget needs a shared store (see the widget spec) | Owner |
| Evidence checklist wording | It records observations, never a verdict, but the owner may want it removed or reworded | Keep, with "cannot verify" on the panel and "does not verify" in the result | Owner |
| Note word list is small | Unknown words are ignored, so a real description may score low | Show the recognized words so the gap is visible | Owner, later |
| Keyboard over the Add panel on iPhone | The panel lifts with the visual viewport; not tried on a device | Check on a device before relying on it | Owner |
| Date inputs on iPhone | The native picker and the future-date limit were tested in a desktop engine only | Check on a device | Owner |
| Search | Listed in the old prototype, not requested here | Not built | Owner |

## 9. Verification and prototype plan

### Acceptance criteria

- Given the sample shelf, when the owner adds a bottle with a house and name, then it appears last, is selected, and survives a reload.
- Given any bottle, when the owner deletes it, then it is gone, numbering closes up, and Undo restores it in place.
- Given a bottle, when the owner taps Wear today, then it reads "Worn today", the date is stored, and Undo reverts it.
- Given the history panel, when a past date is added, then the count and "Last worn" follow; a future or duplicate date is refused.
- Given the evidence panel, when all five read Matches, then the result says "Consistent on all 5 details" and that it does not verify authenticity.
- Given the compare panel, when notes are typed, then the three closest bottles show with overlap and the result never promises a match.
- Given damaged storage, when the page loads, then the sample shelf appears and nothing runs from stored text.
- Given one bottle, then it cannot be deleted and Fan is unavailable.

### Checks

- `npm run docs:check` and `npm test` (the smoke test covers every criterion above, plus 375 by 667 and no page errors).
- Owed on a physical iPhone: Home Screen install and storage, the keyboard over the Add panel, date pickers, the three haptics, the share sheet with eight bottles, one-handed reach of the new buttons.

### Prototype plan

Not needed. Feel is not the open question.

## 10. Rollout, rollback and release

Ships with the web app on the next push to `main`. To revert, revert the commit; stored data under `arooma.v1` is ignored by older builds. Release authority stays with the owner.

## 11. Decision record

| Date | Decision | By | Documents updated |
| --- | --- | --- | --- |
| 2026-10-29 | Build add, delete, wear history, evidence check and compare in the iOS build with honest wording; do not port the prototype's random result or fixed text; store on the device | Owner request, applied by Claude | `DECISIONS.md`, `packs/shelf-change.md`, `README.md` |
