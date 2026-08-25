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

echo "== 3. ExecStart 精简为纯 server（全部参数由 config.yaml 驱动）=="
# k3s 安装器生成多行续行格式（每 flag 一行），整块替换为单行
awk '
  /^ExecStart=/ { print "ExecStart=/usr/local/bin/k3s server"; skip=1; next }
  skip && /^[[:space:]]/ { next }
  skip && /^$/ { next }
  { skip=0; print }
' /etc/systemd/system/k3s.service > /tmp/k3s.service.new && mv /tmp/k3s.service.new /etc/systemd/system/k3s.service
grep -n "^ExecStart=" /etc/systemd/system/k3s.service

echo "== 4. 状态准备/备份单元 =="
cp -a "$HOST_DIR/k3s-state-prep.service" /etc/systemd/system/
cp -a "$HOST_DIR/k3s-state-backup.service" /etc/systemd/system/
cp -a "$HOST_DIR/k3s-state-backup.timer" /etc/systemd/system/
mkdir -p /etc/systemd/system/k3s.service.d
cp -a "$HOST_DIR/k3s.service.d-backup.conf" /etc/systemd/system/k3s.service.d/backup.conf

systemctl daemon-reload
systemctl enable k3s-state-prep.service k3s-state-backup.timer

echo "== 5. 校验 =="
systemd-analyze verify k3s-state-prep.service k3s-state-backup.service k3s-state-backup.timer 2>&1 | head -3 || true
grep datastore-endpoint /etc/rancher/k3s/config.yaml
echo "Done. k3s 未启动——cutover 时：systemctl enable --now k3s"
