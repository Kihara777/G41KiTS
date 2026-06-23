# tile_mail

[中文](../zh/tile_mail.md) | [English](../en/tile_mail.md) | [日本語](../ja/tile_mail.md) | [ｶﾀﾘｯｼｭ](../katalish/tile_mail.md) | 偽中国語 

MailKits 代理体系磁貼。

## 基本情報

| 項目 | 値 |
|------|-----|
| 種別 | tile |
| 依存 | home |
| 図標 | 📧 |

## 導入

```bash
./g41.sh kits add tile_mail
```

## 磁貼内容

- 概要：Cloudflare Email Workers + Resend 基之零費用透過代理
- 構造：Email Routing → mail-worker → 転送/返信/送信
- 機能：送信者識別、後設資料埋込、Resend API 送信、無料枠運用
- GitHub 連結 `github.com/Kihara777/MailKits`