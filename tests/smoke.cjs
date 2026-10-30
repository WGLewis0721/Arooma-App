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
    navigator.share = (d) => { const f = d.files[0]; window.__shared = { name: f.name, size: f.size, type: f.type }; if (/json/.test(f.type)) return f.text().then((t) => { window.__sharedText = t; }); return Promise.resolve(); };
  });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
  page.on('console', (m) => { if (m.type() === 'error') errors.push('console: ' + m.text()); });
  const offsite = [];
  page.on('request', (r) => { const u = r.url(); if (/^https?:/.test(u) && !u.startsWith(base)) offsite.push(u); });

  await page.goto(base);
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(outDir, '1-doors-closed.png') });
  check('doors are closed on first paint', await page.evaluate(() => !document.getElementById('cabinet').classList.contains('open')));

  await page.waitForTimeout(4600);
  await page.screenshot({ path: path.join(outDir, '2-cover-flow.png') });
  check('cabinet opened and cleared', await page.evaluate(() => document.getElementById('cabinet').classList.contains('gone')));
  // FR-1: the first run offers a choice and puts no sample bottle on the shelf
  check('FR-1 first run shows no bottles and offers Start my collection or Explore demo', (await page.locator('.slot').count()) === 0 && await page.isVisible('[data-er="start"]') && await page.isVisible('[data-er="demo"]'));
  check('FR-1 nothing is saved before the choice', await page.evaluate(() => ['arooma.cabinet', 'arooma.demo', 'arooma.prefs', 'arooma.v1'].every((k) => localStorage.getItem(k) === null)));
  await page.screenshot({ path: path.join(outDir, '2a-first-run.png') });
  await page.click('[data-er="demo"]'); await page.waitForTimeout(1600);
  check('7 bottle cards rendered', (await page.locator('.slot').count()) === 7);
  check('FR-2 the demo is labelled as the demo', /^Demo/.test((await page.textContent('#eyebrow')).trim()));
  check('Cover Flow opens on Fig Hour, 02 of 05 on the Autumn shelf', (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '2' && (await page.textContent('#cap')).trim() === '02 / 05' && (await page.textContent('#title')) === 'Autumn shelf');
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
  check('Fan keeps Fig Hour selected', (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '2');
  await page.click('#seg button[data-mode="stack"]'); await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(outDir, '4-stack.png') });
  check('Stack keeps Fig Hour selected', (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '2');
  await page.click('#seg button[data-mode="flow"]'); await page.waitForTimeout(900);

  // daily pick
  await page.click('#pick'); await page.waitForTimeout(1200);
  await page.screenshot({ path: path.join(outDir, '5-daily-pick.png') });
  check('Daily Pick tags exactly one card', (await page.locator('.slot.is-pick').count()) === 1);

  // island timer
  await page.click('#test'); await page.waitForTimeout(900);
  check('Island shows a running timer', (await page.getAttribute('#island', 'data-s')) === 'compact' && /^\d{1,2}:\d\d$/.test((await page.textContent('.i-time')).trim()), await page.textContent('.i-time'));
  await page.screenshot({ path: path.join(outDir, '6-island.png') });
  await page.click('#island'); await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(outDir, '7-island-expanded.png') });
  await page.click('#iEnd'); await page.waitForTimeout(600);
  check('Island returns to idle', (await page.getAttribute('#island', 'data-s')) === 'idle');

  // install hint (iOS user agent, not standalone)
  check('Add to Home Screen hint shown on iOS Safari', await page.evaluate(() => document.getElementById('a2hs').classList.contains('show')));

  // share export (reached from the cabinet menu)
  await page.click('#menu'); await page.waitForSelector('#panel.on');
  await page.click('#share'); await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(outDir, '8-share-sheet.png') });
  await page.click('#saveImg'); await page.waitForTimeout(1200);
  const shared = await page.evaluate(() => window.__shared || null);
  check('share sheet receives a PNG', !!shared && shared.type === 'image/png' && shared.size > 20000, shared ? shared.size + ' bytes' : 'nothing shared');


  // ================= cabinet features: wear, authenticity, compare, add, delete, persistence =================
  const reopenFast = async (p) => {
    await p.reload(); await p.waitForTimeout(300);
    await p.evaluate(() => document.getElementById('cabinet').click()); await p.waitForTimeout(2300);
  };
  const stored = () => page.evaluate(() => JSON.parse(localStorage.getItem('arooma.demo') || 'null'));
  const panelOn = () => page.evaluate(() => document.getElementById('panel').classList.contains('on'));
  const closePanel = async () => { await page.click('#scrim', { position: { x: 20, y: 20 } }); await page.waitForTimeout(800); };
  await page.click('#closeSheet'); await page.waitForTimeout(800);
  await reopenFast(page);
  check('fresh load has no saved data until something changes', (await stored()) === null);

  // full wear tracking
  const wearBtn = '#wear';
  const before = await page.evaluate(() => document.getElementById('meta').textContent);
  await page.click(wearBtn); await page.waitForTimeout(500);
  check('Wear today disables and reads Worn today', (await page.textContent(wearBtn)).includes('Worn today') && await page.isDisabled(wearBtn));
  check('wear is saved with today’s date', await page.evaluate(() => { const d = JSON.parse(localStorage.getItem('arooma.demo')); const t = new Date(); const ymd = t.getFullYear() + '-' + String(t.getMonth() + 1).padStart(2, '0') + '-' + String(t.getDate()).padStart(2, '0'); return d.bottles.some((b) => b.log[0] === ymd); }));
  check('wear toast offers Undo', await page.locator('.toast.on .tact').count() === 1);
  await page.click('.toast.on .tact'); await page.waitForTimeout(500);
  check('Undo restores Wear today', (await page.textContent(wearBtn)).trim() === 'Wear today' && !(await page.isDisabled(wearBtn)));
  await page.click(wearBtn); await page.waitForTimeout(400);

  // wear history: add a dated wear, reject a future date and a duplicate, remove one
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#history'); await page.waitForTimeout(300);
  const rows0 = await page.locator('.hrow').count();
  const wearsNow = async () => +(/Worn (\d+) time/.exec(await page.textContent('#panelBody .sub')) || [0, 0])[1];
  const w0 = await wearsNow();
  const d3 = await page.evaluate(() => { const t = new Date(Date.now() - 3 * 864e5); return t.getFullYear() + '-' + String(t.getMonth() + 1).padStart(2, '0') + '-' + String(t.getDate()).padStart(2, '0'); });
  await page.fill('#hDate', d3); await page.click('[data-act="addw"]'); await page.waitForTimeout(300);
  check('history adds a dated wear', (await wearsNow()) === w0 + 1);
  await page.fill('#hDate', d3); await page.click('[data-act="addw"]'); await page.waitForTimeout(200);
  check('history rejects a duplicate date', /already logged/.test(await page.textContent('#hErr')));
  await page.evaluate(() => { const i = document.getElementById('hDate'); i.removeAttribute('max'); });
  await page.fill('#hDate', '2099-01-01'); await page.click('[data-act="addw"]'); await page.waitForTimeout(200);
  check('history rejects a future date', /not in the future/.test(await page.textContent('#hErr')));
  await page.click('[data-del="' + d3 + '"]'); await page.waitForTimeout(300);
  check('history removes a wear', (await wearsNow()) === w0);
  await page.screenshot({ path: path.join(outDir, '10-wear-history.png') });
  await page.click('#panel [data-act="cancel"]'); await page.waitForTimeout(800);

  // authenticity: an evidence checklist that never claims verification
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#auth'); await page.waitForTimeout(300);
  check('authenticity panel says it cannot verify', /cannot verify authenticity/.test(await page.textContent('#panelBody')));
  const btns = page.locator('.seg3 button[data-val="1"]');
  for (let k = 0; k < 5; k++) await btns.nth(k).click();
  const res = await page.textContent('#aRes');
  check('five matches read consistent, not authentic', /Consistent on all 5 details/.test(res) && /does not verify authenticity/.test(res) && !/\bis authentic\b|\bgenuine\b|\bverified\b/i.test(res), res.slice(0, 80));
  await page.locator('.seg3 button[data-val="2"]').nth(2).click();
  check('one difference is reported without a verdict', /Differs on 1 of 5/.test(await page.textContent('#aRes')) && /not a verdict/.test(await page.textContent('#aRes')));
  await page.locator('.seg3 button[data-val="1"]').nth(2).click();
  await page.screenshot({ path: path.join(outDir, '11-authenticity.png') });
  await page.click('[data-act="saveA"]'); await page.waitForTimeout(900);
  check('evidence lands on the ownership record', await page.evaluate(() => /5 of 5 consistent/.test(document.querySelector('.slot[tabindex="0"] .rec-dl').textContent)));
  check('WO-3 the record calls it your checks, never verified', await page.evaluate(() => /Your checks/.test(document.querySelector('.slot[tabindex="0"] .rec-dl').textContent) && !/verified/i.test(document.querySelector('.slot[tabindex="0"] .rec-dl').textContent)));

  // compare before buying: overlap in listed notes
  await page.click('#menu'); await page.waitForSelector('#panel.on'); await page.click('#compare'); await page.waitForTimeout(300);
  await page.fill('#cNotes', 'fig leaf, cedar, vanilla'); await page.waitForTimeout(200);
  check('compare ranks the three closest bottles', (await page.locator('#cRes .cmp .prow').count()) === 3);
  check('compare puts Fig Hour first for fig leaf and cedar', /Fig Hour/.test(await page.textContent('#cRes .cmp .prow')));
  const cmpTxt = await page.textContent('#cRes');
  check('compare says overlap and listed notes, never a promise', /overlap/i.test(cmpTxt) && /listed notes only/.test(cmpTxt) && !/perfect match|you will love|guaranteed/i.test(cmpTxt));
  check('compare draws a radar chart', (await page.locator('#cRes svg.radar').count()) === 1);
  await page.screenshot({ path: path.join(outDir, '12-compare.png') });
  await page.fill('#cNotes', 'zzzz qqqq'); await page.waitForTimeout(150);
  check('compare admits when no notes are recognized', /No notes recognized/.test(await page.textContent('#cRes')));
  await page.click('#panel [data-act="cancel"]'); await page.waitForTimeout(800);

  // add a bottle
  const n0 = await page.locator('.slot').count();
  await page.click('#addBtn'); await page.waitForSelector('#panel.on');
  await page.screenshot({ path: path.join(outDir, '13-add-bottle.png') });
  await page.click('[data-act="save"]'); await page.waitForTimeout(200);
  check('add requires a house and a name', /house and the fragrance/.test(await page.textContent('#fErr')) && (await page.locator('.slot').count()) === n0);
  await page.fill('#fHouse', 'Test House'); await page.fill('#fName', 'Test Scent'); await page.fill('#fNotes', 'cedar, amber, vanilla');
  await page.click('.vopt[data-v="green"]'); await page.fill('#fNote', 'Bought at the market.');
  await page.click('[data-act="save"]'); await page.waitForTimeout(1500);
  check('added bottle appears and is selected', (await page.locator('.slot').count()) === n0 + 1 && (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === String(n0));
  check('eyebrow and door count follow the shelf', /08 objects/.test(await page.textContent('#eyebrow')));
  check('added bottle is saved on this device', await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.demo')).bottles.some((b) => b.name === 'Test Scent' && b.vessel === 'green' && b.sample === false)));
  await page.screenshot({ path: path.join(outDir, '14-added.png') });
  await page.click('.slot[tabindex="0"]'); await page.waitForTimeout(1100);
  check('record shows the user’s note', await page.evaluate(() => /Bought at the market/.test(document.querySelector('.slot[tabindex="0"] .rec-n').textContent)));
  await page.click('.slot[tabindex="0"]'); await page.waitForTimeout(900);

  // layouts and share with 8 bottles
  await page.click('#seg button[data-mode="fan"]'); await page.waitForTimeout(1000);
  check('Fan keeps the new bottle selected', (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === String(n0));
  await page.click('#seg button[data-mode="stack"]'); await page.waitForTimeout(1000);
  check('Stack handles more than seven bottles', (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === String(n0) && errors.length === 0);
  await page.screenshot({ path: path.join(outDir, '15-stack-eight.png') });
  await page.click('#seg button[data-mode="flow"]'); await page.waitForTimeout(900);
  await page.evaluate(() => { window.__shared = null; });
  await page.click('#menu'); await page.waitForSelector('#panel.on'); await page.click('#share'); await page.waitForTimeout(1800);
  check('shelf image draws the six bottles on the Autumn shelf and is titled by it', (await page.locator('#ed figure').count()) === 6 && /Six objects/.test(await page.textContent('#ed')) && /Autumn shelf/.test(await page.textContent('#ed')));
  await page.screenshot({ path: path.join(outDir, '16-share-eight.png') });
  await page.click('#saveImg'); await page.waitForTimeout(1500);
  check('share still receives a PNG for the shelf', await page.evaluate(() => !!window.__shared && window.__shared.size > 20000));
  await page.click('#closeSheet'); await page.waitForTimeout(800);

  // persistence across reloads
  await reopenFast(page);
  check('shelf, wear and evidence survive a reload', (await page.locator('.slot').count()) === 8 && await page.evaluate(() => { const d = JSON.parse(localStorage.getItem('arooma.demo')); return d.bottles.some((b) => b.auth && b.auth.v.every((x) => x === 1)) && d.bottles.some((b) => b.log.length > 0); }));

  // delete with undo
  await page.focus('#stage'); for (let k = 0; k < 4; k++) await page.keyboard.press('ArrowRight');
  await page.waitForTimeout(900);
  check('keyboard reaches the added bottle', (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '7');
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#del'); await page.waitForTimeout(300);
  check('delete asks first', /Delete Test Scent\?/.test(await page.textContent('#panelBody')));
  await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('delete removes the bottle', (await page.locator('.slot').count()) === 7 && /07 objects/.test(await page.textContent('#eyebrow')));
  check('delete is saved', await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.demo')).bottles.length === 7));
  await page.screenshot({ path: path.join(outDir, '17-deleted-undo.png') });
  await page.click('.toast.on .tact'); await page.waitForTimeout(900);
  check('Undo puts the bottle back where it was', (await page.locator('.slot').count()) === 8 && (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '7');
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#del'); await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('numbers restart on each shelf and stay in sequence after a delete', await page.evaluate(() => [...document.querySelectorAll('.slot')].sort((a, b) => a.dataset.i - b.dataset.i).map((el) => el.querySelector('.num').textContent.trim()).join('|') === ['01', '01', '02', '01', '03', '04', '05'].map((n) => 'N° ' + n).join('|')));

  // reset
  await page.click('#menu'); await page.waitForSelector('#panel.on'); await page.click('#reset'); await page.waitForTimeout(300);
  await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('reset restores the seven sample bottles', (await page.locator('.slot').count()) === 7 && (await stored()) === null);


  // ================= shelves: overview, pinch, rename, add shelf, move a bottle =================
  const zval = () => page.evaluate(() => parseFloat(getComputedStyle(document.getElementById('device')).getPropertyValue('--z')));
  const ttl = () => page.textContent('#title');
  const cdp = await ctx.newCDPSession(page);
  const pinch = async (cy, from, to, steps = 8) => {
    const pts = (d) => [{ x: 196 - d / 2, y: cy, id: 1 }, { x: 196 + d / 2, y: cy, id: 2 }];
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: pts(from) });
    for (let i = 1; i <= steps; i++) { await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: pts(from + (to - from) * i / steps) }); await page.waitForTimeout(25); }
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await page.waitForTimeout(800);
  };
  const shelfY = (id) => page.evaluate((i) => { const r = document.querySelector('.shelf[data-id="' + i + '"]').getBoundingClientRect(); return r.top + r.height / 2; }, id);
  const wheel = (dy, n, x, y) => page.evaluate(([dy, n, x, y]) => { const d = document.getElementById('device'); for (let i = 0; i < n; i++) d.dispatchEvent(new WheelEvent('wheel', { ctrlKey: true, deltaY: dy, clientX: x, clientY: y, bubbles: true, cancelable: true })); }, [dy, n, x, y]);
  const gest = (scale, y = 420) => page.evaluate(([sc, yy]) => { const d = document.getElementById('device'); const mk = (t, s) => { const e = new Event(t, { bubbles: true, cancelable: true }); e.scale = s; e.clientX = 196; e.clientY = yy; return e; }; d.dispatchEvent(mk('gesturestart', 1)); d.dispatchEvent(mk('gesturechange', sc)); d.dispatchEvent(mk('gestureend', sc)); }, [scale, y]);

  await pinch(420, 200, 70);
  check('pinching in zooms out to all shelves', (await zval()) > .98 && (await ttl()) === 'All shelves' && (await page.locator('.shelf').count()) === 4, 'z=' + (await zval()));
  check('every shelf shows its pencil, named for the shelf', await page.evaluate(() => [...document.querySelectorAll('.pen')].map((b) => b.getAttribute('aria-label')).join('|') === 'Rename Spring shelf|Rename Summer shelf|Rename Autumn shelf|Rename Winter shelf'));
  check('seasons are the default shelf names and the empty one says so', await page.evaluate(() => [...document.querySelectorAll('.sname')].map((b) => b.textContent).join('|') === 'Spring shelf|Summer shelf|Autumn shelf|Winter shelf' && /Nothing here yet/.test(document.querySelector('.shelf[data-id="wi"]').textContent)));
  check('the overview shows every bottle, with the selected one marked', (await page.locator('.mb').count()) === 7 && (await page.locator('.mb.is-sel').count()) === 1 && await page.evaluate(() => document.querySelector('.mb.is-sel').getAttribute('data-b') === '2'));
  await page.screenshot({ path: path.join(outDir, '21-all-shelves.png') });
  await pinch(await shelfY('au'), 80, 260);
  check('pinching out over a shelf opens it with the same bottle selected', (await zval()) < .02 && (await ttl()) === 'Autumn shelf' && (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '2');
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  await pinch(await shelfY('sp'), 80, 260);
  check('pinching out over another shelf opens that shelf', (await ttl()) === 'Spring shelf' && (await page.textContent('#cap')).trim() === '01 / 01' && (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '3');
  await page.keyboard.press('-'); await page.waitForTimeout(900);
  check('the - key opens the overview', (await zval()) > .98);
  await page.keyboard.press('Escape'); await page.waitForTimeout(900);
  check('Escape closes the overview', (await zval()) < .02 && (await ttl()) === 'Spring shelf');
  await wheel(40, 10, 196, 420); await page.waitForTimeout(900);
  check('a trackpad pinch (ctrl and wheel) zooms out', (await zval()) > .98);
  await wheel(-40, 14, 196, await shelfY('au')); await page.waitForTimeout(900);
  check('a trackpad pinch opens the shelf under the cursor', (await zval()) < .02 && (await ttl()) === 'Autumn shelf');
  await gest(.45); await page.waitForTimeout(800);
  check('a WebKit gesture pinch (Safari) zooms out', (await zval()) > .98);
  await gest(2.4, await shelfY('au')); await page.waitForTimeout(800);
  check('and back in, onto the shelf under the fingers', (await zval()) < .02 && (await ttl()) === 'Autumn shelf');
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  check('the Shelves button opens the overview', (await zval()) > .98 && (await page.getAttribute('#shelvesBtn', 'aria-pressed')) === 'true');
  await page.click('#openShelf'); await page.waitForTimeout(900);
  check('Open shelf returns to the shelf', (await zval()) < .02 && (await ttl()) === 'Autumn shelf');

  // rename with the pencil
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  await page.click('.pen[data-pen="su"]'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(300);
  await page.fill('#shName', ''); await page.click('[data-act="save"]');
  check('a shelf needs a name', /Give the shelf a name/.test(await page.textContent('#shErr')));
  await page.fill('#shName', 'Weekend rotation'); await page.click('[data-act="save"]'); await page.waitForTimeout(800);
  check('rename shows in the overview and is saved', (await page.textContent('.shelf[data-id="su"] .sname')) === 'Weekend rotation' && await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.demo')).shelves.some((h) => h.id === 'su' && h.name === 'Weekend rotation')));
  await page.click('.sname[data-open="su"]'); await page.waitForTimeout(900);
  check('the renamed shelf titles its own view', (await ttl()) === 'Weekend rotation' && (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '0');
  await page.screenshot({ path: path.join(outDir, '22-renamed-shelf.png') });

  // add a shelf in the zoomed-out view, then put a bottle on it
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  await page.click('#addShelf'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(300);
  await page.click('[data-act="save"]');
  check('a new shelf needs a name', /Give the shelf a name/.test(await page.textContent('#nsErr')));
  await page.fill('#nsName', 'Evenings'); await page.click('[data-act="save"]'); await page.waitForTimeout(900);
  check('a new shelf appears in the overview, empty, and is saved', (await page.locator('.shelf').count()) === 5 && (await page.textContent('.shelf:last-child .sname')) === 'Evenings' && /Nothing here yet/.test(await page.textContent('.shelf:last-child')) && await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.demo')).shelves.length === 5));
  await page.screenshot({ path: path.join(outDir, '23-new-shelf.png') });
  await page.click('.shelf:last-child .sh-add'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(300);
  check('Add a bottle on an empty shelf preselects that shelf', (await page.evaluate(() => document.getElementById('fShelf').selectedOptions[0].textContent)) === 'Evenings');
  await page.fill('#fHouse', 'Shelf House'); await page.fill('#fName', 'Late Hour'); await page.click('[data-act="save"]'); await page.waitForTimeout(1200);
  check('the bottle lands on the new shelf', await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.demo')).bottles.some((b) => b.name === 'Late Hour' && b.shelf !== 'au')) && (await page.locator('.shelf:last-child .mb').count()) === 1);
  await page.click('#openShelf'); await page.waitForTimeout(900);
  check('opening it shows a one-bottle shelf', (await ttl()) === 'Evenings' && (await page.textContent('#cap')).trim() === '01 / 01');

  // move a bottle to another shelf; Undo moves it back
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#move'); await page.waitForTimeout(300);
  await page.click('[data-sh="au"]'); await page.waitForTimeout(1100);
  check('Move puts the bottle on the other shelf and follows it', (await ttl()) === 'Autumn shelf' && (await page.textContent('#cap')).trim() === '06 / 06');
  await page.click('.toast.on .tact'); await page.waitForTimeout(1100);
  check('Undo moves it back', (await ttl()) === 'Evenings' && (await page.textContent('#cap')).trim() === '01 / 01');
  // an empty shelf can be removed, with Undo
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#move'); await page.click('[data-sh="au"]'); await page.waitForTimeout(1100);
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  const evId = await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.demo')).shelves.find((h) => h.name === 'Evenings').id);
  await page.click('.pen[data-pen="' + evId + '"]'); await page.waitForSelector('#panel.on');
  await page.click('#rmShelf'); await page.waitForTimeout(800);
  check('an empty shelf can be removed', (await page.locator('.shelf').count()) === 4);
  await page.click('.toast.on .tact'); await page.waitForTimeout(600);
  check('and Undo brings it back', (await page.locator('.shelf').count()) === 5);
  await page.click('#openShelf'); await page.waitForTimeout(900);

  // ================= liquid: always visible, truthful at rest, alive in motion =================
  const surf = (q) => page.evaluate((sel) => { const d = document.querySelector(sel).getAttribute('d'); const m = d.match(/^M([\d.]+) ([\d.]+)L.*L([\d.]+) ([\d.]+)V/); return m ? [+m[2], +m[4]] : null; }, q);
  check('every bottle on the shelf has liquid', await page.evaluate(() => [...document.querySelectorAll('.slot')].every((el) => el.querySelector('.lq'))));
  check('the three opaque vessels show their liquid through a level window', await page.evaluate(() => ['1', '3', '6'].every((i) => { const el = document.querySelector('.slot[data-i="' + i + '"]'); const g = el.querySelector('.lq').parentNode; return /w\)$/.test(g.getAttribute('clip-path') || '') && el.querySelector('clipPath rect').getAttribute('width') === '12'; })));
  const y0 = (i) => page.evaluate((k) => +document.querySelector('.slot[data-i="' + k + '"] .lq').getAttribute('data-y0'), i);
  const lv = [[2, 145.3, 'Fig Hour 85%'], [4, 202.04, 'Salt Cedar 14%'], [0, 127.08, 'Linen Rain 78%'], [1, 171.7, 'Ink No. 4 55% in its window'], [3, 143.4, 'Milk Paper 70% in its window'], [6, 157.8, 'Dry Earth 90% in its window']];
  for (const [i, want, name] of lv) check('liquid level is true at rest: ' + name, Math.abs((await y0(i)) - want) < .05, 'y0=' + (await y0(i)));
  const idle = [];
  await page.focus('#stage'); while ((await page.getAttribute('.slot[tabindex="0"]', 'data-i')) !== '2') { await page.keyboard.press('ArrowLeft'); await page.waitForTimeout(450); }
  await page.waitForTimeout(2500);
  for (let k = 0; k < 6; k++) { const v = await surf('.slot[tabindex="0"] .lq'); idle.push(Math.abs(v[0] - v[1])); await page.waitForTimeout(260); }
  const d1 = await page.getAttribute('.slot[tabindex="0"] .lq', 'd'); await page.waitForTimeout(350);
  check('a bottle at rest still ripples gently', d1 !== await page.getAttribute('.slot[tabindex="0"] .lq', 'd') && Math.max(...idle) < 4, 'idle tilt max ' + Math.max(...idle).toFixed(1));
  await page.mouse.move(300, 420); await page.mouse.down();
  for (let i = 1; i <= 8; i++) { await page.mouse.move(300 - i * 14, 420); await page.waitForTimeout(12); }
  await page.mouse.up();
  const peak = [];
  for (let k = 0; k < 14; k++) { await page.waitForTimeout(45); const v = await surf('.slot[tabindex="0"] .lq'); peak.push(v[0] - v[1]); }
  check('a swipe sloshes the liquid, with momentum: it tilts one way then the other', Math.max(...peak) > 3 && Math.min(...peak) < -3, 'tilt range ' + Math.min(...peak).toFixed(1) + ' to ' + Math.max(...peak).toFixed(1));
  await page.waitForTimeout(3000);
  const calm = []; for (let k = 0; k < 5; k++) { const v = await surf('.slot[tabindex="0"] .lq'); calm.push(Math.abs(v[0] - v[1])); await page.waitForTimeout(200); }
  check('it settles back to a gentle ripple', Math.max(...calm) < 4, 'max ' + Math.max(...calm).toFixed(1));
  // Fan: cards lean, the liquid stays level with the room
  while ((await page.getAttribute('.slot[tabindex="0"]', 'data-i')) !== '1') { await page.keyboard.press('ArrowLeft'); await page.waitForTimeout(450); }
  await page.click('#seg button[data-mode="fan"]'); await page.waitForTimeout(3600);
  const fanTilt = await surf('.slot[data-i="5"] .lq');
  check('in Fan the leaning cards keep their liquid level with the room', Math.abs(fanTilt[0] - fanTilt[1]) > 12, 'edge difference ' + Math.abs(fanTilt[0] - fanTilt[1]).toFixed(1));
  await page.screenshot({ path: path.join(outDir, '24-fan-liquid.png') });
  await page.click('#seg button[data-mode="flow"]'); await page.waitForTimeout(1200);

  // ================= FR-6 migration and damaged storage: never break, never delete the old save =================
  const fresh = async (kv) => { await page.evaluate((o) => { localStorage.clear(); for (const k in o) localStorage.setItem(k, o[k]); }, kv || {}); await reopenFast(page); };
  const own = () => page.evaluate(() => JSON.parse(localStorage.getItem('arooma.cabinet') || 'null'));
  const demoSaved = () => page.evaluate(() => JSON.parse(localStorage.getItem('arooma.demo') || 'null'));
  for (const [label, value] of [['malformed JSON', '{bad'], ['wrong shape', JSON.stringify({ v: 1, bottles: 'x' })]]) {
    await fresh({ 'arooma.v1': value });
    check('survives ' + label + ': first run is offered and the old save is left as it was', (await page.locator('.slot').count()) === 0 && await page.isVisible('[data-er="start"]') && (await page.evaluate(() => localStorage.getItem('arooma.v1'))) === value && errors.length === 0, errors.join(' | '));
  }
  const hostile = JSON.stringify({ v: 1, bottles: [{ id: 'a1', house: '<img src=x onerror=window.__xss=1>', name: '<b>x</b>', vessel: 'nope', log: ['x', '2026-02-30x', '2026-03-01'] }, { id: 'a2', house: 'H', name: 'N' }, { id: 'a3', house: 'H', name: 'N3' }] });
  await fresh({ 'arooma.v1': hostile });
  check('survives markup in a name', (await page.locator('.slot').count()) === 3 && !(await page.evaluate(() => window.__xss === 1)) && errors.length === 0, errors.join(' | '));
  check('markup in saved text is shown as text', await page.evaluate(() => document.querySelector('.slot .house').textContent.includes('<img')));
  check('FR-6 a v1 save migrates to schema v3 in my collection, and the old key is kept untouched', await page.evaluate((h) => { const c = JSON.parse(localStorage.getItem('arooma.cabinet')); return c.v === 3 && c.bottles.length === 3 && localStorage.getItem('arooma.v1') === h && JSON.parse(localStorage.getItem('arooma.prefs')).mode === 'own'; }, hostile));

  // a v1 save moves to the Autumn shelf; a v2 save with an unknown shelf falls back; shelf names are text
  await fresh({ 'arooma.v1': JSON.stringify({ v: 1, bottles: [{ id: 'm1', house: 'Old House', name: 'Old One' }, { id: 'm2', house: 'Old House', name: 'Old Two' }, { id: 'm3', house: 'Old House', name: 'Old Three' }] }) });
  check('a v1 save migrates onto the Autumn shelf', (await ttl()) === 'Autumn shelf' && (await page.textContent('#cap')).trim().endsWith('/ 03'));
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  check('a migrated save gets the four seasons', (await page.locator('.shelf').count()) === 4);
  await page.keyboard.press('Escape'); await page.waitForTimeout(800);
  await page.click('#wear'); await page.waitForTimeout(400); await reopenFast(page);
  check('FR-6 migration runs once: a later change is not overwritten by the old save', (await page.textContent('#wear')).includes('Worn today'));
  await fresh({ 'arooma.v1': JSON.stringify({ v: 2, shelves: [{ id: 'x1', name: '<img src=x onerror=window.__xss=2>' }, { id: 'x2', name: 'Second' }, { id: 'x1', name: 'Dup' }, { id: '', name: 'No id' }], bottles: [{ id: 'b1', shelf: 'x2', house: 'H', name: 'N1' }, { id: 'b2', shelf: 'gone', house: 'H', name: 'N2' }, { id: 'b3', shelf: 'x1', house: 'H', name: 'N3' }] }) });
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  check('a v2 save keeps only valid shelves, shows names as text, and re-homes a bottle on a missing shelf', (await page.locator('.shelf').count()) === 2 && !(await page.evaluate(() => window.__xss === 2)) && (await page.textContent('.shelf[data-id="x1"] .sname')).includes('<img') && (await page.locator('.mb').count()) === 3);
  await page.keyboard.press('Escape'); await page.waitForTimeout(800);
  // a save written by the parallel v3 build (main at 648a506) carries over: collection, demo, impressions, rotation, mode
  await fresh({ 'arooma.v1': JSON.stringify({ v: 3, active: 'own', own: { shelves: [{ id: 'au', name: 'Autumn shelf' }], bottles: [{ id: 'p1', shelf: 'au', house: 'Par House', name: 'Par One', log: ['2026-10-20'], imp: { '2026-10-20': { o: 'Bright', d: 'Soft', p: 'strong', l: 'long', n: 'Lovely' } } }, { id: 'p2', shelf: 'au', house: 'Par House', name: 'Par Two' }], rots: [{ id: 'r1', name: 'Week', ids: ['p2', 'p1'] }], meta: { backupAt: '2026-10-21', changes: 3 } }, demo: { shelves: [], bottles: [{ id: 's9', shelf: 'au', house: 'Demo', name: 'Kept Demo', sample: true }], rots: [] } }) });
  check('FR-6 a save from the parallel v3 build carries over with its impressions, rotation and demo', (await page.locator('.slot').count()) === 2 && await page.evaluate(() => { const c = JSON.parse(localStorage.getItem('arooma.cabinet')), d = JSON.parse(localStorage.getItem('arooma.demo')), m = c.bottles[0].imp['2026-10-20']; return m.p === 3 && m.l === 3 && m.dv === 'Soft. Lovely' && c.rot.join() === 'p2,p1' && d.bottles[0].name === 'Kept Demo' && JSON.parse(localStorage.getItem('arooma.prefs')).backupAt === '2026-10-21' && JSON.parse(localStorage.getItem('arooma.v1')).own; }));
  // sample bottles that an older version mixed into a real collection are labelled, and can be removed
  await fresh({ 'arooma.v1': JSON.stringify({ v: 2, shelves: [{ id: 'au', name: 'Autumn shelf' }], bottles: [{ id: 's2', shelf: 'au', house: 'Hollis & Reed', name: 'Fig Hour', sample: true }, { id: 'u1', shelf: 'au', house: 'Mine', name: 'Mine One' }, { id: 'u2', shelf: 'au', house: 'Mine', name: 'Mine Two' }] }) });
  check('FR-2 a sample bottle carried over from an old save is labelled Sample', await page.evaluate(() => { const n = (id) => document.querySelector('.slot[data-i="' + id + '"] .num').textContent; return /Sample/.test(n(0)) && !/Sample/.test(n(1)); }));
  await page.click('#menu'); await page.waitForSelector('#panel.on'); await page.click('#samples'); await page.waitForTimeout(300);
  await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('FR-2 Remove sample bottles keeps only my own', (await page.locator('.slot').count()) === 2 && (await own()).bottles.every((b) => !b.sample));

  // ================= FR-1, FR-3, FR-4, FR-5: my collection, the empty cabinet, the last bottle, clear and demo =================
  await fresh({});
  await page.click('[data-er="start"]'); await page.waitForTimeout(900);
  check('FR-1 Start my collection opens a truly empty cabinet and saves it', (await page.locator('.slot').count()) === 0 && (await own()).bottles.length === 0 && (await own()).v === 3);
  check('FR-4 the empty cabinet says so and offers Add a bottle', await page.isVisible('[data-er="add"]') && /An empty cabinet/.test(await page.textContent('#empty')) && /this device/.test(await page.textContent('#empty')));
  check('FR-4 with nothing on the shelves the layouts and Daily Pick wait, and nothing breaks', await page.isDisabled('#seg button[data-mode="fan"]') && await page.isDisabled('#pick') && errors.length === 0);
  await page.screenshot({ path: path.join(outDir, '30-empty-cabinet.png') });
  const addB = async (h, n, sh, notes, photo) => {
    await page.click('#addBtn'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(250);
    await page.fill('#fHouse', h); await page.fill('#fName', n);
    if (sh) await page.selectOption('#fShelf', sh);
    if (notes) await page.fill('#fNotes', notes);
    if (photo) { await page.setInputFiles('#photoFile', photo); await page.waitForTimeout(700); }
    await page.click('[data-act="save"]'); await page.waitForTimeout(1100);
  };
  await page.click('[data-er="add"]'); await page.waitForSelector('#panel.on');
  await page.fill('#fHouse', 'Solo House'); await page.fill('#fName', 'Only One'); await page.click('[data-act="save"]'); await page.waitForTimeout(1300);
  check('FR-1 the first bottle goes into my collection and the demo stays untouched', (await page.locator('.slot').count()) === 1 && (await own()).bottles.length === 1 && (await demoSaved()) === null);
  await page.click('#seg button[data-mode="fan"]'); await page.waitForTimeout(900);
  check('PL-2 Fan works with one bottle and says it is not in the rotation', /not in your rotation/.test(await page.textContent('#cap')) && (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '0');
  await page.click('#seg button[data-mode="flow"]'); await page.waitForTimeout(900);
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#del'); await page.waitForTimeout(300); await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('FR-3 the last bottle can be deleted, and the empty cabinet returns', (await page.locator('.slot').count()) === 0 && await page.isVisible('[data-er="add"]') && (await own()).bottles.length === 0 && errors.length === 0, errors.join(' | '));
  await page.click('.toast.on .tact'); await page.waitForTimeout(900);
  check('FR-3 Undo brings the last bottle back', (await page.locator('.slot').count()) === 1 && !(await page.isVisible('[data-er="add"]')));
  await page.click('#menu'); await page.waitForSelector('#panel.on'); await page.click('#demo'); await page.waitForTimeout(300);
  check('FR-5 Load demo asks first and promises my collection stays', /Open the demo collection/.test(await page.textContent('#panelBody')) && /stays saved/.test(await page.textContent('#panelBody')));
  await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(1200);
  check('FR-5 the demo opens, labelled', (await page.locator('.slot').count()) === 7 && /^Demo/.test((await page.textContent('#eyebrow')).trim()));
  await addB('Demo House', 'Demo Only', 'au');
  check('FR-2 a bottle added in the demo never reaches my collection', (await own()).bottles.map((b) => b.name).join() === 'Only One' && (await demoSaved()).bottles.some((b) => b.name === 'Demo Only'));
  await page.click('#menu'); await page.waitForSelector('#panel.on'); await page.click('#leave'); await page.waitForTimeout(1100);
  check('FR-2 leaving the demo brings my collection back as it was', (await page.locator('.slot').count()) === 1 && /^The cabinet/.test((await page.textContent('#eyebrow')).trim()));
  await page.click('#menu'); await page.waitForSelector('#panel.on'); await page.click('#clear'); await page.waitForTimeout(300);
  check('FR-5 Clear my collection asks first and suggests a backup', /Clear your collection/.test(await page.textContent('#panelBody')) && /Export a backup first/.test(await page.textContent('#panelBody')));
  await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('FR-5 Clear empties only my collection; the demo keeps its changes', (await page.locator('.slot').count()) === 0 && (await own()).bottles.length === 0 && (await demoSaved()).bottles.length === 8);
  await page.click('.toast.on .tact'); await page.waitForTimeout(900);
  check('FR-5 Undo after Clear restores my collection', (await page.locator('.slot').count()) === 1 && (await own()).bottles.length === 1);

  // ================= CM: positions, duplicates, long names, edit, move, search =================
  await addB('Maison Été', 'Fleur d’Oranger', 'au', 'orange, neroli, musk');
  await addB('Atelier Nord', 'Cedar Smoke', 'au', 'cedar, smoke, amber');
  check('CM-4 an added bottle goes to the end of its shelf and is selected', (await ttl()) === 'Autumn shelf' && (await page.textContent('#cap')).trim() === '02 / 02');
  await page.click('#addBtn'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(250);
  await page.fill('#fHouse', 'Atelier Nord'); await page.fill('#fName', 'cedar smoke'); await page.selectOption('#fShelf', 'au');
  await page.click('[data-act="save"]'); await page.waitForTimeout(300);
  const dupMsg = await page.textContent('#fErr');
  await page.click('[data-act="save"]'); await page.waitForTimeout(1100);
  check('CM-5 a duplicate is flagged once, then both are kept', /already have/.test(dupMsg) && (await page.textContent('#cap')).trim() === '03 / 03', dupMsg);
  await addB('A House With A Considerably Long Name Indeed', 'An Extremely Long Fragrance Name For Testing Overflow', 'au');
  check('CM-5 a long name is shortened on the card, whole in its label, and nothing overflows', await page.evaluate(() => { const el = document.querySelector('.slot[tabindex="0"]'), nm = el.querySelector('.nm'); return nm.scrollWidth > nm.clientWidth && getComputedStyle(nm).textOverflow === 'ellipsis' && /Name For Testing/.test(el.getAttribute('aria-label')) && document.documentElement.scrollWidth <= window.innerWidth + 1; }));
  check('CM-5 a bottle with no notes renders without a notes line', (await page.textContent('#notes')).trim() === '');
  await page.screenshot({ path: path.join(outDir, '31-long-name.png') });
  await page.click('#bMenu'); await page.waitForSelector('#panel.on');
  check('CM-2 Edit details is the first row of the bottle menu', await page.evaluate(() => document.querySelector('#panelBody .prow').id === 'edit'));
  await page.click('#edit'); await page.waitForTimeout(300);
  await page.fill('#fName', 'Shorter Name'); await page.click('[data-act="save"]'); await page.waitForTimeout(1000);
  check('CM-2 an edit shows on the card and is saved', (await page.textContent('.slot[tabindex="0"] .nm')) === 'Shorter Name' && (await own()).bottles.some((b) => b.name === 'Shorter Name') && (await page.textContent('#cap')).trim() === '04 / 04');
  await page.click('.slot[tabindex="0"]'); await page.waitForTimeout(1100);
  await page.click('.slot[tabindex="0"] .rec-edit'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(200);
  check('CM-2 the ownership record has its own Edit details link', /Edit Shorter Name/.test(await page.textContent('#panelBody h2')));
  await page.click('#panel [data-act="cancel"]'); await page.waitForTimeout(800);
  await page.click('.slot[tabindex="0"]'); await page.waitForTimeout(900);
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#move'); await page.waitForTimeout(300); await page.click('[data-sh="sp"]'); await page.waitForTimeout(1100);
  check('CM-4 a moved bottle goes to the end of its new shelf, and the selection follows it', (await ttl()) === 'Spring shelf' && (await page.textContent('#cap')).trim() === '02 / 02' && (await page.textContent('.slot[tabindex="0"] .nm')) === 'Shorter Name');
  await page.click('.toast.on .tact'); await page.waitForTimeout(1100);
  check('CM-4 Undo puts it back in its old place', (await ttl()) === 'Autumn shelf' && (await page.textContent('#cap')).trim() === '04 / 04');
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  const hits = async (q) => { await page.fill('#findIn', q); await page.waitForTimeout(200); return page.locator('.hit').count(); };
  check('CM-1 search finds a house without its accents', (await hits('ete')) === 1 && /Maison Été/.test(await page.textContent('.hit')));
  check('CM-1 search matches names, any case, every word', (await hits('CEDAR')) === 2 && (await hits('nord smoke')) === 2 && (await hits('only one')) === 1);
  check('CM-1 search says when nothing matches', (await hits('zzz')) === 0 && /Nothing on your shelves matches/.test(await page.textContent('#overScroll')));
  await hits('fleur'); await page.screenshot({ path: path.join(outDir, '32-search.png') });
  await page.click('.hit'); await page.waitForTimeout(1000);
  check('CM-1 a result opens its shelf with that bottle selected', (await ttl()) === 'Autumn shelf' && (await page.textContent('.slot[tabindex="0"] .nm')) === 'Fleur d’Oranger' && (await page.inputValue('#findIn')) === '');
  await page.focus('#stage'); await page.keyboard.press('/'); await page.waitForTimeout(900);
  check('CM-1 the / key opens search, ready to type', (await zval()) > .98 && await page.evaluate(() => document.activeElement.id === 'findIn'));
  await page.keyboard.press('Escape'); await page.waitForTimeout(900);

  // ================= WL: wear, then how it wore, then history =================
  const ymdAgo = (n) => page.evaluate((k) => { const t = new Date(Date.now() - k * 864e5); return t.getFullYear() + '-' + String(t.getMonth() + 1).padStart(2, '0') + '-' + String(t.getDate()).padStart(2, '0'); }, n);
  const today = await ymdAgo(0);
  check('WL-2 there is no impression prompt before a wear', !(await page.isVisible('#impBtn')));
  await page.click('#wear'); await page.waitForTimeout(500);
  check('WL-1 and CM-6 one tap logs the wear, says so quietly, and updates Last worn', (await page.textContent('#wear')).includes('Worn today') && /Logged/.test(await page.textContent('#toast')) && /^Worn today/.test(await page.textContent('#meta')));
  check('WL-2 an optional Add how it wore link appears, never a questionnaire', await page.isVisible('#impBtn') && !(await panelOn()));
  await page.click('#impBtn'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(250);
  check('WL-2 every impression field is optional', /Every field is optional/.test(await page.textContent('#panelBody')));
  await page.fill('#iO', 'Bright neroli'); await page.click('.seg3[data-k="p"] button[data-val="3"]'); await page.click('.seg3[data-k="l"] button[data-val="2"]');
  await page.screenshot({ path: path.join(outDir, '33-impression.png') });
  await page.click('#panel [data-act="save"]'); await page.waitForTimeout(900);
  const fleur = async () => (await own()).bottles.find((b) => b.name === 'Fleur d’Oranger');
  check('WL-2 the impression is saved on today’s wear', await (async () => { const m = (await fleur()).imp[today]; return m && m.o === 'Bright neroli' && m.p === 3 && m.l === 2; })());
  check('WL-3 the record shows the recent wear and how it wore', /Strong, 3 to 6 h\. Bright neroli/.test(await page.textContent('.slot[tabindex="0"] .rec-tl')));
  const d30 = await ymdAgo(30);
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#history'); await page.waitForTimeout(300);
  await page.fill('#hDate', d30); await page.click('[data-act="addw"]'); await page.waitForTimeout(300);
  await page.click('[data-imp="' + d30 + '"]'); await page.waitForTimeout(300);
  await page.fill('#iD', 'Faded by noon'); await page.click('.seg3[data-k="l"] button[data-val="1"]'); await page.click('#panel [data-act="save"]'); await page.waitForTimeout(500);
  check('WL-2 an older wear can get its impression later, from the history', /Wear history/.test(await page.textContent('#panelBody h2')) && /Under 3 h\. Faded by noon/.test(await page.textContent('#panelBody')));
  await page.screenshot({ path: path.join(outDir, '34-history-impressions.png') });
  await page.click('[data-del="' + d30 + '"]'); await page.waitForTimeout(300);
  check('WL-2 removing a wear removes its impression', !(await fleur()).imp[d30]);
  await page.click('.toast.on .tact'); await page.waitForTimeout(400);
  check('WL-2 Undo brings back the wear and its impression', (await fleur()).imp[d30] && (await fleur()).imp[d30].dv === 'Faded by noon');
  await page.click('#panel [data-act="cancel"]'); await page.waitForTimeout(800);
  // WL-4: give Cedar Smoke an old wear with a noted longevity, then let Daily Pick cite it
  await page.focus('#stage'); await page.keyboard.press('ArrowRight'); await page.waitForTimeout(700);
  const d40 = await ymdAgo(40);
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#history'); await page.waitForTimeout(300);
  await page.fill('#hDate', d40); await page.click('[data-act="addw"]'); await page.waitForTimeout(300);
  await page.click('[data-imp="' + d40 + '"]'); await page.waitForTimeout(300); await page.click('.seg3[data-k="l"] button[data-val="3"]'); await page.click('#panel [data-act="save"]'); await page.waitForTimeout(400);
  await page.click('#panel [data-act="cancel"]'); await page.waitForTimeout(800);
  let reason = '';
  for (let k = 0; k < 5 && !/40 days/.test(reason); k++) { await page.click('#pick'); await page.waitForTimeout(700); reason = await page.textContent('#reason'); }
  check('WL-4 the daily pick cites history honestly', /haven’t worn this in a while: 40 days/.test(reason) && /Last time you noted over 6 hours/.test(reason), reason);
  check('WL-5 and the no-network rule: nothing has left the device', offsite.length === 0, offsite.slice(0, 3).join(' '));

  // ================= BP: the owner's own photos, one physical space =================
  const art = await page.evaluate(() => {
    const out = {};
    const draw = (w, h, fn, type) => { const c = document.createElement('canvas'); c.width = w; c.height = h; const x = c.getContext('2d'); fn(x, w, h); return c.toDataURL(type || 'image/png').split(',')[1]; };
    out.clear = draw(300, 600, (x) => { x.fillStyle = 'rgba(200,220,215,.45)'; x.fillRect(60, 160, 180, 420); x.strokeStyle = 'rgba(60,70,70,.6)'; x.lineWidth = 4; x.strokeRect(60, 160, 180, 420); const g = x.createLinearGradient(110, 0, 190, 0); g.addColorStop(0, '#7b7e7f'); g.addColorStop(.4, '#fbfbfb'); g.addColorStop(1, '#7b7e7f'); x.fillStyle = g; x.fillRect(110, 40, 80, 120); });
    out.black = draw(320, 640, (x) => { x.fillStyle = '#0b0b0b'; x.fillRect(50, 150, 220, 470); x.fillStyle = '#2a2a2a'; x.fillRect(110, 40, 100, 110); });
    out.amber = draw(400, 500, (x) => { x.fillStyle = 'rgba(201,132,40,.9)'; x.beginPath(); x.ellipse(200, 300, 170, 190, 0, 0, 7); x.fill(); x.fillStyle = '#d6c58a'; x.fillRect(160, 30, 80, 90); });
    out.white = draw(480, 640, (x, w, h) => { x.fillStyle = '#7a8a96'; x.fillRect(0, 0, w, h); x.fillStyle = '#f7f4ed'; x.fillRect(140, 180, 200, 420); x.fillStyle = '#bfb8a8'; x.fillRect(190, 110, 100, 70); }, 'image/jpeg');
    out.irregular = draw(360, 560, (x) => { x.fillStyle = 'rgba(140,69,36,.85)'; x.beginPath(); x.moveTo(60, 540); x.lineTo(20, 300); x.lineTo(150, 140); x.lineTo(210, 140); x.lineTo(340, 300); x.lineTo(300, 540); x.closePath(); x.fill(); x.fillStyle = '#1d1c1b'; x.fillRect(150, 50, 60, 90); });
    out.wide = draw(800, 300, (x) => { x.fillStyle = '#9c9fa0'; x.fillRect(40, 80, 720, 200); x.fillStyle = '#25231F'; x.fillRect(360, 20, 80, 60); });
    return out;
  });
  const kinds = ['clear', 'black', 'amber', 'white', 'irregular', 'wide'];
  for (const k of kinds) await addB('Photo House', 'Photo ' + k, 'wi', '', { name: k + (k === 'white' ? '.jpg' : '.png'), mimeType: k === 'white' ? 'image/jpeg' : 'image/png', buffer: Buffer.from(art[k], 'base64') });
  const photos = async () => (await own()).bottles.filter((b) => b.img);
  check('BP-1 six bottles carry their owner’s photo, stored on the device', (await photos()).length === 6 && (await ttl()) === 'Winter shelf' && (await page.locator('.slot use.ph').count()) >= 6);
  check('BP-1 a cut-out keeps its transparency; a photo with a background is kept as JPEG', await (async () => { const p = await photos(), f = (n) => p.find((b) => b.name === 'Photo ' + n).img.src; return /^data:image\/(png|webp)/.test(f('clear')) && /^data:image\/jpeg/.test(f('white')) && p.every((b) => b.img.src.length < 600000); })());
  check('BP-2 photos are never stretched: every one keeps its aspect ratio', await page.evaluate(() => [...document.querySelectorAll('.slot image')].every((im) => im.getAttribute('preserveAspectRatio') === 'xMidYMax meet')));
  check('BP-4 every photo stands on the same table as the drawings: one baseline, one contact shadow, one light', await page.evaluate(() => [...document.querySelectorAll('.slot')].filter((s) => s.querySelector('use.ph')).every((s) => { const im = s.querySelector('image'); return +im.getAttribute('y') + +im.getAttribute('height') === 237 && s.querySelector('ellipse[cy="238"]') && s.querySelector('rect[mask]'); })));
  check('BP-4 every photo bottle shows its liquid through a level window, like the opaque drawings', await page.evaluate(() => [...document.querySelectorAll('.slot')].filter((s) => s.querySelector('use.ph')).every((s) => s.querySelector('.phw .lq') && s.querySelector('.phw clipPath rect'))));
  check('BP-4 the liquid takes its colour from the photo: the amber bottle holds amber', await page.evaluate(() => { const s = [...document.querySelectorAll('.slot')].find((x) => /Photo amber/.test(x.getAttribute('aria-label'))); const c = s.querySelector('.phw linearGradient stop:nth-child(2)').getAttribute('stop-color'); const n = parseInt(c.slice(1), 16), r = n >> 16, g = n >> 8 & 255, b = n & 255; return r > g && g > b && r - b > 80; }));
  await page.screenshot({ path: path.join(outDir, '35-photos-flow.png') });
  await page.click('#seg button[data-mode="stack"]'); await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(outDir, '36-photos-stack.png') });
  await page.click('#seg button[data-mode="flow"]'); await page.waitForTimeout(900);
  // positioning: sliders (tap and keyboard path) and drag
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#edit'); await page.waitForTimeout(300);
  await page.evaluate(() => { const set = (id, v) => { const r = document.getElementById(id); r.value = v; r.dispatchEvent(new Event('input', { bubbles: true })); }; set('phS', 140); set('phX', 10); set('phW', 30); set('fLeft', 40); });
  const fr = await page.locator('#phFrame').boundingBox();
  await page.mouse.move(fr.x + 60, fr.y + 80); await page.mouse.down(); await page.mouse.move(fr.x + 60, fr.y + 60, { steps: 4 }); await page.mouse.up();
  await page.screenshot({ path: path.join(outDir, '37-photo-editor.png') });
  await page.click('[data-act="save"]'); await page.waitForTimeout(1000);
  check('BP-2 size and position are adjustable, by slider and by drag, and saved', await (async () => { const b = (await photos()).find((x) => x.name === 'Photo wide'); return b && b.img.s === 1.4 && b.img.x === 10 && b.img.y < -10 && b.img.w === .3; })());
  check('BP-4 the photo bottle’s liquid sits at the estimated level, 40%', await page.evaluate(() => { const s = document.querySelector('.slot[tabindex="0"]'), r = s.querySelector('.phw clipPath rect'), y = +r.getAttribute('y'), h = +r.getAttribute('height'), lq = +s.querySelector('.phw .lq').getAttribute('data-y0'); return Math.abs(lq - (y + h - .4 * .92 * h)) < .05; }));
  await page.waitForTimeout(1500);
  const pd0 = await page.getAttribute('.slot[tabindex="0"] .phw .lq', 'd'); await page.waitForTimeout(450);
  check('BP-4 the photo bottle’s liquid moves like every other bottle', pd0 !== await page.getAttribute('.slot[tabindex="0"] .phw .lq', 'd'));

  // three photo bottles become the rotation
  for (const n of ['Photo amber', 'Photo black', 'Photo irregular']) {
    await page.click('#shelvesBtn'); await page.waitForTimeout(800); await page.fill('#findIn', n); await page.waitForTimeout(200); await page.click('.hit'); await page.waitForTimeout(900);
    await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#rot'); await page.waitForTimeout(500);
  }
  await page.click('#seg button[data-mode="fan"]'); await page.waitForTimeout(1200);
  check('PL-2 Fan presents only the saved rotation, not everything', /Your rotation · 3 bottles/.test(await page.textContent('#cap')) && await page.evaluate(() => [...document.querySelectorAll('.slot')].filter((s) => +s.style.opacity > .5).length === 3));
  await page.screenshot({ path: path.join(outDir, '38-photos-fan.png') });
  await page.click('#menu'); await page.waitForSelector('#panel.on'); await page.click('#share'); await page.waitForTimeout(1500);
  check('the share image in Fan is the rotation, one row of three', /Current rotation/.test(await page.textContent('#ed')) && (await page.locator('#ed figure').count()) === 3);
  await page.screenshot({ path: path.join(outDir, '39-share-rotation.png') });
  await page.evaluate(() => { window.__shared = null; }); await page.click('#saveImg'); await page.waitForTimeout(1800);
  check('the rotation image with photos exports as a PNG', await page.evaluate(() => !!window.__shared && window.__shared.type === 'image/png' && window.__shared.size > 20000));
  await page.click('#closeSheet'); await page.waitForTimeout(800);
  await page.click('#seg button[data-mode="flow"]'); await page.waitForTimeout(900);
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  await page.screenshot({ path: path.join(outDir, '40-photos-overview.png') });
  await page.keyboard.press('Escape'); await page.waitForTimeout(800);
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#edit'); await page.waitForTimeout(300);
  await page.setInputFiles('#photoFile', { name: 'notes.png', mimeType: 'image/png', buffer: Buffer.from('not an image') }); await page.waitForTimeout(500);
  check('BP-1 a file that is not an image is refused with a message', /Could not read that image/.test(await page.textContent('#fErr')));
  await page.click('#panel [data-act="cancel"]'); await page.waitForTimeout(800);

  // ================= BK: backup, clear, restore =================
  const canon = (v) => Array.isArray(v) ? v.map(canon) : v && typeof v === 'object' ? Object.keys(v).sort().reduce((o, k) => { o[k] = canon(v[k]); return o; }, {}) : v;
  const bkBefore = await own();
  await page.click('#menu'); await page.waitForSelector('#panel.on'); await page.click('#backup'); await page.waitForTimeout(300);
  const bkTxt = await page.textContent('#panelBody');
  check('BK-4 the backup panel says plainly where the data lives and recommends exporting', /lives only in this browser on this device/.test(bkTxt) && /Export a backup now and then/.test(bkTxt));
  await page.evaluate(() => { window.__sharedText = null; }); await page.click('#export'); await page.waitForTimeout(800);
  const exported = await page.evaluate(() => window.__sharedText);
  const ex = JSON.parse(exported || '{}');
  check('BK-1 the export holds shelves, bottles, notes, photos, wears and impressions', ex.app === 'arooma' && ex.v === 3 && ex.shelves.length === bkBefore.shelves.length && ex.bottles.length === bkBefore.bottles.length && ex.bottles.some((b) => b.img) && ex.bottles.some((b) => Object.keys(b.imp).length) && ex.bottles.some((b) => b.log.length > 1) && ex.bottles.some((b) => b.notes) && ex.rot.length === 3, (exported || '').length + ' bytes');
  await page.click('#panel [data-act="cancel"]'); await page.waitForTimeout(700);
  await page.click('#menu'); await page.waitForSelector('#panel.on'); await page.click('#clear'); await page.waitForTimeout(300); await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('BK-3 the collection is cleared before the restore', (await own()).bottles.length === 0);
  await page.setInputFiles('#importFile', { name: 'other.json', mimeType: 'application/json', buffer: Buffer.from('{"hello":1}') }); await page.waitForSelector('#panel.on'); await page.waitForTimeout(300);
  check('BK-2 a file that is not a backup is refused and nothing changes', /Nothing was restored/.test(await page.textContent('#panelBody')) && /nothing was changed/.test(await page.textContent('#panelBody')) && (await page.locator('.slot').count()) === 0);
  await page.click('#panel [data-act="cancel"]'); await page.waitForTimeout(700);
  await page.setInputFiles('#importFile', { name: 'arooma-backup.json', mimeType: 'application/json', buffer: Buffer.from(exported) }); await page.waitForSelector('#panel.on'); await page.waitForTimeout(300);
  check('BK-2 a restore shows what the file holds and asks: replace or add', /Restore this backup/.test(await page.textContent('#panelBody')) && /photos/.test(await page.textContent('#impSum')) && await page.isVisible('#replace') && await page.isVisible('#merge') && (await own()).bottles.length === 0);
  await page.screenshot({ path: path.join(outDir, '41-restore-review.png') });
  await page.click('#replace'); await page.waitForTimeout(1300);
  const after = await own();
  check('BK-3 export, clear and restore give back an identical collection', JSON.stringify(canon(after)) === JSON.stringify(canon(bkBefore)), after.bottles.length + ' bottles');
  await page.setInputFiles('#importFile', { name: 'arooma-backup.json', mimeType: 'application/json', buffer: Buffer.from(exported) }); await page.waitForSelector('#panel.on'); await page.waitForTimeout(300);
  await page.click('#merge'); await page.waitForTimeout(1200);
  check('BK-2 adding the same backup again adds nothing, and says so', (await own()).bottles.length === bkBefore.bottles.length && /Added 0 bottles\. \d+ already here/.test(await page.textContent('#toast')));
  await page.setInputFiles('#importFile', { name: 'one.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify({ app: 'arooma', v: 3, shelves: [], bottles: [{ id: 'z1', house: 'Z', name: 'Z One' }], rot: [] })) }); await page.waitForSelector('#panel.on'); await page.waitForTimeout(300);
  await page.click('#replace'); await page.waitForTimeout(400);
  check('BK-2 replacing a collection that is not empty asks again', new RegExp('Replace ' + bkBefore.bottles.length + ' bottles').test(await page.textContent('#panelBody')));
  await page.click('#panel [data-act="cancel"]'); await page.waitForTimeout(800);
  check('BK-2 Keep mine changes nothing: never a silent overwrite', (await own()).bottles.length === bkBefore.bottles.length);

  // ================= WO-4: the testing session is an in-app aid, minutes and hours apart =================
  await page.click('#test'); await page.waitForTimeout(500);
  check('WO-4 a test counts down to the heart check-in in minutes, not a 30 second default', /^(19|20):\d\d$/.test((await page.textContent('.i-time')).trim()), await page.textContent('.i-time'));
  await reopenFast(page);
  check('WO-4 the session survives a reload', (await page.getAttribute('#island', 'data-s')) === 'compact');
  await page.evaluate(() => { const r = Date.now.bind(Date); window.__off = 0; Date.now = () => r() + window.__off; window.__off = 21 * 60 * 1000; }); await page.waitForTimeout(700);
  check('WO-4 twenty minutes in, it moves to the heart check-in and says it is an in-app timer', /Heart/.test(await page.textContent('#iPhase')) && /In-app timer/.test(await page.textContent('.i-note')));
  await page.screenshot({ path: path.join(outDir, '42-test-heart.png') });
  await page.evaluate(() => { window.__off = 121 * 60 * 1000; }); await page.waitForTimeout(700);
  check('WO-4 after two hours the session completes', (await page.getAttribute('#island', 'data-s')) === 'done' && /Test complete/.test(await page.textContent('#iPhase')));
  await page.click('#iLog'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(250);
  check('WO-4 Log impression opens a real impression for today', /How it wore/.test(await page.textContent('#panelBody h2')));
  await page.click('#panel [data-act="cancel"]'); await page.waitForTimeout(700);
  await page.click('#iEnd'); await page.waitForTimeout(600);
  await page.evaluate(() => { window.__off = 0; });
  check('WO-4 the session ends cleanly', (await page.getAttribute('#island', 'data-s')) === 'idle' && (await page.evaluate(() => localStorage.getItem('arooma.test'))) === null);

  // ================= WO-1 to WO-3: wording on every surface =================
  const allText = () => page.evaluate(() => { const c = document.body.cloneNode(true); c.querySelectorAll('script').forEach((s) => s.remove()); return c.textContent; });
  check('WO-1 to WO-4 no surface claims a true level, a verified result, a certain match or a Dynamic Island', !/true liquid level|liquid level is true|verified authentic|is authentic|perfect match|you will love|Dynamic Island/i.test(await allText()));
  await page.click('#bMenu'); await page.waitForSelector('#panel.on');
  check('WO-3 the bottle menu calls it authenticity notes that cannot verify', /Authenticity notes/.test(await page.textContent('#panelBody')) && /cannot verify/.test(await page.textContent('#panelBody')));
  await page.click('#panel [data-act]', { position: { x: 1, y: 1 } }).catch(() => {}); await closePanel();
  check('WO-1 remaining volume is always called an estimate', /Estimated remaining|\(estimate\)/.test(await page.textContent('#meta')) && /Estimated remaining/.test(await page.textContent('.slot[tabindex="0"] .rec-dl')));

  // ================= CM-5: a 60-bottle cabinet =================
  await page.evaluate(() => {
    const sh = ['sp', 'su', 'au', 'wi'], v = ['clear', 'noir', 'green', 'white', 'amber', 'smoke', 'clay'], b = [];
    for (let i = 0; i < 60; i++) b.push({ id: 'big' + i, shelf: i < 45 ? 'au' : sh[i % 4], house: 'House ' + (i % 9), name: 'Bottle ' + i, ml: 50, left: (i % 10) / 10 + .05, notes: 'cedar, amber', vessel: v[i % 7], log: ['2026-01-0' + (1 + (i % 9))] });
    localStorage.setItem('arooma.cabinet', JSON.stringify({ v: 3, shelves: [{ id: 'sp', name: 'Spring shelf' }, { id: 'su', name: 'Summer shelf' }, { id: 'au', name: 'Autumn shelf' }, { id: 'wi', name: 'Winter shelf' }], bottles: b, rot: [] }));
  });
  errors.length = 0;
  await reopenFast(page);
  check('CM-5 a 60-bottle cabinet loads', (await page.locator('.slot').count()) === 60 && errors.length === 0, errors.join(' | '));
  const perStep = await page.evaluate(() => { const st = document.getElementById('stage'), t = performance.now(); for (let k = 0; k < 20; k++) st.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true })); return (performance.now() - t) / 20; });
  check('CM-5 stepping along a 45-bottle shelf stays quick', perStep < 25, perStep.toFixed(1) + ' ms per step in headless Chromium');
  await page.waitForTimeout(1200);
  await page.click('#shelvesBtn'); await page.waitForTimeout(1000);
  const mbs = await page.locator('.mb').count(), h4 = await hits('bottle 42');
  check('CM-5 the overview and search handle 60 bottles', mbs === 60 && h4 === 1, mbs + ' in the overview, ' + h4 + ' hits');
  await page.screenshot({ path: path.join(outDir, '43-sixty.png') });
  await page.keyboard.press('Escape'); await page.keyboard.press('Escape'); await page.waitForTimeout(900);
  check('CM-5 the cabinet stays well inside browser storage', await page.evaluate(() => localStorage.getItem('arooma.cabinet').length < 1e6));
  await page.evaluate(() => localStorage.clear());

  check('no console or page errors', errors.length === 0, errors.join(' | '));


  // ---- desktop frame ----
  const demoPrefs = () => { if (!localStorage.getItem('arooma.prefs')) localStorage.setItem('arooma.prefs', '{"mode":"demo"}'); };
  const dctx = await browser.newContext({ viewport: { width: 1200, height: 900 } });
  await dctx.addInitScript(demoPrefs);
  const dpage = await dctx.newPage();
  const derrors = [];
  dpage.on('pageerror', (e) => derrors.push(e.message));
  await dpage.goto(base); await dpage.waitForTimeout(5200);
  await dpage.screenshot({ path: path.join(outDir, '9-desktop.png') });
  check('desktop shows the framed device', (await dpage.locator('.slot').count()) === 7 && derrors.length === 0, derrors.join(' | '));


  // ---- Reduce Motion: the liquid stays flat at its true level, and nothing zooms ----
  const rctx = await browser.newContext({ viewport: { width: 393, height: 852 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true, reducedMotion: 'reduce' });
  await rctx.addInitScript(demoPrefs);
  const rpage = await rctx.newPage();
  const rerr = [];
  rpage.on('pageerror', (e) => rerr.push(e.message));
  await rpage.goto(base); await rpage.waitForTimeout(300);
  await rpage.evaluate(() => document.getElementById('cabinet').click()); await rpage.waitForTimeout(1200);
  const flat = () => rpage.evaluate(() => document.querySelector('.slot[tabindex="0"] .lq').getAttribute('d'));
  const f1 = await flat(); await rpage.waitForTimeout(700);
  check('Reduce Motion: the liquid is flat, still, and at its true level', /^M[\d.]+ 145\.3H[\d.]+V[\d.]+H[\d.]+Z$/.test(f1) && f1 === (await flat()), f1);
  await rpage.click('#shelvesBtn'); await rpage.waitForTimeout(300);
  check('Reduce Motion: the overview swaps without scaling', await rpage.evaluate(() => parseFloat(getComputedStyle(document.getElementById('device')).getPropertyValue('--z')) > .98 && getComputedStyle(document.getElementById('over')).transform === 'none'));
  check('Reduce Motion: no page errors', rerr.length === 0, rerr.join(' | '));
  await rctx.close();

  // ---- smallest supported phone: 375 x 667 ----
  const sctx = await browser.newContext({ viewport: { width: 375, height: 667 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
  await sctx.addInitScript(demoPrefs);
  const spage = await sctx.newPage();
  const serr = [];
  spage.on('pageerror', (e) => serr.push(e.message));
  await spage.goto(base); await spage.waitForTimeout(300);
  await spage.evaluate(() => document.getElementById('cabinet').click()); await spage.waitForTimeout(2400);
  const noScroll = () => spage.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth + 1 && document.body.scrollWidth <= window.innerWidth + 1);
  check('375 wide: no horizontal scroll', await noScroll());
  check('375 wide: header buttons, wear, test and menu all fit', await spage.evaluate(() => ['shelvesBtn', 'addBtn', 'menu', 'wear', 'test', 'bMenu', 'pick'].every((id) => { const r = document.getElementById(id).getBoundingClientRect(); return r.left >= 0 && r.right <= window.innerWidth && r.width > 30; })));
  for (const [open, name] of [['#addBtn', 'add'], ['#menu', 'menu']]) {
    await spage.click(open); await spage.waitForSelector('#panel.on'); await spage.waitForTimeout(800);
    const fit = await spage.evaluate(() => { const r = document.getElementById('panel').getBoundingClientRect(); return r.top >= 0 && r.bottom <= window.innerHeight + 1 && r.left >= 0 && r.right <= window.innerWidth + 1; });
    check('375x667: ' + name + ' panel stays on screen', fit);
    await spage.screenshot({ path: path.join(outDir, '19-small-' + name + '.png') });
    await spage.click('#scrim', { position: { x: 20, y: 20 } }); await spage.waitForTimeout(800);
  }
  await spage.click('#bMenu'); await spage.waitForSelector('#panel.on'); await spage.click('#auth'); await spage.waitForTimeout(800);
  check('375x667: authenticity panel scrolls inside itself', await spage.evaluate(() => { const b = document.getElementById('panelBody'); return b.scrollHeight >= b.clientHeight && getComputedStyle(b).overflowY === 'auto'; }));
  await spage.screenshot({ path: path.join(outDir, '20-small-auth.png') });

  await spage.click('#scrim', { position: { x: 20, y: 20 } }); await spage.waitForTimeout(800);
  await spage.click('#shelvesBtn'); await spage.waitForTimeout(1000);
  check('375x667: the overview fits with no horizontal scroll and its bar visible', await noScroll() && await spage.evaluate(() => { const r = document.getElementById('addShelf').getBoundingClientRect(); return r.left >= 0 && r.right <= window.innerWidth && r.bottom <= window.innerHeight + 1; }));
  await spage.screenshot({ path: path.join(outDir, '25-small-overview.png') });
  check('375x667: no page errors', serr.length === 0, serr.join(' | '));

  await browser.close();
  server.close();
  if (failures.length) { console.error('\n' + failures.length + ' check(s) failed'); process.exit(1); }
  console.log('\nAll checks passed');
})().catch((e) => { console.error(e); process.exit(1); });
