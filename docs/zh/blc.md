# blc

[中文](blc.md) | [English](../en/blc.md) | [日本語](../ja/blc.md)

Bilibili 直播聊天，含 AI 翻译。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps, nginx |
| 容器 | lc |

## 安装

```bash
./g41.sh kits add blc
```

## 注意

- 虚拟主机 `server_name blc.*`
- `/api/chat` 端点支持 WebSocket 升级
- 包含 000-home.conf（共享 error_page 处理）
- 所有请求通过 nginx 代理至 `http://lc`