# home

[中文](../zh/home.md) | [English](home.md) | [日本語](../ja/home.md)

Site core data — character messages, theme colors, status codes, i18n

## Info

| Item | Value |
|------|-------|
| Type | data |
| Depends | core,nginx,redis |



## Install

```bash
./g41.sh kits add home
```

## Notes

- compose: none，无 Docker 服务\n- 提供 chars.json、colors.json、langs.json、status.json\n- 全局 i18n 提供者
