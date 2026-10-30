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
| First open | Two cabinet doors swing open. The first time, you choose **Start my collection** (empty) or **Explore the demo** (seven fictional bottles, labeled Demo). The two are saved apart and never mix. Cabinet menu, then Replay the cabinet doors, plays the doors again. |
| Shelves | The cabinet opens on the Autumn shelf. **Pinch in** (or tap the grid button in the header, or press `-`) to zoom out to every shelf: Spring, Summer, Autumn and Winter by default. Each has a **pencil** to rename it, and **Add a shelf** sits at the bottom. Pinch out over a shelf, tap it, or press Escape to go back in; the selected bottle stays selected. Move a bottle between shelves from the three dots under the card. |
| Shelf | Swipe, tap a neighbor, or use arrow keys. Tap the centered card to flip it to its ownership record, with recent wears. The pencil on the selected card edits it. An empty shelf says so and offers Add a bottle. |
| Liquid | Every drawn bottle shows its liquid at the estimated level. The surface sloshes with momentum when you swipe, ripples in the direction the card moves and stays level with the room when cards lean. With Reduce Motion it stays flat. A bottle with your own photo shows the photo instead. |
| Layouts | Cover Flow browses the shelf. Stack is today's shortlist (five candidates plus the selected bottle). Fan presents a saved rotation of up to five bottles; with none saved, Fan offers to make one (Cabinet menu, Rotations). The selected bottle stays selected in all three. |
| Daily Pick | Brings the next candidate forward with an olive outline and a "Today's pick" tab. |
| Low stock | Salt Cedar: the liquid level drops, and a quiet "Running low" label with a hairline gauge. Always labeled as an estimate. |
| Add, edit, delete | The plus button adds a bottle: house, fragrance, size, estimated remaining, notes, acquired date, a neutral vessel or **your own photo** (zoom and position, never stretched). Any bottle can be deleted, including the last one and demo samples, with Undo. Up to 150 bottles. |
| Wear tracking | Wear today logs the date in one tap. **Add how it wore today** is optional: opening, development, projection, longevity, a note. Wear history lists every wear with its impression. Daily Pick cites your history ("You haven't worn this in 5 weeks"). |
| Authenticity notes | Five observations per bottle: Matches, Differs or Not checked. Your own record, with no scan or lookup; it never says a bottle is authentic. |
| Compare before buying | Cabinet menu, Compare notes. Type the notes of a bottle you are considering and see the three closest bottles you own by overlap in listed notes, with an eight-family radar. It does not predict how a scent wears on you. |
| Test timer | An in-app testing aid, not a Dynamic Island integration. Counts to check-ins at 15 minutes, 1 hour and 3 hours; a due check-in offers Log impression. |
| Shelf image | Cabinet menu, then Share shelf image, builds an editorial 1080 x 1350 image of up to eight bottles with no app chrome and opens the iOS share sheet (Save Image, Messages, AirDrop). |
| Find, back up, restore | Cabinet menu, or `/` for Find (house or fragrance, any shelf). Back up my collection saves a JSON file of everything; Restore reviews a file and asks to add or replace. Data lives on this device, in this browser only; the menu shows the last backup date. Clear my collection and Explore or Reset the demo each confirm first. |

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
2. Runs `tests/smoke.cjs` in a headless browser at an iPhone viewport: doors, 7 cards, layouts keep the selection, Daily Pick, Island timer, manifest and icons resolve, service worker active, share image export, then pinch to every shelf (touch, trackpad and Safari gestures), rename, add a shelf, move a bottle, liquid level and motion, then add, delete with Undo, wear history, the evidence checklist, compare, reload persistence, damaged storage, a one-bottle shelf and a 375 by 667 phone, with no console errors. Screenshots are kept as a build artifact.
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

Tested in headless Chromium with an iPhone viewport and iOS user agent. It has not been run on a physical iPhone yet, so check Safari and the Home Screen install on a device, especially the status bar, the splash image, haptics, the two-finger pinch (and that the page itself does not zoom), the liquid's feel and frame rate, the keyboard over the Add panel, date pickers, and that a shelf built in a Safari tab is separate from the installed app's shelf.
