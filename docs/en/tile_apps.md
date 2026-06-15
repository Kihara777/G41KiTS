# tile_apps

[中文](../zh/tile_apps.md) | [English](../en/tile_apps.md) | [日本語](../ja/tile_apps.md)

> Application list tile — entry point for all services on the homepage.

## Info

| Field | Value |
|-------|-------|
| Type | tile |
| Depends | core, home, nginx |
| Compose | none |

## Install

```bash
./g41.sh kits add tile_apps
```

## Notes

- Aggregates app entries from all `app.json` modules
- Each entry includes name, icon, description, and link
- No Docker service — tile data served via Redis API