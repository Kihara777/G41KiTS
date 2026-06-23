# nginx
[中文](../zh/nginx.md) | [English](nginx.md) | [日本語](../ja/nginx.md) | [ｶﾀﾘｯｼｭ](../katalish/nginx.md) | [偽中国語](../pcn/nginx.md)

TLS 1.3 / HTTP/3 gateway, reverse proxy to all backends

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | core |
| 容器 | gx |
| 镜像 | nginx |

## Install

```bash
./g41.sh kits add nginx
```

## Notes

- 端口 80/443，HTTP/3 QUIC\n- 所有 location 通过 include 加载\n- 安全头：HSTS、CSP、X-Frame、Referrer
