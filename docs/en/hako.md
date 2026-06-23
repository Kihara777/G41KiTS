# hako
[中文](../zh/hako.md) | English | [日本語](../ja/hako.md) | [ｶﾀﾘｯｼｭ](../katalish/hako.md) | [偽中国語](../pcn/hako.md)

Web file manager with public WebDAV share

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps,nginx |
| Container | fb |
| Image | filebrowser/filebrowser |

## Install

```bash
./g41.sh kits add hako
```

## Notes

- Based on File Browser
- WebDAV sharing
- Health check: wget http://127.0.0.1:80/
