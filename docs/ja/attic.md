# attic
[中文](../zh/attic.md) | [English](../en/attic.md) | [日本語](attic.md) | [ｶﾀﾘｯｼｭ](../katalish/attic.md) | [偽中国語](../pcn/attic.md)

セルフホスト Nix バイナリキャッシュサーバー（atticd）。

## 基本情報

| 項目 | 値 |
|------|-----|
| タイプ | service |
| 依存 | nginx |
| コンテナ | attic |
| イメージ | ghcr.io/zhaofengli/attic（Docker Hub） |

## インストール

```bash
./g41.sh kits add attic
```

## 初回設定

1. `.env` に `ATTIC_TOKEN_SECRET` を設定（強力なランダム文字列）
2. 署名鍵ペアを生成：
   ```bash
   docker compose exec attic atticd --database /data/attic.db generate-keypair
   ```
3. 出力された公開鍵をクライアント設定に記入

## 注意

- ステータスページ：`/attic/`
- データディレクトリ：`.attic/`
- API エンドポイントは 127.0.0.1:8188 でリッスン、nginx がリバースプロキシ
