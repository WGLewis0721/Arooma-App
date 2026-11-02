# Spec: Native navigation V3, My Collection quick actions, signature header and Gyro Flip

> Part of the [Arooma design brain](../README.md). Source plan: [AROOMA_NAVIGATION_V3_QUICK_ACTIONS.md](../../../AROOMA_NAVIGATION_V3_QUICK_ACTIONS.md), which is authoritative and supersedes the tab configuration, the "no tab long-press" rule and the "remove the wordmark" rule in [Native navigation V2](2026-11-02-native-navigation-v2.md). Evidence: [2026-11-02 Arooma V3](../../evidence/2026-11-02-arooma-v3/README.md).

Summary: Arooma's SwiftUI app now has three bottom tabs in this order: Explore, My Collection, Search. Today is no longer a tab: wear, layering, saved combinations and history are a Wear log sheet inside My Collection. Pressing and holding the My Collection tab shows a frosted column with Wishlist, Add and Wear; Wear logs the owner-selected owned bottle at once. The living Arooma signature returns to the upper left of all three tabs. An optional wrist twist flips an open card through the shared motion feed. Card Studio and My Cards are removed from the visible app and no saved data is touched. This file records what was built and what was decided; it is not a plan.

| | |
| --- | --- |
| Branch | `feat/arooma-v3`, from `origin/main` at `1a477c9` |
| Scope | `ios/AroomaNative/`, `ios/Tests/GyroFlip/`, `.maestro/`, one step in `.github/workflows/native-ios.yml`, design docs |
| Not in scope | Merge, TestFlight, deployment, signing, bundle ID, persisted record schema, the PWA, deleting any saved data |
| Status | Merged to `main` at the owner's request before any Maestro flow had run. First Maestro results (iOS 26 Simulator): 12 of 15 new flows and 4 of 14 existing flows passed; the press-and-hold passes. Fixes for the failures are in a follow-up PR whose confirming runs were not finished when it was merged. Detector unit tests pass (94 checks). No physical-iPhone validation. See the evidence README. |

## What changed

| Area | Result | Where |
| --- | --- | --- |
| Tabs | `AtelierTab` is `explore`, `myCollection`, `search`. No Today tab, no Cards tab, no bottom accessory. Search is the existing `AtelierSearch` as a real tab; a result opens its Inspector from inside the tab and changes no selection. | `AroomaApp.swift` |
| Explore | The "EXPLORE" label and the Search icon are gone. The header is the signature at the left and one View & Style control. | `AtelierGallery.swift` |
| Fragrance identity | House, name, then the concentration and scent-note line **directly beneath the name**, then the contextual actions. Nothing sits between title and notes. | `AtelierGallery.identity` |
| My Collection | Signature left, Owned/Wishlist control right. Low on the screen, labelled controls: Shelves, Wear log, Add. The Wear today and Layer buttons stay, so one-tap wear works without a long press. Shelves and the Wear log stay in the owned view even on an empty collection; Add is hidden then, because the empty state's own button (same identifier) is the single Add. | `MyCollectionScreen` |
| Wear log | The existing `AtelierWearLog` (wear, layer, saved combinations, history, undo) in a sheet from My Collection. Layer on a card opens it with that bottle chosen. | `AtelierRoot.showingWearLog` |
| Quick actions | Hold the My Collection tab: column with Wishlist, Add, Wear, directly above the tab. A tap on the tab still navigates. | `QuickActions.swift` |
| Wear | Resolves the owner-selected owned bottle from `selectedMineID`, validated against `bottles`. One session through `recordWear`, which now returns the session id. A confirmation "Worn today · Name" with Undo that reverses only that session. A bottle already worn today shows "Worn today" and cannot be logged again. With no valid owned selection the row is disabled: "Select a bottle in My Collection". | `QuickWearAvailability`, `CollectionStore.recordWear` |
| Signature | `AroomaSignatureShimmer` (the approved master, image-masked) in a shared `AroomaBrandMark`, 6 s period, paused when the scene is inactive, static under Reduce Motion, capped at 30 redraws a second. Branding only: nothing is attached to it. | `AppHeader.swift`, `Signature.swift` |
| Gyro Flip | Optional wrist twist flips an open card through the same `FlipMotor.flip(direction:)`. Pure detector, one shared `CMMotionManager`, one discrete event. Setting under View & Style, Card lighting. | `GyroFlipDetector.swift`, `GyroFlip.swift`, `MaterialLight.swift` |
| Card Studio | `MyCardsScreen` and `CardStudioScreen` have no entry point. The types, `CardCommerce` and everything it stores are unchanged. | `AroomaApp.swift`, `Commercial.swift` |

## Decisions and judgement calls (for owner review)

- **The tab hold is a UIKit hook.** `TabView` gives a `Tab` no long-press, so a `UILongPressGestureRecognizer` is added to the system `UITabBar`. It begins only on the My Collection item, found by accessibility label with equal thirds as a fallback. The system tab bar is not rebuilt. `AtelierRoot` also reverts any tab change the hold itself causes. It passes on the iOS 26 Simulator (`collection-long-press-actions`); it has not been tried on a physical iPhone.
- **Add is shown once in the lower area** of My Collection, as a labelled control, so users who never long-press can still add. The long-press Add is the shortcut to the same sheet. The old top-right + is gone. Reading "avoid duplicating the contextual Add shortcut" this way is a judgement call.
- **Wear target.** The row names the bottle it will log. While My Collection's owned deck is on screen, the card in front is synced into `selectedMineID` (a first bottle has no stored selection until then). From Explore or Wishlist the last owned selection is used and named; a Wishlist or sample card is never inferred to be owned.
- **Wear confirmation** lasts 6 s. QA builds can lengthen it with `-AroomaQAUndoWindow <seconds>`, the argument the Quick Add flows already use.
- **Gyro Flip is On by default**, with the conservative filters in the plan. Added safety beyond the plan's list: a fresh or reset detector must see the phone still for 0.15 s before it arms, so the tail of an earlier motion can never flip a card. The system share sheet is not detectable from SwiftUI, so motion flips are not suppressed while it is open.
- **Search tab** is a plain tab, not the system search-role tab, so it sits in the same pill as the other two and the tab-bar hold can address three equal items.

## Card Studio audit (flag for owner review)

Removing the visible UI removes the only in-app way to **view, share, export or restore a created card**. `MyCardsScreen` held the created-card list and detail, per-card share, library import, export and restore (`StudioBackup`), and an Autumn shortcut into the sample deck. The records, files and entitlements are untouched and still load at launch (`CardCommerce.start()`), so nothing is lost, but there is currently no screen to reach them. If owners have created cards, a read-only recovery or export surface should be added before this ships. Not decided here.

## Verification

See [the evidence README](../../evidence/2026-11-02-arooma-v3/README.md) for the acceptance table with PASS, FAIL or NOT RUN per criterion, real before and after screenshots, run links and artifact ids.

Simulator evidence does not establish: real gyroscope thresholds, the 20-twist and 100-incidental protocol, haptics, frame pacing, energy cost of the always-on signature, VoiceOver, or the tab-bar hold on a physical iPhone. Those stay NOT RUN until done on a device.
