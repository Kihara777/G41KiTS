# aria2

[中文](aria2.md) | [English](../en/aria2.md) | [日本語](../ja/aria2.md)

并行下载管理器，含 WebUI 与 WebDAV 共享。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps, hako, nginx |
| 容器 | ad |
| compose | file |
| 基础镜像 | `alpine:3.23.4` |

## 安装

```bash
./g41.sh kits add aria2
```

## 注意

- 从 Dockerfile 本地构建，使用 `ADD --checksum` 锁定 AriaNg AllInOne 版本
- WebUI 位于 `/aria2/`（AriaNg，AngularJS 单页应用）
- RPC 通过 `/aria2rpc` 的 WebSocket（wss）代理至 nginx
- WebDAV 共享路径 `/aria2/share`，支持 PUT/DELETE/MKCOL 操作
- 健康检查：`nc -zw1 127.0.0.1 6800`
- `rpc.daemon` 配置文件已迁移至 `.local/`
- 持久化目录 `.ad`（下载文件和配置）被 `.gitignore` 排除
