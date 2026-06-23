# autoheal
[中文](../zh/autoheal.md) | [English](../en/autoheal.md) | [日本語](../ja/autoheal.md) | ｶﾀﾘｯｼｭ | [偽中国語](../pcn/autoheal.md)

ｵｰﾄ-再起動 unhealthy Docker ｺﾝﾃﾅ

## ｲﾝﾌｫ

| 項目 | 値 |
|------|-------|
| ﾀｲﾌﾟ | ｻｰﾋﾞｽ |
| 依存 | ｺｱ,dsock |
| 容器 | ah |
| 镜像 | 本地构建 |

## ｲﾝｽﾄｰﾙ

```bash
./g41.sh kits add autoheal
```

## 注意

- 自定义 Dockerfile（基于 willfarrell/autoheal），支持 TCP ｿｹｯﾄ\n- 通过 DOCKER_SOCK=tcp://ds:2375 连接 dsock\n- 每 5 秒检查一次容器健康状态