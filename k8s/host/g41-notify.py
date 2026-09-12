#!/usr/bin/env python3
"""G41KiTS — 极简 SMTP 通知（无第三方依赖，仅用标准库）

用途：两个 systemd 计划任务（证书分发 / 每周镜像更新）在**有实质动作**时
      发一封邮件；无变化时不发，避免每周噪音。

配置来源（按优先级）：
  1. /opt/g41/.env 中的 G41_SMTP_* 变量
  2. 环境变量

所需变量：
  G41_SMTP_HOST   例 smtp.gmail.com
  G41_SMTP_PORT   例 587（STARTTLS）
  G41_SMTP_USER   登录用户（同时作为发件人）
  G41_SMTP_PASS   密码 / 应用专用密码
  G41_MAIL_TO     收件人（默认取 G41_SMTP_USER）

未配置时静默退出码 0 —— 通知是尽力而为，不应让定时任务失败。

用法：  notify.py "主题" <<'EOF' ...正文... EOF
"""

import os
import smtplib
import ssl
import sys
from email.message import EmailMessage
from pathlib import Path

ENV_FILE = Path("/opt/g41/.env")


def load_env() -> dict:
    """合并 /opt/g41/.env 与进程环境（进程环境优先）。"""
    cfg: dict[str, str] = {}
    if ENV_FILE.is_file():
        for line in ENV_FILE.read_text(errors="replace").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            cfg[key.strip()] = val.strip().strip('"').strip("'")
    for key in ("G41_SMTP_HOST", "G41_SMTP_PORT", "G41_SMTP_USER",
                "G41_SMTP_PASS", "G41_MAIL_TO"):
        if os.environ.get(key):
            cfg[key] = os.environ[key]
    return cfg


def main() -> int:
    subject = sys.argv[1] if len(sys.argv) > 1 else "G41KiTS 通知"
    body = sys.stdin.read()

    cfg = load_env()
    host = cfg.get("G41_SMTP_HOST")
    user = cfg.get("G41_SMTP_USER")
    password = cfg.get("G41_SMTP_PASS")

    if not (host and user and password):
        # 未配置通知渠道：不算失败，只提示一次
        print(f"[notify] SMTP 未配置，跳过通知：{subject}", file=sys.stderr)
        return 0

    port = int(cfg.get("G41_SMTP_PORT") or 587)
    to = cfg.get("G41_MAIL_TO") or user

    msg = EmailMessage()
    msg["From"] = user
    msg["To"] = to
    msg["Subject"] = subject
    msg.set_content(body)

    try:
        if port == 465:
            ctx = ssl.create_default_context()
            with smtplib.SMTP_SSL(host, port, timeout=30, context=ctx) as s:
                s.login(user, password)
                s.send_message(msg)
        else:
            with smtplib.SMTP(host, port, timeout=30) as s:
                s.ehlo()
                s.starttls(context=ssl.create_default_context())
                s.ehlo()
                s.login(user, password)
                s.send_message(msg)
    except Exception as exc:  # noqa: BLE001 — 通知失败不应中断主任务
        print(f"[notify] 发送失败：{exc}", file=sys.stderr)
        return 0

    print(f"[notify] 已发送：{subject} -> {to}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
