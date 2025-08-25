#!/bin/bash
SCRIPT_START=$(date +%s)

API="/usr/syno/bin/synowebapi"
DOCKER_BIN="$(command -v docker)"

# ── Pre-flight checks ────────────────────────────────────────────────────────
[ -x "$API" ]        || { echo "❌ synowebapi not found – abort."; exit 1; }
[ -x "$DOCKER_BIN" ] || { echo "❌ docker CLI not found – abort."; exit 1; }

# ── Containers ───────────────────────────────────────────────────────────────
PORTAINER="portainer"
HOMEPAGE="homepage"
ITTOOLS="IT-TOOLS"
IMMICH_SERVER="Immich-SERVER"
IMMICH_ML="Immich-LEARNING"
IMMICH_REDIS="Immich-REDIS"
IMMICH_DB="Immich-DB"
DOZZLE="Dozzle"
STT="SpeedTest-TRACKER"
STT_DB="SpeedTest-TRACKER-DB"
CFCF="cloudflare-cloudflared-1"
MINIQR="Mini-QR"
WUD="WUD"

ALL_CONTAINERS=(
  "$PORTAINER" "$HOMEPAGE" "$ITTOOLS" "$CFCF"
  "$HOMEPAGE" "$ITTOOLS" "$CFCF"
  "$IMMICH_SERVER" "$IMMICH_ML" "$IMMICH_REDIS" "$IMMICH_DB"
  "$MINIQR" "$WUD" "$STT" "$STT_DB"
)

# ── Tunable sleeps (seconds) ────────────────────────────────────────────────
SLEEP_SSHORT=5      # very short
SLEEP_SHORT=10      # per-container stop gaps and Immich sub-steps
SLEEP_MED=15        # pause between smaller app starts
SLEEP_LONG=30       # Portainer warm-up

wait_sshort() { sleep "$SLEEP_SSHORT"; }
wait_short()  { sleep "$SLEEP_SHORT"; }
wait_med()    { sleep "$SLEEP_MED"; }
wait_long()   { sleep "$SLEEP_LONG"; }

ts() { date '+%Y-%m-%d %H:%M:%S'; }

# ── api_call: pre-check state, then act ──────────────────────────────────────
# Usage: api_call <start|stop> <container_name>
api_call() {
  local act="$1" name="$2"

  # 1) Pre-check via docker ps
  if [ "$act" = start ]; then
    if $DOCKER_BIN ps --format '{{.Names}}' | grep -qx "$name"; then
      echo "⚠️  [$name] Already started"
      return 0
    fi
  else  # act == stop
    if ! $DOCKER_BIN ps --format '{{.Names}}' | grep -qx "$name"; then
      echo "⚠️  [$name] Already stopped"
      return 0
    fi
  fi

  # 2) Perform the Web-API call
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
  echo " [$(ts)] Verifying containers are stopped…"
  while :; do
    local running="$($DOCKER_BIN ps --format '{{.Names}}')"
    local still=()
    for n in "${names[@]}"; do
      if echo "$running" | grep -xq "$n"; then still+=("$n"); fi
    done
    [ ${#still[@]} -eq 0 ] && { echo "✅ [$(ts)] All specified containers stopped."; return 0; }

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
  echo "▶️  [$(ts)] Verifying containers are running…"
  while :; do
    local running="$($DOCKER_BIN ps --format '{{.Names}}')"
    local missing=()
    for n in "${names[@]}"; do
      if ! echo "$running" | grep -xq "$n"; then missing+=("$n"); fi
    done
    [ ${#missing[@]} -eq 0 ] && { echo "✅ [$(ts)] All specified containers running."; return 0; }

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
  echo -n "   • $IMMICH_REDIS… ";  api_call stop "$IMMICH_REDIS";  wait_med
  echo -n "   • $IMMICH_DB… ";     api_call stop "$IMMICH_DB";     wait_short
}
immich_start() {
  echo "▶️  [$(ts)]   • Starting Immich stack"
  echo -n "   • $IMMICH_DB… ";     api_call start "$IMMICH_DB";     wait_med
  echo -n "   • $IMMICH_REDIS… ";  api_call start "$IMMICH_REDIS";  wait_short
  echo -n "   • $IMMICH_ML… ";     api_call start "$IMMICH_ML";     wait_short
  echo -n "   • $IMMICH_SERVER… "; api_call start "$IMMICH_SERVER"; wait_short
}

# ── SpeedTest stack helpers ────────────────────────────────────────────────
stt_stop() {
  echo " [$(ts)]   • Stopping SpeedTest stack"
  echo -n "   • $STT… "; api_call stop "$STT"; wait_med
  # Ensure STT_DB is stopped last, as it is the database for STT
  echo -n "   • $STT_DB… "; api_call stop "$STT_DB"; wait_med
}
stt_start() {
  echo "▶️  [$(ts)]   • Starting SpeedTest stack"
  echo -n "   • $STT_DB… "; api_call start "$STT_DB"; wait_med
  echo -n "   • $STT… "; api_call start "$STT"; wait_med
}

# ── Full-stack stop / start sequences ────────────────────────────────────────
stop_all() {
  echo "▶️  [$(ts)]   • Stopping all containers in sequence"
  immich_stop
  stt_stop
  echo -n " [$(ts)] Stopping $ITTOOLS… ";   api_call stop "$ITTOOLS";   wait_sshort
  echo -n " [$(ts)] Stopping $MINIQR… ";    api_call stop "$MINIQR";    wait_sshort
  echo -n " [$(ts)] Stopping $WUD… ";       api_call stop "$WUD";       wait_sshort
  echo -n " [$(ts)] Stopping $CFCF… ";      api_call stop "$CFCF";      wait_sshort
  echo -n " [$(ts)] Stopping $HOMEPAGE… ";  api_call stop "$HOMEPAGE";  wait_sshort
  echo -n " [$(ts)] Stopping $PORTAINER… "; api_call stop "$PORTAINER"; wait_med
  echo -n " [$(ts)] Stopping $DOZZLE… ";    api_call stop "$DOZZLE";    wait_short
}

start_all() {
  echo "▶️  [$(ts)] Starting all containers in sequence"
  echo -n "▶️  [$(ts)] Starting $DOZZLE… ";    api_call start "$DOZZLE";    wait_long
  echo -n "▶️  [$(ts)] Starting $PORTAINER… "; api_call start "$PORTAINER"; wait_med
  echo -n "▶️  [$(ts)] Starting $HOMEPAGE… ";  api_call start "$HOMEPAGE";  wait_short
  echo -n "▶️  [$(ts)] Starting $CFCF… ";      api_call start "$CFCF";      wait_sshort
  echo -n "▶️  [$(ts)] Starting $ITTOOLS… ";   api_call start "$ITTOOLS";   wait_sshort
  echo -n "▶️  [$(ts)] Starting $MINIQR… ";    api_call start "$MINIQR";    wait_sshort
  echo -n "▶️  [$(ts)] Starting $WUD… ";       api_call start "$WUD";       wait_short
  immich_start
  stt_start
}

# ── Estimate total sleep time for start/stop ──────────────────────────────────
estimate_stop_time() {
  # Immich: 10+10+15+10 = 45
  # STT: 15+15 = 30
  # ITTOOLS, MINIQR, WUD, CFCF, HOMEPAGE: 5*5 = 25
  # PORTAINER: 15
  # DOZZLE: 10
  echo $((45 + 30 + 25 + 15 + 10))
}
estimate_start_time() {
  # DOZZLE: 30
  # PORTAINER: 15
  # HOMEPAGE: 10
  # CFCF, ITTOOLS, MINIQR: 3*5 = 15
  # WUD: 10
  # Immich: 15+10+10+10 = 45
  # STT: 15+15 = 30
  echo $((30 + 15 + 10 + 15 + 10 + 45 + 30))
}

# ── Driver ───────────────────────────────────────────────────────────────────
ACTION="${1:-restart}"
case "$ACTION" in
  stop)
    echo " [$(ts)] Stop sequence initiated sir"
    echo "⏳ Estimated stop sleep time: $(estimate_stop_time) seconds"
    stop_all
    ensure_stopped "${ALL_CONTAINERS[@]}"
    ;;
  start)
    echo "▶️  [$(ts)] Start sequence initiated sir"
    echo "⏳ Estimated start sleep time: $(estimate_start_time) seconds"
    start_all
    ensure_running "${ALL_CONTAINERS[@]}"
    ;;
  restart)
    echo " [$(ts)] Restart sequence initiated sir"
    echo "⏳ Estimated stop sleep time: $(estimate_stop_time) seconds"
    echo "⏳ Estimated start sleep time: $(estimate_start_time) seconds"
    stop_all
    ensure_stopped "${ALL_CONTAINERS[@]}"
    start_all
    ensure_running "${ALL_CONTAINERS[@]}"
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
echo " [$(ts)] Container status (all):"
$DOCKER_BIN ps -a --format "table {{.Names}}\t{{.Status}}"
