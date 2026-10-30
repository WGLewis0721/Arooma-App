# Changelog

## 2026-10-30: Features ported from the parallel build

Ported, at the owner's direction, from the polish build that was on `main` briefly as `648a506`. **Not run in a browser and the smoke test was not updated**, so `npm test` is expected to fail until it is.

**Added**
- Rotations: named sets of up to five bottles, up to twelve. Fan shows the active one; its caption names it and opens the list. Fan with none opens the maker.
- Stack is today's shortlist: the five bottles most due to be worn, plus the selected one.
- The selected bottle, layout and rotation are remembered for each collection.
- A pencil on the selected card, and the `e` key, edit the bottle. The edit form can delete it.
- Photos can fill the picture (crop, zoom, position) or stand on the table (cut-out). Both keep the moving level window.
- A Demo tag on the plank, and "Demo collection" on a shared demo image.
- The Cabinet menu opens with where your data lives and the last backup date.
- Test check-ins at 15 min, 1 h and 3 h wait for you, open the matching field, and move on when saved. A haptic marks a due check-in; card flips no longer tick. `?clock=60` runs it faster.
- An impression note, and today's impression on the button under the card.
- An empty shelf stays in view with Add a bottle and See all shelves, and deleting a shelf's last bottle leaves you there.
- Backup files and saves from that build import correctly.

**Fixed**
- On iPhone, typing in a panel could leave the page scrolled out of place after it closed.

**Not ported**
- Its full-screen welcome (the card on the open cabinet does the same job), its find panel (search lives in All shelves), and photos that draw no liquid.

## 2026-10-29: Polish pass

Spec and acceptance report: [docs/design/specs/2026-10-29-polish-pass.md](docs/design/specs/2026-10-29-polish-pass.md).

**Changed**
- First run asks: Start my collection (empty) or Explore demo. The demo is labelled and stored apart (`arooma.cabinet`, `arooma.demo`, `arooma.prefs`).
- Storage schema 3. v1 and v2 saves, and saves from the short-lived parallel build (648a506), migrate once; `arooma.v1` is never modified.
- Every bottle can be deleted, including the last. The empty cabinet offers Add a bottle and Restore a backup.
- Backup to one JSON file; restore shows what the file holds, then replace (confirmed) or add.
- Search in All shelves (`/`), Edit details in the bottle menu and on the record, added and moved bottles go to the end of their shelf.
- Optional impressions on each wear, recent wears on the record, Daily Pick reasons from your own log.
- Owner photos on the shared table, aspect ratio kept, with a level window whose liquid is coloured from the photo and moves like every other bottle.
- Fan presents a saved rotation of three. Testing session check-ins at 20 minutes and 2 hours; the 30 s default is gone.
- Persistent-storage request, storage usage in Backup, a weekly-at-most backup reminder at five bottles.
- Wording: Estimated remaining, Authenticity notes, overlap in listed notes.

**Superseded**
- The parallel polish pass (648a506) was replaced by this one at the owner's direction. Its commit stays in history.
