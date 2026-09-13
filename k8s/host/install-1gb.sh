#!/usr/bin/env bash
# G41KiTS — 1GB VPS k3s 安装/配置（tmpfs kine 方案）
# 幂等；不启动 k3s（cutover 由迁移 runbook 控制）。
set -e -o pipefail

HOST_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "== 1. sqlite3（在线备份用）=="
command -v sqlite3 >/dev/null || DEBIAN_FRONTEND=noninteractive apt-get install -yq sqlite3

echo "== 2. k3s config.yaml（tmpfs kine + 精简组件）=="
mkdir -p /etc/rancher/k3s
cp -a "$HOST_DIR/k3s-config-1gb.yaml" /etc/rancher/k3s/config.yaml

echo "== 3. 安装 k3s-standalone 单元并停用有问题的 k3s.service =="
cp -a "$HOST_DIR/k3s-standalone.service" /etc/systemd/system/
systemctl disable k3s.service 2>/dev/null || true

echo "== 4. 状态准备/备份单元 =="
cp -a "$HOST_DIR/k3s-state-prep.service" /etc/systemd/system/
cp -a "$HOST_DIR/k3s-state-backup.service" /etc/systemd/system/
cp -a "$HOST_DIR/k3s-state-backup.timer" /etc/systemd/system/
mkdir -p /etc/systemd/system/k3s.service.d
cp -a "$HOST_DIR/k3s.service.d-backup.conf" /etc/systemd/system/k3s.service.d/backup.conf

echo "== 4b. 运维定时任务（证书轮换分发 / 每周镜像更新）=="
# 脚本运行在 /opt/g41/k8s/host/（单元内硬编码路径）
install -d -m 755 /opt/g41/k8s/host
install -m 755 "$HOST_DIR/g41-cert-reload.sh"  /opt/g41/k8s/host/
install -m 755 "$HOST_DIR/g41-image-update.sh" /opt/g41/k8s/host/
install -m 755 "$HOST_DIR/g41-image-build.sh"  /opt/g41/k8s/host/
install -m 755 "$HOST_DIR/g41-notify.py"       /opt/g41/k8s/host/
cp -a "$HOST_DIR/g41-cert-reload.service" "$HOST_DIR/g41-cert-reload.timer" /etc/systemd/system/
cp -a "$HOST_DIR/g41-image-update.service" "$HOST_DIR/g41-image-update.timer" /etc/systemd/system/
install -d -m 755 /var/lib/g41

echo "== 4c. containerd 原生镜像构建（nerdctl + BuildKit，无需 dockerd）=="
# k8s 模式下 dockerd 停用，本地 :local 镜像改由 BuildKit 的 containerd worker
# 直接构建进 k3s 的 k8s.io namespace / overlayfs snapshotter。
# 二进制需预先放置（体积大，不随仓库分发）：
#   /usr/local/bin/nerdctl     https://github.com/containerd/nerdctl/releases
#   /usr/local/bin/buildkitd   https://github.com/moby/buildkit/releases
#   /usr/local/bin/buildctl
if [ -x /usr/local/bin/nerdctl ] && [ -x /usr/local/bin/buildkitd ]; then
  install -d -m 755 /run/buildkit /var/lib/buildkit
  cp -a "$HOST_DIR/buildkitd.service" /etc/systemd/system/
  systemctl enable --now buildkitd.service
else
  echo "NOTE: 未找到 nerdctl/buildkitd，跳过 BuildKit 安装"
  echo "      下载后重跑本步骤即可启用本地镜像构建："
  echo "        nerdctl   https://github.com/containerd/nerdctl/releases"
  echo "        buildkitd https://github.com/moby/buildkit/releases"
fi

systemctl daemon-reload
systemctl enable k3s-state-prep.service k3s-state-backup.timer k3s-standalone.service
systemctl enable --now g41-cert-reload.timer g41-image-update.timer

echo "== 5. 校验 =="
systemd-analyze verify k3s-state-prep.service k3s-state-backup.service k3s-state-backup.timer k3s-standalone.service 2>&1 | head -3 || true
systemd-analyze verify g41-cert-reload.service g41-cert-reload.timer g41-image-update.service g41-image-update.timer 2>&1 | head -3 || true
systemd-analyze verify buildkitd.service 2>&1 | head -3 || true
grep datastore-endpoint /etc/rancher/k3s/config.yaml
echo "Done. k3s 未启动——cutover 时：systemctl enable --now k3s-standalone"
