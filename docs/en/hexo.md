# hexo

[中文](../zh/hexo.md) | [English](hexo.md) | [日本語](../ja/hexo.md)

Personal blog engine.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps, hako, nginx |
| Container | hx |
| Image | local build |

## Install

```bash
./g41.sh kits add hexo
```

## Notes

- `server_name log.*`, matched by nginx virtual host
- Blog content stored in `.hx/source/`, editable via hako WebDAV
- compose=file, built locally from Node.js base image
