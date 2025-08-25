# Tailscale Synology Certificate Configuration Script (`tailscale_cert.sh`)

This document explains the purpose and usage of the `tailscale_cert.sh` script.

## Overview

This Bash script automates the process of running `tailscale configure synology-cert` non-interactively on your Synology NAS. It logs all output with timestamps and reports the total runtime at the end.

## Features
- **Automates Tailscale certificate configuration** for Synology
- **Non-interactive execution** suitable for scheduled or unattended runs
- **Logs output** with timestamps for easy troubleshooting
- **Reports total runtime**
- **Error handling** for missing Tailscale executable or failed configuration

## How It Works
1. **Startup:**
   - Prints a timestamped message indicating the start of the process.
2. **Pre-check:**
   - Verifies that the `tailscale` executable is available in the system PATH.
3. **Configuration:**
   - Runs `tailscale configure synology-cert` and logs the output.
   - Reports success or failure with exit code.
4. **Summary:**
   - Prints the total runtime in minutes and seconds.

## Usage
- Place the script on your Synology NAS.
- Set executable permissions: `chmod +x tailscale_cert.sh`
- Run manually or schedule via Synology Task Scheduler.

## Example Output
```
[2025-08-25 12:00:00] Starting Tailscale Synology-cert configuration…
[2025-08-25 12:00:00] Running: tailscale configure synology-cert
… (tailscale output) …
[2025-08-25 12:00:05] ✅ tailscale configure synology-cert completed successfully.
[2025-08-25 12:00:05] Total runtime: 00:05
```

## Requirements
- Synology NAS with Tailscale installed
- Bash shell

## Notes
- Make sure Tailscale is installed and in the system PATH.
- The script is safe to run non-interactively and can be used in scheduled tasks.
