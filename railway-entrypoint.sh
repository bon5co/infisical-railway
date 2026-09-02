#!/bin/sh
set -e

log() { echo "[railway] $*"; }

# ---------------------------------------------------------------- credentials
if [ -z "${INFISICAL_ADMIN_EMAIL:-}" ] || [ -z "${INFISICAL_ADMIN_PASSWORD:-}" ]; then
  echo "[railway] FATAL: INFISICAL_ADMIN_EMAIL and INFISICAL_ADMIN_PASSWORD must both be set." >&2
  echo "[railway] Without them the instance boots unclaimed and the unauthenticated" >&2
  echo "[railway] /api/v1/admin/bootstrap route hands it to whoever calls it first." >&2
  exit 1
fi

# ------------------------------------------------------------------ heap size
# The upstream image bakes NODE_OPTIONS=--max-old-space-size=1024, so the heap
# ceiling is 1 GB no matter how much memory the deploy actually has.
cgroup_mem=""
if [ -r /sys/fs/cgroup/memory.max ]; then
  cgroup_mem=$(cat /sys/fs/cgroup/memory.max)
elif [ -r /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
  cgroup_mem=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
fi
case "$cgroup_mem" in
  ''|max|*[!0-9]*) heap_mb=1024 ;;
  *) heap_mb=$(( cgroup_mem / 1024 / 1024 * 70 / 100 )) ;;
esac
[ "$heap_mb" -lt 512 ] && heap_mb=512
[ "$heap_mb" -gt 16384 ] && heap_mb=16384
export NODE_OPTIONS="--max-old-space-size=${heap_mb}"
log "heap sized from cgroup: ${heap_mb} MB"

# ------------------------------------------------------------------- seeding
# Bind the seeding server to loopback on a port Railway does not route, so the
# bootstrap window is never reachable from the internet.
export INFISICAL_BOOT_PORT="${INFISICAL_BOOT_PORT:-8081}"

log "starting a loopback server on ${INFISICAL_BOOT_PORT} to seed the administrator"
HOST=127.0.0.1 PORT="$INFISICAL_BOOT_PORT" node --enable-source-maps dist/main.mjs &
boot_pid=$!

set +e
node /usr/local/bin/bootstrap.mjs
boot_rc=$?
set -e

kill "$boot_pid" 2>/dev/null || true
wait "$boot_pid" 2>/dev/null || true

if [ "$boot_rc" -ne 0 ]; then
  echo "[railway] FATAL: could not seed the instance administrator." >&2
  exit 1
fi

# --------------------------------------------------------------- real server
export HOST=0.0.0.0
export PORT="${PORT:-8080}"
log "starting Infisical on ${HOST}:${PORT}"
exec node --enable-source-maps dist/main.mjs
