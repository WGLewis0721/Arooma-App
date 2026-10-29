# Spread reference material

These documents are copied **unchanged** from the Spread repository (`WGLewis0721/spread-app`, commit `4c23d25`, 2026-10-28). Spread is a different product: a local-first weekly planner built as a Capacitor app around React. They are kept here because Arooma is also an iOS product and several of them are good checklists and process. Do not treat them as Arooma rules. The Arooma design brain is in [../../design/README.md](../../design/README.md).

Links inside these files point at Spread's repository layout, so many of them do not resolve here. That is expected.

## What is here

| File | What it is | What is Spread-specific |
| --- | --- | --- |
| `platforms/SPREAD_IPHONE_BUILD_GUIDE.md` | iPhone layout, interaction, haptics, accessibility, dark palette, App Store assets, test matrix, Apple HIG reading list | Task drag and drop, the Week sheet, Capacitor and repo rules, plan item numbers |
| `platforms/SPREAD_IPAD_BUILD_GUIDE.md` | iPad size classes, multitasking, pointer and keyboard, App Store assets | Same |
| `platforms/SPREAD_IPHONE_DUO_BUILD_GUIDE.md` | The iPhone Duo case: safe areas, resize, fold, scenes | Everything about Spread's web chrome |
| `specs/2026-10-28-widget-live-activity.md` | A worked spec for a Home Screen widget and a later Live Activity. Useful model for Arooma's own widget and Island spec | The planner content and the cloud rules |
| `ios-release/IOS_RELEASE.md` | Release candidate runbook for a Capacitor iPhone app | Identity, iCloud, bundle and team details |
| `ios-release/IOS_AUTOMATION.md` | GitHub Actions and Fastlane to internal TestFlight, no Mac needed | Secrets, team and app identifiers |
| `ios-release/APP_STORE_REVIEW_CHECKLIST.md`, `APP_REVIEW_NOTES.md` | App Store review acceptance checklist and reviewer notes | Candidate details |
| `ios-release/APP_STORE_RELEASE_PLAN.md` | The 1.0 release plan | The plan's content |

## What was not copied

Spread's planner and landing page design systems, its Unified UX record, the Studio rebuild spec, iCloud, sync, backup and waitlist documents, the Astra audit evidence, its icon handoff, and its source code and tests. They describe Spread's product, not Arooma's.

## If Arooma goes native

Start from `ios-release/IOS_AUTOMATION.md` for a no-Mac TestFlight pipeline and `specs/2026-10-28-widget-live-activity.md` for the widget and Live Activity shape. Replace every identifier, secret name and bundle ID. Record the decision in [../../design/DECISIONS.md](../../design/DECISIONS.md).
