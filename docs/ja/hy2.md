# hy2

[中文](../zh/hy2.md) | [English](../en/hy2.md) | [日本語](hy2.md)

Hysteria2 プロキシ、nginx と 443 ポートを共有。

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

- host ネットワークモード、SO_REUSEPORT で nginx と 443/UDP を共有
- 設定ファイル `hysteria.yaml` は .local/ に配置（パスワード含む、gitignored）
- サブスクリプションファイルは WebDAV 経由で提供
