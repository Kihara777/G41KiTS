#!/usr/bin/env bash
# G41KiTS — 1GB VPS 主机调优（幂等）
# journald volatile / 停 snapd / fail2ban 白名单 / swappiness / zram / sqlite3
set -e

echo "== journald volatile（磁盘日志会阻塞 k3s 写日志管道，改 RAM）=="
mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nStorage=volatile\n' > /etc/systemd/journald.conf.d/volatile.conf
systemctl restart systemd-journald

echo "== snapd（无 snap 应用，省 CPU/内存）=="
systemctl stop snapd snapd.socket 2>/dev/null || true
systemctl disable snapd snapd.socket 2>/dev/null || true

echo "== fail2ban 白名单本机出口 IP =="
myip=$(curl -s --max-time 10 https://api.ipify.org 2>/dev/null || echo "")
if [ -n "$myip" ]; then
  printf '[DEFAULT]\nignoreip = 127.0.0.1/8 ::1 %s\n' "$myip" > /etc/fail2ban/jail.d/99-g41.local
  systemctl reload fail2ban 2>/dev/null || true
fi

echo "== swappiness（磁盘 swap 吸收负载溢出）=="
sysctl -w vm.swappiness=60
echo "vm.swappiness=60" > /etc/sysctl.d/99-g41.conf

echo "== zram（zram-tools + 附加 240M 设备）+ sqlite3 =="
DEBIAN_FRONTEND=noninteractive apt-get install -yq zram-tools sqlite3
sed -i 's/^#\?PERCENT=.*/PERCENT=50/' /etc/default/zramswap
systemctl enable --now zramswap 2>/dev/null || true
if [ ! -f /etc/systemd/system/zram1-swap.service ]; then
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
  systemctl daemon-reload
  systemctl enable --now zram1-swap 2>/dev/null || true
fi

echo "Done."
