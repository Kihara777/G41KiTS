# tracker

[中文](tracker.md) | [English](../en/tracker.md) | [日本語](../ja/tracker.md)

轻量 HTTPS BitTorrent Tracker。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | hako, home, nginx |
| 容器 | wt |
| 镜像 | 本地构建 |

## 安装

```bash
./g41.sh kits add tracker
```

## 注意

- `/announce` 端点处理 BitTorrent 追踪请求
- `/tracker` 端点返回 HTML 统计，可嵌入磁贴详情页
- UDP 端口 6969 通过 UFW 对公网开放
