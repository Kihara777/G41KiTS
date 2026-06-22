const http=require('http'),fs=require('fs'),path=require('path'),redis=require('redis');

var redisClient=redis.createClient({
  socket:{host:'rd',port:6379},
  password:process.env.REDIS_PASSWORD||undefined
});
redisClient.on('error',function(e){console.error('Redis:',e.message);});

function redisGet(key,cb){redisClient.get(key).then(function(v){cb(v);})['catch'](function(){cb(null);});}
function redisSet(key,val,cb){redisClient.set(key,val).then(function(){if(cb)cb();})['catch'](function(e){console.error('Redis SET:',e.message);if(cb)cb();});}

function readDir(dir){
  try{return fs.readdirSync(dir);}catch(e){return[];}
}

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
          var realPath=fs.realpathSync(path.join(tileDir,f));
          var modDir=path.dirname(realPath);
          var modI18n=path.join(modDir,'i18n');
          if(fs.existsSync(modI18n)){
            readDir(modI18n).forEach(function(lf){
              var m=lf.match(/^(\w+)\.json$/);if(!m)return;
              var lang=m[1];if(!perLang[lang])perLang[lang]={};
              try{Object.assign(perLang[lang],JSON.parse(fs.readFileSync(path.join(modI18n,lf),'utf8')));}catch(e){console.error('i18n tile:',mod,lf,e.message);}
            });
          }
        }catch(e){console.error('tile realpath:',f,e.message);}
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