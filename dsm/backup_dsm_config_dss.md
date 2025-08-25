# DSM Config Backup Script (`backup_config_dss.sh`)

This document explains the purpose and usage of the `backup_config_dss.sh` script.

## Overview

This Bash script automates the backup of Synology DSM system configuration to a `.dss` file and manages retention by deleting old backups. It is designed to be run via the Synology Task Scheduler and logs all actions to stdout.

## Features
- **Exports DSM configuration** to a timestamped `.dss` file
- **Retention management:** deletes backups older than a specified number of days
- **Detailed logging** with timestamps and status icons
- **Runtime summary** at the end

## How It Works
1. **Configuration:**
   - Set the backup target directory and retention period at the top of the script.
2. **Export:**
   - Uses Synology's `synoconfbkp` tool to export the current configuration to a file named with the hostname and timestamp.
3. **Prune Old Backups:**
   - Scans the backup directory for `.dss` files, parses their dates, and deletes those older than the retention period.
4. **Logging:**
   - Logs each step, including files kept, deleted, or skipped (if filename pattern does not match).
5. **Summary:**
   - Prints a summary of deleted, kept, and skipped files, and the total runtime.

## Usage
- Place the script on your Synology NAS.
- Set executable permissions: `chmod +x backup_config_dss.sh`
- Schedule it via Synology Task Scheduler for regular automated backups.

## Example Output
```
────────────────────────────────────────────────────────────
[2025-08-25 12:00:00] ⓘ INFO   → Start DSM-config backup
────────────────────────────────────────────────────────────
[2025-08-25 12:00:00] ✅ SUCCESS→ Export OK      → NAS_2025-08-25_1200.dss (2.1M)
────────────────────────────────────────────────────────────
[2025-08-25 12:00:00] ⓘ INFO   → Prune backups ouder dan 30 dagen (naam-datum)
[2025-08-25 12:00:00] ⚠️ WARN   → Verwijder       → NAS_2025-07-20_1200.dss
[2025-08-25 12:00:00] ⓘ INFO   → Behoud          → NAS_2025-08-25_1200.dss
[2025-08-25 12:00:00] ✅ SUCCESS→ Samenvatting: deleted=1, kept=1, skipped=0
[2025-08-25 12:00:00] ✅ SUCCESS→ Backup voltooid in 0m 2s
────────────────────────────────────────────────────────────
```

## Requirements
- Synology NAS with DSM and `synoconfbkp` tool
- Bash shell

## Notes
- Adjust `TARGET_DIR` and `RETENTION_DAYS` as needed for your environment.
- The script logs in both English and Dutch (for some messages).
- Make sure the backup directory exists and is writable by the script.
