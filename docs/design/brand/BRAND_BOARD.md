# Arooma Brand Board: Warm Archive

> Part of the Arooma design brain. Start at [../README.md](../README.md) for the map and the router. Highest authority for visual and motion decisions.

> Summary: palette and contrast (1), type (2), bottle, liquid and card materials (3), layout motion, all-shelves zoom, liquid physics, haptics and the Island (4), App Store icon (5), share image (6), low stock and daily pick (7).

**Idea (V2):** a private luxury fragrance archive where the selected collectible card is the hero. Not a storefront and not a noisy card game. The old light-paper cabinet survives as the **owner's data and legacy vessel-art system**, but its front-end appearance and door launch are superseded by V2.

## 2026-10-31 owner-approved original calligraphic signature (supersedes generic font entry)

The brand entry wordmark is now a fixed, original **Arooma** handwritten signature, not runtime text in Snell Roundhand or Apple Chancery. Its SVG, transparent PNG, and both Higgsfield-generated light/dark pen-writing videos are in [the canonical asset handoff](../../../assets/brand/AROOMA_SIGNATURE.md). Always integrate those exact assets and preserve their letterforms; do not substitute a font or redraw the logo. The native intro no longer writes the name: the full master signature is legible from the first frame with a restrained, seamless metallic highlight (static with Reduce Motion), and navigation never waits for it.

## V2 implemented appearance and interaction override (2026-10-30)

Implementation and acceptance: [V2 spec](../specs/2026-10-30-v2-collectible-gallery-implementation.md). This **overrides the V1 color, no-real-house-demo, card material, serif restriction and door-animation paragraphs below**, while preserving data model, physics, movements, layout semantics and local backup requirements.

- **Shell palettes, in 60:30:10 proportions** (dominant / secondary / metal accent): Obsidian Gold `#161B24 / #312B33 / #B88B47`; Ivory Oud `#F3EBDD / #D8C4AA / #9F6A36`; Violet Ink `#1B1A28 / #5D5266 / #C9B6D9`; Emerald Resin `#18211F / #4B5A55 / #D1B68B`. Pale themes adjust to bone `#F4EEE4`, beige `#DCCDBA`, cream `#F8F2E8`; dark is navy/plum mixed with near-black, never flat `#000`. Surfaces, microtype and controls obey accessible contrast.
- **Fonts:** SF Pro/system for controls; curated serif themes optically akin to Iowan Old Style, Didot/Bodoni, EB Garamond, Palatino/Fraunces. Runtime uses installed fallback faces with no remote font dependence. Calligraphy (Snell Roundhand/Apple Chancery-style) appears **only** in the fountain-pen Arooma entry wordmark.
- **Entry:** the old hinged cabinet doors are disabled. The calligraphic wordmark draws in with a restrained underline; entry includes four theme swatches, appearance, Demo and My Collection. Returning users land directly in their last collection with no mandatory intro, and can replay the lettering from the menu.
- **Collection:** Keep one selected object across finger-driven Cover Flow, Stack, Fan; haptics only at original allowed moments; honor Reduce Motion and keyboard input. Three approved photographic card pairs use their original foil and fragrance maps; the fourth, Prodigy, remains archival V2 art. The 59:86 card bezel fits each source without stretching. Standard owner bottles keep original art/photo handling.
- **Utility is one tap away:** selected card flip, Wear Today, Test, Search/All Shelves, Add bottle, and demo/own collection switch. Details opens personal wear/history/edit records without replacing a fragrance's scent-map reverse.
- **Trademark/media boundary:** these are Arooma-independent visual art concepts, not sponsored; publication of any actual manufacturer photos follows [third-party content policy](THIRD_PARTY_CONTENT_POLICY.md). Do not confuse name/notes as permission to scrape photography.

### Legacy V1 language (retained for data/animation references)

The paragraphs that follow describe the previous Warm Archive look. Where they conflict with the V2 override, V2 wins for rendered shell, thematic typography, first-run animation, and collectible-card faces.

## 1. Color

| Role | Name | Hex |
|---|---|---|
| Primary | Ink | `#25231F` |
| Secondary | Muted Olive | `#73765F` |
| Accent | Clay | `#A4623F` |
| Background | Oat | `#F2EDE4` |
| Card surface | Paper | `#FBF8F1` |

**Supporting:** Olive Deep `#575A44` (small labels, pick tab), Clay Deep `#8F4E2E` (small low-stock text), Soft Ink `#6B6862` (secondary text), Hairline `rgba(37,35,31,.12)`, Shelf `#E9E2D4` to `#E4DBC9`, Door `#DAD1BF`.

**Contrast (computed):** Ink on Oat 13.5:1. Olive on Oat 4.0:1, so graphics and large text only; small text uses Olive Deep (6.7:1 on Paper). Clay on Paper 4.5:1; small text uses Clay Deep (6.0:1).

**Night is the same cabinet under lower light:** ground `#1C1B18`, card `#26241F`, text `#EDE7DB`, olive `#A9AC8F`, clay `#D79470`. No black-and-gold variant.

**Ratio:** Oat, Paper and Ink carry about 90% of any screen. Olive and Clay together stay under 5%.

## 2. Typography

- **Display:** New York (Apple's system serif, `ui-serif`), Regular or Medium, tracking -0.01em. Cross-platform fallback: Newsreader Display. Used for screen titles, fragrance names, the record title, and italic note lines.
- **UI:** SF Pro. Small caps labels at 8.5 to 10.5 pt with +0.14 to +0.17em tracking, tabular numerals for dates and counts.

Every card has three separate levels, never merged: house (caps, Olive Deep), fragrance name (Display 21), concentration and size (UI 10, Soft Ink). Ownership metadata stays in SF Pro caps. No third face.

## 3. Material and lighting

**Bottles**
- Neutral studio light: one large soft key from the left, about 35° above, neutral white balance, no per-house color grade, so houses never look like one brand.
- Every object stands on the same warm paper table with a contact shadow. No floating cutouts.
- Four readable materials: glass (clear edge, vertical highlight at left), liquid (darker than glass, bright meniscus), label paper (flat, evenly lit), cap (hard highlight for metal, matte speckle for stone).
- Liquid level is drawn from the owner's estimate, so a low bottle looks low. The liquid is always visible: a vessel that is opaque (near-black glass, white ceramic, terracotta) carries a narrow level window with the same liquid inside, so the fill reads on every bottle, on the card and in the all-shelves view.
- **Owner photos:** a person may use a photo of their own bottle, shown one of two ways, both never stretched, both with the soft key light from the left laid over them. *Stand on the table* (for a cut-out with a clear background) uses the frame of the drawings: same table, contact shadow and baseline, scale and position set by the owner. *Fill the picture* (for a photo with a background) crops it to the picture area like a product photo, with zoom and position set by the owner. Arooma never adds a logo or label itself. Either way the photo carries the same level window as the opaque drawings, slid onto the glass by the owner, holding liquid in the colour sampled from the photo, with the same simulated surface. A full bottle keeps a little air at the top so its surface can move.
- Stress test shelf: transparent glass, near-black bottle, amber liquid, opaque white vessel, metal cap, irregular silhouette. The demo shelf is exactly this.

**Cards**
- Opaque Paper, 10 pt radius, 1 pt hairline, lateral light gradient (white at left to 3% ink at right). No blur, no transparency.
- One long soft contact shadow, never a halo.
- Back of card is an ownership record (acquired, size, first and last worn, wears, remaining estimate, one personal line). Essential facts stay on the front, so the flip is never the only route.

**Glass:** native Liquid Glass on the layout switcher, toolbar and header buttons only. Cards, bottles and sheets stay opaque.

## 4. Motion

One rule: the selected bottle persists across layouts. Layouts rearrange the same objects; nothing is rebuilt. Ease `cubic-bezier(.22,1,.36,1)`, 0.85 s for layout moves, 0.9 s for flips. Reduce Motion means cross-fades only.

| Layout | Job | Behavior |
|---|---|---|
| Cover Flow | Browse everything | Center bottle frontal and 3% larger; neighbors turn 54°, recede, shade 10%. Drag maps directly to position; release carries velocity, then settles. |
| Stack | Choose today's bottle | The shortlist: the five bottles most due to be worn on the shelf in view (never low, never already worn today), plus the selected one. Selected card on top, up to three behind peeking above with ±2° lean. Swipe throws the top card left as it fades. |
| Fan | Present a saved rotation: a named set of up to 5 bottles, up to 12 sets | Cards pivot from below the shelf (±14° for three, ±11° for more). Selected card lifts forward. Non-members drop back into the cabinet; a selected bottle outside the rotation visits in front, labelled "with a guest". The caption above the cards is the rotation's name and opens the list of rotations. With no rotation, Fan opens the maker. |

**All shelves:** pinch in to zoom out to every shelf, pinch out over a shelf to open it. The same gesture has a tap path (the Shelves button, Open shelf), a trackpad path (ctrl and wheel), a Safari gesture path and keys (- and Escape). The shelf in view fades and shrinks while the overview grows in, driven by the fingers, then snaps. Each shelf is a Paper-light row of miniature bottles on a plank, with its name in the display serif and a pencil that opens rename. Shelves start as the four seasons. The shelf you were on carries an Olive ring and "here". The selected bottle is lifted and underlined in Olive, so it survives the zoom. Reduce Motion swaps the layers with no scaling.

**Liquid:** every liquid is a simulated surface, flat and exact at rest. It tilts against the card's acceleration with a damped spring (it overshoots and settles, so it has momentum), stays level with the room while a card leans in Fan and Stack, and carries two ripples that travel the way the card is moving. A slow ripple keeps every visible bottle alive. A full bottle barely moves and a low one pools. Landing a selection and wearing a bottle each give it a small kick. Reduce Motion draws it flat at the true level.

**Haptics, three only:** selection settle (after the card stops, never during drag), wear confirmation, completed action (a test check-in is due, impression saved, bottle added or edited, backup exported or restored). A card flip gets no haptic.

**First open:** two doors swing 1.7 s, the interior lamp fades up, bottles rise in an 80 ms stagger from the selected one.

**Island chip:** an in-app timer shaped like the Island, shown only during a testing session. Check-ins at 15 minutes (the opening), 1 hour (the heart) and 3 hours (the dry-down); it runs on the wall clock while Arooma is open and is not a system Live Activity. Compact: progress ring and time to the next check-in. Expanded: fragrance, phase prompt, End. A due check-in opens the chip and waits: Log impression opens the matching field and saving moves on; tapping the open chip skips it. Never a permanent "today's fragrance" badge, and the timer is a test aid, not a longevity measure.

**Widgets:** one bottle, short name, "Today's pick", one Wear action. Never a mini shelf.

## 5. App Store icon: "The Gap"

- Two oat door panels part to a 240 px opening. In it: a field of warm light, a shelf line, and one neutral bottle silhouette (cap, neck, shoulders) in Ink with a soft cast shadow. No text, no sparkle, no baked-in bevel or glass.
- 1024 grid: doors 392 px each, opening from x 392 to 632. Silhouette from y 226 to 764 (about 52% of the canvas), body 150 px wide. Left door `#F4EFE6` to `#E3DAC7`, right door `#E9E1D0` to `#D5CAB4`, opening `#FDFAF3` to `#E2D7C0`, two Olive `#73765F` pulls at the opening edges.
- All content sits inside the central 80% circle, so the same art works as the Home Screen and maskable icon. Source file: `assets/icons/icon.svg`.
- Build as three layers (background, doors, bottle) and let the system apply glass and specular.
- Dark: ground `#1C1B18`, doors `#26241F` and `#2F2C26`, bottle `#EDE7DB`. Tinted: opening brightest, doors mid, bottle darkest.
- Avoid: spray mist, gold, monograms, any real house's bottle.

## 6. Shareable shelf image

Editorial, no chrome, 4:5 portrait. Paper ground with the lateral light gradient. Small caps header row (Arooma left, year right; "Demo collection" in the demo), one display-serif title that is the shelf's name, bottles of that shelf on one or two tiers of up to four (the first eight) at one scale and one baseline, hairline shelf rule with soft shadow, two-digit numerals beneath, one footer line and count. A Fan shares its active rotation as one row of up to 5, titled with the rotation's name, in the same style.

No buttons, tabs, status bar, glass, prices, ratings or watermark. Silhouettes must stay readable at 42 px wide. Caption is the owner's, never retail copy. No fake paper distress.

## 7. Low stock and daily pick

**Low stock (quiet)**
- The liquid level in the bottle drops to the estimate.
- "Running low" in Clay Deep, 9.5 pt semibold, with a 2 pt Clay hairline gauge, right-aligned in the caption.
- Detail line always says estimate: "Running low, about 7 ml (estimate)".
- Never red, never a corner badge, never pulsing or dimmed. The card stays opaque and full size.

**Daily pick (ceremonial but small)**
- The card comes to center, lifts 2.5%, grows 2%.
- 1.5 pt Olive outline plus an Olive Deep paper tab, "TODAY'S PICK", attached to the top edge like a file label.
- One reason line in Olive Deep: "Unworn for 33 days. Suits cooler air." Wear today stays within thumb reach.
- The tab stays on the shelf until the next pick. Haptic only when the card settles. Not in the Island.
