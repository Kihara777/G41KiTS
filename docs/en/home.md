# home

[中文](../zh/home.md) | [English](home.md) | [日本語](../ja/home.md)

Site core data — character messages, theme colors, status codes, i18n.

## Info

| Item | Value |
|------|-------|
| Type | data |
| Depends | core, nginx, redis |

## Install

```bash
./g41.sh kits add home
```

## Notes

- compose:none — no Docker service
- Provides global i18n translations (ja/zh/en)
- Provides tiles/apps/links target directories
- Data files (chars.json, colors.json, etc.) loaded into Redis