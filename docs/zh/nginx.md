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
