# hexo

[中文](../zh/hexo.md) | [English](hexo.md) | [日本語](../ja/hexo.md)

Personal blog engine

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | tile_apps,hako,nginx |
| Container | hx |
| Image | node + hexo-cli（Dockerfile 本地构建） |

## Install

```bash
./g41.sh kits add hexo
```

## Notes

- server_name: log.*
- Health check: wget http://127.0.0.1:4000/
- Survive: .hx/ preserved on uninstall
