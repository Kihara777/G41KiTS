# nginx

[中文](nginx.md) | [English](../en/nginx.md) | [日本語](../ja/nginx.md)

TLS 1.3 / HTTP/3 网关，反向代理全部后端。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | core |
| 容器 | gx |

## 安装

```bash
./g41.sh kits add nginx
```

## 注意

- 从 Dockerfile 本地构建（`FROM alpine:3.23.4`）
- store/ 提供 nginx.conf + mime.types 基础配置
- 所有 location 通过 `include /etc/nginx/conf.d/locations/*.conf` 动态加载
- 安全头：HSTS、X-Content-Type-Options、X-Frame-Options、Referrer-Policy、CSP
- 代理路径（/nichan/、/gr/ 等）覆盖 CSP 为宽松策略
- QUIC/HTTP3 通过 `quic_bpf on` 启用