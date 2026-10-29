# Pack: device layout (iPhone and iPad, Safari and Home Screen)

> Part of the Arooma design brain. Start at [../README.md](../README.md). Tier 2 pack: a digest, not the source. The rules card applies on top.

**Use when:** you change layout, safe areas, widths, the install experience, the status bar, launch images or App Store screenshots. For look and feel use [apple-native-feel.md](apple-native-feel.md).

Evidence tags: `[Repo]` is what ships, `[Apple]` is fact, `[3P]` and `[Rec]` are leads. Facts marked "from Spread" were researched there on 2026-10-21 and not re-verified for Arooma.

## Facts to work from

**One layout rule for every device.** Decide layout from available width and aspect ratio, never device model. At 520 px wide or less the app fills the window; wider windows show a framed phone. Same functionality at every width. No horizontal page scroll. `[Repo]`

**Safe areas.** `viewport-fit=cover` is set, so `env(safe-area-inset-*)` is live. Apply insets per side: the toolbar uses the bottom inset, the header spacer and the Island chip use the top inset. Controls stay inside the safe area; background art may extend past it. No hardcoded screen sizes. `[Repo][Apple]`

**Home Screen install.** The app ships a web manifest (`display: standalone`), an apple touch icon and 11 launch images chosen by device size media queries. Safari offers no install prompt, so a one-line hint shows once on iOS Safari until dismissed. `[Repo]`

**Status bar.** `apple-mobile-web-app-status-bar-style` is `default` so status text stays dark on the oat ground. `black-translucent` would draw white status text over it. Not yet seen on a physical iPhone. `[Rec]`

**Orientation.** Portrait only. On a touch device in landscape with a short viewport a "Hold your iPhone upright" prompt covers the app. `[Repo]`

**Short phones.** At 700 px high or less the notes line and the install hint hide so the shelf keeps its room. Tested at 375 by 667. `[Repo]`

**What a web page cannot do on iPhone.** Live Activities, widgets and system haptics. The Island chip is drawn inside the page below the real island. Haptics use the Vibration API where it exists and a hidden `switch` checkbox on Safari 17.4 and later, near a tap only. `[Repo][3P]`

**Widths to test:** 375, 390 and 430 phone; 820 and 1024 show the framed device. Landscape prompt on a phone. Reduced motion.

**Toolchain for a native build (from Spread).** Xcode 26 or later with the iOS 26 SDK for uploads. `[Apple]`

**App Store screenshots (from Spread, PNG or JPEG, no alpha):** iPhone 1179 by 2556 or 1206 by 2622; iPad 2064 by 2752. `[Apple]`

## Checklist
- [ ] Layout switches on width and aspect ratio only.
- [ ] Per-side insets; `viewport-fit=cover` present.
- [ ] 375, 390, 430 checked plus a 667 high phone; no horizontal scroll.
- [ ] Install from Safari, launch from the Home Screen, launch image matches the closed doors.
- [ ] Offline reload works after the first visit.
- [ ] `npm test` passes in CI.
- [ ] Owed on a physical iPhone: status bar, launch image, haptics, share sheet, offline.

## Read deeper only if needed
- `../reference/spread/platforms/SPREAD_IPHONE_BUILD_GUIDE.md#3. Layout instructions`: iPhone layout checklist (Spread).
- `../reference/spread/platforms/SPREAD_IPHONE_BUILD_GUIDE.md#6. Accessibility and appearance`: dark palette ladder and contrast checks (Spread).
- `../reference/spread/platforms/SPREAD_IPHONE_BUILD_GUIDE.md#9. Test matrix and gates`: what is owed on device (Spread).
- `../reference/spread/platforms/SPREAD_IPAD_BUILD_GUIDE.md#3. Layout and multitasking instructions`: size classes and multitasking (Spread).
