# nginx
中文 | [English](../en/nginx.md) | [日本語](../ja/nginx.md)

TLS 1.3 / HTTP/3 网关，反向代理全部后端

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core |
| 容器 | gx |
| 镜像 | nginx |

## 安装

```bash
./g41.sh kits add nginx
```

## 注意

- 端口 80/443，HTTP/3 QUIC\n- 所有 location 通过 include 加载\n- 安全头：HSTS、CSP、X-Frame、Referrer

## 静态资源的缓存策略

静态文件（HTML/CSS/JS/JSON）一律发 `Cache-Control: no-cache`：

```nginx
add_header Cache-Control "no-cache" always;   # server 块，与安全头并列
```

**为什么不能用默认（什么都不写）**：没有 `Cache-Control` 时浏览器按 `Last-Modified`
走启发式缓存（约 10% 新鲜期），部署后可能拿到「旧 HTML 配新 JS/CSS」的**混合体**——
2026-10-12 就是因此看不到新加的启动环（页面看起来什么都没变）。本站没有文件名指纹，
所以 `no-cache` + ETag（再验证返回 304，很便宜）是唯一不会发出混合体的做法。

## 配置变更怎么生效（reloader sidecar）

`kits/nginx/k8s/deployment.yaml` 里的 `reloader` 容器负责在 `/etc/nginx`、`/certs`
变化后给 nginx 发 SIGHUP。**2026-10-12 实测它不工作**，两个原因都要修：

1. 该容器**没有任何 volumeMounts** —— 它 `find` 的是自己镜像里的 nginx 目录，永远看不到
   挂载进来的 ConfigMap/Secret（`/tmp/.last` 停在 2026-09-26，之后从未触发）。
2. 即使挂上了，`kill -HUP 1` 也打错进程：pod 开了 `shareProcessNamespace`，
   PID 1 是 **pause** 容器，不是 nginx master（应改为 `kill -HUP $(pgrep -f "nginx: master")`）。

后果：`k8s conf` / CD 重新渲染 ConfigMap 之后，**nginx 仍在跑旧配置**，只有 pod 重启才生效。
`k8s/host/g41-cert-reload.sh` 里「交由 reloader sidecar 热加载」的说明因此是错的
（证书续期后 nginx 不会自动重载，仍持有旧证书）。

## 压缩（gzip）

```nginx
gzip on;  gzip_comp_level 5;  gzip_min_length 256;  gzip_proxied any;  gzip_vary on;
gzip_types text/plain text/css application/javascript application/json image/svg+xml application/manifest+json;
```

**2026-10-12 之前一个 `gzip` 指令都没有**（nginx 默认关闭）——首页 HTML（样式内联后约 19.7KB）
与 JS 全是原样发送。实测：`G41.html` → **6.9KB**、`G41.js` 7.0KB → 约 2KB。
`gzip_vary on` 与 `Cache-Control: no-cache` 配合，缓存按编码分开存。

## splash 文案的本地化

启动画面的那行文案（`読み込み中 / Loading`）必须在**任何 JS 与任何额外请求之前**就可读——
客户端脚本要么来得太晚（还要多一次往返），要么被 CSP 拦（`script-src` 是 `'self'`，内联脚本不允许）。
所以按 `Accept-Language` 在 **nginx 侧**替换：

```nginx
map $http_accept_language $g41_loading_text {   # http 块
    default       "Loading";
    "~*^\s*zh"    "载入中";
    "~*^\s*ja"    "読み込み中";
    "~*^\s*en"    "Loading";
}
sub_filter_once on;                              # server 块
sub_filter '読み込み中 / Loading' $g41_loading_text;
```

- **第一语言优先**，与 `G41.js` 的 `detectLang` 同规则；`zh` 用的是简体（与全站 zh 文案一致）
- 响应因此随 `Accept-Language` 变化 → `Vary` 必须写上它。这里把 `gzip_vary` 关掉、
  在 server 块合成一个 `Vary: Accept-Encoding, Accept-Language`，免得同一响应出现两个 Vary
- 被替换的串是 `G41.html` 里那行**双语兜底**（文件被直接打开时仍可读）——改文案要两处一起改
- 已知边界：nginx 看不到 `localStorage` 里的语言偏好，所以「在日文设备上手动切成中文」的访客，
  splash 会先显示日文，app 启动后立刻变中文（差一两秒）
