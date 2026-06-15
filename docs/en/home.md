# home

[中文](../zh/home.md) | [English](home.md) | [日本語](../ja/home.md)

Site core data — character messages, theme colors, status codes, i18n.

## Info

| Item | Value |
|------|-------|
| Type | data |
| Depends | core, nginx, redis |
| Container | — |

## Install

```bash
./g41.sh kits add home
```

## Notes

- Data-only module, no Docker service (`compose: none`)
- Provides global i18n translations (ja/zh/en)
- Manages `error_page` config for homepage tiles
- Site metadata defined in `data/` directory: characters (chars.json), theme colors (colors.json), status codes (status.json)
- Webroot contains G41.html, CSS, JS, and image assets
