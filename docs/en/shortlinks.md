# shortlinks

[中文](../zh/shortlinks.md) | [English](../en/shortlinks.md) | [日本語](../ja/shortlinks.md)

> Dynamic short links — Redis API-backed dynamic short link system.

## Info

| Field | Value |
|-------|-------|
| Type | link |
| Depends | nginx |

## Install

```bash
./g41.sh kits add shortlinks
```

## Notes

- Pure nginx config module (compose: none), no Docker service
- nginx location regex `^/([A-Za-z0-9%+_=-]{20,})$` matches short link tokens
- Matched requests proxy_pass to Redis API's `/link/` endpoint
- API looks up `link:<token>` in Redis, returns 302 redirect on hit
- Returns 404 if no matching mapping exists in Redis
