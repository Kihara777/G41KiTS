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

- No Docker service — pure data module
- JSON files in `data/` loaded into Redis on API startup
- `webroot/` provides homepage HTML/JS/CSS and site icons
- `i18n/` provides global multi-language translations
- Host field in chars.json injected by API from `G41_DOMAIN` env var