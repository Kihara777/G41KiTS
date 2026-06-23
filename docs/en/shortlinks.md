# shortlinks
[中文](../zh/shortlinks.md) | English | [日本語](../ja/shortlinks.md)

Dynamic short links proxied through Redis API.

## Info

| Item | Value |
|------|-------|
| Type | link |
| Depends | nginx |

## Install

```bash
./g41.sh kits add shortlinks
```

## Notes

- nginx location regex matches long tokens, forwards to Redis API