# ﾀｲﾙ_mail
[中文](../zh/tile_mail.md) | [English](../en/tile_mail.md) | [日本語](../ja/tile_mail.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/tile_mail.md)

MailKits email ﾌﾟﾛｸｼ ｼｽﾃﾑ ﾀｲﾙ.

## ｲﾝﾌｫ

| 項目 | 値 |
|------|-------|
| ﾀｲﾌﾟ | ﾀｲﾙ |
| 依存 | home |
| ｱｲｺﾝ | 📧 |

## ｲﾝｽﾄｰﾙ

```bash
./g41.sh kits add tile_mail
```

## ﾀｲﾙ内容

- 概要: ｾﾞﾛ-cost 透過 email ﾌﾟﾛｸｼ based ｵﾝ Cloudflare Email ﾜｰｶｰ + Resend
- ｱｰｷﾃｸﾁｬ: Email Routing → mail-worker → forward/reply/send
- 機能: sender identification, metadata embedding, Resend API sending, free tier
- GitHub ﾘﾝｸ `github.com/Kihara777/MailKits`