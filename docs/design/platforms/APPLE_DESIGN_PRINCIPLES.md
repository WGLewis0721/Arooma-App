# Apple design principles for Arooma

> Part of the Arooma design brain. Start at [../README.md](../README.md) for the map, the rules and what to read for which task.

> Summary: first principles, what Apple's materials, color and sheet guidance means for Arooma (section 2), what a web layer cannot do (3), what reads as amateur (5) and a UI change checklist (6). For routine work read [../packs/apple-native-feel.md](../packs/apple-native-feel.md) first.

Forked from the Spread document of the same name (written 2026-10-28) and adapted for Arooma on 2026-10-29. This file turns Apple's guidance on materials, color and sheets into decisions for Arooma, and records the first principles behind them.

Evidence tags: **[Apple]** read on a developer.apple.com page. **[3P]** third party, including mirrors of Apple pages. **[Repo]** from Arooma docs or code. **[Rec]** a recommendation, not a fact. **The Apple facts below were read for Spread on 2026-10-28 and carried over. Re-read the Apple pages (Materials, Adopting Liquid Glass, Sheets, Color, Live Activities, Widgets) before relying on this file for a new decision.**

---

## 1. First principles

1. **The job.** Arooma keeps a fragrance collection like a cabinet and helps choose what to wear: Shelf, Bottle, Ownership record [Repo]. The interface exists to make the objects present and the choice calm.
2. **Objects first.** Bottles are the richest thing on screen. Cards, type and chrome stay quiet so the objects carry the color [Repo: brand board].
3. **Two layers.** Apple separates a content layer from a functional layer (controls and navigation). Material is how the layers separate [Apple: Materials]. In Arooma the content layer is opaque Paper; only controls are glass.
4. **One selection, three layouts.** Cover Flow, Stack and Fan rearrange the same objects and keep the selected one selected. Apple recommends preserving existing elements as a layout changes rather than removing and reintroducing them [Apple: Live Activities].
5. **Houses stay themselves.** Different fragrances must not look like one brand. Light and table are shared; color and silhouette belong to each bottle [Repo].
6. **Restraint is the signature.** A quiet palette, system type, hairlines, generous spacing. Hierarchy from size, weight and spacing, not from borders and fills [Repo].

---

## 2. What Apple says, and what it means for Arooma

| Topic | Apple guidance | Consequence for Arooma |
| --- | --- | --- |
| Layers | Liquid Glass forms a functional layer for controls and navigation that floats above content. "Don't use Liquid Glass in the content layer." Use standard materials for the content layer [Apple: Materials] | Cards, bottles and sheets are content: no glass. Only the layout switcher, toolbar and header buttons read as glass |
| Restraint | Apply Liquid Glass to custom controls sparingly. Overuse "distracts from content" [Apple: Materials, Adopting Liquid Glass] | Keep the glass set small. Do not add glass to new controls without a spec |
| Vibrancy | Thicker materials give text more contrast; thinner ones keep context. Avoid the quietest label level on thin materials [Apple: Materials] | Text on glass uses Ink or Soft Ink |
| Dimming | Over bright content, clear glass benefits from a dark dimming layer of about 35% [Apple: Materials] | The share sheet scrim and any future photo backdrop get a dim layer |
| Custom backgrounds | "Reduce your use of custom backgrounds in controls and navigation elements." Let the system decide [Apple: Adopting Liquid Glass] | Do not give the toolbar opaque custom fills or borders |
| Color in controls | "Be judicious with your use of color in controls and navigation" [Apple: Adopting Liquid Glass] | Controls are Ink and Soft Ink. Olive appears only on the Daily Pick icon and the pick marker |
| Sheets | Increased corner radius. Half sheets inset from the display edge. A full-height sheet becomes more opaque. Remove custom sheet backgrounds [Apple: Adopting Liquid Glass] | The share sheet is opaque Oat with a Grabber; it never uses glass |
| Detents and grabber | Include a grabber on any resizable sheet; tap it to cycle detents; it works with VoiceOver [3P mirror of Apple HIG: Sheets] | Add a real Grabber role and keyboard path if the share sheet gains detents |
| Corners | Use rounded shapes concentric to their container [Apple: Adopting Liquid Glass] | Nested radius is container radius minus padding. Do not mix unrelated radii |
| Accessibility | Test with Reduce Transparency, Increase Contrast and Reduce Motion [Apple: Adopting Liquid Glass] | Reduce Transparency means opaque controls. Increase Contrast means stronger hairlines and ink. Reduce Motion means cross-fades only |
| Scroll edges | Content under controls needs a scroll edge treatment so controls stay legible [Apple: Adopting Liquid Glass] | If a list ever scrolls under the toolbar, fade or blur its edge |
| Live Activities | Timer is the example of a task with a defined beginning and end. Persistent decoration is not a use. Keep elements in place as the presentation expands [Apple: Live Activities] | The Island chip exists only during a test session, and its elements keep their position as it expands |
| Widgets | A simple, focused purpose with timely content and useful actions. Support tinted and clear appearances [Apple: Widgets] | Today's pick plus one action. Never a miniature shelf |

---

## 3. What a web layer can and cannot do

Arooma draws all of its UI in the browser. Today it runs in Safari or as a Home Screen web app [Repo].

- CSS `backdrop-filter` with a tinted, semi-opaque surface approximates a standard material. It is not Liquid Glass and gets no system vibrancy [Rec].
- A web page cannot create a Live Activity, a widget or a real Dynamic Island presentation. The chip in the page is an imitation. These need a native app (WidgetKit, ActivityKit) [Rec].
- System haptics are not available through the Vibration API on iPhone. Safari 17.4 and later answers a toggled `switch` checkbox with a tick, which the app uses near taps. Unverified on a device [3P][Rec].
- Whether Safari applies `prefers-reduced-transparency` and `prefers-contrast` is **unverified**. Test on a device and offer an in-app switch if it does not [Rec].
- True system glass, native sheets and native bars need native views. That is a separate architecture decision in [../DECISIONS.md](../DECISIONS.md).

The honest ceiling for the web layer is "feels native to the platform", not "is the system material".

---

## 4. How this fits Arooma's existing rules

- **Unchanged:** no new colors, fonts or decorative styles. Apple's guidance is a way to use the existing tokens well: hierarchy from type and spacing, restraint, hairlines [Repo: [../brand/BRAND_BOARD.md](../brand/BRAND_BOARD.md)].
- **Glass is already in the app on controls only.** The `glass` class ships on the layout switcher, the Daily Pick button and the header buttons. Blur on cards or sheets stays off; Apple places those in the content layer.
- **Dark mode:** the brand board specifies a night palette as the same cabinet under lower light. It is not built yet; build it as tokens, not ad hoc values (see [../DECISIONS.md](../DECISIONS.md)).
- **Dynamic Type** is not adopted. If Arooma adopts system text sizes, define the type scale once and test at 200%.

---

## 5. What makes an Apple app read as amateur

Observed in a Spread experiment on 2026-10-28 that reskinned a screen to imitate a wallpaper and was rejected as looking like a student project [Repo: Spread]. Avoid:

- Heavy outlines (about 3 px) and hard offset shadows. Apple uses hairlines and soft, low-opacity depth.
- A display typeface and custom glyphs where the system font and standard symbols belong.
- Opaque, saturated fills where material and a single tint belong.
- Decorating every element, so nothing has hierarchy.
- Decorative edges on standard components such as sheets.
- Faked paper grain or distress.

---

## 6. Checklist for any UI change

- [ ] Swap test: change a bottle or tint and confirm layout geometry is identical.
- [ ] Squint test: blur the screenshot; the hierarchy (title, selected bottle, actions) must still read.
- [ ] Reference test: compare against iOS Wallet, Photos and Apple Music at the same state.
- [ ] Contrast: 4.5:1 body text, 3:1 large text and icons.
- [ ] Reduce Motion, Reduce Transparency, Increase Contrast, and text zoom at 200%.
- [ ] VoiceOver on cards, the Island chip and any sheet or drag alternative.
- [ ] Widths 375, 390 and 430, plus a short phone and the landscape prompt; no horizontal scroll.
- [ ] No new color, font or decorative style outside an approved exception.
- [ ] A real iPhone pass for anything that moves or blurs.
