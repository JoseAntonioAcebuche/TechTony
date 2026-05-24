# Windows OS / Server Repair & Recovery Guide

> **Applicable Systems:** Windows 10/11, Windows Server 2019/2022/2025  
> **Prepared by:** Jose Antonio Acebuche – IT Infrastructure  
> **Organization:** Chase Technologies Corporation  
> **Classification:** Internal Use Only

---

## Table of Contents

1. [Overview](#1-overview)
2. [Troubleshooting Escalation Path](#11-troubleshooting-escalation-path)
3. [Step 1 – System File Checker (SFC)](#2-step-1--system-file-checker-sfc)
4. [Step 2 – DISM](#3-step-2--dism)
5. [Step 3 – Check Disk (CHKDSK)](#4-step-3--check-disk-chkdsk)
6. [Step 4 – Windows Recovery Environment (WinRE)](#5-step-4--windows-recovery-environment-winre)
7. [Step 5 – In-Place Repair / Upgrade](#6-step-5--in-place-repair--upgrade)
8. [Quick Reference – Command Summary](#7-quick-reference--command-summary)
9. [Additional Notes for Production Servers](#8-additional-notes-for-production-servers)

---

## 1. Overview

This document provides a step-by-step guide for repairing a corrupted Windows OS or Windows Server using Microsoft's built-in tools. Procedures are arranged in order of escalation — from the simplest fix to the most comprehensive recovery method.

> ⚠️ **NOTE:** Always back up critical data before starting any repair procedure. In Windows Server environments running SQL Server instances, ensure all databases and system state are backed up first.

---

## 1.1 Troubleshooting Escalation Path

Follow this order — do not skip to a higher step without first attempting the simpler solution:

| Tool | When to Use | Command / Action |
|------|-------------|-----------------|
| `SFC` | System file errors, Windows instability | `sfc /scannow` |
| `DISM` | SFC failed; repair the Windows component store | `DISM.exe /Online /Cleanup-image /Restorehealth` |
| `CHKDSK` | Bad sectors, corrupted directories, I/O freeze | `chkdsk C: /f /r` |
| `WinRE` | OS fails to boot | Boot USB > Troubleshoot > Startup Repair |
| `In-Place Upgrade` | Severe corruption, OS no longer functional | `Setup.exe` > Keep files and apps |

---

## 2. Step 1 – System File Checker (SFC)

**Simplest approach — scan and repair corrupted system files**

### When to Use

- System errors are present and Windows is not functioning normally
- Issues manifest as random crashes, slow performance, or missing DLLs
- Always attempt this first before moving to more advanced tools

### Procedure

1. Open **Command Prompt as Administrator**:
   - Type `cmd` in the Start search bar
   - Right-click > **Run as administrator**

2. Run the following command:

```cmd
sfc /scannow
```

3. Wait for the scan to complete — **do not interrupt.**
4. Restart the computer once the scan finishes.

> 💡 **OUTPUT INTERPRETATION:**  
> - `Windows Resource Protection found corrupt files and repaired them` → **Success**  
> - `could not fix` → Proceed to **DISM (Step 2)**

---

## 3. Step 2 – DISM

**Repair the Windows component store and system image**

### When to Use

- SFC returned errors or failed to repair all corrupted files
- **Recommended:** Run DISM **before** SFC for better results on both
- SFC reports `found corrupt files but was unable to fix some of them`

### Standard Procedure (Online – internet access available)

1. Open **Command Prompt as Administrator.**
2. Run:

```cmd
DISM.exe /Online /Cleanup-image /Restorehealth
```

3. Wait for the process to complete (may take **10–20 minutes**).
4. Once finished, run SFC again:

```cmd
sfc /scannow
```

### Offline Procedure (For Airgapped / No-Internet Servers)

Use this when the server has no access to Windows Update — such as the production environment at ATC:

```cmd
DISM.exe /Online /Cleanup-Image /RestoreHealth ^
  /Source:wim:D:\sources\install.wim:1 /LimitAccess
```

Replace `D:\` with the drive letter of the mounted Windows ISO or USB installer.

> 💡 **PRO TIP:** In Windows Server environments, using an offline source is preferred to avoid downloading incorrect updates. Mount the correct Windows Server ISO before running DISM.

---

## 4. Step 3 – Check Disk (CHKDSK)

**Scan and fix errors on the hard drive or SSD**

### When to Use

- Bad sectors, corrupted directories, or file system errors are present
- System freezes while reading or writing to the drive
- Event Viewer shows disk-related errors (NTFS, Disk Event ID 7, 11, 55)

### Procedure

1. Open **Command Prompt as Administrator.**
2. Run the following command (replace `C:` if the OS is on a different drive):

```cmd
chkdsk C: /f /r
```

**Flag Reference:**

| Flag | Description |
|------|-------------|
| `/f` | Fixes file system errors |
| `/r` | Locates bad sectors and recovers readable data (implies `/f`) |

3. If the drive is in use, Windows will prompt you to schedule the scan on next restart. Type `Y` and restart.

> ⚠️ **WARNING:** The `/r` flag implies `/f` — including both is not redundant but improves documentation clarity. For production servers, schedule a **maintenance window** before running CHKDSK.

---

## 5. Step 4 – Windows Recovery Environment (WinRE)

**For systems that can no longer boot into Windows**

### When to Use

- The OS fails to boot after multiple attempts
- System is stuck in a boot loop or shows a black/blue screen before Windows loads
- Command Prompt cannot be accessed through normal means

### Procedure A – Using Advanced Startup Options

1. During boot, press **F8** or **Shift+F8** (or allow boot to fail three times for WinRE to load automatically).
2. Navigate to: **Troubleshoot > Advanced options > Startup Repair**
3. Allow Windows to diagnose and repair the boot issues.

### Procedure B – Using Windows USB Installer

1. Boot from a Windows installation USB or DVD.
2. On the setup screen, select **Repair your computer** (not Install).
3. Navigate to: **Troubleshoot > Advanced options > Startup Repair**
4. Alternatively, open **Command Prompt** to run SFC or DISM in offline mode.

> 📌 **SERVER NOTE:** For Windows Server, use the correct edition of installation media (2019/2022/2025). A mismatched edition may not repair correctly.

---

## 6. Step 5 – In-Place Repair / Upgrade

**Most thorough solution for severe OS corruption**

### When to Use

- Windows corruption is severe and SFC/DISM/CHKDSK could not resolve the issue
- You need to repair the OS without losing files, applications, or permissions
- For Windows Server: roles, features, and configurations are preserved

### Procedure

1. Download the correct Windows ISO:
   - **Windows 10/11:** Use the Microsoft Media Creation Tool
   - **Windows Server 2019/2022/2025:** Microsoft Evaluation Center or Volume Licensing

2. Mount the ISO while the system is running (double-click the ISO file).
3. Run `setup.exe` from the mounted drive.
4. In the setup wizard, select **Keep personal files and apps.**
5. Allow the upgrade/repair process to complete (**30–60 minutes**).

> 🔴 **CRITICAL – BEFORE RUNNING IN-PLACE UPGRADE:**
> 1. Back up system state and all SQL Server databases
> 2. Snapshot the VM if the server is virtualized
> 3. Document all installed roles and features
> 4. Verify the ISO matches the correct edition and build number

---

## 7. Quick Reference – Command Summary

```cmd
# STEP 1: System File Checker
sfc /scannow

# STEP 2A: DISM (Online – internet access available)
DISM.exe /Online /Cleanup-image /Restorehealth

# STEP 2B: DISM (Offline – no internet, using ISO)
DISM.exe /Online /Cleanup-Image /RestoreHealth /Source:wim:D:\sources\install.wim:1 /LimitAccess

# STEP 2C: After DISM completes, run SFC again
sfc /scannow

# STEP 3: Check Disk (replace C: if OS is on a different drive)
chkdsk C: /f /r

# STEP 4: WinRE – Boot from USB, navigate to:
# Troubleshoot > Advanced Options > Startup Repair

# STEP 5: In-Place Upgrade – Run setup.exe from mounted ISO
# Select: Keep personal files and apps
```

---

## 8. Additional Notes for Production Servers

The following best practices should be observed in all production Windows Server environments:

- **Always back up all SQL Server databases** before performing any repair
- For SQL Server Express (no SQL Agent), use `SQLCMD` + Windows Task Scheduler for automated backup jobs
- Check **Windows Event Viewer** (System and Application logs) to identify the root cause of corruption before running repairs
- **Never interrupt** SFC, DISM, or CHKDSK while running — doing so may worsen the issue
- After any repair, validate SQL Server instances and verify application connectivity
- **Document all steps taken and results** for change management records

> 📌 **REMINDER:** This document is for internal use only. Do not distribute outside the IT team.

---

*Windows OS / Server Repair & Recovery*