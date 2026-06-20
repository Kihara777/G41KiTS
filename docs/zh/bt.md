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

- WebUI 访问路径 `/transmission/`（transmission-web-control）
- RPC 端点 `/transmission/rpc`
- WebDAV 共享 `/transmission/share`，支持 PUT/DELETE/MKCOL
- 持久化目录 `.tr/`，配置文件通过 `.local/` 部署