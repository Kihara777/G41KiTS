# tile_mail
[中文](../zh/tile_mail.md) | [English](../en/tile_mail.md) | 日本語 | [ｶﾀﾘｯｼｭ](../katalish/tile_mail.md) | [偽中国語](../pcn/tile_mail.md)

MailKits メールプロキシシステムタイル。

## 基本情報

| 項目 | 値 |
|------|-----|
| タイプ | tile |
| 依存 | home |
| アイコン | 📧 |

## インストール

```bash
./g41.sh kits add tile_mail
```

## タイル内容

- 概要：Cloudflare Email Workers + Resend ベースのゼロコスト透過メールプロキシ
- アーキテクチャ：Email Routing → mail-worker → 転送/返信/送信
- 機能：送信者識別、メタデータ埋め込み、Resend API 送信、無料枠運用
- GitHub リンク `github.com/Kihara777/MailKits`
