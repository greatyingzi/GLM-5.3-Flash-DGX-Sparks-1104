#!/bin/bash
# glm53-autostart.sh -- bring the engine up after a boot, once, without a human.
# A reboot should restore the service on its own: on 2026-11-16 the box needed a power cycle and then someone to
# run start.sh. Serialised by the same lock start.sh uses, and it does nothing if the container is already there.
# Everything it says goes to $HOME/glm53-autostart.log, because a boot-time failure has no console to print on.
set -u
REPO=/home/leon/NewModels/GLM-5.3-Flash-DGX-Sparks-1104
LOG=${HOME:-/home/leon}/glm53-autostart.log
say() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$LOG"; }

for _ in $(seq 1 60); do
  if docker ps --filter name=glm53-spark --format '{{.Names}}' 2>/dev/null | grep -q .; then
    say "engine already running, nothing to do"; exit 0
  fi
  [ -f "$REPO/start.sh" ] && break
  sleep 5
done

# A build needs the local mirrors (JPEG/WEBP/XGRAMMAR). After a reboot they may not be up, so do not try: the
# current image is tagged by patch hash and start.sh reuses it. Failing here is visible in the log instead.
cd "$REPO" || { say "no repo at $REPO"; exit 1; }
say "starting the engine"
./start.sh >>"$LOG" 2>&1
rc=$?
say "start.sh exit=$rc"
exit $rc
