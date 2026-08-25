// k8s 模式入口：bittorrent-tracker 与 redis API 同进程（1GB 机内存合并）
// compose 模式不受影响（镜像默认入口仍是 node server.js）
// bittorrent-tracker 为 ESM-only，用动态 import 在 CJS 里加载
(async function () {
  var { Server } = await import('bittorrent-tracker');
  var tracker = new Server({ trustProxy: true, http: true, udp: true, ws: true });
  tracker.on('error', function (e) { console.error('Tracker:', e.message); });
  tracker.on('warning', function (e) { console.warn('Tracker:', e.message); });
  tracker.listen(8000, function () { console.log('Tracker:8000'); });
  require('/app/server.js'); // redis API，监听 5800（server.js 挂载自 .rd）
})();
