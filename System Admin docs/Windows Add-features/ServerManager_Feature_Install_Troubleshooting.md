# Server Manager — Feature Installation Troubleshooting Guide
**IT Department | Windows Server Administration**

---

## Section 1 — Pre-Installation Checks

Before installing any feature via Server Manager, verify the following:

| # | Check Item | How to Verify |
|---|---|---|
| 1 | Server is fully updated | Run Windows Update — pending updates can block feature installation |
| 2 | Logged in as Administrator | Must be local or domain Administrator — not standard user |
| 3 | Sufficient disk space | Minimum 1-2GB free on `C:\` — features extract files during install |
| 4 | Internet or WSUS access | Some features need source files from Windows Update or WSUS |
| 5 | No pending restart | Check Server Manager dashboard — pending restart blocks installs |
| 6 | Server Manager is up to date | Close and reopen Server Manager before starting |

> ⚠️ **WARNING:** Always take a snapshot or checkpoint (if VM) before installing roles/features on a production server.

---

## Section 2 — Standard Feature Installation (GUI)

| Step | Action | Details |
|---|---|---|
| 1 | Open Server Manager | Start → Server Manager (run as Administrator) |
| 2 | Click 'Add Roles and Features' | From Dashboard or Manage menu |
| 3 | Installation Type | Select 'Role-based or feature-based installation' |
| 4 | Select Server | Choose the target server from the pool |
| 5 | Select Feature | Navigate and check the feature/role to install |
| 6 | Add Required Features | Click 'Add Features' if prompted for dependencies |
| 7 | Confirm Installation | Review summary — tick 'Restart automatically if required' |
| 8 | Monitor Progress | Wait for installation to complete — do NOT close the wizard |
| 9 | Verify Installation | Check Server Manager dashboard — feature should show as Installed |

---

## Section 3 — Install via PowerShell (Recommended Alternative)

If Server Manager GUI fails, use PowerShell — more reliable and shows detailed error output.

**Check available features:**
```powershell
Get-WindowsFeature | Where-Object {$_.InstallState -eq 'Available'} | Select Name, DisplayName
```

**Install a specific feature:**
```powershell
Install-WindowsFeature -Name <FeatureName> -IncludeManagementTools -Verbose
```

**Install with all sub-features:**
```powershell
Install-WindowsFeature -Name <FeatureName> -IncludeAllSubFeature -IncludeManagementTools
```

**Verify installed features:**
```powershell
Get-WindowsFeature | Where-Object {$_.InstallState -eq 'Installed'} | Select Name, DisplayName
```

### Common Feature Names

| PowerShell Feature Name | Description |
|---|---|
| `AD-Domain-Services` | Active Directory Domain Services |
| `DNS` | DNS Server |
| `DHCP` | DHCP Server |
| `Web-Server` | IIS Web Server |
| `File-Services` | File and Storage Services |
| `RSAT-AD-Tools` | AD Remote Server Admin Tools |
| `Telnet-Client` | Telnet Client |
| `NET-Framework-45-Features` | .NET Framework 4.5 |
| `Windows-Server-Backup` | Windows Server Backup |
| `SNMP-Service` | SNMP Service |

---

## Section 4 — Troubleshooting Common Errors

| Error / Symptom | Likely Cause | Fix / Action |
|---|---|---|
| `0x800F0922` | Cannot reach Windows Update or WSUS | Check internet/WSUS connectivity. Use `-Source` flag pointing to SxS folder |
| "The source files could not be found" | Missing Windows installation source | Mount Windows ISO and run with `-Source D:\sources\sxs` |
| Feature greyed out / cannot select | Conflicting role installed or pending restart | Check for pending restart. Reboot server first |
| Installation stuck at 'Installing' | Background service hung or network issue | Wait 10 mins. If no progress, cancel and check `CBS.log` |
| "Access Denied" error | Not running as Administrator | Close Server Manager. Reopen as Administrator (right-click → Run as Admin) |
| Feature shows 'Failed' in dashboard | Incomplete install or dependency missing | Run `Get-WindowsFeature` to check status. Reinstall via PowerShell with `-Verbose` |
| Server restarts during install | Required restart was triggered | Normal behavior. Log back in — Server Manager will resume automatically |
| "This operation is not supported" | Server Core or wrong server edition | Verify Windows Server edition. Some features require Desktop Experience |
| CBS.log shows component store corruption | WinSXS component store corrupted | Run `DISM /Online /Cleanup-Image /RestoreHealth` then retry install |
| Dependency feature fails to install | Required dependency not met | Install dependencies first manually, then retry the main feature |

---

## Section 5 — Component Store Repair (DISM + SFC)

Run these commands **in order** when source file errors or component corruption is suspected.
Open **CMD or PowerShell as Administrator.**

**Step 1 — Check component store health:**
```cmd
DISM /Online /Cleanup-Image /CheckHealth
```

**Step 2 — Scan for corruption:**
```cmd
DISM /Online /Cleanup-Image /ScanHealth
```

**Step 3 — Restore health (requires internet or ISO source):**
```cmd
DISM /Online /Cleanup-Image /RestoreHealth
```

**Step 4 — Run SFC after DISM completes:**
```cmd
sfc /scannow
```

**Step 5 — If no internet, use Windows ISO as source:**
```cmd
DISM /Online /Cleanup-Image /RestoreHealth /Source:D:\sources\sxs /LimitAccess
```

> ⚠️ **WARNING:** Always run CMD or PowerShell as Administrator when executing DISM and SFC commands.

---

## Section 6 — Where to Find Log Files

| Log File | Location | Purpose |
|---|---|---|
| `CBS.log` | `C:\Windows\Logs\CBS\CBS.log` | Component-Based Servicing — main install log |
| `DISM.log` | `C:\Windows\Logs\DISM\dism.log` | DISM operations and errors |
| `ServerManager.log` | `C:\Windows\Logs\ServerManager.log` | Server Manager GUI operations |
| `WindowsUpdate.log` | `C:\Windows\WindowsUpdate.log` | Windows Update activity |
| Event Viewer | `eventvwr.msc` → Windows Logs → Application/System | System-level install events |

> 💡 **TIP:** When escalating an issue, always attach `CBS.log` and `DISM.log`. These logs contain the exact error codes needed for diagnosis.

---

## Quick Reference — Troubleshooting Flow

```
Feature install fails?
        │
        ├── Pending restart? → Reboot first → Retry
        │
        ├── Access Denied? → Reopen as Administrator → Retry
        │
        ├── Source files not found?
        │       └── Mount ISO → use -Source D:\sources\sxs
        │
        ├── Still failing via GUI?
        │       └── Switch to PowerShell → Install-WindowsFeature -Verbose
        │
        ├── CBS.log shows corruption?
        │       └── DISM RestoreHealth → SFC /scannow → Retry
        │
        └── Still failing? → Check CBS.log + DISM.log → Escalate
```

---

*IT Department | Windows Server Administration Guide | For internal use only*
