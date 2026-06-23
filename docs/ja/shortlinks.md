# shortlinks
[中文](../zh/shortlinks.md) | [English](../en/shortlinks.md) | 日本語

Redis API 経由の動的短縮リンク。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | link |
| 依存 | nginx |

## インストール

```bash
./g41.sh kits add shortlinks
```

## 注意

- nginx location の正規表現で長いトークンをマッチ、Redis API に転送