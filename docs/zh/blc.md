# blc
[中文](blc.md) | [English](../en/blc.md) | [日本語](../ja/blc.md)
Bilibili 直播聊天 — AI 翻译。
## 基本信息
| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps, nginx |
| 容器 | lc |
| 镜像 | xfgryujk/blivechat |
## 安装
```bash
./g41.sh kits add blc
```
## 注意
- server_name: blc.*
- WebSocket 聊天端点: /api/chat
- Docker Hub 镜像，非本地构建
