# home

[中文](home.md) | [English](../en/home.md) | [日本語](../ja/home.md)

站点核心数据 — 角色消息、主题色、状态码、i18n。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | 数据 |
| 依赖 | core, nginx, redis |
| 容器 | — |

## 安装

```bash
./g41.sh kits add home
```

## 注意

- 纯数据模块，无 Docker 服务（`compose: none`）
- 提供全局 i18n 翻译（ja/zh/en）
- 管理首页磁贴的 `error_page` 配置
- 站点元数据定义于 `data/` 目录：角色（chars.json）、主题色（colors.json）、状态码（status.json）
- webroot 包含 G41.html、CSS、JS 和图片资源
