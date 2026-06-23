# hy2

[中文](../../zh/hy2.md) | [English](../../en/hy2.md) | [日本語](../../ja/hy2.md) | [偽中国語](hy2.md) | [ｶﾀﾘｯｼｭ](../../katalish/hy2.md)

Hysteria2 代理（nginx 與 443 端口共有）

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | nginx |
| 容器 | hq |
| 鏡像 | tobyxdd/hysteria |

## 導入

```bash
./g41.sh kits add hy2
```

## 注意

- 宿主網絡模式
- nginx 與 443 端口共有
- 設定 .local/hysteria.yaml（非公開）
- 訂閲書類 .local/webroot/（非公開）