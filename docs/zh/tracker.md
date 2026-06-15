# tracker

[中文](tracker.md) | [English](../en/tracker.md) | [日本語](../ja/tracker.md)

轻量 HTTPS BitTorrent Tracker。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | hako, home, nginx |
| 容器 | wt |

## 安装

```bash
./g41.sh kits add tracker
```

## 注意

- 从 Dockerfile 本地构建（`FROM node:24.16.0-alpine` + bittorrent-tracker@11.2.2）
- 服务监控端点 `/tracker`（嵌入首页磁贴详情）
- UDP 6969 通过 UFW 对公网开放
- 健康检查：`wget -q http://127.0.0.1:8000/stats`
