# Spec: Today's pick widget and the testing Live Activity

> Part of the Arooma design brain. Start at [../README.md](../README.md). Follow [../PLAN_SPEC_PROTOCOL.md](../PLAN_SPEC_PROTOCOL.md). Saved as `docs/design/specs/2026-10-29-widget-live-activity.md`. Modeled on Spread's [widget and Live Activity spec](../../reference/spread/specs/2026-10-28-widget-live-activity.md).

| | |
| --- | --- |
| Request | "Do that", then: "Search Apple's sources again, they are online in the developer part of their website" |
| Restated | The owner sees today's pick and logs a wear from the Home Screen, and runs a timed test of one scent with the timer on the Lock Screen and in the Dynamic Island, without opening the app |
| Surface | iPhone: Home Screen widget, Lock Screen widget, Live Activity (Dynamic Island and Lock Screen). Needs a native build |
| Size | L (new native target, a persistence layer that does not exist yet, and exceptions to the card's Boundaries) |
| Author | Claude, 2026-10-29, for the owner |
| Status | Draft, revised after reading Apple's pages. Proposal only; the owner decides section 8 |
| Governing docs read | `README.md` sections 1 to 4; `RULES_CARD.md`; `PLAN_SPEC_PROTOCOL.md`; `specs/TEMPLATE.md`; `packs/shelf-change.md`; `packs/device-layout.md`; `brand/BRAND_BOARD.md` sections 3, 4 and 7; `DECISIONS.md`; Spread's spec above; the four Apple pages in section 2 |

## 1. Problem

`[Assumption]` The owner decides what to wear in the first minute of the morning, usually with a phone in one hand. Today that means unlocking the phone, opening Arooma, waiting for the cabinet doors, and tapping Daily Pick. Later, when testing a new bottle on a blotter, the owner wants to know how long it has been and when to write down how it has opened, without keeping the app open to watch a timer. The web demo fakes both inside the page, but a page cannot put anything on the Home Screen, the Lock Screen or the Dynamic Island.

## 2. Evidence and context

**Apple pages read on 2026-10-29** at developer.apple.com, fetched as Markdown by adding `.md` to each URL. Where this spec says `[Apple]` it means one of these:
- HIG, [Live Activities](https://developer.apple.com/design/human-interface-guidelines/live-activities) (change log: October 13, 2026).
- HIG, [Widgets](https://developer.apple.com/design/human-interface-guidelines/widgets).
- ActivityKit, [Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities).
- WidgetKit, [Adding interactivity to widgets and Live Activities](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities).

**This repository `[Repo]`**
- Arooma today is one HTML file served as an installable web app. There is no native project, no Capacitor and no Swift. CI tests and deploys the web app only.
- The demo keeps all state in memory. `worn` and the Daily Pick pointer reset on reload. A widget needs data that outlives the page, so persistence is a prerequisite.
- Daily Pick is ranked in JavaScript (`packs/shelf-change.md`). A widget cannot run it.
- The Island chip and the haptic tick in the page are imitations. The brand board fixes the intent: the Island is only for a timed test, a widget is today's pick plus one action (`brand/BRAND_BOARD.md`, "4. Motion").

**Live Activities `[Apple]`**
- Use them for tasks and events with a defined beginning and end, short to medium duration, never over eight hours. A Live Activity can be active for up to 8 hours, and then stays on the Lock Screen for up to 4 more, 12 hours at most. The Dynamic Island clears as soon as it ends.
- Static and dynamic data together cannot exceed 4 KB. A Live Activity cannot use the network. Image assets larger than the presentation can make it fail to start. The Lock Screen presentation is truncated above 160 pt tall.
- The app must be in the foreground to start one, or an App Intent that conforms to `LiveActivityIntent` can start it from the background. People can turn Live Activities off in Settings; `areActivitiesEnabled` reports it. `NSSupportsLiveActivities` goes in `Info.plist`.
- Updates and ends come from ActivityKit in the app, or from push notifications. A `staleDate` flips `isStale` to true at that time, and the view can render a different state, so the display can change without the app running.
- An alert needs an update with an `AlertConfiguration`. On an Island device it expands the Island; elsewhere it shows the Lock Screen presentation as a banner. By default an alert plays the notification sound.
- Ending: `end(_:dismissalPolicy:)` with immediate, default (up to 4 hours) or after a date inside that window. The HIG says to end it immediately when the task ends and to set a dismissal time, "15 to 30 minutes" in most cases.
- It is available on iPhone and iPad, and also appears on a paired Mac menu bar, Apple Watch and CarPlay.
- Presentations: compact, minimal, expanded and Lock Screen are all required. On a 393 by 852 phone: compact 52.33 by 36.67 pt, minimal 36.67 to 45 by 36.67 pt, expanded and Lock Screen 371 wide and 84 to 160 tall. Limited width means fitting a 28 pt circle.
- Design guidance: the two compact elements read as one piece, snug to the camera, and tap to the same screen. Minimal shows updated information, for example the Timer app shows the remaining time. Expanded keeps elements in the same relative place as compact. Lock Screen does not copy notification layouts and uses 14 pt margins. Use large text at medium weight or heavier. Island backgrounds are black and opaque; only the Lock Screen presentation can use a custom background, which must work in light and dark and on an Always-On display. Animations last at most two seconds and are not played on a reduced-luminance Always-On display.
- Interactivity: buttons and toggles only for essential, once-or-pause actions, preferably a single element. Tapping must open the app at the right location. Make it easy to turn the Live Activity off in the app. An App Shortcut can start it from the Action button. Avoid sensitive information; show an innocuous summary or let people choose. Do not draw attention to the Dynamic Island from inside the app.

**Widgets `[Apple]`**
- Purpose: simple, related to the app's main purpose, timely, with useful actions and deep links. Replicating the app icon adds little. Prefer content that changes through the day. Offering one widget in the size that fits is better than every size. Do not mirror the widget's look inside the app.
- Updates: periodic, not continuous. If people look more often than it can refresh, say when it was last updated. Use system date and time views so the system refreshes them.
- Interactivity: buttons and toggles use App Intents. A Button does not keep a pressed state, so on and off state uses a Toggle. On a locked device buttons and toggles are inactive until the owner unlocks. A button should do more than open the app; opening the app is a Link or `widgetURL`. The intent runs in the widget extension's process, or in the app's process for `LiveActivityIntent` and `openAppWhenRun`. When `perform()` returns the system reloads the timeline. The app and the widget share data through a store both can read.
- Families that take interactive controls include small, medium, large and the Lock Screen circular and rectangular. Lock Screen widgets come in inline, circular and rectangular shapes, are monochrome, and use the vibrant rendering mode, with the Always-On display at reduced luminance.
- Appearances on the Home Screen: light, dark, clear and tinted. Light and dark are full color. Tinted and clear desaturate content by default. A full-color image can opt out of that, but Apple says to reserve it for media content, such as album art, and to keep it smaller than the widget.
- Type and layout: text no smaller than 11 pt, system font and styles, a custom font sparingly and best for large text, Dynamic Type from Large to AX5, text never rasterized. 16 pt margins, 11 pt for tight groups. On a 390 by 844 phone: small 158 by 158 pt, medium 338 by 158, Lock Screen rectangular 160 by 72, circular 72 by 72, inline 234 by 26.
- Color: do not rely on color alone for meaning. StandBy and CarPlay use the small widget with the background removed.

**Not on those pages `[3P]` or `[Assumption]`**
- `[3P]` ActivityKit needs iOS 16.1 or later, and the Dynamic Island hardware began with iPhone 14 Pro. Which models have it today was not checked.
- `[Assumption]` Interactive widgets need iOS 17; the page's sample checks for iOS 17 before adding a button, which implies it.
- `[Assumption]` `Text(timerInterval:)` and `ProgressView(timerInterval:)` give a self-updating timer; the ActivityKit page mentions animating timer text but does not name them.
- Not checked: nothing here was built or run. There is no Xcode project to try it in.

## 3. Goals, non-goals and budget

- **Goals:**
  - A small and a medium Home Screen widget, and a Lock Screen rectangular widget, showing today's pick, matching what the app would pick. The medium one has a Wear toggle.
  - A Live Activity that exists only while the owner has explicitly started a timed test, with all four presentations.
  - Everything local. Works in Airplane mode.
- **Non-goals / no-gos:**
  - No permanent "today's fragrance" badge in the Island or on the Lock Screen.
  - No miniature shelf. The three-bottle large widget, the circular and inline Lock Screen widgets, StandBy and CarPlay design, iPad, and Apple Watch are deferred. Apple says to offer the sizes that add value, not all of them.
  - No push backend and no push updates (see the cost of this in section 8).
  - No new colors, fonts or decorative styles. No blur or glass added by Arooma on widget surfaces.
  - No claim of authenticity, projection or longevity. The timer is a test aid.
  - No Live Activity alert or sound unless the owner decides it in section 8.
- **Appetite:** three phases, each shippable on its own. If persistence alone passes a week of work, stop and report.
  1. **Phase 0:** native shell and a local store.
  2. **Phase 1:** the widgets.
  3. **Phase 2:** the Live Activity.

## 4. Rules that apply and exceptions needed

| Rule (document and section) | How this request touches it |
| --- | --- |
| `RULES_CARD.md` Look: no new colors, fonts or decorative styles | Widget and Live Activity colors come from `tokens.json`. No new hex. Native color assets are generated from the tokens, not typed |
| `RULES_CARD.md` Look: cards opaque, glass only on controls | Widget background is solid Oat or Paper in light, and the night ground in dark. The Island is black, set by the system |
| `RULES_CARD.md` Look: bottle art neutral and true to each house | Widget art is the same drawing as the card, in full color, not re-colored |
| `RULES_CARD.md` Look: two faces only | Names use the system serif design and everything else the system sans, matching `ui-serif` and SF Pro. Widget text is 11 pt or larger, which is larger than the 8.5 pt caps on cards |
| `RULES_CARD.md` Behavior: Island for a timed test only; widget is pick plus one action | Direct subject of this spec |
| `RULES_CARD.md` Behavior: haptics at three moments | The widget and the Island add none. Wear and the end of a session keep their in-app moments |
| `RULES_CARD.md` Behavior: volume is an estimate; no certainty claims | Widget text never states remaining volume as fact and never says "verified" or "match" |
| `RULES_CARD.md` Boundaries: fictional houses; no backend, account, analytics or network call | Holds. Local only. No real brand art in any extension |
| `RULES_CARD.md` Boundaries: `index.html` stays one self-contained file | Holds for the web app. A native shell loads the same file, see exception 1 |
| `brand/BRAND_BOARD.md` "7. Low stock and daily pick" | A low-stock bottle is never the pick. The widget uses the same "Today's pick" wording |

**Exceptions needed (owner decides, do not assume):**
1. **A native build.** Add a Capacitor shell, a Swift widget extension target and a small Swift bridge. A new part of the repository and a new CI path. `index.html` stays self-contained.
2. **A persistence layer.** The demo has none. Add a local store that survives reload. Default: a Codable JSON file in an App Group container owned by the native side, read by the page through the bridge in the shell and by localStorage as a web app.
3. **The night palette becomes required.** The Dynamic Island is always black, and the Lock Screen presentation and the widgets need a dark appearance, so the night values in `brand/BRAND_BOARD.md` section 1 must be built as tokens first. They are specified, not built.
4. **An Apple Developer account, a bundle id and an App Group id.** Owner supplies these.
5. **Local notification for the end of a test.** Only if the owner chooses it in section 8. It is outside the Live Activity and in tension with Apple's advice not to alert twice for one update.

## 5. Options and the chosen concept

### Options considered

| Option | Idea in 2 to 3 lines | Pros | Cons |
| --- | --- | --- | --- |
| A. Capacitor shell, Swift extensions | Wrap the existing page in a native shell. Write the widgets and the Live Activity in Swift. A small bridge connects page and store | Reuses the whole UI, including the 3D layouts. Smallest path to a real widget and Island. Spread used this route | Two codebases to keep in step. The page's 3D and blur performance inside a WebView is unverified |
| B. Full SwiftUI app | Rebuild the shelf natively, with the extensions in the same project | Native feel, native haptics, one language | Rebuilds Cover Flow, Stack, Fan and the flip. Largest scope. Loses the web demo as the source of truth |
| C. Stay web | Keep the page and the in-page chip. Add nothing native | No new risk | Cannot meet the brief: no widget, no real Island |
| D. Widgets first, Island later | A with only Phases 0 and 1 | Smallest first release | The Island needs little extra once the shell exists |

**Chosen (proposed):** A, shipped in the three phases above. **Rejected for now:** B, because it replaces working, tested design with a rewrite and can be revisited once the shell exists; C, because it cannot do what the project brief asks. D is not rejected; it is Phases 0 and 1 on their own.

### Breadboard of the chosen concept

**Places and affordances**

- **Small widget (158 by 158 pt):** the bottle in full color, smaller than the widget, its short name, and "Today's pick". Tap opens the shelf on that bottle.
- **Medium widget (338 by 158 pt):** bottle on the left. On the right a short reason line ("Unworn for 33 days. Suits cooler air.") and one Toggle, "Worn today". Tap anywhere else opens the shelf on that bottle.
- **Lock Screen rectangular (160 by 72 pt):** short name and a wear status ("Worn" or "Not worn"), text and a symbol only, no picture. Tap opens the bottle. It has no Wear control, because buttons and toggles are inactive while the phone is locked.
- **Live Activity, compact:** a ring or blotter glyph on the leading side, remaining time on the trailing side, narrow and balanced, reading as one piece.
- **Live Activity, minimal:** the remaining time, in the 36.67 to 45 pt space, as Apple's Timer does.
- **Live Activity, expanded:** fragrance name, a short prompt, and one action, "Log impression", as a link that opens the note sheet. Elements keep their relative places as it expands from compact.
- **Live Activity, Lock Screen:** the same elements in one banner, 14 pt margins, not a notification layout, with a background that works in light, dark and Always-On.
- **In the app:** Test starts the session. A Settings row, "Tests on the Lock Screen and Dynamic Island", turns it off. A second row, "Show fragrance name on the Lock Screen", defaults on.

**Connections**

- The native store owns the day's pick. The app and the widgets both read it.
- The Wear toggle runs an App Intent in the widget extension that writes the wear to the store; the system then reloads the timeline. The app shows it on next open. Toggling it off undoes the wear.
- Test asks the bridge to start the Live Activity while the app is in the foreground. The end of the session is shown by the stale state, and the activity ends when the owner logs, dismisses it or the app next runs.

### States

- **Empty (no bottles):** widget says "Add a bottle in Arooma" and opens the app.
- **No pick yet today:** the native ranking runs and picks one. If every bottle is low stock, the widget says so and opens the app.
- **Widget added before the app was opened:** a placeholder with the closed-door glyph and "Open Arooma".
- **Loading:** system placeholder.
- **Error (store unreadable):** last good pick with the time it was updated, or the first-run text.
- **Low stock:** never the pick.
- **Already worn today:** the Toggle shows on. Turning it off undoes the wear.
- **Locked phone:** the medium widget's toggle is inactive; tapping opens the app after unlock.
- **Offline:** no difference.
- **Live Activities off in Settings or in Arooma:** Test falls back to the in-page chip and says so once.
- **Session running:** compact and minimal show a countdown. **Session done:** the display is stale, shows "Time to note it" and the Log impression link.
- **Dismissed by the owner:** the activity is gone and the app records the test as ended.
- **Refused action:** none.

## 6. Platform behavior

- **Widths and orientation:** sizes are set by the system. App widths and the landscape prompt are unchanged. Portrait only.
- **Install mode:** a native app. The Home Screen web app stays as it is.
- **Appearance:** light uses Oat, Paper and Ink from `tokens.json`. Dark uses the night values (exception 3). Tinted and clear: the bottle image may stay full color because it is object imagery smaller than the widget; the text and glyphs sit in the accented group and the system tints them. Status is never color alone. The Lock Screen widget is monochrome, so it uses text and a symbol.
- **Type:** names in the system serif design, 11 pt or larger everywhere. Dynamic Type from Large to AX5. Text is real text, never an image.
- **Accessibility:** VoiceOver reads the small widget as "Today's pick: Dry Earth by Terre Basse" and the toggle as "Worn today, switch", and the Island as "Testing Dry Earth, 14 minutes left". 44 pt targets. Reduce Motion and Increase Contrast follow the system. Animations in the Live Activity stay under two seconds.
- **Input:** touch. The Island and Lock Screen presentation tap into the app at the bottle.
- **Haptics and motion:** none added by the widget or the Island. Native haptics replace the web `switch` workaround in the app.

## 7. Technical approach

- **Where it lives:** a Capacitor project under `ios/`. Targets: the app shell, one widget extension holding the widgets and the Live Activity, and a shared Swift package for the models, the ranking and the color assets. A small Capacitor plugin, for example `AroomaBridge`, exposes `getShelf`, `recordWear`, `startTest`, `endTest` and `logImpression`.
- **Data and state:** a `Bottle` and a `Wear` record in a JSON file in the App Group container, shared by the app and the extension. The Swift package holds the Daily Pick ranking; the page calls it through the bridge in the shell, so there is one implementation, tested with vectors shared with the JavaScript version. The Live Activity attributes hold the bottle id and name and the planned end. The content state holds the end date. No images, and nothing near 4 KB.
- **Wear intent:** an `AppIntent` in the extension target and the app target, taking the bottle id as an assigned parameter, writing to the store before it returns.
- **Log impression:** a link or `widgetURL` such as `arooma://bottle/<id>/note`, not an intent, because it opens the app. Default scheme name to be confirmed.
- **Live Activity:** `ActivityAttributes` with the bottle id and name; `ContentState` with the end date; `staleDate` set to the session end; a timer view for the countdown; the dismissal policy `after` 15 minutes when the app ends it `[Apple: 15 to 30 minutes]`. Images are not used in the Island, and any Lock Screen image is smaller than the presentation.
- **Page changes:** `index.html` reads data through the bridge when `window.Capacitor` is present and from the sample data otherwise. The only edit to the web app.
- **Flags and rollout:** the shell does not change the web deploy. The extension ships in a TestFlight build only after the device checks in section 9. Spread's [release runbook](../../reference/spread/ios-release/IOS_AUTOMATION.md) is the model for a no-Mac TestFlight pipeline `[Repo: Spread, not verified for Arooma]`.
- **Do not touch:** the Boundaries in [../RULES_CARD.md](../RULES_CARD.md) hold. The generated brain files are not edited by hand.
- **Dependencies:** Capacitor and its iOS runtime. Record each license and maintenance state before adding. No widget plugin; the extension is plain Swift.
- **Performance and privacy:** nothing leaves the device. Lock Screen content is visible to anyone holding the phone, and Apple advises an innocuous summary for sensitive content. A fragrance name is low sensitivity and the switch lets the owner redact it.
- **Colors in Swift:** generated from `docs/design/tokens.json` by a script, never typed twice, so the check that guards tokens also guards the native colors.

## 8. Risks, rabbit holes and open questions

| Item | Why it matters | Proposed default | Who decides |
| --- | --- | --- | --- |
| Go native at all, and the route (A or B) | The largest decision here and the first open row in `DECISIONS.md` | A, in three phases | Owner |
| The demo has no persistence | A widget with nothing to read shows nothing | Phase 0 builds the local store first | Owner |
| Ending a test on time without a server | The page says updates and ends come from the app or from push. The system does not wake the app at a chosen second `[Rec: inference from the page]`, so the activity cannot reliably end at the exact end time | Show the stale "Time to note it" state at the end time, and end it when the owner logs, dismisses it or the app next runs. Accept that it can linger until then, up to the 8 hour limit | Owner |
| Alert at the end of a test | The end is the point of a timer. An alert needs an app update or push; Apple says to alert only for essential updates and not to double up with notifications | No alert by default. Option: one local notification scheduled when the test starts (exception 5) | Owner |
| Push backend | Would fix the two rows above, but breaks "no backend, no network" | Stay without one | Owner |
| Phase prompts (Opening, Heart, Dry-down) | They changed on a schedule in the web demo; without app execution or push the Island cannot change on a schedule | Drop the timed prompts from the Island. Keep one static prompt and put the phase guidance in the note sheet | Owner |
| Daily Pick must match in app and widget | Two answers for "today's pick" destroys trust | One Swift ranking, called by the page, tested with shared vectors | Owner |
| WebView performance of 3D Cover Flow, Fan and `backdrop-filter` | Unverified inside a native shell | Measure on a device in Phase 0 before Phase 1 | Owner |
| Widget content changes once a day | Apple says content that never appears to change may not stay on a screen | Show the pick, worn state and days unworn; revisit after a week of use | Owner |
| Test session length | The web demo uses 30 seconds only to be demonstrable. Apple's Live Activity limit is 8 hours | Presets of 10, 20 and 30 minutes, default 20 `[Assumption]` | Owner |
| Fragrance name on the Lock Screen | Apple advises care with sensitive content | Show it, with a switch | Owner |
| One action in the expanded Island | The web chip has two; Apple prefers a single control | Log impression only; end by the system swipe or from the app | Owner |
| Devices without a Dynamic Island | They show the Lock Screen presentation, as a banner when alerted | Design the Lock Screen presentation first | Owner |
| Bundle id, App Group, URL scheme, team | Needed before any target builds | Owner supplies them | Owner |

## 9. Verification and prototype plan

### Acceptance criteria

- Given a shelf with a pick for today, when the owner adds the small widget, then it shows that bottle's name and "Today's pick", and tapping it opens the shelf on that bottle.
- Given the medium widget and an unlocked phone, when the owner turns on "Worn today", then the app does not open, the toggle stays on after the timeline reloads, and the app later shows the bottle as worn today.
- Given the phone is locked, when the owner touches the medium widget's toggle, then nothing is written until the phone is unlocked.
- Given a low-stock bottle, when the pick is chosen, then it is never that bottle, in the app or in a widget.
- Given the app and a widget are asked for the pick on the same day with the same shelf, then both show the same bottle.
- Given the owner taps Test, when the session starts, then a Live Activity appears with the bottle name and a countdown, in the compact Island form on an Island phone and the Lock Screen form on any phone, and minimal shows the remaining time.
- Given the Live Activity is off in Settings, when the owner taps Test, then the in-page chip is used and the owner is told.
- Given no test is running, then Arooma shows nothing on the Island or as a Live Activity.
- Given the session reaches its end time with the app suspended, then the display shows "Time to note it" with the Log impression link.
- Given the owner taps Log impression, then the app opens on that bottle's note sheet and the activity ends with a 15 minute dismissal.
- Given the bottle image in tinted mode, then it stays full color, is smaller than the widget, and the text stays legible.
- Given Airplane mode, then every behavior above works.
- Given VoiceOver, then the widget and the Island read as in section 6.

### Checks

- `npm run docs:check` and `npm test` for the web app and the docs.
- Swift unit tests for the ranking, with test vectors shared with the JavaScript version.
- Simulator: widget sizes in light, dark, tinted and clear; the four Live Activity presentations; Dynamic Type from Large to AX5.
- Owed on a physical iPhone, not doable in a browser: widget install and refresh, App Group read and write, the Wear toggle and its locked behavior, the Live Activity on an Island phone and on one without, the stale state with the app suspended, Always-On display contrast, StandBy not breaking, tinted and clear modes, battery after a 20 minute test, VoiceOver, behavior after a force quit and a restart.

### Prototype plan (when feel is the open question)

- **What must be real:** the App Group read and write, the widget timeline, starting the Live Activity from the foreground, the stale display with the app suspended, and the compact and expanded Island on a device.
- **What can be faked:** the pick (a fixed bottle) and three bottle images.
- **Where it will be used:** the owner's own iPhone for a week, at the cabinet and on the bedside table.
- **Questions for the tester:** Do you know how to add the widget and start a test? Is the glance easy to read in the morning? How can we make it better?
- The prototype is disposable. The real version is written afterward.

## 10. Rollout, rollback and release

Branch `feature/native-shell` for Phase 0, then one branch per phase, each reviewed before it merges to `main`. The web deploy is untouched throughout. To revert a phase, remove its target and the matching entitlement in one commit; the store file can be deleted on launch if needed. Release authority stays with the owner; this spec is not approval to merge or ship.

## 11. Decision record

| Date | Decision | By | Documents updated |
| --- | --- | --- | --- |
| 2026-10-29 | Draft: native Capacitor shell with Swift widgets and Live Activity, in three phases. Nothing decided; the owner decides section 8 | Claude (proposal) | This spec, `specs/README.md`, `DECISIONS.md` |
| 2026-10-29 | Revised after reading Apple's pages: iPad is supported, minimal shows time, Lock Screen controls are inactive when locked, ending without push is a risk, tinted art may stay full color | Claude (proposal) | This spec |
