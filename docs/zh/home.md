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

- 无 Docker 服务，纯数据模块
- `data/` 目录中的 JSON 文件在 API 启动时加载至 Redis
- `webroot/` 目录提供首页 HTML/JS/CSS 和站点图标
- `i18n/` 目录提供全局多语言翻译
- 角色消息（chars.json）的 host 字段由 API 从 `G41_DOMAIN` 环境变量动态注入