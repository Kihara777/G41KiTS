# attic
[中文](attic.md) | [English](../en/attic.md) | [日本語](../ja/attic.md) | [ｶﾀﾘｯｼｭ](../katalish/attic.md) | [偽中国語](../pcn/attic.md)

自托管 Nix 二进制缓存服务器（atticd）。

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | nginx |
| 容器 | attic |
| 镜像 | ghcr.io/zhaofengli/attic（Docker Hub） |

## 安装

```bash
./g41.sh kits add attic
```

## 首次配置

1. 在 `.env` 中设置 `ATTIC_TOKEN_SECRET`（强随机字符串）
2. 生成签名密钥对：
   ```bash
   docker compose exec attic atticd --database /data/attic.db generate-keypair
   ```
3. 将输出的公钥填入客户端配置

## 注意

- 状态页面：`/attic/`
- 数据目录：`.attic/`
- API 端点仅监听 127.0.0.1:8188，由 nginx 反向代理对外暴露
