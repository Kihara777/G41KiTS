# nginx

[中文](nginx.md) | [English](../en/nginx.md) | [日本語](../ja/nginx.md)

TLS 1.3 / HTTP/3 gateway, reverse proxy to all backends

## Info

| Item | Value |
|------|-----|
| 类型 | service |
| 依赖 | core |
| 容器 | gx |
| 镜像 | nginx |

## Install

```bash
./g41.sh kits add nginx
```

## Notes

- Port 443 with HTTP/3 and QUIC BPF support
- Reverse proxy to all backend services
