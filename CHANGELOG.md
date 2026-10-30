# Changelog

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
