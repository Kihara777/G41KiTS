# shortlinks

[中文](../zh/shortlinks.md) | [English](../en/shortlinks.md) | [日本語](../ja/shortlinks.md)

> 動的ショートリンク — Redis API を利用した動的ショートリンクシステム。

## 情報

| 項目 | 値 |
|------|-----|
| 種類 | link |
| 依存 | nginx |

## インストール

```bash
./g41.sh kits add shortlinks
```

## 注意

- 純粋な nginx 設定モジュール（compose: none）、Docker サービスなし
- nginx location の正規表現 `^/([A-Za-z0-9%+_=-]{20,})$` でショートリンクトークンを照合
- 一致したリクエストを Redis API の `/link/` エンドポイントに proxy_pass
- API が Redis で `link:<token>` を検索し、ヒットすれば 302 リダイレクト
- Redis に対応するマッピングがなければ 404 を返す
