/* Focused release gate for the owner-directed Atelier edition.
   Runs core journeys on the real app. The legacy 200+ case suite remains available
   as tests/smoke.cjs for full regression work, but is not the polish-release gate. */
'use strict';
const fs=require('node:fs');
const path=require('node:path');
const http=require('node:http');
const {chromium}=require('playwright');
const root=path.resolve(process.argv[2]||'.');
const shots=path.resolve(process.argv[3]||'artifacts');
fs.mkdirSync(shots,{recursive:true});
const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.webp':'image/webp','.png':'image/png','.svg':'image/svg+xml','.json':'application/json','.webmanifest':'application/manifest+json'};
function serve(req,res){
 let url=new URL(req.url,'http://127.0.0.1');
 let p=path.resolve(root,'.'+(url.pathname==='/'?'/index.html':url.pathname));
 if(!p.startsWith(root+path.sep)){res.writeHead(403);res.end();return}
 fs.readFile(p,(err,data)=>{
  if(err){res.writeHead(404);res.end();return}
  res.writeHead(200,{'Content-Type':types[path.extname(p)]||'application/octet-stream','Cache-Control':'no-store'});
  res.end(data);
 });
}
function assert(cond,msg){if(!cond)throw new Error('Atelier QA failure: '+msg);console.log('PASS',msg)}
(async()=>{
 const server=http.createServer(serve);
 await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const addr='http://127.0.0.1:'+server.address().port+'/';
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 const ctx=await browser.newContext({viewport:{width:393,height:852},deviceScaleFactor:2,isMobile:true,hasTouch:true,
  userAgent:'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1'});
 const page=await ctx.newPage(),errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 try{
  await page.goto(addr,{waitUntil:'domcontentloaded'});
  await page.waitForTimeout(500);
  assert(await page.isVisible('#introV2'),'first run shows calligraphic Arooma');
  await page.screenshot({path:path.join(shots,'atelier-01-welcome.png')});
  await page.click('#introDemo');
  await page.waitForTimeout(650);
  assert((await page.locator('.at-nav button').count())===5,'five clear destinations');
  assert((await page.locator('.slot.collectible').count())>=3,'original collectible cards loaded');
  const photo=await page.evaluate(async()=>{
    const im=document.querySelector('.slot.collectible.is-sel .collectible-img');
    if(!im)return false;
    try{await im.decode()}catch(_){return false}
    return im.naturalWidth>=700&&/assets\/collectibles\/production\/dior\/front.webp/.test(im.getAttribute('src')||'');
  });
  assert(photo,'selected artwork is approved photographic Dior production asset');
  await page.screenshot({path:path.join(shots,'atelier-02-cover-flow-dark.png')});
  await page.click('.slot.collectible.is-sel');
  await page.waitForSelector('#inspector.on');
  assert(await page.isVisible('.inspector-card .collectible-img'),'focused card expands to Inspector');
  await page.screenshot({path:path.join(shots,'atelier-03-inspector.png')});
  await page.click('#inspectorFlip');await page.waitForTimeout(560);
  assert((await page.locator('.inspector-card.flipped').count())===1,'inspector flips to fragrance map');
  await page.screenshot({path:path.join(shots,'atelier-04-fragrance-map.png')});
  await page.click('#inspectorClose');
  await page.waitForSelector('#inspector.on',{state:'hidden'});
  await page.click('[data-at-tab="shelves"]');await page.waitForTimeout(700);
  assert((await page.locator('.at-shelf-tile').count())>=3,'shelves show collectible photo tiles');
  await page.screenshot({path:path.join(shots,'atelier-05-shelves.png')});
  await page.click('[data-at-tab="discover"]');
  await page.fill('#findIn','dior');
  await page.waitForTimeout(320);
  assert((await page.locator('#overScroll .hit').count())>=1,'search finds a fragrance directly');
  await page.screenshot({path:path.join(shots,'atelier-06-search.png')});
  await page.click('[data-at-tab="archive"]');await page.waitForTimeout(650);
  await page.click('[data-at-tab="bottle"]');await page.waitForSelector('#panel.on');
  assert(await page.isVisible('.at-owner-record'),'ownership sheet opens without menu hunting');
  assert((await page.locator('.at-owner-record [data-at-owner]').count())>=6,'ownership actions present');
  await page.screenshot({path:path.join(shots,'atelier-07-ownership.png')});
  await page.locator('.at-owner-record [data-at-owner="add"]').click();
  await page.waitForTimeout(570);
  const owned=await page.evaluate(()=>{
    const s=JSON.parse(localStorage.getItem('arooma.cabinet')||'null');
    return !!s&&s.bottles.length===1&&s.bottles[0].artKey==='dior';
  });
  assert(owned,'one tap copies approved card to Mine without losing artwork');
  await page.click('#wear');await page.waitForTimeout(400);
  assert(await page.evaluate(()=>{
    const s=JSON.parse(localStorage.getItem('arooma.cabinet')||'null');
    return s&&s.bottles[0].log.length>=1;
  }),'one tap records wear in personal collection');
  await page.reload({waitUntil:'domcontentloaded'});await page.waitForTimeout(510);
  assert(await page.evaluate(()=>{
    const s=JSON.parse(localStorage.getItem('arooma.cabinet')||'null');
    return s&&s.bottles.length===1&&s.bottles[0].artKey==='dior'&&s.bottles[0].log.length>=1;
  }),'owned art and wear survive reload');
  await page.click('[data-at-tab="style"]');await page.waitForSelector('#panel.on');
  await page.click('#panel .themeSwatch[data-palette="emerald"]');
  await page.click('#panel [data-look="light"]');await page.click('#panel [data-act="done"]');
  await page.waitForTimeout(350);
  assert(await page.evaluate(()=>document.querySelector('#device').dataset.appearance==='light'&&document.querySelector('#device').dataset.theme==='emerald'),'theme and appearance persist');
  await page.screenshot({path:path.join(shots,'atelier-08-light.png')});
  // Existing backup controls must remain connected to the engine.
  await page.click('[data-at-tab="bottle"]');await page.waitForSelector('#panel.on');
  await page.locator('.at-owner-record [data-at-owner="backup"]').click();
  assert(await page.locator('#panelBody').textContent().then(t=>t.includes('Export a backup')),'backup/restore path remains available');
  assert(errors.length===0,'no JavaScript page errors: '+errors.join('; '));
  console.log('Atelier focused release checks passed');
 }finally{await browser.close();await new Promise(r=>server.close(r));}
})().catch(e=>{console.error(e.stack||e);process.exit(1)});
