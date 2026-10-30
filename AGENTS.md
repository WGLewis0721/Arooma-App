# Arooma: instructions for coding agents

For Codex, Cursor, Grok Build and any other tool that reads `AGENTS.md`.

Arooma is a personal cabinet for a fragrance collection, shipped as an installable iOS web app. The whole app is `index.html` (one self-contained file), tested and deployed to GitHub Pages by `.github/workflows/pages.yml`.

All design guidance lives in one place: **[docs/design/README.md](docs/design/README.md)**. The block below is generated from `docs/design/RULES_CARD.md` (`npm run docs:sync`); do not edit it here. Plans and specs follow [docs/design/PLAN_SPEC_PROTOCOL.md](docs/design/PLAN_SPEC_PROTOCOL.md). Setup for each AI tool: [docs/design/AI_TOOL_SETUP.md](docs/design/AI_TOOL_SETUP.md).

Commands: `npm start`, `npm run docs:check`, `npm test`, `npm run assets`.

<!-- design-rules-card:start -->
**Start here:** `docs/design/README.md` (router). Plans and specs: `docs/design/PLAN_SPEC_PROTOCOL.md`. Tokens as data: `docs/design/tokens.json`. Visual authority: `docs/design/brand/BRAND_BOARD.md`. Read the task pack the router names, then only the section it points to.

**Look**
- A personal cabinet of objects, not a storefront or an inventory dashboard. Bottles are the richest thing on screen.
- Use a token (`--oat`, `--paper`, `--ink`, `--soft`, `--hair`, `--olive`, `--olive-deep`, `--clay`, `--clay-deep`). Clay is the one accent, for a state that needs it. Two faces: `ui-serif` and SF Pro.
- Cards are opaque Paper. No glass, blur or transparency on cards, bottles or sheets. Glass only on the layout switcher, toolbar and header buttons.
- Drawn bottles share one studio light, table and baseline. An owner's own photo replaces the drawing, cropped to cover, never stretched.
- Olive and Clay are for graphics and large text; small text uses Olive Deep and Clay Deep. Status is never color alone.
- Low stock is quiet: label, hairline gauge, liquid level. Never red, never a badge.

**Behavior**
- Cover Flow browses the shelf, Stack is today's shortlist, Fan presents a saved rotation. The selected bottle persists across all three.
- Every drag has a tap and a keyboard path. Reduced motion means cross-fades only.
- Haptics only when they mean something: selection settle, wear, completed action, a timer check-in.
- The testing timer is an in-app aid, not a Dynamic Island integration. Widgets are today's pick plus one action.
- Say "Estimated remaining". Compare is overlap in entered notes. Authenticity notes are the owner's record, never verified.

**Boundaries**
- Demo houses are fictional and the demo never mixes with the owner's collection. Never draw a real brand's bottle, logo or label; never block an owner's own photo.
- Local-first: data stays on the device, backed up as a JSON file the owner keeps. No backend, account, analytics or network call without a spec.
- `index.html` stays one self-contained file. Generated assets come from `tools/generate_assets.py`.
- Never force-push `main`.

**Verify**
- Widths 375, 390, 430, the landscape prompt, reduced motion, no horizontal scroll.
- `npm run docs:check` and `npm test` are necessary, not sufficient. Device checks are owed: Home Screen install, status bar, launch image, haptics, share sheet.

**If a request seems to need something forbidden, list it as an exception for the owner to decide. Never design around a rule silently.**
<!-- design-rules-card:end -->
