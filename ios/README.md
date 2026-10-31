# Arooma Native · iOS 26+

**Independent SwiftUI application. Not a PWA wrapper, not a web view, not a port of index.html.**

Open **ios/AroomaNative.xcodeproj** in Xcode 26+ and run the **AroomaNative** scheme. The Xcode project references the approved original card masters in this repository; keep the entire repo checkout intact. No dependencies or network access.

## Put Arooma on your iPhone Home Screen

1. On a **Mac with Xcode 26+**, clone the whole repo and open **ios/AroomaNative.xcodeproj**.
2. In Xcode select the **AroomaNative** target → **Signing & Capabilities** → **Automatically manage signing**, and pick your Apple Developer team. Change the bundle identifier from **com.graymatter.arooma** if that identifier belongs to another team.
3. Connect an **iPhone running iOS 26+**, via USB or Xcode wireless pairing. If requested, enable **Developer Mode** in iPhone Settings → Privacy & Security. Select the phone as the Run destination.
4. Press **Run (▶)**. Xcode installs the app, creates its **Arooma Home Screen icon**, and launches it. From then on you can open it directly from the Home Screen, full-screen, offline, with persistent data.
5. For a simulator demo, select an iOS 26 simulator in Xcode and press Run; no signing is needed.

**A native iOS app cannot be installed by Safari's “Add to Home Screen.”** That action makes a web shortcut/PWA, which this project explicitly is not. To install on an iPhone without connecting through Xcode, the next step would be a properly signed **TestFlight** build, Ad Hoc installation, or App Store distribution. Merely having a GitHub URL does not install an unsigned native application.

## Design and behavior

- Content and functional layers are separated. **Original photographic card art stays opaque.** Liquid Glass is applied only to floating controls and the native iOS 26 TabView. Sheets use system presentation. System SF Pro is used for actionable UI; refined system serif for perfume headings.
- The source of truth is **assets/collectibles/masters/approved/**. The bundled original two-up PNGs are split in-memory by midpoint into two faces, with no redrawing or AI regeneration. **Prodigy** is included but marked a historical edition.
- Local-first on-device JSON store in app Documents (**arooma-native-v1.json**); Demo/Mine, four seasonal shelves, Cover Flow/Stack/Fan, selected identity persistence, named rotations, search, immersive card flip, notes, wear/Undo, daily pick, and low stock.
- Four 60:30:10 themes, light/dark/system settings, Dynamic Type, Reduce Motion, Reduce Transparency, meaningful accessible controls, and hardware-conditional Core Haptics (selection settle, wear, completed action).
- No account, backend, ad, analytics, network images, external SDK, sign-in or PWA dependencies.

## Verification

The dedicated **Native iOS 26 SwiftUI Build** GitHub Actions workflow uses **macos-26** and executes an **unsigned iOS simulator Xcode build**. This catches compiler/resource/project errors without requiring Apple signing credentials. It does not prove physical hardware haptic quality or smoothness: perform a real-device pass after installation.

Older PWA workflows still present in the repo are not part of this Xcode target. Read **NATIVE_TARGET_OVERRIDE.md**, **AROOMA_V2_FINAL_POLISH_SPEC.md**, **docs/design/brand/BRAND_BOARD.md**, and **docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md**. Old PWA delivery constraints do not apply; approved artwork and design safety do.

## Rights

The approved compositions are original project artwork but brand identification and source imagery still have unresolved distribution rights. Before App Store/TestFlight public distribution, follow the per-asset review in **docs/design/brand/THIRD_PARTY_CONTENT_POLICY.md**. Fragrance houses have not endorsed this application.
