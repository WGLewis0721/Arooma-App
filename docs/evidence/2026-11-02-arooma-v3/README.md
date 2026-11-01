# Arooma V3: verification evidence (2026-11-02)

> Part of the [Arooma design brain](../../design/README.md). Companion to the [V3 implementation record](../../design/specs/2026-11-02-native-navigation-v3.md) and the [plan](../../../AROOMA_NAVIGATION_V3_QUICK_ACTIONS.md).

**Status: in progress.** This file is updated as each CI run finishes. Rows marked PENDING have no result yet; nothing here is claimed before it has run.

## Established so far

| Item | Result | Evidence |
| --- | --- | --- |
| BEFORE screenshots on the V2 app | 8 captured; the Inspector capture failed (the Explore deck has no Inspect button) | [`before/`](before/), run [41357109292](https://github.com/WGLewis0721/Arooma-App/actions/runs/41357109292), artifact 13104391734 |
| Gyro Flip detector unit tests | **PASS: 94 checks, 0 failed** (synthetic traces on a macOS Swift toolchain; this is logic, not a sensor) | `Native iOS 26 SwiftUI Build` run [41358378384](https://github.com/WGLewis0721/Arooma-App/actions/runs/41358378384), step "Gyro Flip detector unit tests" |
| Native Debug build and Release-proof build | **PASS** at `78b8343` | same run |

## Before screenshots

What V2 looked like, taken from the real app on an iPhone 17 Pro, iOS 26.4 simulator:

| File | Shows |
| --- | --- |
| `before-01-explore.jpg` | "EXPLORE" label, Search icon, and the + and heart buttons sitting between the name and the notes |
| `before-02-view-and-style-card-lighting.jpg` | Card lighting section: no Gyro Flip setting |
| `before-03-explore-search-sheet.jpg` | Search as a sheet from Explore |
| `before-05-my-collection-owned.jpg` | Top toolbar controls, Wear today and Layer, the "What are you wearing today?" banner, and a Today tab |
| `before-06-hold-my-collection-tab.jpg` | Holding the My Collection tab: nothing happens |
| `before-07-today-tab.jpg` | The Today tab |
| `before-08-my-cards.jpg`, `before-09-card-studio.jpg` | My Cards and Card Studio |

## Acceptance (plan section 4)

PENDING: filled in from Maestro run results.
