# k3s 设施评估：资源优化空间 与 全量迁移到 k3s 体系

评估对象：G41KiTS 在自托管 VPS（`homete`）上的 k3s 部署。
结论先行：**资源优化有明确空间（约可省 200–300MB 常驻内存 + ~3GB 磁盘）；
但「全部运维操作迁移到 k3s」在架构上是错误方向** —— 只有一部分该迁。

---

## 一、现状基线（实测，非估算）

主机：1.6GB RAM / 2GB swap + 1.4GB zram，99GB 磁盘（用 32GB）。

### 内存占用

| 组成部分 | 实测 | 占比 |
|---|---|---|
| **k3s 控制面**（k3s server + containerd） | **457 MB** | 最大单项 |
| redis Pod（redis + api + tracker） | 121 MB | |
| blc Pod | 73 MB | |
| hako Pod | 42 MB | |
| hy2 Pod | 39 MB | |
| nginx Pod | 19 MB | |
| dns Pod | 17 MB | |
| download Pod | 16 MB | |
| **业务 Pod 合计** | **327 MB** | |
| cert-manager（controller+cainjector+webhook） | ~64 MB | 3 个 Pod |
| coredns | 24 MB | |
| 宿主级（ntpd/fail2ban/init/sshd 等） | ~90 MB | |

`free -m`：used 1049MB / available 591MB。swap 已用 398MB、zram 用 481MB
—— **已在用交换，说明内存偏紧**，这是最重要的信号。

### 磁盘

| 项 | 实测 |
|---|---|
| containerd 镜像库 | 8.6 GB |
| （其中 overlayfs 快照层） | 5.7 GB |
| tmpfs kine 状态库 | 17 MB |

镜像库中有** 78 个引用**，含大量历史层与已移除模块的镜像。

---

## 二、资源优化空间（按收益排序）

### A. 清理镜像库 —— 省 ~750MB 显式 + 更多历史层（零风险，建议立即做）

已确认**未被任何 Pod 引用**的镜像（逐个核对过 `status.containerStatuses[].imageID`）：

| 镜像 | 大小 | 为何可删 |
|---|---|---|
| `g41k8s/tracker:local` | 440.2 MB | tracker 已并入 api 进程，无 Deployment 引用 |
| `rancher/local-path-provisioner` | 85.2 MB | k3s 已 `--disable local-storage`，无 PVC |
| `ghcr.io/zhaofengli/attic:latest` | 82.9 MB | attic 模块已移除 |
| `g41k8s/hexo:local` | 78.7 MB | hexo 模块已移除 |
| `g41k8s/acme:local` | 35.6 MB | acme 在 k8s 下退役（cert-manager 替代） |
| `ghcr.io/stakater/reloader` | 14.6 MB | **本部署并未安装该控制器**（nginx 用自带 sidecar） |
| `cert-manager-startupapicheck` | 13.7 MB | 仅 helm 安装时用一次 |
| **显式合计** | **~751 MB** | |

另有**同名多 digest 堆积**（浮动 tag 拉新后旧层未回收）：

| repo | 现存 digest 数 |
|---|---|
| `library/redis` | 5 |
| `library/nginx` | 3 |
| `adguard/dnsproxy` | 2 |

这些历史层由 `k3s ctr images prune` 回收，实际节省取决于层共享度 ——
镜像库总量 8.6GB，`prune` 通常可回收其中相当一部分。

> ⚠️ **注意**：`prune` 会同时删掉上述 tag 指向的「当前版本」引用（如
> `dnsproxy:latest`、`nginx:alpine`），下次调度时会重新拉取。这在带宽充裕时
> 无碍，但若想稳妥，应先做 `--dry-run` 或逐个 `k3s ctr images rm`。

对策：把选定镜像的删除加入 `g41-image-update.timer` 的收尾步骤（每周自动回收）。

> 附带收益：镜像层减少后，containerd 的元数据内存也随之下降。

### B. 精简 cert-manager —— 省 ~40MB（中等收益，需评估）

当前跑 3 个 Pod（controller / cainjector / webhook）共 ~64MB。

- `cainjector`（21MB）：只负责把 CA 注入 webhook 配置，**每 19 天用一次**。
  可缩容至 0，仅在需要时临时拉起。
- `webhook`（13MB）：校验 Certificate/Issuer 的合法性。若签发流程已稳定，
  可用 `--enable-certificate-owner-ref` 之外的简化路径，或接受其存在。
- **更根本的选择**：单一域名 + 稳定续期需求，其实可以用更轻的方案
  （如宿主级 acme.sh 只签一次 + 手动投放 Secret），省掉整个 cert-manager 栈
  （~64MB + 3 个 Pod 的调度开销）。但会失去自动续期 —— 与现有
  `g41-cert-reload.timer` 的分工需要重新设计。

**权衡**：证书自动化带来的价值 > 64MB，建议**保留 controller**，
考虑把 cainjector 缩容（省钱有限但无风险）。

### C. tmpfs-kine 的内存代价（**不要动**）

kine 状态库放 `/dev/shm`（17MB 实际、tmpfs 上限 817MB）。
这是 1GB 稳定性的**根基**（journald/磁盘 IO 阻塞会导致 apiserver 卡死），
虽然占用物理内存，但换来的是控制面不被磁盘 IO 拖死。**属正确设计，保持**。

### D. swappiness=60 偏高（可调，低风险）

当前 `vm.swappiness=60`，实测已换出 398MB。在统一内存/zram 场景下，
偏高会让不活跃页过早进 swap，而 k3s 这种延迟敏感服务被换出后响应变差。
可降至 10–20，让内核更倾向保留匿名页、优先丢弃 page cache。

### E. 单副本架构本身已是最优

7 个业务 Pod 均为单副本、无 HPA、无 PDB、无 Service Mesh。
控制面唯一的「浪费」是 **k3s 内置组件无法按需关闭**：
coredns（24MB）虽只用集群内 DNS，但 nginx upstream 依赖它 —— 不可去。
`local-path-provisioner` 已禁用（无 PVC）。**此项无优化空间。**

### F. 换 k3s 发行版？（结论：不建议，收益不明确）

若要极致省内存，可考虑 k0s / microk8s / 纯 kubelet+静态 Pod，
但会失去 k3s 的单二进制自包含优势，且迁移风险 > 收益（预期仅省 50–100MB）。

### 优化收益汇总

| 项 | 收益 | 风险 | 建议 |
|---|---|---|---|
| A. 清理镜像 | ~750MB 显式 + prune 更多 | 无 | **立即做** |
| B. cert-manager 精简 | ~20–40MB | 低 | 评估后做 |
| C. tmpfs-kine | （反向） | — | **保持** |
| D. swappiness 调低 | 间接改善延迟 | 低 | 可做 |
| F. 换发行版 | ~50–100MB | 高 | **不做** |

**预期合计**：约 750MB–2GB 磁盘 + 20–40MB 常驻内存，外加延迟稳定性改善。

---

## 三、能否把全部部署与维护操作迁移到 k3s？

### 短答：不能全迁；但**可以也应该迁掉一大半**。

你设想的终局（sh 只做 k3s 引导，模块的安装/卸载全在 k3s 内）方向和
Kubernetes 的惯用法一致。但它撞上一个硬约束：

### 硬约束：内容装配依赖宿主机文件系统

`g41.sh kits add` 的本质不是「部署容器」，而是**在宿主机上装配内容并建立硬链接**：

```
kits/<m>/tile.json   --ln-->  .rd/data/tiles/<m>.json
kits/<m>/i18n/*.json --ln-->  .rd/data/i18n/<m>/*.json
kits/<m>/site/*.conf --ln-->  .gx/conf.d/{zones,upstreams,servers,locations}/
kits/<m>/webroot/*   --ln-->  .wr/
```

`ln -f` 硬链接意味着**同一 inode 被两个路径共享**，这是本项目的核心设计
（AGENTS.md「硬链接，非符号链接」）。而容器要读这些文件，靠的是
`hostPath` 挂载 `/opt/g41/...`。

**这带来三个结构性事实**：

1. **Pod 无法自己完成装配**。Pod 里的进程看不到 `kits/`（只有被挂载的子目录），
   也不应该去改宿主机文件系统 —— 那等于给容器 host 写权限，是安全倒退。
2. **硬链接无法用 k8s 原生资源表达**。ConfigMap 是文件复制而非链接；
   CSI/Projected volume 也不产出 inode 共享。改成 ConfigMap 会让
   「改源码即生效」的零拷贝特性消失，且 configMap 有 1MB 上限（`.wr` 与
   镜像层远不止）。
3. **k8s 的声明式模型假设「期望状态可从集群内推导」**，而这里期望状态的
   真源是**仓库源码 + 宿主机装配结果**，集群内看不见。

所以「模块安装」这件事，**其装配半部分天然属于宿主机**。

### 但真正的机会在于：`g41.sh` 里混了三类职责

| 职责 | 例子 | 能否迁到 k3s |
|---|---|---|
| **① 宿主机装配** | 硬链接 tile/i18n/site、`.local` 注入 | ❌ 必须在宿主 |
| **② 集群资源编排** | `k8s apply`、ConfigMap 渲染、rollout | ✅ 应迁（Operator/CRD） |
| **③ 运维自动化** | 证书分发、镜像更新、健康检查 | ✅ 已有 timer，可再迁 |

现在 ①②③ 全塞在 1342 行的 `g41.sh` 里。**可行的迁移是让 ②③ 进集群，
① 保留为极薄的宿主层。**

### 具体迁移路线（按性价比排序）

#### 第 1 步：把「模块」变成 CRD（收益最大，也是你设想的核心）

定义一个 `Kit` CRD：

```yaml
apiVersion: g41.moe/v1
kind: Kit
metadata: { name: hy2 }
spec:
  source: { ref: "kits/hy2" }     # 宿主机路径（hostPath 可见）
  compose: hub
  depends: [nginx]
status:
  phase: Ready
  assembledHash: "sha256:..."     # 装配内容指纹
```

配一个 **`kit-operator`**（可直接用现有 Go/Rust 或 Python 写，跑在集群里），
它 reconcile：

- 读 `spec.source` 下的 `info.json` / `k8s/*.yaml`
- `kubectl apply` 该模块的 Deployment/Service（**② 迁进来了**）
- 渲染 nginx ConfigMap（把 `k8s_nginx_conf_apply` 变成 controller 逻辑）
- 维护 `depends` 的拓扑顺序与 finalizer（卸载时先删资源再清理装配）

**收益**：`k8s apply` / `k8s conf` / 依赖排序 / 卸载级联全部成为集群内声明式逻辑，
`g41.sh` 相应函数可直接删除。

**代价（关键）**：它仍需一个**宿主侧 agent** 来执行 ① 的硬链接装配。
两种设计：

- **(a) 特权 DaemonSet**：挂载宿主 `/opt/g41`，operator 通过它下发装配指令。
  代价是容器获得 host 写权限（安全考量），但**只限 `/opt/g41` 子树**，
  比现在 ssh + bash 的权限面更小、更可审计。
- **(b) 保持 sh 装配 + CRD 编排**：装配仍由 `./g41.sh kits add` 的极薄版完成，
  装完创建 `Kit` CR；operator 只负责集群侧。
  **推荐 (b)** —— 符合你「sh 只做必要设施」的意图，且不引入特权容器。

#### 第 2 步：把运维定时任务迁进集群

现有 `g41-cert-reload` / `g41-image-update` 是宿主机 systemd timer —— 但它们的
工作内容（调 kubectl、比对 digest、rollout）**完全在集群语义内**。
可改为 **CronJob**：

| 现在 | 迁移后 |
|---|---|
| `g41-cert-reload.timer` | CronJob `cert-reload`（每 15 分钟）+ ServiceAccount RBAC |
| `g41-image-update.timer` | CronJob `image-update`（每周日） |
| `g41-image-build.sh` | 保留在宿主（需要 containerd socket + 构建缓存） |

**收益**：不再需要宿主 kubectl、不再需要 `/var/lib/g41` 状态目录、
日志统一进 `kubectl logs`、权限收窄到 RBAC ServiceAccount。
**代价**：CronJob 需要集群可用才能跑（宿主 timer 在 apiserver 挂掉时仍能执行诊断）——
**建议保留一个宿主侧「看门狗」**，用于监控集群本身。

#### 第 3 步：健康检查与自愈

现在靠 Pod livenessProbe（已足够）。可补：
- 用 `Prometheus Operator` 太重；建议轻量方案：CronJob 定期探测各端点，
  异常时写 Event（`kubectl get events` 可见）或触发通知。

### 迁移后 `g41.sh` 的残留（应当保留的部分）

```
./g41.sh init k8s        # 装 k3s + tmpfs-kine + 主机调优 + Apply base
./g41.sh kits assemble   # ① 宿主装配（硬链接）+ 创建/更新 Kit CR
./g41.sh k8s build       # 本地镜像构建（需 containerd + buildkit socket）
./g41.sh kits pack       # 归档（纯宿主文件操作）
./g41.sh kits verify     # L1–L4 校验（读 info.json + 检查装配结果）
```

预计 `g41.sh` 可从 1342 行降到 ~400 行。**这符合你的目标。**

### 不建议迁移的部分

- ❌ **装配硬链接**（结构上属于宿主，见上文硬约束）
- ❌ **镜像构建**（需 containerd/buildkit socket 与宿主内核/GPU 能力）
- ❌ **主机调优**（journald/zram/swappiness 是宿主机范畴）
- ❌ **k3s 自身引导**（这正是你要求 sh 保留的）

---

## 四、结论与建议顺序

### 资源优化

1. **立即**：清理镜像库（~3GB，零风险）
2. **本周**：`vm.swappiness` 60 → 10–20
3. **评估后**：cert-manager cainjector 缩容（~20MB）

### 架构迁移

你的方向正确，但要**把「模块管理」拆成装配与编排两半**：

| 阶段 | 内容 | 预期 |
|---|---|---|
| P1 | 定义 `Kit` CRD + operator，接收现有 `k8s apply/conf` 逻辑 | `g41.sh` 减 ~300 行 |
| P2 | `cert-reload`/`image-update` 改 CronJob + RBAC | 再减 ~200 行 |
| P3 | 保留宿主看门狗 + 极薄装配层 | 终态 ~400 行 |

**终态**：`sh` 负责 ① 引导 k3s、② 宿主内容装配、③ 本地镜像构建；
**其余（模块编排、卸载级联、证书分发、镜像巡检、健康巡检）全部在集群内声明式完成。**

这既是 k8s 的惯用法，也保住了本项目「硬链接 + hostPath + 源码即真源」的既有优势
——不必为了「全 k8s 化」而牺牲零拷贝装配。

### 需要你决策的两点

1. **是否引入特权 DaemonSet 做装配**？我建议**不**（保持 (b) 方案），
   用最小权限换掉「一切进集群」的纯粹性。
2. **cert-manager 保留与否**？我建议保留 controller、缩容 cainjector。
   若要极致省内存可整体替换为宿主 acme.sh，但会失去自动续期。
