# attic

[中文](../../zh/attic.md) | [English](../../en/attic.md) | [日本語](../../ja/attic.md) | [偽中国語](attic.md) | [ｶﾀﾘｯｼｭ](../../katalish/attic.md)

宿主 Nix 二進緩衝伺服器（atticd）。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種別 | service |
| 依存 | nginx |
| 容器 | attic |
| 鏡像 | ghcr.io/zhaofengli/attic（Docker Hub） |

## 導入

```bash
./g41.sh kits add attic
```

## 初期設定

1. `.env` 於 `ATTIC_TOKEN_SECRET` 設定（強力乱数文字列）
2. 署名鍵対生成：
   ```bash
   docker compose exec attic atticd --database /data/attic.db generate-keypair
   ```
3. 出力公開鍵依頼者設定於記入

## 注意

- 状態頁：`/attic/`
- 資料目録：`.attic/`
- API 端点 127.0.0.1:8188 以聴取、nginx 逆代理