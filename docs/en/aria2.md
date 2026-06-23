# aria2
[中文](../zh/aria2.md) | English | [日本語](../ja/aria2.md) | [ｶﾀﾘｯｼｭ](../katalish/aria2.md) | [偽中国語](../pcn/aria2.md)

Parallel download manager with WebUI and WebDAV share

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps,hako,nginx |
| Container | ad |
| Image | alpine + aria2（Dockerfile 本地构建） |

## Install

```bash
./g41.sh kits add aria2
```

## Notes

- WebUI: /aria2/
- RPC: /aria2rpc (WebSocket ws://)
- AriaNg AllInOne embedded
- Health check: nc -zw1 127.0.0.1 6800
