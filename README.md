# Arooma

A personal cabinet for your fragrance collection. A premium iOS app concept: not a storefront, not an inventory dashboard. Bottles are the richest thing on screen; everything around them is paper, light and restraint.

This repo holds the **iOS web app demo** (an installable PWA) and the brand board.

**Live demo:** https://wglewis0721.github.io/Arooma-App/

## Try it on iPhone

1. Open the link above in **Safari** on your iPhone.
2. Tap **Share**, then **Add to Home Screen**.
3. Launch **Arooma** from the Home Screen. It opens full screen with its own icon and a closed-cabinet launch image, and keeps working offline after the first load.

Hold the phone upright; landscape shows a prompt to rotate.

## What the demo shows

| Area | What to try |
|---|---|
| First open | Two cabinet doors swing open, the interior light comes up, bottles rise into place. Tap the doors to open sooner. Cabinet menu, then Replay the cabinet doors, plays it again. |
| Shelf | 7 sample bottles (fictional houses), saved on this device once you change anything. Swipe, tap a neighbor, or use arrow keys. Tap the centered card to flip it to its ownership record. |
| Layouts | Cover Flow, Stack and Fan keep the same bottle selected. Fan is a saved 3-bottle rotation and needs at least three bottles. |
| Daily Pick | Brings the next candidate forward with an olive outline and a "Today's pick" tab. |
| Low stock | Salt Cedar: the liquid level drops, and a quiet "Running low" label with a hairline gauge. Always labeled as an estimate. |
| Add and delete | The plus button adds a bottle: house, fragrance, size, an estimate of what is left, notes, acquired date and one of seven neutral vessels. The three dots under the card open Delete bottle, which asks first and offers Undo. The shelf holds 1 to 40 bottles. |
| Wear tracking | Wear today logs the date with Undo. Wear history (three dots under the card) lists every wear, adds a past date, removes one and shows the average gap. Daily Pick uses the log. |
| Authenticity check | Five observations per bottle: Matches, Differs or Not checked. It is a simulated checklist with no scan or lookup, so it reports "Consistent on" or "Differs on" and says it cannot verify. The result goes on the ownership record. |
| Compare before buying | Cabinet menu, Compare notes. Type the notes of a bottle you are considering and see the three closest bottles you own by overlap in listed notes, with an eight-family radar. It does not predict how a scent wears on you. |
| Test timer | "Test" starts a 30 s session. A Dynamic Island style chip shows the timer, expands on tap, and walks through Opening, Heart and Dry-down. |
| Shelf image | Cabinet menu, then Share shelf image, builds an editorial 1080 x 1350 image of up to eight bottles with no app chrome and opens the iOS share sheet (Save Image, Messages, AirDrop). |
| Reset | Cabinet menu, then Reset demo data, clears what you added and logged and brings back the seven samples. |

## Web demo versus the native app

This is a web app, so a few things are imitations of native features:

| Feature | In this demo | In the native app |
|---|---|---|
| Dynamic Island | In-app chip drawn inside the page | Live Activity (ActivityKit) |
| Widgets | Not possible on the web | WidgetKit: today's pick plus one action |
| Haptics | Best effort. Safari 17.4+ ticks through a hidden switch control, and only near a tap | UIFeedbackGenerator |
| Glass | CSS blur on controls and navigation only | Native Liquid Glass |
| Fonts | `ui-serif` resolves to New York on iOS, SF Pro for UI | Same |

## Deploy

`.github/workflows/pages.yml` runs on every push to `main`:

1. Assembles `dist/` (the app, manifest, service worker, icons) and stamps the service worker with the commit SHA.
2. Runs `tests/smoke.cjs` in a headless browser at an iPhone viewport: doors, 7 cards, layouts keep the selection, Daily Pick, Island timer, manifest and icons resolve, service worker active, share image export, then add, delete with Undo, wear history, the evidence checklist, compare, reload persistence, damaged storage, a one-bottle shelf and a 375 by 667 phone, with no console errors. Screenshots are kept as a build artifact.
3. Deploys to GitHub Pages.

**One-time setup:** in the repo go to **Settings, Pages, Build and deployment, Source** and choose **GitHub Actions**. Then re-run the workflow if the first run stopped at the deploy step.

## Design brain

All design guidance lives in [docs/design/README.md](docs/design/README.md): a task router, a short rules card that is copied into `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` and the Copilot instructions, task packs, a plan and spec protocol, and the brand board. `npm run docs:check` keeps it consistent (links, size budgets, a fresh rules card, a fresh `tokens.json`) and runs in CI.

The structure and checks are forked from the Spread repository (`WGLewis0721/spread-app`, commit `4c23d25`) and adapted to Arooma. Spread's iPhone, iPad and Duo build guides, widget and Live Activity spec and iOS release runbooks are kept unchanged in [docs/reference/spread/](docs/reference/spread/README.md) for reference.

## Develop

```bash
npm start                  # serves the folder at http://localhost:8080
npm install && npx playwright install chromium
npm test                   # same smoke test CI runs
npm run assets             # regenerate icons and splash screens (needs Python Playwright)
npm run check              # design docs check and its tests (no install needed)
```

No build step: `index.html` is one self-contained file.

## Repo map

```
index.html                  the app (HTML, CSS and JS in one file)
manifest.webmanifest        install metadata
sw.js                       offline cache
assets/icons/               icon.svg is the source; PNGs are generated
assets/splash/              iPhone launch images (closed cabinet doors)
variants/                   the earlier prototype, kept as it was
docs/design/                the design brain: map, rules card, protocol, packs, brand board
docs/reference/spread/      iOS reference documents forked unchanged from Spread
scripts/                    design docs checker and token generator
tests/smoke.cjs             CI smoke test
tools/generate_assets.py    icon and splash generator
.github/workflows/pages.yml test and deploy
```

## Earlier prototype

`variants/collection-demo.html` is the earlier all-in-one prototype from the first commit on `main` (add bottle, wear tracking, search, simulated authenticity check, blind-buy DNA matcher, shareable shelf image, Dynamic Island timer). It is kept as it was, served next to the app at `/variants/collection-demo.html`, and has no iOS install layer. Its authenticity result was a random number and its scent matcher printed fixed text, so those two were rebuilt rather than ported; see [the spec](docs/design/specs/2026-10-29-cabinet-features.md). Its search is not in the iOS build.

## Status

Tested in headless Chromium with an iPhone viewport and iOS user agent. It has not been run on a physical iPhone yet, so check Safari and the Home Screen install on a device, especially the status bar, the splash image, haptics, the keyboard over the Add panel, date pickers, and that a shelf built in a Safari tab is separate from the installed app's shelf.
