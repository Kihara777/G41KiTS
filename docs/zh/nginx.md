# nginx

[中文](nginx.md) | [English](../en/nginx.md) | [日本語](../ja/nginx.md)

TLS 1.3 / HTTP/3 网关，反向代理全部后端。

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

- 监听 80/443，启用 HTTP/3 QUIC
- 安全头：HSTS、CSP、X-Frame-Options、X-Content-Type-Options、Referrer-Policy
- 代理路径（nix-cache、gh-proxy）覆盖为宽松 CSP
- location 由各模块的 `site/` 配置组装
- upstream 通过 `kit_resolve` 发现