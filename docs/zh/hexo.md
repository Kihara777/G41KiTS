# hexo
[中文](hexo.md) | [English](../en/hexo.md) | [日本語](../ja/hexo.md) | [ｶﾀﾘｯｼｭ](../katalish/hexo.md) | [偽中国語](../pcn/hexo.md)

个人博客引擎

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | service |
| 依赖 | tile_apps,hako,nginx |
| 容器 | hx |
| 镜像 | node + hexo-cli（Dockerfile 本地构建） |

## 安装

```bash
./g41.sh kits add hexo
```

## 注意

- server_name: log.*
- 健康检查: wget http://127.0.0.1:4000/
- survive 机制：卸载时保留 .hx/ 目录
