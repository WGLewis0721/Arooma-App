# Arooma Brand Board: Warm Archive

> Part of the Arooma design brain. Start at [../README.md](../README.md) for the map and the router. Highest authority for visual and motion decisions.

> Summary: palette and contrast (1), type (2), bottle, liquid and card materials (3), layout motion, all-shelves zoom, liquid physics, haptics and the Island (4), App Store icon (5), share image (6), low stock and daily pick (7).

**Idea:** a personal cabinet of objects. Not a storefront, not an inventory dashboard. Bottles are the richest thing on screen; everything around them is paper, light and restraint.

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
| Stack | Choose from a shortlist | Selected card on top, up to three behind peeking above with ±2° lean. Swipe throws the top card left as it fades. |
| Fan | Compare a saved rotation of 3 | Cards pivot from below the shelf (±14°). Selected card lifts forward. Non-members drop back into the cabinet. |

**All shelves:** pinch in to zoom out to every shelf, pinch out over a shelf to open it. The same gesture has a tap path (the Shelves button, Open shelf), a trackpad path (ctrl and wheel), a Safari gesture path and keys (- and Escape). The shelf in view fades and shrinks while the overview grows in, driven by the fingers, then snaps. Each shelf is a Paper-light row of miniature bottles on a plank, with its name in the display serif and a pencil that opens rename. Shelves start as the four seasons. The shelf you were on carries an Olive ring and "here". The selected bottle is lifted and underlined in Olive, so it survives the zoom. Reduce Motion swaps the layers with no scaling.

**Liquid:** every liquid is a simulated surface, flat and exact at rest. It tilts against the card's acceleration with a damped spring (it overshoots and settles, so it has momentum), stays level with the room while a card leans in Fan and Stack, and carries two ripples that travel the way the card is moving. A slow ripple keeps every visible bottle alive. A full bottle barely moves and a low one pools. Landing a selection and wearing a bottle each give it a small kick. Reduce Motion draws it flat at the true level.

**Haptics, three only:** selection settle (after the card stops, never during drag), wear confirmation, completed action (test finished, impression saved).

**First open:** two doors swing 1.7 s, the interior lamp fades up, bottles rise in an 80 ms stagger from the selected one.

**Dynamic Island:** only during a timed testing session. Compact: progress ring and time left. Expanded: fragrance, phase prompt (Opening, Heart, Dry-down), End, Log impression. Never a permanent "today's fragrance" badge, and the timer is a test aid, not a longevity measure.

**Widgets:** one bottle, short name, "Today's pick", one Wear action. Never a mini shelf.

## 5. App Store icon: "The Gap"

- Two oat door panels part to a 240 px opening. In it: a field of warm light, a shelf line, and one neutral bottle silhouette (cap, neck, shoulders) in Ink with a soft cast shadow. No text, no sparkle, no baked-in bevel or glass.
- 1024 grid: doors 392 px each, opening from x 392 to 632. Silhouette from y 226 to 764 (about 52% of the canvas), body 150 px wide. Left door `#F4EFE6` to `#E3DAC7`, right door `#E9E1D0` to `#D5CAB4`, opening `#FDFAF3` to `#E2D7C0`, two Olive `#73765F` pulls at the opening edges.
- All content sits inside the central 80% circle, so the same art works as the Home Screen and maskable icon. Source file: `assets/icons/icon.svg`.
- Build as three layers (background, doors, bottle) and let the system apply glass and specular.
- Dark: ground `#1C1B18`, doors `#26241F` and `#2F2C26`, bottle `#EDE7DB`. Tinted: opening brightest, doors mid, bottle darkest.
- Avoid: spray mist, gold, monograms, any real house's bottle.

## 6. Shareable shelf image

Editorial, no chrome, 4:5 portrait. Paper ground with the lateral light gradient. Small caps header row (Arooma left, year right), one display-serif title that is the shelf's name, bottles of that shelf on one or two tiers of up to four (the first eight) at one scale and one baseline, hairline shelf rule with soft shadow, two-digit numerals beneath, one footer line and count. A saved Fan renders as one row of 3 to 5 in the same style.

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
