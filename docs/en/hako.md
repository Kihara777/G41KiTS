# hako

[中文](../zh/hako.md) | [English](hako.md) | [日本語](../ja/hako.md)

Web file manager with public WebDAV share.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps, nginx |
| Container | fb |
| Image | filebrowser/filebrowser:v2.63.14-s6 |

## Install

```bash
./g41.sh kits add hako
```

## Notes

- Docker Hub image, pinned to `v2.63.14-s6`
- WebUI default port 80
- Health check: `wget -q http://127.0.0.1:80/`
- Branding files installed via `.local/branding/`
