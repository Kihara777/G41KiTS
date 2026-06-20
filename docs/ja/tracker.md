# tracker

[中文](../zh/tracker.md) | [English](../en/tracker.md) | [日本語](tracker.md)

軽量 HTTPS BitTorrent トラッカー。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | hako, home, nginx |
| コンテナ | wt |
| イメージ | ローカルビルド |

## インストール

```bash
./g41.sh kits add tracker
```

## 注意

- `/announce` エンドポイントで BitTorrent 追跡リクエストを処理
- `/tracker` エンドポイントは HTML 統計を返し、タイル詳細ページに埋込可能
- UDP ポート 6969 を UFW 経由で公開
