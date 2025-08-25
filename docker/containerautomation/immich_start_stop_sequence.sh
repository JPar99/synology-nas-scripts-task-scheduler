#!/bin/bash
###############################################################################
# Immich stack control – start, stop, restart only Immich containers
###############################################################################
SCRIPT_START=$(date +%s)

API="/usr/syno/bin/synowebapi"
DOCKER_BIN="$(command -v docker)"

# ── Pre-flight checks ────────────────────────────────────────────────────────
[ -x "$API" ]        || { echo "❌ synowebapi not found – abort."; exit 1; }
[ -x "$DOCKER_BIN" ] || { echo "❌ docker CLI not found – abort."; exit 1; }

# ── Immich containers ────────────────────────────────────────────────────────
IMMICH_SERVER="Immich-SERVER"
IMMICH_ML="Immich-LEARNING"
IMMICH_REDIS="Immich-REDIS"
IMMICH_DB="Immich-DB"

IMMICH_CONTAINERS=(
  "$IMMICH_SERVER" "$IMMICH_ML" "$IMMICH_REDIS" "$IMMICH_DB"
)

# ── Tunable sleeps (seconds) ────────────────────────────────────────────────
SLEEP_SHORT=10      # per-container stop gaps and Immich sub-steps

wait_short()  { sleep "$SLEEP_SHORT"; }
ts() { date '+%Y-%m-%d %H:%M:%S'; }

# ── api_call: pre-check state, then act ──────────────────────────────────────
api_call() {
  local act="$1" name="$2"
  if [ "$act" = start ]; then
    if $DOCKER_BIN ps --format '{{.Names}}' | grep -qx "$name"; then
      echo "⚠️  [$name] Already started"
      return 0
    fi
  else
    if ! $DOCKER_BIN ps --format '{{.Names}}' | grep -qx "$name"; then
      echo "⚠️  [$name] Already stopped"
      return 0
    fi
  fi
  local out
  out="$($API --exec api=SYNO.Docker.Container method="$act" version=1 name="$name" 2>/dev/null)"
  if echo "$out" | grep -q '"success"[[:space:]]*:[[:space:]]*true'; then
    echo "✅ [$name] $act OK"
  else
    echo "❌ [$name] $act FAIL  $out"
    return 1
  fi
}

# ── ensure_stopped (retry -> kill -> abort) ──────────────────────────────────
ensure_stopped() {
  local names=("$@") elapsed=0
  echo " [$(ts)] Verifying Immich containers are stopped…"
  while :; do
    local running="$($DOCKER_BIN ps --format '{{.Names}}')"
    local still=()
    for n in "${names[@]}"; do
      if echo "$running" | grep -xq "$n"; then still+=("$n"); fi
    done
    [ ${#still[@]} -eq 0 ] && { echo "✅ [$(ts)] All Immich containers stopped."; return 0; }
    elapsed=$((elapsed+2))
    case $elapsed in
      30)
        echo "⏳ [$(ts)] • Retry graceful stop on: ${still[*]}"
        for n in "${still[@]}"; do api_call stop "$n"; done
        ;;
      60)
        echo " [$(ts)] • Force-killing: ${still[*]}"
        for n in "${still[@]}"; do $DOCKER_BIN kill "$n" >/dev/null 2>&1; done
        ;;
      90)
        echo "❌ [$(ts)] ABORT – still running: ${still[*]}"
        exit 1
        ;;
    esac
    sleep 2
  done
}

# ── ensure_running (retry -> restart -> abort) ───────────────────────────────
ensure_running() {
  local names=("$@") elapsed=0
  echo "▶️  [$(ts)] Verifying Immich containers are running…"
  while :; do
    local running="$($DOCKER_BIN ps --format '{{.Names}}')"
    local missing=()
    for n in "${names[@]}"; do
      if ! echo "$running" | grep -xq "$n"; then missing+=("$n"); fi
    done
    [ ${#missing[@]} -eq 0 ] && { echo "✅ [$(ts)] All Immich containers running."; return 0; }
    elapsed=$((elapsed+2))
    case $elapsed in
      30)
        echo "⏳ [$(ts)] • Retry start on: ${missing[*]}"
        for n in "${missing[@]}"; do api_call start "$n"; done
        ;;
      60)
        echo " [$(ts)] • docker restart on: ${missing[*]}"
        for n in "${missing[@]}"; do $DOCKER_BIN restart "$n" >/dev/null 2>&1; done
        ;;
      90)
        echo "❌ [$(ts)] ABORT – failed to start: ${missing[*]}"
        exit 1
        ;;
    esac
    sleep 2
  done
}

# ── Immich helpers ───────────────────────────────────────────────────────────
immich_stop() {
  echo " [$(ts)]   • Stopping Immich stack"
  echo -n "   • $IMMICH_SERVER… "; api_call stop "$IMMICH_SERVER"; wait_short
  echo -n "   • $IMMICH_ML… ";     api_call stop "$IMMICH_ML";     wait_short
  echo -n "   • $IMMICH_REDIS… ";  api_call stop "$IMMICH_REDIS";  wait_short
  echo -n "   • $IMMICH_DB… ";     api_call stop "$IMMICH_DB";     wait_short
}
immich_start() {
  echo "▶️  [$(ts)]   • Starting Immich stack"
  echo -n "   • $IMMICH_DB… ";     api_call start "$IMMICH_DB";     wait_short
  echo -n "   • $IMMICH_REDIS… ";  api_call start "$IMMICH_REDIS";  wait_short
  echo -n "   • $IMMICH_ML… ";     api_call start "$IMMICH_ML";     wait_short
  echo -n "   • $IMMICH_SERVER… "; api_call start "$IMMICH_SERVER"; wait_short
}

# ── Driver ───────────────────────────────────────────────────────────────────
ACTION="${1:-restart}"
case "$ACTION" in
  stop)
    echo " [$(ts)] Immich stop sequence initiated"
    immich_stop
    ensure_stopped "${IMMICH_CONTAINERS[@]}"
    ;;
  start)
    echo "▶️  [$(ts)] Immich start sequence initiated"
    immich_start
    ensure_running "${IMMICH_CONTAINERS[@]}"
    ;;
  restart)
    echo " [$(ts)] Immich restart sequence initiated"
    immich_stop
    ensure_stopped "${IMMICH_CONTAINERS[@]}"
    immich_start
    ensure_running "${IMMICH_CONTAINERS[@]}"
    ;;
  *)
    echo "❓ Usage: $0 [start|stop|restart]"
    exit 1
    ;;
esac

# ── Runtime summary ----------------------------------------------------------
SCRIPT_END=$(date +%s)
ELAPSED=$((SCRIPT_END - SCRIPT_START))
printf '⏱️  [%s] Total runtime: %02d:%02d\n' "$(ts)" $((ELAPSED/60)) $((ELAPSED%60))

# ── Final status -------------------------------------------------------------
echo " [$(ts)] Immich container status:"
$DOCKER_BIN ps -a --format "table {{.Names}}\t{{.Status}}" | grep -E 'Immich-(SERVER|LEARNING|REDIS|DB)'
