# bt

[中文](bt.md) | [English](../en/bt.md) | [日本語](../ja/bt.md)

BitTorrent 客户端，含 WebUI 与 WebDAV 共享。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps, hako, nginx |
| 容器 | tr |

## 安装

```bash
./g41.sh kits add bt
```

## 注意

- 从 Dockerfile 本地构建（`FROM alpine:3.23.4` + transmission-daemon）
- WebUI 位于 `/transmission/`（transmission-web-control v1.6.1-update1）
- 原始 UI 保留在 `/transmission/web/index.original.html`
- WebDAV 共享路径 `/transmission/share`
- 健康检查：`nc -zw1 127.0.0.1 9091`
- settings.json 配置已迁移至 `.local/`