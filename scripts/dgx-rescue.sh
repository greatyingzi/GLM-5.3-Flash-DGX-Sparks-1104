#!/bin/bash
# dgx-rescue.sh -- the only thing spark-01 may run on spark-00.
# Installed as a forced command in ~leon/.ssh/authorized_keys, so $SSH_ORIGINAL_COMMAND carries the request and
# nothing else can be run through that key: no shell, no port forwarding, no agent, no pty.
#
# Why this exists: 2026-11-16 spark-00 wedged twice with the kernel alive and sshd accepting TCP connections but
# unable to fork a session (no banner on LAN, tailscale or the CX7 cable). With no BMC and no PDU, the only way
# back was someone walking to the machine. spark-01 could reach it at 0.06 ms but had no key, so it could not help.
set -u
cmd="${SSH_ORIGINAL_COMMAND:-status}"
case "$cmd" in
  status)
    echo "host:     $(hostname)  ($(uptime -p 2>/dev/null || uptime))"
    echo "memory:   $(awk '/^MemAvailable:/{a=$2}/^MemTotal:/{t=$2}END{printf "%.1f GiB available of %.1f GiB", a/1048576, t/1048576}' /proc/meminfo 2>/dev/null)"
    echo "engine:   $(docker ps --filter name=glm53-spark --format '{{.Status}}' 2>/dev/null | head -1 || echo 'not running')"
    echo "health:   $(curl -s -m 3 -o /dev/null -w '%{http_code}' http://127.0.0.1:1235/health 2>/dev/null)"
    echo "ssh conns: $(ss -tn state established '( sport = :22 )' 2>/dev/null | tail -n +2 | wc -l)"
    ;;
  stop)
    sudo docker rm -f glm53-spark 2>&1 | tail -1 ;;
  start)
    if sudo systemctl start glm53-autostart 2>/dev/null; then echo "autostart unit started"; else
      cd /home/leon/NewModels/GLM-5.3-Flash-DGX-Sparks-1104 && ./start.sh 2>&1 | tail -2
    fi ;;
  reboot)
    echo "rebooting with systemctl reboot -f in 2 s"
    sync; sleep 2; sudo systemctl reboot -f ;;
  hard-reboot)
    echo "hard reboot through sysrq in 2 s"
    sync; sleep 2; echo 1 | sudo tee /proc/sys/kernel/sysrq >/dev/null; echo b | sudo tee /proc/sysrq-trigger ;;
  *)
    echo "unknown request: $cmd"; echo "known: status | stop | start | reboot | hard-reboot"; exit 2 ;;
esac
