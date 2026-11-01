# Arooma — App Store submission checklist

Status as of 1 November 2026. Purchases are covered separately in [COMMERCIAL_RELEASE.md](COMMERCIAL_RELEASE.md); this first release ships **without** in-app purchases.

## Already handled in the app

| Item | Where |
| --- | --- |
| Privacy manifest (UserDefaults reason CA92.1, no tracking, no collected data) | `ios/AroomaNative/PrivacyInfo.xcprivacy` |
| Photo-library *add* permission text (share sheet "Save Image" would otherwise crash) | `ios/AroomaNative/Info.plist` |
| Camera permission text | target build settings |
| `ITSAppUsesNonExemptEncryption = NO` (no export-compliance prompt per upload) | `ios/AroomaNative/Info.plist` |
| iPhone portrait only | `ios/AroomaNative/Info.plist` |
| Storefront, Restore Purchases and StoreKit lookups hidden until an offer is approved (Guidelines 2.1 and 3.1) | `CommercialRelease.storefrontVisible` |
| Owner tools (tuning panel, frame-time readout) only in Debug and TestFlight builds (Guideline 2.3.1) | `BuildChannel.allowsOwnerTools` |
| Unavailable "stylized card downloads" settings hidden in App Store builds | `StylizedCardSettings` |
| 1024 px app icon without alpha | `Assets.xcassets/AppIcon` |
| Public privacy policy and support pages | `legal/` → `https://wglewis0721.github.io/Arooma-App/privacy.html` and `/support.html` (published by the Pages workflow) |

## Owner steps in App Store Connect

1. **App record:** bundle ID `com.graymatter.arooma`, primary category Lifestyle.
2. **App Privacy (nutrition label):** choose **Data Not Collected**. Nothing leaves the device.
3. **Privacy Policy URL:** `https://wglewis0721.github.io/Arooma-App/privacy.html`. **Support URL:** `https://wglewis0721.github.io/Arooma-App/support.html`. If the repository is private, replace the support page's GitHub issues link with a support email first.
4. **Age rating questionnaire:** all answers "None", which gives 4+.
5. **Screenshots:** 6.9-inch iPhone (1320 × 2868) is required; capture the deck, inspector, Quick Add review, Today and Search. Avoid house logos in the screenshot captions and in the app name, subtitle and keywords.
6. **Build:** run the Codemagic `arooma-testflight` workflow, test on TestFlight, then select that build for review.
7. **App Review notes** (paste):
   > Arooma is an independent, offline fragrance collection app. No account or login is needed. All data stays on the device. To try it: choose "Explore the Archive", swipe the cards, tap a card to inspect and flip it, swipe up on a card for insights, tap + to capture a bottle by name or photo and swipe the review card right (Collection) or left (Wishlist). This version has no in-app purchases.

## Remaining approval risk that needs an owner decision

**Guideline 5.2.1 (third-party trademarks and content).** The bundled sample cards show real fragrance houses, product names and bottle imagery (Dior, Yves Saint Laurent, Rasasi). Review can reject this without written permission, even with the in-app "independent, not affiliated" notice. Options, fastest first:

1. Ship the App Store build with brand-neutral sample cards and keep the approved branded masters for owner and TestFlight use only.
2. Obtain written permission from each house, and attach it in App Store Connect under Review Information › Attachment.
3. Submit as-is and respond to any rejection by removing the bundled branded samples; collections that owners photograph themselves are unaffected.
