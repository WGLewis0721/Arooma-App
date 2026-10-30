# Arooma: instructions for GitHub Copilot

Arooma is a personal cabinet for a fragrance collection, shipped as an installable iOS web app. The whole app is `index.html` (one self-contained file), tested and deployed to GitHub Pages by `.github/workflows/pages.yml`.

All design guidance lives in one place: **[docs/design/README.md](../docs/design/README.md)**. The block below is generated from `docs/design/RULES_CARD.md` (`npm run docs:sync`); do not edit it here. Plans and specs follow [docs/design/PLAN_SPEC_PROTOCOL.md](../docs/design/PLAN_SPEC_PROTOCOL.md). Setup for each AI tool: [docs/design/AI_TOOL_SETUP.md](../docs/design/AI_TOOL_SETUP.md).

<!-- design-rules-card:start -->
**Start here:** `docs/design/README.md` (router). Plans and specs: `docs/design/PLAN_SPEC_PROTOCOL.md`. Tokens as data: `docs/design/tokens.json`. Visual authority: `docs/design/brand/BRAND_BOARD.md`. Read the task pack the router names, then only the section it points to.

**Look**
- A personal cabinet of objects, not a storefront or an inventory dashboard. Bottles are the richest thing on screen.
- No new colors, fonts or decorative styles. Use a token (`--oat`, `--paper`, `--ink`, `--soft`, `--hair`, `--olive`, `--olive-deep`, `--clay`, `--clay-deep`) or an existing pattern. Two faces only: `ui-serif` and SF Pro.
- Cards are opaque Paper. No glass, blur or transparency on cards, bottles or sheets. Glass only on the layout switcher, toolbar and header buttons.
- Bottle art stays neutral and true to each house: same studio light and table, no per-house color grade, liquid drawn at the estimated level. The owner's own photos sit on the same table.
- Olive and Clay are for graphics and large text; small text uses Olive Deep and Clay Deep. Status is never color alone.
- Low stock is quiet: label, hairline gauge, liquid level. Never red, never a badge.

**Behavior**
- The selected bottle persists across Cover Flow, Stack and Fan. Layouts rearrange the same objects.
- Every drag has a tap and a keyboard path. Reduced motion means cross-fades only.
- Haptics at three moments only: selection settle, wear confirmation, completed action.
- The Island chip is an in-app timer for a testing session only. Widgets are today's pick plus one action, never a mini shelf.
- Remaining volume is an estimate and says so. Never claim authenticity is verified or a scent match is certain.

**Boundaries**
- Sample houses and bottles are fictional. Never draw a real brand's bottle, logo or label. The demo is labelled and stored apart from the owner's collection.
- No backend, account, analytics or network call without a spec.
- `index.html` stays one self-contained file. Generated assets come from `tools/generate_assets.py`.
- Never force-push `main`.

**Verify**
- Widths 375, 390, 430, the landscape prompt, reduced motion, no horizontal scroll.
- `npm run docs:check` and `npm test` are necessary, not sufficient. Device checks are owed: Home Screen install, status bar, launch image, haptics, share sheet.

**If a request seems to need something forbidden, list it as an exception for the owner to decide. Never design around a rule silently.**
<!-- design-rules-card:end -->
