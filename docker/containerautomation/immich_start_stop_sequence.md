# Immich Start/Stop Sequence Script

This document explains the purpose and usage of the `immich_start_stop_sequence.sh` script.

## Overview

This Bash script is designed to control the lifecycle (start, stop, restart) of the Immich stack containers on a Synology NAS or similar Docker environment. It ensures that the Immich containers are started and stopped in the correct order, with checks and retries for reliability.

## Features
- **Start, stop, or restart** all Immich-related containers in the correct sequence
- **Graceful shutdown and startup** with retries and forced actions if needed
- **Status checks** to confirm containers are running or stopped
- **Runtime summary** and final status output

## Containers Managed
- `Immich-SERVER`
- `Immich-LEARNING`
- `Immich-REDIS`
- `Immich-DB`

## Usage
Run the script with one of the following arguments:

```sh
./immich_start_stop_sequence.sh start    # Start all Immich containers
./immich_start_stop_sequence.sh stop     # Stop all Immich containers
./immich_start_stop_sequence.sh restart  # Restart all Immich containers (default)
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
   - Stops: SERVER → LEARNING → REDIS → DB
   - Starts: DB → REDIS → LEARNING → SERVER
5. **Status Output:**
   - Prints the status of each container and a summary of the script runtime.

## Example Output
```
▶️  [2025-08-25 12:00:00] Immich start sequence initiated
   • Immich-DB… ✅ [Immich-DB] start OK
   • Immich-REDIS… ✅ [Immich-REDIS] start OK
   • Immich-LEARNING… ✅ [Immich-LEARNING] start OK
   • Immich-SERVER… ✅ [Immich-SERVER] start OK
✅ [2025-08-25 12:01:00] All Immich containers running.
⏱️  [2025-08-25 12:01:00] Total runtime: 01:00
 [2025-08-25 12:01:00] Immich container status:
Immich-SERVER   Up 1 minute
Immich-LEARNING Up 1 minute
Immich-REDIS    Up 1 minute
Immich-DB       Up 1 minute
```

## Requirements
- Synology NAS with Docker and Synology WebAPI
- Bash shell

## Notes
- The script is intended for environments where container names match those listed above.
- Adjust container names or sleep durations as needed for your setup.
