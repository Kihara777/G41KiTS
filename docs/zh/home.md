# home

[中文](home.md) | [English](../en/home.md) | [日本語](../ja/home.md)

站点核心数据 — 角色消息、主题色、状态码、i18n。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | data |
| 依赖 | core, nginx, redis |

## 安装

```bash
./g41.sh kits add home
```

## 注意

- compose:none — 无 Docker 服务
- 提供全局 i18n 翻译（ja/zh/en）
- 提供 tiles/apps/links 的 provides 目标目录
- 数据文件（chars.json、colors.json 等）加载至 Redis