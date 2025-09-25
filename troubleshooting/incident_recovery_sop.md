# General Incident Recovery SOP

## Purpose
Standard operating procedure for recovering systems with OS corruption, random shutdowns, or database-dependent applications (e.g., SQL + business apps).

---

## Step 1 — Preparation
- Prepare bootable rescue media (Hiren’s/WinPE, Windows installer).
- Collect drivers, SQL Server installer, FoxPro/app installers, and license keys.
- Have an external disk for backups.
- Ensure admin credentials (Windows + SQL).

---

## Step 2 — Data Rescue
- Boot Hiren’s/WinPE.
- Copy critical files:
  - SQL DB files (*.mdf, *.ldf)
  - Application configs, licenses, executables
  - User data (C:\Users)
- Verify backup integrity (checksums/file size).

---

## Step 3 — Hardware Verification
- Run memory test (MemTest86).
- Check disk SMART + run `chkdsk`.
- Confirm BIOS defaults, time/date, and NIC enabled.

---

## Step 4 — Attempt OS Repair (if possible)
- Boot from Windows installer → Repair → Command Prompt.
- Identify OS partition letter (`diskpart → list vol`).
- Run DISM with matching source (install.wim/esd).
- Run SFC offline:
  ```
  sfc /scannow /offbootdir=D:\ /offwindir=D:\Windows
  ```
- If repair fails → proceed to clean install.

---

## Step 5 — Clean OS Installation
- Backup confirmed data.
- Boot installer → delete system partitions → fresh install.
- Install drivers (chipset, storage, NIC).
- Apply Windows Updates.

---

## Step 6 — Application & SQL Restore
1. Install SQL Server (matching previous version).
2. Place MDF/LDF in SQL data folder.
3. Attach DB:
   ```sql
   CREATE DATABASE [AppDB] ON
     (FILENAME = 'D:\MSSQL\DATA\AppDB.mdf'),
     (FILENAME = 'D:\MSSQL\DATA\AppDB_log.ldf')
   FOR ATTACH;
   ```
   If log missing:
   ```sql
   CREATE DATABASE [AppDB] ON
     (FILENAME = 'D:\MSSQL\DATA\AppDB.mdf')
   FOR ATTACH_REBUILD_LOG;
   ```
4. Run `DBCC CHECKDB` for integrity.
5. Recreate SQL logins and permissions.
6. Reinstall application (WinPark, FoxPro, etc.).
7. Reconfigure connection strings.

---

## Step 7 — Validation
- Test application workflows.
- Verify SQL logs, run sample transactions.
- Check Event Viewer for critical errors.
- Confirm NIC link lights and connectivity.

---

## Step 8 — Hardening & Backup
- Schedule SQL backups (full + transaction logs).
- Create system image baseline.
- Enable updates + antivirus/EDR.
- Monitor system logs and hardware health.

---

## Incident Report (Template)
- **Incident ID:**  
- **Date/Time:**  
- **System Affected:**  
- **Symptoms:**  
- **Actions Taken:**  
- **Outcome:**  
- **Remaining Issues:**  
- **Next Steps:**  
- **Responsible Technician:**  
