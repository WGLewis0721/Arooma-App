# Changelog

## 2026-10-29: Polish pass

Spec and acceptance report: [docs/design/specs/2026-10-29-polish-pass.md](docs/design/specs/2026-10-29-polish-pass.md).

**Changed**
- First run asks: Start my collection (empty) or Explore the demo. The demo is labeled and stored apart.
- Storage schema 3 (`own` and `demo` collections, rotations, photos, impressions). v1 and v2 saves migrate on load and are written back.
- Every bottle can be deleted, including the last. Empty shelves have a proper empty state.
- Back up to a JSON file; restore with validation and an explicit merge or replace.
- Find across shelves (`/`). Pencil on the selected card for edit.
- Optional impressions on each wear; recent wears on the record; honest pick reasons.
- Owner photos per bottle, cropped to cover with zoom and position.
- Stack is today's shortlist. Fan presents a saved rotation of up to five.
- Wording: Estimated remaining, Authenticity notes, overlap in listed notes.
- Timer: in-app aid, check-ins at 15 min, 1 h, 3 h. The 30 s default is gone.
- Haptics: none on flips; added for a due check-in and a saved backup.
- Closing a panel resets page scroll left by a focused input.

**Decided**
- Clay is the single accent, used only for states. No new colors.
- Photos skip the liquid simulation; the estimate stays in text.
- Backup goes through the share sheet when available, otherwise a download. No network.
- Bottle cap raised from 40 to 150; photos are 640 px JPEG to stay inside `localStorage`.

**Deferred**
- Real Dynamic Island and widgets (native build).
- IndexedDB for photos at scale, night palette, device testing (checklist in the spec, untested).

**Tests**
- `tests/smoke.cjs` enters the demo through the new first run and adds checks for every acceptance ID it can exercise in Chromium: empty start, migration, delete-last, backup round-trip, merge, invalid files, search, edit, photos, impressions, rotations, Stack, timer and a 60-bottle shelf. The liquid swipe check takes the best of three swipes because swipe timing is unreliable on a loaded runner.
