# dsock
[中文](../zh/dsock.md) | [English](../en/dsock.md) | [日本語](../ja/dsock.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/dsock.md)

Restricted Docker API ﾌﾟﾛｸｼ, 置換 直接 docker.sock ﾏｳﾝﾄ

## ｲﾝﾌｫ

| 項目 | 値 |
|------|-------|
| ﾀｲﾌﾟ | ｻｰﾋﾞｽ |
| 依存 | ｺｱ |
| 容器 | ds |
| 镜像 | tecnativa/docker-ｿｹｯﾄ-ﾌﾟﾛｸｼ |

## ｲﾝｽﾄｰﾙ

```bash
./g41.sh kits add dsock
```

## 注意

- 挂载 /var/run/docker.sock 只读（:ro）\n- 限制 API 端点为 ｺﾝﾃﾅ + EXEC + POST