#!/bin/bash
###############################################################################
# DSM Config Backup – System settings export (.dss)
# Logs to stdout only; Synology captures stdout/stderr itself
###############################################################################

set -euo pipefail

SCRIPT_START=$(date +%s)

# ── Configuratie ──────────────────────────────────────────────────────────────
TARGET_DIR="/volume1/Backup/systemconfiguration/dss"
RETENTION_DAYS=30
API_BIN="/usr/syno/bin/synoconfbkp"

# ── Helpers ───────────────────────────────────────────────────────────────────
ts()  { date '+%Y-%m-%d %H:%M:%S'; }
sep() { printf '─%.0s' {1..60}; echo; }
log_info()    { printf "[%s] ⓘ INFO   → %s\n"    "$(ts)" "$1"; }
log_success() { printf "[%s] ✅ SUCCESS→ %s\n"   "$(ts)" "$1"; }
log_warn()    { printf "[%s] ⚠️ WARN   → %s\n"   "$(ts)" "$1"; }
log_error()   { printf "[%s] ❌ ERROR  → %s\n"   "$(ts)" "$1"; }

# ── BEGIN ─────────────────────────────────────────────────────────────────────
sep
log_info "Start DSM-config backup"
sep

# ── Export .dss ───────────────────────────────────────────────────────────────
sep
FNAME="$(hostname)_$(date +%Y-%m-%d_%H%M).dss"
DEST="$TARGET_DIR/$FNAME"

if $API_BIN export --filepath="$DEST" &>/dev/null; then
  SIZE=$(du -h "$DEST" | cut -f1)
  log_success "Export OK      → $FNAME ($SIZE)"
else
  log_error   "Export MISLUKT → $FNAME"
  exit 1
fi

# ── Prune oude backups op bestandsnaam-datum ─────────────────────────────────
sep
log_info "Prune backups ouder dan ${RETENTION_DAYS} dagen (naam-datum)"

CUTOFF=$(date -d "-${RETENTION_DAYS} days" +%s)
deleted=0 kept=0 skipped=0

# Verzamel alle .dss in map
shopt -s nullglob
files=( "$TARGET_DIR"/*.dss )

for file in "${files[@]}"; do
  fname=$(basename "$file")
  if [[ $fname =~ _([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4})\.dss$ ]]; then
    datestr=${BASH_REMATCH[1]}
    dt="${datestr:0:10} ${datestr:11:2}:${datestr:13:2}"
    file_epoch=$(date -d "$dt" +%s 2>/dev/null || echo "")
    if [[ -n "$file_epoch" && "$file_epoch" -lt "$CUTOFF" ]]; then
      log_warn "Verwijder       → $fname"
      rm -f "$file"
      ((deleted++))
    else
      log_info "Behoud          → $fname"
      ((kept++))
    fi
  else
    log_warn "Skip (patroon mismatch) → $fname"
    ((skipped++))
  fi
done

if [ $deleted -eq 0 ]; then
  log_success "Geen oude backups om te verwijderen."
fi

# ── Runtime summary ───────────────────────────────────────────────────────────
sep
log_success "Samenvatting: deleted=${deleted}, kept=${kept}, skipped=${skipped}"
SCRIPT_END=$(date +%s)
ELAPSED=$((SCRIPT_END - SCRIPT_START))
log_success "Backup voltooid in $((ELAPSED/60))m $((ELAPSED%60))s"
sep

exit 0
