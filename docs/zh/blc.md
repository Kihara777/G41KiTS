# blc

[中文](blc.md) | [English](../en/blc.md) | [日本語](../ja/blc.md)

Bilibili 直播聊天，含 AI 翻译。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps, nginx |
| 容器 | lc |
| compose | hub |
| 镜像 | `xfgryujk/blivechat:v1.10.3` |

## 安装

```bash
./g41.sh kits add blc
```

## 注意

- 从 Docker Hub 拉取预构建镜像，版本标签固定
- WebSocket 端点 `/api/chat` 通过 nginx 代理
- `config.ini` 配置文件位于 `.local/`，包含房间号等部署专属设置
- 持久化目录 `.lc`（数据库和配置）被 `.gitignore` 排除
- server_name 使用通配符 `blc.*`，适配任意部署域名
