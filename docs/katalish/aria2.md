# aria2
[中文](../zh/aria2.md) | [English](../en/aria2.md) | [日本語](../ja/aria2.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/aria2.md)

並列 ﾀﾞｳﾝﾛｰﾄﾞ ﾑｱﾝｱｼﾞｴﾗ ｳｨｽﾞ WebUI ｱﾝﾄﾞ WebDAV ｼｪｱ

## ｲﾝﾌｫ

| 項目 | 値 |
|------|-------|
| ﾀｲﾌﾟ | ｻｰﾋﾞｽ |
| 依存 | ﾀｲﾙ_apps,hako,nginx |
| ｺﾝﾃﾅ | ad |
| ｲﾒｰｼﾞ | alpine + aria2（Dockerfile 本地构建） |

## ｲﾝｽﾄｰﾙ

```bash
./g41.sh kits add aria2
```

## 注意

- WebUI: /aria2/
- RPC: /aria2rpc (WebSocket ws://)
- AriaNg AllInOne embedded
- ﾍﾙｽ ﾁｪｯｸ: nc -zw1 127.0.0.1 6800