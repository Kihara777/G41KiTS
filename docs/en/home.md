# home
[中文](../zh/home.md) | [English](home.md) | [日本語](../ja/home.md) | [ｶﾀﾘｯｼｭ](../katalish/home.md) | [偽中国語](../pcn/home.md)

Site core data — character messages, theme colors, status codes, i18n. Directly provides the homete tile (G41KiTS project intro).

## Info

| Item | Value |
|------|-------|
| Type | data + tile |
| Depends | core, nginx, redis |
| compose | none |

## Provides

- **Tile**: tile_homete (G41KiTS project overview and tech stack)
- **Global i18n**: character dialogue, greetings — JA / ZH / EN
- **Data files**: chars.json, colors.json, langs.json, status.json
- **Web resources**: homepage HTML, JS, CSS, images
- **Site config**: SSL/TLS base settings, HSTS, error pages (prefix=0)

## Install

```bash
./g41.sh kits add home
```
