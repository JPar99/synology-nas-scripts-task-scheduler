# Containers Start/Stop Sequence Script

This document explains the purpose and usage of the `containers_startstop_sequence.sh` script.

## Overview

This Bash script provides master control for starting, stopping, or restarting a suite of Docker containers, including Immich, IT-TOOLS, Glances, homepage, Portainer, and others. It ensures containers are managed in a safe, ordered sequence, with checks, retries, and runtime summaries.

## Features
- **Start, stop, or restart** all managed containers in a defined order
- **Graceful shutdown and startup** with retries and forced actions if needed
- **Status checks** to confirm containers are running or stopped
- **Estimated sleep time** for start/stop operations
- **Runtime summary** and final status output

## Containers Managed
- `portainer`
- `homepage`
- `IT-TOOLS`
- `Immich-SERVER`, `Immich-LEARNING`, `Immich-REDIS`, `Immich-DB`
- `Dozzle`
- `SpeedTest-TRACKER`, `SpeedTest-TRACKER-DB`
- `cloudflare-cloudflared-1`
- `Mini-QR`
- `WUD`

## Usage
Run the script with one of the following arguments:

```sh
./containers_startstop_sequence.sh start    # Start all containers
./containers_startstop_sequence.sh stop     # Stop all containers
./containers_startstop_sequence.sh restart  # Restart all containers (default)
```
If no argument is provided, `restart` is used by default.

## How It Works
1. **Pre-flight Checks:**
   - Verifies that the Synology WebAPI and Docker CLI are available.
2. **Container Actions:**
   - Uses the Synology API to start/stop containers, with checks to avoid redundant actions.
3. **Graceful Handling:**
   - Retries stopping/starting containers, escalates to force-kill/restart if needed, and aborts if unsuccessful after several attempts.
4. **Order of Operations:**
   - Stops and starts containers in a logical sequence, respecting dependencies (e.g., databases before apps).
5. **Status Output:**
   - Prints the status of each container and a summary of the script runtime.
6. **Estimated Sleep Time:**
   - Provides an estimate of the total wait time for start/stop operations.

## Example Output
```
▶️  [2025-08-25 12:00:00] Start sequence initiated sir
⏳ Estimated start sleep time: 155 seconds
▶️  [2025-08-25 12:00:00] Starting Dozzle… ✅ [Dozzle] start OK
▶️  [2025-08-25 12:00:30] Starting portainer… ✅ [portainer] start OK
... (other containers)
✅ [2025-08-25 12:03:00] All specified containers running.
⏱️  [2025-08-25 12:03:00] Total runtime: 03:00
 [2025-08-25 12:03:00] Container status (all):
NAMES                STATUS
portainer            Up 3 minutes
homepage             Up 3 minutes
... (other containers)
```

## Requirements
- Synology NAS with Docker and Synology WebAPI
- Bash shell

## Notes
- The script is intended for environments where container names match those listed above.
- Adjust container names or sleep durations as needed for your setup.
- The script prints estimated sleep times, but actual times may vary depending on system performance.
