# hy2
[中文](../zh/hy2.md) | [English](../en/hy2.md) | 日本語

Hysteria2 プロキシ（nginx と 443 ポート共有）

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | nginx |
| コンテナ | hq |
| イメージ | tobyxdd/hysteria |

## インストール

```bash
./g41.sh kits add hy2
```

## 注意

- ホストネットワークモード
- nginx と 443 ポート共有
- 設定は .local/hysteria.yaml（非公開）
- サブスクリプションファイルは .local/webroot/（非公開）
