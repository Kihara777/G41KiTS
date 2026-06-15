# hexo

[中文](../zh/hexo.md) | [English](hexo.md) | [日本語](../ja/hexo.md)

Personal blog engine.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps, hako, nginx |
| Container | hx |

## Install

```bash
./g41.sh kits add hexo
```

## Notes

- Locally built from Dockerfile (`FROM node:24.16.0-alpine` + hexo-cli@4.3.2)
- Virtual host `server_name log.*`
- Health check: `wget -q http://127.0.0.1:4000/`
- Persist directory `.hx` with survive flag
