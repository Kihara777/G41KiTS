# home

[中文](../zh/home.md) | [English](../en/home.md) | [日本語](home.md)

サイトコアデータ — キャラクターメッセージ、テーマカラー、ステータスコード、i18n

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | data |
| 依存 | core,nginx,redis |



## インストール

```bash
./g41.sh kits add home
```

## 注意

- compose: none，无 Docker 服务\n- 提供 chars.json、colors.json、langs.json、status.json\n- 全局 i18n 提供者
