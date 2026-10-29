# Pack: changing the shelf, cards and objects

> Part of the Arooma design brain. Start at [../README.md](../README.md). Tier 2 pack: a digest, not the source. The rules card applies on top.

**Use when:** you touch the shelf, a card, bottle art, Cover Flow, Stack or Fan, Daily Pick, low stock, the ownership record, the test timer, the Island chip or the share image. Visual authority is [../brand/BRAND_BOARD.md](../brand/BRAND_BOARD.md).

## Facts to work from

**Anatomy of a card (front).** Photo window with `N° 04` top left, the bottle standing on a warm table band, then a caption in three separate levels: house (caps, Olive Deep), fragrance name (display serif), concentration and size (UI, Soft Ink). Low stock adds a right-aligned block: "Running low" in Clay Deep with a 2 pt Clay hairline gauge. Back of the card is the ownership record; essential facts stay on the front. `[Repo]`

**Tokens.** `--oat` ground, `--paper` card, `--ink` text and primary buttons, `--soft` secondary text, `--hair` hairlines, `--olive` and `--clay` for graphics and large text only, `--olive-deep` and `--clay-deep` for small text. Values in [../tokens.json](../tokens.json). Contrast numbers are in the brand board. `[Repo]`

**One DOM, three layouts.** Every card is the same element in all layouts, so the selected bottle persists and transitions are continuous. `place` handles Cover Flow and Stack, `fanPlace` handles Fan, both return the same transform fields. Cover Flow: neighbors turn 54 degrees, recede and shade 10%. Stack: up to three cards peek above with a 2 degree lean. Fan: three cards pivot from below the shelf at plus and minus 14 degrees, the selected one lifts. Fan shows the saved rotation (`ROT_IDS`, read through `ROTI()`); a selected bottle outside it joins as a guest, and Fan is off with fewer than three bottles. Drag maps to position, release carries velocity. `[Repo]`

**Daily Pick.** Candidates exclude low-stock bottles and ones already worn today, and rank by days unworn (never worn counts as longest) plus 20 for cool-weather bottles. If none qualify it relaxes the filters rather than failing. Each tap moves to the next candidate, selects it, lifts it and tags it with an Olive outline and the "Today's pick" tab. The tab stays until the next pick. One reason line, never a score. `[Repo]`

**Test timer.** "Test" starts a 30 second session in the Island chip: Opening, Heart, Dry-down in 10 second phases. Compact is a ring and time; expanded adds fragrance, prompt, End and Log impression. It exists only during a session. It is a test aid, not a measure of longevity. `[Repo]`

**Share image.** A 1080 by 1350 canvas drawn in the page: header row, display title, bottles on one or two tiers of up to four (first eight shown) with numerals, footer that follows the count. No chrome. It goes to the iOS share sheet as a PNG file, or downloads where sharing files is unavailable. `[Repo]`

**Data and storage.** The shelf is saved on the device under `arooma.v1` once anything changes. Stored per bottle: `id`, `house`, `name`, `conc`, `ml`, `left` (0 to 1 estimate), `notes`, `vessel`, `acq`, `log` (dates, newest first), `auth` (five observations), `cool`, `note`, `sample`. Drawing, scent profile, low stock and the fit line are derived. Wear, history, evidence, add, delete and compare all go through this model; the shelf holds at most 40 and never fewer than one. Sample houses are fictional; a bottle the owner adds uses one of seven neutral drawings in `VESSELS`, never a logo or label. A new drawing needs a unique id prefix (`draw(prefix, left)`) and a liquid level from `left`. See [../specs/2026-10-29-cabinet-features.md](../specs/2026-10-29-cabinet-features.md). `[Repo]`

**Claims.** Remaining volume is an estimate and says so. The authenticity panel records five observations and says it cannot verify; its result reads "Consistent on" or "Differs on", never "authentic". Compare shows "overlap in listed notes" and what it does not predict. Do not write "verified authentic", "match" as a promise or "you will love it". `[Repo]`

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
