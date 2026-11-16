#!/bin/bash
# glm53-autostart.sh -- bring the engine up after a boot, once, without a human.
# A reboot should restore the service on its own: on 2026-11-16 the box needed a power cycle and then someone to
# run start.sh. Serialised by the same lock start.sh uses, and it does nothing if the container is already there.
set -u
REPO=/home/leon/NewModels/GLM-5.3-Flash-DGX-Sparks-1104
for _ in $(seq 1 60); do
  docker ps --filter name=glm53-spark --format '{{.Names}}' 2>/dev/null | grep -q . && { echo "already running"; exit 0; }
  [ -f "$REPO/start.sh" ] && break
  sleep 5
done
cd "$REPO" || exit 1
exec ./start.sh
