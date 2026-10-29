# Pack: making the UI feel native on Apple platforms

> Part of the Arooma design brain. Start at [../README.md](../README.md). Tier 2 pack: a digest, not the source. The rules card applies on top.

**Use when:** you touch materials, translucency, color in controls, sheets, corners, motion or accessibility settings, or review a screen for "does this look like an Apple app". For per-device layout use [device-layout.md](device-layout.md). For token values use [../tokens.json](../tokens.json).

## Facts to work from

**Principles.** The job is keeping a collection like a cabinet and choosing what to wear. Objects first: bottles are the richest thing on screen, the interface is paper and light. Hierarchy comes from size, weight and spacing, not borders and fills. One quiet palette, system type, hairlines, generous space. `[Repo][Apple]`

**Two layers.** Controls and navigation float above content. Glass belongs to the controls layer only; the content layer (cards, bottles, sheets) uses opaque surfaces. Use glass sparingly on custom controls. `[Apple]`

**What ships today.** The `glass` class (blur 18 px, saturate 1.6, a translucent Paper fill and a white hairline) is used on the layout switcher, the Daily Pick button, the header buttons and nothing else. Cards and the share sheet are opaque. `[Repo]`

**Apple rules carried over from Spread (read there on 2026-10-28, not re-read for Arooma):**
- Text on any material uses primary or secondary ink, never the quietest level.
- A bright backdrop gets a dim layer of about 35% behind readable UI.
- Do not give bars and the toolbar opaque custom fills or borders.
- Be judicious with color in controls: one accent with light, dark and increased-contrast variants.
- Sheets: inset at lower detents, flush and more opaque at full height, a Grabber, a slider role with keyboard control.
- Concentric corners: nested radius is container radius minus padding. Do not mix unrelated radii.
- Content scrolling under a bar needs a fade or blur edge so controls stay legible.
- Accessibility: Reduce Transparency means opaque surfaces; Increase Contrast means stronger separators and ink; Reduce Motion means no movement. `[Apple]`

**Web ceiling.** `backdrop-filter` with a tinted, semi-opaque surface approximates a material. It is not system Liquid Glass. A web page cannot make a Live Activity, a widget, or system haptics; the Island chip and the haptic tick are imitations. Whether Safari applies `prefers-reduced-transparency` and `prefers-contrast` is unverified; test on a device. `[Rec]`

**What reads as amateur:** heavy outlines and hard offset shadows; a display typeface where system type belongs; opaque saturated fills where a material and one tint belong; decorating every element; fake paper distress. A wallpaper-driven reskin that did this was rejected in the Spread project on 2026-10-28. `[Repo: Spread]`

## Checklist
- [ ] Swap test: change a bottle and layout geometry is identical.
- [ ] Squint test: blur the screenshot; house, name and the selected bottle still read.
- [ ] Reference test: compare with iOS Wallet, Photos and Apple Music in the same state.
- [ ] Contrast 4.5:1 body, 3:1 large text and icons (the brand board lists the pairs).
- [ ] Reduce Motion, Reduce Transparency, Increase Contrast, text zoom at 200%.
- [ ] VoiceOver on cards, sheets and the Island chip.
- [ ] No new color, font or decorative style outside an approved exception.
- [ ] A real iPhone pass for anything that moves or blurs.

## Read deeper only if needed
- `platforms/APPLE_DESIGN_PRINCIPLES.md#2. What Apple says`: the full table with sources.
- `platforms/APPLE_DESIGN_PRINCIPLES.md#3. What a web layer can and cannot do`: web limits.
- `platforms/APPLE_DESIGN_PRINCIPLES.md#5. What makes an Apple app read as amateur`: the failure list.
- `brand/BRAND_BOARD.md#3. Material and lighting`: what Arooma adopted.
