# G41KiTS — k8s/k3s 部署层

Docker Compose 架构的 k3s 平替。核心思想：**k8s 只接管容器编排；内容装配
（tile/i18n/site 硬链接、.local 注入）仍由 `g41.sh` 在宿主机完成**，容器通过
`hostPath` 挂载 `/opt/g41/...`（`/opt/g41` 是指向仓库根目录的稳定符号链接）。

## 目录结构

```
k8s/
├── base/                 # 集群级资源（Namespace、cert-manager、reloader）
├── examples/             # issuer/certificate 形状示例（真实对象由 g41.sh 生成）
└── README.md
kits/<module>/k8s/        # 每个容器模块的 Deployment/Service
```

## 架构决策

| 主题 | 决策 |
|---|---|
| include 痛点 | k8s 无中央清单：`g41.sh k8s apply` 自动遍历 `kits/*/k8s/`；纯 kubectl 等价于 `kubectl apply $(for d in k8s/base kits/*/k8s; do printf -- '-f %s ' "$d"; done)`（shell glob，零编辑） |
| 数据 | hostPath 挂载 `/opt/g41/.rd` 等 → **零数据迁移**，与 compose 共用同一批目录 |
| 证书 | cert-manager（Cloudflare DNS01）替代 acme.sh；轮换后手动 `kubectl rollout restart deploy/{nginx,dns,hy2} -n g41`（每 ~60 天一次） |
| acme/autoheal/dsock | 无 k8s manifest，整体退役（探针/cert-manager 原生替代） |
| 网关 | 保留 nginx（hostPort 80/443），配置仍来自 .gx 装配 |
| hy2 | hostNetwork（443/udp 与 nginx 共存，同现状） |
| 镜像 | hub 模块沿用原镜像；`compose: file` 模块 `docker build` + `k3s ctr images import`（tag `g41k8s/<kit>:local`） |
| 密钥 | `kubectl create secret g41-env --from-env-file=.env`（声明式、幂等、自更新） |
| 健康检查 | compose healthcheck → livenessProbe（同命令） |
| 资源限制 | mem_limit/cpus → resources.limits/requests |

## 使用

```bash
./g41.sh backend k8s              # 切换后端（写入 .env: G41_BACKEND=k8s）
./g41.sh k8s apply --all          # 应用 base + 全部模块 manifest（引导部署）
./g41.sh kits add -y <module>     # 安装模块：装配内容 + 构建镜像 + apply manifest
./g41.sh kits del -y <module>     # 卸载模块：删除 manifest + 移除装配内容
./g41.sh k8s build                # 重建全部 compose=file 模块的镜像
./g41.sh k8s status               # pods/svc/deploy 概览
./g41.sh kits reload              # Redis 热重载（kubectl exec deploy/api）
```

## 前置条件

- **内存 ≥ 2GB**（k3s 控制面 ~300MB + 工作负载；1GB VPS 需先升级）
- k3s 安装建议：`curl -sfL https://get.k3s.io | sh -s - --disable traefik --disable metrics-server --disable servicelb`
  （网关用 nginx、端口用 hostPort，无需 traefik/servicelb）
- `kubectl`（root：`export KUBECONFIG=/etc/rancher/k3s/k3s.yaml`）
- cert-manager / Reloader 由 base/ 中的 HelmChart CR 自动安装（k3s helm-controller）

## 回滚

compose 与 k8s 共用宿主机数据目录，双轨共存。回滚 = `./g41.sh backend compose`
+ `docker compose up -d`（k8s 侧先 `kubectl delete -f` 或直接停 k3s），数据无损。
详见 `docs/zh/k8s-migration.md`。
