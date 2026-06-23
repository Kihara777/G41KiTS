# home
中文 | [English](../en/home.md) | [日本語](../ja/home.md)

站点核心数据 — 角色消息、主题色、状态码、i18n。模块直接提供 homete 磁贴（G41KiTS 项目介绍）。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | data + tile |
| 依赖 | core, nginx, redis |
| compose | none |

## 提供内容

- **磁贴**：tile_homete（G41KiTS 项目概览与技术栈）
- **全局 i18n**：角色对话、问候语 — JA / ZH / EN
- **数据文件**：chars.json、colors.json、langs.json、status.json
- **Web 资源**：首页 HTML、JS、CSS、图片
- **站点配置**：SSL/TLS 基础设置、HSTS、错误页（prefix=0）

## 安装

```bash
./g41.sh kits add home
```
