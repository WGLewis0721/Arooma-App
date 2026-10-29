# Arooma icon handoff

> Part of the Arooma design brain. Start at [../README.md](../README.md) for the map and the router. The icon concept and colors are in [BRAND_BOARD.md](BRAND_BOARD.md), section 5.

Which icon files exist, where they are used, and how they are made. Highest authority for icon files.

## Source and generated files

| File | Size | Used for |
| --- | --- | --- |
| `assets/icons/icon.svg` | vector, 1024 grid | Source of truth. Browser tab icon and the `any` manifest icon |
| `assets/icons/icon-1024.png` | 1024 | Master raster. Hand to a native project or App Store Connect |
| `assets/icons/icon-512.png`, `icon-192.png` | 512, 192 | Web manifest `any` icons |
| `assets/icons/icon-maskable-512.png` | 512 | Web manifest `maskable` icon. Same art; content sits inside the central 80% circle |
| `assets/icons/apple-touch-icon.png` | 180 | iOS Home Screen icon (iOS rounds the corners itself, so the art is a full square) |
| `assets/icons/favicon-32.png` | 32 | Browser tab fallback |
| `assets/splash/splash-*.png` | 11 iPhone sizes | iOS launch images: closed cabinet doors, so launch flows into the app's first screen |

Everything except `icon.svg` is generated. Do not edit the PNGs.

## Regenerating

Edit `assets/icons/icon.svg`, then `npm run assets` (Python Playwright and Chromium required). The script renders every PNG and every launch image. Launch image sizes are the portrait iPhone sizes listed in `tools/generate_assets.py`; the matching `<link rel="apple-touch-startup-image">` media queries are in `index.html`. Add a size in both places.

## Rules

- The icon is the doors parted around one neutral bottle. No text, no sparkle, no baked-in bevel, glass or highlight.
- No real house's bottle, label or logo.
- Keep the art full bleed and opaque; the system applies the corner mask.
- Do not add a second icon style. A dark or tinted variant follows the brand board and is made from the same SVG when a native project needs it.
- Launch images show the closed doors only, with no label text, because fonts differ between the generator and a phone.

## Owed

- A check of the Home Screen icon and a launch image on a physical iPhone.
- An Icon Composer layered version if the app goes native ([../DECISIONS.md](../DECISIONS.md)).
