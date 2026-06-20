# aria2

[中文](aria2.md) | [English](../en/aria2.md) | [日本語](../ja/aria2.md)

并行下载管理器，含 WebUI 与 WebDAV 共享。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps, hako, nginx |
| 容器 | ad |

## 安装

```bash
./g41.sh kits add aria2
```

## 注意

- WebUI 访问路径 `/aria2/`（AriaNg，本地 Dockerfile 构建）
- RPC 端点 `/aria2rpc`（WebSocket over nginx 代理）
- WebDAV 共享路径 `/aria2/`，支持 PUT/DELETE/MKCOL
- 健康检查通过 `nc -zw1 127.0.0.1 6800`（TCP 端口探测）