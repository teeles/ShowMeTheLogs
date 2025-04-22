# ShowMeTheLogs

ShowMeTheLogs is a Bash script that gathers macOS system logs, diagnostic reports, and application‑specific logs into a structured ZIP archive on the user's Desktop. Designed for HelpDesk teams, it simplifies log collection for troubleshooting. Version 2.0 introduces modular functions, sysdiagnose integration, and pre‑check validations.

---

## Features

- **Structured Log Collection**: Separates logs into `/var/log`, `/Library/Logs`, and user `~/Library/Logs` directories.
- **sysdiagnose Integration**: Automatically runs `sysdiagnose` for in‑depth system diagnostics.
- **GlobalProtect Support**: Detects GlobalProtect installation and invokes its support script if present.
- **OneDrive Diagnostics**: Collects OneDrive diagnostic reports, preferences, and FileProvider logs.
- **Error Checking**: Validates each collection step and logs failures to an internal `SMTL.log`.
- **Zips up all the data**: Packages all collected logs into a timestamped ZIP on the Desktop.

---

## Prerequisites

- **macOS** (12.0+ recommended)
- **SwiftDialog** (for future GUI enhancements, optional)
- **GlobalProtect VPN** (optional, for VPN log collection)
- **OneDrive** (optional, for cloud sync log collection)

---

## Use Without MDM

1. **Download the Script**
   ```bash
   wget https://raw.githubusercontent.com/teeles/ShowMeTheLogs/refs/heads/main/ShowMeTheLogs.sh
   ```
2. **Make the script executable**
   ```bash
   chmod +x showmethelogs.sh
   ```
3. **Run the Scrip**

   ```bash
   ./showmethelogs.sh
   ```

- A temporary directory `/tmp/logs` is created for log aggregation.
- A ZIP file named `logs_backup_<hostname>_<YYYYMMDDHHMMSS>.zip` is placed on the user’s Desktop.
- Internal progress and errors are written to `/tmp/logs/SMTL.log`.

---

## Deployment with Jamf Pro

1. Upload `showmethelogs.sh` as a Script in Jamf Pro.  
2. Create a Policy scoped to your target Macs.  
3. In the “Scripts” payload, add `showmethelogs.sh` add to self service so users can access whenever. 

---

## Script Breakdown

| Function / Step       | Description                                                                                   |
| --------------------- | --------------------------------------------------------------------------------------------- |
| `set_up()`            | Creates temporary folders and initializes `SMTL.log`.                                         |
| `write_log()`         | Appends timestamped entries to `SMTL.log`.                                                    |
| `sdiagnose()`         | Runs `sysdiagnose`, checks output, and logs success or failure.                              |
| `global_protect()`    | Detects GlobalProtect and runs its support script into the log folder.                       |
| `one_drive()`         | Gathers OneDrive diagnostic reports, settings, FileProvider logs, and zips them separately.   |
| `/Library/Logs` copy  | Recursively copies system logs.                                                              |
| `~/Library/Logs` copy | Copies the logged‑in user’s library logs.                                                     |
| `/var/log` copy       | Copies all `/var/log` entries.                                                                |
| `zip` step            | Compresses the entire `/tmp/logs` folder to the Desktop.                                       |
| Cleanup               | Removes the temporary log folder after zipping.                                               |
| Exit check            | Confirms ZIP success and outputs a status message.                                            |

---

## To Do

- **Custom Log Paths**: Accept user‑defined log directories via flags.

---



