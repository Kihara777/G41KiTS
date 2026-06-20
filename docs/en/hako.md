# hako

[中文](../zh/hako.md) | [English](hako.md) | [日本語](../ja/hako.md)

Web file manager with public WebDAV share.

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps, nginx |
| Container | fb |
| Image | filebrowser/filebrowser |

## Install

```bash
./g41.sh kits add hako
```

## Notes

- Web file management UI with upload/download/preview
- Public WebDAV share at `/hako/`
- Config files `filebrowser.db` and `settings.json` deployed via .local
