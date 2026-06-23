# blc
中文 | [English](../en/blc.md) | [日本語](../ja/blc.md)

Bilibili 直播聊天，含 AI 翻译

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps,nginx |
| 容器 | lc |
| 镜像 | xfgryujk/blivechat |

## 安装

```bash
./g41.sh kits add blc
```

## 注意

- server_name: blc.*
- WebSocket: /api/chat
- 健康检查: wget http://127.0.0.1:12450/
