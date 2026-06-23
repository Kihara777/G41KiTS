# autoheal

[中文](../../zh/autoheal.md) | [English](../../en/autoheal.md) | [日本語](../../ja/autoheal.md) | [偽中国語](autoheal.md) | [ｶﾀﾘｯｼｭ](../../katalish/autoheal.md)

異常 Docker 容器之自動再起動

## 基本情報

| 項目 | 値 |
|------|-----|
| 種類 | service |
| 依存 | core,dsock |
| 容器 | ah |
| 镜像 | 本地构建 |

## 導入

```bash
./g41.sh kits add autoheal
```

## 注意

- 自定义 Dockerfile（基于 willfarrell/autoheal），支持 TCP socket\n- 通过 DOCKER_SOCK=tcp://ds:2375 连接 dsock\n- 每 5 秒检查一次容器健康状态