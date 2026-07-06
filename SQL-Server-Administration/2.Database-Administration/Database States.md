# 💾 SQL Server Database States

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** To understand the different SQL Server database states, their causes, and the appropriate recovery or troubleshooting steps.

---

# 📖 Overview

A SQL Server database can exist in different operational states. These states indicate whether the database is available for user access, recovering, restoring, or requires administrator intervention.

Understanding database states helps database administrators quickly diagnose and resolve issues.

---

# Database State Overview

| Database State | User Access | Description |
|----------------|:-----------:|-------------|
| ONLINE | ✅ | Database is fully operational. |
| OFFLINE | ❌ | Database is manually taken offline. |
| RESTORING | ❌ | Database is currently being restored. |
| RECOVERING | ❌ | SQL Server is recovering the database during startup. |
| RECOVERY_PENDING | ❌ | Recovery cannot start because required resources are unavailable. |
| SUSPECT | ❌ | SQL Server detected corruption or cannot complete recovery. |
| EMERGENCY | Limited | Read-only emergency access for troubleshooting. |

---

# 1. ONLINE

## Description

The database is available and functioning normally.

Users can:

- Read data
- Insert data
- Update records
- Delete records

---

## Verify Status

```sql
SELECT
name,
state_desc
FROM sys.databases;
```

Expected Output

```text
ONLINE
```

---

# 2. OFFLINE

## Description

The database has been intentionally taken offline by an administrator.

No users can access the database.

---

## Common Reasons

- Server maintenance
- Database migration
- File relocation
- Troubleshooting

---

## Bring Database Online

```sql
ALTER DATABASE ParkingDB
SET ONLINE;
```

---

# 3. RESTORING

## Description

The database is currently being restored from a backup.

Users cannot access the database until the restore process is complete.

---

## Common Causes

- Full Backup Restore
- Differential Restore
- Transaction Log Restore
- Point-in-Time Recovery

---

## Complete Restore

```sql
RESTORE DATABASE ParkingDB
WITH RECOVERY;
```

---

# 4. RECOVERING

## Description

SQL Server is performing crash recovery.

This typically occurs after:

- SQL Server restart
- Unexpected shutdown
- Power outage

---

## What SQL Server Does

- Redo committed transactions
- Undo incomplete transactions
- Verify transaction logs

Normally this state lasts only a short period.

---

# 5. RECOVERY_PENDING

## Description

SQL Server knows recovery is required but cannot begin because necessary resources are unavailable.

---

## Common Causes

- Disk full
- Missing database files
- Permission issues
- Storage failure

---

## Troubleshooting

- Verify MDF/LDF files exist.
- Check available disk space.
- Verify file permissions.
- Review SQL Server Error Log.

---

# 6. SUSPECT

## Description

The database cannot complete recovery due to corruption or serious errors.

Users cannot access the database.

---

## Common Causes

- Corrupted MDF file
- Corrupted LDF file
- Storage failure
- Unexpected shutdown during write operations

---

## Check Database State

```sql
SELECT
name,
state_desc
FROM sys.databases;
```

---

## Possible Recovery Steps

Set Emergency Mode

```sql
ALTER DATABASE ParkingDB
SET EMERGENCY;
```

Run Integrity Check

```sql
DBCC CHECKDB ('ParkingDB');
```

Repair (Last Resort)

```sql
DBCC CHECKDB
(
'ParkingDB',
REPAIR_ALLOW_DATA_LOSS
);
```

> **Warning:** `REPAIR_ALLOW_DATA_LOSS` may permanently remove damaged data. Always restore from a valid backup if possible.

---

# 7. EMERGENCY

## Description

Emergency Mode provides read-only access when a database is severely damaged.

Only members of the `sysadmin` server role can use Emergency Mode.

---

## Characteristics

- Read-only
- Logging disabled
- Single-user access
- Used for data recovery

---

## Enable Emergency Mode

```sql
ALTER DATABASE ParkingDB
SET EMERGENCY;
```

---

# Check Database State

```sql
SELECT
name,
state_desc
FROM sys.databases
ORDER BY name;
```

---

# Check Database Files

```sql
SELECT
name,
physical_name,
state_desc
FROM sys.master_files;
```

---

# Best Practices

- Monitor SQL Server Error Logs regularly.
- Perform scheduled Full, Differential, and Transaction Log Backups.
- Run `DBCC CHECKDB` regularly.
- Monitor disk space and storage health.
- Test restore procedures periodically.
- Use RAID and redundant storage for production databases.
- Configure SQL Server alerts for database state changes.

---

# Common Troubleshooting Flow

```text
Database Unavailable
        │
        ▼
Check Database State
        │
        ├── ONLINE
        │      │
        │      └── Investigate application issue
        │
        ├── OFFLINE
        │      │
        │      └── Bring database ONLINE
        │
        ├── RESTORING
        │      │
        │      └── Complete RESTORE WITH RECOVERY
        │
        ├── RECOVERING
        │      │
        │      └── Wait for recovery to complete
        │
        ├── RECOVERY_PENDING
        │      │
        │      └── Check storage and SQL logs
        │
        ├── SUSPECT
        │      │
        │      └── Restore backup or use EMERGENCY mode
        │
        └── EMERGENCY
               │
               └── Recover data and restore database
```

---

# Real-World Example

### Parking Management System

A parking management database suddenly becomes inaccessible after a power outage.

Investigation:

1. Check SQL Server service.
2. Query `sys.databases`.
3. Database state shows **RECOVERY_PENDING**.
4. Verify the database drive is full.
5. Free disk space.
6. Restart SQL Server.
7. Database returns to **ONLINE**.

---

# Summary

| State | Accessible | Administrator Action |
|--------|:----------:|----------------------|
| ONLINE | ✅ | None |
| OFFLINE | ❌ | Bring database online |
| RESTORING | ❌ | Finish restore |
| RECOVERING | ❌ | Wait |
| RECOVERY_PENDING | ❌ | Resolve storage/resource issue |
| SUSPECT | ❌ | Restore backup or repair |
| EMERGENCY | Limited | Recover data |

---

# Related Documentation

- Recovery Models
- Backup Operations
- Restore Operations
- DBCC CHECKDB
- Database Corruption
- SQL Server Troubleshooting
- Performance Tuning

---

**Documentation by:**  
**Jose Antonio "Tony" Acebuche**
