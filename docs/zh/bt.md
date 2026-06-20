# bt
[中文](bt.md) | [English](../en/bt.md) | [日本語](../ja/bt.md)
BitTorrent 客户端 — WebUI + WebDAV 共享。
## 基本信息
| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps, hako, nginx |
| 容器 | tr |
| 镜像 | 本地构建（Dockerfile） |
## 安装
```bash
./g41.sh kits add bt
```
## 注意
- WebUI: /transmission/
- WebDAV: /transmission/share
- Transmission 守护进程，Web 控制面板为 transmission-web-control
