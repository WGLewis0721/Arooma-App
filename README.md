# Arooma · Native iOS 26+

**Current app:** [AroomaNative.xcodeproj](ios/AroomaNative.xcodeproj) — a standalone SwiftUI iPhone app, not a web wrapper. [Native build and iPhone Home Screen installation instructions](ios/README.md).

The native project bundles the exact approved photographic card masters from `assets/collectibles/masters/approved/`, preserves independent Demo and Mine collections, and uses iOS 26 Liquid Glass only on controls. Open the whole repository in **Xcode 26+**, choose **AroomaNative**, select your iPhone and development team, then press **Run** to install the app and its Home Screen icon. **Safari's Add to Home Screen is not the native installation route.**

---

## Earlier web prototype (historical reference only)

# Arooma

Native SwiftUI iOS 26+ app for a private collectible fragrance archive.

Photographic collectible cards are the hero (the jewelry). The shell is a fitted velvet tray using the four approved 60:30:10 themes. Liquid Glass only on the functional/navigation layer. Content layer stays opaque.

**Primary goal:** demo the polished app in the iOS Simulator without TestFlight or device install. Clone the repo, open the Xcode project, and run.

All design objectives, art masters, interaction rules, and the brand board remain authoritative. See [AROOMA_V2_FINAL_POLISH_SPEC.md](AROOMA_V2_FINAL_POLISH_SPEC.md) (updated for native) and [docs/design/brand/BRAND_BOARD.md](docs/design/brand/BRAND_BOARD.md).

## Status

PWA / single-file `index.html` / GitHub Pages target is retired. Do not extend it. Native SwiftUI is the only delivery vehicle.

Production card assets remain in `assets/collectibles/production/`. Masters stay untouched.
