# attic
[中文](../zh/attic.md) | [English](../en/attic.md) | [日本語](../ja/attic.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/attic.md)

ｾﾙﾌﾎｽﾄ Nix ﾊﾞｲﾅﾘ ｷｬｯｼｭ ｻｰﾊﾞｰ (atticd).

## ｲﾝﾌｫ

| 項目 | 値 |
|------|-------|
| ﾀｲﾌﾟ | ｻｰﾋﾞｽ |
| 依存 | nginx |
| ｺﾝﾃﾅ | attic |
| ｲﾒｰｼﾞ | ghcr.io/zhaofengli/attic (Docker Hub) |

## ｲﾝｽﾄｰﾙ

```bash
./g41.sh kits add attic
```

## 初回設定

1. Set `ATTIC_TOKEN_SECRET` ｲﾝ `.env` (strong random string)
2. Generate signing keypair:
   ```bash
   docker ｺﾝﾎﾟｰｽﾞ exec attic atticd --database /ﾃﾞｲﾀ/attic.db generate-keypair
   ```
3. ﾕｰｽﾞ ｻﾞ output ﾊﾟﾌﾞﾘｯｸ key ｲﾝ ｸﾗｲｱﾝﾄ 設定

## 注意

- ｽﾃｰﾀｽ ﾍﾟｰｼﾞ: `/attic/`
- ﾃﾞｲﾀ ﾃﾞｨﾚｸﾄﾘ: `.attic/`
- API ｴﾝﾄﾞﾎﾟｲﾝﾄ listens ｵﾝ 127.0.0.1:8188, 露出済 via nginx ﾘﾊﾞｰｽ ﾌﾟﾛｸｼ