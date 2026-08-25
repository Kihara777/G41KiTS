# 1GB 内存下稳定运行 k3s 的方案（研究结论）

> 实测平台：Conoha 958MB（2 vCPU）+ Ubuntu 25.10 + k3s v1.36.3。
> 结论：**可行且已实测验证**——8 Pod 拓扑在 958MB 上运行稳定（站点 200、探针全绿），
> 但存在一条必须遵守的**运行纪律**（cert-manager 常态缩 0），违反即触发内存墙。

## 一、核心矛盾与破解

**矛盾**：k3s 控制面（~350MB）+ 8 个业务 Pod（~600MB）+ 内核（~200MB）≈ 1.15GB > 958MB。

**破解思路不是"再省 100MB"，而是三点**：
1. 把工作集压到 RAM 附近（8-Pod 整合，-350MB）；
2. 让控制面状态存储离开慢盘（tmpfs kine），让负载溢出走 swap 而**不影响 apiserver**；
3. 消除一切"隐性杀手"（journald 冻结、systemd 单元、churn）。

## 二、实测内存预算

| 组成 | 估算 |
|---|---|
| k3s（含嵌入式 containerd/coredns） | ~350MB |
| 8 业务 Pod（nginx/redis+api+tracker/download/dns/hy2/hako/blc/attic） | ~450-550MB |
| 内核 + page cache | ~200MB |
| **合计** | **~1.0-1.1GB** |
| 供给 | RAM 958MB + zram ~720MB（压缩 ≈ 1.2GB 有效）+ 磁盘 swap 2GB 兜底 |

关键：**kine（sqlite）在 tmpfs**，负载页面换出换入不阻塞 apiserver——这是 1GB 能稳定的根基。

## 三、完整配方（均已脚本化于 k8s/host/）

1. **8-Pod 整合**（12→8）：hexo 静态化（Job 按需构建）、tracker 并入 api 进程、api 并入 redis Pod、aria2+bt 合 Pod。
2. **tmpfs kine**：`datastore-endpoint: sqlite:///dev/shm/k3s-db/state.db?...` + `k3s-state-backup.timer`（30min）+ `k3s-state-prep.service`（开机恢复）。
3. **k3s-standalone 单元**：`StandardOutput=file:` 解耦 journald、`MemoryMin=400M`、`OOMScoreAdjust=-900`、`Restart=always`。禁用出厂 `k3s.service`（其 watchdog+冻结组合导致每 2-4 分钟退出）。
4. **主机调优**：`journald volatile`（磁盘日志会阻塞 k3s 管道，是"进程活着 apiserver 卡死"的元凶）、zram 720MB、`swappiness=60`、停 snapd、fail2ban 白名单、`disable: [traefik,metrics-server,servicelb,local-storage]`。
5. **资源请求调低**：requests 合计必须 < 节点 allocatable（否则调度死锁）。
6. **cert-manager 常态缩 0**（见纪律），每月 1 日 2 小时窗口续期。

## 四、关键根因（均已修复，勿回退）

| 症状 | 根因 | 修复 |
|---|---|---|
| 进程活着、apiserver 反复卡死 | **journald 磁盘日志阻塞 k3s 写管道** | journald volatile + k3s 文件日志 |
| k3s 每 2-4 分钟"干净退出" | k3s.service 单元（watchdog+冻结） | k3s-standalone 替换 |
| Slow SQL 数秒（tmpfs 上） | 进程冻结期间的时间流逝 | 同上 |
| Pod 全 Pending | requests 超卖 | requests 调低 |
| 滚动更新死锁 | 旧 Pod 占 hostPort/requests | 删旧 Pod 解 |
| bittorrent-tracker require 失败 | 包为 ESM-only | 动态 `import()` |
| api 连不上 redis | server.js 硬编码 `rd` | `REDIS_HOST` 环境变量 |

## 五、运行纪律（1GB 下必须遵守）

1. **cert-manager 常态缩 0**——它是唯一会周期性把内存推到墙上的组件。签发/续期时临时 `kubectl scale --replicas=1`，完成后**立即缩回 0**。任何"临时拉起后忘缩"都会在下次重启/Pod 风暴时复现内存墙。
2. **镜像构建用 docker 短窗**：`systemctl start docker → build → save -o /tmp/x.tar → systemctl stop docker → k3s ctr images import`，docker 与 k3s **不同时在线**。
3. **部署用 `k8s stage`**（全缩 0 → 依赖顺序逐个拉起），不要 `apply --all` 直接放全部 Pod 启动风暴。
4. 重启后 5 分钟内是 k3s 启动 + Pod 恢复的脆弱期，勿叠加操作。

## 六、何时应升级内存

1GB 方案**能跑，但贴墙**：每次重启/风暴/临时组件都需人工干预，运维成本高。以下情况建议 ≥2GB：
- 需要 cert-manager 常驻（自动续期）、或频繁发布、或同时跑多个临时 Job；
- 不再想维护"窗口+缩 0"这类纪律。

生产环境最终采用 2GB；1GB 配方保留为**低配部署/边缘场景的备选方案**（脚本即 `k8s/host/install-1gb.sh` + `host-tune.sh`，入口 `./g41.sh init k8s`）。
