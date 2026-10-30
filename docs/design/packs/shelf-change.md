# Pack: changing the shelf, cards and objects

> Part of the Arooma design brain. Start at [../README.md](../README.md). Tier 2 pack: a digest, not the source. The rules card applies on top.

**Use when:** you touch the shelf, a card, bottle art, Cover Flow, Stack or Fan, Daily Pick, low stock, the ownership record, the test timer, the Island chip or the share image. Visual authority is [../brand/BRAND_BOARD.md](../brand/BRAND_BOARD.md).

## Facts to work from

**Shelves.** The cabinet has shelves (default Spring, Summer, Autumn and Winter, renamable, at most 12). One shelf is in view; the selected bottle decides which, so selection survives everything. Cover Flow, Stack, arrow keys, drag, Daily Pick, card numbers and the share image all work inside the shelf in view; Fan shows the saved rotation across shelves. Pinch in, the Shelves button or `-` zooms out to the overview; pinch out over a shelf, Open shelf or Escape returns. See [../specs/2026-10-29-shelves-and-liquid.md](../specs/2026-10-29-shelves-and-liquid.md). `[Repo]`

**Liquid.** `liq()` draws each liquid as a path that `LQ` redraws every frame (tilt spring, travelling ripples, ambient ripple); `sight()` adds a level window to opaque vessels. A new vessel must draw its liquid with `liq()` at the true level and, if opaque, a `sight()` window. `[Repo]`

**Anatomy of a card (front).** Photo window with `N° 04` top left, the bottle standing on a warm table band, then a caption in three separate levels: house (caps, Olive Deep), fragrance name (display serif), concentration and size (UI, Soft Ink). Low stock adds a right-aligned block: "Running low" in Clay Deep with a 2 pt Clay hairline gauge. Back of the card is the ownership record; essential facts stay on the front. `[Repo]`

**Tokens.** `--oat` ground, `--paper` card, `--ink` text and primary buttons, `--soft` secondary text, `--hair` hairlines, `--olive` and `--clay` for graphics and large text only, `--olive-deep` and `--clay-deep` for small text. Values in [../tokens.json](../tokens.json). Contrast numbers are in the brand board. `[Repo]`

**One DOM, three layouts.** Every card is the same element in all layouts, so the selected bottle persists and transitions are continuous. `place` handles Cover Flow and Stack, `fanPlace` handles Fan. Cover Flow browses: neighbors turn 54 degrees, recede and shade 10%. Stack chooses: up to three cards peek above with a 2 degree lean. Fan presents the owner's saved rotation (`ROT`, up to three, set from the bottle menu): cards pivot from below the shelf at plus and minus 14 degrees. A selected bottle outside the rotation visits in front and the cap says so; it never joins silently. Drag maps to position, release carries velocity. `[Repo]`

**Daily Pick.** Candidates exclude low-stock bottles and ones worn today, ranked by days unworn (never worn counts as longest) plus 20 for cool-weather bottles, relaxing the filters rather than failing. The tab and Olive outline stay until the next pick. The reason line only cites the log and the owner's own notes: "You haven't worn this in a while: 40 days. Last time you noted over 6 hours." Never a score. `[Repo]`

**Testing session.** "Test" starts an in-app timer shown in the Island chip, with check-ins at the opening, the heart (20 minutes) and the dry-down (2 hours). It runs on the wall clock and survives a reload, but only shows while Arooma is open; it is not a Live Activity. Log impression opens the impression for today's wear. `[Repo]`

**Share image.** A 1080 by 1350 canvas drawn in the page: header row, display title, bottles on one or two tiers of up to four (first eight shown) with numerals, footer that follows the count. No chrome. It goes to the iOS share sheet as a PNG file, or downloads where sharing files is unavailable. `[Repo]`

**Data and storage.** Schema v3. Your collection is `arooma.cabinet`, the demo is `arooma.demo`, the mode is `arooma.prefs`; they never mix. A v1 or v2 save in `arooma.v1` is migrated once and kept untouched. First run offers Start my collection (empty) or Explore demo. Per bottle: `id`, `shelf`, `house`, `name`, `conc`, `ml`, `left` (estimate), `notes`, `vessel`, `acq`, `log` (dates, newest first), `imp` (impression per wear date: opening, development, projection, longevity), `auth`, `cool`, `note`, `sample`, `img` (the owner's photo, shrunk, with position). Any bottle can be deleted; the cabinet holds 200. Added and moved bottles go to the end of their shelf. Backup is one JSON file (export, then replace or add, always reviewed first). A photo is drawn by `photoArt` on the same table, baseline and light as the drawings, never stretched, with a level window (`photoWin`) whose liquid is sampled from the photo and simulated like the rest. Full detail: [../specs/2026-10-29-polish-pass.md](../specs/2026-10-29-polish-pass.md). `[Repo]`

**Claims.** Remaining volume reads "Estimated remaining" or "(estimate)", never a true level. Authenticity notes are the owner's record and say they cannot verify; results read "Consistent on" or "Differs on". Compare shows overlap in the notes entered, not similarity or enjoyment. `[Repo]`

## Checklist
- [ ] Only tokens and existing patterns; no new color, font or decorative style.
- [ ] Cards stay opaque; glass only on switcher, toolbar and header buttons.
- [ ] Selection survives all three layouts and a Daily Pick in each.
- [ ] Low stock is a label, a gauge and a lower liquid line; nothing red.
- [ ] Every drag has a tap, and arrow keys work on the shelf.
- [ ] Haptics only at settle, wear and completed action.
- [ ] Share image has no app chrome and bottles read at 42 px wide.
- [ ] 375, 390 and 430 wide, short phone (667 high), landscape prompt, reduced motion.
- [ ] `npm run docs:check` and `npm test`. A real iPhone pass is owed for motion and haptics.

## Read deeper only if needed
- `brand/BRAND_BOARD.md#1. Color`: palette, contrast, night values.
- `brand/BRAND_BOARD.md#3. Material and lighting`: bottle and card rules.
- `brand/BRAND_BOARD.md#4. Motion`: layout motion, haptics, Island, widgets.
- `brand/BRAND_BOARD.md#6. Shareable shelf image`: editorial image rules.
- `brand/BRAND_BOARD.md#7. Low stock and daily pick`: both treatments in full.
