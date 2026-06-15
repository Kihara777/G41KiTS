/* ═══════════ G41 core: init, i18n, status, detail ── */
function $json(url){return fetch(url).then(function(r){return r.json();});}

var LANGS=['ja','zh','en'],I18N={},lang,TILES,CHARS,STATUS;
var METRO=['lime','cobalt','magenta','teal','amber','emerald'];

function computeHC(){
  var cs=getComputedStyle(document.documentElement);
  var sheet=document.createElement('style');sheet.id='g41-hc-dynamic';
  ['lime','green','emerald','teal','cobalt','indigo','violet','magenta','red','orange','amber','yellow','brown','olive','steel','mauve'].forEach(function(c){
    var hex=cs.getPropertyValue('--wp-'+c).trim(),r,g,b,lum;
    if(!hex)return;
    r=parseInt(hex.slice(1,3),16);g=parseInt(hex.slice(3,5),16);b=parseInt(hex.slice(5,7),16);
    lum=(0.299*r+0.587*g+0.114*b)/255;
    sheet.textContent+='.g41-hc .t-wp-'+c+'{background:rgba(0,0,0,'+(0.3+lum*0.65).toFixed(2)+')}';
  });
  document.head.appendChild(sheet);
}

Promise.all([
  $json('/data/tiles'),$json('/data/home/chars'),$json('/data/home/status'),
  $json('/data/i18n_ja'),$json('/data/i18n_zh'),$json('/data/i18n_en')
]).then(function(d){
  TILES=d[0];CHARS=d[1];STATUS=d[2];
  I18N.ja=d[3];I18N.zh=d[4];I18N.en=d[5];window.G41_I18N=I18N;
  try{computeHC();}catch(e){console.error(e);}
  init();
}).catch(function(e){console.error('G41 init failed:',e);});

function detectLang(){var n=(navigator.language||'').toLowerCase();return n.indexOf('ja')===0?'ja':n.indexOf('zh')===0?'zh':'en';}
function t(k,i){var v=I18N[lang];v=v&&v[k]!==undefined?v[k]:k;if(!Array.isArray(v))return v;return i!==undefined?v[i]:v[0];}
window.G41_T=t;

var dom={};

function init(){
  lang=localStorage.getItem('g41-lang');
  if(!lang||LANGS.indexOf(lang)===-1){lang=detectLang();localStorage.setItem('g41-lang',lang);}
  window.G41_LANG=lang;
  ['g41-title','g41-greet','g41-character','g41-char-img','g41-char-msg',
   'g41-tiles','g41-contrast','g41-bg-img','g41-detail-title','g41-detail-body',
   'g41-back','g41-view-main','g41-view-detail','g41-lang'].forEach(function(id){dom[id]=document.getElementById(id);});
  if(localStorage.getItem('g41-hc')==='1')document.documentElement.classList.add('g41-hc');
  dom['g41-contrast'].addEventListener('click',function(){
    var on=document.documentElement.classList.toggle('g41-hc');localStorage.setItem('g41-hc',on?'1':'0');
  });
  var langMenu=document.getElementById('g41-lang-menu'),langBtn=dom['g41-lang'];
  LANGS.forEach(function(l){
    var b=document.createElement('button');b.className='lang-opt';b.dataset.lang=l;b.textContent=I18N[l].lang;
    langMenu.appendChild(b);
  });
  function setLangUI(){langBtn.textContent=I18N[lang].lang;langMenu.querySelectorAll('.lang-opt').forEach(function(o){o.classList.toggle('active',o.dataset.lang===lang);});}
  setLangUI();
  langBtn.addEventListener('click',function(e){e.stopPropagation();langMenu.classList.toggle('open');});
  document.addEventListener('click',function(){langMenu.classList.remove('open');});
  langMenu.addEventListener('click',function(e){var b=e.target.closest('.lang-opt');if(!b)return;lang=b.dataset.lang;localStorage.setItem('g41-lang',lang);window.G41_LANG=lang;langMenu.classList.remove('open');setLangUI();reload();});
  dom['g41-back'].addEventListener('click',closeDetail);
  dom['g41-view-main'].classList.add('main-entry');
  reload();
}

function findStatus(code){
  var M=CHARS.msgs;
  for(var i=0;i<STATUS.length;i++){
    var s=STATUS[i];
    if(s.code===String(code))return{msg:M[s.msg]||s.msg,img:s.img};
    if(s.code==='2xx'&&code>=200&&code<300)return{msg:M[s.msg]||s.msg,img:s.img};
    if(s.code==='3xx'&&code>=300&&code<400)return{msg:M[s.msg]||s.msg,img:s.img};
    if(s.code==='4xx'&&code>=400&&code<500)return{msg:M[s.msg]||s.msg,img:s.img};
    if(s.code==='5xx'&&code>=500&&code<600)return{msg:M[s.msg]||s.msg,img:s.img};
  }
  return null;
}
function getCode(cb){
  var p=window.location.pathname,m=p.match(/^\/([1-9]\d{2})$/);if(m)return cb(parseInt(m[1],10));
  if(p==='/'||p==='')return cb(200);
  try{fetch(window.location.href,{method:'HEAD',signal:AbortSignal.timeout(5000)}).then(function(r){cb(r.status);}).catch(function(){cb(0);});}catch(e){cb(0);}
}
function applyStatus(code){
  var title=dom['g41-title'],greet=dom['g41-greet'],bgImg=dom['g41-bg-img'],ctrls=document.querySelector('.h-controls');
  if(code===200){
    ctrls.style.display='';title.textContent=CHARS.site.title;title.style.color='';
    greet.textContent=CHARS.msgs.home;greet.classList.remove('err');
    bgImg.src=CHARS.home.img;bgImg.style.opacity='';bgImg.style.filter='';
    dom['g41-tiles'].style.display='';
  }else{
    ctrls.style.display='none';title.textContent=code;title.style.color=code>=500?'var(--wp-red)':'var(--wp-amber)';
    dom['g41-tiles'].style.display='none';dom['g41-character'].classList.remove('on');
    var st=findStatus(code);
    var msg=st?st.msg:code?'HTTP '+code:'',img=st?st.img:'/img/Pic_G41.png';
    greet.textContent=msg;greet.classList.add('err');
    dom['g41-char-msg'].textContent=code>=600?CHARS.msgs.nonstd:'HTTP '+code;
    bgImg.src=img;bgImg.style.opacity='.55';bgImg.style.filter='none';
  }
  document.getElementById('g41-app').style.opacity='1';
}
function reload(){try{buildTiles();}catch(e){console.error(e);}getCode(applyStatus);}
