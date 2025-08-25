# synology-nas-scripts-task-scheduler

Handy scripts to run via task scheduler on your Synology NAS.

## Included Scripts

### 1. `immich_start_stop_sequence.sh`
Controls the start, stop, and restart of the Immich stack containers in a safe, ordered sequence. Includes status checks, retries, and a runtime summary.
- See: `immich_start_stop_sequence.md` for full documentation.

### 2. `containers_startstop_sequence.sh`
Master control script for starting, stopping, or restarting a suite of Docker containers (Immich, IT-TOOLS, Glances, homepage, Portainer, and more). Ensures proper order, handles dependencies, and provides runtime and status output.
- See: `containers_startstop_sequence.md` for full documentation.


### 3. `backup_config_dsm_dss.sh`
Automates the backup of Synology DSM system configuration to a `.dss` file and manages retention by deleting old backups. Includes detailed logging, retention management, and a runtime summary. Designed for use with Synology Task Scheduler.
- See: `backup_config_dss.md` for full documentation.

## Usage
- Place these scripts on your Synology NAS.
- Use the Synology Task Scheduler to run them as needed (e.g., for automated maintenance, backup, or service restarts).

## Documentation
- Each script has a dedicated `.md` file with details on usage, features, and requirements.

---

Feel free to update the documentation as you add or modify scripts!
