/* ═══════════ G41 tiles: build, animate, detail ── */
function shuffle(a){for(var j=a.length-1;j>0;j--){var r=Math.floor(Math.random()*(j+1)),t=a[j];a[j]=a[r];a[r]=t;}return a;}
function stripHtml(s){if(!s)return'';var d=document.createElement('div');d.innerHTML=s;return d.textContent||d.innerText||'';}
function resolveText(s){
  s=stripHtml(t(s)).replace(/__HOST__/g,(CHARS.site.host || window.location.host));
  var m=s.match(/^(\w+)/);
  if(m&&I18N[lang]&&I18N[lang][m[1]]){var r=I18N[lang][m[1]];if(!Array.isArray(r))s=s.replace(m[1],r);}
  return s;
}
function collectLiveTexts(cfg){
  var texts=[],desc=t(cfg.label,1);if(desc)texts.push(desc);
  if(cfg.type==='guide'&&cfg.sections){
    cfg.sections.forEach(function(s){
      if(s.h){var h=t(s.h);if(typeof h==='string'&&h)texts.push(h);}
      if(s.p){var p=resolveText(s.p);if(p)texts.push(p);}
      if(s.pre){var pre=stripHtml(s.pre).replace(/__HOST__/g,(CHARS.site.host || window.location.host));if(pre)texts.push(pre);}
    });
  }else if(cfg.type==='list'&&cfg.items){
    cfg.items.forEach(function(it){
      var l=t(it.label,0);if(l)texts.push(l);
      var d=it.desc?(Array.isArray(it.desc)?t(it.desc[0]):t(it.desc)):t(it.label,1);
      if(d&&d!==l)texts.push(d);
    });
  }
  return texts;
}
function tmplList(items){
  var h='<div class="app-list">';
  items.forEach(function(it){
    h+='<a href="'+(it.href||'javascript:void(0)')+'" class="app-row">';
    if(it.icon)h+='<span class="app-icon">'+it.icon+'</span>';
    h+='<span class="app-name">'+t(it.label,0)+'</span><span class="app-desc">'+(it.desc?(Array.isArray(it.desc)?t(it.desc[0]):t(it.desc)):t(it.label,1))+'</span></a>';
  });
  return h.replace(/__HOST__/g,(CHARS.site.host || window.location.host))+'</div>';
}
function tmplGuide(sections){
  var h='';
  sections.forEach(function(s){
    if(s.h)h+='<h3>'+t(s.h)+'</h3>';
    if(s.p)h+='<p>'+t(s.p)+'</p>';
    if(s.pre)h+='<pre>'+s.pre+'</pre>';
  });
  return h.replace(/__HOST__/g,(CHARS.site.host || window.location.host));
}
function getDetail(cfg){
  if(cfg.dataFile&&(!cfg.items||!cfg.items.length)){
    return $json(cfg.dataFile).then(function(data){
      cfg.items=data.map(function(l){return{label:l.short,desc:l.desc,href:l.target,icon:l.icon};});
      return{title:t(cfg.label,0),body:tmplList(cfg.items)};
    });
  }
  var body=(cfg.type==='list')?tmplList(cfg.items):tmplGuide(cfg.sections||[]);
  return Promise.resolve({title:t(cfg.label,0),body:body});
}

function buildTiles(){
  dom['g41-tiles'].innerHTML='';
  TILES.forEach(function(cfg,idx){
    var label=t(cfg.label,0),desc=t(cfg.label,1);
    var a=document.createElement('a');a.className='tile t-wp-'+METRO[idx%METRO.length];
    a.innerHTML='<span class="tile-icon">'+cfg.icon+'</span><span><span class="tile-label">'+label+'</span><br><span class="tile-desc"><span>'+desc+'</span></span></span>';
    var liveTexts=collectLiveTexts(cfg);
    if(!liveTexts.length)liveTexts=[t(cfg.label,1)||t(cfg.label,0)||cfg.icon];
    if(liveTexts.length){
      shuffle(liveTexts);
      var live=document.createElement('div');live.className='tile-live';live.textContent=liveTexts[0];a.appendChild(live);
      if(liveTexts.length>1){
        var i=0,cycle=function(){if(flipping)return;i=(i+1)%liveTexts.length;live.style.transform='translateY(1.2em)';live.style.opacity='0';
          setTimeout(function(){live.textContent=liveTexts[i];if(detail)detail.textContent=liveTexts[i];live.style.transition='none';live.style.transform='translateY(-.5em)';live.style.opacity='0';
            setTimeout(function(){live.style.transition='transform .35s ease, opacity .35s ease';live.style.transform='translateY(0)';live.style.opacity='1';},30);
          },350);
        };
        setInterval(cycle,3200+idx*800+Math.random()*1800);
      }
    }
    a.href='javascript:void(0)';
    a.addEventListener('click',function(e){e.preventDefault();a.classList.add('tile-press');openDetail(cfg);});
    dom['g41-tiles'].appendChild(a);
    var detail=document.createElement('div');detail.className='tile-detail';a.appendChild(detail);
    var labelEl=a.querySelector('.tile-label'),descEl=a.querySelector('.tile-desc');
    if(descEl&&liveTexts.length){
      var dx=a.clientWidth*.5,flipping=false;descEl.style.setProperty('--dx',dx+'px');
      (function step(){
        var skip=Math.random()<.25;
        if(skip){
          flipping=true;
          var axis=Math.random()>.5?'x':'y',axis2=Math.random()>.5?'x':'y';
          live.style.opacity='';labelEl.style.opacity='';
          detail.textContent=live.textContent;
          detail.style.transform='rotate'+axis.toUpperCase()+'(-180deg)';
          a.classList.add('flip-'+axis,'flipped');
          setTimeout(function(){
            detail.style.opacity='0';
            a.classList.remove('flip-'+axis);void a.offsetWidth;a.classList.add('flip-back-'+axis2);
            detail.style.transform='rotate'+axis2.toUpperCase()+'(-180deg)';
            setTimeout(function(){a.classList.remove('flip-back-'+axis2,'flipped');detail.style.opacity='';detail.style.transform='';live.style.opacity='';flipping=false;setTimeout(step,(2+Math.random()*6)*1000);},1900);
          },(3+Math.random()*5)*1000);
        }else{
          descEl.classList.remove('scroll-r');void descEl.offsetWidth;descEl.classList.add('scroll-l');
          setTimeout(function(){descEl.classList.remove('scroll-l','scroll-r');setTimeout(step,(2+Math.random()*6)*1000);},3700);
        }
      })();
    }
  });
}

function openDetail(cfg){
  var p=getDetail(cfg);if(!p)return;
  Promise.resolve(p).then(function(d){
    if(!d)return;
    dom['g41-detail-title'].textContent=d.title;dom['g41-detail-body'].innerHTML=d.body;
    dom['g41-detail-body'].classList.remove('fade-in');dom['g41-detail-body'].style.opacity='0';
    var bgImg=dom['g41-bg-img'];bgImg.style.opacity='0';
    setTimeout(function(){
      bgImg.src='/img/GK_Logo_EN.png';bgImg.style.objectFit='contain';
      var dv=dom['g41-view-detail'];dv.classList.remove('g41-view--slide-in','g41-view--slide-out');dv.offsetHeight;
      dv.classList.add('g41-view--active');dv.offsetHeight;dv.classList.add('g41-view--slide-in');
      dom['g41-view-main'].classList.remove('g41-view--active','main-entry');
      setTimeout(function(){dv.classList.remove('g41-view--slide-in');dom['g41-detail-body'].classList.add('fade-in');dom['g41-detail-body'].style.opacity='';bgImg.style.opacity='';
        if(cfg.embed){
           fetch(cfg.embed).then(function(r){return r.text();}).then(function(txt){var h=document.createElement('h3');h.textContent=t('tr_status');var w=document.createElement('div');w.className='tracker-embed';w.innerHTML=txt;dom['g41-detail-body'].appendChild(h);dom['g41-detail-body'].appendChild(w);}).catch(function(){var p=document.createElement('p');p.className='tracker-err';p.textContent=t('tr_err');dom['g41-detail-body'].appendChild(p);});
        }
      },350);
    },250);
  });
}
function closeDetail(){
  var mv=dom['g41-view-main'],dv=dom['g41-view-detail'],bgImg=dom['g41-bg-img'];
  bgImg.style.opacity='0';dom['g41-detail-body'].classList.remove('fade-in');dom['g41-detail-body'].style.opacity='0';
  setTimeout(function(){
    mv.querySelectorAll('.tile-press').forEach(function(el){el.classList.remove('tile-press');});
    dv.classList.add('g41-view--slide-out');mv.classList.add('g41-view--active');mv.offsetHeight;mv.classList.add('main-entry');
    bgImg.src='/img/Pic_G41.png';bgImg.style.objectFit='';bgImg.style.opacity='';
    setTimeout(function(){dv.classList.remove('g41-view--active');},250);
    setTimeout(function(){dv.classList.remove('g41-view--slide-out');mv.classList.remove('main-entry');},500);
  },250);
}
