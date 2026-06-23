# bt
[中文](bt.md) | [English](../en/bt.md) | [日本語](../ja/bt.md) | [ｶﾀﾘｯｼｭ](../katalish/bt.md) | [偽中国語](../pcn/bt.md)

BitTorrent 客户端，含 WebUI 与 WebDAV 共享

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps,hako,nginx |
| 容器 | tr |
| 镜像 | alpine + transmission-daemon（Dockerfile 本地构建） |

## 安装

```bash
./g41.sh kits add bt
```

## 注意

- WebUI: /transmission/
- WebDAV: /transmission/share
- 健康检查: nc -zw1 127.0.0.1 9091
