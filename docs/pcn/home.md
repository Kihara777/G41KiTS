# home

[中文](../../zh/home.md) | [English](../../en/home.md) | [偽中国語](home.md)

網站点核心資料 — 角色消息、主題色彩、状態符号、i18n。homete 磁貼（G41KiTS 計画紹介）直接提供。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | data + tile |
| 依存 | core, nginx, redis |
| compose | none |

## 提供内容

- **磁貼**：tile_homete（G41KiTS 計画概要與技術堆栈）
- **全局 i18n**：角色会話、挨拶 — JA / ZH / EN
- **資料書類**：chars.json、colors.json、langs.json、status.json
- **Web 資源**：首頁 HTML、JS、CSS、画像
- **網站点設定**：SSL/TLS 基本設定、HSTS、錯誤頁（prefix=0）

## 導入

```bash
./g41.sh kits add home
```