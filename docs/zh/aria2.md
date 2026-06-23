# aria2
中文 | [English](../en/aria2.md) | [日本語](../ja/aria2.md)

并行下载管理器，含 WebUI 与 WebDAV 共享

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps,hako,nginx |
| 容器 | ad |
| 镜像 | alpine + aria2（Dockerfile 本地构建） |

## 安装

```bash
./g41.sh kits add aria2
```

## 注意

- WebUI: /aria2/
- RPC: /aria2rpc（WebSocket ws://）
- AriaNg AllInOne 内嵌
- 健康检查: nc -zw1 127.0.0.1 6800
