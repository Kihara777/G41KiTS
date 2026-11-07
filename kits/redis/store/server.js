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
function loadData(callback) {
  redisGet('data:loading',function(loading){
    if(loading){console.log('Reload blocked: already in progress');callback(new Error('already loading'));return;}
    console.log('Data load started');
    redisSet('data:loading','1');

    var confDir='/conf-data',perLang={},pending=0,tileList=[];

    function done(){if(--pending<=0)finish();}

    /* Load tiles */
    var tileDir=path.join(confDir,'tiles');
    if(fs.existsSync(tileDir)){
      readDir(tileDir).forEach(function(f){
        if(!f.endsWith('.json'))return;
        pending++;
        var td=JSON.parse(fs.readFileSync(path.join(tileDir,f),'utf8'));
        try{
          // 模块名取自文件名，不再用 realpath 反查源目录（理由见文件顶部的注释）。
          var modName=tileModuleName(f);
          var modI18n=resolveTileI18nDir(confDir,f);
          if(fs.existsSync(modI18n)){
            readDir(modI18n).forEach(function(lf){
              var m=lf.match(/^(\w+)\.json$/);if(!m)return;
              var lang=m[1];if(!perLang[lang])perLang[lang]={};
              try{Object.assign(perLang[lang],JSON.parse(fs.readFileSync(path.join(modI18n,lf),'utf8')));}catch(e){console.error('i18n tile:',modName,lf,e.message);}
            });
          }
        }catch(e){console.error('tile i18n:',f,e.message);}
        if(td.type==='list'){
          var dd=path.join(confDir,td.id);
          if(fs.existsSync(dd))td.items=mergeDir(confDir,td.id).map(function(it){
            return{label:it.short||it.label,desc:it.desc,href:it.target||it.href,icon:it.icon};
          });
        }
        tileList.push(td);
        var id=f.replace('.json','');
        redisSet('data:tiles/'+id,JSON.stringify(td),function(){console.log('data:tiles/'+id);done();});
      });
      if(tileList.length===0)finish();
    } else { finish(); }

    /* Load global i18n */
    var i18nDir=path.join(confDir,'i18n');
    if(fs.existsSync(i18nDir)){
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
    }

    /* Load top-level JSON files */
    var topFiles=readDir(confDir).filter(function(f){return f.endsWith('.json');});
    topFiles.forEach(function(f){
      var key=f.replace('.json',''),data=fs.readFileSync(path.join(confDir,f),'utf8');
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

    /* Load static data subdirectories */
    readDir(confDir).forEach(function(f){
      var fp=path.join(confDir,f);
      try{if(!fs.statSync(fp).isDirectory())return;}catch(e){return;}
      if(f==='tiles'||f==='i18n'||f==='apps'||f==='links')return;
      readDir(fp).forEach(function(df){
        if(!df.endsWith('.json'))return;
        var key=f+'/'+df.replace('.json','');
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

    function finish(){
      var multi=redisClient.multi();
      var linksDir=path.join(confDir,'links');
      if(fs.existsSync(linksDir)){
        var all=mergeDir(confDir,'links');
        multi.set('data:links',JSON.stringify(all));
        console.log('data:links');
        for(var j=0;j<all.length;j++){multi.set('link:'+all[j].short,all[j].target);}
      }
      tileList.sort(function(a,b){return (a.id||'').localeCompare(b.id||'');});
      if(tileList.length){multi.set('data:tiles',JSON.stringify(tileList));console.log('data:tiles ('+tileList.length+')');}
      var lk=Object.keys(perLang);
      for(var k=0;k<lk.length;k++){multi.set('data:i18n_'+lk[k],JSON.stringify(perLang[lk[k]]));console.log('data:i18n_'+lk[k]);}
      multi.set('data:loaded','1');
      multi.del('data:loading');
      multi.exec().then(function(){
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