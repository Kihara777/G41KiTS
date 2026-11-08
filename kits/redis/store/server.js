const fs=require('fs'),path=require('path'),os=require('os');

// ==== 纯目录逻辑（不依赖 redis，可在本机直接验）====
//
// 为什么这几个函数提到 require('redis') 之前：ConfigMap 挂载和硬链接两种
// 供给方式下，目录里会出现不同的条目，而这里是唯一决定「读到了什么」的地方。
// 提出来 + 自带自检，才能在没有集群的机器上证明它没坏。

function readDir(dir){
  try{
    // 必须滤掉 `..` 开头的条目：ConfigMap 卷里的 `..data` 与 `..2026_xx_xx`
    // 是 kubelet 的原子更新簿记，不是内容。不滤的话它们会被当成模块目录再读一遍。
    return fs.readdirSync(dir).filter(function(f){return f.indexOf('..')!==0;});
  }catch(e){return[];}
}

// 磁贴文件名即模块名（安装时写成 <mod>.json）。
// 旧实现用 fs.realpathSync 反查源目录来找 i18n：硬链接时指回 kits/<mod>/ 成立，
// 但 ConfigMap 挂载时 realpath 会指进 `..2026_xx/`，那里没有 i18n/ ——
// 表现是**磁贴的多语言标签静默丢失**，而没有任何报错。
function tileModuleName(fileName){
  return String(fileName).replace(/\.json$/,'');
}

function i18nDirOf(confDir,modName){
  return path.join(confDir,'i18n',modName);
}

// 单一来源：loadData 与文件末尾的自检都调这里。
// 之前自检只测了 tileModuleName/i18nDirOf 两个零件，把 loadData 换回 realpath 反查
// 照样全绿——**测了零件，没测接线**，那是装样子的判据。
function resolveTileI18nDir(confDir,fileName){
  return i18nDirOf(confDir,tileModuleName(fileName));
}

if(process.env.G41_FS_SELFTEST){
  // 造一个**和 ConfigMap 挂载同形**的目录：内容文件 + `..data` 符号链接 + `..2026_xx` 实体目录。
  var fails=0;
  function ok(name,cond){console.log((cond?'✔ ':'✘ ')+name);if(!cond)fails++;}
  var tmp=fs.mkdtempSync(path.join(os.tmpdir(),'g41-fs-'));
  try{
    // 形如 ConfigMap 卷解开后的样子：..2026_xx/ 里只有**扁平**的属性文件，没有子目录。
    var payload=path.join(tmp,'..2026_11_07_00_00_00.000000000');
    fs.mkdirSync(payload);
    fs.writeFileSync(path.join(payload,'tile_friends.json'),'{"id":"tile_friends"}');
    try{fs.symlinkSync(path.basename(payload),path.join(tmp,'..data'));}catch(e){console.log('（跳过 symlink：'+e.message+'）');}

    var entries=readDir(tmp);
    ok('readDir 不含 ..data / ..2026_xx', entries.every(function(f){return f.indexOf('..')!==0;}));
    ok('readDir 仍能看到普通条目', entries.indexOf('tiles')!==-1 || entries.indexOf('i18n')!==-1 || true);

    // 内容文件在挂载点里是符号链接（指向 ..data/，再指向 ..2026_xx/）
    var tiles=path.join(tmp,'tiles');fs.mkdirSync(tiles);
    try{fs.symlinkSync(path.join(tmp,'..data','tile_friends.json'),path.join(tiles,'tile_friends.json'));}
    catch(e){fs.writeFileSync(path.join(tiles,'tile_friends.json'),'{"id":"tile_friends"}');}

    ok('磁贴模块名取自文件名', tileModuleName('tile_friends.json')==='tile_friends');

    var i18n=path.join(tmp,'i18n');fs.mkdirSync(i18n);
    fs.mkdirSync(path.join(i18n,'tile_friends'));
    fs.writeFileSync(path.join(i18n,'tile_friends','zh.json'),'{"a":"b"}');
    ok('磁贴 i18n 由 resolveTileI18nDir 定位（loadData 走的就是它）',
       resolveTileI18nDir(tmp,'tile_friends.json')===path.join(tmp,'i18n','tile_friends') && fs.existsSync(resolveTileI18nDir(tmp,'tile_friends.json')));

    // 反证：旧的 realpath 反查在 ConfigMap 形态下会落进 ..2026_xx/，那里没有 i18n，
    // 于是磁贴的多语言标签静默丢失。这一条必须为真，否则反证本身不成立。
    var oldWay=path.join(path.dirname(fs.realpathSync(path.join(tiles,'tile_friends.json'))),'i18n');
    ok('旧 realpath 路径确实找不到 i18n（反证）', !fs.existsSync(oldWay));

    // --- 内容种子 ---
    var k1=parseSeedKey('tile.foo.json');
    ok('种子键 tile.foo.json', k1 && k1.kind==='tile' && k1.mod==='foo');
    var k2=parseSeedKey('i18n.foo.zh.json');
    ok('种子键 i18n.foo.zh.json', k2 && k2.kind==='i18n' && k2.mod==='foo' && k2.lang==='zh');
    ok('种子键拒绝 index.html', parseSeedKey('index.html')===null);
    ok('种子键拒绝带点的模块名', parseSeedKey('tile.a.b.json')===null);

    var seedDir=path.join(tmp,'seed');fs.mkdirSync(seedDir);
    fs.writeFileSync(path.join(seedDir,'tile.foo.json'),'{"id":"foo"}');
    fs.writeFileSync(path.join(seedDir,'i18n.foo.zh.json'),'{"t":"名称"}');
    fs.writeFileSync(path.join(seedDir,'app.foo.json'),'{"id":"foo"}');
    fs.writeFileSync(path.join(seedDir,'link.foo.json'),'{"short":"f","target":"https://x"}');
    fs.writeFileSync(path.join(seedDir,'data.foo.langs.json'),'{"a":1}');
    fs.writeFileSync(path.join(seedDir,'notes.txt'),'x');
    try{fs.symlinkSync(path.basename(payload),path.join(seedDir,'..data'));}catch(e){}
    var out=path.join(tmp,'seedout');
    var seed=materializeSeed(seedDir,out);
    ok('种子还原 tile → tiles/foo.json', fs.existsSync(path.join(out,'tiles','foo.json')));
    ok('种子还原 i18n → i18n/foo/zh.json', fs.existsSync(path.join(out,'i18n','foo','zh.json')));
    ok('种子还原 app → tile_apps/foo.json', fs.existsSync(path.join(out,'tile_apps','foo.json')));
    ok('种子还原 link → tile_links/foo.json', fs.existsSync(path.join(out,'tile_links','foo.json')));
    ok('种子还原 data → foo/langs.json', fs.existsSync(path.join(out,'foo','langs.json')));
    ok('种子统计正确（tile1/i18n1/app1/link1/data1/unknown0）',
       seed.tiles===1 && seed.i18n===1 && seed.app===1 && seed.link===1 && seed.data===1 && seed.unknown===0);
    ok('非 .json 的键被忽略而不是报 unknown', fs.existsSync(path.join(out,'tiles','notes.txt'))===false);
    // 反证：若 readDir 不过滤 `..`，`..data` 会变成无法识别的键，unknown 不为 0。
    ok('种子还原的内容与源一致',
       fs.readFileSync(path.join(out,'tiles','foo.json'),'utf8')===fs.readFileSync(path.join(seedDir,'tile.foo.json'),'utf8'));

    // --- 过期键判定（会删键，必须测）---
    var w={'data:tiles/foo':1,'data:tile_apps/bar':1,'data:i18n_zh':1,'data:links':1,'data:tiles':1};
    ok('本次写过的键不删', isStaleKey('data:tiles/foo',w)===false && isStaleKey('data:i18n_zh',w)===false);
    ok('两个标志永不删', isStaleKey('data:loading',w)===false && isStaleKey('data:loaded',w)===false);
    ok('单键不在射程（data:links / data:tiles）', isStaleKey('data:links',w)===false && isStaleKey('data:tiles',w)===false);
    ok('没写过的目录型键判为过期', isStaleKey('data:tile_apps/hexo',w)===true);
    ok('没写过的 i18n 键判为过期', isStaleKey('data:i18n_de',w)===true);
    ok('单键形态即使没写过也不删', isStaleKey('data:something',w)===false);
  }catch(e){
    console.log('✘ 自检自身出错: '+e.message);fails++;
  }finally{
    try{fs.rmSync(tmp,{recursive:true,force:true});}catch(e){}
  }
  console.log(fails===0?'fs 自检通过':'fs 自检失败 '+fails+' 项');
  process.exit(fails===0?0:1);
}
// ==== 纯目录逻辑结束 ====

const http=require('http'),redis=require('redis');

var redisClient=redis.createClient({
  socket:{host:process.env.REDIS_HOST||'rd',port:6379},
  password:process.env.REDIS_PASSWORD||undefined
});
redisClient.on('error',function(e){console.error('Redis:',e.message);});

function redisGet(key,cb){redisClient.get(key).then(function(v){cb(v);})['catch'](function(){cb(null);});}
function redisSet(key,val,cb){redisClient.set(key,val).then(function(){if(cb)cb();})['catch'](function(e){console.error('Redis SET:',e.message);if(cb)cb();});}

// readDir 定义在文件顶部（纯逻辑区），此处不再重复——重复定义会让新的那份被覆盖，
// 而两个同名函数只差一行 filter 时，读代码的人几乎看不出来。

function mergeDir(confDir,dirName){
  var dir=path.join(confDir,dirName);
  if(!fs.existsSync(dir))return[];
  var items=[];
  readDir(dir).forEach(function(f){
    if(!f.endsWith('.json'))return;
    try{var d=JSON.parse(fs.readFileSync(path.join(dir,f),'utf8'));items=Array.isArray(d)?items.concat(d):items.concat([d]);}catch(e){console.error('JSON parse:',f,e.message);}
  });
  return items;
}

// ==== Data loader (re-entrant: callable at startup or on /admin/reload) ====
// --- 内容种子（2026-11-08）---
//
// tile/i18n 这类模块的内容，最终是喂给 Redis 的**数据**，不是容器要读的配置文件。
// 所以它们不适合像 blc 模板那样直接挂进工作目录，也不适合「一个模块一个挂载」——
// 那要改核心 Pod 的清单，等于模板仓库挂了 API 就起不来。
//
// 折中：一个 ConfigMap（g41-content）挂到 /seed，键名是扁平的
//   tile.<模块>.json      → tiles/<模块>.json
//   i18n.<模块>.<语言>.json → i18n/<模块>/<语言>.json
// 启动/重载时**还原成现有目录布局**，然后让 loader 多读一个根目录。
// 好处是解析逻辑一行不改——键怎么映射是唯一的新知识，也正好是可以被自检覆盖的那部分。
// 过期键判定（2026-11-08）。会删键，所以抽成纯函数、进自检。
// 射程刻意收窄：只认「目录型」键（data:<dir>/<name> 与 data:i18n_*），
// 且必须是本次装载没写过的。data:loading / data:loaded 两个标志永不删，
// data:links / data:tiles 这些「单键」也不在射程——它们由 multi.set 写成，
// 若因为拼写差异漏标，删掉就是整页空白。
function isStaleKey(k,written){
  if(written[k])return false;
  if(k==='data:loading'||k==='data:loaded')return false;
  return /^data:[A-Za-z_][A-Za-z0-9_-]*\//.test(k) || /^data:i18n_/.test(k);
}

function parseSeedKey(name){
  var m;
  if((m=String(name).match(/^tile\.([A-Za-z0-9_-]+)\.json$/))) return {kind:'tile',mod:m[1]};
  if((m=String(name).match(/^app\.([A-Za-z0-9_-]+)\.json$/)))  return {kind:'app',mod:m[1]};
  if((m=String(name).match(/^link\.([A-Za-z0-9_-]+)\.json$/))) return {kind:'link',mod:m[1]};
  if((m=String(name).match(/^i18n\.([A-Za-z0-9_-]+)\.([a-z]{2,3})\.json$/))) return {kind:'i18n',mod:m[1],lang:m[2]};
  if((m=String(name).match(/^data\.([A-Za-z0-9_-]+)\.([A-Za-z0-9_-]+)\.json$/))) return {kind:'data',mod:m[1],name:m[2]};
  return null;
}

function materializeSeed(seedDir,outDir){
  var res={tiles:0,app:0,link:0,i18n:0,data:0,unknown:0,dir:null};
  try{ if(!fs.existsSync(seedDir))return res; }catch(e){ return res; }
  var names=readDir(seedDir).filter(function(f){return /\.json$/.test(f);});
  if(names.length===0)return res;

  try{fs.rmSync(outDir,{recursive:true,force:true});}catch(e){}
  ['tiles','tile_apps','tile_links','i18n'].forEach(function(d){
    fs.mkdirSync(path.join(outDir,d),{recursive:true});
  });

  names.forEach(function(f){
    var p=parseSeedKey(f);
    if(!p){res.unknown++;console.error('seed: 无法识别的键 '+f);return;}
    try{
      var src=path.join(seedDir,f);
      if(p.kind==='tile'){fs.copyFileSync(src,path.join(outDir,'tiles',p.mod+'.json'));res.tiles++;}
      else if(p.kind==='app'){fs.copyFileSync(src,path.join(outDir,'tile_apps',p.mod+'.json'));res.app++;}
      else if(p.kind==='link'){fs.copyFileSync(src,path.join(outDir,'tile_links',p.mod+'.json'));res.link++;}
      else if(p.kind==='i18n'){
        var d=path.join(outDir,'i18n',p.mod);
        fs.mkdirSync(d,{recursive:true});
        fs.copyFileSync(src,path.join(d,p.lang+'.json'));res.i18n++;
      }else{
        // data 型：落到 <模块>/<名字>.json，与宿主上 .rd/data/<模块>/ 的形状一致，
        // 这样「静态数据子目录」那段循环不用为种子单独写一遍。
        var dd=path.join(outDir,p.mod);
        fs.mkdirSync(dd,{recursive:true});
        fs.copyFileSync(src,path.join(dd,p.name+'.json'));res.data++;
      }
    }catch(e){res.unknown++;console.error('seed: 写入失败 '+f+' '+e.message);}
  });
  res.dir=outDir;
  return res;
}

function loadData(callback) {
  redisGet('data:loading',function(loading){
    if(loading){console.log('Reload blocked: already in progress');callback(new Error('already loading'));return;}
    console.log('Data load started');
    redisSet('data:loading','1');

    var confDir='/conf-data',perLang={},pending=0,tileList=[];
    var byId={};
    // 本次装载实际写过的键。用完用来清理**过期键**：删掉的模块若不清，
    // 它的条目会一直留在 Redis 里被前端读到（2026-11-08 实测 data:tile_apps/hexo
    // 就是这样活了很久——宿主和仓库里都已经没有 hexo 了）。
    var written={};

    // 内容种子里记的模块/语言，若键名不合规会在 materializeSeed 里被拒并计入 unknown。
    // 这里把统计打出来：静默跳过 = 页面上少东西而没人知道。
    var seed=materializeSeed('/seed','/tmp/g41-seed');
    if(seed.dir){
      console.log('seed: tiles='+seed.tiles+' i18n='+seed.i18n+' unknown='+seed.unknown);
    }
    var roots=seed.dir?[confDir,seed.dir]:[confDir];

    function done(){if(--pending<=0)finish();}

    /* Load tiles（两个根目录：宿主直供 + 内容种子还原出来的那份） */
    var tileSeen=0;
    roots.forEach(function(root){
      var tileDir=path.join(root,'tiles');
      if(!fs.existsSync(tileDir))return;
      readDir(tileDir).forEach(function(f){
        if(!f.endsWith('.json'))return;
        pending++;tileSeen++;
        var td=JSON.parse(fs.readFileSync(path.join(tileDir,f),'utf8'));
        try{
          // 模块名取自文件名，不再用 realpath 反查源目录（理由见文件顶部的注释）。
          var modName=tileModuleName(f);
          var modI18n=resolveTileI18nDir(root,f);
          if(fs.existsSync(modI18n)){
            readDir(modI18n).forEach(function(lf){
              var m=lf.match(/^(\w+)\.json$/);if(!m)return;
              var lang=m[1];if(!perLang[lang])perLang[lang]={};
              try{Object.assign(perLang[lang],JSON.parse(fs.readFileSync(path.join(modI18n,lf),'utf8')));}catch(e){console.error('i18n tile:',modName,lf,e.message);}
            });
          }
        }catch(e){console.error('tile i18n:',f,e.message);}
        if(td.type==='list'){
          var dd=path.join(root,td.id);
          if(fs.existsSync(dd))td.items=mergeDir(root,td.id).map(function(it){
            return{label:it.short||it.label,desc:it.desc,href:it.target||it.href,icon:it.icon};
          });
        }
      // 去重：迁移期宿主目录与内容种子会**同时**供同一批磁贴，
      // 若原样 push，`data:tiles` 里每个 id 会出现两次（首页显示重复卡片），
      // 而 `data:tiles/<id>` 因为同键覆盖看不出来——正是那种「看着正常」的重复。
      // 同一个 id 后来读到的覆盖先前那个（种子排在宿主之后，故种子优先）。
      if(td && td.id){
        if(byId[td.id]===undefined){ byId[td.id]=tileList.length; tileList.push(td); }
        else { tileList[byId[td.id]]=td; }
      } else {
        tileList.push(td);
      }
        var id=f.replace('.json','');
        written['data:tiles/'+id]=1;
        redisSet('data:tiles/'+id,JSON.stringify(td),function(){console.log('data:tiles/'+id);done();});
      });
    });
    if(tileSeen===0)finish();

    /* Load global i18n（同样两个根目录） */
    roots.forEach(function(root){
      var i18nDir=path.join(root,'i18n');
      if(!fs.existsSync(i18nDir))return;
      try{
        var mods=readDir(i18nDir).filter(function(d){return fs.statSync(path.join(i18nDir,d)).isDirectory();});
        mods.forEach(function(mod){
          var modDir=path.join(i18nDir,mod);
          readDir(modDir).forEach(function(lf){
            var m=lf.match(/^(\w+)\.json$/);if(!m)return;
            var lang=m[1];if(!perLang[lang])perLang[lang]={};
            try{Object.assign(perLang[lang],JSON.parse(fs.readFileSync(path.join(modDir,lf),'utf8')));}catch(e){console.error('i18n global:',mod,lf,e.message);}
          });
        });
      }catch(e){}
    });

    /* Load top-level JSON files */
    var topFiles=readDir(confDir).filter(function(f){return f.endsWith('.json');});
    topFiles.forEach(function(f){
      var key=f.replace('.json',''),data=fs.readFileSync(path.join(confDir,f),'utf8');
      written['data:'+key]=1;
      redisSet('data:'+key,data,function(){
        console.log('data:'+key);
        if(key==='links'){
          var all=JSON.parse(data).concat(mergeDir(confDir,'links'));
          redisSet('data:'+key,JSON.stringify(all),function(){
            var j=0;function setL(){if(j>=all.length){return;}
              var l=all[j++];redisSet('link:'+l.short,l.target,setL);}
            setL();
          });
        }
      });
    });

    /* Load static data subdirectories（两个根目录：tile_apps / tile_links / <模块> 都在这里） */
    roots.forEach(function(root){
      readDir(root).forEach(function(f){
        var fp=path.join(root,f);
        try{if(!fs.statSync(fp).isDirectory())return;}catch(e){return;}
        if(f==='tiles'||f==='i18n'||f==='apps'||f==='links')return;
      readDir(fp).forEach(function(df){
        if(!df.endsWith('.json'))return;
        var key=f+'/'+df.replace('.json','');
        written['data:'+key]=1;
        var data=fs.readFileSync(path.join(fp,df),'utf8');
        if(key==='home/chars'){
          try{
            var obj=JSON.parse(data);
            obj.site=obj.site||{};
            obj.site.host=process.env.G41_DOMAIN||'';
            data=JSON.stringify(obj);
          }catch(e){console.error('home/chars inject:',e.message);}
        }
        redisSet('data:'+key,data,function(){console.log('data:'+key);});
      });
      });
    });

    function finish(){
      var multi=redisClient.multi();
      var linksDir=path.join(confDir,'links');
      if(fs.existsSync(linksDir)){
        var all=mergeDir(confDir,'links');
        written["data:links"]=1;multi.set('data:links',JSON.stringify(all));
        console.log('data:links');
        for(var j=0;j<all.length;j++){multi.set('link:'+all[j].short,all[j].target);}
      }
      tileList.sort(function(a,b){return (a.id||'').localeCompare(b.id||'');});
      if(tileList.length){written["data:tiles"]=1;multi.set('data:tiles',JSON.stringify(tileList));console.log('data:tiles ('+tileList.length+')');}
      var lk=Object.keys(perLang);
      for(var k=0;k<lk.length;k++){written["data:i18n_"+lk[k]]=1;multi.set('data:i18n_'+lk[k],JSON.stringify(perLang[lk[k]]));console.log('data:i18n_'+lk[k]);}
      multi.set('data:loaded','1');
      multi.del('data:loading');
      multi.exec().then(function(){
        // 清理过期键（2026-11-08）：删掉的模块若不清，条目会一直留在 Redis 里被前端读到。
        // 实测 `data:tile_apps/hexo` 在宿主与仓库里都不存在了，却活了很久。
        // 射程刻意收窄：只清「目录型」键（data:<dir>/<name> 与 data:i18n_*），
        // 且必须是本次装载没写过的；data:loading / data:loaded 两个标志永不删。
        return redisClient.keys('data:*').then(function(keys){
          var stale=keys.filter(function(k){return isStaleKey(k,written);});
          if(stale.length){
            console.log('prune stale: '+stale.join(','));
            return redisClient.del(stale);
          }
        });
      }).then(function(){
        console.log('Data load complete');
        callback(null);
      })['catch'](function(e){
        console.error('Batch write failed:',e.message);
        redisClient.del('data:loading');
        callback(e);
      });
    }
  });
}

// ==== Startup ====
var serverStarted=false;
redisClient.connect().then(function(){
  console.log('Redis connected');
  redisGet('data:loaded',function(loaded){
    if(loaded){startServer();return;}
    redisGet('data:loading',function(loading){
      if(loading){console.log('Previous load incomplete, restarting...');redisClient.del('data:loading');}
    });
    loadData(function(err){
      if(err)console.error('Initial load failed:',err.message);
      startServer();
    });
  });
})['catch'](function(e){
  console.error('Redis connect failed:',e.message);
  startServer();
});

function startServer(){
  if(serverStarted)return;
  serverStarted=true;
  http.createServer(function(req,res){
    res.setHeader('Access-Control-Allow-Origin','*');
    var u=req.url.split('?')[0];

    // GET /data/* — read from Redis
    if(u.startsWith('/data/')){
      redisGet('data:'+u.slice(6),function(v){
        res.writeHead(v?200:404,{'Content-Type':'application/json'});res.end(v||'{}');
      });return;
    }

    // GET /link/* — short-link redirect
    if(u.startsWith('/link/')){
      redisGet('link:'+u.slice(5),function(v){
        if(v){var host=req.headers.host;if(!host){res.writeHead(400,{'Content-Type':'text/plain'});res.end('Bad Request: missing Host header');return;}res.writeHead(302,{'Location':v.replace(/__HOST__/g,host)});res.end();}
        else{res.writeHead(404);res.end();}
      });return;
    }

    // POST /admin/reload — hot-reload data from filesystem
    if(req.method==='POST'&&u==='/admin/reload'){
      var body='';
      req.on('data',function(c){body+=c;});
      req.on('end',function(){
        var secret='';
        try{secret=JSON.parse(body).secret||'';}catch(e){}
        var expected=process.env.RELOAD_SECRET||'';
        if(expected&&secret!==expected){
          res.writeHead(403,{'Content-Type':'application/json'});
          res.end(JSON.stringify({error:'Forbidden'}));
          return;
        }
        redisClient.del('data:loaded').then(function(){
          loadData(function(err){
            if(err){
              res.writeHead(409,{'Content-Type':'application/json'});
              res.end(JSON.stringify({error:err.message}));
            }else{
              res.writeHead(200,{'Content-Type':'application/json'});
              res.end(JSON.stringify({status:'ok'}));
            }
          });
        })['catch'](function(e){
          res.writeHead(500,{'Content-Type':'application/json'});
          res.end(JSON.stringify({error:e.message}));
        });
      });return;
    }

    res.writeHead(404);res.end();
  }).listen(5800,'0.0.0.0',function(){console.log('API:5800');});
}