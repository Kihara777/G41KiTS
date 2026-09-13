# G41KiTS — k8s/k3s 部署层

Docker Compose 架构的 k3s 平替。核心思想：**k8s 只接管容器编排；内容装配
（tile/i18n/site 硬链接、.local 注入）仍由 `g41.sh` 在宿主机完成**，容器通过
`hostPath` 挂载 `/opt/g41/...`（`/opt/g41` 是指向仓库根目录的稳定符号链接）。

## 目录结构

```
k8s/
├── base/                 # 集群级资源（Namespace、cert-manager）
├── examples/             # issuer/certificate 形状示例（真实对象由 g41.sh 生成）
├── host/                 # 宿主机级单元与脚本（调优、状态备份、定时任务）
└── README.md
kits/<module>/k8s/        # 每个容器模块的 Deployment/Service
```

## 架构决策

| 主题 | 决策 |
|---|---|
| include 痛点 | k8s 无中央清单：`g41.sh k8s apply` 自动遍历 `kits/*/k8s/`；纯 kubectl 等价于 `kubectl apply $(for d in k8s/base kits/*/k8s; do printf -- '-f %s ' "$d"; done)`（shell glob，零编辑） |
| 数据 | hostPath 挂载 `/opt/g41/.rd` 等 → **零数据迁移**，与 compose 共用同一批目录 |
| 证书 | cert-manager（Cloudflare DNS01）替代 acme.sh；常驻（replicas=1）自动续期。续期后的分发见「证书轮换」一节 |
| acme/autoheal/dsock | 无 k8s manifest，整体退役（探针/cert-manager 原生替代） |
| 网关 | 保留 nginx（hostPort 80/443）；配置 ConfigMap 化（`g41.sh k8s conf` 从 .gx 装配结果渲染），sidecar 轮询检测变更自动 `nginx -s reload` |
| hy2 | hostNetwork（443/udp 与 nginx 共存，同现状） |
| 镜像 | hub 模块沿用原镜像；`compose: file` 模块 `docker build` + `k3s ctr images import`（tag `g41k8s/<kit>:local`） |
| 密钥 | `kubectl create secret g41-env --from-env-file=.env`（声明式、幂等、自更新） |
| 健康检查 | compose healthcheck → livenessProbe（同命令） |
| 资源限制 | mem_limit/cpus → resources.limits/requests |
| Pod 整合 | tracker 并入 api 进程（entry.js）、api 并入 redis Pod（sidecar）、aria2+bt 合 Pod |

## Pod 拓扑（整合后）

| Pod | 内容 | 镜像 |
|---|---|---|
| nginx | 网关（ConfigMap + reload sidecar） | nginx:alpine |
| redis | redis + api + tracker（同进程） | redis / g41k8s/redis:local（node:24-alpine） |
| download | aria2 + bt 双容器共享 webroot | g41k8s/{aria2,bt}:local |
| dns / hy2 / hako / blc | 单服务 | 各自原镜像 |

## 证书轮换

cert-manager 续期后只更新 Secret `g41/g41-tls`；Pod 内证书文件虽由 kubelet
自动刷新（`..data` 符号链接切换），但**进程不会自动重读**。各消费者能力不一：

| 消费者 | 机制 | 轮换动作 |
|---|---|---|
| nginx | 自带 reloader sidecar（轮询 `/certs` 后 `kill -HUP 1`） | 热加载，**不重启** |
| hy2 | hostNetwork UDP/443，无热加载 | 滚动重启 |
| dns | UDP/53/853，无热加载 | 滚动重启 |

> `hy2`/`dns` 上的 `reloader.stakater.com/auto` 注解**是失效的** —— 集群内并未
> 部署 stakater/reloader 控制器（`k8s/base/` 也不含它）。注解仅为历史遗留，
> 真正生效的重启由 `g41-cert-reload.timer` 负责。

`g41-cert-reload.timer` 每 15 分钟比对 Secret 中 `tls.crt` 的 sha256，变化时
执行上述分发；同一指纹下为空操作（幂等），并在分发前用 `openssl -checkend 0`
拒绝已过期证书。

## 定时任务

| 单元 | 周期 | 作用 |
|---|---|---|
| `g41-cert-reload.timer` | 每 15 分钟 | 证书更新后分发到 hy2/dns（nginx 热加载），指纹幂等 |
| `g41-image-update.timer` | 每周日 04:30 | 比对浮动 tag 上游 digest + 重建本地 `:local` 镜像 |

脚本位于 `k8s/host/`，部署到 `/opt/g41/k8s/host/`，宿主机单元装到
`/etc/systemd/system/`。状态存于 `/var/lib/g41/`。日志：`journalctl -u <unit>`。
有实质动作（证书轮换 / 镜像更新 / 失败）时经 `g41-notify.py` 发信；未配置
`G41_SMTP_*` 时静默跳过，不影响任务本身。

### 本地镜像构建（containerd 原生）

k8s 模式下 **dockerd 是停用的**（集群用 k3s 自带 containerd），因此原有的
`docker build` + `docker save | k3s ctr images import` 路径无法运行。改为：

```
nerdctl build --buildkit-host unix:///run/buildkit/buildkitd.sock \
              --address /run/k3s/containerd/containerd.sock --namespace k8s.io
```

BuildKit 以 **containerd worker** 模式直接把镜像构建进 k3s 的 `k8s.io`
namespace 与 `overlayfs` snapshotter，**省去 save/import 两步**，构建完成即可
被 kubelet 使用。`buildkitd.service` 提供守护进程；`g41-image-build.sh` 是
构建入口，`./g41.sh k8s build [module]` 也会优先路由到它。

需预先放置的二进制（体积大，不随仓库分发，`install-1gb.sh` 会检测）：

| 路径 | 来源 |
|---|---|
| `/usr/local/bin/nerdctl` | https://github.com/containerd/nerdctl/releases |
| `/usr/local/bin/buildkitd` | https://github.com/moby/buildkit/releases |
| `/usr/local/bin/buildctl` | 同上 |

只构建 **k8s 下真正部署**的 `compose: "file"` 模块（有 `kits/<m>/k8s/` 的）；
`autoheal`/`dsock`/`acme` 等已退役模块会自动跳过。构建上下文按 Dockerfile 的
COPY 路径风格自动判定（`kits/<m>/...` → 仓库根；裸文件名 → kit 目录）。

每周任务以「Dockerfile + 被 COPY 文件」的内容哈希判断是否需重建，未变化则跳过，
避免空转。

### 单节点滚动更新的三个硬约束

本集群只有 **一个节点**，以下三点若不满足会导致 rollout **永久卡死**、
**静默不生效**或**控制面崩溃**，均已实测踩坑：

1. **hostPort 与 maxSurge 互斥** —— 使用 `hostPort` 的 Deployment（nginx
   80/443、dns 53/853、download 51413）若 `maxSurge>0`，新 Pod 会因宿主机端口
   被旧 Pod 占用而永久 `Pending`。必须 `maxSurge=0`（先停后起，秒级中断）。
   `hy2` 用 `hostNetwork` 而非 `hostPort`，不受此限。
2. **浮动 tag 必须 `imagePullPolicy: Always`** —— 非 `:latest` 的浮动 tag
   （如 `nginx:alpine`）未显式声明时默认 `IfNotPresent`，`rollout restart`
   只会复用本地缓存镜像，**上游发布新版也永远拉不到**。脚本会在重启前后比对
   `imageID` 以捕获这种"报成功但未生效"的情况。

两个脚本均内置上述护栏（`ensure_rollout_safe` / `ensure_pull_policy`），会在
重启前自动修正并记录 `FIX` 日志。

3. **必须依赖 `k3s-standalone.service`，不能依赖 `k3s.service`** —— k3s 安装包
   自带的 `k3s.service` 虽被 disable，但单元文件仍在，且 `Restart=always`。
   若定时任务写 `Wants=k3s.service`，每次触发都会把这个遗留单元拉起来，它与
   `k3s-standalone` 抢占 `127.0.0.1:6444` 端口 → `bind: address already in use`
   → apiserver crash-loop（实测 restart counter 涨到 41，API 返回
   `ServiceUnavailable`）。`k3s-standalone.service` 已加 `Conflicts=k3s.service`
   作为第二道防线。

## 使用

```bash
./g41.sh backend k8s              # 切换后端（写入 .env: G41_BACKEND=k8s）
./g41.sh k8s apply --all          # 应用 base + 全部模块 manifest（引导部署）
./g41.sh k8s conf                 # 仅重渲染 nginx 配置 ConfigMap（sidecar 自动 reload）
./g41.sh kits add -y <module>     # 安装模块：装配内容 + 构建镜像 + apply manifest
./g41.sh kits del -y <module>     # 卸载模块：删除 manifest + 移除装配内容
./g41.sh k8s build                # 重建全部 compose=file 模块的镜像
./g41.sh k8s status               # pods/svc/deploy 概览
./g41.sh kits reload              # Redis 热重载（kubectl exec deploy/api）
```

## 前置条件

- **内存 ≥ 2GB**（k3s 控制面 ~300MB + 工作负载；1GB 可跑，见 docs/zh/1gb-stability.md，但长期建议 2GB）
- k3s 安装建议：`curl -sfL https://get.k3s.io | sh -s - --disable traefik --disable metrics-server --disable servicelb`
  （网关用 nginx、端口用 hostPort，无需 traefik/servicelb）
- `kubectl`（root：`export KUBECONFIG=/etc/rancher/k3s/k3s.yaml`）
- cert-manager 由 base/ 中的 HelmChart CR 自动安装（k3s helm-controller）；
  本部署**不使用** stakater/reloader（nginx 自带 sidecar，hy2/dns 由定时任务重启）

## 回滚

compose 与 k8s 共用宿主机数据目录，双轨共存。回滚 = `./g41.sh backend compose`
+ `docker compose up -d`（k8s 侧先 `kubectl delete -f` 或直接停 k3s），数据无损。
详见 `docs/zh/k8s-migration.md`。
