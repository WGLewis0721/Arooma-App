/* Arooma Atelier Edition — navigation, search, shelf and ownership experience.
   Uses the existing local-first engine through an intentionally small bridge.
   Does not touch the approved photography or replace saved user data.
*/
(function(){
'use strict';
function $(selector,root){return (root||document).querySelector(selector)}
function $$(selector,root){return Array.from((root||document).querySelectorAll(selector))}
var c=window.AroomaCore;
if(!c){document.documentElement.dataset.atelierFailed='bridge';return}
var shell=$('#device'),screen=$('#screen'),activeTab='archive',lastKey='';
var icons={
 archive:'<rect x="4" y="4" width="16" height="19" rx="2"/><path d="M8 8h8M8 13h8M8 18h5"/>',
 discover:'<circle cx="11" cy="11" r="6.5"/><path d="m16 16 5 5"/>',
 shelves:'<rect x="3" y="4" width="8" height="8" rx="1.5"/><rect x="13" y="4" width="8" height="8" rx="1.5"/><rect x="3" y="14" width="8" height="8" rx="1.5"/><rect x="13" y="14" width="8" height="8" rx="1.5"/>',
 bottle:'<path d="M9 3h6M10 3v4M14 3v4M8 7h8a3 3 0 0 1 3 3v10a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V10a3 3 0 0 1 3-3Z"/><path d="M9 13h6"/>',
 style:'<circle cx="12" cy="12" r="8.5"/><path d="M12 3.5v17M3.5 12h17"/>'
};
var tabs=[
 ['archive','Cards'],['discover','Search'],['shelves','Shelves'],['bottle','My Bottle'],['style','Style']
];
var nav=document.createElement('nav');
nav.className='at-nav';
nav.setAttribute('aria-label','Arooma main navigation');
nav.innerHTML=tabs.map(function(t){
 return '<button type="button" data-at-tab="'+t[0]+'" aria-current="'+(t[0]==='archive'?'page':'false')+'">'
  +'<svg viewBox="0 0 24 26" aria-hidden="true">'+icons[t[0]]+'</svg><span>'+t[1]+'</span></button>'
}).join('');
shell.appendChild(nav);
var identity=document.createElement('div');
identity.className='at-identity';
identity.id='atIdentity';
identity.setAttribute('aria-live','off');
identity.innerHTML='<div class="at-identity-main"><p class="at-house" id="atHouse">YOUR ARCHIVE</p><p class="at-fragrance" id="atFragrance">The collection</p></div><span class="at-counter" id="atCounter"></span>';
var info=$('#info');info.parentNode.insertBefore(identity,info);
var shelfEl=$('#overScroll'),selectedKey=null;
function setTab(key){
 activeTab=key;
 $$('button[data-at-tab]',nav).forEach(function(b){b.setAttribute('aria-current',b.dataset.atTab===key?'page':'false')});
}
function withColor(text){return c.esc(text||'')}
function picture(b,tag){
 return c.picture(b,tag);
}
function tile(b,i){
 var index=c.selectedIndex(),current=index===i;
 return '<button type="button" class="at-shelf-tile" data-b="'+i+'" aria-current="'+(current?'true':'false')+'" aria-label="Inspect '+withColor(b.house+' '+b.name)+'">'
  +'<span class="at-shelf-image">'+picture(b,'at-'+tagSafe(b.id))+'</span>'
  +'<strong>'+withColor(b.name)+'</strong><small>'+withColor(b.house)+'</small></button>';
}
function tagSafe(s){return String(s).replace(/[^a-z0-9]/gi,'')}
function renderShelves(){
 var shelves=c.shelves(),bottles=c.bottles(),selected=c.selected(),currentShelf=c.shelfId();
 var body=shelves.map(function(s){
  var indices=[];bottles.forEach(function(b,i){if(b.shelf===s.id)indices.push(i)});
  return '<section class="shelf'+(s.id===currentShelf?' cur':'')+'" data-id="'+withColor(s.id)+'">'
  +'<div class="sh-top"><button type="button" class="sname" data-open="'+withColor(s.id)+'">'+withColor(s.name)+'</button>'
  +'<span class="scount">'+String(indices.length).padStart(2,'0')+' '+(indices.length===1?'CARD':'CARDS')+'</span>'
  +'<button type="button" class="pen" data-pen="'+withColor(s.id)+'" aria-label="Rename '+withColor(s.name)+'">'+icons.style.replace('<circle','<circle')+'</button></div>'
  +(indices.length?'<div class="at-shelf-grid">'+indices.map(function(i){return tile(bottles[i],i)}).join('')+'</div>'
   :'<div class="sh-empty"><span>Nothing on this shelf yet.</span> <button type="button" class="sh-add" data-addto="'+withColor(s.id)+'">Add a fragrance</button></div>')
  +'</section>'
 }).join('');
 shelfEl.innerHTML=body||'<p class="nohit">Your archive begins with one fragrance.</p>';
 return true;
}
function normalize(s){return String(s||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase()}
function renderHits(){
 var q=normalize(c.query()).trim(),terms=q.split(/\s+/).filter(Boolean),bottles=c.bottles(),matches=[];
 bottles.forEach(function(b,i){
  var all=normalize([b.house,b.name,b.conc,b.notes,c.shelfName(b.shelf)].join(' '));
  if(terms.every(function(t){return all.includes(t)}))matches.push({b:b,i:i});
 });
 var html=matches.slice(0,70).map(function(x){
  var b=x.b;
  return '<button type="button" class="hit" data-b="'+x.i+'">'
   +'<span class="mb">'+picture(b,'at-search-'+tagSafe(b.id))+'</span>'
   +'<span><b>'+withColor(b.name)+'</b><small>'+withColor(b.house)+' · '+withColor(b.conc)+' · '+withColor(c.shelfName(b.shelf))+'</small></span></button>';
 }).join('');
 // Search real approved Arooma cards across collection boundaries without confusing EDT/EDP.
 var cardNames=c.curated();
 var ownKeys=new Set(bottles.map(function(b){return c.artKey(b)}).filter(Boolean));
 var extras=cardNames.filter(function(d){
  if(ownKeys.has(d.key))return false;
  var all=normalize([d.house,d.name,d.conc,d.notes||'',d.key].join(' '));
  return terms.every(function(t){return all.includes(t)});
 });
 html+=extras.map(function(d){
  return '<button type="button" class="hit" data-catalog="'+withColor(d.key)+'">'
    +'<span class="mb"><img src="'+c.artUrl(d.key,'front')+'" alt="" loading="lazy" decoding="async"></span>'
    +'<span><b>'+withColor(d.name)+'</b><small>'+withColor(d.house)+' · '+withColor(d.conc)+' · Add to my collection</small></span></button>';
 }).join('');
 shelfEl.innerHTML=html?'<p class="sub" role="status" style="padding:2px 0 13px">'+(matches.length+extras.length)+' '+(matches.length+extras.length===1?'result':'results')+'</p>'+html
 :'<p class="nohit" role="status">No fragrance matches “'+withColor(c.query().trim())+'”. Try a house, concentration or note.</p>';
 return true;
}
function sync(){
 var b=c.selected(),mode=c.storeMode(),shelf=c.shelfName(c.shelfId()),count=c.bottles().length,index=c.selectedIndex();
 var sig=[b&&b.id,mode,count,index,c.isOverview()].join(':');
 if(sig!==lastKey){
   lastKey=sig;
   $('#atHouse').textContent=b?b.house:'THE AROOMA ARCHIVE';
   $('#atFragrance').textContent=b?b.name:'Your collection awaits';
   $('#atCounter').textContent=index>=0?String(index+1).padStart(2,'0')+' / '+String(count).padStart(2,'0'):'00 / 00';
   var em=$('#eyebrow');
   if(em)em.textContent=(mode==='demo'?'CURATED DEMO':'PRIVATE COLLECTION')+'  ·  '+shelf.toUpperCase();
 }
 if(c.isOverview()&&activeTab==='archive')setTab('shelves');
 else if(!c.isOverview()&&(activeTab==='shelves'||activeTab==='discover'))setTab('archive');
}
function actionButton(label,act,primary){
 return '<button type="button" class="btn'+(primary?' primary':'')+'" data-at-owner="'+act+'">'+label+'</button>';
}
function metric(num,label){
 return '<div class="at-owner-stat"><strong>'+withColor(num)+'</strong><span>'+withColor(label)+'</span></div>';
}
function openOwner(){
 var b=c.selected();
 if(!b){c.add();return}
 var key=c.artKey(b),demo=c.storeMode()==='demo',count=b.log.length;
 var thumb='<div class="at-owner-thumb">'+picture(b,'at-record-'+tagSafe(b.id))+'</div>';
 var details='<div class="at-owner-hero">'+thumb
  +'<div><p class="at-owner-eyebrow">'+withColor(b.house)+'</p>'
  +'<h3 class="at-owner-name">'+withColor(b.name)+'</h3><p class="at-owner-sub">'+withColor(b.conc)+' · '+(b.ml||'—')+' ml<br>'+withColor(c.shelfName(b.shelf))+'</p></div></div>';
 var stats='<div class="at-owner-stats">'+metric(String(count),'Wears')
  +metric(Math.round((b.left||0)*100)+'%','Estimated left')
  +metric(count?c.lastWorn(b):'—','Last worn')+'</div>';
 var primary=demo&&key? actionButton('Add to Mine','add',true)
  : actionButton(c.wornToday(b)?'Worn today':'Wear today','wear',true);
 var actions='<div class="at-owner-actions">'+primary+actionButton('Wear history','history',false)+'</div>';
 var body='<div class="at-owner-record"><p class="at-owner-eyebrow">MY BOTTLE / OWNERSHIP</p>'
  +'<h2>Fragrance record</h2>'+details+stats
  +(b.note?'<p class="at-owner-notes">“'+withColor(b.note)+'”</p>':'')
  +actions+'<p class="at-owner-heading">Collection controls</p>'
  +actionButton('Edit details','edit',false)
  +actionButton('Move to shelf','move',false)
  +actionButton('Authenticity notes','auth',false)
  +actionButton('Export / restore','backup',false)
  +actionButton('Delete bottle','delete',false)+'</div>';
 // Remaining actions are a typographic list, not a row of decorative buttons.
 body=body.replace(/<p class="at-owner-heading">Collection controls<\/p>/,'<p class="at-owner-heading">Collection controls</p><div class="at-owner-links">')
    .replace(/<\/div>$/,'</div></div>');
 c.openPanel(body,function(e){
  var btn=e.target.closest('[data-at-owner]');if(!btn)return;
  var a=btn.dataset.atOwner;
  if(a==='add'){c.closePanel();c.addCurated();setTab('archive')}
  else if(a==='wear'){c.closePanel();c.wear()}
  else if(a==='history')c.history();
  else if(a==='edit')c.edit();
  else if(a==='move')c.move();
  else if(a==='auth')c.auth();
  else if(a==='backup')c.backup();
  else if(a==='delete')c.remove();
 });
}
function navAction(type){
 if(type==='archive'){c.closeOverview();setTab('archive')}
 if(type==='discover'){c.search();setTab('discover')}
 if(type==='shelves'){c.overview();setTab('shelves')}
 if(type==='bottle'){openOwner();setTab('bottle')}
 if(type==='style'){c.theme();setTab('style')}
}
nav.addEventListener('click',function(e){
 var b=e.target.closest('[data-at-tab]');if(b)navAction(b.dataset.atTab);
});
document.addEventListener('click',function(e){
 var b=e.target.closest('[data-at-owner]');if(!b)return;
});
// Keep focus visible and navigation state reversible.
document.addEventListener('keydown',function(e){
 if(e.key==='Escape'&&c.isOverview()){c.closeOverview();setTab('archive')}
});
function mark(){
 sync();
}

// A restrained foil rim that reacts to the actual pointer. No ambient loop,
// no device-orientation permission, no wash over the printed photography.
var stage=$('#stage'),foilCard=null,foilFrame=0;
function foilOff(){
 if(foilFrame)cancelAnimationFrame(foilFrame);
 foilFrame=0;
 if(foilCard){foilCard.style.setProperty('--at-foil-opacity','0');foilCard=null}
}
stage.addEventListener('pointermove',function(e){
 if(e.pointerType==='mouse'&&!e.buttons)return;
 var card=$('.slot.collectible.is-sel',stage);
 if(!card||window.matchMedia('(prefers-reduced-motion:reduce)').matches)return;
 if(foilFrame)cancelAnimationFrame(foilFrame);
 foilFrame=requestAnimationFrame(function(){
  var r=card.getBoundingClientRect();
  if(!r.width||!r.height)return;
  if(foilCard&&foilCard!==card)foilCard.style.setProperty('--at-foil-opacity','0');
  foilCard=card;
  var pct=Math.max(0,Math.min(1,(e.clientX-r.left)/r.width));
  card.style.setProperty('--at-foil-angle',(65+pct*95).toFixed(1)+'deg');
  card.style.setProperty('--at-foil-opacity','0.72');
 });
},{passive:true});
['pointerup','pointercancel','pointerleave'].forEach(function(type){
 stage.addEventListener(type,foilOff,{passive:true});
});

window.AroomaAtelier={
 renderShelves:renderShelves,
 renderHits:renderHits,
 sync:sync
};
mark();
})();
