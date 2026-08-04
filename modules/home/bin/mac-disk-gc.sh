#!/bin/bash
# Recurring Mac + depot-fleet disk cleanup, run weekly by the
# launchd.agents.mac-disk-gc home-manager module (see
# modules/home/mac-disk-gc.nix). Safe/reversible steps only — no VM image
# compaction here (that needs stopping VMs; run manually/less often).
set -uo pipefail

# launchd agents get a minimal PATH (no Homebrew/nix/orbstack dirs) — extend
# it explicitly so docker/xcrun/etc resolve the same as in an interactive shell.
export PATH="$HOME/.local/bin:$HOME/.orbstack/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

LOG_PREFIX="[mac-disk-gc $(date '+%Y-%m-%d %H:%M:%S')]"
log() { echo "$LOG_PREFIX $*"; }

free_gb() {
  df -g / 2>/dev/null | awk 'NR==2{print $4}' || df -k / | awk 'NR==2{print int($4/1024/1024)}'
}

before=$(free_gb)
log "starting, free=${before}G"

# --- Docker / OrbStack: build cache + dangling images (safe, CI-reproducible) ---
# OrbStack isn't a login item, so its daemon is often not running when this
# fires. Launch it and wait briefly for the socket before giving up.
if command -v docker >/dev/null 2>&1 && ! docker system df >/dev/null 2>&1; then
  log "docker: daemon not up, launching OrbStack"
  open -g -a OrbStack >/dev/null 2>&1 || true
  for _ in $(seq 1 30); do
    docker system df >/dev/null 2>&1 && break
    sleep 2
  done
fi

if command -v docker >/dev/null 2>&1 && docker system df >/dev/null 2>&1; then
  log "docker: pruning build cache"
  docker builder prune -a -f >/dev/null 2>&1
  log "docker: pruning dangling images"
  docker image prune -a -f >/dev/null 2>&1
  # NOTE: deliberately NOT pruning volumes here — orphaned volumes across
  # other repos (postgres/minio/etc data) can hold real data. Review manually:
  #   docker volume ls -f dangling=true
else
  log "docker: daemon not reachable, skipping"
fi

# --- Xcode Simulator runtimes: keep only the newest ---
if command -v xcrun >/dev/null 2>&1; then
  runtimes=$(xcrun simctl runtime list 2>/dev/null | grep -E '^iOS ' | grep -oE '[0-9A-F-]{36}' || true)
  count=$(echo "$runtimes" | grep -c . || true)
  if [ "$count" -gt 1 ]; then
    newest=$(xcrun simctl runtime list 2>/dev/null | grep -E '^iOS ' | tail -1 | grep -oE '[0-9A-F-]{36}')
    log "simulator runtimes: keeping $newest, deleting $((count - 1)) older"
    for uuid in $runtimes; do
      [ "$uuid" = "$newest" ] && continue
      xcrun simctl runtime delete "$uuid" >/dev/null 2>&1
    done
  fi
fi

# --- iOS DeviceSupport: keep newest 2 per device ---
DS_DIR="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
if [ -d "$DS_DIR" ]; then
  find "$DS_DIR" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null \
    | xargs -0 ls -dt 2>/dev/null \
    | tail -n +3 \
    | while IFS= read -r old; do
        log "iOS DeviceSupport: removing stale $(basename "$old")"
        rm -rf "$old"
      done
fi

# --- go build cache (rebuildable) ---
[ -d "$HOME/.cache/go-build" ] && rm -rf "$HOME/.cache/go-build"

# --- depot fleet: rollback backups + nix gc + journal + apt + fstrim ---
DEPOT_DIR="$HOME/Developer/go/src/github.com/spinupdev/depot"
if [ -d "$DEPOT_DIR/tools" ]; then
  log "depot fleet: running disk-gc"
  ( cd "$DEPOT_DIR" && ./tools/devtool fleet disk-gc >/tmp/mac-disk-gc-fleet.log 2>&1 )
fi

after=$(free_gb)
log "done, free=${before}G -> ${after}G"

if [ "$after" -lt 50 ]; then
  osascript -e "display notification \"Only ${after}GB free after cleanup — VM disk images likely need compaction (qemu-img).\" with title \"Mac disk still low\"" >/dev/null 2>&1 || true
fi
