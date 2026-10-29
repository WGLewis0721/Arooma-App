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
  await page.fill('#hDate', '2026-01-02'); await page.click('[data-act="addw"]'); await page.waitForTimeout(300);
  check('history adds a dated wear', (await page.locator('.hrow').count()) === rows0 + 1);
  await page.fill('#hDate', '2026-01-02'); await page.click('[data-act="addw"]'); await page.waitForTimeout(200);
  check('history rejects a duplicate date', /already logged/.test(await page.textContent('#hErr')));
  await page.evaluate(() => { const i = document.getElementById('hDate'); i.removeAttribute('max'); });
  await page.fill('#hDate', '2099-01-01'); await page.click('[data-act="addw"]'); await page.waitForTimeout(200);
  check('history rejects a future date', /not in the future/.test(await page.textContent('#hErr')));
  await page.click('[data-del="2026-01-02"]'); await page.waitForTimeout(300);
  check('history removes a wear', (await page.locator('.hrow').count()) === rows0);
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
  check('shelf image draws all eight bottles', (await page.locator('#ed figure').count()) === 8);
  await page.screenshot({ path: path.join(outDir, '16-share-eight.png') });
  await page.click('#saveImg'); await page.waitForTimeout(1500);
  check('share still receives a PNG with eight bottles', await page.evaluate(() => !!window.__shared && window.__shared.size > 20000));
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
  check('numbers stay in sequence after a delete', await page.evaluate(() => [...document.querySelectorAll('.slot .num')].map((e) => e.textContent.trim()).join('|') === ['01', '02', '03', '04', '05', '06', '07'].map((n) => 'N° ' + n).join('|')));

  // reset
  await page.click('#menu'); await page.waitForSelector('#panel.on'); await page.click('#reset'); await page.waitForTimeout(300);
  await page.click('#panel [data-act="yes"]'); await page.waitForTimeout(900);
  check('reset restores the seven sample bottles', (await page.locator('.slot').count()) === 7 && (await stored()) === null);

  // storage that is damaged or hostile must not break the app
  for (const [label, value] of [['malformed JSON', '{bad'], ['wrong shape', JSON.stringify({ v: 1, bottles: 'x' })],
    ['markup in a name', JSON.stringify({ v: 1, bottles: [{ id: 'a1', house: '<img src=x onerror=window.__xss=1>', name: '<b>x</b>', vessel: 'nope', log: ['x', '2026-02-30x', '2026-03-01'] }, { id: 'a2', house: 'H', name: 'N' }, { id: 'a3', house: 'H', name: 'N3' }] })]]) {
    await page.evaluate((v) => localStorage.setItem('arooma.v1', v), value);
    await reopenFast(page);
    const xss = await page.evaluate(() => window.__xss === 1);
    check('survives ' + label, (await page.locator('.slot').count()) >= 3 && !xss && errors.length === 0, errors.join(' | '));
  }
  check('markup in saved text is shown as text', await page.evaluate(() => document.querySelector('.slot .house').textContent.includes('<img')));

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

  // ---- smallest supported phone: 375 x 667 ----
  const sctx = await browser.newContext({ viewport: { width: 375, height: 667 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
  const spage = await sctx.newPage();
  const serr = [];
  spage.on('pageerror', (e) => serr.push(e.message));
  await spage.goto(base); await spage.waitForTimeout(300);
  await spage.evaluate(() => document.getElementById('cabinet').click()); await spage.waitForTimeout(2400);
  const noScroll = () => spage.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth + 1 && document.body.scrollWidth <= window.innerWidth + 1);
  check('375 wide: no horizontal scroll', await noScroll());
  check('375 wide: header buttons, wear, test and menu all fit', await spage.evaluate(() => ['addBtn', 'menu', 'wear', 'test', 'bMenu', 'pick'].every((id) => { const r = document.getElementById(id).getBoundingClientRect(); return r.left >= 0 && r.right <= window.innerWidth && r.width > 30; })));
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
  check('375x667: no page errors', serr.length === 0, serr.join(' | '));

  await browser.close();
  server.close();
  if (failures.length) { console.error('\n' + failures.length + ' check(s) failed'); process.exit(1); }
  console.log('\nAll checks passed');
})().catch((e) => { console.error(e); process.exit(1); });
