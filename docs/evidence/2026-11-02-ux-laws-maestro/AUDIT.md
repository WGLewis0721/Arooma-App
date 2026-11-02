# Arooma native UX audit: 15 screenshot anti-patterns + Foundational UX principles

> Scope: existing **native SwiftUI** app at main SHA `b5ec118ad7cdbc9fa111bcac576b272043173627`, with simulator runs from a branch based on that main. Never apply legacy PWA rules.
>
> Sources: user's screenshot of “15 tells your app was vibe coded”; [Arooma Foundational UX Principles](../../design/FOUNDATIONAL_UX_PRINCIPLES.md); [native iOS guide](../../design/platforms/AROOMA_IOS_DESIGN_GUIDE.md).
>
> Interpretation: screenshots and heuristics are **not automatic proof of defects**. Purple is a visual choice, emojis aren't automatically incorrect, and an elegant empty state is not measured by its color. Classify: PASS, FAIL (reproduced), CODE FINDING (source-backed but device not confirmed), UNVERIFIED (needs screen/device), or N/A (not applicable). No invented Maestro results.

## Baseline evidence and reproducibility

- Pre-fix code: main SHA `b5ec118ad7cdbc9fa111bcac576b272043173627`.
- Simulator path: original `.github/workflows/maestro-ios.yml` modified **only on audit branch** to trigger existing workflow on audit branch pushes and run tagged smoke, navigation, search, quick-add persistence/undo and appearance flows.
- Reports are under `Maestro-results` artifact: JUnit, screenshots, hierarchy and logs. The job is not considered passed until GitHub reports completion.
- All flows reset app state for test isolation. State preservation uses `launchApp` without `clearState` after creating an owned bottle.
- On-device tests are still needed for actual haptics, camera, real tilt, animation frame pacing, hardware keyboard and network/thermal behavior.

## Screenshot 15-point audit matrix (priority is fix risk, not severity)

| # | Screenshot signal | Law(s) / measurable criterion | Initial evidence or validation path | Risk of fix |
|---|---|---|---|---|
| 1 | Purple gradients | Unity, contrast, aesthetic–usability | Use approved Arooma theme design tokens, screenshots in both appearances. Color by itself is not a defect. | High (re-theme) |
| 2 | Excessive padding | Balance, hierarchy, Fitts | Compare focused card size and action visibility on narrow iPhones; don't remove required safe areas. | Medium |
| 3 | Keyboard covers input | Jakob, Fitts | Maestro enters Search/Quick Add; inspect screenshots during editing and confirm save action visible. | Medium |
| 4 | Buttons too small | Fitts | Code has 34–36 pt minimum heights in quick tools/scan and a 30×30 close icon; aim at least 44×44 pt accessible targets. | Low–medium |
| 5 | No caching | Doherty, performance | Existing `NSCache` in artwork, owner photo and card studio; don't report missing caching without network/decoder measurements. | High |
| 6 | Text too small | Scale, contrast | Search relationship badges use fixed 9 pt font; replace with Dynamic Type-relative footnote/caption sizes where possible. | Low |
| 7 | Spinners everywhere | Doherty, honest feedback | Isolating-photo flow has a context-specific `ProgressView`; no proof of excessive spinners. Verify actual wait/loading scenarios. | Medium |
| 8 | Emojis | Coherence, Gestalt | Audit icon usage and SF Symbols in nav; emoji presence alone isn't a functional bug. | Low–medium |
| 9 | Tapping twice submits twice | Goal-gradient, state truth | Quick Add flow asserts one saved bottle after relaunch. Need fast double-tap stress case or transaction lock; do not claim Maestro alone proved it. | High |
| 10 | New user blank screen | Jakob, onboarding | Maestro smoke and Quick Add cover initial welcome then usable demo and owned collection; screenshot first-run and empty state. | Medium |
| 11 | Text scaling issues | Scale, contrast | Dynamic Type checks in XCTest/physical device or simulator text-size override; fixed 9–10 pt copy deserves review. | Medium |
| 12 | Dark/light mode issues | Unity, contrast | Run appearance regression and inspect both actual renders; never reinterpret the color palette as an inherent bug. | Medium |
| 13 | Raw error text | State truth, Aesthetic–Usability | **CODE FINDING:** `Commercial.swift` exposes `error.localizedDescription` in commerce, photos, backup and file importer/exporter. Replace with user-actionable copy; preserve errors in private debug logs. | Low |
| 14 | No tap animations | Doherty, feedback | Existing native `withAnimation`, spring cards and haptics; review actual feedback on buttons, not animation count. | Medium |
| 15 | User preferences wiped | Tesler, state truth | `CollectionStore` persists theme, appearance, selected bottles/shelf/mode, wishlist etc to atomic JSON; verify relaunch and no unintended reset. | High |

## Fundamental law pass-through

1. Hick: smoke and navigation, one obvious primary action and <=3 interactions to main tasks where practical.
2. Jakob: Search/Explore/Mine tab changes and sheet close/back.
3. Fitts: accessible 44-point targets from native code and screenshots.
4. Gestalt: notes near focused card name and main actions, visual screenshot review.
5. Miller: search/inspect and ownership preserve relevant labels.
6. Tesler: state does not reset and Demo vs Mine never mingle.
7. Doherty: screen responds to Search and buttons; actual response latency and 60 fps need device instrumentation.
8. Aesthetic–Usability: no foil or animation blocking Search or Quick Add; Reduce Motion physical check still owed.
9. Von Restorff: focused card and selected action uniquely visually emphasized.
10. Goal-gradient / Zeigarnik / Peak–End: Quick Add persists and Undo restores the pending draft.

## Fix sequence, least to most production risk

1. **Low:** Replace exposed OS-level `localizedDescription` strings with user-friendly, actionable messages; log details privately. Keep error semantics.
2. **Low:** Remove fixed 9 pt small badge text in Search; use a Dynamic Type-relative style.
3. **Low–medium:** Expand native quick-tool hit targets to minimum 44 pt and inspect associated layouts; keep all existing IDs.
4. **Medium:** Fix any confirmed keyboard/empty-state/light-dark defects from simulator evidence, one localized flow at a time.
5. **Medium:** Tune excessive padding and animation only after screenshot evidence; preserve premium frame hierarchy, haptics and Reduce Motion.
6. **High:** Add an idempotent save guard only if duplicates are reproduced or supported by source; do not risk data loss by rewriting ownership storage.
7. **High:** Change cache or persistence only after measured faults and backup/migration verification. Do not delete data or overwrite approved art.

No changes should merge to production based solely on static inspection. Require CI build/flow results and preserve user records.
