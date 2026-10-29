'use strict';
/* Smoke test for the built site.
   Usage: node tests/smoke.cjs <site-dir> [screenshot-dir]
   Serves the folder on localhost, drives it with an iPhone-sized touch viewport,
   and exits non-zero if anything is broken. */
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const root = path.resolve(process.argv[2] || '.');
const outDir = path.resolve(process.argv[3] || 'artifacts');
fs.mkdirSync(outDir, { recursive: true });

const MIME = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.json': 'application/json',
  '.webmanifest': 'application/manifest+json', '.png': 'image/png', '.svg': 'image/svg+xml', '.css': 'text/css'
};
const server = http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p.endsWith('/')) p += 'index.html';
  const f = path.join(root, p);
  if (!f.startsWith(root) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); return res.end('not found'); }
  res.writeHead(200, { 'content-type': MIME[path.extname(f)] || 'application/octet-stream' });
  fs.createReadStream(f).pipe(res);
});

const failures = [];
function check(name, ok, detail) {
  console.log((ok ? 'PASS  ' : 'FAIL  ') + name + (detail ? '  (' + detail + ')' : ''));
  if (!ok) failures.push(name);
}

(async () => {
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = 'http://127.0.0.1:' + server.address().port + '/';
  const browser = await chromium.launch();

  // ---- iPhone-sized, touch, iOS user agent ----
  const ctx = await browser.newContext({
    viewport: { width: 393, height: 852 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true,
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1'
  });
  await ctx.addInitScript(() => {
    // Stand in for the iOS share sheet so the export path can be asserted.
    navigator.canShare = () => true;
    navigator.share = (d) => { window.__shared = { name: d.files[0].name, size: d.files[0].size, type: d.files[0].type }; return Promise.resolve(); };
  });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
  page.on('console', (m) => { if (m.type() === 'error') errors.push('console: ' + m.text()); });

  await page.goto(base);
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(outDir, '1-doors-closed.png') });
  check('doors are closed on first paint', await page.evaluate(() => !document.getElementById('cabinet').classList.contains('open')));

  await page.waitForTimeout(4600);
  await page.screenshot({ path: path.join(outDir, '2-cover-flow.png') });
  check('7 bottle cards rendered', (await page.locator('.slot').count()) === 7);
  check('cabinet opened and cleared', await page.evaluate(() => document.getElementById('cabinet').classList.contains('gone')));
  check('Cover Flow centers bottle 4', (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '3');
  check('low-stock card present', (await page.locator('.low').count()) === 1);

  // PWA wiring
  const manifest = await page.evaluate(async () => {
    const href = document.querySelector('link[rel="manifest"]').href;
    const m = await (await fetch(href)).json();
    const results = [];
    for (const i of m.icons) { const r = await fetch(new URL(i.src, href)); results.push([i.src, r.ok]); }
    return { name: m.name, display: m.display, icons: results };
  });
  check('manifest is standalone', manifest.display === 'standalone' && manifest.name === 'Arooma');
  check('manifest icons all resolve', manifest.icons.every((i) => i[1]), manifest.icons.map((i) => i[0].split('/').pop()).join(', '));
  const assets = await page.evaluate(async () => {
    const hrefs = [...document.querySelectorAll('link[rel="apple-touch-icon"],link[rel="apple-touch-startup-image"]')].map((l) => l.href);
    const out = [];
    for (const h of hrefs) { const r = await fetch(h); out.push(r.ok); }
    return out;
  });
  check('apple touch icon and ' + (assets.length - 1) + ' splash screens resolve', assets.length >= 12 && assets.every(Boolean));
  const sw = await page.evaluate(() => navigator.serviceWorker.ready.then((r) => !!r.active));
  check('service worker active', sw === true);

  if (fs.existsSync(path.join(root, 'variants/collection-demo.html'))) {
    const ok = await page.evaluate(async () => (await fetch('variants/collection-demo.html')).ok);
    check('earlier prototype is served under /variants', ok);
  }

  // layouts keep the selection
  await page.click('#seg button[data-mode="fan"]'); await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(outDir, '3-fan.png') });
  check('Fan keeps bottle 4 selected', (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '3');
  await page.click('#seg button[data-mode="stack"]'); await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(outDir, '4-stack.png') });
  check('Stack keeps bottle 4 selected', (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '3');
  await page.click('#seg button[data-mode="flow"]'); await page.waitForTimeout(900);

  // daily pick
  await page.click('#pick'); await page.waitForTimeout(1200);
  await page.screenshot({ path: path.join(outDir, '5-daily-pick.png') });
  check('Daily Pick tags exactly one card', (await page.locator('.slot.is-pick').count()) === 1);

  // island timer
  await page.click('#test'); await page.waitForTimeout(900);
  check('Island shows a running timer', (await page.getAttribute('#island', 'data-s')) === 'compact' && /^0:\d\d$/.test((await page.textContent('.i-time')).trim()));
  await page.screenshot({ path: path.join(outDir, '6-island.png') });
  await page.click('#island'); await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(outDir, '7-island-expanded.png') });
  await page.click('#iEnd'); await page.waitForTimeout(600);
  check('Island returns to idle', (await page.getAttribute('#island', 'data-s')) === 'idle');

  // install hint (iOS user agent, not standalone)
  check('Add to Home Screen hint shown on iOS Safari', await page.evaluate(() => document.getElementById('a2hs').classList.contains('show')));

  // share export
  await page.click('#share'); await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(outDir, '8-share-sheet.png') });
  await page.click('#saveImg'); await page.waitForTimeout(1200);
  const shared = await page.evaluate(() => window.__shared || null);
  check('share sheet receives a PNG', !!shared && shared.type === 'image/png' && shared.size > 20000, shared ? shared.size + ' bytes' : 'nothing shared');

  check('no console or page errors', errors.length === 0, errors.join(' | '));

  // ---- desktop frame ----
  const dctx = await browser.newContext({ viewport: { width: 1200, height: 900 } });
  const dpage = await dctx.newPage();
  const derrors = [];
  dpage.on('pageerror', (e) => derrors.push(e.message));
  await dpage.goto(base); await dpage.waitForTimeout(5200);
  await dpage.screenshot({ path: path.join(outDir, '9-desktop.png') });
  check('desktop shows the framed device', (await dpage.locator('.slot').count()) === 7 && derrors.length === 0, derrors.join(' | '));

  await browser.close();
  server.close();
  if (failures.length) { console.error('\n' + failures.length + ' check(s) failed'); process.exit(1); }
  console.log('\nAll checks passed');
})().catch((e) => { console.error(e); process.exit(1); });
