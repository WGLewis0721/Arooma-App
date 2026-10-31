# Arooma Commercial Native Release Contract

**Build branch:** `feat/commercial-product-studio-store`
**Application:** `com.graymatter.arooma` · iOS 26+ · SwiftUI/Metal · StoreKit 2
**Status:** Commercial product architecture implemented on a draft PR; **live payments remain intentionally disabled pending rights, account setup, and recoverable booster delivery**.

## Product surfaces

1. **My Bottles:** owned physical fragrances, shelves, existing Wishlist, search, Today, wear history and saved layering.
2. **My Cards:** a separate ownership record for creator-made digital cards, permanent StoreKit card acquisitions and time-limited library access. The relationship never implies physical bottle ownership.
3. **Card Studio:** photo intake with PhotosPicker, optional on-device Vision foreground isolation, theme-finishes, editable title and caption, bottle association, dynamic holographic lighting, local project persistence and static PNG sharing. Backup/export/import includes photos and makes a non-destructive merge.
4. **Discover:** exact-card catalog and StoreKit product metadata, annual library access and seasonal booster offer with honest disabled states until each is commercially safe. Restorable purchases use verified StoreKit 2 transactions. Non-consumable grants are recorded independently of membership.

## App Store Connect product registration

| Identifier | Intended product type | Merchant-facing offer |
| --- | --- | --- |
| `com.graymatter.arooma.library.annual` | Auto-renewable (Annual, Arooma Library group) | Annual digital card library access; proposal $24.99/year |
| `com.graymatter.arooma.booster.season01` | Consumable | Seasonal randomized pack; proposal $5.99 |
| `com.graymatter.arooma.frames.archive` | Non-consumable | Permanent studio customization pack |
| `com.graymatter.arooma.card.dior-archive` | Non-consumable | Dior illustration edition, rights pending |
| `com.graymatter.arooma.card.hawas-archive` | Non-consumable | Rasasi illustration edition, rights pending |
| `com.graymatter.arooma.card.myslf-archive` | Non-consumable | YSL illustration edition, rights pending |
| `com.graymatter.arooma.card.prodigy-archive` | Non-consumable | Historical Prodigy edition, rights pending |

**Do not create a purchasable product for any artwork without evidence that commercial distribution is permitted.** Apple review of an app or another application never establishes copyright permission. Create price/availability/agreements in App Store Connect, not in code.

## Why paid packs are off

Paid randomized virtual items require odds disclosures before purchase under Apple's App Review Guidelines 3.1.1; a valid 50-card licensed season, actual card count per pack, rarity, duplicate rules and guarantees are not configured. A permanent card-ownership ledger must reconcile **each verified transaction once**, including reinstall/device loss and refunds. On-device storage alone is insufficient for this. Provision a dedicated Arooma service or authenticated entitlement backend and Apple App Store Server API + Notifications V2; do not place App Store private keys in the iPhone app or reuse unrelated projects. Until those dependencies are genuinely operational, the commercial gates remain false. Never charge and then leave a card undelivered.

## Recovery semantics

- Purchases: StoreKit verified `Transaction.currentEntitlements` for subscriptions and non-consumables, with explicit user-initiated `AppStore.sync()` restore.
- Personal studio projects: `arooma-cards-v1.json` and studio image files in Documents. Cards menu > Export My Cards writes a portable JSON with image bytes; Import merges by UUID and remaps file names, without deleting current library.
- Existing physical fragrance archive remains in its separate `arooma-native-v1.json` and must not be overwritten.
- Membership-only cards disappear from available library access when subscription entitlement ends; permanently purchased cards and created cards remain.
- External ledger for purchased randomized card grants is still a blocker. Do not claim guaranteed cross-device recovery before the backend is live.

## Apple platform and privacy

- Xcode target includes StoreKit, PhotosPicker, Vision, Metal and Core Motion. No new entitlement is needed for these frameworks alone.
- Existing camera permission is in the Xcode build settings.
- `PrivacyInfo.xcprivacy` declares UserDefaults (CA92.1) for app settings and no in-app tracking. Re-audit App Store privacy labels and any future remote analytics/cloud services when added.
- If adding iCloud/sync, configure an Apple Developer CloudKit container and signing; if adding share extensions/widgets, create their targets and App Groups; if sending push alerts, enable APNs and document opt-in. None is silently enabled by this PR.

## Release acceptance

1. Existing native GitHub Actions Xcode simulator build succeeds; Swift data models do not break previously stored archives.
2. On physical iPhone, photo picker, Studio cutout/original choice, live foil, 120 Hz where supported, PNG sharing, export/import, and accessibility alternatives work.
3. App Store Connect products are registered, Paid Apps Agreement active, prices in all intended storefronts verified, StoreKit sandbox purchases/refunds/restores verified. No manual enabling of purchase flags before this.
4. Asset provenance and redistribution rights signed off for every paid edition and shareable artwork.
5. A dedicated server-side verified booster grant pipeline, publishable odds and restore/refund reconciliation are deployed and independently exercised before activating paid randomized purchases.
6. License terms, privacy policy, support, subscription cancellation/expiry behavior, and App Review disclosures are complete.

An unsigned simulator compile does **not** mean StoreKit is configured, physical foil is tuned, content rights are cleared, or this commercial app is ready for paid launch.
