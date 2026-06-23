# shortlinks

[中文](../zh/shortlinks.md) | [English](../en/shortlinks.md) | [日本語](../ja/shortlinks.md) | 偽中国語 | [ｶﾀﾘｯｼｭ](../katalish/shortlinks.md)

Redis API 経由之動的短縮連結。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | link |
| 依存 | nginx |

## 導入

```bash
./g41.sh kits add shortlinks
```

## 注意

- nginx location 之正規表現以長令牌、Redis API 於転送