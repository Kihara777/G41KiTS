# shortlinks

[中文](../zh/shortlinks.md) | [English](../en/shortlinks.md) | [日本語](../ja/shortlinks.md)

> Dynamic short links resolved via Redis API.

## Info

| Field | Value |
|-------|-------|
| Type | link |
| Depends | nginx |
| Compose | none |

## Install

```bash
./g41.sh kits add shortlinks
```

## Notes

- nginx location 正则匹配 `^/([A-Za-z0-9%+_=-]{20,})$`
- Token 转发至 Redis API `/link/{token}` → 302 redirect
- 无 Docker 服务 — 纯 nginx 路由