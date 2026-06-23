# tracker
[中文](tracker.md) | [English](../en/tracker.md) | [日本語](../ja/tracker.md) | [ｶﾀﾘｯｼｭ](../katalish/tracker.md) | [偽中国語](../pcn/tracker.md)

轻量 HTTPS BitTorrent Tracker

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | hako,home,nginx |
| 容器 | wt |
| 镜像 | node + bittorrent-tracker（Dockerfile 本地构建） |

## 安装

```bash
./g41.sh kits add tracker
```

## 注意

- HTTP/UDP/WebSocket 多协议
- 嵌入端点: /tracker（状态页）
- UDP 6969 公网开放（UFW）
- 健康检查: wget http://127.0.0.1:8000/stats
