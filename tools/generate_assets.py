#!/usr/bin/env python3
"""Regenerate the PNG icons and iOS splash screens.

Source of truth for the icon: assets/icons/icon.svg
Requires: pip install playwright && playwright install chromium
Run from the repo root: python3 tools/generate_assets.py
"""
import pathlib
from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parent.parent
ICON_SVG = (ROOT / 'assets/icons/icon.svg').read_text()

# name -> pixel size. The artwork is full bleed and its content sits inside the
# central 80% circle, so the same drawing serves as the maskable icon.
ICONS = {
    'icon-1024.png': 1024,
    'icon-512.png': 512,
    'icon-maskable-512.png': 512,
    'icon-192.png': 192,
    'apple-touch-icon.png': 180,
    'favicon-32.png': 32,
}

# (css width, css height, device pixel ratio) for portrait iPhones.
SPLASH = [
    (440, 956, 3), (430, 932, 3), (428, 926, 3), (402, 874, 3), (393, 852, 3),
    (390, 844, 3), (375, 812, 3), (414, 896, 3), (414, 896, 2), (414, 736, 3), (375, 667, 2),
]

SPLASH_HTML = """<!doctype html><meta charset="utf-8"><style>
html,body{margin:0;height:100%;background:#F2EDE4;overflow:hidden}
.d{position:absolute;top:0;bottom:0;width:50%;background:linear-gradient(180deg,#DAD1BF,#CDC3AE);box-shadow:inset 0 0 0 1px rgba(255,255,255,.35)}
.l{left:0;border-right:1px solid rgba(37,35,31,.28)}.r{right:0;border-left:1px solid rgba(37,35,31,.28)}
.d::before{content:"";position:absolute;inset:26px 20px 26px 24px;border:1px solid rgba(37,35,31,.14);box-shadow:inset 0 2px 8px rgba(37,35,31,.08),0 1px 0 rgba(255,255,255,.5)}
.r::before{inset:26px 24px 26px 20px}
.p{position:absolute;top:46%;width:5px;height:78px;border-radius:3px;background:linear-gradient(90deg,#4d503f,#8a8d74,#4d503f);box-shadow:0 3px 6px -2px rgba(37,35,31,.5)}
.l .p{right:17px}.r .p{left:17px}
</style><div class="d l"><i class="p"></i></div><div class="d r"><i class="p"></i></div>"""


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch()

        for name, size in ICONS.items():
            page = browser.new_page(viewport={'width': size, 'height': size}, device_scale_factor=1)
            page.set_content(
                '<body style="margin:0;background:#F2EDE4">'
                + ICON_SVG.replace('width="1024" height="1024"', f'width="{size}" height="{size}"')
                + '</body>'
            )
            page.screenshot(path=str(ROOT / 'assets/icons' / name))
            page.close()
            print('icon  ', name, size)

        for w, h, dpr in SPLASH:
            page = browser.new_page(viewport={'width': w, 'height': h}, device_scale_factor=dpr)
            page.set_content(SPLASH_HTML)
            out = ROOT / 'assets/splash' / f'splash-{w * dpr}x{h * dpr}.png'
            page.screenshot(path=str(out))
            page.close()
            print('splash', out.name)

        browser.close()


if __name__ == '__main__':
    main()
