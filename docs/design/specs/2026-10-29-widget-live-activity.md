# Spec: Today's pick widget and the testing Live Activity

> Part of the Arooma design brain. Start at [../README.md](../README.md). Follow [../PLAN_SPEC_PROTOCOL.md](../PLAN_SPEC_PROTOCOL.md). Saved as `docs/design/specs/2026-10-29-widget-live-activity.md`. Modeled on Spread's [widget and Live Activity spec](../../reference/spread/specs/2026-10-28-widget-live-activity.md).

| | |
| --- | --- |
| Request | "Do that": write the Arooma spec for the widget and the Dynamic Island, using Spread's as the model |
| Restated | A person who keeps a fragrance collection in Arooma sees today's pick and logs a wear from the Home or Lock Screen, and runs a timed test of one scent with the timer in the Dynamic Island, without opening the app |
| Surface | iPhone: Home Screen and Lock Screen widget, Live Activity (Dynamic Island and Lock Screen). Needs a native build |
| Size | L (new native target, a persistence layer that does not exist yet, and it needs exceptions to the card's Boundaries) |
| Author | Claude, 2026-10-29, for the owner |
| Status | Draft. Proposal only; the owner decides the open items in section 8 |
| Governing docs read | `README.md` sections 1 to 4; `RULES_CARD.md`; `PLAN_SPEC_PROTOCOL.md`; `specs/TEMPLATE.md`; `packs/shelf-change.md`; `packs/device-layout.md`; `brand/BRAND_BOARD.md` sections 3, 4 and 7; `DECISIONS.md`; Spread's spec above |

## 1. Problem

`[Assumption]` The owner decides what to wear in the first minute of the morning, usually with a phone in one hand. Today that means unlocking the phone, opening Arooma, waiting for the cabinet doors, and tapping Daily Pick. Later, when testing a new bottle on a blotter, the owner wants to know how long it has been and when to write down how it has opened, without keeping the app open to watch a timer. The web demo fakes both inside the page, but a page cannot put anything on the Home Screen, the Lock Screen or the Dynamic Island.

## 2. Evidence and context

- `[Repo]` Arooma today is one HTML file served as an installable web app. There is no native project, no Capacitor, no Swift. CI tests and deploys the web app only.
- `[Repo]` The demo keeps all state in memory. `worn` and the Daily Pick pointer reset on reload. Nothing is stored except one localStorage flag for the install hint. A widget needs data that outlives the page, so persistence is a prerequisite, not a detail.
- `[Repo]` Daily Pick is ranked in JavaScript: exclude low-stock bottles, rank by days unworn plus 20 for cool-weather bottles (`packs/shelf-change.md`). A widget cannot run that JavaScript.
- `[Repo]` The Island chip and the haptic tick in the page are imitations. The brand board already fixes the intent: the Island is only for a timed testing session, never a permanent "today's fragrance" badge, and a widget is today's pick plus one action, never a mini shelf (`brand/BRAND_BOARD.md`, "4. Motion").
- `[Apple]` (from the project research notes, which cite Apple's HIG pages; the HIG page bodies could not be fetched this session, only their metadata) Live Activities suit a task or event with a defined beginning and end, with Timer as the example. Keep elements in the same relative place as the presentation expands. Widgets should have a simple, focused purpose with timely content and useful actions, and be designed for tinted, clear and other system appearances. Interactive widgets can offer buttons or toggles without opening the app.
- `[Apple]` (Apple DTS reply, developer.apple.com/forums/thread/797676) A Live Activity can be active for up to 8 hours. After it ends it can stay on the Lock Screen for up to 4 more hours, so at most 12 hours on the Lock Screen. The Dynamic Island clears as soon as it ends.
- `[3P]` ActivityKit needs iOS 16.1 or later and is iPhone only. Combined static and dynamic data is capped at 4 KB, so images stay out of `ContentState` and ids or asset names go in. A Live Activity cannot use the network. It is started from the foreground. It ends with `end(_:dismissalPolicy:)` using immediate, default (up to 4 hours) or after a date. The Dynamic Island exists on iPhone 14 Pro and later; other iPhones show the Lock Screen presentation only.
- `[Apple]` (read for Spread on 2026-10-28, not re-read) Interactive widget controls use App Intents and need iOS 17. The widget extension is a separate process. An App Group entitlement is needed in the app, the extension and the provisioning profile.
- `[Assumption]` The Lock Screen widget families (circular, rectangular, inline) and `Text(timerInterval:)` for a self-updating timer are right as remembered. Recheck on the day native work starts.
- Not checked: nothing here was built or run. No Xcode project exists to try it in.

## 3. Goals, non-goals and budget

- **Goals:**
  - A small, medium and Lock Screen widget that show today's pick and a Wear action, matching what the app would pick.
  - A Live Activity that exists only while the owner has explicitly started a timed test, with compact, minimal, expanded and Lock Screen presentations.
  - Everything local. Works in Airplane mode.
- **Non-goals / no-gos:**
  - No permanent "today's fragrance" badge in the Island or on the Lock Screen.
  - No miniature shelf, no browsing, no search in a widget.
  - No push backend and no push updates. The session is started and updated on the device.
  - No new colors, fonts or decorative styles. No blur or glass on widget surfaces.
  - No claim of authenticity, projection or longevity. The timer is a test aid.
  - No Apple Watch, StandBy-specific or iPad widget design in this release.
  - No Dark or tinted art beyond what is listed in section 6.
- **Appetite:** three phases, each shippable on its own. If persistence alone passes a week of work, stop and report.
  1. **Phase 0:** native shell and a local store.
  2. **Phase 1:** the widget.
  3. **Phase 2:** the Live Activity.

## 4. Rules that apply and exceptions needed

| Rule (document and section) | How this request touches it |
| --- | --- |
| `RULES_CARD.md` Look: no new colors, fonts or decorative styles | Widget colors come from `tokens.json`. No new hex. Native color assets are generated from the tokens, not typed |
| `RULES_CARD.md` Look: cards opaque, glass only on controls | Widget background is solid Oat or Paper. The Island is system black. No blur is added |
| `RULES_CARD.md` Look: bottle art neutral and true to each house | Widget art is the same drawing as the card, not a re-colored version |
| `RULES_CARD.md` Behavior: Island for a timed test only; widget is pick plus one action | Direct subject of this spec |
| `RULES_CARD.md` Behavior: haptics at three moments | Wear and completed action only. The widget cannot trigger custom haptics; the in-app moments are unchanged |
| `RULES_CARD.md` Behavior: volume is an estimate; no certainty claims | Widget text never states remaining volume as fact and never says "verified" or "match" |
| `RULES_CARD.md` Boundaries: fictional houses; no backend, account, analytics or network call | Holds. Local only. No real brand art in any extension |
| `RULES_CARD.md` Boundaries: `index.html` stays one self-contained file | Holds for the web app. A native shell loads the same file, see exception 1 |
| `brand/BRAND_BOARD.md` "7. Low stock and daily pick" | A low-stock bottle is never the pick. The widget shows the same pick tab wording |

**Exceptions needed (owner decides, do not assume):**
1. **A native build.** Add a Capacitor shell, a Swift widget extension target and a small Swift bridge. This is a new part of the repository and a new CI path. It does not change `index.html` being self-contained.
2. **A persistence layer.** The demo has none. Add a local store that survives reload. Default: Codable JSON in an App Group container owned by the native side, read by the page through the bridge when it runs in the shell and by localStorage when it runs as a web app.
3. **New generated assets.** Bottle art as PNG for widgets, and monochrome silhouettes for tinted mode, generated from the same SVG functions by an extension of `tools/generate_assets.py`.
4. **An Apple Developer account, a bundle id and an App Group id.** Owner supplies these.
5. **Night palette.** Widgets in Dark Mode need the night values that are specified but not built (`DECISIONS.md`). Default: build them as tokens first, or let widgets follow the system container background in Dark Mode until then.

## 5. Options and the chosen concept

### Options considered

| Option | Idea in 2 to 3 lines | Pros | Cons |
| --- | --- | --- | --- |
| A. Capacitor shell, Swift extensions | Wrap the existing page in a native shell. Write the widget and the Live Activity in Swift. A small bridge connects page and store | Reuses the whole UI, including the 3D layouts. Smallest path to a real widget and Island. Spread used this route | Two codebases to keep in step. The page's 3D and blur performance inside a WebView is unverified |
| B. Full SwiftUI app | Rebuild the shelf natively, with the extensions in the same project | Native feel, native haptics, one language | Rebuilds Cover Flow, Stack, Fan and the flip. Largest scope. Loses the web demo as the source of truth |
| C. Stay web | Keep the page and the in-page chip. Add nothing native | No new risk | Cannot meet the brief: no widget, no real Island |
| D. Widget first, Island later | A with only Phases 0 and 1 | Smallest first release | The Island needs no extra native plumbing once the shell exists, so deferring it saves little |

**Chosen (proposed):** A, shipped in the three phases above. Phase 1 is the first thing a person can use; Phase 2 follows. **Rejected for now:** B, because it replaces working, tested design with a rewrite and can be revisited once the shell exists; C, because it cannot do what the project brief asks; D is not rejected, it is Phase 1 on its own.

### Breadboard of the chosen concept

**Places and affordances**

- **Small widget:** the bottle, its short name, and the label "Today's pick". Tap opens the shelf with that bottle selected.
- **Medium widget:** bottle on the left. On the right a short reason line (for example "Unworn for 33 days. Suits cooler air.") and one button, Wear. Tap elsewhere opens the shelf on that bottle.
- **Large widget:** the saved three-bottle rotation with a clear primary. One Wear button, on the primary only.
- **Lock Screen widget:** a short name or a symbol and a wear status ("Worn" or "Not worn"). It does not depend on the picture.
- **Live Activity, compact:** a blotter or ring glyph on one side, remaining time on the other.
- **Live Activity, minimal:** the ring or glyph only.
- **Live Activity, expanded:** fragrance name, the current phase prompt ("Note the opening"), and one action, Log impression. Elements keep their relative positions as it expands from compact.
- **Live Activity, Lock Screen:** the same elements in one banner.
- **In the app:** the Test button starts the session. A Settings row, "Show fragrance name on the Lock Screen", defaults on (see section 8).

**Connections**

- The native store owns the day's pick. The app and the widget both read it.
- Wear on the widget runs an App Intent that writes the wear to the store and reloads the widget timeline. The app shows it on next open.
- Test in the app asks the bridge to start the Live Activity. Log impression opens the app on the note sheet. The session ends at its end time or when the owner ends it.

### States

- **Empty (no bottles):** widget says "Add a bottle in Arooma" and opens the app.
- **No pick yet today:** the native ranking runs and picks one. If every bottle is low stock, the widget says so and opens the app.
- **First run, widget added before opening the app:** a placeholder with the closed-door glyph and "Open Arooma".
- **Loading:** system placeholder.
- **Error (store unreadable):** last good pick with no time claim, or the first-run text.
- **Low stock:** never the pick. The bottle can still appear in the rotation, with the same quiet label as the card.
- **Already worn today:** the Wear button becomes a quiet "Worn today" and is inert.
- **Offline:** no difference.
- **Undo:** in the app, a wear can be undone, and the next timeline reload corrects the widget.
- **Live Activity not allowed or disabled by the owner:** Test falls back to the in-page chip and says so once.
- **Session ends or is dismissed:** the Island and Lock Screen clear. The app records the session as ended.
- **Refused action:** none.

## 6. Platform behavior

- **Widths and orientation:** widget sizes are set by the system. App widths and the landscape prompt are unchanged. Portrait only.
- **Install mode:** a native app, not the Home Screen web app. The web app stays as it is.
- **Appearance:** light uses Oat, Paper and Ink from `tokens.json`. Dark follows exception 5. Tinted and clear modes use the monochrome silhouette, because full-color art does not survive them `[Apple, per the research notes]`. Status is never color alone.
- **Accessibility:** VoiceOver reads the small widget as "Today's pick: Dry Earth by Terre Basse. Button: Wear" and the Island as "Testing Dry Earth, opening phase, 14 minutes left". 44 pt targets on the buttons. Dynamic Type through system text styles. Reduce Motion and Increase Contrast follow the system.
- **Input:** touch. The Wear button and the Log impression action are real buttons with labels.
- **Haptics and motion:** the widget and the Island add none of their own. Wear confirmation and the end of a session reuse the existing moments in the app, using native haptics instead of the web `switch` workaround.

## 7. Technical approach

- **Where it lives:** a Capacitor project under `ios/`. Targets: the app shell, a widget extension that holds both the widget and the Live Activity, and a shared Swift package for the models, the ranking and the color assets. A small Capacitor plugin, for example `AroomaBridge`, exposes `getShelf`, `recordWear`, `startTest`, `endTest` and `logImpression`.
- **Data and state:** a `Bottle` and a `Wear` record in a JSON file in the App Group container. The Swift package holds the Daily Pick ranking. The page calls it through the bridge when it runs in the shell, so there is one implementation, tested with vectors shared with the JavaScript version. The Live Activity attributes hold the bottle id, name and the planned end. The content state holds the phase and end date. No images.
- **Page changes:** `index.html` reads data through the bridge when `window.Capacitor` is present and from the sample data otherwise, so the web app keeps working. This is the only edit to the web app.
- **Deep links:** a custom URL scheme such as `arooma://bottle/<id>` selects a bottle. Default scheme name to be confirmed by the owner.
- **Flags and rollout:** the shell does not change the web deploy. The extension ships in a TestFlight build only after the device checks in section 9. Spread's [release runbook](../../reference/spread/ios-release/IOS_AUTOMATION.md) is the model for a no-Mac TestFlight pipeline `[Repo: Spread, not verified for Arooma]`.
- **Do not touch:** the Boundaries in [../RULES_CARD.md](../RULES_CARD.md) hold. The generated brain files are not edited by hand.
- **Dependencies:** Capacitor and its iOS runtime. Record each license and maintenance state before adding. No widget plugin; the extension is plain Swift.
- **Performance and privacy:** nothing leaves the device. Lock Screen content is visible to anyone holding the phone; the name is a low-sensitivity detail and is switchable. The Live Activity runs on a self-updating timer, so no per-second updates are needed `[Assumption]`.
- **Colors in Swift:** generated from `docs/design/tokens.json` by a script, never typed twice, so the check that guards tokens also guards the native colors.

## 8. Risks, rabbit holes and open questions

| Item | Why it matters | Proposed default | Who decides |
| --- | --- | --- | --- |
| Go native at all, and the route (A or B) | It is the largest decision here and the first open row in `DECISIONS.md` | A, in three phases | Owner |
| The demo has no persistence | A widget with nothing to read shows nothing | Phase 0 builds the local store first | Owner |
| Daily Pick must match in app and widget | Two answers for "today's pick" destroys trust | One Swift ranking, called by the page, tested with shared vectors | Owner |
| WebView performance of 3D Cover Flow, Fan and `backdrop-filter` | Unverified inside a native shell | Measure on a device in Phase 0 before Phase 1 | Owner |
| Tinted mode needs monochrome silhouettes | New art assets | Generate from the existing SVG drawings | Owner |
| Widget refresh budget | The system limits reloads, so the pick can lag | Midnight timeline entry plus a reload after each wear | Owner |
| Test session length and phases | The web demo uses 30 seconds only to be demonstrable | Presets of 10, 20 and 30 minutes, default 20, split in thirds `[Assumption]` | Owner |
| Fragrance name on the Lock Screen | Apple advises care with sensitive content | Show it, with a switch | Owner |
| One action in the expanded Island | The web chip has two (End, Log impression) | Log impression only; end by the system swipe or from the app | Owner |
| No Dynamic Island on older iPhones | Many iPhones show the Lock Screen presentation only | Design the Lock Screen presentation first | Owner |
| Bundle id, App Group, URL scheme, team | Needed before any target builds | Owner supplies them | Owner |

## 9. Verification and prototype plan

### Acceptance criteria

- Given a shelf with a pick for today, when the owner adds the small widget, then it shows that bottle's name and "Today's pick", and tapping it opens the shelf on that bottle.
- Given the medium widget, when the owner taps Wear, then the app does not open, the widget shows "Worn today", and the app later shows the bottle as worn today.
- Given a low-stock bottle, when the pick is chosen, then it is never that bottle, in the app or the widget.
- Given the app and the widget are asked for the pick on the same day with the same shelf, then both show the same bottle.
- Given the owner taps Test, when the session starts, then a Live Activity appears with the bottle name, the remaining time and the phase prompt, in the compact Island form on an Island phone and the Lock Screen form on any phone.
- Given no test is running, then Arooma shows nothing on the Island or as a Live Activity.
- Given the session reaches its end, then the activity shows one Log impression action and clears within the dismissal time set for it.
- Given tinted mode, then the widget uses a monochrome silhouette and stays legible.
- Given Airplane mode, then every behavior above works.
- Given VoiceOver, then the small widget and the Island read as in section 6.

### Checks

- `npm run docs:check` and `npm test` for the web app and the docs.
- Swift unit tests for the ranking, with test vectors shared with the JavaScript version.
- Simulator: all widget sizes, light and dark, tinted, the four Live Activity presentations.
- Owed on a physical iPhone, and not doable in a browser: widget install and refresh, App Group read and write, the Wear intent, the Live Activity on an iPhone 14 Pro or later and on one without an Island, Lock Screen visibility, tinted and clear modes, battery after a 20 minute test, VoiceOver, behavior after a force quit and a restart.

### Prototype plan (when feel is the open question)

- **What must be real:** the App Group read and write, the widget timeline, starting the Live Activity from the foreground, and the compact and expanded Island on a device.
- **What can be faked:** the pick (a fixed bottle) and three bottle images.
- **Where it will be used:** the owner's own iPhone for a week, at the cabinet and on the bedside table.
- **Questions for the tester:** Do you know how to add the widget and start a test? Is the glance easy to read in the morning? How can we make it better?
- The prototype is disposable. The real version is written afterward.

## 10. Rollout, rollback and release

Branch `feature/native-shell` for Phase 0, then one branch per phase, each reviewed before it merges to `main`. The web deploy is untouched throughout. To revert a phase, remove its target and the matching entitlement in one commit; the store file can be deleted on launch if needed. Release authority stays with the owner; this spec is not approval to merge or ship.

## 11. Decision record

| Date | Decision | By | Documents updated |
| --- | --- | --- | --- |
| 2026-10-29 | Draft: native Capacitor shell with Swift widget and Live Activity, in three phases. Nothing decided; the owner decides section 8 | Claude (proposal) | This spec, `specs/README.md`, `DECISIONS.md` |
