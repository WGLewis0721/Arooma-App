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
  check('Island shows a running timer', (await page.getAttribute('#island', 'data-s')) === 'compact' && /^0:\d\d$/.test((await page.textContent('.i-time')).trim()));
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
  const stored = () => page.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1') || 'null'));
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
  check('wear is saved with today’s date', await page.evaluate(() => { const d = JSON.parse(localStorage.getItem('arooma.v1')); const t = new Date(); const ymd = t.getFullYear() + '-' + String(t.getMonth() + 1).padStart(2, '0') + '-' + String(t.getDate()).padStart(2, '0'); return d.bottles.some((b) => b.log[0] === ymd); }));
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
  check('added bottle is saved on this device', await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).bottles.some((b) => b.name === 'Test Scent' && b.vessel === 'green' && b.sample === false)));
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
  check('shelf, wear and evidence survive a reload', (await page.locator('.slot').count()) === 8 && await page.evaluate(() => { const d = JSON.parse(localStorage.getItem('arooma.v1')); return d.bottles.some((b) => b.auth && b.auth.v.every((x) => x === 1)) && d.bottles.some((b) => b.log.length > 0); }));

  // delete with undo
  await page.focus('#stage'); for (let k = 0; k < 4; k++) await page.keyboard.press('ArrowRight');
  await page.waitForTimeout(900);
  check('keyboard reaches the added bottle', (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '7');
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#del'); await page.waitForTimeout(300);
  check('delete asks first', /Delete Test Scent\?/.test(await page.textContent('#panelBody')));
  await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('delete removes the bottle', (await page.locator('.slot').count()) === 7 && /07 objects/.test(await page.textContent('#eyebrow')));
  check('delete is saved', await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).bottles.length === 7));
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
  check('rename shows in the overview and is saved', (await page.textContent('.shelf[data-id="su"] .sname')) === 'Weekend rotation' && await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).shelves.some((h) => h.id === 'su' && h.name === 'Weekend rotation')));
  await page.click('.sname[data-open="su"]'); await page.waitForTimeout(900);
  check('the renamed shelf titles its own view', (await ttl()) === 'Weekend rotation' && (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '0');
  await page.screenshot({ path: path.join(outDir, '22-renamed-shelf.png') });

  // add a shelf in the zoomed-out view, then put a bottle on it
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  await page.click('#addShelf'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(300);
  await page.click('[data-act="save"]');
  check('a new shelf needs a name', /Give the shelf a name/.test(await page.textContent('#nsErr')));
  await page.fill('#nsName', 'Evenings'); await page.click('[data-act="save"]'); await page.waitForTimeout(900);
  check('a new shelf appears in the overview, empty, and is saved', (await page.locator('.shelf').count()) === 5 && (await page.textContent('.shelf:last-child .sname')) === 'Evenings' && /Nothing here yet/.test(await page.textContent('.shelf:last-child')) && await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).shelves.length === 5));
  await page.screenshot({ path: path.join(outDir, '23-new-shelf.png') });
  await page.click('.shelf:last-child .sh-add'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(300);
  check('Add a bottle on an empty shelf preselects that shelf', (await page.evaluate(() => document.getElementById('fShelf').selectedOptions[0].textContent)) === 'Evenings');
  await page.fill('#fHouse', 'Shelf House'); await page.fill('#fName', 'Late Hour'); await page.click('[data-act="save"]'); await page.waitForTimeout(1200);
  check('the bottle lands on the new shelf', await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).bottles.some((b) => b.name === 'Late Hour' && b.shelf !== 'au')) && (await page.locator('.shelf:last-child .mb').count()) === 1);
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
  const evId = await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).shelves.find((h) => h.name === 'Evenings').id);
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

  // storage that is damaged or hostile must not break the app
  for (const [label, value] of [['malformed JSON', '{bad'], ['wrong shape', JSON.stringify({ v: 1, bottles: 'x' })],
    ['markup in a name', JSON.stringify({ v: 1, bottles: [{ id: 'a1', house: '<img src=x onerror=window.__xss=1>', name: '<b>x</b>', vessel: 'nope', log: ['x', '2026-02-30x', '2026-03-01'] }, { id: 'a2', house: 'H', name: 'N' }, { id: 'a3', house: 'H', name: 'N3' }] })]]) {
    await page.evaluate((v) => localStorage.setItem('arooma.v1', v), value);
    await reopenFast(page);
    const xss = await page.evaluate(() => window.__xss === 1);
    check('survives ' + label, (await page.locator('.slot').count()) >= 3 && !xss && errors.length === 0, errors.join(' | '));
  }
  check('markup in saved text is shown as text', await page.evaluate(() => document.querySelector('.slot .house').textContent.includes('<img')));


  // a v1 save moves to the Autumn shelf; a v2 save with an unknown shelf falls back; shelf names are text
  await page.evaluate(() => localStorage.setItem('arooma.v1', JSON.stringify({ v: 1, bottles: [{ id: 'm1', house: 'Old House', name: 'Old One' }, { id: 'm2', house: 'Old House', name: 'Old Two' }, { id: 'm3', house: 'Old House', name: 'Old Three' }] })));
  await reopenFast(page);
  check('a v1 save migrates onto the Autumn shelf', (await ttl()) === 'Autumn shelf' && (await page.textContent('#cap')).trim().endsWith('/ 03'));
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  check('a migrated save gets the four seasons', (await page.locator('.shelf').count()) === 4);
  await page.keyboard.press('Escape'); await page.waitForTimeout(800);
  await page.evaluate(() => localStorage.setItem('arooma.v1', JSON.stringify({ v: 2, shelves: [{ id: 'x1', name: '<img src=x onerror=window.__xss=2>' }, { id: 'x2', name: 'Second' }, { id: 'x1', name: 'Dup' }, { id: '', name: 'No id' }], bottles: [{ id: 'b1', shelf: 'x2', house: 'H', name: 'N1' }, { id: 'b2', shelf: 'gone', house: 'H', name: 'N2' }, { id: 'b3', shelf: 'x1', house: 'H', name: 'N3' }] })));
  await reopenFast(page);
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  check('a v2 save keeps only valid shelves, shows names as text, and re-homes a bottle on a missing shelf', (await page.locator('.shelf').count()) === 2 && !(await page.evaluate(() => window.__xss === 2)) && (await page.textContent('.shelf[data-id="x1"] .sname')).includes('<img') && (await page.locator('.mb').count()) === 3);
  await page.keyboard.press('Escape'); await page.waitForTimeout(800);

  // one bottle left: delete is blocked and Fan is unavailable
  await page.evaluate(() => localStorage.setItem('arooma.v1', JSON.stringify({ v: 1, bottles: [{ id: 'only', house: 'Solo House', name: 'Only One' }] })));
  await reopenFast(page);
  check('with one bottle Fan is unavailable', await page.isDisabled('#seg button[data-mode="fan"]'));
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#del'); await page.waitForTimeout(400);
  check('the last bottle cannot be deleted', /Keep at least one/.test(await page.textContent('#toast')) && (await page.locator('.slot').count()) === 1);
  await page.screenshot({ path: path.join(outDir, '18-one-bottle.png') });
  await page.evaluate(() => localStorage.removeItem('arooma.v1'));

  check('no console or page errors', errors.length === 0, errors.join(' | '));

  // ---- desktop frame ----
  const dctx = await browser.newContext({ viewport: { width: 1200, height: 900 } });
  const dpage = await dctx.newPage();
  const derrors = [];
  dpage.on('pageerror', (e) => derrors.push(e.message));
  await dpage.goto(base); await dpage.waitForTimeout(5200);
  await dpage.screenshot({ path: path.join(outDir, '9-desktop.png') });
  check('desktop shows the framed device', (await dpage.locator('.slot').count()) === 7 && derrors.length === 0, derrors.join(' | '));


  // ---- Reduce Motion: the liquid stays flat at its true level, and nothing zooms ----
  const rctx = await browser.newContext({ viewport: { width: 393, height: 852 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true, reducedMotion: 'reduce' });
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
