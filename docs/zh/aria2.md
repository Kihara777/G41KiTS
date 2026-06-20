# aria2
[中文](aria2.md) | [English](../en/aria2.md) | [日本語](../ja/aria2.md)
并行下载管理器 — WebUI + WebDAV 共享。
## 基本信息
| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps, hako, nginx |
| 容器 | ad |
| 镜像 | 本地构建（Dockerfile） |
## 安装
```bash
./g41.sh kits add aria2
```
## 注意
- WebUI: /aria2/
- JSON-RPC over WebSocket: wss://HOST/aria2rpc
- WebDAV 共享目录通过 hako 提供
