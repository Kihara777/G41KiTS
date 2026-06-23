# attic
[中文](../zh/attic.md) | English | [日本語](../ja/attic.md)

Self-hosted Nix binary cache server (atticd).

## Info

| Item | Value |
|------|-------|
| Type | service |
| Depends | nginx |
| Container | attic |
| Image | ghcr.io/zhaofengli/attic (Docker Hub) |

## Install

```bash
./g41.sh kits add attic
```

## First-time Setup

1. Set `ATTIC_TOKEN_SECRET` in `.env` (strong random string)
2. Generate signing keypair:
   ```bash
   docker compose exec attic atticd --database /data/attic.db generate-keypair
   ```
3. Use the output public key in client configuration

## Notes

- Status page: `/attic/`
- Data directory: `.attic/`
- API endpoint listens on 127.0.0.1:8188, exposed via nginx reverse proxy
