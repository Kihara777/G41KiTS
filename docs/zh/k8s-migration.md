# G41KiTS → k3s 迁移手册

Docker Compose 架构向 k3s 的迁移 runbook。**双轨共存、数据零迁移、可随时回滚**。

## 0. 前置条件（必须先做）

- **内存 ≥ 2GB**。1GB VPS 实测可跑（见下方"1GB 实战配置"），但长期仍建议升级。
- 仓库已同步至最新（含 `k8s/`、`kits/*/k8s/`、新 `g41.sh`）。
- 建议先做一次全量备份：`./g41.sh kits pack -SAL`

## 0.1 1GB VPS 实战配置（本次迁移所用）

在 958MB VPS 上让 k3s 稳定运行的三件套：

1. **只用 zram，不用磁盘 swap**（磁盘 swap 的 I/O 会饿死 kine/sqlite，
   表现为 apiserver TLS 握手超时、k3s 日志出现 "Slow SQL" 数秒）：
   ```bash
   apt-get install -y zram-tools
   sed -i 's/^#\?PERCENT=.*/PERCENT=75/' /etc/default/zramswap
   systemctl enable --now zramswap
   # 追加第二块 zram（zramswap 实际产出约 50%）
   cat > /etc/systemd/system/zram1-swap.service <<'EOF'
[Unit]
Description=Extra zram swap device (240M)
After=zramswap.service
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c "[ -e /dev/zram1 ] || zramctl -f -s 240M; mkswap /dev/zram1 >/dev/null; swapon -p 90 /dev/zram1"
ExecStop=/bin/sh -c "swapoff /dev/zram1 2>/dev/null; [ -e /dev/zram1 ] && zramctl -r /dev/zram1"
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable zram1-swap
   sysctl -w vm.swappiness=10
   echo "vm.swappiness=10" > /etc/sysctl.d/99-g41.conf
   sed -i 's|^/var/spool/swap/swapfile|#/var/spool/swap/swapfile|' /etc/fstab
   swapoff /var/spool/swap/swapfile   # 立即卸载（页面转入 zram）
   ```
2. **kine/sqlite 降低同步强度**（`/etc/rancher/k3s/config.yaml`）：
   ```yaml
   datastore-endpoint: "sqlite:///var/lib/rancher/k3s/server/db/state.db?_pragma_busy_timeout(5000)&_pragma_journal_mode(WAL)&_pragma_synchronous(NORMAL)&_pragma_cache_size(2000)"
   ```
3. **fail2ban 白名单**（迁移期大量 SSH 会话会触发误封，导致连接被掐断）：
   ```bash
   printf "[DEFAULT]\nignoreip = 127.0.0.1/8 ::1 <你的出口IP>\n" > /etc/fail2ban/jail.d/99-g41.local
   systemctl reload fail2ban
   ```

## 1. 安装 k3s

```bash
# 精简组件：网关用 nginx、端口用 hostPort，无需 traefik/servicelb/metrics-server
curl -sfL https://get.k3s.io | sh -s - \
  --disable traefik --disable metrics-server --disable servicelb

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml   # 建议写入 /root/.bashrc
kubectl get nodes                              # Ready 后继续
```

## 2. 切换后端并引导

```bash
cd ~/G41KiTS
./g41.sh backend k8s                          # .env 写入 G41_BACKEND=k8s

# 引导部署：装配内容 + 构建本地镜像(docker build → k3s ctr import)
# + 应用 base(cert-manager/reloader) + 逐模块 manifest
./g41.sh kits add -C -y all
```

该步骤会：
- 把全部模块（含此前遗漏记账的 attic）写入 G41_KITS；
- 生成 Secret `g41-env`（.env 全量）与 ClusterIssuer/Certificate（Let's Encrypt + Cloudflare DNS01）；
- 通过 k3s helm-controller 安装 cert-manager 与 Reloader；
- 内容装配仍硬链接进 `.rd/.wr/.gx` 等宿主目录（与 compose 共用）。

**注意**：此时 compose 容器仍在运行，k8s 侧绑定 80/443/53/853/51413 的 Pod 会因端口冲突失败——属预期。

## 3. 证书就绪（替代 acme 模块）

```bash
kubectl get certificate -n g41 g41-tls -w    # 等待 READY=True（DNS01 签发约 1–2 分钟）
kubectl get secret -n g41 g41-tls            # 存在即就绪
```

## 4. 切换（cutover）

```bash
# 1. 停掉全部 compose 容器（保留容器与数据，用于回滚；docker 守护进程继续用于构建）
docker compose stop

# 2. 重新应用，让端口冲突的 Pod 正常起来
./g41.sh k8s apply --all

# 3. 观察
./g41.sh k8s status
kubectl get pods -n g41 -w                     # 全部 Running/Ready
curl -sk https://g41.moe/ | head               # 验证站点
./g41.sh kits reload                           # Redis 热重载验证
```

nginx 在 g41-tls Secret 出现前会处于 CreateContainerConfigError（kubelet 自动重试），
证书签发后自行恢复；hy2/dns 同理。

## 5. 观察期与回滚

- **观察 1–2 周**，compose 容器保持 stopped。
- **回滚**（数据无损，双轨共用同一批宿主目录）：

```bash
./g41.sh backend compose
kubectl delete namespace g41        # 或逐模块 kubectl delete -f kits/*/k8s/
docker compose start                # 原 compose 栈直接复活
```

## 6. 收尾（稳定后）

```bash
docker compose down                 # 清理 compose 网络/容器（数据目录不动）
# 可选：卸载 acme/autoheal/dsock 模块（k8s 下无对应物，但保留无碍）
```

## 日常操作速查

| 操作 | 命令 |
|---|---|
| 安装模块 | `./g41.sh kits add -y <m>`（装配 + 构建 + apply 一条龙） |
| 卸载模块 | `./g41.sh kits del -y <m>` |
| 全量重放 | `./g41.sh k8s apply --all` |
| 重建本地镜像 | `./g41.sh k8s build` |
| 数据热重载 | `./g41.sh kits reload` |
| 日志 | `kubectl logs -n g41 deploy/<name> -f` |
| 证书轮换 | 全自动（cert-manager 续期 → Reloader 滚动重启 nginx/dns/hy2） |

## 架构对照

| compose | k8s | 说明 |
|---|---|---|
| include 列表 + sed 编辑 | `kits/*/k8s/*.yaml` glob 自动纳入 | **痛点消除**：安装=放文件，`./g41.sh k8s apply`（或 `kubectl apply -f k8s/base -f kits/*/k8s`） |
| 服务网络 | 集群 DNS（Service 名） | Service 名对齐 nginx upstream：`aria2/attic/blc/bt/dns/hako/ra/tracker`；**`hx` 例外**（upstream 引用容器名缩写，Service 特意命名为 hx） |
| bind 挂载（相对路径） | hostPath `/opt/g41/...`（g41.sh 维护稳定符号链接） | 零数据迁移 |
| acme.sh + 标签钩子 | cert-manager DNS01 + Reloader | acme 模块退役 |
| autoheal / dsock | 原生探针自愈 / 无 docker.sock | 两模块退役 |
| depends_on | 无（探针 + 重启回退） | 行为等价：上游未就绪时 Pod 重启直到就绪 |
| healthcheck | livenessProbe（同命令） | — |
| mem_limit / cpus | resources.limits/requests | 原值平移 |
| `compose: file` 模块 | `docker build` + `k3s ctr images import`（tag `g41k8s/<kit>:local`） | g41.sh k8s build 自动完成 |
| `.env` 变量 | Secret `g41-env`（`kubectl create secret --from-env-file=.env` 幂等自更新） | 密钥不进 git |
| 端口 80/443、53/853、51413 | hostPort | hy2 保持 hostNetwork |

## 已知取舍

1. **证书签发从 ZeroSSL 换为 Let's Encrypt**（cert-manager 默认）。如需 ZeroSSL 可后续配置 issuer server URL。
2. **attic 原 127.0.0.1:8188 宿主映射不再需要**（集群内直连 8080）。
3. **证书轮换**：nginx 由 Pod 内 reloader sidecar 检测 `/certs` 变化自动 `nginx -s reload`（无缝）；dns/hy2 无热重载，需 `kubectl rollout restart deploy/{dns,hy2} -n g41`（约每 60 天一次）。
4. **G41_EXTRA_DOMAINS 暂缓**：多个附加域名共用 `_acme-challenge.g41.moe` 委托目标时，cert-manager 并发签发的清理竞态会导致部分 challenge 失败。需在各自 DNS 把 CNAME 改为**独立目标**（如 `_acme-challenge.maidkihara.g41.moe`）后恢复 `G41_EXTRA_DOMAINS` 并 `./g41.sh k8s base` 重新签发。旧 acme.sh 证书到期前（.ca 目录）仍可回退使用。
5. **cron 清理**：迁移验证完成后移除旧栈周任务 `0 0 * * 7 docker compose build`（`crontab -e`）。
6. **镜像构建**：`g41.sh k8s build` 已启用 BuildKit（`DOCKER_BUILDKIT=1`，Dockerfile 使用 heredoc COPY）；构建期间 docker 守护进程按需启停（`systemctl start docker` / `stop`），常态保持停止以省内存。
