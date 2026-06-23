# bt
[中文](../zh/bt.md) | [English](../en/bt.md) | [日本語](../ja/bt.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/bt.md)

BitTorrent ｸﾗｲｱﾝﾄ ｳｨｽﾞ WebUI ｱﾝﾄﾞ WebDAV ｼｪｱ

## ｲﾝﾌｫ

| 項目 | 値 |
|------|-------|
| ﾀｲﾌﾟ | ｻｰﾋﾞｽ |
| 依存 | ﾀｲﾙ_apps,hako,nginx |
| ｺﾝﾃﾅ | tr |
| ｲﾒｰｼﾞ | alpine + transmission-daemon（Dockerfile 本地构建） |

## ｲﾝｽﾄｰﾙ

```bash
./g41.sh kits add bt
```

## 注意

- WebUI: /transmission/
- WebDAV: /transmission/ｼｪｱ
- ﾍﾙｽ ﾁｪｯｸ: nc -zw1 127.0.0.1 9091