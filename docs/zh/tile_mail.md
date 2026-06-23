# tile_mail
中文 | [English](../en/tile_mail.md) | [日本語](../ja/tile_mail.md) | [ｶﾀﾘｯｼｭ](../katalish/tile_mail.md) | [偽中国語](../pcn/tile_mail.md)

MailKits 邮件代理系统磁贴。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | tile |
| 依赖 | home |
| 图标 | 📧 |

## 安装

```bash
./g41.sh kits add tile_mail
```

## 磁贴内容

- 项目概述：基于 Cloudflare Email Workers + Resend 的零成本透明邮件代理
- 架构说明：Email Routing → mail-worker → 转发/回复/发送
- 功能要点：发件人识别、元数据嵌入、Resend API 发送、免费额度运行
- GitHub 链接 `github.com/Kihara777/MailKits`
