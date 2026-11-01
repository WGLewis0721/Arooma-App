# Arooma | Native iOS Design Guide

> Summary: Arooma's native SwiftUI implementation and validation rules, adapted from Spread's iOS reference set without inheriting Spread's web stack.

> Part of the Arooma design brain. Start at [../README.md](../README.md) and [Apple design principles](APPLE_DESIGN_PRINCIPLES.md).

**Scope:** native SwiftUI iOS 26+ Arooma experience, derived from the established Spread iOS research and adapted to a collectible fragrance archive. This is design guidance, not a claim that every listed device class is supported or verified.

## Where the Spread iOS fork lives

Arooma already includes byte-for-byte copies of Spread's [iPhone](../../reference/spread/platforms/SPREAD_IPHONE_BUILD_GUIDE.md), [iPad](../../reference/spread/platforms/SPREAD_IPAD_BUILD_GUIDE.md) and [iPhone Duo](../../reference/spread/platforms/SPREAD_IPHONE_DUO_BUILD_GUIDE.md) build guides. These are **reference copies, not Arooma requirements**. The local [Apple design principles](APPLE_DESIGN_PRINCIPLES.md) were previously forked and adapted from Spread. Do not recopy them over Arooma's native work or inherit Spread's React/Capacitor, planner, Apple ID, storage and CI assumptions.

Arooma's product authorities: [brand board](../brand/BRAND_BOARD.md), [foundational UX principles](../FOUNDATIONAL_UX_PRINCIPLES.md), [native Atelier direction](../../../NATIVE_ATELIER_FINAL.md), and [native motion spec](../specs/2026-10-31-native-premium-motion-interaction-system.md). Follow [third-party-content policy](../brand/THIRD_PARTY_CONTENT_POLICY.md) when using fragrance photos or marks.

## Core native design decisions

| Topic | Native Arooma rule | Evidence to collect |
| --- | --- | --- |
| **Object-first hierarchy** | The active collectible card is the hero. Keep approved photographic art opaque and unobscured; put Liquid Glass on controls only | Focused card has all four edges and legible identity; controls do not paint over copy |
| **Platform familiarity** | Use SwiftUI-compatible navigation, sheets, back, labels, confirmation and system accessibility behaviors; avoid a custom control when a clear native one fits | New user understands Browse, Search, Add, Inspect and Wear without training |
| **Reachability** | At least 44 x 44 pt hit areas for primary controls where applicable. Respect safe areas, gesture home bar, hardware cutouts and Dynamic Island | Real tap boxes and no overlap in portrait and supported rotated sizes |
| **Direct manipulation** | Drag and card physics follow the finger, release with deliberate spring/velocity settling; selection survives Cover Flow, Stack and Fan | Frame-capture and hands-on response check; no reselected wrong bottle |
| **Motion and haptics** | Prefer restrained, coherent physical motion; Reduce Motion provides functional alternatives; haptics only at defined confirmation moments | No forced intro pause or perpetual animation; accessible fallback succeeds |
| **Typography and contrast** | SF Pro utility text, approved editorial serif and restrained calligraphy within existing brand rules. Adapt to Dynamic Type and Increase Contrast | No clipped names, notes or action labels; accessibility reading order matches |
| **State truth** | Demo/Mine and local records stay separate; no fictitious progress, fake source confidence or fabricated processing | Reopen app and verify persistence; correct error/empty/offline display |
| **Privacy and asset provenance** | Use bundled owner-approved masters as permitted; do not imply rights to redistribute unlicensed imagery | Rights review and exact master/derived asset traceability |

## Devices and scenes

- **iPhone:** audit at representative compact and large phone widths (including 375, 390 and 430 pt), portrait and supported landscape. Respect content margins and safe areas without sacrificing card visibility.
- **iPad:** if iPad support is claimed, validate split view, Stage Manager sizing, pointer/keyboard, multiple size classes and native sheets. Do not treat the Spread iPad guide as proof Arooma supports any of those.
- **iPhone Duo / fold concepts:** Spread's Duo research is a **design reference only**, not an announced or supported Arooma device target. Verify actual platform availability and simulator/device support before planning, screenshots or release claims.
- **Accessibility:** VoiceOver card summaries; correct grouping; SwiftUI labels; Dynamic Type; high contrast; Reduce Motion; tap/keyboard/accessibility alternatives to custom swipe/drag and pinch interactions.
- **Robustness:** offline collection, fresh install, returning user, no bottles, very long fragrance names, import/export or backup if implemented, interrupted gestures and app resumption.

## Surface rules

1. **First run:** display the approved wordmark and clear Demo/Mine entry; allow skipping motion. Returning users go to their previous collection without a blocking intro.
2. **Cover Flow, Stack and Fan:** maintain one shared selected-bottle identity. Touch feedback and card placement are deterministic. Don't create separate store copies for each mode.
3. **Inspect:** focused art is not re-rendered or inventively regenerated; notes and ownership fields remain readable and accurate. The card may flip, but critical actions are never available only through an undiscoverable gesture.
4. **Search/Add/Wear:** show one clear next step. Keep secondary actions grouped and make confirmation reflect actual saved state. Place destructive actions behind appropriate system semantics.
5. **Themes:** retain the approved brand palettes and light/dark behavior; changing appearance must not recolor photographic collectible art or change navigation semantics.

## Implementation and release evidence

Use the **actual SwiftUI target** under `ios/AroomaNative` rather than `index.html` or the retired PWA. For a design PR, list: affected screens, relevant [UX laws](../FOUNDATIONAL_UX_PRINCIPLES.md), governing brand rule, before/after screenshots from the running native build, interactions and VoiceOver/Reduce Motion results, and remaining device-only acceptance owed. Tests or static documentation alone do not establish 60 fps, accessibility, App Store eligibility or animation quality. Preserve the native bundle, local data and existing signed distribution process.
