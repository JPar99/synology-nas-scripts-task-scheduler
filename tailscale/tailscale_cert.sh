#!/bin/bash
###############################################################################
# configure_tailscale_synology_cert.sh
#
# Runs `tailscale configure synology-cert` non-interactively, logs output with
# timestamps, and reports total runtime at the end.
###############################################################################

SCRIPT_START=$(date +%s)

# ts: print current timestamp as YYYY-MM-DD HH:MM:SS
ts() {
    date '+%Y-%m-%d %H:%M:%S'
}

echo "[$(ts)] Starting Tailscale Synology-cert configuration…"

# Verify that `tailscale` is in PATH
if ! command -v tailscale &>/dev/null; then
    echo "[$(ts)] ❌ Error: 'tailscale' executable not found. Aborting."
    exit 1
fi

# Execute the configure command and capture output
echo "[$(ts)] Running: tailscale configure synology-cert"
if tailscale configure synology-cert 2>&1; then
    echo "[$(ts)] ✅ tailscale configure synology-cert completed successfully."
    EXIT_CODE=0
else
    EXIT_CODE=$?
    echo "[$(ts)] ❌ tailscale configure synology-cert failed with exit code $EXIT_CODE."
fi

# Runtime summary
SCRIPT_END=$(date +%s)
ELAPSED=$((SCRIPT_END - SCRIPT_START))
printf '[%s] Total runtime: %02d:%02d\n' "$(ts)" $((ELAPSED/60)) $((ELAPSED%60))

exit $EXIT_CODE
