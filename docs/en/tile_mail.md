# tile_mail

[中文](../zh/tile_mail.md) | [English](tile_mail.md) | [日本語](../ja/tile_mail.md)

MailKits email proxy system tile.

## Info

| Item | Value |
|------|-------|
| Type | tile |
| Depends | home |
| Icon | 📧 |

## Install

```bash
./g41.sh kits add tile_mail
```

## Tile Content

- Overview: Zero-cost transparent email proxy based on Cloudflare Email Workers + Resend
- Architecture: Email Routing → mail-worker → forward/reply/send
- Features: sender identification, metadata embedding, Resend API sending, free tier
- GitHub link `github.com/Kihara777/MailKits`
