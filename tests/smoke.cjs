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
    window.__col = () => { const d = JSON.parse(localStorage.getItem('arooma.v1') || 'null'); return d && (d.v >= 3 ? d[d.active] : d); };
    // Stand in for the iOS share sheet so the export path can be asserted.
    navigator.canShare = () => true;
    navigator.share = (d) => { window.__sharedFile = d.files[0]; window.__shared = { name: d.files[0].name, size: d.files[0].size, type: d.files[0].type }; return Promise.resolve(); };
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
  check('first run offers Start my collection or Explore demo', await page.evaluate(() => document.getElementById('welcome').classList.contains('on')) && await page.isVisible('#wStart') && await page.isVisible('#wDemo'));
  check('first run saves nothing before a choice', await page.evaluate(() => localStorage.getItem('arooma.v1') === null));
  await page.screenshot({ path: path.join(outDir, '1b-welcome.png') });
  await page.click('#wDemo'); await page.waitForTimeout(1600);
  await page.screenshot({ path: path.join(outDir, '2-cover-flow.png') });
  check('the demo is labeled as the demo', /Demo/.test(await page.textContent('#eyebrow')) && await page.isVisible('.demo-tag'));
  check('7 bottle cards rendered', (await page.locator('.slot').count()) === 7);
  check('cabinet opened and cleared', await page.evaluate(() => document.getElementById('cabinet').classList.contains('gone')));
  check('Cover Flow opens on Fig Hour, 02 of 06 on the Autumn shelf', (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '2' && (await page.textContent('#cap')).trim() === '02 / 06' && (await page.textContent('#title')) === 'Autumn shelf');
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
  check('Island shows a running timer', (await page.getAttribute('#island', 'data-s')) === 'compact' && /^\d+:\d\d$/.test((await page.textContent('.i-time')).trim()));
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
  check('the demo choice is saved as a separate collection', await page.evaluate(() => { const d = JSON.parse(localStorage.getItem('arooma.v1')); return d.v === 3 && d.active === 'demo' && !d.own && d.demo.bottles.length === 7; }));

  // full wear tracking
  const wearBtn = '#wear';
  const before = await page.evaluate(() => document.getElementById('meta').textContent);
  await page.click(wearBtn); await page.waitForTimeout(500);
  check('Wear today disables and reads Worn today', (await page.textContent(wearBtn)).includes('Worn today') && await page.isDisabled(wearBtn));
  check('wear is saved with today’s date', await page.evaluate(() => { const d = window.__col(); const t = new Date(); const ymd = t.getFullYear() + '-' + String(t.getMonth() + 1).padStart(2, '0') + '-' + String(t.getDate()).padStart(2, '0'); return d.bottles.some((b) => b.log[0] === ymd); }));
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
  check('a bottle added in the demo stays in the demo', await page.evaluate(() => { const d = JSON.parse(localStorage.getItem('arooma.v1')); return !d.own && d.demo.bottles.some((b) => b.name === 'Test Scent' && b.vessel === 'green' && b.sample === true); }));
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
  check('shelf image draws the seven bottles on the Autumn shelf and is titled by it', (await page.locator('#ed figure').count()) === 7 && /Seven objects/.test(await page.textContent('#ed')) && /Autumn shelf/.test(await page.textContent('#ed')));
  await page.screenshot({ path: path.join(outDir, '16-share-eight.png') });
  await page.click('#saveImg'); await page.waitForTimeout(1500);
  check('share still receives a PNG for the shelf', await page.evaluate(() => !!window.__shared && window.__shared.size > 20000));
  await page.click('#closeSheet'); await page.waitForTimeout(800);

  // persistence across reloads
  await reopenFast(page);
  check('shelf, wear and evidence survive a reload', (await page.locator('.slot').count()) === 8 && await page.evaluate(() => { const d = window.__col(); return d.bottles.some((b) => b.auth && b.auth.v.every((x) => x === 1)) && d.bottles.some((b) => b.log.length > 0); }));

  // delete with undo
  await page.focus('#stage'); for (let k = 0; k < 4; k++) await page.keyboard.press('ArrowRight');
  await page.waitForTimeout(900);
  check('keyboard reaches the added bottle', (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '7');
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#del'); await page.waitForTimeout(300);
  check('delete asks first', /Delete Test Scent\?/.test(await page.textContent('#panelBody')));
  await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('delete removes the bottle', (await page.locator('.slot').count()) === 7 && /07 objects/.test(await page.textContent('#eyebrow')));
  check('delete is saved', await page.evaluate(() => window.__col().bottles.length === 7));
  await page.screenshot({ path: path.join(outDir, '17-deleted-undo.png') });
  await page.click('.toast.on .tact'); await page.waitForTimeout(900);
  check('Undo puts the bottle back where it was', (await page.locator('.slot').count()) === 8 && (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '7');
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#del'); await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('numbers restart on each shelf and stay in sequence after a delete', await page.evaluate(() => [...document.querySelectorAll('.slot')].sort((a, b) => a.dataset.i - b.dataset.i).map((el) => el.querySelector('.num').textContent.trim()).join('|') === ['01', '01', '02', '03', '04', '05', '06'].map((n) => 'N° ' + n).join('|')));

  // reset
  await page.click('#menu'); await page.waitForSelector('#panel.on'); await page.click('#resetdemo'); await page.waitForTimeout(300);
  await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('Reset demo restores the seven demo bottles, and the demo only', (await page.locator('.slot').count()) === 7 && await page.evaluate(() => window.__col().bottles.length === 7));


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
  check('pinching out over an empty shelf opens its empty state', (await ttl()) === 'Spring shelf' && await page.isVisible('#eAdd'));
  await page.screenshot({ path: path.join(outDir, '21b-empty-shelf.png') });
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
  check('rename shows in the overview and is saved', (await page.textContent('.shelf[data-id="su"] .sname')) === 'Weekend rotation' && await page.evaluate(() => window.__col().shelves.some((h) => h.id === 'su' && h.name === 'Weekend rotation')));
  await page.click('.sname[data-open="su"]'); await page.waitForTimeout(900);
  check('the renamed shelf titles its own view', (await ttl()) === 'Weekend rotation' && (await page.getAttribute('.slot[tabindex="0"]', 'data-i')) === '0');
  await page.screenshot({ path: path.join(outDir, '22-renamed-shelf.png') });

  // add a shelf in the zoomed-out view, then put a bottle on it
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  await page.click('#addShelf'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(300);
  await page.click('[data-act="save"]');
  check('a new shelf needs a name', /Give the shelf a name/.test(await page.textContent('#nsErr')));
  await page.fill('#nsName', 'Evenings'); await page.click('[data-act="save"]'); await page.waitForTimeout(900);
  check('a new shelf appears in the overview, empty, and is saved', (await page.locator('.shelf').count()) === 5 && (await page.textContent('.shelf:last-child .sname')) === 'Evenings' && /Nothing here yet/.test(await page.textContent('.shelf:last-child')) && await page.evaluate(() => window.__col().shelves.length === 5));
  await page.screenshot({ path: path.join(outDir, '23-new-shelf.png') });
  await page.click('.shelf:last-child .sh-add'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(300);
  check('Add a bottle on an empty shelf preselects that shelf', (await page.evaluate(() => document.getElementById('fShelf').selectedOptions[0].textContent)) === 'Evenings');
  await page.fill('#fHouse', 'Shelf House'); await page.fill('#fName', 'Late Hour'); await page.click('[data-act="save"]'); await page.waitForTimeout(1200);
  check('the bottle lands on the new shelf', await page.evaluate(() => window.__col().bottles.some((b) => b.name === 'Late Hour' && b.shelf !== 'au')) && (await page.locator('.shelf:last-child .mb').count()) === 1);
  await page.click('#openShelf'); await page.waitForTimeout(900);
  check('opening it shows a one-bottle shelf', (await ttl()) === 'Evenings' && (await page.textContent('#cap')).trim() === '01 / 01');

  // move a bottle to another shelf; Undo moves it back
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#move'); await page.waitForTimeout(300);
  await page.click('[data-sh="au"]'); await page.waitForTimeout(1100);
  check('Move puts the bottle on the other shelf and follows it', (await ttl()) === 'Autumn shelf' && (await page.textContent('#cap')).trim() === '07 / 07');
  await page.click('.toast.on .tact'); await page.waitForTimeout(1100);
  check('Undo moves it back', (await ttl()) === 'Evenings' && (await page.textContent('#cap')).trim() === '01 / 01');
  // an empty shelf can be removed, with Undo
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#move'); await page.click('[data-sh="au"]'); await page.waitForTimeout(1100);
  await page.click('#shelvesBtn'); await page.waitForTimeout(900);
  const evId = await page.evaluate(() => window.__col().shelves.find((h) => h.name === 'Evenings').id);
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
  let peak = [];
  for (let tryN = 0; tryN < 3; tryN++) {
    // a swipe is timing-sensitive under a loaded CI runner; take the best of three
    await page.mouse.move(300, 420); await page.mouse.down();
    for (let i = 1; i <= 8; i++) { await page.mouse.move(300 - i * 14, 420); await page.waitForTimeout(12); }
    await page.mouse.up();
    const pk = [];
    for (let k = 0; k < 26; k++) { await page.waitForTimeout(40); const v = await surf('.slot[tabindex="0"] .lq'); pk.push(v[0] - v[1]); }
    if (Math.max(...pk) - Math.min(...pk) > Math.max(...peak, 0) - Math.min(...peak, 0)) peak = pk;
    if (Math.max(Math.max(...peak), -Math.min(...peak)) > 3 && Math.min(Math.max(...peak), -Math.min(...peak)) > 1.5) break;
    await page.waitForTimeout(2500);
    while ((await page.getAttribute('.slot[tabindex="0"]', 'data-i')) !== '2') { await page.keyboard.press('ArrowLeft'); await page.waitForTimeout(450); }
  }
  check('a swipe sloshes the liquid, with momentum: it tilts one way then the other', Math.max(Math.max(...peak), -Math.min(...peak)) > 3 && Math.min(Math.max(...peak), -Math.min(...peak)) > 1.5, 'tilt range ' + Math.min(...peak).toFixed(1) + ' to ' + Math.max(...peak).toFixed(1));
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
    check('survives ' + label, ((await page.locator('.slot').count()) >= 3 || await page.evaluate(() => document.getElementById('welcome').classList.contains('on'))) && !xss && errors.length === 0, errors.join(' | '));
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
  check('FR-6: a v1 save of the owner’s bottles migrates to schema 3 as their own collection', await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).v === 3) && await page.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).active === 'own') && !(await page.isVisible('.demo-tag')));
  await page.click('#seg button[data-mode="fan"]'); await page.waitForSelector('#panel.on'); await page.waitForTimeout(300);
  check('Fan with no saved rotation offers to make one', /rotation/i.test(await page.textContent('#panelBody')));
  await page.click('#panel [data-act="cancel"]'); await page.waitForTimeout(800);
  await page.click('#bMenu'); await page.waitForSelector('#panel.on'); await page.click('#del'); await page.waitForTimeout(300);
  await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('FR-3: the last bottle can be deleted, leaving the empty state', (await page.locator('.slot').count()) === 0 && await page.isVisible('#eAdd'));
  await page.screenshot({ path: path.join(outDir, '18-one-bottle.png') });
  await page.evaluate(() => localStorage.removeItem('arooma.v1'));


  // ================= polish pass acceptance: first run, own collection, photos, wear loop, rotations, backup =================
  {
    const actx = await browser.newContext({ viewport: { width: 393, height: 852 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
    await actx.addInitScript(() => {
      navigator.canShare = () => true;
      navigator.share = (d) => { window.__sharedFile = d.files[0]; return Promise.resolve(); };
    });
    const a = await actx.newPage();
    const aerr = [];
    a.on('pageerror', (e) => aerr.push('pageerror: ' + e.message));
    a.on('console', (m) => { if (m.type() === 'error') aerr.push('console: ' + m.text()); });
    const raw = () => a.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1') || 'null'));
    const menu = async (row) => { await a.click('#menu'); await a.waitForSelector('#panel.on'); await a.waitForTimeout(250); await a.click('#' + row); await a.waitForTimeout(400); };
    const yes = async () => { await a.click('#panel [data-act="yes"]'); await a.waitForTimeout(900); };
    const capT = async () => (await a.textContent('#cap')).trim();
    const selName = () => a.evaluate(() => { const el = document.querySelector('.slot[tabindex="0"]'); return el ? el.querySelector('.nm').textContent : null; });
    const addB = async (house, name, extra) => {
      await a.click(await a.isVisible('#eAdd') ? '#eAdd' : '#addBtn'); await a.waitForSelector('#panel.on'); await a.waitForTimeout(300);
      await a.fill('#fHouse', house); await a.fill('#fName', name);
      if (extra) await extra();
      await a.click('[data-act="save"]'); await a.waitForTimeout(1300);
    };

    await a.goto(base); await a.waitForTimeout(300);
    await a.evaluate(() => document.getElementById('cabinet').click()); await a.waitForTimeout(1500);
    await a.click('#wStart'); await a.waitForTimeout(1200);
    check('FR-1: Start my collection opens a truly empty cabinet', (await a.locator('.slot').count()) === 0 && await a.evaluate(() => { const d = JSON.parse(localStorage.getItem('arooma.v1')); return d.active === 'own' && d.own.bottles.length === 0 && !d.demo; }));
    check('FR-4: the empty shelf has a clear Add a bottle action', await a.isVisible('#eAdd') && /bottle/i.test(await a.textContent('#eAdd')));
    check('FR-2: the own collection is not labeled as demo', !(await a.isVisible('.demo-tag')) && !/Demo/.test(await a.textContent('#eyebrow')));
    check('with nothing on the shelf, Fan is unavailable', await a.isDisabled('#seg button[data-mode="fan"]'));
    await a.screenshot({ path: path.join(outDir, '30-empty-start.png') });

    await menu('find'); await a.click('#panel [data-act="cancel"]'); await a.waitForTimeout(700);
    await a.click('#menu'); await a.waitForSelector('#panel.on'); await a.waitForTimeout(250);
    const note = await a.textContent('#storeNote');
    check('BK-4: the menu says data lives on this device and suggests a backup', /on this device/.test(note) && /No backup yet/.test(note));
    check('FR-5: Clear and Load demo are separate menu actions', (await a.locator('#clear').count()) === 1 && (await a.locator('#demo').count()) === 1);
    await a.click('#scrim', { position: { x: 20, y: 20 } }); await a.waitForTimeout(700);

    // BP: a user photo, tall and narrow, is cropped to cover, never stretched
    const png = Buffer.from(await a.evaluate(() => { const c = document.createElement('canvas'); c.width = 120; c.height = 360; const g = c.getContext('2d'); g.fillStyle = '#6b4a2a'; g.fillRect(0, 0, 120, 360); g.fillStyle = '#ddd'; g.fillRect(40, 20, 40, 60); return c.toDataURL('image/png').split(',')[1]; }), 'base64');
    await addB('Own House', 'Amber Study', async () => {
      await a.setInputFiles('#fPhoto', { name: 'bottle.png', mimeType: 'image/png', buffer: png }); await a.waitForTimeout(900);
      check('BP-2: the photo previews with position controls', await a.isVisible('#phPrev') && await a.isVisible('#pZ'));
      await a.fill('#fNotes', 'amber, vanilla, labdanum');
    });
    check('BP-1: the bottle shows the owner’s photo, cropped to cover, never stretched', await a.evaluate(() => { const i = document.querySelector('.slot[tabindex="0"] img'); return !!i && getComputedStyle(i).objectFit === 'cover' && i.src.startsWith('data:image/jpeg'); }));
    check('BP-1: the photo is saved with the bottle', await a.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).own.bottles[0].photo.src.startsWith('data:image/jpeg')));
    check('CM-4: the first bottle lands at 01 / 01', (await capT()) === '01 / 01');

    // CM-5: long names, missing optional fields, duplicates
    const longName = 'An Extremely Long Fragrance Name Past Edge'.slice(0, 40);
    await addB('Duplicate House', longName);
    await addB('Duplicate House', longName);
    check('CM-5: a duplicate is allowed and kept as its own bottle', await a.evaluate((n) => JSON.parse(localStorage.getItem('arooma.v1')).own.bottles.filter((b) => b.name === n).length === 2, longName));
    check('CM-4: an added bottle lands at the end of its shelf and is selected', (await capT()) === '03 / 03');
    check('CM-5: a long name stays inside its card', await a.evaluate(() => { const el = document.querySelector('.slot[tabindex="0"] .nm'); return el.scrollWidth > el.clientWidth ? getComputedStyle(el).textOverflow === 'ellipsis' : el.getBoundingClientRect().right <= document.querySelector('.slot[tabindex="0"]').getBoundingClientRect().right + 1; }));
    await a.screenshot({ path: path.join(outDir, '31-own-three.png') });

    // CM-1 search, CM-2 edit
    await a.focus('#stage'); await a.keyboard.press('/'); await a.waitForSelector('#panel.on'); await a.waitForTimeout(300);
    await a.fill('#qFind', 'amber'); await a.waitForTimeout(200);
    check('CM-1: search finds by fragrance name', (await a.locator('#qRes [data-go]').count()) === 1);
    await a.fill('#qFind', 'duplicate'); await a.waitForTimeout(200);
    check('CM-1: search finds by house', (await a.locator('#qRes [data-go]').count()) === 2);
    await a.fill('#qFind', 'AMBÉR'); await a.waitForTimeout(200);
    check('CM-1: search ignores case and accents', (await a.locator('#qRes [data-go]').count()) === 1);
    await a.click('#qRes [data-go]'); await a.waitForTimeout(1000);
    check('CM-1: picking a result selects that bottle', (await selName()) === 'Amber Study');
    check('CM-2: the selected card shows an edit pencil', await a.isVisible('.slot[tabindex="0"] .cpen'));
    await a.click('.slot[tabindex="0"] .cpen'); await a.waitForSelector('#panel.on'); await a.waitForTimeout(300);
    check('CM-2: the pencil opens the edit form for that bottle', (await a.inputValue('#fName')) === 'Amber Study');
    await a.fill('#fName', 'Amber Study II'); await a.click('[data-act="save"]'); await a.waitForTimeout(1100);
    check('CM-2: the edit is saved in place', (await selName()) === 'Amber Study II' && (await capT()) === '01 / 03');

    // WL: one-tap wear, optional impression, timeline
    await a.click('#wear'); await a.waitForTimeout(600);
    check('WL-1: one tap logs a wear and confirms quietly', (await a.textContent('#wear')).includes('Worn today') && (await a.locator('.toast.on').count()) === 1 && (await a.locator('#panel.on').count()) === 0);
    check('WL-2: an optional impression is offered, not forced', await a.isVisible('#impBtn') && /how it wore/i.test(await a.textContent('#impBtn')));
    await a.click('#impBtn'); await a.waitForSelector('#panel.on'); await a.waitForTimeout(300);
    await a.fill('#iO', 'bright resin'); await a.click('.seg3.imp[data-k="p"] button[data-val="moderate"]'); await a.click('.seg3.imp[data-k="l"] button[data-val="long"]');
    await a.click('[data-act="saveI"]'); await a.waitForTimeout(900);
    check('WL-2: the impression is attached to today’s wear', /Today/.test(await a.textContent('#impBtn')) && await a.evaluate(() => { const b = JSON.parse(localStorage.getItem('arooma.v1')).own.bottles.find((x) => x.name === 'Amber Study II'); const k = Object.keys(b.imp)[0]; return b.log.includes(k) && b.imp[k].p === 'moderate' && b.imp[k].l === 'long' && b.imp[k].o === 'bright resin'; }));
    await a.click('.slot[tabindex="0"]'); await a.waitForTimeout(1100);
    const rec = await a.textContent('.slot[tabindex="0"] .rec-tl');
    check('WL-3: the record shows a timeline with the impression', /Moderate/.test(rec) && /All day/.test(rec));
    check('WO-1: the record says Estimated remaining', /Estimated remaining/.test(await a.textContent('.slot[tabindex="0"]')) && !/true liquid level/i.test(await a.evaluate(() => document.body.innerText)));
    await a.screenshot({ path: path.join(outDir, '32-record-timeline.png') });
    await a.click('.slot[tabindex="0"]'); await a.waitForTimeout(900);

    // PL-2: Stack chooses, Fan presents a saved rotation; CM-3 selection persists
    await a.click('#seg button[data-mode="stack"]'); await a.waitForTimeout(1000);
    check('PL-2: Stack reads as a shortlist', /Shortlist/.test(await capT()) && (await selName()) === 'Amber Study II');
    await a.click('#seg button[data-mode="fan"]'); await a.waitForSelector('#panel.on'); await a.waitForTimeout(400);
    check('PL-2: Fan with no rotation asks for one', /rotation/i.test(await a.textContent('#panelBody')));
    await a.click('#panel [data-act="newrot"]'); await a.waitForTimeout(400);
    await a.fill('#rName', 'Weekdays');
    const picks = a.locator('#rList [data-pick][aria-pressed="false"]');
    await picks.first().click(); await a.waitForTimeout(150);
    check('a rotation counts its bottles', /2 of 5/.test(await a.textContent('#rCount')));
    await a.click('[data-act="saveR"]'); await a.waitForTimeout(1600);
    if (await a.locator('#panel.on').count()) { await a.click('#scrim', { position: { x: 20, y: 20 } }); await a.waitForTimeout(800); }
    if ((await a.getAttribute('#seg button[data-mode="fan"]', 'aria-pressed')) !== 'true') { await a.click('#seg button[data-mode="fan"]'); await a.waitForTimeout(1200); }
    check('PL-2: Fan presents the saved rotation by name', /Weekdays/.test(await capT()));
    check('CM-3: the selected bottle stays selected in Fan', (await selName()) === 'Amber Study II');
    await a.screenshot({ path: path.join(outDir, '33-fan-rotation.png') });
    await a.click('#seg button[data-mode="flow"]'); await a.waitForTimeout(900);
    check('CM-3: and back in Cover Flow', (await selName()) === 'Amber Study II' && (await capT()) === '01 / 03');

    // CM-4: delete keeps a predictable neighbor; Undo restores the slot
    await a.focus('#stage'); await a.keyboard.press('ArrowRight'); await a.waitForTimeout(700);
    await a.click('#bMenu'); await a.waitForSelector('#panel.on'); await a.click('#del'); await a.waitForTimeout(300); await yes();
    check('CM-4: after a delete the next bottle takes the slot', (await capT()) === '02 / 02');
    await a.click('.toast.on .tact'); await a.waitForTimeout(900);
    check('CM-4: Undo puts it back in the same slot', (await capT()) === '02 / 03');

    // BK-1..3: export, clear, import round-trip
    const before = await a.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).own);
    await a.evaluate(() => { window.__sharedFile = null; });
    await menu('backup'); await a.waitForTimeout(800);
    const backupText = await a.evaluate(async () => window.__sharedFile ? { name: window.__sharedFile.name, text: await window.__sharedFile.text() } : null);
    const bk = backupText && JSON.parse(backupText.text);
    check('BK-1: the backup is a JSON file with every shelf, bottle, photo, wear, impression and rotation', !!bk && /^arooma-backup-\d{4}-\d\d-\d\d\.json$/.test(backupText.name) && bk.app === 'Arooma' && bk.schema === 3 && bk.collection.shelves.length === before.shelves.length && bk.collection.bottles.length === 3 && bk.collection.rots.length === 1 && bk.collection.bottles.some((b) => b.photo && Object.keys(b.imp).length === 1 && b.log.length === 1));
    check('BK-4: the last backup date is remembered', await a.evaluate(() => !!JSON.parse(localStorage.getItem('arooma.v1')).own.meta.backupAt));
    await menu('clear');
    check('FR-5: Clear asks first and says what it removes', /Clear your collection\?/.test(await a.textContent('#panelBody')) && /3 bottles/.test(await a.textContent('#panelBody')));
    await yes();
    check('FR-5: Clear empties the collection', (await a.locator('.slot').count()) === 0 && await a.isVisible('#eAdd'));
    const file = { name: 'arooma-backup.json', mimeType: 'application/json', buffer: Buffer.from(backupText.text) };
    await a.setInputFiles('#importFile', file); await a.waitForSelector('#panel.on'); await a.waitForTimeout(400);
    const rv = await a.textContent('#panelBody');
    check('BK-2: import reviews the file and states merge or replace before changing anything', /3 bottles/.test(rv) && (await a.locator('#merge').count()) === 1 && (await a.locator('#replace').count()) === 1 && await a.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).own.bottles.length === 0));
    await a.click('#replace'); await a.waitForTimeout(300);
    check('BK-2: replace asks a second time', /Replace your collection\?/.test(await a.textContent('#panelBody')));
    await yes();
    const after = await a.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).own);
    const strip = (c) => JSON.stringify({ shelves: c.shelves, bottles: c.bottles, rots: c.rots });
    check('BK-3: export, clear, import round-trips to an identical collection', strip(before) === strip(after), strip(before).length + ' vs ' + strip(after).length);
    check('BK-3: the restored shelf renders', (await a.locator('.slot').count()) === 3);
    await a.setInputFiles('#importFile', file); await a.waitForSelector('#panel.on'); await a.waitForTimeout(300);
    check('BK-2: merging the same backup adds nothing', /0 new bottles/.test(await a.textContent('#panelBody')));
    await a.click('#merge'); await a.waitForTimeout(900);
    check('BK-2: and merge keeps every bottle as it was', await a.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).own.bottles.length === 3));
    for (const [label, txt] of [['not JSON', '{bad'], ['another app', JSON.stringify({ app: 'Other', bottles: [] })], ['a newer schema', JSON.stringify({ app: 'Arooma', kind: 'backup', schema: 99, collection: { bottles: [] } })]]) {
      await a.setInputFiles('#importFile', { name: 'x.json', mimeType: 'application/json', buffer: Buffer.from(txt) }); await a.waitForSelector('#panel.on'); await a.waitForTimeout(300);
      check('BK-2: an invalid file (' + label + ') is refused and nothing changes', /Can’t restore/.test(await a.textContent('#panelBody')) && /Nothing was changed/.test(await a.textContent('#panelBody')) && await a.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).own.bottles.length === 3));
      await a.click('#panel [data-act="cancel"]'); await a.waitForTimeout(700);
    }

    // FR-2, FR-5: load the demo, confirmed, and it never touches the own collection
    await menu('demo');
    check('FR-5: Explore the demo asks first', /Explore the demo\?/.test(await a.textContent('#panelBody')));
    await yes();
    check('FR-2: the demo is labeled and the own collection is untouched', await a.isVisible('.demo-tag') && await a.evaluate(() => { const d = JSON.parse(localStorage.getItem('arooma.v1')); return d.active === 'demo' && d.own.bottles.length === 3 && d.demo.bottles.every((b) => b.sample) && !d.own.bottles.some((b) => b.sample); }));
    await a.click('#bMenu'); await a.waitForSelector('#panel.on'); await a.click('#del'); await a.waitForTimeout(300); await yes();
    check('FR-3: a demo sample can be deleted too', await a.evaluate(() => JSON.parse(localStorage.getItem('arooma.v1')).demo.bottles.length === 6));
    check('WO-3: demo has no backup action; it is not the owner’s data', await (async () => { await a.click('#menu'); await a.waitForSelector('#panel.on'); await a.waitForTimeout(250); const n = await a.locator('#backup').count(); await a.click('#scrim', { position: { x: 20, y: 20 } }); await a.waitForTimeout(700); return n === 0; })());
    await menu('mine'); await a.waitForTimeout(600);
    check('FR-2: back to my collection, exactly as left', (await a.locator('.slot').count()) === 3 && !(await a.isVisible('.demo-tag')));

    // WO-4: the timer has check-ins, not a 30 second default
    await a.click('#test'); await a.waitForTimeout(700);
    const t0 = (await a.textContent('.i-time')).trim();
    check('WO-4: the testing timer runs to a 15 minute check-in, not a 30 second default', /^1[45]:\d\d$/.test(t0) && (await a.getAttribute('#island', 'data-s')) === 'compact', t0);
    await a.click('#island'); await a.waitForTimeout(600); await a.click('#iEnd'); await a.waitForTimeout(600);
    check('closing a panel leaves the page unscrolled', await a.evaluate(() => window.scrollY === 0 && document.getElementById('device').scrollTop === 0));
    check('no page errors in the polish pass flows', aerr.length === 0, aerr.join(' | '));
    await actx.close();
  }

  // ================= CM-5: a 60 bottle collection stays quick =================
  {
    const bctx = await browser.newContext({ viewport: { width: 393, height: 852 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
    const b = await bctx.newPage();
    const berr = []; b.on('pageerror', (e) => berr.push(e.message));
    await b.goto(base);
    await b.evaluate(() => {
      const vs = ['clear', 'amber', 'smoke', 'green', 'white', 'ink'];
      const bottles = Array.from({ length: 60 }, (_, i) => ({ id: 'b' + i, shelf: 'au', house: 'House ' + (i % 9), name: 'Bottle ' + (i + 1), conc: 'EDP', ml: 50, left: (i * 7) % 100, notes: i % 3 ? 'cedar, iris' : '', vessel: vs[i % vs.length], log: [], imp: {} }));
      localStorage.setItem('arooma.v1', JSON.stringify({ v: 3, active: 'own', own: { shelves: [{ id: 'sp', name: 'Spring shelf' }, { id: 'su', name: 'Summer shelf' }, { id: 'au', name: 'Autumn shelf' }, { id: 'wi', name: 'Winter shelf' }], bottles, rots: [], meta: {} } }));
    });
    await b.reload(); await b.waitForTimeout(300);
    await b.evaluate(() => document.getElementById('cabinet').click()); await b.waitForTimeout(2000);
    check('CM-5: 60 bottles load onto one shelf', (await b.locator('.slot').count()) === 60 && /\/ 60$/.test((await b.textContent('#cap')).trim()));
    const ms = await b.evaluate(async () => { const st = document.getElementById('stage'); st.focus(); const t = performance.now(); for (let i = 0; i < 20; i++) { st.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true })); await new Promise((r) => requestAnimationFrame(r)); } return performance.now() - t; });
    await b.waitForTimeout(900);
    check('CM-5: twenty steps through 60 bottles stay under a frame budget', ms < 20 * 50 && /21 \/ 60/.test((await b.textContent('#cap')).trim()), Math.round(ms) + ' ms');
    await b.focus('#stage'); await b.keyboard.press('/'); await b.waitForSelector('#panel.on'); await b.fill('#qFind', 'bottle 6'); await b.waitForTimeout(200);
    check('CM-5: search narrows a large shelf', (await b.locator('#qRes [data-go]').count()) === 2);
    await b.click('#qRes [data-go]:last-child'); await b.waitForTimeout(900);
    check('CM-5: and jumps to the bottle', /\/ 60$/.test((await b.textContent('#cap')).trim()) && berr.length === 0, berr.join(' | '));
    await b.screenshot({ path: path.join(outDir, '34-sixty.png') });
    await bctx.close();
  }

  check('no console or page errors', errors.length === 0, errors.join(' | '));

  // ---- desktop frame ----
  const dctx = await browser.newContext({ viewport: { width: 1200, height: 900 } });
  const dpage = await dctx.newPage();
  const derrors = [];
  dpage.on('pageerror', (e) => derrors.push(e.message));
  await dpage.goto(base); await dpage.waitForTimeout(5200); await dpage.click('#wDemo'); await dpage.waitForTimeout(1500);
  await dpage.screenshot({ path: path.join(outDir, '9-desktop.png') });
  check('desktop shows the framed device', (await dpage.locator('.slot').count()) === 7 && derrors.length === 0, derrors.join(' | '));


  // ---- Reduce Motion: the liquid stays flat at its true level, and nothing zooms ----
  const rctx = await browser.newContext({ viewport: { width: 393, height: 852 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true, reducedMotion: 'reduce' });
  const rpage = await rctx.newPage();
  const rerr = [];
  rpage.on('pageerror', (e) => rerr.push(e.message));
  await rpage.goto(base); await rpage.waitForTimeout(300);
  await rpage.evaluate(() => document.getElementById('cabinet').click()); await rpage.waitForTimeout(800); await rpage.click('#wDemo'); await rpage.waitForTimeout(1000);
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
  await spage.evaluate(() => document.getElementById('cabinet').click()); await spage.waitForTimeout(2400); await spage.click('#wDemo'); await spage.waitForTimeout(1200);
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
