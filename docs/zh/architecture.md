# G41KiTS 架构总览
中文 | [English](../en/architecture.md) | [日本語](../ja/architecture.md) 

一张图看懂：**一个模块从声明到上线，经过哪几条管道、每条的单一来源是什么、判据落在哪里。**

字段级细节见 [kits-spec.md](kits-spec.md)；迁移过程见 [k8s-migration.md](k8s-migration.md)。

## 一句话

仓库是唯一来源；宿主机上没有「另一份内容」。所有下线产物都从 `kits/` 单向生成，
生成物要么进 ConfigMap、要么进 containerd、要么进集群清单。

## 一个模块是什么

```
kits/<名字>/
├── info.json          声明
├── tile.json          ┐
├── app.json           │ 内容文件（走哪条管道由 provider 的 provides 决定）
├── link.json          │
├── i18n/<lang>.json   │
├── data/<name>.json   ┘
├── k8s/*.yaml         集群清单（有它才会被装进集群）
├── store/             需要 hardlink 到运行目录的文件（少数模块）
└── .local/            部署专属文件（不入库）
```

## 四条管道

```
                      ┌─────────────────────────────────────────────────┐
   kits/*/info.json   │  仓库是唯一来源                                  │
   + 内容文件          └─────────────────────────────────────────────────┘
          │
          ├──(1) kits content ──→ dist/g41-content.yaml ──apply──→ ConfigMap g41-content
          │        │                 （类型 → 目录 的映射作为 _map.json 一起下发）
          │        │                                                      │
          │        │                                                      ▼
          │        │                                         redis Pod: /seed 挂载
          │        │                                                      │
          │        │                                          loader 落盘 → 写 Redis
          │        │                                                      │
          │        │                                                      ▼
          │        │                                                    前端
          │        │
          ├──(2) kits api-src ──→ dist/g41-api-src.yaml ──apply──→ ConfigMap g41-api-src
          │                                                              │
          │                                                    redis Pod: /app/server.js
          │
          ├──(3) g41-image-build.sh ──→ containerd: g41k8s/<模块>:<版本>（+ :local 别名）
          │
          └──(4) kits export <模块> ──→ dist/<模块>-<版本>.yaml ──kubectl apply──→ 集群

  装载触发：Redis 里没有 data:loaded 时才装载。改了内容/源码要
  `DEL data:loaded` 再重启 redis Pod —— 否则 Pod 重启但**不会重新装载**。
```

## 类型与目标位置：由 provider 决定

模块类型不是看文件名，而是看它**依赖了谁**、那个 provider 声明接收什么。

```
home/info.json:
  provides: [{dir:"tiles", accepts:["tile"], file:"tile.json", ext:"json", content:true},
             {dir:"i18n",  accepts:["i18n"], file:"i18n",     ext:"json", content:true}]

kits/tile_friends/   依赖 home，且有 tile.json 和 i18n/  → 是 tile 与 i18n 的消费者
kits/dns/            有 tile.json 但依赖 home → 同上
```

`kits content` 解析出的映射随种子下发：

```
_map.json = { "tile": {dir:"tiles",  file:"tile.json", ext:"json", shape:"file"},
              "i18n": {dir:"i18n",   file:"i18n",      ext:"json", shape:"dir"},
              "app":  {dir:"tile_apps",  ...}, "link": {dir:"tile_links", ...},
              "data": {dir:"",       ...} }        ← 空 dir = Redis 数据根

loader 的写侧与读侧都用这张表 —— 只改一侧会导致「落地成功但读不到」。
```

`content: true` 表示「这个类型走内容种子」。`site`（nginx conf）、`webroot`（静态资源）、
`blc_template` 没有这个标记，各有各的供给路径。

## 从仓库到线上

```
git push
   │
   ├─ GitHub Actions: check.yml（21 项闸门，不碰生产）
   └─ GitHub Actions: deploy.yml
        ├─ 守卫：HEAD == origin/main ？（否则拒绝，防止积压的旧 run 把生产拉回旧版本）
        ├─ rsync 到部署机
        ├─ kits content → apply g41-content
        ├─ kits api-src → apply g41-api-src
        └─ k8s apply --all
```

镜像不在这条线上：**自建镜像只在部署机的 containerd 里**，用
`/opt/g41/k8s/host/g41-image-build.sh` 构建（无参 = 全部已部署模块）。这是恢复路径。

## 命令面

| 命令 | 做什么 | 何时用 |
|------|--------|--------|
| `kits install <m>` | 校验 → 构建镜像 → 刷新种子/源码 → 出包 → apply（自动装依赖） | 装一个模块 |
| `kits uninstall <m>` | 删对象 + 种子排除该模块（有反向依赖则拒绝） | 卸一个模块 |
| `kits update <m> --to <v> --build` | 改版本 + 构建 + 出包 | 升级 |
| `kits rollback <m>` | 回到 `dist/` 里的旧版本 | 出事回退（**只改集群，仓库要一起改**） |
| `kits status [--cluster]` | 现状账：版本 / Pod 组 / 镜像 / 内容键 | 「现在装了什么」 |
| `kits health` | 五项体检 | 「线上和仓库是否一致」 |
| `kits images --verify` | 清单引用的 tag 在不在 containerd | apply 之前 |
| `kits remote <url>` | 从远程地址安装一个清单 | 装外部扩展 |

`kits add` / `kits del` 在 k8s 后端下**转发**到 `install` / `uninstall`——
它们原本的宿主装配路径在 k8s 下没有消费者。

## 判据落在哪里

| 判据 | 位置 | 跑什么 | 失败意味着 |
|------|------|--------|-----------|
| 闸门 21 项 | GitHub Actions（每次 push） | 语法、清单 schema、内容种子逐字节还原、镜像 tag 与版本一致、ConfigMap 引用闭环、README 与体检自检 | 这次提交不该合并 |
| loader 自检 32 项 | 容器内（`G41_FS_SELFTEST=1`） | 种子键解析、映射驱动、过期键判定、readDir 过滤 | loader 逻辑坏了 |
| 生产体检 5 项 | 部署机，每 6 小时（`g41-health.timer`） | 镜像存在、drift、内容种子与仓库逐键一致、api 源码一致、站点 200 | 线上与仓库分叉；**只在状态变化时通知** |
| 三态约定 | 所有判据 | 0 通过 / 1 有失败 / 2 没能验到 | 2 不是通过 |

## 已知边界

1. **新类型仍需代码**：`_map` 让「装到哪」成为数据，但 loader 的语义（tile 是列表项、
   i18n 按语言合并）按类型名分支。这一点老设计就有，不是 ConfigMap 引入的。
2. **`dir` 同时是 Redis 键空间**：改 `tile_apps` 的 `dir`，键名跟着变，前端就不认。
   「provider 想改哪就改哪」只在键空间之外成立。
3. **镜像没有 registry**：只在部署机的 containerd 里，可从 git 重建，但没有远端副本。
4. **`kits add all` 慢**：25 个模块各跑一遍 verify + export，以分钟计。
