# blc
[中文](../zh/blc.md) | English | [日本語](../ja/blc.md)

Bilibili live chat with AI translation

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps,nginx |
| Container | lc |
| Image | xfgryujk/blivechat |

## Install

```bash
./g41.sh kits add blc
```

## Provides for dependents

blc provides `blc_template` type to modules that depend on it:

| Field | Value |
|-------|-------|
| Type | `blc_template` |
| Target directory | `.lc/custom_public/templates/<module>/` |
| Container path | `/mnt/data/data/custom_public/templates/<module>/` |
| Source directory | `blc_template/` under consumer module |

Modules depending on blc can place a `blc_template/` directory (containing `template.json`) in their module directory. On install, files are hardlinked to the blivechat templates directory. Restart blc container for new templates to take effect:

```bash
docker compose restart blc
```

## Notes

- server_name: blc.*
- WebSocket: /api/chat
- Health check: wget http://127.0.0.1:12450/
- Template directory: `.lc/custom_public/templates/` (restart required)
