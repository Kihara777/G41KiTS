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

## 提供给依赖模块

blc 向依赖它的模块提供 `blc_template` 类型：

| 提供字段 | 值 |
|---------|-----|
| 类型 | `blc_template` |
| 目标目录 | `.lc/custom_public/templates/<模块名>/` |
| 容器内路径 | `/mnt/data/data/custom_public/templates/<模块名>/` |
| 源目录 | 消费者模块下的 `blc_template/` |

依赖 blc 的模块可以在模块目录中放置 `blc_template/` 目录（含 `template.json`），安装时自动硬链接到 blivechat 模板目录。安装后需重启 blc 容器使模板生效：

```bash
docker compose restart blc
```

## 注意

- server_name: blc.*
- WebSocket: /api/chat
- 健康检查: wget http://127.0.0.1:12450/
- 模板目录: `.lc/custom_public/templates/`（需重启容器生效）
