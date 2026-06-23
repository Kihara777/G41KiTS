# ﾄﾗｯｶｰ
[中文](../zh/tracker.md) | [English](../en/tracker.md) | [日本語](../ja/tracker.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/tracker.md)

ﾗｲﾄｳｪｲﾄ HTTPS BitTorrent ﾄﾗｯｶｰ

## ｲﾝﾌｫ

| 項目 | 値 |
|------|-------|
| ﾀｲﾌﾟ | ｻｰﾋﾞｽ |
| 依存 | hako,home,nginx |
| ｺﾝﾃﾅ | wt |
| ｲﾒｰｼﾞ | node + bittorrent-ﾄﾗｯｶｰ（Dockerfile 本地构建） |

## ｲﾝｽﾄｰﾙ

```bash
./g41.sh kits add tracker
```

## 注意

- HTTP/UDP/WebSocket 複数-protocol
- 埋込: /ﾄﾗｯｶｰ (ｽﾃｰﾀｽ ﾍﾟｰｼﾞ)
- UDP 6969 ｵｰﾌﾟﾝ ﾄｩ ﾊﾟﾌﾞﾘｯｸ (UFW)
- ﾍﾙｽ ﾁｪｯｸ: wget http://127.0.0.1:8000/stats