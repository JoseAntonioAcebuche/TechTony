# 📦 SQL Server Shrink Database Guide

**Author:** Jose Antonio "Tony" Acebuche"

**Category:** SQL Server Administration

**Purpose:** Learn how SQL Server Shrink Database works, when it should be used, its advantages and disadvantages, and best practices for safely reclaiming unused database space.

---

# 📖 Overview

**Shrink Database** is a SQL Server operation that reduces the physical size of database data files (.mdf, .ndf) and log files (.ldf) by reclaiming unused space.

It moves data pages toward the beginning of the file and releases the free space back to the operating system.

> **Important:** Shrinking a database should **not** be part of regular maintenance because it can cause index fragmentation and negatively impact performance.

---

# How Shrink Database Works

```text
Before Shrink

┌──────────────────────────────┐
│██████████████░░░░░░░░░░░░░░░░│
│ Used Data      Free Space    │
└──────────────────────────────┘

            │
            ▼

DBCC SHRINKDATABASE

            │
            ▼

┌──────────────────┐
│██████████████████│
│ Used Data Only   │
└──────────────────┘

Unused space is released back to Windows.
```

---

# When Should You Shrink a Database?

Shrink is appropriate only in special situations such as:

- Large amount of data permanently deleted
- Database archive completed
- One-time data migration
- Disk space emergency
- Temporary data removed
- Large maintenance operation completed

---

# When NOT to Shrink

Avoid shrinking when:

- Performing routine maintenance
- Database continues to grow regularly
- OLTP production databases
- Before index maintenance
- As part of nightly jobs

Frequent shrinking causes:

- Index fragmentation
- Slower queries
- Increased page splits
- Additional file growth events

---

# Types of Shrink

| Operation | Description |
|------------|-------------|
| DBCC SHRINKDATABASE | Shrinks the entire database |
| DBCC SHRINKFILE | Shrinks a specific data or log file |

---

# Method 1: Shrink Database (SSMS)

Navigate to:

```text
Object Explorer

↓

Databases

↓

Right Click Database

↓

Tasks

↓

Shrink

↓

Database
```

Configure:

- Database
- Shrink Action
- Target Free Space (%)

Click **OK**.

---

# Method 2: DBCC SHRINKDATABASE

Syntax

```sql
DBCC SHRINKDATABASE
(
ParkingDB
);
```

Specify target free space:

```sql
DBCC SHRINKDATABASE
(
ParkingDB,
10
);
```

This attempts to leave approximately **10% free space** inside the database.

---

# Method 3: Shrink Individual File

View logical file names:

```sql
USE ParkingDB;
GO

SELECT
name,
physical_name
FROM sys.database_files;
```

Shrink a data file:

```sql
DBCC SHRINKFILE
(
ParkingDB_Data,
10240
);
```

The target size is specified in **MB**.

---

# Shrinking Log Files

Example:

```sql
DBCC SHRINKFILE
(
ParkingDB_Log,
2048
);
```

---

# Check File Sizes

```sql
SELECT

name,

type_desc,

size * 8 / 1024 AS SizeMB

FROM sys.database_files;
```

---

# Check Database Space Usage

```sql
EXEC sp_spaceused;
```

Displays:

- Database size
- Reserved space
- Data size
- Index size
- Unused space

---

# Why Log Files Cannot Shrink

Common reasons:

- Active transaction
- Open transaction
- Full Recovery Model without log backups
- Replication
- Always On Availability Groups

Check the reason:

```sql
SELECT
name,
log_reuse_wait_desc
FROM sys.databases;
```

---

# Shrink Log File Properly

## Step 1

Backup the transaction log (Full Recovery Model)

```sql
BACKUP LOG ParkingDB

TO DISK='D:\Backup\ParkingDB_Log.trn';
```

---

## Step 2

Shrink the log

```sql
DBCC SHRINKFILE
(
ParkingDB_Log,
1024
);
```

---

# Recovery Model Considerations

| Recovery Model | Log Backup Required Before Shrink |
|----------------|-----------------------------------|
| Simple | No |
| Full | Yes |
| Bulk-Logged | Yes |

---

# Side Effects of Shrink

Shrinking may cause:

- Index fragmentation
- Poor query performance
- Page movement
- Increased file growth
- Longer execution plans

---

# Recommended After Shrink

Always rebuild or reorganize indexes after shrinking.

Example:

```sql
ALTER INDEX ALL
ON dbo.ParkingTransaction

REBUILD;
```

Then update statistics.

```sql
EXEC sp_updatestats;
```

---

# Monitor Fragmentation

```sql
SELECT

OBJECT_NAME(object_id) AS TableName,

avg_fragmentation_in_percent

FROM sys.dm_db_index_physical_stats
(
DB_ID(),
NULL,
NULL,
NULL,
'LIMITED'
);
```

---

# Best Practices

- Shrink only when necessary.
- Shrink specific files instead of the entire database when possible.
- Perform shrink during maintenance windows.
- Rebuild indexes after shrinking.
- Update statistics after index maintenance.
- Monitor file growth settings.
- Pre-size databases appropriately to reduce autogrowth.

---

# Common Mistakes

❌ Scheduling shrink jobs every night.

❌ Shrinking after every backup.

❌ Ignoring index fragmentation.

❌ Shrinking active production databases without planning.

❌ Forgetting to update statistics after shrink.

---

# Real-World Example

## Parking Management System

### Scenario

A parking transaction archive removed **150 GB** of historical data.

Before

```
Database Size

250 GB

Used Space

95 GB
```

Action

```sql
DBCC SHRINKDATABASE
(
ParkingDB,
10
);
```

After

```
Database Size

110 GB
```

Then:

```sql
ALTER INDEX ALL
ON dbo.ParkingTransaction
REBUILD;

EXEC sp_updatestats;
```

Result

- 140 GB reclaimed.
- Index performance restored.
- Storage costs reduced.
- Normal query performance maintained.

---

# Daily DBA Checklist

- [ ] Verify database free space.
- [ ] Monitor autogrowth events.
- [ ] Review disk usage.

---

# Monthly DBA Checklist

- [ ] Review database growth trends.
- [ ] Confirm shrink is not scheduled unnecessarily.
- [ ] Monitor index fragmentation.
- [ ] Verify maintenance plans.

---

# Related Documentation

- Backup and Restore
- Recovery Models
- Rebuild Index
- Reorganize Index
- Update Statistics
- DBCC CHECKDB
- Performance Tuning
- Maintenance Plan
- Auto Maintenance Scripts

---

# Summary

| Operation | Purpose |
|------------|----------|
| DBCC SHRINKDATABASE | Shrink entire database |
| DBCC SHRINKFILE | Shrink specific file |
| sp_spaceused | View database space usage |
| sys.database_files | View file information |
| sys.dm_db_index_physical_stats | Check fragmentation |

---

# Shrink Database Workflow

```text
Large Data Deleted
        │
        ▼
Check Free Space
        │
        ▼
Need Space Back?
   ┌────┴────┐
   │         │
  No        Yes
   │         │
   ▼         ▼
Monitor   Backup Log (if Full Recovery)
                 │
                 ▼
        Shrink Database/File
                 │
                 ▼
         Rebuild Indexes
                 │
                 ▼
        Update Statistics
                 │
                 ▼
      Verify Performance
```

---

# Enterprise Recommendation

```text
Routine Maintenance

Backup
    │
    ▼
DBCC CHECKDB
    │
    ▼
Index Maintenance
    │
    ▼
Update Statistics
    │
    ▼
Monitor Growth
    │
    ▼
Shrink Database?
    │
 ┌──┴──┐
 │     │
 No   Only if Necessary
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
